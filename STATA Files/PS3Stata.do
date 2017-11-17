clear
set more off
cap log close

use "/Users/Banjodan2/Desktop/2003CPSWorkers.dta"
log using "/Users/Banjodan2/Desktop/PS3Stata.smcl"
* Do file for PS3
* Daniel Banko
/*------------------------------------------------------------------------------
		Date Created: Oct 21, 2015
------------------------------------------------------------------------------*/
describe
sum
ci hourly_wage if black==1 & male==0, level(95)
*95% ci = [15.73, 18.71]
*
ci hourly_wage if black==1 & male==0, level(90)
*90% ci = [15.97,18.47]
*
*It is narrower and more precise interval because we are less confident that the
*true population mean lies within the interval.
ci hourly_wage if black==1 & male==1, level(95)
*95% ci = [18.72, 21.78]
*
*This comparison shows us that, on average, black males had a higher hourly wage
*than black females did in 2003.

ttest hourly_wage==18.5 if black==1 & male==0
*
*Ha: mean < 18.5 p(T < t) = 0.0462
*
*The probability that the null hypothesis of the hourly wage for black
*females being equal to $18.5 is very low (<.05 chance).

ttest hourly_wage if black==1, by(male) unequal
*
*Ha: diff < 0 p(T < t) = 0.0027
*
*This tells us that the probability the null hypothesis is true is very low (<.05)
*compared to the alternative hypothesis that the difference between the mean 
*hourly wage of black females and the mean hourly wage of black males in 2003 is
*positive, or greater than 0.
