clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on

local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018

log using `projectpath'/log/prepare.txt, replace text

local CCPData /home/data/projects/Experian/ProcessedData/Stata
local GeoVars consumer_nb tract 
local ScoreVars consumer_nb vantage_sc deceased_cd
local TradeVars balance_dt consumer_nb ptk_nb kob_cd accounttype_cd balance_am balance_dt company_nb subscriber_nb estatus_cd condition_cd comment_cd ecoa_cd limit_am paymentgrid paymentgrid_cd open_dt actualpayment_am lastpayment_dt status_cd

//macros for selecting geographic area:
local Texas 	 inlist(floor(tract/1000000000),48)
local HoustonMSA inlist(floor(tract/1000000),48201,48157,48339,48039,48167,48291,48473,48071,48015)
local DallasMSA  inlist(floor(tract/1000000),48085,48113,48121,48139,48221,48231,48251,48257,48367,48397,48425,48439,48497)

foreach area in Texas HoustonMSA DallasMSA {
	*Read in geography file from September 2017
	*Append quarterly credit score data from subsequent quarters:
	foreach year in 2017 2018 { 
		if ("`year'"=="2017") local quarterlist mar jun sep dec
		if ("`year'"=="2018") local quarterlist mar
		foreach quarter in `quarterlist' { //score and geo data are quarterly:
			pe use consumer_nb tract using `CCPData'/geography.sample.sep2017.dta if ``area'', clear
			format tract %16.0g
			gen county = floor(tract/1000000)

			di "Merging `area' credit score data - `quarter' `year'"
			pe merge 1:m consumer_nb using `CCPData'/score.sample.`quarter'`year'.dta, keep(match) keepusing(`ScoreVars') nogen

			pe drop if deceased_cd==1
			pe drop deceased_cd
			pe drop if vantage_sc<300 | vantage_sc>850
			tempfile `area'_consumer_`quarter'`year'
			save ``area'_consumer_`quarter'`year''
		}
	}

	clear
	#delimit ;
	append using	``area'_consumer_mar2017'
					``area'_consumer_jun2017'
					``area'_consumer_sep2017'	
					``area'_consumer_dec2017'	
					``area'_consumer_mar2018', gen(vantage_quarter);
	#delim cr
*Incorporate credit score data from each quarter:
	reshape wide vantage_sc, i(consumer_nb) j(vantage_quarter)

	save `projectpath'/data/texas/`area'_consumer_scores, replace

*Merge in monthly tradeline data:
	foreach year in 2017 2018 {
		if ("`year'"=="2017") local monthlist apr may jun jul aug sep oct nov dec
		if ("`year'"=="2018") local monthlist jan feb mar apr
		foreach month in `monthlist' {
			pe use `projectpath'/data/texas/`area'_consumer_scores, clear
			gen ReportingPeriod = "`year'`month'"
			di "Merging `area' tradeline data - `month' `year'"
			pe merge 1:m consumer_nb using `CCPData'/tradeline.sample.`month'`year'.dta, keep(match) keepusing(`TradeVars') nogen

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

			tempfile `area'_cohort_`month'`year'
			save ``area'_cohort_`month'`year'', replace
		}
	}

	clear

	#delimit ;

	append using 	``area'_cohort_apr2017'
					``area'_cohort_may2017'
					``area'_cohort_jun2017'		
					``area'_cohort_jul2017'		
					``area'_cohort_aug2017'		
					``area'_cohort_sep2017'		
					``area'_cohort_oct2017'		
					``area'_cohort_nov2017'		
					``area'_cohort_dec2017'
					``area'_cohort_jan2018'
					``area'_cohort_feb2018'
					``area'_cohort_mar2018'
					``area'_cohort_apr2018';

	#delimit cr

	*Create ordered month variable:

		gen Month = .
		replace Month = 4 if ReportingPeriod == "2017apr"
		replace Month = 5 if ReportingPeriod == "2017may"
		replace Month = 6 if ReportingPeriod == "2017jun"
		replace Month = 7 if ReportingPeriod == "2017jul"
		replace Month = 8 if ReportingPeriod == "2017aug"
		replace Month = 9 if ReportingPeriod == "2017sep"
		replace Month = 10 if ReportingPeriod == "2017oct"
		replace Month = 11 if ReportingPeriod == "2017nov"
		replace Month = 12 if ReportingPeriod == "2017dec"
		replace Month = 13 if ReportingPeriod == "2018jan"
		replace Month = 14 if ReportingPeriod == "2018feb"
		replace Month = 15 if ReportingPeriod == "2018mar"
		replace Month = 16 if ReportingPeriod == "2018apr"

	save `projectpath'/data/texas/`area'.dta, replace
}

log close

shell echo -e "It's Done" | mail -s "STATA finished" "daniel.banko-ferran@cfpb.gov"


