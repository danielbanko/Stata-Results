*Daniel Banko

clear
set more off
capture response
capture log close

cd "/Users/Banjodan2/Documents/Dropbox/Swarthmore Documents/Research Stuff"

import excel "/Users/Banjodan2/Downloads/Custodial Absentee report ANON.xls", sheet("Sheet1")

keep if E!="" | L=="Time"
drop if A=="Employee"

*DROP EMPTY VARIABLES
drop B C D F G H J K M O P R S T V W X Z AA
drop I L N Q U Y

gen whyabsent=""
replace whyabsent=A[_n+1] //took all values from the row below and moved them up.

drop if E==""

rename A id
rename E date

label variable id "this is the id number"
label variable date "date"
label variable whyabsent "reason for absence"

gen date2 = date(date,"DMY") //note: NOT dmy must be upper case
format date2 %td
drop date
rename date2 date

label variable date "date"

gen month = month(date)
gen day = day(date)
gen year = year(date)

bysort month: tab whyabsent //sort by month, then show me the number of absences happening in each month

gen AWOL = 0
replace AWOL = 1 if whyabsent == "A W O L"

gen month2 = month if year==2015 
replace month2 = month+12 if year==2016
label variable month2 "month in data, Jan'15=1 Jan'16=13"

bysort month2: egen meanAWOLSinmonth=mean(awol)

bysort month2: gen count=_n

preserve
drop if count!=1
hist month2 meanAWOLsinmonth
restore


