clear
set more off
cap log close

log using "/Users/Banjodan2/Desktop/PS4LogFile.smcl", replace
* Do file for PS5
* Daniel Banko
/*------------------------------------------------------------------------------
		Date Created: Dec 2, 2015
------------------------------------------------------------------------------*/
use "/Users/Banjodan2/Desktop/jtrain2.dta"

regress logearn78 train black hisp
/* The model predicts that, on average, workers in 1978 who are black would earn
 63.72% less than workers in 1978 with the same job training who are not
 black.

 The coefficient on hisp tells us that, on average, we expect workers in 1978
 who are hispanic to earned 11.66% less than workers in 1978 with the same job
 training who are not hispanic.
*/

test black hisp

/*
Null Hypothesis: coefficient on black = coefficient on hisp = 0
Alternate Hypothesis: not all = 0

The Prob > F is 0.003, so we can reject null hypothesis with 99.7% confidence.
*/

regress logearn78 train black hisp age married dropout

/*
The coefficient tells us that we expect workers who are married in 1978 earned
on average 4.9% more than those workers with the same training, age, education,
and ethnicity who are unmarried in 1978.

The coefficient on dropout tells us that, on average, we expect workers in 1978
who dropped outearned 15.2% less than those workers with the same training, age,
ethnicity, and marriage status who did not drop out.
*/

test age married dropout
/*
Null hypothesis: coefficient on age, married, and dropout = 0
Alternate Hypothesis: not all = 0

Because Prob > F = 0.51, we cannot reject null hypothesis. Therefore, we can say
that age, married, and dropout did not improve upon our prior regression because
we were unable to reject the hypothesis that all three are = 0. We also can see
that the Adj R-squared falls when we add the three new variables (.039 vs. .041)
which means the predictive power of our model is weaker as a result of 
adding the new variables.
*/


