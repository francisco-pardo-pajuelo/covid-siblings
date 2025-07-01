* v2

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

*- Color Schemes
(old) s2color
stcolor, stcolor_alt, stgcolor, and stgcolor_alt.


set scheme vertical n(10): HCL blues
*/

*- Mother file
//ssc install distinct
//ssc install isvar
//net install binsreg, from(https://raw.githubusercontent.com/nppackages/binsreg/master/stata) replace
//ssc install lpdensity
//ssc install estout
//ssc install outreg2 //needed?
//ssc install coefplot
//ssc install rddensity
//ssc install rdrobust
//findit estread //needed?
/*
*-  Install reghdfe - Development version (6.x): https://scorreia.com/software/reghdfe/install.html

* Install ftools (remove program if it existed previously)
cap ado uninstall ftools
net install ftools, from("https://raw.githubusercontent.com/sergiocorreia/ftools/master/src/")

* Install reghdfe 6.x
cap ado uninstall reghdfe
net install reghdfe, from("https://raw.githubusercontent.com/sergiocorreia/reghdfe/master/src/")

* Install parallel, if using the parallel() option; don't install from SSC
cap ado uninstall parallel
net install parallel, from(https://raw.github.com/gvegayon/parallel/stable/) replace
mata mata mlib index

* For ivreghdfe
cap ado uninstall ivreghdfe
cap ssc install ivreg2 // Install ivreg2, the core package
net install ivreghdfe, from(https://raw.githubusercontent.com/sergiocorreia/ivreghdfe/master/src/)

*/

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




