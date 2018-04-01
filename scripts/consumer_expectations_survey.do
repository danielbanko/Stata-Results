

cap log close
clear all
set more off
set trace off
pause on
local projectpath /Users/Banjodan2/Dropbox/Stata
cd `projectpath'
cap log using `projectpath'/log/time_series_outcomes.txt, replace text

/*************************************************\
* Practice with Stata: data downloaded from internet***/
* Date modified:
* Output saved in: "/Users/Banjodan2/Desktop/StataPractice/"
/***************************************************/

import excel `projectpath'/data/FRBNY-SCE-DATA.xls, sheet("Inflation expectations") cellrange(A4) firstrow
export delimited using FRBNY-SCE-DATA_Inflation_expectations, replace
import delimited using FRBNY-SCE-DATA_Inflation_expectations, numericcols(2/9) stringcols(1) clear

rename f sevenfiveperconeyearexpinflrate
rename a date

gen date2 = date(date,"YM")
drop date
gen date = date2
format date %td
drop date2
order date, first
//mylabels "1 Jul 2013" "1 Jan 2014" "1 Jul 2014" "1 Jan 2015" "1 Jul 2015" "1 Jan 2016" "1 Jul 2016" "1 Jan 2017" "1 Jul 2017" "1 Jan 2018", myscale(clock("@", "DMY")) local(time_labels)

graph twoway line medianoneyearaheadexpectedi medianthreeyearaheadexpected date, legend(label(1 "Median one-year ahead expected inflation rate") label(2 "Median three-year ahead expected inflation rate") rows(2)) ylabel(0(2)8, angle(horizontal)) ytitle("Expected inflation rate (%)")

graph export `projectpath'/figures/inflation_expectations.png, replace

log close
	
