

*- Current editing
/*
doedit "$CODE\V01_histograms_per_school.do"
doedit "$CODE\C01_tables_figures.do"
doedit "$CODE\C00_descriptive.do" //Working here, line 160
doedit "$CODE\A00_clean_final"
doedit "$CODE\A00_clean_raw"
*/


/*
*- Main colors
lcolor("26 133 255")
lcolor("212 17 89")

*/

*- Mother file
//ssc install binsreg
//ssc install lpdensity
//findit estread

if c(username)=="franc" 	global 	DB = "C:\Users\franc\Dropbox\"
if c(username)=="Francisco" global 	DB = "C:\Users\Francisco\Dropbox\"
if c(username)=="fp4897" 	global 	DB = "C:\Users\fp4897\Dropbox\"

global IN_PREV "$DB\Alfonso_Minedu"



global DB_PROJECT "$DB\research\projectsX\18_aspirations_siblings_rank"
global DATA "$DB_PROJECT\DATA"
	global IN "$DATA\IN"
	global TEMP "$DATA\TEMP"
	global OUT "$DATA\OUT"
global CODE "$DB_PROJECT\CODE"	
global FIGURES "$DB_PROJECT\FIGURES"
global TABLES "$DB_PROJECT\TABLES"
global LOGS "$DB_PROJECT\LOGS"

*-- Shaping beliefs: 

// Aspirations from parents
// Aspirations from students
// Directors cuestionnaire

*- To standardize variables
cap prog drop VarStandardiz
prog define VarStandardiz
	syntax varname, newvar(name) [by(varlist)]
	tempvar mean sd
	
	if "`by'"!="" {
		bys `by': egen `mean' = mean(`varlist')
		bys `by': egen `sd'	  = sd(`varlist')
	}
	if "`by'"=="" {
		egen `mean' = mean(`varlist')
		egen `sd'	= sd(`varlist')
	}
	gen `newvar' = (`varlist' - `mean')/`sd'
end


cap prog drop VarStandardiz_control //Standardized doing control=0
prog define VarStandardiz_control
	syntax varlist(min=2 max=2), newvar(name) [by(varlist)]
	tokenize "`varlist'", parse(" ",",")
	tempvar mean sd temp_mean temp_sd

	if "`by'"!="" {
		bys `by': egen `temp_mean' = mean(`1') if `2'==0
		bys `by': egen `temp_sd'	  = sd(`1') if `2'==0
		bys `by': egen `mean' = max(`temp_mean') //attach it to treatment as well
		bys `by': egen `sd' = max(`temp_sd') //attach it to treatment as well
	}
	if "`by'"=="" { 
		egen `temp_mean' = mean(`1') if `2'==0
		egen `temp_sd'	= sd(`1') if `2'==0
		egen `mean' = max(`temp_mean') //attach it to treatment as well
		egen `sd' = max(`temp_sd') //attach it to treatment as well		
	}
	
	gen `newvar' = (`1' - `mean')/`sd'
end	

/*
Default Stata colors
("stc1" = "26 133 255"%100)
("stc2" = "212   17      89"%100)
("stc3" = "0     191    127"%100)
("stc4" = "255   212      0"%100)
*/



*- For dubugging (just type 'close', do other things, do edits, and type 'open' to return to previous database)
cap prog drop close
program close 
	save "$TEMP\temp_program", replace
end

cap prog drop open
program open
	use "$TEMP\temp_program", clear
end

cap prog drop erase_close
program erase_close
	erase "$TEMP\temp_program.dta"
end


*-----------------------
*-- Complete Run
*-----------------------


*- Clean databases
do "$CODE\A01_clean_raw"
do "$CODE\A02_cutoff_simulation"
do "$CODE\A03_mccrary_cutoffs"
do "$CODE\A04_clean_final"
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


