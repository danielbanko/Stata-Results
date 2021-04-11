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

# delim ;

bysort Month ptk_nb: gen accounts_tag = (_n==1);
count if accounts_tag == 1;
bysort ptk_nb: gen unique_accounts_tag = (_n==1);
count if unique_accounts_tag == 1;

* table Month loan_type if inlist(loan_type,110,200,150,100,220), c(sum unique_accounts_tag) column row center;

//FORBEARANCE AND DEFERRED PAYMENTS
gen deferred_payment = cond(comment_cd == "29",1,0,.);
gen forbearance = cond(comment_cd == "CP",1,0,.);
gen combined_forb_defe = cond(inlist(comment_cd,"CP","29"),1,0,.);
* table Month loan_type if inlist(loan_type,110,200,150,100,220), c(sum forbearance) column row center;

* bysort Month: egen forbearance_sum = sum(forbearance);
* graph twoway scatter forbearance_sum Month if inlist(loan_type, 110, 200,150,100,200), connect(direct) sort(Month)
* 			title("Total accounts in forbearance by month") 
* 			ytitle("Accounts in forbearance (sum)") 
* 			xline(9) 
* 			xla(6 "Jun" 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec" 13 "Jan" 14 "Feb")
* 			xtick(6(1)14);

* graph bar (sum) 
* 	forbearance,
* 		title("Total accounts in forbearance by month")
* 		blabel(total)
* 		ytitle("Accounts in forbearance (sum)")
* 		over(Month, relabel(1 "Jun '17" 2 "Jul '17" 3 "Aug '17" 4 "Sep '17" 5 "Oct '17" 6 "Nov '17" 7 "Dec '17" 8 "Jan '18" 9 "Feb '18"));

* graph export `projectpath'/figures/forbearance_sum_trends.png, replace;


* graph bar (sum) 
* 	deferred_payment,
* 		title("Total deferred payment accounts by month")
* 		blabel(total)
* 		ytitle("Deferred payment comment code (sum)")
* 		over(Month, relabel(1 "Jun '17" 2 "Jul '17" 3 "Aug '17" 4 "Sep '17" 5 "Oct '17" 6 "Nov '17" 7 "Dec '17" 8 "Jan '18" 9 "Feb '18"));

* graph export `projectpath'/figures/deferred_payment_trends.png, replace;

* bysort Month: egen deferred_payment_sum = sum(deferred_payment);
* graph twoway scatter deferred_payment_sum Month if inlist(loan_type,110,200,150,100,220), connect(direct) sort(Month) 
* 			title("Total accounts with deferred payments by month") 
* 			ytitle("Deferred payments (sum)") 
* 			xline(9) 
* 			xla(6 "Jun" 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec" 13 "Jan" 14 "Feb")
* 			xtick(6(1)14);

* 	graph export `projectpath'/figures/deferred_payment_trends.png, replace;

graph bar (sum) deferred_payment forbearance,
		title("Total accounts deferred or in forbearance by month")
		blabel(bar)
		stack
		ytitle("Comment codes (sum)")
		over(Month, relabel(1 "Jun '17" 2 "Jul '17" 3 "Aug '17" 4 "Sep '17" 5 "Oct '17" 6 "Nov '17" 7 "Dec '17" 8 "Jan '18" 9 "Feb '18" 10 "Mar '18" 11 "Apr '18"))
		legend(order(1 "Deferred payment" 2 "Forbearance"));

graph export `projectpath'/figures/forb_defe_combined_sum_trends.png, replace;


//NONDECREASING BALANCE ACCOUNTS
* gen no_decrease = cond(diff`i' >= 0,1,0,.);
* replace no_decrease`i' = . if diff`i' == .;
* gen positive_balance = cond(balance_wt > 0,1,0,.);

* gen late_account = cond(!inlist(substr(paymentgrid,1,1),"0","C"),1,0,.) if balance_wt > 0 & accounts_tag == 1;
* gen flag_account = cond(!inlist(comment_cd,"29","CP"),1,0,.) if balance_wt > 0 & !inlist(substr(paymentgrid,1,1),"0","C") & accounts_tag == 1;
* table Month, c(sum flag_account sum late_account sum accounts_tag) //there is a decrease in the number of accounts marked late.

sort consumer_nb ptk_nb Month;
* gen balance_wt = balance_am * ecoa_wt;
gen balance_ref = .;
gen diff = .;
foreach i in 6 7 8 9 10 11 12 13 14 15 {;
	di "Month `i'";
	replace balance_ref = balance_wt if Month == `i';
	bysort consumer_nb ptk_nb (balance_ref): replace balance_ref = balance_ref[1];
	sort consumer_nb ptk_nb Month;
	replace diff = balance_wt - balance_ref if Month == `i' + 1;
	replace balance_ref = .;
};

gen no_decrease = cond(diff >= 0,1,0,.) if balance_wt > 0 & diff != .;
gen credit_card = cond(loan_type == 200,1,0,.);
gen mort_acc = cond(loan_type==110,1,0,.);
gen stu_acc = cond(loan_type==150,1,0,.);
gen auto_acc = cond(loan_type==100,1,0,.);

table loan_type Month if inlist(loan_type,110,200,150,100,120,220), c(sum no_decrease);
table Month loan_type if inlist(loan_type,110,200,150,100), c(sum no_decrease sum accounts_tag) column row center;

preserve;

//NONDECREASING BALANCE ACCOUNTS AS PERCENTAGE OF TOTAL GRAPH
collapse (sum) credit_card mort_acc stu_acc auto_acc no_decrease, by(Month loan_type);
* graph twoway (scatter no_decrease Month if loan_type==110, mlabel(no_decrease) mlabposition(6) connect(direct) sort(Month)) 
* 			 (scatter no_decrease Month if loan_type==200, 	mlabel(no_decrease) mlabposition(12) connect(direct) sort(Month))
* 			 (scatter no_decrease Month if loan_type==150,	mlabel(no_decrease) mlabposition(12) connect(direct) sort(Month))
* 			 (scatter no_decrease Month if loan_type==100,
* 			 	connect(direct) 
* 				sort(Month) 
* 			  	title("Accounts with nondecreasing balance amount")	
* 				ytitle("# of accounts (sum)")
* 				ytick(0(50000)300000)
* 				ylab(0 "0" 50000 "50,000" 100000 "100,000" 150000 "150,000" 200000 "200,000" 250000 "250,000" 300000 "300,000")
* 				xla(7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18") 
* 				xtick(7(1)15)
* 				mlabel(no_decrease)
* 				mlabposition(12)
* 				legend(order(1 "Mortgages" 2 "Credit cards" 3 "Student loans" 4 "Auto loans")));

* graph export `projectpath'/figures/accounts_no_decrease.png, replace;

gen cc_no_dec_per = round(no_decrease/credit_card*100,.01) if loan_type == 200;
gen mort_no_dec_per = round(no_decrease/mort_acc*100,.01) if loan_type == 110;
gen stu_no_dec_per = round(no_decrease/stu_acc*100,.01) if loan_type == 150;
gen auto_no_dec_per = round(no_decrease/auto_acc*100,.01) if loan_type == 100;

drop if Month == 6;
graph twoway (scatter stu_no_dec_per Month,	mlabel(stu_no_dec_per) mlabposition(12) connect(direct) sort(Month))
			 (scatter mort_no_dec_per Month,  mlabposition(12) connect(direct) sort(Month))
			 (scatter cc_no_dec_per Month, mlabel(cc_no_dec_per) mlabposition(12) connect(direct) sort(Month)) 
			 (scatter auto_no_dec_per Month,
			 	connect(direct) 
				sort(Month) 
			  	title("Accounts with nondecreasing balance amount")	
				ytitle("% of accounts (by type)")
				xla(7 "Jul '17" 8 "Aug '17" 9 "Sep '17" 10 "Oct '17" 11 "Nov '17" 12 "Dec '17" 13 "Jan '18" 14 "Feb '18" 15 "March '18" 16 "April '18") 
				xtick(7(1)15)
				mlabel(auto_no_dec_per)
				mlabposition(12)
				legend(order(1 "Student loans" 2 "Mortgages" 3 "Credit cards" 4 "Auto loans")));

graph export `projectpath'/figures/accounts_perc_no_decrease.png, replace;



restore;

//COUNTY DATA
* preserve
* collapse (sum) forbearance deferred_payment accounts_tag, by(county Month)
* table Month, c(sum forbearance sum deferred_payment) m
* table county Month, c(sum forbearance sum deferred_payment) m

* gen forbearance_proportion = .
* replace forbearance_proportion = 0 if accounts_tag == 0
* bysort county Month: replace forbearance_proportion = forbearance/accounts_tag*100 if accounts_tag != 0

* gen deferred_payment_proportion = .
* replace deferred_payment_proportion = 0 if accounts_tag == 0
* bysort county Month: replace deferred_payment_proportion = deferred_payment/accounts_tag*100 if accounts_tag != 0

* bysort Month county: egen total_forbearance = sum(forbearance)
* sum total_forbearance
* gsort - total_forbearance
* list Month county total_forbearance in 1/10

* bysort Month county: egen total_deferred_payment = sum(deferred_payment)
* sum total_deferred_payment
* gsort - total_deferred_payment
* list Month county total_deferred_payment in 1/10

* table Month county, c(sum forbearance  sum accounts_tag) column center
* table Month county, c(sum deferred_payment sum accounts_tag sum deferred_payment_proportion) column center


log close;

shell echo -e "It's Done" | mail -s "STATA finished" "daniel.banko-ferran@cfpb.gov";

