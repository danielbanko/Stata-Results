clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on

local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018
cd `projectpath'

log using `projectpath'/log/map.txt, replace text
use `projectpath'/data/texas/Texas_genvars, clear

count

preserve
gen obs_cohort1 = obs if cohort==1
gen obs_cohort0 = obs if cohort==0
collapse (sum) obs_cohort1 obs_cohort0 total_obs = obs, by(county Month)
gen obs_cohort1_pct = obs_cohort1/total_obs*100
gen obs_cohort0_pct = obs_cohort0/total_obs*100
* table county cohort, c(sum total_obs) m
* table county Month, c(sum total_obs) m

#delim ;
foreach i in 5 6 7 8 9 10 11 12 13 14 15 16 {;
	maptile obs_cohort1_pct if Month == `i',
		geography(county2014)
		mapif(floor(county/1000)==48)
		spopt(legend(position(7)))
		twopt(	
				legend(title("Cohort Composition" " % of total", position(11) size(small)))
				title("Treated by county" "Month `i'", position(12) size(medium))
		)
		savegraph(`projectpath'/figures/texas/maps/texas_treated_pct_month`i'.png)
		replace;
};
restore;
preserve;
	maptile,
		geography(county2014)
		mapif(inlist(county,48201,48157,48339,48039,48167,48291,48473,48071,48015))
		spopt(legend(position(7)))
		twopt(	
				legend(title("Houston MSA", position(11) size(small)))
				title("", position(12) size(medium))
		)
		savegraph(`projectpath'/figures/texas/maps/houstonMSA.png)
		replace;

#delim cr
* gen forbearance_proportion = .
* replace forbearance_proportion = 0 if accounts_tag == 0
* bysort county Month: replace forbearance_proportion = forbearance/accounts_tag*100 if accounts_tag != 0

* gen deferred_payment_proportion = .
* replace deferred_payment_proportion = 0 if accounts_tag == 0
* bysort county Month: replace deferred_payment_proportion = deferred_payment/accounts_tag*100 if accounts_tag != 0


* //create maps:
* #delim ;
* rename forbearance_proportion Forbearance;
* rename deferred_payment_proportion Deferral;
* foreach var of varlist Forbearance Deferral {;
* maptile `var' if Month == 8, 
* 	geography(county2014) mapif(floor(county/1000)==48)  
* 	spopt(legend(position(7))) 
* 	legd(2) 
* 	savegraph(`projectpath'/figures/maps/texas_natural_disaster_cd_aug_`var'.png) 
* 	replace
* 	cutvalues(0 0.25 0.5 0.75 1)  
* 	twopt(
* 		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01-0.25") lab(4 "0.26-0.50") lab(5 "0.51-0.75") lab(6 "0.76-1.00") lab(7 "1.01+") title("Comment" "% of total", position(11) size(small)))
* 		title("`var' Comment Occurences" "August 2017", position(12) size(medium))
* 	);

* maptile `var' if Month == 9, 
* 	geography(county2014) 
* 	mapif(floor(county/1000)==48)  
* 	spopt(legend(position(7))) 
* 	legd(2) 
* 	savegraph(`projectpath'/figures/maps/texas_cd_sep_`var'.png) 
* 	replace 
* 	cutvalues(0 0.05 0.25 2.25 5) 
* 	twopt(
* 		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.05") lab(4 "0.06 - 0.25") lab(5 "0.26-2.25") lab(6 "2.26-5.00") lab(7 "5.01+") title("Comment" "% of total", position(11) size(small)))
* 		title("`var' Comment Occurences " "September 2017", position(12) size(medium))
* 	);

* maptile `var' if Month == 10, 
* 	geography(county2014) 
* 	mapif(floor(county/1000)==48)  
* 	spopt(legend(position(7)))
* 	legd(2) 
* 	savegraph(`projectpath'/figures/maps/texas_cd_oct_`var'.png) 
* 	replace 
* 	cutvalues(0 0.15 0.35 1 5) 
* 	twopt(
* 		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") title("Comment" "% of total", position(11) size(small)))
* 		title("`var' Comment Occurences" "October 2017", position(12) size(medium))
* 	);

* maptile `var' if Month == 11, 
* 	geography(county2014) 
* 	mapif(floor(county/1000)==48) 
* 	spopt(legend(position(7))) legd(2) 
* 	savegraph(`projectpath'/figures/maps/texas_cd_nov_`var'.png) 
* 	replace 
* 	cutvalues(0 0.15 0.35 1 5) 
* 	twopt(
* 		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") title("Comment" "% of total", position(11) size(small)) )
* 		title("`var' Comment Occurences" "November 2017", position(12) size(medium))
* 	);

* maptile `var' if Month == 12, 
* 	geography(county2014) 
* 	mapif(floor(county/1000)==48)  
* 	spopt(legend(position(7))) 
* 	legd(2) 
* 	savegraph(`projectpath'/figures/maps/texas_cd_dec_`var'.png) 
* 	replace 
* 	cutvalues(0 0.15 0.35 1 5)
* 	twopt(
* 		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") title("Comment" "% of total", position(11) size(small)))
* 		title("`var' Comment Occurences" "December 2017", position(12) size(medium))
* 	);

	
* maptile `var' if Month == 13, 
* 	geography(county2014) 
* 	mapif(floor(county/1000)==48) 
* 	spopt(legend(position(7))) 
* 	legd(2) 
* 	savegraph(`projectpath'/figures/maps/texas_cd_jan_`var'.png) 
* 	replace 
* 	cutvalues(0 0.15 0.35 1 5) 
* 	twopt(
* 		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") title("Comment" "% of total", position(11) size(small)) )
* 		title("`var' Comment Occurences" "January 2018", position(12) size(medium))
* 	);

* maptile `var' if Month == 14, 
* 	geography(county2014) 
* 	mapif(floor(county/1000)==48)  
* 	spopt(legend(position(7))) 
* 	legd(2) 
* 	savegraph(`projectpath'/figures/maps/texas_cd_feb_`var'.png) 
* 	replace 
* 	cutvalues(0 0.15 0.35 1 5)
* 	twopt(
* 		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") title("Comment" "% of total", position(11) size(small)))
* 		title("`var' Comment Occurences" "February 2018", position(12) size(medium))
* 	);

* maptile `var' if Month == 15, 
* 	geography(county2014) 
* 	mapif(floor(county/1000)==48)  
* 	spopt(legend(position(7))) 
* 	legd(2) 
* 	savegraph(`projectpath'/figures/maps/texas_cd_feb_`var'.png) 
* 	replace 
* 	cutvalues(0 0.15 0.35 1 5)
* 	twopt(
* 		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") title("Comment" "% of total", position(11) size(small)))
* 		title("`var' Comment Occurences" "March 2018", position(12) size(medium))
* 	);

* maptile `var' if Month == 16, 
* 	geography(county2014) 
* 	mapif(floor(county/1000)==48)  
* 	spopt(legend(position(7))) 
* 	legd(2) 
* 	savegraph(`projectpath'/figures/maps/texas_cd_feb_`var'.png) 
* 	replace 
* 	cutvalues(0 0.15 0.35 1 5)
* 	twopt(
* 		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") 
* 		title("Comment" "% of total",
* 		position(11) 
* 		size(small)))
* 		title("`var' Comment Occurences" "April 2018", position(12) size(medium))
* 	);
* };

// preserve
// collapse (sum) nat_dis_cm consumers_tag, by(county Month)
// tab Month nat_dis_cm, m
//
// county Month, c(sum nat_dis_cm) m
// gen nat_proportion = .
// replace nat_proportion = 0 if accounts_tag == 0
// bysort county Month: replace nat_proportion = nat_dis_cm/accounts_tag*100 if accounts_tag != 0
// format nat_proportion %6.2f

log close
