clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on

local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018
cd `projectpath'

local CCPData /home/data/projects/Experian/ProcessedData/Stata
local ScoreVars consumer_nb vantage_sc deceased_cd
local TradeVars balance_dt consumer_nb ptk_nb kob_cd accounttype_cd balance_am balance_dt company_nb subscriber_nb estatus_cd condition_cd comment_cd ecoa_cd limit_am paymentgrid paymentgrid_cd open_dt actualpayment_am lastpayment_dt status_cd

*read in geography file, 48201 = Harris County FIPS code, 48113 = Dallas County FIPS code:
*use consumer_nb tract using `CCPData'/geography.sample.sep2017.dta if inlist(floor(tract/1000000),48201,48113), clear
*append score file over time to develop list of consumers in cohort:
	foreach year in 2017 {
		foreach month in mar jun sep dec { //score data is quarterly:
			use consumer_nb tract using `CCPData'/geography.sample.sep2017.dta if inlist(floor(tract/1000000),48201), clear
			format tract %16.0g
			gen county = floor(tract/1000000)
			merge 1:m consumer_nb using `CCPData'/score.sample.`month'`year'.dta, keep(match) keepusing(`ScoreVars') nogen
			//append using `CCPData'/score.sample.`month'`year'.dta, keep(`ScoreVars') 
			
			drop if deceased_cd==1
			drop deceased_cd
			drop if vantage_sc<300 | vantage_sc>850
			tempfile consumer_`month'`year'
			save `consumer_`month'`year''
		}
	}		
	clear 
	append using	`consumer_mar2017'	///
					`consumer_jun2017'	///
					`consumer_sep2017'	///
					`consumer_dec2017', gen(vantage_quarter)

	reshape wide vantage_sc, i(consumer_nb) j(vantage_quarter)
	save consumer_scores, replace


* merge in tradeline files:
	foreach year in 2017 {
		foreach month in jun jul aug sep oct nov dec { //tradeline data is monthly:
			use consumer_scores, clear
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
			drop dup

		*Determine which accounts are open and have been reported in the last 6 months:
			gen numArchive_dt = mofd(date(ReportingPeriod, "YM"))
			format numArchive_dt %tm
			gen numReported_dt = mofd(balance_dt)
			format numReported_dt %tm

			gen periods_since_reported = numArchive_dt - numReported_dt

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
			gen first_lien_debt = balance_wt if accounttype_cd == "26" //we want to use accounttype_cd == "26" instead of loan_type because restricts to PPM and first-lien mortgage only
			gen HELOC_debt = balance_wt if inlist(loan_type,120,220)
			gen other_debt = balance_wt if !inlist(loan_type,200,150,100,110,120,220)

			tempfile cohort2_`month'`year'
			save `cohort2_`month'`year'', replace
		}
	}
	clear
	append using 	`cohort_jun2016'		///
					`cohort_jul2016'		///
					`cohort_aug2016'		///
					`cohort_sep2016'		///
					`cohort_oct2016'		///
					`cohort_nov2016'		///
					`cohort_dec2016'		///	
					`cohort_jun2017'		///
					`cohort_jul2017'		///
					`cohort_aug2017'		///
					`cohort_sep2017'		///
					`cohort_oct2017'		///
					`cohort_nov2017'		///
					`cohort_dec2017'


	save `projectpath'/data/Houston_payments_comparison_2016_2017.dta, replace
