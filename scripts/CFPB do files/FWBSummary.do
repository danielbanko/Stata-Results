																				///
capture log close																
clear all
set more off
set trace off
local projectpath "/home/cfpb/banko-ferrand/WriteUp4Journal/BankoFWBAnalysis/Analysis"
cd `projectpath'
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
local catvList "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_1 AUTOMATED_2 MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"
local contvList "FWBscore CONNECT avgPROP avgMAN totSHOCK avgFINSOC"
local DEMOGRAPH "PPAGE PPINCIMP PPEDUC PPWORK FEMALE PPMARIT"
local catvList2 "REJECTED_1 REJECTED_2 COLLECT AUTOMATED_2 MANAGE2 SCFHORIZON ENDSMEETrev SAVEHABIT ABSORBSHOCK FRUGALITY ASK1_2 ASK1_1"

drop PPEDUCAT
* Create new dummy variables:
quietly gen SSChoice = 0 if DISCOUNT != . 
quietly replace SSChoice = 1 if DISCOUNT == 1
label variable SSChoice "=1 if DISCOUNT==1"
label define smallersooner 1 "Sooner, smaller reward" 0 "Later, larger reward" 
label values SSChoice smallersooner 
numlabel , add
quietly gen FEMALE = 0 if PPGENDER != .
quietly replace FEMALE = 1 if PPGENDER == 2
label variable FEMALE "=1 if PPGENDER==2"
* gen AUTOMATEDDISCOUNT11 = 0 if AUTOMATED_1 != . & DISCOUNT != .
* replace AUTOMATEDDISCOUNT11 = 1 if AUTOMATED_1 == 1 & DISCOUNT == 1
label variable AUTOMATEDDISCOUNT11 "=1 if AUTOMATED_1==1 & DISCOUNT==1"
*Creating indicator variables:

capture log using "FWBSummaryLog", replace

foreach var of varlist _all{
	sum `var'
	tabulate `var', missing plot
}

capture log close

translate FWBSummaryLog.smcl FWBSummary.pdf, replace
