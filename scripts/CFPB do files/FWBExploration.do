clear all
set more off
set trace off
capture log using "FWBExploration", replace
/*----------------------------------------------------------------*/
* Daniel Banko-Ferran - FWBExploration.do
* Examine FWB data for Soph Scale project
* Data modified: 12/19/2017
* Output saved in: "/home/cfpb/banko-ferrand/BankoFWB/Analysis/"
/*----------------------------------------------------------------*/
local projectpath "/home/cfpb/banko-ferrand/WriteUp4Journal/BankoFWBAnalysis/Analysis"
cd `projectpath'
use "`projectpath'/data/30356-CFPB_client_170915_DB_Cleaned.dta"

/******************* 1) SETUP 	**************************/
//Defining local macros:
local PROP "PROPPLAN_1 PROPPLAN_2 PROPPLAN_3 PROPPLAN_4"
local MAN1 "MANAGE1_1 MANAGE1_2 MANAGE1_3 MANAGE1_4"
local SHOCK "SHOCKS_1 SHOCKS_2 SHOCKS_3 SHOCKS_4 SHOCKS_5 SHOCKS_6 SHOCKS_7 SHOCKS_8 SHOCKS_9 SHOCKS_10 SHOCKS_11"
local CONTROL "SELFCONTROL_1rev SELFCONTROL_2 SELFCONTROL_3"
//Defining programs:
program define recodeNA
	args var1
	replace `var1' = . if `var1' == 1
	foreach n of numlist 2/6 {
			replace `var1' = `n'-1 if `var1' == `n'
	}
	label values `var1' recodeLab
end
program define createBarOver
	args var1 var2 type1 filename title1
	graph bar (`type1') `var1', over(`var2') asyvars saving("`filename'", replace) title("`title1'")
	graph export "output/`filename'.png", replace
end

/***************** 2) CLEANING	 *************************/
* Recoding if "Not applicable":
recodeNA MANAGE1_1
recodeNA MANAGE1_2
recodeNA MANAGE1_3
recodeNA MANAGE1_4
* Recoding "refused" as missing:
foreach var of varlist _all { 
	replace `var' = . if `var' == -1 | `var' == -2 | `var' == 8
}
// gen SELFCONTROL_1rev = 5 - SELFCONTROL_1
label values SELFCONTROL_1rev reverseLab 
// egen totSHOCK = rowtotal(`SHOCK')
label variable totSHOCK "rowtotal(SHOCK)"
// gen ENDSMEETrev = 4 - ENDSMEET
label values ENDSMEETrev reverseLab2
numlabel, add

/***************** 3)	 EXPLORATION	 **********************/
hist FWBscore, freq xlabel(56 "mean = 56", grid axis(0(10)100)) ylabel(0(100)600, grid) xtitle("Distribution of FWB score") normal
graph export "output/FWBscoredistribution.png", replace
foreach var of varlist _all {
	sum `var'
	tabulate `var', missing plot summarize()
}

* Checking for correlations among scale variables:
* Cronbach's alpha is a scale reliability measure that measures the consistency strength of a set of items. 
* It is computed by correlating the score for each item with the total score for each observation, and comparing that 
* to the variance for all individual team scores.
// corr `PROP' 
// alpha `PROP', detail gen(avgPROP)
// corr `MAN1'
// alpha `MAN1', detail gen(avgMAN)
corr `MAN1'
alpha `MAN1' MANAGE2, detail
corr `CONTROL'
alpha `CONTROL', detail
corr ENDSMEET COLLECT
alpha ENDSMEET COLLECT, detail

* Our threshold for relability in Cronbach's alpha is 0.7.  All scales except SELFCONTROL and MANAGE1_# with MANAGE2 items had an alpha greater than 0.7.
* Therefore, our SELFCONTROL items and MANAGE1_# items with MANAGE2 do not have enough inter-item consistency to be considered reliable measures, and I remove them from subsequent analyses.
label variable avgPROP "rmean(PROP)"
label variable avgMAN "rmean(MAN1)"

/*************** 4) Relationship w/ DISCOUNT	 *************/
* Our primary interest is to identify associations between variables in the FWB survey,
* especially DISCOUNT, in order to provide context and improve our knowledge and design of the sophistication survey.
* A chi-square test is used to determine whether there is a significant association between two categorical variables. 
* The null hypothesis is that the two tested variables are independent.
foreach var of varlist avgPROP avgMAN SCFHORIZON totSHOCK FWBscore CONNECT MANAGE2 REJECTED_1 REJECTED_2 COLLECT ENDSMEETrev SAVEHABIT ABSORBSHOCK {
	tabulate `var' DISCOUNT, chi2 row
}
* Overall, all 12 variables have a relationship with DISCOUNT.

* Now to check the effect size and relationship between DISCOUNT and our two continuous variables, FWBscore and CONNECT:
ttest FWBscore, by(DISCOUNT)
ttest CONNECT, by(DISCOUNT)
* On average, a person who chooses the "larger, later" option for DISCOUNT we predict to score 7.5 points higher on the FWB scale and 8.5 points higher on the CONNECT scale.
* This statistic is significant at the 0.01 level for both FWBscore and CONNECT.

/*************** 5) Age and Income Checks 	***************/
* Brianna and Melissa suggested that age and household income may bet mediating factors on participants' reported future discounted time preferences.
* To check for this, I run regressions across our variables of interest with FWBscore and CONNECT controlling for these two variables.
foreach var of varlist avgPROP avgMAN MANAGE2 SCFHORIZON totSHOCK DISCOUNT MANAGE2 REJECTED_1 REJECTED_2 COLLECT ENDSMEETrev SAVEHABIT {
	regress FWBscore `var' PPAGE PPINCIMP
	regress CONNECT `var' PPAGE PPINCIMP
}
* Controlling for age and income reduces the effect size of DISCOUNT on FWBscore and CONNECT dramatically. Now the difference in FWB score is only 4.71 for the two values of DISCOUNT.
* avgMAN has a larger effect on FWBscore and CONNECT than DISCOUNT. On average, we predict a difference in FWB score of 7.93 points and 5.13 points for CONNECT for each 1-unit increase in avgMAN.

regress FWBscore DISCOUNT PPAGE PPINCIMP avgMAN
regress CONNECT DISCOUNT PPAGE PPINCIMP avgMAN
* In fact, controlling for avgMAN further decreases the effect size of DISCOUNT on FWBscore and CONNECT to 4.71 and 4.65 respectively.
* This suggests an overlapping relationship to FWBscore between avgMAN and DISCOUNT.

*To see the relationship between DISCOUNT and avgMAN, we run a regression controlling for FWBscore and CONNECT:
regress DISCOUNT avgMAN PPAGE PPINCIMP FWBscore CONNECT
* There is a somewhat large and statistically significant effect of avgMAN on DISCOUNT.
* On average, we predict that an individual is 11% more likely to prefer the "larger, later" option if their avgMAN score is 1-unit higher, controlling for age, income and FWBscore.

/**** 6) CONCLUSION **********/
* I recommend using DISCOUNT, avgMAN, ENDSMEET, ABSORBSHOCK and COLLECT controlling for age and household income

//toadd: Output regression results, summary statistics, and labels in a table
//toadd: run logistics
//toadd: use collapse to add standard errors to graphs
//toadd: graph the total number of frequencies for each value of manage across manage1_1, 1_2, etc. grouped by DISCOUNT value
translate FWBAnalyzed.smcl FWBAnalysisPDF.pdf, replace translator(smcl2pdf)
capture log close
