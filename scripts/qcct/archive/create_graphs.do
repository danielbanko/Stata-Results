//SETUP CODE
clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on

local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018
cd `projectpath'

log using `projectpath'/log/create_graphs.txt, replace text

use `projectpath'/data/harris_MSA_data_2017_2018_genvars, clear

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
