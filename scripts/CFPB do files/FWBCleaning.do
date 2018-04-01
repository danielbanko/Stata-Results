										///										///
capture log close
clear all
set more off
local projectpath "/home/cfpb/banko-ferrand/WriteUp4Journal/BankoFWBAnalysis/Analysis/"
cd `projectpath'
capture log using "FWBCleanedLog", replace
/*----------------------------------------------------------------*/
* Daniel Banko-Ferran - FWBCleaned.do                         		 		
* Examine FWB data for Soph Scale project 				 		  
* Data modified: Tues 19 Dec 2017						  		  
* Output saved in: "/home/cfpb/banko-ferrand/WriteUp4Journal/BankoFWBAnalysis/Analysis/" 
/*----------------------------------------------------------------*/

/******************* 1) SETUP 	**************************/
use "/home/data/restricted/fwb_natl_survey/CFPB Use File/30356-CFPB_client_170915.dta"
* Dropping all variables except measures of interest:
keep FWB* CONNECT SCFHORIZON DISCOUNT SELFCONTROL* SHOCKS* PROPPLAN* MANAGE* 	///
PPAGE PPINCIMP REJECTED_1 REJECTED_2 COLLECT SAVEHABIT ENDSMEET ABSORBSHOCK 	///
AUTOMATED* FRUGALITY ASK1_* FINSOC2* PPGENDER PPETHM PPEDUC PPEDUCAT PPMARIT 	///
PPWORK
drop FWB1_O* FWB2_O* PROPPLAN_O* SELFCONTROL_O* SHOCKS_O* MANAGE1_O* 		///
AUTOMATED_O* ASK1_O* FINSOC2_O*
* Defining local macros:
local PROP "PROPPLAN_1 PROPPLAN_2 PROPPLAN_3 PROPPLAN_4"
local MAN1 "MANAGE1_1 MANAGE1_2 MANAGE1_3 MANAGE1_4"
local SHOCK "SHOCKS_1 SHOCKS_2 SHOCKS_3 SHOCKS_4 SHOCKS_5 SHOCKS_6 SHOCKS_7 SHOCKS_8 SHOCKS_9 SHOCKS_10 SHOCKS_11"
local CONTROL "SELFCONTROL_1rev SELFCONTROL_2 SELFCONTROL_3"
local AUTOMATE "AUTOMATED_1 AUTOMATED_2"
local ASK "ASK1_1 ASK1_2"
local FINSOC "FINSOC2_1 FINSOC2_2 FINSOC2_3 FINSOC2_4 FINSOC2_5 FINSOC2_6 FINSOC2_7"
local catvList MANAGE2 REJECTED_1 REJECTED_2 COLLECT SCFHORIZON 		///
ENDSMEETrev SAVEHABIT ABSORBSHOCK AUTOMATED_1 AUTOMATED_2 FRUGALITY ASK1_2  	///
ASK1_1
local contvList FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC
label define recodeLab 1 "Never" 2 "Seldom" 3 "Sometimes" 4 "Often" 5 "Always"
label define recodeLab2 1 "Not at all" 2 "Not very well" 3 "Very well" 4 "Completely well"
label define recodeLab3 1 "Very difficult" 2 "Somewhat difficult" 3 "Not at all difficult"
* Defining programs:
program define recodeNA
	args var1
	replace `var1' = . if `var1' == 1
	foreach n of numlist 2/6 {
			quietly replace `var1' = `n'-1 if `var1' == `n'
	}
	label values `var1' recodeLab
end

/***************** 2)   	CLEANING	 ************************/
* Recoding if "Not applicable":
recodeNA MANAGE1_1
recodeNA MANAGE1_2
recodeNA MANAGE1_3
recodeNA MANAGE1_4
* Recoding "refused" as missing:
foreach var of varlist _all { 
	quietly replace `var' = . if `var' == -1 | `var' == -2
}
replace AUTOMATED_1 = . if AUTOMATED_1 == 7
replace AUTOMATED_2 = . if AUTOMATED_2 == 7
*Lot of participants did not have accounts which they could automate.

replace COLLECT = . if COLLECT == 8
replace ABSORBSHOCK = . if ABSORBSHOCK == 8
* Reversing order:
gen SELFCONTROL_1rev = 5 - SELFCONTROL_1
label values SELFCONTROL_1rev recodeLab2
egen totSHOCK = rowtotal(`SHOCK')
label variable totSHOCK "rowtotal(SHOCK)"
gen ENDSMEETrev = 4 - ENDSMEET
label values ENDSMEETrev recodeLab3
numlabel, add

/***************** 3)	 EXPLORATION	 **********************/
hist FWBscore, freq xlabel(56 "mean = 56", grid axis(0(10)100)) 	  	///	
ylabel(0(100)600, grid) scheme(cfpb) ///
 xtitle("Distribution of FWB score") normal
graph export "output/FWBscoredistribution.png", replace
foreach var of varlist _all {
	sum `var'
	tabulate `var', missing plot
}


* Checking for correlations among scale variables:
corr `PROP'
alpha `PROP', detail gen(avgPROP)
corr `MAN1'
alpha `MAN1', detail gen(avgMAN)
corr `MAN1'
alpha `MAN1' MANAGE2, detail
corr `CONTROL'
alpha `CONTROL', detail //not reliable
corr `AUTOMATE'
alpha `AUTOMATE', detail //not reliable
corr `FINSOC'
alpha `FINSOC', detail gen(avgFINSOC)
corr `ASK'
alpha `ASK', detail //not reliable

corr SAVEHABIT FRUGALITY
corr DISCOUNT AUTOMATED_1
corr `MAN1' SAVEHABIT
corr avgMAN SAVEHABIT
* Cronbach's alpha is a scale reliability measure that measures the consistency strength of a set of items. 
* It is computed by correlating the score for each item with the total score for each observation, and comparing that 
* to the variance for all individual team scores.
* Our threshold for relability in Cronbach's alpha is 0.7.  All scales except SELFCONTROL, AUTOMATED, and MANAGE1_# with MANAGE2 
* had an alpha greater than 0.7. Therefore, our SELFCONTROL items, AUTOMATED items, and MANAGE1_# items with MANAGE2 do not have
* sufficient inter-item consistency to be considered reliable measures, and I remove them from subsequent analyses. They do not hang together.

label variable avgPROP "rmean(PROP)"
label variable avgMAN "rmean(MAN1)"
label variable avgFINSOC "rmean(FINSOC)"

drop PPEDUCAT
* Create new dummy variables:
quietly gen SSChoice = 0 if DISCOUNT != . 
quietly replace SSChoice = 1 if DISCOUNT == 1
label variable SSChoice "=1 if DISCOUNT==1"
label define smallersooner 1 "Sooner, smaller reward" 0 "Later, larger reward" 
label values SSChoice smallersooner 
numlabel , add
quietly gen FEMALE = 0 if PPGENDER != .
quietly replace FEMALE = 1 if PPGENDER == 2
label variable FEMALE "=1 if PPGENDER==2"
gen AUTOMATEDDISCOUNT11 = 0 if AUTOMATED_1 != . & DISCOUNT != .
replace AUTOMATEDDISCOUNT11 = 1 if AUTOMATED_1 == 1 & DISCOUNT == 1
label variable AUTOMATEDDISCOUNT11 "=1 if AUTOMATED_1==1 & DISCOUNT==1"
gen AUTOMATEDDISCOUNT21 = 0 if AUTOMATED_2 != . & DISCOUNT != .
replace AUTOMATEDDISCOUNT21 = 1 if AUTOMATED_2 == 1 & DISCOUNT == 1
label variable AUTOMATEDDISCOUNT21 "=1 if AUTOMATED_2==1 & DISCOUNT==1"
label define FEMALE 1 "Female" 0 "Other" 
label values FEMALE FEMALE
label variable ENDSMEETrev "Difficulty of covering monthly expenses and bills"
label define ENDSMEETrev 1 "Very difficult" 2 "Somewhat difficult" 3 "Not at all difficult"
label values ENDSMEETrev ENDSMEETrev
label variable ABSORBSHOCK "How confident are you that you could come up with $2,000 in 30 days if an unexpected need arose within the next month?"
label define ABSORBSHOCK 1 "I am certain I could not come up with $2000" 2 "I could probably not come up with $2000" 3 "I could probably come up with $2000" 4 "I am certain I could come up with the full $2000" 
label values ABSORBSHOCK ABSORBSHOCK


save "output/30356-CFPB_client_170915_DB_Cleaned.dta", replace
capture log close
translate FWBCleanedLog.smcl FWBCleanedLog.pdf, replace
//must keep this blank
