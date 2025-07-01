/*******************************************************************************

								            MASTER FILE

                  Replication files for QJE version

						        Andrés Barrios Fernández
								          January, 2021
*******************************************************************************/

clear all
set more off
set seed 1000
cap log close
set scheme s1mono

*** 1. Path definitions ********************************************************

global path_input 			     "/Users/andresbarriosfernandez/Dropbox/04. Paper Siblings/Replication files/01. Input"
global path_code  			     "/Users/andresbarriosfernandez/Documents/GitHub/siblings-effects-sweden/src/chile-croatia"
global path_outcomes_chile 	 "/Users/andresbarriosfernandez/Dropbox/04. Paper Siblings/Replication files/05. Outcomes - Chile VFF"
global path_outcomes_croatia "/Users/andresbarriosfernandez/Dropbox/04. Paper Siblings/Replication files/05. Outcomes - Croatia VFF"

*** 2. Estimate results for Chile **********************************************
cd $path_outcomes_chile
global bwc = 35
use "$path_input/sample_chile.dta", clear

egen mcfe    = group(year_old codigo_demre_old)  //Target college-major fe.
egen nmcfe   = group(year_old codigo_demre_next) //Next best college-major fe.

*** Table II: Summary statistics
do "$path_code/table2_cl.do"

*** Table III: Sibling Spillovers on Applications to and Enrollment in Older
*** Sibling’s Target Choice
do "$path_code/table3_cl.do"

*** Table V: Sibling Spillovers on Younger Siblings’ Applications by Differences
*** between Older Siblings’ Target and Next Best Options
do "$path_code/table5_cl.do

*** Table VI: Sibling Spillovers on Younger Siblings’ Application by Older Siblings’
*** Target Option Characteristics
do "$path_code/table6_cl.do

*** Table VII: Sibling Spillovers on Applications to College and College-Major by
*** Age Difference and Gender
do "$path_code/table7_cl.do

*** Table VIII: Sibling Spillovers on College and College-Major Choice by Older
*** Sibling’s Dropout
do "$path_code/table8_cl.do

*** Table IX: Sibling Spillovers on Academic Performance
do "$path_code/table9_cl.do

*** Figure I: Older Siblings’ Admission and Enrollment Probabilities in Target
*** Major-College at the Admission Cutoff (First Stage)
do "$path_code/figure1_cl.do

*** Figure III: Probabilities of Applying and Enrolling in Older Sibling’s Target College
*** Figure V: Probabilities of Applying and Enrolling in Older Sibling’s Target College-Major
*** Figure VI: Probabilities of Applying and Enrolling in Older Sibling’s Target Major
do "$path_code/figure3_cl.do

*** 3. Estimate results for Croatia ********************************************
cd $path_outcomes_croatia
global bwc = 120
use "$path_input/sample_cro.dta", clear

egen mcfe    = group(year_old codigo_demre_old)  //Target college-major fe.
egen nmcfe   = group(year_old codigo_demre_next) //Next best college-major fe.

*** Table II: Summary statistics
do "$path_code/table2_cro.do"

*** Table III: Sibling Spillovers on Applications to and Enrollment in Older
*** Sibling’s Target Choice
do "$path_code/table3_cro.do"

*** Table V: Sibling Spillovers on Younger Siblings’ Applications by Differences
*** between Older Siblings’ Target and Next Best Options
do "$path_code/table5_cro.do

*** Table VI: Sibling Spillovers on Younger Siblings’ Application by Older Siblings’
*** Target Option Characteristics
do "$path_code/table6_cro.do

*** Table VII: Sibling Spillovers on Applications to College and College-Major by
*** Age Difference and Gender
do "$path_code/table7_cro.do

*** Table IX: Sibling Spillovers on Academic Performance
do "$path_code/table9_cro.do

*** Figure I: Older Siblings’ Admission and Enrollment Probabilities in Target
*** Major-College at the Admission Cutoff (First Stage)
do "$path_code/figure1_cro.do

*** Figure III: Probabilities of Applying and Enrolling in Older Sibling’s Target College
*** Figure V: Probabilities of Applying and Enrolling in Older Sibling’s Target College-Major
*** Figure VI: Probabilities of Applying and Enrolling in Older Sibling’s Target Major
do "$path_code/figure3_cro.do
