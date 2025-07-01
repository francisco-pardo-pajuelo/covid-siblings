// STARTUP
version 15
set more off, permanently
clear all
capture log close
eststo clear
estimates clear
set emptycells drop
set matsize 10000
set maxvar 10000
set linesize 200
set graphics off
set scheme s1mono, permanently

global country "swe"

// PATHS
global main_path 	    "/scratch/adam/siblings-effects-chi-cro-swe/replication_test/swe" // set to correct absolute path
global path_input 	    "${main_path}/data"
global path_code	    "${main_path}"
global path_out  	    "${main_path}/out"

cd $path_out

// STARTUP
do "$path_code/01_programs_swe.do"
do "$path_code/02_settings_swe.do"

// DATA PREPARATION
use "$path_input/main_data_raw_swe.dta", clear
do "$path_code/03_variables_swe.do"

*** Table II: Summary statistics
use "$path_input/main_data_raw_swe.dta", clear
do "$path_code/table2_swe.do"

// Load main data
use "$path_input/main_data_swe.dta", clear

*** Table III: Sibling Spillovers on Applications to and Enrollment in Older
*** Sibling’s Target Choice
do "$path_code/table3_swe.do"

*** Table V: Sibling Spillovers on Younger Siblings’ Applications by Differences
*** between Older Siblings’ Target and Next Best Options
do "$path_code/table5_swe.do

*** Table VI: Sibling Spillovers on Younger Siblings’ Application by Older Siblings’
*** Target Option Characteristics
do "$path_code/table6_swe.do

*** Table VII: Sibling Spillovers on Applications to College and College-Major by
*** Age Difference and Gender
do "$path_code/table7_swe.do

*** Table VIII: Sibling Spillovers on College and College-Major Choice by Older
*** Sibling’s Dropout
do "$path_code/table8_swe.do

*** Table IX: Sibling Spillovers on Academic Performance
do "$path_code/table9_swe.do

*** Figure I: Older Siblings’ Admission and Enrollment Probabilities in Target
*** Major-College at the Admission Cutoff (First Stage)
do "$path_code/figure1_swe.do

*** Figure III: Probabilities of Applying and Enrolling in Older Sibling’s Target College
*** Figure V: Probabilities of Applying and Enrolling in Older Sibling’s Target College-Major
*** Figure VI: Probabilities of Applying and Enrolling in Older Sibling’s Target Major
do "$path_code/figure3_swe.do
