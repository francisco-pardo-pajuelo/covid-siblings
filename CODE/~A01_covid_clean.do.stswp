*- Only child and siblings in COVID

capture program drop main 
program define main 

	setup_COVID_A01
	
	*- Clean data *** EDITED
	clean_data
	internet_census
	

end

********************************************************************************
* Setup
********************************************************************************

capture program drop setup_COVID_A01
program define setup_COVID_A01

	*- Define if test run
	global covid_test = 0
	global covid_data = ""
	if ${covid_test} == 1 global covid_data = "_TEST"
	
	*- Only analyze specific outcomes
	global main_outcomes=1
	global main_outcome_1 = "std_gpa_m_adj"
	global main_outcome_2 = "" //pass_math
	global main_outcome_3 = "higher_ed_parent" //higher_ed_parent
	
	global main_loop = 0
	global main_loop_level	= "all"
	global main_loop_only_covid = "all"

	*- Global variables
	global fam_type=2
	global max_sibs = 4
	global x_all = "male_siagie urban_siagie public_siagie"
	global x_nohigher_ed = "male_siagie urban_siagie public_siagie"
	
	
	*- Colorpalette
	colorpalette  HCL blues, selec(1 5 9 11) nograph
	return list

	global blue_1 = "`r(p1)'"
	global blue_2 = "`r(p2)'"
	global blue_3 = "`r(p3)'"
	global blue_4 = "`r(p4)'"
	global blue_5 = "`r(p5)'"
	//local blue_6 = "`r(p6)'"

	//colorpalette  HCL reds, selec(1 4 6 8 10 12) nograph
	colorpalette  HCL reds, selec(2 5 9 11) nograph
	return list

	global red_1 = "`r(p1)'"
	global red_2 = "`r(p2)'"
	global red_3 = "`r(p3)'"	
	global red_4 = "`r(p4)'"
	
	colorpalette  HCL greens, selec(2 5 9 11) nograph
	return list

	global green_1 = "`r(p1)'"
	global green_2 = "`r(p2)'"
	global green_3 = "`r(p3)'"		
	global green_4 = "`r(p4)'"
	
	//Ellsworth Kelly - Blue Green Red - https://www.metmuseum.org/art/collection/search/489307
	global ek_blue 	"21 53 162"
	global ek_green "19 151 65"
	global ek_red	"221 63 15"
	
end

********************************************************************************
* Clean data
********************************************************************************

capture program drop clean_data
program define clean_data
/*
	use id_per_umc dob_siagie using  "$TEMP\siagie_append", clear
	
	*- Has a younger sibling preg/0-2/2-4 years old when Covid academic year starts (04/1/2020)
	gen covid_preg 	= (dob_siagie>=mdy(4, 1, 2020) & dob_siagie<mdy(4, 1, 2021))
	gen covid_0_2 	= (dob_siagie>=mdy(4, 1, 2018) & dob_siagie<mdy(4, 1, 2020))
	gen covid_2_4 	= (dob_siagie>=mdy(4, 1, 2016) & dob_siagie<mdy(4, 1, 2018))
	
	bys id_per_umc
*/	
	use   "$TEMP\siagie_append", clear

	keep id_per_umc  id_ie level grade year section_siagie region_siagie public_siagie urban_siagie male_siagie lives_with_mother lives_with_father approved approved_first std_gpa_m std_gpa_c std_gpa_m_adj std_gpa_c_adj math comm

	preserve
			use "$TEMP\id_siblings", clear
			keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} born* closest_age_gap*${fam_type} covid_preg_sib covid_0_2_sib covid_2_4_sib exp_graduating_year?
			tempfile id_siblings_sample
			save `id_siblings_sample', replace
	restore

	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} born* closest_age_gap*${fam_type} covid_preg_sib covid_0_2_sib covid_2_4_sib exp_graduating_year?) 
	rename _m merge_siblings

	*- Match ECE IDs
	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2p", keep(master match) keepusing(id_estudiante source)
	rename _m merge_2p
	//tab grade merge_2p, row nofreq
	rename (id_estudiante source) (id_estudiante_2p source_2p)

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_4p", keep(master match) keepusing(id_estudiante source)
	rename _m merge_4p
	//tab grade merge_4p, row nofreq
	rename (id_estudiante source) (id_estudiante_4p source_4p)

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_6p", keep(master match) keepusing(id_estudiante source)
	rename _m merge_6p
	//tab grade merge_4p, row nofreq
	rename (id_estudiante source) (id_estudiante_6p source_6p)
	
	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2s", keep(master match) keepusing(id_estudiante source)
	rename _m merge_2s
	//tab grade merge_2s, row nofreq
	rename (id_estudiante source) (id_estudiante_2s source_2s)

	*- Match Baseline ECE exams
	rename year year_siagie

	foreach g in "2p" "4p" /*"6p"*/ "2s" {
		merge m:1 id_estudiante_`g'  using  "$TEMP\ece_`g'", keep(master match) keepusing(year score_math score_com score_math_std score_com_std score_acad_std socioec_index socioec_index_cat label_* urban) //m:1 because there are missings
		rename _m merge_ece_base_`g'
		rename (year score_math score_com score_math_std score_com_std score_acad_std) (year_`g' base_score_math_`g' base_score_com_`g' base_math_std_`g' base_com_std_`g' base_acad_std_`g')
		rename (socioec_index socioec_index_cat) (base_socioec_index_`g' base_socioec_index_cat_`g')
		rename (urban) (base_urban_`g')
		}
		
	foreach g in "2p" "4p" /*"6p"*/ "2s" {	
		if "`g'"!="2s"	merge m:1 id_estudiante_`g'  using "$TEMP\ece_family_`g'", keep(master match) keepusing(aspiration_`g' internet_`g' pc_`g' laptop_`g' radio_`g') //m:1 because there are missings
		if "`g'"=="2s"	merge m:1 id_estudiante_`g'  using "$TEMP\ece_student_`g'", keep(master match) keepusing(aspiration_`g' internet_`g' pc_`g' laptop_`g' radio_`g') //m:1 because there are missings
		rename _m merge_ece_survey_base_`g'
		rename (aspiration_`g' internet_`g' pc_`g' laptop_`g' radio_`g') (base_aspiration_`g' base_internet_`g' base_pc_`g' base_laptop_`g' base_radio_`g')	
		}
		
	rename year_siagie year

	*- Match ECE exams
	foreach g in "2p" "4p" "6p" "2s" {
		foreach v in "score_math" "score_com" "score_math_std" "score_com_std" "score_acad_std" "label_m" "label_c" "socioec_index" "socioec_index_cat" "urban" "spanish" "peso_m" "peso_c" {
			gen `v'_`g' = . 
		} 
	}
	
	foreach g in "2p" "4p" /*"6p"*/ "2s" {
		merge m:1 id_estudiante_`g' year using "$TEMP\ece_`g'", keep(master match) keepusing(score_math score_com score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat urban spanish peso*) //m:1 because there are missings		
		rename _m merge_ece_`g'
		rename peso_l peso_c
		//replace year_`g' = year if year_`g'==.
		replace score_math_`g'			= score_math		if score_math_`g' 		==.
		replace score_com_`g' 			= score_com			if score_com_`g' 		== .
		replace score_math_std_`g' 		= score_math_std 	if score_math_std_`g'	==.
		replace score_com_std_`g' 		= score_com_std 	if score_com_std_`g'	==.
		replace score_acad_std_`g' 		= score_acad_std 	if score_acad_std_`g'	==.
		replace label_m_`g'				= label_m 			if label_m_`g'			==.
		replace label_c_`g'				= label_c 			if label_c_`g'			==.
		replace socioec_index_`g' 		= socioec_index 	if socioec_index_`g' 	==.
		replace socioec_index_cat_`g' 	= socioec_index_cat if socioec_index_cat_`g' ==.
		replace urban_`g' 				= urban 			if urban_`g' ==.
		replace spanish_`g' 			= spanish 			if spanish_`g' ==.
		replace peso_m_`g'				= peso_m			if peso_m_`g'			==.
		replace peso_c_`g'				= peso_c			if peso_c_`g'			==.		
		drop score_math score_com score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat peso_? //year	
	}

	*- Match EM exams
	foreach g in "2p" "4p" "6p" "2s" {
		merge m:1 id_estudiante_`g' year using  "$TEMP\em_`g'", keep(master match) keepusing(score_math score_com score_math_std score_com_std score_acad_std label_m label_c  socioec_index socioec_index_cat urban spanish peso*) //m:1 because there are missings
		rename _m merge_m_`g'
		rename peso_l peso_c
		//replace year_`g' = year if year_`g'==.
		replace score_math_`g'			= score_math		if score_math_`g' 		==.
		replace score_com_`g' 			= score_com			if score_com_`g' 		== .
		replace score_math_std_`g' 		= score_math_std 	if score_math_std_`g'	==.
		replace score_com_std_`g' 		= score_com_std 	if score_com_std_`g'	==.
		replace score_acad_std_`g' 		= score_acad_std 	if score_acad_std_`g'	==.
		replace label_m_`g'				= label_m 			if label_m_`g'			==.
		replace label_c_`g'				= label_c 			if label_c_`g'			==.
		replace socioec_index_`g' 		= socioec_index 	if socioec_index_`g' 	==.
		replace socioec_index_cat_`g' 	= socioec_index_cat if socioec_index_cat_`g' ==.
		replace urban_`g' 				= urban 			if urban_`g' ==.
		replace spanish_`g' 			= spanish 			if spanish_`g' ==.
		replace peso_m_`g'				= peso_m			if peso_m_`g'			==.
		replace peso_c_`g'				= peso_c			if peso_c_`g'			==.
		drop score_math score_com score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat peso_? //year	
	}

	*- Match ECE survey
	merge m:1 id_estudiante_2p year using "$TEMP\ece_family_2p", keep(master match) keepusing(aspiration_2p internet_2p pc_2p laptop_2p radio_2p) //m:1 because there are missings
	rename _m merge_ece_survey_fam_2p
	rename aspiration_2p aspiration_fam_2p
	
	merge m:1 id_estudiante_4p year using "$TEMP\ece_family_4p", keep(master match) keepusing(aspiration_4p gender_subj_?_4p internet_4p pc_4p laptop_4p radio_4p study_desk_4p quiet_room_4p pc_hw_4p) //m:1 because there are missings
	rename _m merge_ece_survey_fam_4p
	rename aspiration_4p aspiration_fam_4p
	
	merge m:1 id_estudiante_6p year using "$TEMP\ece_family_6p", keep(master match) keepusing(aspiration_6p gender_subj_?_6p) //m:1 because there are missings
	rename _m merge_ece_survey_fam_6p	
	rename aspiration_6p aspiration_fam_6p
	
	merge m:1 id_estudiante_6p year using "$TEMP\ece_student_6p", keep(master match) keepusing(aspiration_6p) //m:1 because there are missings
	rename _m merge_ece_survey_stud_6p	
	rename aspiration_6p aspiration_stu_6p	
	
	merge m:1 id_estudiante_2s year using "$TEMP\ece_student_2s", keep(master match) keepusing(aspiration_2s lives_with_*_2s total_siblings_2s pc_2s internet_2s laptop_2s radio_2s) //m:1 because there are missings
	rename _m merge_ece_survey_stud_2s
	rename aspiration_2s aspiration_stu_2s
		
	drop id_estudiante_2p source_2p merge_2p id_estudiante_4p source_4p merge_4p id_estudiante_6p source_6p merge_6p id_estudiante_2s source_2s merge_2s merge_ece_?? merge_m_?? merge_ece_survey_*

	*- Other potential treatment variables
	gen t_born = .
	gen t_born_Q2 = .
	forvalues y = 2014(1)2023 {
		local next_y = `y' + 1
		replace t_born = 1 		if born_`y'==1 			& year==`y'
		replace t_born = 0 		if born_`next_y'==1 	& year==`y'
		replace t_born_Q2 = 1 	if born_`y'_Q2==1 		& year==`y'
		replace t_born_Q2 = 0 	if born_`next_y'_Q2==1 	& year==`y'
	}
	

	*- Define additional outcomes:
	
	*-- Completed Primary on time
	bys id_per_umc: egen year_graduating_prim_1 = min(cond(grade>=7,year,.))
	bys id_per_umc: egen year_graduating_prim_2 = min(cond(grade==6 & approved,year,.))
	gen year_graduating_prim = min(year_graduating_prim_1-1,year_graduating_prim_2)
	drop year_graduating_prim_?
	gen prim_on_time = (year_graduating_prim<=(exp_graduating_year2-5)) if  (exp_graduating_year2-5<=2024) & (exp_graduating_year2-5)<=year
	

	*-- Satisfactory level in ECE
	foreach g in "2p" "4p" "6p" "2s" {
		gen satisf_m_`g' = label_m_`g'==4 if label_m_`g'!=.
		gen satisf_c_`g' = label_c_`g'==4 if label_c_`g'!=.
		}
		
	*-- Baseline Resources/SES
	foreach g in "2p" "4p" "2s" {
		//We used family before, but OC have no siblings so better to have a comparable sample.
		bys id_per_umc: egen has_internet_`g' = max(cond(year<=2019,internet_`g',.)) 	
		bys id_per_umc: egen has_pc_`g' = max(cond(year<=2019,pc_`g',.)) 	
		bys id_per_umc: egen has_laptop_`g' = max(cond(year<=2019,laptop_`g',.)) 	
		bys id_per_umc: egen is_low_ses_`g' = min(cond(year<=2019,socioec_index_cat_`g',.)) 	
		}

	bys id_per_umc: egen quiet_room = min(cond(year<=2019,quiet_room_4p,.)) 

	egen has_internet 	= rmax(has_internet_2p has_internet_4p) if has_internet_2p!=. | has_internet_4p!=.
	egen has_comp 		= rmax(has_pc_2p has_laptop_2p has_pc_4p has_laptop_4p) if has_pc_2p!=. | has_laptop_2p!=. | has_pc_4p!=. | has_laptop_4p!=.
	egen low_ses 		= rmin(is_low_ses_2p is_low_ses_4p) if is_low_ses_2p!=. | is_low_ses_4p!=.
	
	*-- Overall Resources/SES (more sample but endogenous)
	foreach g in "2p" "4p" "2s" {
		//We used family before, but OC have no siblings so better to have a comparable sample.
		bys id_per_umc: egen full_has_internet_`g' = max(cond(internet_`g'!=.,internet_`g',.)) 	
		bys id_per_umc: egen full_has_pc_`g' = max(cond(pc_`g'!=.,pc_`g',.)) 	
		bys id_per_umc: egen full_has_laptop_`g' = max(cond(laptop_`g'!=.,laptop_`g',.)) 	
		bys id_per_umc: egen full_is_low_ses_`g' = min(cond(socioec_index_cat_`g'!=.,socioec_index_cat_`g',.)) 		
		}

	bys id_per_umc: egen full_quiet_room = min(cond(quiet_room_4p!=.,quiet_room_4p,.)) 

	egen full_has_internet 	= rmax(full_has_internet_2p full_has_internet_4p full_has_internet_2s) 													if full_has_internet_2p!=. 	| full_has_internet_4p!=. | full_has_internet_2s!=.
	egen full_has_comp 		= rmax(full_has_pc_2p 		full_has_laptop_2p full_has_pc_4p full_has_laptop_4p full_has_pc_2s full_has_laptop_2s) 	if full_has_pc_2p!=. 		| full_has_laptop_2p!=. | full_has_pc_4p!=. | full_has_laptop_4p!=. | full_has_pc_2s!=. | full_has_laptop_2s!=.
	egen full_low_ses 		= rmin(full_is_low_ses_2p 	full_is_low_ses_4p full_is_low_ses_2s) 																		if full_is_low_ses_2p!=. 	| full_is_low_ses_4p!=.	
	
	*- School average SES - Quartiles
	merge m:1 id_ie using "$TEMP\school_SES", keepusing(socioec_index_ie_cat)
	bys id_per_umc: egen min_socioec_index_ie_cat=min(socioec_index_ie_cat)
	drop socioec_index_ie_cat
	
	*- School average enrollment
	bys id_ie grade year	: gen 	enrollment_grade_year=_N
	bys id_ie grade year section_siagie	: gen 	enrollment_class_grade_year=_N
	bys id_ie							: egen 	grade_size_average=mean(enrollment_grade_year)
	bys id_ie							: egen 	class_size_average=mean(enrollment_class_grade_year)
	
	tabstat grade_size_average, by(grade)
	tabstat class_size_average, by(grade)
	
	foreach unit in "class" "grade" {
		gen quart_`unit'_size = .
		_pctile `unit'_size_average if grade>=1 & grade <=6, p(25 50 75)
		//sum `unit'_size_average if grade>=1 & grade <=6, de
		replace quart_`unit'_size = 1 if `unit'_size_average<=r(r1) 							& grade>=1 & grade <=6
		replace quart_`unit'_size = 2 if `unit'_size_average>r(r1) & `unit'_size_average<=r(r2) & grade>=1 & grade <=6
		replace quart_`unit'_size = 3 if `unit'_size_average>r(r2) & `unit'_size_average<=r(r3) & grade>=1 & grade <=6
		replace quart_`unit'_size = 4 if `unit'_size_average>r(r3) & `unit'_size_average!=. 	& grade>=1 & grade <=6
		
		_pctile `unit'_size_average if grade>=7, p(25 50 75)
		replace quart_`unit'_size = 1 if `unit'_size_average<=r(r1) 							& grade>=7
		replace quart_`unit'_size = 2 if `unit'_size_average>r(r1) & `unit'_size_average<=r(r2) & grade>=7
		replace quart_`unit'_size = 3 if `unit'_size_average>r(r2) & `unit'_size_average<=r(r3) & grade>=7
		replace quart_`unit'_size = 4 if `unit'_size_average>r(r3) & `unit'_size_average!=. 	& grade>=7
		
		label var quart_`unit'_size "School by quartiles `unit' size (1=Q1, 4=Q4)"
		}
	/*
	bys id_ie: egen min_grade = min(grade)
	bys id_ie: egen max_grade = max(grade)
	
	tab min_grade max_grade
	*/

	
	*- Census 2017 characteristics:
	// Match INTERNET/ELECTRICITY Penetration
	

	//rename quiet_room_4p quiet_room
	
	drop if grade==0	

	
	describe
	compress

	save "$TEMP\long_siagie_ece", replace



	*- Check how many years of data each school has (to use comparable samples)
	use id_ie year grade score_math_?? score_com_?? score_*_std_?? approved approved_first std_gpa_? std_gpa_?_adj math comm peso* using "$TEMP\long_siagie_ece", clear

		collapse  score_math_?? score_com_?? score_*_std_?? approved approved_first std_gpa_? std_gpa_?_adj math comm peso*, by(id_ie year)

		foreach v of var  score_math_?? score_com_?? score_*_std_?? approved approved_first std_gpa_? std_gpa_?_adj math comm peso* {
			bys id_ie: egen  `v'_min =  min(cond( `v'!=.,year,.))
			bys id_ie: egen  `v'_max =  max(cond( `v'!=.,year,.))
			bys id_ie: egen  `v'_sum =  sum(cond( `v'!=.,1,0))
			}
			
		collapse *min *max *sum, by(id_ie)
		
		compress
		
	save "$TEMP\siagie_ece_ie_obs", replace	


	*- Create Event Study vars	
	use 	///
		id_per_umc id_ie grade year ///
		fam_order_${fam_type} fam_total_${fam_type} ///
		male_siagie public_siagie urban_siagie min_socioec_index_ie_cat educ_mother educ_father lives_with_mother lives_with_father ///
		quart_* grade_size* class_size* closest_age_gap*${fam_type} base* ///
		covid_preg_sib covid_0_2_sib covid_2_4_sib t_born*  ///
		year_2p year_4p year_2s peso*  socioec* *has_internet *has_comp *low_ses *quiet_room ///
		approved* std* math comm score* satisf* prim_on_time aspiration* ///
		using "$TEMP\long_siagie_ece", clear

		keep if fam_total_${fam_type}<=${max_sibs}
		
		gen treated = fam_total_${fam_type}>1

		gen post = year>=2020
		gen treated_post = treated*post
		
		*- Parent's education
		*-- Higher Ed parents
		gen byte higher_ed_mother 		= inlist(educ_mother,7,8) if educ_mother!=. & educ_mother!=1
		gen byte higher_ed_father 		= inlist(educ_father,7,8) if educ_father!=. & educ_father!=1
		//drop educ_mother educ_father
		gen byte higher_ed_parent		= (higher_ed_mother==1 | higher_ed_father==1) if higher_ed_mother!=. | higher_ed_father!=.
		drop higher_ed_mother higher_ed_father
		
		*-- Mother's education
		gen educ_cat_mother = 1 if inlist(educ_mother,2,3,4)==1
		replace educ_cat_mother = 2 if inlist(educ_mother,5)==1
		replace educ_cat_mother = 3 if inlist(educ_mother,6,7,8)==1
		label define educ_cat_mother 1 "Did not complete secondary education" 2 "Completed secondary education" 3 "Some level of higher education"
		label values educ_cat_mother 
		
		*-- Father's education
		gen educ_cat_father = 1 if inlist(educ_father,2,3,4)==1
		replace educ_cat_father = 2 if inlist(educ_father,5)==1
		replace educ_cat_father = 3 if inlist(educ_father,6,7,8)==1
		label define educ_cat_father 1 "Did not complete secondary education" 2 "Completed secondary education" 3 "Some level of higher education"
		label values educ_cat_father 		
		
		//gen lives_parents = .
		//replace lives_parents = 0 if lives_with_mother==0 & lives_with_father==0
		//gen dif_caretaker = 0 if id_caretaker!=""
		
		*- Standardize ECE scores based on reference year (2007 for 2P and 2013 for the rest. Those are the years with 500 mean and 100 SD). This as opposed to yearly standardization.
		foreach g in "2p" "4p" "2s" {
			//replace score_math_`g' = (score_math_`g'-500)/100
			//replace score_com_`g' = (score_com_`g'-500)/100
		}
		
		*- Passed Math and Reading
		gen letter = 0
		replace letter = 1 if grade<=6 
		replace letter = 1 if grade==7 & year>=2019
		replace letter = 1 if grade==8 & year>=2020
		replace letter = 1 if grade==9 & year>=2021
		replace letter = 1 if grade==10 & year>=2022
		replace letter = 1 if grade==11 & year>=2023
		
		local fail_letter = 2 //2=B, they need to get an A, otherwise they either fail or need to take extra classes?
		local fail_number = 13 //
		
		gen byte pass_math = 1 if math!=.	
		replace pass_math = 0 if math<=`fail_letter' & math!=. & letter==1
		replace pass_math = 0 if math<=`fail_number' & math!=. & letter==0
		
		gen byte pass_read = 1 if comm!=.
		replace pass_read = 0 if comm<=`fail_letter' & comm!=. & letter==1
		replace pass_read = 0 if comm<=`fail_number' & comm!=. & letter==0
		
		*- Fix weights for census examinations
		replace peso_m_4p = 1 if inlist(year,2016,2018,2024)==1 & grade==4 & peso_m_4p==.
		replace peso_c_4p = 1 if inlist(year,2016,2018,2024)==1 & grade==4 & peso_c_4p==.
		replace peso_m_2s = 1 if inlist(year,2015,2016,2018,2019)==1 & grade==8 & peso_m_2s==.
		replace peso_c_2s = 1 if inlist(year,2015,2016,2018,2019)==1 & grade==8 & peso_c_2s==.		
		
		*- Events
		ds urban_siagie higher_ed_parent

		local suf_2014 = "b6"
		local suf_2015 = "b5"
		local suf_2016 = "b4"
		local suf_2017 = "b3"
		local suf_2018 = "b2"
		local suf_2019 = "o1"
		local suf_2020 = "a0"
		local suf_2021 = "a1"
		local suf_2022 = "a2"
		local suf_2023 = "a3"
		local suf_2024 = "a4"

		forvalues y = 2014(1)2024 {
			gen byte year_`suf_`y'' = year==`y'
			gen byte year_t_`suf_`y'' = year_`suf_`y''*treated
		}




		reghdfe score_acad_std_2s treated_post treated post , a(year grade)

		bys id_per_umc: egen first_year = min(year)
		bys id_per_umc: egen last_year = max(year)
		compress
		save "$TEMP\pre_reg_covid", replace

		if ${covid_test}==1  {
			use "$TEMP\pre_reg_covid", clear

			bys id_ie: egen u = max(cond(_n==1,runiform(),.))
			keep if u <0.1

			save "$TEMP\pre_reg_covid_TEST", replace
		}
	
end

********************************************************************************
* Intenet schools
********************************************************************************
capture program drop internet_census
program define internet_census
		

import dbase "$IN\MINEDU\census\2019\local_lineal.dbf", clear
	rename *, lower
	rename p702 internet 
	destring internet, replace
	recode internet (2 = 0)
	tab internet 
	keep  codlocal internet
tempfile internet
save `internet', replace

import dbase using "$IN/MINEDU/Padron/Padron_web.dbf", clear
	rename *, lower	
	gen id_ie = cod_mod + anexo
	keep id_ie codlocal talumno tdocente
	order id?ie codlocal talumno tdocente
tempfile codlocal
save `codlocal', replace

merge m:1 codlocal using `internet', keep(master match)
keep if _m==3
drop _m

save "$TEMP\school_internet", replace



end






//main
