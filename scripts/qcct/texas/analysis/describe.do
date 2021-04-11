//SETUP CODE
clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on

local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018
cd `projectpath'

log using `projectpath'/log/describe.txt, replace text

foreach area in HoustonMSA DallasMSA Texas {
	pe capture log close log_describe`area'
	pe log using `projectpath'/log/describe_`area'.txt, name(log`area') replace text
	pe use `projectpath'/data/texas/`area', clear
	pe count

	//COUNTS
	di "COUNTS"
		pe count
		pe count if balance_wt < 0
		pe count if balance_wt == 0

	//SUMMARIES
	di "SUMMARIES"
		pe sum balance_wt, detail
		pe sum balance_wt if balance_wt != 0, detail
		pe sum vantage_sc, detail
		pe sum vantage_sc if switcher_cohort==1, detail

	//TABULATIONS
	di "TABULATIONS"
		pe tab Month
		pe tab comment_cd, m
		pe tab comment_cd if comment_cd != "00", m
		pe tab estatus_cd, m
		pe tab estatus_cd if estatus_cd != "11", mi

	//CROSSTABS
	di "CROSSTABS"
		pe tab cohort, m
		pe tab no_decrease notcurrent_flag, m
		pe tab no_decrease delinquency_flag, m
		pe tab notcurrent_flag delinquency_flag, m
		pe tab Month pre_hurr_cohort, m
		pe tab first Month, m
		pe tab delinquency_flag notcurrent_flag, m

	//TABLES
	di "TABLES"
		pe table Month if balance_wt != 0, c(sum unique_acc_month sum unique_consumer_month)
		pe table Month if balance_wt != 0, c(mean vantage_sc median vantage_sc)
		pe table Month if balance_wt != 0, c(sum obs sum natural_disaster sum deferred_payment sum forbearance sum no_decrease)
		pe table Month if balance_wt != 0, c(sum delinquency_flag sum notcurrent_flag)
		pe table Month if balance_wt != 0, c(p50 balance_wt mean balance_wt sum balance_wt)
		pe table Month if pre_hurr_cohort==1, c(mean vantage_sc median vantage_sc)
		pe table Month if switcher_cohort==1, c(mean vantage_sc median vantage_sc)
		pe table Month if switcher_cohort!=1 & pre_hurr_cohort!=1 & balance_wt != 0, c(mean vantage_sc median vantage_sc)
		pe table cohort, c(p50 balance_wt mean balance_wt sum balance_wt sum obs)
		pe table loan_type, c(sum balance_wt p50 balance_wt mean balance_wt sum obs)
		pe table forbearance Month, c(p50 vantage_sc)
		pe table natural_disaster Month, c(p50 vantage_sc)
		pe table deferred_payment Month, c(p50 vantage_sc)
		pe table no_decrease Month, c(p50 vantage_sc)
		pe table cohort Month, c(sum obs)
		pe table cohort Month, c(p50 vantage_sc)
		pe table cohort Month, c(mean vantage_sc)
		pe table cohort Month, c(p50 balance_wt)
		pe table cohort Month, c(mean balance_wt)
		pe table cohort Month, c(sum delinquency_flag)
		pe preserve
		pe collapse (sum) cc_acc mort_acc stu_acc auto_acc other_debt_acc total_acc = obs, by(cohort months_aggregated)
		foreach acc in cc_acc mort_acc stu_acc auto_acc other_debt_acc {
			pe gen `acc'_pct = (`acc'/total_acc)*100
			pe replace `acc'_pct = round(`acc'_pct,.01)
		}
		pe table cohort, c(sum cc_acc_pct sum mort_acc_pct sum stu_acc_pct sum auto_acc_pct sum other_debt_acc_pct)
		pe table cohort months_aggregate, c(sum obs sum cc_acc_pct sum mort_acc_pct sum stu_acc_pct sum auto_acc_pct sum other_debt_acc_pct)
		pe restore

		pe gen no_payment = 1 if actualpayment_am == 0
		pe gen missing_payment = 1 if actualpayment_am == .
		pe table Month, c(sum missing_payment sum no_payment)


	//TABOUTS

	//TABEXCELS

	//MATRICES

	log close log_describe`area'

}
pe log close

//ARCHIVE

* table loan_type, c(min actualpayment_am p25 actualpayment_am p50 actualpayment_am p75 actualpayment_am max actualpayment_am)
* table loan_type, c(mean actualpayment_am)
* table Month, c(min actualpayment_am p25 actualpayment_am p50 actualpayment_am p75 actualpayment_am max actualpayment_am)
* table cohort, c(min actualpayment_am p25 actualpayment_am p50 actualpayment_am p75 actualpayment_am max actualpayment_am)
* table cohort Month, c(p50 actualpayment_am)

* tab Month switcher_cohort
* table Month if pre_hurr_cohort==1, c(mean vantage_sc median vantage_sc)
* table Month if switcher_cohort==1, c(mean vantage_sc median vantage_sc)
* table Month if balance_wt != 0, c(mean vantage_sc median vantage_sc)
* table cohort months_aggregate, c(sum obs sum cc_acc_pct sum mort_acc_pct sum stu_acc_pct sum auto_acc_pct sum other_debt_acc_pct)
