*- Figure out why RD is not balanced:


capture drop prepare
program define prepare

	clear
	foreach y in "2014" "2015" "2016" /*"2017" "2018" "2019" "2020" "2021" "2022" "2023"*/ {
			append using "$TEMP\siagie_`y'${data_siagie}", keep(id_ie id_per_umc year grade approved std_gpa_? educ_mother)
		}
	keep if grade==10 | grade==11
	bys id_per_umc grade (year): keep if _n==_N
	reshape wide id_ie year approved std_gpa_? educ_mother, i(id_per_umc) j(grade)
	//drop educ_mother10
	compress
	save "$TEMP\erase_siagie_10_11", replace

	use "$TEMP\applied", clear

	local cutoff_level = "major"


	merge m:1 id_cutoff_`cutoff_level' using  "$TEMP/applied_cutoffs_`cutoff_level'.dta", keep(master match) keepusing(cutoff_rank_`cutoff_level' cutoff_std_`cutoff_level' cutoff_raw_`cutoff_level' R2_`cutoff_level' N_below_`cutoff_level' N_above_`cutoff_level')
	gen lottery_nocutoff_`cutoff_level' = (cutoff_std_`cutoff_level'==.)
	drop _merge

	merge m:1 id_cutoff_`cutoff_level' using  "$TEMP/mccrary_cutoffs_noz_`cutoff_level'.dta", keep(master match) keepusing(mccrary_pv_def_noz_`cutoff_level' mccrary_pv_biasi_noz_`cutoff_level' mccrary_test_noz_`cutoff_level') nogen


	*- Match ECE IDs
	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2p", keep(master match) keepusing(id_estudiante source)
	rename _m merge_2p
	//tab grade merge_2p, row nofreq
	rename (id_estudiante source) (id_estudiante_2p source_2p)

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_4p", keep(master match) keepusing(id_estudiante source)
	rename _m merge_4p
	//tab grade merge_4p, row nofreq
	rename (id_estudiante source) (id_estudiante_4p source_4p)

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2s", keep(master match) keepusing(id_estudiante source)
	rename _m merge_2s
	//tab grade merge_2s, row nofreq
	rename (id_estudiante source) (id_estudiante_2s source_2s)

	*- Match ECE exams
	merge m:1 id_estudiante_2p using  "$TEMP\ece_2p", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year urban) //m:1 because there are missings
	rename _m merge_ece_2p
	rename (year score_math_std score_com_std score_acad_std) (year_2p score_math_std_2p score_com_std_2p score_acad_std_2p)
	rename (socioec_index socioec_index_cat) (socioec_index_2p socioec_index_cat_2p)
	rename (urban) (urban_2p)

	merge m:1 id_estudiante_4p using "$TEMP\ece_4p", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year) //m:1 because there are missings
	rename _m merge_ece_4p
	rename (year score_math_std score_com_std score_acad_std) (year_4p score_math_std_4p score_com_std_4p score_acad_std_4p)
	rename (socioec_index socioec_index_cat) (socioec_index_4p socioec_index_cat_4p)

	merge m:1 id_estudiante_2s using "$TEMP\ece_2s", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year) //m:1 because there are missings
	rename _m merge_ece_2s
	rename (year score_math_std score_com_std score_acad_std) (year_2s score_math_std_2s score_com_std_2s score_acad_std_2s)
	rename (socioec_index socioec_index_cat) (socioec_index_2s socioec_index_cat_2s)

	merge m:1 id_per_umc using "$TEMP\erase_siagie_10_11", keep(master match) keepusing(id_ie?? year?? approved?? std_gpa_??? educ_mother??)

	isvar 	id_cutoff_`cutoff_level' codigo_modular major_c1_inei_code major_c1_code  major_c1_name codigo_ubigeo type_admission public admitted one_application first_application_sem* year semester male age  score_raw score_std rank_score_raw_major score_std_major ///
			score_math* score_com* socioec* merge_?? ///
			cutoff_* lottery* mccrary_* rank_* R2* N_* ///
			id_ie?? year?? approved?? std_gpa_??? educ_mother
			
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'

	close

	*- Relevant Variables
	open


	set seed 1234
	global window = 2

	local fam_type = 2
	local cell = "major"
	local type = "noz"

	local sem = "first"
	local stack = "student_sibling"
	local results = "main" 


	global siblings = "oldest"
	global fam_type = `fam_type'
	global sem = "`sem'"
	global main_cell = "`cell'"
		
	egen FE_cm = group(codigo_modular major_c1_code)
	egen FE_y = group(semester)

	global fe_used = "FE_cm FE_y"

	**********************
	*- Additional Vars
	**********************
	rename *_`cell' *
	rename *_`type' * 

		

	*- Score relative
	gen score_relative = score_std - cutoff_std
	drop if score_relative==.	
	keep if abs(score_relative)<${window} 
	sort score_relative

	*- Run the RD regression
	gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=. //To avoid float issues around 0, we use the precisely integer rank scores.
	gen score_relative_1			= score_relative^1
	gen ABOVE_score_relative_1 	= ABOVE*score_relative_1

	**********************
	*- Prepare RD
	**********************

	*- Public schools
	keep if public==1

	*- Exclude those without estimated cutoffs
	keep if lottery_nocutoff == 0

	*- Exclude those at cutoff
	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)		
	keep if not_at_cutoff==1


	global scores_1 		= "score_relative_1"
	global ABOVE_scores_1 	= "ABOVE_score_relative_1"

end

*****

capture drop check_low_R2
program define check_low_R2

	preserve
		bys codigo_modular: sum R2 if type_admission==1, de

		/*
		//SOME CASES WITH LOW % OF R2=1
		160000003. UNIVERSIDAD NACIONAL DE SAN ANTONIO ABAD DEL CUSCO
		160000004. UNIVERSIDAD NACIONAL DE TRUJILLO
		160000005. UNIVERSIDAD NACIONAL DE SAN AGUSTÍN
		160000010. UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ
		160000011. UNIVERSIDAD NACIONAL DE LA AMAZONÍA PERUANA
		160000016. UNIVERSIDAD NACIONAL DE CAJAMARCA
		160000027. UNIVERSIDAD NACIONAL DEL CALLAO
		160000032. UNIVERSIDAD NACIONAL JORGE BASADRE GROHMANN
		*/

		keep if type_admission==1
		twoway 	(kdensity R2 if codigo_modular==160000003) ///
				(kdensity R2 if codigo_modular==160000004) ///
				(kdensity R2 if codigo_modular==160000005) ///
				(kdensity R2 if codigo_modular==160000010) ///
				(kdensity R2 if codigo_modular==160000011) ///
				(kdensity R2 if codigo_modular==160000016) ///
				(kdensity R2 if codigo_modular==160000027) ///
				(kdensity R2 if codigo_modular==160000032) 
				
	restore	
	
	*- UNMSM
	preserve
		keep if codigo_modular==160000001	
		keep if type_admission==1
		bys major_c1_name: egen r2_mean = mean(R2)
		tab major_c1_name if r2_mean<0.7
		tab major_c1_name if r2_mean<0.7
		tabstat R2 if codigo_modular==160000001 & r2_mean<0.7, by(major_c1_name)
	restore
		R2 inlist(codigo_modular,160000003,160000004,160000010,160000011,160000016,160000027,160000032)==1

end

capture drop prog1
program define prog1
	di "PROG1"
end

capture drop prog1
program define prog1
	di "PROG1"
end

capture drop prog1
program define prog1
	di "PROG1"
end

capture drop prog1
program define prog1
	di "PROG1"
end

*- First Stage
reghdfe admitted ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ///
		 abs(score_relative)<0.5, ///
		absorb(${fe_used}) 
		
reghdfe score_math_std_2s ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ///
		 abs(score_relative)<0.5 & inlist(type_admission,1)==1, ///
		absorb(${fe_used}) 			
		
reghdfe score_math_std_2s ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ///
		 abs(score_relative)<0.5 & inlist(type_admission,1)==1, ///
		absorb(${fe_used}) 	
		
reghdfe std_gpa_m11 ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ///
		 abs(score_relative)<0.5 & inlist(type_admission,1)==1, ///
		absorb(${fe_used}) 			
//-> There is likely an issue with how GPA of sibling was constructed? Try GPA of Focal.			
	
reghdfe merge_2s ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ///
		 abs(score_relative)<0.5 & inlist(type_admission,1)==1, ///
		absorb(${fe_used}) 		

gen non_gpa = std_gpa_m11==.
reghdfe non_gpa ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ///
		 abs(score_relative)<0.5 & inlist(type_admission,1)==1, ///
		absorb(${fe_used}) 			
		
		
//Clearly an issue at the cutoff. Why?	
binsreg score_math_std_2s score_relative if abs(score_relative)<0.2, nbins(1000)
reghdfe score_math_std_2s ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ///
		 abs(score_relative)<0.5, ///
		absorb(${fe_used}) 	
		
		
		
//Even if looking at the exams only, although balance regression looks well then
binsreg score_math_std_2s score_relative if abs(score_relative)<0.2 & inlist(type_admission,1)==1, nbins(1000)
binsreg score_math_std_2s score_relative if abs(score_relative)<0.2 & inlist(type_admission,1)!=1, nbins(1000)
reghdfe score_math_std_2s ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ///
		 abs(score_relative)<0.5 & inlist(type_admission,1,2)==1, ///
		absorb(${fe_used}) 		
		
		
//Is this the product of some colleges?
tab id_cutoff 	 if codigo_modular==160000001
binsreg admitted score_relative 		if  id_cutoff==1136
scatter score_math_std_2s score_relative if inlist(type_admission,1)==1 & id_cutoff==1136
		
		
//For one uni it looks ok
binsreg score_math_std_2s score_relative if abs(score_relative)<0.5 & codigo_modular==160000001, nbins(1000)
binsreg score_math_std_2s score_relative if abs(score_relative)<0.5 & codigo_modular==160000001, nbins(1000)

levelsof codigo_modular, local(college_list)
foreach cod of local college_list {
	di as text "	" _n
	di as text "CODIGO MODULAR: `cod'" _n
	di as text "	" _n
	reghdfe score_math_std_2s ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if codigo_modular==`cod' & ///
		 abs(score_relative)<0.2 & type_admission==1, ///
		absorb(${fe_used}) 	
}

//160000012
//160000013
//160000021
//160000027 (-)
//160000028
//160000031 (-)
//160000075 (-)
//160000076	(-)
//160000077 
//160000125 (VERY BIG)



binsreg admitted score_relative if codigo_modular==160000005, nbins(100)
reghdfe score_math_std_2s ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if codigo_modular==160000125 & ///
		 abs(score_relative)<0.2, ///
		absorb(${fe_used}) resid
		
predict y,xbd


gen step = round(score_relative,0.01)
bys codigo_modular step: egen y_mean = mean(score_math_std_2s)

twoway 	(scatter y score_relative if codigo_modular==160000125) ///
		(scatter y_mean score_relative if codigo_modular==160000125) 
		

///160000120 FULL 0

//We check if score_relative is similarly distributed across unis/cutoffs
gen just_above = score_relative>0 & score_relative<0.02
gen just_below = score_relative<0 & score_relative>-0.02

tabstat just_*, by(codigo_modular)

twoway 	(kdensity score_relative if codigo_modular==160000001) ///
		(kdensity score_relative if codigo_modular==160000002) ///
		(kdensity score_relative if codigo_modular==160000003) ///
		(kdensity score_relative if codigo_modular==160000004) ///
		, legend(off)

