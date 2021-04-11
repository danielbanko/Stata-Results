clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on
local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018
log using `projectpath'/log/payments_made_jul_oct.txt, replace text
local CCPData /home/data/projects/Experian/ProcessedData/Stata
local ScoreVars consumer_nb vantage_sc deceased_cd
local TradeVars balance_dt consumer_nb ptk_nb kob_cd accounttype_cd balance_am balance_dt company_nb subscriber_nb estatus_cd condition_cd comment_cd ecoa_cd limit_am paymentgrid paymentgrid_cd open_dt actualpayment_am lastpayment_dt

/**

*read in geography file, 48201 = Harris County FIPS code, 48113 = Dallas County FIPS code:
// 	use consumer_nb tract using `CCPData'/geography.sample.sep2017.dta if inlist(floor(tract/1000000),48201,48113), clear
	use consumer_nb tract using `CCPData'/geography.sample.sep2017.dta if inlist(floor(tract/1000000),48201), clear
	format tract %16.0g
	gen county = floor(tract/1000000) 

*merge in score file:
	merge 1:m consumer_nb using `CCPData'/score.sample.sep2017.dta, keep(match) keepusing(`ScoreVars') nogen
	drop if deceased_cd==1
	drop deceased_cd
	drop if vantage_sc<300 | vantage_sc>850

	tempfile consumer_data
	save `consumer_data', replace

* merge in tradeline files:
	foreach year in 2016 2017	{
		foreach month in aug sep oct nov dec {
			use `consumer_data', clear
			gen ReportingPeriod = "`year'`month'"

			merge 1:m consumer_nb using `CCPData'/tradeline.sample.`month'`year'.dta, keep(match) keepusing(`TradeVars') nogen

		*Weight each observation based on its ecoa code:
			gen ecoa_wt = 1 if inlist(ecoa_cd,"0","1","X","A","H","W","I")
			replace ecoa_wt = 0.5 if inlist(ecoa_cd,"2","B","4","D","5","E")
			replace ecoa_wt = 0.5 if inlist(ecoa_cd,"6","F","7","G")
			replace ecoa_wt = 0 if inlist(ecoa_cd,"3","C","NA")

			bysort consumer_nb ptk_nb ReportingPeriod: gen dup = _N
			replace ecoa_wt=ecoa_wt/dup
			
			drop if ecoa_wt==0

		*Determine which accounts are open and have been reported in the last 6 months:
			gen numArchive_dt = mofd(date(ReportingPeriod, "YM"))
			format numArchive_dt %tm
			gen numReported_dt = mofd(balance_dt)
			format numReported_dt %tm

			gen periods_since_reported = numArchive_dt  - numReported_dt

			keep if upper(condition_cd)=="A1" & periods_since_reported <= 5
			drop numReported_dt numArchive_dt

		*Generate loan type code:
			get_loan_type accounttype_cd kob_cd

		*calculate total balances of different types:
			gen balance_wt = balance_am * ecoa_wt
			gen cc_debt = balance_wt if loan_type==200
			gen student_debt = balance_wt if loan_type==150
			gen auto_debt = balance_wt if loan_type==100
			gen mortgage_debt = balance_wt if loan_type==110
			gen HELOC_debt = balance_wt if inlist(loan_type,120,220)
			gen other_debt = balance_wt if !inlist(loan_type,200,150,100,110,120,220)

			tempfile cohort_`month'`year'
			save `cohort_`month'`year'', replace
		}
	}
	clear
	append using 	`cohort_aug2016'		///
					`cohort_sep2016'		///
					`cohort_oct2016'		///
					`cohort_aug2017'		///
					`cohort_sep2017'		///
					`cohort_oct2017'


	save `projectpath'/data/Houston_cohort_2017_2016.dta, replace
**/

use `projectpath'/data/Houston_cohort_2017.dta, clear
keep if inlist(loan_type, 150, 200, 110, 100)


bysort consumer_nb ptk_nb ReportingPeriod: gen flag = 1 if _N!=1
drop if flag==1
drop flag

reshape wide actualpayment_am balance_am balance_dt loan_type balance_wt other_debt comment_cd company_nb ecoa_cd estatus_cd kob_cd limit_am paymentgrid ecoa_wt dup periods_since_reported cc_debt student_debt auto_debt mortgage_debt HELOC_debt lastpayment_dt condition_cd status_cd, i(consumer_nb ptk_nb) j(ReportingPeriod, string)
//order loan_type2016sep loan_type2017sep paymentgrid2016sep paymentgrid2017sep actualpayment_am2016sep actualpayment_am2017sep diff, last

// bysort loan_type2016sep: egen sep2016total_bytype = sum(actualpayment_am2016sep)
// bysort loan_type2017sep: egen sep2017total_bytype = sum(actualpayment_am2017sep)
tab loan_type2017jul, missing
tab loan_type2017oct, missing
//tag accounts open in january
gen tag = 0
replace tag = 1 if balance_wt2017jan > 0 //has a positive balance amount in January...

tab tag, m

tab loan_type2017jul if tag == 1
tab loan_type2017oct if tag == 1

//tag accounts late in january
gen latetag = 1 if substr(paymentgrid2017jan,1,1) != "C" //...but was late on that payment
tab latetag, m

tab latetag tag, m
tab loan_type2017jul if latetag == 1
tab loan_type2017oct if latetag == 1

//store month of late payment date from July snapshot and count number of payments made in July.
gen lastpaymentJul = month(lastpayment_dt2017jul)
count if substr(paymentgrid2017jul,1,1)== "C"
count if balance_wt2017jul > 0
count if lastpaymentJul == 7
gen paidjul = 0
replace paidjul = 1 if balance_wt2017jul > 0 & month(lastpayment_dt2017jul) == 7 & substr(paymentgrid2017jul,1,1)=="C"
tab paidjul, m
//now do the same for October
gen lastpaymentOct = month(lastpayment_dt2017oct)
count if substr(paymentgrid2017oct,1,1)== "C"
count if balance_wt2017oct > 0

count if balance_wt2017oct > 0 & month(lastpayment_dt2017oct) == 10
gen paidoct = 0
replace paidoct = 1 if balance_wt2017oct > 0 & month(lastpayment_dt2017oct) == 10 & substr(paymentgrid2017oct,1,1)=="C"
tab paidoct, m
gen total = 1
//calculate the total number of payments made in July by loan type, if the loan existed in january 2017
//table loan_type2017jul if tag == 1, c(sum paidjul) //if the loan existed in January 2017

//calculate the total number of payments made in October by loan type, if the loan existed in january 2017
//table loan_type2017oct if tag == 1, c(sum paidoct)


table loan_type2017oct if tag == 1, c(sum paidjul sum paidoct sum tag) row

* ----------------------------------------------------
* 2017oct   |
* loan_type | sum(paidjul)  sum(paidoct)      sum(tag)
* ----------+-----------------------------------------
*       100 |         3061          3163         27840
*       110 |         3638          4814         16379
*       150 |         1030           897         35038
*       200 |        36630         30640         90956
*           | 
*     Total |        44359         39514        170213
* ----------------------------------------------------

graph bar (sum) paidjul paidoct if tag == 1, over(loan_type2017oct, relabel(1 "Auto loans" 2 "Mortgages" 3 "Student loans" 4 "Credit cards")) title("Cumulative impact of hurricanes on debt and bill payments") blabel(total, format(%4.0f)) ytitle(total payments made (count)) legend(order(1 "July" 2 "October"))
graph export `projectpath'/figures/houston_debt_and_bill_payments.png, replace
graph bar (sum) paidjul paidoct if tag == 1 & accounttype_cd == "26", title("Impact on mortgage payments (first-lien PPM and refinanced loans)") blabel(total, format(%4.0f)) ytitle(total payments made (count)) legend(order(1 "July" 2 "October"))
graph export `projectpath'/figures/houston_mortgage_payments_rate_2017.png, replace

gen refinancedjul = 1 if status_cd2017jul == "10"
gen refinancedoct = 1 if status_cd2017oct ==  "10"

graph bar (sum) refinancedjul refinancedoct if tag == 1, over(loan_type2017oct, relabel(1 "Auto loans" 2 "Mortgages" 3 "Student loans" 4 "Credit cards")) title("Hurricane impact on refinancing") blabel(total, format(%4.0f)) ytitle(total refinancing (count)) legend(order(1 "July" 2 "October"))
graph export `projectpath'/figures/houston_mortgage_refinancing.png, replace
graph bar (sum) refinancedjul refinancedoct if tag == 1 & accounttype_cd == "26", title("Impact on refinancing (first-lien PPM)") blabel(total, format(%4.0f)) ytitle(total refinancing (count)) legend(order(1 "July" 2 "October"))
graph export `projectpath'/figures/houston_PPM_refinancing.png, replace

gen paymentjul = actualpayment_am2017jul if paidjul == 1
gen paymentoct = actualpayment_am2017oct if paidoct == 1

graph bar (sum) paymentjul paymentoct if tag == 1, over(loan_type2017oct, relabel(1 "Auto loans" 2 "Mortgages" 3 "Student loans" 4 "Credit cards")) title("Total payments") blabel(total, format(%4.0f)) ytitle(Total payments made (sum)) legend(order(1 "July" 2 "October"))
graph export `projectpath'/figures/houston_total_bill_payments.png, replace
graph bar (sum) paymentjul paymentoct if tag == 1 & accounttype_cd == "26", title("Total payments (first-lien PPM)") blabel(total, format(%4.0f)) ytitle(Total payments made (sum)) legend(order(1 "July" 2 "October"))
graph export `projectpath'/figures/houston_total_PPM_payments.png, replace

tab accounttype_cd if loan_type2017oct ==110

//compare the number of payers in July and the number of payers in October...

//now look at mortgage payments, specifically first-lien PMM and refi...
