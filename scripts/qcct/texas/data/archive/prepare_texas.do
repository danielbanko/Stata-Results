clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on

local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018
cd `projectpath'

log using `projectpath'/log/prepare_texas.txt, replace text

local CCPData /home/data/projects/Experian/ProcessedData/Stata
local ScoreVars consumer_nb vantage_sc deceased_cd
local TradeVars balance_dt consumer_nb ptk_nb kob_cd accounttype_cd balance_am balance_dt company_nb subscriber_nb estatus_cd condition_cd comment_cd ecoa_cd limit_am paymentgrid paymentgrid_cd open_dt actualpayment_am lastpayment_dt status_cd

*Read in geography file for Texas state from September (when hurricane struck)
*Append score file each quarter:
	foreach year in 2017 {
		foreach month in mar jun sep dec {
			use consumer_nb tract using `CCPData'/geography.sample.sep2017.dta if inlist(floor(tract/1000000000),48), clear
			format tract %16.0g
			gen county = floor(tract/1000000)
			merge 1:m consumer_nb using `CCPData'/score.sample.`month'`year'.dta, keep(match) keepusing(`ScoreVars') nogen
			
			drop if deceased_cd==1
			drop deceased_cd
			drop if vantage_sc<300 | vantage_sc>850
			tempfile texas_`month'`year'
			save `texas_`month'`year''
		}
	}
	foreach year in 2018 {
			foreach month in mar {
				use consumer_nb tract using `CCPData'/geography.sample.sep2017.dta if inlist(floor(tract/1000000000),48), clear
				format tract %16.0g
				gen county = floor(tract/1000000)
				merge 1:m consumer_nb using `CCPData'/score.sample.`month'`year'.dta, keep(match) keepusing(`ScoreVars') nogen
				
				drop if deceased_cd==1
				drop deceased_cd
				drop if vantage_sc<300 | vantage_sc>850
				tempfile texas_`month'`year'
				save `texas_`month'`year''
			}
		}		
	clear 
	append using	`texas_mar2017'	///
					`texas_jun2017'	///
					`texas_sep2017'	///
					`texas_dec2017'	///
					`texas_mar2018', gen(vantage_quarter)

*Combine credit score data:
	reshape wide vantage_sc, i(consumer_nb) j(vantage_quarter)
	save texas_consumer_scores, replace


*Merge in monthly tradeline data:
	foreach year in 2017 {
		foreach month in apr may jun jul aug sep oct nov dec { //tradeline data is monthly:
			use texas_consumer_scores, clear
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

		*Calculate total balance:
			gen balance_wt = balance_am * ecoa_wt

			tempfile t_cohort_`month'`year'
			save `t_cohort_`month'`year'', replace
		}
	}
	foreach year in 2018 {
		foreach month in jan feb mar apr { //tradeline data is monthly:
			use texas_consumer_scores, clear
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

		*Calculate total balance:
			gen balance_wt = balance_am * ecoa_wt

			tempfile t_cohort_`month'`year'
			save `t_cohort_`month'`year'', replace
		}
	}

	#delimit ;

	clear;

	append using 	`t_cohort_apr2017'
					`t_cohort_may2017'
					`t_cohort_jun2017'		
					`t_cohort_jul2017'		
					`t_cohort_aug2017'		
					`t_cohort_sep2017'		
					`t_cohort_oct2017'		
					`t_cohort_nov2017'		
					`t_cohort_dec2017'
					`t_cohort_jan2018'
					`t_cohort_feb2018'
					`t_cohort_mar2018'
					`t_cohort_apr2018';

*Create ordered month variable:
gen Month = .;
replace Month = 4 if ReportingPeriod == "2017apr";
replace Month = 5 if ReportingPeriod == "2017may";
replace Month = 6 if ReportingPeriod == "2017jun";
replace Month = 7 if ReportingPeriod == "2017jul";
replace Month = 8 if ReportingPeriod == "2017aug";
replace Month = 9 if ReportingPeriod == "2017sep";
replace Month = 10 if ReportingPeriod == "2017oct";
replace Month = 11 if ReportingPeriod == "2017nov";
replace Month = 12 if ReportingPeriod == "2017dec";
replace Month = 13 if ReportingPeriod == "2018jan";
replace Month = 14 if ReportingPeriod == "2018feb";
replace Month = 15 if ReportingPeriod == "2018mar";
replace Month = 16 if ReportingPeriod == "2018apr";

save `projectpath'/data/texas_data_2017_2018.dta, replace;

log close;
