	* gen one = 0.001 //#s in thousands
	* graph bar (sum) one, over(estatus_cd, label(angle(90))) ytitle(frequency) ylabel( , format(%8.0fc)) saving(estatus_cd_hist, replace)
	* graph export `projectpath'/figures/estatus_cd_hist.png, replace

	* graph bar (sum) one, over(condition_cd, label(angle(90))) ytitle(frequency) ylabel( , format(%8.0fc)) saving(condition_cd_hist, replace)
	* graph export `projectpath'/figures/condition_cd_hist.png, replace

	* graph bar (sum) one, over(status_cd, label(angle(90))) ytitle(frequency) ylabel( , format(%8.0fc)) saving(status_cd_hist, replace)
	* graph export `projectpath'/figures/status_cd_hist.png, replace

	* graph bar (sum) one if comment_cd != "00" & Month == 6, over(comment_cd, label(angle(90))) ytitle(frequency) ylabel( , format(%8.0fc)) title("comment codes June 2017")
	* graph export `projectpath'/figures/comment_cd_hist_June.png, replace

	* graph bar (sum) one if comment_cd != "00" & Month == 7, over(comment_cd, label(angle(90))) ytitle(frequency) ylabel( , format(%8.0fc)) title("comment codes July 2017")
	* graph export `projectpath'/figures/comment_cd_hist_July.png, replace

	* graph bar (sum) one if comment_cd != "00" & Month == 8, over(comment_cd, label(angle(90))) ytitle(frequency) ylabel( , format(%8.0fc)) title("comment codes August 2017")
	* graph export `projectpath'/figures/comment_cd_hist_August.png, replace

	* graph bar (sum) one if comment_cd != "00" & Month == 9, over(comment_cd, label(angle(90))) ytitle(frequency) ylabel( , format(%8.0fc)) title("comment codes September 2017")
	* graph export `projectpath'/figures/comment_cd_hist_September.png, replace

	* graph bar (sum) one if comment_cd != "00" & Month == 10, over(comment_cd, label(angle(90))) ytitle(frequency) ylabel( , format(%8.0fc)) title("comment codes October 2017")
	* graph export `projectpath'/figures/comment_cd_hist_October.png, replace

	* graph bar (sum) one if comment_cd != "00" & Month == 11, over(comment_cd, label(angle(90))) ytitle(frequency) ylabel( , format(%8.0fc)) title("comment codes November 2017")
	* graph export `projectpath'/figures/comment_cd_hist_November.png, replace

	* graph bar (sum) one if comment_cd != "00" & Month == 12, over(comment_cd, label(angle(90))) ytitle(frequency) ylabel( , format(%8.0fc)) title("comment codes December 2017")
	* graph export `projectpath'/figures/comment_cd_hist_December.png, replace

		//bysort Month consumer_nb : gen consumers_tag = (_n==1)
	* collapse (sum) Population = consumers_tag Payment_amount = actualpayment_am Total_debt = balance_wt cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt if payment_flag_2017==1, by(Month_last vantage_group)
	* //graph twoway (line Payment_amount Month_last if payment_flag_2017 == 1 & vantage_group == 1) || (line Payment_amount Month_last if payment_flag_2017 == 1 & vantage_group==2) //, by(vantage_group)
	* graph twoway line Payment_amount Month_last if vantage_group == 1  || line Payment_amount Month_last if vantage_group == 2 || line Payment_amount Month_last if vantage_group == 3 || line Payment_amount Month_last if vantage_group == 4

	* tab Payment_amount Month_last, mi
	* gen Year = substr(ReportingPeriod,1,4);
	* gen Month = month(date(substr(ReportingPeriod,5,3),"M"))
	* graph twoway line Total_debt Month //cc_debt student_debt auto_debt mortgage_debt HELOC_debt other_debt ReportingPeriod ylabel(0(2)8, angle(horizontal))
	* graph twoway line mortgage_debt Month
	* graph twoway line cc_debt student_debt auto_debt HELOC_debt other_debt Month

	// 5/18
	* #delim cr
* gen most_recent_payment = substr(paymentgrid,1,1)
* *bysort Month:tab most_recent_payment if !inlist(most_recent_payment,"0","C"), mi plot

* //enhanced status codes:
* gen trouble_status = cond(inlist(estatus_cd,"05","10","20","42","71","72"),1,0,.)
* *bysort Month: tab trouble_status, mi plot$Castl

* //graph bar (sum) deferred_payment, over(Month, relabel(1 "Jun '17" 2 "Jul '17" 3 "Aug '17" 4 "Sep '17" 5 "Oct '17" 6 "Nov '17" 7 "Dec '17" 8 "Jan '18" 9 "Feb '18")) 

* * bysort Month ptk_nb: gen accounts_tag = (_n==1)

* # delim ;

* gen mortgage_deferred_payment = deferred_payment if loan_type == 110;
* gen cc_deferred_payment = deferred_payment if loan_type == 200;
* gen student_deferred_payment = deferred_payment if loan_type==150;
* gen auto_deferred_payment = deferred_payment if loan_type == 100;
* gen HELOC_deferred_payment = deferred_payment if inlist(loan_type,120,220);
* gen other_deferred_payment = deferred_payment if !inlist(loan_type,110,200,150,100,120,220);

* gen mortgage_account = (loan_type==110);
* gen cc_account = (loan_type == 200);
* gen student_account = (loan_type==150);
* gen auto_account = (loan_type == 100);
* gen HELOC_account = inlist(loan_type,120,220);
* gen other_account = !inlist(loan_type,120,220,150,100,200,110);

* table loan_type Month, c(sum deferred_payment);
* pause;
* preserve;
* collapse (sum) other_account HELOC_account auto_account student_account cc_account mortgage_account accounts_tag mortgage_deferred_payment cc_deferred_payment student_deferred_payment auto_deferred_payment HELOC_deferred_payment other_deferred_payment, by(Month);

* * foreach deferred_account in mortgage_deferred_payment cc_deferred_payment student_deferred_payment auto_deferred_payment HELOC_deferred_payment other_deferred_payment {;

* gen student_deferred_payment_pct = (student_deferred_payment/student_account)*100;


* graph twoway 	scatter mortgage_deferred_payment_pct Month, connect(direct) sort(Month);
* graph twoway	scatter HELOC_deferred_payment_pct Month, connect(direct) sort(Month);
* graph twoway	scatter auto_deferred_payment_pct Month, connect(direct) sort(Month);
* graph twoway	scatter other_deferred_payment_pct Month, connect(direct) sort(Month);

* graph twoway scatter student_deferred_payment_pct Month, connect(direct) sort(Month);

* restore;

//collapse (sum) deferred_payment mortgage_deferred_payment cc_deferred_payment student_deferred_payment auto_deferred_payment HELOC_deferred_payment other_deferred_payment accounts_tag if comment_cd!="00", by(Month);

* foreach comment_code in mortgage_deferred_payment cc_deferred_payment student_deferred_payment auto_deferred_payment HELOC_deferred_payment other_deferred_payment {;
* 	gen `comment_code'_pct = (`comment_code'/deferred_payment)*100;
* };

* graph bar 
* 	mortgage_deferred_payment
* 	cc_deferred_payment
* 	student_deferred_payment
* 	auto_deferred_payment
* 	HELOC_deferred_payment
* 	other_deferred_payment,
* 		stack
* 		title("Total deferred payment by month")
* 		blabel(total)
* 		ytitle("Deferred payment comment code (count)")
* 		leg(order(1 "Mortgage" 2 "Credit cards" 3 "Student loans" 4 "Auto loans" 5 "HELOCs" 6 "Other"))
* 		over(Month, relabel(1 "Jun '17" 2 "Jul '17" 3 "Aug '17" 4 "Sep '17" 5 "Oct '17" 6 "Nov '17" 7 "Dec '17" 8 "Jan '18" 9 "Feb '18"));
* graph export `projectpath'/figures/deferred_payment_code_by_type.png, replace;

* graph bar 
* 	mortgage_deferred_payment_pct 
* 	cc_deferred_payment_pct
* 	student_deferred_payment_pct 
* 	auto_deferred_payment_pct
* 	HELOC_deferred_payment_pct 
* 	other_deferred_payment_pct,
* 		stack
* 		title("Total deferred payment by month")
* 		ytitle("Deferred payment comment code (% of total)")
* 		leg(order(1 "Mortgage" 2 "Credit cards" 3 "Student loans" 4 "Auto loans" 5 "HELOCs" 6 "Other"))
* 		over(Month, relabel(1 "Jun '17" 2 "Jul '17" 3 "Aug '17" 4 "Sep '17" 5 "Oct '17" 6 "Nov '17" 7 "Dec '17" 8 "Jan '18" 9 "Feb '18"));
* graph export `projectpath'/figures/deferred_payment_code_by_type_pct.png,replace;

* restore;

* gen mortgage_forbearance = forbearance if loan_type == 110;
* gen cc_forbearance = forbearance if loan_type == 200;
* gen student_forbearance = forbearance if loan_type==150;
* gen auto_forbearance = forbearance if loan_type == 100;
* gen HELOC_forbearance = forbearance if inlist(loan_type,120,220);
* gen other_forbearance = forbearance if !inlist(loan_type,120,220,150,100,200,110);

* preserve;
* collapse (sum) mortgage_forbearance forbearance cc_forbearance student_forbearance auto_forbearance HELOC_forbearance other_forbearance, by(Month);

* foreach forbearance_code in mortgage_forbearance cc_forbearance student_forbearance auto_forbearance HELOC_forbearance other_forbearance{; 
* 	gen `forbearance_code'_pct = (`forbearance_code'/forbearance)*100;
* };

* graph bar mortgage_forbearance cc_forbearance student_forbearance auto_forbearance HELOC_forbearance other_forbearance, over(Month, relabel(1 "Jun '17" 2 "Jul '17" 3 "Aug '17" 4 "Sep '17" 5 "Oct '17" 6 "Nov '17" 7 "Dec '17" 8 "Jan '18" 9 "Feb '18"))
* 	stack
* 	title("Total forbearance by month")
* 	ytitle("Forbearance comment code (count)")
* 	blabel(total)
* 	leg(order(1 "Mortgage" 2 "Credit cards" 3 "Student loans" 4 "Auto loans" 5 "HELOCs" 6 "Other"));
* graph export `projectpath'/figures/forbearance_code_by_type.png,replace;

* graph bar mortgage_forbearance_pct cc_forbearance_pct student_forbearance_pct auto_forbearance_pct HELOC_forbearance_pct other_forbearance_pct, over(Month, relabel(1 "Jun '17" 2 "Jul '17" 3 "Aug '17" 4 "Sep '17" 5 "Oct '17" 6 "Nov '17" 7 "Dec '17" 8 "Jan '18" 9 "Feb '18"))
* 	stack
* 	title("Total forbearance by month")
* 	ytitle("Forbearance comment code (% of total)")
* 	leg(order(1 "Mortgage" 2 "Credit cards" 3 "Student loans" 4 "Auto loans" 5 "HELOCs" 6 "Other"));
* graph export `projectpath'/figures/forbearance_code_by_type_pct.png,replace;