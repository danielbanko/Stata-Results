#delimit ;
clear;
set more off;
set scheme cfpb;

*global pathipa /home/work/ipa/wangj/CCDB/duedate;
global pathipa /home/cfpb/ricksj/CCDB/cardact_duedate;

/* Set data directories */
global HOME 		"$pathipa"; 
global DATA 		"$pathipa/data"; 
global LOGS 		"$pathipa/log"; 
global DOFILES 		"$pathipa/do"; 
global TABLES 		"$pathipa/table"; 
global FIGURES 		"$pathipa/figure"; 
global REGS 		"$pathipa/reg"; 

/*******************************************************************************/
/*******************************************************************************/
/** Project Name: 	Credit Card Due Dates 				      **/
/** Sub-project:  	Preliminary Analysis on Due Dates 		      **/
/** Data Sources:	CCDB 0.1% File					      **/
/** Last Updated By:	Jialan Wang 					      **/
/** Last Updated: 	12/2017					              **/
/** Purpose:		This program pulls CCDB sample, cleans data, and      **/
/**			conducts preliminary analysis. PA includes the	      **/
/**			following: 					      **/
/** 			a. Histogram of payment timing measures		      **/
/** 			b. Time series of DOM for due date		      **/
/** 			d. Time series of average same due date		      **/
/** 			e. Time series of average past due rates   	      **/
/** 			f. Time series of average past due rates by modal chg **/
/** 			This file can be run for consumer cards or small      **/
/** 			business cards by changing local macros at start.     **/
/** Sample selection: 	Restrict to nonsecured, non 3rd party acquired,       **/
/** 			single borrower, FICO at origination available,	      **/
/** 			account not opened after June 2009	      	      **/
/*******************************************************************************/
/*******************************************************************************/

*************************************************************;
**** Start log file;
*************************************************************;
capture log close;
log using "$LOGS/3b_analysis_desc.log", replace;

*************************************************************;
**** Locals;
*************************************************************;

local sampsize "point_1_percent";

/** Sample type: consumer card (ctype,1), business card (ctype,3) **/
local cons_type 1;
local smbus_type 3;

local 1 a;
local 3 b;
local cons_lab "Consumer:";
local smbus_lab "Small Bus:";

/** Observation window: start and end year are inclusive **/
local sample_start 2008;
local sample_end 2014;

/** Vertical line in time series graphs, indicates policy implementation yrmo **/
local tline "22feb2010";
local tline_all "20aug2009 22feb2010 22aug2010";
*local tline_all "2009m8 2010m2 2010m8";

/******************************************************************************/
/** Step 1. Pull Data							     **/
/** This data set is very large, so restrictions are made when uploading     **/
/** the data. The data is restricted to the following:			     **/
/** a. CreditCardType-General purpose and private label accounts, no 	     **/
/**    business or corporate						     **/
/******************************************************************************/

foreach samp in /** cons **/ smbus {;

	/******************************************************************************/
	/** Read in processed data file					     	     **/
	/******************************************************************************/

	use $DATA/analysis_sample_`samp'_`sampsize' if year(stmt_date)>=`sample_start' & year(stmt_date)<=`sample_end', clear;

	/******************************************************************************/
	/** Report descriptive statistics of key variables in log file		     **/
	/******************************************************************************/
	
	/**
	sum;
	sum, det;
	codebook;

	/** Check whether ReferenceNumber is unique across BankIDs		     **/
	unique ReferenceNumber BankId;
	unique ReferenceNumber;

	cap noisily tab DaysPastDue;
	cap noisily tab grace_period;
	tab CreditCardType;
	tab ProductType;
	tab LendingType;
	tab CreditCardSecuredFlag;
	tab LoanChannel;
	tab JointAccountFlag;

	tab CreditCardType ProductType;

	/******************************************************************************/
	/** Examine statement dates, due dates, and grace periods		     **/
	/******************************************************************************/

	format %td AccountCycleEndDate NextPaymentDueDate;

	sort ReferenceNumber stmt_date;
	list ReferenceNumber stmt_date due_date grace_period same_dom_* days_bt_* same_days_bt_* same_grace_* in 1/1000;
	compare stmt_date due_date;

	/******************************************************************************/
	/** Examine delinquency measures					     **/
	/******************************************************************************/

	list ReferenceNumber stmt_date due_date CycleBeginningBalance MinimumPaymentDue  ActualPaymentAmount DaysPastDue paid_ltmin nzero_late_fee nzero_tot_past_due in 1/1000;

	sum dpd_any paid_ltmin nzero_late_fee nzero_tot_past_due ;
	pwcorr dpd_any paid_ltmin nzero_late_fee nzero_tot_past_due ;
	compare dpd_any nzero_late_fee;
	compare dpd_any nzero_tot_past_due;

	/******************************************************************************/
	/** Examine characteristics of treatment groups				     **/
	/******************************************************************************/

	egen account_tag = tag(ReferenceNumber);
	
	tab num_obs_pre if account_tag == 1;
	sum num_obs_pre avg_same_dom_due_t_t1 treat* if account_tag == 1;
	
	foreach val in 20 40 60 90 {;
		tab treat`val' if account_tag == 1;
	};
	**/


	/******************************************************************************/
	/** b. Histograms of due date and statement date day of month, grace period, pre period vs. post period **/
	/******************************************************************************/
	
	preserve;
		local tit_dom_due "Due Date Day of Month";
		local tit_dom_stmt "Statement Date Day of Month";
		local tit_days_bt_due "Days Between Due Dates";
		local tit_days_bt_stmt "Days Between Due Statements";
		local tit_grace_period "Grace Period";
		local tit_DaysPastDue "Days Past Due";

		local xtit_dom_due "Day of Month";
		local xtit_dom_stmt "Day of Month";
		local xtit_days_bt_due "# of days";
		local xtit_days_bt_stmt "# of days";
		local xtit_grace_period "Grace Period";
		local xtit_DaysPastDue "# of days";

		local post0_lab "Pre-reform";
		local post1_lab "Post-reform";
		local post0_suf "pre";
		local post1_suf "post";

		/** Winsorize **/
		foreach var in grace_period days_bt_due days_bt_stmt DaysPastDue {;
			sum `var', det;
			replace `var'= `r(p1)' if `var' < `r(p1)' & ~missing(`var');
			replace `var'= `r(p99)' if `var' > `r(p99)' & ~missing(`var');
		};

		/** Plot histograms **/
		foreach var in dom_due dom_stmt days_bt_due days_bt_stmt grace_period DaysPastDue {;				
			foreach p in 0 1 {;
				histogram `var' if post==`p', 
					discrete
					xtitle("`xtit_`var''")
					title("a. `post`p'_lab'")
					saving("$FIGURES/hist_`var'_`samp'_`post`p'_suf'.gph", replace)
					;
			
			/** Combine graphs and export as PDF, png, and gph**/
				gr combine "$FIGURES/hist_`var'_`samp'_`post`p'_suf'.gph"
					"$FIGURES/hist_`var'_`samp'_`post`p'_suf'.gph"
					,
					title("`tit_`var''") ycom xcom
					saving("$FIGURES/hist_`var'_`samp'.gph", replace);
				
			};
		};

		
			graph export "$FIGURES/hist_`var'_`samp'.pdf", as(pdf) replace;
			cap graph export "$FIGURES/hist_`var'_`samp'.png", replace;
		

	restore;




	/******************************************************************************/
	/** c. Time series of timing and delinquency measures **/
	/******************************************************************************/

	preserve;
		loc vars "days_bt_due days_bt_stmt same_dom_due_t_t1 same_dom_stmt_t_t1 grace_period DaysPastDue dpd_* paid_ltmin nzero_late_fee nzero_tot_past_due ";
		loc mean_vars "(mean)";
		loc med_vars "(median)";

		local tit_same_dom_due_t_t1 "Same Due Date DOM, t and t-1";
		local tit_same_dom_stmt_t_t1 "Same Statement DOM, t and t-1";

		local ytit_days_bt_due "# of days";
		local ytit_days_bt_stmt "# of days";
		local ytit_same_dom_due_t_t1 "Fraction With Same DOM";
		local ytit_same_dom_stmt_t_t1 "Fraction With Same DOM";
		local ytit_grace_period "Grace Period";
		
		foreach var of varlist `vars' {;
			loc mean_vars "`mean_vars' mean_`var'=`var'";
			loc med_vars "`mean_vars' med_`var'=`var'";
		};
	
		collapse `mean_vars' `med_vars', by(stmt_date);

		foreach var of varlist `vars' {;				
			graph twoway 	(scatter mean_`var' stmt_date, msymbol(O) connect(l))
					(scatter med_`var' stmt_date, msymbol(T) lp(shortdash) connect(l))
					,
					legend(rows(2)
						lab(1 "Mean")
						lab(2 "Median")
						)
					tline(`tline')
					xtitle("Statement Date")
					ytitle("# Days")
					title("``samp'_lab' `tit_`var''")
					saving("$FIGURES/time_`var'_`samp'.gph", replace)
					;
			graph export "$FIGURES/time_`var'_`samp'.pdf", as(pdf) replace;
			cap graph export "$FIGURES/time_`var'_`samp'.png", replace;
		};
	restore;

	/******************************************************************************/
	/** b. Histogram of treatment variable **/
	/******************************************************************************/

	preserve;
		loc vars "num_obs_pre avg_same_dom_due_t_t1";

		local tit_num_obs_pre "# of obs per account in pre-period";
		local tit_avg_same_dom_due_t_t1 "% of months with same due date";

		local xtit_num_obs_pre "# of obs";
		local xtit_avg_same_dom_due_t_t1 "Average % months w/ same DOM per account";

		local disc_num_obs_pre disc;
		local disc_avg_same_dom_due_t_t1 "";

		collapse (first) `vars', by(ReferenceNumber);

		foreach var in `vars' {;				
			histogram `var', 
				`disc_`var''
				xtitle("`xtit_`var''")
				title("``samp'_lab' `tit_`var''")
				saving("$FIGURES/hist_`var'_`samp'.gph", replace)
				;
			graph export "$FIGURES/hist_`var'_`samp'.pdf", as(pdf) replace;
			cap graph export "$FIGURES/hist_`var'_`samp'.png", replace;
		};
	restore;	

	/******************************************************************************/
	/** c. Time series of delinquency measures by various measures of treatment group **/
	/******************************************************************************/

};

/******************************************************************************/
/** Close log file **/
/******************************************************************************/

log close;
