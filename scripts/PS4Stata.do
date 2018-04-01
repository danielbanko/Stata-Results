clear
set more off
cap log close

log using "/Users/Banjodan2/Desktop/PS4LogFile.smcl", replace
* Do file for PS3 Q6 and 7
* Daniel Banko
/*------------------------------------------------------------------------------
		Date Created: Oct 21, 2015
------------------------------------------------------------------------------*/
set obs 1
generate str var1 = "year" in 1
replace var1 = "1968" in 1
set obs 2
replace var1 = "1969" in 2
set obs 3
replace var1 = "1970" in 3
set obs 4
replace var1 = "1971" in 4
set obs 5
replace var1 = "1972" in 5
set obs 6
replace var1 = "1973" in 6
set obs 7
replace var1 = "1974" in 7
set obs 8
replace var1 = "1975" in 8
set obs 9
replace var1 = "1976" in 9
set obs 10
replace var1 = "1977" in 10
set obs 11
replace var1 = "1978" in 11
set obs 12

generate var2 = 10.7 in 1
replace var2 = 11.1 in 2
replace var2 = 11.5 in 3
replace var2 = 117 in 4
replace var2 = 11.67 in 4
replace var2 = 11.7 in 4
replace var2 = 12.0 in 5
replace var2 = 12.0 in 6
replace var2 = 12.1 in 7
replace var2 = 12.7 in 8
replace var2 = 12.5 in 9
replace var2 = 13.3 in 10
replace var2 = 12.5 in 11

generate var3 = 3.6 in 1
replace var3 = 3.5 in 2
replace var3 = 4.9 in 3
replace var3 = 5.9 in 4
replace var3 = 5.6 in 5
replace var3 = 4.9 in 6
replace var3 = 5.6 in 7
replace var3 = 8.5 in 8
replace var3 = 7.7 in 9
replace var3 = 7.0 in 10
replace var3 = 6.0 in 11

//renaming vars
rename var1 year
rename var2 srate
rename var3 urate

//Question 6:
scatter srate urate

//Question 7:
regress srate urate
/*a) B0 is 9.672 and the B1 coefficient is .4066.
/*B1 being positive means the relationship between srate and urate is positive,
and that for every 1 unit increase in the unemployment rate, we expect the
suicide rate to increase by .4 percentage points. B0 of 9.672 tells us that we
 would predict suicide rate to be 9.672 percentage for an unemployment rate of 0
 percent.

/*b) We can reject the null nypothesis that the unemployment rate has zero
 "effect" on the suicide rate at the 95% level of confidence because the 
 95% CI interval for B1 does not include 0.
 
*/c) R^2 is .7223, which tells us that 72% of the variation in the suicide rate 
can be explained by variations in the unemployment rate.
*/
*/
//Question 8:
predict srate_hat
gen error = srate - srate_hat
list year srate srate_hat error
sum
/*the average estimate error is .000000087. This tells us that there is not a 
lot of variation in the actual (observed) sucide rate in each year away from 
the predicted suicide rate in each year.
*/
replace year = "1979" in 12
replace urate = 5.8 in 12



