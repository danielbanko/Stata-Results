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
/** Last Updated By:	Judie Ricks 					      **/
/** Last Updated: 	1/2017						      **/
/** Purpose:		This program pulls CCDB sample, cleans data, and      **/
/**			saves analysis datasets for both consumer cards       **/
/**                     and small business cards                              **/
/*******************************************************************************/
/*******************************************************************************/

*************************************************************;
**** Start log file;
*************************************************************;
capture log close;
log using "$LOGS/3a_process_files.log", replace;

*************************************************************;
**** Locals;
*************************************************************;

local sampsize "point_1_percent";

/** Sample type: consumer card (ctype,1), business card (ctype,3) **/
local cons_type 1;
local smbus_type 3;

local 1 a;
local 3 b;
local a "Consumer:";
local b "Small Bus:";

/******************************************************************************/
/** Step 1. Pull Data							     **/
/** This data set is very large, so restrictions are made when uploading     **/
/** the data. The data is restricted to the following:			     **/
/** a. CreditCardType-General purpose and private label accounts, no 	     **/
/**    business or corporate						     **/
/******************************************************************************/

/*******************************************************************************
Other variables of potential interest:
	AccountState AccountZipCode AccountCountry BorrowerIncome 
	BorrowerIncomeType UpdatedBorrowerIncome UpdatedBorrowerIncomeType 
	DateUpdatedBorrowerIncome BankId
*******************************************************************************/

loc panel_vars "ReferenceNumber PeriodId AccountCycleEndDate NextPaymentDueDate BankId";
loc card_vars "CreditCardType ProductType LendingType CreditCardSecuredFlag LoanChannel AccountOriginationDate";
loc acct_vars "OriginalCreditLimit CurrentCreditLimit MultipleBankingRelationshipFlag MultipleCardRelationshipFlag JointAccountFlag CurrentCashAdvanceLimit CycleEndingBalance* CashAdvanceVolume BalanceTransferVolume FeeNet* CycleBeginningBalance AverageDailyBalance CycleEndingRetailAPR PurchaseVolume FinanceCharge CycleEndActiveFlag";
loc cust_vars "BorrowerIncome UpdatedBorrowerIncome OriginalFicoScorePrimBorrower  RefreshedFicoScorePrimBorrower";
loc payment_vars "MinimumPaymentDue TotalPaymentDue ActualPaymentAmount TotalPastDue DaysPastDue FeeNetLateAmount TotalPastDue CreditCardSecuredFlag";

local vars "`panel_vars' `card_vars' `payment_vars' `acct_vars' `cust_vars' `payment_vars'";	

/**
use `vars' if inlist(CreditCardType,3) using 
		"/home/data/projects/CCDB/ProcessedData/Final_Data_Old_CCDB/CFPB_OCC_`sampsize'.dta"
		, clear;
**/

foreach samp in cons smbus {;

	use `vars' if inlist(CreditCardType,``samp'_type') using 
		"/home/data/projects/CCDB/ProcessedData/Final_Data_Old_CCDB/CFPB_OCC_`sampsize'.dta"
		, clear;

	* & CreditCardSecuredFlag==0 & JointAccountFlag==0 & OriginalFicoScorePrimBorrower<=900;

	/******************************************************************************/
	/** Step 1. Create timing variables					     **/
	/******************************************************************************/

	/** a. Convert PeriodID from numeric, length 8 format into yr moy and dom **/
	*gen int date=mdy(floor(mod(PeriodId,10000)/100), mod(PeriodId,100),floor(PeriodId/10000));

	/** Define statement and due dates **/
	gen int stmt_date=AccountCycleEndDate;
	gen int due_date=NextPaymentDueDate;
	format %td stmt_date due_date;

	gen grace_period = NextPaymentDueDate - AccountCycleEndDate;

	/** Day of month of statement and due date **/
	/** Measure constant dom, constant days between **/

	foreach var in due stmt {;
		gen dom_`var' = day(`var'_date);

		gen int `var'_yr_mon=mofd(`var'_date);
		format %tm `var'_yr_mon;

		bysort ReferenceNumber (`var'_date): gen same_dom_`var'_t_t1=(dom_`var'[_n]==dom_`var'[_n-1]) if _n > 1;
		* & `var'_yr_mon[_n] == `var'_yr_mon[_n-1]+1;

		by ReferenceNumber (`var'_date): gen days_bt_`var'=(`var'_date[_n]-`var'_date[_n-1]) if _n > 1;
		by ReferenceNumber (`var'_date): gen same_days_bt_`var'=(days_bt_`var'[_n]==days_bt_`var'[_n-1]) if _n > 1;
	};

	/** Measure constant grace periods **/
	local var stmt;
	bysort ReferenceNumber (`var'_date): gen same_grace_t_t1=(grace_period[_n]==grace_period[_n-1]) if _n > 1;


	/******************************************************************************/
	/** Step 1. Clean descriptive variables					     **/
	/******************************************************************************/

	foreach var in OriginalCreditLimit CurrentCreditLimit BorrowerIncome UpdatedBorrowerIncome {;
		replace `var' = . if `var'==0;
	};

	foreach var in OriginalFicoScorePrimBorrower RefreshedFicoScorePrimBorrower {;
		replace `var' = . if `var' < 300 | `var' > 1000;
	};

	/** Generate credit utilization measure **/
	gen utiliz=CycleBeginningBalance/CurrentCreditLimit;
		replace utiliz=1 if utiliz > 1 & ~missing(utiliz);
		replace utiliz=0 if utiliz < 0 & ~missing(utiliz);

	*** use best available income and fico;
	gen fico=RefreshedFicoScorePrimBorrower;
	replace fico = OriginalFicoScorePrimBorrower if missing(fico) & ~missing(OriginalFicoScorePrimBorrower);

	gen income=UpdatedBorrowerIncome;
	replace income=BorrowerIncome if missing(UpdatedBorrowerIncome) & ~missing(BorrowerIncome);
	qui: sum income, det;
	replace income=`r(p99)' if income > `r(p99)' & ~missing(income) ;

	
	*** Backfill and forward fill;
	foreach var in fico income {;
		gsort +ReferenceNumber -stmt_date;
		by ReferenceNumber: replace fico = fico[_n-1] if _n > 1 & missing(fico) & ~missing(fico[_n-1]);
		bysort ReferenceNumber (stmt_date): replace fico = fico[_n-1] if _n > 1 & missing(fico) & ~missing(fico[_n-1]);
	};



	foreach var in PurchaseVolume CycleEndingBalancePromo FeeNetLateAmount TotalPastDue FeeNetOverLimitAmount FeeNetNSFAmount {;
		local short=subinstr("`var'","Promotional","Promo",.);
		local short=subinstr("`short'","Amount","",.);

		bysort ReferenceNumber (stmt_yr_mon): gen `short'_1 = `var'[_n-1] if _n > 1 & stmt_yr_mon==stmt_yr_mon[_n-1]+1;
	};

	local short_FeeNetLate_1 "late_fee";
	local short_TotalPastDue_1 "tot_past_due";
	local short_FeeNetOverLimit_1 "fee_olim";
	local short_PurchaseVolume_1 "purch";

	foreach var in FeeNetLate_1 TotalPastDue_1 FeeNetOverLimit_1 PurchaseVolume_1 {;
		gen nzero_`short_`var''=(`var' > 0) if ~missing(`var');
	};

	gen acct_age = (dofm(stmt_yr_mon)-AccountOriginationDate)/365;

	/******************************************************************************/
	/** Step 2. Create delinquency variables				     **/
	/******************************************************************************/

	gen dpd_any=(DaysPastDue>0) if ~missing(DaysPastDue);
	foreach d in 5 10 15 30 {;
		gen dpd_lt`d'=inrange(DaysPastDue,1,`=`d'-1');
	};
	foreach d in 30 60 {;
		gen dpd_`d'p=(DaysPastDue>=`d') if ~missing(DaysPastDue);
	};


	/******************************************************************************/
	/** Step 3. Payment variables from minimum payments			     **/
	/******************************************************************************/

	*** #### Need to check about timing to make sure all the delinq measures line up and;
	*** #### aren't shifted by 1 month;

	local short_MinimumPaymentDue "min_due";
	local short_ActualPaymentAmount "dolls_pay";

	sort ReferenceNumber stmt_date;
	foreach var in MinimumPaymentDue ActualPaymentAmount {;
		by ReferenceNumber (stmt_date): gen `short_`var''
		= `var'[_n-1] if _n > 1;
	};


	**< Min payment;
	gen payment_bin = -1 if CycleBeginningBalance <= 0;
	replace payment_bin = 0 if ActualPaymentAmount < min_due & ActualPaymentAmount < CycleBeginningBalance & min_due > 0 & ~missing(min_due) & ~missing(CycleBeginningBalance);
	** Min payment exact;
	replace payment_bin = 10 if dolls_pay==floor(min_due) & min_due > 0 & missing(payment_bin) & ~missing(min_due) & ~missing(CycleBeginningBalance);
	** consider <= 0 payments = to min if min <= 0;
	replace payment_bin = 10 if dolls_pay<=0 & min_due <= 0 & missing(payment_bin)  & ~missing(min_due) & ~missing(CycleBeginningBalance);
	**Full;
	replace payment_bin = 2 if ActualPaymentAmount >= CycleBeginningBalance & missing(payment_bin)  & ~missing(min_due) & ~missing(CycleBeginningBalance);
	** Min payment 50;
	replace payment_bin = 11 if dolls_pay <= floor(min_due)+50 & min_due > 0 & missing(payment_bin)  & ~missing(min_due) & ~missing(CycleBeginningBalance);
	replace payment_bin = 11 if dolls_pay<=50 & min_due <= 0 & missing(payment_bin)  & ~missing(min_due) & ~missing(CycleBeginningBalance);
	**Min to full;
	replace payment_bin = 99 if missing(payment_bin)  & ~missing(min_due) & ~missing(CycleBeginningBalance);

	label def payment_bin 0 "< min" 2 "Full" 10 "Min exact" 11 "Min + 50" 99 "Min to full", replace;
	label val payment_bin payment_bin;

	** Classification of payments;
	gen byte paid_full = inlist(payment_bin,1,2) if ~missing(min_due) & ~missing(CycleBeginningBalance);
	gen byte paid_min_exact = (payment_bin==10) if ~missing(min_due) & ~missing(CycleBeginningBalance);
	gen byte paid_min_50 = inlist(payment_bin,10,11) if ~missing(min_due) & ~missing(CycleBeginningBalance);
	gen byte paid_ltmin = (payment_bin==0) if ~missing(min_due) & ~missing(CycleBeginningBalance);
	gen byte paid_mintofull = (payment_bin==99) if ~missing(min_due) & ~missing(CycleBeginningBalance);

	gen fraction_paid=ActualPaymentAmount/CycleBeginningBalance  if ~missing(min_due) & ~missing(CycleBeginningBalance);
	replace fraction_paid=. if CycleBeginningBalance < 0 & ~missing(fraction_paid)  & ~missing(min_due) & ~missing(CycleBeginningBalance);	
	replace fraction_paid=0 if ActualPaymentAmount < 0 & CycleBeginningBalance > 0 & ~missing(fraction_paid) & ~missing(min_due) & ~missing(CycleBeginningBalance);
	replace fraction_paid=1 if fraction_paid > 1 & ~missing(fraction_paid) & ~missing(min_due) & ~missing(CycleBeginningBalance);	


	/******************************************************************************/
	/** Step 3. Create difference-in-difference indicators			     **/
	/******************************************************************************/

	/** Post indicator**/
	gen post= stmt_date >= mdy(2,22,2010) & ~missing(stmt_date) ;

	/** Create fixed due date measures **/
	local var due;
	bysort ReferenceNumber: egen t=mean(same_dom_`var'_t_t1) if post==0;
	by ReferenceNumber: egen t2=count(same_dom_`var'_t_t1) if post==0;
	by ReferenceNumber: egen avg_same_dom_`var'_t_t1=max(t);
	by ReferenceNumber: egen num_obs_pre=max(t2);
	drop t t2;

	/** Specify the treatment variable, in case we want to try variations **/
	local treat_var "avg_same_dom_due_t_t1";

	foreach val in 20 40 60 90 {;
		/** treat`val' = 1 for accounts with < `val' of months with same due date **/	
		gen treat`val'=`treat_var' < 0.`val' if ~missing(`treat_var') ;
	};


	/******************************************************************************/
	/** Step 2. Save dataset						     **/
	/******************************************************************************/
	
	compress;
	save $DATA/analysis_sample_`samp'_`sampsize', replace ;
};

/******************************************************************************/
/** Close log file **/
/******************************************************************************/

log close;
