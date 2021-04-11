cap log close
clear all
set more off
set trace off
set scheme cfpb
pause on
local projectpath 	/home/work/projects/Experian/Shared/ricksj/qcct_nov2018

log using `projectpath'/log/time_series_outcomes.txt, replace text

local CCPData 		/home/data/projects/Experian/ProcessedData/Stata
local TradeVars 	balance_dt consumer_nb ptk_nb kob_cd accounttype_cd balance_am balance_dt company_nb subscriber_nb estatus_cd condition_cd comment_cd ecoa_cd limit_am paymentgrid paymentgrid_cd open_dt
local ScoreVars 	consumer_nb vantage_sc deceased_cd

/**/
*read in geography file, 48=texas state code:
	use consumer_nb tract using `CCPData'/geography.sample.jun2017.dta if floor(tract/1000000000) == 48, clear
	format tract %16.0g
	gen county = floor(tract/1000000) 

*merge in score file:
	merge 1:m consumer_nb using `CCPData'/score.sample.jun2017.dta, keep(match) keepusing(`ScoreVars') nogen
	drop if deceased_cd==1
	drop deceased_cd
	drop if vantage_sc<300 | vantage_sc>850

	tempfile consumer_data
	save `consumer_data', replace
	
* merge in tradeline data from 2017:
foreach month in jan feb mar apr may jun jul aug sep oct nov dec {
	use consumer_nb using `consumer_data', clear
	gen ReportingPeriod = "2017`month'"
	
* merge in tradeline file:
	merge 1:m consumer_nb using `CCPData'/tradeline.sample.`month'2017.dta, keep(match) keepusing(`TradeVars') nogen

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

tempfile cohort_`month'2017
save `cohort_`month'2017', replace
}
clear
append using 	`cohort_jan2017' 	///
		`cohort_feb2017' 			///
		`cohort_mar2017' 			///
		`cohort_apr2017'			///
		`cohort_may2017'			///
		`cohort_jun2017'			///
		`cohort_jul2017'			///
		`cohort_aug2017'			///
		`cohort_sep2017'			///
		`cohort_oct2017'			///
		`cohort_nov2017'			///
		`cohort_dec2017'

save `projectpath'/data/texas_cohort_2017.dta, replace
**/
/**
use `projectpath'/data/texas_cohort_2017.dta, clear

tab loan_type

gen Month = month(date(substr(ReportingPeriod,5,3),"M"))
gen flagged = 0
replace flagged = 1 if  balance_wt > limit_am
gen credit_utilization = balance_wt/limit_am*100 if balance_wt > 0 & inlist(loan_type,120,200,220,230,240)
gen delinquency_dummy = 0
replace delinquency_dummy = 1 if inlist(estatus_cd,"71","72","73","74","75","76","77","78","79")
replace delinquency_dummy = 1 if inlist(estatus_cd,"80","81","82","83","84")

egen tag = tag(Month)
egen mean = mean(credit_utilization) if loan_type == 200, by(Month)

* graph twoway connected 																					///
* 		mean																							///
* 		Month 																							///
* 		if tag, 																						///
* 		sort(Month)																						///
* 		title("Average credit card utilization in 2017")												///
* 		ytitle("Average credit card utilization (%)", size(medium))										///
* 		xtitle("Month") 																				///
* 		xline(8)																						///
* 		xla(8 "Hurricane Harvey")												///
* 		xtick(1(1)12)																					///
* 		ytick(0(20)100)

foreach outcome in credit_utilization vantage_sc delinquency_dummy {
	if "`outcome'" == "credit_utilization" {
			tempvar mean
			egen `mean' = mean(`outcome') if loan_type == `type', by(Month)
			if "`type'" == "200" {
			scatter `mean' Month if tag, 
					connect(direct) 
					sort(Month) 
					title("Average credit card utilization in 2017")
					ytitle("Average credit card utilization (%)") 
					ysc(r(0 100)) 
					xline(8) 
					xla(1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec") 
					xtick(1(1)12)
					ylabel(0(10)100) 
					ymtick(#100)
			}
		}
	} 
	else {
		tempvar mean
		egen `mean' = mean(`outcome'), by(Month)
		scatter `mean' Month if tag, 
			connect(direct) 
			sort(Month) 
			title("Average credit card utilization in 2017")
			ytitle("Average credit card utilization (%)") 
			ysc(r(0 100)) 
			xline(8) 
			xla(1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec") 
			xtick(1(1)12)
			ylabel(0(10)100) 
			ymtick(#100)
		drop mean
	}


graph export `projectpath'/figures/credit_card_utilization_2017.png, replace
}
}

egen mean2 = mean(credit_utilization) if loan_type == 110, by(Month)

scatter mean Month if tag, connect(direct) sort(Month) title("Average mortgage utilization in 2017") ytitle("Average credit card utilization (%)") ysc(r(0 100)) xline(8) xla(1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec") xtick(1(1)12) ylabel(0(10)100) ymtick(#100)
graph export `projectpath'/figures/mortgage_utilization_2017.png, replace


scatter mean Month if tag, connect(direct) sort(Month) title("Average credit card utilization in 2017") ytitle("Average credit card utilization (%)") ysc(r(0 100)) xli
ne(8) xla(1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec") xtick(1(1)12) ylabel(0(10)100) ymtick(#100)


egen mean3 = mean(vantage_sc), by(Month)

egen mean4 = mean(delinquency_dummy), by(Month)
**/
log close
