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

log using `projectpath'/log/texas_map_data.txt, replace text
* use `projectpath'/data/texas_data_2017_2018, clear
use `projectpath'/data/harris_county_data_2017_2018, clear

count

* gen Month = .
* replace Month = 6 if ReportingPeriod == "2017jun" 	
* replace Month = 7 if ReportingPeriod == "2017jul"
* replace Month = 8 if ReportingPeriod == "2017aug"
* replace Month = 9 if ReportingPeriod == "2017sep"
* replace Month = 10 if ReportingPeriod == "2017oct"
* replace Month = 11 if ReportingPeriod == "2017nov"
* replace Month = 12 if ReportingPeriod == "2017dec"
* replace Month = 13 if ReportingPeriod == "2018jan"
* replace Month = 14 if ReportingPeriod == "2018feb"

gen nat_dis_cm = 0
replace nat_dis_cm = 1 if comment_cd == "54"

* gen deferred_payment = cond(comment_cd == "29",1,0,.)
* gen resolved_dispute = cond(comment_cd == "13",1,0,.)
* gen current_dispute = cond(comment_cd == "78",1,0,.)
* gen disagreed_resolved = cond(comment_cd == "20",1,0,.)
* gen other_comment = cond(!inlist(comment_cd, "29","54", "13", "CP", "78","20","","00"),1,0,.)

gen forbearance = cond(comment_cd == "CP",1,0,.)
* gen comment_tag = cond(!inlist(comment_cd,"","00"),1,0,.)

bysort Month ptk_nb: gen accounts_tag = (_n==1)
bysort Month consumer_nb: gen consumers_tag = (_n==1)

#delim ;

gen mortgage_forbearance = forbearance if loan_type == 110;
gen cc_forbearance = forbearance if loan_type == 200;
gen student_forbearance = forbearance if loan_type==150;
gen auto_forbearance = forbearance if loan_type == 100;
gen HELOC_forbearance = forbearance if inlist(loan_type,120,220);
gen other_forbearance = forbearance if !inlist(loan_type,120,220,150,100,200,110);

preserve;
collapse (sum) Total_accounts = accounts_tag mortgage_forbearance forbearance cc_forbearance student_forbearance auto_forbearance HELOC_forbearance other_forbearance, by(Month);

foreach forbearance_code in mortgage_forbearance cc_forbearance student_forbearance auto_forbearance HELOC_forbearance other_forbearance{; 
	gen `forbearance_code'_pct = (`forbearance_code'/forbearance)*100;
};

graph bar mortgage_forbearance cc_forbearance student_forbearance auto_forbearance HELOC_forbearance other_forbearance, over(Month, relabel(1 "Jun '17" 2 "Jul '17" 3 "Aug '17" 4 "Sep '17" 5 "Oct '17" 6 "Nov '17" 7 "Dec '17" 8 "Jan '18" 9 "Feb '18" 10 "Mar '18" 11 "Apr '18"))
	stack
	title("Total forbearance by month")
	ytitle("Forbearance comment code (count)")
	leg(order(1 "Mortgage" 2 "Credit cards" 3 "Student loans" 4 "Auto loans" 5 "HELOCs" 6 "Other"));

graph bar mortgage_forbearance_pct cc_forbearance_pct student_forbearance_pct auto_forbearance_pct HELOC_forbearance_pct other_forbearance_pct, over(Month, relabel(1 "Jun '17" 2 "Jul '17" 3 "Aug '17" 4 "Sep '17" 5 "Oct '17" 6 "Nov '17" 7 "Dec '17" 8 "Jan '18" 9 "Feb '18" 10 "Mar '18" 11 "Apr '18"))
	stack
	title("Total forbearance by month")
	ytitle("Forbearance comment code (% of total)")
	leg(order(1 "Mortgage" 2 "Credit cards" 3 "Student loans" 4 "Auto loans" 5 "HELOCs" 6 "Other"));

restore;
gen mortgage_nat_cm = nat_dis_cm if loan_type == 110;
gen cc_nat_cm = nat_dis_cm if loan_type == 200;
gen student_nat_cm = nat_dis_cm if loan_type==150;
gen auto_nat_cm = nat_dis_cm if loan_type == 100;
gen HELOC_nat_cm = nat_dis_cm if inlist(loan_type,120,220);
gen other_nat_cm = nat_dis_cm if !inlist(loan_type,120,220,150,100,200,110);
tab other_nat_cm loan_type;

preserve;
collapse (sum) Total_accounts = accounts_tag mortgage_forbearance mortgage_nat_cm cc_nat_cm student_nat_cm auto_nat_cm HELOC_nat_cm other_nat_cm nat_dis_cm, by(Month);
list in 1/9;

foreach comment_code in mortgage_nat_cm cc_nat_cm student_nat_cm auto_nat_cm HELOC_nat_cm other_nat_cm {; 
	gen `comment_code'_pct = (`comment_code'/nat_dis_cm)*100;
};

graph bar 
	mortgage_nat_cm
	cc_nat_cm
	student_nat_cm
	auto_nat_cm 
	HELOC_nat_cm 
	other_nat_cm,
		over(Month, relabel(1 "Sep '17" 2 "Oct '17" 3 "Nov '17" 4 "Dec '17" 5 "Jan '18" 6 "Feb '18" 7 "Mar '18" 8 "Apr '18"))
		stack 
		title("Total natural disaster comments by loan type") 
		ytitle("Natural disaster comment code (count)")
		leg(order(1 "Mortgage" 2 "Credit cards" 3 "Student loans" 4 "Auto loans" 5 "HELOCs" 6 "Other"));
graph export `projectpath'/figures/nat_dis_code_by_type.png,replace;

graph bar 
	mortgage_nat_cm_pct
	cc_nat_cm_pct
	student_nat_cm_pct
	auto_nat_cm_pct
	HELOC_nat_cm_pct
	other_nat_cm_pct
	if !inlist(Month,6,7,8),
		over(Month, relabel(1 "Sep '17" 2 "Oct '17" 3 "Nov '17" 4 "Dec '17" 5 "Jan '18" 6 "Feb '18" 7 "Mar '18" 8 "Apr '18"))
		stack 
		title("Percent of natural disaster comments by loan type") 
		ytitle("Natural disaster comment code (% of total comments)")
		leg(order(1 "Mortgage" 2 "Credit cards" 3 "Student loans" 4 "Auto loans" 5 "HELOCs" 6 "Other"));
graph export `projectpath'/figures/nat_dis_code_by_type_per.png,replace;

log close;

shell echo -e "It's Done" | mail -s "STATA finished" "daniel.banko-ferran@cfpb.gov";
