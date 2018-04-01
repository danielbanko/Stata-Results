clear all
set more off

/*------------------------------------------------*/
/* Examine left-hand bias in the CCDB             */
/* Data modified: Fri 16 Sep 2016 04:17:19 PM EDT */
/*------------------------------------------------*/

/* Output will be saved in project folder */

include "scripts/bias.ado"

/* Set locals to avoid using long path names */
local ccdb_path "/home/work/projects/CCDB/Shared"
local ccdb_data "0030_Sample_Data_Sets/CFPB_OCC_1_percent.dta"
local jw_data   "JW/payments/data/temp_allissuers_10_percent.dta.gz"

/* Load the data */
gzuse DataSource ReferenceNumber ReportingPeriod                           ///
      MinimumPaymentDue ActualPaymentAmount CycleEndingBalance LoanChannel ///
      CurrentCreditLimit RefreshedFicoScorePrimBorrower FinanceCharge      ///
      OriginalFicoScorePrimBorrower BorrowerIncome CycleEndingRetailAPR    ///
      PurchaseVolume FeeNetLateAmount FeeNetOverLimitAmount                ///
      FeeNetNSFAmount FeeNetCashAdvanceAmount FeeNetAnnualAmount           ///
      FeeNetDebtSuspensionAmount FeeNetBalanceTransferAmount               ///
      FeeNetOtherAmount                                                    ///
        using "`ccdb_path'/`jw_data'", clear

include "scripts/data/clean.do"
include "scripts/data/create_vars.do"

/* Restrict the data to relevant observations */
gen selector = (1000 * floor((CycleEndingBalance + 500) / 1000) + ///
                2000 <= CurrentCreditLimit                      & ///
                mod(CurrentCreditLimit, 1000) != 500            & ///
                CycleEndingBalance > 500                        & ///
                L1FinanceCharge > 0 & !missing(L1FinanceCharge))

keep if selector == 1

/* Plot the stacked versions */
gen BalanceRound = round(CycleEndingBalance, 1000)

keep if inrange(BalanceRound, 1000, 11000) == 1
tab BalanceRound, gen(br_)
rename br_1 brx_1

tab DataSource,      gen(ds_)
tab ReportingPeriod, gen(rp_)

foreach var of varlist FeeNetLateAmount FeeNetOverLimitAmount FeeNetNSFAmount FeeNetCashAdvanceAmount FeeNetAnnualAmount FeeNetDebtSuspensionAmount FeeNetBalanceTransferAmount FeeNetOtherAmount {
  plot_aggregate `var' CycleEndingBalance,                                     ///
    c(br_* ds_* rp_* CurrentCreditLimit RefreshedFicoScorePrimBorrower BorrowerIncome CycleEndingRetailAPR) ///
    nb(-500(25)500)                                                                          ///
    nc(0)                                                                                    ///
    center(BalanceRound)                                                                     ///
    xtitle("Balance Relative to Threshold in $25 buckets")
  graph export "figures/agg_`var'_bal_nb25_thres2k_bw500_rev_bt0_all_ctrl.eps", replace
  graph save   "figures/agg_`var'_bal_nb25_thres2k_bw500_rev_bt0_all_ctrl.gph", replace
}

plot_aggregate ActualPaymentAmount CycleEndingBalance,                                     ///
  c(br_* ds_* rp_* CurrentCreditLimit RefreshedFicoScorePrimBorrower BorrowerIncome CycleEndingRetailAPR) ///
  nb(-500(25)500)                                                                          ///
  nc(0)                                                                                    ///
  center(BalanceRound)                                                                     ///
  xtitle("Balance Relative to Threshold in $25 buckets")
graph export "figures/agg_pay_bal_nb25_thres2k_bw500_rev_bt0_all_ctrl.eps", replace
graph save   "figures/agg_pay_bal_nb25_thres2k_bw500_rev_bt0_all_ctrl.gph", replace

plot_aggregate ActualPaymentAmount CycleEndingBalance,                                     ///
  c(br_* ds_* rp_* CurrentCreditLimit RefreshedFicoScorePrimBorrower BorrowerIncome CycleEndingRetailAPR) ///
  nb(-500(25)500)                                                                          ///
  nc(0)                                                                                    ///
  center(BalanceRound)                                                                     ///
  xtitle("Balance Relative to Threshold in $25 buckets")
graph export "figures/agg_pay_bal_nb25_thres2k_bw500_rev_bt0_all_ctrl.eps", replace
graph save   "figures/agg_pay_bal_nb25_thres2k_bw500_rev_bt0_all_ctrl.gph", replace

plot_aggregate CurrentCreditLimit CycleEndingBalance,                                     ///
  c(br_* ds_* rp_* RefreshedFicoScorePrimBorrower BorrowerIncome CycleEndingRetailAPR) ///
  nb(-500(25)500)                                                                          ///
  nc(0)                                                                                    ///
  center(BalanceRound)                                                                     ///
  xtitle("Balance Relative to Threshold in $25 buckets")
graph export "figures/agg_cl_bal_nb25_thres2k_bw500_rev_bt0_all_ctrl.eps", replace
graph save   "figures/agg_cl_bal_nb25_thres2k_bw500_rev_bt0_all_ctrl.gph", replace

plot_aggregate OriginalFicoScorePrimBorrower CycleEndingBalance,                                     ///
  c(br_* ds_* rp_* CurrentCreditLimit BorrowerIncome CycleEndingRetailAPR) ///
  nb(-500(25)500)                                                                          ///
  nc(0)                                                                                    ///
  center(BalanceRound)                                                                     ///
  xtitle("Balance Relative to Threshold in $25 buckets")
graph export "figures/agg_of_bal_nb25_thres2k_bw500_rev_bt0_all_ctrl.eps", replace
graph save   "figures/agg_of_bal_nb25_thres2k_bw500_rev_bt0_all_ctrl.gph", replace

plot_aggregate MinimumPaymentDue CycleEndingBalance,                                     ///
  c(br_* ds_* rp_* CurrentCreditLimit BorrowerIncome CycleEndingRetailAPR) ///
  nb(-500(25)500)                                                                          ///
  nc(0)                                                                                    ///
  center(BalanceRound)                                                                     ///
  xtitle("Balance Relative to Threshold in $25 buckets")
graph export "figures/agg_min_bal_nb25_thres2k_bw500_rev_bt0_all_ctrl.eps", replace
graph save   "figures/agg_min_bal_nb25_thres2k_bw500_rev_bt0_all_ctrl.gph", replace

foreach closest_bal of numlist 1(1)11 {
  plot_aggregate ActualPaymentAmount CycleEndingBalance                                ///
    if BalanceRound == `closest_bal' * 1000,                                 ///
    c(ds_* rp_* CurrentCreditLimit RefreshedFicoScorePrimBorrower BorrowerIncome CycleEndingRetailAPR) ///
    nb(-500(25)500)                                                          ///
    nc(0)                                                                    ///
    center(BalanceRound)                                                     ///
    xtitle("Balance Relative to Threshold in $25 buckets")
  graph export "figures/agg_pay_bal_nb25_thres2k_bw500_rev_bt0_br`closest_bal'k_ctrl.eps", replace
  graph save   "figures/agg_pay_bal_nb25_thres2k_bw500_rev_bt0_br`closest_bal'k_ctrl.gph", replace

}

