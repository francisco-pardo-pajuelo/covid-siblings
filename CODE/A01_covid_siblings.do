*- Only child and siblings in COVID

capture program drop main 
program define main 

	setup_COVID
	
	clean_data
	
	internet_census
	
	*DOB_scatter
	
	*raw_ece_trends
	raw_gpa_trends siblings
	raw_gpa_trends urban
	raw_gpa_trends ses
	raw_gpa_trends internet
	raw_gpa_trends parent_ed
	raw_gpa_trends both_parents
	raw_gpa_trends t_born
	raw_gpa_trends t_born_Q2
	*raw_histograms
	
	//ece_baseline_netherlands
	
	twfe_summary
	twfe_A //School characteristics
	twfe_B //Student demographics - gender and age
	twfe_C //Family Structure - Siblings
	twfe_D //Family Structure - Parents
	
						//twfe_cohorts //Should not be done as it does not address the age trend.
	twfe_grades
	twfe_survey
	
	event_ece_student
	event_ece_school
	event_gpa
	//event_approved
					//event_cohort_grade //Should not be done as it does not address the age trend.
	event_cohort_grade
	
end

********************************************************************************
* Setup
********************************************************************************

capture program drop setup_COVID
program define setup_COVID

	global covid_test = 0
	global covid_data = ""
	if ${covid_test} == 1 global covid_data = "_TEST"

	global fam_type=2
	
	global max_sibs = 4

	global x_all = "male_siagie urban_siagie public_siagie"
	global x_nohigher_ed = "male_siagie urban_siagie public_siagie"
	
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
	merge m:1 id_estudiante_2p  using  "$TEMP\ece_2p", keep(master match) keepusing(year score_math score_com score_math_std score_com_std score_acad_std socioec_index socioec_index_cat label_* urban) //m:1 because there are missings
	rename _m merge_ece_baseline_2p
	rename (year score_math score_com score_math_std score_com_std score_acad_std) (year_2p base_score_math_2p base_score_com_2p base_math_std_2p base_com_std_2p base_acad_std_2p)
	rename (socioec_index socioec_index_cat) (base_socioec_index_2p base_socioec_index_cat_2p)
	rename (urban) (base_urban_2p)
	rename year_siagie year

	*- Match ECE exams
	foreach g in "2p" "4p" "6p" "2s" {
		foreach v in "score_math" "score_com" "score_math_std" "score_com_std" "score_acad_std" "label_m" "label_c" "socioec_index" "socioec_index_cat" "peso_m" "peso_c" {
			gen `v'_`g' = . 
		} 
	}
	
	foreach g in "2p" "4p" /*"6p"*/ "2s" {
		merge m:1 id_estudiante_`g' year using "$TEMP\ece_`g'", keep(master match) keepusing(score_math score_com score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat peso*) //m:1 because there are missings		
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
		replace peso_m_`g'				= peso_m			if peso_m_`g'			==.
		replace peso_c_`g'				= peso_c			if peso_c_`g'			==.		
		drop score_math score_com score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat peso_? //year	
	}

	*- Match EM exams
	foreach g in "2p" "4p" "6p" "2s" {
		merge m:1 id_estudiante_`g' year using  "$TEMP\em_`g'", keep(master match) keepusing(score_math score_com score_math_std score_com_std score_acad_std label_m label_c  socioec_index socioec_index_cat peso*) //m:1 because there are missings
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
		year_2p peso*  socioec* *has_internet *has_comp *low_ses *quiet_room ///
		approved* std* math comm score* satisf* prim_on_time ///
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




********************************************************************************
* RAW TRENDS
********************************************************************************
capture program drop raw_ece_trends
program define raw_ece_trends

use "$TEMP\pre_reg_covid${covid_data}", clear


	global g2lab = "2p" 
	global g4lab = "4p" 
	global g6lab = "6p" 
	global g8lab = "2s" 
	
	global g2tit = "2nd grade" 
	global g4tit = "4th grade" 
	global g6tit = "6th grade" 
	global g8tit = "8th grade" 	
	
	
	

	keep fam_total_${fam_type} grade year score_*_??  peso_?_?? id_ie
	keep if inlist(grade,2,4,8)==1

	/*
	replace peso_m_4p = 1 if inlist(year,2016,2018,2024)==1 & grade==4 & peso_m_4p==.
	replace peso_c_4p = 1 if inlist(year,2016,2018,2024)==1 & grade==4 & peso_c_4p==.
	replace peso_m_2s = 1 if inlist(year,2015,2016,2018,2019)==1 & grade==8 & peso_m_2s==.
	replace peso_c_2s = 1 if inlist(year,2015,2016,2018,2019)==1 & grade==8 & peso_c_2s==.
	*/
	
	//keep if year<=2016 | year==2019
	//bys id_ie year: gen n=_n==1
	//bys id_ie : egen N=sum(n)


	
/*
	open
	local subj = `com'
	keep if score_`subj'_${g`g'lab}!=.
	keep if N==4
	collapse score_`subj'_${g`g'lab}, by(year id_ie) 
	list 

	open
	keep if N==4
	collapse score_math_${g`g'lab}, by(year) 
	list 
	 
	open
	keep if N==4
	collapse score_math_${g`g'lab} [iw=peso_m_${g`g'lab}], by(year) 
	list
*/

	
	
	
	foreach g in 2 4 8 {
		global g = `g'
		foreach subj in "com" "math" {
		preserve
			keep if inlist(grade,${g})==1
			
			keep if score_`subj'_${g${g}lab}!=.
			keep if year!=2020
			gen score_${g${g}lab} = (score_`subj'_${g${g}lab}-500)/100

			gen pop = 1 
			gen sibs = (fam_total_${fam_type}>=2)
			collapse (sum) pop (mean) score_${g${g}lab} [iw=peso_m_${g${g}lab}], by(year sibs) 
			twoway 	(line score_${g${g}lab} year if sibs==0 & year<=2019, lcolor("${red_1}")) 	///
					(line score_${g${g}lab} year if sibs==1 & year<=2019, lcolor("${blue_1}"))	///
					(line score_${g${g}lab} year if sibs==0 & year>=2020, lcolor("${red_1}")) 	///
					(line score_${g${g}lab} year if sibs==1 & year>=2020, lcolor("${blue_1}"))	///
					, ///
					xlabel(2014(1)2024) ///
					xtitle("Year") ///
					ytitle("${g${g}tit} standardize exam score") ///
					legend(order(1 "Only Childs" 2 "Children with Siblings") pos(6) col(2))

			capture qui graph export "$FIGURES\Descriptive\raw_ece_`subj'_`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\raw_ece_`subj'_`g'${covid_data}.pdf", replace		
			
			twoway 	(line pop year if sibs==0 & year<=2019, lcolor("${red_1}")) 	///
					(line pop year if sibs==1 & year<=2019, lcolor("${blue_1}"))	///
					(line pop year if sibs==0 & year>=2020, lcolor("${red_1}")) 	///
					(line pop year if sibs==1 & year>=2020, lcolor("${blue_1}"))	///
					, ///
					xlabel(2014(1)2024) ///
					xtitle("Year") ///
					ytitle("${g${g}tit} standardize exam population") /// 
					legend(order(1 "Only Childs" 2 "Children with Siblings") pos(6) col(2))				
					
			capture qui graph export "$FIGURES\Descriptive\raw_ece_pop_`subj'_`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\raw_ece_pop_`subj'_`g'${covid_data}.pdf", replace				

			bys year (sibs): gen score = score_${g${g}lab} - score_${g${g}lab}[1]		
			twoway 	(line score year if sibs==0 & year<=2019, lcolor("${red_1}")) 	///
					(line score year if sibs==1 & year<=2019, lcolor("${blue_1}"))	///
					(line score year if sibs==0 & year>=2020, lcolor("${red_1}")) 	///
					(line score year if sibs==1 & year>=2020, lcolor("${blue_1}"))	///
					, ///
					xlabel(2014(1)2024) ///
					xtitle("Year") ///
					ytitle("${g${g}tit} standardize exam score relative to only childs") /// 
					legend(order(1 "Only Childs" 2 "Children with Siblings") pos(6) col(2))
			capture qui graph export "$FIGURES\Descriptive\raw_ece_rel_`subj'_`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\raw_ece_rel_`subj'_`g'${covid_data}.pdf", replace		
		restore
		}
	}
	

end








capture program drop raw_gpa_trends
program define raw_gpa_trends

args type

	*- Primary letters
	*- Secondary numbers
	*- But secondary changed to letters starting with cohort 2013 (7th grade in 2019)
	
	local ytitle_std_gpa_m 		= "Standardized GPA"		
	local ytitle_std_gpa_c 		= "Standardized GPA"			
	local ytitle_std_gpa_m_adj 	= "Standardized GPA (adj)"		
	local ytitle_std_gpa_c_adj 	= "Standardized GPA (adj)"		
	local ytitle_pass_math = "Passed GPA"		
	local ytitle_pass_read = "Passed GPA"	
	
	local g1 "1st"
	local g2 "2nd"
	local g3 "3rd"
	local g4 "4th"
	local g5 "5th"
	local g6 "6th"
	local g7 "7th"
	local g8 "8th"
	local g9 "9th"
	local g10 "10th"
	local g11 "11th"

	use id_ie std_gpa_?* pass_math pass_read prim_on_time id_per_umc year grade treated min_socioec_index_ie_cat urban_siagie educ_cat_mother lives_with_mother lives_with_father t_born* fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid${covid_data}", clear
	
	*- School has internet
	merge m:1 id_ie using "$TEMP\school_internet", keepusing(codlocal internet) keep(master match)
	
	if "`type'"=="siblings" {
		di "Continue, since treated is already defined as having siblings"
		local lab_control = "Only childs"
		local lab_treated = "Children with siblings"
	}
	if "`type'"=="urban" {
		drop treated
		gen treated = urban_siagie==1
		local lab_control = "Rural"
		local lab_treated = "Urban"
	}
	if "`type'"=="ses" {
		drop treated
		gen treated = inlist(min_socioec_index_ie_cat,3,4)==1 if min_socioec_index_ie_cat<=4
		local lab_control = "Low SES"
		local lab_treated = "High SES"
	}
	
	if "`type'"=="internet" {
		drop treated
		gen treated = internet==1
		local lab_control = "No Internet"
		local lab_treated = "Internet"
	}	
	
	if "`type'"=="parent_ed" {
		drop treated
		gen treated = (educ_cat_mother==3)
		local lab_control = "Mother no higher ed."
		local lab_treated = "Mother some higher ed."
	}
	
	if "`type'"=="both_parents" {
		drop treated
		gen treated = (lives_with_mother==1 & lives_with_father==1)
		local lab_control = "Does not live with both"
		local lab_treated = "Lives with both parents"
	}	
	
	if "`type'" == "t_born" {
		drop treated
		gen treated = (t_born)
		local lab_control = "Sibling born during same year"
		local lab_treated = "Sibling born next year"
	}
	
	if "`type'" == "t_born_Q2" {
		drop treated
		gen treated = (t_born_Q2)
		local lab_control = "Sibling born during same year (Q2)"
		local lab_treated = "Sibling born next year (Q2)"
	}	
		
	*- Remove early grades and years
	keep if year>=2014
	drop if grade==0	

	*- Divide sample based on expected cohort
	bys id_per_umc: egen min_year 		= min(year)
	bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
	gen proxy_1st = min_year - grade_min_year  + 1
	
	*- Collapse data
	foreach level in "all" "elm" "sec" {
	preserve 	
		if "`level'" == "elm" keep if grade>=1 & grade<=6
		if "`level'" == "sec" keep if grade>=7
		
		collapse std_gpa_m std_gpa_c std_gpa_m_adj std_gpa_c_adj pass_math pass_read prim_on_time, by(year treated)
		
		gen areax = 2019.5 if mod(_n,2)==0
		replace areax = 2021.5 if mod(_n,2)==1
		
		foreach v in /*"std_gpa_m" "std_gpa_c"*/ "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" "prim_on_time" {
			if inlist("`type'","siblings","parent_ed","both_parents","t_born","t_born_Q2")==0 & inlist("`v'","std_gpa_m","std_gpa_c","std_gpa_m_adj","std_gpa_c_adj")==1 continue
			sum `v' 
			gen miny = r(min)
			gen maxy = r(max)
			
			twoway 		///(rarea miny maxy areax if inrange(areax, 2019.5, 2021.5), color(gs15)) ///
						(line `v' year if treated==0 & year<=2019, lcolor("${red_3}")) /// 
						(line `v' year if treated==0 & year>=2020, lcolor("${red_1}")) /// 
						(line `v' year if treated==1 & year<=2019, lcolor("${blue_3}")) ///
						(line `v' year if treated==1 & year>=2020, lcolor("${blue_1}")) ///
						, ///
						xline(2019.5 2021.5, lcolor(gs8)) ///
						xlabel(2014 "14" 2015 "15" 2016 "16" 2017 "17" 2018 "18" 2019 "19" 2020 "20" 2021 "21" 2022 "22" 2023 "23" 2024 "24")  ///
						ytitle("`ytitle_`v''", size(small)) ///
						xtitle("Year") ///
						///legend(off) ///
						legend(order(2 "`lab_control'" 4 "`lab_treated'") col(3) pos(6)) ///
						name(total_`v', replace)	
					if "`type'" == "siblings" {	
						capture qui graph export "$FIGURES\Descriptive\raw_total_`level'_`v'_`type'${covid_data}.png", replace			
						capture qui graph export "$FIGURES\Descriptive\raw_total_`level'_`v'_`type'${covid_data}.pdf", replace	
					}
					if "`type'" != "siblings" {	
						capture qui graph export "$FIGURES_TEMP\Descriptive\raw_total_`level'_`v'_`type'${covid_data}.png", replace			
						capture qui graph export "$FIGURES_TEMP\Descriptive\raw_total_`level'_`v'_`type'${covid_data}.pdf", replace	
					}
						
			drop miny maxy
				}	
	restore
	}
	/*
	preserve
		collapse std_gpa_m std_gpa_c std_gpa_m_adj std_gpa_c_adj pass_math pass_read, by(year proxy_1st treated)
		
		foreach v of var std_gpa_? pass_math pass_read {
			replace `v' = . if proxy_1st == 2008 & year>=2019 //Should be 2021 but there are no grades for 2020 for 11th which is the on time grade for cohort 2010, so all left are delayed students
			replace `v' = . if proxy_1st == 2009 & year>=2020 //Should be 2021 but there are no grades for 2020 for 11th which is the on time grade for cohort 2010, so all left are delayed students
			replace `v' = . if proxy_1st == 2010 & year>=2020 //Should be 2021 but there are no grades for 2020 for 11th which is the on time grade for cohort 2010, so all left are delayed students
			replace `v' = . if proxy_1st == 2011 & year>=2022
			replace `v' = . if proxy_1st == 2012 & year>=2023
			replace `v' = . if proxy_1st == 2013 & year>=2024
		}
		
		*- All individual plots	
		
		gen areax = 2019.5 if mod(_n,2)==0
		replace areax = 2021.5 if mod(_n,2)==1
		
		forvalues y = 2008(1)2018 {
			foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" {
				sum `v' if proxy_1st>=2008 & proxy_1st<=2018 & `v'!=. & year>=2014 & year<=2024
				gen miny = r(min)
				gen maxy = r(max)
				twoway 	(rarea miny maxy areax if inrange(areax, 2019.5, 2021.5), color(gs15)) ///
						(line `v' year if proxy_1st == `y' & treated==0 & year<=2019, lcolor("${red_1}")) /// 
						(line `v' year if proxy_1st == `y' & treated==0 & year>=2020, lcolor("${red_1}")) /// 
						(line `v' year if proxy_1st == `y' & treated==1 & year<=2019, lcolor("${blue_1}")) ///
						(line `v' year if proxy_1st == `y' & treated==1 & year>=2020, lcolor("${blue_1}")) ///
						, ///
						xline(2019.5) ///
						xlabel(2014 "14" 2015 "15" 2016 "16" 2017 "17" 2018 "18" 2019 "19" 2020 "20" 2021 "21" 2022 "22" 2023 "23" 2024 "24")  ///
						ytitle("`ytitle_`v''", size(small)) ///
						xtitle("Year") ///
						subtitle("`y' cohort") ///
						legend(off) ///
						///legend(order(1 "Only childs" 3 "Children with siblings") col(3) pos(6)) ///
						name(`v'_`y', replace)	
				drop miny maxy
					}
				}
		
		foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" {
		graph combine   `v'_2010 	///
						`v'_2011 `v'_2012 	///
						`v'_2013 `v'_2014 	///
						`v'_2015 `v'_2016 	///
						`v'_2017 `v'_2018 	///
						, 				///
						col(3) ///
						xsize(40) ///
						ysize(30) 
						
			///graph save "$FIGURES\raw_m.gph" , replace	
			///capture qui graph export "$FIGURES\raw_m.eps", replace	
			capture qui graph export "$FIGURES\Descriptive\raw_cohorts_`v'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\raw_cohorts_`v'${covid_data}.pdf", replace	
		}	
	restore
	*/
	
	preserve
		collapse std_gpa_m std_gpa_c std_gpa_m_adj std_gpa_c_adj pass_math pass_read prim_on_time, by(year grade treated)
		
		/*
		foreach v of var std_gpa_? pass_math pass_read {
			replace `v' = . if proxy_1st == 2008 & year>=2019 
			replace `v' = . if proxy_1st == 2009 & year>=2020 
			replace `v' = . if proxy_1st == 2010 & year>=2020 
			replace `v' = . if proxy_1st == 2011 & year>=2022
			replace `v' = . if proxy_1st == 2012 & year>=2023
		}
		*/
		
		*- All individual plots	
		
		gen areax = 2019.5 if mod(_n,2)==0
		replace areax = 2021.5 if mod(_n,2)==1
		
		forvalues g = 1(1)11 {
			foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" "prim_on_time" {
				if inlist("`type'","siblings","parent_ed","both_parents")==0 & inlist("`v'","std_gpa_m","std_gpa_c","std_gpa_m_adj","std_gpa_c_adj")==1 continue
				sum `v' if grade>=1 & grade<=11 & `v'!=. & year>=2014 & year<=2024
				gen miny = r(min)
				gen maxy = r(max)
				twoway 	///(rarea miny maxy areax if inrange(areax, 2019.5, 2021.5), color(gs15)) ///
						(line `v' year if grade == `g' & treated==0 & year<=2019, lcolor("${red_1}")) /// 
						(line `v' year if grade == `g' & treated==0 & year>=2020, lcolor("${red_1}")) /// 
						(line `v' year if grade == `g' & treated==1 & year<=2019, lcolor("${blue_1}")) ///
						(line `v' year if grade == `g' & treated==1 & year>=2020, lcolor("${blue_1}")) ///
						, ///
						xline(2019.5 2021.5, lcolor(gs8)) ///
						xlabel(2014 "14" 2015 "15" 2016 "16" 2017 "17" 2018 "18" 2019 "19" 2020 "20" 2021 "21" 2022 "22" 2023 "23" 2024 "24")  ///
						ytitle("`ytitle_`v''", size(small)) ///
						xtitle("Year") ///
						subtitle("`g`g'' grade") ///
						legend(off) ///
						///legend(order(1 "Only childs" 3 "Children with siblings") col(3) pos(6)) ///
						name(`v'_`g', replace)	
				drop miny maxy
					}
				}
		
		foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" "prim_on_time" {
			if inlist("`type'","siblings","parent_ed","both_parents")==0 & inlist("`v'","std_gpa_m","std_gpa_c","std_gpa_m_adj","std_gpa_c_adj")==1 continue
			graph combine   `v'_1 	///
							`v'_2 `v'_3 	///
							`v'_4 `v'_5 	///
							`v'_6 `v'_7 	///
							`v'_8 `v'_9 	///
							`v'_10 `v'_11 	///
							, 				///
							col(3) ///
							xsize(40) ///
							ysize(40) 
							
				///graph save "$FIGURES\raw_m.gph" , replace	
				///capture qui graph export "$FIGURES\raw_m.eps", replace	
				if "`type'" == "siblings" {
					capture qui graph export "$FIGURES\Descriptive\raw_grades_`v'_`type'${covid_data}.png", replace			
					capture qui graph export "$FIGURES\Descriptive\raw_grades_`v'_`type'${covid_data}.pdf", replace	
					}
					
				if "`type'" != "siblings" {
					capture qui graph export "$FIGURES_TEMP\Descriptive\raw_grades_`v'_`type'${covid_data}.png", replace			
					capture qui graph export "$FIGURES_TEMP\Descriptive\raw_grades_`v'_`type'${covid_data}.pdf", replace	
					}				
			}
			
	restore
		
end


********************************************************************************
* Grade distributions
********************************************************************************

capture program drop raw_histograms
program define raw_histograms	

	use std_gpa_? math comm pass_math pass_read id_per_umc year grade treated fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid${covid_data}", clear
	
	*- Aggregate: Elementary
	twoway 	(histogram math if inlist(grade,1,2,3,4,5,6)==1 & (inlist(year,2019)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
			(histogram math if inlist(grade,1,2,3,4,5,6)==1 & (inlist(year,2019)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
			, ///
			/// legend(order(1 "No siblings" 2 "1 sibling" 3 "2 siblings" 4 "3 siblings") pos(6) col(4))
			legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
			xtitle("Mathematics grade") ///
			xlabel(1 "D" 2 "C" 3 "B" 4 "A")
	capture qui graph export "$FIGURES\Descriptive\histogram_pre_elm${covid_data}.png", replace			
	capture qui graph export "$FIGURES\Descriptive\histogram_pre_elm${covid_data}.pdf", replace	
	
	twoway 	(histogram math if inlist(grade,1,2,3,4,5,6)==1 & (inlist(year,2020)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
			(histogram math if inlist(grade,1,2,3,4,5,6)==1 & (inlist(year,2020)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
			, ///
		legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
		xtitle("Mathematics grade") ///
		xlabel(1 "D" 2 "C" 3 "B" 4 "A") 
	capture qui graph export "$FIGURES\Descriptive\histogram_post_elm${covid_data}.png", replace			
	capture qui graph export "$FIGURES\Descriptive\histogram_post_elm${covid_data}.pdf", replace	
	
	
	*- Aggregate: High school
	twoway 	(histogram math if inlist(grade,9,10)==1 & (inlist(year,2019)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
			(histogram math if inlist(grade,9,10)==1 & (inlist(year,2019)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
			, ///
			/// legend(order(1 "No siblings" 2 "1 sibling" 3 "2 siblings" 4 "3 siblings") pos(6) col(4))
			legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
			xtitle("Mathematics grade") 
	capture qui graph export "$FIGURES\Descriptive\histogram_pre_9-10${covid_data}.png", replace			
	capture qui graph export "$FIGURES\Descriptive\histogram_pre_9-10${covid_data}.pdf", replace	
	
	twoway 	(histogram math if inlist(grade,9,10)==1 & (inlist(year,2020)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
			(histogram math if inlist(grade,9,10)==1 & (inlist(year,2020)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
			, ///
		legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
		xtitle("Mathematics grade")
	capture qui graph export "$FIGURES\Descriptive\histogram_post_9-10${covid_data}.png", replace			
	capture qui graph export "$FIGURES\Descriptive\histogram_post_9-10${covid_data}.pdf", replace		
	
	
	*- Grade by grade
	forvalues g = 1/7 {
		twoway 	(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
				(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
				, ///
				/// legend(order(1 "No siblings" 2 "1 sibling" 3 "2 siblings" 4 "3 siblings") pos(6) col(4))
				legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
				xtitle("Mathematics grade") ///
				xlabel(1 "D" 2 "C" 3 "B" 4 "A")
			capture qui graph export "$FIGURES\Descriptive\histogram_pre_grade`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\histogram_pre_grade`g'${covid_data}.pdf", replace	
			
		twoway 	(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
				(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
				, ///
				legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
				xtitle("Mathematics grade") ///
				xlabel(1 "D" 2 "C" 3 "B" 4 "A") 
			capture qui graph export "$FIGURES\Descriptive\histogram_post_grade`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\histogram_post_grade`g'${covid_data}.pdf", replace				
		}
		
	forvalues g = 9/10 {
		twoway 	(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
				(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
				, ///
				legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
				xtitle("Mathematics grade") ///
				xline(10.5)
			capture qui graph export "$FIGURES\Descriptive\histogram_pre_grade`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\histogram_pre_grade`g'${covid_data}.pdf", replace	
			
		twoway 	(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
				(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
				, ///
				legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
				xtitle("Mathematics grade") ///
				xline(10.5)
			capture qui graph export "$FIGURES\Descriptive\histogram_post_grade`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\histogram_post_grade`g'${covid_data}.pdf", replace				
		}		
		
end

********************************************************************************
* Event Study - ECE
********************************************************************************

capture program drop event_ece_student
program define event_ece_student	

	global x = "$x_all"

	*---------
	*- ECE - Student level
	*---------
	*- ECE - 2P
	foreach v in "score_math_2p" "score_com_2p" "score_math_std_2p" "score_com_std_2p" "score_acad_std_2p" "satisf_m_2p" "satisf_c_2p" {
		di "`v'"
		if inlist("`v'","score_math_2p","score_math_std_2p","satisf_m_2p")==1 	local subj = "math"
		if inlist("`v'","score_com_2p","score_com_std_2p","satisf_c_2p")==1 	local subj = "com"
		if inlist("`v'","score_acad_std_2p")==1 				local subj = "acad"
		use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} if grade==2 using "$TEMP\pre_reg_covid${covid_data}", clear
		keep if inlist(year,2015,2016,2018,2019,2022,2023)==1
		merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_2p_*) nogen
		if inlist("`v'","score_math_2p","score_com_2p")==1 replace `v' = (`v'-500)/100 //standardize to reference year mean 0 and sd 1
		reghdfe 	`v' ${x}	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated, a(id_ie)
		*reghdfe 	score_acad_std_2p	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated if score_acad_std_2p_max==2022 & score_acad_std_2p_sum==5 & fam_order_2==1, a(id_ie)
		estimates 	store `v'
		}

	*- ECE - 4P
	foreach v in "score_math_4p" "score_com_4p" "score_math_std_4p" "score_com_std_4p" "score_acad_std_4p" "satisf_m_4p" "satisf_c_4p" {
		di "`v'"
		if inlist("`v'","score_math_4p","score_math_std_4p","satisf_m_4p")==1 	local subj = "math"
		if inlist("`v'","score_com_4p","score_com_std_4p","satisf_c_4p")==1 	local subj = "com"
		if inlist("`v'","score_acad_std_4p")==1 				local subj = "acad"
		use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} if grade==4 using "$TEMP\pre_reg_covid${covid_data}", clear
		keep if inlist(year,2016,2018,2019,2022,2023,2024)==1
		merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_4p_*) nogen
		if inlist("`v'","score_math_4p","score_com_4p")==1 replace `v' = (`v'-500)/100 //standardize to reference year mean 0 and sd 1
		reghdfe 	`v' 	${x}						year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 year_t_a4  treated, a(year id_ie)
		estimates 	store `v'		
		}	

	*- ECE - 2S
	foreach v in "score_math_2s" "score_com_2s" "score_math_std_2s" "score_com_std_2s" "score_acad_std_2s" "satisf_m_2s" "satisf_c_2s" {
		di "`v'"
		if inlist("`v'","score_math_2s","score_math_std_2s","satisf_m_2s")==1 	local subj = "math"
		if inlist("`v'","score_com_2s","score_com_std_2s","satisf_c_2s")==1 	local subj = "com"
		if inlist("`v'","score_acad_std_2s")==1 				local subj = "acad"
		use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} if grade==8 using "$TEMP\pre_reg_covid${covid_data}", clear
		merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_2s_*) nogen
		if inlist("`v'","score_math_2s","score_com_2s")==1 replace `v' = (`v'-500)/100 //standardize to reference year mean 0 and sd 1
		keep if inlist(year,2015,2016,2018,2019,2022,2023)==1
		reghdfe 	`v' ${x}			 year_t_b5 		year_t_b4  			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3  treated, a(year id_ie)
		estimates 	store `v'		
		}	
		
	foreach g in "2p" "4p" "2s" {
		if "`g'" == "2p" local g_label = "2nd Grade"
		if "`g'" == "4p" local g_label = "4th Grade"
		if "`g'" == "2s" local g_label = "8th Grade"

		coefplot 	score_math_`g' score_com_`g', ///
					omitted ///
					keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
					drop(year_t_b3) ///
					leg(order(1 "Mathematics" 3 "Reading")) ///
					coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
					yline(0,  lcolor(gs6))  ///
					ytitle("Effect") ///
					subtitle("Panel A: Standardized Exams - `g_label'") ///
					legend(pos(6) col(3)) ///
					name(panel_A_SATISF_`g',replace)	
		//graph save "$FIGURES\covid_ece_`g'.gph" , replace	
		//capture qui graph export "$FIGURES\covid_ece_`g'.eps", replace	
		capture qui graph export "$FIGURES\Event Study\ece_student_score_`g'${covid_data}.png", replace			
		capture qui graph export "$FIGURES\Event Study\ece_student_score_`g'${covid_data}.pdf", replace		
	}	

	foreach g in "2p" "4p" "2s" {
		if "`g'" == "2p" local g_label = "2nd Grade"
		if "`g'" == "4p" local g_label = "4th Grade"
		if "`g'" == "2s" local g_label = "8th Grade"

		coefplot 	score_math_std_`g' score_com_std_`g' score_acad_std_`g', ///
					omitted ///
					keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
					drop(year_t_b3) ///
					leg(order(1 "Mathematics" 3 "Reading" 5 "Average")) ///
					coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
					yline(0,  lcolor(gs6))  ///
					ytitle("Effect (SD)") ///
					subtitle("Panel A: Standardized Exams - `g_label'") ///
					legend(pos(6) col(3)) ///
					name(panel_A_STD_`g',replace)	
		//graph save "$FIGURES\covid_ece_`g'.gph" , replace	
		//capture qui graph export "$FIGURES\covid_ece_`g'.eps", replace	
		capture qui graph export "$FIGURES\Event Study\ece_student_std_score`g'${covid_data}.png", replace			
		capture qui graph export "$FIGURES\Event Study\ece_student_std_score`g'${covid_data}.pdf", replace		
	}

	foreach g in "2p" "4p" "2s" {
		if "`g'" == "2p" local g_label = "2nd Grade"
		if "`g'" == "4p" local g_label = "4th Grade"
		if "`g'" == "2s" local g_label = "8th Grade"

		coefplot 	satisf_m_`g' satisf_c_`g', ///
					omitted ///
					keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
					drop(year_t_b3) ///
					leg(order(1 "Mathematics" 3 "Reading")) ///
					coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
					yline(0,  lcolor(gs6))  ///
					ytitle("Effect") ///
					subtitle("Panel A: Satisfactory Level - `g_label'") ///
					legend(pos(6) col(3)) ///
					name(panel_A_SATISF_`g',replace)	
		//graph save "$FIGURES\covid_ece_`g'.gph" , replace	
		//capture qui graph export "$FIGURES\covid_ece_`g'.eps", replace	
		capture qui graph export "$FIGURES\Event Study\ece_student_satisf_`g'${covid_data}.png", replace			
		capture qui graph export "$FIGURES\Event Study\ece_student_satisf_`g'${covid_data}.pdf", replace		
	}	

end	


capture program drop event_ece_school
program define event_ece_school	

	
	global x = "$x_all"

	*---------
	*- ECE - Student level
	*---------
	
	foreach weight in "" "_weighted" {
	estimates clear	
		*- ECE - 2P
		foreach v in "score_math_2p" "score_com_2p" "score_math_std_2p" "score_com_std_2p" "score_acad_std_2p" "satisf_m_2p" "satisf_c_2p" {
			di "`v'"
			if inlist("`v'","score_math_2p","score_math_std_2p","satisf_m_2p")==1 	local subj = "math"
			if inlist("`v'","score_com_2p","score_com_std_2p","satisf_c_2p")==1 	local subj = "com"
			if inlist("`v'","score_acad_std_2p")==1 				local subj = "acad"
			use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} peso_?_2p if grade==2 using "$TEMP\pre_reg_covid${covid_data}", clear
			
			keep if inlist(year,2015,2016,2018,2019,2022,2023)==1
			//merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_2p_*) nogen
			if inlist("`v'","score_math_2p","score_com_2p")==1 replace `v' = (`v'-500)/100 //standardize to reference year mean 0 and sd 1
			gen pop = 1
			collapse (sum) pop (mean) `v' [iw=peso_m_2p], by(id_ie year_?_?? year treated) 
			if "`weight'" == "" 		reghdfe 	`v' /*${x}*/	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated, a(id_ie)
			if "`weight'" == "_weighted" 	reghdfe 	`v' /*${x}*/	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated [aw=pop], a(id_ie)
			estimates 	store `v'
			}

		*- ECE - 4P
		foreach v in "score_math_4p" "score_com_4p" "score_math_std_4p" "score_com_std_4p" "score_acad_std_4p" "satisf_m_4p" "satisf_c_4p" {
			di "`v'"
			if inlist("`v'","score_math_4p","score_math_std_4p","satisf_m_4p")==1 	local subj = "math"
			if inlist("`v'","score_com_4p","score_com_std_4p","satisf_c_4p")==1 	local subj = "com"
			if inlist("`v'","score_acad_std_4p")==1 				local subj = "acad"
			use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} peso_?_4p if grade==4 using "$TEMP\pre_reg_covid${covid_data}", clear
			
			keep if inlist(year,2016,2018,2019,2022,2023,2024)==1
			//merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_4p_*) nogen
			if inlist("`v'","score_math_4p","score_com_4p")==1 replace `v' = (`v'-500)/100 //standardize to reference year mean 0 and sd 1
			gen pop = 1
			collapse (sum) pop (mean) `v' [iw=peso_m_4p], by(id_ie year_?_?? year treated) 
			if "`weight'" == "" 		reghdfe 	`v' /*${x}*/	 		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 year_t_a4 i.year treated, a(id_ie)
			if "`weight'" == "_weighted" 	reghdfe 	`v' /*${x}*/	 		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 year_t_a4 i.year treated [aw=pop], a(id_ie)		
			estimates 	store `v'		
			}	

		*- ECE - 2S
		foreach v in "score_math_2s" "score_com_2s" "score_math_std_2s" "score_com_std_2s" "score_acad_std_2s" "satisf_m_2s" "satisf_c_2s" {
			di "`v'"
			if inlist("`v'","score_math_2s","score_math_std_2s","satisf_m_2s")==1 	local subj = "math"
			if inlist("`v'","score_com_2s","score_com_std_2s","satisf_c_2s")==1 	local subj = "com"
			if inlist("`v'","score_acad_std_2s")==1 				local subj = "acad"
			use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} peso_?_2s if grade==8 using "$TEMP\pre_reg_covid${covid_data}", clear
			
			keep if inlist(year,2015,2016,2018,2019,2022,2023)==1
			//merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_2s_*) nogen
			if inlist("`v'","score_math_2s","score_com_2s")==1 replace `v' = (`v'-500)/100 //standardize to reference year mean 0 and sd 1
			gen pop = 1
			collapse (sum) pop (mean) `v' [iw=peso_m_2s], by(id_ie year_?_?? year treated) 
			if "`weight'" == "" 		reghdfe 	`v' /*${x}*/	 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated, a(id_ie)
			if "`weight'" == "_weighted" 	reghdfe 	`v' /*${x}*/	 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated [aw=pop], a(id_ie)					
			estimates 	store `v'
			}	
			
		foreach g in "2p" "4p" "2s" {
			if "`g'" == "2p" local g_label = "2nd Grade"
			if "`g'" == "4p" local g_label = "4th Grade"
			if "`g'" == "2s" local g_label = "8th Grade"

			coefplot 	score_math_`g' score_com_`g', ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						drop(year_t_b3) ///
						leg(order(1 "Mathematics" 3 "Reading")) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
						yline(0,  lcolor(gs6))  ///
						ytitle("Effect") ///
						subtitle("Panel A: Standardized Exams - `g_label'") ///
						legend(pos(6) col(3)) ///
						name(panel_A_SATISF_`g',replace)	
			//graph save "$FIGURES\covid_ece_`g'.gph" , replace	
			//capture qui graph export "$FIGURES\covid_ece_`g'.eps", replace	
			capture qui graph export "$FIGURES\Event Study\ece_school`weight'_score_`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Event Study\ece_school`weight'_score_`g'${covid_data}.pdf", replace		
		}	

		foreach g in "2p" "4p" "2s" {
			if "`g'" == "2p" local g_label = "2nd Grade"
			if "`g'" == "4p" local g_label = "4th Grade"
			if "`g'" == "2s" local g_label = "8th Grade"

			coefplot 	score_math_std_`g' score_com_std_`g' score_acad_std_`g', ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						drop(year_t_b3) ///
						leg(order(1 "Mathematics" 3 "Reading" 5 "Average")) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
						yline(0,  lcolor(gs6))  ///
						ytitle("Effect (SD)") ///
						subtitle("Panel A: Standardized Exams - `g_label'") ///
						legend(pos(6) col(3)) ///
						name(panel_A_STD_`g',replace)	
			//graph save "$FIGURES\covid_ece_`g'.gph" , replace	
			//capture qui graph export "$FIGURES\covid_ece_`g'.eps", replace	
			capture qui graph export "$FIGURES\Event Study\ece_school`weight'_std_score_`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Event Study\ece_school`weight'_std_score_`g'${covid_data}.pdf", replace		
		}

		foreach g in "2p" "4p" "2s" {
			if "`g'" == "2p" local g_label = "2nd Grade"
			if "`g'" == "4p" local g_label = "4th Grade"
			if "`g'" == "2s" local g_label = "8th Grade"

			coefplot 	satisf_m_`g' satisf_c_`g', ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						drop(year_t_b3) ///
						leg(order(1 "Mathematics" 3 "Reading")) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
						yline(0,  lcolor(gs6))  ///
						ytitle("Effect") ///
						subtitle("Panel A: Satisfactory Level - `g_label'") ///
						legend(pos(6) col(3)) ///
						name(panel_A_SATISF_`g',replace)	
			//graph save "$FIGURES\covid_ece_`g'.gph" , replace	
			//capture qui graph export "$FIGURES\covid_ece_`g'.eps", replace	
			capture qui graph export "$FIGURES\Event Study\ece_school`weight'_satisf_`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Event Study\ece_school`weight'_satisf_`g'${covid_data}.pdf", replace		
		}	
	}
end	


********************************************************************************
* TWFE - GPA
********************************************************************************

capture program drop ece_baseline_netherlands
program define ece_baseline_netherlands 

	use "$TEMP\pre_reg_covid${covid_data}", clear
	
	/*
	keep if grade==2 | grade==8
	keep if score_math_2p!=. | score_math_2s!=.
	bys id_per_umc: egen has_2p = max(cond(score_math_2p!=.,1,0))
	bys id_per_umc: egen has_2s = max(cond(score_math_2s!=.,1,0))
	keep if has_2p == 1 & has_2s==1
	keep if 
		*/

	
	keep score_com_std score_math_std score_acad_std satisf_m satisf_c init_m init_c socioec_index socioec_index_cat id_per_umc id_ie year source educ_caretaker educ_mother educ_father grade fam_total_${fam_type}
	reshape wide score_com_std score_math_std score_acad_std satisf_m satisf_c init_m init_c socioec_index socioec_index_cat year id_ie source ,i(id_per_umc educ_caretaker educ_mother educ_father fam_total_${fam_type}) j(grade)
	
	tab fam_total_${fam_type}
	keep if fam_total_${fam_type}<=4
	
	gen sibs = inlist(fam_total_${fam_type},2,3,4) == 1 
	
	local g0 = 2
	local g1 = 8
	reghdfe score_com_std`g1' i.fam_total_${fam_type} score_com_std`g0' i.year`g0' i.educ_mother i.educ_father if year`g1'<=2019, a(id_ie`g0')
	reghdfe score_com_std`g1' i.fam_total_${fam_type} score_com_std`g0' i.year`g0' i.educ_mother i.educ_father if year`g1'>=2020, a(id_ie`g0')	
	
	local g0 = 4
	local g1 = 8
	reghdfe score_com_std`g1' i.fam_total_${fam_type} score_com_std`g0' i.year`g0' i.educ_mother i.educ_father if year`g1'<=2019, a(id_ie`g0')
	reghdfe score_com_std`g1' i.fam_total_${fam_type} score_com_std`g0' i.year`g0' i.educ_mother i.educ_father if year`g1'>=2020, a(id_ie`g0')	
	
	
	local g0 = 2
	local g1 = 8
	gen post = year`g1'>=2020 if year`g1'!=.
	reg score_com_std`g1' score_com_std`g0' i.post
	reg score_math_std`g1' score_math_std`g0' i.post
	reg score_com_std`g1' score_com_std`g0' i.post##i.sibs
	reg score_math_std`g1' score_math_std`g0' i.post##i.sibs
	capture drop post

/*
	local g0 = 2
	local g1 = 4
	gen post = year`g1'>=2020 if year`g1'!=.
	reg score_com_std`g1' score_com_std`g0' i.post##i.sibs
	capture drop post	
	
	
	local g0 = 4
	local g1 = 8
	gen post = year`g1'>=2020 if year`g1'!=.
	reg score_com_std`g1' score_com_std`g0' i.post##i.sibs
	capture drop post	
*/	
	//gen score_com_std = score_com_std`g1' - score_com_std`g0' 
	
	//reg score_com_std i.post##i.fam_total_${fam_type}, vce(cluster id_ie`g1')
	//reg score_com_std i.post##i.sibs, vce(cluster id_ie`g1')
	
	capture drop post score_
	
	reghdfe 	
	
	
	
	gen pop = 1 
	
	reghdfe satisf_m i.fam_total_${fam_type} i.year i.educ_mother i.educ_father if grade==2, a(id_ie)
	reghdfe satisf_m i.fam_total_${fam_type} i.year i.educ_mother i.educ_father if grade==4, a(id_ie)
	reghdfe satisf_m i.fam_total_${fam_type} i.year i.educ_mother i.educ_father if grade==8, a(id_ie)

	/
	collapse (mean) score_*_std satisf* init* socioec_index (sum) pop, by(grade year fam_total_${fam_type})
	
	
	graph bar satisf_m if grade==2, ///
		by(year) over(fam_total_${fam_type}) ///
		legend(order(1 "${g1l} grade (Pre covid)" 2 "${g2l} grade (Post covid)") pos(6) col(2))

end	


********************************************************************************
* TWFE 
********************************************************************************


capture program drop twfe_summary
program define twfe_summary

*- Main categories for TWFE from A, B, C, D
di "Summary TWFE"
/*
A: 
Urb/Rural
Internet
SES

B: 
primary/secondary

C: 


D: 
single parents?
no education?

*/


	clear

	*- TWFE Estimates
	foreach v in /*"std_gpa_m" "std_gpa_c"*/ "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" "prim_on_time" /*"approved" "approved_first"*/ {
		foreach only_covid in "20-21" "all" {
			foreach level in "all" "elm" "sec" {
			
			if ${covid_test} == 1 & inlist("`v'","std_gpa_m_adj","pass_math")==0 continue
			if ${covid_test} == 1 & inlist("`level'","sec")==1 continue
			if ${covid_test} == 1 & inlist("`only_covid'","all")==1 continue
			
			estimates clear
				global x = "$x_all"
				if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"	
				
				use ///
				/*OUTCOME*/		`v'  ///
				/*ID*/ 			id_ie id_per_umc year grade ///
				/*FAMILY*/		fam_order_${fam_type} fam_total_${fam_type} ///
				/*DID*/			treated post treated_post ///
				/*EVENT*/		year_t_?? ///
				/*Demog*/		public_siagie urban_siagie male_siagie  ${x} ///
				/*A*/ 			min_socioec_index_ie_cat quart_class_size quart_grade_size /*OTHER IN DEMOG*/ ///
				/*B*/			/*GRADE AND MALE*/ ///
				/*C*/			///closest_age_gap* ///
				/*D*/			educ_cat_mother /*higher_ed_parent*/ lives_with_mother lives_with_father ///
				/*Other*/		/**has_internet *has_comp *low_ses *quiet_room*/ ///
				using "$TEMP\pre_reg_covid${covid_data}", clear
				
				*- Remove early grades and years
				keep if year>=2016
				drop if grade==0
				
				*- Keep only 2020-2021 (exclude 2022,2023,2024) from the TWFE estimates
				if "`only_covid'" == "20-21" keep if year<=2021
				
				*- School has internet
				merge m:1 id_ie using "$TEMP\school_internet", keepusing(codlocal internet) keep(master match)
				
				*- Divide sample based on grade in 2020
				//bys id_per_umc: egen grade_2020	= min(cond(year==2020,grade,.))
				
				*- Divide sample based on expected cohort
				bys id_per_umc: egen min_year 		= min(year)
				bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
				gen proxy_1st = min_year - grade_min_year  + 1
								
				
				/*
				*- Not enough pre-years
							
				drop if inlist(grade_2020,1,2)==1
				drop if grade_2020==3 & year<=2017 //<=2017 Would only include those who repeated..
				drop if grade_2020==4 & year<=2016 //<=2016 Would only include those who repeated..
				keep if proxy_1st <= 2018
				*/
				
				
				/*
				if "`area'" == "rur" keep if urban_siagie == 0
				if "`area'" == "urb" keep if urban_siagie == 1

				if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
				if "`hed_parent'" == "yes" 	keep if higher_ed_parent == 1
				*/
				
				if "`level'" == "all" {
					keep if grade>=1 & grade<=11
					//gen young = inlist(grade_2020,3,4,5,6)==1 if inlist(grade_2020,3,4,5,6,7,8,9,10,11)
					//gen young = inlist(proxy_1st,2015,2016,2017,2018) if inlist(proxy_1st,2011,2012,2013,2014,2015,2016,2017,2018)==1
					gen young = inlist(grade,1,2,3,4,5,6)==1 if inlist(grade,1,2,3,4,5,6,7,8,9,10,11)
					local young_lab = "Primary" //Primary in 2020
					local old_lab 	= "Secondary"
					}
				if "`level'" == "elm" {
					keep if grade>=1 & grade<=6
					//gen young = inlist(grade_2020,3,4)==1 if inlist(grade_2020,3,4,5,6)
					//gen young = inlist(proxy_1st,2017,2018) if inlist(proxy_1st,2015,2016)==1
					//local young_lab = "2017-2018 cohort" //3rd-4th grade in 2020
					//local old_lab 	= "2015-2016 cohort" //5th-6th grade in 2020
					gen young = inlist(grade,1,2,3)==1 if inlist(grade,1,2,3,4,5,6)
					local young_lab = "1st-3rd grade"
					local old_lab 	= "4th-6th grade"
					}
				if "`level'" == "sec" {
					keep if grade>=7	
					//gen young = inlist(grade_2020,7,8)==1 if inlist(grade_2020,7,8,9,10,11)
					//gen young = inlist(proxy_1st,2014,2013) if inlist(proxy_1st,2011,2012)==1
					//local young_lab = "2014-2013 cohort" //7th-8th grade in 2020
					//local old_lab 	= "2011-2012 cohort" //9th-11th grade in 2020
					gen young = inlist(grade,7,8)==1 if inlist(grade,7,8,9,10,11)
					local young_lab = "7th-8th grade"
					local old_lab 	= "9th-11th grade"
					}

				if "`v'" == "std_gpa_m" 		local vlab = "gpa_m"
				if "`v'" == "std_gpa_c" 		local vlab = "gpa_c"
				if "`v'" == "std_gpa_m_adj" 	local vlab = "gpa_m_adj"
				if "`v'" == "std_gpa_c_adj" 	local vlab = "gpa_c_adj"				
				if "`v'" == "pass_math" 		local vlab = "pass_m"				
				if "`v'" == "pass_read" 		local vlab = "pass_c"				
				if "`v'" == "approved" 			local vlab = "pass"
				if "`v'" == "approved_first" 	local vlab = "passf"
		
				* All students
				di as result "*******" _n as text "All" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 , a(grade id_ie)
				estimates store all_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(grade id_ie)
				estimates store all_`vlab'_2
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1  , a(grade id_ie)
				estimates store all_`vlab'_3
				if ${max_sibs} == 4 eststo all_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1  , a(grade id_ie)
				
				*****
				* Panel A: Confounders: Type of school
				*****			
				*- Urban/Rural
				di as result "*******" _n as text "Urban" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & urban_siagie==1 , a(grade id_ie)
				estimates store urb_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & urban_siagie==1 , a(grade id_ie)
				estimates store urb_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & urban_siagie==1  , a(grade id_ie)
				estimates store urb_`vlab'_3
				if ${max_sibs} == 4 eststo urb_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & urban_siagie==1  , a(grade id_ie)

				di as result "*******" _n as text "Rural" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & urban_siagie==0 , a(grade id_ie)
				estimates store rur_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & urban_siagie==0 , a(grade id_ie)
				estimates store rur_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & urban_siagie==0  , a(grade id_ie)
				estimates store rur_`vlab'_3
				if ${max_sibs} == 4 eststo rur_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & urban_siagie==0  , a(grade id_ie)
				
				*- Internet/No Internet
				di as result "*******" _n as text "Internet in school" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1  & internet==1, a(grade id_ie)
				estimates store int_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & internet==1 , a(grade id_ie)
				estimates store int_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & internet==1  , a(grade id_ie)
				estimates store int_`vlab'_3
				if ${max_sibs} == 4 eststo int_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & internet==1  , a(grade id_ie)

				di as result "*******" _n as text "No internet in school" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & internet==0 , a(grade id_ie)
				estimates store nin_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & internet==0 , a(grade id_ie)
				estimates store nin_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & internet==0  , a(grade id_ie)
				estimates store nin_`vlab'_3
				if ${max_sibs} == 4 eststo nin_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & internet==0  , a(grade id_ie)
				/*
				*- Public/Private
				di as result "*******" _n as text "Public" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1  & public_siagie==1, a(grade id_ie)
				estimates store all_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & public_siagie==1 , a(grade id_ie)
				estimates store pub_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & public_siagie==1  , a(grade id_ie)
				estimates store pub_`vlab'_3
				if ${max_sibs} == 4 eststo pub_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & public_siagie==1  , a(grade id_ie)

				di as result "*******" _n as text "Private" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & public_siagie==0, a(grade id_ie)
				estimates store all_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & public_siagie==0 , a(grade id_ie)
				estimates store pri_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & public_siagie==0  , a(grade id_ie)
				estimates store pri_`vlab'_3
				if ${max_sibs} == 4 eststo pri_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & public_siagie==0  , a(grade id_ie)
				*/
				*- Low SES/High SES schools
				di as result "*******" _n as text "Low SES IE" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1  & min_socioec_index_ie_cat==1 , a(grade id_ie)
				estimates store low_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & min_socioec_index_ie_cat==1 , a(grade id_ie)
				estimates store low_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & min_socioec_index_ie_cat==1  , a(grade id_ie)
				estimates store low_`vlab'_3
				if ${max_sibs} == 4 eststo low_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & min_socioec_index_ie_cat==1  , a(grade id_ie)

				di as result "*******" _n as text "High SES IE" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1  & min_socioec_index_ie_cat==4, a(grade id_ie)
				estimates store hig_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & min_socioec_index_ie_cat==4 , a(grade id_ie)
				estimates store hig_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & min_socioec_index_ie_cat==4  , a(grade id_ie)
				estimates store hig_`vlab'_3
				if ${max_sibs} == 4 eststo hig_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & min_socioec_index_ie_cat==4  , a(grade id_ie)	

				*- By age
				di as result "*******" _n as text "Younger cohort" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1  & young==1 , a(grade id_ie)
				estimates store young_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & young==1 , a(grade id_ie)
				estimates store young_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & young==1  , a(grade id_ie)
				estimates store young_`vlab'_3
				if ${max_sibs} == 4 eststo young_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & young==1  , a(grade id_ie)
				
				di as result "*******" _n as text "Older cohort" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1  & young==0, a(grade id_ie)
				estimates store old_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & young==0 , a(grade id_ie)
				estimates store old_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & young==0  , a(grade id_ie)
				estimates store old_`vlab'_3
				if ${max_sibs} == 4 eststo old_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & young==0  , a(grade id_ie)
		
				*- Birth Order
				di as result "*******" _n as text "Oldest" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & inlist(fam_order_${fam_type},1)==1, a(grade id_ie)
				estimates store first_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & inlist(fam_order_${fam_type},1)==1 , a(grade id_ie)
				estimates store first_`vlab'_2
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & inlist(fam_order_${fam_type},1)==1  , a(grade id_ie)
				estimates store first_`vlab'_3
				if ${max_sibs} == 4 eststo first_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & inlist(fam_order_${fam_type},1)==1  , a(grade id_ie)
					
				*- Mother's education
				di as result "*******" _n as text "Some level of higher education" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & educ_cat_mother==3 , a(grade id_ie)
				estimates store edu3_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & educ_cat_mother==3 , a(grade id_ie)
				estimates store edu3_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & educ_cat_mother==3  , a(grade id_ie)
				estimates store edu3_`vlab'_3
				if ${max_sibs} == 4 eststo edu3_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & educ_cat_mother==3  , a(grade id_ie)
				
				*- Lives with parents
				di as result "*******" _n as text "Only lives with one parent" _n as result "*******"
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1  &  ((lives_with_mother==1 & lives_with_father==0) | (lives_with_mother==0 & lives_with_father==1)), a(grade id_ie)
				estimates store one_`vlab'
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 &  ((lives_with_mother==1 & lives_with_father==0) | (lives_with_mother==0 & lives_with_father==1)) , a(grade id_ie)
				estimates store one_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & ((lives_with_mother==1 & lives_with_father==0) | (lives_with_mother==0 & lives_with_father==1))   , a(grade id_ie)
				estimates store one_`vlab'_3
				if ${max_sibs} == 4 eststo one_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & ((lives_with_mother==1 & lives_with_father==0) | (lives_with_mother==0 & lives_with_father==1))   , a(grade id_ie)
				
				
				if ${max_sibs}==4 local legend_child_${max_sibs} = "4 children"	
				if ${max_sibs}==4 local legend_sib_${max_sibs} = "3 siblings"	
				
				if inlist("`v'","std_gpa_m","std_gpa_c","std_gpa_m_adj","std_gpa_c_adj")==1 {
					local xmin = -0.04
					local xlines = "-.1 -.08 -.06 -.04 -.02 .02"
				}
				if inlist("`v'","pass_math","pass_read")==1 {
					local xmin = -0.04
					local xlines = "-.04 -.02 .02"
				}
				 
				*Only main TWFE 
				coefplot 	(all_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("All Students") ///
							||  ///
							///(urb_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							///(urb_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							///(urb_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							///, ///
							///bylabel("Urban") ///
							///||  ///
							(rur_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Rural") ///
							||  ///
							(int_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Internet in school") ///
							||  ///
							(nin_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("No internet in school") ///
							||  ///
							///(hig_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							///(hig_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							///(hig_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							///, ///
							///bylabel("Top 25% SES schools") ///
							///||  ///
							(low_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Bottom 25% SES schools") ///
							||  ///
							(young_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("`young_lab'") ///
							|| ///
							(old_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("`old_lab'") ///
							||  ///
							(first_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Oldest child") ///
							||  ///
							(edu3_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Mother with some level of Higher ed.") ///
							||  ///
							(one_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Lives with one parent") ///
							||  ///
							, ///
							keep(treated_post) ///
							xtitle("Standardized GPA", size(medsmall) height(5)) ///
							xlabel(`xmin'(0.02)0.02) ///
							xline(0, lcolor(gs12)) ///
							xline(`xlines', lcolor(gs15))  ///
							grid(none) ///
							bycoefs	
				
						
				*- All TWFE by # of siblings	
				if "${covid_data}" == "_TEST" {
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_summ_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_summ_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}
				if "${covid_data}" == "" {
					capture qui graph export "$FIGURES\TWFE\covid_twfe_summ_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES\TWFE\covid_twfe_summ_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}	 
				 
				coefplot 	(all_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(all_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(all_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("All Students") ///
							||  ///
							///(urb_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							///(urb_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							///(urb_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							///, ///
							///bylabel("Urban") ///
							///||  ///
							(rur_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(rur_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(rur_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Rural") ///
							||  ///
							(int_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(int_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(int_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Internet in school") ///
							||  ///
							(nin_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(nin_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(nin_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("No internet in school") ///
							||  ///
							///(hig_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							///(hig_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							///(hig_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							///, ///
							///bylabel("Top 25% SES schools") ///
							///||  ///
							(low_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(low_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(low_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Bottom 25% SES schools") ///
							||  ///
							(young_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(young_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(young_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("`young_lab'") ///
							|| ///
							(old_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(old_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(old_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("`old_lab'") ///
							||  ///
							(first_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(first_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(first_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Oldest child") ///
							||  ///
							(edu3_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(edu3_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(edu3_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Mother with some level of Higher ed.") ///
							||  ///
							(one_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(one_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(one_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Lives with one parent") ///
							||  ///
							, ///
							keep(treated_post) ///
							legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
							xtitle("Standardized GPA", size(medsmall) height(5)) ///
							xlabel(`xmin'(0.02)0.02) ///
							xline(0, lcolor(gs12)) ///
							xline(`xlines', lcolor(gs15))  ///
							grid(none) ///
							bycoefs	
				
						
				//graph save "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.gph" , replace	
				//capture qui graph export "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.eps", replace	
				if "${covid_data}" == "_TEST" {
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_sibs_summ_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_sibs_summ_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}
				if "${covid_data}" == "" {
					capture qui graph export "$FIGURES\TWFE\covid_twfe_sibs_summ_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES\TWFE\covid_twfe_sibs_summ_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}				
			}
		}
	}
end
		


capture program drop twfe_A
program define twfe_A
		
	
	clear

	*- TWFE Estimates

	foreach v in /*"std_gpa_m" "std_gpa_c"*/ "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" /*"approved" "approved_first"*/ {
		foreach only_covid in "20-21" "all" {
			foreach level in "all" "elm" "sec" {
			
			if ${covid_test} == 1 & inlist("`v'","std_gpa_m_adj","pass_math")==0 continue
			if ${covid_test} == 1 & inlist("`level'","sec")==1 continue
			if ${covid_test} == 1 & inlist("`only_covid'","all")==1 continue
			
			estimates clear
			global x = "$x_all"
			if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"	
			

			use ///
			/*OUTCOME*/		`v'  ///
			/*ID*/ 			id_ie id_per_umc year grade ///
			/*FAMILY*/		fam_order_${fam_type} fam_total_${fam_type} ///
			/*DID*/			treated post treated_post ///
			/*EVENT*/		year_t_?? ///
			/*Demog*/		public_siagie urban_siagie male_siagie  ${x} ///
			/*A*/ 			min_socioec_index_ie_cat quart_class_size quart_grade_size /*OTHER IN DEMOG*/ ///
			/*B*/			/*GRADE AND MALE*/ ///
			/*C*/			///closest_age_gap* ///
			/*D*/			///educ_cat_mother higher_ed_parent lives_with_mother lives_with_father ///
			/*Other*/		/**has_internet *has_comp *low_ses *quiet_room*/ ///
			using "$TEMP\pre_reg_covid${covid_data}", clear
			
			*- Remove early grades and years
			keep if year>=2016
			drop if grade==0
				
			*- Keep only 2020-2021 (exclude 2022,2023,2024) from the TWFE estimates
			if "`only_covid'" == "20-21" keep if year<=2021			
			
			*- School has internet
			merge m:1 id_ie using "$TEMP\school_internet", keepusing(codlocal internet) keep(master match)
			
			*- Divide sample based on grade in 2020
			//bys id_per_umc: egen grade_2020	= min(cond(year==2020,grade,.))
			
			*- Divide sample based on expected cohort
			bys id_per_umc: egen min_year 		= min(year)
			bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
			gen proxy_1st = min_year - grade_min_year  + 1
							
			
			/*
			*- Not enough pre-years
						
			drop if inlist(grade_2020,1,2)==1
			drop if grade_2020==3 & year<=2017 //<=2017 Would only include those who repeated..
			drop if grade_2020==4 & year<=2016 //<=2016 Would only include those who repeated..
			keep if proxy_1st <= 2018
			*/
			
			
			/*
			if "`area'" == "rur" keep if urban_siagie == 0
			if "`area'" == "urb" keep if urban_siagie == 1

			if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
			if "`hed_parent'" == "yes" 	keep if higher_ed_parent == 1
			*/
			
			if "`level'" == "all" {
				keep if grade>=1 & grade<=11
				//gen young = inlist(grade_2020,3,4,5,6)==1 if inlist(grade_2020,3,4,5,6,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2015,2016,2017,2018) if inlist(proxy_1st,2011,2012,2013,2014,2015,2016,2017,2018)==1
				gen young = inlist(grade,1,2,3,4,5,6)==1 if inlist(grade,1,2,3,4,5,6,7,8,9,10,11)
				local young_lab = "Primary" //Primary in 2020
				local old_lab 	= "Secondary"
				}
			if "`level'" == "elm" {
				keep if grade>=1 & grade<=6
				//gen young = inlist(grade_2020,3,4)==1 if inlist(grade_2020,3,4,5,6)
				//gen young = inlist(proxy_1st,2017,2018) if inlist(proxy_1st,2015,2016)==1
				//local young_lab = "2017-2018 cohort" //3rd-4th grade in 2020
				//local old_lab 	= "2015-2016 cohort" //5th-6th grade in 2020
				gen young = inlist(grade,1,2,3)==1 if inlist(grade,1,2,3,4,5,6)
				local young_lab = "1st-3rd grade"
				local old_lab 	= "4th-6th grade"
				}
			if "`level'" == "sec" {
				keep if grade>=7	
				//gen young = inlist(grade_2020,7,8)==1 if inlist(grade_2020,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2014,2013) if inlist(proxy_1st,2011,2012)==1
				//local young_lab = "2014-2013 cohort" //7th-8th grade in 2020
				//local old_lab 	= "2011-2012 cohort" //9th-11th grade in 2020
				gen young = inlist(grade,7,8)==1 if inlist(grade,7,8,9,10,11)
				local young_lab = "7th-8th grade"
				local old_lab 	= "9th-11th grade"
				}

			if "`v'" == "std_gpa_m" 		local vlab = "gpa_m"
			if "`v'" == "std_gpa_c" 		local vlab = "gpa_c"
			if "`v'" == "std_gpa_m_adj" 	local vlab = "gpa_m_adj"
			if "`v'" == "std_gpa_c_adj" 	local vlab = "gpa_c_adj"				
			if "`v'" == "pass_math" 		local vlab = "pass_m"				
			if "`v'" == "pass_read" 		local vlab = "pass_c"				
			if "`v'" == "approved" 			local vlab = "pass"
			if "`v'" == "approved_first" 	local vlab = "passf"
	
			* All students
			di as result "*******" _n as text "All" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 , a(grade id_ie)
			estimates store all_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(grade id_ie)
			estimates store all_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1  , a(grade id_ie)
			estimates store all_`vlab'_3
			if ${max_sibs} == 4 eststo all_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1  , a(grade id_ie)
			
			*****
			* Panel A: Confounders: Type of school
			*****			
			*- Urban/Rural
			di as result "*******" _n as text "Urban" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & urban_siagie==1 , a(grade id_ie)
			estimates store urb_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & urban_siagie==1 , a(grade id_ie)
			estimates store urb_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & urban_siagie==1  , a(grade id_ie)
			estimates store urb_`vlab'_3
			if ${max_sibs} == 4 eststo urb_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & urban_siagie==1  , a(grade id_ie)

			di as result "*******" _n as text "Rural" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & urban_siagie==0 , a(grade id_ie)
			estimates store rur_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & urban_siagie==0 , a(grade id_ie)
			estimates store rur_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & urban_siagie==0  , a(grade id_ie)
			estimates store rur_`vlab'_3
			if ${max_sibs} == 4 eststo rur_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & urban_siagie==0  , a(grade id_ie)
			
			*- Internet/No Internet
			di as result "*******" _n as text "Internet in school" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & internet==1 , a(grade id_ie)
			estimates store int_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & internet==1 , a(grade id_ie)
			estimates store int_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & internet==1  , a(grade id_ie)
			estimates store int_`vlab'_3
			if ${max_sibs} == 4 eststo int_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & internet==1  , a(grade id_ie)

			di as result "*******" _n as text "No internet in school" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & internet==0 , a(grade id_ie)
			estimates store nin_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & internet==0 , a(grade id_ie)
			estimates store nin_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & internet==0  , a(grade id_ie)
			estimates store nin_`vlab'_3
			if ${max_sibs} == 4 eststo nin_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & internet==0  , a(grade id_ie)
			
			*- Public/Private
			di as result "*******" _n as text "Public" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & public_siagie==1 , a(grade id_ie)
			estimates store pub_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & public_siagie==1 , a(grade id_ie)
			estimates store pub_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & public_siagie==1  , a(grade id_ie)
			estimates store pub_`vlab'_3
			if ${max_sibs} == 4 eststo pub_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & public_siagie==1  , a(grade id_ie)

			di as result "*******" _n as text "Private" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & public_siagie==0 , a(grade id_ie)
			estimates store pri_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & public_siagie==0 , a(grade id_ie)
			estimates store pri_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & public_siagie==0  , a(grade id_ie)
			estimates store pri_`vlab'_3
			if ${max_sibs} == 4 eststo pri_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & public_siagie==0  , a(grade id_ie)
			
			*- Low SES/High SES schools
			di as result "*******" _n as text "Low SES IE" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & min_socioec_index_ie_cat==1 , a(grade id_ie)
			estimates store low_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & min_socioec_index_ie_cat==1 , a(grade id_ie)
			estimates store low_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & min_socioec_index_ie_cat==1  , a(grade id_ie)
			estimates store low_`vlab'_3
			if ${max_sibs} == 4 eststo low_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & min_socioec_index_ie_cat==1  , a(grade id_ie)

			di as result "*******" _n as text "High SES IE" _n as result 
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & min_socioec_index_ie_cat==4 , a(grade id_ie)
			estimates store hig_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & min_socioec_index_ie_cat==4 , a(grade id_ie)
			estimates store hig_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & min_socioec_index_ie_cat==4  , a(grade id_ie)
			estimates store hig_`vlab'_3
			if ${max_sibs} == 4 eststo hig_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & min_socioec_index_ie_cat==4  , a(grade id_ie)	

			*- Low SES + Public
			di as result "*******" _n as text "Low SES + Public" _n as result "*******"		
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & min_socioec_index_ie_cat==1 & public_siagie==1 , a(grade id_ie)
			estimates store pubL_`vlab'	
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & min_socioec_index_ie_cat==1 & public_siagie==1 , a(grade id_ie)
			estimates store pubL_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & min_socioec_index_ie_cat==1 & public_siagie==1  , a(grade id_ie)
			estimates store pubL_`vlab'_3
			if ${max_sibs} == 4 eststo pubL_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & min_socioec_index_ie_cat==1 &  public_siagie==1 , a(grade id_ie)

	
			*- High SES + Private
			di as result "*******" _n as text "High SES + Private" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & min_socioec_index_ie_cat==4 & public_siagie==0 , a(grade id_ie)
			estimates store priH_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & min_socioec_index_ie_cat==4 & public_siagie==0 , a(grade id_ie)
			estimates store priH_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & min_socioec_index_ie_cat==4 & public_siagie==0, a(grade id_ie)
			estimates store priH_`vlab'_3
			if ${max_sibs} == 4 eststo priH_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & min_socioec_index_ie_cat==4 &  public_siagie==0 , a(grade id_ie)				
			*- Class size Q1 (Bottom 25%)
			di as result "*******" _n as text "Low class size" _n as result "*******"		
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & quart_class_size==1 , a(grade id_ie)
			estimates store sma_`vlab'		
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & quart_class_size==1 , a(grade id_ie)
			estimates store sma_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & quart_class_size==1, a(grade id_ie)
			estimates store sma_`vlab'_3
			if ${max_sibs} == 4 eststo sma_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & quart_class_size==1 , a(grade id_ie)	

	
			*- Class size Q4 (Top 25%)
			di as result "*******" _n as text "Top class size" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & quart_class_size==4 , a(grade id_ie)
			estimates store big_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & quart_class_size==4 , a(grade id_ie)
			estimates store big_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & quart_class_size==4, a(grade id_ie)
			estimates store big_`vlab'_3
			if ${max_sibs} == 4 eststo big_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & quart_class_size==4 , a(grade id_ie)							
			
			
			
			if ${max_sibs}==4 local legend_child_${max_sibs} = "4 children"	
			if ${max_sibs}==4 local legend_sib_${max_sibs} = "3 siblings"	
	
				
				if inlist("`v'","std_gpa_m","std_gpa_c","std_gpa_m_adj","std_gpa_c_adj")==1 {
					local xmin = -0.04
					local xlines = "-.1 -.08 -.06 -.04 -.02 .02"
				}
				if inlist("`v'","pass_math","pass_read")==1 {
					local xmin = -0.04
					local xlines = "-.04 -.02 .02"
				}
				 
	
				*Only main TWFE 
				coefplot 	(all_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("All Students") ///
							||  ///
							(urb_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Urban") ///
							||  ///
							(rur_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Rural") ///
							||  ///
							(int_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Internet in school") ///
							||  ///
							(nin_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("No internet in school") ///
							||  ///
							(pub_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Public Schools") ///
							||  ///
							(pri_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Private Schools") ///
							||  ///
							(low_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Bottom 25% SES schools") ///
							||  ///
							(hig_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Top 25% SES schools") ///
							||  ///
							(pubL_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Public + Bottom 25% SES schools") ///
							||  ///
							(priH_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Private + Top 25% SES schools") ///
							||  ///
							(sma_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Bottom 25% class size") ///
							||  ///
							(big_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Top 25% class size") ///
							||  ///
							, ///
							keep(treated_post) ///
							xtitle("Standardized GPA", size(medsmall) height(5)) ///
							xlabel(`xmin'(0.02)0.02) ///
							xline(0, lcolor(gs12)) ///
							xline(`xlines', lcolor(gs15))  ///
							grid(none) ///
							bycoefs	
				
						
				*- All TWFE by # of siblings	
				if "${covid_data}" == "_TEST" {
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_A_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_A_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}
				if "${covid_data}" == "" {
					capture qui graph export "$FIGURES\TWFE\covid_twfe_A_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES\TWFE\covid_twfe_A_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}	 
				 
				coefplot 	(all_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(all_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(all_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("All Students") ///
							||  ///
							(urb_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(urb_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(urb_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Urban") ///
							||  ///
							(rur_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(rur_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(rur_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Rural") ///
							||  ///
							(int_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(int_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(int_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Internet in school") ///
							||  ///
							(nin_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(nin_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(nin_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("No internet in school") ///
							||  ///
							(pub_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(pub_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(pub_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Public schools") ///
							||  ///
							(pri_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(pri_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(pri_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Private schools") ///
							||  ///
							(low_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(low_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(low_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Bottom 25% SES schools") ///
							||  ///
							(hig_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(hig_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(hig_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Top 25% SES schools") ///
							||  ///
							(pubL_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(pubL_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(pubL_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Public + Bottom 25% SES schools") ///
							||  ///
							(priH_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(priH_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(priH_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Private + Top 25% SES schools") ///
							||  ///
							(sma_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(sma_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(sma_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Bottom 25% class size") ///
							||  ///
							(big_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(big_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(big_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Top 25% class size") ///
							|| ///
							, ///
							keep(treated_post) ///
							legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
							xtitle("Standardized GPA", size(medsmall) height(5)) ///
							xlabel(`xmin'(0.02)0.02) ///
							xline(0, lcolor(gs12)) ///
							xline(`xlines', lcolor(gs15))  ///
							grid(none) ///
							bycoefs	
				
						
				//graph save "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.gph" , replace	
				//capture qui graph export "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.eps", replace	
				if "${covid_data}" == "_TEST" {
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_sibs_A_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_sibs_A_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}
				if "${covid_data}" == "" {
					capture qui graph export "$FIGURES\TWFE\covid_twfe_sibs_A_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES\TWFE\covid_twfe_sibs_A_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}	
			/*
			coefplot all_`vlab'_?, ///
					bylabel("All Students") ///
					|| urb_`vlab'_?, ///
					bylabel("Urban") ///
					|| rur_`vlab'_?, ///
					bylabel("Rural") ///
					|| int_`vlab'_?, ///
					bylabel("Internet in school") ///
					|| nin_`vlab'_?, ///
					bylabel("No internet in school") ///
					|| pub_`vlab'_?, ///
					bylabel("Public Schools") ///
					|| pri_`vlab'_?, ///
					bylabel("Private Schools") ///
					|| low_`vlab'_?, ///
					bylabel("Bottom 25% SES schools") ///
					|| hig_`vlab'_?, ///
					bylabel("Top 25% SES schools") ///
					|| pubL_`vlab'_?, ///
					bylabel("Public + Bottom 25% SES schools") ///
					|| priH_`vlab'_?, ///
					bylabel("Private + Top 25% SES schools") ///
					|| sma_`vlab'_?, ///
					bylabel("Bottom 25% class size") ///
					|| big_`vlab'_?, ///
					bylabel("Top 25% class size") ///
					keep(treated_post) ///
					legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
					xtitle("Standard Deviations", size(medsmall) height(5)) ///
					xlabel(-.1(0.02)0.02) ///
					xline(0, lcolor(gs12)) ///
					xline(-.1 -.08 -.06 -.04 -.02 .02, lcolor(gs15))  ///
					///xlabel(-.1 "-0.8" -.4 "-0.4" 0 "0" .4 "0.4" .8 "0.8", labsize(medsmall)) ///
					///ciopts(recast(rcap) lwidth(medium)) ///
					grid(none) ///
					///yscale(reverse) ///
					bycoefs	
			
					
			//graph save "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.gph" , replace	
			//capture qui graph export "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.eps", replace	
			capture qui graph export "$FIGURES\TWFE\covid_twfe_A_`level'_`vlab'_${max_sibs}${covid_data}.png", replace	
			capture qui graph export "$FIGURES\TWFE\covid_twfe_A_`level'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
			*/
			
		}
	}
}

end

***********************************************


capture program drop twfe_B
program define twfe_B
		
	
	clear

	*- TWFE Estimates

	foreach v in /*"std_gpa_m" "std_gpa_c"*/ "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" /*"approved" "approved_first"*/ {
		foreach only_covid in "20-21" "all" {
			foreach level in "all" "elm" "sec" {
			
			if ${covid_test} == 1 & inlist("`v'","std_gpa_m_adj","pass_math")==0 continue
			if ${covid_test} == 1 & inlist("`level'","sec")==1 continue
			if ${covid_test} == 1 & inlist("`only_covid'","all")==1 continue			
			estimates clear
			global x = "$x_all"
			if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"	
			

			use ///
			/*OUTCOME*/		`v'  ///
			/*ID*/ 			id_ie id_per_umc year grade ///
			/*FAMILY*/		fam_order_${fam_type} fam_total_${fam_type} ///
			/*DID*/			treated post treated_post ///
			/*EVENT*/		year_t_?? ///
			/*Demog*/		public_siagie urban_siagie male_siagie  ${x} ///
			/*A*/ 			min_socioec_index_ie_cat /*OTHER IN DEMOG*/ ///
			/*B*/			/*GRADE AND MALE*/ ///
			/*C*/			///closest_age_gap* ///
			/*D*/			///educ_cat_mother higher_ed_parent lives_with_mother lives_with_father ///
			/*Other*/		/**has_internet *has_comp *low_ses *quiet_room*/ ///
			using "$TEMP\pre_reg_covid${covid_data}", clear
			
			*- Remove early grades and years
			keep if year>=2016
			drop if grade==0
			
			*- Keep only 2020-2021 (exclude 2022,2023,2024) from the TWFE estimates
			if "`only_covid'" == "20-21" keep if year<=2021
			
			*- Divide sample based on grade in 2020
			//bys id_per_umc: egen grade_2020	= min(cond(year==2020,grade,.))
			
			*- Divide sample based on expected cohort
			bys id_per_umc: egen min_year 		= min(year)
			bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
			gen proxy_1st = min_year - grade_min_year  + 1
							
			
			/*
			*- Not enough pre-years
						
			drop if inlist(grade_2020,1,2)==1
			drop if grade_2020==3 & year<=2017 //<=2017 Would only include those who repeated..
			drop if grade_2020==4 & year<=2016 //<=2016 Would only include those who repeated..
			keep if proxy_1st <= 2018
			*/
			
			
			/*
			if "`area'" == "rur" keep if urban_siagie == 0
			if "`area'" == "urb" keep if urban_siagie == 1

			if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
			if "`hed_parent'" == "yes" 	keep if higher_ed_parent == 1
			*/
			
			if "`level'" == "all" {
				keep if grade>=1 & grade<=11
				//gen young = inlist(grade_2020,3,4,5,6)==1 if inlist(grade_2020,3,4,5,6,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2015,2016,2017,2018) if inlist(proxy_1st,2011,2012,2013,2014,2015,2016,2017,2018)==1
				gen young = inlist(grade,1,2,3,4,5,6)==1 if inlist(grade,1,2,3,4,5,6,7,8,9,10,11)
				local young_lab = "Primary" //Primary in 2020
				local old_lab 	= "Secondary"
				}
			if "`level'" == "elm" {
				keep if grade>=1 & grade<=6
				//gen young = inlist(grade_2020,3,4)==1 if inlist(grade_2020,3,4,5,6)
				//gen young = inlist(proxy_1st,2017,2018) if inlist(proxy_1st,2015,2016)==1
				//local young_lab = "2017-2018 cohort" //3rd-4th grade in 2020
				//local old_lab 	= "2015-2016 cohort" //5th-6th grade in 2020
				gen young = inlist(grade,1,2,3)==1 if inlist(grade,1,2,3,4,5,6)
				local young_lab = "1st-3rd grade"
				local old_lab 	= "4th-6th grade"
				}
			if "`level'" == "sec" {
				keep if grade>=7	
				//gen young = inlist(grade_2020,7,8)==1 if inlist(grade_2020,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2014,2013) if inlist(proxy_1st,2011,2012)==1
				//local young_lab = "2014-2013 cohort" //7th-8th grade in 2020
				//local old_lab 	= "2011-2012 cohort" //9th-11th grade in 2020
				gen young = inlist(grade,7,8)==1 if inlist(grade,7,8,9,10,11)
				local young_lab = "7th-8th grade"
				local old_lab 	= "9th-11th grade"
				}

			if "`v'" == "std_gpa_m" 		local vlab = "gpa_m"
			if "`v'" == "std_gpa_c" 		local vlab = "gpa_c"
			if "`v'" == "std_gpa_m_adj" 	local vlab = "gpa_m_adj"
			if "`v'" == "std_gpa_c_adj" 	local vlab = "gpa_c_adj"					
			if "`v'" == "pass_math" 		local vlab = "pass_m"				
			if "`v'" == "pass_read" 		local vlab = "pass_c"				
			if "`v'" == "approved" 			local vlab = "pass"
			if "`v'" == "approved_first" 	local vlab = "passf"
	
			* All students
			di as result "*******" _n as text "All" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 , a(grade id_ie)
			estimates store all_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(grade id_ie)
			estimates store all_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1  , a(grade id_ie)
			estimates store all_`vlab'_3
			if ${max_sibs} == 4 eststo all_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1  , a(grade id_ie)
			
			*****
			* Panel B: Confounders - Demographics
			*****
			*- Male/Female
			di as result "*******" _n as text "Public" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & male_siagie==1 , a(grade id_ie)
			estimates store mal_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & male_siagie==1 , a(grade id_ie)
			estimates store mal_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & male_siagie==1  , a(grade id_ie)
			estimates store mal_`vlab'_3
			if ${max_sibs} == 4 eststo mal_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & male_siagie==1  , a(grade id_ie)

			di as result "*******" _n as text "Private" _n as result 
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & male_siagie==0 , a(grade id_ie)
			estimates store fem_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & male_siagie==0 , a(grade id_ie)
			estimates store fem_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & male_siagie==0  , a(grade id_ie)
			estimates store fem_`vlab'_3
			if ${max_sibs} == 4 eststo fem_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & male_siagie==0  , a(grade id_ie)
								
			*- By age
			di as result "*******" _n as text "Younger cohort" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & young==1 , a(grade id_ie)
			estimates store young_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & young==1 , a(grade id_ie)
			estimates store young_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & young==1  , a(grade id_ie)
			estimates store young_`vlab'_3
			if ${max_sibs} == 4 eststo young_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & young==1  , a(grade id_ie)
			
			di as result "*******" _n as text "Older cohort" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & young==0 , a(grade id_ie)
			estimates store old_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & young==0 , a(grade id_ie)
			estimates store old_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & young==0  , a(grade id_ie)
			estimates store old_`vlab'_3
			if ${max_sibs} == 4 eststo old_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & young==0  , a(grade id_ie)
	
			
			
			if ${max_sibs}==4 local legend_child_${max_sibs} = "4 children"	
			if ${max_sibs}==4 local legend_sib_${max_sibs} = "3 siblings"	
	
				
				if inlist("`v'","std_gpa_m","std_gpa_c","std_gpa_m_adj","std_gpa_c_adj")==1 {
					local xmin = -0.04
					local xlines = "-.1 -.08 -.06 -.04 -.02 .02"
				}
				if inlist("`v'","pass_math","pass_read")==1 {
					local xmin = -0.04
					local xlines = "-.04 -.02 .02"
				}
				 
				*Only main TWFE 
				coefplot 	(all_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("All Students") ///
							|| ///
							(mal_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Boys") ///
							|| ///
							(fem_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Girls") ///
							|| ///
							(young_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("`young_lab'") ///
							|| ///
							(old_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("`old_lab'") ///
							|| ///
							, ///
							keep(treated_post) ///
							xtitle("Standardized GPA", size(medsmall) height(5)) ///
							xlabel(`xmin'(0.02)0.02) ///
							xline(0, lcolor(gs12)) ///
							xline(`xlines', lcolor(gs15))  ///
							grid(none) ///
							bycoefs	
				
						
				*- All TWFE by # of siblings	
				if "${covid_data}" == "_TEST" {
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_B_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_B_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}
				if "${covid_data}" == "" {
					capture qui graph export "$FIGURES\TWFE\covid_twfe_B_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES\TWFE\covid_twfe_B_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}	 
				 
				coefplot 	(all_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(all_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(all_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("All Students") ///
							||  ///
							(mal_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(mal_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(mal_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Boys") ///
							||  ///
							(fem_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(fem_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(fem_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Girls") ///
							||  ///
							(young_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(young_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(young_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("`young_lab'") ///
							||  ///
							(old_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(old_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(old_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("`old_lab'") ///
							||  ///
							, ///
							keep(treated_post) ///
							legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
							xtitle("Standardized GPA", size(medsmall) height(5)) ///
							xlabel(`xmin'(0.02)0.02) ///
							xline(0, lcolor(gs12)) ///
							xline(`xlines', lcolor(gs15))  ///
							grid(none) ///
							bycoefs	
				
						
				//graph save "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.gph" , replace	
				//capture qui graph export "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.eps", replace	
				if "${covid_data}" == "_TEST" {
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_sibs_B_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_sibs_B_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}
				if "${covid_data}" == "" {
					capture qui graph export "$FIGURES\TWFE\covid_twfe_sibs_B_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES\TWFE\covid_twfe_sibs_B_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}	
	/*
			coefplot all_`vlab'_?, ///
					bylabel("All Students") ///
					|| mal_`vlab'_?, ///
					bylabel("Boys") ///
					|| fem_`vlab'_?, ///
					bylabel("Girls") ///
					|| young_`vlab'_?, ///
					bylabel("`young_lab'") ///
					|| old_`vlab'_?, ///
					bylabel("`old_lab'") ///
					keep(treated_post) ///
					legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
					xtitle("Standard Deviations", size(medsmall) height(5)) ///
					xlabel(-.1(0.02)0.02) ///
					xline(0, lcolor(gs12)) ///
					xline(-.1 -.08 -.06 -.04 -.02 .02, lcolor(gs15))  ///
					///xlabel(-.1 "-0.8" -.4 "-0.4" 0 "0" .4 "0.4" .8 "0.8", labsize(medsmall)) ///
					///ciopts(recast(rcap) lwidth(medium)) ///
					grid(none) ///
					///yscale(reverse) ///
					bycoefs	
			
					
			//graph save "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.gph" , replace	
			//capture qui graph export "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.eps", replace	
			capture qui graph export "$FIGURES\TWFE\covid_twfe_B_`level'_`vlab'_${max_sibs}${covid_data}.png", replace	
			capture qui graph export "$FIGURES\TWFE\covid_twfe_B_`level'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
		*/	
			
		}
	}
	}

end


***********************************************


capture program drop twfe_C
program define twfe_C
		
	
	clear

	*- TWFE Estimates

	foreach v in /*"std_gpa_m" "std_gpa_c"*/ "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" /*"approved" "approved_first"*/ {
		foreach only_covid in "20-21" "all" {
			foreach level in "all" "elm" "sec" {
			
			if ${covid_test} == 1 & inlist("`v'","std_gpa_m_adj","pass_math")==0 continue
			if ${covid_test} == 1 & inlist("`level'","sec")==1 continue
			if ${covid_test} == 1 & inlist("`only_covid'","all")==1 continue
			
			estimates clear
			global x = "$x_all"
			if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"	
			

			use ///
			/*OUTCOME*/		`v'  ///
			/*ID*/ 			id_ie id_per_umc year grade ///
			/*FAMILY*/		fam_order_${fam_type} fam_total_${fam_type} ///
			/*DID*/			treated post treated_post ///
			/*EVENT*/		year_t_?? ///
			/*Demog*/		public_siagie urban_siagie male_siagie  ${x} ///
			/*A*/ 			min_socioec_index_ie_cat /*OTHER IN DEMOG*/ ///
			/*B*/			/*GRADE AND MALE*/ ///
			/*C*/			closest_age_gap* ///
			/*D*/			///educ_cat_mother higher_ed_parent lives_with_mother lives_with_father ///
			/*Other*/		/**has_internet *has_comp *low_ses *quiet_room*/ ///
			using "$TEMP\pre_reg_covid${covid_data}", clear
						
			*- Remove early grades and years
			keep if year>=2016
			drop if grade==0
			
			*- Keep only 2020-2021 (exclude 2022,2023,2024) from the TWFE estimates
			if "`only_covid'" == "20-21" keep if year<=2021
						
			*- Divide sample based on grade in 2020
			//bys id_per_umc: egen grade_2020	= min(cond(year==2020,grade,.))
			
			*- Divide sample based on expected cohort
			bys id_per_umc: egen min_year 		= min(year)
			bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
			gen proxy_1st = min_year - grade_min_year  + 1
							
			
			/*
			*- Not enough pre-years
						
			drop if inlist(grade_2020,1,2)==1
			drop if grade_2020==3 & year<=2017 //<=2017 Would only include those who repeated..
			drop if grade_2020==4 & year<=2016 //<=2016 Would only include those who repeated..
			keep if proxy_1st <= 2018
			*/
			
			
			/*
			if "`area'" == "rur" keep if urban_siagie == 0
			if "`area'" == "urb" keep if urban_siagie == 1

			if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
			if "`hed_parent'" == "yes" 	keep if higher_ed_parent == 1
			*/
			
			if "`level'" == "all" {
				keep if grade>=1 & grade<=11
				//gen young = inlist(grade_2020,3,4,5,6)==1 if inlist(grade_2020,3,4,5,6,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2015,2016,2017,2018) if inlist(proxy_1st,2011,2012,2013,2014,2015,2016,2017,2018)==1
				gen young = inlist(grade,1,2,3,4,5,6)==1 if inlist(grade,1,2,3,4,5,6,7,8,9,10,11)
				local young_lab = "Primary" //Primary in 2020
				local old_lab 	= "Secondary"
				}
			if "`level'" == "elm" {
				keep if grade>=1 & grade<=6
				//gen young = inlist(grade_2020,3,4)==1 if inlist(grade_2020,3,4,5,6)
				//gen young = inlist(proxy_1st,2017,2018) if inlist(proxy_1st,2015,2016)==1
				//local young_lab = "2017-2018 cohort" //3rd-4th grade in 2020
				//local old_lab 	= "2015-2016 cohort" //5th-6th grade in 2020
				gen young = inlist(grade,1,2,3)==1 if inlist(grade,1,2,3,4,5,6)
				local young_lab = "1st-3rd grade"
				local old_lab 	= "4th-6th grade"
				}
			if "`level'" == "sec" {
				keep if grade>=7	
				//gen young = inlist(grade_2020,7,8)==1 if inlist(grade_2020,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2014,2013) if inlist(proxy_1st,2011,2012)==1
				//local young_lab = "2014-2013 cohort" //7th-8th grade in 2020
				//local old_lab 	= "2011-2012 cohort" //9th-11th grade in 2020
				gen young = inlist(grade,7,8)==1 if inlist(grade,7,8,9,10,11)
				local young_lab = "7th-8th grade"
				local old_lab 	= "9th-11th grade"
				}

			if "`v'" == "std_gpa_m" 		local vlab = "gpa_m"
			if "`v'" == "std_gpa_c" 		local vlab = "gpa_c"
			if "`v'" == "std_gpa_m_adj" 	local vlab = "gpa_m_adj"
			if "`v'" == "std_gpa_c_adj" 	local vlab = "gpa_c_adj"					
			if "`v'" == "pass_math" 		local vlab = "pass_m"				
			if "`v'" == "pass_read" 		local vlab = "pass_c"				
			if "`v'" == "approved" 			local vlab = "pass"
			if "`v'" == "approved_first" 	local vlab = "passf"
	
			* All students
			di as result "*******" _n as text "All" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 , a(grade id_ie)
			estimates store all_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(grade id_ie)
			estimates store all_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1  , a(grade id_ie)
			estimates store all_`vlab'_3
			if ${max_sibs} == 4 eststo all_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1  , a(grade id_ie)
			
			*****
			* Panel C: Mechanisms - Family structure - Siblings
			*****

			
			*- Birth Order
			di as result "*******" _n as text "Oldest" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & inlist(fam_order_${fam_type},1)==1 , a(grade id_ie)
			estimates store first_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & inlist(fam_order_${fam_type},1)==1 , a(grade id_ie)
			estimates store first_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & inlist(fam_order_${fam_type},1)==1  , a(grade id_ie)
			estimates store first_`vlab'_3
			if ${max_sibs} == 4 eststo first_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & inlist(fam_order_${fam_type},1)==1  , a(grade id_ie)
			
			di as result "*******" _n as text "Middle" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & (fam_total_${fam_type}==1 | (fam_total_${fam_type}>1 & fam_order_${fam_type}!=1 & fam_order_${fam_type}!=fam_total_${fam_type})) , a(grade id_ie)
			estimates store mid_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & (fam_total_${fam_type}==1 | (fam_total_${fam_type}>1 & fam_order_${fam_type}!=1 & fam_order_${fam_type}!=fam_total_${fam_type})) , a(grade id_ie)
			estimates store mid_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & (fam_total_${fam_type}==1 | (fam_total_${fam_type}>1 & fam_order_${fam_type}!=1 & fam_order_${fam_type}!=fam_total_${fam_type}))  , a(grade id_ie)
			estimates store mid_`vlab'_3
			if ${max_sibs} == 4 eststo mid_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & (fam_total_${fam_type}==1 | (fam_total_${fam_type}>1 & fam_order_${fam_type}!=1 & fam_order_${fam_type}!=fam_total_${fam_type})) , a(grade id_ie)			
			
			di as result "*******" _n as text "Youngest" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & fam_order_${fam_type}==fam_total_${fam_type} , a(grade id_ie)
			estimates store last_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & fam_order_${fam_type}==fam_total_${fam_type} , a(grade id_ie)
			estimates store last_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & fam_order_${fam_type}==fam_total_${fam_type}  , a(grade id_ie)
			estimates store last_`vlab'_3
			if ${max_sibs} == 4 eststo last_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & fam_order_${fam_type}==fam_total_${fam_type}  , a(grade id_ie)		
			
			*- Gap <=2
			di as result "*******" _n as text "Close Age sibling (<=2 year difference)" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & ((closest_age_gap_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store g02_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & ((closest_age_gap_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store g02_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & ((closest_age_gap_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)
			estimates store g02_`vlab'_3
			if ${max_sibs} == 4 eststo g02_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & ((closest_age_gap_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)
			/*
			*- Gap 3-5
			di as result "*******" _n as text "Close Age sibling (3-5 year difference)" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & ((closest_age_gap_2>=3 & closest_age_gap_2<=5 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store g35_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & ((closest_age_gap_2>=3 & closest_age_gap_2<=5 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store g35_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & ((closest_age_gap_2>=3 & closest_age_gap_2<=5 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)
			estimates store g35_`vlab'_3
			if ${max_sibs} == 4 eststo g35_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & ((closest_age_gap_2>=3 & closest_age_gap_2<=5 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)
			
			*- Gap 6+
			di as result "*******" _n as text "Close Age sibling (>=6 year difference)" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & ((closest_age_gap_2>=6 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store g6m_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & ((closest_age_gap_2>=6 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store g6m_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & ((closest_age_gap_2>=6 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)
			estimates store g6m_`vlab'_3
			if ${max_sibs} == 4 eststo g6m_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & ((closest_age_gap_2>=6 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)
			*/			
			*- Younger Gap <=2
			di as result "*******" _n as text "Younger sibling within 2 years" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & ((closest_age_gap_younger<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store y02_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & ((closest_age_gap_younger<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store y02_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & ((closest_age_gap_younger<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)
			estimates store y02_`vlab'_3
			if ${max_sibs} == 4 eststo y02_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & ((closest_age_gap_younger<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)
			
			*- Same sex Gap <=2
			di as result "*******" _n as text "Same sex sibling within 2 years" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & ((closest_age_gap_samesex_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store s02_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & ((closest_age_gap_samesex_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store s02_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & ((closest_age_gap_samesex_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)
			estimates store s02_`vlab'_3
			if ${max_sibs} == 4 eststo s02_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & ((closest_age_gap_samesex_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)

			/*
			*- Male gap <=2
			di as result "*******" _n as text "Male sibling within 2 years" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & ((closest_age_gap_male_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store m02_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & ((closest_age_gap_male_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store m02_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & ((closest_age_gap_male_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)
			estimates store m02_`vlab'_3
			if ${max_sibs} == 4 eststo m02_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & ((closest_age_gap_male_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)
			
			*- Female gap <=2
			di as result "*******" _n as text "Female sibling within 3 years" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & ((closest_age_gap_female_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store f02_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & ((closest_age_gap_female_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1)), a(grade id_ie)
			estimates store f02_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & ((closest_age_gap_female_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)
			estimates store f02_`vlab'_3
			if ${max_sibs} == 4 eststo f02_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & ((closest_age_gap_female_2<=2 & fam_total_${fam_type}>1) | (fam_total_${fam_type}==1))  , a(grade id_ie)
			*/

			if ${max_sibs}==4 local legend_child_${max_sibs} = "4 children"	
			if ${max_sibs}==4 local legend_sib_${max_sibs} = "3 siblings"	
	
				
				if inlist("`v'","std_gpa_m","std_gpa_c","std_gpa_m_adj","std_gpa_c_adj")==1 {
					local xmin = -0.04
					local xlines = "-.1 -.08 -.06 -.04 -.02 .02"
				}
				if inlist("`v'","pass_math","pass_read")==1 {
					local xmin = -0.04
					local xlines = "-.04 -.02 .02"
				}
				 
				 
				 	 
				*Only main TWFE 
				coefplot 	(all_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("All Students") ///
							||  ///
							(first_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Oldest child") ///
							||  ///
							(mid_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Middle child") ///
							||  ///
							(last_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Youngest child") ///
							||  ///
							(g02_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Closest Sibling within 0-2 years") ///
							||  ///
							(y02_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Younger sibling within 0-2 years") ///
							||  ///
							(s02_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Same sex sibling within 0-2 years") ///
							||  ///
							, ///
							keep(treated_post) ///
							xtitle("Standardized GPA", size(medsmall) height(5)) ///
							xlabel(`xmin'(0.02)0.02) ///
							xline(0, lcolor(gs12)) ///
							xline(`xlines', lcolor(gs15))  ///
							grid(none) ///
							bycoefs	
				
						
				*- All TWFE by # of siblings	
				if "${covid_data}" == "_TEST" {
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_C_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_C_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}
				if "${covid_data}" == "" {
					capture qui graph export "$FIGURES\TWFE\covid_twfe_C_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES\TWFE\covid_twfe_C_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}	 
				 
				coefplot 	(all_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(all_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(all_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("All Students") ///
							||  ///
							(first_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(first_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(first_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Oldest child") ///
							||  ///
							(mid_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(mid_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(mid_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Middle child") ///
							||  ///
							(last_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(last_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(last_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Youngest child") ///
							||  ///
							(g02_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(g02_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(g02_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Closest Sibling within 0-2 years") ///
							||  ///
							(y02_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(y02_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(y02_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Younger sibling within 0-2 years") ///
							||  ///
							(s02_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(s02_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(s02_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Same sex sibling within 0-2 years") ///
							||  ///
							, ///
							keep(treated_post) ///
							legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
							xtitle("Standardized GPA", size(medsmall) height(5)) ///
							xlabel(`xmin'(0.02)0.02) ///
							xline(0, lcolor(gs12)) ///
							xline(`xlines', lcolor(gs15))  ///
							grid(none) ///
							bycoefs	
				
						
				//graph save "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.gph" , replace	
				//capture qui graph export "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.eps", replace	
				if "${covid_data}" == "_TEST" {
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_sibs_C_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_sibs_C_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}
				if "${covid_data}" == "" {
					capture qui graph export "$FIGURES\TWFE\covid_twfe_sibs_C_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES\TWFE\covid_twfe_sibs_C_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}	
	/*
			coefplot all_`vlab'_?, ///
					bylabel("All Students") ///
					|| first_`vlab'_?, ///
					bylabel("Oldest child") ///
					|| mid_`vlab'_?, ///
					bylabel("Middle child") ///
					|| last_`vlab'_?, ///
					bylabel("Youngest child") ///
					|| g02_`vlab'_?, ///
					bylabel("Closest Sibling within 0-2 years") ///
					|| g35_`vlab'_?, ///
					bylabel("Closest Sibling within 3-5 years") ///
					|| g6m_`vlab'_?, ///
					bylabel("Closest Sibling beyond 6+ years") ///
					|| y02_`vlab'_?, ///
					bylabel("Younger sibling within 0-2 years") ///
					|| s02_`vlab'_?, ///
					bylabel("Same sex sibling within 0-2 years") ///
					|| m02_`vlab'_?, ///
					bylabel("Male sibling within 0-2 years") ///
					|| f02_`vlab'_?, ///
					bylabel("Female sibling within 0-2 years") ///
					keep(treated_post) ///
					legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
					xtitle("Standard Deviations", size(medsmall) height(5)) ///
					xlabel(-.1(0.02)0.02) ///
					xline(0, lcolor(gs12)) ///
					xline(-.1 -.08 -.06 -.04 -.02 .02, lcolor(gs15))  ///
					///xlabel(-.1 "-0.8" -.4 "-0.4" 0 "0" .4 "0.4" .8 "0.8", labsize(medsmall)) ///
					///ciopts(recast(rcap) lwidth(medium)) ///
					grid(none) ///
					///yscale(reverse) ///
					bycoefs	
			
					
			//graph save "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.gph" , replace	
			//capture qui graph export "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.eps", replace	
			capture qui graph export "$FIGURES\TWFE\covid_twfe_C_`level'_`vlab'_${max_sibs}${covid_data}.png", replace	
			capture qui graph export "$FIGURES\TWFE\covid_twfe_C_`level'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
		*/	
			
		}
	}
}

end



***********************************************

capture program drop twfe_D
program define twfe_D
		
	
	clear

	*- TWFE Estimates

	foreach v in /*"std_gpa_m" "std_gpa_c"*/ "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" /*"approved" "approved_first"*/ {
		foreach only_covid in "20-21" "all" {
			foreach level in "all" "elm" "sec" {
			
			if ${covid_test} == 1 & inlist("`v'","std_gpa_m_adj","pass_math")==0 continue
			if ${covid_test} == 1 & inlist("`level'","sec")==1 continue
			if ${covid_test} == 1 & inlist("`only_covid'","all")==1 continue	
			
			estimates clear
			global x = "$x_all"
			if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"	
			

			use ///
			/*OUTCOME*/		`v'  ///
			/*ID*/ 			id_ie id_per_umc year grade ///
			/*FAMILY*/		fam_order_${fam_type} fam_total_${fam_type} ///
			/*DID*/			treated post treated_post ///
			/*EVENT*/		year_t_?? ///
			/*Demog*/		public_siagie urban_siagie male_siagie  ${x} ///
			/*A*/ 			min_socioec_index_ie_cat /*OTHER IN DEMOG*/ ///
			/*B*/			/*GRADE AND MALE*/ ///
			/*C*/			///closest_age_gap* ///
			/*D*/			educ_cat_mother higher_ed_parent lives_with_mother lives_with_father ///
			/*Other*/		/**has_internet *has_comp *low_ses *quiet_room*/ ///
			using "$TEMP\pre_reg_covid${covid_data}", clear
			
			*- Remove early grades and years
			keep if year>=2016
			drop if grade==0
			
			*- Keep only 2020-2021 (exclude 2022,2023,2024) from the TWFE estimates
			if "`only_covid'" == "20-21" keep if year<=2021
			
			*- Divide sample based on grade in 2020
			//bys id_per_umc: egen grade_2020	= min(cond(year==2020,grade,.))
			
			*- Divide sample based on expected cohort
			bys id_per_umc: egen min_year 		= min(year)
			bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
			gen proxy_1st = min_year - grade_min_year  + 1
							
			
			/*
			*- Not enough pre-years
						
			drop if inlist(grade_2020,1,2)==1
			drop if grade_2020==3 & year<=2017 //<=2017 Would only include those who repeated..
			drop if grade_2020==4 & year<=2016 //<=2016 Would only include those who repeated..
			keep if proxy_1st <= 2018
			*/
			
			
			/*
			if "`area'" == "rur" keep if urban_siagie == 0
			if "`area'" == "urb" keep if urban_siagie == 1

			if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
			if "`hed_parent'" == "yes" 	keep if higher_ed_parent == 1
			*/
			
			if "`level'" == "all" {
				keep if grade>=1 & grade<=11
				//gen young = inlist(grade_2020,3,4,5,6)==1 if inlist(grade_2020,3,4,5,6,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2015,2016,2017,2018) if inlist(proxy_1st,2011,2012,2013,2014,2015,2016,2017,2018)==1
				gen young = inlist(grade,1,2,3,4,5,6)==1 if inlist(grade,1,2,3,4,5,6,7,8,9,10,11)
				local young_lab = "Primary" //Primary in 2020
				local old_lab 	= "Secondary"
				}
			if "`level'" == "elm" {
				keep if grade>=1 & grade<=6
				//gen young = inlist(grade_2020,3,4)==1 if inlist(grade_2020,3,4,5,6)
				//gen young = inlist(proxy_1st,2017,2018) if inlist(proxy_1st,2015,2016)==1
				//local young_lab = "2017-2018 cohort" //3rd-4th grade in 2020
				//local old_lab 	= "2015-2016 cohort" //5th-6th grade in 2020
				gen young = inlist(grade,1,2,3)==1 if inlist(grade,1,2,3,4,5,6)
				local young_lab = "1st-3rd grade"
				local old_lab 	= "4th-6th grade"
				}
			if "`level'" == "sec" {
				keep if grade>=7	
				//gen young = inlist(grade_2020,7,8)==1 if inlist(grade_2020,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2014,2013) if inlist(proxy_1st,2011,2012)==1
				//local young_lab = "2014-2013 cohort" //7th-8th grade in 2020
				//local old_lab 	= "2011-2012 cohort" //9th-11th grade in 2020
				gen young = inlist(grade,7,8)==1 if inlist(grade,7,8,9,10,11)
				local young_lab = "7th-8th grade"
				local old_lab 	= "9th-11th grade"
				}

			if "`v'" == "std_gpa_m" 		local vlab = "gpa_m"
			if "`v'" == "std_gpa_c" 		local vlab = "gpa_c"	
			if "`v'" == "std_gpa_m_adj" 	local vlab = "gpa_m_adj"
			if "`v'" == "std_gpa_c_adj" 	local vlab = "gpa_c_adj"				
			if "`v'" == "pass_math" 		local vlab = "pass_m"				
			if "`v'" == "pass_read" 		local vlab = "pass_c"				
			if "`v'" == "approved" 			local vlab = "pass"
			if "`v'" == "approved_first" 	local vlab = "passf"
	
			* All students
			di as result "*******" _n as text "All" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 , a(grade id_ie)
			estimates store all_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(grade id_ie)
			estimates store all_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1  , a(grade id_ie)
			estimates store all_`vlab'_3
			if ${max_sibs} == 4 eststo all_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1  , a(grade id_ie)
			
			
			
			*****
			* Panel B: Mechanisms
			*****
			
			*- Parents Have some level of higher education
			/*
			di as result "*******" _n as text "Some Higher Ed" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & higher_ed_parent==1 , a(grade id_ie)
			estimates store yhed_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & higher_ed_parent==1 , a(grade id_ie)
			estimates store yhed_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & higher_ed_parent==1  , a(grade id_ie)
			estimates store yhed_`vlab'_3
			if ${max_sibs} == 4 eststo yhed_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & higher_ed_parent==1  , a(grade id_ie)
			
			di as result "*******" _n as text "No Higher ed" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & higher_ed_parent==0 , a(grade id_ie)
			estimates store nhed_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & higher_ed_parent==0 , a(grade id_ie)
			estimates store nhed_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & higher_ed_parent==0  , a(grade id_ie)
			estimates store nhed_`vlab'_3
			if ${max_sibs} == 4 eststo nhed_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & higher_ed_parent==0  , a(grade id_ie)
			*/
			*- Mother's education
			di as result "*******" _n as text "Incomplete Secondary" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & educ_cat_mother==1 , a(grade id_ie)
			estimates store edu1_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & educ_cat_mother==1 , a(grade id_ie)
			estimates store edu1_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & educ_cat_mother==1  , a(grade id_ie)
			estimates store edu1_`vlab'_3
			if ${max_sibs} == 4 eststo edu1_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & educ_cat_mother==1  , a(grade id_ie)
			
			di as result "*******" _n as text "Completed Secondary" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & educ_cat_mother==2 , a(grade id_ie)
			estimates store edu2_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & educ_cat_mother==2 , a(grade id_ie)
			estimates store edu2_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & educ_cat_mother==2  , a(grade id_ie)
			estimates store edu2_`vlab'_3
			if ${max_sibs} == 4 eststo edu2_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & educ_cat_mother==2  , a(grade id_ie)
			
			di as result "*******" _n as text "Some level of higher education" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & educ_cat_mother==3 , a(grade id_ie)
			estimates store edu3_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & educ_cat_mother==3 , a(grade id_ie)
			estimates store edu3_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & educ_cat_mother==3  , a(grade id_ie)
			estimates store edu3_`vlab'_3
			if ${max_sibs} == 4 eststo edu3_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & educ_cat_mother==3  , a(grade id_ie)
			
			*- Lives with parents
			di as result "*******" _n as text "Lives with both parents" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & (lives_with_mother==1 & lives_with_father==1) , a(grade id_ie)
			estimates store both_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & (lives_with_mother==1 & lives_with_father==1) , a(grade id_ie)
			estimates store both_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & (lives_with_mother==1 & lives_with_father==1) , a(grade id_ie)
			estimates store both_`vlab'_3
			if ${max_sibs} == 4 eststo both_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & (lives_with_mother==1 & lives_with_father==1)  , a(grade id_ie)
			
			di as result "*******" _n as text "Only lives with one parent" _n as result 
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 &  ((lives_with_mother==1 & lives_with_father==0) | (lives_with_mother==0 & lives_with_father==1)) , a(grade id_ie)
			estimates store one_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 &  ((lives_with_mother==1 & lives_with_father==0) | (lives_with_mother==0 & lives_with_father==1)) , a(grade id_ie)
			estimates store one_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & ((lives_with_mother==1 & lives_with_father==0) | (lives_with_mother==0 & lives_with_father==1))   , a(grade id_ie)
			estimates store one_`vlab'_3
			if ${max_sibs} == 4 eststo one_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & ((lives_with_mother==1 & lives_with_father==0) | (lives_with_mother==0 & lives_with_father==1))   , a(grade id_ie)
			
			di as result "*******" _n as text "Doesn't live with parents" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 & (lives_with_mother==0 & lives_with_father==0) , a(grade id_ie)
			estimates store none_`vlab'
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & (lives_with_mother==0 & lives_with_father==0) , a(grade id_ie)
			estimates store none_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & (lives_with_mother==0 & lives_with_father==0) , a(grade id_ie)
			estimates store none_`vlab'_3
			if ${max_sibs} == 4 eststo none_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & (lives_with_mother==0 & lives_with_father==0)  , a(grade id_ie)


			
			
			if ${max_sibs}==4 local legend_child_${max_sibs} = "4 children"	
			if ${max_sibs}==4 local legend_sib_${max_sibs} = "3 siblings"	
			
				
				if inlist("`v'","std_gpa_m","std_gpa_c","std_gpa_m_adj","std_gpa_c_adj")==1 {
					local xmin = -0.04
					local xlines = "-.1 -.08 -.06 -.04 -.02 .02"
				}
				if inlist("`v'","pass_math","pass_read")==1 {
					local xmin = -0.04
					local xlines = "-.04 -.02 .02"
				}
				 
coefplot all_`vlab'_?, ///
					bylabel("All Students") ///
					|| edu1_`vlab'_?, ///
					bylabel("Mother did not complete Secondary") ///
					|| edu2_`vlab'_?, ///
					bylabel("Mother completed Secondary") ///
					|| edu3_`vlab'_?, ///
					bylabel("Mother with some level of Higher ed.") ///
					|| both_`vlab'_?, ///
					bylabel("Lives with both parents") ///					
					|| one_`vlab'_?, ///
					bylabel("Lives with one parent") ///
					|| none_`vlab'_?, ///
					bylabel("Does not live with parents") ///
					keep(treated_post) ///
					legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
					xtitle("Standard Deviations", size(medsmall) height(5)) ///
					xlabel(-.1(0.02)0.02) ///
					xline(0, lcolor(gs12)) ///
					xline(-.1 -.08 -.06 -.04 -.02 .02, lcolor(gs15))  ///
					///xlabel(-.1 "-0.8" -.4 "-0.4" 0 "0" .4 "0.4" .8 "0.8", labsize(medsmall)) ///
					///ciopts(recast(rcap) lwidth(medium)) ///
					grid(none) ///
					///yscale(reverse) ///
					bycoefs	
							 
				 
				 
				*Only main TWFE 
				coefplot 	(all_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("All Students") ///
							||  ///
							(edu1_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Mother did not complete Secondary") ///
							||  ///
							(edu2_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Mother completed Secondary") ///
							||  ///
							(edu3_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Mother with some level of Higher ed.") ///
							||  ///
							(both_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Lives with both parents") ///
							||  ///
							(one_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Lives with one parent") ///
							||  ///
							(none_`vlab', mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							, ///
							bylabel("Does not live with parents") ///
							||  ///
							, ///
							keep(treated_post) ///
							xtitle("Standardized GPA", size(medsmall) height(5)) ///
							xlabel(`xmin'(0.02)0.02) ///
							xline(0, lcolor(gs12)) ///
							xline(`xlines', lcolor(gs15))  ///
							grid(none) ///
							bycoefs	
				
						
				*- All TWFE by # of siblings	
				if "${covid_data}" == "_TEST" {
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_D_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_D_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}
				if "${covid_data}" == "" {
					capture qui graph export "$FIGURES\TWFE\covid_twfe_D_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES\TWFE\covid_twfe_D_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}	 
				 
				coefplot 	(all_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(all_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(all_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("All Students") ///
							||  ///
							///(urb_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							///(urb_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							///(urb_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							///, ///
							///bylabel("Urban") ///
							///||  ///
							(edu1_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(edu1_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(edu1_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Mother did not complete Secondary") ///
							||  ///
							(edu2_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(edu2_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(edu2_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Mother completed Secondary") ///
							||  ///
							(edu3_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(edu3_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(edu3_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Mother with some level of Higher ed.") ///
							||  ///
							(both_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(both_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(both_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Lives with both parents") ///
							||  ///
							(one_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(one_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(one_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Lives with one parent") ///
							|| ///
							(none_`vlab'_2, mcolor("${blue_1}") ciopts(color("${blue_1}"))) ///
							(none_`vlab'_3, mcolor("${blue_2}") ciopts(color("${blue_2}"))) ///
							(none_`vlab'_4, mcolor("${blue_3}") ciopts(color("${blue_3}"))) ///
							, ///
							bylabel("Does not live with parents") ///
							||  ///
							, ///
							keep(treated_post) ///
							legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
							xtitle("Standardized GPA", size(medsmall) height(5)) ///
							xlabel(`xmin'(0.02)0.02) ///
							xline(0, lcolor(gs12)) ///
							xline(`xlines', lcolor(gs15))  ///
							grid(none) ///
							bycoefs	
				
						
				//graph save "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.gph" , replace	
				//capture qui graph export "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.eps", replace	
				if "${covid_data}" == "_TEST" {
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_sibs_D_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					capture qui graph export "$FIGURES_TEMP\TWFE\covid_twfe_sibs_D_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					}
				if "${covid_data}" == "" {
					capture qui graph export "$FIGURES\TWFE\covid_twfe_sibs_D_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
					capture qui graph export "$FIGURES\TWFE\covid_twfe_sibs_D_`level'_`only_covid'_`vlab'_${max_sibs}${covid_data}.png", replace	
					}			
			/*
			coefplot all_`vlab'_?, ///
					bylabel("All Students") ///
					|| edu1_`vlab'_?, ///
					bylabel("Mother did not complete Secondary") ///
					|| edu2_`vlab'_?, ///
					bylabel("Mother completed Secondary") ///
					|| edu3_`vlab'_?, ///
					bylabel("Mother with some level of Higher ed.") ///
					|| both_`vlab'_?, ///
					bylabel("Lives with both parents") ///					
					|| one_`vlab'_?, ///
					bylabel("Lives with one parent") ///
					|| none_`vlab'_?, ///
					bylabel("Does not live with parents") ///
					keep(treated_post) ///
					legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
					xtitle("Standard Deviations", size(medsmall) height(5)) ///
					xlabel(-.1(0.02)0.02) ///
					xline(0, lcolor(gs12)) ///
					xline(-.1 -.08 -.06 -.04 -.02 .02, lcolor(gs15))  ///
					///xlabel(-.1 "-0.8" -.4 "-0.4" 0 "0" .4 "0.4" .8 "0.8", labsize(medsmall)) ///
					///ciopts(recast(rcap) lwidth(medium)) ///
					grid(none) ///
					///yscale(reverse) ///
					bycoefs	
			
					
			//graph save "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.gph" , replace	
			//capture qui graph export "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.eps", replace	
			capture qui graph export "$FIGURES\TWFE\covid_twfe_D_`level'_`vlab'_${max_sibs}${covid_data}.png", replace	
			capture qui graph export "$FIGURES\TWFE\covid_twfe_D_`level'_`vlab'_${max_sibs}${covid_data}.pdf", replace	
			*/
			
			}
		}
	}

end


***********************************************

capture program drop twfe_cohorts
program define twfe_cohorts	
		
	
	clear

	*- TWFE Estimates

	foreach level in "all" /*"elm" "sec"*/ {
		foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj"  "pass_math" "pass_read" /*"approved" "approved_first"*/ {
			
			estimates clear
			global x = "$x_all"
			if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"	
			

			use `v' pass_math pass_read approved approved_first id_per_umc year_t_?? public_siagie urban_siagie male_siagie educ_cat_mother higher_ed_parent lives_with_mother lives_with_father *has_internet *has_comp *low_ses *quiet_room year grade treated post treated_post id_ie fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid${covid_data}", clear
			
			*- Remove early grades and years
			keep if year>=2016
			drop if grade==0
			
			
			*- Divide sample based on grade in 2020
			//bys id_per_umc: egen grade_2020	= min(cond(year==2020,grade,.))
			
			*- Divide sample based on expected cohort
			bys id_per_umc: egen min_year 		= min(year)
			bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
			gen proxy_1st = min_year - grade_min_year  + 1
							
			
			/*
			*- Not enough pre-years
						
			drop if inlist(grade_2020,1,2)==1
			drop if grade_2020==3 & year<=2017 //<=2017 Would only include those who repeated..
			drop if grade_2020==4 & year<=2016 //<=2016 Would only include those who repeated..
			keep if proxy_1st <= 2018
			*/
			
			
			/*
			if "`area'" == "rur" keep if urban_siagie == 0
			if "`area'" == "urb" keep if urban_siagie == 1

			if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
			if "`hed_parent'" == "yes" 	keep if higher_ed_parent == 1
			*/
			
			if "`level'" == "all" {
				keep if grade>=1 & grade<=11
				//gen young = inlist(grade_2020,3,4,5,6)==1 if inlist(grade_2020,3,4,5,6,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2015,2016,2017,2018) if inlist(proxy_1st,2011,2012,2013,2014,2015,2016,2017,2018)==1
				gen young = inlist(grade,1,2,3,4,5,6)==1 if inlist(grade,1,2,3,4,5,6,7,8,9,10,11)
				local young_lab = "Primary" //Primary in 2020
				local old_lab 	= "Secondary"
				}
			if "`level'" == "elm" {
				keep if grade>=1 & grade<=6
				//gen young = inlist(grade_2020,3,4)==1 if inlist(grade_2020,3,4,5,6)
				//gen young = inlist(proxy_1st,2017,2018) if inlist(proxy_1st,2015,2016)==1
				//local young_lab = "2017-2018 cohort" //3rd-4th grade in 2020
				//local old_lab 	= "2015-2016 cohort" //5th-6th grade in 2020
				gen young = inlist(grade,1,2,3)==1 if inlist(grade,1,2,3,4,5,6)
				local young_lab = "1st-3rd grade"
				local old_lab 	= "4th-6th grade"
				}
			if "`level'" == "sec" {
				keep if grade>=7	
				//gen young = inlist(grade_2020,7,8)==1 if inlist(grade_2020,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2014,2013) if inlist(proxy_1st,2011,2012)==1
				//local young_lab = "2014-2013 cohort" //7th-8th grade in 2020
				//local old_lab 	= "2011-2012 cohort" //9th-11th grade in 2020
				gen young = inlist(grade,7,8)==1 if inlist(grade,7,8,9,10,11)
				local young_lab = "7th-8th grade"
				local old_lab 	= "9th-11th grade"
				}

			if "`v'" == "std_gpa_m" 		local vlab = "gpa_m"
			if "`v'" == "std_gpa_c" 		local vlab = "gpa_c"
			if "`v'" == "std_gpa_m_adj" 	local vlab = "gpa_m_adj"
			if "`v'" == "std_gpa_c_adj" 	local vlab = "gpa_c_adj"					
			if "`v'" == "pass_math" 		local vlab = "pass_m"				
			if "`v'" == "pass_read" 		local vlab = "pass_c"				
			if "`v'" == "approved" 			local vlab = "pass"
			if "`v'" == "approved_first" 	local vlab = "passf"
	
			* All students
			di as result "*******" _n as text "All" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(grade id_ie)
			estimates store all_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1  , a(grade id_ie)
			estimates store all_`vlab'_3
			if ${max_sibs} == 4 eststo all_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1  , a(grade id_ie)
				
			if "`level'" == "all" {
				forvalues cohort = 2011(1)2018 {
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & proxy_1st==`cohort' , a(grade id_ie)
				estimates store c`cohort'_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & proxy_1st==`cohort' , a(grade id_ie)
				estimates store c`cohort'_`vlab'_3
				if ${max_sibs} == 4 eststo c`cohort'_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & proxy_1st==`cohort'  , a(grade id_ie)	
				}
				
				if ${max_sibs}==4 local legend_child_${max_sibs} = "4 children"	
				if ${max_sibs}==4 local legend_sib_${max_sibs} = "3 siblings"
				coefplot all_`vlab'_?, ///
						bylabel("All Students") ///
						|| c2011_`vlab'_?, ///
						bylabel("2011 cohort") ///
						|| c2012_`vlab'_?, ///
						bylabel("2012 cohort") ///
						|| c2013_`vlab'_?, ///
						bylabel("2013 cohort") ///
						|| c2014_`vlab'_?, ///
						bylabel("2014 cohort") ///
						|| c2015_`vlab'_?, ///
						bylabel("2015 cohort") ///
						|| c2016_`vlab'_?, ///
						bylabel("2016 cohort") ///
						|| c2017_`vlab'_?, ///
						bylabel("2017 cohort") ///
						|| c2018_`vlab'_?, ///
						bylabel("2018 cohort") ///
						keep(treated_post) ///
						legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
						xtitle("Standard Deviations", size(medsmall) height(5)) ///
						xlabel(-.1(0.02)0.02) ///
						xline(0, lcolor(gs12)) ///
						xline(-.1 -.08 -.06 -.04 -.02 .02, lcolor(gs15))  ///
						///xlabel(-.1 "-0.8" -.4 "-0.4" 0 "0" .4 "0.4" .8 "0.8", labsize(medsmall)) ///
						///ciopts(recast(rcap) lwidth(medium)) ///
						grid(none) ///
						///yscale(reverse) ///
						bycoefs	
				
						
				//graph save "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.gph" , replace	
				//capture qui graph export "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.eps", replace	
				capture qui graph export "$FIGURES\TWFE\covid_twfe_cohort_`vlab'_${max_sibs}${covid_data}.png", replace	
				capture qui graph export "$FIGURES\TWFE\covid_twfe_cohort_`vlab'_${max_sibs}${covid_data}.pdf", replace					
				
				}
				
		

			}
		}

end

***********************************************

capture program drop twfe_grades
program define twfe_grades	
		
	
	clear

	*- TWFE Estimates

	foreach level in "all" /*"elm" "sec"*/ {
		foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj"  "pass_math" "pass_read" /*"approved" "approved_first"*/ {
			
			estimates clear
			global x = "$x_all"
			if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"	
			

			use `v' pass_math pass_read approved approved_first id_per_umc year_t_?? public_siagie urban_siagie male_siagie educ_cat_mother higher_ed_parent lives_with_mother lives_with_father *has_internet *has_comp *low_ses *quiet_room year grade treated post treated_post id_ie fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid${covid_data}", clear
			
			*- Remove early grades and years
			keep if year>=2016
			drop if grade==0
			
			
			*- Divide sample based on grade in 2020
			//bys id_per_umc: egen grade_2020	= min(cond(year==2020,grade,.))
			
			*- Divide sample based on expected cohort
			bys id_per_umc: egen min_year 		= min(year)
			bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
			gen proxy_1st = min_year - grade_min_year  + 1
							
			
			/*
			*- Not enough pre-years
						
			drop if inlist(grade_2020,1,2)==1
			drop if grade_2020==3 & year<=2017 //<=2017 Would only include those who repeated..
			drop if grade_2020==4 & year<=2016 //<=2016 Would only include those who repeated..
			keep if proxy_1st <= 2018
			*/
			
			
			/*
			if "`area'" == "rur" keep if urban_siagie == 0
			if "`area'" == "urb" keep if urban_siagie == 1

			if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
			if "`hed_parent'" == "yes" 	keep if higher_ed_parent == 1
			*/
			
			if "`level'" == "all" {
				keep if grade>=1 & grade<=11
				//gen young = inlist(grade_2020,3,4,5,6)==1 if inlist(grade_2020,3,4,5,6,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2015,2016,2017,2018) if inlist(proxy_1st,2011,2012,2013,2014,2015,2016,2017,2018)==1
				gen young = inlist(grade,1,2,3,4,5,6)==1 if inlist(grade,1,2,3,4,5,6,7,8,9,10,11)
				local young_lab = "Primary" //Primary in 2020
				local old_lab 	= "Secondary"
				}
			if "`level'" == "elm" {
				keep if grade>=1 & grade<=6
				//gen young = inlist(grade_2020,3,4)==1 if inlist(grade_2020,3,4,5,6)
				//gen young = inlist(proxy_1st,2017,2018) if inlist(proxy_1st,2015,2016)==1
				//local young_lab = "2017-2018 cohort" //3rd-4th grade in 2020
				//local old_lab 	= "2015-2016 cohort" //5th-6th grade in 2020
				gen young = inlist(grade,1,2,3)==1 if inlist(grade,1,2,3,4,5,6)
				local young_lab = "1st-3rd grade"
				local old_lab 	= "4th-6th grade"
				}
			if "`level'" == "sec" {
				keep if grade>=7	
				//gen young = inlist(grade_2020,7,8)==1 if inlist(grade_2020,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2014,2013) if inlist(proxy_1st,2011,2012)==1
				//local young_lab = "2014-2013 cohort" //7th-8th grade in 2020
				//local old_lab 	= "2011-2012 cohort" //9th-11th grade in 2020
				gen young = inlist(grade,7,8)==1 if inlist(grade,7,8,9,10,11)
				local young_lab = "7th-8th grade"
				local old_lab 	= "9th-11th grade"
				}

			if "`v'" == "std_gpa_m" 		local vlab = "gpa_m"
			if "`v'" == "std_gpa_c" 		local vlab = "gpa_c"
			if "`v'" == "std_gpa_m_adj" 	local vlab = "gpa_m_adj"
			if "`v'" == "std_gpa_c_adj" 	local vlab = "gpa_c_adj"					
			if "`v'" == "pass_math" 		local vlab = "pass_m"				
			if "`v'" == "pass_read" 		local vlab = "pass_c"				
			if "`v'" == "approved" 			local vlab = "pass"
			if "`v'" == "approved_first" 	local vlab = "passf"
	
			* All students
			di as result "*******" _n as text "All" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(grade id_ie)
			estimates store all_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1  , a(grade id_ie)
			estimates store all_`vlab'_3
			if ${max_sibs} == 4 eststo all_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1  , a(grade id_ie)
				
			if "`level'" == "all" {
				forvalues g = 1(1)11 {
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & grade==`g' , a(grade id_ie)
				estimates store g`g'_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & grade==`g' , a(grade id_ie)
				estimates store g`g'_`vlab'_3
				if ${max_sibs} == 4 eststo g`g'_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & grade==`g'  , a(grade id_ie)	
				}
				
				if ${max_sibs}==4 local legend_child_${max_sibs} = "4 children"	
				if ${max_sibs}==4 local legend_sib_${max_sibs} = "3 siblings"
				coefplot all_`vlab'_?, ///
						bylabel("All Students") ///
						|| g1_`vlab'_?, ///
						bylabel("1st grade") ///
						|| g2_`vlab'_?, ///
						bylabel("2nd grade") ///
						|| g3_`vlab'_?, ///
						bylabel("3rd grade") ///
						|| g4_`vlab'_?, ///
						bylabel("4th grade") ///
						|| g5_`vlab'_?, ///
						bylabel("5th grade") ///
						|| g6_`vlab'_?, ///
						bylabel("6th grade") ///
						|| g7_`vlab'_?, ///
						bylabel("7th grade") ///
						|| g8_`vlab'_?, ///
						bylabel("8th grade") ///
						|| g9_`vlab'_?, ///
						bylabel("9th grade") ///
						|| g10_`vlab'_?, ///
						bylabel("10th grade") ///
						|| g11_`vlab'_?, ///
						bylabel("11th grade") ///
						keep(treated_post) ///
						legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
						xtitle("Standard Deviations", size(medsmall) height(5)) ///
						xlabel(-.1(0.02)0.02) ///
						xline(0, lcolor(gs12)) ///
						xline(-.1 -.08 -.06 -.04 -.02 .02, lcolor(gs15))  ///
						///xlabel(-.1 "-0.8" -.4 "-0.4" 0 "0" .4 "0.4" .8 "0.8", labsize(medsmall)) ///
						///ciopts(recast(rcap) lwidth(medium)) ///
						grid(none) ///
						///yscale(reverse) ///
						bycoefs	
				
						
				//graph save "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.gph" , replace	
				//capture qui graph export "$FIGURES\covid_twfe_`level'_`vlab'_${max_sibs}.eps", replace	
				capture qui graph export "$FIGURES\TWFE\covid_twfe_grades_`vlab'_${max_sibs}${covid_data}.png", replace	
				capture qui graph export "$FIGURES\TWFE\covid_twfe_grades_`vlab'_${max_sibs}${covid_data}.pdf", replace					
				
				}
				
		

			}
		}

end

***********************************************

capture program drop twfe_survey
program define twfe_survey
		
	
	clear

	*- TWFE Estimates

	foreach level in "all" /*"elm" "sec"*/ {
		foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj"  "pass_math" "pass_read" /*"approved" "approved_first"*/ {
			
			estimates clear
			global x = "$x_all"
			if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"	
			

			use `v' pass_math pass_read approved approved_first id_per_umc year_t_?? public_siagie urban_siagie male_siagie educ_cat_mother higher_ed_parent lives_with_mother lives_with_father *has_internet *has_comp *low_ses *quiet_room year grade treated post treated_post id_ie fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid${covid_data}", clear
			
			*- Remove early grades and years
			keep if year>=2016
			drop if grade==0
			
			
			*- Divide sample based on grade in 2020
			//bys id_per_umc: egen grade_2020	= min(cond(year==2020,grade,.))
			
			*- Divide sample based on expected cohort
			bys id_per_umc: egen min_year 		= min(year)
			bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
			gen proxy_1st = min_year - grade_min_year  + 1
							
			
			/*
			*- Not enough pre-years
						
			drop if inlist(grade_2020,1,2)==1
			drop if grade_2020==3 & year<=2017 //<=2017 Would only include those who repeated..
			drop if grade_2020==4 & year<=2016 //<=2016 Would only include those who repeated..
			keep if proxy_1st <= 2018
			*/
			
			
			/*
			if "`area'" == "rur" keep if urban_siagie == 0
			if "`area'" == "urb" keep if urban_siagie == 1

			if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
			if "`hed_parent'" == "yes" 	keep if higher_ed_parent == 1
			*/
			
			if "`level'" == "all" {
				keep if grade>=1 & grade<=11
				//gen young = inlist(grade_2020,3,4,5,6)==1 if inlist(grade_2020,3,4,5,6,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2015,2016,2017,2018) if inlist(proxy_1st,2011,2012,2013,2014,2015,2016,2017,2018)==1
				gen young = inlist(grade,1,2,3,4,5,6)==1 if inlist(grade,1,2,3,4,5,6,7,8,9,10,11)
				local young_lab = "Primary" //Primary in 2020
				local old_lab 	= "Secondary"
				}
			if "`level'" == "elm" {
				keep if grade>=1 & grade<=6
				//gen young = inlist(grade_2020,3,4)==1 if inlist(grade_2020,3,4,5,6)
				//gen young = inlist(proxy_1st,2017,2018) if inlist(proxy_1st,2015,2016)==1
				//local young_lab = "2017-2018 cohort" //3rd-4th grade in 2020
				//local old_lab 	= "2015-2016 cohort" //5th-6th grade in 2020
				gen young = inlist(grade,1,2,3)==1 if inlist(grade,1,2,3,4,5,6)
				local young_lab = "1st-3rd grade"
				local old_lab 	= "4th-6th grade"
				}
			if "`level'" == "sec" {
				keep if grade>=7	
				//gen young = inlist(grade_2020,7,8)==1 if inlist(grade_2020,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2014,2013) if inlist(proxy_1st,2011,2012)==1
				//local young_lab = "2014-2013 cohort" //7th-8th grade in 2020
				//local old_lab 	= "2011-2012 cohort" //9th-11th grade in 2020
				gen young = inlist(grade,7,8)==1 if inlist(grade,7,8,9,10,11)
				local young_lab = "7th-8th grade"
				local old_lab 	= "9th-11th grade"
				}

			if "`v'" == "std_gpa_m" 		local vlab = "gpa_m"
			if "`v'" == "std_gpa_c" 		local vlab = "gpa_c"	
			if "`v'" == "std_gpa_m_adj" 	local vlab = "gpa_m_adj"
			if "`v'" == "std_gpa_c_adj" 	local vlab = "gpa_c_adj"			
			if "`v'" == "pass_math" 		local vlab = "pass_m"				
			if "`v'" == "pass_read" 		local vlab = "pass_c"				
			if "`v'" == "approved" 			local vlab = "pass"
			if "`v'" == "approved_first" 	local vlab = "passf"
	
			* All students
			di as result "*******" _n as text "All" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(grade id_ie)
			estimates store all_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1  , a(grade id_ie)
			estimates store all_`vlab'_3
			if ${max_sibs} == 4 eststo all_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1  , a(grade id_ie)				

			di as result "*******" _n as text "All with Survey info" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & low_ses!=. , a(grade id_ie)
			estimates store alls_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & low_ses!=.  , a(grade id_ie)
			estimates store alls_`vlab'_3
			if ${max_sibs} == 4 eststo alls_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & low_ses!=.  , a(grade id_ie)

			di as result "*******" _n as text "No internet" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & has_internet==0 , a(grade id_ie)
			estimates store nint_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & has_internet==0  , a(grade id_ie)
			estimates store nint_`vlab'_3
			if ${max_sibs} == 4 eststo nint_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & has_internet==0  , a(grade id_ie)

			di as result "*******" _n as text "Low SES" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & low_ses==1 , a(grade id_ie)
			estimates store lses_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & low_ses==1  , a(grade id_ie)
			estimates store lses_`vlab'_3
			if ${max_sibs} == 4 eststo lses_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & low_ses==1  , a(grade id_ie)

			di as result "*******" _n as text "No computer" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & has_comp==0 , a(grade id_ie)
			estimates store ncom_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & has_comp==0  , a(grade id_ie)
			estimates store ncom_`vlab'_3
			if ${max_sibs} == 4 eststo ncom_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & has_comp==0  , a(grade id_ie)

			coefplot alls_`vlab'_?, ///
					bylabel("All Students") ///
					|| lses_`vlab'_?, ///
					bylabel("Low SES") ///
					|| nint_`vlab'_?, ///
					bylabel("No access to Internet") ////
					|| ncom_`vlab'_?, ///
					bylabel("No Computer in the house") ///	
					keep(treated_post) ///
					xline(0, lpattern(dash)) ///
					legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
					xlabel(-.1(0.02)0.02) ///
					///ciopts(recast(rcap) lwidth(medium)) ///
					grid(none) ///
					///yscale(reverse) ///
					bycoefs
					
			//graph save "$FIGURES\covid_twfe_survey_`level'_`vlab'_${max_sibs}.gph" , replace	
			//capture qui graph export "$FIGURES\covid_twfe_survey_`level'_`vlab'_${max_sibs}.eps", replace	
			capture qui graph export "$FIGURES\TWFE\covid_twfe_survey_`level'_`vlab'_${max_sibs}${covid_data}.png", replace	
			capture qui graph export "$FIGURES\TWFE\covid_twfe_survey_`level'_`vlab'_${max_sibs}${covid_data}.pdf", replace			

			}
		}

end
	
********************************************************************************
* Event Study - GPA
********************************************************************************

capture program drop event_gpa
program define event_gpa	
	
	
colorpalette  HCL blues, selec(1 6 11) nograph
return list

local blue_1 = "`r(p1)'"
local blue_2 = "`r(p2)'"
local blue_3 = "`r(p3)'"

if ${max_sibs}==4 local legend_child_${max_sibs} = "4 children"	
if ${max_sibs}==4 local legend_sib_${max_sibs} = "3 siblings"	
*- GPA Overall 
estimates clear

clear

*- Event Study


foreach level in "all" "elm" "sec" {
	foreach young in "" /*"0" "1"*/ {
		foreach area in  "all" /*"urb" "rur"*/  { 
			foreach lives_both_parents in  "all" /*"both" "notboth"*/  { 
				foreach hed in "all" /*"hed" "nhed"*/  { //none or at least one. # No change
					foreach res in "all" /*"alls"*/ /*"nint"*/ /*"ncom" "lses" "nqui"*/ { //all sample with data, No internet, no computer, low ses, no quiet room
						foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj"  "pass_math" "pass_read"  {
							di "`v' - `area' - `hed' - `level' - `res'"
							
							//if "`area'" == "urb" continue
							//if "`area'" == "rur" &  "`hed'" =="no" & "`level'" == "all" & inlist("`v'","approved_first")!=1 continue
				
							global x = "$x_all"
							if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"							
							
							use `v' id_per_umc year_t_?? urban_siagie higher_ed_parent lives_with_mother lives_with_father *has_internet *has_comp *low_ses *quiet_room year grade treated post treated_post  id_ie fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid${covid_data}", clear
							
							*- Remove early grades and years
							keep if year>=2016
							drop if grade==0
							
							*- Divide sample based on grade in 2020
							bys id_per_umc: egen grade_2020	= min(cond(year==2020,grade,.))
							
							*- Not enough pre-years
							drop if inlist(grade_2020,1,2)==1
							drop if grade_2020==3 & year<=2017 //<=2017 Would only include those who repeated..
							drop if grade_2020==4 & year<=2016 //<=2016 Would only include those who repeated..						
										
							
							if "`area'" == "rur" keep if urban_siagie == 0
							if "`area'" == "urb" keep if urban_siagie == 1
							
							if "`hed'" == "no" 	keep if higher_ed_parent == 0
							if "`hed'" == "yes" 	keep if higher_ed_parent == 1
							
							if "`level'" == "all" {
								keep if grade>=1 & grade<=11
								if "`young'" == "1" keep if inlist(grade_2020,3,4,5,6)==1
								if "`young'" == "0" keep if inlist(grade_2020,7,8,9,10,11)==1
								}
							if "`level'" == "elm" {
								keep if grade>=1 & grade<=6
								if "`young'" == "1" keep if inlist(grade_2020,3,4)==1
								if "`young'" == "0" keep if inlist(grade_2020,5,6)==1
								}
							if "`level'" == "sec" {
								keep if grade>=7
								if "`young'" == "1" keep if inlist(grade_2020,7,8)==1
								if "`young'" == "0" keep if inlist(grade_2020,9,10,11)==1
								}
								
							if "`lives_both_parents'" == "both" {
								keep if lives_with_mother==1 & lives_with_father==1
							}
							
							if "`lives_both_parents'" == "notboth" {
								keep if (lives_with_mother==1 & lives_with_father==0) | (lives_with_mother==0 & lives_with_father==1) | (lives_with_mother==0 & lives_with_father==0)
								//Some missing cases will be excluded so yes/no dont add up to all
							}							
									
							if "`res'" == "all" 		keep if 1==1
							if "`res'" == "alls" 		keep if has_internet!=.
							if "`res'" == "nint" 		keep if has_internet==0
							if "`res'" == "ncom" 		keep if has_comp==0
							if "`res'" == "lses" 		keep if low_ses==1
							if "`res'" == "nqui" 		keep if quiet_room==0
							
							if "`v'" == "std_gpa_m" {
								local vlab = "gm"
								local tlab = "Standardized mathematics GPA"
							}
							
							if "`v'" == "std_gpa_c" {
								local vlab = "gc"
								local tlab = "Standardized reading GPA"
							}
							
							if "`v'" == "std_gpa_m_adj" {
								local vlab = "am"
								local tlab = "Standardized mathematics GPA (adj)"
							}
							
							if "`v'" == "std_gpa_c_adj" {
								local vlab = "ac"
								local tlab = "Standardized reading GPA (adj)"
							}							
							
							if "`v'" == "pass_math" {
								local vlab = "pm"
								local tlab = "Passed mathematics"
							}						
							
							if "`v'" == "pass_read" {
								local vlab = "pc"
								local tlab = "Passed reading"
							}	
							
							if "`v'" == "higher_ed_parent" {
								local vlab = "he"
								local tlab = "Has parent with higher education"
							}	
							
							local level_lab = ""
							if "`level'" == "elm" local level_lab = "p"
							if "`level'" == "sec" local level_lab = "s"
							
							local area_lab = ""
							if "`area'" == "urb" local area_lab = "u"
							if "`area'" == "rur" local area_lab = "r"
							
							local lives_lab = ""
							if "`lives_both_parents'" == "both" local lives_lab = "b"
							if "`lives_both_parents'" == "notboth" local lives_lab = "n"
							
							local hed_lab = ""
							if "`hed'" == "hed" 	local hed_lab = "h"
							if "`hed'" == "nhed" local hed_lab = "n"
							
							local res_lab = ""
							if "`res'" == "alls" local res_lab = "s"
							if "`res'" == "nint" local res_lab = "i"
							if "`res'" == "ncom" local res_lab = "c"
							if "`res'" == "lses" local res_lab = "l"
							if "`res'" == "nqui" local res_lab = "q"
							//merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(`v'_*) nogen
							
							*- Event Study
							//OC vs size =2/3
							reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if fam_total_${fam_type}<=${max_sibs}, a(year grade id_ie)
							estimates store e`vlab'_`area_lab'_`lives_lab'_`hed_lab'_`level_lab'`young'_`res_lab'1 //'e' for event study
							
							//OC vs size =2
							reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(year grade id_ie)
							estimates store e`vlab'_`area_lab'_`lives_lab'_`hed_lab'_`level_lab'`young'_`res_lab'2
							
							//OC vs size =3
							reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,3)==1 , a(year grade id_ie)
							estimates store e`vlab'_`area_lab'_`lives_lab'_`hed_lab'_`level_lab'`young'_`res_lab'3
							
							if ${max_sibs} == 4 eststo e`vlab'_`area_lab'_`lives_lab'_`hed_lab'_`level_lab'`young'_`res_lab'4 :reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,4)==1 , a(year grade id_ie)
							/*
							*- TWFE 
							//OC vs size =2
							reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(year grade id_ie)
							estimates store t`vlab'_`area'_`hed'_`level'_`res'2
							
							//OC vs size =3
							reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,3)==1 , a(year grade id_ie)
							estimates store t`vlab'_`area'_`hed'_`level'_`res'3	
							
							if ${max_sibs} == 4 eststo t`vlab'_`area'_`hed'_`level'_`res'4 :reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,4)==1 , a(year grade id_ie)
							*/
							
							
							local drop_vars = ""
							if "`level'" == "elm" & "`young'" == "1" local drop_vars = "year_t_b5 year_t_b4 year_t_b3"
							
							coefplot 	(e`vlab'_`area_lab'_`lives_lab'_`hed_lab'_`level_lab'`young'_`res_lab'1, drop(year_t_b6 `drop_vars') mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
										(e`vlab'_`area_lab'_`lives_lab'_`hed_lab'_`level_lab'`young'_`res_lab'2, drop(year_t_b6 `drop_vars') mcolor("${blue_3}") ciopts(bcolor("${blue_3}")) lcolor("${blue_3}")) ///
										(e`vlab'_`area_lab'_`lives_lab'_`hed_lab'_`level_lab'`young'_`res_lab'3, drop(year_t_b6 `drop_vars') mcolor("${blue_2}") ciopts(bcolor("${blue_2}")) lcolor("${blue_2}")) ///
										(e`vlab'_`area_lab'_`lives_lab'_`hed_lab'_`level_lab'`young'_`res_lab'4, drop(year_t_b6 `drop_vars') mcolor("${blue_1}") ciopts(bcolor("${blue_1}")) lcolor("${blue_1}")) ///
										, ///
										omitted ///
										keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
										drop(year_t_b6 year_t_b5 year_t_b4) ///
										leg(order(1 "Children with siblings" 3 "1 sibling" 5 "2 siblings" 7 "`legend_sib_${max_sibs}'")) ///
										coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
										yline(0,  lcolor(gs10))  ///
										ytitle("Effect") ///
										ylab(-.1(.02).04) ///
										///xline(2019.5 2021.5) ///
										subtitle("`tlab'") ///
										legend(pos(6) col(4))
							
							capture qui graph export "$FIGURES\Event Study\covid_`v'_`area'_`lives_both_parents'_`hed'_`level'`young'_`res'`i'${covid_data}.png", replace	
							capture qui graph export "$FIGURES\Event Study\covid_`v'_`area'_`lives_both_parents'_`hed'_`level'`young'_`res'`i'${covid_data}.pdf", replace								
							
							}
							
										
						/*				
						forvalues i = 1/4 {
							coefplot 	em_`area'_`hed'_`level'_`res'`i' ec_`area'_`hed'_`level'_`res'`i', ///
										omitted ///
										keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
										leg(order(1 "GPA Math" 3 "GPA Comm")) ///
										coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
										yline(0,  lcolor(gs10))  ///
										ytitle("Effect") ///
										ylab(-.1(.02).04) ///
										subtitle("Panel A: GPA") ///
										legend(pos(6) col(3)) ///
										name(panel_A_GPA_`area'_`hed'_`level'_`res'`i',replace)	
							*/
							//graph save "$FIGURES\covid_gpa_`vlab'_`area'_`hed'_`level'`young'_`res'`i'.gph" , replace	
							//capture qui graph export "$FIGURES\covid_gpa_`vlab'_`area'_`hed'_`level'`young'_`res'`i'.eps", replace	

						
						}
						estimates drop e*	
						
					}
				
				}
			}
		}
	}

end

********************************************************************************
* Event Study - Approved
********************************************************************************

capture program drop event_approved
program define event_approved	

if ${max_sibs}==4 local legend_child_${max_sibs} = "4 children"	
if ${max_sibs}==4 local legend_sib_${max_sibs} = "3 siblings"	
			
estimates clear
foreach level in "all" "elm" "sec" {
	foreach area in  "all" "urb" "rur"  {
		foreach hed_parent in "no" "yes" "all" { //none or at least one
			//ds urban_siagie higher_ed_parent	
			foreach res in "all" "alls" "nint" "ncom" "lses" "nqui" { //all sample with data, No internet, no computer, low ses, no quiet room
				foreach v in  "approved" "approved_first" {
					di "`v' - `area' - `hed_parent' - `level' - `res'"
					
					//if "`area'" == "urb" continue
					//if "`area'" == "rur" &  "`hed_parent'" =="no" & "`level'" == "all" & inlist("`v'","approved_first")!=1 continue
						
					use `v' id_per_umc year_t_?? urban_siagie higher_ed_parent *has_internet *has_comp *low_ses *quiet_room year grade treated post treated_post  id_ie fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid${covid_data}", clear
					
					if "`area'" == "rur" keep if urban_siagie == 0
					if "`area'" == "urb" keep if urban_siagie == 1
					
					if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
					if "`hed_parent'" == "yes" 	keep if higher_ed_parent == 1
					
					if "`level'" == "all" keep if grade>=1 & grade<=11
					if "`level'" == "elm" keep if grade>=1 & grade<=6
					if "`level'" == "sec" keep if grade>=7
					
					if "`res'" == "all" 		keep if 1==1
					if "`res'" == "alls" 		keep if has_internet!=.
					if "`res'" == "nint" 		keep if has_internet==0
					if "`res'" == "ncom" 		keep if has_comp==0
					if "`res'" == "lses" 		keep if low_ses==1
					if "`res'" == "nqui" 		keep if quiet_room==0
									
					if "`v'" == "approved" 			local vlab = "pass"
					if "`v'" == "approved_first" 	local vlab = "passf"
					
					
					//merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(`v'_*) nogen
					
					//OC vs size =2/3
					reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if fam_total_${fam_type}<=${max_sibs}, a(year grade id_ie)
					estimates store e`vlab'_`area'_`hed_parent'_`level'_`res'1
					
					//OC vs size =2
					reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(year grade id_ie)
					estimates store e`vlab'_`area'_`hed_parent'_`level'_`res'2
					
					//OC vs size =3
					reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,3)==1 , a(year grade id_ie)
					estimates store e`vlab'_`area'_`hed_parent'_`level'_`res'3		
					
					if ${max_sibs} == 4 eststo e`vlab'_`area'_`hed_parent'_`level'_`res'4: reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,4)==1 , a(year grade id_ie)
					
					}
				forvalues i = 1/4 {
		
					coefplot 	epass_`area'_`hed_parent'_`level'_`res'`i' epassf_`area'_`hed_parent'_`level'_`res'`i', ///
								omitted ///
								keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
								drop(year_t_b6 year_t_b5 year_t_b4) ///
								leg(order(1 "Passed grade" 3 "Passed grade without extension")) ///
								coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016"  year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
								yline(0,  lcolor(gs10))  ///
								ytitle("Effect") ///
								///xline(2019.5 2021.5) ///
								subtitle("Panel B: Grade Pass Rate") ///
								legend(pos(6) col(3)) ///
								name(panel_B_PASSED_`level'_`res'`i',replace)	
					//graph save "$FIGURES\covid_approved_`area'_`hed_parent'_`level'_`res'`i'.gph" , replace	
					//capture qui graph export "$FIGURES\covid_approved_`area'_`hed_parent'_`level'_`res'`i'.eps", replace	
					capture qui graph export "$FIGURES\Event Study\covid_approved_`area'_`hed_parent'_`level'_`res'`i'${covid_data}.png", replace			
					capture qui graph export "$FIGURES\Event Study\covid_approved_`area'_`hed_parent'_`level'_`res'`i'${covid_data}.pdf", replace				
					}
				}	
			}
		estimates clear
		}
	}

end


********************************************************************************
* Event Study - Cohort Grade
********************************************************************************

capture program drop event_cohort_grade
program define event_cohort_grade	
	foreach v in "std_gpa_m" /*"std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read"*/ /*"higher_ed_parent"*/ {
		foreach area in "all" /*"urb" "rur"*/  {
			foreach res in "all" /*"alls" "nint"*/ { 
				
				global x = "$x_all"
				if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"
				 
				estimates clear
				use `v' id_per_umc year_t_?? urban_siagie higher_ed_parent *has_internet *has_comp *low_ses *quiet_room year grade treated post treated_post  id_ie fam_order_${fam_type} fam_total_${fam_type} ${x_all} using "$TEMP\pre_reg_covid${covid_data}", clear
						
				di as result "*******************************"
				di as text "`v' - `area' - `res'"
				di as result "*******************************"
			
				drop if grade==0

				/*
				bys id_per_umc: egen year_1st 	= min(cond(grade==1,year,.))
				//bys id_per_umc: egen grade_2016	= max(cond(year==2016,grade,.))
				bys id_per_umc: egen grade_2019	= max(cond(year==2019,grade,.))

				bys id_per_umc: egen min_grade 		= min(grade)
				bys id_per_umc: egen year_min_grade = min(cond(grade==min_grade,year,.))

				//Expected grade based on first year in primary			
				gen grade_exp = year-year_1st+1 
				tab grade_exp grade

				//Expected grade based on first year and grade observed (proxy because it could've repeated before.)
				gen grade_exp_proxy = year-year_min_grade+min_grade

				*- On time variables
				gen byte on_time 		=  (grade_exp==grade)		if grade_exp!=.
				gen byte on_time_proxy 	=  (grade_exp_proxy==grade)	if grade_exp_proxy!=.
				
				drop min_grade year_min_grade grade_exp grade_exp_proxy on_time
				compress
				*/
				
				*- Divide sample based on expected cohort
				bys id_per_umc: egen min_year 		= min(year)
				bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
				gen proxy_1st = min_year - grade_min_year  + 1
				
				keep if year>=2015
				
				/*
				bys id_per_umc: egen year_1st 	= min(cond(grade==1,year,.))
				bys id_per_umc: egen grade_2016	= max(cond(year==2016,grade,.))
				*/
				if "`area'" == "rur" keep if urban_siagie == 0
				if "`area'" == "urb" keep if urban_siagie == 1
				
				if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
				if "`hed_parent'" == "ys" 	keep if higher_ed_parent == 1
				
				if "`level'" == "all" keep if grade>=1 & grade<=11
				if "`level'" == "elm" keep if grade>=1 & grade<=6
				if "`level'" == "sec" keep if grade>=7
				
				if "`res'" == "all" 		keep if 1==1
				if "`res'" == "alls" 		keep if has_internet!=.
				if "`res'" == "nint" 		keep if has_internet==0
				if "`res'" == "ncom" 		keep if has_comp==0
				if "`res'" == "lses" 		keep if low_ses==1
				if "`res'" == "nqui" 		keep if quiet_room==0
				
				//if "`res'" != "all" 		keep if on_time_proxy==1
				
				if "`v'" == "std_gpa_m" {
					local vlab = "gpa_m"
					local tlab = "Standardized mathematics GPA"
				}
				if "`v'" == "std_gpa_c" {
					local vlab = "gpa_c"
					local tlab = "Standardized reading GPA"
				}
				
				if "`v'" == "std_gpa_m_adj" {
					local vlab = "gpa_m_adj"
					local tlab = "Standardized mathematics GPA (adj)"
				}
				if "`v'" == "std_gpa_c_adj" {
					local vlab = "gpa_c_adj"
					local tlab = "Standardized reading GPA (adj)"
				}				
						
				if "`v'" == "pass_math" {
					local vlab = "pass_m"
					local tlab = "Passed mathematics"
				}						
				
				if "`v'" == "pass_read" {
					local vlab = "pass_c"
					local tlab = "Passed reading"
				}					
				if "`v'" == "higher_ed_parent" {
					local vlab = "hed"
					local tlab = "Has parent with higher education"
				}			
				
				keep `v' /*event*/ year_t_?? treated /*covariates*/ ${x} /*conditional*/ proxy_1st  /*FE*/ year grade id_ie
				
				*- Results by cohort
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(proxy_1st,2011,2012,2013,2014,2015,2016,2017,2018) & year>=2015, a(year grade id_ie)
				estimates store c_all_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if proxy_1st==2011 & year>=2015, a(year grade id_ie)
				estimates store c_2011_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if proxy_1st==2012 & year>=2015, a(year grade id_ie)
				estimates store c_2012_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if proxy_1st==2013 & year>=2015, a(year grade id_ie)
				estimates store c_2013_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if proxy_1st==2014 & year>=2015, a(year grade id_ie)
				estimates store c_2014_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if proxy_1st==2015 & year>=2015, a(year grade id_ie)
				estimates store c_2015_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if proxy_1st==2016 & year>=2016, a(year grade id_ie)
				estimates store c_2016_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if proxy_1st==2017 & year>=2017, a(year grade id_ie)
				estimates store c_2017_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if proxy_1st==2018 & year>=2018, a(year grade id_ie)
				estimates store c_2018_`res'_`area'_`vlab'
								
				
				local add_coef = ""
				//if "`res'" == "all" local add_coef = `"(c_2017*, drop(year_t_b6 year_t_b5 year_t_b4) mcolor("`blue_4'") ciopts(bcolor("`blue_4'")))"'
				
				if "`res'" == "all" {
				coefplot 	(c_all*, 													mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
							///(c_2013*, drop(year_t_b6) 									mcolor("`blue_1'") ciopts(bcolor("`blue_1'"))) ///
							(c_2011*, drop(year_t_b6)									mcolor("${blue_1}") ciopts(bcolor("${blue_1}")) lcolor("${blue_1}")) ///
							(c_2012*, drop(year_t_b6)									mcolor("${blue_2}") ciopts(bcolor("${blue_2}")) lcolor("${blue_2}")) ///
							(c_2013*, drop(year_t_b6)									mcolor("${blue_3}") ciopts(bcolor("${blue_3}")) lcolor("${blue_3}")) ///
							(c_2014*, drop(year_t_b6)									mcolor("${blue_4}") ciopts(bcolor("${blue_4}")) lcolor("${blue_4}")) ///
							(c_2015*, drop(year_t_b6)									mcolor("${red_4}") ciopts(bcolor("${red_4}")) lcolor("${red_4}")) ///
							(c_2016*, drop(year_t_b6 year_t_b5)							mcolor("${red_3}") ciopts(bcolor("${red_3}")) lcolor("${red_3}")) ///
							(c_2017*, drop(year_t_b6 year_t_b5 year_t_b4) 				mcolor("${red_2}") ciopts(bcolor("${red_2}")) lcolor("${red_2}")) /// 2007 not included for survey sample since that cohort wouldn't be surveyed in 2nd or 4th grade.
							(c_2018*, drop(year_t_b6 year_t_b5 year_t_b4 year_t_b3) 	mcolor("${red_1}") ciopts(bcolor("${red_1}")) lcolor("${red_1}")), ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							leg(order(1 "All" 3 "2011" 5 "2012" 7 "2013" 9 "2014" 11 "2015" 13 "2016" 15 "2017" 17 "2018")) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							///xline(2019.5 2021.5) ///
							subtitle("`tlab' by year in 1st grade") ///
							legend(pos(6) col(6)) ///
							name(check_cohorts,replace)	
					}
					
				if "`res'" != "all" {
				coefplot 	(c_all*, 													mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
							///(c_2013*, drop(year_t_b6) 									mcolor("`blue_1'") ciopts(bcolor("`blue_1'"))) ///
							(c_2014*, drop(year_t_b6)									mcolor("${blue_2}") ciopts(bcolor("${blue_2}")) lcolor("${blue_2}")) ///
							(c_2015*, drop(year_t_b6)									mcolor("${blue_3}") ciopts(bcolor("${blue_3}")) lcolor("${blue_3}")) ///
							(c_2016*, drop(year_t_b6 year_t_b5)							mcolor("${red_3}") ciopts(bcolor("${red_3}")) lcolor("${red_3}")) ///
							(c_2018*, drop(year_t_b6 year_t_b5 year_t_b4 year_t_b3) 	mcolor("${red_1}") ciopts(bcolor("${red_1}")) lcolor("${red_1}")) ///
							, ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							leg(order(1 "All" 3 "2014" 5 "2015" 7 "2016" 9 "2018")) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							///xline(2019.5 2021.5) ///
							subtitle("`tlab' by year in 1st grade") ///
							legend(pos(6) col(6)) ///
							name(check_cohorts,replace)	
					}				
							
				capture qui graph export "$FIGURES\Event Study\covid_cohort_`res'_`area'_`v'${covid_data}.png", replace				
						
				coefplot 	(c_all*, 													mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
							, ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							///xline(2019.5 2021.5) ///
							subtitle("`tlab'") ///
							legend(off) 		
							
				capture qui graph export "$FIGURES\Event Study\covid_cohort_full_`res'_`area'_`v'${covid_data}.png", replace				
						
				/*			
				*- Results by grade in 2016
				//reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(grade_2016,1,2,3,4,5), a(year grade id_ie)
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(grade_2019,2,4,5,6,7), a(year grade id_ie)
				estimates store g_all_`res'_`area'_`vlab'
					
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==2 & year>=2018, a(year grade id_ie)
				estimates store g_2_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==4 & year>=2016, a(year grade id_ie)
				estimates store g_4_`res'_`area'_`vlab'

				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==5, a(year grade id_ie)
				estimates store g_5_`res'_`area'_`vlab'

				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==6, a(year grade id_ie)
				estimates store g_6_`res'_`area'_`vlab'

				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==7, a(year grade id_ie)
				estimates store g_7_`res'_`area'_`vlab'
				/*
				if "`res'" == "all" {
					reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2016==5, a(year grade id_ie)
					estimates store g_5_`res'_`area'_`vlab'				
					}
				*/
				coefplot 	(g_all*,												mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
							(g_2_*, drop(year_t_b6 year_t_b5 year_t_b4 year_t_b3)	mcolor("`red_1'") ciopts(bcolor("`red_1'")) lcolor("`red_1'")) ///
							(g_4_*, drop(year_t_b6 year_t_b5)						mcolor("`red_3'") ciopts(bcolor("`red_3'")) lcolor("`red_3'")) ///
							(g_5_*, drop(year_t_b6)									mcolor("`blue_3'") ciopts(bcolor("`blue_3'")) lcolor("`blue_3'")) ///
							(g_6_*,													mcolor("`blue_2'") ciopts(bcolor("`blue_2'")) lcolor("`blue_2'")) ///
							(g_7_*,													mcolor("`blue_1'") ciopts(bcolor("`blue_1'")) lcolor("`blue_1'")) ///
							, ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							leg(order(1 "All" 3 "2nd" 5 "4th" 7 "5th" 9 "6th" 11 "7th" /*11 "5th"*/)) ///
							/// leg(order(1 "All" 3 "1st" 5 "2nd" 7 "3rd" 9 "4th" /*11 "5th"*/)) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							xline(2019.5 2021.5) ///
							subtitle("`tlab' by grade in 2019") ///
							legend(pos(6) col(6)) ///
							name(check_cohorts,replace)		
							
				capture qui graph export "$FIGURES\covid_grade_`res'_`area'_`v'${covid_data}.png", replace	
				
				coefplot 	(g_all*, 													mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
							, ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							xline(2019.5 2021.5) ///
							subtitle("`tlab'") ///
							legend(off) 		
							
				capture qui graph export "$FIGURES\covid_grade_full_`res'_`area'_`v'${covid_data}.png", replace					
				
				
				reghdfe `v' 			year_t_b6 year_t_b5 year_t_b4 year_t_b3 o.year_t_b2 year_t_o1 year_t_a?  treated ${x} if inlist(grade_2019,2,4,5,6,7), a(year grade id_ie)
				estimates store test
				
							coefplot 	(test, mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)), ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							xline(2019.5 2021.5) ///
							subtitle("`tlab' by grade in 2019") ///
							legend(pos(6) col(6))
							
				capture qui graph export "$FIGURES\test_grade_`res'_`area'_`v'${covid_data}.png", replace	
				*/
			}
		}
	}	

end


********************************************************************************
* Event Study - By grades
********************************************************************************

capture program drop event_grade
program define event_grade	

	foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" /*"higher_ed_parent"*/ {
		foreach area in "all" /*"urb" "rur"*/  {
			foreach res in "all" /*"alls" "nint"*/ { 
				
				global x = "$x_all"
				if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"
				 
				estimates clear
				use `v' id_per_umc year_t_?? urban_siagie higher_ed_parent *has_internet *has_comp *low_ses *quiet_room year grade treated post treated_post  id_ie fam_order_${fam_type} fam_total_${fam_type} ${x_all} using "$TEMP\pre_reg_covid${covid_data}", clear
						
				di as result "*******************************"
				di as text "`v' - `area' - `res'"
				di as result "*******************************"
			
				drop if grade==0

				/*
				bys id_per_umc: egen year_1st 	= min(cond(grade==1,year,.))
				//bys id_per_umc: egen grade_2016	= max(cond(year==2016,grade,.))
				bys id_per_umc: egen grade_2019	= max(cond(year==2019,grade,.))

				bys id_per_umc: egen min_grade 		= min(grade)
				bys id_per_umc: egen year_min_grade = min(cond(grade==min_grade,year,.))

				//Expected grade based on first year in primary			
				gen grade_exp = year-year_1st+1 
				tab grade_exp grade

				//Expected grade based on first year and grade observed (proxy because it could've repeated before.)
				gen grade_exp_proxy = year-year_min_grade+min_grade

				*- On time variables
				gen byte on_time 		=  (grade_exp==grade)		if grade_exp!=.
				gen byte on_time_proxy 	=  (grade_exp_proxy==grade)	if grade_exp_proxy!=.
				
				drop min_grade year_min_grade grade_exp grade_exp_proxy on_time
				compress
				*/
				
				*- Divide sample based on expected cohort
				bys id_per_umc: egen min_year 		= min(year)
				bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
				gen proxy_1st = min_year - grade_min_year  + 1
				
				keep if year>=2015
				
				/*
				bys id_per_umc: egen year_1st 	= min(cond(grade==1,year,.))
				bys id_per_umc: egen grade_2016	= max(cond(year==2016,grade,.))
				*/
				if "`area'" == "rur" keep if urban_siagie == 0
				if "`area'" == "urb" keep if urban_siagie == 1
				
				if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
				if "`hed_parent'" == "ys" 	keep if higher_ed_parent == 1
				
				if "`level'" == "all" keep if grade>=1 & grade<=11
				if "`level'" == "elm" keep if grade>=1 & grade<=6
				if "`level'" == "sec" keep if grade>=7
				
				if "`res'" == "all" 		keep if 1==1
				if "`res'" == "alls" 		keep if has_internet!=.
				if "`res'" == "nint" 		keep if has_internet==0
				if "`res'" == "ncom" 		keep if has_comp==0
				if "`res'" == "lses" 		keep if low_ses==1
				if "`res'" == "nqui" 		keep if quiet_room==0
				
				//if "`res'" != "all" 		keep if on_time_proxy==1
				
				if "`v'" == "std_gpa_m" {
					local vlab = "gpa_m"
					local tlab = "Standardized mathematics GPA"
				}
				if "`v'" == "std_gpa_c" {
					local vlab = "gpa_c"
					local tlab = "Standardized reading GPA"
				}
				
				if "`v'" == "std_gpa_m_adj" {
					local vlab = "gpa_m_adj"
					local tlab = "Standardized mathematics GPA (adj)"
				}
				if "`v'" == "std_gpa_c_adj" {
					local vlab = "gpa_c_adj"
					local tlab = "Standardized reading GPA (adj)"
				}				
						
				if "`v'" == "pass_math" {
					local vlab = "pass_m"
					local tlab = "Passed mathematics"
				}						
				
				if "`v'" == "pass_read" {
					local vlab = "pass_c"
					local tlab = "Passed reading"
				}					
				if "`v'" == "higher_ed_parent" {
					local vlab = "hed"
					local tlab = "Has parent with higher education"
				}			
				
				keep `v' /*event*/ year_t_?? treated /*covariates*/ ${x} /*conditional*/ proxy_1st  /*FE*/ year grade id_ie
				
				*- All
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year>=2015, a(year grade id_ie)
				estimates store g_all_`res'_`area'_`vlab'	
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year>=2015 & grade<=6, a(year grade id_ie)
				estimates store g_pri_`res'_`area'_`vlab'	
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year>=2015 & grade>=7, a(year grade id_ie)
				estimates store g_sec_`res'_`area'_`vlab'					
				
				*- Results by cohort
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade==1, a(year grade id_ie)
				estimates store g_1_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade==2, a(year grade id_ie)
				estimates store g_2_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade==3, a(year grade id_ie)
				estimates store g_3_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade==4, a(year grade id_ie)
				estimates store g_4_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade==5, a(year grade id_ie)
				estimates store g_5_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade==6, a(year grade id_ie)
				estimates store g_6_`res'_`area'_`vlab'				
	

				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade==7, a(year grade id_ie)
				estimates store g_7_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade==8, a(year grade id_ie)
				estimates store g_8_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade==9, a(year grade id_ie)
				estimates store g_9_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade==10, a(year grade id_ie)
				estimates store g_10_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade==11, a(year grade id_ie)
				estimates store g_11_`res'_`area'_`vlab'					
	
				
				local add_coef = ""
				//if "`res'" == "all" local add_coef = `"(c_2017*, drop(year_t_b6 year_t_b5 year_t_b4) mcolor("`blue_4'") ciopts(bcolor("`blue_4'")))"'
				
				
				coefplot 	(g_all*, 	drop(year_t_b6)							mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
							(g_pri, 	drop(year_t_b6)							mcolor("${blue_1}") ciopts(bcolor("${blue_1}")) lcolor("${blue_1}")) ///
							(g_sec, 	drop(year_t_b6)							mcolor("${blue_2}") ciopts(bcolor("${blue_2}")) lcolor("${blue_2}")) ///
							, ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							leg(order(1 "All" 3 "Primary" 5 "Secondary")) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							///xline(2019.5 2021.5) ///
							///subtitle("`tlab' by year in 1st grade") ///
							legend(pos(6) col(6)) ///
							name(check_cohorts,replace)	
				capture qui graph export "$FIGURES\Event Study\covid_grade_`res'_`area'_`v'${covid_data}.png", replace				
				capture qui graph export "$FIGURES\Event Study\covid_grade_`res'_`area'_`v'${covid_data}.pdf", replace	
				
				
				
				coefplot 	(g_pri*, 	drop(year_t_b6)									mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
							(g_1, 		drop(year_t_b6)									mcolor("${blue_1}") ciopts(bcolor("${blue_1}")) lcolor("${blue_1}")) ///
							(g_2, 		drop(year_t_b6)									mcolor("${blue_2}") ciopts(bcolor("${blue_2}")) lcolor("${blue_2}")) ///
							(g_3, 		drop(year_t_b6)									mcolor("${blue_3}") ciopts(bcolor("${blue_3}")) lcolor("${blue_3}")) ///
							(g_4, 		drop(year_t_b6)									mcolor("${blue_4}") ciopts(bcolor("${blue_4}")) lcolor("${blue_4}")) ///
							(g_5, 		drop(year_t_b6)									mcolor("${red_4}") ciopts(bcolor("${red_4}")) lcolor("${red_4}")) ///
							(g_6, 		drop(year_t_b6)									mcolor("${red_3}") ciopts(bcolor("${red_3}")) lcolor("${red_3}")) ///
							, ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							leg(order(1 "Primary" 3 "1st" 5 "2nd" 7 "3rd" 9 "4th" 11 "5th" 13 "6th")) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							///xline(2019.5 2021.5) ///
							///subtitle("`tlab' by year in 1st grade") ///
							legend(pos(6) col(6)) ///
							name(check_cohorts,replace)	
				capture qui graph export "$FIGURES\Event Study\covid_grade_pri_`res'_`area'_`v'${covid_data}.png", replace				
				capture qui graph export "$FIGURES\Event Study\covid_grade_pri_`res'_`area'_`v'${covid_data}.pdf", replace						
	
				coefplot 	(g_sec*,	drop(year_t_b6) 								mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
							(g_7, 		drop(year_t_b6)									mcolor("${blue_1}") ciopts(bcolor("${blue_1}")) lcolor("${blue_1}")) ///
							(g_8, 		drop(year_t_b6)									mcolor("${blue_2}") ciopts(bcolor("${blue_2}")) lcolor("${blue_2}")) ///
							(g_9, 		drop(year_t_b6)									mcolor("${blue_3}") ciopts(bcolor("${blue_3}")) lcolor("${blue_3}")) ///
							(g_10, 		drop(year_t_b6)									mcolor("${blue_4}") ciopts(bcolor("${blue_4}")) lcolor("${blue_4}")) ///
							(g_11, 		drop(year_t_b6)									mcolor("${red_4}") ciopts(bcolor("${red_4}")) lcolor("${red_4}")) ///
							, ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							leg(order(1 "Secondary" 3 "7th" 5 "8th" 7 "9th" 9 "10th" 11 "11th")) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							///xline(2019.5 2021.5) ///
							///subtitle("`tlab' by year in 1st grade") ///
							legend(pos(6) col(6)) ///
							name(check_cohorts,replace)	
				capture qui graph export "$FIGURES\Event Study\covid_grade_sec_`res'_`area'_`v'${covid_data}.png", replace				
				capture qui graph export "$FIGURES\Event Study\covid_grade_sec_`res'_`area'_`v'${covid_data}.pdf", replace						
					

			}
		}
	}	

end

************************************************************************************








main
