clear all
set more off

/*------------------------------------------------*/
/* Examine left-hand bias in the CCDB             */
/* Data modified: Fri 16 Sep 2016 04:17:19 PM EDT */
/*------------------------------------------------*/

/* Output will be saved in project folder */
cd "/home/work/projects/CCDB/Shared/Jambulapati/Bias"

include "/home/work/projects/CCDB/Shared/Jambulapati/Bias/gitlab/scripts/analysis/bias.ado"

/* Set locals to avoid using long path names */
local ccdb_path "/home/work/projects/CCDB/Shared"
local ccdb_data "0030_Sample_Data_Sets/CFPB_OCC_1_percent.dta"
local jw_data   "JW/payments/data/temp_allissuers_10_percent.dta.gz"

/*Correct path names-DB*/
local oneper_data "/home/work/ipa/wangj/CCDB/payments/data/temp_allissuers_1_percent.dta.gz"
local tenper_data "/home/work/ipa/wangj/CCDB/payments/data/temp_allissuers_10_percent.dta.gz"

/* Load the data */
gzuse DataSource ReferenceNumber ReportingPeriod                           ///
      MinimumPaymentDue ActualPaymentAmount CycleEndingBalance LoanChannel ///
      CurrentCreditLimit RefreshedFicoScorePrimBorrower FinanceCharge      ///
      OriginalFicoScorePrimBorrower BorrowerIncome CycleEndingRetailAPR    ///
      PurchaseVolume FeeNetLateAmount FeeNetOverLimitAmount                ///
      FeeNetNSFAmount FeeNetCashAdvanceAmount FeeNetAnnualAmount           ///
      FeeNetDebtSuspensionAmount FeeNetBalanceTransferAmount               ///
      FeeNetOtherAmount AccountOriginationDate                                               /// added accountoriginationdate
        using "`tenper_data'", clear

include "/home/work/projects/CCDB/Shared/Jambulapati/Bias/gitlab/scripts/data/clean.do"
include "/home/work/projects/CCDB/Shared/Jambulapati/Bias/gitlab/scripts/data/create_vars.do"

/* Restrict the data to relevant observations */
gen selector = (1000 * floor((CycleEndingBalance + 500) / 1000) + ///
                2000 <= CurrentCreditLimit                      & ///
                mod(CurrentCreditLimit, 1000) != 500            & ///
                CycleEndingBalance > 500                        & ///
                FinanceCharge > 0)

keep if selector == 1

gen  center   = round(CycleEndingBalance, 1000)
gen  xcenter  = CycleEndingBalance - center
egen bin      = cut(xcenter)   if selector == 1, at(-500(10)500)
gegen tag_bin  = tag(bin)       if selector == 1
gen  d        = (xcenter >= 0) if selector == 1
gen  dxcenter = d * xcenter

label var d "\$\mathds{1} \left\{ {\text{Distance from Closest Threshold} \geq 0} \right\}\$"

forvalues threshold = 1/11 {
  gen thresh_`threshold'    = (center == `threshold' * 1000)
  gen xcenter_`threshold'k  = xcenter  * (center == `threshold' * 1000)
  gen d_`threshold'k        = d        * (center == `threshold' * 1000)
  gen dxcenter_`threshold'k = dxcenter * (center == `threshold' * 1000)

  label var d_`threshold'k "\$\mathds{1} \left\{ {\text{Distance from Closest \\$`threshold'K} \geq 0} \right\}\$"
}


* Define controls and cluster
local controls "CurrentCreditLimit RefreshedFicoScorePrimBorrower CycleEndingRetailAPR"
local fix_fx   "ds_* rp_*"

tab DataSource,      gen(ds_)
tab ReportingPeriod, gen(rp_)

* local yvars "F*ActualPaymentAmount F*PurchaseVolume D1PurchaseVolume lnPurchaseVolume"
* local svars "selector inc_deciles_* ofico_deciles_* rfico_deciles_* apr_deciles_*"

/*banko's work*/
gen percentBalancePaid = (F0ActualPaymentAmount / CycleEndingBalance)*100
gen ninetyPerPaid = .
replace ninetyPerPaid = (percentBalancePaid >= 90) if percentBalancePaid != .
// local yvars "percentBalancePaid"
// local yvars "F0ActualPaymentAmount"
//local svars "inc_deciles_*"
local yvars "ninetyPerPaid"
local svars "selector"
foreach yvar of varlist `yvars' {
    foreach svar of varlist `svars' {
        * Run the regressions
        eststo: regress `yvar' xcenter d dxcenter                     if `svar' == 1 & inrange(center, 1000, 11000) == 1, cluster(groupReferenceNumber)
          estadd local controls "\multicolumn{1}{c}{No}"
          estadd local bank_fx  "\multicolumn{1}{c}{No}"
          estadd local month_fx "\multicolumn{1}{c}{No}"
        eststo: regress `yvar' xcenter d dxcenter `fix_fx'            if `svar' == 1 & inrange(center, 1000, 11000) == 1, cluster(groupReferenceNumber)
          estadd local controls "\multicolumn{1}{c}{No}"
          estadd local bank_fx  "\multicolumn{1}{c}{Yes}"
          estadd local month_fx "\multicolumn{1}{c}{Yes}"
        eststo: regress `yvar' xcenter d dxcenter `fix_fx' `controls' if `svar' == 1 & inrange(center, 1000, 11000) == 1, cluster(groupReferenceNumber)
          estadd local controls "\multicolumn{1}{c}{Yes}"
          estadd local bank_fx  "\multicolumn{1}{c}{Yes}"
          estadd local month_fx "\multicolumn{1}{c}{Yes}"
        esttab using "gitlab/Banko/Tables/ols_`yvar'_rd_lin_`svar'.tex",           ///
            se r2 nocons                                              ///
            label nomtitle                                            ///
            keep(d)                                                   ///
            scalars("controls Controls"                               ///
                    "bank_fx  Bank Fixed Effects"                     ///
                    "month_fx Month Fixed Effects")                   ///
            booktabs frag replace
        eststo clear

        * Run the regressions (interacted)
        eststo: regress `yvar' thresh_* xcenter_*k d_*k dxcenter_*k                     if `svar' == 1 & inrange(center, 1000, 11000) == 1, cluster(groupReferenceNumber)
          estadd local controls "\multicolumn{1}{c}{No}"
          estadd local bank_fx  "\multicolumn{1}{c}{No}"
          estadd local month_fx "\multicolumn{1}{c}{No}"
        eststo: regress `yvar' thresh_* xcenter_*k d_*k dxcenter_*k `fix_fx'            if `svar' == 1 & inrange(center, 1000, 11000) == 1, cluster(groupReferenceNumber)
          estadd local controls "\multicolumn{1}{c}{No}"
          estadd local bank_fx  "\multicolumn{1}{c}{Yes}"
          estadd local month_fx "\multicolumn{1}{c}{Yes}"
        eststo: regress `yvar' thresh_* xcenter_*k d_*k dxcenter_*k `fix_fx' `controls' if `svar' == 1 & inrange(center, 1000, 11000) == 1, cluster(groupReferenceNumber)
          estadd local controls "\multicolumn{1}{c}{Yes}"
          estadd local bank_fx  "\multicolumn{1}{c}{Yes}"
          estadd local month_fx "\multicolumn{1}{c}{Yes}"

        esttab using "gitlab/Banko/Tables/ols_`yvar'_rd_inter_`svar'.tex", ///
            se r2 nocons                                      ///
            label nomtitle                                    ///
            keep(d_*k)                                        ///
            scalars("controls Controls"                       ///
                    "bank_fx  Bank Fixed Effects"             ///
                    "month_fx Month Fixed Effects")           ///
            booktabs frag replace
        eststo clear
    }
}

/*BEGIN COPY PASTE 12/07/2017 */
local yvars "F0ActualPaymentAmount"
local svars "acct_age_deciles_*"

foreach yvar of varlist `yvars' {
    foreach svar of varlist `svars' {
        * Run the regressions
        eststo: regress `yvar' xcenter d dxcenter                     if `svar' == 1 & inrange(center, 1000, 11000) == 1, cluster(groupReferenceNumber)
          estadd local controls "\multicolumn{1}{c}{No}"
          estadd local bank_fx  "\multicolumn{1}{c}{No}"
          estadd local month_fx "\multicolumn{1}{c}{No}"
        eststo: regress `yvar' xcenter d dxcenter `fix_fx'            if `svar' == 1 & inrange(center, 1000, 11000) == 1, cluster(groupReferenceNumber)
          estadd local controls "\multicolumn{1}{c}{No}"
          estadd local bank_fx  "\multicolumn{1}{c}{Yes}"
          estadd local month_fx "\multicolumn{1}{c}{Yes}"
        eststo: regress `yvar' xcenter d dxcenter `fix_fx' `controls' if `svar' == 1 & inrange(center, 1000, 11000) == 1, cluster(groupReferenceNumber)
          estadd local controls "\multicolumn{1}{c}{Yes}"
          estadd local bank_fx  "\multicolumn{1}{c}{Yes}"
          estadd local month_fx "\multicolumn{1}{c}{Yes}"

        esttab using "gitlab/Banko/Tables/ols_`yvar'_rd_lin_`svar'.tex",           ///
            se r2 nocons                                              ///
            label nomtitle                                            ///
            keep(d)                                                   ///
            scalars("controls Controls"                               ///
                    "bank_fx  Bank Fixed Effects"                     ///
                    "month_fx Month Fixed Effects")                   ///
            booktabs frag replace
        eststo clear

        * Run the regressions (interacted)
        eststo: regress `yvar' thresh_* xcenter_*k d_*k dxcenter_*k                     if `svar' == 1 & inrange(center, 1000, 11000) == 1, cluster(groupReferenceNumber)
          estadd local controls "\multicolumn{1}{c}{No}"
          estadd local bank_fx  "\multicolumn{1}{c}{No}"
          estadd local month_fx "\multicolumn{1}{c}{No}"
        eststo: regress `yvar' thresh_* xcenter_*k d_*k dxcenter_*k `fix_fx'            if `svar' == 1 & inrange(center, 1000, 11000) == 1, cluster(groupReferenceNumber)
          estadd local controls "\multicolumn{1}{c}{No}"
          estadd local bank_fx  "\multicolumn{1}{c}{Yes}"
          estadd local month_fx "\multicolumn{1}{c}{Yes}"
        eststo: regress `yvar' thresh_* xcenter_*k d_*k dxcenter_*k `fix_fx' `controls' if `svar' == 1 & inrange(center, 1000, 11000) == 1, cluster(groupReferenceNumber)
          estadd local controls "\multicolumn{1}{c}{Yes}"
          estadd local bank_fx  "\multicolumn{1}{c}{Yes}"
          estadd local month_fx "\multicolumn{1}{c}{Yes}"

        esttab using "gitlab/Banko/Tables/ols_`yvar'_rd_inter_`svar'.tex", ///
            se r2 nocons                                      ///
            label nomtitle                                    ///
            keep(d_*k)                                        ///
            scalars("controls Controls"                       ///
                    "bank_fx  Bank Fixed Effects"             ///
                    "month_fx Month Fixed Effects")           ///
            booktabs frag replace
        eststo clear
    }
}

/*END COPY PASTE*/
shell echo -e "It's Done" | mail -s "STATA finished" "daniel.banko-ferran@cfpb.gov"
/* End of script */

