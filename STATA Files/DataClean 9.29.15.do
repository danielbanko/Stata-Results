* Data Prep for WaterSmart Boomerang
* Syon Bhanot
/*------------------------------------------------------------------------------
		Date Created: Sep 18, 2015
		Last Modified: Sep 26, 2015
		
------------------------------------------------------------------------------*/
//next three items, put on everything
clear
set more off
cap log close

*USER SELECTION*
*---------------------------------------------*
*cd "C:\Users\Syon\Dropbox\Research\Watersmart_Boomerang\Data2"
*cd "\Users\sbhanot1\Dropbox\Research\Watersmart_Boomerang\Data2"
//cd "/Users/xiyuesong/Dropbox/Data2/"
//Guihyun's
cd "/Users/guihyunbyon/desktop/ccwd"
*---------------------------------------------*

*Start with data import

*1) import water report emails data
*import excel "Batch 4\dallas_ws_medJune162015.xlsx", firstrow clear
//import excel "Batch 4/dallas_ws_medJune162015.xlsx", firstrow clear
import excel "/Users/guihyunbyon/desktop/ccwd/ccwd_ws_medSeptember242015.xlsx", firstrow clear

*drop pointless variables - don't think I need the latter...?
*drop channel utility_acct_no

//you should drop duplicates just in case someone mistyped
*drop duplicate observations--No duplicates
duplicates drop

*make mailer month and year variables using date variable in there
sort send_timestamp
//dofc is a date, turn it into a number
gen boo=dofc(send_timestamp)
unique boo
*making variables
gen mailermonth= month(boo)
gen maileryear= year(boo)
gen mailerday= day(boo)

*for mailer number
/*gen mailer=.
replace mailer=1 if mailermonth==10 & maileryear==2014
replace mailer=2 if mailermonth==11 & maileryear==2014
replace mailer=3 if mailermonth==12 & maileryear==2014
replace mailer=4 if mailermonth==1 & maileryear==2015
replace mailer=5 if mailermonth==2 & maileryear==2015
replace mailer=6 if mailermonth==3 & maileryear==2015*/

*check for weird stuff with mailers
sort residence_id send_timestamp
bysort residence_id: gen mailer2=_n
*bro residence_id send_timestamp mailer2

/*unique residence_id if mailer!=mailer2
gen temp_issue=0
replace temp_issue=1 if mailer!=mailer2*/
*ISSUE: 338 poeople have an issue here...

/* FIXED FROM BATCH 3 ON
*weird thing with email clicks and portal opens messing up by adding duplicates
bysort residence_id mailer: egen emailopen=max(email_open)
bysort residence_id mailer: egen portalclick=max(portallink_click)
drop email_open portallink_click
duplicates drop
*/

*drop boo variable
drop boo

*save data
sort residence_id mailer2
saveold "Reports.dta", replace

*------------------------------*

*2) use data
*import water use data
import excel ccwd_usageSeptember242015.xlsx, firstrow clear

*drop duplicates (there aren't any but just in case)
duplicates drop

*drop pointless variables
drop allocation

*make read type dummy
sort read_type
gen combinedread=0
replace combinedread=1 if read_type=="combined"
label variable combinedread "Dummy for if combined read (or NA) - whatever those are"
drop read_type
//THIS IS WHERE I GOT TO

*making mailer variables
gen mailer=.
replace mailer=1 if nthreading==9 & nthreading_year==2014
replace mailer=2 if nthreading==10 & nthreading_year==2014
replace mailer=3 if nthreading==11 & nthreading_year==2014
replace mailer=4 if nthreading==12 & nthreading_year==2014
replace mailer=5 if nthreading==1 & nthreading_year==2015
replace mailer=6 if nthreading==2 & nthreading_year==2015

*rename and destring gpd variable for merge
rename gpd gpd_usedata
replace gpd_usedata="" if gpd_usedata=="NA"
destring gpd_usedata, replace

*destring period_length variable
replace period_length="" if period_length=="NA"
destring period_length, replace

/* DON'T NEED TO DO THIS YET BUT WILL NEED TO DO IT LATER ONCE I HAVE THIS DATA
*preserve as new file the March and April 2015 use data
preserve
keep if nthreading_year==2015
keep if nthreading==3 | nthreading==4
save use_postperiod.dta, replace
restore
*/

* Now keep ALL observations; don't drop pre-period data
  
*save data
sort residence_id mailer
saveold "dallas_data/nodrop_with_pre.dta", replace

*------------------------------*

*3) account group data

*import account group data
*import excel "Batch 4\dallas_account_groups_June162015.xlsx", firstrow clear
import excel "Batch 4/dallas_account_groups_June162015.xlsx", firstrow clear

sort residence_id 

*save data
saveold "dallas_data/accountgroup.dta", replace

*------------------------------*

*4) residence demogs data

*import residence data
import excel "Batch 4/dallas_residence_June162015.xlsx", firstrow clear

*fix variables
rename id residence_id

//These characteristics variables may be very important!!!!
foreach var in YearHomeBuilt HomeSizeSqFt NumFloors LotSizeSqFt IrrigableAreaSqFt NumBedrooms NumBathrooms {
	replace `var'="" if `var'=="NA"
	destring `var', replace
}

* Fix these into dummies - OccupantsSource IrrigableAreaSource
  *make occupant source dummy
gen OccSource=0
replace OccSource=1 if OccupantsSource=="user-specified"
label variable OccSource "Dummy for if occupants is user-specified (0=estimated)"
drop OccupantsSource
  *make irrigable area dummy
gen IASource=0
replace IASource=1 if IrrigableAreaSource=="specified"
label variable IASource "Dummy for if IA is specified (0=coil-estimate)"
drop IrrigableAreaSource

sort residence_id

*save data
saveold "dallas_data/residence.dta", replace

*------------------------------*

*5) merge data
  
  * start with use data
  // Now the data I merge in has pre-mailer usage
use "dallas_data/nodrop_with_pre.dta",clear

  * merge use and email reports
  //SB: I use m:1 merge instead of your original 1:1 merge; but both the original and the current merge has ~40 unmatched.
  *SB RESPONSE: I SEE THAT ALSO - 42 UNMATCHED. THIS IS NOT NECESSARILY A PROBLEM. IT JUST MEANS 42 PEOPLE HAD USAGE DATA, BUT FOR SOME REASON DID NOT HAVE EMAIL REPORT DATA.

merge m:1 residence_id mailer using "dallas_data/nodrop_reports.dta"
rename _merge _merge1

/* DON'T NEED TO DO THIS YET BUT WILL NEED TO DO IT LATER ONCE I HAVE THIS DATA
  * append back the use data I had dropped for post-periods
append using use_postperiod.dta
replace mailer=7 if nthreading_year==2015 & nthreading==3
replace mailer=8 if nthreading_year==2015 & nthreading==4
*/
sort residence_id mailer

  * merge master and residence data
merge m:1 residence_id using "dallas_data/residence.dta"

tab _merge

drop if _merge==2

rename _merge _merge2

  * merge master and account group data
merge m:1 residence_id using "dallas_data/accountgroup.dta"
rename _merge _merge3
//There are unmatched. For now don't drop those
  * save merged file
*save merged.dta, replace
saveold "dallas_data/nodrop_withpre_merged.dta", replace

*------------------------------*

*6) clean up weird stuff and check merge

sort section

*drop people missing section
drop if section=="" //12 obsv. deleted

*drop people missing everything but accountgroup
*drop if _merge3==2
  * can drop _merge3 as it is all 3
  //SB: But now there are 12 with _m==1; people without an account group..
  *drop _merge3
  *SB RESPONSE - I DON'T SEE _merge3 HAVING ANY VALUES EXCEPT 3... (Right...Don't know why I was seeing that)
*  la var _merge2 "merge with accountgroup;1:without accountgroup;12 obs"
  
*a few checks
sum send_timestamp if section=="control"
  * good - all missing
sum send_timestamp if section=="experimental"
  * some missing - experimental people without an email sometimes
sort residence_id mailer
  
*check that GPDs match in use and reports data
gen check=.
replace check=gpd-gpd_usedata
tab check
*all zero... looks good
drop check
// Here let's drop one of the "gpd". Otherwise it becomes confusing!
drop gpd
saveold "dallas_data/full_merged2.dta", replace

*------------------------------*

*7) Bring next two periods use up

sort residence_id mailer

gen next_readdate=.
format next_readdate %tdnn/dd/CCYY
gen next_gpd=.
gen next_gallons=.
gen next_period_length=.
gen next_flag=.

gen next2_readdate=.
format next2_readdate %tdnn/dd/CCYY
gen next2_gpd=.
gen next2_gallons=.
gen next2_period_length=.
gen next2_flag=.

replace next_readdate = readdate[_n+1] if residence_id==residence_id[_n+1]
replace next_gpd = gpd_usedata[_n+1] if residence_id==residence_id[_n+1]
replace next_gallons = total_gallons[_n+1] if residence_id==residence_id[_n+1]
replace next_period_length = period_length[_n+1] if residence_id==residence_id[_n+1]
replace next_flag = suspect_data_flag[_n+1] if residence_id==residence_id[_n+1]

replace next2_readdate = readdate[_n+2] if residence_id==residence_id[_n+2]
replace next2_gpd = gpd_usedata[_n+2] if residence_id==residence_id[_n+2]
replace next2_gallons = total_gallons[_n+2] if residence_id==residence_id[_n+2]
replace next2_period_length = period_length[_n+2] if residence_id==residence_id[_n+2]
replace next2_flag = suspect_data_flag[_n+2] if residence_id==residence_id[_n+2]

*make mailer missing for observations that did not have emails associated!
replace mailer=. if send_timestamp==.

*------------------------------*

*8) Identify red flags

gen redflag=0
replace redflag=1 if waterscore!=3 & gpd>action_gpd_cutoff & mailer!=.
replace redflag=1 if waterscore!=1 & gpd<efficient_gpd_cutoff & mailer!=.
replace redflag=1 if waterscore!=2 & gpd<action_gpd_cutoff & gpd>efficient_gpd_cutoff & mailer!=.

*this is for when mailer is not equal to mailer2 from above
replace temp_issue=0 if temp_issue==.
bysort residence_id: egen mailerissue=max(temp_issue)
drop temp_issue
replace redflag=1 if mailerissue==1
drop mailerissue

*TO  VIEW RED FLAGS USE BELOW COMMAND
*bro residence_id send_timestamp waterscore gpd action_gpd_cutoff efficient_gpd_cutoff if redflag==1

*------------------------------*

*9) Make distances to cutoffs

gen dist_high_med=.
gen dist_med_low=.

replace dist_high_med=gpd-action_gpd_cutoff if waterscore==2
replace dist_high_med=gpd-action_gpd_cutoff if waterscore==3

replace dist_med_low=gpd-efficient_gpd_cutoff if waterscore==2
replace dist_med_low=gpd-efficient_gpd_cutoff if waterscore==1

*bro residence_id gpd waterscore action_gpd_cutoff efficient_gpd_cutoff dist_med_low dist_high_med
*hist dist_high_med
*hist dist_med_low

*------------------------------*

*10) Generate dummy variables for each face

gen face_frown=.
gen face_neutral=.
gen face_smile=.

*FROWN
replace face_frown=0 if mailer!=. & send_timestamp!=. & section!="control" & waterscore==1
replace face_frown=0 if mailer!=. & send_timestamp!=. & section!="control" & waterscore==2
replace face_frown=1 if mailer!=. & send_timestamp!=. & section!="control" & waterscore==3

*NEUTRAL
replace face_neutral=0 if mailer!=. & send_timestamp!=. & section!="control" & waterscore==1
replace face_neutral=0 if mailer!=. & send_timestamp!=. & section!="control" & waterscore==3
replace face_neutral=1 if mailer!=. & send_timestamp!=. & section!="control" & waterscore==2

*SMILE
replace face_smile=0 if mailer!=. & send_timestamp!=. & section!="control" & waterscore==2
replace face_smile=0 if mailer!=. & send_timestamp!=. & section!="control" & waterscore==3
replace face_smile=1 if mailer!=. & send_timestamp!=. & section!="control" & waterscore==1

*------------------------------*

*11) Label variables

la var _merge1 "merge use and email reports"
la var mailer "1st,2nd...email received about water use"
la var mailermonth "month received the email"
la var maileryear "year received the email"
la var mailerday "day received the email"
la var next_readdate "the next readdate for the same resident_id"
la var next_gallons "the next month water use for the same resident_id"
la var next_gpd "next month gallons/day for the same resident id"
la var next_period_length "days until the next readdate"
la var next_flag "next water use weird or not (0 no 1 yes)"

la var next2_readdate "readdate two months from now"
la var next2_gpd "gpd two months from now"
la var next2_gallons "gallons of water used two months from now"
la var next2_period_length "typically another month"
la var next2_flag "weird or not"
la var redflag "abnormal water usage, weird"
la var dist_high_med "gpd - action_gpd_cutoff"
la var dist_med_low "gpd-efficient_gpd_cutoff"

la var face_frown "1 if receive mail,experimental,waterscore=3"
la var face_neutral "1 if receive mail,experimental,waterscore=2"
la var face_smile "1 if receive mail,experimental,waterscore=1"

*------------------------------*

* TO DO OR CHECK
* AS IS YOU DROPPED PRE EXPERIMENT DATA FOR ALL HOUSEHOLDS - MIGHT BE NICE TO HAVE THAT PUT BACK?
*LABEL VARIABLES (continue what I started above in #11)
sort residence_id readdate

*---------- Generate vars to help with analysis------------*

* Create some dummy vars
gen postexp = .
replace postexp = 1 if mailer>0 & mailer<7
//SB:Here is a problem: For people who are in the experimental group but missing emails
//this way of generating binary doesn't make sense. For the graphs, I just dropped those
//But there are lots of those!
replace postexp = 0 if missing(mailer) & section=="experimental"
*SB RESPONSE: DOES THIS EDIT ABOVE WORK?
//IRIS RE: Still the same problem as before. For example: br if residence_id==1338 (all obs for this id has postexp = 0, but this id is in the experimental group)

* Separating Pre/Post experimental months (Thanks to Prof. Bhanot)
* So yes, match on read_month. As for the weird lag, the data is what it is...
gen postcount=0
replace postcount=1 if nthreading==10 & nthreading_year==2014
replace postcount=1 if nthreading==11 & nthreading_year==2014
replace postcount=1 if nthreading==12 & nthreading_year==2014
replace postcount=1 if nthreading==1 & nthreading_year==2015
replace postcount=1 if nthreading==2 & nthreading_year==2015
bysort residence_id: egen totalpost=sum(postcount)

gen precount=0
replace precount=1 if nthreading==10 & nthreading_year==2013
replace precount=1 if nthreading==11 & nthreading_year==2013
replace precount=1 if nthreading==12 & nthreading_year==2013
replace precount=1 if nthreading==1 & nthreading_year==2014
replace precount=1 if nthreading==2 & nthreading_year==2014
bysort residence_id: egen totalpre=sum(precount)

*This will give you a sense of how many IDs have data for all pre and all post periods.
unique residence_id
unique residence_id if totalpre==5 & totalpost==5

* There was a problem with the original code...Here is a way to fix it, but it's
* Cubersome...Will change this when I think of a better way
preserve
*From here, it is easy to computer average pre and post GPD, using: 
bysort residence_id: egen mean_pre=mean(gpd_usedata) if precount==1
bysort residence_id: egen mean_post=mean(gpd_usedata) if postcount==1
keep residence_id mean_pre mean_post
duplicates drop
drop if missing(mean_pre) & missing(mean_post)
sort residence_id
replace mean_post = mean_post[_n+1] if residence_id==residence_id[_n+1]
drop if missing(mean_pre)
* Again, there are some missing mean_post still; same question as mentioned previously
* Unresolved
saveold "dallas_data/aux1.dta",replace
restore

merge m:1 residence_id using "dallas_data/aux1.dta"

*Then to get the difference:
gen changegpd=mean_post-mean_pre
label variable changegpd "gpd change computed as mean_post-mean_pre"

* Gen a 0/1 dummy for treatment
gen treatment = (section=="experimental")
label variable treatment "dummy for treatment"

* Gen some dummy for email opens
bysort residence_id: egen opens=sum(email_open)
gen atleast1_open = (opens>0)
gen atleast2_open = (opens>1)
gen atleast3_open = (opens>2)

saveold "dallas_data/cleaned_full_merged2.dta", replace

