
//DALLAS AREA CODE FOR QCCT TO COMPARE COHORT COMPOSITION
//SETUP CODE
clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on

local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018
cd `projectpath'

log using `projectpath'/log/dallas_MSA_data_2017_2018.txt, replace text

use `projectpath'/data/Dallas_MSA_data_2017_2018, clear

gen deferred_payment = cond(comment_cd == "29",1,0,.)
gen natural_disaster = cond(comment_cd == "54",1,0,.)
gen forbearance = cond(comment_cd == "CP",1,0,.)
gen delinquency_flag = 0
replace delinquency_flag = 1 if inlist(estatus_cd,"71","72","73","74","75","76","77","78","79")
replace delinquency_flag = 1 if inlist(estatus_cd,"80","81","82","83","84")
replace delinquency_flag = 1 if inlist(estatus_cd,"22", "23", "24", "25", "26", "27", "28", "29")
gen notcurrent_flag = cond(!inlist(substr(paymentgrid,1,1), "C","0"),1,0,.)
tab notcurrent_flag, m
tab delinquency_flag notcurrent_flag, m
list estatus_cd if delinquency_flag == 0 & notcurrent_flag == 1

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

gen obs = 1
gen cohort = . 
replace cohort = 0 if balance_wt > 0
replace cohort = 1 if balance_wt > 0 & (cond(inlist(comment_cd,"29","54","CP"),1,0,.) | no_decrease == 1)
tab cohort, m

#delim ;

preserve;
gen obs_cohort1 = obs if cohort==1;
gen obs_cohort0 = obs if cohort==0;
collapse (sum) obs_cohort1 obs_cohort0 total_obs = obs, by(Month);
gen obs_cohort1_pct = round(obs_cohort1/total_obs*100,.01);
gen obs_cohort0_pct = round(obs_cohort0/total_obs*100,.01);
drop if Month == 4;
graph bar
		obs_cohort1_pct
		obs_cohort0_pct, 
			over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
			stack
			title("Total accounts by cohort (Dallas MSA)") 
			ytitle("# of accounts (percent of total)")
			blabel(bar)
			leg(order(1 "Treated cohort" 2 "Untreated cohort"))
			note(Both cohorts exclude zero balance amount tradelines);
graph export `projectpath'/figures/dallas/total_accounts_cohort_Dallas_MSA.png, replace;

log close;
