
gen F0ActualPaymentAmount = ActualPaymentAmount
label var F0ActualPaymentAmount "Payment ($)"

xtset groupReferenceNumber numReportingPeriod
forvalues i = 1/4 {
    gen F`i'ActualPaymentAmount = F`i'.ActualPaymentAmount
    gen F`i'CycleEndingBalance  = F`i'.CycleEndingBalance
    gen F`i'PurchaseVolume      = F`i'.PurchaseVolume
    label var F`i'ActualPaymentAmount "Payment ($) at t + `i'"
    label var F`i'PurchaseVolume      "Purchase Volume ($) at t + `i'"
}

gen L1FinanceCharge  = L1.FinanceCharge
gen D1PurchaseVolume = D1.PurchaseVolume
gen lnPurchaseVolume = log(PurchaseVolume)

xtile inc_deciles = BorrowerIncome, nq(10)
tabulate inc_deciles, gen(inc_deciles_)

xtile ofico_deciles = OriginalFicoScorePrimBorrower, nq(10)
tabulate ofico_deciles, gen(ofico_deciles_)

xtile rfico_deciles = RefreshedFicoScorePrimBorrower, nq(10)
tabulate rfico_deciles, gen(rfico_deciles_)

xtile apr_deciles = CycleEndingRetailAPR, nq(10)
tabulate apr_deciles, gen(apr_deciles_)

gen     perc_paid   = ActualPaymentAmount / CycleEndingBalance
replace perc_paid   = .e if inrange(perc_paid, 0, 1) == 0
egen    perc_paid_c = cut(perc_paid), at(0(0.1)1) icodes
tabulate perc_paid_c, gen(perc_paid_c_)
rename perc_paid_c_* perc_paid_c_#, addnumber(0)

xtset groupReferenceNumber numReportingPeriod
foreach var of varlist FeeNetLateAmount FeeNetOverLimitAmount FeeNetNSFAmount FeeNetCashAdvanceAmount FeeNetAnnualAmount FeeNetDebtSuspensionAmount FeeNetBalanceTransferAmount FeeNetOtherAmount {
    by groupReferenceNumber: gen sum`var' = sum(`var')
    replace sum`var' = 1 if sum`var' > 0 & !missing(sum`var')
}

foreach var of varlist FeeNetLateAmount FeeNetOverLimitAmount FeeNetNSFAmount FeeNetCashAdvanceAmount FeeNetAnnualAmount FeeNetDebtSuspensionAmount FeeNetBalanceTransferAmount FeeNetOtherAmount {
    gegen tot`var' = total(`var')
    replace tot`var' = 1 if tot`var' > 0 & !missing(tot`var')
}

/* Compute age of account */
gen OriginationMonth = mofd(AccountOriginationDate) //changed to accountoriginationdate
gen AccountAge = numReportingPeriod - OriginationMonth
xtile acct_age_deciles = AccountAge, nq(10)
tabulate acct_age_deciles, gen(acct_age_deciles_)
