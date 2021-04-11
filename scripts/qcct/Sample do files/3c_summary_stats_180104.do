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
/** Sub-project:  	Summary stats tables 				      **/
/** Data Sources:	CCDB 0.1% File					      **/
/** Last Updated By:	Jialan Wang 					      **/
/** Last Updated: 	12/2017					              **/
/** Purpose:		This program creates table of summary statistics.     **/
/** 			This file can be run for consumer cards or small      **/
/** 			business cards by changing local macros at start.     **/
/*******************************************************************************/
/*******************************************************************************/

*************************************************************;
**** Start log file;
*************************************************************;
capture log close;
log using "$LOGS/3c_summary_stats.log", replace;

*************************************************************;
**** Locals;
*************************************************************;

local sampsize "point_1_percent";

/** Observation window: start and end year are inclusive **/
local sample_start 2008;
local sample_end 2014;

/******************************************************************************/
/** Step 1. Pull Data							     **/
/** This data set is very large, so restrictions are made when uploading     **/
/** the data. The data is restricted to the following:			     **/
/** a. CreditCardType-General purpose and private label accounts, no 	     **/
/**    business or corporate						     **/
/******************************************************************************/

foreach samp in smbus cons {;

	/******************************************************************************/
	/** Read in processed data file					     	     **/
	/******************************************************************************/

	use $DATA/analysis_sample_`samp'_`sampsize', clear;

	/******************************************************************************/
	/** Summary stats tables					     	     **/
	/******************************************************************************/
	gen row=.;

	*age ;
	local base_vars "income fico acct_age CurrentCreditLimit CycleEndingRetailAPR JointAccountFlag";
	local use_vars "utiliz CycleBeginningBalance CycleEndingBalancePromo_1 CycleEndingBalanceCash CycleEndingBalancePenalty PurchaseVolume_1 nzero_purch";
	local payment_vars "fraction_paid min_due ActualPaymentAmount paid_ltmin row dpd_any dpd_lt5 dpd_lt15 dpd_lt30 dpd_30p dpd_60p row nzero_late_fee nzero_fee_olim nzero_tot_past_due ";
	local binvars " paid_* nzero* *Flag dpd_*";

	eststo clear;
	eststo all: qui estpost summarize `base_vars' row row `use_vars' row row `payment_vars', det;



	foreach val in 20 40 60 90 {;
		eststo control`val': qui estpost sum if treat`val' == 0, det;
		eststo treat`val': qui estpost sum if treat`val' == 1, det;
	};



	estout using $TABLES/summary_stats_`samp'.txt , cells("mean sd(fmt(a1) drop(`binvars')) p25( drop(`binvars') ) p50( drop(`binvars') ) p75( drop(`binvars') ) count") style(tab) label nonumber replace collabels("Mean" "Stdev" "P25" "P50" "P75" "N");

}
;


/******************************************************************************/
/** Close log file **/
/******************************************************************************/

log close;
