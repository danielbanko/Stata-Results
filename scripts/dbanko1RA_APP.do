clear all

import delimited "/Users/Banjodan2/Desktop/scp-1205.csv"

/*defining variable names*/
gen countyname = v1
gen state = v2
gen healthplanname = v4
gen typeofplan = v5
gen countyssa = v6
gen eligibles = v7
gen enrollees = v8
gen penetration = v9
gen greaterthan10 = 0

by healthplanname, sort: gen nvals = _n //summing number of adopters for each health plan by county
by countyname, sort: replace greaterthan10 = 1 if nvals == 11 //marking the plans who have more than 10 enrollees

by countyname, sort: egen numberofplans1 = sum(greaterthan10) //number of health plans with more than 10 enrollees

destring penetration, replace
replace penetration = 0 if penetration == .

by countyname, sort: egen numberofplans2 = sum(penetration > 0.5) //number of health plans with penetration > 0.5

destring enrollees, replace
replace enrollees = 0 if enrollees == .
by countyname, sort: egen totalenrollees = sum(enrollees) //summing number of health care enrollees by county

destring eligibles, replace
replace eligibles = 0 if eligibles == .
by countyname, sort: replace eligibles = sum(eligibles) //summing number of elgible individuals by county

by countyname, sort: gen totalpenetration = (totalenrollees/eligibles)*100 //calculating total penetration by county

by countyname, sort: gen nvals2 = _n == 1 //mark the first entry of a county
drop if nvals2 == 0 //drop all other occurrences of a county.

drop typeofplan enrollees penetration totalenrollees v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 greaterthan10 nvals nvals2
sort state countyname




