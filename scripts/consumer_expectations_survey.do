cap log close
clear all
set more off
set trace off
pause on
local projectpath /Users/Banjodan2/Dropbox/Stata
cd `projectpath'
cap log using `projectpath'/log/time_series_outcomes.txt, replace text
set excelxlsxlargefile on
/***************************************************\
* Practice with Stata: data downloaded from... 	   */
* Date modified:								   */
* Output saved in: "/Users/Banjodan2/Desktop/Stata/"
/***************************************************/

//import excel `projectpath'/data/FRBNY-SCE-DATA.xls, sheet("Inflation expectations") cellrange(A4) firstrow
/* import excel `projectpath'/data/FRBNY-SCE-Public-Microdata-Complete.xlsx, sheet("Data") cellrange(A2) firstrow //(too big)
export delimited using `projectpath'/data/FRBNY-SCE-Public-Microdata-Complete, replace */
import delimited using `projectpath'/data/FRBNY-SCE-Public-Microdata-Complete, numericcols(3/165, 167/213) stringcols(1, 2, 166, 214/218) clear

//export delimited using `projectpath'/data/FRBNY-SCE-DATA_Inflation_expectations, replace
//import delimited using `projectpath'/data/FRBNY-SCE-DATA_Inflation_expectations, numericcols(2/9) stringcols(1) clear

gen date2 = date(date,"YM")
drop date
gen date = date2
format date %td
drop date2
order date, first
//mylabels "1 Jul 2013" "1 Jan 2014" "1 Jul 2014" "1 Jan 2015" "1 Jul 2015" "1 Jan 2016" "1 Jul 2016" "1 Jan 2017" "1 Jul 2017" "1 Jan 2018", myscale(clock("@", "DMY")) local(time_labels)

//graph twoway line medianoneyearaheadexpectedi medianthreeyearaheadexpected date, legend(label(1 "Median one-year ahead expected inflation rate") label(2 "Median three-year ahead expected inflation rate") rows(2)) ylabel(0(2)8, angle(horizontal)) ytitle("Expected inflation rate (%)")

//graph export `projectpath'/output/figures/inflation_expectations.png, replace
save `projectpath'/data/FRBNY-SCE-Public-Microdata-Complete, replace
log close
	
//How do I disentangle peopole who are ignorant of their actual economic prospects (perceived economic prospect) and actual economic prospect?
//Regress education + region with some way to control for prospects
//Find an economic article that answers a related or similarly related question
//Do same 1 sentence summary: what is question? why interestesting? Why did they find?