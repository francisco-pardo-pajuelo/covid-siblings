
*-----------------------
*-- Complete Run
*-----------------------

timer clear 1


*- Clean databases
timer clear 1
timer on 1
do "$CODE\A01_clean_raw" 
timer off 1
timer list 1

timer clear 2
timer on 2
do "$CODE\A02_cutoff_simulation"
timer off 2
timer list 2

timer clear 3
timer on 3
do "$CODE\A03_mccrary_cutoffs"
timer off 3
timer list 3

timer clear 4
timer on 4
do "$CODE\A04_clean_final"
timer off 4
timer list 4


timer list 2
timer list 3
timer list 4
clear
set obs 3
gen dofile = _n
gen t = .
replace t = r(t2)/3600 in 1 //9477.06  	(2.6h)
replace t = r(t3)/3600 in 2 //60612.20		(16h)
replace t = r(t4)/3600 in 3 // 1h)
save "$TEMP\DURATION_DOFILE", replace


//do "$CODE\A03_ranking_preferences"

*- Analysis 
do "$CODE\C01_descriptive"
do "$CODE\C02_tables_figures"

*- Validating
do "$CODE\V01_histograms_per_school"
do "$CODE\V02_explaining_spurious"


*- Preliminary
do "$CODE\P01_descriptive_survey_census_university"

*- Issues
do "$CODE\I00_review_balance"
do "$CODE\I01_exp_year_sib" //solved
do "$CODE\I02_dropout_2020" //solved, checking corrected measure for 2020
do "$CODE\I03_info_region_sib" //partially solved: We were keeping non matched individuals too.
do "$CODE\I04_match_with_survey"
do "$CODE\I05_number_of_siblings"
do "$CODE\I06_bandwidth_peers"
do "$CODE\I07_age_gap_8th_grade"

do "$CODE\I08_priv_uni_score_distribution"













****do "$CODE\A00_siblings"

/*
*- Append and clean database:
do "$CODE\A01_clean_data"
do "$CODE\A04_SIAGIE_ECE"
*- Analysis
//do "$CODE\B01_analysis"

do "$CODE\B03_final_data"
do "$CODE\B04_first_stage"
do "$CODE\B05_descriptive"
*/