clear
set more off
cap log close

import excel "/Users/Banjodan2/Desktop/econometricsProjectdata.xlsx", firstrow clear
log using "/Users/Banjodan2/Desktop/Analysis.smcl", replace
* Do file for econometrics project
* Daniel Banko
/*------------------------------------------------------------------------------
		Date Created: Oct 29, 2015
------------------------------------------------------------------------------*/
drop timestamp
