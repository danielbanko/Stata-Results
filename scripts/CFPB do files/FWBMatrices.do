																				///
capture log close																
clear all
set more off
set trace off
local projectpath "/home/cfpb/banko-ferrand/WriteUp4Journal/BankoFWBAnalysis/Analysis"
 cd `projectpath'
/*----------------------------------------------------------------*/
* Daniel Banko-Ferran - FWBMatrices.do
* Examine FWB data for Soph Scale project
* Data modified: 10/26/2017
* Output saved in: "/home/cfpb/banko-ferrand/BankoFWB/Analysis/"
/*----------------------------------------------------------------*/
use "`projectpath'/data/30356-CFPB_client_170915_DB_Cleaned.dta"
* Defining local macros:
local PROP "PROPPLAN_1 PROPPLAN_2 PROPPLAN_3 PROPPLAN_4"
local MAN1 "MANAGE1_1 MANAGE1_2 MANAGE1_3 MANAGE1_4"
local SHOCK "SHOCKS_1 SHOCKS_2 SHOCKS_3 SHOCKS_4 SHOCKS_5 SHOCKS_6 SHOCKS_7 ///SHOCKS_8 SHOCKS_9 SHOCKS_10 SHOCKS_11"
local CONTROL "SELFCONTROL_1rev SELFCONTROL_2 SELFCONTROL_3"
local AUTOMATE "AUTOMATED_1 AUTOMATED_2"
local ASK "ASK1_1 ASK1_2"
local FINSOC "FINSOC2_1 FINSOC2_2 FINSOC2_3 FINSOC2_4 FINSOC2_5 FINSOC2_6 FINSOC2_7"
local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2"
local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
local DEMOGRAPH "PPAGE PPINCIMP PPEDUC PPWORK FEMALE PPMARIT"
local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2"

*Creating indicator variables:
// foreach var of varlist `catvList' {
// 	quietly tab `var', gen("`var'L_")
// }

* Defining programs:
quietly program define createTableChi2
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2"
	args selector matrixname macro1
	local size : word count ``macro1''
	matrix `matrixname' = J(`size',7,.)
	matrix colname `matrixname' = N Chi2Disc Avg0 Avg1 Diff Min Max
	matrix rowname `matrixname' = ``macro1''
	* Since we are looping over varlist, need a separate counter
	local i=1
	foreach var of varlist ``macro1'' {
		quietly tabulate `var' `selector', chi2 row
		matrix `matrixname'[`i',1] = `r(N)'
		matrix `matrixname'[`i',2] = round(`r(chi2)',.01)
		quietly summ `var' if `selector' == 0
		matrix `matrixname'[`i',3] = round(`r(mean)',.01)
		quietly summ `var' if `selector' == 1
		matrix `matrixname'[`i',4] = round(`r(mean)',.01)
		matrix `matrixname'[`i',5] = `matrixname'[`i',4]-`matrixname'[`i',3]
		matrix `matrixname'[`i',6] = `r(min)'
		matrix `matrixname'[`i',7] = `r(max)'
		local ++i
	}
	matrix list `matrixname'
end
quietly program define createTablett
	local DEMOGRAPH "PPAGE PPINCIMP PPEDUC PPWORK FEMALE PPMARIT"
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2"
	args var1 matrixname macro1
	local size : word count ``macro1''
	matrix `matrixname' = J(`size',7,.)
	matrix colname `matrixname' = N ttDISCOUNT Avg0 Avg1 Diff Min Max
	matrix rowname `matrixname' = ``macro1''
	local i=1
	foreach var of varlist ``macro1'' {
		quietly ttest `var', by(`var1')
		matrix `matrixname'[`i',1] = `r(N_1)' + `r(N_2)'
		matrix `matrixname'[`i',2] = round(`r(t)',.01)
		quietly summ `var' if `var1' == 0
		matrix `matrixname'[`i',3] = round(`r(mean)',.01)
		quietly summ `var' if `var1' == 1
		matrix `matrixname'[`i',4] = round(`r(mean)',.01)
		matrix `matrixname'[`i',5] = `matrixname'[`i',4]-`matrixname'[`i',3]
		matrix `matrixname'[`i',6] = `r(min)'
		matrix `matrixname'[`i',7] = `r(max)'
		local ++i
	}
	matrix list `matrixname'
end
quietly program define createTableRegCat
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2  MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1  MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2"
	local vListLevels "REJECTED_1L_1 REJECTED_1L_2 REJECTED_2L_1 REJECTED_2L_2 COLLECTL_1 COLLECTL_2  AUTOMATED_1L_1 AUTOMATED_1L_2 AUTOMATED_2L_1 AUTOMATED_2L_2 MANAGE2L_1 MANAGE2L_2 MANAGE2L_3 SCFHORIZONL_1 SCFHORIZONL_2 SCFHORIZONL_3 SCFHORIZONL_4 SCFHORIZONL_5 ENDSMEETrevL_1 ENDSMEETrevL_2 ENDSMEETrevL_3 SAVEHABITL_1 SAVEHABITL_2 SAVEHABITL_3 SAVEHABITL_4 SAVEHABITL_5 SAVEHABITL_6 ABSORBSHOCKL_1 ABSORBSHOCKL_2 ABSORBSHOCKL_3 ABSORBSHOCKL_4 FRUGALITYL_1 FRUGALITYL_2 FRUGALITYL_3 FRUGALITYL_4 FRUGALITYL_5 FRUGALITYL_6 ASK1_1L_1 ASK1_1L_2 ASK1_1L_3 ASK1_1L_4 ASK1_1L_5 ASK1_2L_1 ASK1_2L_2 ASK1_2L_3 ASK1_2L_4 ASK1_2L_5"
	local vListLevels2 "REJECTED_1L_1 REJECTED_1L_2 REJECTED_2L_1 REJECTED_2L_2 COLLECTL_1 COLLECTL_2 AUTOMATED_1L_1 AUTOMATED_1L_2 MANAGE2L_1 MANAGE2L_2 MANAGE2L_3 SCFHORIZONL_1 SCFHORIZONL_2 SCFHORIZONL_3 SCFHORIZONL_4 SCFHORIZONL_5 ENDSMEETrevL_1 ENDSMEETrevL_2 ENDSMEETrevL_3 SAVEHABITL_1 SAVEHABITL_2 SAVEHABITL_3 SAVEHABITL_4 SAVEHABITL_5 SAVEHABITL_6 ABSORBSHOCKL_1 ABSORBSHOCKL_2 ABSORBSHOCKL_3 ABSORBSHOCKL_4 FRUGALITYL_1 FRUGALITYL_2 FRUGALITYL_3 FRUGALITYL_4 FRUGALITYL_5 FRUGALITYL_6 ASK1_1L_1 ASK1_1L_2 ASK1_1L_3 ASK1_1L_4 ASK1_1L_5 ASK1_2L_1 ASK1_2L_2 ASK1_2L_3 ASK1_2L_4 ASK1_2L_5 "
	args var1 matrixname macro1 macro2 controls switcher
	local size : word count ``macro1''
	matrix `matrixname' = J(`size',4,.)
	matrix colname `matrixname' = odds se z p-val
	matrix rowname `matrixname' = ``macro1''
	local i=1
	foreach var of varlist ``macro2'' {
		quietly tab `var'
		local s = r(r)
		/*Sections 1 and 2*/
		if `switcher' == 0 { //switch for across or within population regression
			if `controls' == 0 { //switch for controls or no controls
				quietly logit `var1' i.`var', or
			}
			else if `controls' == 1 {
				quietly logit `var1' i.`var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT, or
			}
			else {
				di "invalid entry for controls. must be either 0 or 1"
				exit
			}
		}
		/*Within DISCOUNT == 1 population (Section 3)*/
		else if `switcher' == 1 {
			if `controls' == 0 {
				quietly logit `var1' i.`var' if DISCOUNT == 1, or
			}
			else if `controls' == 1 {
				quietly logit `var1' i.`var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT if DISCOUNT == 1, or
			}
			else {
				di "invalid entry for controls. must be either 0 or 1"
				exit
			}			
		}
		else {
			di "invalid entry for switcher. must be 0 or 1"
			exit
		}
		/*creating the matrix*/
		matrix temp = r(table)
		foreach n of numlist 1/`s' {
			foreach m of numlist 1/4 {
				matrix `matrixname'[`i',`m'] = round(temp[`m',`n'],.01)
			}
			local ++i
		}
		matrix drop temp
	}
	matrix list `matrixname'
end
quietly program define createTableRegCont
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2 "
	args var1 matrixname macro1 controls switcher
	local size : word count ``macro1''
	matrix `matrixname' = J(`size',4,.)
	matrix colname `matrixname' = odds se z p-val
	matrix rowname `matrixname' = ``macro1''
	local i=1
	foreach var of varlist ``macro1'' {
		/*Sections 1 and 2*/
		if `switcher' == 0 {
			if `controls' == 0 {
				quietly logit `var1' `var', or
			}
			else if `controls' == 1 {
				quietly logit `var1' `var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT, or
			}
			else {
				di "invalid entry for control. must be either 0 or 1"
				exit
			}
		}
		/*Within DISCOUNT == 1 population (Section 3)*/
		else if `switcher' == 1 {
			if `controls' == 0 {
				quietly logit `var1' `var' if DISCOUNT == 1, or
			}
			else if `controls' == 1 {
				quietly logit `var1' `var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT if DISCOUNT == 1, or
			}
			else {
				di "invalid entry for controls. must be either 0 or 1"
				exit
			}			
		}
		else {
			di "invalid entry for switcher. must be 0 or 1"
			exit
		}
		/*creating the matrix*/
		matrix temp = r(table)
		foreach n of numlist 1/4 {
			matrix `matrixname'[`i',`n'] = round(temp[`n',1],.01)
		}
		matrix drop temp
		local ++i
	}
	matrix list `matrixname'
end

quietly program define createTableChi2DISCOUNT
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2"
	args selector matrixname macro1
	local size : word count ``macro1''
	matrix `matrixname' = J(`size',7,.)
	matrix colname `matrixname' = N Chi2Disc Avg0 Avg1 Diff Min Max
	matrix rowname `matrixname' = ``macro1''
	* Since we are looping over varlist, need a separate counter
	local i=1
	foreach var of varlist ``macro1'' {
		quietly tabulate `var' `selector' if DISCOUNT==1, chi2 row
		matrix `matrixname'[`i',1] = `r(N)'
		matrix `matrixname'[`i',2] = round(`r(chi2)',.01)
		quietly summ `var' if `selector' == 0 & DISCOUNT==1
		matrix `matrixname'[`i',3] = round(`r(mean)',.01)
		quietly summ `var' if `selector' == 1 & DISCOUNT==1
		matrix `matrixname'[`i',4] = round(`r(mean)',.01)
		matrix `matrixname'[`i',5] = `matrixname'[`i',4]-`matrixname'[`i',3]
		matrix `matrixname'[`i',6] = `r(min)'
		matrix `matrixname'[`i',7] = `r(max)'
		local ++i
	}
	matrix list `matrixname'
end
quietly program define createTablettDISCOUNT
	local DEMOGRAPH "PPAGE PPINCIMP PPEDUC PPWORK FEMALE PPMARIT"
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_1 ASK1_2"
	args var1 matrixname macro1
	local size : word count ``macro1''
	matrix `matrixname' = J(`size',7,.)
	matrix colname `matrixname' = N ttDISCOUNT Avg_DiscLL Avg_DiscSS Diff Min Max
	matrix rowname `matrixname' = ``macro1''
	local i=1
	foreach var of varlist ``macro1'' {
		quietly ttest `var' if DISCOUNT==1, by(`var1')
		matrix `matrixname'[`i',1] = `r(N_1)' + `r(N_2)'
		matrix `matrixname'[`i',2] = round(`r(t)',.01)
		quietly summ `var' if `var1' == 0 & DISCOUNT==1
		matrix `matrixname'[`i',3] = round(`r(mean)',.01)
		quietly summ `var' if `var1' == 1 & DISCOUNT==1
		matrix `matrixname'[`i',4] = round(`r(mean)',.01)
		matrix `matrixname'[`i',5] = `matrixname'[`i',4]-`matrixname'[`i',3]
		matrix `matrixname'[`i',6] = `r(min)'
		matrix `matrixname'[`i',7] = `r(max)'
		local ++i
	}
	matrix list `matrixname'
end

capture log using "FWBMatricesLog", replace
/*************** Codebook *****************************/
foreach var of varlist *{
	di "`var'" _col(20) "`: var l `var''" _col(50)
}

di "Control variables: `DEMOGRAPH'"

/*************** SECTION 1: DISCOUNT ****************/

/*************** a) DISCOUNT without controls ****************/
* Table for chi2 test results of categorical variables with
* SSChoice to see mean differences. Then a table for t-test results of 
* continuous variables with SSChoice.

* Results of Chi2 tests and t-tests with SSChoice without controls:
createTableChi2 SSChoice tabDisc catvList
createTablett SSChoice ttDisc contvList

/*************** b) Age, Income, and other Controls ***************/
* Brianna and Melissa suggested that age, household income, and other controls may 
* be mediating factors on participants' reported future discounted time preferences.
* As a robustness check, I run regressions with SSChoice as the DV controlling for
* age, income, and other factors like employment, marriage, and gender.

di "Controls are: `DEMOGRAPH'"

*logistic regressions with controls in a table:
createTableRegCat SSChoice catRegTablewControls vListLevels catvList 1 0
createTableRegCont SSChoice contRegTablewControls contvList 1 0

/*************** SECTION 2: AUTOMATEDDISCOUNT21 ****************/

/*************** a) Relationship between AUTOMATED and DISCOUNT (without controls)  ***************/
* Our population of interest is the population of present biased people who may
* or may not be sophisticated. We cannot directly measure present bias people
* using FWB data because it lacks a measuring tool for present bias.
* gen AUTOMATEDDISCOUNT21 = 0 if AUTOMATED_2 != . & DISCOUNT != .
* replace AUTOMATEDDISCOUNT21 = 1 if AUTOMATED_2 == 1 & DISCOUNT == 1 
* AUTOMMATEDDISCOUNT21=1 for those people who automated their non-retirement savings and 
* are potentially present-biased (prefer less money now)

*regressions without controls outputted in a table:
createTableChi2 AUTOMATEDDISCOUNT21 tabAutoDisc catvList2
createTablett AUTOMATEDDISCOUNT21 ttAutoDisc contvList

/***************b) AUTOMATEDDISCOUNT21 Regressions with controls *********/
* As with DISCOUNT, age, income and other characteristics may be mediating factors in our
* analysis of the relationship between present-biased behavior and well-being. 
* To account for this, I run logitistic regressions with AUTOMATEDDISCOUNT21 as the 
* DV controlling for age, income, and other factors as above.

* Regressions with controls outputted in a table:
createTableRegCat AUTOMATEDDISCOUNT21 catRegTableAutoControl vListLevels2 catvList2 1 0
createTableRegCont AUTOMATEDDISCOUNT21 contRegTableAutoControl contvList 1 0



/*************** SECTION 3: AUTOMATEDDISCOUNT w/ DISCOUNT = 1 ****************/

/*************** a) AUTOMATEDDISCOUNT w/ DISCOUNT = 1 (without controls)  ***************/
* AUTOMMATEDDISCOUNT=1 for those people who automated their retirement savings and 
* are potentially present-biased (prefer less money now) and we comepare them just
* within the population of people who preferred smaller, sooner reward

* Results without controls outputted in a table:
createTableChi2DISCOUNT AUTOMATEDDISCOUNT21 tabAUTODisc2 catvList2
createTablettDISCOUNT AUTOMATEDDISCOUNT21 ttAUTODisc2 contvList

/***************b) AUTOMATEDDISCOUNT w/ DISCOUNT == 1 with controls *********/
* As with DISCOUNT, age, income and other characteristics may be mediating factors in our
* analysis of the relationship between present-biased behavior and well-being. 
* To account for this, I run logistic regressions with AUTOMATEDDISCOUNT21 if DISCOUNT==1 as the 
* DV controlling for age, income, and other factors as before.

* AUTOMATEDDISCOUNT21 logistic regressions when DISCOUNT ==1 with controls:
createTableRegCat AUTOMATEDDISCOUNT21 catRegTableAutoControl2 vListLevels2 catvList2 1 1
createTableRegCont AUTOMATEDDISCOUNT21 contRegTableAutoControl2 contvList 1 1

capture log close
translator set smcl2pdf pagesize custom
translator set smcl2pdf pagewidth 11.0
translator set smcl2pdf pageheight 8.5
translate FWBMatricesLog.smcl FWBAnalyzedMatricesAUTOMATED2.pdf, replace

capture log using "FWBDEMOGRAPH", replace
createTablett SSChoice ttDisc DEMOGRAPH
createTablett AUTOMATEDDISCOUNT11 ttAutoDisc DEMOGRAPH
createTablettDISCOUNT AUTOMATEDDISCOUNT11 ttAUTODisc2 DEMOGRAPH
createTablett AUTOMATEDDISCOUNT21 ttAutoDisc DEMOGRAPH
createTablettDISCOUNT AUTOMATEDDISCOUNT21 ttAUTODisc2 DEMOGRAPH
capture log close
translator set smcl2pdf pagesize custom
translator set smcl2pdf pagewidth 11.0
translator set smcl2pdf pageheight 8.5
translate FWBDEMOGRAPH.smcl FWBDEMOGRAPH.pdf, replace
//must keep this blank
