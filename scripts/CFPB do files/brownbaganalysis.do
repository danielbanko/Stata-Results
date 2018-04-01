																				///
capture log close
clear all
set more off
cd "/home/cfpb/banko-ferrand/Data collection r3_BrownBag"
use brownbag11292017_Merged
rename testquestionid questionid

replace playerq_levelone = "Y" if playerq_levelone == "Yes"
replace playerq_levelone = "N" if playerq_levelone == "No"
replace playerq_leveltwo = "Y" if playerq_leveltwo == "Yes"
replace playerq_leveltwo = "N" if playerq_leveltwo == "No"
replace playerq_levelthree = "Y" if playerq_levelthree == "Yes"
replace playerq_levelthree = "N" if playerq_levelthree == "No"

gen q_summary = ""
replace q_summary = playerq_levelone + playerq_leveltwo + playerq_levelthree

gen timespentlevel1 = .
gen timespentlevel2 = .
gen timespentlevel3 = .
replace timespentlevel1 = seconds_on_page if page_name == "surveyQuestionTop"
replace timespentlevel2 = seconds_on_page if page_name == "qlevelTwo"
replace timespentlevel3 = seconds_on_page if page_name == "qlevelThree"

//The questions which have hypothetical subquestions are 1,2,7,8,9,10,11,12,13,15
gen hypotheticalquestions = .
replace hypotheticalquestions = 1 if playerquestionid == 1 | playerquestionid 	 ///
				==  2| playerquestionid ==  7 | playerquestionid /// 
				==  8| playerquestionid ==  9 | playerquestionid ///
				== 10| playerquestionid == 11 | playerquestionid ///
				 == 12 | playerquestionid ==  13 | 		 ///
				 playerquestionid == 15
//Mark those participants (observations) who responded to hypothetical questions:			 
gen hypotheticalresponses = .
replace hypotheticalresponses = 1 if playerq_levelone == "N" & hypotheticalquestions == 1
gen questionhyptag = .
//so that we can keep track of what question it was:
replace questionhyptag = playerquestionid if hypotheticalresponses == 1

//Tag those questions which have 'super sophisticated' subquestions:
gen supersophisticated = .
replace supersophisticated= 1 if playerq_levelone == "N" & hypotheticalquestions != 1
gen supertag = .
replace supertag = playerquestionid if supersophisticated == 1

//mark the hypothetical questions in the time_spent data:
gen hyptree = .
local i = 1
local size = _N
while `i' < `size' {
	local n = 1
	while `n' < 16 {
		local j = 1
		while `j' < 16 {
			if questionhyptag[`i'] == `j'{
				quietly replace hyptree = 1 if questionid == `j' & participant__id_in_session == `n'
			}
			local j = `j' + 1
		}
		local n = `n'+1
	}
	local i = `i'+1
}

//mark the supersophisticated questions in the timespent data
gen supertree = .
local i = 1
local size = _N
while `i' < `size' {
	local n = 1
	while `n' < 16 {
		local j = 1
		while `j' < 16 {
			if supertag[`i'] == `j'{
				quietly replace supertree = 1 if questionid == `j' & participant__id_in_session == `n'
			}
			local j = `j' + 1
		}
		local n = `n'+1
	}
	local i = `i'+1
}

//Classify individuals based on our SophScale labeling method:
gen PBSoph = .
gen PBNotSoph = .
gen NotPB = .
replace PBSoph = 1 if q_summary == "YYY"
replace PBNotSoph = 1 if q_summary == "YNY"
replace NotPB = 1 if q_summary == "YYN" | q_summary=="YNN"

//Tally classification totals for each participant:
bysort participantid_in_session: egen totPBSoph = sum(PBSoph)
bysort participantid_in_session: egen totPBNotSoph = sum(PBNotSoph)
bysort participantid_in_session: egen totNotPB = sum(NotPB)

//...and totals for each question:
bysort playerquestionid: egen PBSoph_byquestion = sum(PBSoph)
bysort playerquestionid: egen PBNotSoph_byquestion = sum(PBNotSoph)
bysort playerquestionid: egen NotPB_byquestion = sum(NotPB)

//Calculate total time taken to complete survey:
bysort testparticipantid:  egen surveytotal = sum(seconds_on_page)
gen minutes = surveytotal/60

rename playerquestionid QuestionID
rename participantid_in_session participantID
rename participant__id_in_session participantID_ex
rename questionid QuestionID_ex

label variable QuestionID "QuestionID"
label variable QuestionID_ex "QuestionID for time data"
label variable participantID "userID"
label variable participantID_ex "userID for time data"

// Responses by participant id:
// table participantID q_summary, center missing

capture log using "analysisLog", replace
/*----------------------------------------------------------------*/
* Daniel Banko-Ferran - brownbaganalysis.do                       		 		
* Examine brown bag data for Soph Scale project 				 		  
* Data modified: Thurs Dec 21 2017						  		  
* Output saved in: "/home/cfpb/banko-ferrand/Data collection r3_BrownBag"
/*----------------------------------------------------------------*/

//Responses by Question ID:
//NOTE: PBSoph=YYY, PBNotSoph=YNY, NotPB=YYN or YNN
table QuestionID q_summary, missing stubwidth(10) row

//Total time taken for each participant:
//Note that participantid==5 is excluded from all analyses
//NOTE: first column is seconds, second column is minutes
table participantID_ex, c(mean surveytotal mean minutes) format(%9.2f) center

//Total time taken for each question:
//NOTE: all columns are in seconds
bysort participantID_ex QuestionID_ex: egen questiontotaltime = sum(seconds_on_page)
table QuestionID_ex, c(p50 questiontotaltime min questiontotaltime max questiontotaltime) format(%9.2f) stubwidth(10) center

//Did participants dwell on any particular level? No.
tabstat timespentlevel1, s(p50, min, max) format(%6.2f) varwidth(15)
tabstat timespentlevel2, s(p50, min, max) format(%6.2f) varwidth(15)
tabstat timespentlevel3, s(p50, min, max) format(%6.2f) varwidth(15)

//What was the average total time to take survey?
sum surveytotal
// Participants spent on average 284 seconds (4.73 minutes) taking the survey

//Did people take longer to respond to hypothetical questions? Yes, slightly.
gen hypresponse = .
replace hypresponse = 0 if page_name == "qlevelTwo" & hyptree!=1
replace hypresponse = 1 if page_name == "qlevelTwo" & hyptree==1
table hypresponse if supertree!=1, c(mean seconds_on_page min seconds_on_page max seconds_on_page) format(%9.2f) stubwidth(10) center

//What were the actual responses by individual?
table participantID, c(sum PBSoph sum PBNotSoph sum NotPB) cellwidth(10) center

//Scoring individuals on sophistication based on our PBSoph/PB+PBSoph formula:
bysort participantID: gen SophScore = round(totPBSoph/(totPBSoph+totPBNotSoph),.01)
table participantID, c(mean SophScore) center

//How did each item do in categorizing individuals?
table QuestionID, c(sum PBSoph sum PBNotSoph sum NotPB) stubwidth(10)

capture log close
translator set smcl2pdf pagesize custom
translator set smcl2pdf pagewidth 11.0
translator set smcl2pdf pageheight 8.5
translate analysisLog.smcl analysisLog.pdf, replace
order q_summary hypotheticalquestions hypotheticalresponses questionhyptag q_summary hypotheticalquestions hypotheticalresponses questionhyptag PBSoph PBNotSoph NotPB totPBSoph totPBNotSoph totNotPB PBSoph_byquestion PBNotSoph_byquestion NotPB_byquestion SophScore, b(_merge)
order page_index participantID_ex, b(QuestionID_ex)
drop _merge index time_stamp sessioncode  subsession_pk auto_submitted app_name testparticipantid hypotheticalquestions supertag questionhyptag
sort participantID_ex QuestionID_ex page_index participantID QuestionID
//must keep this blank
