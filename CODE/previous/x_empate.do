if c(username)=="franc" 	global DB = "C:\Users\franc\Dropbox\"
if c(username)=="Francisco" global DB = "C:\Users\Francisco\Dropbox\"

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

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE07_13.xlsx", sheet("Sheet1") firstrow clear

tempfile siagie_ece_2007_2013
save `siagie_ece_2007_2013', replace

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE14_23.xlsx", sheet("Sheet1") firstrow clear

append using `siagie_ece_2007_2013'

save "$TEMP\empate_siagie_ece", replace



//Comparing new data with old SIAGIE data


use "C:\Users\Francisco\Dropbox\Alfonso_Minedu\SIAGIE\siagie_12_22_ece_12_19_postulantes(27.07.2022).dta", clear
keep if cod_mod_17 == "1530377"


use "$TEMP\siagie_2017", clear
keep if cod_mod_siagie == 1530377
keep if grade==7
//tab ece