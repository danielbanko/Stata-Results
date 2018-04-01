clear
set more off
cap log close

log using "/Users/Banjodan2/Desktop/PS4LogFile.smcl", replace
* Do file for PS4 Q3
* Daniel Banko
/*------------------------------------------------------------------------------
		Date Created: Oct 21, 2015
------------------------------------------------------------------------------*/
set obs 1
generate var1 = 10 in 1
set obs 2
replace var1 = 12 in 2
set obs 3
replace var1 = 28 in 3
set obs 4
replace var1 = 24 in 4
set obs 5
replace var1 = 18 in 5
set obs 6
replace var1 = 16 in 6
set obs 7
replace var1 = 15 in 7
set obs 8
replace var1 = 12 in 8
generate var2 = 55 in 1
replace var2 = 60 in 2
replace var2 = 85 in 3
replace var2 = 75 in 4
replace var2 = 80 in 5
replace var2 = 85 in 6
replace var2 = 65 in 7
replace var2 = 60 in 8
rename var1 weeklySales
rename var2 testScore
regress weeklySales testScore
