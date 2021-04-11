*SETUP CODE
clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on

local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018
cd `projectpath'

log using `projectpath'/log/graph.txt, replace text
#delim ;
use `projectpath'/data/texas/HoustonMSA_genvars, clear;

//drop first month because nondecreasing balance variable undefined
drop if Month == 4;

local tradeline_debt "total_debt = balance_wt cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt total_obs = obs" 
local debts "cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt"
local debts_pct "cc_debt_pct mortgage_debt_pct  student_debt_pct  auto_debt_pct HELOC_debt_pct other_debt_pct"
local Mocoh "Month cohort"
local cohort1 "cohort == 1"
local cohort0 "cohort == 0"

local tradelines "1 "Credit card" 2 "Mortgage (first-lien)" 3 "Student loan" 4 "Auto loan" 5 "HELOC" 6 "Other debt""
local cohorts "1 "Treated cohort" 2 "Untreated cohort""
local credits "550 "550" 600 "600" 650 "650" 700 "700" 750 "750""

local Debt "Debt composition for"
local Treated "treated cohort"
local Untreated "untreated cohort"


local ytotal "Sum"
local yaccount "of accounts"
local ypct "(% of total)"

local ymean "Mean"
local ymedian "Median"
local ybalance "balance amount"
local ycredit "credit score"

local xticks "5(1)17"

local yticks "10000(5000)30000"
local yticks_credit "550(100)750"

local houston "(Houston MSA)"
local dallas "(Dallas MSA)"

local figurespath "`projectpath'/figures/texas"
local twogroup "/houston/two_group"
local threegroup "/houston/three_group"

*FLAG COMPOSITION FOR TREATED COHORT;
	* preserve;
	* collapse (sum) deferred_payment natural_disaster forbearance no_decrease total_obs = obs, by(cohort Month);
	* graph bar 	deferred_payment 
	* 			natural_disaster 
	* 			forbearance 
	* 			no_decrease if cohort==1, 
	* 				over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
	* 				stack
	* 				title("Treated cohort composition") 
	* 				ytitle("Total observations (sum)") 
	* 				note("Note: Categories not mutually exclusive", size(vsmall))
	* 				leg(order(1 "Deferred payment" 2 "Natural disaster" 3 "Forbearance" 4 "Nondecreasing balance"));
	* graph export `projectpath'/figures/texas/houston/two_group/treated_flag_composition.png,replace;


	preserve;
	collapse (sum) deferred_payment natural_disaster forbearance no_decrease, by(Month);
	foreach obs in deferred_payment natural_disaster forbearance no_decrease {;
		replace `obs' = `obs'/1000;
	};
	graph bar 	no_decrease
				deferred_payment 
				forbearance
				natural_disaster, 
					over(Month, relabel(1 "May '17" 2 "Jun" 3 "Jul" 4 "Aug" 5 "Sep" 6 "Oct" 7 "Nov" 8 "Dec" 9 "Jan '18" 10 "Feb" 11 "Mar" 12 "Apr"))  
					stack
					title("Treated cohort composition") 
					ytitle("Total observations (thousands)") 
					note("Note: Categories are not mutually exclusive", size(small))
					leg(order(1 "Nondecreasing balance" 2 "Deferred payment" 3 "Forbearance" 4 "Natural disaster"));
	graph export `projectpath'/figures/texas/houston/two_group/treated_flag_composition.png,replace;
	
	list;

	foreach flag in deferred_payment natural_disaster forbearance no_decrease {;
		gen `flag'_pct = round((`flag'/total_obs)*100,.01);

	};

	graph bar 	no_decrease_pct 
				deferred_payment_pct
				forbearance_pct
				natural_disaster_pct
				if inlist(Month,5,6,7,8), 
					title("Treated cohort composition 4-mos before hurricane") 
					ytitle("Total observations (%)") 
					note("Note: Categories not mutually exclusive", size(vsmall))
					leg(order(1 "Nondecreasing balance" 2 "Deferred payment" 3 "Forbearance" 4 "Natural disaster"));
	graph export `projectpath'/figures/texas/houston/two_group/treated_flag_composition_pre_specialhurricane.png,replace;
	
	graph bar 	no_decrease_pct 
				deferred_payment_pct
				forbearance_pct
				natural_disaster_pct
				if inlist(Month,9,10,11,12),
					title("Treated cohort composition 4-mos after hurricane") 
					ytitle("Total observations (%)")
					note("Note: Categories not mutually exclusive", size(vsmall))
					leg(order(1 "Nondecreasing balance" 2 "Deferred payment" 3 "Forbearance" 4 "Natural disaster"));
	graph export `projectpath'/figures/texas/houston/two_group/treated_flag_composition_posthurricane.png,replace;
	restore;


* HOUSTON;
* DEBT COMPOSITION BY COHORT;
	preserve;
	collapse (sum) total_debt = balance_wt cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt total_obs = obs, by(Month cohort);

	foreach debt in cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt {;
		gen `debt'_pct = (`debt'/total_debt)*100;
	};
	graph bar 
			cc_debt_pct mortgage_debt_pct  student_debt_pct  auto_debt_pct HELOC_debt_pct other_debt_pct
			if cohort == 0, 
				over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
				stack
				title("Debt composition for untreated cohort") 
				ytitle("Total debt (%)") 
				leg(order(1 "Credit card" 2 "Mortgage (first-lien)" 3 "Student loan" 4 "Auto loan" 5 "HELOC" 6 "Other debt"));
	graph export `projectpath'/figures/texas/houston/two_group/untreated_cohort_debt_pct.png,replace;

	graph bar 
			cc_debt_pct
			mortgage_debt_pct 
			student_debt_pct 
			auto_debt_pct
			HELOC_debt_pct
			other_debt_pct
			if cohort == 1, 
				over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
				stack
				title("Debt composition for treated cohort") 
				ytitle("Total debt (%)") 
				leg(order(1 "Credit card" 2 "Mortgage (first-lien)" 3 "Student loan" 4 "Auto loan" 5 "HELOC" 6 "Other debt"));
	graph export `projectpath'/figures/texas/houston/two_group/treated_cohort_debt_pct.png,replace;
	restore;

*TOTAL ACCOUNTS BY COHORT;
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
				title("Total accounts by cohort (Houston MSA)") 
				ytitle("Total accounts (% of total)")
				blabel(bar)
				leg(order(1 "Treated cohort" 2 "Untreated cohort"));
	graph export `projectpath'/figures/texas/houston/two_group/total_accounts_by_cohort_h.png, replace;
	restore;

*MEDIAN DEBT BALANCE AMOUNT BY COHORT;
	preserve;
	collapse (median)  median_debt = balance_wt if inlist(loan_type,100,110,120,150,200,220), by(Month cohort);

	graph twoway 	(scatter median_debt Month if cohort == 1, connect(direct) sort(Month) mlabel(median_debt) mlabposition(6))
					(scatter median_debt Month if cohort == 0,
			 			connect(direct)
						sort(Month)
						mlabel(median_debt)
						mlabposition(12)
					  	title("Median balances by cohort")	
						ytitle("Median balance amount")
						xla(5 "May '17" 6 "Jun '17" 7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18" 16 "Apr '18") 
						xtick(5(1)17)
						legend(order(1 "Treated cohort" 2 "Untreated cohort")));
	graph export `projectpath'/figures/texas/houston/two_group/median_debt_by_cohort.png, replace;
	restore;

*MEAN DEBT BALANCE AMOUNT BY COHORT;
	preserve;
	collapse (mean)  mean_debt = balance_wt if inlist(loan_type,100,110,120,150,200,220), by(Month cohort);
	replace mean_debt = round(mean_debt,1);
	graph twoway 	(scatter mean_debt Month if cohort == 1, connect(direct) sort(Month) mlabel(mean_debt) mlabposition(6))
					(scatter mean_debt Month if cohort == 0,
			 			connect(direct) 
						sort(Month)
						mlabel(mean_debt)
						mlabposition(6)
					  	title("Mean balances by cohort")	
						ytitle("Mean balance amount")
						xla(5 "May '17" 6 "Jun '17" 7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18" 16 "Apr '18") 
						xtick(5(1)17)
						ytick(10000(5000)30000)
						legend(order(1 "Treated cohort" 2 "Untreated cohort")));
	graph export `projectpath'/figures/texas/houston/two_group/mean_debt_by_cohort.png, replace;
	restore;

* MEDIAN CREDIT SCORE BY COHORT;
	preserve;
	collapse (median) vantage_sc if inlist(loan_type,100,110,120,150,200,220), by(Month cohort);

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
						xtick(5(1)17)
						legend(order(1 "Treated cohort" 2 "Untreated cohort")));

	graph export `projectpath'/figures/texas/houston/two_group/median_vantage_sc_by_cohort.png, replace;
	restore;

*MEAN CREDIT SCORE BY COHORT;
	preserve;
	collapse (mean) vantage_sc if inlist(loan_type,100,110,120,150,200,220), by(Month cohort);
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
						xtick(5(1)17)
						legend(order(1 "Treated cohort" 2 "Untreated cohort")));
	graph export `projectpath'/figures/texas/houston/two_group/mean_vantage_sc_by_cohort.png, replace;

	restore;

*TRADELINE COMPOSITION BY COHORT;
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
				leg(order(1 "Credit card" 2 "Mortgage (first-lien)" 3 "Student loan" 4 "Auto loan" 5 "HELOC" 6 "Other debt"));

	graph export `projectpath'/figures/texas/houston/two_group/tradeline_composition_treated.png,replace;

	graph bar 
			cc_acc_pct
			mort_acc_pct
			stu_acc_pct
			auto_acc_pct 
			HELOC_acc_pct
			other_debt_acc_pct
			if cohort == 0, 
				over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
				stack
				title("Tradeline account composition for untreated cohort") 
				ytitle("Total accounts (%)") 
				leg(order(1 "Credit card" 2 "Mortgage (first-lien)" 3 "Student loan" 4 "Auto loan" 5 "HELOC" 6 "Other debt"));

	graph export `projectpath'/figures/texas/houston/two_group/tradeline_composition_untreated.png,replace;
	restore;

*DELINQUENT ACCOUNTS BY COHORT;
	preserve;
	collapse (sum) delinquency_flag total_obs = obs if inlist(loan_type,100,110,120,150,200,220), by(Month cohort);
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
						xtick(5(1)17)
						legend(order(1 "Treated cohort" 2 "Untreated cohort")));
	graph export `projectpath'/figures/texas/houston/two_group/delinquency_by_cohort.png,replace;
	restore;



*CREDIT SCORES AMONG SWITCHERS AND NONSWITCHERS (pre-special and pre-nonspecial);
	preserve;
	
	egen vantage_mean_pre_special = mean(vantage_sc) if pre_hurr_special == 1, by(Month);
	egen vantage_mean_switch = mean(vantage_sc) if switcher_cohort == 1, by(Month);
	egen vantage_mean_pre_nonspecial = mean(vantage_sc) if pre_hurr_nonspecial == 1, by(Month);

	collapse vantage_mean_pre_special vantage_mean_switch vantage_mean_pre_nonspecial, by(Month);

	replace vantage_mean_pre_special = round(vantage_mean_pre_special,1);
	replace vantage_mean_switch = round(vantage_mean_switch,1);
	replace vantage_mean_pre_nonspecial = round(vantage_mean_pre_nonspecial,1);

	graph twoway 	(scatter vantage_mean_pre_special Month, connect(direct) sort(Month) mlabel(vantage_mean_pre_special) mlabposition(12))
					(scatter vantage_mean_pre_nonspecial Month, connect(direct) sort(Month) mlabel(vantage_mean_pre_nonspecial) mlabposition(12))
					(scatter vantage_mean_switch Month,
			 			connect(direct) 
						sort(Month)
						mlabel(vantage_mean_switch)
						mlabposition(6)
					  	title("Mean credit score for cohort switchers and non-switchers")	
						ytitle("Mean credit score")
						ytick(550(100)750)
						ylab(550 "550" 600 "600" 650 "650" 700 "700" 750 "750")
						xla(5 "May '17" 6 "Jun '17" 7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18" 16 "Apr '18") 
						xtick(5(1)17)
						legend(order(1 "Pre/Special" 2 "Pre/Non-Special" 3 "Switcher")));
	graph export `projectpath'/figures/texas/houston/three_group/mean_vantage_sc_switchers.png, replace;

	restore;

	preserve;
	
	egen vantage_median_pre_special = median(vantage_sc) if pre_hurr_special == 1, by(Month);
	egen vantage_median_switch = median(vantage_sc) if switcher_cohort == 1 , by(Month);
	egen vantage_median_pre_nonspecial = median(vantage_sc) if pre_hurr_nonspecial == 1, by(Month);

	collapse vantage_median_pre_special vantage_median_switch vantage_median_pre_nonspecial, by(Month);

	graph twoway 	(scatter vantage_median_pre_special Month, connect(direct) sort(Month) mlabel(vantage_median_pre_special) mlabposition(12))
					(scatter vantage_median_pre_nonspecial Month, connect(direct) sort(Month) mlabel(vantage_median_pre_nonspecial) mlabposition(12))
					(scatter vantage_median_switch Month,
			 			connect(direct) 
						sort(Month)
						mlabel(vantage_median_switch)
						mlabposition(6)
					  	title("Median credit score for cohort switchers and non-switchers")	
						ytitle("Median credit score")
						ytick(550(100)750)
						ylab(550 "550" 600 "600" 650 "650" 700 "700" 750 "750")
						xla(5 "May '17" 6 "Jun '17" 7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18" 16 "Apr '18") 
						xtick(5(1)17)
						legend(order(1 "Pre/Special" 2 "Pre/Non-Special" 3 "Switcher")));
	graph export `projectpath'/figures/texas/houston/three_group/median_vantage_sc_switchers.png, replace;
	restore;

*DELINQUENT ACCOUNTS BY SWITCHERS/NONSWITCHERS;
	preserve;

	bysort Month pre_hurr_special: egen delinquency_pre_special = total(delinquency_flag);
	bysort Month switcher_cohort: egen delinquency_switch  = total(delinquency_flag);
	bysort Month pre_hurr_nonspecial: egen delinquency_pre_nonspecial = total(delinquency_flag);
	bysort Month: egen total_pre_special = total(pre_hurr_special);
	bysort Month: egen total_switch = total(switcher_cohort);
	bysort Month: egen total_pre_nonspecial = total(pre_hurr_nonspecial);

	foreach group in pre_special switch pre_nonspecial {;
		gen delinquency_`group'_pct = delinquency_`group'/total_`group'*100;
	};

	collapse delinquency_pre_special_pct delinquency_switch_pct delinquency_pre_nonspecial_pct, by(Month);
	
	foreach group in _pre_special _switch _pre_nonspecial {;
		replace delinquency`group'_pct = round(delinquency`group'_pct,.01);
	};

	graph twoway 	(scatter delinquency_pre_special_pct Month, connect(direct) sort(Month) mlabel(delinquency_pre_special_pct) mlabposition(12))
					(scatter delinquency_pre_nonspecial_pct Month, connect(direct) sort(Month) mlabel(delinquency_pre_nonspecial_pct) mlabposition(12))
					(scatter delinquency_switch_pct Month, 
						mlabel(delinquency_switch_pct)
			 			connect(direct) 
						sort(Month)
						mlabposition(6)
					  	title("Delinquent accounts for cohort switchers and non-switchers")	
						ytitle("Delinquent accounts (%)")
						xla(5 "May '17" 6 "Jun '17" 7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18" 16 "Apr '18") 
						xtick(5(1)17)
						legend(order(1 "Pre/Special" 2 "Pre/Non-Special" 3 "Switcher")));
	graph export `projectpath'/figures/texas/houston/three_group/delinquency_switchers.png,replace;
	restore;


*TRADELINE COMPOSITION BY SWITCHERS/NONSWITCHERS;
	preserve;


	collapse (sum) cc_acc mort_acc stu_acc auto_acc HELOC_acc other_debt_acc total_acc = obs, by(Month pre_hurr_special);
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
			if pre_hurr_special == 1, 
				over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
				stack
				title("Tradeline account composition Pre/Special") 
				ytitle("Total accounts (%)") 
				leg(order(1 "Credit card" 2 "Mortgage (first-lien)" 3 "Student loan" 4 "Auto loan" 5 "HELOC" 6 "Other debt"));

	graph export `projectpath'/figures/texas/houston/three_group/tradeline_composition_noswitch.png,replace;

	restore;

	preserve;
	collapse (sum) cc_acc mort_acc stu_acc auto_acc HELOC_acc other_debt_acc total_acc = obs, by(Month switcher_cohort);
		
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
			if switcher_cohort == 1, 
				over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
				stack
				title("Tradeline account composition for switchers") 
				ytitle("Total accounts (%)") 
				leg(order(1 "Credit card" 2 "Mortgage (first-lien)" 3 "Student loan" 4 "Auto loan" 5 "HELOC" 6 "Other debt"));

	graph export `projectpath'/figures/texas/houston/three_group/tradeline_composition_switch.png,replace;

	restore;

	preserve;
	collapse (sum) cc_acc mort_acc stu_acc auto_acc HELOC_acc other_debt_acc total_acc = obs, by(Month pre_hurr_nonspecial);
		
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
			if pre_hurr_nonspecial == 1, 
				over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
				stack
				title("Tradeline account composition Pre/Non-Special") 
				ytitle("Total accounts (%)") 
				leg(order(1 "Credit card" 2 "Mortgage (first-lien)" 3 "Student loan" 4 "Auto loan" 5 "HELOC" 6 "Other debt"));

	graph export `projectpath'/figures/texas/houston/three_group/tradeline_composition_pre_nonspecial.png,replace;

	restore;

* *MEAN/MEDIAN DEBT BALANCE AMOUNT SWITCHERS/NONSWITCHERS;

	preserve;
	
	egen debt_mean_pre_special = mean(balance_wt) if pre_hurr_special == 1 & inlist(loan_type,100,110,120,150,200,220), by(Month);
	egen debt_mean_switch = mean(balance_wt) if switcher_cohort == 1 & inlist(loan_type,100,110,120,150,200,220), by(Month);
	egen debt_mean_pre_nonspecial = mean(balance_wt) if pre_hurr_nonspecial == 1 & inlist(loan_type,100,110,120,150,200,220), by(Month);

	collapse debt_mean_pre_special debt_mean_switch debt_mean_pre_nonspecial, by(Month);

	replace debt_mean_pre_special = round(debt_mean_pre_special,1);
	replace debt_mean_switch = round(debt_mean_switch,1);
	replace debt_mean_pre_nonspecial = round(debt_mean_pre_nonspecial,1);

	graph twoway 	(scatter debt_mean_pre_special Month, connect(direct) sort(Month) mlabel(debt_mean_pre_special) mlabposition(12))
					(scatter debt_mean_pre_nonspecial Month, connect(direct) sort(Month) mlabel(debt_mean_pre_nonspecial) mlabposition(6))
					(scatter debt_mean_switch Month,
			 			connect(direct) 
						sort(Month)
						mlabel(debt_mean_switch)
						mlabposition(12)
						ytick(5000(5000)35000)
						ylab(5000 "5000" 15000 "15000" 25000 "25000" 35000 "35000")
					  	title("Mean balances for cohort switchers and non-switchers")	
						ytitle("Mean balance amount")
						xla(5 "May '17" 6 "Jun '17" 7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18" 16 "Apr '18") 
						xtick(5(1)17)
						legend(order(1 "Pre/Special" 2 "Pre/Non-Special" 3 "Switcher")));
	graph export `projectpath'/figures/texas/houston/three_group/mean_debt_switchers.png, replace;
	
	restore;

	preserve;
	
	egen debt_median_pre_special = median(balance_wt) if pre_hurr_special == 1 & inlist(loan_type,100,110,120,150,200,220), by(Month);
	egen debt_median_switch = median(balance_wt) if switcher_cohort == 1 & inlist(loan_type,100,110,120,150,200,220), by(Month);
	egen debt_median_pre_nonspecial = median(balance_wt) if pre_hurr_nonspecial == 1 & inlist(loan_type,100,110,120,150,200,220), by(Month);

	collapse debt_median_pre_special debt_median_switch debt_median_pre_nonspecial, by(Month);

	replace debt_median_pre_special = round(debt_median_pre_special,1);
	replace debt_median_switch = round(debt_median_switch,1);
	replace debt_median_pre_nonspecial = round(debt_median_pre_nonspecial,1);

	graph twoway 	(scatter debt_median_pre_special Month, connect(direct) sort(Month) mlabel(debt_median_pre_special) mlabposition(12))
					(scatter debt_median_pre_nonspecial  Month, connect(direct) sort(Month) mlabel(debt_median_pre_nonspecial) mlabposition(12))
					(scatter debt_median_switch Month,
			 			connect(direct) 
						sort(Month)
						mlabel(debt_median_switch)
						mlabposition(12)
						ytick(1000(1000)10000)
					  	title("Median balances for cohort switchers and non-switchers")	
						ytitle("Median balance amount")
						xla(5 "May '17" 6 "Jun '17" 7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18" 16 "Apr '18") 
						xtick(5(1)17)
						legend(order(1 "Pre/Special" 2 "Pre/Non-Special" 3 "Switcher")));
	graph export `projectpath'/figures/texas/houston/three_group/median_debt_switchers.png, replace;
	
	restore;


* DEBT COMPOSITION SWITCHERS/NONSWITCHERS;
	preserve;

	collapse (sum) total_debt = balance_wt cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt, by(Month pre_hurr_special);
	foreach debt in cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt{;
		gen `debt'_pct = round((`debt'/total_debt)*100,.01);
	};
 	graph bar 
			cc_debt_pct
			mortgage_debt_pct
			student_debt_pct
			auto_debt_pct 
			HELOC_debt_pct
			other_debt_pct
			if pre_hurr_special == 1, 
				over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
				stack
				title("Debt composition for Pre/Special") 
				ytitle("Total debt (%)") 
				leg(order(1 "Credit card" 2 "Mortgage (first-lien)" 3 "Student loan" 4 "Auto loan" 5 "HELOC" 6 "Other debt"));

	graph export `projectpath'/figures/texas/houston/three_group/pre_hurr_special_debt_pct.png,replace;

	restore;

	preserve;

	collapse (sum) total_debt = balance_wt cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt, by(Month switcher_cohort);
	foreach debt in cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt{;
		gen `debt'_pct = round((`debt'/total_debt)*100,.01);
	};
 	graph bar 
			cc_debt_pct
			mortgage_debt_pct
			student_debt_pct
			auto_debt_pct 
			HELOC_debt_pct
			other_debt_pct
			if switcher_cohort == 1, 
				over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
				stack
				title("Debt composition for switchers") 
				ytitle("Total debt (%)") 
				leg(order(1 "Credit card" 2 "Mortgage (first-lien)" 3 "Student loan" 4 "Auto loan" 5 "HELOC" 6 "Other debt"));

	graph export `projectpath'/figures/texas/houston/three_group/switcher_debt_pct.png,replace;

	restore;

	preserve;
	collapse (sum) total_debt = balance_wt cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt, by(Month pre_hurr_nonspecial);
	foreach debt in cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt{;
		gen `debt'_pct = round((`debt'/total_debt)*100,.01);
	};
 	graph bar 
			cc_debt_pct
			mortgage_debt_pct
			student_debt_pct
			auto_debt_pct 
			HELOC_debt_pct
			other_debt_pct
			if pre_hurr_nonspecial == 1, 
				over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
				stack
				title("Debt composition Pre/Non-Special") 
				ytitle("Total debt (%)") 
				leg(order(1 "Credit card" 2 "Mortgage (first-lien)" 3 "Student loan" 4 "Auto loan" 5 "HELOC" 6 "Other debt"));

	graph export `projectpath'/figures/texas/houston/three_group/pre_hurr_nonspecial_debt_pct.png,replace;

	restore;


*DALLAS;
*TOTAL ACCOUNTS BY COHORT;
	preserve;
	use `projectpath'/data/texas/DallasMSA_genvars, clear;
	drop if Month == 4;
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
				title("Total accounts by cohort (Dallas MSA)") 
				ytitle("Total accounts (% of total)")
				blabel(bar)
				leg(order(1 "Treated cohort" 2 "Untreated cohort"));
	graph export `projectpath'/figures/texas/dallas/total_accounts_by_cohort_d.png, replace;
	restore;



              
*ARCHIVED GRAPHS

*CREDIT SCORES AMONG "SWITCHERS" "PRE-HURRICANE" AND Non-Special COHORT
* Average credit score of accounts with special status code pre-hurricane:  
* table Month if pre_hurr_special==1, c(mean vantage_sc median vantage_sc)
* Average credit score among “switchers”
* table Month if switcher_cohort==1, c(mean vantage_sc median vantage_sc)
* Average credit score in Non-Special
* table Month if balance_wt != 0, c(mean vantage_sc median vantage_sc)

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

	* graph export `projectpath'/figures/houston/two_group/cohort_composition.png, replace;

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
	* graph export `projectpath'/figures/houston/two_group/.png,replace;

* sort  cohort consumer_nb ptk_nb Month;
* order consumer_nb ptk_nb Month;
*GENERATE PAYMENT VARIABLES;
	* generate cc_payment = actualpayment_am if loan_type==200;
	* generate student_payment = actualpayment_am if loan_type==150;
	* generate auto_payment = actualpayment_am if loan_type==100;
	* generate mortgage_payment = actualpayment_am if loan_type==110;
	* generate HELOC_payment = actualpayment_am if inlist(loan_type,120,220);
	* generate other_payment = actualpayment_am if !inlist(loan_type,200,150,100,110,120,220);

	* collapse (median) actualpayment_am cc_payment student_payment auto_payment mortgage_payment HELOC_payment other_payment, by(Month);

	* graph twoway 	(scatter cc_payment Month, connect(direct) sort(Month) mlabposition(12))
	* 				(scatter student_payment Month, connect(direct) sort(Month) mlabposition(12))
	* 				(scatter auto_payment Month, connect(direct) sort(Month) mlabposition(12))
	* 				(scatter mortgage_payment Month, connect(direct) sort(Month) mlabposition(12))
	* 				(scatter HELOC_payment Month, connect(direct) sort(Month) mlabposition(12))
	* 				(scatter other_payment Month, 
	* 		 			connect(direct) 
	* 					sort(Month)
	* 					mlabposition(6)
	* 				  	title("Median payments by type")	
	* 					ytitle("Median payments ($)")
	* 					xla(5 "May '17" 6 "Jun '17" 7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "Mar '18" 16 "Apr '18") 
	* 					xtick(5(1)17)
	* 					legend(order(1 "Credit cards" 2 "Student loans" 3 "Auto loans" 4 "Mortgages" 5 "HELOCs" 6 "Other tradelines")));
	* graph export `projectpath'/figures/texas/houston/two_group/median_payment_amount_loantype.png,replace;
	* restore;

	* gen no_payment = 1 if actualpayment_am == 0;
	* gen missing_payment = 1 if actualpayment_am == .;
	* preserve;
	* collapse (sum) no_payment missing_payment, by(Month);
	* graph bar 		no_payment 
	* 				missing_payment, 
	* 					over(Month, relabel(1 "May '17" 2 "Jun '17" 3 "Jul '17" 4 "Aug '17" 5 "Sep '17" 6 "Oct '17" 7 "Nov '17" 8 "Dec '17" 9 "Jan '18" 10 "Feb '18" 11 "Mar '18" 12 "Apr '18"))  
	* 					stack
	* 					title("Median payment amount") 
	* 					ytitle("Median payment amount") 
	* 					leg(order(1 "No payment" 2 "Missing payment"));
	* graph export `projectpath'/figures/texas/houston/two_group/missing_payment_flag_sum.png,replace;
	* restore;

log close;
