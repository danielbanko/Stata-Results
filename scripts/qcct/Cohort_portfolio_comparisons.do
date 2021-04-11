#delim ;
set more off;
set rmsg on, permanent;
cap log close; 
set scrollbufsize 2000000;
set trace off;
set scheme cfpb, permanently;
cap set processors 8;
pause on;

log using /home/work/projects/Experian/Shared/Litwin/logs/Cohort_portfolio_comparisons.txt, replace text;

local CCPData 		/home/data/projects/Experian/ProcessedData/Stata/;
local TradeVars 	consumer_nb ptk_nb kob_cd accounttype_cd balance_am balance_dt company_nb subscriber_nb estatus_cd condition_cd comment_cd ecoa_cd limit_am paymentgrid paymentgrid_cd open_dt;
/**/
foreach year in 2004
				2007
				2010
				2013
				2016
				{;
	*Read in score file to develop list of consumers in cohort;
		use consumer_nb vantage_sc deceased_cd birthyear using `CCPData'score.sample.dec`year'.dta, clear;
		drop if deceased_cd==1;
		drop deceased_cd;

		drop if vantage_sc<300 | vantage_sc>850;

		if ("`year'"<"2010") {;
			drop birthyear;
			merge 1:1 consumer_nb using `CCPData'score.sample.jun2010.dta, keepusing(birthyear);
			drop if _merge==2;
			drop _merge;

			gen birth = (birthyear~=.);
			tab birth;
			keep if birth==1;
			drop birth;
		};

		gen age = `year' - birthyear;
		gen cohort=1 if age>=55 & age<=61;
		replace cohort=2 if age>=62 & age<=66;
		drop if cohort==.;

		gen ReportingPeriod = "`year'12";

	*merge in the tradeline file;
		merge 1:m consumer_nb using `CCPData'tradeline.sample.dec`year'.dta, keep(match) keepusing(`TradeVars') nogen;

	*Weight each observation based on its ecoa code;
		gen ecoa_wt = 1 if inlist(ecoa_cd,"0","1","X","A","H","W","I");
		replace ecoa_wt = 0.5 if inlist(ecoa_cd,"2","B","4","D","5","E");
		replace ecoa_wt = 0.5 if inlist(ecoa_cd,"6","F","7","G");
		replace ecoa_wt = 0 if inlist(ecoa_cd,"3","C","NA");

		bysort consumer_nb ptk_nb ReportingPeriod: gen dup = _N;
		replace ecoa_wt=ecoa_wt/dup;

		drop if ecoa_wt==0;

	*Determine which accounts are open and have been reported in the last 6 months;
		gen numArchive_dt = mofd(date(ReportingPeriod, "YM"));
		format numArchive_dt %tm;
		gen numReported_dt = mofd(balance_dt);
		format numReported_dt %tm;

		gen periods_since_reported = numArchive_dt  - numReported_dt;

		keep if upper(condition_cd)=="A1" & periods_since_reported <= 5;
		drop numReported_dt numArchive_dt;

	*Generate loan type code;
		get_loan_type accounttype_cd kob_cd;

	*calculate total balances of different types;
		gen balance_wt = balance_am * ecoa_wt;

		generate cc_debt = balance_wt if loan_type==200;
		generate student_debt = balance_wt if loan_type==150;
		generate auto_debt = balance_wt if loan_type==100;
		generate mortgage_debt = balance_wt if loan_type==110;
		generate HELOC_debt = balance_wt if inlist(loan_type,120,220);
		generate other_debt = balance_wt if ~inlist(loan_type,200,150,100,110,120,220);

	tempfile cohort_`year';
	save `cohort_`year'', replace;
};

clear;
append using `cohort_2004'
			 `cohort_2007'
			 `cohort_2010'
			 `cohort_2013'
			 `cohort_2016';
save /home/work/projects/Experian/Shared/Litwin/data/Cohort_portfolio_comparisons.dta, replace;
**/
use  /home/work/projects/Experian/Shared/Litwin/data/Cohort_portfolio_comparisons.dta, clear;

	bysort ReportingPeriod consumer_nb : gen consumers_tag = (_n==1);

		collapse (sum)	Population = consumers_tag
						Total_debt = balance_wt
						cc_debt
						student_debt
						auto_debt
						mortgage_debt
						HELOC_debt
						other_debt
			, by(ReportingPeriod cohort);

foreach debt in Total_debt
				cc_debt
				student_debt
				auto_debt
				mortgage_debt
				HELOC_debt
				other_debt
				{;
	replace `debt' = `debt'/1000000000;
	gen `debt'_pct = (`debt'/Total_debt)*100;
};

gen Year = substr(ReportingPeriod,1,4);

graph bar 	mortgage_debt
			HELOC_debt
			cc_debt
			student_debt
			auto_debt
			other_debt
	if cohort==1,
	over(Year)
	stack
	title("Volume of debt held by consumers 55 - 61")
	ytitle("Debt held (billions $)")
	leg(order(1 "Mortgage"
			  2 "HELOCs"
			  3 "Credit cards"
			  4 "Student loans"
			  5 "Auto loans"
			  6 "Other"));
	graph export /home/work/projects/Experian/Shared/Litwin/output/debt_held_55_61_vol.png, replace;

graph bar 	mortgage_debt_pct
			HELOC_debt_pct
			cc_debt_pct
			student_debt_pct
			auto_debt_pct
			other_debt_pct
	if cohort==1,
	over(Year)
	stack
	title("Percent of debt held by consumers 55 - 61")
	ytitle("Debt held (% of total debt)")
	leg(order(1 "Mortgage"
			  2 "HELOCs"
			  3 "Credit cards"
			  4 "Student loans"
			  5 "Auto loans"
			  6 "Other"));
	graph export /home/work/projects/Experian/Shared/Litwin/output/debt_held_55_61_pct.png, replace;

graph bar 	mortgage_debt
			HELOC_debt
			cc_debt
			student_debt
			auto_debt
			other_debt
	if cohort==2,
	over(Year)
	stack
	title("Volume of debt held by consumers 62 - 66")
	ytitle("Debt held (billions $)")
	leg(order(1 "Mortgage"
			  2 "HELOCs"
			  3 "Credit cards"
			  4 "Student loans"
			  5 "Auto loans"
			  6 "Other"));
	graph export /home/work/projects/Experian/Shared/Litwin/output/debt_held_62_66_vol.png, replace;

graph bar 	mortgage_debt_pct
			HELOC_debt_pct
			cc_debt_pct
			student_debt_pct
			auto_debt_pct
			other_debt_pct
	if cohort==2,
	over(Year)
	stack
	title("Percent of debt held by consumers 62 - 66")
	ytitle("Debt held (% of total debt)")
	leg(order(1 "Mortgage"
			  2 "HELOCs"
			  3 "Credit cards"
			  4 "Student loans"
			  5 "Auto loans"
			  6 "Other"));
	graph export /home/work/projects/Experian/Shared/Litwin/output/debt_held_62_66_pct.png, replace;

foreach debt in Total_debt
				mortgage_debt
				HELOC_debt
				cc_debt
				student_debt
				auto_debt
				other_debt
				{;
	recast double `debt', force;
	replace `debt' = `debt'*1000000000;
	format %12.0g `debt';

	replace `debt'_pct=`debt'_pct*100;
	recast long `debt'_pct, force;
	recast double `debt'_pct, force;
	replace `debt'_pct=`debt'_pct/100;
};

foreach cohort in 1 2 {;
	mat debt_`cohort'=J(7,5,.);
	mat pct_`cohort'=J(7,5,.);
	local col=0;

	foreach year in 2004
					2007
					2010
					2013
					2016
					{;
		local ++col;
		local row=0;
		foreach debt in Total_debt
						mortgage_debt
						HELOC_debt
						cc_debt
						student_debt
						auto_debt
						other_debt
						{;
			local ++row;
			sum `debt' if Year=="`year'" & cohort==`cohort';
			mat debt_`cohort'[`row',`col'] = r(mean);

			sum `debt'_pct if Year=="`year'" & cohort==`cohort';
			mat pct_`cohort'[`row',`col'] = r(mean);
		};
	};

	mat colnames debt_`cohort' 	= 2004 2007 2010 2013 2016;
	mat rownames debt_`cohort' 	= Total Mortgage HELOC Card Student Auto Other;

	mat colnames pct_`cohort' 	= 2004 2007 2010 2013 2016;
	mat rownames pct_`cohort'	= Total Mortgage HELOC Card Student Auto Other;
};

mat list debt_1, f(%18.2fc);
mat list pct_1;

mat list debt_2, f(%18.2fc);
mat list pct_2;

log close;