//SETUP CODE
clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on

local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018
cd `projectpath'

log using `projectpath'/log/gen_vars.txt, replace text
use `projectpath'/data/harris_MSA_data_2017_2018, clear
count
count if balance_wt > 0
drop if balance_wt < 0

bysort ptk_nb: gen unique_acc = (_n==1)
bysort consumer_nb: gen unique_consumer = (_n==1)
bysort Month ptk_nb: gen unique_acc_month = (_n==1)
bysort Month consumer_nb: gen unique_consumer_month = (_n==1)
gen obs = 1

//GEN FLAG VARIABLES
	gen deferred_payment = cond(comment_cd == "29",1,0,.)
	gen natural_disaster = cond(comment_cd == "54",1,0,.)
	gen forbearance = cond(comment_cd == "CP",1,0,.)
	gen delinquency_flag = 0
	replace delinquency_flag = 1 if inlist(estatus_cd,"71","72","73","74","75","76","77","78","79")
	replace delinquency_flag = 1 if inlist(estatus_cd,"80","81","82","83","84")
	replace delinquency_flag = 1 if inlist(estatus_cd,"22", "23", "24", "25", "26", "27", "28", "29")
	gen notcurrent_flag = cond(!inlist(substr(paymentgrid,1,1), "C","0"),1,0,.)

//NONDECREASING BALANCE AMOUNTS ON CLOSED-END ACCOUNTS (Auto loan, student loan, mortage loan, personal loan, retail loan, HELOC)
	gen balance_ref = .
	gen diff = .
	foreach i in 4 5 6 7 8 9 10 11 12 13 14 15 {
		replace balance_ref = balance_wt if Month == `i'
		bysort consumer_nb ptk_nb (balance_ref): replace balance_ref = balance_ref[1]
		sort consumer_nb ptk_nb Month
		replace diff = balance_wt - balance_ref if Month == `i' + 1
		replace balance_ref = .
	}
	gen no_decrease = .
	replace no_decrease = 0 if diff != . & balance_wt > 0 &  inlist(loan_type,100,110,120,130,140,150,220) 
	replace no_decrease = 1 if diff >= 0 & balance_wt > 0 &  inlist(loan_type,100,110,120,130,140,150,220)

	tab no_decrease, m
	tab notcurrent_flag, m
	tab delinquency_flag notcurrent_flag, m
	count if delinquency_flag == 0 & notcurrent_flag == 1

//ARCHIVED VARIABLES:
	* gen resolved_dispute = cond(comment_cd == "13",1,0,.)
	* gen current_dispute = cond(comment_cd == "78",1,0,.)
	* gen disagreed_resolved = cond(comment_cd == "20",1,0,.)
	* gen most_common_comments = cond(inlist(comment_cd,"29","54","CP"),1,0,.)
	* gen other_comments = cond(!inlist(comment_cd,"54", "29", "CP", "13","78","20","00"),1,0,.)
	* gen trouble_status = cond(inlist(estatus_cd,"05","10","20","42"),1,0,.)  //transferred, refinanced, credit line closed, redeemed/repossesed
	* gen time_diff = month(balance_dt) - month(lastpayment_dt) if year(balance_dt)==year(lastpayment_dt)

//GENERATE DEBT VARIABLES
	generate cc_debt = balance_wt if loan_type==200
	generate student_debt = balance_wt if loan_type==150
	generate auto_debt = balance_wt if loan_type==100
	generate mortgage_debt = balance_wt if loan_type==110
	generate HELOC_debt = balance_wt if inlist(loan_type,120,220)
	generate other_debt = balance_wt if !inlist(loan_type,200,150,100,110,120,220)

//GENERATE CREDIT SCORE VARIABLE
	gen vantage_sc = .
	replace vantage_sc = vantage_sc1 if inlist(Month,3,4,5)
	replace vantage_sc = vantage_sc2 if inlist(Month,6,7,8)
	replace vantage_sc = vantage_sc3 if inlist(Month,9,10,11)
	replace vantage_sc = vantage_sc4 if inlist(Month,12,13,14)
	replace vantage_sc = vantage_sc5 if inlist(Month,15,16,17)
	drop vantage_sc1 vantage_sc2 vantage_sc3 vantage_sc4 vantage_sc5

//GENERATE TREATED AND UNTREATED COHORT VARIABLE: 
* both cohorts only consist of positive balance amount accounts.
* cohort = 1 if payment deferred, natural disaster, acount in forbearance, closed-end credit account balance non-decreasing
	gen cohort = . 
	replace cohort = 0 if balance_wt > 0
	replace cohort = 1 if balance_wt > 0 & (cond(inlist(comment_cd,"29","54","CP"),1,0,.) | no_decrease == 1)

//TOTAL NUMBER OF UNIQUE ACCOUNTS UNDER SPECIAL STATUS CODE (AGGREGATE FOR SEP/OCT/NOV) and break down (% values) of account type(i.e., Mortgage, student loan, auto loans, cc, etc.);
gen cc_acc = cond(loan_type == 200,1,0,.)
gen mort_acc = cond(loan_type==110,1,0,.)
gen stu_acc = cond(loan_type==150,1,0,.)
gen auto_acc = cond(loan_type==100,1,0,.)
gen HELOC_acc = cond(inlist(loan_type,120,220),1,0,.)
gen other_debt_acc = cond(!inlist(loan_type,200,150,100,110,120,220),1,0,.)

gen cohort_aggregated=0
replace cohort_aggregated=1 if cohort==1 & inlist(Month,9,10,11)
//only want unique instances, so drop duplicates of accounts:
gen dup = 0
bysort ptk_nb: replace dup = _n if cohort_aggregated==1
count if dup > 1
replace cohort_aggregated=0 if dup > 1
drop dup
replace cohort = cohort_aggregated if inlist(Month,9,10,11)
gen months_aggregated = Month
replace months_aggregated = 91011 if inlist(Month,9,10,11)

//checking switcher fico scores
gen cohort_ref = .
gen switched = .
foreach i in 5 6 7 8 9 10 11 12 13 14 15 {
	replace cohort_ref = cohort if Month == `i'
	bysort ptk_nb (cohort_ref): replace cohort_ref = cohort_ref[1]
	replace switched = cohort - cohort_ref if Month == `i' + 1
	replace cohort_ref = .
}
drop cohort_ref
* replace switched = . if switched < 1 
bysort ptk_nb (Month): gen byte first = cond(sum(switched==1) == 1 & sum(switched[_n - 1] == 1) == 0,1,.)
gen switcher_cohort = cond(first==1 & inlist(Month,9,10,11),1,.)

bysort ptk_nb switcher_cohort: replace switcher_cohort = switcher_cohort[1]

* checking non-switcher fico scores:
gen pre_hurr_cohort = cond(cohort==1 & inlist(Month,5,6,7,8),1,.)
* bysort ptk_nb (pre_hurr_cohort): replace pre_hurr_cohort = pre_hurr_cohort[1]

save `projectpath'/data/harris_MSA_data_2017_2018_genvars, replace

log close;
