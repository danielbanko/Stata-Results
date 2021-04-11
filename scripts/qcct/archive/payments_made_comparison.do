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

/**
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

			tempfile cohort_`month'`year'
			save `cohort_`month'`year'', replace
		}
	}
	clear
	append using 	`cohort_jun2017'		///
					`cohort_jul2017'		///
					`cohort_aug2017'		///
					`cohort_sep2017'		///
					`cohort_oct2017'		///
					`cohort_nov2017'		///
					`cohort_dec2017'


	save `projectpath'/data/Houston_payments_comparison_2017.dta, replace
**/
	log using `projectpath'/log/payments_made_comparison.txt, replace text
	* use `projectpath'/data/Houston_payments_comparison_2017.dta, clear
	use `projectpath'/data/harris_county_data_2017_2018, clear
	count

	bysort consumer_nb ReportingPeriod ptk_nb: gen duplicate_flag = (_n>1)
	tab duplicate_flag, mi
	drop if duplicate_flag==1
	drop duplicate_flag
	count
	//reshape long vantage_sc, i(consumer_nb ReportingPeriod ptk_nb) j(vantage_quarter)
	
	*create date variables:
	gen Year_last = year(lastpayment_dt)
	tab Year_last, mi
	gen Month_last = month(lastpayment_dt)
	tab Month_last, mi
	tab Month_last if Year_last == 2017, mi
	*create integer value of months:
	* gen Month = 6 if ReportingPeriod == "2017jun" 	
	* replace Month = 7 if ReportingPeriod == "2017jul"
	* replace Month = 8 if ReportingPeriod == "2017aug"
	* replace Month = 9 if ReportingPeriod == "2017sep"
	* replace Month = 10 if ReportingPeriod == "2017oct"
	* replace Month = 11 if ReportingPeriod == "2017nov"
	* replace Month = 12 if ReportingPeriod == "2017dec"
	tab Month, mi

	*convert ReportingPeriod to date format:
	gen ReportingPeriod2 = date(ReportingPeriod, "YM")
	drop ReportingPeriod
	gen ReportingPeriod = ReportingPeriod2
	format ReportingPeriod %td
	drop ReportingPeriod2
	tab ReportingPeriod, mi

	generate cc_debt = balance_wt if loan_type==200
	generate student_debt = balance_wt if loan_type==150
	generate auto_debt = balance_wt if loan_type==100
	generate mortgage_debt = balance_wt if loan_type==110
	generate HELOC_debt = balance_wt if inlist(loan_type,120,220)
	generate other_debt = balance_wt if !inlist(loan_type,200,150,100,110,120,220)

	//gen credit_utilization = balance_wt/limit_am*100 if balance_wt > 0 & inlist(loan_type,120,200,220,230,240) //what if limit_am is 0?
	sum balance_wt, detail
	sum cc_debt, detail
	sum student_debt, detail
	sum auto_debt, detail
	sum mortgage_debt, detail
	sum first_lien_debt, detail
	sum HELOC_debt, detail
	sum other_debt, detail
	gen credit_utilization = cc_debt/limit_am*100 if limit_am > 0
	sum credit_utilization, detail
	gen mortgage_utilization = mortgage_debt/limit_am*100 if limit_am > 0 //what if limit_am is 0?
	sum mortgage_utilization, detail

	*flags:
	gen over_limit_flag = 0
	replace over_limit_flag = 1 if balance_wt > limit_am
	tab over_limit_flag, mi
	gen payment_flag_2017 = cond(Year_last > 2016,1,0,.)
	tab payment_flag_2017 , mi
	gen delinquency_flag = 0
	replace delinquency_flag = 1 if inlist(estatus_cd,"71","72","73","74","75","76","77","78","79")
	replace delinquency_flag = 1 if inlist(estatus_cd,"80","81","82","83","84")
	tab delinquency_flag, mi
	* gen refinanced_mortgage_flag = 1 if status_cd == "10" & accounttype_cd == "26"
	* tab refinanced_mortgage_flag, mi

	bysort Month: sum balance_wt, detail
	bysort Month: sum actualpayment_am, detail
	bysort consumer_nb Month: gen tag = (_n==1)
	bysort Month: sum consumer_nb if tag==1, detail
	* gen vantage_group = (vantage_sc <= 660) + (vantage_sc <= 700) + (vantage_sc <= 740) + (vantage_sc <= 850)
	* replace vantage_group = . if vantage_group == 0
	sort consumer_nb Month ptk_nb //vantage_quarter
	order consumer_nb Month ptk_nb, first //vantage_quarter, first

	foreach var of varlist kob_cd accounttype_cd estatus_cd condition_cd comment_cd ecoa_cd status_cd {
		tab `var', mi
	}

	foreach var of varlist balance_dt balance_dt open_dt lastpayment_dt {
		sum `var', detail f
	}

	foreach var of varlist consumer_nb ptk_nb balance_wt company_nb subscriber_nb limit_am actualpayment_am {
		sum `var', detail
	}

	gen comment_tag = cond(!inlist(comment_cd,"","00"),1,0,.)
	gen deferred_payment = cond(comment_cd == "29",1,0,.)
	gen natural_disaster = cond(comment_cd == "54",1,0,.)
	gen resolved_dispute = cond(comment_cd == "13",1,0,.)
	gen forbearance = cond(comment_cd == "CP",1,0,.)
	gen current_dispute = cond(comment_cd == "78",1,0,.)
	gen disagreed_resolved = cond(comment_cd == "20",1,0,.)
	gen other_comment = cond(!inlist(comment_cd, "29","54", "13", "CP", "78","20","","00"),1,0,.)

	collapse (sum)	Total_comments = comment_tag deferred_payment natural_disaster resolved_dispute forbearance current_dispute disagreed_resolved other_comment if payment_flag_2017==1, by(Month vantage_group)
	foreach comment_code in deferred_payment natural_disaster resolved_dispute forbearance current_dispute disagreed_resolved other_comment {
		gen `comment_code'_pct = (`comment_code'/Total_comments)*100
	}
	graph bar deferred_payment natural_disaster resolved_dispute forbearance current_dispute disagreed_resolved other_comment, over(Month, relabel(1 "Jun" 2 "Jul" 3 "Aug" 4 "Sep" 5 "Oct" 6 "Nov" 7 "Dec")) stack title("Total comment codes in Houston") ytitle("Total comment codes") leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Resolved dispute" 4 "Forebearance" 5 "Current dispute" 6 "Disagreement" 7 "Other comment"))
	graph export `projectpath'/figures/comment_cd_total.png,replace
	graph bar deferred_payment_pct natural_disaster_pct resolved_dispute_pct forbearance_pct current_dispute_pct disagreed_resolved_pct other_comment_pct, over(Month, relabel(1 "Jun" 2 "Jul" 3 "Aug" 4 "Sep" 5 "Oct" 6 "Nov" 7 "Dec")) stack title("Percent of comment codes in Houston") ytitle("Total comment codes (%)") leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Resolved dispute" 4 "Forebearance" 5 "Current dispute" 6 "Disagreement" 7 "Other comment"))
	graph export `projectpath'/figures/comment_cd_percent.png,replace
	
	graph bar deferred_payment natural_disaster resolved_dispute forbearance current_dispute disagreed_resolved other_comment if vantage_group==1, over(Month, relabel(1 "Jun" 2 "Jul" 3 "Aug" 4 "Sep" 5 "Oct" 6 "Nov" 7 "Dec")) stack title("Total comment codes in Houston, credit score <660") ytitle("Total comment codes") leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Resolved dispute" 4 "Forebearance" 5 "Current dispute" 6 "Disagreement" 7 "Other comment"))
	graph export `projectpath'/figures/comment_cd_total_vs1.png,replace
	graph bar deferred_payment natural_disaster resolved_dispute forbearance current_dispute disagreed_resolved other_comment if vantage_group==2, over(Month, relabel(1 "Jun" 2 "Jul" 3 "Aug" 4 "Sep" 5 "Oct" 6 "Nov" 7 "Dec")) stack title("Total comment codes in Houston, credit score 661-700") ytitle("Total comment codes") leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Resolved dispute" 4 "Forebearance" 5 "Current dispute" 6 "Disagreement" 7 "Other comment"))
	graph export `projectpath'/figures/comment_cd_total_vs2.png,replace
	graph bar deferred_payment natural_disaster resolved_dispute forbearance current_dispute disagreed_resolved other_comment if vantage_group==3, over(Month, relabel(1 "Jun" 2 "Jul" 3 "Aug" 4 "Sep" 5 "Oct" 6 "Nov" 7 "Dec")) stack title("Total comment codes in Houston, credit score 701-740") ytitle("Total comment codes") leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Resolved dispute" 4 "Forebearance" 5 "Current dispute" 6 "Disagreement" 7 "Other comment"))
	graph export `projectpath'/figures/comment_cd_total_vs3.png,replace
	graph bar deferred_payment natural_disaster resolved_dispute forbearance current_dispute disagreed_resolved other_comment if vantage_group==4, over(Month, relabel(1 "Jun" 2 "Jul" 3 "Aug" 4 "Sep" 5 "Oct" 6 "Nov" 7 "Dec")) stack title("Total comment codes in Houston, credit score 741-850") ytitle("Total comment codes") leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Resolved dispute" 4 "Forebearance" 5 "Current dispute" 6 "Disagreement" 7 "Other comment"))
	graph export `projectpath'/figures/comment_cd_total_vs4.png,replace

	graph bar deferred_payment_pct natural_disaster_pct resolved_dispute_pct forbearance_pct current_dispute_pct disagreed_resolved_pct other_comment_pct if vantage_group==1, over(Month, relabel(1 "Jun" 2 "Jul" 3 "Aug" 4 "Sep" 5 "Oct" 6 "Nov" 7 "Dec")) stack title("Percent of comment codes in Houston, credit score <660") ytitle("Total comment codes (%)") leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Resolved dispute" 4 "Forebearance" 5 "Current dispute" 6 "Disagreement" 7 "Other comment"))
	graph export `projectpath'/figures/comment_cd_percent_vs1.png,replace
	graph bar deferred_payment_pct natural_disaster_pct resolved_dispute_pct forbearance_pct current_dispute_pct disagreed_resolved_pct other_comment_pct if vantage_group==2, over(Month, relabel(1 "Jun" 2 "Jul" 3 "Aug" 4 "Sep" 5 "Oct" 6 "Nov" 7 "Dec")) stack title("Percent of comment codes in Houston, credit score 661-700") ytitle("Total comment codes (%)") leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Resolved dispute" 4 "Forebearance" 5 "Current dispute" 6 "Disagreement" 7 "Other comment"))
	graph export `projectpath'/figures/comment_cd_percent_vs2.png,replace
	graph bar deferred_payment_pct natural_disaster_pct resolved_dispute_pct forbearance_pct current_dispute_pct disagreed_resolved_pct other_comment_pct if vantage_group==3, over(Month, relabel(1 "Jun" 2 "Jul" 3 "Aug" 4 "Sep" 5 "Oct" 6 "Nov" 7 "Dec")) stack title("Percent of comment codes in Houston, credit score 701-740") ytitle("Total comment codes (%)") leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Resolved dispute" 4 "Forebearance" 5 "Current dispute" 6 "Disagreement" 7 "Other comment"))
	graph export `projectpath'/figures/comment_cd_percent_vs3.png,replace
	graph bar deferred_payment_pct natural_disaster_pct resolved_dispute_pct forbearance_pct current_dispute_pct disagreed_resolved_pct other_comment_pct if vantage_group==4, over(Month, relabel(1 "Jun" 2 "Jul" 3 "Aug" 4 "Sep" 5 "Oct" 6 "Nov" 7 "Dec")) stack title("Percent of comment codes in Houston, credit score 741-850") ytitle("Total comment codes (%)") leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Resolved dispute" 4 "Forebearance" 5 "Current dispute" 6 "Disagreement" 7 "Other comment"))
	graph export `projectpath'/figures/comment_cd_percent_vs4.png,replace

	graph bar deferred_payment natural_disaster resolved_dispute forbearance current_dispute disagreed_resolved other_comment if Month==10, over(vantage_group, relabel(1 "<660" 2 "661-700" 3 "701-740" 4 "741-850")) stack title("Total comment codes in Oct 2017 Houston") ytitle("Total comment codes") leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Resolved dispute" 4 "Forebearance" 5 "Current dispute" 6 "Disagreement" 7 "Other comment"))
	graph export `projectpath'/figures/comment_cd_vantage_group.png,replace
	graph bar deferred_payment_pct natural_disaster_pct resolved_dispute_pct forbearance_pct current_dispute_pct disagreed_resolved_pct other_comment_pct if Month==10, over(vantage_group, relabel(1 "<660" 2 "661-700" 3 "701-740" 4 "741-850")) stack title("Percent of comment codes in Oct 2017 Houston") ytitle("Total comment codes (%)") leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Resolved dispute" 4 "Forebearance" 5 "Current dispute" 6 "Disagreement" 7 "Other comment"))
	graph export `projectpath'/figures/comment_cd_percent_vantage_group.png,replace

	gen diff = month(balance_dt) - month(lastpayment_dt) if year(balance_dt)==year(lastpayment_dt)
	drop if diff < 0

	gen flag_notcurrent = 1 if !inlist(substr(paymentgrid,1,1), "C","0") & diff == 0
	count if substr(paymentgrid,1,1)== "C" & diff == 0
	gen delinquency_dummy = 0

	replace delinquency_dummy = 1 if inlist(estatus_cd,"71","72","73","74","75","76","77","78","79")
	replace delinquency_dummy = 1 if inlist(estatus_cd,"80","81","82","83","84")
	replace delinquency_dummy = 1 if inlist(estatus_cd,"22", "23", "24", "25", "26")
	table Month, c(sum delinquency_dummy)
	table Month, c(sum flag_notcurrent)
	bysort Month: count if flag_notcurrent==1 //goes down
	tab delinquency_dummy flag_notcurrent, mi

	//collapse (sum) cc_debt, by(Month) //goes up
	gen cc_debt_millions = cc_debt/1000000
	format cc_debt_millions %16.2f
	log close

//shell echo -e "It's Done" | mail -s "STATA finished" "daniel.banko-ferran@cfpb.gov"
