/********************************************************************************
- Author: Francisco Pardo
- Description: Create Final matched database
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/

capture program drop main 
program define main 

setup_A04

*- Final Student Database
student_final

*- Average data
average_data_school //


*- Final Student-sibling database
//student_sibling_final 2

//application_averages
peer_application major


*- Likelihood of enrolling or not if rejected:
likelihood_enroll_reject major

*- Final applications-sibling database
application_final 2


	
end





********************************************************************************
* Setup
********************************************************************************

capture program drop setup_A04
program define setup_A04
	
	global fam_type = 2
	global test_A04 = 1
	global run_predicted_uni = 1
	global run_predicted_rej = 1
	set seed 1234

	global test_size = "h" //"s" "m" "h"
	
	if ${test_A04} == 0 global data = ""
	if ${test_A04} == 1 global data = "_TEST${test_size}"

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
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		append using "$TEMP\siagie_`y'", keep(id_ie id_per_umc level grade year male_siagie region_siagie public_siagie urban_siagie carac_siagie approved approved_???? approved_first approved_first_???? section_siagie comm_secondary_???? math_secondary_???? std_gpa_m_???? std_gpa_c_???? change_ie_???? lat_ie lon_ie)
	}

timer off 1	

timer clear 2
timer on 2
	
	*- Encode section/class variable
	/*
	encode seccion_siagie, gen(section_siagie)
	drop seccion_siagie*
*/
timer off 2
	
timer clear 3
timer on 3	
//	destring id_per_umc, replace
	
timer off 3


timer clear 4
timer on 4
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
timer off 4


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

	isvar /*Relevant vars*/ id_ie id_per_umc id_ie_??? exp_entry_year exp_graduating_year1 exp_graduating_year2 male_siagie region_siagie public_siagie urban_siagie carac_siagie grade section_siagie year dropout* approved_???? approved_first_???? math_secondary_???? comm_secondary_???? std_gpa_m_???? std_gpa_c_???? change_ie_???? pri_grad sec_grad year_grad_school educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} lat_ie lon_ie
			
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'
	compress	
		
	
	rename (year grade section_siagie lat_ie lon_ie) (last_year last_grade last_section last_lat_ie last_lon_ie)
	
	compress
	
timer off 10	

timer clear 11
timer on 11
	
	save "$TEMP\siagie_ids", replace
	
	use "$TEMP\siagie_ids", clear
	

	
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
	/*
	*- Applied
	merge 1:1 id_per_umc using "$TEMP\applied_students", keep(master match) keepusing(year dob)
	recode _m (1 = 0) (3 = 1)
	rename (_m year dob) (applied year_app dob_app)
	
	*- Applied public
	merge 1:1 id_per_umc using "$TEMP\applied_students_public", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_public year_app_public)
	
	*- Applied public
	merge 1:1 id_per_umc using "$TEMP\applied_students_private", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_private year_app_private)
	

	
	*- Applied STEM
	merge 1:1 id_per_umc using "$TEMP\applied_stem_students", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_stem year_app_stem)
	
	*- Applied NOT IN STEM
	merge 1:1 id_per_umc using "$TEMP\applied_nstem_students", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_nstem year_app_nstem)		
	
	

	*- Admitted
	merge 1:1 id_per_umc using "$TEMP\admitted_students", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (admitted year_adm)

	*- Admitted public
	merge 1:1 id_per_umc using "$TEMP\admitted_students_public", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (admitted_public year_adm_public)

	*- Admitted private
	merge 1:1 id_per_umc using "$TEMP\admitted_students_private", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (admitted_private year_adm_private)
	
	
	
	*- Enrolled
	merge 1:1 id_per_umc using "$TEMP\enrolled_students", keep(master match) keepusing(year score_std_uni dob)
	recode _m (1 = 0) (3 = 1)
	rename (_m year dob score_std_uni) (enrolled year_enr dob_enr score_std_uni_enr)

	*- Enrolled public
	merge 1:1 id_per_umc using "$TEMP\enrolled_students_public", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_public year_enr_public)

	*- Enrolled private
	merge 1:1 id_per_umc using "$TEMP\enrolled_students_private", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_private year_enr_private)
	
	*- Enrolled STEM
	merge 1:1 id_per_umc using "$TEMP\enrolled_stem_students", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_stem year_enr_stem)
	
	*- Enrolled NOT IN STEM
	merge 1:1 id_per_umc using "$TEMP\enrolled_nstem_students", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_nstem year_enr_nstem)	
	
	*- Graduated
	merge 1:1 id_per_umc using "$TEMP\graduated_students", keep(master match) keepusing(year score_std_uni dob)
	recode _m (1 = 0) (3 = 1)
	rename (_m year dob score_std_uni) (graduated year_grad dob_grad score_std_uni_grad)

	*- Graduated public
	merge 1:1 id_per_umc using "$TEMP\graduated_students_public", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (graduated_public year_grad_public)

	*- Graduated private
	merge 1:1 id_per_umc using "$TEMP\graduated_students_private", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (graduated_private year_grad_private)
	
	label var graduated_public 			"Graduated in public university ever"
	label var graduated_private 		"Graduated in private university ever"
	label var graduated 				"Graduated in other public university ever"
	
	
	
	
	*- Peer outcomes
		
	*- ECE Scores and Grad rates
	merge 1:1 id_per_umc using "$TEMP\first_enrollment_outcomes",  keep(master match) keepusing(peer_*_std_?? peer_grad_* peer_socio*)  nogen	
	*/
	
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
	if ${run_predicted_uni} == 1 likelihood_predicted_uni
	merge 1:1 id_per_umc using "$TEMP\likelihood_predicted_uni${data}", keepusing(*lpred?) keep(master match) nogen
	
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
				/*Demographics*/ 		male_siagie educ_caretaker educ_mother educ_father exp_entry_year exp_graduating_year1  exp_graduating_year2 fam_order_? lives_with_* ///
				/*Last observation*/ 	last_grade last_section last_year last_lat_ie last_lon_ie ///
				/*Attainment*/			pri_grad sec_grad year_grad_school ///
				/*Progression*/			approved_???? approved_first_???? ///
				/*GPA*/					math_secondary_???? comm_secondary_???? std_gpa_m_???? std_gpa_c_???? ///
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
	save "$OUT\students${data}", replace
	
	//capture erase "$TEMP\siagie_ids.dta"
end


capture program drop likelihood_predicted_uni
program define likelihood_predicted_uni

*- Heterogeneity analysis: Likelihood of going to college
	// We include 3 measures, with more variables but less sample progressively.
	
	preserve
	
		global pred_out 	   	"applied admitted enrolled"
		global pred_ifs 		"exp_graduating_year1 exp_graduating_year2"
		global pred_covar1 	"male_siagie educ_mother region_siagie urban_siagie public_siagie"
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
		save "$TEMP\likelihood_predicted_uni${data}", replace
	restore
	


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
* Final database: Student-siblings level
********************************************************************************

*- We keep most relevant data
capture program drop student_sibling_final 
program define student_sibling_final 

	/*
	args fam_type 
	global fam_type = `fam_type'


	use "$OUT\students${data}", clear

	keep id_per_umc
	
	merge 1:1 id_per_umc using "$TEMP\id_siblings", keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}) keep(master match) nogen
	
	keep if inlist(fam_total_${fam_type},2,3,4,5,6,7)==1
	
	*- Focal Child variables
	*-- School characteristics
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_???) keep(master match) nogen
	rename (id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_pri id_ie_sec) (id_ie_foc region_siagie_foc public_siagie_foc urban_siagie_foc carac_siagie_foc id_ie_pri_foc id_ie_sec_foc)
	
	*-- Demographic
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(male_siagie exp_graduating_year? socioec_index_* enrolled_lpred? last_year last_grade) keep(master match) nogen
	rename (male_siagie exp_graduating_year? socioec_index_* enrolled_lpred? last_year last_grade) (male_siagie_foc exp_graduating_year?_foc socioec_index_*_foc enrolled_lpred?_foc last_year_foc last_grade_foc)
	
	*-- School progression
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? change_ie_???? pri_grad sec_grad year_grad_school) keep(master match)  nogen
	rename (dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? change_ie_???? pri_grad sec_grad year_grad_school) (dropout_foc dropout_year_foc dropout_grade_foc dropout_ever_foc approved_????_foc approved_first_????_foc math_secondary_????_foc comm_secondary_????_foc change_ie_????_foc pri_grad_foc sec_grad_foc year_grad_school_foc)

	*-- Exam
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(score_math_std_?? score_com_std_?? score_acad_std_?? year_??) keep(master match) nogen 
	rename (score_math_std_?? score_com_std_?? score_acad_std_?? year_??) (score_math_std_??_foc score_com_std_??_foc  score_acad_std_??_foc year_??_foc)
	
	*-- Survey variables (Aspiration, ...)
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(aspiration_?? asp_college?_?? /*std_belief_gender*_??*/ /*gender_miss_4p*/) keep(master match) nogen
	rename (aspiration_?? asp_college?_?? /*std_belief_gender*_??*/ /*gender_miss_4p*/) (aspiration_??_foc asp_college?_??_foc  /*std_belief_gender*_??_foc*/ /*gender_miss_4p_foc*/)
	
	*-- University (application)
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(year_app applied year_app_public applied_public dob_app) keep(master match) nogen
	rename (year_app applied year_app_public applied_public dob_app) (year_app_foc applied_foc year_app_public_foc applied_public_foc dob_app_foc)		
	
	*-- University (enrollment)
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(dob_enr score_std_uni_enr ) keep(master match) nogen
	rename (dob_enr score_std_uni_enr) (dob_enr_foc score_std_uni_enr_foc)	
	
	*-- Peer Outcomes
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(peer_score_*_std_?? peer_grad_uni_ever peer_grad_uni_5 peer_grad_uni_6) keep(master match) nogen
	rename peer_score_*_std_?? peer_score_*_std_??_foc	
	rename (peer_grad_uni_ever peer_grad_uni_5 peer_grad_uni_6) (peer_grad_uni_ever_foc peer_grad_uni_5_foc peer_grad_uni_6_foc)
	
	**##
	*- We are considering up to next 5 siblings 
	expand 10
	
	*- We recover the IDs (id_per_umc) of each sibling based on sibling order
	rename fam_order_${fam_type} aux_fam_order_${fam_type}
	rename id_per_umc aux_id_per_umc
	clonevar fam_order_${fam_type} = aux_fam_order_${fam_type}
	sort aux_id_per_umc id_fam_${fam_type} fam_order_${fam_type}
	bys aux_id_per_umc: replace fam_order_${fam_type} = fam_order_${fam_type} + _n-5 			//5 above and 5 below
	bys aux_id_per_umc: replace fam_order_${fam_type} = fam_order_${fam_type} - 1 if  fam_order_${fam_type}<= aux_fam_order_${fam_type} //we correct since those 5 below are starting from current
	drop if fam_order_${fam_type} > fam_total_${fam_type} //No need to look for siblings beyond the maximum size
	drop if fam_order_${fam_type} < 1 //Only start with first sibling
	
	*- Recover ID
**# Bookmark #2 
	merge m:1 id_fam_${fam_type} fam_order_${fam_type} using "$OUT\students", keepusing(id_per_umc) keep(master match)
	bys id_fam_${fam_type}: egen m_max= max(_m)
	tab m_max
	assert m_max==3
	//Why would there be families with no matches if all of them had 2+ siblings?
	drop m_max
	///////////////////////////############
	rename _m m_sibling_siagie
	keep if m_sibling_siagie == 3 //Only keep those who match a younger sibling
	
	*-- School characteristics
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_??? avg_applied* avg_enroll*) keep(master match) nogen
	rename (id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_???  avg_applied* avg_enroll*) (id_ie_sib region_siagie_sib public_siagie_sib urban_siagie_sib carac_siagie_sib id_ie_???_sib avg_applied*_foc avg_enroll*_foc)
	
	*-- Demographic
	rename socioec_index* _socioec_index*
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(male_siagie exp_graduating_year? socioec_index_* enrolled_lpred? last_year last_grade) keep(master match) nogen
	rename (male_siagie exp_graduating_year? socioec_index_* enrolled_lpred? last_year last_grade) (male_siagie_sib exp_graduating_year?_sib socioec_index_*_sib enrolled_lpred?_sib last_year_sib last_grade_sib)	
	rename _socioec_index* socioec_index*
	
	*-- School progression
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? change_ie_???? pri_grad sec_grad year_grad_school) keep(master match)  nogen
	rename (dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? change_ie_???? pri_grad sec_grad year_grad_school) (dropout_sib dropout_year_sib dropout_grade_sib dropout_ever_sib approved_????_sib approved_first_????_sib math_secondary_????_sib comm_secondary_????_sib change_ie_????_sib pri_grad_sib sec_grad_sib year_grad_school_sib)
	
	*-- Exam 
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(score_math_std_?? score_com_std_??  score_acad_std_?? year_??) keep(master match) nogen 
	rename (score_math_std_?? score_com_std_??  score_acad_std_?? year_??) (score_math_std_??_sib score_com_std_??_sib  score_acad_std_??_sib year_??_sib)
	
	*-- Survey variables (Aspiration, ...)
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(aspiration_?? asp_college?_?? /*std_belief_gender*_??*/ /*gender_miss_4p*/) keep(master match) nogen
	rename (aspiration_?? asp_college?_??  /*std_belief_gender*_??*/ /*gender_miss_4p*/) (aspiration_??_sib asp_college?_??_sib  /*std_belief_gender*_??_sib*/ /*gender_miss_4p_sib*/)

	*-- University (application)
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(year_app applied year_app_public applied_public dob_app year_app_stem applied_stem year_app_nstem applied_nstem) keep(master match) nogen
	rename (year_app applied year_app_public applied_public dob_app year_app_stem applied_stem year_app_nstem applied_nstem) (year_app_sib applied_sib year_app_public_sib applied_public_sib dob_app_sib year_app_stem_sib applied_stem_sib year_app_nstem_sib applied_nstem_sib)	
	
	*-- University (enrollment)
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(dob_enr score_std_uni_enr  year_enr_stem enrolled_stem year_enr_nstem enrolled_nstem) keep(master match) nogen
	rename (dob_enr score_std_uni_enr year_enr_stem enrolled_stem year_enr_nstem enrolled_nstem) (dob_enr_sib score_std_uni_enr_sib  year_enr_stem_sib enrolled_stem_sib year_enr_nstem_sib enrolled_nstem_sib)	
	
	*-- Peer Outcomes
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(peer_score_*_std_?? peer_grad_uni_ever peer_grad_uni_5 peer_grad_uni_6) keep(master match) nogen
	rename peer_score_*_std_?? peer_score_*_std_??_sib
	rename (peer_grad_uni_ever peer_grad_uni_5 peer_grad_uni_6) (peer_grad_uni_ever_sib peer_grad_uni_5_sib peer_grad_uni_6_sib)	
		

	
	
	*- School outcomes
/*
	merge m:1 id_fam_4 fam_order_4 using "$OUT\students", keepusing(/*SCHOOL*/ aspiration_?? asp_college?_?? score_math_std_?? score_com_std_?? year_?? exp_graduating_year1 socioec_index_?? socioec_index_cat_?? /*UNI*/ year_app applied year_app_public applied_public dob_app dob_enr score_std_uni_enr) keep(master match)
	rename (aspiration_?? asp_college?_?? score_math_std_?? score_com_std_?? year_?? exp_graduating_year1 socioec_index_?? socioec_index_cat_?? year_app applied year_app_public applied_public dob_app dob_enr score_std_uni_enr) (aspiration_??_sib asp_college?_??_sib score_math_std_??_sib score_com_std_??_sib year_??_sib exp_graduating_year1_sib socioec_index_??_sib socioec_index_cat_??_sib year_app_sib applied_sib year_app_public_sib applied_public_sib dob_app_sib dob_enr_sib score_std_uni_enr_sib) 

	rename _m m_sibling_siagie
*/

	rename (aux_id_per_umc id_per_umc) (id_per_umc id_per_umc_sib)
	rename (aux_fam_order_${fam_type} fam_order_${fam_type}) (fam_order_${fam_type} fam_order_${fam_type}_sib)
	
	
	*- Age differenec
	gen age_gap_app = datediff(dob_app_foc, dob_app_sib, "year") if dob_app_foc!=. & dob_app_sib!=.
	gen age_gap_exp = exp_graduating_year1_sib-exp_graduating_year1_foc
	
	replace age_gap_app = . if abs(age_gap_app)>20
	
	tab age_gap_app age_gap_exp if abs(age_gap_app)<5 & abs(age_gap_exp)<5

	save "$OUT\students_siblings_${fam_type}${data}", replace
	*/
	
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

	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(/*School*/ 		region_siagie public_siagie urban_siagie /*avg_applied* avg_enroll**/ ///
																 /*Demog*/ 			male_siagie educ_mother educ_father socioec_index_*  ///
																 /*Academic*/		score_math_std_?? score_com_std_?? ///
																 /*Progression*/	 ///
																 /*Aspiration*/		 aspiration_?? ///
																 /*University*/		enrolled enrolled_private ///
																 )


	
	bys id_per_umc: gen 	one_app = _N==1
	bys id_per_umc: egen 	priv_app = max(cond(public==0,1,0))
	gen no_priv = priv_app==0
	

	gen score_relative = score_std_`cutoff_level' - cutoff_std_`cutoff_level'
	drop if score_relative==.

	gen sample = 0
	replace sample = 1 

	gen sample_b = 0 //below
	replace sample_b = 1 if rank_score_raw_`cutoff_level'<cutoff_rank_`cutoff_level'

	gen sample_b5 = 0
	replace sample_b5 = 1 if rank_score_raw_`cutoff_level'<cutoff_rank_`cutoff_level' & score_relative>-0.5

	gen sample_b2 = 0
	replace sample_b2 = 1 if rank_score_raw_`cutoff_level'<cutoff_rank_`cutoff_level' & score_relative>-0.2
	
	
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

			global covar1 "male_siagie i.educ_mother i.region_siagie i.urban_siagie i.public_siagie"
			logit `out' ${covar1} if sample`sample'==1			
			local s1`sample' =  e(N) 
			predict rej_`out'`sample'_lpred1

			global covar2 "male_siagie i.educ_mother i.region_siagie i.urban_siagie i.public_siagie score_math_std_2p score_com_std_2p"
			logit `out' ${covar2} if sample`sample'==1		
			local s2`sample' =  e(N) 
			predict rej_`out'`sample'_lpred2

			global covar3 "male_siagie i.educ_mother i.region_siagie i.urban_siagie i.public_siagie score_math_std_2s score_com_std_2s socioec_index_2s"
			logit `out' ${covar3} if sample`sample'==1			
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
	
	
timer clear 40
timer on 40	

	use "$TEMP\applied", clear
	
	if ${test_A04}==1 merge m:1 id_per_umc using "$OUT\students${data}", keepusing(id_per_umc) keep(match) nogen 

	
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
	
	merge m:1 id_per_umc using "$OUT\students${data}", keep(master match) nogen keepusing( ///
														/*School characteristics*/ 		id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_??? avg_applied* avg_enroll* ///
														/*Demographic*/  				male_siagie exp_graduating_year? socioec_index_* *_lpred? last_year last_grade	///		
														/*School progression*/ 			dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? std_gpa_m_???? std_gpa_c_???? change_ie_???? pri_grad sec_grad year_grad_school ///
														/*ECE score*/  					score_math_std_?? score_com_std_?? score_acad_std_?? year_??	///
														/*Survey*/  					aspiration_?? asp_college?_?? /*std_belief_gender*_??*/ /*gender_miss_4p*/	///
														/*University (application)*/  	/*year_app applied year_app_public applied_public*/ dob_app	///
														/*University (enrollment)*/  	dob_enr score_std_uni_enr	///
														/*Peer Outcomes*/  				peer_score_*_std_?? peer_graduated_uni_ever peer_graduated_uni_5 peer_graduated_uni_6	///
														/**/  ///
														) 
														
														

	foreach v of var 									/*School characteristics*/ 		id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_??? avg_applied* avg_enroll* ///
														/*Demographic*/  				male_siagie exp_graduating_year? socioec_index_* *_lpred? last_year last_grade	///		
														/*School progression*/ 			dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? std_gpa_m_???? std_gpa_c_???? change_ie_???? pri_grad sec_grad year_grad_school ///
														/*ECE score*/  					score_math_std_?? score_com_std_?? score_acad_std_?? year_??	///
														/*Survey*/  					aspiration_?? asp_college?_?? /*std_belief_gender*_??*/ /*gender_miss_4p*/	///
														/*University (application)*/  	/*year_app applied year_app_public applied_public*/ dob_app	///
														/*University (enrollment)*/  	dob_enr score_std_uni_enr	///
														/*Peer Outcomes*/  				peer_score_*_std_?? peer_graduated_uni_ever peer_graduated_uni_5 peer_graduated_uni_6	///
														/**/  ///
														{ 	
														rename `v' `v'_foc
														}
														
timer off 41



timer clear 42
timer on 42
*- University variables (application, enrollment, graduation, peers)
	merge m:1 id_per_umc using "$TEMP\student_umc_uni",  keep(master match) nogen keepusing( ///
																applied_public year_applied_public 	///
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
																graduated_public year_graduated_public 	///	
																graduated_private year_graduated_private 	///
																graduated year_graduated 	///
																year_graduated_f_uni graduated_f_uni_ever graduated_f_uni_5 graduated_f_uni_6 score_std_f_uni_grad years_to_grad_f_uni	 	///
														) 
														
														

	foreach v of var 											applied_public year_applied_public 	///
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
																graduated_public year_graduated_public 	///	
																graduated_private year_graduated_private 	///
																graduated year_graduated 	///
																year_graduated_f_uni graduated_f_uni_ever graduated_f_uni_5 graduated_f_uni_6 score_std_f_uni_grad years_to_grad_f_uni	 	///
														{ 	
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
		
	/*
	*-- School characteristics
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_??? avg_applied* avg_enroll*) keep(master match) nogen
	rename (id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_??? avg_applied* avg_enroll*) (id_ie_foc region_siagie_foc public_siagie_foc urban_siagie_foc carac_siagie_foc id_ie_???_foc avg_applied*_foc avg_enroll*_foc)
	
	*-- Demographic
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(male_siagie exp_graduating_year? socioec_index_* *_lpred? last_year last_grade) keep(master match) nogen
	rename (male_siagie exp_graduating_year? socioec_index_* *_lpred? last_year last_grade) (male_siagie_foc exp_graduating_year?_foc socioec_index_*_foc *_lpred?_foc last_year_foc last_grade_foc)

	*-- School progression
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? change_ie_???? pri_grad sec_grad year_grad_school) keep(master match)  nogen
	rename (dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? change_ie_???? pri_grad sec_grad year_grad_school) (dropout_foc dropout_year_foc dropout_grade_foc dropout_ever_foc approved_????_foc approved_first_????_foc math_secondary_????_foc comm_secondary_????_foc change_ie_????_foc pri_grad_foc sec_grad_foc year_grad_school_foc)
	
	*-- Exam
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(score_math_std_?? score_com_std_?? score_acad_std_?? year_??) keep(master match) nogen 
	rename (score_math_std_?? score_com_std_?? score_acad_std_?? year_??) (score_math_std_??_foc score_com_std_??_foc  score_acad_std_??_foc year_??_foc)
	
	*-- Survey variables (Aspiration, ...)
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(aspiration_?? asp_college?_?? /*std_belief_gender*_??*/ /*gender_miss_4p*/) keep(master match) nogen
	rename (aspiration_?? asp_college?_?? /*std_belief_gender*_??*/ /*gender_miss_4p*/) (aspiration_??_foc asp_college?_??_foc  /*std_belief_gender*_??_foc*/ /*gender_miss_4p_foc*/)
	
	*-- University (application)
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(/*year_app applied year_app_public applied_public*/ dob_app) keep(master match) nogen
	rename (/*year_app applied year_app_public applied_public*/ dob_app) (/*year_app_foc applied_foc year_app_public_foc applied_public_foc*/ dob_app_foc)
	
	*-- University (enrollment)
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(dob_enr score_std_uni_enr) keep(master match) nogen
	rename (dob_enr score_std_uni_enr) (dob_enr_foc score_std_uni_enr_foc)	
	
	*-- Peer Outcomes
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(peer_score_*_std_?? peer_grad_uni_ever peer_grad_uni_5 peer_grad_uni_6) keep(master match) nogen
	rename peer_score_*_std_?? peer_score_*_std_??_foc
	rename (peer_grad_uni_ever peer_grad_uni_5 peer_grad_uni_6) (peer_grad_uni_ever_foc peer_grad_uni_5_foc peer_grad_uni_6_foc)	
	*/
	

	
	
	
	*-- Likelihood of enrolled if reject: For counterfactual
	merge m:1 id_per_umc using  "$TEMP\likelihood_rej_enr${data}", keepusing(rej_enr_b2_lpred? rej_enr_b2_lpred?_above) keep(master match) nogen
	rename rej_enr* rej_enr*_foc	
	
		
	
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
		
		//Ever	
		/*
		*- # of applications
		merge m:1 id_per_umc using "$TEMP\total_applications_student", keepusing(N_applications N_applications_first) keep(master match)  	
		assert _m==3 //based on same data so should be everyone
		rename (N_applications N_applications_first) (N_applications_foc N_applications_first_foc)
		drop _m
		
		*- Applied to public 			ever
		merge m:1 id_per_umc using "$TEMP\applied_students_public", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (applied_public_foc year_applied_public_foc)
		
		*- Applied to other public ever
		merge m:1 id_per_umc using "$TEMP\applied_students", keepusing(applied_public_tot) keep(master match)  
		rename applied_public_tot applied_public_tot_foc
		gen applied_public_o_foc = 0 
		replace applied_public_o_foc = 1 if public_foc == 0 & applied_public_tot_foc>=1 & applied_public_tot_foc!=.
		replace applied_public_o_foc = 1 if public_foc == 1 & applied_public_tot_foc>=2 & applied_public_tot_foc!=.
		drop _m
		*/
		* Applied to (other) public
		/*
		merge m:1 id_per_umc codigo_modular using "$TEMP\applied_students_multiple_public", keepusing(year) keep(master match) 
		gen applied_public_o_foc = 0
		replace applied_public_o_foc = 1 if _m==1 // Applied to other public (than target) if they have 2+ public college applications (this is for focal)
		drop _m year
		*/
		
		*- Applied to private 			ever
		/*
		merge m:1 id_per_umc using "$TEMP\applied_students_private", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (applied_private_foc year_applied_private_foc)
			
		label values applied*foc yes_no
		*/
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
		/*
		*- Enrolled in public 			ever
		merge m:1 id_per_umc using "$TEMP\enrolled_students_public", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (enrolled_public_foc year_enr_public_foc)	
		
		*- Enrolled in other public ever
		merge m:1 id_per_umc using "$TEMP\enrolled_students", keepusing(enrolled_public_tot) keep(master match)  
		rename enrolled_public_tot enrolled_public_tot_foc
		gen enrolled_public_o_foc = 0 
		replace enrolled_public_o_foc = 1 if public_foc == 0 & enrolled_public_tot_foc>=1 & enrolled_public_tot_foc!=.
		replace enrolled_public_o_foc = 1 if public_foc == 1 & enrolled_public_tot_foc>=2 & enrolled_public_tot_foc!=.
		drop _m	
		*/

		*- Enrolled in (other) public
		/*
		merge m:1 id_per_umc codigo_modular using "$TEMP\enrolled_students_multiple_public", keepusing(year) keep(master match) 
		gen enrolled_public_o_foc = 0
		replace enrolled_public_o_foc = 1 if _m==1 // Enroll to other public (than target) if they have 2+ public college enrollments (this is for focal)
		drop _m year		
		*/
		/*
		*- Enrolled in private 			ever
		merge m:1 id_per_umc using "$TEMP\enrolled_students_private", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (enrolled_private_foc year_enr_private_foc)
		
		*- Enrolled 					ever
		merge m:1 id_per_umc using "$TEMP\enrolled_students", keepusing(year) keep(master match) 
		recode _m (1 = 0) (3 = 1)
		rename (_m year) (enrolled_foc year_enr_foc)			
		*/
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
		
*- Graduation Outcomes
	*- Graduation outcomes
	merge m:1 id_per_umc codigo_modular using "$TEMP\graduated_students_university", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (graduated_uni_foc year_graduated_uni_foc)	
	/*
	merge m:1 id_per_umc using "$TEMP\graduated_students_public", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (grad_public_foc year_grad_public_foc)

	merge m:1 id_per_umc using "$TEMP\graduated_students_private", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (grad_private_foc year_grad_private_foc)

	merge m:1 id_per_umc using "$TEMP\graduated_students", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (grad_foc year_grad_foc)
	
	merge m:1 id_per_umc using "$TEMP\first_enrollment_outcomes", keepusing(year_grad grad_uni_ever grad_uni_5 grad_uni_6 score_std_uni_grad years_to_grad_uni) keep(master match) 
	rename (year_grad grad_uni_ever grad_uni_5 grad_uni_6 score_std_uni_grad years_to_grad_uni) (year_grad_f_uni_foc grad_f_uni_ever_foc grad_f_uni_5_foc grad_f_uni_6_foc score_std_f_uni_grad_foc years_to_grad_f_uni_foc)
	drop _m
	*/

	//assert test_year_grad_uni_foc == year_grad_uni_foc //won't be equal but would like to understand difference.
	
	label var graduated_uni_foc 		"Graduated in same university ever (focal child)"
	label var graduated_public_foc 		"Graduated in public university ever (focal child)"
	label var graduated_private_foc 	"Graduated in private university ever (focal child)"
	label var graduated_foc 			"Graduated in other public university ever (focal child)"		
	label var years_to_grad_f_uni_foc 	"Years to graduate from university (focal)"
	label var graduated_f_uni_ever_foc 		"Graduated in same university ever (focal child)"
	label var graduated_f_uni_5_foc 			"Graduated in same university within 5 years (focal child)"
	label var graduated_f_uni_6_foc 			"Graduated in same university within 6 years (focal child)"
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
	merge m:1 id_fam_${fam_type} fam_order_${fam_type} using "$OUT\students${data}", keepusing(id_per_umc) keep(master match) 
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
	merge m:1 id_per_umc using "$OUT\students${data}", keep(master match) nogen keepusing( ///
														/*School characteristics*/ 		id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_??? avg_applied* avg_enroll* ///
														/*Demographic*/  				male_siagie exp_graduating_year? socioec_index_* *_lpred? last_year last_grade	///		
														/*School progression*/ 			dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? std_gpa_m_???? std_gpa_c_???? change_ie_???? pri_grad sec_grad year_grad_school ///
														/*ECE score*/  					score_math_std_?? score_com_std_?? score_acad_std_?? year_??	///
														/*Survey*/  					aspiration_?? asp_college?_?? /*std_belief_gender*_??*/ /*gender_miss_4p*/	///
														/*University (application)*/  	/*year_app applied year_app_public applied_public*/ dob_app	///
														/*University (enrollment)*/  	dob_enr score_std_uni_enr	///
														/*Peer Outcomes*/  				peer_score_*_std_?? peer_graduated_uni_ever peer_graduated_uni_5 peer_graduated_uni_6	///
														/**/  ///
														) 
														
														

	foreach v of var 									/*School characteristics*/ 		id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_??? avg_applied* avg_enroll* ///
														/*Demographic*/  				male_siagie exp_graduating_year? socioec_index_* *_lpred? last_year last_grade	///		
														/*School progression*/ 			dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? std_gpa_m_???? std_gpa_c_???? change_ie_???? pri_grad sec_grad year_grad_school ///
														/*ECE score*/  					score_math_std_?? score_com_std_?? score_acad_std_?? year_??	///
														/*Survey*/  					aspiration_?? asp_college?_?? /*std_belief_gender*_??*/ /*gender_miss_4p*/	///
														/*University (application)*/  	/*year_app applied year_app_public applied_public*/ dob_app	///
														/*University (enrollment)*/  	dob_enr score_std_uni_enr	///
														/*Peer Outcomes*/  				peer_score_*_std_?? peer_graduated_uni_ever peer_graduated_uni_5 peer_graduated_uni_6	///
														/**/  ///
														{ 	
														rename `v' `v'_sib
														}
	
*- University variables (application, enrollment, graduation, peers)
	merge m:1 id_per_umc using "$TEMP\student_umc_uni",  keep(master match) nogen keepusing( ///
																applied_public year_applied_public 	///
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
																graduated_public year_graduated_public 	///	
																graduated_private year_graduated_private 	///
																graduated year_graduated 	///
																year_graduated_f_uni graduated_f_uni_ever graduated_f_uni_5 graduated_f_uni_6 score_std_f_uni_grad years_to_grad_f_uni	 	///
														) 
														
														

	foreach v of var 											applied_public year_applied_public 	///
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
																graduated_public year_graduated_public 	///	
																graduated_private year_graduated_private 	///
																graduated year_graduated 	///
																year_graduated_f_uni graduated_f_uni_ever graduated_f_uni_5 graduated_f_uni_6 score_std_f_uni_grad years_to_grad_f_uni	 	///
														{ 	
	
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
														
/*
	*-- School characteristics
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_???) keep(master match) nogen
	rename (id_ie region_siagie public_siagie urban_siagie carac_siagie id_ie_pri id_ie_sec) (id_ie_sib region_siagie_sib public_siagie_sib urban_siagie_sib carac_siagie_sib id_ie_pri_sib id_ie_sec_sib)
	
	*-- Demographic
	rename socioec_index* _socioec_index*
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(male_siagie exp_graduating_year? socioec_index_* *_lpred? last_year last_grade) keep(master match) nogen
	rename (male_siagie exp_graduating_year? socioec_index_* *_lpred? last_year last_grade) (male_siagie_sib exp_graduating_year?_sib socioec_index_*_sib *_lpred?_sib last_year_sib last_grade_sib)	
	rename _socioec_index* socioec_index*
		
	*-- School progression
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? change_ie_???? pri_grad sec_grad year_grad_school) keep(master match)  nogen
	rename (dropout dropout_year dropout_grade dropout_ever approved_???? approved_first_???? math_secondary_???? comm_secondary_???? change_ie_???? pri_grad sec_grad year_grad_school) (dropout_sib dropout_year_sib dropout_grade_sib dropout_ever_sib approved_????_sib approved_first_????_sib math_secondary_????_sib comm_secondary_????_sib change_ie_????_sib pri_grad_sib sec_grad_sib year_grad_school_sib)
	
	*-- Exam 
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(score_math_std_?? score_com_std_??  score_acad_std_?? year_??) keep(master match) nogen 
	rename (score_math_std_?? score_com_std_??  score_acad_std_?? year_??) (score_math_std_??_sib score_com_std_??_sib  score_acad_std_??_sib year_??_sib)
	
	*-- Survey variables (Aspiration, ...)
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(aspiration_?? asp_college?_?? /*std_belief_gender*_??*/ /*gender_miss_4p*/) keep(master match) nogen
	rename (aspiration_?? asp_college?_??  /*std_belief_gender*_??*/ /*gender_miss_4p*/) (aspiration_??_sib asp_college?_??_sib  /*std_belief_gender*_??_sib*/ /*gender_miss_4p_sib*/)	
	
	*-- University (application)
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(/*year_app applied year_app_public applied_public*/ dob_app) keep(master match) nogen
	rename (/*year_app applied year_app_public applied_public*/ dob_app) (/*year_app_sib applied_sib year_app_public_sib applied_public_sib*/ dob_app_sib)
	
	*-- University (enrollment)
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(dob_enr score_std_uni_enr ) keep(master match) nogen
	rename (dob_enr score_std_uni_enr) (dob_enr_sib score_std_uni_enr_sib)	
		
	*-- Peer Outcomes
	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(peer_score_*_std_?? peer_grad_uni_ever peer_grad_uni_5 peer_grad_uni_6) keep(master match) nogen
	rename peer_score_*_std_?? peer_score_*_std_??_sib
	rename (peer_grad_uni_ever peer_grad_uni_5 peer_grad_uni_6) (peer_grad_uni_ever_sib peer_grad_uni_5_sib peer_grad_uni_6_sib)
	*/
	
	

	
	/*
	merge m:1 id_per_umc using "$TEMP\applied_students_public", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_public_sib year_applied_public_sib)

	merge m:1 id_per_umc using "$TEMP\applied_students_private", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_private_sib year_applied_private_sib)	

	**** CONTINUE
	merge m:1 id_per_umc using "$TEMP\applied_students", keepusing(applied_public_tot) keep(master match) 
	rename applied_public_tot applied_public_tot_sib
	gen applied_public_o_sib = 0 
	replace applied_public_o_sib = 1 if public_foc == 0 & applied_public_tot_sib>=1 & applied_public_tot_sib!=. //If target is private and sibling has public then =1
	replace applied_public_o_sib = 1 if public_foc == 1 & applied_public_tot_sib>=2 & applied_public_tot_sib!=. //If target is public and sibling has 2+ then =1
	replace applied_public_o_sib = 1 if public_foc == 1 & applied_public_tot_sib==1 & applied_uni_sib==0  //If target is public and sibling only has one but has public and different from target, then =1
	drop _m
	*/
	
	/*
	merge m:1 id_per_umc codigo_modular using "$TEMP\applied_students_multiple_public", keepusing(year) keep(master match) 
	gen applied_public_o_sib = 0
	replace applied_public_o_sib = 1 if (applied_public_sib==1 & applied_uni_sib==0) 	// Applied to public but not target
	replace applied_public_o_sib = 1 if (_m==3) 										// Applied to multiple publics
	drop _m year 
	*/
/*	
	merge m:1 id_per_umc using "$TEMP\applied_students", keepusing(year semester) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_sib year_applied_sib)
	
	merge m:1 id_per_umc using "$TEMP\admitted_students", keepusing(year semester) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (admitted_sib year_admitted_sib)	
	
	*- Applied STEM
	merge m:1 id_per_umc using "$TEMP\applied_stem_students", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_stem_sib year_applied_stem_sib)
	
	*- Applied NOT IN STEM
	merge m:1 id_per_umc using "$TEMP\applied_nstem_students", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_nstem_sib year_applied_nstem_sib)	
*/
	
	
	*- # of applications semester
	/*
	merge m:1 id_per_umc semester using "$TEMP\total_applications_student_semester", keepusing(N_applications_semester) keep(master match)  	
	replace N_applications_semester = 0 if applied_sem_sib == 0 
	rename (N_applications_semester) (N_applications_semester_sib)	
	drop _m
	*/
	
/*	
	
	*- # of applications
	merge m:1 id_per_umc using "$TEMP\total_applications_student", keepusing(N_applications N_applications_first) keep(master match)  	
	replace N_applications = 0 if applied_sib == 0 
	rename (N_applications N_applications_first) (N_applications_sib N_applications_first_sib) //No included in focal
	drop _m
	
*/

	
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
	drop _m 
	
	foreach cutoff_level in "major" "deprt" "major_full" "deprt_full" {	
		replace score_std_`cutoff_level'_uni_o_f_sib = score_std_`cutoff_level'_all_f_sib
		replace score_std_`cutoff_level'_pub_o_f_sib = score_std_`cutoff_level'_pub_f_sib 
	}
	
	foreach cutoff_level in "major" "deprt" "major_full" "deprt_full" {
		label var score_std_`cutoff_level'_all_f_sib 	"Average score of all universities 	- First semester cosidered (sibling)"
		label var score_std_`cutoff_level'_pub_f_sib 	"Average score of public universities  - First semester cosidered (sibling)"
		label var score_std_`cutoff_level'_uni_f_sib 	"Average score of target university - First semester cosidered (sibling)"
		label var score_std_`cutoff_level'_uni_o_f_sib "Average score of other universities - First semester cosidered (sibling)"
		label var score_std_`cutoff_level'_pub_o_f_sib	"Average score of other public universities - First semester cosidered (sibling)"
	}	

	label values applied*sib yes_no

	label var applied_uni_major_sib 	"Applied in same university-major ever (sibling)"
	label var applied_uni_sib 			"Applied in same university ever (sibling)"
	label var applied_major_sib 		"Applied in same major ever (sibling)"
	label var applied_public_sib 		"Applied in public university ever (sibling)"
	label var applied_private_sib 		"Applied in private university ever (sibling)"
	label var applied_sib 				"Applied ever (sibling)"	
	
	//HAS TO BE ONE PER SIBLING. CAN WE HAVE ONE PER 'SIBLING' (for application), 'SIBLING-COLLEGE'/'SIBLING-MAJOR' for those outcome and 
	

/*	
	merge m:1 id_per_umc using "$TEMP\enrolled_students_public", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_public_sib year_enrolled_public_sib)

	merge m:1 id_per_umc using "$TEMP\enrolled_students_private", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_private_sib year_enrolled_private_sib)
	
	merge m:1 id_per_umc using "$TEMP\enrolled_students", keepusing(enrolled_public_tot) keep(master match) 
	rename enrolled_public_tot enrolled_public_tot_sib
	gen enrolled_public_o_sib = 0 
*/

/*
	replace enrolled_public_o_sib = 1 if public_foc == 0 & enrolled_public_tot_sib>=1 & enrolled_public_tot_sib!=. //If target is private and sibling has public then =1
	replace enrolled_public_o_sib = 1 if public_foc == 1 & enrolled_public_tot_sib>=2 & enrolled_public_tot_sib!=. //If target is public and sibling has 2+ then =1
	replace enrolled_public_o_sib = 1 if public_foc == 1 & enrolled_public_tot_sib==1 & enrolled_uni_sib==0  //If target is public and sibling only has one but has public and different from target, then =1	
	
	drop _m	
	*/
	/*
	merge m:1 id_per_umc codigo_modular using "$TEMP\enrolled_students_multiple_public", keepusing(year) keep(master match) 
	gen enrolled_public_o_sib = 0
	replace enrolled_public_o_sib = 1 if (enrolled_public_sib==1 & enrolled_uni_sib==0) 	// Applied to public but not target
	replace enrolled_public_o_sib = 1 if (_m==3) 										// Applied to multiple publics
	drop _m year 
	*/
	
	/*
	merge m:1 id_per_umc using "$TEMP\enrolled_students", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_sib year_enrolled_sib)
	
	*- Enrolled STEM
	merge m:1 id_per_umc using "$TEMP\enrolled_stem_students", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_stem_sib year_enrolled_stem_sib)
	
	*- Enrolled NOT IN STEM
	merge m:1 id_per_umc using "$TEMP\enrolled_nstem_students", keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_nstem_sib year_enrolled_nstem_sib)		
	*/
	drop major_inei_code

	label values enroll*sib yes_no

	label var enrolled_uni_major_sib 		"Enrolled in same university-major ever (sibling)"
	label var enrolled_uni_sib 			"Enrolled in same university ever (sibling)"
	label var enrolled_major_sib 			"Enrolled in same major ever (sibling)"
	label var enrolled_public_sib 		"Enrolled in public university ever (sibling)"
	label var enrolled_private_sib 		"Enrolled in private university ever (sibling)"
	label var enrolled_public_o_sib 		"Enrolled in other public university ever (sibling)"
	label var enrolled_sib 				"Enrolled ever (sibling)"	
	
	
	*- Graduation outcomes
	merge m:1 id_per_umc codigo_modular using "$TEMP\graduated_students_university", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (graduated_uni_sib year_graduated_uni_sib)	
	/*
	merge m:1 id_per_umc using "$TEMP\graduated_students_public", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (grad_public_sib year_grad_public_sib)

	merge m:1 id_per_umc using "$TEMP\graduated_students_private", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (grad_private_sib year_grad_private_sib)

	merge m:1 id_per_umc using "$TEMP\graduated_students", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (grad_sib year_grad_sib)
	
	merge m:1 id_per_umc using "$TEMP\first_enrollment_outcomes", keepusing(year_grad grad_uni_ever grad_uni_5 grad_uni_6 score_std_uni_grad years_to_grad_uni) keep(master match) 
	rename (year_grad grad_uni_ever grad_uni_5 grad_uni_6 score_std_uni_grad years_to_grad_uni) (year_grad_f_uni_sib grad_f_uni_ever_sib grad_f_uni_5_sib grad_f_uni_6_sib score_std_f_uni_grad_sib years_to_grad_f_uni_sib)
	drop _m
	*/
	//assert test_year_grad_uni_sib == year_grad_uni_sib //won't be equal but would like to understand difference.
	
	label var graduated_uni_sib 				"Graduated in same university ever (sibling)"
	label var graduated_public_sib 			"Graduated in public university ever (sibling)"
	label var graduated_private_sib 			"Graduated in private university ever (sibling)"
	label var graduated_sib 					"Graduated in other public university ever (sibling)"		
	label var years_to_grad_f_uni_sib 	"Years to graduate from university (focal)"
	label var graduated_f_uni_ever_sib 		"Graduated in same university ever (sibling)"
	label var graduated_f_uni_5_sib 			"Graduated in same university within 5 years (sibling)"
	label var graduated_f_uni_6_sib 			"Graduated in same university within 6 years (sibling)"
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
						/*Counterfactual*/		rej_enr*_foc ///
						/*Progression*/			dropout*_foc approved_????_foc approved_first_????_foc  math_secondary_????_foc comm_secondary_????_foc std_gpa_?_????_foc change_ie_????_foc pri_grad_foc sec_grad_foc year_graduated_school_foc ///	
						/*Exams*/				year_??_foc score_math_std_??_foc score_com_std_??_foc score_acad_std_??_foc ///
						/*Survey*/				aspiration_??_foc asp_college?_??_foc std_belief_gender*_??_foc gender_miss_4p_foc  ///
						/*Other*/				sch_*_foc ///
					/*University*/ ///
						/*Application */ 		year_applied_foc semester_foc type_admission N_applications*foc N_admissions_semester_foc ///
						/*Admission */			admitted_foc year_admitted_foc ///
						/*Enrollment*/ 			year_enr_foc ///	
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
						/*Demographics*/		male_siagie*_sib *_lpred?_sib last_year_sib last_grade_sib ///
						/*Progression*/			dropout*_sib approved_????_sib approved_first_????_sib math_secondary_????_sib comm_secondary_????_sib std_gpa_?_????_sib change_ie_????_sib pri_grad_sib sec_grad_sib year_graduated_school_sib ///
						/*Exams*/			 	year_??_sib score_math_std_??_sib score_com_std_??_sib score_acad_std_??_sib ///
						/*Survey*/				aspiration_??_sib asp_college?_??_sib std_belief_gender*_??_sib gender_miss_4p_sib /// 
						/*Other*/				sch_*_sib ///
					/*University*/ ///	
						/*Application */ 		year*app*sib app*sib semester_sib N_applications*sib score_std_*_all*sib score_std_*_uni*sib score_std_*_pub*sib  ///
						/*Admission */			year_admitted_sib admitted_sib ///
						/*Enrollment*/ 			year*enr*sib enr*sib score_std_uni_enr_sib ///
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
				
				
	
	save "$OUT/applied_outcomes_${fam_type}${data}.dta", replace	
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

forvalues i = 1(1)50 {
	capture timer list `i'
	ret li
	capture local time_`i' = r(t`i')/60
}


forvalues i = 1(1)22 {
	di as text "section #`i' lasted " `time_`i''	
}


forvalues i = 40(1)50 {
	di as text "section #`i' lasted " `time_`i''
}
	
	
clear

set obs 50
gen time = .
gen i = .

forvalues i = 1(1)50 {
	replace i = `i' in `i'
	replace time = `time_`i'' in `i'
}

	drop if time==.

save "$TEMP\timer_04_3", replace