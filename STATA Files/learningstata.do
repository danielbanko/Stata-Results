clear
*Clears out the dataset that is currently in memory

 
capture log close
*Closes any log files you may have accidentally left open

 
cd "/Users/Banjodan2/Dropbox/Swarthmore Documents/Junior Year/Fall 2015/BE Team"
*Changes the working directory to the specified drive and directory

 
log using filename, replace
*Opens an existing log file called “filename,” deletes the contents and *places the current log into the file

 
use filename
*Loads a data set called "filename" into Stata
  
 
*** Useful Commands Below ***
 
 
browse
*Look at your data
 
preserve
*keeps data, allows you to drop subsequent stuff and then recover them later.

edit
*Look at your data, but in a way that you can change actual entries… I don’t advise this!
 
 
describe
*Lists each variable in Stata's memory
 
 
summarize
*Lists the number of observations, mean, standard deviation, min, and max for *a variable


sort var1 var2..
* sorts data by whichever variables you specify 


tab
*Gives frequencies (counts), and is most useful with categorical variables


bysort variable: tab variable2
bysort variable: sum variable2
* sorts by variable, then tabulates/summarizes variable2 by the different values of variable
 

correlate var1 var2
*Computes the correlation between var1 and var2
 

generate newvar = something
gen newvar = something
*Generates a new variable called newvar which is whatever you specify
 
 
replace var1 = something if blah == 1
*Replaces existing value of var1 with something if blah is equal to 1. *Something may be an expression. Replace can also be used without the "if" *qualifier. Notice there's a distinction between "=" and "==" throughout *Stata
 
drop var1
*Removes var1 from your dataset
 
 
regress y var1 var2, robust
reg y var1 var2, robust
*This computes the ordinary least squares estimates. y is the dependent *variable, all others are independent variables.  The robust command assumes *unequal variances
 
 
ttest varname1, by(varname2) unequal
*For two variables called "varname1" and "varname2," calculate an independent *samples difference of means test; assumes unequal variances
 
 
log close
*Closes and saves the current log file
