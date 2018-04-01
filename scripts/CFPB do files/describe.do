clear all
set more off
capture log close _all
graph set eps fontface "Palatino"

/*------------------------------------------------*/
/* Some descriptive statististics                 */
/* Date created: Wed 07 Sep 2016 09:48:02 AM EDT  */
/* Data modified: Sun 28 Aug 2016 01:18:39 PM EDT */
/*------------------------------------------------*/
/* Output will be saved in project folder */
cd "/home/work/restricted/argus/Jambulapati/Bias"

/* Set locals to avoid using long path names */
local ccdb_path "/home/work/restricted/argus"
local ccdb_data "0030_Sample_Data_Sets/CFPB_OCC_1_percent.dta"
local jw_data   "JW/payments/data/temp_allissuers_point_1_percent.dta.gz"

/* Load the data */
gzuse DataSource ReferenceNumber ReportingPeriod                           ///
      MinimumPaymentDue ActualPaymentAmount CycleEndingBalance LoanChannel ///
      CurrentCreditLimit FinanceCharge                                     ///
        using "`ccdb_path'/`jw_data'", clear


/* End of script */
