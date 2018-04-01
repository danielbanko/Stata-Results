																				///
capture log close																
clear all
set more off
set trace off
local projectpath "/home/cfpb/banko-ferrand/WriteUp4Journal"
cd `projectpath'

use "`projectpath'/BankoFWBAnalysis/Analysis/data/30356-CFPB_client_170915_DB_Cleaned.dta"

capture log using "ResultsforAbstract", replace
/*----------------------------------------------------------------*/
* Daniel Banko-Ferran - FWBWriteUpAnalysis.do
* Examine FWB data for Soph Scale project
* Data modified: 12/19/2017
* Output saved in: "/home/cfpb/banko-ferrand/WriteUp4Journal/BankoFWBAnalysis"
/*----------------------------------------------------------------*/
***********Creating subpopulations of interest******************************************************
quietly gen group = 0
quietly replace group = 1 if SSChoice==1 & AUTOMATED_2 == 0
quietly replace group = 2 if SSChoice==1 & AUTOMATED_2==1
quietly replace group = 3 if SSChoice==0

****************Demographics of each group**********************************************************
matrix demoTable = J(6,4,.)
matrix colname demoTable = SSNoAuto SSAuto LargerLater all
matrix rowname demoTable = AGE INCIMP EDUC WORK FEMALE MARIT
local i=1
foreach var of varlist PPAGE PPINCIMP PPEDUC PPWORK FEMALE PPMARIT {
	quietly summ `var' if group == 1
	matrix demoTable[`i',1] = round(`r(mean)',.01)
	quietly summ `var' if group == 2
	matrix demoTable[`i',2] = round(`r(mean)',.01)
	quietly summ `var' if group ==3
	matrix demoTable[`i',3] = round(`r(mean)',.01)
	quietly summ `var'
	matrix demoTable[`i',4] = round(`r(mean)',.01)
	local ++i
}

****************Means of FWBscore, ENDSMEET, and ABSORBSHOCK for each group***********************
matrix resultsTable = J(3,4,.)
matrix colname resultsTable = SSNoAuto SSAuto LargerLater all
matrix rowname resultsTable = FWBscore ENDSMEET ABSORBSHOCK
local i=1
foreach var of varlist FWBscore ENDSMEETrev ABSORBSHOCK {
	quietly summ `var' if group == 1
	matrix resultsTable[`i',1] = round(`r(mean)',.01)
	quietly summ `var' if group == 2
	matrix resultsTable[`i',2] = round(`r(mean)',.01)	
	quietly summ `var' if group == 3
	matrix resultsTable[`i',3] = round(`r(mean)',.01)
	quietly summ `var'
	matrix resultsTable[`i',4] = round(`r(mean)',.01)
	local ++i
}


******************Predicting FWBscore, ENDSMEET, and ABSORBSHOCK************************************
matrix predictTable = J(3,4,.)
matrix colname predictTable = SSNoAuto SSAuto LargerLater all
matrix rowname predictTable = FWBscore_hat ENDSMEET_hat ABSORBSHOCK_hat
local i=1
foreach var of varlist FWBscore ENDSMEETrev ABSORBSHOCK {
	order `var', last
	quietly regress `var' i.group PPAGE PPINCIMP PPEDUC PPWORK FEMALE PPMARIT
	quietly predict `var'_hat if e(sample), xb
	quietly replace `var'_hat = round(`var'_hat,1)
 	quietly summ `var'_hat if group==1
	matrix predictTable[`i',1] = round(`r(mean)',.01)
	quietly summ `var'_hat if group==2
	matrix predictTable[`i',2] = round(`r(mean)',.01)
	quietly summ `var'_hat if group==3
	matrix predictTable[`i',3] = round(`r(mean)',.01)
	quietly summ `var'_hat
	matrix predictTable[`i',4] = round(`r(mean)',.01)
	local ++i
}

*******************************TABLES***************************************************************
*Demographics:
matrix list demoTable
*Observed values:
matrix list resultsTable
*Predicted values:
matrix list predictTable

******DEMOGRAPHS******
foreach var of varlist PPINCIMP PPEDUC PPWORK PPMARIT {
	label list `var'
}
***********************
foreach var of varlist ABSORBSHOCK ENDSMEETrev {
	sum `var'
	tabulate `var'
}
*******************************CONCLUSION************************************************************
// We reject the null hypothesis for both observed and predicted values of our 
// financial well-being measures (FWBscore, ENDSMEET, ABSORBSHOCK) that the mean 
// values are the same across groupings based upon intertemporal preference and the
// presence of sophisticated action. Of those who choose to receive the smaller 
// sooner reward, financial well-being is higher for those who automate 
// their non-retirement savings than those who do not, on average. Those who choose 
// the larger later reward (irrespective of automation choice) are better off than
// both of these groups, on average. This suggests that financial well-being is 
// lower among those who have a stronger preference for immediate consumption on 
// average, and this downward effect can be mediated by taking sophisticated 
// actions to mitigate this intertemporal bias.

capture log close
translator set smcl2pdf pagesize custom
translator set smcl2pdf pagewidth 11.0
translator set smcl2pdf pageheight 8.5
translate ResultsforAbstract.smcl ResultsforAbstract.pdf, replace
//leave blank
