//SETUP CODE
clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on

local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018
cd `projectpath'

log using `projectpath'/log/harris_MSA_data_2017_2018.txt, replace text

use `projectpath'/data/harris_MSA_data_2017_2018_genvars, clear

//Descriptive Statistics

//SUMMARIES
* sum vantage_sc if switcher_cohort==1, detail

//TABULATIONS
		* tab comment_cd, m
		* tab comment_cd if comment_cd != "00", m

		* tab estatus_cd, m
		* tab estatus_cd if estatus_cd != "11", mi

//CROSSTABS
	* tab no_decrease notcurrent_flag, m
	* tab no_decrease delinquency_flag, m
	* tab no_decrease most_common_comments_cd, m
	* tab notcurrent_flag delinquency_flag, m
	* tab notcurrent_flag most_common_comments_cd, m
	* tab delinquency_flag most_common_comments_cd, m
	* tab Month pre_hurr_cohort
	* tab first Month
	* tab cohort, m

//TABLES
	* table Month if balance_wt != 0, c(sum unique_acc_month sum unique_consumer_month)
	* table Month if balance_wt != 0, c(mean vantage_sc median vantage_sc)
	* table Month if balance_wt != 0, c(sum obs sum natural_disaster sum deferred_payment sum forbearance sum no_decrease)
	* table Month if balance_wt != 0, c(sum delinquency_flag sum notcurrent_flag) 	 	//falls significantly in september.
	* table Month if balance_wt != 0, c(p50 balance_wt mean balance_wt sum balance_wt)
	* table Month if pre_hurr_cohort==1, c(mean vantage_sc median vantage_sc)
	* table Month if switcher_cohort==1, c(mean vantage_sc median vantage_sc)
	* table Month if switcher_cohort!=1 & pre_hurr_cohort!=1 & balance_wt != 0, c(mean vantage_sc median vantage_sc)
	* table cohort, c(p50 balance_wt mean balance_wt sum balance_wt sum obs)
	* table loan_type, c(sum balance_wt p50 balance_wt mean balance_wt sum obs)
	* table forbearance Month, c(p50 vantage_sc)
	* table natural_disaster Month, c(p50 vantage_sc)
	* table deferred_payment Month, c(p50 vantage_sc)
	* table no_decrease Month, c(p50 vantage_sc)
	* table cohort Month, c(sum obs)
	* table cohort Month, c(p50 vantage_sc)
	* table cohort Month, c(mean vantage_sc)
	* table cohort Month, c(p50 balance_wt)
	* table cohort Month, c(mean balance_wt)
	* table cohort Month, c(sum delinquency_flag)


* preserve
* collapse (sum) cc_acc mort_acc stu_acc auto_acc other_debt_acc total_acc = obs, by(cohort months_aggregated)
* foreach acc in cc_acc mort_acc stu_acc auto_acc other_debt_acc {
* 	gen `acc'_pct = (`acc'/total_acc)*100
* 	replace `acc'_pct = round(`acc'_pct,.01)
* }
* table cohort, c(sum cc_acc_pct sum mort_acc_pct sum stu_acc_pct sum auto_acc_pct sum other_debt_acc_pct)
* table cohort months_aggregate, c(sum cc_acc_pct sum mort_acc_pct sum stu_acc_pct sum auto_acc_pct sum other_debt_acc_pct)
* restore

log close;
