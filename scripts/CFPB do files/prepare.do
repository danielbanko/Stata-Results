clear all
set more off
/*------------------------------------------------*/
/* Prepare data for analysis                      */
/* Data modified: Thu 15 Sep 2016 03:08:29 PM EDT */
/*------------------------------------------------*/

/* Output will be saved in project folder */
cd "~/Documents/Bias/"

/* Set locals to avoid using long path names */
local ccdb_path   "/home/work/projects/CCDB/Shared"
local sample_size "1_percent"
local ccdb_data   "0030_Sample_Data_Sets/CFPB_OCC_`sample_size'.dta"
local jw_data     "JW/payments/data/temp_allissuers_`sample_size'.dta.gz"
local bias_data   "`ccdb_path'/jw_`sample'.dta"

save "`bias_data'", replace

/* End of script */
