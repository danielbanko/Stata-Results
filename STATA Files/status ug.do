clear
set more off
cd "C:\Users\Gordon\Documents\Projects\Status\data"
import excel "DBGKT_rank_UG_1.xlsx", clear firstrow



gen public=(epu!=.)
replace public=. if epu==. & epr==.
la de label_public 0 "Private" 1 "Public"
la val public label_public

gen high=(hi==1)
replace high=. if hi==. & lo==.
la de label_status 0 "Lo Status" 1 "Hi Status"
la val high label_status

gen iq1c=(IQ1==3)
gen iq2c=(IQ2==3)
gen iq3c=(IQ3==5)
gen iq4c=(IQ4==2)
gen iq5c=(IQ5==3)
gen iq6c=(IQ6==3)
gen iq7c=(IQ7==3)
gen iq8c=(IQ8==2)
egen iq=rowtotal(iq1c iq2c iq3c iq4c iq5c iq6c iq7c iq8c)

gen comp1c=(comp1==1)
gen comp2c=(comp2==1)
gen comp3c=(comp3==5)
gen comp4c=(comp4==0)
egen comp=rowtotal(comp1c comp2c comp3c comp4c)
gen comp_all=(comp==4)

egen mc=rowmean(mc1 mc2 mc3)

gen rank=(PR1==1 | WTPEP1==1)
replace rank=2 if PR2==1 | WTPEP2==1
replace rank=3 if PR3==1 | WTPEP3==1
replace rank=4 if PR4==1 | WTPEP4==1
replace rank=5 if PR5==1 | WTPEP5==1
replace rank=6 if PR6==1 | WTPEP6==1
replace rank=7 if PR7==1 | WTPEP7==1
replace rank=8 if PR8==1 | WTPEP8==1
replace rank=9 if PR9==1 | WTPEP9==1
replace rank=10 if PR10==1 | WTPEP10==1
gen hirank=(rank<=5)
la de label_hirank 0 "Lo Rank" 1 "Hi Rank"
la val hirank label_hirank

gen ugb=.
replace ugb=10 if ugb_10==0
replace ugb=9 if ugb_10==1 & ugb_9==0
replace ugb=8 if ugb_9==1 & ugb_8==0
replace ugb=7 if ugb_8==1 & ugb_7==0
replace ugb=6 if ugb_7==1 & ugb_6==0
replace ugb=5 if ugb_6==1 & ugb_5==0
replace ugb=4 if ugb_5==1 & ugb_4==0
replace ugb=3 if ugb_4==1 & ugb_3==0
replace ugb=2 if ugb_3==1 & ugb_2==0
replace ugb=1 if ugb_2==1 & ugb_1==0
replace ugb=0 if ugb_1==1

/////////////////////////////////////////
//visualize
/////////////////////////////////////////

gr bar uga,o(hirank) o(public) ysc(r(0 10))
gr bar ugb,o(hirank) o(public) ysc(r(0 10))
gr bar uga if public==1,o(high) ysc(r(0 10))
gr bar ugb if public==1,o(high) ysc(r(0 10))

/////////////////////////////////////////
//analysis
/////////////////////////////////////////

ttest uga,by(public) //public>private marg
reg uga public comp mc order //weaker
ttest ugb,by(public) //public>private marg
reg ugb public comp mc order //same

ttest uga,by(high) //hi>lo
reg uga high comp mc order //stronger
ttest ugb,by(high) //no
reg ugb high comp mc order //stronger

an uga public##hirank //public marg
an uga public##hirank order c.comp c.mc //weaker
an ugb public##hirank //public marg
an ugb public##hirank order c.comp c.mc //stronger

ttest uga if public==0,by(hirank) //no
ttest ugb if public==0,by(hirank) //no
reg uga rank if public==0 //marg
reg uga rank comp mc order if public==0 //weaker
reg ugb rank if public==0 //no
reg ugb rank comp mc order if public==0 //weaker

reg uga rank if public==1 //no
reg uga rank comp mc order if public==1 //stronger
reg ugb rank if public==1 //no
reg ugb rank comp mc order if public==1 //stronger
reg uga rank high if public==1 //high +
reg uga rank high comp mc order if public==1 //stronger
reg ugb rank high if public==1 //no
reg ugb rank high comp mc order if public==1 //stronger
an uga hirank##high if public==1 //high +
an uga hirank##high order c.comp c.mc if public==1 //stronger
an ugb hirank##high if public==1 //no
an ugb hirank##high order c.comp c.mc if public==1 //stronger
ttest uga if public==1,by(hirank) //no
ttest ugb if public==1,by(hirank) //no
ttest uga if public==1,by(high) //hi>lo
ttest ugb if public==1,by(high) //no

//in public, ppl are more generous & demand more
//absolute rank doesn't matter, comparative rank does
//hi status in public more generous


