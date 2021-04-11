//SETUP CODE
clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on

local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018
cd `projectpath'

log using `projectpath'/log/create_vars.txt, replace text


foreach area in HoustonMSA DallasMSA Texas {
	pe capture log close log`area'
	pe log using `projectpath'/log/create_vars_`area'.txt, name(log`area') replace text
	pe use `projectpath'/data/texas/`area', clear
	pe count

	pe drop  if balance_wt < 0 | balance_wt == .
	pe count if balance_wt > 0

	pe gen obs = 1

	di "GEN FLAG VARIABLES"
		pe gen deferred_payment = cond(comment_cd == "29",1,0,.)
		pe gen natural_disaster = cond(comment_cd == "54",1,0,.)
		pe gen forbearance = cond(comment_cd == "CP",1,0,.)
		pe gen delinquency_flag = 0
		pe replace delinquency_flag = 1 if inlist(estatus_cd,"71","72","73","74","75","76","77","78","79")
		pe replace delinquency_flag = 1 if inlist(estatus_cd,"80","81","82","83","84")
		pe replace delinquency_flag = 1 if inlist(estatus_cd,"22", "23", "24", "25", "26", "27", "28", "29")
		pe gen notcurrent_flag = cond(!inlist(substr(paymentgrid,1,1), "C","0"),1,0,.)
		pe gen positive_balance = cond(balance_wt != 0,1,0,.)

	di "CLOSED-END ACCOUNTS WITH NONDECREASING BALANCES"
		pe gen balance_ref = .
		pe gen diff = .
		foreach i in 4 5 6 7 8 9 10 11 12 13 14 15 { //i = month of year (>12 corresponds to month of year in 2018, ie 13 = jan 2018)
			pe replace balance_ref = balance_wt if Month == `i'
			pe bysort consumer_nb ptk_nb (balance_ref): replace balance_ref = balance_ref[1]
			pe replace diff = balance_wt - balance_ref if Month == `i' + 1
			pe replace balance_ref = .
		}
		pe gen no_decrease = .
		pe replace no_decrease = 0 if diff != . & balance_wt > 0 &  inlist(loan_type,100,110,120,130,140,150,220) 
		pe replace no_decrease = 1 if diff != . & diff >= 0 & balance_wt > 0 &  inlist(loan_type,100,110,120,130,140,150,220)

	di "GENERATE DEBT VARIABLES"
		pe gen cc_debt = balance_wt if loan_type==200
		pe gen student_debt = balance_wt if loan_type==150
		pe gen auto_debt = balance_wt if loan_type==100
		pe gen mortgage_debt = balance_wt if loan_type==110
		pe gen HELOC_debt = balance_wt if inlist(loan_type,120,220)
		pe gen other_debt = balance_wt if !inlist(loan_type,200,150,100,110,120,220)

	di "GENERATE ACCOUNT VARIABLES"
		pe gen cc_acc = cond(loan_type ==200,1,0,.)
		pe gen mort_acc = cond(loan_type==110,1,0,.)
		pe gen stu_acc = cond(loan_type==150,1,0,.)
		pe gen auto_acc = cond(loan_type==100,1,0,.)
		pe gen HELOC_acc = cond(inlist(loan_type,120,220),1,0,.)
		pe gen other_debt_acc = cond(!inlist(loan_type,200,150,100,110,120,220),1,0,.)

	di "GENERATE CREDIT SCORE VARIABLE"
		pe gen vantage_sc = .
		pe replace vantage_sc = vantage_sc1 if inlist(Month,3,4,5)
		pe replace vantage_sc = vantage_sc2 if inlist(Month,6,7,8)
		pe replace vantage_sc = vantage_sc3 if inlist(Month,9,10,11)
		pe replace vantage_sc = vantage_sc4 if inlist(Month,12,13,14)
		pe replace vantage_sc = vantage_sc5 if inlist(Month,15,16,17)
		pe drop vantage_sc1 vantage_sc2 vantage_sc3 vantage_sc4 vantage_sc5

	di "GENERATE TREATED AND UNTREATED COHORT VARIABLE (ONLY INCLUDE NONZERO BALANCE ACCOUNTS)"
		pe gen cohort = . 
		pe replace cohort = 0 if balance_wt != 0
		pe replace cohort = 1 if balance_wt != 0 & (cond(inlist(comment_cd,"29","54","CP"),1,0,.) | no_decrease == 1)
		pe replace cohort = . if Month == 4

	di "GENERATE PRE-HURRICANE SPECIAL COHORT VARIABLE"
		pe gen pre_hurr_special = cond(cohort==1 & inlist(Month,5,6,7,8),1,.)
		pe bysort ptk_nb (pre_hurr_special): replace pre_hurr_special = pre_hurr_special[1]

	di "GENERATE SWITCHER COHORT VARIABLE"
		pe gen switched = .
		pe gen cohort_ref = .

		foreach i in 4 5 6 7 8 9 10 11 12 13 14 15 {
			pe replace cohort_ref = cohort if Month == `i'
			pe bysort ptk_nb (cohort_ref): replace cohort_ref = cohort_ref[1]
			pe replace switched = 0 if Month == `i' + 1
			pe replace switched = 1 if Month == `i' + 1 & cohort == 1 & cohort_ref == 0
			pe replace switched = 1 if Month == `i' + 1 & cohort == 1 & cohort_ref == .
			pe replace cohort_ref = .
		}
		pe drop cohort_ref
		pe bysort ptk_nb (Month): gen byte first = sum(switched==1) == 1 & sum(switched[_n - 1] == 1) == 0 & Month == (Month[_n - 1] + 1)
		pe gen switcher_cohort = cond(first==1 & inlist(Month,9,10,11,12),1,.)
		pe bysort ptk_nb (switcher_cohort): replace switcher_cohort = switcher_cohort[1]

	di "GENERATE PRE-HURRICANE NON-SPECIAL COHORT VARIABLE"
		pe gen pre_hurr_nonspecial = cond(pre_hurr_special!=1 & switcher_cohort!=1 & balance_wt!=0 & inlist(Month,5,6,7,8),1,.)
		pe bysort ptk_nb (pre_hurr_nonspecial): replace pre_hurr_nonspecial = pre_hurr_nonspecial[1]
		
		pe assert((switcher_cohort==1 & (pre_hurr_special==1|pre_hurr_nonspecial==1)) != 1)
		pe assert((pre_hurr_special==1 & (switcher_cohort==1|pre_hurr_nonspecial==1)) != 1)
		pe assert((pre_hurr_nonspecial==1 & (switcher_cohort==1|pre_hurr_special==1)) != 1)
		pe sort consumer_nb ptk_nb Month	

	pe save `projectpath'/data/texas/`area'_genvars, replace

	log close log`area'
}

log close

//ARCHIVED VARIABLES
	* gen resolved_dispute = cond(comment_cd == "13",1,0,.)
	* gen current_dispute = cond(comment_cd == "78",1,0,.)
	* gen disagreed_resolved = cond(comment_cd == "20",1,0,.)
	* gen most_common_comments = cond(inlist(comment_cd,"29","54","CP"),1,0,.)
	* gen other_comments = cond(!inlist(comment_cd,"54", "29", "CP", "13","78","20","00"),1,0,.)
	* gen trouble_status = cond(inlist(estatus_cd,"05","10","20","42"),1,0,.)  //transferred, refinanced, credit line closed, redeemed/repossesed
	* gen time_diff = month(balance_dt) - month(lastpayment_dt) if year(balance_dt)==year(lastpayment_dt)
	* bysort ptk_nb: gen unique_acc = (_n==1)
	* bysort consumer_nb: gen unique_consumer = (_n==1)
	* bysort Month ptk_nb: gen unique_acc_month = (_n==1)
	* bysort Month consumer_nb: gen unique_consumer_month = (_n==1)
	* gen zero_flag = cond(balance_wt == 0,1,0,.)


	* di "GENERATE COHORT AGGREGATED VARIABLE (AGGREGATE FOR SEP/OCT/NOV)"
		* recode region 1/4=1 5 6 7 13=2 8/12=3 , gen(zone)
	* bysort year industry zone : egen tax_zones = total(tax)
		* pe gen cohort_aggregated=cond(cohort==1 & inlist(Month,9,10,11),1,0,.)
		* pe gen dup = 0

		* pe bysort ptk_nb: replace dup = _n if cohort_aggregated==1
		* pe replace cohort_aggregated=0 if dup > 1
		* pe drop dup
		* pe gen months_aggregated = Month
		* pe replace months_aggregated = 10 if inlist(Month,9,10,11)

