*- Semaforo Escuela Remoto

	global ek_blue 	"21 53 162"
	global ek_green "19 151 65"
	global ek_red	"221 63 15"

*- Save data as DTA

*-----------
*- 2020
*-----------
import excel "$IN\Semaforo Escuela Remoto\bases\SER_base_familias_agosto.xlsx", sheet("SER_base_familias_agosto") firstrow allstring clear

gen id_ie = COD_MOD
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = id_ie + ANEXO
destring * , replace
compress

save "$TEMP\ser_2020_08", replace


import excel "$IN\Semaforo Escuela Remoto\bases\SER_base_familias_setiembre.xlsx", sheet("SER_base_familias_setiembre") firstrow allstring clear

gen id_ie = COD_MOD
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = id_ie + ANEXO
destring * , replace
compress

save "$TEMP\ser_2020_09", replace


import excel "$IN\Semaforo Escuela Remoto\bases\SER_base_familias_octubre.xlsx", sheet("SER_base_familias_octubre") firstrow allstring clear

gen id_ie = COD_MOD
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = id_ie + ANEXO
destring * , replace
compress

save "$TEMP\ser_2020_10", replace


import excel "$IN\Semaforo Escuela Remoto\bases\SER_base_familias_noviembre.xlsx", sheet("SER_base_familias_noviembre") firstrow allstring clear

gen id_ie = COD_MOD
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = id_ie + ANEXO
destring * , replace
compress

save "$TEMP\ser_2020_11", replace

*-----------
*- 2021
*-----------


import excel "$IN\Semaforo Escuela Remoto\bases\SER_2021_base_familias_abril.xlsx", sheet("SER_2021_base_familias_abril") firstrow allstring clear

gen id_ie = COD_MOD
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = id_ie + ANEXO
destring * , replace
compress

save "$TEMP\ser_2021_04", replace


import excel "$IN\Semaforo Escuela Remoto\bases\SER_2021_base_familias_mayo.xlsx", sheet("SER_2021_base_familias_mayo") firstrow allstring clear

gen id_ie = COD_MOD
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = id_ie + ANEXO
destring * , replace
compress

save "$TEMP\ser_2021_05", replace


import excel "$IN\Semaforo Escuela Remoto\bases\SER_2021_base_familias_junio.xlsx", sheet("SER_2021_base_familias_junio") firstrow allstring clear

gen id_ie = COD_MOD
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = id_ie + ANEXO
destring * , replace
compress

save "$TEMP\ser_2021_06", replace


import excel "$IN\Semaforo Escuela Remoto\bases\SER_2021_base_familias_julio.xlsx", sheet("SER_2021_base_familias_julio") firstrow allstring clear

gen id_ie = COD_MOD
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = id_ie + ANEXO
destring * , replace
compress

save "$TEMP\ser_2021_07", replace


import excel "$IN\Semaforo Escuela Remoto\bases\SER_2021_base_familias_agosto.xlsx", sheet("SER_2021_base_familias_agosto") firstrow allstring clear

gen id_ie = COD_MOD
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = id_ie + ANEXO
destring * , replace
compress

save "$TEMP\ser_2021_08", replace


import excel "$IN\Semaforo Escuela Remoto\bases\SER_2021_base_familias_setiembre.xlsx", sheet("SER_2021_base_familias_setiembr") firstrow allstring clear

gen id_ie = COD_MOD
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = id_ie + ANEXO
destring * , replace
compress

save "$TEMP\ser_2021_09", replace


import excel "$IN\Semaforo Escuela Remoto\bases\SER_2021_base_familias_octubre.xlsx", sheet("SER_2021_base_familias_octubre") firstrow allstring clear

gen id_ie = COD_MOD
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = id_ie + ANEXO
destring * , replace
compress

save "$TEMP\ser_2021_10", replace


import excel "$IN\Semaforo Escuela Remoto\bases\SER_2021_base_familias_noviembre.xlsx", sheet("SER_2021_base_familias_noviembr") firstrow allstring clear

gen id_ie = COD_MOD
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = "0" + COD_MOD if strlen(id_ie)<=6
replace id_ie = id_ie + ANEXO
destring * , replace
compress

save "$TEMP\ser_2021_11", replace



*- Verifying saved data
use  "$TEMP\ser_2020_08", clear
use  "$TEMP\ser_2020_09", clear
use  "$TEMP\ser_2020_10", clear
use  "$TEMP\ser_2020_11", clear
use  "$TEMP\ser_2021_04", clear
use  "$TEMP\ser_2021_05", clear
use  "$TEMP\ser_2021_06", clear
use  "$TEMP\ser_2021_07", clear
use  "$TEMP\ser_2021_08", clear
use  "$TEMP\ser_2021_09", clear
use  "$TEMP\ser_2021_10", clear
use  "$TEMP\ser_2021_11", clear


*- Cleaning data
foreach m in "08" "09" "10" "11" {
	use  "$TEMP\ser_2020_`m'", clear	
	
	*- Date
	gen year = 2020
	gen month = `m'

	*- Completed Survey
	keep if RES_FIN == 1
	
	*- Area
	label define area 1 "Urban" 2 "Rural"
	label values AREA_CENSO area
	
	*- Level
	label define level 1 "Inicial" 2 "Primary" 3 "Secondary" 4 "EBE"
	label values COD_NIVEL level

	*- Access
	gen tv = P1_2_A==1 if inlist(P1_2_A,0,1)==1
	replace tv = 0 if P1_1==2

	gen radio = P1_2_B==1  if inlist(P1_2_B,0,1)==1
	replace radio = 0 if P1_1==2

	gen online = P1_2_C==1  if inlist(P1_2_C,0,1)==1
	replace online = 0 if P1_1==2

	*- Communication with teacher
	gen teacher_communicated = P2_1==1 if inlist(P2_1,1,2,3)==1
	gen teacher_times_com	= P2_2 if inlist(P2_2,1,2,3,4,5,6,7)==1
	replace teacher_times_com = 0 if teacher_communicated==0

	*- Parent's help
	gen parent_accompanied 	= P4_3_A==1 if inlist(P4_3_A,1,2)==1
	gen parent_helped 		= P4_3_B==1 if inlist(P4_3_B,1,2)==1
	gen parent_reviewed 	= P4_3_C==1 if inlist(P4_3_C,1,2)==1
	
	rename *, lower
	
	isvar 	year month ///
			id_ie codgeo cod_nivel nivel_desc area_censo cod_nivel cod_hogar factor_expansion ///
			tv radio online ///
			teacher* ///
			parent*
	keep `r(varlist)'
	
	tempfile clean_ser_2020_`m'
	save `clean_ser_2020_`m'', replace	
}

foreach m in "04" "05" "06" "07" "08" {
	use  "$TEMP\ser_2021_`m'", clear	
	
	*- Date
	gen year = 2021
	gen month = `m'

	*- Completed Survey
	keep if RES_FIN == 1
	
	*- Area
	label define area 1 "Urban" 2 "Rural"
	label values AREA_CENSO area
	
	*- Level
	label define level 1 "Inicial" 2 "Primary" 3 "Secondary" 4 "EBE"
	label values COD_NIVEL level

	*- Access
	gen tv = P1_1A_A==1 if inlist(P1_1A_A,1,2)==1
	//replace tv = 0 if P1_1==2

	gen radio = P1_1A_B==1  if inlist(P1_1A_B,1,2)==1
	//replace radio = 0 if P1_1==2

	gen online = P1_1A_C==1  if inlist(P1_1A_C,1,2)==1
	//replace online = 0 if P1_1==2

	*- Communication with teacher
	gen teacher_communicated = P3_1A_B==1 if inlist(P3_1A_B,1,2,3,4)==1
	gen teacher_times_com = P3_1B_B if inlist(P3_1B_B,1,2,3,4,5,6,7)==1
	replace teacher_times_com = 0 if teacher_communicated==0
	
	*- Parent's help
	gen parent_accompanied 	= P5_3_A==1 if inlist(P5_3_A,0,1)==1 & `m'!=4 //April seems to have reporting issues.
	gen parent_doubts 		= P5_3_B==1 if inlist(P5_3_B,0,1)==1
	gen parent_resources 	= P5_3_C==1 if inlist(P5_3_C,0,1)==1
	gen parent_reviewed 	= P5_3_D==1 if inlist(P5_3_D,0,1)==1
	gen parent_verified 	= P5_3_E==1 if inlist(P5_3_E,0,1)==1
	
	rename *, lower
	
	isvar 	year month ///
			id_ie codgeo cod_nivel nivel_desc area_censo cod_nivel cod_hogar factor_expansion ///
			tv radio online ///
			teacher* ///
			parent*
	keep `r(varlist)'
	
	tempfile clean_ser_2021_`m'
	save `clean_ser_2021_`m'', replace	
}

foreach m in "09" "10" "11"  {
	use  "$TEMP\ser_2021_`m'", clear	
	
	*- Date
	gen year = 2021
	gen month = `m'

	*- Completed Survey
	keep if RES_FIN == 1
	
	*- Area
	label define area 1 "Urban" 2 "Rural"
	label values AREA_CENSO area
	
	*- Level
	label define level 1 "Inicial" 2 "Primary" 3 "Secondary" 4 "EBE"
	label values COD_NIVEL level

	*- Access
	gen tv = P1_1A_A==1 if inlist(P1_1A_A,1,2,3)==1
	//replace tv = 0 if P1_1==2

	gen radio = P1_1A_B==1  if inlist(P1_1A_B,1,2,3)==1
	//replace radio = 0 if P1_1==2

	gen online = P1_1A_C==1  if inlist(P1_1A_C,1,2,3)==1
	//replace online = 0 if P1_1==2

	*- Communication with teacher
	gen teacher_communicated = P2_1A_B==1 if inlist(P2_1A_B,1,2,3,4)==1
	gen teacher_times_com = P2_1B_B if inlist(P2_1B_B,1,2,3,4,5,6,7)==1
	replace teacher_times_com = 0 if teacher_communicated==0
	
	*- Parent's help
	gen parent_accompanied 	= P4_3_A==1 if inlist(P4_3_A,0,1)==1
	gen parent_doubts 		= P4_3_B==1 if inlist(P4_3_B,0,1)==1
	gen parent_resources 	= P4_3_C==1 if inlist(P4_3_C,0,1)==1
	gen parent_reviewed 	= P4_3_D==1 if inlist(P4_3_D,0,1)==1
	gen parent_verified 	= P4_3_E==1 if inlist(P4_3_E,0,1)==1
	
	rename *, lower
	
	isvar 	year month ///
			id_ie codgeo cod_nivel nivel_desc area_censo cod_nivel cod_hogar factor_expansion ///
			tv radio online ///
			teacher* ///
			parent*
	keep `r(varlist)'
	
	
	tempfile clean_ser_2021_`m'
	save `clean_ser_2021_`m'', replace	
}



clear
append using `clean_ser_2020_08'
append using `clean_ser_2020_09'
append using `clean_ser_2020_10'
append using `clean_ser_2020_11'
append using `clean_ser_2021_04'
append using `clean_ser_2021_05'
append using `clean_ser_2021_06'
append using `clean_ser_2021_07'
append using `clean_ser_2021_08'
append using `clean_ser_2021_09'
append using `clean_ser_2021_10'
append using `clean_ser_2021_11'

compress

save "$TEMP\ser_families", replace




foreach level in "prek" "elm" "sec" {

	use "$TEMP\ser_families", clear
	
	if "`level'" == "prek" 	keep if cod_nivel==1
	if "`level'" == "elm" 	keep if cod_nivel==2
	if "`level'" == "sec" 	keep if cod_nivel==3

	collapse tv radio online teacher_communicated teacher_times_com parent* [aw=factor_expansion], by(year month)

	gen year_month = ym(year, month)
	format year_month %tm

	twoway 	(line radio year_month 	if year==2020, lcolor("${ek_blue}")) ///
			(line tv year_month		if year==2020, lcolor("${ek_red}")) ///
			(line online year_month	if year==2020, lcolor("${ek_green}")) ///
			(line radio year_month 	if year==2021, lcolor("${ek_blue}")) ///
			(line tv year_month		if year==2021, lcolor("${ek_red}")) ///
			(line online year_month	if year==2021, lcolor("${ek_green}")) ///
			, ///
		xlabel(, format(%tmMon-CCYY) angle(45)) ///
		xtitle("Year - month") ///
		ytitle("Access to education resources (%)") ///
		ylabel(.1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%" .6 "60%" .7 "70%") ///
		legend(order (1 "Radio" 2 "TV" 3 "Online") col(3) pos(6))

	capture qui graph export "$FIGURES\Descriptive\SER_access_`level'.png", replace			
	capture qui graph export "$FIGURES\Descriptive\SER_access_`level'.pdf", replace		

	twoway 	(line teacher_communicated year_month 	if year==2020, lcolor("${ek_blue}")) ///
			(line teacher_communicated year_month	if year==2021, lcolor("${ek_blue}")) ///
			, ///
		xlabel(, format(%tmMon-CCYY) angle(45)) ///
		xtitle("Year - month") ///
		ytitle("Did the teacher communicated with parent" "last week? (%)" ) ///
		ylabel(.1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1 "100%") ///
		///legend(order (1 "Radio" 2 "TV") col(3) pos(6))
		legend(off)

	capture qui graph export "$FIGURES\Descriptive\SER_teacher_com_`level'.png", replace			
	capture qui graph export "$FIGURES\Descriptive\SER_teacher_com_`level'.pdf", replace	
	
	twoway 	(line teacher_times_com year_month 	if year==2020, lcolor("${ek_blue}")) ///
			(line teacher_times_com year_month	if year==2021, lcolor("${ek_blue}")) ///
			, ///
		xlabel(, format(%tmMon-CCYY) angle(45)) ///
		xtitle("Year - month") ///
		ytitle("Number of times the teacher communicated" "during last week" ) ///
		///legend(order (1 "Radio" 2 "TV") col(3) pos(6))	
		legend(off)

	capture qui graph export "$FIGURES\Descriptive\SER_teacher_times_`level'.png", replace			
	capture qui graph export "$FIGURES\Descriptive\SER_teacher_times_`level'.pdf", replace			

	twoway 	(line parent_accompanied year_month 	if year==2020, lcolor("${ek_blue}")) ///
			(line parent_reviewed year_month		if year==2020, lcolor("${ek_red}")) ///
			(line parent_accompanied year_month 	if year==2021, lcolor("${ek_blue}")) ///
			(line parent_reviewed year_month		if year==2021, lcolor("${ek_red}")) ///
			, ///
		xlabel(, format(%tmMon-CCYY) angle(45)) ///
		xtitle("Year - month") ///
		ytitle("Parental support (%)") ///
		ylabel(.1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1 "100%") ///
		legend(order (1 "Parent accompanied" 2 "Parent reviewed") col(3) pos(6))

	capture qui graph export "$FIGURES\Descriptive\SER_parent_`level'.png", replace			
	capture qui graph export "$FIGURES\Descriptive\SER_parent_`level'.pdf", replace				
}	
//year_month > ym(2020, 8)