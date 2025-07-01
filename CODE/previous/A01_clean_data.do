/********************************************************************************
- Author: Francisco Pardo
- Description: Opens raw (xls, txt), cleans it and appends to a DTA
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/

capture program drop main 
program define main 

setup


siagie 			//	school progression
sibling_id		// 	identify siblings


ece				// 	test scores
ece_survey		//	beliefs 


//siries			//	applications


crosswalk_ece		// 
merge_data_ece		//

end




********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup

	set seed 1234
	global excel = 1
	global test = 0

end


********************************************************************************
* siagie
********************************************************************************

capture program drop siagie
program define siagie


forvalues y = 2017(1)2019 {

	if $test == 0 & $excel ==1 {
		capture import delimited "$IN\MINEDU\ECE EM innominada\SIAGIE\Data_matriculados_siries_`y'_INNOM.txt", clear
		capture import delimited "$IN\MINEDU\ECE EM innominada\SIAGIE\Data_matriculados_siries_`y' INNOM.txt", clear
	}
		
	if $test == 0 & $excel ==0 {
		assert 1==0 //To save space we don't save the raw excel as dta
	}
			
	if $test == 1 & $excel ==1 {
		capture import delimited "$IN\MINEDU\ECE EM innominada\SIAGIE\Data_matriculados_siries_`y'_INNOM.txt", clear
		capture import delimited "$IN\MINEDU\ECE EM innominada\SIAGIE\Data_matriculados_siries_`y' INNOM.txt", clear
		gen u = runiform()
		keep if u<0.02
		drop u
		save "$TEMP\raw_siagie_`y'_TEST", replace
	}

	if $test == 1 & $excel ==0 {
		use "$TEMP\raw_siagie_`y'_TEST", clear
	}
		

	*- Format all strings in UPPER
	ds, has(type string)
	local string_vars = r(varlist)

	foreach v of local string_vars {
		ds `v'
		replace `v' = upper(`v')
		replace `v' = trim(itrim(`v'))
	}


	*- Year
	rename id_anio_siagie year

	*- Region
	rename departamento_siagie region_siagie

	*- Level 
	label define level 1 "Pre-school" 2 "Primary" 3 "Secondary" 
	gen level = .
	replace level = 1 if strmatch(nivel_educativo_siagie,"*INICIAL*")==1
	replace level = 2 if strmatch(nivel_educativo_siagie,"*PRIMARIA*")==1
	replace level = 3 if strmatch(nivel_educativo_siagie,"*SECUNDARIA*")==1

	*- Basic school
	gen ebr = (strmatch(nivel_educativo_siagie,"*ESPECIAL*")==0)

	*- Grade
	gen grade = 0 if level==1
	replace grade = 1 if level==2 & strmatch(grado_siagie,"*PRIMERO*")==1
	replace grade = 2 if level==2 & strmatch(grado_siagie,"*SEGUNDO*")==1
	replace grade = 3 if level==2 & strmatch(grado_siagie,"*TERCERO*")==1
	replace grade = 4 if level==2 & strmatch(grado_siagie,"*CUARTO*")==1
	replace grade = 5 if level==2 & strmatch(grado_siagie,"*QUINTO*")==1
	replace grade = 6 if level==2 & strmatch(grado_siagie,"*SEXTO*")==1
	replace grade = 7 if level==3 & strmatch(grado_siagie,"*PRIMERO*")==1
	replace grade = 8 if level==3 & strmatch(grado_siagie,"*SEGUNDO*")==1
	replace grade = 9 if level==3 & strmatch(grado_siagie,"*TERCERO*")==1
	replace grade = 10 if level==3 & strmatch(grado_siagie,"*CUARTO*")==1
	replace grade = 11 if level==3 & strmatch(grado_siagie,"*QUINTO*")==1

	*- Male
	gen male_siagie = sexo_siagie == "HOMBRE" if inlist(sexo_siagie,"HOMBRE","MUJER")==1

	*- Approved grade
	gen approved 		= sf_regular == "APROBADO" | sf_recuperacion=="APROBADO"
	gen approved_first 	= sf_regular == "APROBADO"
	tabstat approved* , by(grade)

	//Check ID 
	/*
	forvalues i = 1/8 {
		 gen d`i' = substr( id_persona_apoderado_rec,`i',1)
		 tab d`i'
	}	
	*/


	*- Course grades
	rename comunicación comm
	rename matemática math

	gen math_primary = math if level==2
	gen math_secondary = math if level==3

	gen comm_primary = comm if level==2
	gen comm_secondary = comm if level==3
	destring math_secondary comm_secondary, replace

	*- Adult variables
	foreach adult in "caretaker" "mother" "father" {
		if "`adult'" == "caretaker" local adult_sp = "apoderado"
		if "`adult'" == "mother" local adult_sp = "madre"
		if "`adult'" == "father" local adult_sp = "padre"
		
		*- ID
		rename id_persona_`adult_sp'_rec id_`adult'
		
		*- Sex
		rename sexo_`adult_sp' sex_`adult'
		gen male_`adult' = (sex_`adult' == "HOMBRE") if inlist(sex_`adult',"HOMBRE","MUJER")==1
		drop sex_`adult'
		
		*- Date of birth
		rename fecha_nacimiento_`adult_sp' dob_`adult'
		
		*- Lives with adult
		gen lives_with_`adult' = (vive_con_estudiante_`adult_sp'=="SI") if inlist(vive_con_estudiante_`adult_sp',"SI","NO")==1
		drop vive_con_estudiante_`adult_sp'
		
		*- Educ
		
		gen educ_`adult' = .
		replace educ_`adult' = 1 if nivel_instruccion_`adult_sp' == "NINGUNO"
		replace educ_`adult' = 2 if nivel_instruccion_`adult_sp' == "PRIMARIA INCOMPLETA"
		replace educ_`adult' = 3 if nivel_instruccion_`adult_sp' == "PRIMARIA COMPLETA"
		replace educ_`adult' = 4 if nivel_instruccion_`adult_sp' == "SECUNDARIA INCOMPLETA"
		replace educ_`adult' = 5 if nivel_instruccion_`adult_sp' == "SECUNDARIA COMPLETA"
		replace educ_`adult' = 6 if inlist(nivel_instruccion_`adult_sp',"SUPERIOR NO UNIVERSITARIA INCOMPLETA","SUPERIOR UNIVERSITARIA INCOMPLETA")==1
		replace educ_`adult' = 7 if inlist(nivel_instruccion_`adult_sp',"SUPERIOR NO UNIVERSITARIA COMPLETA","SUPERIOR UNIVERSITARIA COMPLETA")==1
		replace educ_`adult' = 8 if nivel_instruccion_`adult_sp' == "SUPERIOR POST GRADUADO"
		drop nivel_instruccion_`adult_sp'
		
		
		
		}
	label define educ 1 "None" 2 "Primary Incomplete" 3 "Primary Complete" 4 "Secondary Incomplete" 5 "Secondary Complete" 6 "Higher Incomplete" 7 "Higher Complete" 8 "Post-grad"
	label values educ_caretaker educ_mother educ_father educ

			isvar 	/*ID*/ 			id_per_umc correlativo year ///
					/*GEO*/			region_siagie ///
					/*School*/		cod_mod_siagie anexo_siagie ebr level grade seccion_siagie ///
					/*Student*/		male_siagie ///
					/*Grades*/		approved approved_first math_primary math_secondary comm_primary comm_secondary ///
					/*Adult*/ 		 *caretaker *mother *father 
					/*Family*/		// id_fam N_siblings
			local all_vars = r(varlist)
			ds `all_vars', not
			keep `all_vars'
			order `all_vars'
			compress	
		
		
	if ${test}==0 save "$TEMP\siagie_`y'", replace
	if ${test}==1 save "$TEMP\siagie_`y'_TEST", replace
}

end



********************************************************************************
* ECE
********************************************************************************

capture program drop ece
program define ece

*- Aspirations

**## IN 2S, 2018 CTA and 2019 CN MIGHT BE DIFFERENT. CURRENTLY BOTH LABELED AS 'S' FROM SCIENCE
**## How to recover SECCION in 2013 from id_2p_2013 based on the patter from other years.
*----------------
*-	1. APPEND DATA
*----------------
		
*- ECE: append 2P
	local grade = "2p"
	foreach year in "2007" "2008" "2009" "2010" "2011" "2012" "2013" "2014" "2015" "2016" /*"2019"*/ {
		local s1year = substr("`year'",4,1)
		local s2year = substr("`year'",3,2)
		if inlist(`year',2007,2008)==1 				use "$IN\ECE\in\umc_`s1year'", clear
		if inlist(`year',2009)==1 					use "$IN\UMC\umc_`s1year'", clear
		if inlist(`year',2010,2011,2012)==1 		use "$IN\UMC\umc_`s2year'", clear
		if inlist(`year',2013,2014,2015,2016)==1 	use "$IN\ECE\in\ece_`year'_`grade'", clear
		rename *, lower
		
		if inlist(`year',2011,2012)==1 {
			tostring cod_al, replace
			replace cod_al = "0" + cod_al if strlen(cod_al)==1
		}
		
		if inlist(`year',2007,2008,2009,2010,2011,2012)==1  {
			rename id id_ie
			tostring id_ie, replace
			replace id_ie = "0" + id_ie if strlen(id_ie) < 8
			gen id_`grade'_`year' = id_ie + seccion + cod_al		
		}
		
		rename id_`grade'_`year' id
		drop if id=="" | id=="0" | id=="#NULL!"
		
		*- Rename School ID
		if inlist(`year',2013)==1					replace id = substr(id,8,12)
		if inlist(`year',2013)==1 					gen id_ie = cod_mod7 + anexo
		if inlist(`year',2014,2015,2016)==1 		gen id_ie = cod_mod7 + string(anexo) //2009,2010,2011,2012,

		*- Rename sex
		if inlist(`year',2007,2008,2009,2010,2011,2012)==1 {
			gen sexo = "Mujer" if nena==1 
			replace sexo = "Hombre" if nena==0
		}
		if inlist(`year',2014,2015)==1		rename sexo_estu sexo

		*- Rename Gestion
		if inlist(`year',2015,2016)==1		rename gestion2 gestion
		replace gestion = "No estatal" if gestion=="No Estatal"
		
		*- Rename Seccion
		if inlist(`year',2016)==1 rename (id_seccion) (seccion) //l to c		

		
		*- Rename Scores
		if inlist(`year',2014,2015)==1 rename (m500_c_`year' m500_m_`year') (m500_c m500_m) //l to c
		if inlist(`year',2016)==1 rename (m500_l) (m500_c) //l to c		

		*- Rename Score labels
		if inlist(`year',2007,2008,2009,2010,2011,2012,2014,2015)==1 rename (grupo_3c grupo_3m) (grupo_c grupo_m) // missing 2013
		if inlist(`year',2016)==1 rename (grupo_l grupo_m) (grupo_c grupo_m) // missing 2013
		if inlist(`year',2011,2012)==1 {
			replace grupo_c = "1" if grupo_c=="< Nivel 1"
			replace grupo_c = "2" if grupo_c=="Nivel 1"
			replace grupo_c = "3" if grupo_c=="Nivel 2"
			
			replace grupo_m = "1" if grupo_m=="< Nivel 1"
			replace grupo_m = "2" if grupo_m=="Nivel 1"
			replace grupo_m = "3" if grupo_m=="Nivel 2"			
		}
		
		if inlist(`year',2014,2015,2016)==1 {
			replace grupo_c = "1" if grupo_c=="En inicio" | grupo_c=="En Inicio"
			replace grupo_c = "2" if grupo_c=="En proceso" | grupo_c=="EN Proceso"
			replace grupo_c = "3" if grupo_c=="Satisfactorio"
			
			replace grupo_m = "1" if grupo_m=="En inicio" | grupo_m=="En Inicio"
			replace grupo_m = "2" if grupo_m=="En proceso" | grupo_m=="EN Proceso"
			replace grupo_m = "3" if grupo_m=="Satisfactorio"			
		}
	
			
		//if inlist(`year',2009,2010,2011)==1 rename (m500_c_`s2year' m500_m_`s2year') (m500_c m500_m) //l to c
		destring m500*, replace force
		capture destring  grupo*, replace force
		
		gen year = `year'
		
		isvar 	/*ID*/ 			id* year* ///
				/*GEO*/			region* provincia* distrito* cod area* rural /*cod_dre cod_ugel codgeo*/ cen_pob /// //solve format of var for cod_ugel, cod_geo
				/*School*/		caracteristica2* gestion* polidocente multigrado unidocente  id_seccion seccion ///
				/*Student*/		sexo* lengua_materna ise n_ise paterno materno nombres ///
				/*Test*/ 		m500_* grupo*
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress

		tempfile ece_`year'_`grade'
		save `ece_`year'_`grade'', replace
	}

	clear
	foreach year in "2007" "2008" "2009" "2010" "2011" "2012" "2013" "2014" "2015" "2016" /*"2019"*/ {
		append using `ece_`year'_`grade''
		}

	/*
	merge 1:1 id_2p year using "$temp\umc_newvars", keepusing(rep*) keep(master match)
	drop _m 
	*/

	replace caracteristica2 = "Polidocente Completo" if strmatch(caracteristica2,"*olidocent*")==1	
	replace caracteristica2 = "Polidocente Completo" if polidocente==1 & year<=2008
	replace caracteristica2 = "Unidocente / Multigrado" if (polidocente==0) & year==2007
	replace caracteristica2 = "Unidocente / Multigrado" if (multigrado==1 | unidocente==1) & year==2008
	rename caracteristica2 caracteristica

	replace area = "Urbana" if rural==0 & year<=2008
	replace area = "Rural" if rural==1 & year<=2008
	replace area = "Urbana" if area=="Urbano" & year==2015
	drop rural polidocente multigrado unidocente
	gen rural = (area == "Rural") if area!=""
	gen polidocente = (caracteristica == "Polidocente Completo")

	replace sexo = "" if sexo=="No identificado"

	label define rural 0 "Urbano" 1 "Rural"
	label define polidocente 0 "Unidocente / Multigrado" 1 "Polidocente Completo"
	label values rural rural 
	label values polidocente polidocente
	
	*- Standardized scores
	VarStandardiz m500_m, newvar(std_m) by(year)
	VarStandardiz m500_c, newvar(std_c) by(year)
	gen m500_total = std_m + std_c
	VarStandardiz m500_total, newvar(std_t) by(year)
	
	*- Percentile scores
	gen pct_m = .
	gen pct_c = .
	gen pct_t = .
	foreach year in "2007" "2008" "2009" "2010" "2011" "2012" "2013" "2014" "2015" "2016" {
		xtile pct_m_`year' = std_m if year == `year', n(100)
		xtile pct_c_`year' = std_c if year == `year', n(100)
		xtile pct_t_`year' = std_t if year == `year', n(100)
		replace pct_m = pct_m_`year' if pct_m==. & year==`year'
		replace pct_c = pct_m_`year' if pct_c==. & year==`year'
		replace pct_t = pct_m_`year' if pct_t==. & year==`year'
	}
	
	//drop m500*
		
	rename * *_`grade'
	
	compress
	tempfile ece_2p
	save `ece_2p'

	save "$TEMP\ece_2p", replace // need umcnewvars to have repitence


*- ECE: append 4P
	local grade  = "4p"
	foreach year in "2016" "2018" {
		use "$IN\ECE\in\ece_`year'_`grade'", clear
		rename *, lower
		
		rename id_`grade'_`year' id
		drop if id=="" | id=="0" | id=="#NULL!"
			
		gen id_ie = cod_mod7 + string(anexo)
		

	
		*- Rename Seccion
		if inlist(`year',2016)==1 rename (id_secc) (seccion) //l to c
		
		if inlist(`year',2018) == 1 {
			capture drop seccion //only 2018 has it
			rename id_seccion seccion
		}
		
		*- Rename Scores
		if inlist(`year',2016)==1 rename (m500_l) (m500_c) //l to c
		if inlist(`year',2018)==1 rename (medida500_l medida500_m) (m500_c m500_m)

		*- Rename Score labels	
		if inlist(`year',2016,2018)==1 rename (grupo_l grupo_m) (grupo_c grupo_m) // missing 2013
		if inlist(`year',2016,2018)==1 {
			replace grupo_c = "1" if grupo_c=="Previo al inicio"
			replace grupo_c = "2" if grupo_c=="En inicio" 
			replace grupo_c = "3" if grupo_c=="En proceso"
			replace grupo_c = "4" if grupo_c=="Satisfactorio"
			
			replace grupo_m = "1" if grupo_m=="Previo al inicio"
			replace grupo_m = "2" if grupo_m=="En inicio" 
			replace grupo_m = "3" if grupo_m=="En proceso"
			replace grupo_m = "4" if grupo_m=="Satisfactorio"			
		}		
		
		destring m500*, replace force
		capture destring  grupo*, replace force
		
		gen year = `year'
		
		isvar 	/*ID*/ 			id* year* ///
				/*GEO*/			 region* provincia* distrito* cod area* rural cod_dre cod_ugel codgeo cen_pob ///
				/*School*/		caracteristica2* gestion* polidocente multigrado unidocente  id_seccion seccion ///
				/*Student*/		sexo* lengua_materna ise n_ise paterno materno nombres ///
				/*Test*/ 		m500_* grupo*
				
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress
		
		tempfile ece_`year'_`grade'
		save `ece_`year'_`grade'', replace
	}


	clear
	foreach year in "2016" "2018" {
		append using `ece_`year'_`grade''
		}

	*- Standardized scores
	VarStandardiz m500_m, newvar(std_m) by(year)
	VarStandardiz m500_c, newvar(std_c) by(year)
	gen m500_total = std_m + std_c
	VarStandardiz m500_total, newvar(std_t) by(year)
	
	*- Percentile scores
	gen pct_m = .
	gen pct_c = .
	gen pct_t = .
	foreach year in "2016" "2018" {
		xtile pct_m_`year' = std_m if year == `year', n(100)
		xtile pct_c_`year' = std_c if year == `year', n(100)
		xtile pct_t_`year' = std_t if year == `year', n(100)
		replace pct_m = pct_m_`year' if pct_m==. & year==`year'
		replace pct_c = pct_m_`year' if pct_c==. & year==`year'
		replace pct_t = pct_m_`year' if pct_t==. & year==`year'
	}
	
	//drop m500*
	
	rename * *_`grade'

	compress
	tempfile ece_4p
	save `ece_4p'

	save "$TEMP\ece_4p", replace // need umcnewvars to have repitence


*- ECE: append 2S
	local grade  = "2s"
	foreach year in "2015" "2016" "2018" "2019" {
		use "$IN\ECE\in\ece_`year'_`grade'", clear
		rename *, lower
		
		*- Rename ID		
		if inlist(`year',2019)==0 rename id_`grade'_`year' id
		if inlist(`year',2019)==1 {
			rename id_estudiante_`year' id			
			replace id = substr(id,8,12)
			rename id_estudiante2013 validate_id_2p2013_2s2019
		}
		drop if id=="" | id=="0" | id=="#NULL!"
			
		if inlist(`year',2019)==0 gen id_ie = cod_mod7 + string(anexo)
		if inlist(`year',2019)==1 gen id_ie = cod_mod7 + anexo
		
		*- Rename Seccion
		if inlist(`year',2016,2018) == 1 {
			capture drop seccion //only 2018 has it
			rename id_seccion seccion
		}		
		
		*- Rename Sex
		if inlist(`year',2015)==1 rename (sexo_estu) (sexo) //l to c

		*- Rename Scores
		if inlist(`year',2015)==1 rename (m500_l) (m500_c) //l to c		
		if inlist(`year',2016)==1 rename m500_l m500_c //l to c
		if inlist(`year',2018)==1 rename (medida500_l medida500_m medida500_hge medida500_cta) (m500_c m500_m m500_h m500_s)
		if inlist(`year',2019)==1 rename (medida500_l medida500_m medida500_cn) (m500_c m500_m m500_s)
		
		*- Rename Score labels	
		if inlist(`year',2015)==1 rename (grupo_ece_2s_2015_c grupo_ece_2s_2015_m) 	(grupo_c grupo_m) // missing 2013
		if inlist(`year',2016)==1 rename (grupo_l grupo_m grupo_hge) 				(grupo_c grupo_m grupo_h) // missing 2013
		if inlist(`year',2018)==1 rename (grupo_l grupo_hge grupo_cta) (grupo_c grupo_h grupo_s) // missing 2013
		if inlist(`year',2019)==1 rename (grupo_l grupo_cn) (grupo_c grupo_s) // missing 2013
		if inlist(`year',2015,2016,2018,2019)==1 {
			foreach subj in "c" "m" "h" "s" {
				capture replace grupo_`subj' = "1" if grupo_`subj'=="Previo al inicio"
				capture replace grupo_`subj' = "2" if grupo_`subj'=="En inicio" 
				capture replace grupo_`subj' = "3" if grupo_`subj'=="En proceso"
				capture replace grupo_`subj' = "4" if grupo_`subj'=="Satisfactorio"
			}
		}		
						
		destring m500*, replace force
		capture destring  grupo*, replace force
		
		gen year = `year'

		isvar 	/*ID*/ 			id* year* ///
				/*GEO*/			 region* provincia* distrito* cod area* rural cod_dre cod_ugel codgeo cen_pob ///
				/*School*/		caracteristica2* gestion* polidocente multigrado unidocente  id_seccion seccion ///
				/*Student*/		sexo* lengua_materna ise n_ise paterno materno nombres ///
				/*Test*/ 		m500_* grupo*
				
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress
		
		tempfile ece_`year'_`grade'
		save `ece_`year'_`grade'', replace
	}


	clear
	foreach year in "2015" "2016" "2018" "2019" {
		append using `ece_`year'_`grade''
		}


	*- Standardized scores
	VarStandardiz m500_m, newvar(std_m) by(year)
	VarStandardiz m500_c, newvar(std_c) by(year)
	gen m500_total = std_m + std_c
	VarStandardiz m500_total, newvar(std_t) by(year)
	
	capture VarStandardiz m500_s, newvar(std_s) by(year)
	capture VarStandardiz m500_h, newvar(std_h) by(year)
	
	*- Percentile scores
	gen pct_m = .
	gen pct_c = .
	gen pct_t = .
	foreach year in "2015" "2016" "2018" "2019" {
		xtile pct_m_`year' = std_m if year == `year', n(100)
		xtile pct_c_`year' = std_c if year == `year', n(100)
		xtile pct_t_`year' = std_t if year == `year', n(100)
		replace pct_m = pct_m_`year' if pct_m==. & year==`year'
		replace pct_c = pct_m_`year' if pct_c==. & year==`year'
		replace pct_t = pct_m_`year' if pct_t==. & year==`year'
	}
	
	//drop m500*
	
	rename * *_`grade'	

	compress
	tempfile ece_2s
	save `ece_2s'

	save "$TEMP\ece_2s", replace // need umcnewvars to have repitence

end

********************************************************************************
* ECE Survey
********************************************************************************
	
capture program drop ece_survey 
program define ece_survey 	

*- Family 2P
	import excel "$IN\socioeconomico\Primaria 2P\ECE 2P 2015 Cuestionario Familia.xlsx", sheet("Base de datos") firstrow allstring clear
	local year = 2015
	local grade = "2p"
	
	rename *, lower
	rename id_estudiante id
	replace id = substr(id,8,12)
	
	*- Recode id student to make compatible with other databases
	gen id_part1 = substr(id,1,8)
	gen id_part2 = substr(id,9,2)
	gen id_part3 = substr(id,11,2)
	
	replace id_part2 = subinstr(id_part2,"01","A",.)
	replace id_part2 = subinstr(id_part2,"02","B",.)
	replace id_part2 = subinstr(id_part2,"03","C",.)
	replace id_part2 = subinstr(id_part2,"04","D",.)
	replace id_part2 = subinstr(id_part2,"05","E",.)
	replace id_part2 = subinstr(id_part2,"06","F",.)
	replace id_part2 = subinstr(id_part2,"07","G",.)
	replace id_part2 = subinstr(id_part2,"08","H",.)
	replace id_part2 = subinstr(id_part2,"09","I",.)
	replace id_part2 = subinstr(id_part2,"10","J",.)
	replace id_part2 = subinstr(id_part2,"11","K",.)
	replace id_part2 = subinstr(id_part2,"12","L",.)
	replace id_part2 = subinstr(id_part2,"13","M",.)
	replace id_part2 = subinstr(id_part2,"14","N",.)
	replace id_part2 = subinstr(id_part2,"15","O",.)
	replace id_part2 = subinstr(id_part2,"16","P",.)
	replace id_part2 = subinstr(id_part2,"17","Q",.)
	replace id_part2 = subinstr(id_part2,"18","R",.)
	replace id_part2 = subinstr(id_part2,"19","S",.)
	replace id_part2 = subinstr(id_part2,"20","T",.)
	replace id_part2 = subinstr(id_part2,"21","U",.)
	replace id_part2 = subinstr(id_part2,"22","V",.)
	replace id_part2 = subinstr(id_part2,"23","W",.)
	replace id_part2 = subinstr(id_part2,"24","X",.)
	replace id_part2 = subinstr(id_part2,"25","Y",.)
	replace id_part2 = subinstr(id_part2,"26","Z",.)
	replace id_part2 = subinstr(id_part2,"27","0",.)
	replace id_part2 = subinstr(id_part2,"28","1",.)
	
	replace id = id_part1 + id_part2 + id_part3	
	
	drop if id=="" | id=="0" | id=="#NULL!"
	rename pfp41 aspiration
	rename pfp23_01 radio
	rename pfp23_09 phone_internet
	rename pfp23_10 internet
	rename pfp23_11 pc
	rename pfp23_12 laptop
	
	rename pfp03 lengua_materna_mother
	rename pfp05 edu_mother
	
	rename pfp32_1 freq_activities_1
	rename pfp32_2 freq_activities_2
	rename pfp32_3 freq_activities_3
	rename pfp32_4 freq_activities_4

	gen id_ie = cod_mod7 + anexo
	gen year = `year'
	isvar 	/*ID*/ 					id* year* ///
			/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
			/*Parents*/				lengua_materna_mother edu_mother ///
			/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
			/*child labor*/			child_labor
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'
	compress	

	rename * *_`grade'

	tempfile ece_family_`year'_`grade'
	save `ece_family_`year'_`grade'', replace
	save "$TEMP\ece_family_`year'_2p", replace


	import excel "$IN\socioeconomico\Primaria 2P\ECE 2P 2016 Cuestionario Familia.xlsx", sheet("Base de datos") firstrow allstring clear
	local year = 2016
	local grade = "2p"
	
	rename *, lower
	rename id_estudiante id
	replace id = substr(id,8,12)
	drop if id=="" | id=="0" | id=="#NULL!"
	rename pa_36 aspiration
	rename pa_19_01 radio
	rename pa_19_19 phone_internet
	rename pa_19_20 internet
	rename pa_19_07 pc
	rename pa_19_08 laptop
	
	rename pa_04 lengua_materna_mother
	rename pa_06 edu_mother
	rename pa_27_01 gender_subj_1
	rename pa_27_02 gender_subj_2
	rename pa_27_03 gender_subj_3
	rename pa_27_04 gender_subj_4
	
	rename pa_28_01 importance_success_m_1
	rename pa_28_02 importance_success_m_2
	rename pa_28_03 importance_success_m_3
	rename pa_28_04 importance_success_m_4
	rename pa_28_05 importance_success_m_5
	rename pa_28_06 importance_success_m_6

	rename pa_29_01 importance_success_c_1
	rename pa_29_02 importance_success_c_2
	rename pa_29_03 importance_success_c_3
	rename pa_29_04 importance_success_c_4
	rename pa_29_05 importance_success_c_5
	rename pa_29_06 importance_success_c_6
	
	rename pa_30 current_m
	rename pa_31 future_m
	rename pa_32 past_m
	rename pa_33 current_c
	rename pa_34 future_c
	rename pa_35 past_c

	gen id_ie = cod_mod7 + anexo
	gen year = `year'
	isvar 	/*ID*/ 					id* year* ///
			/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
			/*Parents*/				lengua_materna_mother edu_mother ///
			/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
			/*child labor*/			child_labor
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'
	compress	

	rename * *_`grade'

	tempfile ece_family_`year'_`grade'
	save `ece_family_`year'_`grade'', replace
	save "$TEMP\ece_family_`year'_2p", replace



	import excel "$IN\socioeconomico\Primaria 2P\ECE 2P 2019 Cuestionario Familia.xlsx", sheet("Base de datos") firstrow allstring clear
	local year = 2019
	local grade = "2p"
	
	rename *, lower
	rename id_estudiante id
	replace id = substr(id,8,12)
	drop if id=="" | id=="0" | id=="#NULL!"
	rename p17 aspiration
	rename p11_01 radio
	rename p11_17 phone_internet
	rename p11_18 internet
	rename p11_07 pc
	rename p11_08 laptop

	gen id_ie = cod_mod7 + anexo
	gen year = `year'
	isvar 	/*ID*/ 					id* year* ///
			/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
			/*Parents*/				lengua_materna_mother edu_mother ///
			/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
			/*child labor*/			child_labor
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'
	compress	

	rename * *_`grade'

	tempfile ece_family_`year'_`grade'
	save `ece_family_`year'_`grade'', replace
	save "$TEMP\ece_family_`year'_2p", replace

	clear
	append using `ece_family_2015_2p'
	append using `ece_family_2016_2p'
	append using `ece_family_2019_2p'
	save "$TEMP\ece_family_2p", replace



*- Family 4P

	import excel "$IN\socioeconomico\Primaria 4P\ECE 4P 2016 Cuestionario Familia.xlsx", sheet("Base de datos") firstrow allstring clear
	local year = 2016
	local grade = "4p"
	
	rename *, lower
	rename id_estudiante id
	replace id = substr(id,8,12)
	drop if id=="" | id=="0" | id=="#NULL!"
	rename pa_29 aspiration
	rename pa_19_01 radio
	rename pa_19_19 phone_internet
	rename pa_19_20 internet
	rename pa_19_07 pc
	rename pa_19_08 laptop

	gen id_ie = cod_mod7 + anexo
	gen year = `year'
	isvar 	/*ID*/ 					id* year* ///
			/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
			/*Parents*/				lengua_materna_mother edu_mother ///
			/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
			/*child labor*/			child_labor
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'
	compress	

	rename * *_`grade'

	tempfile ece_family_`year'_`grade'
	save `ece_family_`year'_`grade'', replace


	import excel "$IN\socioeconomico\Primaria 4P\ECE 4P 2018 Cuestionario Familia.xlsx", sheet("Base de datos") firstrow allstring clear
	local year = 2018
	local grade = "4p"
	
	rename *, lower
	rename id_estudiante id
	replace id = substr(id,8,12)
	drop if id=="" | id=="0" | id=="#NULL!"
	rename p27 aspiration
	rename p09_01 radio
	rename p09_19 phone_internet
	rename p09_20 internet
	rename p09_07 pc
	rename p09_08 laptop
	
	rename p15 lengua_materna_mother
	rename p17 edu_mother
	rename p25_01 gender_subj_1
	rename p25_02 gender_subj_2
	rename p25_03 gender_subj_3
	rename p25_04 gender_subj_4
	rename p25_05 gender_subj_5
	rename p25_06 gender_subj_6
	rename p21_01 satisfied_opportunities_1
	rename p21_02 satisfied_opportunities_2
	rename p21_03 satisfied_opportunities_3
	rename p21_04 satisfied_opportunities_4
	rename p21_05 satisfied_opportunities_5
	rename p21_06 satisfied_opportunities_6
	rename p21_07 satisfied_opportunities_7
	rename p26_01 importance_success_1
	rename p26_02 importance_success_2
	rename p26_03 importance_success_3
	rename p26_04 importance_success_4
	rename p26_05 importance_success_5
	rename p32_01 asked_activities_1
	rename p32_02 asked_activities_2
	rename p32_03 asked_activities_3
	rename p32_04 asked_activities_4
	rename p32_05 asked_activities_5

	gen id_ie = cod_mod7 + anexo
	gen year = `year'
	isvar 	/*ID*/ 					id* year* ///
			/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
			/*Parents*/				lengua_materna_mother edu_mother ///
			/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
			/*child labor*/			child_labor
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'
	compress	

	rename * *_`grade'

	tempfile ece_family_`year'_`grade'
	save `ece_family_`year'_`grade'', replace


	clear
	append using `ece_family_2016_4p'
	append using `ece_family_2018_4p'
	save "$TEMP\ece_family_4p", replace
	
*- Student 2S
	import excel "$IN\socioeconomico\Secundaria 2S\ECE 2S 2015 Cuestionario Estudiante.xlsx", sheet("Base de datos") firstrow allstring clear
	local year = 2015
	local grade = "2s"
	
	rename *, lower
	rename id_estudiante id
	
	replace id = substr(id,8,12)

	*- Recode id student to make compatible with other databases
	gen id_part1 = substr(id,1,8)
	gen id_part2 = substr(id,9,2)
	gen id_part3 = substr(id,11,2)
	
	replace id_part2 = subinstr(id_part2,"01","A",.)
	replace id_part2 = subinstr(id_part2,"02","B",.)
	replace id_part2 = subinstr(id_part2,"03","C",.)
	replace id_part2 = subinstr(id_part2,"04","D",.)
	replace id_part2 = subinstr(id_part2,"05","E",.)
	replace id_part2 = subinstr(id_part2,"06","F",.)
	replace id_part2 = subinstr(id_part2,"07","G",.)
	replace id_part2 = subinstr(id_part2,"08","H",.)
	replace id_part2 = subinstr(id_part2,"09","I",.)
	replace id_part2 = subinstr(id_part2,"10","J",.)
	replace id_part2 = subinstr(id_part2,"11","K",.)
	replace id_part2 = subinstr(id_part2,"12","L",.)
	replace id_part2 = subinstr(id_part2,"13","M",.)
	replace id_part2 = subinstr(id_part2,"14","N",.)
	replace id_part2 = subinstr(id_part2,"15","O",.)
	replace id_part2 = subinstr(id_part2,"16","P",.)
	replace id_part2 = subinstr(id_part2,"17","Q",.)
	replace id_part2 = subinstr(id_part2,"18","R",.)
	replace id_part2 = subinstr(id_part2,"19","S",.)
	replace id_part2 = subinstr(id_part2,"20","T",.)
	replace id_part2 = subinstr(id_part2,"21","U",.)
	replace id_part2 = subinstr(id_part2,"22","V",.)
	replace id_part2 = subinstr(id_part2,"23","W",.)
	replace id_part2 = subinstr(id_part2,"24","X",.)
	replace id_part2 = subinstr(id_part2,"25","Y",.)
	replace id_part2 = subinstr(id_part2,"26","Z",.)
	replace id_part2 = subinstr(id_part2,"27","0",.)
	replace id_part2 = subinstr(id_part2,"28","1",.)
	
	replace id = id_part1 + id_part2 + id_part3

	drop if id=="" | id=="0" | id=="#NULL!"
	rename esp31 aspiration
	rename esp17_01 radio
	rename esp17_09 phone_internet
	rename esp17_10 internet
	rename esp17_11 pc
	rename esp17_12 laptop

	gen id_ie = cod_mod7 + anexo
	gen year = `year'
	isvar 	/*ID*/ 					id* year* ///
			/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
			/*Parents*/				lengua_materna_mother edu_mother ///
			/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
			/*child labor*/			child_labor
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'
	compress	

	rename * *_`grade'

	tempfile ece_student_`year'_`grade'
	save `ece_student_`year'_`grade'', replace
	save "$TEMP\ece_student_`year'_2s", replace
	
	import excel "$IN\socioeconomico\Secundaria 2S\ECE 2S 2016 Cuestionario Estudiante.xlsx", sheet("Base de datos") firstrow allstring clear
	local year = 2016
	local grade = "2s"
	
	rename *, lower
	rename id_estudiante id
	replace id = substr(id,8,12)
	drop if id=="" | id=="0" | id=="#NULL!"
	rename e1_23 aspiration
	rename e1_13_01 radio
	rename e1_13_19 phone_internet
	rename e1_13_20 internet
	rename e1_13_07 pc
	rename e1_13_08 laptop

	gen id_ie = cod_mod7 + anexo
	gen year = `year'
	isvar 	/*ID*/ 					id* year* ///
			/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
			/*Parents*/				lengua_materna_mother edu_mother ///
			/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
			/*child labor*/			child_labor
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'
	compress	

	rename * *_`grade'

	tempfile ece_student_`year'_`grade'
	save `ece_student_`year'_`grade'', replace	
	save "$TEMP\ece_student_`year'_2s", replace
	
	import excel "$IN\socioeconomico\Secundaria 2S\ECE 2S 2018 Cuestionario Estudiante.xlsx", sheet("Base de datos") firstrow allstring clear
	local year = 2018
	local grade = "2s"
	
	rename *, lower
	rename id_estudiante id
	replace id = substr(id,8,12)
	drop if id=="" | id=="0" | id=="#NULL!"
	rename p23 aspiration
	rename p12_01 radio
	rename p12_19 phone_internet
	rename p12_20 internet
	rename p12_07 pc
	rename p12_08 laptop

	gen id_ie = cod_mod7 + anexo
	gen year = `year'
	isvar 	/*ID*/ 					id* year* ///
			/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
			/*Parents*/				lengua_materna_mother edu_mother ///
			/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
			/*child labor*/			child_labor
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'
	compress	

	rename * *_`grade'

	tempfile ece_student_`year'_`grade'
	save `ece_student_`year'_`grade'', replace	
	save "$TEMP\ece_student_`year'_2s", replace
	
	import excel "$IN\socioeconomico\Secundaria 2S\ECE 2S 2019 Cuestionario Estudiante.xlsx", sheet("Base de datos") firstrow allstring clear
	local year = 2019
	local grade = "2s"
	
	rename *, lower
	rename id_estudiante id
	replace id = substr(id,8,12)
	drop if id=="" | id=="0" | id=="#NULL!"
	rename p05 aspiration
	rename p14_01 radio
	rename p14_19 phone_internet
	rename p14_20 internet
	rename p14_07 pc
	rename p14_08 laptop

	gen id_ie = cod_mod7 + anexo
	gen year = `year'
	isvar 	/*ID*/ 					id* year* ///
			/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
			/*Parents*/				lengua_materna_mother edu_mother ///
			/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
			/*child labor*/			child_labor
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'
	compress	

	rename * *_`grade'

	tempfile ece_student_`year'_`grade'
	save `ece_student_`year'_`grade'', replace	
	save "$TEMP\ece_student_`year'_2s", replace

	
	clear
	append using `ece_student_2015_2s'
	append using `ece_student_2016_2s'
	append using `ece_student_2018_2s'
	append using `ece_student_2019_2s'	
	save "$TEMP\ece_student_2s", replace
	
end

********************************************************************************
* crosswalk
********************************************************************************
	
capture program drop crosswalk_ece 
program define crosswalk_ece 		
	
*- Crosswalk

	import excel "$IN\ECE\in\Empate_2014(2P) y 2016(4P).xlsx", sheet("Empate_2014(2P) y 2016(4P)") firstrow allstring clear
	rename *, lower
	rename (id_2p_2014 id_4p_2016) (id_2p id_4p)
	gen year_2p = 2014
	gen year_4p = 2016
	tempfile ece_2014_2016
	save `ece_2014_2016'
	save "$TEMP\ece_2014_2016.dta", replace

	import excel "$IN\ECE\in\Empate_2016(2P) y 2018(4P).xlsx", sheet("Sheet1") firstrow allstring clear
	rename *, lower
	rename (id_2p_2016 id_4p_2018) (id_2p id_4p)
	gen year_2p = 2016
	gen year_4p = 2018
	tempfile ece_2016_2018
	save `ece_2016_2018'
	save "$TEMP\ece_2016_2018.dta", replace

	import excel "$IN\ECE\in\Empate_2009(2P) y 2015(2S).xlsx", sheet("Empate_2009(2P) y 2015(2S)") firstrow allstring clear
	rename *, lower
	rename (id_2p_2009 id_2s_2015) (id_2p id_2s)
	gen year_2p = 2009
	gen year_2s = 2015
	tempfile ece_2009_2015
	save `ece_2009_2015'
	save "$TEMP\ece_2009_2015.dta", replace

	import excel "$IN\ECE\in\Empate_2010(2P) y 2016(2S).xlsx", sheet("Empate_2010(2P) y 2016(2S)") firstrow allstring clear
	rename *, lower
	rename (id_2p_2010 id_2s_2016) (id_2p id_2s)
	gen year_2p = 2010
	gen year_2s = 2016
	tempfile ece_2010_2016
	save `ece_2010_2016'
	save "$TEMP\ece_2010_2016.dta", replace

	import excel "$IN\ECE\in\Empate_2012(2P) y 2018(2S).xlsx", sheet("Sheet1") firstrow allstring clear
	rename *, lower
	rename (id_2p_2012 id_2s_2018) (id_2p id_2s)
	gen year_2p = 2012
	gen year_2s = 2018
	tempfile ece_2012_2018
	save `ece_2012_2018'
	save "$TEMP\ece_2012_2018.dta", replace

	use ID_estudiante_2019 ID_estudiante2013 using "$IN\ECE\in\ece_2019_2s", clear
	rename *, lower
	rename (id_estudiante2013 id_estudiante_2019) (id_2p id_2s)
	replace id_2p = substr(id_2p,8,12)
	replace id_2s = substr(id_2s,8,12)
	gen year_2p = 2013
	gen year_2s = 2019
	drop if id_2p==""
	tempfile ece_2013_2019
	save `ece_2013_2019'
	save "$TEMP\ece_2013_2019.dta", replace

end

********************************************************************************
* merge_data
********************************************************************************
	
capture program drop merge_data_ece
program define merge_data_ece 	

	*----------------
	*-	2. MERGE DATA
	*----------------

	use "$TEMP\ece_2p", clear
	gen year_2s = .
	gen year_4p = .
	gen id_2s = ""
	gen id_4p = ""


	merge m:1 id_2p year_2p using "$TEMP\ece_2009_2015", keep(master match match_update) assert(master match using match_update) update //2s - there should be no conflict since 2p is yearly.
	rename _m m_2009
	merge m:1 id_2p year_2p using "$TEMP\ece_2010_2016", keep(master match match_update) assert(master match using match_update)  update //2s
	rename _m m_2010
	merge m:1 id_2p year_2p using "$TEMP\ece_2012_2018", keep(master match match_update) assert(master match using match_update)  update //2s
	rename _m m_2012
	merge m:1 id_2p year_2p using "$TEMP\ece_2013_2019", keep(master match match_update) assert(master match using match_update)  update //2s
	rename _m m_2013
	merge m:1 id_2p year_2p using "$TEMP\ece_2014_2016", keep(master match match_update) assert(master match using match_update)  update //4p
	rename _m m_2014
	merge m:1 id_2p year_2p using "$TEMP\ece_2016_2018", keep(master match match_update) assert(master match using match_update)  update //4p
	rename _m m_2016

	save "$TEMP\temp2", replace

	use "$TEMP\temp2", clear

	*Attach 4° and II secondary given matched ID's
	merge m:1 id_4p year_4p using "$TEMP\ece_4p" , keep(master match match_update) assert(master match using match_update)  update nogen
	merge m:1 id_2s year_2s using "$TEMP\ece_2s", keep(master match match_update) assert(master match using match_update)  update nogen


	*Attach Family/Student questionnaire
	merge m:1 id_2p year_2p using "$TEMP\ece_family_2p", keep(master match match_update) assert(master match using match_update)  update nogen
	merge m:1 id_4p year_4p using "$TEMP\ece_family_4p", keep(master match match_update) assert(master match using match_update)  update nogen
	merge m:1 id_2s year_2s using "$TEMP\ece_student_2s", keep(master match match_update) assert(master match using match_update)  update nogen


	*----------------
	*-	CLEAN DATA
	*----------------

	*- Make Strings to Numeric when appropriate
	isvar *
	local all_vars = r(varlist)
	foreach v of local all_vars {
		if substr("`v'",1,2) == "id" | substr("`v'",1,4) == "year" | substr("`v'",1,3) == "cod" | substr("`v'",1,7) == "seccion" continue
		capture confirm string variable `v'
		if !_rc {
			//string variables
			replace `v' = "" if `v' == "#NULL!"
			destring `v', replace
			di "`v' turned into numeric"
		}
		else {
			//numeric variables
			continue
		}	
	}

	compress

	*- Seccion
	foreach grade in "2p" "4p" "2s" {
		if "`grade'" == "2s" {
			replace seccion_`grade' = subinstr(seccion_`grade',"LL","A",.)
			replace seccion_`grade' = subinstr(seccion_`grade',"RR","A",.)
			replace seccion_`grade' = subinstr(seccion_`grade',"Ñ","A",.)
		}
		
		replace seccion_`grade' = subinstr(seccion_`grade',"01","A",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"02","B",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"03","C",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"04","D",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"05","E",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"06","F",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"07","G",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"08","H",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"09","I",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"10","J",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"11","K",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"12","L",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"13","M",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"14","N",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"15","O",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"16","P",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"17","Q",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"18","R",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"19","S",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"20","T",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"21","U",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"22","V",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"23","W",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"24","X",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"25","Y",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"26","Z",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"27","0",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"28","1",.)
		replace seccion_`grade' = subinstr(seccion_`grade',"29","2",.)
	}
	*- Male
	gen male_2p = sexo_2p == "Hombre"
	gen male_4p = sexo_4p == "Hombre"
	gen male_2s = sexo_2s == "Hombre"


	*- School by cohort fixed effect
	egen SC_2p 		= group(id_ie_2p year_2p), missing
	egen SSC_2p 	= group(id_ie_2p seccion_2p year_2p), missing
	egen SC_4p 		= group(id_ie_4p year_4p), missing
	egen SSC_4p 	= group(id_ie_4p seccion_4p year_4p), missing
	egen SC_2s 		= group(id_ie_2s year_2s), missing
	egen SSC_2s 	= group(id_ie_2s seccion_2s year_2s), missing

	*- Average score in school
	//## Should be done out of sample?
	bys SC_2p: egen std_m_2p_ie = mean(std_m_2p)
	bys SC_4p: egen std_m_4p_ie = mean(std_m_4p)
	bys SC_2s: egen std_m_2s_ie = mean(std_m_2s)
	bys SC_2p: egen std_c_2p_ie = mean(std_c_2p)
	bys SC_4p: egen std_c_4p_ie = mean(std_c_4p)
	bys SC_2s: egen std_c_2s_ie = mean(std_c_2s)

	bys SC_2p: egen pct_m_2p_ie = mean(pct_m_2p)
	bys SC_4p: egen pct_m_4p_ie = mean(pct_m_4p)
	bys SC_2s: egen pct_m_2s_ie = mean(pct_m_2s)
	bys SC_2p: egen pct_c_2p_ie = mean(pct_c_2p)
	bys SC_4p: egen pct_c_4p_ie = mean(pct_c_4p)
	bys SC_2s: egen pct_c_2s_ie = mean(pct_c_2s)

	*- Percentile rank within (school-cohort) according to ECE 2P
	bys SC_2p (pct_m_2p): gen rank_sc_m_2p = _n/_N if pct_m_2p!=.
	bys SC_2p (pct_c_2p): gen rank_sc_c_2p = _n/_N if pct_m_2p!=.
	bys SC_2p (pct_t_2p): gen rank_sc_t_2p = _n/_N if pct_m_2p!=.

	bys SC_4p (pct_m_4p): gen rank_sc_m_4p = _n/_N if pct_m_4p!=.
	bys SC_4p (pct_c_4p): gen rank_sc_c_4p = _n/_N if pct_m_4p!=.
	bys SC_4p (pct_t_4p): gen rank_sc_t_4p = _n/_N if pct_m_4p!=.

	bys SC_2s (pct_m_2s): gen rank_sc_m_2s = _n/_N if pct_m_2s!=.
	bys SC_2s (pct_c_2s): gen rank_sc_c_2s = _n/_N if pct_m_2s!=.
	bys SC_2s (pct_t_2s): gen rank_sc_t_2s = _n/_N if pct_m_2s!=.

	*- Percentile rank within classroom (school-subject-cohort) according to ECE 2P
	bys SSC_2p (pct_m_2p): gen rank_ssc_m_2p = _n/_N if pct_m_2p!=.
	bys SSC_2p (pct_c_2p): gen rank_ssc_c_2p = _n/_N if pct_m_2p!=.
	bys SSC_2p (pct_t_2p): gen rank_ssc_t_2p = _n/_N if pct_m_2p!=.

	bys SSC_4p (pct_m_4p): gen rank_ssc_m_4p = _n/_N if pct_m_4p!=.
	bys SSC_4p (pct_c_4p): gen rank_ssc_c_4p = _n/_N if pct_m_4p!=.
	bys SSC_4p (pct_t_4p): gen rank_ssc_t_4p = _n/_N if pct_m_4p!=.

	bys SSC_2s (pct_m_2s): gen rank_ssc_m_2s = _n/_N if pct_m_2s!=.
	bys SSC_2s (pct_c_2s): gen rank_ssc_c_2s = _n/_N if pct_m_2s!=.
	bys SSC_2s (pct_t_2s): gen rank_ssc_t_2s = _n/_N if pct_m_2s!=.

	*- Deviations from school average
	bys SC_2p: gen std_m_2p_SC_dev = std_m_2p - std_m_2p_ie
	bys SC_4p: gen std_m_4p_SC_dev = std_m_4p - std_m_4p_ie
	bys SC_2s: gen std_m_2s_SC_dev = std_m_2s - std_m_2s_ie
	bys SC_2p: gen pct_m_2p_SC_dev = pct_m_2p - pct_m_2p_ie
	bys SC_4p: gen pct_m_4p_SC_dev = pct_m_4p - pct_m_4p_ie
	bys SC_2s: gen pct_m_2s_SC_dev = pct_m_2s - pct_m_2s_ie

	bys SC_2p: gen std_c_2p_SC_dev = std_c_2p - std_c_2p_ie
	bys SC_4p: gen std_c_4p_SC_dev = std_c_4p - std_c_4p_ie
	bys SC_2s: gen std_c_2s_SC_dev = std_c_2s - std_c_2s_ie
	bys SC_2p: gen pct_c_2p_SC_dev = pct_c_2p - pct_c_2p_ie
	bys SC_4p: gen pct_c_4p_SC_dev = pct_c_4p - pct_c_4p_ie
	bys SC_2s: gen pct_c_2s_SC_dev = pct_c_2s - pct_c_2s_ie

	*- Standardized at the SC/SSC level
	VarStandardiz std_m_2p, by(SC_2p) newvar(std_m_2p_SC_std)
	VarStandardiz std_m_4p, by(SC_4p) newvar(std_m_4p_SC_std)
	VarStandardiz std_m_2s, by(SC_2s) newvar(std_m_2s_SC_std)
	VarStandardiz std_m_2p, by(SSC_2p) newvar(std_m_2p_SSC_std)
	VarStandardiz std_m_4p, by(SSC_4p) newvar(std_m_4p_SSC_std)
	VarStandardiz std_m_2s, by(SSC_2s) newvar(std_m_2s_SSC_std)

	VarStandardiz std_c_2p, by(SC_2p) newvar(std_c_2p_SC_std)
	VarStandardiz std_c_4p, by(SC_4p) newvar(std_c_4p_SC_std)
	VarStandardiz std_c_2s, by(SC_2s) newvar(std_c_2s_SC_std)
	VarStandardiz std_c_2p, by(SSC_2p) newvar(std_c_2p_SSC_std)
	VarStandardiz std_c_4p, by(SSC_4p) newvar(std_c_4p_SSC_std)
	VarStandardiz std_c_2s, by(SSC_2s) newvar(std_c_2s_SSC_std)


	*- Relation between rank and aspirations (1=Finish primary, 2=finish secondary, 3=Finish Technical, 4=Finish University, 5=Finish Master/PhD)
	gen aspiration_2p_HE = inlist(aspiration_2p,3,4,5) == 1 if aspiration_2p!=.
	gen aspiration_4p_HE = inlist(aspiration_4p,3,4,5) == 1 if aspiration_4p!=.
	gen aspiration_2s_HE = inlist(aspiration_2s,3,4,5) == 1 if aspiration_2s!=.


	label var std_m_2p_ie "Average STD score in 2nd grade school in Mathematics"
	label var std_m_4p_ie "Average STD score in 4th grade school in Mathematics"
	label var std_m_2s_ie "Average STD score in 8th grade school in Mathematics"
	label var std_c_2p_ie "Average STD score in 2nd grade school in Communication"
	label var std_c_4p_ie "Average STD score in 4th grade school in Communication"
	label var std_c_2s_ie "Average STD score in 8th grade school in Communication"

	label var std_m_2p_SC_dev "Demeaned STD score in 2nd grade school in Mathematics"
	label var std_m_4p_SC_dev "Demeaned STD score in 4th grade school in Mathematics"
	label var std_m_2s_SC_dev "Demeaned STD score in 8th grade school in Mathematics"
	label var std_c_2p_SC_dev "Demeaned STD score in 2nd grade school in Communication"
	label var std_c_4p_SC_dev "Demeaned STD score in 4th grade school in Communication"
	label var std_c_2s_SC_dev "Demeaned STD score in 8th grade school in Communication"

	label var pct_m_2p_SC_dev "Demeaned PCT score in 2nd grade school in Mathematics"
	label var pct_m_4p_SC_dev "Demeaned PCT score in 4th grade school in Mathematics"
	label var pct_m_2s_SC_dev "Demeaned PCT score in 8th grade school in Mathematics"
	label var pct_c_2p_SC_dev "Demeaned PCT score in 2nd grade school in Communication"
	label var pct_c_4p_SC_dev "Demeaned PCT score in 4th grade school in Communication"
	label var pct_c_2s_SC_dev "Demeaned PCT score in 8th grade school in Communication"

	label var pct_m_2p  "Percentile 2th grade Mathematics"
	label var pct_c_2p  "Percentile 2th grade Communication"
	label var pct_t_2p  "Percentile 2th grade Total"
	label var std_m_2p  "Standardized 2th grade Mathematics"
	label var std_c_2p  "Standardized 2th grade Communication"
	label var std_t_2p  "Standardized 2th grade Total"
	label var rank_sc_m_2p  "Ranking 2th grade Mathematics"
	label var rank_sc_c_2p  "Ranking 2th grade Communication"
	label var rank_sc_t_2p  "Ranking 2th grade Total"
	label var rank_ssc_m_2p  "Ranking 2th grade class Mathematics"
	label var rank_ssc_c_2p  "Ranking 2th grade class Communication"
	label var rank_ssc_t_2p  "Ranking 2th grade class Total"

	label var pct_m_4p  "Percentile 4th grade Mathematics"
	label var pct_c_4p  "Percentile 4th grade Communication"
	label var pct_t_4p  "Percentile 4th grade Total"
	label var std_m_4p  "Standardized 4th grade Mathematics"
	label var std_c_4p  "Standardized 4th grade Communication"
	label var std_t_4p  "Standardized 4th grade Total"
	label var rank_sc_m_4p  "Ranking 4th grade Mathematics"
	label var rank_sc_c_4p  "Ranking 4th grade Communication"
	label var rank_sc_t_4p  "Ranking 4th grade Total"
	label var rank_ssc_m_4p  "Ranking 4th grade class Mathematics"
	label var rank_ssc_c_4p  "Ranking 4th grade class Communication"
	label var rank_ssc_t_4p  "Ranking 4th grade class Total"

	label var pct_m_2s  "Percentile 8th grade Mathematics"
	label var pct_c_2s  "Percentile 8th grade Communication"
	label var pct_t_2s  "Percentile 8th grade Total"
	label var std_m_2s  "Standardized 8th grade Mathematics"
	label var std_c_2s  "Standardized 8th grade Communication"
	label var std_t_2s  "Standardized 8th grade Total"
	label var rank_sc_m_2s  "Ranking 8th grade Mathematics"
	label var rank_sc_c_2s  "Ranking 8th grade Communication"
	label var rank_sc_t_2s  "Ranking 8th grade Total"
	label var rank_ssc_m_2s  "Ranking 8th grade class Mathematics"
	label var rank_ssc_c_2s  "Ranking 8th grade class Communication"
	label var rank_ssc_t_2s  "Ranking 8th grade class Total"

	label var male_2p "Male"
	label var male_4p "Male"
	label var male_2s "Male"

	isvar 	/*ID*/ 						id* year* ///
			/*GEO*/						region* provincia* distrito* cod area* rural* cod_dre* cod_ugel* codgeo* cen_pob* ///
			/*School*/					caracteristica2* gestion* polidocente* multigrado* unidocente* id_seccion* seccion* std_*_ie ///
			/*Fixed Effect*/ 			SC* SSC* ///
			/*Student*/					male* lengua_materna* ise* n_ise* paterno* materno* nombres*  ///
			/*Parent*/					lengua_materna_mother* edu_mother* ///
			/*Test*/ 					m500* std* pct* rank* grupo* ///
			/*Access*/ 					radio* internet* pc* laptop* phone* plan_data*  ///
			/*aspiration/beliefs*/		aspiration* gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
			/*child labor*/				child_labor*
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'


	compress	

	save "$TEMP\students", replace

	tab year_2p if aspiration_2p!=.
	tab year_4p if aspiration_4p!=.
	tab year_2s if aspiration_2s!=.

end

/*
capture erase "$TEMP\temp1.dta"
capture erase "$TEMP\temp2.dta"
capture erase "$TEMP\ece_2p.dta"
capture erase "$TEMP\ece_4p.dta"
capture erase "$TEMP\ece_2s.dta"
capture erase "$TEMP\ece_family_2p.dta"
capture erase "$TEMP\ece_family_2015_2p.dta"
capture erase "$TEMP\ece_family_2016_2p.dta"
capture erase "$TEMP\ece_family_2019_2p.dta"
capture erase "$TEMP\ece_family_4p.dta"
capture erase "$TEMP\ece_student_2015_2s.dta"
capture erase "$TEMP\ece_student_2016_2s.dta"
capture erase "$TEMP\ece_student_2018_2s.dta"
capture erase "$TEMP\ece_student_2019_2s.dta"
capture erase "$TEMP\ece_student_2s.dta"
capture erase "$TEMP\ece_2014_2016.dta"
capture erase "$TEMP\ece_2016_2018.dta"
capture erase "$TEMP\ece_2009_2015.dta"
capture erase "$TEMP\ece_2010_2016.dta"
capture erase "$TEMP\ece_2012_2018.dta"
capture erase "$TEMP\ece_2013_2019.dta"
*/
