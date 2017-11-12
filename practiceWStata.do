										///										
capture log close
clear
set more off
local projectpath "/Users/Banjodan2/Desktop/StataPractice/"
cd `projectpath'
capture log using "PracticeStataLog", replace
/*************************************************
* Practice with Stata--hospital noshow rates data downloaded from internet***/
* Date modified:
* Output saved in: "/Users/Banjodan2/Desktop/StataPractice/"

import delimited /`projectpath'/KaggleV2-May-2016.csv
//clean the data
drop if age < 0


local categoricalVars "gender scholarship hipertension diabetes alcoholism handcap sms_received noshow neighbourhood"
local size : word count `categoricalVars'

di "We have `size' categorical variables."

*summarizing the categorical vars:
foreach var of varlist `categoricalVars' {
	sum `var'
	tabulate `var', missing plot
}

note gender: there is not a significant difference between no-show rates of males vs females

save "PracticeDataCleaned.dta", replace
capture log close

//leave blank