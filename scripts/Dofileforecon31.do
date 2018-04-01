clear
set more off
cap log close

import excel "/Users/Banjodan2/Dropbox/Swarthmore Documents/Junior Year/Fall 2015/Intro. to Econometrics/ec31data.xlsx", firstrow clear
log using "/Users/banjodan2/Desktop/ec31projectanalysis.smcl", replace

* Do file for Group 7 Project Fall 2015
* Daniel Banko
/*------------------------------------------------------------------------------
		Date Created: Oct 21, 2015
------------------------------------------------------------------------------*/

summarize

*dummy variable if a student participates in any organized sport.
gen athlete = 1 if varsityAthlete == 1 | clubAthlete == 1
replace athlete = 0 if athlete == .

*FIRST PRES HYPOTHESIS TESTS
ttest personalMa~s==2 //significant at .05
ttest predictedM~s==2 //almost significant at .1 (larger sample size needed)
ttest diff==0  //significant with one-sided test.
ttest personalMatchboxHours, by(varsityAthlete) level(99) //significant at .01


*VAR. PERSONAL HOURS REGRESSIONS- ALL HAVE HIGH P VALUES
regress personalMa~s goWithFriend 
*p val = 0.208
regress personalMa~s thirdOfDay
*p val = 0.647
regress personalMa~s breakfastFreq
*p val = 0.459
regress personalMa~s firstClass
*p val = 0.282
regress personalMa~s classYear
*p val = 0.652
regress personalMa~s hoursOfSleep
*p val = 0.720
regress personalMa~s dorm
*p val = 0.932
regress personalMa~s stressLevel
*p val = 0.715

*REGRESSIONS WITH P VALUES UNDER 0.2
regress predictedM~s firstClass 
*p val = 0.103...so close! 
regress diff breakfastFreq
*p val = 0.127
regress diff goWithFriend
*p val = 0.118
regress predictedM~s varsityAthlete
*p val = 0.194

*ACTUALLY STATISTICALLY SIG REGRESSIONS
regress personalM~s varsityAthlete 
*p val = 0.0000
regress personalM~s varsityAthlete
regress personalMa~s clubAthlete varsityAthlete
test clubAthlete varsityAthlete
*p-value here is 0.0002--good! 
*although maybe the clubAthlete variable isn't helpful to add in? 
regress diff varsityAthlete
*p val = 0.000
*coef was 2.52, so being a varsity athlete was associated with on average
*estimating that you went to the Matchox 2.52 hours more per week than the 
*average Swattie
*scatter diff varsityAthlete
regress diff clubAthlete varsityAthlete
*p val for vars = 0.000, p val for club = 0.109
regress personalMa~s gender
*p val = 0.003
*coef was -1.32, so being female was associated with going to the matchbox
*1.32 hrs less per week
regress diff gender
*p val = 0.006
* being female was associated with -1.42 more of a difference between 
*personal and predicted hours- i.e. females estimated higher predicted avg
*Matchbox hours relative to personal hours than males

regress personalMa~s gender varsityAthlete
test gender varsityAthlete
*F test p val = 0.0000 so yes jointly significant

regress diff female varsityAthlete
regress personalM~s female varsityAthlete

*testing interaction variables
gen femaleVarsityAthlete = female*varsityAthlete

regress personalM~s female varsityAthlete femaleVarsityAthlete 
*R^2 = .19


