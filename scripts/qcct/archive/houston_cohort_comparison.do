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
* use `projectpath'/data/harris_MSA_data_2017_2018, clear
* count
* count if balance_wt > 0
* drop if balance_wt < 0

* bysort ptk_nb: gen unique_acc = (_n==1)
* bysort consumer_nb: gen unique_consumer = (_n==1)
* bysort Month ptk_nb: gen unique_acc_month = (_n==1)
* bysort Month consumer_nb: gen unique_consumer_month = (_n==1)
* gen obs = 1

* //TABULATIONS
* 	//COMMENT CODES
* 		* tab comment_cd, m
* 		* tab comment_cd if comment_cd != "00", m

* 	//ESTATUS CODES
* 		* tab estatus_cd, m
* 		* tab estatus_cd if estatus_cd != "11", mi

* //GEN FLAG VARIABLES
* 	gen deferred_payment = cond(comment_cd == "29",1,0,.)
* 	gen natural_disaster = cond(comment_cd == "54",1,0,.)
* 	gen forbearance = cond(comment_cd == "CP",1,0,.)
* 	gen delinquency_flag = 0
* 	replace delinquency_flag = 1 if inlist(estatus_cd,"71","72","73","74","75","76","77","78","79")
* 	replace delinquency_flag = 1 if inlist(estatus_cd,"80","81","82","83","84")
* 	replace delinquency_flag = 1 if inlist(estatus_cd,"22", "23", "24", "25", "26", "27", "28", "29")
* 	gen notcurrent_flag = cond(!inlist(substr(paymentgrid,1,1), "C","0"),1,0,.)

* //NONDECREASING BALANCE AMOUNTS ON CLOSED-END ACCOUNTS (Auto loan, student loan, mortage loan, personal loan, retail loan, HELOC)
* 	gen balance_ref = .
* 	gen diff = .
* 	foreach i in 4 5 6 7 8 9 10 11 12 13 14 15 {
* 		replace balance_ref = balance_wt if Month == `i'
* 		bysort consumer_nb ptk_nb (balance_ref): replace balance_ref = balance_ref[1]
* 		sort consumer_nb ptk_nb Month
* 		replace diff = balance_wt - balance_ref if Month == `i' + 1
* 		replace balance_ref = .
* 	}
* 	gen no_decrease = .
* 	replace no_decrease = 0 if diff != . & balance_wt > 0 &  inlist(loan_type,100,110,120,130,140,150,220) 
* 	replace no_decrease = 1 if diff >= 0 & balance_wt > 0 &  inlist(loan_type,100,110,120,130,140,150,220)

* 	tab no_decrease, m
* 	tab notcurrent_flag, m
* 	tab delinquency_flag notcurrent_flag, m
* 	* list estatus_cd if delinquency_flag == 0 & notcurrent_flag == 1
* 	count if delinquency_flag == 0 & notcurrent_flag == 1
* //archived flag variables:
* 	* gen resolved_dispute = cond(comment_cd == "13",1,0,.)
* 	* gen current_dispute = cond(comment_cd == "78",1,0,.)
* 	* gen disagreed_resolved = cond(comment_cd == "20",1,0,.)
* 	* gen most_common_comments = cond(inlist(comment_cd,"29","54","CP"),1,0,.)
* 	* gen other_comments = cond(!inlist(comment_cd,"54", "29", "CP", "13","78","20","00"),1,0,.)
* 	* gen trouble_status = cond(inlist(estatus_cd,"05","10","20","42"),1,0,.)  //transferred, refinanced, credit line closed, redeemed/repossesed
* 	* gen time_diff = month(balance_dt) - month(lastpayment_dt) if year(balance_dt)==year(lastpayment_dt)

* //GENERATE DEBT VARIABLES
* 	generate cc_debt = balance_wt if loan_type==200
* 	generate student_debt = balance_wt if loan_type==150
* 	generate auto_debt = balance_wt if loan_type==100
* 	generate mortgage_debt = balance_wt if loan_type==110
* 	generate HELOC_debt = balance_wt if inlist(loan_type,120,220)
* 	generate other_debt = balance_wt if !inlist(loan_type,200,150,100,110,120,220)

* //GENERATE CREDIT SCORE VARIABLE
* 	gen vantage_sc = .
* 	replace vantage_sc = vantage_sc1 if inlist(Month,3,4,5)
* 	replace vantage_sc = vantage_sc2 if inlist(Month,6,7,8)
* 	replace vantage_sc = vantage_sc3 if inlist(Month,9,10,11)
* 	replace vantage_sc = vantage_sc4 if inlist(Month,12,13,14)
* 	replace vantage_sc = vantage_sc5 if inlist(Month,15,16,17)
* 	drop vantage_sc1 vantage_sc2 vantage_sc3 vantage_sc4 vantage_sc5

* //GENERATE TREATED AND UNTREATED COHORT VARIABLE: 
* * both cohorts only consist of positive balance amount accounts.
* * cohort = 1 if payment deferred, natural disaster, acount in forbearance, closed-end credit account balance non-decreasing
* 	gen cohort = . 
* 	replace cohort = 0 if balance_wt > 0
* 	replace cohort = 1 if balance_wt > 0 & (cond(inlist(comment_cd,"29","54","CP"),1,0,.) | no_decrease == 1)
* 	tab cohort, m

use `projectpath'/data/harris_MSA_data_2017_2018_modified, clear

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
sum vantage_sc if switcher_cohort==1, detail

* checking non-switcher fico scores:
gen pre_hurr_cohort = cond(cohort==1 & inlist(Month,5,6,7,8),1,.)
bysort ptk_nb (pre_hurr_cohort): replace pre_hurr_cohort = pre_hurr_cohort[1]

save `projectpath'/data/harris_MSA_data_2017_2018_modified, replace

preserve
collapse (sum) cc_acc mort_acc stu_acc auto_acc other_debt_acc total_acc = obs, by(cohort months_aggregated)
foreach acc in cc_acc mort_acc stu_acc auto_acc other_debt_acc {
	gen `acc'_pct = (`acc'/total_acc)*100
	replace `acc'_pct = round(`acc'_pct,.01)
}
table cohort, c(sum cc_acc_pct sum mort_acc_pct sum stu_acc_pct sum auto_acc_pct sum other_debt_acc_pct)
table cohort months_aggregate, c(sum cc_acc_pct sum mort_acc_pct sum stu_acc_pct sum auto_acc_pct sum other_debt_acc_pct)
restore

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

//CROSSTABS
	* tab no_decrease notcurrent_flag, m
	* tab no_decrease delinquency_flag, m
	* tab no_decrease most_common_comments_cd, m
	* tab notcurrent_flag delinquency_flag, m
	* tab notcurrent_flag most_common_comments_cd, m
	* tab delinquency_flag most_common_comments_cd, m
	* tab Month pre_hurr_cohort
	* tab first Month

* use `projectpath'/data/harris_MSA_data_2017_2018_modified, clear

//GRAPHS
	#delim ;
	bysort consumer_nb Month vantage_sc: gen consumer_tag = (_n==1);
	drop if Month == 4;

	//DEBT COMPOSITION BY COHORT;
		preserve;
		collapse (sum) total_debt = balance_wt cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt total_obs = obs, by(Month cohort);

		foreach debt in cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt {;
			gen `debt'_pct = (`debt'/total_debt)*100;
		};
		graph bar 
				cc_debt_pct
				student_debt_pct 
				auto_debt_pct
				mortgage_debt_pct 
				HELOC_debt_pct 
				other_debt_pct
				if cohort == 0, 
					over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
					stack
					title("Debt composition for untreated cohort") 
					ytitle("Total debt (%)") 
					leg(order(1 "Credit card" 2 "Student loan" 3 "Auto loan" 4 "Mortgages (first-lien)" 5 "HELOCs" 6 "Other debt"));
		graph export `projectpath'/figures/houston/untreated_cohort_debt_pct.png,replace;

		graph bar 
				cc_debt_pct
				student_debt_pct 
				auto_debt_pct
				mortgage_debt_pct 
				HELOC_debt_pct
				other_debt_pct
				if cohort == 1, 
					over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
					stack
					title("Debt composition for treated cohort") 
					ytitle("Total debt (%)") 
					leg(order(1 "Credit card" 2 "Student loan" 3 "Auto loan" 4 "Mortgages (first-lien)" 5 "HELOCs" 6 "Other debt"));
		graph export `projectpath'/figures/houston/treated_cohort_debt_pct.png,replace;
		restore;

	//TOTAL ACCOUNTS BY COHORT;
		preserve;
		gen obs_cohort1 = obs if cohort==1;
		gen obs_cohort0 = obs if cohort==0;
		collapse (sum) obs_cohort1 obs_cohort0 total_obs = obs, by(Month);
		gen obs_cohort1_pct = round(obs_cohort1/total_obs*100,.01);
		gen obs_cohort0_pct = round(obs_cohort0/total_obs*100,.01);
		graph bar
				obs_cohort1_pct
				obs_cohort0_pct, 
					over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
					stack
					title("Total accounts by cohort (Harris County)") 
					ytitle("# of accounts (percent of total)")
					blabel(bar)
					leg(order(1 "Treated cohort" 2 "Untreated cohort"))
					note(Both cohorts exclude accounts with zero balance amount);
		graph export `projectpath'/figures/houston/total_accounts_cohort_Harris.png, replace;
		restore;

	//MEDIAN DEBT BALANCE AMOUNT BY COHORT;
		preserve;
		collapse (median)  median_debt = balance_wt if inlist(loan_type,100,110,120,150,200,220), by(Month cohort);

		graph twoway 	(scatter median_debt Month if cohort == 1, connect(direct) sort(Month) mlabel(median_debt) mlabposition(12))
						(scatter median_debt Month if cohort == 0,
				 			connect(direct) 
							sort(Month)
							mlabel(median_debt)
							mlabposition(12)
						  	title("Median balances for each cohort")	
							ytitle("Median balance amount")
							xla(5 "May '17" 6 "Jun '17" 7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18" 16 "Apr '18") 
							xtick(5(1)16)
							legend(order(1 "Treated cohort" 2 "Untreated cohort")));
		graph export `projectpath'/figures/houston/median_debt.png, replace;
		restore;

	//MEAN DEBT BALANCE AMOUNT BY COHORT;
		preserve;
		collapse (mean)  mean_debt = balance_wt if inlist(loan_type,100,110,120,150,200,220), by(Month cohort);
		replace mean_debt = round(mean_debt,1);
		graph twoway 	(scatter mean_debt Month if cohort == 1, connect(direct) sort(Month) mlabel(mean_debt) mlabposition(12))
						(scatter mean_debt Month if cohort == 0,
				 			connect(direct) 
							sort(Month)
							mlabel(mean_debt)
							mlabposition(6)
						  	title("Mean balances for each cohort")	
							ytitle("Mean balance amount")
							xla(5 "May '17" 6 "Jun '17" 7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18" 16 "Apr '18") 
							xtick(5(1)16)
							legend(order(1 "Treated cohort" 2 "Untreated cohort")));
		graph export `projectpath'/figures/houston/mean_debt.png, replace;
		restore;

	//MEDIAN CREDIT SCORE BY COHORT;
		preserve;
		collapse (median) vantage_sc if inlist(loan_type,100,110,120,150,200,220) & consumer_tag == 1, by(Month cohort);

		graph twoway 	(scatter vantage_sc Month if cohort == 1, connect(direct) sort(Month) mlabel(vantage_sc) mlabposition(12))
						(scatter vantage_sc Month if cohort == 0,
				 			connect(direct) 
							sort(Month)
							mlabel(vantage_sc)
							mlabposition(12)
						  	title("Median credit score for each cohort")	
							ytitle("Median credit score")
							ytick(550(100)750)
							ylab(550 "550" 600 "600" 650 "650" 700 "700" 750 "750")
							xla(5 "May '17" 6 "Jun '17" 7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18" 16 "Apr '18") 
							xtick(5(1)16)
							legend(order(1 "Treated cohort" 2 "Untreated cohort")));

		graph export `projectpath'/figures/houston/median_vantage_sc.png, replace;
		restore;

	//MEAN CREDIT SCORE BY COHORT;
		preserve;
		collapse (mean) vantage_sc if inlist(loan_type,100,110,120,150,200,220) & consumer_tag == 1, by(Month cohort);
		replace vantage_sc = round(vantage_sc,1);
		graph twoway 	(scatter vantage_sc Month if cohort == 1, connect(direct) sort(Month) mlabel(vantage_sc) mlabposition(12))
						(scatter vantage_sc Month if cohort == 0,
				 			connect(direct) 
							sort(Month)
							mlabel(vantage_sc)
							mlabposition(12)
						  	title("Mean credit score for each cohort")	
							ytitle("Mean credit score")
							ytick(550(100)750)
							ylab(550 "550" 600 "600" 650 "650" 700 "700" 750 "750")
							xla(5 "May '17" 6 "Jun '17" 7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18" 16 "Apr '18") 
							xtick(5(1)16)
							legend(order(1 "Treated cohort" 2 "Untreated cohort")));
		graph export `projectpath'/figures/houston/mean_vantage_sc.png, replace;

		restore;

	//TRADELINE COMPOSITION BY COHORT;
		preserve;

		collapse (sum) cc_acc mort_acc stu_acc auto_acc HELOC_acc other_debt_acc total_acc = obs, by(Month cohort);

		foreach acc in cc_acc mort_acc stu_acc auto_acc HELOC_acc other_debt_acc {;
			gen `acc'_pct = round((`acc'/total_acc)*100,.01);
		};
		graph bar 
				cc_acc_pct
				mort_acc_pct
				stu_acc_pct
				auto_acc_pct 
				HELOC_acc_pct
				other_debt_acc_pct
				if cohort == 1, 
					over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
					stack
					title("Tradeline account composition for treated cohort") 
					ytitle("Total accounts (%)") 
					leg(order(1 "Credit card" 2 "Mortgages (first-lien)" 3 "Student loans" 4 "Auto loans" 5 "HELOC" 6 "Other debt"));

		graph export `projectpath'/figures/houston/tradeline_composition_treated.png,replace;

		graph bar 
				cc_acc_pct
				mort_acc_pct
				stu_acc_pct
				auto_acc_pct 
				other_debt_acc_pct
				if cohort == 0, 
					over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
					stack
					title("Tradeline account composition for untreated cohort") 
					ytitle("Total accounts (%)") 
					leg(order(1 "Credit card" 2 "Mortgages (first-lien)" 3 "Student loans" 4 "Auto loans" 5 "Other debt"));

		graph export `projectpath'/figures/houston/tradeline_composition_untreated.png,replace;
		restore;

	//DELINQUENT ACCOUNTS BY COHORT;
		preserve;
		collapse (sum) delinquency_flag total_obs = obs, by(Month cohort);
		gen delinquency_flag_pct = round(delinquency_flag/total_obs*100,.01);

		graph twoway 	(scatter delinquency_flag_pct Month if cohort == 1, connect(direct) sort(Month) mlabel(delinquency_flag_pct) mlabposition(12))
						(scatter delinquency_flag_pct Month if cohort == 0, 
							mlabel(delinquency_flag_pct)
				 			connect(direct) 
							sort(Month)
							mlabposition(6)
						  	title("Delinquent accounts by cohort")	
							ytitle("Delinquent accounts (%)")
							xla(5 "May '17" 6 "Jun '17" 7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18" 16 "Apr '18") 
							xtick(5(1)16)
							legend(order(1 "Treated cohort" 2 "Untreated cohort")));
		graph export `projectpath'/figures/houston/delinquency_cohort_treated.png,replace;
		restore;

	//FLAG COMPOSITION FOR TREATED COHORT;
		preserve;
		collapse (sum) deferred_payment natural_disaster forbearance no_decrease total_obs = obs, by(cohort Month);
		graph bar 	deferred_payment 
					natural_disaster 
					forbearance 
					no_decrease if cohort==1, 
						over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
						stack
						title("Treated cohort composition") 
						ytitle("Total observations (sum)") 
						leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Forbearance" 4 "Nondecreasing balance accounts"));
		graph export `projectpath'/figures/houston/cohort_composition_treated.png,replace;

		foreach flag in deferred_payment natural_disaster forbearance no_decrease {;
			gen `flag'_pct = round((`flag'/total_obs)*100,.01);

		};
		graph bar 	no_decrease_pct 
					deferred_payment_pct
					natural_disaster_pct
					forbearance_pct
					if cohort==1 & inlist(Month,4,5,6,7,8), 
						title("Treated cohort composition before hurricane") 
						ytitle("Total observations (%)") 
						note("Note: Categories not mutually exclusive", size(vsmall))
						leg(order(1 "Nondecreasing balance accounts" 2 "Deferred payment code" 3 "Natural disaster code" 4 "Forbearance code"));
		graph export `projectpath'/figures/houston/cohort_composition_treated_pct_prehurricane.png,replace;
		
		graph bar 	no_decrease_pct 
					deferred_payment_pct
					natural_disaster_pct
					forbearance_pct
						if cohort==1 & inlist(Month,9,10,11),
						title("Treated cohort composition after hurricane") 
						ytitle("Total observations (%)")
						note("Note: Categories not mutually exclusive", size(vsmall))
						leg(order(1 "Nondecreasing balance accounts" 2 "Deferred payment code" 3 "Natural disaster code" 4 "Forbearance code"));
		graph export `projectpath'/figures/houston/cohort_composition_treated_pct_posthurricane.png,replace;

	//ARCHIVED GRAPHS
		* graph twoway (scatter credit_card_pct Month if cohort==1,mlabel(credit_card_pct) mlabposition(12) connect(direct) sort(Month))
		* 			 (scatter mort_acc_pct Month if cohort==1, mlabel(mort_acc_pct) mlabposition(12) connect(direct) sort(Month))
		* 			 (scatter stu_acc_pct Month if cohort==1, mlabel(stu_acc_pct) mlabposition(12) connect(direct) sort(Month))
		* 			 (scatter auto_acc_pct Month if cohort==1,  mlabel(auto_acc_pct) mlabposition(12) connect(direct) sort(Month))
		* 			 (scatter other_debt_acc_pct Month if cohort==1,
		* 			 	connect(direct) 
		* 				sort(Month) 
		* 			  	title("Treated cohort composition")	
		* 				ytitle("% of accounts (by type)")
		* 				xla(6 "Jun '17" 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec" 13 "Jan '18" 14 "Feb" 15 "Mar" 16 "Apr") 
		* 				xtick(6(1)16)
		* 				mlabel(other_debt_acc_pct)
		* 				mlabposition(12)
		* 				legend(order(1 "Credit cards" 2 "Mortgages" 3 "Student loans" 4 "Auto loans" 5 "Other debt")));

		* graph export `projectpath'/figures/houston/cohort_composition.png, replace;

		* graph bar 
		* 		cc_debt_pct
		* 		student_debt_pct 
		* 		auto_debt_pct
		* 		mortgage_debt_pct 
		* 		HELOC_debt_pct
		* 		other_debt_pct, 
		* 			over(Month, relabel(6 "Jun" 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18")) 
		* 			stack
		* 			title("Total debt in sample") 
		* 			ytitle("Total debt ($)") 
		* 			leg(order(1 "Credit card" 2 "Student loan" 3 "Auto loan" 4 "Mortgages (first-lien)" 5 "HELOCs" 6 "Other debt"));
		* graph export `projectpath'/figures/houston/.png,replace;

* sort  cohort consumer_nb ptk_nb Month;
* order consumer_nb ptk_nb Month;

log close;
