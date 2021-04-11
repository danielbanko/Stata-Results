clear all
cap log close
set more off
set trace off
set scheme cfpb
pause on

local projectpath /home/work/projects/Experian/Shared/ricksj/qcct_nov2018
cd `projectpath'

local CCPData /home/data/projects/Experian/ProcessedData/Stata
local ScoreVars consumer_nb vantage_sc deceased_cd
local TradeVars balance_dt consumer_nb ptk_nb kob_cd accounttype_cd balance_am balance_dt company_nb subscriber_nb estatus_cd condition_cd comment_cd ecoa_cd limit_am paymentgrid paymentgrid_cd open_dt actualpayment_am lastpayment_dt status_cd

log using `projectpath'/log/texas_map_data.txt, replace text
use `projectpath'/data/texas_data_2017_2018, clear

count

* gen Month = .
* replace Month = 6 if ReportingPeriod == "2017jun" 	
* replace Month = 7 if ReportingPeriod == "2017jul"
* replace Month = 8 if ReportingPeriod == "2017aug"
* replace Month = 9 if ReportingPeriod == "2017sep"
* replace Month = 10 if ReportingPeriod == "2017oct"
* replace Month = 11 if ReportingPeriod == "2017nov"
* replace Month = 12 if ReportingPeriod == "2017dec"
* replace Month = 13 if ReportingPeriod == "2018jan"
* replace Month = 14 if ReportingPeriod == "2018feb"
* replace Month = 15 if ReportingPeriod == "2018mar"
* replace Month = 16 if ReportingPeriod == "2018apr"

tab Month, m
tab comment_cd, m
bysort Month: tab comment_cd, m

gen nat_dis_cm = 0
replace nat_dis_cm = 1 if comment_cd == "54"
gen forbearance = cond(comment_cd == "CP",1,0,.)
gen comment_tag = cond(!inlist(comment_cd,"","00"),1,0,.)
gen deferred_payment = cond(comment_cd == "29",1,0,.)
gen resolved_dispute = cond(comment_cd == "13",1,0,.)
gen current_dispute = cond(comment_cd == "78",1,0,.)
gen disagreed_resolved = cond(comment_cd == "20",1,0,.)
gen other_comment = cond(!inlist(comment_cd, "29","54", "13", "CP", "78","20","","00"),1,0,.)

tab nat_dis_cm, m
tab nat_dis_cm if Month < 9, m
tab nat_dis_cm if Month > 8, m

bysort Month ptk_nb: gen accounts_tag = (_n==1)
bysort Month consumer_nb: gen consumers_tag = (_n==1)

tab accounts_tag, m
tab consumers_tag, m

//pause
gen nat_dis_cm_cc = nat_dis_cm if loan_type == 200
gen nat_dis_cm_mortgage = nat_dis_cm if loan_type == 110
gen nat_dis_cm_auto = nat_dis_cm if loan_type == 100
gen nat_dis_cm_student = nat_dis_cm if loan_type == 150
gen nat_dis_cm_HELOC = nat_dis_cm if loan_type == inlist(loan_type,120,220)
gen nat_dis_cm_other = nat_dis_cm if loan_type == !inlist(loan_type,120,220,150,100,200,110)

preserve
collapse (sum) nat_dis_cm nat_dis_cm_cc nat_dis_cm_mortgage nat_dis_cm_aut nat_dis_cm_student nat_dis_cm_HELOC nat_dis_cm_other accounts_tag, by(county Month)
table Month, c(sum nat_dis_cm) m
table county Month, c(sum nat_dis_cm) m
gen nat_proportion = .
replace nat_proportion = 0 if accounts_tag == 0
bysort county Month: replace nat_proportion = nat_dis_cm/accounts_tag*100 if accounts_tag != 0
foreach debt in _cc _mortgage _auto _student _HELOC _other {
	gen nat_proportion`debt' = .
	replace nat_proportion`debt' = 0 if accounts_tag == 0
	bysort county Month: replace nat_proportion`debt' = nat_dis_cm`debt'/accounts_tag*100 if accounts_tag != 0
}

format nat_proportion %6.2f
sum nat_proportion, detail

//create maps:
#delim ;

foreach var of varlist nat_proportion_cc nat_proportion_mortgage nat_proportion_student nat_proportion_auto nat_proportion_HELOC nat_proportion_other {;
	maptile `var' if Month == 8, 
	geography(county2014) mapif(floor(county/1000)==48)  
	spopt(legend(position(7))) 
	legd(2) 
	savegraph(`projectpath'/figures/maps/texas_natural_disaster_cd_aug_`var'.png) 
	replace
	cutvalues(0 0.25 0.5 0.75 1)  
	twopt(
		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01-0.25") lab(4 "0.26-0.50") lab(5 "0.51-0.75") lab(6 "0.76-1.00") lab(7 "1.01+") title("Comment" "% of total", position(11) size(small)))
		title("Natural Disaster Comment `var'" "August 2017", position(12) size(medium))
	);

maptile `var' if Month == 9, 
	geography(county2014) 
	mapif(floor(county/1000)==48)  
	spopt(legend(position(7))) 
	legd(2) 
	savegraph(`projectpath'/figures/maps/texas_natural_disaster_cd_sep_`var'.png) 
	replace 
	cutvalues(0 0.05 0.25 2.25 5) 
	twopt(
		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.05") lab(4 "0.06 - 0.25") lab(5 "0.26-2.25") lab(6 "2.26-5.00") lab(7 "5.01+") title("Comment" "% of total", position(11) size(small)))
		title("Natural Disaster Comment `var' " "September 2017", position(12) size(medium))
	);

maptile `var' if Month == 10, 
	geography(county2014) 
	mapif(floor(county/1000)==48)  
	spopt(legend(position(7)))
	legd(2) 
	savegraph(`projectpath'/figures/maps/texas_natural_disaster_cd_oct_`var'.png) 
	replace 
	cutvalues(0 0.15 0.35 1 5) 
	twopt(
		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") title("Comment" "% of total", position(11) size(small)))
		title("Natural Disaster Comment `var'" "October 2017", position(12) size(medium))
	);

maptile `var' if Month == 11, 
	geography(county2014) 
	mapif(floor(county/1000)==48) 
	spopt(legend(position(7))) legd(2) 
	savegraph(`projectpath'/figures/maps/texas_natural_disaster_cd_nov_`var'.png) 
	replace 
	cutvalues(0 0.15 0.35 1 5) 
	twopt(
		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") title("Comment" "% of total", position(11) size(small)) )
		title("Natural Disaster Comment `var'" "November 2017", position(12) size(medium))
	);

maptile `var' if Month == 12, 
	geography(county2014) 
	mapif(floor(county/1000)==48)  
	spopt(legend(position(7))) 
	legd(2) 
	savegraph(`projectpath'/figures/maps/texas_natural_disaster_cd_dec_`var'.png) 
	replace 
	cutvalues(0 0.15 0.35 1 5)
	twopt(
		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") title("Comment" "% of total", position(11) size(small)))
		title("Natural Disaster Comment `var'" "December 2017", position(12) size(medium))
	);

	
maptile `var' if Month == 13, 
	geography(county2014) 
	mapif(floor(county/1000)==48) 
	spopt(legend(position(7))) 
	legd(2) 
	savegraph(`projectpath'/figures/maps/texas_natural_disaster_cd_jan_`var'.png) 
	replace 
	cutvalues(0 0.15 0.35 1 5) 
	twopt(
		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") title("Comment" "% of total", position(11) size(small)) )
		title("Natural Disaster Comment `var'" "January 2018", position(12) size(medium))
	);

maptile `var' if Month == 14, 
	geography(county2014) 
	mapif(floor(county/1000)==48)  
	spopt(legend(position(7))) 
	legd(2) 
	savegraph(`projectpath'/figures/maps/texas_natural_disaster_cd_feb_`var'.png) 
	replace 
	cutvalues(0 0.15 0.35 1 5)
	twopt(
		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") title("Comment" "% of total", position(11) size(small)))
		title("Natural Disaster Comment `var'" "February 2018", position(12) size(medium))
	);


maptile `var' if Month == 15, 
	geography(county2014) 
	mapif(floor(county/1000)==48)  
	spopt(legend(position(7))) 
	legd(2) 
	savegraph(`projectpath'/figures/maps/texas_natural_disaster_cd_feb_`var'.png) 
	replace 
	cutvalues(0 0.15 0.35 1 5)
	twopt(
		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") title("Comment" "% of total", position(11) size(small)))
		title("Natural Disaster Comment `var'" "March 2018", position(12) size(medium))
	);


maptile `var' if Month == 16, 
	geography(county2014) 
	mapif(floor(county/1000)==48)  
	spopt(legend(position(7))) 
	legd(2) 
	savegraph(`projectpath'/figures/maps/texas_natural_disaster_cd_feb_`var'.png) 
	replace 
	cutvalues(0 0.15 0.35 1 5)
	twopt(
		legend(lab(1 "No data") lab(2 "0") lab(3 "0.01 - 0.15") lab(4 "0.16 - 0.35") lab(5 "0.36-1.00") lab(6 "1.00-5.00") lab(7 "5.00+") title("Comment" "% of total", position(11) size(small)))
		title("Natural Disaster Comment `var'" "April 2018", position(12) size(medium))
	);
};

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

shell echo -e "It's Done" | mail -s "STATA finished" "daniel.banko-ferran@cfpb.gov"
