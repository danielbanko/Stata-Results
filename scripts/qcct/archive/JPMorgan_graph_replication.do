clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on
local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018
log using `projectpath'/log/JPMorgan_graph_replication.txt, replace text
local CCPData /home/data/projects/Experian/ProcessedData/Stata
local ScoreVars consumer_nb vantage_sc deceased_cd
local TradeVars balance_dt consumer_nb ptk_nb kob_cd accounttype_cd balance_am balance_dt company_nb subscriber_nb estatus_cd condition_cd comment_cd ecoa_cd limit_am paymentgrid paymentgrid_cd open_dt actualpayment_am lastpayment_dt

/***

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
			save `cohort_`month'`year', replace
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

use `projectpath'/data/Houston_cohort_2017_2016.dta, clear
keep if inlist(loan_type, 150, 200, 110, 100)

bysort consumer_nb ptk_nb ReportingPeriod: gen flag = 1 if _N!=1
drop if flag==1
drop flag

reshape wide actualpayment_am balance_am balance_dt loan_type balance_wt other_debt comment_cd company_nb ecoa_cd estatus_cd kob_cd limit_am paymentgrid ecoa_wt dup periods_since_reported cc_debt student_debt auto_debt mortgage_debt HELOC_debt lastpayment_dt, i(consumer_nb ptk_nb) j(ReportingPeriod, string)
//order loan_type2016sep loan_type2017sep paymentgrid2016sep paymentgrid2017sep actualpayment_am2016sep actualpayment_am2017sep diff, last

// bysort loan_type2016sep: egen sep2016total_bytype = sum(actualpayment_am2016sep)
// bysort loan_type2017sep: egen sep2017total_bytype = sum(actualpayment_am2017sep)
//graph 1:
gen late2016sep = 1 if substr(paymentgrid2016sep,1,1)=="1"
gen late2017sep = 1 if substr(paymentgrid2017sep,1,1)=="1"
gen late2016oct = 1 if substr(paymentgrid2016oct,1,1)=="1"
gen late2017oct = 1 if substr(paymentgrid2017oct,1,1)=="1"
gen late2016nov = 1 if substr(paymentgrid2016nov,1,1)=="1"
gen late2017nov = 1 if substr(paymentgrid2017nov,1,1)=="1"
gen late2016dec = 1 if substr(paymentgrid2016dec,1,1)=="1"
gen late2017dec = 1 if substr(paymentgrid2017dec,1,1)=="1"

replace late2016sep = 0 if substr(paymentgrid2016sep,1,1)=="C"
replace late2017sep = 0 if substr(paymentgrid2017sep,1,1)=="C"
replace late2016oct = 0 if substr(paymentgrid2016oct,1,1)=="C"
replace late2017oct = 0 if substr(paymentgrid2017oct,1,1)=="C"
replace late2016nov = 0 if substr(paymentgrid2016nov,1,1)=="C"
replace late2017nov = 0 if substr(paymentgrid2017nov,1,1)=="C"
replace late2016dec = 0 if substr(paymentgrid2016dec,1,1)=="C"
replace late2017dec = 0 if substr(paymentgrid2017dec,1,1)=="C"

gen presentsep2016 = 1 if late2016sep==0
gen presentsep2017 = 1 if late2017sep==0
gen presentoct2016 = 1 if late2016oct==0
gen presentoct2017 = 1 if late2017oct==0
gen presentnov2016 = 1 if late2016nov==0
gen presentnov2017 = 1 if late2017nov==0
gen presentdec2016 = 1 if late2016dec==0
gen presentdec2017 = 1 if late2017dec==0

bys loan_type2016sep: egen total_payment_2016_sep = sum(actualpayment_am2016sep) if presentsep2016==1 //If payment was made in september 2016, sum them by loan type...
bys loan_type2017sep: egen total_payment_2017_sep = sum(actualpayment_am2017sep) if presentsep2017==1 //...and for september 2017...
bys loan_type2017sep: gen total_diff = total_payment_2017_sep - total_payment_2016_sep	//...and then calculate difference
//table loan_type2017sep, c(mean total_diff)
bys loan_type2017sep: gen percent_deviation = 100*(total_diff/total_payment_2016_sep) //calculate percent difference of the difference over the "baseline period"
table loan_type2017sep, c(mean percent_deviation)
graph bar (mean) percent_deviation, over(loan_type2017sep, relabel(1 "Auto loans" 2 "Mortgages" 3 "Student loans" 4 "Credit cards")) title("Percent deviation of bill and debt payments from baseline") blabel(total, format(%4.2f)) ytitle("Percent deviation")
graph export `projectpath'/figures/JPMorgan_graph1_replicated.png, replace

//graph 2:
gen first_delinquent = .
replace first_delinquent = 1 if estatus_cd2017sep == "71" //missed a payment for first time in sep 2017

bys loan_type2016sep: egen total_present_payers_2016 = sum(presentsep2016)
bys loan_type2017sep: egen total_present_payers_2017 = sum(presentsep2017)
bys loan_type2016sep: egen total_late_payers_2016 = sum(late2016sep)
bys loan_type2017sep: egen total_late_payers_2017 = sum(late2017sep)
replace total_present_payers_2016 = 0 if missing(total_present_payers_2016)
replace total_present_payers_2017 = 0 if missing(total_present_payers_2017)
replace total_late_payers_2016 = 0 if missing(total_late_payers_2016)
replace total_late_payers_2017 = 0 if missing(total_late_payers_2017)

* gen 2017total = total_present_payers_2017 + total_late_payers_2017
* gen 2017_proportion = total_present_payers_2017/2017total

* gen 2016total = total_present_payers_2016 + total_late_payers_2016
* gen 2016_proportion = total_present_payers_2016/2016total

gen present_payers_diff = total_present_payers_2017 - total_present_payers_2016 if total_present_payers_2016>0 & total_present_payers_2017>0
gen percent_deviation_present = 100*(present_payers_diff/total_present_payers_2016)

table loan_type2017sep, c(mean percent_deviation_present)

* bysort loan_type2016sep: egen conditionalpayment_sep2016 = median(actualpayment_am2016sep) if !missing(actualpayment_am2016sep, actualpayment_am2017sep) & presentsep2016 == 1
* bysort loan_type2017sep: egen conditionalpayment_sep2017 = median(actualpayment_am2017sep) if !missing(actualpayment_am2016sep, actualpayment_am2017sep) & presentsep2017 == 1
* gen total_diff_conditional = conditionalpayment_sep2017 - conditionalpayment_sep2016 if !missing(conditionalpayment_sep2016, conditionalpayment_sep2017)
* table loan_type2016sep, c(mean conditionalpayment_sep2016)
* table loan_type2017sep, c(mean total_diff_conditional)

gen diff = actualpayment_am2017sep - actualpayment_am2016sep if !missing(actualpayment_am2016sep, actualpayment_am2017sep) & presentsep2016 == 1 & presentsep2017 == 1
label variable diff "2017sep - 2016sep payment amount"
sum diff, detail
bysort loan_type2017sep: egen total_diff_conditional = sum(diff)
bys loan_type2017sep: gen conditional_payment_deviation = 100*(total_diff_conditional/total_payment_2016_sep)

graph bar (mean)  percent_deviation_present conditional_payment_deviation, over(loan_type2017sep, relabel(1 "Auto loans" 2 "Mortgages" 3 "Student loans" 4 "Credit cards")) title("Decomposition of debt and bill payments") blabel(total, format(%4.2f)) legend(order(1 "Deviation in number of payers" 2 "Deviation in conditional payment"))
graph export `projectpath'/figures/JPMorgan_graph2_replicated.png, replace

drop total_payment_2016_sep
drop total_payment_2017_sep
//graph 3:
foreach month in sep oct nov dec {
	bys loan_type2016`month': egen total_payment_2016_`month' = sum(actualpayment_am2016`month') if present`month'2016==1
	bys loan_type2017`month': egen total_payment_2017_`month' = sum(actualpayment_am2017`month') if present`month'2017==1
	bys loan_type2017`month': gen total_diff_`month' = total_payment_2017_`month' - total_payment_2016_`month'
	bys loan_type2017`month': gen percent_deviation_`month' = 100*(total_diff_`month'/total_payment_2016_`month')
}


graph bar percent_deviation_sep percent_deviation_oct percent_deviation_nov percent_deviation_dec, over(loan_type2017dec, relabel(1 "Auto loans" 2 "Mortgages" 3 "Student loans" 4 "Credit cards")) title("Cumulative impact of hurricanes on debt and bill payments") blabel(total, format(%4.2f)) ytitle(Deviation from baseline (%)) legend(order(1 "September" 2 "October" 3 "November" 4 "December"))
graph export `projectpath'/figures/JPMorgan_replicated_graph3.png, replace

