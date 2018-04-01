scatter wage year

twoway lfit lfp year
twoway lfit wage year

twoway lfit lfp year if age > 15, by(sex)
twoway lfit lfp year if age > 15, by(white)
twoway lfit lfp year if age > 15, by(age_group)
twoway lfit lfp year if age > 25 & sex == 1, by(skilled) //linear fitted values model >25 year-old men labor participation by educational attainment
twoway lfit lfp year if age > 15, by(skilled)
twoway lfit lfp year if age > 15, by(white sex)
twoway lfit lfp year if age > 15, by(white skilled)

twoway lfit wage year if age > 15, by(sex)
twoway lfit wage year if age > 15, by(white)
twoway lfit wage year if age > 15, by(age_group)
twoway lfit wage year if age > 25 & sex == 1, by(skilled white) //linear fitted values model >25 year-old men wage by educational attainment
twoway lfit wage year if age > 15, by(skilled)
twoway lfit wage year if age > 15, by(white sex)
twoway lfit wage year if age > 15, by(white skilled)

sum wage if year == 1976 & sex == 1
sum wage if year == 1976 & sex == 2
sum wage if year == 2015 & sex == 1 //male wages in 2015
sum wage if year == 2015 & sex == 2 //female wages in 2015

twoway (lfit wage year if age > 25 & sex == 1 & white == 1 & skilled == 1) (lfit wage year if age > 25 & sex == 1 & white == 0 & skilled == 0)
