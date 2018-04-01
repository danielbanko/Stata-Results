/* Set as time series */
gegen double groupReferenceNumber = group(DataSource ReferenceNumber)
gen  numReportingPeriod          = mofd(date(string(ReportingPeriod_int), "YM"))
* gen  numReportingPeriod        = mofd(date(ReportingPeriod, "YM"))
format numReportingPeriod %tm
xtset groupReferenceNumber numReportingPeriod

/* Drop outliers */
summ ActualPaymentAmount, detail
replace ActualPaymentAmount = .o if ActualPaymentAmount > `r(p99)'

/* Remove negatives */
foreach var of varlist FinanceCharge ActualPaymentAmount {
  replace `var' = .n if `var' < 0
}

/* Remove payment if no balance */
replace ActualPaymentAmount = .e if CycleEndingBalance <= 0

/* Replace as errors if payment exceeds balance */
replace ActualPaymentAmount = .e if   CycleEndingBalance < ActualPaymentAmount ///
                                    & !missing(CycleEndingBalance)             ///
                                    & !missing(ActualPaymentAmount)

/* Remove FICO scores with zeroes */
foreach var of varlist RefreshedFicoScorePrimBorrower OriginalFicoScorePrimBorrower {
    replace `var' = .e if !inrange(`var', 300, 850)
}

/* Remove 99.99 and negative APRs */
replace CycleEndingRetailAPR = .e if round(CycleEndingRetailAPR, .01) == 99.99 & !missing(CycleEndingRetailAPR)

/* Lable variables */
label var ActualPaymentAmount            "Payment ($)"
label var RefreshedFicoScorePrimBorrower "Current FICO"
label var OriginalFicoScorePrimBorrower  "FICO at Origination"
label var BorrowerIncome                 "Reported Income at Origination"
label var CycleEndingRetailAPR           "APR (%)"
label var CurrentCreditLimit             "Current Credit Limit"
label var MinimumPaymentDue              "Minimum Payment"

//merge m:1 DataSource using "Data/DataSourceRand.dta", keep(master matched) nogen

summ BorrowerIncome, detail
replace BorrowerIncome = `r(p99)' if !missing(BorrowerIncome) & ///
                                     BorrowerIncome > `r(p99)'
replace BorrowerIncome = . if BorrowerIncome == 0

foreach fico of varlist RefreshedFicoScorePrimBorrower OriginalFicoScorePrimBorrower {
    replace `fico' = . if `fico' > 850
    replace `fico' = . if `fico' < 300 
}

replace CycleEndingRetailAPR = . if CycleEndingRetailAPR < 0
replace CycleEndingRetailAPR = . if abs(CycleEndingRetailAPR - 99.99) < .1
