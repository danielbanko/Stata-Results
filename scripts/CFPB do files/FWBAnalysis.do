																				///
capture log close																
clear all
set more off
set trace off
local projectpath "/home/cfpb/banko-ferrand/WriteUp4Journal/BankoFWBAnalysis/Analysis"
cd `projectpath'
capture log using "FWBAnalyzedLog", replace
/*----------------------------------------------------------------*/
* Daniel Banko-Ferran - FWBAnalysis.do
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
local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
local DEMOGRAPH "PPAGE PPINCIMP PPEDUC PPWORK PPGENDER PPMARIT"
local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"

*Creating indicator variables:
foreach var of varlist `catvList' {
	quietly tab `var', gen("`var'L_")
}

* Defining programs:
quietly program define createBarOver
	args var1 var2 type1 filename title1
	graph bar (`type1') `var1', over(`var2') asyvars saving("`filename'", replace) title("`title1'")
	graph export "output/`filename'.png", replace
end
quietly program define createTableChi2
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	args varname matrixname macro1
	matrix `matrixname' = J(14,7,.)
	matrix colname `matrixname' = N Chi2Disc Avg0 Avg1 Diff Min Max
	matrix rowname `matrixname' = ``macro1''
	* Since we are looping over varlist, need a separate counter
	local i=1
	foreach var of varlist ``macro1'' {
		quietly tabulate `var' `varname', chi2 row
		matrix `matrixname'[`i',1] = `r(N)'
		matrix `matrixname'[`i',2] = round(`r(chi2)',.01)
		quietly summ `var' if `varname' == 0
		matrix `matrixname'[`i',3] = round(`r(mean)',.01)
		quietly summ `var' if `varname' == 1
		matrix `matrixname'[`i',4] = round(`r(mean)',.01)
		matrix `matrixname'[`i',5] = `matrixname'[`i',4]-`matrixname'[`i',3]
		matrix `matrixname'[`i',6] = `r(min)'
		matrix `matrixname'[`i',7] = `r(max)'
		local ++i
	}
	matrix list `matrixname'
end
quietly program define createTablett
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	args var1 matrixname macro1
	matrix `matrixname' = J(6,7,.)
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
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local vListLevels "REJECTED_1L_1 REJECTED_1L_2 REJECTED_2L_1 REJECTED_2L_2 COLLECTL_1 COLLECTL_2 AUTOMATED_1L_1 AUTOMATED_1L_2 AUTOMATED_2L_1 AUTOMATED_2L_2 FEMALEL_1 FEMALEL_2 MANAGE2L_1 MANAGE2L_2 MANAGE2L_3 SCFHORIZONL_1 SCFHORIZONL_2 SCFHORIZONL_3 SCFHORIZONL_4 SCFHORIZONL_5 ENDSMEETrevL_1 ENDSMEETrevL_2 ENDSMEETrevL_3 SAVEHABITL_1 SAVEHABITL_2 SAVEHABITL_3 SAVEHABITL_4 SAVEHABITL_5 SAVEHABITL_6 ABSORBSHOCKL_1 ABSORBSHOCKL_2 ABSORBSHOCKL_3 ABSORBSHOCKL_4 FRUGALITYL_1 FRUGALITYL_2 FRUGALITYL_3 FRUGALITYL_4 FRUGALITYL_5 FRUGALITYL_6 ASK1_2L_1 ASK1_2L_2 ASK1_2L_3 ASK1_2L_4 ASK1_2L_5 ASK1_1L_1 ASK1_1L_2 ASK1_1L_3 ASK1_1L_4 ASK1_1L_5"
	local vListLevels2 "REJECTED_1L_1 REJECTED_1L_2 REJECTED_2L_1 REJECTED_2L_2 COLLECTL_1 COLLECTL_2 AUTOMATED_2L_1 AUTOMATED_2L_2 FEMALEL_1 FEMALEL_2 MANAGE2L_1 MANAGE2L_2 MANAGE2L_3 SCFHORIZONL_1 SCFHORIZONL_2 SCFHORIZONL_3 SCFHORIZONL_4 SCFHORIZONL_5 ENDSMEETrevL_1 ENDSMEETrevL_2 ENDSMEETrevL_3 SAVEHABITL_1 SAVEHABITL_2 SAVEHABITL_3 SAVEHABITL_4 SAVEHABITL_5 SAVEHABITL_6 ABSORBSHOCKL_1 ABSORBSHOCKL_2 ABSORBSHOCKL_3 ABSORBSHOCKL_4 FRUGALITYL_1 FRUGALITYL_2 FRUGALITYL_3 FRUGALITYL_4 FRUGALITYL_5 FRUGALITYL_6 ASK1_2L_1 ASK1_2L_2 ASK1_2L_3 ASK1_2L_4 ASK1_2L_5 ASK1_1L_1 ASK1_1L_2 ASK1_1L_3 ASK1_1L_4 ASK1_1L_5"
	args var1 matrixname macro1 macro2
	local size : word count ``macro1''
	matrix `matrixname' = J(`size',4,.)
	matrix colname `matrixname' = odds se z p-val
	matrix rowname `matrixname' = ``macro1''
	local i=1
	foreach var of varlist ``macro2'' {
		quietly tab `var'
		local s = r(r)
		quietly logit `var1' i.`var', or
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
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	args var1 matrixname macro1
	matrix `matrixname' = J(6,4,.)
	matrix colname `matrixname' = odds se z p-val
	matrix rowname `matrixname' = ``macro1''
	local i=1
	foreach var of varlist ``macro1'' {
		quietly logit `var1' `var', or
		matrix temp = r(table)
		foreach n of numlist 1/4 {
			matrix `matrixname'[`i',`n'] = round(temp[`n',1],.01)
		}
		matrix drop temp
		local ++i
	}
	matrix list `matrixname'
end

quietly program define createTableRegCatwControls
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local vListLevels "REJECTED_1L_1 REJECTED_1L_2 REJECTED_2L_1 REJECTED_2L_2 COLLECTL_1 COLLECTL_2 AUTOMATED_1L_1 AUTOMATED_1L_2 AUTOMATED_2L_1 AUTOMATED_2L_2 FEMALEL_1 FEMALEL_2 MANAGE2L_1 MANAGE2L_2 MANAGE2L_3 SCFHORIZONL_1 SCFHORIZONL_2 SCFHORIZONL_3 SCFHORIZONL_4 SCFHORIZONL_5 ENDSMEETrevL_1 ENDSMEETrevL_2 ENDSMEETrevL_3 SAVEHABITL_1 SAVEHABITL_2 SAVEHABITL_3 SAVEHABITL_4 SAVEHABITL_5 SAVEHABITL_6 ABSORBSHOCKL_1 ABSORBSHOCKL_2 ABSORBSHOCKL_3 ABSORBSHOCKL_4 FRUGALITYL_1 FRUGALITYL_2 FRUGALITYL_3 FRUGALITYL_4 FRUGALITYL_5 FRUGALITYL_6 ASK1_2L_1 ASK1_2L_2 ASK1_2L_3 ASK1_2L_4 ASK1_2L_5 ASK1_1L_1 ASK1_1L_2 ASK1_1L_3 ASK1_1L_4 ASK1_1L_5"
	local vListLevels2 "REJECTED_1L_1 REJECTED_1L_2 REJECTED_2L_1 REJECTED_2L_2 COLLECTL_1 COLLECTL_2 AUTOMATED_2L_1 AUTOMATED_2L_2 FEMALEL_1 FEMALEL_2 MANAGE2L_1 MANAGE2L_2 MANAGE2L_3 SCFHORIZONL_1 SCFHORIZONL_2 SCFHORIZONL_3 SCFHORIZONL_4 SCFHORIZONL_5 ENDSMEETrevL_1 ENDSMEETrevL_2 ENDSMEETrevL_3 SAVEHABITL_1 SAVEHABITL_2 SAVEHABITL_3 SAVEHABITL_4 SAVEHABITL_5 SAVEHABITL_6 ABSORBSHOCKL_1 ABSORBSHOCKL_2 ABSORBSHOCKL_3 ABSORBSHOCKL_4 FRUGALITYL_1 FRUGALITYL_2 FRUGALITYL_3 FRUGALITYL_4 FRUGALITYL_5 FRUGALITYL_6 ASK1_2L_1 ASK1_2L_2 ASK1_2L_3 ASK1_2L_4 ASK1_2L_5 ASK1_1L_1 ASK1_1L_2 ASK1_1L_3 ASK1_1L_4 ASK1_1L_5"
	args var1 matrixname macro1 macro2
	local size : word count ``macro1''
	matrix `matrixname' = J(`size',4,.)
	matrix colname `matrixname' = odds se z p-val
	matrix rowname `matrixname' = ``macro1''
	local i=1
	foreach var of varlist ``macro2'' {
		quietly tab `var'
		local s = r(r)
		quietly logit `var1' i.`var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT, or
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

quietly program define createTableRegContwControls
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	args var1 matrixname macro1
	matrix `matrixname' = J(6,4,.)
	matrix colname `matrixname' = odds se z p-val
	matrix rowname `matrixname' = ``macro1''
	local i=1
	foreach var of varlist ``macro1'' {
		quietly logit `var1' `var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT, or
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
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	args varname matrixname macro1
	matrix `matrixname' = J(14,7,.)
	matrix colname `matrixname' = N Chi2Disc Avg0 Avg1 Diff Min Max
	matrix rowname `matrixname' = ``macro1''
	* Since we are looping over varlist, need a separate counter
	local i=1
	foreach var of varlist ``macro1'' {
		quietly tabulate `var' `varname' if DISCOUNT==1, chi2 row
		matrix `matrixname'[`i',1] = `r(N)'
		matrix `matrixname'[`i',2] = round(`r(chi2)',.01)
		quietly summ `var' if `varname' == 0 & DISCOUNT==1
		matrix `matrixname'[`i',3] = round(`r(mean)',.01)
		quietly summ `var' if `varname' == 1 & DISCOUNT==1
		matrix `matrixname'[`i',4] = round(`r(mean)',.01)
		matrix `matrixname'[`i',5] = `matrixname'[`i',4]-`matrixname'[`i',3]
		matrix `matrixname'[`i',6] = `r(min)'
		matrix `matrixname'[`i',7] = `r(max)'
		local ++i
	}
	matrix list `matrixname'
end
quietly program define createTablettDISCOUNT
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	args var1 matrixname macro1
	matrix `matrixname' = J(6,7,.)
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
quietly program define createTableRegCatDISCOUNT
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local vListLevels "REJECTED_1L_1 REJECTED_1L_2 REJECTED_2L_1 REJECTED_2L_2 COLLECTL_1 COLLECTL_2 AUTOMATED_1L_1 AUTOMATED_1L_2 AUTOMATED_2L_1 AUTOMATED_2L_2 FEMALEL_1 FEMALEL_2 MANAGE2L_1 MANAGE2L_2 MANAGE2L_3 SCFHORIZONL_1 SCFHORIZONL_2 SCFHORIZONL_3 SCFHORIZONL_4 SCFHORIZONL_5 ENDSMEETrevL_1 ENDSMEETrevL_2 ENDSMEETrevL_3 SAVEHABITL_1 SAVEHABITL_2 SAVEHABITL_3 SAVEHABITL_4 SAVEHABITL_5 SAVEHABITL_6 ABSORBSHOCKL_1 ABSORBSHOCKL_2 ABSORBSHOCKL_3 ABSORBSHOCKL_4 FRUGALITYL_1 FRUGALITYL_2 FRUGALITYL_3 FRUGALITYL_4 FRUGALITYL_5 FRUGALITYL_6 ASK1_2L_1 ASK1_2L_2 ASK1_2L_3 ASK1_2L_4 ASK1_2L_5 ASK1_1L_1 ASK1_1L_2 ASK1_1L_3 ASK1_1L_4 ASK1_1L_5"
	local vListLevels2 "REJECTED_1L_1 REJECTED_1L_2 REJECTED_2L_1 REJECTED_2L_2 COLLECTL_1 COLLECTL_2 AUTOMATED_2L_1 AUTOMATED_2L_2 FEMALEL_1 FEMALEL_2 MANAGE2L_1 MANAGE2L_2 MANAGE2L_3 SCFHORIZONL_1 SCFHORIZONL_2 SCFHORIZONL_3 SCFHORIZONL_4 SCFHORIZONL_5 ENDSMEETrevL_1 ENDSMEETrevL_2 ENDSMEETrevL_3 SAVEHABITL_1 SAVEHABITL_2 SAVEHABITL_3 SAVEHABITL_4 SAVEHABITL_5 SAVEHABITL_6 ABSORBSHOCKL_1 ABSORBSHOCKL_2 ABSORBSHOCKL_3 ABSORBSHOCKL_4 FRUGALITYL_1 FRUGALITYL_2 FRUGALITYL_3 FRUGALITYL_4 FRUGALITYL_5 FRUGALITYL_6 ASK1_2L_1 ASK1_2L_2 ASK1_2L_3 ASK1_2L_4 ASK1_2L_5 ASK1_1L_1 ASK1_1L_2 ASK1_1L_3 ASK1_1L_4 ASK1_1L_5"
	args var1 matrixname macro1 macro2
	local size : word count ``macro1''
	matrix `matrixname' = J(`size',4,.)
	matrix colname `matrixname' = odds se z p-val
	matrix rowname `matrixname' = ``macro1''
	local i=1
	foreach var of varlist ``macro2'' {
		quietly tab `var'
		local s = r(r)
		quietly logit `var1' i.`var' if DISCOUNT==1, or
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
quietly program define createTableRegContDISCOUNT
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	args var1 matrixname macro1
	matrix `matrixname' = J(6,4,.)
	matrix colname `matrixname' = odds se z p-val
	matrix rowname `matrixname' = ``macro1''
	local i=1
	foreach var of varlist ``macro1'' {
		quietly logit `var1' `var' if DISCOUNT==1, or
		matrix temp = r(table)
		foreach n of numlist 1/4 {
			matrix `matrixname'[`i',`n'] = round(temp[`n',1],.01)
		}
		matrix drop temp
		local ++i
	}
	matrix list `matrixname'
end
quietly program define TableRegCatControlsDISC
	local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
	local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	local vListLevels "REJECTED_1L_1 REJECTED_1L_2 REJECTED_2L_1 REJECTED_2L_2 COLLECTL_1 COLLECTL_2 AUTOMATED_1L_1 AUTOMATED_1L_2 AUTOMATED_2L_1 AUTOMATED_2L_2 FEMALEL_1 FEMALEL_2 MANAGE2L_1 MANAGE2L_2 MANAGE2L_3 SCFHORIZONL_1 SCFHORIZONL_2 SCFHORIZONL_3 SCFHORIZONL_4 SCFHORIZONL_5 ENDSMEETrevL_1 ENDSMEETrevL_2 ENDSMEETrevL_3 SAVEHABITL_1 SAVEHABITL_2 SAVEHABITL_3 SAVEHABITL_4 SAVEHABITL_5 SAVEHABITL_6 ABSORBSHOCKL_1 ABSORBSHOCKL_2 ABSORBSHOCKL_3 ABSORBSHOCKL_4 FRUGALITYL_1 FRUGALITYL_2 FRUGALITYL_3 FRUGALITYL_4 FRUGALITYL_5 FRUGALITYL_6 ASK1_2L_1 ASK1_2L_2 ASK1_2L_3 ASK1_2L_4 ASK1_2L_5 ASK1_1L_1 ASK1_1L_2 ASK1_1L_3 ASK1_1L_4 ASK1_1L_5"
	local vListLevels2 "REJECTED_1L_1 REJECTED_1L_2 REJECTED_2L_1 REJECTED_2L_2 COLLECTL_1 COLLECTL_2 AUTOMATED_2L_1 AUTOMATED_2L_2 FEMALEL_1 FEMALEL_2 MANAGE2L_1 MANAGE2L_2 MANAGE2L_3 SCFHORIZONL_1 SCFHORIZONL_2 SCFHORIZONL_3 SCFHORIZONL_4 SCFHORIZONL_5 ENDSMEETrevL_1 ENDSMEETrevL_2 ENDSMEETrevL_3 SAVEHABITL_1 SAVEHABITL_2 SAVEHABITL_3 SAVEHABITL_4 SAVEHABITL_5 SAVEHABITL_6 ABSORBSHOCKL_1 ABSORBSHOCKL_2 ABSORBSHOCKL_3 ABSORBSHOCKL_4 FRUGALITYL_1 FRUGALITYL_2 FRUGALITYL_3 FRUGALITYL_4 FRUGALITYL_5 FRUGALITYL_6 ASK1_2L_1 ASK1_2L_2 ASK1_2L_3 ASK1_2L_4 ASK1_2L_5 ASK1_1L_1 ASK1_1L_2 ASK1_1L_3 ASK1_1L_4 ASK1_1L_5"
	args var1 matrixname macro1 macro2
	local size : word count ``macro1''
	matrix `matrixname' = J(`size',4,.)
	matrix colname `matrixname' = odds se z p-val
	matrix rowname `matrixname' = ``macro1''
	local i=1
	foreach var of varlist ``macro2'' {
		quietly tab `var'
		local s = r(r)
		quietly logit `var1' i.`var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT if DISCOUNT==1, or
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
quietly program define TableRegContControlsDISC
local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 FEMALE MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
	args var1 matrixname macro1
	matrix `matrixname' = J(6,4,.)
	matrix colname `matrixname' = odds se z p-val
	matrix rowname `matrixname' = ``macro1''
	local i=1
	foreach var of varlist ``macro1'' {
		quietly logit `var1' `var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT if DISCOUNT==1, or
		matrix temp = r(table)
	foreach n of numlist 1/4 {
		matrix `matrixname'[`i',`n'] = round(temp[`n',1],.01)
		}
		matrix drop temp
		local ++i
	}
	matrix list `matrixname'
end



/*************** 0) Codebook *****************************/
foreach var of varlist *{
	di "`var'" _col(20) "`: var l `var''" _col(50)
}
/*************** 1) Descriptive Statistics****************/
* foreach var of varlist `catvList' `contvList' `binaryvList' `DEMOGRAPH' {
* 	sum `var'
* 	tabulate `var', missing plot
* }

* Now to check the effect size and relationship between DISCOUNT and our two continuous variables, FWBscore and CONNECT:
ttest FWBscore, by(DISCOUNT)
ttest CONNECT, by(DISCOUNT)
* On average, a person who chooses the "larger, later" option for DISCOUNT we predict to score 7.5 points higher on the FWB scale and 8.5 points higher on the CONNECT scale.
* This statistic is significant at the 0.01 level for both FWBscore and CONNECT.

/*************** 3) Age and Income Checks 	***************/
* Brianna and Melissa suggested that age and household income may bet mediating factors on participants' reported future discounted time preferences.
* To check for this, I run regressions across our variables of interest with FWBscore and CONNECT controlling for these two variables.
// foreach var of varlist avgPROP avgMAN MANAGE2 SCFHORIZON totSHOCK DISCOUNT MANAGE2 REJECTED_1 REJECTED_2 COLLECT ENDSMEETrev SAVEHABIT {
// 	regress FWBscore `var' PPAGE PPINCIMP
// 	regress CONNECT `var' PPAGE PPINCIMP
// }
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

/**** 4) CONCLUSION**********/
* I recommend using DISCOUNT, avgMAN, ENDSMEET, ABSORBSHOCK and COLLECT controlling for age and household income

//toadd: Output regression results, summary statistics, and labels in a table
//toadd: run logistics
//toadd: use collapse to add standard errors to graphs
//toadd: graph the total number of frequencies for each value of manage across manage1_1, 1_2, etc. grouped by DISCOUNT value

/*********************PART 2: FURTHER ANALYSIS*******************************/
/*************** 5) Relationship w/ DISCOUNT (without controls) *************/
* Our primary interest is to identify associations between variables in the FWB 
* survey, especially DISCOUNT, in order to provide context and improve our		
* knowledge and design of the sophistication survey.
* A chi-square test is used to determine whether there is a significant 		
* association between two categorical variables. 								
* The null hypothesis is that the two tested variables are independent.			
// foreach var of varlist `catvList' {
// 	di "`var'"
// 	tabulate `var' DISCOUNT, chi2 row missing
// }
* Overall, all variables have a relationship with DISCOUNT.

* Now we check the effect size and relationship between DISCOUNT=1 (SS choice) and
* our continuous variables:
//  foreach var of varlist `contvList' {
//  	di "`var', by(SSChoice)"
//  	ttest `var', by(SSChoice)
//  }

*robustness checks: predict SSChoice with every variable one by one witout controls.
// foreach var of varlist `catvList' {
// 	logit SSChoice i.`var', or
// }
// foreach var of varlist `contvList' {
// 	logit SSChoice `var', or
// }
* Overall, all 20 variables have significant relationships with SSChoice.

/*************** 3) Summary tables for DISCOUNT without controls ****************/
* Now we create summary tables for quick understanding of results from above.
* First, we create a table for chi2 values of categorical (factor) variables with 
* SSChoice. Second, we create a table for t-test results of our continuous variables.
* Then we create a table for odds ratio results for categorical (factor) variables
* and another odds ratio results table for our continuous variables.
createTableChi2 SSChoice tabDisc catvList
createTablett SSChoice ttDisc contvList
createTableRegCat SSChoice catRegTable vListLevels catvList
createTableRegCont SSChoice contRegTable contvList

/*************** 4) Age, Income, and other Controls ***************/
* Brianna and Melissa suggested that age, household income, and other controls may 
* be mediating factors on participants' reported future discounted time preferences.
* As a robustness check, I run regressions with SSChoice as the DV controlling for
* age, income, and other factors like employment, marriage, and gender.

// foreach var of varlist `catvList' {
// 	logit SSChoice i.`var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT, or
// }
// foreach var of varlist `contvList' {
// 	logit SSChoice `var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT, or
// }

/*************** 5) Summary tables of results with controls ***************/
*Here we output the results from our logistic regressions in a table:
createTableRegCatwControls SSChoice catRegTablewControls vListLevels catvList
createTableRegContwControls SSChoice contRegTablewControls contvList

/*************** 6) Relationship between AUTOMATED and DISCOUNT (without controls)  ***************/
* Our population of interest is the population of present biased people who may	///
* or may not be sophisticated. We cannot directly measure present bias people 	///
* using FWB data because it lacks a measuring tool for present bias.
* AUTOMMATEDDISCOUNT11=1 for those people who automated their retirement savings and 
* are potentially present-biased (prefer less money now)

*cross-section of DISCOUNT and AUTOMATED to see distribution:
tab DISCOUNT AUTOMATED_1

* Now checking the effect size and relationship between AUTOMATEDDISCOUNT11 and our 		
* categorical variables:
foreach var of varlist `catvList2' {
	di "`var'"
	tabulate `var' AUTOMATEDDISCOUNT11, chi2 row missing
}
* And the relationship between AUTOMATEDDISCOUNT11 and our 		
* continuous variables:
 foreach var of varlist `contvList' {
 	di "`var', by(AUTOMATEDDISCOUNT11)"
 	ttest `var', by(AUTOMATEDDISCOUNT11)
 }

* As a robustness check, we predict AUTOMATEDDISCOUNT11 with every variable one-by-one
* without controls. Categorical:
foreach var of varlist `catvList2' {
	logit AUTOMATEDDISCOUNT11 i.`var', or
}
* Continuous:
foreach var of varlist `contvList' {
	logit AUTOMATEDDISCOUNT11 `var', or
}
* Overall, all 20 variables have significant relationships with AUTOMATEDDISCOUNT11.

/*************** 7) Summary Tables of Results for AUTOMATEDDISCOUNT11 without controls ****************/
*Here are the results from our regressions without controls outputted in a table:
createTableChi2 AUTOMATEDDISCOUNT11 tabAutoDisc catvList2
createTablett AUTOMATEDDISCOUNT11 ttAutoDisc contvList
createTableRegCat AUTOMATEDDISCOUNT11 catRegTableAuto vListLevels2 catvList2
createTableRegCont AUTOMATEDDISCOUNT11 contRegTableAuto contvList

/***************8) AUTOMATEDDISCOUNT11 Regressions with Age, Income, and other Controls *********/
* As with DISCOUNT, age, income and other characteristics may be mediating factors in our
* analysis of the relationship between present-biased behavior and well-being. 
* To account for this, I run logitistic regressions with AUTOMATEDDISCOUNT11 as the 
* DV controlling for age, income, and other factors as above.

// foreach var of varlist `catvList2' {
// 	logit AUTOMATEDDISCOUNT11 i.`var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT, or
// }
// foreach var of varlist `contvList' {
// 	logit AUTOMATEDDISCOUNT11 `var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT, or
// }

/*************** 9) Creating our summary tables for AUTOMATEDDISCOUNT11 with controls ****************/
*Here are the results from our AUTOMATEDDISCOUNT11 logistic regressions with controls outputted in a table:
createTableRegCatwControls AUTOMATEDDISCOUNT11 catRegTableAutoControl vListLevels2 catvList2
createTableRegContwControls AUTOMATEDDISCOUNT11 contRegTableAutoControl contvList


/*************** 10) AUTOMATEDDISCOUNT w/ DISCOUNT = 1 (without controls)  ***************/
* AUTOMMATEDDISCOUNT11=1 for those people who automated their retirement savings and 
* are potentially present-biased (prefer less money now) just within the population who said DISCOUNT==1

* Now checking the effect size and relationship between AUTOMATEDDISCOUNT11 and our 		
* categorical variables:
foreach var of varlist `catvList2' {
	di "`var' if DISCOUNT==1"
	tabulate `var' AUTOMATEDDISCOUNT11 if DISCOUNT==1, chi2 row missing
}
* And the relationship between AUTOMATEDDISCOUNT11 and our 		
* continuous variables:
 foreach var of varlist `contvList' {
 	di "`var' if DISCOUNT==1, by(AUTOMATEDDISCOUNT11)"
 	ttest `var' if DISCOUNT==1, by(AUTOMATEDDISCOUNT11)
 }

* As a robustness check, we predict AUTOMATEDDISCOUNT11 with every variable one-by-one
* without controls. Categorical:
// foreach var of varlist `catvList2' {
// 	logit AUTOMATEDDISCOUNT11 i.`var' if DISCOUNT==1, or
// }
// // Continuous:
// foreach var of varlist `contvList' {
// 	logit AUTOMATEDDISCOUNT11 `var' if DISCOUNT==1, or
// }
* Overall, all 20 variables have significant relationships with AUTOMATEDDISCOUNT11 without controls and within DISCOUNT==1 population.

/*************** 11) Summary Tables of Results for AUTOMATEDDISCOUNT11 w/ DISCOUNT = 1 without controls ****************/
*Here are the results from our regressions without controls outputted in a table:
createTableChi2DISCOUNT AUTOMATEDDISCOUNT11 tabAUTODisc2 catvList2
createTablettDISCOUNT AUTOMATEDDISCOUNT11 ttAUTODisc2 contvList
createTableRegCatDISCOUNT AUTOMATEDDISCOUNT11 catRegTableAuto2 vListLevels2 catvList2
createTableRegContDISCOUNT AUTOMATEDDISCOUNT11 contRegTableAuto2 contvList
/***************12) AUTOMATEDDISCOUNT11 w/ DISCOUNT == 1 Regressions with Age, Income, and other Controls *********/
* As with DISCOUNT, age, income and other characteristics may be mediating factors in our
* analysis of the relationship between present-biased behavior and well-being. 
* To account for this, I run logistic regressions with AUTOMATEDDISCOUNT11 if DISCOUNT==1 as the 
* DV controlling for age, income, and other factors as above.

// foreach var of varlist `catvList2' {
// 	logit AUTOMATEDDISCOUNT11 i.`var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT if DISCOUNT==1, or
// }
// foreach var of varlist `contvList' {
// 	logit AUTOMATEDDISCOUNT11 `var' PPAGE i.PPINCIMP i.PPEDUC FEMALE i.PPWORK i.PPMARIT if DISCOUNT==1, or
// }

/*************** 13) Creating our summary tables for AUTOMATEDDISCOUNT11 w/ DISCOUNT ==1 with controls ****************/
*Here are the results from our AUTOMATEDDISCOUNT11 logistic regressions when DISCOUNT ==1, with controls outputted in a table:
TableRegCatControlsDISC AUTOMATEDDISCOUNT11 catRegTableAutoControl2 vListLevels2 catvList2
TableRegContControlsDISC AUTOMATEDDISCOUNT11 contRegTableAutoControl2 contvList

capture log close
translator set smcl2pdf pagesize custom
translator set smcl2pdf pagewidth 11.0
translator set smcl2pdf pageheight 8.5
translate FWBAnalyzedLog.smcl FWBAnalyzedLog.pdf, replace
* translate FWBAnalyzedLog.smcl FWBAnalyzedMatrices.pdf, replace

// beep

//must keep this blank
