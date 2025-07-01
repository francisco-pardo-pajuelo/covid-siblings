/********************************************************************************
- Author: Francisco Pardo
- Description: Create Final matched database
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/

capture program drop main 
program define main 

setup_A04

*- Standardized measures achievement
timer clear 91
timer on 91
//standardize_gpa_beta
//standardize_uni_beta
timer off 91

*- Final Student Database
timer clear 92
timer on 92
student_final
timer off 92

*- Average data
timer clear 93
timer on 93
average_data_school
timer off 93

*- application_averages
timer clear 94
timer on 94
peer_application major
timer off 94

*- Final applications-sibling database
timer clear 95
timer on 95
application_final 2
timer off 95


	
end





********************************************************************************
* Setup
********************************************************************************

capture program drop setup_A04
program define setup_A04
	
	global fam_type = 2
	global test_A04_siagie = 0 	//Use test data from SIAGIE
	global test_A04 = 0			//Produce test data here
	global run_siagie_append = 1
	global run_predicted_uni = 0
	global run_predicted_enroll_rej = 0
	set seed 1234

	global test_size = "s" //"s" "m" "h"
	
	if ${test_A04} == 0 global data = ""
	if ${test_A04} == 1 global data = "_TEST${test_size}"
	if ${test_A04_siagie} == 0 global data_siagie = ""
	if ${test_A04_siagie} == 1 global data_siagie = "_TEST"
	
	if  ${test_A04_siagie}==1 assert ${run_predicted_uni}!=1
end
 
********************************************************************************
* Final database: Student level
********************************************************************************

*- We keep most relevant data
capture program drop student_final 
program define student_final 


timer clear 1
timer on 1

	clear
	
	if ${run_siagie_append} == 1 {
	
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		append using "$TEMP\siagie_`y'${data_siagie}", keep(id_ie id_per_umc level grade /*grade_????*/ year male_siagie region_siagie public_siagie urban_siagie /*carac_siagie*/ approved /*approved_????*/ approved_first /*approved_first_????*/ section_siagie /*comm_secondary_???? math_secondary_????*/ math comm std_gpa_? /*change_ie_???? lat_ie lon_ie*/)
	}
	
	sort id_per_umc
	merge m:1 id_per_umc /*id_ie year grade*/ using "$TEMP\standardized_beta_gpa_school_yearvars${data}${data_siagie}", keep(master match) keepusing(grade_???? 	approved_???? approved_first_???? /*math_secondary_* comm_secondary_**/ std_gpa_?_???? /*std_pred_gpa_?_all_**/ std_pred_gpa_?_ie_y_????) nogen
	
	capture drop comm_secondary_2023 math_secondary_2023 
	capture drop std_gpa_?_2023
	/*
	foreach year_vars in "grade" /*"comm_secondary" "math_secondary"*/ "approved" "approved_first" "std_gpa_m" "std_gpa_c" {
		foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
			if inlist("`year_vars'","grade")!=1 & "`y'"=="2023" continue //No data for secondary grades in scale 0-20 for 2023
			bys id_per_umc (`year_vars'_`y'): replace `year_vars'_`y' = `year_vars'_`y'[1]
		}
	}
	*/
	
	save "$TEMP\siagie_append${data_siagie}", replace
	}
	
	if ${run_siagie_append} == 0 use "$TEMP\siagie_append${data_siagie}", clear

timer off 1	


timer clear 2
timer on 2
	preserve
		use "$TEMP\id_siblings", clear
		keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}
		if ${test_A04}==1 & "${test_size}" == "s" bys id_fam_${fam_type}: egen sample =max(cond(_n==1,runiform()<0.005,.))
		if ${test_A04}==1 & "${test_size}" == "m" bys id_fam_${fam_type}: egen sample =max(cond(_n==1,runiform()<0.05,.))
		if ${test_A04}==1 & "${test_size}" == "h" bys id_fam_${fam_type}: egen sample =max(cond(_n==1,runiform()<0.1,.))
		if ${test_A04}==0 gen sample=1
		keep if sample==1
		drop sample	
		tempfile id_siblings_sample
		save `id_siblings_sample', replace
	restore

	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}) 
	rename _m merge_siblings
	if ${test_A04}==1 keep if merge_siblings==3
timer off 2


timer clear 2
timer on 2
*- Attach distances to closest universities
merge m:1 id_ie using "$TEMP\school_uni_distances", keep(master match) keepusing(min_dist_uni min_dist_uni_public min_dist_uni_private) nogen

timer off 2
	
timer clear 3
timer on 3	
//	destring id_per_umc, replace
	
timer off 3





timer clear 5
timer on 5	
	*- Keep sample for test run
	if ${test_A04}==1 {
		if "${test_size}" == "s" bys id_fam_${fam_type}: egen sample =max(cond(_n==1,runiform()<0.005,.))
		if "${test_size}" == "m" bys id_fam_${fam_type}: egen sample =max(cond(_n==1,runiform()<0.05,.))
		if "${test_size}" == "h" bys id_fam_${fam_type}: egen sample =max(cond(_n==1,runiform()<0.1,.))
		keep if sample==1
		drop sample
		}
		
	
	*- Remove all pre-elementary observations
	drop if level==1
	
	*- If max level is pre-school, then remove those observations as we will have no relevant outcomes: (not relevant anymore because of above filter)
	bys id_per_umc: egen max_level=max(level)
	drop if max_level == 1 
	drop max_level
timer off 5	

timer clear 6
timer on 6
	*- Schools by level (to see if they match with sibling)
	bys id_per_umc level (year grade approved): gen id_ie_last_level = id_ie[_N] //Last school in primary they were at
	gen id_ie_pri = id_ie_last_level if level==2
	bys id_per_umc (id_ie_pri): replace id_ie_pri=id_ie_pri[_N] //assign to all obs. Max didn't accept strings.
	gen id_ie_sec = id_ie_last_level if level==3
	bys id_per_umc (id_ie_sec): replace id_ie_sec=id_ie_sec[_N]
	drop id_ie_last_level
timer off 6	

timer clear 7
timer on 7
	*- Entry and graduating year (expected until DOB)
	bys id_per_umc: egen int min_year = min(year)
	bys id_per_umc: egen int exp_entry_year = max(cond(year==min_year,min_year-grade+1,.))
	
	bys id_per_umc: egen int max_year = max(year)
	bys id_per_umc: egen int exp_graduating_year1 = max(cond(year==max_year,11-grade+max_year,.)) //based on most current information (what we care for sample in application)
	gen int exp_graduating_year2 = exp_entry_year+10 //based on entry year
timer off 7

timer clear 8
timer on 8
/*
	*- Approved per year
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		bys id_per_umc (year): egen byte approved_`y' = max(cond(year==`y',approved,.)) 
		bys id_per_umc (year): egen byte approved_first_`y' = max(cond(year==`y',approved_first,.)) 
		}
		
	*- GPA per year
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		bys id_per_umc (year): egen byte math_secondary_`y' = max(cond(year==`y',math_secondary,.)) 
		bys id_per_umc (year): egen byte comm_secondary_`y' = max(cond(year==`y',comm_secondary,.)) 
		bys id_per_umc (year): egen byte std_gpa_m_`y' = max(cond(year==`y',std_gpa_m,.)) 
		bys id_per_umc (year): egen byte std_gpa_c_`y' = max(cond(year==`y',std_gpa_c,.)) 
		}		
		

	*- Change IE per year
	bys id_per_umc (year): gen byte change_ie = id_ie[_n]!=id_ie[_n-1] if id_per_umc[_n]==id_per_umc[_n-1] & (inlist(grade,0,1,6)==0)
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		bys id_per_umc (year): egen byte change_ie_`y' = max(cond(year==`y',change_ie,.)) 
		}
	*/
timer off 8	

timer clear 9
timer on 9
	*- Year finished school
	bys id_per_umc: egen int year_grad_school = 	max(cond(grade==11 & approved==1,year,.))
	
	*- Finished primary and secondary
	bys id_per_umc: egen byte pri_grad = 	max(cond(grade>=6 & approved==1,1,0))
	bys id_per_umc: egen byte sec_grad = 	max(cond(grade==11 & approved==1,1,0))
		
	*- Dropout
	bys id_per_umc: egen byte 	finished_school 	= max(cond(grade==11 & approved==1,1,0)) 
	bys id_per_umc: egen int	last_year 			= max(year) 
	
	gen byte dropout = (last_year<2023 & finished_school==0 & last_year==year)
	bys id_per_umc: egen int dropout_year = 	max(cond(dropout==1,last_year+1,.))
	bys id_per_umc: egen int dropout_grade = 	max(cond(dropout==1,grade,.))
	bys id_per_umc: egen byte dropout_ever = 	max(cond(dropout==1,1,0))

	drop approved approved_first
	
	label var exp_entry_year "Expected entry year based on first observation"
	label var exp_graduating_year1 "Expected graduating year based on last observation"
	label var exp_graduating_year2 "Expected graduating year based on first observation"
timer off 9


timer clear 10
timer on 10	
	//we keep data from last observation	
	bys id_per_umc (year grade): keep if _n==_N

	isvar /*Relevant vars*/ id_ie id_per_umc id_ie_??? exp_entry_year exp_graduating_year1 exp_graduating_year2 male_siagie region_siagie public_siagie urban_siagie carac_siagie grade grade_???? section_siagie year dropout* approved_???? approved_first_???? math_secondary_???? comm_secondary_???? std_gpa_?_???? change_ie_???? std_pred_gpa_?_all_* std_pred_gpa_?_ie_y_*  pri_grad sec_grad year_grad_school educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} lat_ie lon_ie min_dist* 
			
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'
	compress	
		
	
	rename (year grade section_siagie /*lat_ie lon_ie*/) (last_year last_grade last_section /*last_lat_ie last_lon_ie*/)
	
	compress
	
timer off 10	

timer clear 11
timer on 11
	
	save "$TEMP\siagie_ids${data}${data_siagie}", replace
	
	use "$TEMP\siagie_ids${data}${data_siagie}", clear
	

	
	*- Match ECE IDs
	merge 1:1 id_per_umc using "$TEMP\match_siagie_ece_2p", keep(master match) keepusing(id_estudiante source)
	rename _m merge_2p
	//tab grade merge_2p, row nofreq
	rename (id_estudiante source) (id_estudiante_2p source_2p)

	merge 1:1 id_per_umc using "$TEMP\match_siagie_ece_4p", keep(master match) keepusing(id_estudiante source)
	rename _m merge_4p
	//tab grade merge_4p, row nofreq
	rename (id_estudiante source) (id_estudiante_4p source_4p)

	merge 1:1 id_per_umc using "$TEMP\match_siagie_ece_2s", keep(master match) keepusing(id_estudiante source)
	rename _m merge_2s
	//tab grade merge_2s, row nofreq
	rename (id_estudiante source) (id_estudiante_2s source_2s)
timer off 11

timer clear 12
timer on 12	
	*- They are unique in using database so should be unique
	distinct id_estudiante_2p if id_estudiante_2p!=""
	assert r(N) == r(ndistinct)
	distinct id_estudiante_4p if id_estudiante_4p!=""
	assert r(N) == r(ndistinct)
	distinct id_estudiante_2s if id_estudiante_2s!=""
	assert r(N) == r(ndistinct)

timer off 12


timer clear 13
timer on 13	
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

timer off 13


timer clear 14
timer on 14	
	*- Match EM exams
	merge m:1 id_estudiante_2p using  "$TEMP\em_2p", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year) //m:1 because there are missings
	rename _m merge_m_2p
	replace year_2p = year if year_2p==.
	replace score_math_std_2p 	= score_math_std 	if score_math_std_2p==.
	replace score_com_std_2p 	= score_com_std 	if score_com_std_2p==.
	replace score_acad_std_2p 	= score_acad_std 	if score_acad_std_2p==.
	replace socioec_index_2p = socioec_index if socioec_index_2p ==.
	replace socioec_index_cat_2p = socioec_index_cat if socioec_index_cat_2p ==.
	drop score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year	
	
	merge m:1 id_estudiante_4p using "$TEMP\em_4p", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year) //m:1 because there are missings
	rename _m merge_m_4p
	replace year_4p = year if year_4p==.
	replace score_math_std_4p 	= score_math_std 	if score_math_std_4p==.
	replace score_com_std_4p 	= score_com_std 	if score_com_std_4p==.
	replace score_acad_std_4p 	= score_acad_std 	if score_acad_std_4p==.
	replace socioec_index_4p = socioec_index if socioec_index_4p ==.
	replace socioec_index_cat_4p = socioec_index_cat if socioec_index_cat_4p ==.
	drop score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year
	
	merge m:1 id_estudiante_2s using "$TEMP\em_2s", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year) //m:1 because there are missings
	rename _m merge_m_2s
	replace year_2s = year if year_2s==.
	replace score_math_std_2s 	= score_math_std 	if score_math_std_2s==.
	replace score_com_std_2s 	= score_com_std 	if score_com_std_2s==.
	replace score_acad_std_2s 	= score_acad_std 	if score_acad_std_2s==.
	replace socioec_index_2s = socioec_index if socioec_index_2s ==.
	replace socioec_index_cat_2s = socioec_index_cat if socioec_index_cat_2s ==.
	drop score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year
timer off 14

timer clear 15
timer on 15	
	
	*- Match ECE survey
	merge m:1 id_estudiante_2p using "$TEMP\ece_family_2p", keep(master match) keepusing(aspiration_2p) //m:1 because there are missings
	rename _m merge_ece_survey_2p
	
	merge m:1 id_estudiante_4p using "$TEMP\ece_family_4p", keep(master match) keepusing(aspiration_4p gender_subj_?_4p) //m:1 because there are missings
	rename _m merge_ece_survey_4p
	
	merge m:1 id_estudiante_2s using "$TEMP\ece_student_2s", keep(master match) keepusing(aspiration_2s lives_with_*_2s total_siblings_2s) //m:1 because there are missings
	rename _m merge_ece_survey_2s

timer off 15


timer clear 16
timer on 16	
	
	*- Match with SIRIES (applications and enrollment)
	//merge m:1 id_per_umc using "$TEMP\applied", keep(master match) keepusing()
	
	*- Aspirations
	gen byte asp_college2_2p = inlist(aspiration_2p,3,4,5) if aspiration_2p!=.
	gen byte asp_college2_4p = inlist(aspiration_4p,3,4,5) if aspiration_4p!=.
	gen byte asp_college2_2s = inlist(aspiration_2s,3,4,5) if aspiration_2s!=.	
	gen byte asp_college4_2p = inlist(aspiration_2p,4,5) if aspiration_2p!=.
	gen byte asp_college4_4p = inlist(aspiration_4p,4,5) if aspiration_4p!=.
	gen byte asp_college4_2s = inlist(aspiration_2s,4,5) if aspiration_2s!=.
	
	*- Gender belief
	egen gender_miss_4p = rownonmiss( gender_subj_?_4p)
	forvalues i = 1/6 {
	  gen gender_subj_`i'_4p_dum = inlist(gender_subj_`i'_4p,1,2)==1 if gender_subj_`i'_4p !=.
	  VarStandardiz gender_subj_`i'_4p_dum, newvar(std_gender_subj_`i'_4p_dum)
	  drop gender_subj_`i'_4p_dum
	}
	egen belief_gender_boy_4p 	= rmean(std_gender_subj_1_4p_dum std_gender_subj_3_4p_dum std_gender_subj_5_4p_dum)
	egen belief_gender_girl_4p = rmean(std_gender_subj_2_4p_dum std_gender_subj_4_4p_dum std_gender_subj_6_4p_dum)
	egen belief_gender_4p 		= rmean(std_gender_subj_?_4p_dum)
	VarStandardiz belief_gender_boy_4p		, newvar(std_belief_gender_boy_4p)
	VarStandardiz belief_gender_girl_4p		, newvar(std_belief_gender_girl_4p)
	VarStandardiz belief_gender_4p			, newvar(std_belief_gender_4p)
	drop belief_gender_boy_4p belief_gender_girl_4p belief_gender_4p std_gender_subj_?_4p_dum
	
timer off 16

timer clear 17
timer on 17	
	
	
	*- University variables (application, enrollment, graduation, peers)
	merge 1:1 id_per_umc using "$TEMP\student_umc_uni",  keep(master match) nogen
	


timer off 17

timer clear 18
timer on 18	
	*- Sibling outcomes
	//
	
	
	*- School characteristics related to unversity:
	bys id_ie: egen avg_applied 			= mean(cond(exp_graduating_year2>=2016 & exp_graduating_year2<=2022,applied,.))
	bys id_ie: egen avg_applied_public 		= mean(cond(exp_graduating_year2>=2016 & exp_graduating_year2<=2022,applied_public,.))
	bys id_ie: egen avg_applied_private 	= mean(cond(exp_graduating_year2>=2016 & exp_graduating_year2<=2022,applied_private,.))

	//		bys id_ie: egen avg_applied_public_if 	= mean(cond(exp_graduating_year2>=2016 & exp_graduating_year2<=2022 & applied==1,applied_public,.))
//		bys id_ie: egen avg_applied_private_if 	= mean(cond(exp_graduating_year2>=2016 & exp_graduating_year2<=2022 & applied==1,applied_private,.))

	bys id_ie: egen avg_enrolled 			= mean(cond(exp_graduating_year2>=2016 & exp_graduating_year2<=2022,enrolled,.))
	bys id_ie: egen avg_enrolled_public 	= mean(cond(exp_graduating_year2>=2016 & exp_graduating_year2<=2022,enrolled_public,.))
	bys id_ie: egen avg_enrolled_private 	= mean(cond(exp_graduating_year2>=2016 & exp_graduating_year2<=2022,enrolled_private,.))

timer off 18


timer clear 19
timer on 19	
	*- Likelihood of enrollment
	if ${run_predicted_uni} == 1 likelihood_uni
	merge 1:1 id_per_umc using "$TEMP\likelihood_uni${data}", keepusing(*lpred?) keep(master match) nogen
	
timer off 19


timer clear 20
timer on 20
	//Other potential variables: Lives with mother/father/caretaker, age, province/district with university, id_ie?, mother tongue.
	
	*- Individual best SES indicator //We keep the latest one.
	gen socioec_index_cat_all = socioec_index_cat_2s
	replace socioec_index_cat_all = socioec_index_cat_4p if socioec_index_cat_all==.
	replace socioec_index_cat_all = socioec_index_cat_2p if socioec_index_cat_all==.
	
	*- Household variables
	bys id_fam_${fam_type}: egen socioec_index_cat_fam = max(socioec_index_cat_all)
	//These can be endogenous, as we are constructing based on all-time maximums. ###
	
	*- Label variables
	capture label define educ 1 "None" 2 "Primary Incomplete" 3 "Primary Complete" 4 "Secondary Incomplete" 5 "Secondary Complete" 6 "Higher Incomplete" 7 "Higher Complete" 8 "Post-grad", replace
	label values educ_caretaker educ_mother educ_father educ
	
	
	*- Destring ID variables that are numeric in newer version of SIRIES
	destring id_per_umc, replace

timer off 20

timer clear 21
timer on 21
	
		
	isvar 		/*ID*/ 					id_ie id_per_umc id_ie_pri id_ie_sec id_fam_?  ///
				/*School Char*/ 		region_siagie public_siagie urban_siagie carac_siagie fam_total_? ///
				/*School Dist*/ 		min_dist* ///
				/*Demographics*/ 		male_siagie educ_caretaker educ_mother educ_father exp_entry_year exp_graduating_year1  exp_graduating_year2 fam_order_? lives_with_* grade_???? ///
				/*Last observation*/ 	last_grade last_section last_year last_lat_ie last_lon_ie ///
				/*Attainment*/			pri_grad sec_grad year_grad_school ///
				/*Progression*/			approved_???? approved_first_???? ///
				/*GPA*/					math_secondary_???? comm_secondary_???? std_gpa_?_???? std_pred_gpa_?_all_* std_pred_gpa_?_ie_y_* ///
				/*Dropout*/  			dropout dropout_year dropout_grade dropout_ever ///
				/*Change schools*/		change_ie_???? ///
				/*ECE*/					year_??  score_*_std_2p score_*_std_4p score_*_std_2s  ///
				/*ECE Survey*/			socioec_index_?? socioec_index_cat_?? socioec_index_cat_??? aspiration_?? asp_college?_?? lives_with_???_2s total_siblings_2s  ///
				/*Applications*/		year_app dob_app applied year_app_public applied_public year_app_private applied_private year_app_*stem applied_*stem  ///
				/*Admitted*/ 			year_adm admitted year_adm_public admitted_public year_adm_private admitted_private ///
				/*Enrolled*/			year_enr dob_enr enrolled year_enr_public enrolled_public year_enr_private enrolled_private year_enr_*stem enrolled_*stem score_std_uni_enr  ///
				/*Enrolled peers ECE*/	peer_score_math_std_2p peer_score_com_std_2p peer_score_acad_std_2p peer_score_math_std_2s peer_score_com_std_2s peer_score_acad_std_2s ///
				/*Enrolled peers grad*/	peer_grad* ///
				/*Enrolled peers SES*/	peer_socio* ///
				/*Persistence*/			enrolled_?year n_credits_?year ///
				/*Graduated*/			year_graduated dob_graduated graduated year_graduated_public graduated_public year_graduated_private graduated_private score_std_uni_grad ///
				/*School averages*/		avg_applied* avg_enrolled* ///
				/*Likelihoods*/			applied_lpred? admitted_lpred? enrolled_lpred? ///
				/*To include*/			 /// gender_subj_* std_belief_gender_* ///
				/*Not included*/		 /// id_estudiante_?? source_?? merge_?? urban_?? merge_ece_?? merge_m_?? merge_ece_survey_?? gender_miss_4p 
	
				local all_vars = r(varlist)
				ds `all_vars', not
				keep `all_vars'
				order `all_vars'

				foreach v of local all_vars {
					capture confirm string variable `v'
						if _rc==0 {
							   replace `v' = trim(itrim(`v'))
						}
				}
				
				*Destring those not IDs
				ds /*id_per_umc id_persona_rec*/ id_ie*, not //In newer version of SIRIES, IDs are numeric.
				local all_vars = r(varlist)
				destring `all_vars', replace
	timer off 21
	
	timer clear 22
timer on 22
				compress
timer off 22	
	save "$OUT\students${data}${data_siagie}", replace
	
	//capture erase "$TEMP\siagie_ids.dta"
end


capture program drop likelihood_uni
program define likelihood_uni

*- Heterogeneity analysis: Likelihood of going to college
	// We include 3 measures, with more variables but less sample progressively.
	
	preserve
	
		global pred_out 	   	"applied admitted enrolled"
		global pred_ifs 		"exp_graduating_year1 exp_graduating_year2"
		global pred_covar1 	"male_siagie educ_mother region_siagie urban_siagie public_siagie min_dist_uni"
		global pred_covar2 	"score_math_std_2p score_com_std_2p"
		global pred_covar3 	"score_math_std_2s score_com_std_2s aspiration_2s socioec_index_2s"
		
		ds ${pred_out} ${pred_ifs} ${pred_covar1} ${pred_covar2} ${pred_covar3}
		foreach out in "applied" "admitted" "enrolled" {
			
			capture drop `out'_lpred?
			count if exp_graduating_year1+1>=2017 & exp_graduating_year1+1<=2023
			local N = r(N)
			
			*-- #1 : ~98% of sample have data
			
			logit `out' ${covar1}						if exp_graduating_year1+1>=2017 & exp_graduating_year1+1<=2023
			local s1 =  e(N) 
			predict `out'_lpred1
			
			*-- #2 : ~55% of sample have data
			
			logit `out' ${covar1} ${covar2} 			if exp_graduating_year1+1>=2017 & exp_graduating_year1+1<=2023
			local s2 =  e(N) 
			predict `out'_lpred2
			
			*-- #3 : ~46% of sample have data
			
			logit `out' ${covar1} ${covar3}	if exp_graduating_year1+1>=2017 & exp_graduating_year1+1<=2023
			local s3 =  e(N) 
			predict `out'_lpred3
			
			*-- #4 : ~30% of sample have data
			logit `out' ${covar1} ${covar2} ${covar3}	if exp_graduating_year1+1>=2017 & exp_graduating_year1+1<=2023
			local s4 =  e(N) 
			predict `out'_lpred4
		
			
			di as text  _n "Sample 1:" %9.1f `s1'*100/`N' ///
						_n "Sample 2:" %9.1f `s2'*100/`N' ///
						_n "Sample 4:" %9.1f `s4'*100/`N' ///
						_n "Sample 3:" %9.1f `s3'*100/`N'
						
						
			//Set median cutoffs
			sum	`out'_lpred1, de
			gen `out'_lpred1_above = (`out'_lpred1>r(p50) & `out'_lpred1!=.)
			sum	`out'_lpred2, de`'
			gen `out'_lpred2_above = (`out'_lpred2>r(p50) & `out'_lpred2!=.)
			sum	`out'_lpred3, de`'
			gen `out'_lpred3_above = (`out'_lpred3>r(p50) & `out'_lpred3!=.)
			sum	`out'_lpred4, de`'
			gen `out'_lpred4_above = (`out'_lpred3>r(p50) & `out'_lpred3!=.)

		
		
	
	compress

			
		
		}
		
		keep id_per_umc *lpred? 
		sum *_lpred?
		save "$TEMP\likelihood_uni${data}${data_siagie}", replace
	restore
	


end

 
********************************************************************************
* Creating Standardized measures of achievement based on standardized national examinations for cross school comparissons and GPA/application score for within school/pool comparison
********************************************************************************	
	
*- Standardized measures of achievement 
capture program drop standardize_gpa_beta
program define standardize_gpa_beta
	
	*- 1. Get Standardized measure
	use "$TEMP\match_siagie_ece_2p", clear
	append using "$TEMP\match_siagie_ece_4p"
	append using "$TEMP\match_siagie_ece_2s"
	keep id_per_umc
	bys id_per_umc: keep if _n==1
	
	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2p", keep(master match) keepusing(id_estudiante) nogen
	rename id_estudiante id_estudiante_2p

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_4p", keep(master match) keepusing(id_estudiante) nogen
	rename id_estudiante id_estudiante_4p

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2s", keep(master match) keepusing(id_estudiante) nogen
	rename id_estudiante id_estudiante_2s

	merge m:1 id_estudiante_2p using  "$TEMP\ece_2p", keep(master match) keepusing(year score_math_std score_com_std score_acad_std) nogen //m:1 because there are missings
	rename (year score_math_std score_com_std score_acad_std) (year_2p score_math_std_2p score_com_std_2p score_acad_std_2p)
	
	merge m:1 id_estudiante_4p using "$TEMP\ece_4p", keep(master match) keepusing(score_math_std score_com_std score_acad_std year) nogen //m:1 because there are missings
	rename (year score_math_std score_com_std score_acad_std) (year_4p score_math_std_4p score_com_std_4p score_acad_std_4p)
	
	merge m:1 id_estudiante_2s using "$TEMP\ece_2s", keep(master match) keepusing(score_math_std score_com_std score_acad_std year) nogen //m:1 because there are missings
	rename (year score_math_std score_com_std score_acad_std) (year_2s score_math_std_2s score_com_std_2s score_acad_std_2s)

	order id_per_umc *2p *4p *2s 
	
	drop if year_2p ==. & year_4p == . & year_2s ==. 
	
	compress
	
	save "$TEMP\ece_id_per_umc", replace

	*- 2. Standardized school GPA
	
	clear
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		append using "$TEMP\siagie_`y'${data_siagie}", keep(id_ie id_per_umc year grade std_gpa_? std_gpa_?)
	}
	
	*- Get standardized measure
	merge m:1 id_per_umc using "$TEMP\ece_id_per_umc", keepusing(score*std_?? year_??) keep(master match) nogen
	
		
	rename score_math* score_m*
	rename score_com* score_c* 
	rename score_acad* score_a* 
	
	drop year_2p score_c_std_2p score_m_std_2p score_a_std_2p year_4p score_c_std_4p score_m_std_4p score_a_std_4p

	save "$TEMP\pre_reg_standardized_gpa${data}${data_siagie}", replace
	
	*- Regression with full sample (one slope)
	foreach cell_type in "all" /*"ie_g"*/ "ie_y" /*"ie"*/  {
		foreach subj in "m" "c" /*"l" "v"*/  {
			use "$TEMP\pre_reg_standardized_gpa${data}${data_siagie}", clear
			if "`cell_type'" == "all" 		local cell_vars = "id_ie year grade" 
			//Still very limited, because there is a correlation between ECE being available and Cells
			if "`cell_type'" == "ie_g" 		local cell_vars = "id_ie grade" 
			if "`cell_type'" == "ie_y" 		local cell_vars = "id_ie year " 
			if "`cell_type'" == "ie" 		local cell_vars = "id_ie" 

			gen sample = (score_`subj'_std_2s!=. & std_gpa_`subj'!=.)
			bys `cell_vars': egen N_sample = sum(sample)
			drop if N_sample<=1
			
			egen cell_`cell_type' = group(`cell_vars')
			
			*- We group them in groups of 100 to run the interacted regression (faster than single regressions)
			gen cell_group = floor(cell_`cell_type'/100)
			
			//local cell_type = "ie_y"
			gen pred_oos_gpa_`subj'_`cell_type' = .	
			levelsof cell_group, local(levels_group)	
			//distinct cell_group
			//local cell_group = r(ndistinct)
			//forvalues group = 1(1)`N_cell_`cell_type'' {
			foreach group of local levels_group {
				//count if cell_`cell_type' == `group' & score_`subj'_std_2s!=. & std_gpa_`subj'!=.
				//if r(N)<=1 continue
				reg score_m_std_2s cell_`cell_type'##c.std_gpa_`subj' if cell_group==`group'
				predict temp_pred_oos_gpa_`subj'_`cell_type' if cell_group==`group'
				replace pred_oos_gpa_`subj'_`cell_type' = temp_pred_oos_gpa_`subj'_`cell_type' if pred_oos_gpa_`subj'_`cell_type'==.
				drop temp_pred_oos_gpa_`subj'_`cell_type'
				}	
			VarStandardiz pred_oos_gpa_`subj'_`cell_type', newvar(std_pred_gpa_`subj'_`cell_type')
			keep id_per_umc year pred* std_pred*
			save "$TEMP\pre_reg_standardized_gpa_`subj'_`cell_type'${data}${data_siagie}", replace
		}
	}

	use "$TEMP\pre_reg_standardized_gpa${data}${data_siagie}", clear
	merge 1:1 id_per_umc year using "$TEMP\pre_reg_standardized_gpa_m_all${data}${data_siagie}"	, keepusing(pred* std_pred*) keep(master match) nogen
	merge 1:1 id_per_umc year using "$TEMP\pre_reg_standardized_gpa_c_all${data}${data_siagie}"	, keepusing(pred* std_pred*) keep(master match) nogen
	merge 1:1 id_per_umc year using "$TEMP\pre_reg_standardized_gpa_m_ie_y${data}${data_siagie}"	, keepusing(pred* std_pred*) keep(master match) nogen
	merge 1:1 id_per_umc year using "$TEMP\pre_reg_standardized_gpa_c_ie_y${data}${data_siagie}"	, keepusing(pred* std_pred*) keep(master match) nogen
	
	//drop if std_pred_gpa_m_ie_y ==. & std_pred_gpa_m_all==. & std_pred_gpa_c_ie_y ==. & std_pred_gpa_c_all==.
	keep id_per_umc id_ie grade year *pred_*
		
	save "$TEMP\standardized_beta_gpa_school${data}${data_siagie}", replace
	
	use "$TEMP\standardized_beta_gpa_school${data}${data_siagie}", clear
	
	keep id_per_umc year std_pred_gpa_?_all std_pred_gpa_?_ie_y 
	reshape wide std_pred_gpa_?_all std_pred_gpa_?_ie_y, i(id_per_umc) j(year)
	
	rename std_pred_gpa_?_all* std_pred_gpa_?_all_*
	rename std_pred_gpa_?_ie_y* std_pred_gpa_?_ie_y_*
	
	merge 1:1 id_per_umc using "$TEMP\siagie_yearvars${data}${data_siagie}", keep(master match) nogen
	
	keep 	id_per_umc  grade_???? approved_???? approved_first_???? /*math_secondary_????*/ std_gpa_?_???? std_pred_gpa_?_all_???? std_pred_gpa_?_ie_y_???? 
	order 	id_per_umc  grade_???? approved_???? approved_first_???? /*math_secondary_????*/ std_gpa_?_???? std_pred_gpa_?_all_???? std_pred_gpa_?_ie_y_???? 
	//capture drop math_secondary_2023 comm_secondary_2023
	//capture drop std_gpa_m_2023 std_gpa_c_2023
	compress
	save "$TEMP\standardized_beta_gpa_school_yearvars${data}${data_siagie}", replace

	
	*- 3. Standardized uni GPA
	/*
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		//append using "$TEMP\siagie_`y'${data_siagie}", keep(id_ie id_per_umc year grade std_gpa_m std_gpa_c)
	}
	
	*- Get standardized measure
	merge m:1 id_per_umc using "$TEMP\ece_id_per_umc", keepusing(score*std_?? year_??) keep(master match) nogen
	
	*- Regression with full sample (one slope)
	egen cell = group(id_ie year grade)
	reghdfe score_math_std_2s std_gpa_m, a(cell) resid
	predict predict_gpa_m, xbd 
	label var predict_gpa_m "Predicted National GPA - Mathematics"
	rename predict_gpa_m temp
	VarStandardiz temp, newvar(predict_gpa_m)
	
	keep id_per_umc id_ie year grade predict_gpa_m
	
	save "$TEMP\standardized_gpa_school", replace
	*/
	*- 4. Standardized uni applications
	/*
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		//append using "$TEMP\siagie_`y'${data_siagie}", keep(id_ie id_per_umc year grade std_gpa_m std_gpa_c)
	}
	
	*- Get standardized measure
	merge m:1 id_per_umc using "$TEMP\ece_id_per_umc", keepusing(score*std_?? year_??) keep(master match) nogen
	
	*- Regression with full sample (one slope)
	
	egen cell = group(id_ie year grade)
	reghdfe score_math_std_2s std_gpa_m, a(cell) resid
	predict predict_gpa_m, xbd 
	label var predict_gpa_m "Predicted National GPA - Mathematics"
	rename predict_gpa_m temp
	VarStandardiz temp, newvar(predict_gpa_m)
	
	keep id_per_umc id_ie year grade predict_gpa_m
	
	save "$TEMP\standardized_gpa_school", replace
	*/
end

********************************************************************************
* Creating Standardized measures of achievement based on standardized national examinations for cross university comparissons and application scores
********************************************************************************	
	
*- Standardized measures of achievement 
capture program drop standardize_uni_exams_beta
program define standardize_uni_exams_beta
	
	*- 1. Get Standardized measure
	/*
	use "$TEMP\match_siagie_ece_2p", clear
	append using "$TEMP\match_siagie_ece_4p"
	append using "$TEMP\match_siagie_ece_2s"
	keep id_per_umc
	bys id_per_umc: keep if _n==1
	
	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2p", keep(master match) keepusing(id_estudiante) nogen
	rename id_estudiante id_estudiante_2p

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_4p", keep(master match) keepusing(id_estudiante) nogen
	rename id_estudiante id_estudiante_4p

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2s", keep(master match) keepusing(id_estudiante) nogen
	rename id_estudiante id_estudiante_2s

	merge m:1 id_estudiante_2p using  "$TEMP\ece_2p", keep(master match) keepusing(year score_math_std score_com_std score_acad_std) nogen //m:1 because there are missings
	rename (year score_math_std score_com_std score_acad_std) (year_2p score_math_std_2p score_com_std_2p score_acad_std_2p)
	
	merge m:1 id_estudiante_4p using "$TEMP\ece_4p", keep(master match) keepusing(score_math_std score_com_std score_acad_std year) nogen //m:1 because there are missings
	rename (year score_math_std score_com_std score_acad_std) (year_4p score_math_std_4p score_com_std_4p score_acad_std_4p)
	
	merge m:1 id_estudiante_2s using "$TEMP\ece_2s", keep(master match) keepusing(score_math_std score_com_std score_acad_std year) nogen //m:1 because there are missings
	rename (year score_math_std score_com_std score_acad_std) (year_2s score_math_std_2s score_com_std_2s score_acad_std_2s)

	order id_per_umc *2p *4p *2s 
	
	drop if year_2p ==. & year_4p == . & year_2s ==. 
	
	compress
	
	save "$TEMP\ece_id_per_umc", replace
	*/
	*- 2. Standardized school GPA
	
	clear
	use "$TEMP\applied", clear
	ds score_std_major
	
	*- Get standardized measure
	merge m:1 id_per_umc using "$TEMP\ece_id_per_umc", keepusing(score*std_?? year_??) keep(master match) nogen
	
		
	rename score_math* score_m*
	rename score_com* score_c* 
	rename score_acad* score_a* 
	
	drop year_2p score_c_std_2s score_m_std_2s score_a_std_2s year_4p score_c_std_4p score_m_std_4p score_a_std_4p

	keep id_per_umc id_ie id_persona_rec id_cutoff_major codigo_modular id_periodo_postulacion score_raw score_std_major score_a_std_2p
	
	save "$TEMP\pre_reg_standardized_uni${data}${data_siagie}", replace
	
	*- Regression with full sample (one slope)
	foreach cell_type in "all" /*"ie_g"*/ /*"ie_y"*/ /*"ie"*/  {
		foreach subj in "a" /*"m" "c" "l" "v"*/  {
			use "$TEMP\pre_reg_standardized_uni${data}${data_siagie}", clear
			if "`cell_type'" == "all" 		local cell_vars = "id_cutoff_major" 
			//Still very limited, because there is a correlation between ECE being available and Cells
			if "`cell_type'" == "ie_g" 		local cell_vars = "id_ie grade" 
			if "`cell_type'" == "ie_y" 		local cell_vars = "id_ie year " 
			if "`cell_type'" == "ie" 		local cell_vars = "id_ie" 

			gen sample = (score_`subj'_std_2p!=. & score_std_major!=.)
			bys `cell_vars': egen N_sample = sum(sample)
			drop if N_sample<=1
			
			egen cell_`cell_type' = group(`cell_vars')
			
			*- We group them in groups of 100 to run the interacted regression (faster than single regressions)
			gen cell_group = floor(cell_`cell_type'/100)
			
			//local cell_type = "ie_y"
			gen pred_oos_uni_`cell_type' = .	
			levelsof cell_group, local(levels_group)	
			//distinct cell_group
			//local cell_group = r(ndistinct)
			//forvalues group = 1(1)`N_cell_`cell_type'' {
			foreach group of local levels_group {
				//count if cell_`cell_type' == `group' & score_`subj'_std_2p!=. & std_gpa_`subj'!=.
				//if r(N)<=1 continue
				reg score_a_std_2p cell_`cell_type'##c.score_std_major if cell_group==`group'
				predict temp_pred_oos_uni_`cell_type' if cell_group==`group'
				replace pred_oos_uni_`cell_type' = temp_pred_oos_uni_`cell_type' if pred_oos_uni_`cell_type'==.
				drop temp_pred_oos_uni_`cell_type'
				}	
			VarStandardiz pred_oos_uni_`cell_type', newvar(std_pred_uni_`cell_type')
			keep id_per_umc id_persona_rec id_cutoff_major codigo_modular id_periodo_postulacion score_raw score_std_major score_a_std_2p year pred* std_pred*
			save "$TEMP\pre_reg_standardized_uni_`cell_type'${data}${data_siagie}", replace
		}
	}

	use "$TEMP\pre_reg_standardize_uni${data}${data_siagie}", clear
	merge 1:1 id_per_umc year using "$TEMP\pre_reg_standardized_uni_all${data}${data_siagie}"	, keepusing(pred* std_pred*) keep(master match) nogen
	//merge 1:1 id_per_umc year using "$TEMP\pre_reg_standardized_uni_ie_y${data}${data_siagie}"	, keepusing(pred* std_pred*) keep(master match) nogen
	//drop if std_pred_gpa_m_ie_y ==. & std_pred_gpa_m_all==. & std_pred_gpa_c_ie_y ==. & std_pred_gpa_c_all==.
	keep id_per_umc id_ie grade year *pred_*
		
	save "$TEMP\standardized_beta_uni${data}${data_siagie}", replace
	
	use "$TEMP\standardized_beta_uni${data}${data_siagie}", clear
	
	keep id_per_umc year std_pred_uni_all /*std_pred_uni_ie_y*/ 
	reshape wide std_pred_uni_all /*std_pred_uni_ie_y*/, i(id_per_umc) j(year)
	
	rename std_pred_uni_all* 	std_pred_uni_all_*
	//rename std_pred_uni_ie_y* 	std_pred_uni_ie_y_*
	
	merge 1:1 id_per_umc using "$TEMP\siagie_yearvars${data}${data_siagie}", keep(master match) nogen
	
	keep 	/*ID*/ id_per_umc id_persona_rec id_cutoff_major codigo_modular id_periodo_postulacion /*ID SCORE*/ score_raw score_std_major score_a_std_2p /*STANDARDIZED UNI SCORE*/ std_pred_uni_all_???? /*std_pred_uni_ie_y_????*/
	order 	/*ID*/ id_per_umc id_persona_rec id_cutoff_major codigo_modular id_periodo_postulacion /*ID SCORE*/ score_raw score_std_major score_a_std_2p /*STANDARDIZED UNI SCORE*/ std_pred_uni_all_???? /*std_pred_uni_ie_y_????*/
	compress
	save "$TEMP\standardized_beta_uni_yearvars${data}${data_siagie}", replace

	
end
 
********************************************************************************
* Creating Standardized measures of achievement based on standardized national examinations for cross school comparissons and GPA/application score for within school/pool comparison
********************************************************************************	
	
*- Standardized measures of achievement 



capture program drop standardize_gpa
program define standardize_gpa
	
	*- 1. Get Standardized measure
	use "$TEMP\match_siagie_ece_2p", clear
	append using "$TEMP\match_siagie_ece_4p"
	append using "$TEMP\match_siagie_ece_2s"
	keep id_per_umc
	bys id_per_umc: keep if _n==1
	
	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2p", keep(master match) keepusing(id_estudiante) nogen
	rename id_estudiante id_estudiante_2p

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_4p", keep(master match) keepusing(id_estudiante) nogen
	rename id_estudiante id_estudiante_4p

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2s", keep(master match) keepusing(id_estudiante) nogen
	rename id_estudiante id_estudiante_2s

	merge m:1 id_estudiante_2p using  "$TEMP\ece_2p", keep(master match) keepusing(year score_math_std score_com_std score_acad_std) nogen //m:1 because there are missings
	rename (year score_math_std score_com_std score_acad_std) (year_2p score_math_std_2p score_com_std_2p score_acad_std_2p)
	
	merge m:1 id_estudiante_4p using "$TEMP\ece_4p", keep(master match) keepusing(score_math_std score_com_std score_acad_std year) nogen //m:1 because there are missings
	rename (year score_math_std score_com_std score_acad_std) (year_4p score_math_std_4p score_com_std_4p score_acad_std_4p)
	
	merge m:1 id_estudiante_2s using "$TEMP\ece_2s", keep(master match) keepusing(score_math_std score_com_std score_acad_std year) nogen //m:1 because there are missings
	rename (year score_math_std score_com_std score_acad_std) (year_2s score_math_std_2s score_com_std_2s score_acad_std_2s)

	order id_per_umc *2p *4p *2s 
	
	drop if year_2p ==. & year_4p == . & year_2s ==. 
	
	compress
	
	save "$TEMP\ece_id_per_umc", replace

	*- 2. Standardized school GPA
	
	clear
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		append using "$TEMP\siagie_`y'${data_siagie}", keep(id_ie id_per_umc year grade std_gpa_?)
	}
	
	*- Get standardized measure
	merge m:1 id_per_umc using "$TEMP\ece_id_per_umc", keepusing(score*std_?? year_??) keep(master match) nogen
	
		
	rename score_math* score_m*
	rename score_com* score_c* 
		
	*- Regression with full sample (one slope)
	foreach cell_type in "all" /*"ie_g"*/ "ie_y" /*"ie"*/  {
		if "`cell_type'" == "all" 		egen cell_`cell_type' = group(id_ie year grade)
		//Still very limited, because there is a correlation between ECE being available and Cells
		
		if "`cell_type'" == "ie_g" 	egen cell_`cell_type' = group(id_ie grade)
		if "`cell_type'" == "ie_y" 	egen cell_`cell_type' = group(id_ie year)
		if "`cell_type'" == "ie" 		egen cell_`cell_type' = group(id_ie)

		foreach subj in "m" "c" /*"l" "v"*/ {
		*- Mathematics
		reghdfe score_`subj'_std_2s std_gpa_`subj', a(FE_`subj'_`cell_type'=cell_`cell_type') resid
			
		bys cell_`cell_type' (FE_`subj'_`cell_type'): replace FE_`subj'_`cell_type' = FE_`subj'_`cell_type'[1]
		//replace FE = 0 if FE == .

		*- In sample (only for e(sample), way reghdfe differs from reg.)
		predict pred_gpa_`subj'_`cell_type', xbd 
		
		*- We force OOS estimation
		predict xvars_`subj'_`cell_type', xb
		gen pred_oos_gpa_`subj'_`cell_type' = xvars_`subj'_`cell_type'+FE_`subj'_`cell_type'
		
		VarStandardiz pred_oos_gpa_`subj'_`cell_type', newvar(std_pred_gpa_`subj'_`cell_type')
		}
	}

	//drop if std_pred_gpa_m_ie_y ==. & std_pred_gpa_m_all==. & std_pred_gpa_c_ie_y ==. & std_pred_gpa_c_all==.
	keep id_per_umc id_ie grade year *pred_*
		
	save "$TEMP\standardized_gpa_school${data}${data_siagie}", replace
	
	use "$TEMP\standardized_gpa_school${data}${data_siagie}", clear
	
	keep id_per_umc year std_pred_gpa_?_all std_pred_gpa_?_ie_y 
	reshape wide std_pred_gpa_?_all std_pred_gpa_?_ie_y, i(id_per_umc) j(year)
	
	rename std_pred_gpa_?_all* std_pred_gpa_?_all_*
	rename std_pred_gpa_?_ie_y* std_pred_gpa_?_ie_y_*
	
	merge 1:1 id_per_umc using "$TEMP\siagie_yearvars${data}${data_siagie}", keep(master match) nogen
	
	keep 	id_per_umc  grade_???? approved_???? approved_first_???? /*math_secondary_????*/ std_gpa_?_???? std_pred_gpa_?_ie_y_???? 
	order 	id_per_umc  grade_???? approved_???? approved_first_???? /*math_secondary_????*/ std_gpa_?_???? std_pred_gpa_?_ie_y_???? 
	//capture drop math_secondary_2023 comm_secondary_2023
	//capture drop std_gpa_m_2023 std_gpa_c_2023
	compress
	save "$TEMP\standardized_gpa_school_yearvars${data}${data_siagie}", replace

	
	*- 3. Standardized uni GPA
	/*
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		//append using "$TEMP\siagie_`y'${data_siagie}", keep(id_ie id_per_umc year grade std_gpa_m std_gpa_c)
	}
	
	*- Get standardized measure
	merge m:1 id_per_umc using "$TEMP\ece_id_per_umc", keepusing(score*std_?? year_??) keep(master match) nogen
	
	*- Regression with full sample (one slope)
	egen cell = group(id_ie year grade)
	reghdfe score_math_std_2s std_gpa_m, a(cell) resid
	predict predict_gpa_m, xbd 
	label var predict_gpa_m "Predicted National GPA - Mathematics"
	rename predict_gpa_m temp
	VarStandardiz temp, newvar(predict_gpa_m)
	
	keep id_per_umc id_ie year grade predict_gpa_m
	
	save "$TEMP\standardized_gpa_school", replace
	*/
	*- 4. Standardized uni applications
	/*
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		//append using "$TEMP\siagie_`y'${data_siagie}", keep(id_ie id_per_umc year grade std_gpa_m std_gpa_c)
	}
	
	*- Get standardized measure
	merge m:1 id_per_umc using "$TEMP\ece_id_per_umc", keepusing(score*std_?? year_??) keep(master match) nogen
	
	*- Regression with full sample (one slope)
	
	egen cell = group(id_ie year grade)
	reghdfe score_math_std_2s std_gpa_m, a(cell) resid
	predict predict_gpa_m, xbd 
	label var predict_gpa_m "Predicted National GPA - Mathematics"
	rename predict_gpa_m temp
	VarStandardiz temp, newvar(predict_gpa_m)
	
	keep id_per_umc id_ie year grade predict_gpa_m
	
	save "$TEMP\standardized_gpa_school", replace
	*/
end

********************************************************************************
* School average data
********************************************************************************

capture program drop average_data_school
program define average_data_school 

	*- 2. School averages
	use "$OUT\students", clear

	drop if id_ie_sec==""

	//We use 'cohort' year for better reference
	keep if exp_graduating_year2>=2016 & exp_graduating_year2<=2024
	gen pop=1

	preserve
		collapse (mean) sec_grad applied admitted enrolled applied_public enrolled_public applied_private enrolled_private (sum) enrollment = pop, by(id_ie_sec exp_graduating_year2)
		format %9.2f sec_grad applied admitted enrolled applied_public enrolled_public applied_private enrolled_private
		rename (sec_grad applied admitted enrolled applied_public enrolled_public applied_private enrolled_private enrollment) (schy_sec_grad schy_applied schy_admitted schy_enrolled schy_applied_public schy_enrolled_public schy_applied_private schy_enrolled_private schy_enrollment)
		compress
		save "$TEMP\school_year_average", replace
	restore
		
	preserve
		bys id_ie_sec exp_graduating_year2: gen enrollment=_N
		collapse (mean) sec_grad applied admitted enrolled applied_public enrolled_public applied_private enrolled_private enrollment = pop, by(id_ie_sec)
		format %9.2f sec_grad applied admitted enrolled applied_public enrolled_public applied_private enrolled_private
		rename (sec_grad applied admitted enrolled applied_public enrolled_public applied_private enrolled_private enrollment) (sch_sec_grad sch_applied sch_admitted sch_enrolled sch_applied_public sch_enrolled_public sch_applied_private sch_enrolled_private sch_enrollment)
		compress
		save "$TEMP\school_average", replace
	restore	

end



********************************************************************************
* Application cutoff averages
********************************************************************************

capture program drop application_averages
program define application_averages


	use "$TEMP\applied", clear

	keep id_per_umc semester codigo_modular id_cutoff_deprt* id_cutoff_major*
	
	*-- Exam
	merge m:1 id_per_umc using "$OUT\students", keepusing(score_math_std_?? score_com_std_?? score_acad_std_??) keep(master match) nogen 

	foreach v of var score_*_std_?? {
		bys id_cutoff_major: 			egen `v'_avg_major 		= mean(`v')
		bys id_cutoff_deprt: 			egen `v'_avg_dep 		= mean(`v')
		bys id_cutoff_major_full:		egen `v'_avg_major_full = mean(`v')
		bys id_cutoff_deprt_full: 		egen `v'_avg_dep_full 	= mean(`v')
		
		bys codigo_modular semester	: 	egen `v'_avg_uni 		= mean(`v')
	}
	
	save "$OUT\application_averages", replace
	
	
end




********************************************************************************
* Application score per school-cohort: For peers FE
********************************************************************************

capture program drop peer_application
program define peer_application

args /*type*/ cell

	//local cell major
	//local type noz
	
	use "$TEMP\applied", clear
	
	*- Attach if enrolled in target college-semester
	merge m:1 id_per_umc codigo_modular semester using "$TEMP\enrolled_students_university_semester", keepusing(id_per_umc) keep(master match) 
	gen enrolled = (_m==3) if inlist(_m,1,3)
	drop _m
	
	*- Attach cutoff information (department)
	merge m:1 id_cutoff_`cell' using  "$TEMP/applied_cutoffs_`cell'.dta", keep(master match) keepusing(cutoff_rank_`cell' cutoff_std_`cell')
	gen lottery_nocutoff_`cell' = (cutoff_std_`cell'==.)
	drop _merge
	
	
	rename *_`cell' *
	//rename *_`type' * 
	
	keep id_per_umc semester codigo_modular id_cutoff public score_raw score_std rank_score_raw cutoff_std cutoff_rank admitted enrolled
	
	*- Attach school data
	merge m:1 id_per_umc using "$OUT\students", keepusing(id_ie_sec year_grad_school) keep(master match)   //exp_graduating_year1 exp_graduating_year2 year_grad_school
	drop if id_ie_sec==""

	*- Score relative
	gen score_relative = score_std - cutoff_std
	gen rank_relative =  rank_score_raw - cutoff_rank
	gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=. //To avoid float issues around 0, we use the precisely integer rank scores.	
	drop if score_relative==.	
	
	*- Consider first applications:
	bys id_per_umc (semester): keep if semester==semester[1]
	
	*- Max relative score among school-cohort
	bys id_ie_sec year_grad_school: egen max_score_relative=max(cond(public==1,score_relative,.))
	bys id_ie_sec year_grad_school: egen max_rank_relative=max(cond(public==1,rank_relative,.))
	bys id_ie_sec year_grad_school: egen max_ABOVE=max(cond(public==1,ABOVE,.))
	
	*- Admission and application outcomes
	bys id_ie_sec year_grad_school: egen total_applicants=sum(cond(score_std!=.,1,0))
	bys id_ie_sec year_grad_school: egen has_admitted=max(cond(admitted==1,1,0))
	bys id_ie_sec year_grad_school: egen has_admitted_public=max(cond(admitted==1 & public==1,1,0))
	bys id_ie_sec year_grad_school: egen total_admitted			=sum(cond(admitted==1,1,0))
	bys id_ie_sec year_grad_school: egen total_admitted_public		=sum(cond(admitted==1 & public==1,1,0))
	bys id_ie_sec year_grad_school: egen total_enrolled			=sum(cond(enrolled==1,1,0))
	bys id_ie_sec year_grad_school: egen total_enrolled_public		=sum(cond(enrolled==1 & public==1,1,0))
	
	bys id_ie_sec year_grad_school: gen n=_n==1

	
	*- Run the RD regression
	keep if n==1
	keep 	id_ie_sec year_grad_school ///
			max_score_relative max_rank_relative max_ABOVE ///
			total_applicants has_admitted has_admitted_public total_admitted total_admitted_public total_enrolled total_enrolled_public
	
	save "$OUT\applications_school_cohort_`cell'", replace	
		
end

***************************
*- Likelihood of enrolling ever if rejected
***************************


*- We keep most relevant data
capture program drop likelihood_enroll_reject
program define likelihood_enroll_reject 

args cell

	//local cell major
	use "$TEMP\applied.dta", clear

	keep codigo_modular major_c1_inei_code id_per_umc id_cutoff_`cell' score_std_`cell' rank_score_raw_`cell' public

	//Attach cutoffs, get those marginally rejected
	merge m:1 id_cutoff_`cell' using  "$TEMP/applied_cutoffs_`cell'.dta", keep(master match) keepusing(cutoff_rank_`cell' cutoff_std_`cell' R2_`cell' N_below_`cell' N_above_`cell')
	gen lottery_nocutoff_`cell' = (cutoff_std_`cell'==.)
	drop _merge

	sum  /*avg_applied* avg_enroll**/ 

	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(/*School*/ 		region_siagie public_siagie urban_siagie /*avg_applied* avg_enroll**/ min_dist_uni min_dist_uni_public min_dist_uni_private ///
																 /*Demog*/ 			male_siagie educ_mother educ_father socioec_index_*  ///
																 /*Academic*/		score_math_std_?? score_com_std_?? ///
																 /*Progression*/	 ///
																 /*Aspiration*/		 aspiration_?? ///
																 /*University*/		enrolled enrolled_private ///
																 )


	
	bys id_per_umc: gen 	one_app = _N==1
	bys id_per_umc: egen 	priv_app = max(cond(public==0,1,0))
	gen no_priv = priv_app==0
	

	gen score_relative = score_std_`cell' - cutoff_std_`cell'
	drop if score_relative==.

	gen sample = 0
	replace sample = 1 

	gen sample_b = 0 //below
	replace sample_b = 1 if rank_score_raw_`cell'<cutoff_rank_`cell'

	gen sample_b5 = 0
	replace sample_b5 = 1 if rank_score_raw_`cell'<cutoff_rank_`cell' & score_relative>-0.5

	gen sample_b2 = 0
	replace sample_b2 = 1 if rank_score_raw_`cell'<cutoff_rank_`cell' & score_relative>-0.2
	
	
	//binsreg enrolled score_relative if public==1 & abs(score_relative)<2


	//binsreg enrolled score_relative if public==1 & abs(score_relative)<4
	//binsreg one_app score_relative if public==1 & abs(score_relative)<4
	//binsreg no_pri_app score_relative if public==1 & abs(score_relative)<4
	
	
	tab enrolled if one_app==1 & sample_b==1 & public==1
	//How are they enrolled if 'not admitted' and 'didn't reapplied'?
	preserve
		keep if one_app==1 & sample_b==1 & enrolled==1 & public==1
		keep id_per_umc
		tempfile one_app_rej_enrolled
		save `one_app_rej_enrolled', replace
		
		use "$TEMP\enrolled.dta", clear	
		tab semester_admitted if inlist(id_per_umc,607432,615680,617446,617797,619018,619381)==1
	restore
	
	
	tab enrolled if one_app==1 & sample_b==1
	//How are they enrolled if 'not admitted' and 'didn't reapplied'?	
	
	rename enrolled enr
	rename one_app one
	rename no_priv npr
	
	foreach out in "enr" "one" "npr" {
		foreach sample in "" "_b" "_b5" "_b2" {	
			count
			local N`sample' = r(N)

			global covar1 "male_siagie i.educ_mother i.region_siagie i.urban_siagie i.public_siagie min_dist_uni"
			logit `out' ${covar1} if sample`sample'==1			
			local s1`sample' =  e(N) 
			predict rej_`out'`sample'_lpred1

			global covar2 "score_math_std_2p score_com_std_2p"
			logit `out' ${covar1} ${covar2} if sample`sample'==1		
			local s2`sample' =  e(N) 
			predict rej_`out'`sample'_lpred2

			global covar3 "score_math_std_2s score_com_std_2s socioec_index_2s"
			logit `out' ${covar1} ${covar3} if sample`sample'==1			
			local s3`sample' =  e(N) 
			predict rej_`out'`sample'_lpred3

			di as text  _n "Sample 1:" %9.1f `s1`sample''*100/`N`sample'' ///
						_n "Sample 2:" %9.1f `s2`sample''*100/`N`sample'' ///
						_n "Sample 3:" %9.1f `s3`sample''*100/`N`sample''
				
			//Set median cutoffs
			sum	rej_`out'`sample'_lpred1, de
			gen rej_`out'`sample'_lpred1_above = (rej_`out'`sample'_lpred1>r(p50) & rej_`out'`sample'_lpred1!=.)
			sum	rej_`out'`sample'_lpred2, de
			gen rej_`out'`sample'_lpred2_above = (rej_`out'`sample'_lpred2>r(p50) & rej_`out'`sample'_lpred2!=.)
			sum	rej_`out'`sample'_lpred3, de
			gen rej_`out'`sample'_lpred3_above = (rej_`out'`sample'_lpred3>r(p50) & rej_`out'`sample'_lpred3!=.)

		}
		
	}
	compress

	keep id_per_umc rej_*_*_lpred? rej_*_*_lpred?_above
	
	bys id_per_umc: keep if _n==1 //Based on demographics unrelated to application
	
	//Likelihood that if rejected they will be eventually enrolled in a 4-year college.		
	save "$TEMP\likelihood_rej_enr${data}", replace
end

********************************************************************************
* Final database: Application level
********************************************************************************

*- We keep most relevant data
capture program drop application_final
program define application_final 

	args fam_type 
	global fam_type = `fam_type'
	

timer clear 39
timer on 39
*- Likelihood of enrolling or not if rejected:
if ${run_predicted_enroll_rej} == 1 likelihood_enroll_reject major
timer off 39
	
	
timer clear 40
timer on 40	

	use "$TEMP\applied", clear
	
	if ${test_A04}==1 merge m:1 id_per_umc using "$OUT\students${data}${data_siagie}", keepusing(id_per_umc) keep(match) nogen 

	
	bys id_per_umc: egen sample =max(cond(_n==1,runiform()<0.01,.))
	
	keep if id_per_umc != .

	capture drop university academic dob
	capture drop id_codigo_facultad id_carrera_primera_opcion
	
	rename year year_applied_foc
	rename region region_foc
	rename public public_foc
	
timer off 40

timer clear 41
timer on 41

	**************
	*- Focal child outcomes
	**************	
	
	*- Family and IDs
		*- Match Family info
	merge m:1 id_per_umc using "$TEMP\id_siblings", keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}) keep(master match)
	rename _m m_app_siagie
	/*
	merge m:1 id_per_umc using "$OUT\students", keepusing(id_fam_4 fam_order_4 fam_total_4) keep(master match)
	rename _merge m_app_siagie
	*/	
	*- Focal Child variables
	preserve
		use "$OUT\students${data}${data_siagie}", clear
		isvar 	/*School characteristics*/ 		id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_??? avg_applied* avg_enroll* ///
				/*Demographic*/  				male_siagie exp_graduating_year? socioec_index_* *_lpred? last_year last_grade	///		
				/*School progression*/ 			dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? std_gpa_?_???? /*change_ie_????*/ std_pred_gpa_?_ie_y_???? std_pred_gpa_?_all_???? pri_grad sec_grad year_grad_school ///
				/*ECE score*/  					score_math_std_?? score_com_std_?? score_acad_std_?? year_??	///
				/*Survey*/  					aspiration_?? asp_college?_?? std_belief_gender*_?? gender_miss_4p	///
				/*University (application)*/  	/*year_app applied year_app_public applied_public*/ dob_app	///
				/*University (enrollment)*/  	dob_enr score_std_uni_enr	///
				/*University Persistence*/		/*enrolled_?year n_credits_?year*/ ///
				/*Peer Outcomes*/  				peer_score_*_std_?? peer_graduated_uni_ever peer_graduated_uni_5 peer_graduated_uni_6
		local all_vars = r(varlist)		
	restore
	
	merge m:1 id_per_umc using "$OUT\students${data}${data_siagie}", keep(master match) nogen keepusing(`all_vars') 
																										
	foreach v of var `all_vars' { 	
		rename `v' `v'_foc
		}
		
timer off 41



timer clear 42
timer on 42

	preserve
		use "$TEMP\student_umc_uni", clear
		isvar 	applied_public year_applied_public 	///
				applied_private year_applied_private 	///
				applied_public_tot  	///
				///applied year_applied 	///
				admitted year_admitted 	///
				///applied_stem year_applied_stem 	///
				///applied_nstem year_applied_nstem 	///
				N_applications N_applications_first 	///
				enrolled_public year_enrolled_public 	///
				enrolled_private year_enrolled_private 	///
				enrolled_public_tot 	///
				enrolled year_enrolled 	///
				///enrolled_stem year_enrolled_stem 	///
				///enrolled_nstem year_enrolled_nstem 	///
				score_std_f_uni_enr ///
				enrolled_?year n_credits_?year ///
				graduated_public year_graduated_public 	///	
				graduated_private year_graduated_private 	///
				graduated year_graduated 	///
				year_graduated_f_uni graduated_f_uni_ever graduated_f_uni_5 graduated_f_uni_6 score_std_f_uni_grad years_to_grad_f_uni	
		local all_vars = r(varlist)		
	restore

	*- University variables (application, enrollment, graduation, persistence, peers)
	merge m:1 id_per_umc using "$TEMP\student_umc_uni", keep(master match) nogen keepusing(`all_vars') 
																										
	foreach v of var `all_vars' { 	
		rename `v' `v'_foc
		}	
	
	*- Applied to other public ever
	gen applied_public_o_foc = 0 
	replace applied_public_o_foc = 1 if public_foc == 0 & applied_public_tot_foc>=1 & applied_public_tot_foc!=.
	replace applied_public_o_foc = 1 if public_foc == 1 & applied_public_tot_foc>=2 & applied_public_tot_foc!=.
	
	*- Enrolled in other public ever
	gen enrolled_public_o_foc = 0 
	replace enrolled_public_o_foc = 1 if public_foc == 0 & enrolled_public_tot_foc>=1 & enrolled_public_tot_foc!=.
	replace enrolled_public_o_foc = 1 if public_foc == 1 & enrolled_public_tot_foc>=2 & enrolled_public_tot_foc!=.
		
timer off 42


timer clear 43
timer on 43		
	
	
	
	*-- Likelihood of enrolled if reject: For counterfactual
	merge m:1 id_per_umc using  "$TEMP\likelihood_rej_enr${data}", keepusing(rej_enr_b2_lpred? rej_enr_b2_lpred?_above rej_npr_b2_lpred? rej_npr_b2_lpred?_above rej_one_b2_lpred? rej_one_b2_lpred?_above) keep(master match) nogen
	rename (rej_enr* rej_npr* rej_one*) (rej_enr*_foc rej_npr*_foc rej_one*_foc)
	
		
	
	*- Exams focal child during school
	/*
	merge m:1 id_per_umc using "$OUT\students", keepusing(aspiration_?? asp_college?_?? score_math_std_?? score_com_std_?? year_?? exp_graduating_year1 socioec_index_?? socioec_index_cat_?? dob_app dob_enr score_std_uni_enr) keep(master match) nogen //same merge as before, so use same 'm_app_siagie'
	rename (aspiration_?? asp_college?_?? score_math_std_?? score_com_std_?? year_?? exp_graduating_year1 socioec_index_?? socioec_index_cat_?? dob_app dob_enr score_std_uni_enr) (aspiration_??_foc asp_college?_??_foc score_math_std_??_foc score_com_std_??_foc year_??_foc exp_graduating_year1_foc socioec_index_??_foc socioec_index_cat_??_foc dob_app_foc dob_enr_foc score_std_uni_enr_foc) 
	*/
	*- Application outcomes:
	
		//Same semester			
		*- # of applications each semester
		merge m:1 id_per_umc semester using "$TEMP\total_applications_student-semester", keepusing(N_applications_semester) keep(master match)  	
		assert _m==3 //based on same data so should be everyone
		rename (N_applications_semester) (N_applications_semester_foc)	
		drop _m
		
		*- Applied to public semester
		merge m:1 id_per_umc semester using "$TEMP\applied_students_public_semester", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (applied_public_sem_foc year_applied_public_sem_foc)			
			
		*- Applied to private semester
		merge m:1 id_per_umc semester  using "$TEMP\applied_students_private_semester", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (applied_private_sem_foc year_applied_private_sem_foc)		
		
		
		label var applied_public_sem_foc 	"Applied in public university in applied semester"
		label var applied_private_sem_foc 	"Applied in private university in applied semester"
	
		label var applied_public_foc 		"Applied in public university ever"
		label var applied_private_foc 		"Applied in private university ever"
		
		label var applied_public_tot_foc "Number of public schools applied (focal)"
		
		
		*- # of admissions/offers each semester
		merge m:1 id_per_umc semester using "$TEMP\total_admissions_student-semester", keepusing(N_admissions_semester) keep(master match)  	
		assert _m==3 //
		rename (N_admissions_semester) (N_admissions_semester_foc)	
		drop _m
timer off 43



timer clear 44
timer on 44		
		
*- Enrollment outcomes:
	label define yes_no 0 "No" 1 "Yes", replace
	clonevar major_inei_code = major_c1_inei_code
	
		//Same semester
		*- Enrolled in same uni-major 	semester
		merge m:1 id_per_umc codigo_modular /*facultad*/ major_inei_code semester using "$TEMP\enrolled_students_university_major_semester", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (enrolled_uni_major_sem_foc year_enr_uni_major_sem_foc)
	
		*- Enrolled in same uni 		semester
		merge m:1 id_per_umc codigo_modular semester using "$TEMP\enrolled_students_university_semester", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (enrolled_uni_sem_foc year_enr_uni_sem_foc)		
			
		*- Enrolled in same major 		semester
		merge m:1 id_per_umc major_inei_code semester using "$TEMP\enrolled_students_major_semester", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (enrolled_major_sem_foc year_enr_major_sem_foc)		
		
		*- Enrolled in public 			semester
		merge m:1 id_per_umc semester using "$TEMP\enrolled_students_public_semester", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (enrolled_public_sem_foc year_enr_public_sem_foc)		
		
		*- Enrolled in private 			semester
		merge m:1 id_per_umc semester  using "$TEMP\enrolled_students_private_semester", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (enrolled_private_sem_foc year_enr_private_sem_foc)		
		
		*- Enrolled 					semester
		merge m:1 id_per_umc semester using "$TEMP\enrolled_students_semester", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (enrolled_sem_foc year_enr_sem_foc)	
		
		
		//Ever
		*- Enrolled in same uni-major 	ever
		merge m:1 id_per_umc codigo_modular /*facultad*/ major_inei_code  using "$TEMP\enrolled_students_university_major", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (enrolled_uni_major_foc year_enr_uni_major_foc)		
		
		*- Enrolled in same uni 		ever
		merge m:1 id_per_umc codigo_modular using "$TEMP\enrolled_students_university", keepusing(year) keep(master match)  
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (enrolled_uni_foc year_enr_uni_foc)		
		
		*- Enrolled in same major 		ever
		merge m:1 id_per_umc major_inei_code using "$TEMP\enrolled_students_major", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (enrolled_major_foc year_enr_major_foc)		
	
	
timer off 44



timer clear 45
timer on 45
		
		drop major_inei_code
	
		label values enroll*foc yes_no
	
		label var enrolled_uni_major_sem_foc "Enrolled in same university-major in applied semester"
		label var enrolled_uni_sem_foc 		"Enrolled in same university in applied semester"
		label var enrolled_major_sem_foc 	"Enrolled in same major in applied semester"
		label var enrolled_public_sem_foc 	"Enrolled in public university in applied semester"
		label var enrolled_private_sem_foc 	"Enrolled in private university in applied semester"
		label var enrolled_sem_foc 			"Enrolled in applied semester"
		
		label var enrolled_uni_major_foc 	"Enrolled in same university-major ever"
		label var enrolled_uni_foc 			"Enrolled in same university ever"
		label var enrolled_major_foc 			"Enrolled in same major ever"
		label var enrolled_public_foc 		"Enrolled in public university ever"
		label var enrolled_private_foc 		"Enrolled in private university ever"
		label var enrolled_foc 				"Enrolled ever"	
		
		label var enrolled_public_tot_foc "Number of public schools enrolled (focal)"
		
		
*- Persistence outcomes
/*
	merge m:1 id_per_umc using "$TEMP\persistence", keep(master match) keepusing(enrolled_?year n_credits_?year)
	recode _m (1 = 0) (3 = 1)
	drop _m
	rename (enrolled_?year n_credits_?year) (enrolled_?year_foc n_credits_?year_foc)
*/
	
*- Graduation Outcomes
	*- Graduation outcomes
	merge m:1 id_per_umc codigo_modular using "$TEMP\graduated_students_university", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (graduated_uni_foc year_graduated_uni_foc)	

	//assert test_year_grad_uni_foc == year_grad_uni_foc //won't be equal but would like to understand difference.
	
	
	label var graduated_uni_foc 		"Graduated in same university ever (focal child)"
	label var graduated_public_foc 		"Graduated in public university ever (focal child)"
	label var graduated_private_foc 	"Graduated in private university ever (focal child)"
	label var graduated_foc 			"Graduated in other public university ever (focal child)"		
	label var years_to_grad_f_uni_foc 	"Years to graduate from university (focal)"
	label var graduated_f_uni_ever_foc 	"Graduated in same university ever (focal child)"
	label var graduated_f_uni_5_foc 	"Graduated in same university within 5 years (focal child)"
	label var graduated_f_uni_6_foc 	"Graduated in same university within 6 years (focal child)"
	label var score_std_f_uni_grad_foc	"Graduation uni GPA"
					
	//Renaming some focal child variables	
	rename (male semester) (male_foc semester_foc)	
	
	
	**## We consider up to families of 7
	//keep if m_app_siagie == 3
	keep if inlist(fam_total_${fam_type},2,3,4,5,6,7)==1	
	
timer off 45



timer clear 46
timer on 46
	
	
	**************
	*- Sibling outcomes
	**************		
	
	*- We now make the database application-sibling, so we have information for each sibling. In case there are no matches we keep only one.	
	
	sort id_periodo_postulacion id_cutoff_major id_persona_rec //Not unique perhaps because modalidad-ingreso
	gen id_application = _n
	//keep id_application id_fam_4 fam_order_4 year *_foc
	
	**##
	
	*- We are considering up to next 5 siblings 
	expand 10
	
	*- We create the matching variable for each sibling
	rename fam_order_${fam_type} aux_fam_order_${fam_type}
	rename (id_per_umc year_applied_foc) (aux_id_per_umc aux_year)
	
	clonevar fam_order_${fam_type} = aux_fam_order_${fam_type}
	sort id_application id_fam_${fam_type} fam_order_${fam_type}
	bys id_application: replace fam_order_${fam_type} = fam_order_${fam_type} + _n-5 			//5 above and 5 below
	bys id_application: replace fam_order_${fam_type} = fam_order_${fam_type} - 1 if  fam_order_${fam_type}<= aux_fam_order_${fam_type} //we correct since those 5 below are starting from current
	drop if fam_order_${fam_type} > fam_total_${fam_type} //No need to look for siblings beyond the maximum size
	drop if fam_order_${fam_type} < 1 //Only start with first sibling
	
	sort id_application id_fam_${fam_type} fam_order_${fam_type}
	//drop if fam_order_${fam_type} > fam_total_${fam_type} //No need to look for siblings beyond the maximum size
	
	*- School outcomes
	merge m:1 id_fam_${fam_type} fam_order_${fam_type} using "$OUT\students${data}${data_siagie}", keepusing(id_per_umc) keep(master match) 
	rename _m m_sibling_siagie
	//keep if m_sibling_siagie == 3 //Only keep those who match a younger sibling
	
	*- If no matches just keep 1. Otherwise, keeps siblings who match. This for overall statistics at the application level so that it includes focal child without siblings (all applicants essentially), also makes database smaller.
	bys id_application: egen any_sib_match = max(cond(m_sibling_siagie==3,1,0))
	bysort id_application (fam_order_${fam_type}): keep if (_n==1 & any_sib_match==0) | m_sibling_siagie==3
	//Someone who doesn't match a sibling is because (i) has no siblings or (ii) is the youngest. Given that we have restricted for families -with- siblings, (i) may be already out. So mainly keeping the youngest siblings here.	
	
	//close 
	
timer off 46



timer clear 47
timer on 47	


	*- Sibling variables
	preserve
		use "$OUT\students${data}${data_siagie}", clear
		isvar 	/*School characteristics*/ 		id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_??? avg_applied* avg_enroll* ///
				/*Demographic*/  				male_siagie exp_graduating_year? socioec_index_* *_lpred? last_year last_grade grade_???? ///		
				/*School progression*/ 			dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? std_gpa_?_???? change_ie_????  std_pred_gpa_?_ie_y_???? std_pred_gpa_?_all_????  pri_grad sec_grad year_grad_school ///
				/*ECE score*/  					score_math_std_?? score_com_std_?? score_acad_std_?? year_??	///
				/*Survey*/  					aspiration_?? asp_college?_?? std_belief_gender*_?? gender_miss_4p	///
				/*University (application)*/  	/*year_app applied year_app_public applied_public*/ dob_app	///
				/*University (enrollment)*/  	dob_enr score_std_uni_enr	///
				/*University Persistence*/		/*enrolled_?year n_credits_?year*/ ///
				/*Peer Outcomes*/  				peer_score_*_std_?? peer_graduated_uni_ever peer_graduated_uni_5 peer_graduated_uni_6
				/**/  ///
		local all_vars = r(varlist)		
	restore
	
	merge m:1 id_per_umc using "$OUT\students${data}${data_siagie}", keep(master match) nogen keepusing(`all_vars') 
																										
	foreach v of var `all_vars' { 	
		rename `v' `v'_sib
		}	
*- University variables (application, enrollment, graduation, peers)

	preserve
		use "$TEMP\student_umc_uni", clear
		isvar 	applied_public year_applied_public 	///
				applied_private year_applied_private 	///
				applied_public_tot  	///
				applied year_applied 	///
				admitted year_admitted 	///
				applied_stem year_applied_stem 	///
				applied_nstem year_applied_nstem 	///
				N_applications N_applications_first 	///
				enrolled_public year_enrolled_public 	///
				enrolled_private year_enrolled_private 	///
				enrolled_public_tot 	///
				enrolled year_enrolled 	///
				enrolled_stem year_enrolled_stem 	///
				enrolled_nstem year_enrolled_nstem 	///
				score_std_f_uni_enr ///
				enrolled_?year n_credits_?year /// a
				graduated_public year_graduated_public 	///	
				graduated_private year_graduated_private 	///
				graduated year_graduated 	///
				year_graduated_f_uni graduated_f_uni_ever graduated_f_uni_5 graduated_f_uni_6 score_std_f_uni_grad years_to_grad_f_uni	
		local all_vars = r(varlist)		
	restore
	
	//drop `all_vars'

	*- University variables (application, enrollment, graduation, peers)
	merge m:1 id_per_umc using "$TEMP\student_umc_uni", keep(master match) nogen keepusing(`all_vars') 
																										
	foreach v of var `all_vars' { 	
		rename `v' `v'_sib
		}	

											
timer off 47


timer clear 48
timer on 48														
														
	*- Application outcomes
	merge m:1 id_per_umc codigo_modular /*facultad*/ major_c1_inei_code using "$TEMP\applied_students_university_major", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_uni_major_sib year_applied_uni_major_sib)
	
	merge m:1 id_per_umc codigo_modular using "$TEMP\applied_students_university", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_uni_sib year_applied_uni_sib)
	
	merge m:1 id_per_umc major_c1_inei_code using "$TEMP\applied_students_major", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_major_sib year_applied_major_sib)
	
	*- # of applications to target 
	merge m:1 id_per_umc codigo_modular using "$TEMP\total_applications_student-uni", keepusing(N_applications_uni) keep(master match)  	
	replace N_applications_uni = 0 if applied_uni_sib == 0 
	rename N_applications_uni N_applications_uni_sib
	drop _m		
	
	*- Enrollment outcomes
	clonevar major_inei_code = major_c1_inei_code
	
	merge m:1 id_per_umc codigo_modular /*facultad*/ major_inei_code using "$TEMP\enrolled_students_university_major", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_uni_major_sib year_enrolled_uni_major_sib)
	
	merge m:1 id_per_umc codigo_modular using "$TEMP\enrolled_students_university", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_uni_sib year_enrolled_uni_sib)
	
	merge m:1 id_per_umc major_inei_code using "$TEMP\enrolled_students_major", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_major_sib year_enrolled_major_sib)
															
	*- Applied to other public
	gen applied_public_o_sib = 0 
	replace applied_public_o_sib = 1 if public_foc == 0 & applied_public_tot_sib>=1 & applied_public_tot_sib!=. //If target is private and sibling has public then =1
	replace applied_public_o_sib = 1 if public_foc == 1 & applied_public_tot_sib>=2 & applied_public_tot_sib!=. //If target is public and sibling has 2+ then =1
	replace applied_public_o_sib = 1 if public_foc == 1 & applied_public_tot_sib==1 & applied_uni_sib==0  //If target is public and sibling only has one but has 	
	
	*- Enrolled in other public
	gen enrolled_public_o_sib = 0
	replace enrolled_public_o_sib = 1 if public_foc == 0 & enrolled_public_tot_sib>=1 & enrolled_public_tot_sib!=. //If target is private and sibling has public then =1
	replace enrolled_public_o_sib = 1 if public_foc == 1 & enrolled_public_tot_sib>=2 & enrolled_public_tot_sib!=. //If target is public and sibling has 2+ then =1
	replace enrolled_public_o_sib = 1 if public_foc == 1 & enrolled_public_tot_sib==1 & enrolled_uni_sib==0  //If target is public and sibling only has one but has p	
	
														
timer off 48


timer clear 49
timer on 49														
	
	
	*- Exam averages (considering first take per university) (suffix: u - first-university)
	merge m:1 id_per_umc using "$TEMP\application_info_first-uni_student", keepusing(score_std_*_all score_std_*_pub) keep(master match)
	rename (score_std_*_all score_std_*_pub) (score_std_*_all_u_sib score_std_*_pub_u_sib)
	drop _m
	merge m:1 id_per_umc codigo_modular using "$TEMP\application_info_first-uni_student-uni", keepusing(score_std_*_uni score_std_*_uni_o score_std_*_pub_o) keep(master match) 
	rename (score_std_*_uni score_std_*_uni_o score_std_*_pub_o) (score_std_*_uni_u_sib score_std_*_uni_o_u_sib score_std_*_pub_o_u_sib)
	foreach cutoff_level in "major" "deprt" "major_full" "deprt_full" {	
		replace score_std_`cutoff_level'_uni_o_u_sib = score_std_`cutoff_level'_all_u_sib if score_std_`cutoff_level'_uni_o_u_sib == . & _m==1 //For those that did not match 'target college' and hence had no value
		replace score_std_`cutoff_level'_pub_o_u_sib = score_std_`cutoff_level'_pub_u_sib if score_std_`cutoff_level'_pub_o_u_sib == . & _m==1
	}
	drop _m 
	
	foreach cutoff_level in "major" "deprt" "major_full" "deprt_full" {
		label var score_std_`cutoff_level'_all_u_sib 	"Average score of all universities 	- First semester-uni cosidered (sibling)"
		label var score_std_`cutoff_level'_pub_u_sib 	"Average score of public universities  - First semester-uni cosidered (sibling)"
		label var score_std_`cutoff_level'_uni_u_sib 	"Average score of target university - First semester-uni cosidered (sibling)"
		label var score_std_`cutoff_level'_uni_o_u_sib 	"Average score of other universities - First semester-uni cosidered (sibling)"
		label var score_std_`cutoff_level'_pub_o_u_sib	"Average score of other public universities - First semester-uni cosidered (sibling)"
	}
	
	*- Exam averages (considering first take ever) (suffix: f - first-ever)
	merge m:1 id_per_umc using "$TEMP\application_info_first_student", keepusing(score_std_*_all score_std_*_pub) keep(master match)
	rename (score_std_*_all score_std_*_pub) (score_std_*_all_f_sib score_std_*_pub_f_sib)
	drop _m
	merge m:1 id_per_umc codigo_modular using "$TEMP\application_info_first_student-uni", keepusing(score_std_*_uni score_std_*_uni_o score_std_*_pub_o) keep(master match) 
	rename (score_std_*_uni score_std_*_uni_o score_std_*_pub_o) (score_std_*_uni_f_sib score_std_*_uni_o_f_sib score_std_*_pub_o_f_sib)
	foreach cutoff_level in "major" "deprt" "major_full" "deprt_full" {	
		replace score_std_`cutoff_level'_uni_o_f_sib = score_std_`cutoff_level'_all_f_sib if score_std_`cutoff_level'_uni_o_f_sib==. & _m==1 //If they do not apply to target uni, then the average of all 'other' is the same as the average (and was otherwise not defined before at the student-uni level)
		replace score_std_`cutoff_level'_pub_o_f_sib = score_std_`cutoff_level'_pub_f_sib if score_std_`cutoff_level'_pub_o_f_sib==. & _m==1
	}
	drop _m 
	
	foreach cutoff_level in "major" "deprt" "major_full" "deprt_full" {
		label var score_std_`cutoff_level'_all_f_sib 	"Average score of all universities 	- First semester cosidered (sibling)"
		label var score_std_`cutoff_level'_pub_f_sib 	"Average score of public universities  - First semester cosidered (sibling)"
		label var score_std_`cutoff_level'_uni_f_sib 	"Average score of target university - First semester cosidered (sibling)"
		label var score_std_`cutoff_level'_pub_o_f_sib	"Average score of other public universities - First semester cosidered (sibling)"
		label var score_std_`cutoff_level'_uni_o_f_sib 	"Average score of other universities - First semester cosidered (sibling)"
	}	

	label values applied*sib yes_no

	label var applied_uni_major_sib 	"Applied in same university-major ever (sibling)"
	label var applied_uni_sib 			"Applied in same university ever (sibling)"
	label var applied_major_sib 		"Applied in same major ever (sibling)"
	label var applied_public_sib 		"Applied in public university ever (sibling)"
	label var applied_private_sib 		"Applied in private university ever (sibling)"
	label var applied_sib 				"Applied ever (sibling)"	
	
	//HAS TO BE ONE PER SIBLING. CAN WE HAVE ONE PER 'SIBLING' (for application), 'SIBLING-COLLEGE'/'SIBLING-MAJOR' for those outcome and 
	

	drop major_inei_code

	label values enroll*sib yes_no

	label var enrolled_uni_major_sib 		"Enrolled in same university-major ever (sibling)"
	label var enrolled_uni_sib 			"Enrolled in same university ever (sibling)"
	label var enrolled_major_sib 			"Enrolled in same major ever (sibling)"
	label var enrolled_public_sib 		"Enrolled in public university ever (sibling)"
	label var enrolled_private_sib 		"Enrolled in private university ever (sibling)"
	label var enrolled_public_o_sib 		"Enrolled in other public university ever (sibling)"
	label var enrolled_sib 				"Enrolled ever (sibling)"	
	
	*- Persistence outcomes
	/*
	merge m:1 id_per_umc using "$TEMP\persistence", keep(master match) keepusing(enrolled_?year n_credits_?year)
	recode _m (1 = 0) (3 = 1)
	drop _m
	rename (enrolled_?year n_credits_?year) (enrolled_?year_sib n_credits_?year_sib)
	*/
	
	*- Graduation outcomes
	merge m:1 id_per_umc codigo_modular using "$TEMP\graduated_students_university", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (graduated_uni_sib year_graduated_uni_sib)	
	
	//assert test_year_grad_uni_sib == year_grad_uni_sib //won't be equal but would like to understand difference.
	
	label var graduated_uni_sib 		"Graduated in same university ever (sibling)"
	label var graduated_public_sib 		"Graduated in public university ever (sibling)"
	label var graduated_private_sib 	"Graduated in private university ever (sibling)"
	label var graduated_sib 			"Graduated in other public university ever (sibling)"		
	label var years_to_grad_f_uni_sib 	"Years to graduate from university (focal)"
	label var graduated_f_uni_ever_sib 	"Graduated in same university ever (sibling)"
	label var graduated_f_uni_5_sib 	"Graduated in same university within 5 years (sibling)"
	label var graduated_f_uni_6_sib 	"Graduated in same university within 6 years (sibling)"
	label var score_std_f_uni_grad_sib	"Graduation uni GPA"

	//Rename variables to original
	rename id_per_umc id_per_umc_sib
	rename (aux_id_per_umc aux_year) (id_per_umc year_applied_foc)
	
	rename fam_order_${fam_type} fam_order_${fam_type}_sib
	rename aux_fam_order_${fam_type} fam_order_${fam_type}
	
	//rename semester semester_sib
	
	*- We assign missing values to those who don't actually have a sibling:
	foreach v of var *sib {
		capture replace `v' = . if any_sib_match==0
		capture replace `v' = "" if any_sib_match==0
	}
	
	*- If no matches just keep 1. This for overall statistics at the application level, also makes database smaller.
//	bys id_application: egen any_sib_match = max(m_sibling_siagie)
//	bysort id_application (fam_order_4_sib): keep if (_n==1 & any_sib_match==1) | m_sibling_siagie==3 
	//Someone who doesn't match a sibling is because (i) has no siblings or (ii) is the youngest. Given that we have restricted for families -with- siblings, (i) may be already out. So mainly keeping the youngest siblings here.
	
	
	//rename (aspiration_?? asp_college?_?? score_math_std_?? score_com_std_?? year_?? exp_graduating_year1 dob_app dob_enr score_std_uni_enr) (aspiration_??_sib asp_college?_??_sib score_math_std_??_sib score_com_std_??_sib year_??_sib exp_graduating_year1_sib dob_app_sib dob_enr_sib score_std_uni_enr_sib)	
timer off 49



timer clear 50
timer on 50	
		
	**************
	*-  Attaching school information
	**************
		
	*- Focal
	*- Sibling	
	clonevar id_ie_sec = id_ie_sec_foc
	clonevar exp_graduating_year2 = exp_graduating_year2_foc 
	replace exp_graduating_year2=-1 //Previous year rate
	
	/*
	merge m:1 id_ie_sec exp_graduating_year2 using "$TEMP\school_year_average", keep(master match)
	capture drop _m
	*/
	
	//### To simplify, let's use school average for now, although that has some endogeneity of considering outcome in their obs.
	merge m:1 id_ie_sec using "$TEMP\school_average", keep(master match)
	capture drop _m
	rename sch_* _sch_*_foc
	drop id_ie_sec exp_graduating_year2
		
	*- Sibling	
	clonevar id_ie_sec = id_ie_sec_sib 
	clonevar exp_graduating_year2 = exp_graduating_year2_sib 
	replace exp_graduating_year2=-1 //Previous year rate
	
	/*
	merge m:1 id_ie_sec exp_graduating_year2 using "$TEMP\school_year_average", keep(master match)
	capture drop _m
	*/
	
	//### To simplify, let's use school average for now, although that has some endogeneity of considering outcome in their obs.
	merge m:1 id_ie_sec using "$TEMP\school_average", keep(master match)
	capture drop _m
	rename sch_* sch_*_sib
	rename _sch_*_foc sch_*_foc
	drop id_ie_sec exp_graduating_year2
	
	
	**************
	*- Attaching cutoff information
	**************
	
	*- Attach cutoff information
	foreach cutoff_level in "major" "deprt" "major_full" "deprt_full" {
		merge m:1 id_cutoff_`cutoff_level' using  "$TEMP/applied_cutoffs_`cutoff_level'.dta", keep(master match) keepusing(cutoff_rank_`cutoff_level' cutoff_std_`cutoff_level' R2_`cutoff_level' N_below_`cutoff_level' N_above_`cutoff_level')
		gen lottery_nocutoff_`cutoff_level' = (cutoff_std_`cutoff_level'==.)
		drop _merge
	}
	
		
		
	*- Attach McCrary Tests (removing score=0) (major)
	foreach cutoff_level in "major" "deprt" "major_full" "deprt_full" {
		merge m:1 id_cutoff_`cutoff_level' using  "$TEMP/mccrary_cutoffs_noz_`cutoff_level'.dta", keep(master match) keepusing(mccrary_pv_def_noz_`cutoff_level' mccrary_pv_biasi_noz_`cutoff_level' mccrary_test_noz_`cutoff_level')
		drop _merge
	}	

		
	// We can later get info on 'N_above_* N_below_* R2_*' as needed for tests
		
	*- For testing graph purposes
	bys id_cutoff_major: gen n=_n==1	
	
	*- Label dummy variables
	foreach v of var applied_sib applied_public* applied_private* applied_uni* applied_major* applied_stem*  ///
					 enrolled_sib enrolled_public* enrolled_private* enrolled_uni* enrolled_major* enrolled_stem*  ///
					 enrolled_?year* n_credits_?year* ///
					 graduated_sib graduated_uni* graduated_public* graduated_private* {
	label values `v' yes_no
	}
	
isvar 			///
				/*Match ID*/ 	///
				/*UNIVERSITY APPLICATION*/ ///
					/*Characteristics*/ region_foc public_foc ///
					/*Demographics*/ dob age male_foc /// 
				/*UNIVERSITY ENROLLMENT*/ ///
				/*Family*/ 						///
					/*ID*/						id_fam_${fam_type} fam_order_${fam_type} fam_order_${fam_type}_sib  ///
					/*Demographics*/			fam_total_${fam_type} any_sib_match ///
				/**************/ ///
				/*Focal Child*/ ///
				/**************/ ///
					/*ID*/						id_per_umc id_persona_rec ///
					/*School*/ ///
						/*Characteristics*/  	id_ie_foc region_siagie*_foc public_siagie*_foc urban_siagie*_foc carac_siagie*_foc id_ie_???_foc ///
						/*Demographics*/		male_siagie*_foc *_lpred?_foc last_year_foc last_grade_foc ///
						/*Counterfactual*/		rej_enr*_foc rej_npr*_foc rej_one*_foc ///
						/*Progression*/			dropout*_foc approved_????_foc approved_first_????_foc  math_secondary_????_foc comm_secondary_????_foc std_gpa_?_????_foc change_ie_????_foc  std_pred_gpa_?_ie_y_????_foc std_pred_gpa_?_all_????_foc pri_grad_foc sec_grad_foc year_graduated_school_foc ///	
						/*Exams*/				year_??_foc score_math_std_??_foc score_com_std_??_foc score_acad_std_??_foc ///
						/*Survey*/				aspiration_??_foc asp_college?_??_foc std_belief_gender*_??_foc gender_miss_4p_foc  ///
						/*Other*/				sch_*_foc ///
					/*University*/ ///
						/*Application */ 		year_applied_foc semester_foc type_admission N_applications*foc N_admissions_semester_foc ///
						/*Admission */			admitted_foc year_admitted_foc ///
						/*Enrollment*/ 			year*enr*foc ///	
						/*Persistence*/			enrolled_?year_foc n_credits_?year_foc ///
						/*Graduation*/			year_graduated_foc grad*foc graduated_f_uni_ever_foc graduated_f_uni_5_foc graduated_f_uni_6_foc  score_std_uni_f_grad_foc ///enroll* nota_promedio public_any public_ever 
						/*Peers*/				peer_*_foc ///
						/*mccrary*/	 			mccrary* ///
						/*cutoff info*/ 		has_cutoff_deprt* cutoff_raw*_deprt* cutoff_std*_deprt* cutoff_rank*_deprt* has_cutoff*_major* cutoff_raw*_major* cutoff_std*_major* cutoff_rank*_major* lottery* N_above* N_below* R2_* ///
				/**************/ ///
				/*Sibling*/ ///
				/**************/ ///
					/*ID*/						id_per_umc_sib ///
					/*School*/ ///
						/*Characteristics*/ 	id_ie_sib region_siagie*_sib public_siagie*_sib urban_siagie*_sib carac_siagie*_sib id_ie_???_sib ///
						/*Demographics*/		male_siagie*_sib *_lpred?_sib last_year_sib last_grade_sib grade_????_sib ///
						/*Progression*/			dropout*_sib approved_????_sib approved_first_????_sib math_secondary_????_sib comm_secondary_????_sib std_gpa_?_????_sib change_ie_????_sib  std_pred_gpa_?_ie_y_????_sib std_pred_gpa_?_all_????_sib pri_grad_sib sec_grad_sib year_graduated_school_sib ///
						/*Exams*/			 	year_??_sib score_math_std_??_sib score_com_std_??_sib score_acad_std_??_sib ///
						/*Survey*/				aspiration_??_sib asp_college?_??_sib std_belief_gender*_??_sib gender_miss_4p_sib /// 
						/*Other*/				sch_*_sib ///
					/*University*/ ///	
						/*Application */ 		year*app*sib app*sib semester_sib N_applications*sib score_std_*_all*sib score_std_*_uni*sib score_std_*_pub*sib  ///
						/*Admission */			year_admitted_sib admitted_sib ///
						/*Enrollment*/ 			year*enr*sib enr*sib score_std_uni_enr_sib ///
						/*Persistence*/			enrolled_?year_sib n_credits_?year_sib ///
						/*Graduation*/			graduated_sib graduated_uni_sib graduated_public_sib graduated_private_sib graduated_f_uni_ever_sib graduated_f_uni_5_sib graduated_f_uni_6_sib  score_std_f_uni_grad_sib ///
						/*Peers*/				peer_*_sib ///
							///
							///
				/*************************/ ///
				/*Older version (arrange)*/ ///
				/*************************/ ///									
				/*SIBLINGS*/ ///
					/*SIAGIE*/					  ///
					/*APPLICATIONS DATA*/ 		codigo_modular periodo_postulacion /*facultad*/ ///id_per_pos /// 
					/*CUTOFFS*/ 				id_cutoff_deprt* id_cutoff_major* ///
					/*OTHER ID*/ 				 /// codigo_modular  /// id_codigo_facultad id_periodo_postulacion  
				/*CHOICES*/ 					major_c1_cat major_c1_cat3 major_c1_cat6  major_c1_inei_code  ///
				/*INSTITUTION*/					codigo_modular  public licensed academic	region	/// facultad university
				/*DEMOGRAPHIC*/	 				 educ_caretaker educ_mother educ_father socioec_index_*	///
				/*APPLICATION SCORE*/ 			score_raw score_std_deprt* score_std_major* rank_score_raw_deprt* rank_score_raw_major*	source issue		///
				/*APPLICATION RESULT*/ 			admitted major_admit_inei_code ///
				/*ECE OWN SCORE*/ 				///score_com*g? score_math*g?			///
				/*ECE CLASS SCORE*/				///score_com*g?_sch score_math*g?_sch		///
				/*CLASS COVARIATES*/ 			///male*g?_sch spanish*g?_sch	socioec_index*g?_sch		///
				/*CLASS OUTCOMES*/ 				///applied*sch enroll*sch		///
				/*ECE SIBLING SCORE*/			///
				/*Application INFO*/ 			applied*foc first_application* one_application*  ///enroll* nota_promedio public_any public_ever ///
				/*ENROLLMENT INFO*/ 			enroll*foc score_std_uni_enr_foc ///enroll* nota_promedio public_any public_ever ///
				/*Focal child siagie outcomes*/ exp_graduating_year?_foc  ///
				/*Sibling*/						///
				/*UNIVERSITY APPLICATION*/ ///
					/*Characteristics*/ /// region_sib public_sib /// ##?? Included
					/*Demographics*/ /// dob_sib  ///  age_sib male_sib
				/*sibling siagie outcomes*/ 	exp_graduating_year?_sib ///
				/*merge*/						
				/**/
				
				//
				
				local all_vars = r(varlist)
				ds `all_vars', not
				keep `all_vars'
				order `all_vars'

				foreach v of local all_vars {
					capture confirm string variable `v'
						if _rc==0 {
							   replace `v' = trim(itrim(`v'))
						}
				}
				
				*Destring those not IDs
				ds /*id_per_umc id_persona_rec*/ id_ie*, not //In newer version of SIRIES, IDs are numeric.
				local all_vars = r(varlist)
				destring `all_vars', replace
				
				*- Final renames for length
				rename enrolled_uni_major_sem_foc enr_uni_major_sem_foc
				//rename peer_graduated* peer_grad*
				compress
				
				
	
	save "$OUT/applied_outcomes_${fam_type}${data}${data_siagie}.dta", replace	
	timer off 50
	/*
	Reducing size tips:
	
	describe facultad codigo_modular semester_sib
	describe facultad codigo_modular semester_sib
	describe mccrary_pv_def_noz_department mccrary_pv_biasi_noz_department mccrary_pv_def_noz_major mccrary_pv_biasi_noz_major
	*/
	
	
end



********************************************************************************
* Run program
********************************************************************************

main

forvalues i = 1(1)100 {
	capture timer list `i'
	ret li
	capture local time_`i' = r(t`i')/60
}


forvalues i = 1(1)22 {
	di as text "section #`i' lasted " `time_`i''	
}


forvalues i = 39(1)50 {
	di as text "section #`i' lasted " `time_`i''
}
	
	
forvalues i = 91(1)95 {
	di as text "section #`i' lasted " `time_`i''
}	
	
clear

set obs 100
gen time = .
gen i = .

forvalues i = 1(1)100 {
	replace i = `i' in `i'
	replace time = `time_`i'' in `i'
}

drop if time==.

save "$TEMP\timer_${data}", replace