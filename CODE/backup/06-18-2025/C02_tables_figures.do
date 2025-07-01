/********************************************************************************
- Author: Francisco Pardo
- Description: Produces final tables and figures
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/

capture program drop main 
program define main 

	setup_C02

	*first_stage 2 major first student main
	/*
	histogram_score 2 first student 4
	
	mccrary 2 first student uniform 2
	mccrary 2 first student uniform 1
	mccrary 2 first student uniform 0.5
	
	mccrary 2 first student triangular 2
	mccrary 2 first student triangular 1
	mccrary 2 first student triangular 0.5	
	
	mccrary 2 first student_sibling triangular 2
	*/
	main_reg major triangular
	main_reg major uniform
	
	
	
	
	
	
	
	
	
	
	//first_stage_test major
	*first_stage 2 major all student main
	*first_stage 2 major all student R2
	//reg_test_new
	*main_reg major_full
	*mccrary 2 all student\
	/*
	RESTRICT TO RELEVANT SAMPLE (if_apps) 
	mccrary 2 all student_sibling
	mccrary 2 first student
	mccrary 2 first student_sibling
	*/

	*visual_balance 2 first	
	*visual_balance 2 all
	//family ID, sample (all, first...), outcomes (all, t_balance,...) , bandwidth (optimal, fixed)
	//e.g.
	//regressions 2 first t_sib_heterog_stem fixed
	//misc_figures
	

end


/*
Adding new outcomesss

*/




********************************************************************************
* Setup
********************************************************************************

capture program drop setup_C02
program define setup_C02

	set seed 1234
	global window = 10
	global mccrary_window = 4
	global redo_all = 0
	global test_C02 = 0
	

	global test_size = "h" //"s" "m" "h"
	
	if ${test_C02} == 0 global data = ""
	if ${test_C02} == 1 global data = "_TEST${test_size}"

	
end



********************************************************************************
* Prepare RD
********************************************************************************
capture program drop additional_vars
program define additional_vars

args type cell

	//local cell major
	//local type noz
	
	rename *_`cell' *
	rename *_`type' * 
	
	rename score_std_`cell'* score_std*

*- Score relative
	gen score_relative = score_std - cutoff_std
	drop if score_relative==.	
	keep if abs(score_relative)<${window} 

	*- Run the RD regression
	gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=. //To avoid float issues around 0, we use the precisely integer rank scores.

	*- Polynomial
	forvalues p = 1/1 {
		gen score_relative_`p' 			= score_relative^`p'
		gen ABOVE_score_relative_`p' 	= ABOVE*score_relative_`p'
	}
	
	*- Age gap
	gen age_gap = exp_graduating_year1_sib-exp_graduating_year1_foc	
	
	*- Remaining variables
	gen byte higher_ed_caretaker 	= inlist(educ_caretaker,7,8) if educ_caretaker!=. & educ_caretaker!=1 // =none seems to be partly missing
	gen byte higher_ed_mother 		= inlist(educ_mother,7,8) if educ_mother!=. & educ_mother!=1
	gen byte higher_ed_father 		= inlist(educ_father,7,8) if educ_father!=. & educ_father!=1
	gen byte sec_inc_caretaker 		= inlist(educ_caretaker,2,3,4) if educ_caretaker!=. & educ_caretaker!=1 
	gen byte sec_inc_mother 		= inlist(educ_mother,2,3,4) if educ_mother!=. & educ_mother!=1 
	gen byte sec_inc_father 		= inlist(educ_father,2,3,4) if educ_father!=. & educ_father!=1 
	gen byte pgrad_2p_foc			= inlist(aspiration_2p_foc,5) if aspiration_2p_foc!=.
	gen byte pgrad_4p_foc			= inlist(aspiration_4p_foc,5) if aspiration_4p_foc!=.
	gen byte pgrad_2s_foc			= inlist(aspiration_2s_foc,5) if aspiration_2s_foc!=.
	gen byte pgrad_2p_sib			= inlist(aspiration_2p_sib,5) if aspiration_2p_sib!=.
	gen byte pgrad_4p_sib			= inlist(aspiration_4p_sib,5) if aspiration_4p_sib!=.
	gen byte pgrad_2s_sib			= inlist(aspiration_2s_sib,5) if aspiration_2s_sib!=.
	//gen byte any_coll_2p_sib		= inlist(aspiration_2p_sib,3,4,5) if aspiration_2p_sib!=.
	//gen byte any_coll_4p_sib		= inlist(aspiration_4p_sib,3,4,5) if aspiration_4p_sib!=.
	//gen byte any_coll_2s_sib		= inlist(aspiration_2s_sib,3,4,5) if aspiration_2s_sib!=.	
	gen byte comp_sec_4p_sib		= inlist(aspiration_4p_sib,2,3,4,5) if aspiration_4p_sib!=.
	
	gen first_gen = 0 if educ_mother!=. | educ_father!=.
	replace first_gen = 1 if inlist(educ_mother,1,2,3,4,5,6,.)==1 & inlist(educ_father,1,2,3,4,5,6,.)==1
	

	gen asp_years_4p_sib 	 	= 6*(aspiration_4p_sib==1)+ 11*(aspiration_4p_sib==2)+ 14*(aspiration_4p_sib==3)+ 16*(aspiration_4p_sib==4)+18*(aspiration_4p_sib==5) if  aspiration_4p_sib!=.		
	gen asp_years_2s_sib 	 	= 8*(aspiration_2s_sib==1)+ 11*(aspiration_2s_sib==2)+ 14*(aspiration_2s_sib==3)+ 16*(aspiration_2s_sib==4)+18*(aspiration_2s_sib==5) if  aspiration_2s_sib!=.
	gen applies_on_time_sib 	= (year_applied_sib	<=(exp_graduating_year1_sib+1) & applied_sib==1) 	if exp_graduating_year1_sib!=.
	gen enrolls_on_time_sib 	= (year_enrolled_sib<=(exp_graduating_year1_sib+1) & enrolled_sib==1) 	if exp_graduating_year1_sib!=.
	gen byte vlow_ses_foc 		= socioec_index_cat_2s_foc==1 if socioec_index_cat_2s_foc!=.

	
	*- Likelihood of application/enrollment
	//Set median cutoffs
	foreach out in "applied" "admitted" "enrolled" {	
		sum	`out'_lpred1_foc, de
		gen `out'_lpred1_above_foc = (`out'_lpred1_foc>r(p50) & `out'_lpred1_foc!=.)
		sum	`out'_lpred2_foc, de`'
		gen `out'_lpred2_above_foc = (`out'_lpred2_foc>r(p50) & `out'_lpred2_foc!=.)
		sum	`out'_lpred3_foc, de`'
		gen `out'_lpred3_above_foc = (`out'_lpred3_foc>r(p50) & `out'_lpred3_foc!=.)
		sum	`out'_lpred4_foc, de`'
		gen `out'_lpred4_above_foc = (`out'_lpred4_foc>r(p50) & `out'_lpred4_foc!=.)
	}

	//USE: comp_sec_4p_sib any_coll_4p_sib asp_years_4p_sib, any_coll_2s_sib higher_ed_2s_sib asp_years_2s_sib
	
	
	/*
	RECOVER VARIABLES THAT SHOULD BE INCLUDED IN FUTURE RUN
	*/
	/*
	rename (id_per_umc id_per_umc_sib) (aux_id_per_umc id_per_umc)
	
	preserve
		use "$TEMP\applied_stem_students", clear
		destring id_per_umc, replace
		tempfile applied_stem_students
		save `applied_stem_students', replace
		
		use "$TEMP\applied_nstem_students", clear
		destring id_per_umc, replace
		tempfile applied_nstem_students
		save `applied_nstem_students', replace
		
		use "$TEMP\enrolled_stem_students", clear
		destring id_per_umc, replace
		tempfile enrolled_stem_students
		save `enrolled_stem_students', replace
		
		use "$TEMP\enrolled_nstem_students", clear
		destring id_per_umc, replace
		tempfile enrolled_nstem_students
		save `enrolled_nstem_students', replace	
	restore
	
	*- Applied STEM
	merge m:1 id_per_umc using `applied_stem_students', keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_stem_sib year_applied_stem_sib)
	
	*- Applied NOT IN STEM
	merge m:1 id_per_umc using `applied_nstem_students', keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_nstem_sib year_applied_nstem_sib)	
	
	*- Enrolled STEM
	merge m:1 id_per_umc using `enrolled_stem_students', keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_stem_sib year_enrolled_stem_sib)
	
	*- Enrolled NOT IN STEM
	merge m:1 id_per_umc using `enrolled_nstem_students', keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enrolled_nstem_sib year_enrolled_nstem_sib)	
	
	rename (aux_id_per_umc id_per_umc) (id_per_umc id_per_umc_sib)
	*/
	//STEM
	gen stem_major = inlist(major_c1_cat,5,6,7)
	

	//rename math_secondary* gpa_m*
	//rename comm_secondary* gpa_c*
	di "ASSERT"
	//assert 1==0
	foreach var in  "grade"  /*"gpa_m" "gpa_c"*/ "std_gpa_m" "std_gpa_c" "std_pred_gpa_m_ie_y" "std_pred_gpa_c_ie_y" "approved" "approved_first" /*"change_ie" */ {
		
		*- Post outcomes
		forvalues t = 0(1)3 {
			gen 		`var'_a`t'_sib = .
			
			foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
				if inlist("`var'","std_gpa_m","std_gpa_c", "std_pred_gpa_m_ie_y", "std_pred_gpa_c_ie_y")==1 & "`y'"=="2023" continue
				replace `var'_a`t'_sib = `var'_`y'_sib if year_applied_foc+`t' == `y'
				//if "`var'" != "grade" replace `var'_a`t'_sib = . if grade_a`t'_sib<7
			}
		}
		
		*- Pre outcomes
		forvalues t = 1(1)2 {
			gen 		`var'_b`t'_sib = .
			
			foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
				if inlist("`var'","std_gpa_m","std_gpa_c", "std_pred_gpa_m_ie_y", "std_pred_gpa_c_ie_y")==1 & "`y'"=="2023" continue
				replace `var'_b`t'_sib = `var'_`y'_sib if year_applied_foc-`t' == `y'
					//replace `var'_b`t'_sib = . if grade_b`t'_sib<7
			}
		}
	}
	
	forvalues g = 7(1)11 {
		foreach var in  "std_gpa_m" "std_gpa_c" "std_pred_gpa_m_ie_y" "std_pred_gpa_c_ie_y" "approved" "approved_first"  {
			forvalues t = 0(1)3 {
				gen 		`var'_`g'_a`t'_sib = `var'_a`t'_sib if grade_a`t'_sib == `g'
			}
		}
	}
		
		
	*- Student sample
	bys id_per_umc id_cutoff: gen student=_n==1 // Use applicant database instead of applicant-sibling database
		
	*- Fixed Effects
	egen FE_cm = group(codigo_modular major_c1_inei_code)
	egen FE_y = group(semester_foc)	
	
	*- Timing of application vars
	capture drop year_applied_foc_*
	tab year_applied_foc, gen(year_applied_foc_)
	
	tab semester_foc, gen(semester_foc_)
	
	gen term = substr(semester_foc,6,1)
	destring term, replace		
	
	compress

end


********************************************************************************
* Prepare RD
********************************************************************************
capture program drop prepare_rd
program define prepare_rd

	estimates drop _all

	*- Only through exam (and academy?)
	keep if type_admission==1
	
	*- Public schools
	keep if public_foc==1

	*- Exclude those without estimated cutoffs
	keep if lottery_nocutoff == 0

	*- Exclude those at cutoff
	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)		
	keep if not_at_cutoff==1
	
	*- Exclude those without sibling
	drop if any_sib_match==0
	
	*- Only those that apply once
	//keep if one_application==1
	

	*- Create sample of (i) 1 obs per student, (ii) one per year (iii) oldest sibling (iv) Those whose sibling could've applied
		bys id_persona_rec (semester_foc): gen byte sample_first_semester_app = semester_foc == semester_foc[1] 
		sort id_persona_rec semester_foc age, stable 
		gen n = _n
		bys id_persona_rec (semester_foc age n): gen sample_first_app = (_n==1) //there is some randomness, so we use n for replication.
		drop n

		//gen sample_oldest = (fam_order_${fam_type} == 1)

		gen sample_applied_sib = (exp_graduating_year1_sib>=2016 & exp_graduating_year1_sib<=2022 & exp_graduating_year1_sib+1>year_applied_foc)
	
	*- Only oldest brother
	//keep if sample_oldest==1 

	
	
	
	
	//averages of enrolled university ###121
	/*
	rename semester_foc semester
	merge m:1 universidad semester using "$OUT\application_averages", keepusing(*_avg_uni) keep(master match)
	rename semester semester_foc 
	*/
	
		
	//Dividing sample by likelihood
	sum enrolled_lpred1_foc, de
	gen byte h_simpf = (enrolled_lpred1_foc>r(p50)) if enrolled_lpred1_foc!=.
	sum enrolled_lpred3_foc, de
	gen byte h_fullf = (enrolled_lpred3_foc>r(p50)) if enrolled_lpred3_foc!=.	
	sum enrolled_lpred1_sib, de
	gen byte h_simps = (enrolled_lpred1_sib>r(p50)) if enrolled_lpred1_sib!=.	
	sum enrolled_lpred3_sib, de
	gen byte h_fulls = (enrolled_lpred3_sib>r(p50)) if enrolled_lpred3_sib!=.	
	

	//Dividing sample by mother&father education
	gen parent_highered = 0 
	replace parent_highered = 1 if inlist(educ_mother,6,7,8)
	replace parent_highered = 1 if inlist(educ_father,6,7,8)
	rename parent_highered h_pared
	
	//Dividing sample by scores
	sum score_acad_std_2s_sib, de
	gen byte above_acad = (score_acad_std_2s_sib>r(p50)) if score_acad_std_2s_sib!=.
	rename above_acad h_acad
	
	
	//Dividing sample by SES
	gen byte above_ses = (inlist(socioec_index_cat_all_sib,3,4)) if socioec_index_cat_all_sib!=.
	rename above_ses h_ses
	
	//Dividing sample by sex of Focal
	clonevar h_malef = male_siagie_foc
	
	//Dividing sample by sex of sibling
	clonevar h_males = male_siagie_sib
	
	//Dividing sample by public school
	clonevar h_pubs = public_siagie_sib
	
	//Dividing sample by same_sex
	gen same_sex = (male_siagie_foc==male_siagie_sib)
	rename same_sex h_ssex
	
	//Dividing sample by age gap
	replace age_gap = . if age_gap<=0
	gen h_gap = (age_gap>3) & age_gap!=.
	
	//Dividing sample by siblings who share school
	gen same_ie = 0
	replace same_ie = 1 if id_ie_sec_foc == id_ie_sec_sib
	replace same_ie = 1 if id_ie_pri_foc == id_ie_pri_sib
	rename same_ie h_sie

	//Dividing sample by urban/rural
	
	//Dividing sample for STEM-sex of sibling (by sex of focal)
	gen h_stem_sm = .
	replace h_stem_sm = 0 if stem_major==1 & male_siagie_sib==1 & male_siagie_foc==0
	replace h_stem_sm = 1 if stem_major==1 & male_siagie_sib==1 & male_siagie_foc==1
	
	gen h_stem_sf = .
	replace h_stem_sf = 0 if stem_major==1 & male_siagie_sib==0 & male_siagie_foc==0
	replace h_stem_sf = 1 if stem_major==1 & male_siagie_sib==0 & male_siagie_foc==1	
	
	gen h_nstem_sm = .
	replace h_nstem_sm = 0 if stem_major==0 & male_siagie_sib==1 & male_siagie_foc==0
	replace h_nstem_sm = 1 if stem_major==0 & male_siagie_sib==1 & male_siagie_foc==1
	
	gen h_nstem_sf = .
	replace h_nstem_sf = 0 if stem_major==0 & male_siagie_sib==0 & male_siagie_foc==0
	replace h_nstem_sf = 1 if stem_major==0 & male_siagie_sib==0 & male_siagie_foc==1		
	
	
	
	//Covariates used
	global scores_1 		= "score_relative_1"
	global ABOVE_scores_1 	= "ABOVE_score_relative_1"

	global scores_2			= "score_relative_1 		score_relative_2"
	global ABOVE_scores_2 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2"


	global scores_3 		= "score_relative_1 		score_relative_2 		score_relative_3"
	global ABOVE_scores_3 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2 	ABOVE_score_relative_3"

	global scores_5 		= "score_relative_1 		score_relative_2 		score_relative_3 		score_relative_4 		score_relative_5"
	global ABOVE_scores_5 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2 	ABOVE_score_relative_3 	ABOVE_score_relative_4 	ABOVE_score_relative_5"
	
	global controls = "" //"male o18.age" //omitted variable (constant) is at age 18.


end



********************************************************************************
* Condition for sample in regression
********************************************************************************

capture program drop if_condition
program define if_condition


		global if_sibs = ""
		global if_apps = ""
		global if_rel_app = ""
		global if_out = ""
		global if_pre = ""
		
		*- Stack
		if "${stack}" == "student" 	global if_stack "student==1" //will be filtered by relative to application
		
		if "${stack}" == "student_sibling" 	global if_stack "1==1"

		* Sibling sample
		if "${siblings}" == "all"				global if_sibs "1==1" //will be filtered by relative to application
		if "${siblings}" == "oldest"			global if_sibs "fam_order_${fam_type} == 1"
		if "${siblings}" == "older"				global if_sibs "fam_order_${fam_type} < fam_order_${fam_type}_sib"
	
		if "${siblings}" == "all_placebo"		global if_sibs "1==1" //will be filtered by relative to application
		if "${siblings}" == "oldest_placebo"	global if_sibs "fam_order_${fam_type}_sib == 1"
		if "${siblings}" == "youngest_placebo"	global if_sibs "fam_order_${fam_type}_sib == 1"
		if "${siblings}" == "older_placebo"		global if_sibs "fam_order_${fam_type}_sib < fam_order_${fam_type}"		

		* Applications sample
		if "${sem}" == "one" 			global if_apps "one_application==1"
		if "${sem}" == "first" 			global if_apps "first_application_sem==1"
		if "${sem}" == "first_type" 	global if_apps "first_application_sem_type==1"
		if "${sem}" == "first_sem_out" 	global if_apps "(last_year_foc + 1 == year_applied_foc) & term==1" 	//First semester after finishing school.
		if "${sem}" == "first_year_out" global if_apps "(last_year_foc + 1 == year_applied_foc)" //First semester after finishing school.
		if "${sem}" == "all" 			global if_apps "1==1"
		
		if inlist("${sem}","one","first","all","first_sem_out","first_year_out")==0  assert 1==0
		
		* Sample relative to application period (after (outcome) or before (placebo))
		if "${rel_app}" == "all"		global if_rel_app "1==1"
		
		local gap_after = 0
		local gap_before = 2
		
		local expected_grad_sib = "exp_graduating_year1_sib"
		
		if "${rel_app}" == "restrict" & inlist("${siblings}","all","oldest","older")==1		{ //If actual outcome, then restriction is for after
			global if_rel_app = "1==1"
			if substr("${outcome}",1,3) == "gpa" 				global if_rel_app "1==1" //Already using 'next'
			if substr("${outcome}",1,7) == "std_gpa" 			global if_rel_app "1==1" //Already using 'next'
			if substr("${outcome}",1,12) == "std_pred_gpa" 		global if_rel_app "1==1" //Already using 'next'
			if substr("${outcome}",-6,6) == "2p_sib"  			global if_rel_app "year_2p_sib>=year_applied_foc" // Interested in cases where spillover sibling takes exam after focal application (often application is at the beginning of year so same year works). 
			if substr("${outcome}",-6,6) == "4p_sib"  			global if_rel_app "year_4p_sib>=year_applied_foc"
			if substr("${outcome}",-6,6) == "2s_sib"  			global if_rel_app "year_2s_sib>=year_applied_foc"
			if substr("${outcome}",-6,6) == "2p_sib"  			global if_rel_app "year_2p_sib>=year_applied_foc"
			if strmatch("${outcome}","sec_grad*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_applied_foc)" // Reference is when focal applies same year the other graduates (is ahead). Interested in cases where spillover sibling at least graduates same year  graduates at least on the same year as focal child (application would be after)
			if strmatch("${outcome}","applied*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_applied_foc)" // Reference is when focal applies same year the other graduates (is ahead). Interested in cases where spillover sibling at least graduates same year  graduates at least on the same year as focal child (application would be after)
			if strmatch("${outcome}","admitted*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_applied_foc)"
			if strmatch("${outcome}","enroll*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_applied_foc)"
			if strmatch("${outcome}","applies_on_time*sib")==1	global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_applied_foc)"
			if strmatch("${outcome}","enrolls_on_time*sib")==1	global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_applied_foc)"
			if strmatch("${outcome}","N_app*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_applied_foc)"
			if strmatch("${outcome}","score_std*sib")==1		global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_applied_foc)"
			if strmatch("${outcome}","avg_enr_score*sib")==1	global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_applied_foc)"
			if strmatch("${outcome}","enrolled_*year*sib")==1	global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_applied_foc)"
			if strmatch("${outcome}","graduated_sib")==1		global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_applied_foc)"

		}
		
		if "${rel_app}" == "restrict" & inlist("${siblings}","all_placebo","oldest_placebo","older_placebo")==1		{ //If placebo outcome, then restriction is for before
			if substr("${outcome}",-6,6) == "2p_sib"  			global if_rel_app "year_2p_sib<year_applied_foc" // Interested in cases where spillover sibling takes exam before focal application
			if substr("${outcome}",-6,6) == "4p_sib"  			global if_rel_app "year_4p_sib<year_applied_foc"
			if substr("${outcome}",-6,6) == "2s_sib"  			global if_rel_app "year_2s_sib<year_applied_foc"
			if substr("${outcome}",-6,6) == "2p_sib"  			global if_rel_app "year_2p_sib<year_applied_foc"
			if strmatch("${outcome}","sec_grad*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_before'<year_applied_foc)" // Interested in cases where spillover sibling graduates and has time to apply before focal child.
			if strmatch("${outcome}","admitted*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_before'<year_applied_foc)" // Interested in cases where spillover sibling graduates and has time to apply before focal child.
			if strmatch("${outcome}","applied*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_before'<=year_applied_foc)"
			if strmatch("${outcome}","enroll*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_before'<=year_applied_foc)"
			if strmatch("${outcome}","applies_on_time*sib")==1	global if_rel_app "(`expected_grad_sib'+`gap_before'<=year_applied_foc)"
			if strmatch("${outcome}","enrolls_on_time*sib")==1	global if_rel_app "(`expected_grad_sib'+`gap_before'<=year_applied_foc)"
			if strmatch("${outcome}","N_app*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_before'<=year_applied_foc)"
			if strmatch("${outcome}","score_std*sib")==1		global if_rel_app "(`expected_grad_sib'+`gap_before'<=year_applied_foc)"
			if strmatch("${outcome}","avg_enr_score*sib")==1	global if_rel_app "(`expected_grad_sib'+`gap_before'<=year_applied_foc)"
		}
		
		

		* Sample when outcome is relevant
		//Balance
		if "${outcome}" == "male_foc" 					global if_out "1==1"
		if "${outcome}" == "age" 						global if_out "1==1"
		if "${outcome}" == "higher_ed_mother" 			global if_out "1==1"
		if "${outcome}" == "vlow_ses_foc" 				global if_out "1==1"
		if "${outcome}" == "score_math_std_2p_foc" 		global if_out "1==1"		
		if "${outcome}" == "score_com_std_2p_foc" 		global if_out "1==1"
		if "${outcome}" == "score_acad_std_2p_foc" 		global if_out "1==1"
		if "${outcome}" == "score_math_std_2s_foc" 		global if_out "1==1"		
		if "${outcome}" == "score_com_std_2s_foc" 		global if_out "1==1"
		if "${outcome}" == "score_acad_std_2s_foc" 		global if_out "1==1"	
		
		//First Stage
		if "${outcome}" == "admitted_foc" 					global if_out "1==1"
		if "${outcome}" == "enr_uni_major_sem_foc" 			global if_out "1==1"
		if "${outcome}" == "enrolled_sem_foc" 				global if_out "1==1"		
		if "${outcome}" == "enrolled_uni_major_foc" 		global if_out "1==1"		
		if "${outcome}" == "enrolled_uni_sem_foc" 			global if_out "1==1"		
		if "${outcome}" == "enrolled_uni_foc" 				global if_out "1==1"		
		if "${outcome}" == "enrolled_foc" 					global if_out "1==1"
		if "${outcome}" == "enrolled_public_foc" 			global if_out "1==1"
		if "${outcome}" == "enrolled_private_foc" 			global if_out "1==1"
		if "${outcome}" == "enrolled_public_o_foc" 			global if_out "1==1"
		
		//Focal child outcomes
		if "${outcome}" == "enrolled_1year_foc" 			global if_out "year_applied_foc<=2022"	//Enough years to graduate
		if "${outcome}" == "enrolled_2year_foc" 			global if_out "year_applied_foc<=2021"	//Enough years to graduate
		if "${outcome}" == "enrolled_3year_foc" 			global if_out "year_applied_foc<=2020"	//Enough years to graduate
		if "${outcome}" == "enrolled_4year_foc" 			global if_out "year_applied_foc<=2019"	//Enough years to graduate
		if "${outcome}" == "graduated_foc" 					global if_out "year_applied_foc<=2019"	//Enough years to graduate

		
		//Peer Quality
		if "${outcome}" == "peer_score_math_std_2p_foc" 	global if_out "1==1"
		if "${outcome}" == "peer_score_com_std_2p_foc" 		global if_out "1==1"
		if "${outcome}" == "peer_score_acad_std_2p_foc" 	global if_out "1==1"
		if "${outcome}" == "peer_score_math_std_2s_foc" 	global if_out "1==1"
		if "${outcome}" == "peer_score_com_std_2s_foc" 		global if_out "1==1"
		if "${outcome}" == "peer_score_acad_std_2s_foc" 	global if_out "1==1"	
		if "${outcome}" == "peer_graduated_uni_ever_foc" 		global if_out "1==1"	
		if "${outcome}" == "peer_graduated_uni_5_foc" 			global if_out "1==1"	
		if "${outcome}" == "peer_graduated_uni_6_foc" 			global if_out "1==1"	
		
		//school performance
		if "${outcome}" == "score_math_std_2p_sib" 		global if_out "year_2p_sib!=."
		if "${outcome}" == "score_acad_std_2p_sib" 		global if_out "year_2p_sib!=."
		if "${outcome}" == "score_com_std_2p_sib" 		global if_out "year_2p_sib!=."
		if "${outcome}" == "score_math_std_4p_sib" 		global if_out "year_4p_sib!=."
		if "${outcome}" == "score_com_std_4p_sib" 		global if_out "year_4p_sib!=."
		if "${outcome}" == "score_acad_std_4p_sib" 		global if_out "year_4p_sib!=."
		if "${outcome}" == "score_math_std_2s_sib" 		global if_out "year_2s_sib!=."
		if "${outcome}" == "score_com_std_2s_sib" 		global if_out "year_2s_sib!=."
		if "${outcome}" == "score_acad_std_2s_sib" 		global if_out "year_2s_sib!=."
		if "${outcome}" == "gpa_m_b2_sib" 			global if_out "1==1"
		if "${outcome}" == "gpa_m_b1_sib" 			global if_out "1==1"
		if "${outcome}" == "gpa_m_a0_sib" 			global if_out "1==1"
		if "${outcome}" == "gpa_m_a1_sib" 			global if_out "1==1"
		if "${outcome}" == "gpa_m_a2_sib" 			global if_out "1==1"
		if "${outcome}" == "gpa_c_b2_sib" 			global if_out "1==1"
		if "${outcome}" == "gpa_c_b1_sib" 			global if_out "1==1"
		if "${outcome}" == "gpa_c_a0_sib" 			global if_out "1==1"
		if "${outcome}" == "gpa_c_a1_sib" 			global if_out "1==1"	
		if "${outcome}" == "gpa_c_a2_sib" 			global if_out "1==1"	
		if "${outcome}" == "std_gpa_m_b2_sib" 		global if_out "1==1"
		if "${outcome}" == "std_gpa_m_b1_sib" 		global if_out "1==1"
		if "${outcome}" == "std_gpa_m_a0_sib" 		global if_out "1==1"
		if "${outcome}" == "std_gpa_m_a1_sib" 		global if_out "1==1"
		if "${outcome}" == "std_gpa_m_a2_sib" 		global if_out "1==1"
		if "${outcome}" == "std_gpa_c_b2_sib" 		global if_out "1==1"
		if "${outcome}" == "std_gpa_c_b1_sib" 		global if_out "1==1"
		if "${outcome}" == "std_gpa_c_a0_sib" 		global if_out "1==1"
		if "${outcome}" == "std_gpa_c_a1_sib" 		global if_out "1==1"			
		if "${outcome}" == "std_gpa_c_a2_sib" 		global if_out "1==1"
		if substr("${outcome}",1,3)=="gpa" 				global if_out "1==1"
		if substr("${outcome}",1,7)=="std_gpa" 			global if_out "1==1"
		if substr("${outcome}",1,7)=="has_gpa" 			global if_out "1==1"
		if substr("${outcome}",1,12) == "std_pred_gpa" 	global if_out "1==1" 
		//school progression
		if "${outcome}" == "approved_b2_sib" 		global if_out "1==1"
		if "${outcome}" == "approved_b1_sib" 		global if_out "1==1"
		if "${outcome}" == "approved_a0_sib" 		global if_out "1==1"
		if "${outcome}" == "approved_a1_sib" 		global if_out "1==1"
		if "${outcome}" == "approved_a2_sib" 		global if_out "1==1"
		if "${outcome}" == "dropout_ever_sib" 			global if_out "1==1"
		if "${outcome}" == "sec_grad_sib" 				global if_out "(exp_graduating_year2_sib+1>=2017 & exp_graduating_year2_sib+1<=2023)" //In this case we use 'exp_graduating_year2_sib' instead of 'exp_graduating_year1_sib' cause it  proxies better what we want to measure: who should be already graduated from high school rather than choices in applications (for which we want them to have finished school. Is that endogenous for the other case?)		
		
		//Aspirations and survey measures
		if "${outcome}" == "comp_sec_4p_sib"  			global if_out "year_4p_sib!=."
		if "${outcome}" == "any_coll_4p_sib"  			global if_out "year_4p_sib!=."
		if "${outcome}" == "asp_college2_4p_sib"  		global if_out "year_4p_sib!=."
		if "${outcome}" == "asp_college4_4p_sib"  		global if_out "year_4p_sib!=."
		if "${outcome}" == "asp_years_4p_sib"  			global if_out "year_4p_sib!=."
		if "${outcome}" == "any_coll_2s_sib"  			global if_out "year_2s_sib!=."
		if "${outcome}" == "asp_college2_2s_sib"  		global if_out "year_2s_sib!=."
		if "${outcome}" == "asp_college4_2s_sib"  		global if_out "year_2s_sib!=."
		if "${outcome}" == "asp_years_2s_sib"  			global if_out "year_2s_sib!=."
	
		//Gender beliefs
		if "${outcome}" == "std_belief_gender_boy_4p_sib"  		global if_out "year_4p_sib!=."
		if "${outcome}" == "std_belief_gender_girl_4p_sib"  	global if_out "year_4p_sib!=."
		if "${outcome}" == "std_belief_gender_4p_sib"  			global if_out "year_4p_sib!=."
		
		//university	
		if "${outcome}" == "applied_sib"  					global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "admitted_sib"  					global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "enrolled_sib"  					global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"	
		if "${outcome}" == "applies_on_time_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "enrolls_on_time_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "N_applications_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "N_applications_first_sib" 		global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "N_applications_uni_sib" 		global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "score_std_all_u_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "score_std_uni_u_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "score_std_uni_o_u_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "score_std_pub_u_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "score_std_pub_o_u_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "score_std_all_f_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "score_std_uni_f_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "score_std_uni_o_f_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "score_std_pub_f_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "score_std_pub_o_f_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"		
		
		//if "${outcome}" == "score_std_major_avg_sib" 		global if_out "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_applied_foc)"

		if "${outcome}" == "avg_enr_score_math_std_2p_sib" 	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "avg_enr_score_com_std_2p_sib" 	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "avg_enr_score_acad_std_2p_sib" 	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "avg_enr_score_math_std_2s_sib" 	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "avg_enr_score_com_std_2s_sib" 	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "avg_enr_score_acad_std_2s_sib" 	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		
		
		//Persistence sibling outcomes
		if "${outcome}" == "enrolled_1year_sib" 			global if_out "`expected_grad_sib'+1<=2022"	//Enough years to graduate
		if "${outcome}" == "enrolled_2year_sib" 			global if_out "`expected_grad_sib'+1<=2021"	//Enough years to graduate
		if "${outcome}" == "enrolled_3year_sib" 			global if_out "`expected_grad_sib'+1<=2020"	//Enough years to graduate
		if "${outcome}" == "enrolled_4year_sib" 			global if_out "`expected_grad_sib'+1<=2019"	//Enough years to graduate
		if "${outcome}" == "graduated_sib" 					global if_out "`expected_grad_sib'+1<=2019"	//Enough years to graduate		
		
		//Application choices
		if "${outcome}" == "applied_public_sib" 		global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "applied_uni_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "applied_public_o_sib" 		global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "applied_private_sib" 		global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		
		if "${outcome}" == "enrolled_uni_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "applied_uni_major_sib"  	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "enrolled_uni_major_sib"  		global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "applied_major_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "enrolled_major_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		
		//STEM*/
		if "${outcome}" == "applied_stem_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "applied_nstem_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "enrolled_stem_sib"  			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "enrolled_uni_major_sib"  		global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"	
	
	
	*- Consider all restrictions for sample of interest
	global if_pre "${if_stack} & ${if_sibs} & ${if_rel_app} & ${if_apps} & ${if_out} & ${if_add}"
		

end		
	
	
	

********************************************************************************
* Histogram
********************************************************************************
capture program drop histogram_score
program define histogram_score 

	args fam_type sem stack window
	
	estimates drop _all

	global fam_type = `fam_type'
	global sem = "`sem'"
		
	use "$OUT/applied_outcomes_${fam_type}${data}.dta", clear
	
	//gen any_sib_match = (region_siagie_sib!=.)

	additional_vars 	noz major
	prepare_rd 			
	
	if "`stack'" == "student" 			bys id_per_umc id_cutoff: keep if _n==1 // Use applicant database instead of applicant-sibling database
	if "`stack'" == "student_sibling" 	keep if 1==1 // Use applicant-sibling database

	histogram score_relative ///
	if abs(score_relative)<`window' ///
	,  ///
	bins(40) ///
	fcolor(gs14) lcolor(gs0) xline(0, lcolor(red)) /*title("All cutoffs")*/ xtitle("Standardized score relative to cutoff")	 ///
	name(histogram_${sem}, replace)
	if ${test_C02} == 0 {
	graph export 	"$FIGURES/eps/histogram_`stack'_wide_${sem}.eps", replace	
	graph export 	"$FIGURES/png/histogram_`stack'_wide_${sem}.png", replace	
	graph export 	"$FIGURES/pdf/histogram_`stack'_wide_${sem}.pdf", replace	
	}
	

	histogram score_relative ///
	if abs(score_relative)<`window' ///
	,  ///
	bins(300) ///
	fcolor(gs14) lcolor(gs0) xline(0, lcolor(red)) /*title("All cutoffs")*/ xtitle("Standardized score relative to cutoff")	 ///
	name(histogram_${sem}, replace)
	if ${test_C02} == 0 {
	graph export 	"$FIGURES/eps/histogram_`stack'_thin_${sem}.eps", replace	
	graph export 	"$FIGURES/png/histogram_`stack'_thin_${sem}.png", replace	
	graph export 	"$FIGURES/pdf/histogram_`stack'_thin_${sem}.pdf", replace	
	}	

end

	
	

********************************************************************************
* McCrary
********************************************************************************
capture program drop mccrary
program define mccrary 

	args fam_type sem stack kernel window

	estimates drop _all

	global fam_type = `fam_type'
	global sem = "`sem'"
	
	local label_window = int(`window'*10)
		
	use "$OUT/applied_outcomes_${fam_type}${data}.dta", clear
	
	//gen any_sib_match = (region_siagie_sib!=.)

	additional_vars 	noz major
	prepare_rd 			
	
	if "`stack'" == "student" 			bys id_per_umc id_cutoff: keep if _n==1 // Use applicant database instead of applicant-sibling database
	if "`stack'" == "student_sibling" 	keep if 1==1 // Use applicant-sibling database

	

*- 1. Using default p() and q()	
	// Get the estimate
rddensity score_relative ///
	if abs(score_relative)<`window' ///
	, ///
	c(0) ///
	///p(1) /// are these required for mccrary? Or just for estimating outcomes? ###
	///q(2) ///
	kernel(`kernel') ///
	all 
	
local pval: display %9.3f e(pv_q)  

// Plot the estimate directly (otherwise, it will use the previously stored e(pv_q))
rddensity score_relative ///
	if abs(score_relative)<`window' ///
	, ///
	graph_opt(xtitle("Standardized score relative to cutoff") legend(off) note("McCrary Test p-val: 0.`pval'")) ///
	c(0) ///
	///p(1) /// are these required for mccrary? Or just for estimating outcomes? ###
	///q(2) ///
	kernel(`kernel') ///
	all ///
	plot
	if ${test_C02} == 0 {	
	graph export 	"$FIGURES/eps/mccrary_`stack'_`label_window'_`kernel'_${sem}.eps", replace	
	graph export 	"$FIGURES/png/mccrary_`stack'_`label_window'_`kernel'_${sem}.png", replace	
	graph export 	"$FIGURES/pdf/mccrary_`stack'_`label_window'_`kernel'_${sem}.pdf", replace	
	}
	
	//global mccrary_pval_${sem} = e(pv_q)
	
*- 2. Using default p=q so that bounds are centered around point estimate	
	// Get the estimate
rddensity score_relative ///
	if abs(score_relative)<`window' ///
	, ///
	c(0) ///
	p(2) /// are these required for mccrary? Or just for estimating outcomes? ###
	///q(2) ///
	kernel(`kernel') ///
	all 
	
local pval: display %9.3f e(pv_q)  

// Plot the estimate directly (otherwise, it will use the previously stored e(pv_q))
rddensity score_relative ///
	if abs(score_relative)<`window' ///
	, ///
	graph_opt(xtitle("Standardized score relative to cutoff") legend(off) note("McCrary Test p-val: 0.`pval'")) ///
	c(0) ///
	p(2) /// are these required for mccrary? Or just for estimating outcomes? ###
	///q(2) ///
	kernel(`kernel') ///
	all ///
	plot
	if ${test_C02} == 0 {	
	graph export 	"$FIGURES/eps/mccrary_`stack'_`label_window'_`kernel'_${sem}_cent.eps", replace	
	graph export 	"$FIGURES/png/mccrary_`stack'_`label_window'_`kernel'_${sem}_cent.png", replace	
	graph export 	"$FIGURES/pdf/mccrary_`stack'_`label_window'_`kernel'_${sem}_cent.pdf", replace	
	}	
end





********************************************************************************
* First Stage - Test
********************************************************************************
capture program drop first_stage_test
program define first_stage_test

	args fam_type cell sem stack results

	estimates drop _all

	global fam_type = 2
	global sem = "first"
	local stack = "student_sibling"
	local results = "main"
	
	global main_sibling_sample = "oldest"
	global main_rel_app = "restrict"
	global main_term = "first"
	global main_bw = "optimal"
	global main_covs_rdrob = "semester_foc" //semester_foc
		
	
		
	use "$OUT/applied_outcomes_${fam_type}${data}.dta", clear
	
	
	merge m:1 id_cutoff_major using "$TEMP/applied_cutoffs_major.dta", keepusing(type_admission) keep(master match)

	additional_vars 	noz `cell'
	prepare_rd 			
	
	if "`stack'" == "student" 			bys id_per_umc id_cutoff: keep if _n==1 // Use applicant database instead of applicant-sibling database
	if "`stack'" == "student_sibling" 	keep if 1==1 // Use applicant-sibling database
	if "`stack'" == ""					keep if 1==1 
	
	
	preserve 
		//keep if type_admission==1
		*- Outcomes
		estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enr_uni_major_sem_foc 	/*label*/ test  /*sibling*/ older /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ semester_foc
	restore
	
	preserve 
		keep if type_admission==2
		*- Outcomes
		estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enr_uni_major_sem_foc 	/*label*/ test  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	restore	
	*- First Stage
	local var = "admitted_foc"	
	binsreg `var' score_relative if abs(score_relative)<${window}, ///
		nbins(100) ///
		xline(0) ///
		ylabel(0(.2)1) ///
		ytitle("`ytitle'") ///
		xtitle("Relative Application Exam Score") ///
		xsize(5.5) ///
		ysize(5) ///
		by(ABOVE) ///
		bycolors(gs0 gs0) ///
		bysymbols(o o) ///
		legend(off) ///
		name(fs_`var', replace)

	*- Histogram
	twoway (histogram score_relative if type_admission ==1)
	twoway (histogram score_relative if type_admission ==2)
	twoway (histogram score_relative if type_admission ==3)		
	twoway (histogram score_relative if type_admission ==4)
	twoway (histogram score_relative if type_admission ==8)
			
	
	
end



********************************************************************************
* First Stage
********************************************************************************
capture program drop first_stage
program define first_stage

	args fam_type cell sem stack results

	estimates drop _all

	global fam_type = `fam_type'
	global main_cell = "`cell'"
	global sem = "`sem'"
		
	use "$OUT/applied_outcomes_${fam_type}${data}.dta", clear

	additional_vars 	noz ${main_cell}
	prepare_rd 			
	
	if "`stack'" == "student" 			bys id_per_umc id_cutoff: keep if _n==1 // Use applicant database instead of applicant-sibling database
	if "`stack'" == "student_sibling" 	keep if 1==1 // Use applicant-sibling database
	if "`stack'" == ""					keep if 1==1 
	
	if "`results'" == "main" {
		
		foreach var in "admitted_foc" "enr_uni_major_sem_foc" "enrolled_uni_sem_foc" "enrolled_sem_foc" "enrolled_uni_foc" "enrolled_public_o_foc" "enrolled_private_foc" "enrolled_foc" {
			
		if "`var'" == "admitted_foc" 					local ytitle = "Admitted"	
		if "`var'" == "enr_uni_major_sem_foc" 			local ytitle = "Enrolled"
		if "`var'" == "enrolled_uni_sem_foc" 			local ytitle = "Enrolled in target college"
		if "`var'" == "enrolled_sem_foc" 				local ytitle = "Enrolled in any college"
		if "`var'" == "enrolled_uni_foc" 				local ytitle = "Enrolled in target college ever"
		if "`var'" == "enrolled_public_o_foc" 			local ytitle = "Enrolled in other public college ever"		
		if "`var'" == "enrolled_private_foc" 			local ytitle = "Enrolled in private college ever"
		if "`var'" == "enrolled_foc" 					local ytitle = "Enrolled in any college ever"		
		
		binsreg `var' score_relative if abs(score_relative)<${window}, ///
			nbins(100) ///
			xline(0) ///
			ylabel(0(.2)1) ///
			ytitle("`ytitle'") ///
			xtitle("Relative Application Exam Score") ///
			xsize(5.5) ///
			ysize(5) ///
			by(ABOVE) ///
			bycolors(gs0 gs0) ///
			bysymbols(o o) ///
			legend(off) ///
			name(fs_`var', replace)
			
		if ${test_C02} == 0 {
			graph export 	"$FIGURES/eps/first_stage_${main_cell}_`var'.eps", replace	
			graph export 	"$FIGURES/png/first_stage_${main_cell}_`var'.png", replace	
			graph export 	"$FIGURES/pdf/first_stage_${main_cell}_`var'.pdf", replace	
			}	

		}
	}
	
	
	//Counterfactuals
	estimates restore rf_admitted_foc
	local admitted_foc = _b[ABOVE]
	estimates restore rf_enr_uni_major_sem_foc
	local enrolled_same_sem_uni = _b[ABOVE]
	estimates restore rf_enrolled_uni_foc
	local enrolled_uni = _b[ABOVE]
	estimates restore rf_enrolled_private_foc
	local enrolled_private = _b[ABOVE]
	estimates restore rf_enrolled_foc
	local enrolled_ever = _b[ABOVE]
	
	
	di `admitted_foc' _n `enrolled_same_sem_uni' _n `enrolled_uni' _n `enrolled_private' _n `enrolled_ever'
	
	// By R2
	
	if "`results'" == "R2" {
		gen R2_cat = .
		replace R2_cat = 1 if R2<0.7
		replace R2_cat = 2 if R2>=0.7 & R2<0.9
		replace R2_cat = 3 if R2>=0.9 & R2!=.

		forvalues i = 1/3 {
			preserve
				keep if R2_cat == `i'
				
				binsreg admitted_foc score_relative if abs(score_relative)<${window}, ///
				nbins(100) ///
				xline(0) ///
				ylabel(0(.2)1) ///
				ytitle("Admitted") ///
				xtitle("Relative Application Exam Score") ///
				xsize(5.5) ///
				ysize(5) ///
				by(ABOVE) ///
				bycolors(gs0 gs0) ///
				bysymbols(o o) ///
				legend(off) ///
				name(fs_admitted_foc, replace)
				
				if ${test_C02} == 0 {
					graph export 	"$FIGURES/eps/first_stage_${main_cell}_admitted_R2_cat`i'.eps", replace	
					graph export 	"$FIGURES/png/first_stage_${main_cell}_admitted_R2_cat`i'.png", replace	
					graph export 	"$FIGURES/pdf/first_stage_${main_cell}_admitted_R2_cat`i'.pdf", replace
				}	
			estimate_reg /*OUTCOME*/ admitted_foc 					/*IV*/ none 	/*label*/ fs_admitted_R2`i' /*stack*/ student  	/*sibling*/ oldest /*relative to application*/ all /*semesters*/ first /*bw*/ optimal	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ triangular	/*FE*/ cm+y	
			estimate_reg /*OUTCOME*/ enr_uni_major_sem_foc 	/*IV*/ none 	/*label*/ fs_enrolled_R2`i'  /*stack*/ student 	/*sibling*/ oldest /*relative to application*/ all /*semesters*/ first /*bw*/ optimal	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ triangular	/*FE*/ cm+y		
			
			
			
			restore	
		}
		tables_pres_main 1 table_first_stage_R2
		
		
	}

	
	
end



********************************************************************************
* Visual balance test
********************************************************************************
capture program drop visual_balance
program define visual_balance

	args fam_type sem stack

	estimates drop _all

	global fam_type = `fam_type'
	global sem = "`sem'"
		
	use "$OUT/applied_outcomes_${fam_type}${data}.dta", clear

	additional_vars 	noz major
	prepare_rd 			
		
	if "`stack'" == "student" 			bys id_per_umc id_cutoff: keep if _n==1 // Use applicant database instead of applicant-sibling database
	if "`stack'" == "student_sibling" 	keep if 1==1 // Use applicant-sibling database
	
	binsreg score_math_std_2s_foc score_relative if abs(score_relative)<${window}, ///
		nbins(100) ///
		xline(0) ///
		ylabel(-1(.2)1) ///
		ytitle("8th grade Mathematics standardized score") ///
		xsize(5.5) ///
		ysize(5) ///
		///by(ABOVE) ///
		bycolors(gs0 gs0) ///
		bysymbols(o o) ///
		legend(off) ///
		name(fs_admitted_foc, replace)
	if ${test_C02} == 0 {
	graph export 	"$FIGURES/png/balance_math_2s.png", replace	
	graph export 	"$FIGURES/eps/balance_math_2s.eps", replace	
	graph export 	"$FIGURES/pdf/balance_math_2s.pdf", replace	
		}
	binsreg score_com_std_2s_foc score_relative if abs(score_relative)<${window}, ///
		nbins(100) ///
		xline(0) ///
		ylabel(-1(.2)1) ///
		ytitle("8th grade Reading standardized score") ///
		xtitle("Score relative to cutoff") ///
		xsize(5.5) ///
		ysize(5) ///
		///by(ABOVE) ///
		bycolors(gs0 gs0) ///
		bysymbols(o o) ///
		legend(off) ///
		name(fs_enr_uni_major_sem_foc, replace)
	if ${test_C02} == 0 {	
	graph export 	"$FIGURES/png/balance_com_2s.png", replace	
	graph export 	"$FIGURES/eps/balance_com_2s.eps", replace	
	graph export 	"$FIGURES/pdf/balance_com_2s.pdf", replace			
	}	
	binsreg score_acad_std_2s_foc score_relative if abs(score_relative)<${window}, ///
		nbins(100) ///
		xline(0) ///
		ylabel(-1(.2)1) ///
		ytitle("8th grade Academic standardized score") ///
		xsize(5.5) ///
		ysize(5) ///
		///by(ABOVE) ///
		bycolors(gs0 gs0) ///
		bysymbols(o o) ///
		legend(off) ///
		name(fs_enrolled_foc, replace)		
	if ${test_C02} == 0 {	
	graph export 	"$FIGURES/png/balance_acad_2s.png", replace	
	graph export 	"$FIGURES/eps/balance_acad_2s.eps", replace	
	graph export 	"$FIGURES/pdf/balance_acad_2s.pdf", replace	
	}
end

	




********************************************************************************
* Regressions for tables #####
********************************************************************************

capture program drop estimate_reg
program define estimate_reg

	args outcome iv label stack siblings rel_app semesters bw covs_rdrob kernel fe if_add x_vars
	
	global iv = "`iv'"	
	global fe = "`fe'"
	
	//Define outcome globally in case needed to pass (for 'if_condition')
	global outcome = "`outcome'"
	
	//Sample
	global stack = "`stack'"
	global siblings "`siblings'"
	global rel_app ="`rel_app'"
	global sem = "`semesters'"
	global bw_select "`bw'"
	
	//Extra for regression
	global x_vars = "`x_vars'"
	global if_add = "`if_add'"
	if "`if_add'"=="" global if_add = "1==1"
	
	//FE to use
	if "${fe}"=="cmy" 	global fe_used = "id_cutoff"
	if "${fe}"=="cm+y" 	global fe_used = "FE_cm FE_y"
	if "${fe}"=="cm" 	global fe_used = "FE_cm"
	if "${fe}"=="y" 	global fe_used = "FE_y"
	if "${fe}"=="nofe" 	global fe_used = ""
	

	*- Get "if" condition for each outcome
	if_condition // & h`heterog_type' == `likely_val'
	
	di "if_condition done" _n
	di as text "${outcome}"
  
	*- We get the optimal bandwidths
	if "${bw_select}" == "optimal" & "${iv}" != "none" 	{
		rdrobust ${outcome} score_relative if ${if_pre}, ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(`kernel') ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(${iv}) ///
		  covs(`covs_rdrob'_*) //  covs(year_applied_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
		  
		  global bw_${outcome} = e(h_l)
	}
	
	//For first stage, when not doing IV
	if "${bw_select}" == "optimal" &  "${iv}" == "none" 	{
		rdrobust ${outcome} score_relative if ${if_pre}, ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(`kernel') ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  covs(`covs_rdrob'_*) //  covs(year_applied_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
		  
		  global bw_${outcome} = e(h_l)
	}	
	
	if "${bw_select}" != "optimal" 			global bw_${outcome} = ${bw_select}	
	//if inlist("`likely_val'","0","1")==1 	global if_final "${if_pre} & h`heterog_type' == `likely_val'"
	//if inlist("`likely_val'","")==1 		global if_final "${if_pre}"				
	global if_final "${if_pre}"	

	di as text "OPTIMAL BANDWIDTH" ${bw_${outcome}}
	
	//global bw_${outcome} = 0.8894
	if "${fe}" != "nofe" {
	if "${iv}" != "none" {
	ivreghdfe ${outcome}  ${scores_1} ${ABOVE_scores_1} ${x_vars} (${iv} = ABOVE) ///  
			if ${if_final} ///
			& abs(score_relative)<${bw_${outcome}}, ///
			absorb(${fe_used}) cluster(id_fam_${fam_type}) ///
			first ffirst savefirst savefprefix(fs_)
			
			local fs = e(widstat)

			estadd ysumm //a group of descriptives of dependant variable
			estadd scalar bandwidth ${bw_${outcome}}
			estadd scalar fstage = `fs'
			estimates store iv_`label'
			
			//We save first stage estimate in case needed.
			estimates restore fs_${iv}
			estimates store fs_`label' //In case we need to rename
	}	
	*-- Reduced form 
	reghdfe ${outcome} ABOVE  ${scores_1} ${ABOVE_scores_1} ${x_vars} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(${fe_used}) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

		estadd ysumm
		estadd scalar bandwidth ${bw_${outcome}}
		estadd scalar FE e(df_a)
		if inlist("${outcome}","admitted_foc","enr_uni_major_sem_foc")==0 & "${iv}" != "none" estadd scalar fstage = `fs'
		estimates store rf_`label'
	}
	
	if "${fe}" == "nofe" {
			*-- Reduced form 
	reg ${outcome} ABOVE  ${scores_1} ${ABOVE_scores_1} ${x_vars} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

		estadd ysumm
		estadd scalar bandwidth ${bw_${outcome}}
		estadd scalar FE 0
		if inlist("${outcome}","admitted_foc","enr_uni_major_sem_foc")==0 & "${iv}" != "none" estadd scalar fstage = `fs'
		estimates store rf_`label'
	}

	//capture drop student
end


******

capture program drop estimate_reg_rf
program define estimate_reg_rf

	args outcome iv label siblings rel_app semesters bw percentile covs_rdrob kernel fe 
	
	global iv = "`iv'"	
	global fe = "`fe'"
	
	//Define outcome globally in case needed to pass (for 'if_condition')
	global outcome = "`outcome'"
	
	//Sample
	global siblings "`siblings'"
	global rel_app ="`rel_app'"
	global sem = "`semesters'"
	global bw_select "`bw'"
	
	//FE to use
	if "${fe}"=="cmy" 	global fe_used = "id_cutoff"
	if "${fe}"=="cm+y" 	global fe_used = "FE_cm FE_y"
	if "${fe}"=="cm" 	global fe_used = "FE_cm"
	if "${fe}"=="y" 	global fe_used = "FE_y"
	if "${fe}"=="nofe" 	global fe_used = ""
	
	
	
	*- ABOVE Variable: (for coefplot model)
	clonevar ABOVE`percentile' = ABOVE

	*- Get "if" condition for each outcome
	if_condition // & h`heterog_type' == `likely_val'
	
	di "if_condition done"
  
	*- We get the optimal bandwidths
	if "${bw_select}" == "optimal" 	{
		rdrobust ${outcome} score_relative if ${if_pre}, ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(`kernel') ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(${iv}) ///
		  covs(`covs_rdrob'_*) //  covs(year_applied_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
		  
		  global bw_${outcome} = e(h_l)
	}
	
	if "${bw_select}" != "optimal" 			global bw_${outcome} = ${bw_select}	
	//if inlist("`likely_val'","0","1")==1 	global if_final "${if_pre} & h`heterog_type' == `likely_val'"
	//if inlist("`likely_val'","")==1 		global if_final "${if_pre}"				
	global if_final "${if_pre}"

	di as text "OPTIMAL BANDWIDTH" ${bw_${outcome}}
	
			
	*-- Reduced form
	reghdfe ${outcome} ABOVE`percentile'  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(${fe_used}) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

		estadd ysumm
		estadd scalar bandwidth ${bw_${outcome}}
		estadd scalar FE e(df_a)
		
		estimates store rf_`label'

	drop ABOVE`percentile'
//
end


	
********************************************************************************
* Plot for RD sensitivity: Reduced form effects highlighting optimal bandwidth
********************************************************************************


capture program drop rd_sensitivity
program define rd_sensitivity

args outcome iv label stack siblings rel_app semesters bw covs_rdrob kernel fe 
	
	
	*- Remove preexisting variables
	capture drop ABOVEopt
	capture drop ABOVE?
	capture drop ABOVE??
	
	global iv = "`iv'"	
	global fe = "`fe'"
	
	//Define outcome globally in case needed to pass (for 'if_condition')
	global outcome = "`outcome'"
	
	//Sample
	global siblings "`siblings'"
	global rel_app ="`rel_app'"
	global sem = "`semesters'"
	global bw_select "`bw'"
	global bw_select_label = "optimal"
	if "${bw_select}" != "optimal" global bw_select_label = "fixed"
	
	//FE to use
	if "${fe}"=="cmy" 	global fe_used = "id_cutoff"
	if "${fe}"=="cm+y" 	global fe_used = "FE_cm FE_y"
	if "${fe}"=="cm" 	global fe_used = "FE_cm"
	if "${fe}"=="y" 	global fe_used = "FE_y"
	if "${fe}"=="nofe" 	global fe_used = ""

	*- Get "if" condition for each outcome
	if_condition // & h`heterog_type' == `likely_val'
	
	di "if_condition done"
  
	*- We get the optimal bandwidths
	if "${bw_select}" == "optimal" & "${iv}" != "none" 	{
		rdrobust ${outcome} score_relative if ${if_pre}, ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(`kernel') ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(${iv}) ///
		  covs(`covs_rdrob'_*) //  covs(year_applied_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
		  
		  global bw_${outcome} = e(h_l)
	}
	
	//For first stage, when not doing IV
	if "${bw_select}" == "optimal" &  "${iv}" == "none" 	{
		rdrobust ${outcome} score_relative if ${if_pre}, ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(`kernel') ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  covs(`covs_rdrob'_*) //  covs(year_applied_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
		  
		  global bw_${outcome} = e(h_l)
	}	
	

	if "${bw_select}" != "optimal" 			global bw_${outcome} = ${bw_select}	
	//if inlist("`likely_val'","0","1")==1 	global if_final "${if_pre} & h`heterog_type' == `likely_val'"
	//if inlist("`likely_val'","")==1 		global if_final "${if_pre}"	
	global if_final "${if_pre}"
	
	//Optimal
	global opt100 = int(${bw_${outcome}}*100)
	clonevar ABOVEopt = ABOVE
	label var ABOVEopt  " "
	
	if "${fe}" != "nofe" {
		reghdfe ${outcome} ABOVEopt  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(${fe_used}) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.
	}
	
	if "${fe}" == "nofe" {
		reg ${outcome} ABOVEopt  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.
	}
	
	estimates store rf_rd_opt
	*drop ABOVEopt	
		
	*-- Loop for each fixed window
	forvalues bw_window=1(1)15 { //We use integers instead of actual window in 0.1 steps for both easier labelling and because 'relocate' works better with integers.
	clonevar ABOVE`bw_window' = ABOVE //In order for ABOVE to be considered as different coefficients in each model and order them with coefplots independently so that we can place the optimal window at the appropriate place.
	local window_label = `bw_window'/10
	label var ABOVE`bw_window'  "`window_label'" // If we 'rename' in the coefplot command, the option 'relocate' does not work properly but rather would have to use the 'renamed' coefficients. This way it is easier to read the code.
	if "${fe}" != "nofe" {
		reghdfe ${outcome} ABOVE`bw_window'  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<`bw_window'/10, ///
		absorb(${fe_used}) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.
	}	
	
	if "${fe}" == "nofe" {
		reghdfe ${outcome} ABOVE`bw_window'  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<`bw_window'/10, ///
		cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.
	}		
		estimates store rf_rd_`bw_window'
		*drop ABOVE`bw_window'
	}
	
	
*- Plot RD estimates for each window	
coefplot 	(rf_rd_1 rf_rd_2 rf_rd_3 rf_rd_4 rf_rd_5 rf_rd_6 rf_rd_7 rf_rd_8 rf_rd_9 rf_rd_10 rf_rd_11 rf_rd_12 rf_rd_13 rf_rd_14 rf_rd_15, mcolor(gs0) ciopts(color(/*gs0 gs0*/ gs0)) levels(/*99 95*/ 90)) ///
			(rf_rd_opt,mcolor(blue) ciopts(color(/*blue blue*/ blue)) levels(/*99 95*/ 90)), ///
				keep(ABOVE? ABOVE?? ABOVE???) ///
				xline(0) ///
				relocate(ABOVE1 = 10 ABOVE2 = 20 ABOVE3 = 30 ABOVE4 = 40 ABOVE5 = 50 ABOVE6 = 60 ABOVE7 = 70 ABOVE8 = 80 ABOVE9 = 90 ABOVE10 = 100 ABOVE11 = 110 ABOVE12 = 120 ABOVE13 = 130 ABOVE14 = 140 ABOVE15 = 150 ABOVEopt = ${opt100})	///
				xtitle("Effect Size") ///
				ytitle("Bandwidth") ///
				legend(off)
	
	if ${test_C02}==0 {
	graph export 	"$FIGURES/eps/RD_sens_${outcome}_${siblings}_${rel_app}_${sem}_${bw_select_label}_${main_cell}_${fe}.eps", replace	
	graph export 	"$FIGURES/png/RD_sens_${outcome}_${siblings}_${rel_app}_${sem}_${bw_select_label}_${main_cell}_${fe}.png", replace	
	graph export 	"$FIGURES/pdf/RD_sens_${outcome}_${siblings}_${rel_app}_${sem}_${bw_select_label}_${main_cell}_${fe}.pdf", replace		
	}

	//capture drop student
	
end




********************************************************************************
* tables for latex document
********************************************************************************

capture program drop tables_pres_main
program define tables_pres_main	

args scale table_type heterog_type panel_A panel_B var

	global t_tex = "`table_type'"
	local suffix = "_${main_cell}_${main_kernel}_PRES"
	
	if ${test_C02} == 0 {

	file open  table_tex	using "$TABLES\\${t_tex}`heterog_type'`suffix'.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\makebox[0.1\width][l]{" _n ///
					"\resizebox{`scale'\textwidth}{!}{" _n
	file close table_tex
	
	

	tables_input_main PRES "`heterog_type'" "`panel_A'" "`panel_B'" "`var'"
	
	file open  table_tex	using "$TABLES\\${t_tex}`heterog_type'`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule" _n ///
		"\end{tabular}" _n ///
		"}" _n ///
		"}" _n
	file close table_tex	

	}
end


********************************************************************************
* tables for latex document
********************************************************************************
		
capture program drop tables_input_main
program define tables_input_main

	args t_suffix heterog_type panel_A panel_B var

	if "`t_suffix'" == "DOC" 	local suffix = "_${main_cell}_${main_kernel}"
	if "`t_suffix'" == "PRES" 	local suffix = "_${main_cell}_${main_kernel}_PRES"
	
	if "`var'" == "applied_sib" 		local var_title = "Applied to any college"
	if "`var'" == "applied_public_sib" 	local var_title = "Applied to any public college"
	if "`var'" == "applied_uni_sib" 	local var_title = "Applied to same college"
	if "`var'" == "admitted_sib" 		local var_title = "Admitted to any college"
	if "`var'" == "enrolled_sib" 		local var_title = "Enrolled to any college"
	if "`var'" == "asp_college4_4p_sib" local var_title = "4th grade expectations (parents)"
	if "`var'" == "std_gpa_m_b2_sib" 	local var_title = "Mathematics GPA (t-2)"
	if "`var'" == "std_gpa_m_a0_sib" local var_title = "Mathematics GPA (t)"
	if "`var'" == "std_gpa_m_a2_sib" local var_title = "Mathematics GPA (t+2)"
	

	
	di "`var'"

*- We produce Table with estimates

**# Edit: Include outcomes of quality: Peers 2nd, Peers 8th, graduation rates, (check Mountjoy)
if inlist("${t_tex}","table_balance") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"\cmidrule(lr){2-7}" _n ///					
					"& Male & Age & Mother has & very low  & \multicolumn{2}{c}{2nd grade standardized} & \multicolumn{2}{c}{8th grade standardized} \\" _n ///
					"& &  & higher education & SES & Mathematics & Reading & Mathematics & Reading \\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-8} " _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & & & &   & \\" _n 
	file close table_tex
	
	estout   rf_male_foc rf_age rf_higher_ed_mother rf_vlow_ses_foc rf_score_math_std_2p_foc rf_score_com_std_2p_foc rf_score_math_std_2s_foc rf_score_com_std_2s_foc ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}


if inlist("${t_tex}","table_first_stage") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{3}{c}{Same semester} 									& \multicolumn{3}{c}{Ever} \\" _n ///
					"\cmidrule(lr){2-4} \cmidrule(lr){5-7}" _n ///					
					"& Admitted 				& Enrolled  			& Enrolled 			& Enrolled target	& Enrolled private  & Enrolled any \\" _n ///
					"\cmidrule(lr){2-4} \cmidrule(lr){5-7}" _n ///
					"& target college-major 	& target college-major  & any college		& college 			& college  			& college \\" _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & & &  \\" _n 
	file close table_tex
	
	estout   rf_admitted_foc rf_enr_uni_major_sem_foc rf_enrolled_sem_foc rf_enrolled_uni_foc rf_enrolled_private_foc rf_enrolled_foc ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}

if inlist("${t_tex}","table_focal_effects") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{4}{c}{Enrolled in college after} 									& \multicolumn{1}{c}{Graduated} \\" _n ///
					"\cmidrule(lr){2-5} \cmidrule(lr){5-5}" _n ///					
					"& 1 year 				& 2 years  			& 3 years 			& 4 years & Any \\" _n ///
					"\cmidrule(lr){2-5} \cmidrule(lr){5-5}" _n ///
					"& (1) & (2) & (3) & (4) & (5) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & &  \\" _n 
	file close table_tex
	
	estout   rf_enrolled_1year_foc rf_enrolled_2year_foc rf_enrolled_3year_foc rf_enrolled_4year_foc rf_graduated_foc ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}

**# Edit: Include outcomes of quality: Peers 2nd, Peers 8th, graduation rates, (check Mountjoy)
if inlist("${t_tex}","table_peers") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"\cmidrule(lr){2-7}" _n ///					
					"& \multicolumn{4}{c}{College Peer's Standardized Score} & \multicolumn{3}{c}{Peer's 5-year BA Completion} \\" _n ///
					"& 2nd grade Mathematics & 2nd grade Literacy & 8th grade Mathematics & 8th grade Literacy & Ever & 5 years & 6 years \\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-8} " _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6) & (7)  \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & & & &  \\" _n 
	file close table_tex
	
	estout   rf_peer_math_std_2p_foc rf_peer_com_std_2p_foc rf_peer_math_std_2s_foc rf_peer_com_std_2s_foc rf_peer_grad_uni_ever_foc rf_peer_grad_uni_5_foc rf_peer_grad_uni_6_foc ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}



if inlist("${t_tex}","table_quality") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{2}{c}{Student outcomes} 									& \multicolumn{2}{c}{Peers' characteristics} \\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-5}" _n ///					
					"& Enrolled after 3 years &	Graduates &	8th grade academic achievement &	Graduation rates \\" _n ///
					"\cmidrule(lr){2-5} \cmidrule(lr){5-5}" _n ///
					"& (1) & (2) & (3) & (4)  \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  &   \\" _n 
	file close table_tex
	
	estout     rf_enrolled_3year_foc rf_graduated_foc rf_peer_acad_std_2s_foc rf_peer_grad_uni_ever_foc ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}
	



if inlist("${t_tex}","table_main_extensive","table_main_extensive_placebo","table_main_extensive_nofe","table_main_extensive_placebo_nofe") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" & \multicolumn{5}{c}{Applied to}   			& Admitted to 		& Enrolled in     \\" _n ///
					" & \multicolumn{5}{c}{4-year college}   		& 4-year college  	& 4-year college  \\" _n ///
					"\cmidrule(lr){2-6} \cmidrule(lr){7-7} \cmidrule(lr){8-8}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& Any 			& Public 		& Same as sibling 		& Other public 		& Private & Any & Any		\\" _n ///
					"& (1) 				& (2) 			& (3) 			& (4) 			& (5)	 &  (6) & (7) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  &  & & &\\" _n 
	file close table_tex

	///estout  iv_applied_sib iv_app_pu_sib iv_app_u_sib iv_app_puo_sib iv_app_pr_sib iv_admitted_sib iv_enrolled_sib ///
	///using "$TABLES\\${t_tex}`suffix'.tex", ///
	///append style(tex) ///
	///cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	///keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	///mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout  rf_applied_sib rf_app_pu_sib rf_app_u_sib rf_app_puo_sib rf_app_pr_sib rf_admitted_sib rf_enrolled_sib ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}

if inlist("${t_tex}","table_main_extensive_fes_`var'") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" & \multicolumn{5}{c}{`var_title'}   			  \\" _n ///
					"\cmidrule(lr){2-6}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& (1) 				& (2) 			& (3) & (4) & (5) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  &  & \\" _n 
	file close table_tex

	///estout  iv_applied_sib iv_app_pu_sib iv_app_u_sib iv_app_puo_sib iv_app_pr_sib iv_admitted_sib iv_enrolled_sib ///
	///using "$TABLES\\${t_tex}`suffix'.tex", ///
	///append style(tex) ///
	///cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	///keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	///mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout  rf_`var'1 rf_`var'2 rf_`var'3 rf_`var'4 rf_`var'5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Younger Applied Any") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FEs")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					" CM FE 		&  & X &  & X & \\" _n  ///
					" Semester FE 	&  &  & X & X & \\" _n ///
					" CMS FE 		&  &  &  &  & X\\" _n 
	file close table_tex	
}
	
	

if inlist("${t_tex}","table_persistence") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{4}{c}{Enrolled in college after} 									& \multicolumn{1}{c}{Graduated} \\" _n ///
					"\cmidrule(lr){2-5} \cmidrule(lr){5-5}" _n ///					
					"& 1 year 				& 2 years  			& 3 years 			& 4 years & Any \\" _n ///
					"\cmidrule(lr){2-5} \cmidrule(lr){5-5}" _n ///
					"& (1) & (2) & (3) & (4) & (5) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & &  \\" _n 
	file close table_tex
	
	estout   rf_enrolled_1year_sib rf_enrolled_2year_sib rf_enrolled_3year_sib rf_enrolled_4year_sib rf_graduated_sib ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)		
}

if inlist("${t_tex}","table_college_choice_persistence") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{3}{c}{Application} 									& \multicolumn{2}{c}{Enrollment} \\" _n ///
					"\cmidrule(lr){2-4} \cmidrule(lr){5-6}" _n ///					
					"& Same college as older & Ever & On time & On time & Continues after 1 year \\" _n ///
					"\cmidrule(lr){2-4} \cmidrule(lr){5-6}" _n ///
					"& (1) & (2) & (3) & (4) & (5) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & &   \\" _n 
	file close table_tex
	
	estout   rf_applied_uni_sib	 rf_applied_sib rf_app_ot_sib  rf_enr_ot_sib rf_enrolled_1year_sib ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)		
}



	

if inlist("${t_tex}","table_main_summary_fes","table_main_summary_fes_uniform","table_main_summary_fes_triangular") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"\cmidrule(lr){2-5}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& (1) 				& (2) 			& (3) & (4) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  &   \\" _n 
	file close table_tex

	estout  rf_applied_sib1 rf_applied_sib2 rf_applied_sib4 rf_applied_sib5     ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Applies") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout  rf_applied_uni_sib1 rf_applied_uni_sib2 rf_applied_uni_sib4 rf_applied_uni_sib5     ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Applies to same college") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
		
	estout rf_applies_on_time_sib1 rf_applies_on_time_sib2 rf_applies_on_time_sib4 rf_applies_on_time_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Applies on time") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
		
	estout rf_enrolls_on_time_sib1 rf_enrolls_on_time_sib2 rf_enrolls_on_time_sib4 rf_enrolls_on_time_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Enrolls on time") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
				
	estout rf_score_std_uni_u_sib1 rf_score_std_uni_u_sib2 rf_score_std_uni_u_sib4 rf_score_std_uni_u_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Score same college") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
		
	estout rf_score_std_pub_o_u_sib1 rf_score_std_pub_o_u_sib2 rf_score_std_pub_o_u_sib4 rf_score_std_pub_o_u_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Score different college") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
				
	estout rf_admitted_sib1 rf_admitted_sib2 rf_admitted_sib4 rf_admitted_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Admitted") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
				
	estout rf_enrolled_sib1 rf_enrolled_sib2 rf_enrolled_sib4 rf_enrolled_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Enrolled") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)			
	
	
	estout rf_approved_a0_sib1 rf_approved_a0_sib2 rf_approved_a0_sib4 rf_approved_a0_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Approved grade") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout rf_approved_a1_sib1 rf_approved_a1_sib2 rf_approved_a1_sib4 rf_approved_a1_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Approved grade (t+1)") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_dropout_ever_sib1 rf_dropout_ever_sib2 rf_dropout_ever_sib4 rf_dropout_ever_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Dropout ever") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_sec_grad_sib1 rf_sec_grad_sib2 rf_sec_grad_sib4 rf_sec_grad_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Completed Secondary") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_std_gpa_m_b2_sib1 rf_std_gpa_m_b2_sib2 rf_std_gpa_m_b2_sib4 rf_std_gpa_m_b2_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "GPA t-2") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	

	estout rf_std_gpa_m_b1_sib1 rf_std_gpa_m_b1_sib2 rf_std_gpa_m_b1_sib4 rf_std_gpa_m_b1_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "GPA t-1") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_std_gpa_m_a0_sib1 rf_std_gpa_m_a0_sib2 rf_std_gpa_m_a0_sib4 rf_std_gpa_m_a0_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "GPA t") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_std_gpa_m_a1_sib1 rf_std_gpa_m_a1_sib2 rf_std_gpa_m_a1_sib4 rf_std_gpa_m_a1_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "GPA t+1") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
				
	estout rf_std_gpa_m_a2_sib1 rf_std_gpa_m_a2_sib2 rf_std_gpa_m_a2_sib4 rf_std_gpa_m_a2_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "GPA t+2") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_std_pred_gpa_m_b2_sib1 rf_std_pred_gpa_m_b2_sib2 rf_std_pred_gpa_m_b2_sib4 rf_std_pred_gpa_m_b2_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "NGPA t-2") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	

	estout rf_std_pred_gpa_m_b1_sib1 rf_std_pred_gpa_m_b1_sib2 rf_std_pred_gpa_m_b1_sib4 rf_std_pred_gpa_m_b1_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "NGPA t-1") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_std_pred_gpa_m_a0_sib1 rf_std_pred_gpa_m_a0_sib2 rf_std_pred_gpa_m_a0_sib4 rf_std_pred_gpa_m_a0_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "NGPA t") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_std_pred_gpa_m_a1_sib1 rf_std_pred_gpa_m_a1_sib2 rf_std_pred_gpa_m_a1_sib4 rf_std_pred_gpa_m_a1_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "NGPA t+1") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
				
	estout rf_std_pred_gpa_m_a2_sib1 rf_std_pred_gpa_m_a2_sib2 rf_std_pred_gpa_m_a2_sib4 rf_std_pred_gpa_m_a2_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "NGPA t+2") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
		
		
	estout rf_std_gpa_c_b2_sib1 rf_std_gpa_c_b2_sib2 rf_std_gpa_c_b2_sib4 rf_std_gpa_c_b2_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "GPA t-2") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	

	estout rf_std_gpa_c_b1_sib1 rf_std_gpa_c_b1_sib2 rf_std_gpa_c_b1_sib4 rf_std_gpa_c_b1_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "GPA t-1") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_std_gpa_c_a0_sib1 rf_std_gpa_c_a0_sib2 rf_std_gpa_c_a0_sib4 rf_std_gpa_c_a0_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "GPA t") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_std_gpa_c_a1_sib1 rf_std_gpa_c_a1_sib2 rf_std_gpa_c_a1_sib4 rf_std_gpa_c_a1_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "GPA t+1") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
				
	estout rf_std_gpa_c_a2_sib1 rf_std_gpa_c_a2_sib2 rf_std_gpa_c_a2_sib4 rf_std_gpa_c_a2_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "GPA t+2") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_std_pred_gpa_c_b2_sib1 rf_std_pred_gpa_c_b2_sib2 rf_std_pred_gpa_c_b2_sib4 rf_std_pred_gpa_c_b2_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "NGPA t-2") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	

	estout rf_std_pred_gpa_c_b1_sib1 rf_std_pred_gpa_c_b1_sib2 rf_std_pred_gpa_c_b1_sib4 rf_std_pred_gpa_c_b1_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "NGPA t-1") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_std_pred_gpa_c_a0_sib1 rf_std_pred_gpa_c_a0_sib2 rf_std_pred_gpa_c_a0_sib4 rf_std_pred_gpa_c_a0_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "NGPA t") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_std_pred_gpa_c_a1_sib1 rf_std_pred_gpa_c_a1_sib2 rf_std_pred_gpa_c_a1_sib4 rf_std_pred_gpa_c_a1_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "NGPA t+1") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
				
	estout rf_std_pred_gpa_c_a2_sib1 rf_std_pred_gpa_c_a2_sib2 rf_std_pred_gpa_c_a2_sib4 rf_std_pred_gpa_c_a2_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "NGPA t+2") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_asp_college2_4p_sib1 rf_asp_college2_4p_sib2 rf_asp_college2_4p_sib4 rf_asp_college2_4p_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Parents' exp. 2-year") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout rf_asp_college4_4p_sib1 rf_asp_college4_4p_sib2 rf_asp_college4_4p_sib4 rf_asp_college4_4p_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Parents' exp. 4-year") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_asp_college2_2s_sib1 rf_asp_college2_2s_sib2 rf_asp_college2_2s_sib4 rf_asp_college2_2s_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Students' exp. 2-year") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout rf_asp_college4_2s_sib1 rf_asp_college4_2s_sib2 rf_asp_college4_2s_sib4 rf_asp_college4_2s_sib5 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Students' exp. 4-year") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	///stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
		
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					" College-major FE 			&  & X & X &  \\" _n  ///
					" Semester FE 				&  &   & X &  \\" _n ///
					" College-major-semester FE &  &   &   & X \\" _n 
	file close table_tex	
}	


	
	
**# Edit: Include graduation
if inlist("${t_tex}","table_uni_performance_u","table_uni_performance_f") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcccccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& Applies on  		& Enrolls on & \multicolumn{3}{c}{Number of Applications}   	& \multicolumn{5}{c}{Application Score}    \\" _n ///
					"\cmidrule(lr){2-2} \cmidrule(lr){3-3} \cmidrule(lr){4-6} \cmidrule(lr){7-11}" _n ///
					"& time  			& time & Total & First time 	& Same College 			& Any & Same College 	& Public 	& Other Colleges 	& Other Public		\\" _n ///
					"& (1) 				& (2) 	& (3) 			& (4) 					& (5) & (6) 			& (7) 		& (8)				& (9)	 & (10) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  &  & & & & & & \\" _n 
	file close table_tex

	///estout  iv_app_ot_sib iv_enr_ot_sib iv_N_apps_sib iv_N_apps_first_sib iv_N_apps_uni_sib iv_app_sco_all_sib iv_app_sco_uni_sib iv_app_sco_pub_sib iv_app_sco_uni_o_sib iv_app_sco_pub_o_sib  ///
	///using "$TABLES\\${t_tex}`suffix'.tex", ///
	///append style(tex) ///
	///cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	///keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	///mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout  rf_app_ot_sib rf_enr_ot_sib rf_N_apps_sib rf_N_apps_first_sib rf_N_apps_uni_sib rf_app_sco_all_sib rf_app_sco_uni_sib rf_app_sco_pub_sib rf_app_sco_uni_o_sib rf_app_sco_pub_o_sib  ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}
	
	

if inlist("${t_tex}","table_school_performance") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcccccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" &\multicolumn{2}{c}{GPA same year} & \multicolumn{2}{c}{GPA $t+1$}  & \multicolumn{2}{c}{GPA $t+2$} & \multicolumn{2}{c}{4th grade Standardized scores}   & \multicolumn{2}{c}{8th grade Standardized scores}   \\" _n ///
					" 		& Mathematics   		& Literacy  	& Mathematics & Literacy & Mathematics   		& Literacy & Mathematics   		& Literacy  & Mathematics   		& Literacy   \\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9} \cmidrule(lr){10-11}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& (1) 				& (2) 			& (3) 			& (4) 			& (5) & (6) & (7) & (8) & (9) & (10) \\" _n ///
					"\bottomrule" _n ///
					" & &  &  &  &  & &  &  &  & \\" _n 
	file close table_tex

	///estout  iv_std_gpa_m_b1_sib iv_std_gpa_c_b1_sib  iv_std_gpa_m_a0_sib iv_std_gpa_c_a0_sib iv_std_gpa_m_a1_sib iv_std_gpa_c_a1_sib iv_std_gpa_m_a2_sib iv_std_gpa_c_a2_sib  iv_math_4p_sib iv_com_4p_sib iv_math_2s_sib iv_com_2s_sib   ///
	///using "$TABLES\\${t_tex}`suffix'.tex", ///
	///append style(tex) ///
	///cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	///keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	///mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout rf_std_gpa_m_b1_sib rf_std_gpa_c_b1_sib  rf_std_gpa_m_a0_sib rf_std_gpa_c_a0_sib rf_std_gpa_m_a1_sib rf_std_gpa_c_a1_sib rf_std_gpa_m_a2_sib rf_std_gpa_c_a2_sib rf_math_4p_sib rf_com_4p_sib rf_math_2s_sib rf_com_2s_sib  ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}

	

if inlist("${t_tex}","table_school_performance_math","table_school_performance_math_nofe") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" &\multicolumn{5}{c}{Mathematics GPA} & \multicolumn{2}{c}{Mathematics Standardized National Exam}   \\" _n ///
					" & Year - 2 & Year - 1 & Same Year & Year + 1 & Year + 2 & 4th grade  &  8th grade   \\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-6} \cmidrule(lr){7-8} " _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& (1) 				& (2) 			& (3) 			& (4) 			& (5) & (6) & (7) \\" _n ///
					"\bottomrule" _n ///
					" & & &  &  &  &  &  \\" _n 
	file close table_tex

	estout rf_std_gpa_m_b2_sib rf_std_gpa_m_b1_sib  rf_std_gpa_m_a0_sib  rf_std_gpa_m_a1_sib  rf_std_gpa_m_a2_sib  rf_math_4p_sib  rf_math_2s_sib   ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}


if inlist("${t_tex}","table_school_performance_com") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" &\multicolumn{5}{c}{Reading GPA} & \multicolumn{2}{c}{Reading Standardized National Exam}   \\" _n ///
					" & Year - 2 & Year - 1 & Same Year & Year + 1 & Year + 2 & 4th grade  &  8th grade   \\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-6} \cmidrule(lr){7-8} " _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& (1) 				& (2) 			& (3) 			& (4) 			& (5) & (6) & (7) \\" _n ///
					"\bottomrule" _n ///
					" & & &  &  &  &  &  \\" _n 
	file close table_tex

	estout rf_std_gpa_c_b2_sib rf_std_gpa_c_b1_sib  rf_std_gpa_c_a0_sib  rf_std_gpa_c_a1_sib  rf_std_gpa_c_a2_sib  rf_com_4p_sib  rf_com_2s_sib   ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}


if inlist("${t_tex}","table_school_performance_grade") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" & GPA $t=0$ & GPA $t=1$ &   GPA $t=2$   \\" _n ///
					" 		& Mathematics   		& Mathematics  	& Mathematics    \\" _n ///
					"\cmidrule(lr){2-4} " _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& (1) 				& (2) 			& (3) \\" _n ///
					"\bottomrule" _n ///
					" & &  & \\" _n 
	file close table_tex

	estout  rf_std_gpa_m_7_a0_sib rf_std_gpa_m_7_a1_sib /*rf_std_gpa_m_7_a2_sib*/     ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "7th grade") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout  rf_std_gpa_m_8_a0_sib rf_std_gpa_m_8_a1_sib rf_std_gpa_m_8_a2_sib     ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "8th grade") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout  rf_std_gpa_m_9_a0_sib rf_std_gpa_m_9_a1_sib rf_std_gpa_m_9_a2_sib     ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "9th grade") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout  rf_std_gpa_m_10_a0_sib rf_std_gpa_m_10_a1_sib rf_std_gpa_m_10_a2_sib    ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "10th grade") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	estout  rf_std_gpa_m_11_a0_sib  rf_std_gpa_m_11_a1_sib /*rf_std_gpa_m_11_a2_sib*/   ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "11th grade") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}


	
**# Edit: Include GPA?	
if inlist("${t_tex}","table_school_progression") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" & \multicolumn{2}{c}{Passed grade} 		&  	Dropout & Graduate      \\" _n ///
					" 		& Same year   		& t+1 year  	& 	Ever  & Secondary \\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-4} \cmidrule(lr){5-5}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& (1) 				& (2) 			& (3) 			& (4)  \\" _n ///
					"\bottomrule" _n ///
					" & &  &  &   \\" _n 
	file close table_tex

	///estout  iv_approved_a0_sib iv_approved_a1_sib iv_dropout_ever_sib iv_sec_grad_sib  ///
	///using "$TABLES\\${t_tex}`suffix'.tex", ///
	///append style(tex) ///
	///cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	///keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	///mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout rf_approved_a0_sib rf_approved_a1_sib rf_dropout_ever_sib rf_sec_grad_sib ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}

	
**# Edit: Include GPA?	

if inlist("${t_tex}","table_school_aspirations") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"  		& \multicolumn{2}{c}{4th grade parents' expectations} & \multicolumn{2}{c}{8th grade students' expectations}     \\" _n ///
					" 		& 2-year college & 4-year college & 2-year college & 4-year college \\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-5}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& (1) 				& (2)  & (3) & (4) \\" _n ///
					"\bottomrule" _n ///
					" & & & & \\" _n 
	file close table_tex

	///estout  iv_asp_college2_4p_sib iv_asp_college4_4p_sib iv_asp_college2_2s_sib iv_asp_college4_2s_sib  ///
	///using "$TABLES\\${t_tex}`suffix'.tex", ///
	///append style(tex) ///
	///cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	///keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	///mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout rf_asp_college2_4p_sib rf_asp_college4_4p_sib rf_asp_college2_2s_sib rf_asp_college4_2s_sib ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}


if inlist("${t_tex}","table_school_aspirations_4") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"  		& \multicolumn{1}{c}{4th grade parents' expectations} & \multicolumn{1}{c}{8th grade students' expectations}     \\" _n ///
					" 		& 4-year college &  4-year college \\" _n ///
					"\cmidrule(lr){2-2} \cmidrule(lr){3-3}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& (1) 				& (2)  \\" _n ///
					"\bottomrule" _n ///
					" & &  \\" _n 
	file close table_tex

	///estout  iv_asp_college2_4p_sib iv_asp_college4_4p_sib iv_asp_college2_2s_sib iv_asp_college4_2s_sib  ///
	///using "$TABLES\\${t_tex}`suffix'.tex", ///
	///append style(tex) ///
	///cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	///keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	///mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout  rf_asp_college4_4p_sib  rf_asp_college4_2s_sib ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}
	
*****
*- Heterogeneity
*****	
	
if inlist("${t_tex}","table_heterogeneity") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`heterog_type'`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" & 4th grade expectations  &	8th grade expectations 	& Completed 		& Applied to   	& \multicolumn{2}{c}{Application Exam Score}	& Admitted to 		& Enrolled in  		     	\\" _n ///
					" & 4-year college 		  &	4-year college 			& Secondary 		& 4-year college   	& Any & Same				& 4-year college  	& 4-year college 			\\" _n ///
					"\cmidrule(lr){2-4} \cmidrule(lr){5-9}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& (1) 				& (2) 			& (3) 			& (4) 			& (5)	 &  (6) & (7) & (8) \\" _n ///
					"\bottomrule" _n ///
					"& & & & & & & &  \\" _n  ///
					"\multicolumn{9}{l}{Panel A: `panel_A' } \\" _n
	file close table_tex
	
	///estout  iv_asp_4_4p_sib0 iv_asp_4_2s_sib0 iv_secg_sib0  iv_applied_sib0  iv_app_sco_all_sib0 iv_app_sco_uni_sib0 iv_admitted_sib0 iv_enrolled_sib0   ///
	///using "$TABLES\\${t_tex}`heterog_type'`suffix'.tex", ///
	///append style(tex) ///
	///cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	///keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	///mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout rf_asp_4_4p_sib0 rf_asp_4_2s_sib0 rf_secg_sib0  rf_applied_sib0  rf_app_sco_all_sib0 rf_app_sco_uni_sib0 rf_admitted_sib0 rf_enrolled_sib0 ///
	using "$TABLES\\${t_tex}`heterog_type'`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	

	file open  table_tex	using "$TABLES\\${t_tex}`heterog_type'`suffix'.tex", append write
	file write table_tex ///
					"&  &  &  & & & & & &    \\" _n  ///
					"\multicolumn{9}{l}{Panel B: `panel_B'} \\" _n
	file close table_tex	
	
	
	///estout  iv_asp_4_4p_sib1 iv_asp_4_2s_sib1 iv_secg_sib1  iv_applied_sib1  iv_app_sco_all_sib1 iv_app_sco_uni_sib1 iv_admitted_sib1 iv_enrolled_sib1   ///
	///using "$TABLES\\${t_tex}`heterog_type'`suffix'.tex", ///
	///append style(tex) ///
	///cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	///keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	///mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout rf_asp_4_4p_sib1 rf_asp_4_2s_sib1 rf_secg_sib1  rf_applied_sib1  rf_app_sco_all_sib1 rf_app_sco_uni_sib1 rf_admitted_sib1 rf_enrolled_sib1 ///
	using "$TABLES\\${t_tex}`heterog_type'`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)		
	
}	


*****
*- Robustness
*****


*- 1. Focus on sharp cutoffs. Do results change?
	
if inlist("${t_tex}","table_first_stage_R2") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{2}{c}{(R2 $<$ 0.7)}  &  \multicolumn{2}{c}{(R2: 0.7-0.9)} &  \multicolumn{2}{c}{(R2 $>=$ 0.9)}		 \\" _n ///
					"& Admitted 				& Enrolled  & Admitted 				& Enrolled  & Admitted 				& Enrolled  			 \\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7}" _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & &  \\" _n 
	file close table_tex
	
	estout   rf_fs_admitted_R21 rf_fs_enrolled_R21  rf_fs_admitted_R22 rf_fs_enrolled_R22  rf_fs_admitted_R23 rf_fs_enrolled_R23 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}
	

if inlist("${t_tex}","table_robust_R2") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{2}{c}{(R2 $<$ 0.7)}  &  \multicolumn{2}{c}{(R2: 0.7-0.9)} &  \multicolumn{2}{c}{(R2 $>=$ 0.9)}		 \\" _n ///
					"& Applied ever 				& Enrolled ever  & Applied ever 				& Enrolled ever  & Applied ever 				& Enrolled ever  &  			 \\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7}" _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & &  \\" _n 
	file close table_tex
	


	///estout  iv_applied_sib_R21 iv_enrolled_sib_R21  iv_applied_sib_R22 iv_enrolled_sib_R22  iv_applied_sib_R23 iv_enrolled_sib_R23  ///
	///using "$TABLES\\${t_tex}`suffix'.tex", ///
	///append style(tex) ///
	///cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	///keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	///mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout rf_applied_sib_R21 rf_enrolled_sib_R21  rf_applied_sib_R22 rf_enrolled_sib_R22  rf_applied_sib_R23 rf_enrolled_sib_R23 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	stats(blank_line N ymean bandwidth FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth"  "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)		
	
}
		

end


********************************************************************************
* Checking_Testing
********************************************************************************

capture program drop reg_test_new
program define reg_test_new

	clear
		
	//Sample
	global fam_type = 2
	
	//Specification details
	
	global main_sibling_sample = "oldest"
	global main_rel_app = "restrict"
	global main_term = "first"
	global main_bw = "fixed"
	global main_covs_rdrob = "semester_foc" //semester_foc
	
	
	//Covariates used
	global scores_1 		= "score_relative_1"
	global ABOVE_scores_1 	= "ABOVE_score_relative_1"
	global pot_outcomes "admitted_sib applied_sib admitted_sib enrolled_sib applied_uni_sib enrolled_uni_sib"
	global new_outcomes "graduated_foc avg_enr_score_*_std_??_foc"
	global pot_ifs 		"fam_order_* first_sem* exp_grad* year_applied_foc"
		
	/*
	//Reduce dataset
	use "$OUT/applied_outcomes_${fam_type}${data}.dta", clear
	
	bys id_persona_rec type_admission (semester_foc): gen first_sem_type_application = semester_foc==semester_foc[1]

	
	
	
	drop if public_foc!=1	
	isvar 				${pot_outcomes} ${pot_ifs} score_std_* ABOVE* score_1_* ABOVE_score_1_* id_cutoff_* id_fam_* /*prep*/ cutoff* rank* public_foc lottery*  any_sib_match ///
						N_above* N_below* R2_* ///
						score_raw ///
						codigo_modular type_admission major_c1_cat major_c1_inei_code 
	local all_vars = r(varlist)
	ds `all_vars', not
	keep `all_vars'
	order `all_vars'
	

	******
	*- additional vars
	******
	
	foreach cell in "major" "major_full" "deprt" "deprt_full" {
		*- Score relative
		gen score_relative_`cell' = score_std_`cell' - cutoff_std_`cell'
		//drop if score_relative==.	
		//keep if abs(score_relative)<${window} 

		*- Run the RD regression
		gen ABOVE_`cell' = (rank_score_raw_`cell'>=cutoff_rank_`cell') if score_relative_`cell'!=. //To avoid float issues around 0, we use the precisely integer rank scores.
		gen score_1_`cell' = score_relative_`cell'
		gen ABOVE_score_1_`cell'	= ABOVE_`cell'*score_1_`cell'
	}
	
	*- Timing of application vars
	tab year_applied_foc, gen(year_applied_foc_)
	
	
	
	*- Prepare sample for each case
	foreach cell in "major" "major_full" "deprt" "deprt_full" {	
		gen sample_`cell'=1
		replace sample_`cell' = 2 if public_foc!=1
		replace sample_`cell' = 3 if lottery_nocutoff_`cell' != 0
		replace sample_`cell' = 4 if (rank_score_raw_`cell'==cutoff_rank_`cell')
		replace sample_`cell' = 5 if any_sib_match==0
	}
	
	gen mark = 0
	replace mark = 1 if abs(score_relative_major)<1
	replace mark = 1 if abs(score_relative_major_full)<1
	replace mark = 1 if abs(score_relative_deprt)<1
	replace mark = 1 if abs(score_relative_deprt_full)<1
	
	merge m:1 id_cutoff_major 			using  "$TEMP/applied_cutoffs_major.dta", keep(master match) keepusing(cutoff_raw_major) nogen
	merge m:1 id_cutoff_major_full 		using  "$TEMP/applied_cutoffs_major_full.dta", keep(master match) keepusing(cutoff_raw_major_full) nogen	

	close
	*/
	open
	

	//keep if type_admission == 2
	//drop if codigo_modular==160000033
	
		//Define outcome globally in case needed to pass (for 'if_condition')
	global outcome = "applied_sib"
	
	//Sample
	global bw_${outcome} = 0.5
	
	*- Get "if" condition for each outcome
	global if_sibs "fam_order_${fam_type} == 1" //oldest
	**## First exam?
	global if_apps "first_sem_type_application==1" //First first_sem_type_application
	local gap_after = 0
	local gap_before = 2
	local expected_grad_sib = "exp_graduating_year1_sib"
	global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_applied_foc)"
	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		
	*- Consider all restrictions for sample of interest
	global if_pre "${if_sibs} & ${if_rel_app} & ${if_apps} & ${if_out}"	
	global if_final "${if_pre}"
	di "if_condition done"
  	
	*-- First stage
	foreach cell in "major" "major_full" "deprt" "deprt_full" {		
		
		}
	
	*-- Reduced form
		foreach cell in "major" "major_full" "deprt" "deprt_full" {		
			
			
		preserve
			//drop if abs(cutoff_raw_major-cutoff_raw_major_full)>1
			//keep if type_admission==1
			//keep if N_above_`cell'>10 & N_below_`cell'>10
			reghdfe admitted_foc ABOVE_`cell'  score_1_`cell' ABOVE_score_1_`cell' ///
					if ${if_final} ///
					& abs(score_1_`cell')<${bw_${outcome}} ///
					& sample_`cell'==1, ///
					absorb(id_cutoff_`cell') cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.
			local fs_`cell': di  %9.2f _b[ABOVE_`cell']*100
			
			
			reghdfe ${outcome} ABOVE_`cell'  score_1_`cell' ABOVE_score_1_`cell' ///
				if ${if_final} ///
				& abs(score_1_`cell')<${bw_${outcome}} ///
				& sample_`cell'==1, ///
				absorb(id_cutoff_`cell') cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.
				mat res = r(table)

				count if e(sample)==1
				local N_`cell': di %9.0fc `r(N)'
				local b_`cell': di %9.3f res[1,1]
				local pv_`cell': di %9.3f res[4,1]
				
		restore
		}
		
		di as text "RESULTS OF REGRESSIONS:" _n ///
					"Major by: 		`b_major' (`pv_major')      " `fs_major' "% First stage and `N_major' obs." _n ///
					"Major full: 		`b_major_full' (`pv_major_full')      " `fs_major_full' "% First stage and `N_major_full' obs." _n ///
					"Department by: 	`b_deprt' (`pv_deprt')      " `fs_deprt' "% First stage and `N_deprt' obs." _n ///
					"Department full: 	`b_deprt_full' (`pv_deprt_full')      " `fs_deprt_full' "% First stage and `N_deprt_full' obs." _n 

					
	review_differences
	
end

/*
Admission type = 1

//first sem
Major by:                  0.016 (    0.454)      76.72% First stage and    10,180 obs.
Major full:                0.042 (    0.030)      74.08% First stage and    11,852 obs.
Department by:             0.014 (    0.466)      50.24% First stage and    12,260 obs.
Department full:           0.010 (    0.547)      47.98% First stage and    14,049 obs.

//first sem for each admission type
Major by:                  0.010 (    0.624)      77.22% First stage and    11,565 obs.
Major full:                0.035 (    0.052)      73.93% First stage and    13,388 obs.
Department by:             0.006 (    0.749)      51.3% First stage and    13,822 obs.
Department full:          -0.002 (    0.907)      48.95% First stage and    15,772 obs.



*/


capture program drop review_differences
program define review_differences

	//Some reviews:
	/*
	1. When restricting to only exam takers, # of cutoffs, obs and FS are similar between both majors, but coef still different. So cutoff scores are different. This happens even when R2>0.99. Isn't that strange? How can R2 be = 1 with and without score takers... should cutoff be the same then?
	*/
	preserve

		keep if abs(cutoff_raw_major-cutoff_raw_major_full)>0.01
		keep if N_above_major_full>10 & N_below_major_full>10
		bys id_cutoff_major id_cutoff_major_full: keep if _n==1
		scatter cutoff_std_major cutoff_std_major_full if type_admission==1 & R2_major_full>0.99 & R2_major>0.99
		scatter cutoff_raw_major cutoff_raw_major_full if type_admission==1 & R2_major_full>0.99 & R2_major>0.99
		gen dist = abs(cutoff_std_major_full - cutoff_std_major)
		gen dist_raw = abs(cutoff_std_major_full - cutoff_std_major)
		keep if R2_major==1 & R2_major_full==1 &  dist>0.5
		keep if N_above_major>2 & N_above_major_full>2
		gsort codigo_modular -dist
		list codigo_modular id_cutoff_major* cutoff_std_major* cutoff_raw_major* R2_major* N_above_major*,sepby(codigo_modular)
		
	/*
	
 
     +------------------------------------------------------------------------------+
     | id_cut~r   i~r_full   c~d_major   cutoff_..   R2_major   R2_maj~l       dist |
     |------------------------------------------------------------------------------|
  1. |     5778       1819    3.786217    .6505701          1          1   3.135647 |
  2. |    27865       8838    2.069281   -.2854441          1          1   2.354725 |
  3. |    29541       9307    3.507127    1.289545          1          1   2.217582 |
  4. |    28224       8935    2.480725    .3574259          1          1   2.123299 |
  5. |    10651       3216    3.050272    1.006272          1          1      2.044 |
     |------------------------------------------------------------------------------|



     +------------------------------------------------------------------------------+
     | id_cut~r   i~r_full   c~d_major   cutoff_..   R2_major   R2_maj~l       dist |
     |------------------------------------------------------------------------------|
  1. |    27962       8867    1.539621   -.0017309          1          1   1.541352 |
  2. |    16239       5199    2.015675    .5590884          1          1   1.456586 |
  3. |    28557       9043    1.422093   -.0221238          1          1   1.444217 |
  4. |    28633       9064    1.657692    .2263803          1          1   1.431312 |
  5. |    21323       6792    1.349461   -.0560791          1          1    1.40554 |
	 
	 
	*/
	restore	
	
	preserve
		use "$TEMP\applied", clear
		tab id_cutoff_major type_admission if id_cutoff_major_full == 8867
		//tab id_cutoff_major_full if id_cutoff_major == 27962
		
		
		keep if id_cutoff_major_full==8867
		tab score_raw admitted_foc if type_admission==1
		tab score_raw admitted_foc if type_admission==2
		tab score_raw admitted_foc if type_admission==8
		
		tab score_std_major admitted_foc if type_admission==1
		tab score_std_major admitted_foc if type_admission==2
		tab score_std_major admitted_foc if type_admission==8
		
		tab score_std_major_full admitted_foc if type_admission==1
		tab score_std_major_full admitted_foc if type_admission==2
		tab score_std_major_full admitted_foc if type_admission==8	
	restore
	
	preserve
		use "$TEMP\applied", clear
		tab id_cutoff_major type_admission if id_cutoff_major_full == 1807
		//tab id_cutoff_major_full if id_cutoff_major == 27962
		
		
		keep if id_cutoff_major_full==1807
		tab score_raw admitted_foc if type_admission==1
		tab score_raw admitted_foc if type_admission==2
		
		tab score_std_major admitted_foc if type_admission==1
		tab score_std_major admitted_foc if type_admission==2
		
		tab score_std_major_full admitted_foc if type_admission==1
		tab score_std_major_full admitted_foc if type_admission==2
	restore	
	
	
	levelsof codigo_modular, local(uni_cods)
	foreach cod of local uni_cods {
		histogram score_relative_major if codigo_modular == `cod' & abs(score_relative_major)<2  & sample_major==1, bins(100) note("`cod' : `: label universidad_cod `i''")
		graph export 	"$FIGURES/TEMP/distrib_`cod'.png", replace	

	}
	
	preserve
		open
		levelsof codigo_modular, local(uni_cods)
		foreach cod of local uni_cods {
			histogram score_relative_major if codigo_modular == `cod' & abs(score_relative_major)<2  & sample_major==1, bins(100) note("`cod' : `: label universidad_cod `i''")
			graph export 	"$FIGURES/TEMP/wcutoffs_distrib_`cod'.png", replace	

		}
			
	restore
	
	foreach cod in "160000011" "160000022" "160000025" "160000089" "160000106" "160000126" {
		histogram score_relative_major if codigo_modular == `cod' & abs(score_relative_major)<2  & sample_major==1, bins(200) note("`cod' : `: label universidad_cod `cod''")
		graph export 	"$FIGURES/TEMP/check_distrib_`cod'.png", replace	
	}

	
	histogram score_relative_major if abs(score_relative_major)<2  & sample_major==1, bins(200)	
	histogram score_relative_major if abs(score_relative_major)<2  & sample_major==1 & type_admission==1, bins(200)	
	histogram score_relative_major if inlist(codigo_modular,160000011,160000022,160000025,160000089,160000106,160000126)!=1 & abs(score_relative_major)<2  & sample_major==1, bins(200)

	use "$TEMP\applied", clear
	tab id_cutoff_major if codigo_modular==160000025 & type_admission==1 & year==2018
	tab score_raw admitted if codigo_modular==160000025 & type_admission==1 & year==2018

	levelsof id_cutoff_major if codigo_modular==160000025 & type_admission==1 & year==2018, local(id_cut)
	foreach id of local id_cut {
		tab score_raw admitted if codigo_modular==160000025 & type_admission==1 & year==2018 & id_cutoff_major==`id'
	}
	histogram score_raw if codigo_modular==160000025 & type_admission==1 & year==2018, bins(50)
	tab score_raw admitted if id_cutoff_major == 21142
	use "$TEMP/applied_cutoffs_major.dta", clear 
	br if id_cutoff_major==21142
	
	
	// Check if all admitted 
	use "$TEMP\applied", clear
	bys id_cutoff_major (admitted): gen all = admitted[1]
	
end
	
********************************************************************************
**# Regressions for tables #HERE
********************************************************************************

capture program drop main_reg
program define main_reg

args cell kernel

	clear
	
	global ignore = 1 
	
	//Sample
	global fam_type = 2
	
	//Specification details
	
	global main_stack = "student_sibling"
	global main_sibling_sample = "oldest"
	global main_rel_app = "restrict"
	global main_term = "first"
	global main_bw = "optimal"
	global main_covs_rdrob = "semester_foc" //semester_foc
	global main_fes = "cmy" //semester_foc
	global main_kernel = "`kernel'" //semester_foc
	global main_cell = "`cell'"
	
	use "$OUT/applied_outcomes_${fam_type}${data}.dta", clear

	additional_vars 	noz ${main_cell}
	prepare_rd 			

	isvar ///
		/*ID*/						id_per_umc id_cutoff id_fam_* fam_order_${fam_type} fam_order_${fam_type}_sib id_ie_???_??? type_admission ///
		/*FE*/						FE_cm FE_y ///
		/*RD*/						score_relative  score_relative_* ABOVE_score_relative_* ABOVE admitted_foc enr_uni_major_sem_foc ///
		/*Geographic*/				region_siagie_foc region_foc ///
		/*cutoff*/					R2 N_below N_above ///		
		/*First stage*/				admitted_foc enr_uni_major_sem_foc enrolled_uni_sem_foc enrolled_sem_foc enrolled_uni_foc enrolled_uni_major_foc enrolled_public_o_foc enrolled_private_foc enrolled_uni_foc enrolled_foc  avg_enr_score_*_std_??_foc ///
		/*Peers*/					peer_*_foc ///
		/*Focal Outcomes */			graduated_foc graduated_5_foc graduated_6_foc enrolled_?year_foc n_credits_?year_foc /// 
		/*Demographics*/			socioec_index_2s_foc socioec_index_cat_2s_foc ///
		/*sample*/					first_application* one_application* oldest sample_oldest last_year_foc year_applied_foc semester_foc term semester_foc_* year_applied_foc_* student  ///
		/*school characteristic*/	sch*_foc ///
		/*Other*/					year_applied_foc universidad codigo_modular  ///
		/*Demographics*/			exp_graduating_year?_sib year_2p_sib year_4p_sib year_2s_sib male_siagie_foc male_siagie_sib first_gen ///
		/*Choices*/					stem_major ///
		/*Balance*/					male_foc age score_math_std_2?_foc score_com_std_2?_foc score_acad_std_2?_foc higher_ed_mother vlow_ses_foc ///
		/*SIBLINGS*/				///
			/*school characteristic*/	sch*_sib ///
			/*demographics*/		 	last_year_sib last_grade_sib grade_????_sib grade_??_sib ///
			/*School perf*/				score_math_std_??_sib score_com_std_??_sib score_acad_std_??_sib std_gpa_*sib gpa_*sib std_pred_gpa_*_sib  ///
			/*School prog*/				approved_??_sib approved_first_??_sib dropout_ever_sib pri_grad_sib sec_grad_sib year_grad_school_sib change_ie_next?_sib ///
			/*Survey*/					comp_sec_4p_sib any_coll_4p_sib asp_college?_4p_sib asp_years_4p_sib any_coll_2s_sib asp_college?_2s_sib asp_years_2s_sib std_belief_gender*_??_sib ///
			/*Application*/				applied_sib year_applied_sib applies_on_time_sib N_applications_*sib applied_public_tot_sib ///
			/*Choices*/					applied_uni_sib  applied_uni_major_sib  applied_major_sib    applied_public_sib applied_public_o_sib applied_private_sib year_applied_public_sib year_applied_private_sib year_applied_uni_sib  ///
			/*choices STEM*/			applied_stem_sib applied_nstem_sib enrolled_stem_sib enrolled_nstem_sib ///
			/*Admission*/				admitted_sib ///
			/*Enrollment*/ 				enrolled_sib year_enrolled_sib enrolled_public_tot_sib enrolls_on_time_sib enrolled_major_sib enrolled_uni_major_sib enrolled_uni_sib ///
			/*Persistence*/				enrolled_?year_sib n_credits_?year_sib ///
			/*Graduation*/ 				score_std_*_sib avg_enr_score_*_std_??_sib  graduated_sib   ///
			/*Heterogeneity*/			age_gap applied_lpred?_above_foc enrolled_lpred?_above_foc admitted_lpred?_above_foc h_* rej_*_b2_lpred?_above_foc* applied_lpred*above admitted_lpred*above  enrolled_lpred*_above
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'

	//binsreg admitted score_relative
	beep
	close
 	assert 1==0
	 
	*- Estimate Bandwidth:
	//Note: The bandwidth is estimated without cutoff fixed effects due to restrictions of 'rdrobust' on using high dimension fixed effects. The final regression will include fixed effects and some robustness of different bandwidths will be shown in the appendix.
	//Similar options as in Altmejd et. al. (2021) for Chile and Croatia have been used.	
	
	if ${ignore}==0 {
	*- MAIN RESULTS (TEST)
	estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enr_uni_major_sem_foc 	/*label*/ test  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}

	estimate_reg /*OUTCOME*/ asp_college4_4p_sib 		/*IV*/ enr_uni_major_sem_foc 	/*label*/ test  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ asp_college4_4p_sib 		/*IV*/ enr_uni_major_sem_foc 	/*label*/ test  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	
	estimate_reg /*OUTCOME*/ score_std_uni_u_sib 		/*IV*/ enr_uni_major_sem_foc 	/*label*/ test  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ score_std_uni_f_sib 		/*IV*/ enr_uni_major_sem_foc 	/*label*/ test  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}

	
	
	//FIX public_o
	
	*- Potential new results
	//Results higher for those with low expectations
	preserve
		keep if asp_college4_2s_sib==0
		estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enr_uni_major_sem_foc 	/*label*/ test  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	restore	
	
	
	*- Heterogeneity
	*-- Oldest didn't apply
	preserve
		bys id_fam_${fam_type}: egen oldest_sib_to_apply = min(fam_order_${fam_type})
		keep if oldest_sib_to_apply>1
		estimate_reg /*OUTCOME*/ applied_sib 			/*IV*/ enr_uni_major_sem_foc 		/*label*/ applied_sib`i'  		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	restore
	
	
	preserve
	// By n of observations above and below
	
	restore
	
	preserve
	// cat_sch_applied
		keep if cat_sch_applied==0
		estimate_reg /*OUTCOME*/ asp_college4_4p_sib 		/*IV*/ enr_uni_major_sem_foc 		/*label*/ asp_4_4p_sib`i'  		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}	
		
	restore	
	
	}
	
	
	//assert 1==0

	
	**************
	* Final results
	**************
	*- 0. Balance
	estimate_reg /*OUTCOME*/ male_foc 				/*IV*/ none /*label*/ male_foc  				/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ age 					/*IV*/ none /*label*/ age  						/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ higher_ed_mother 		/*IV*/ none /*label*/ higher_ed_mother  		/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ vlow_ses_foc 			/*IV*/ none /*label*/ vlow_ses_foc  			/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ score_math_std_2p_foc 	/*IV*/ none /*label*/ score_math_std_2p_foc  	/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ score_com_std_2p_foc 	/*IV*/ none /*label*/ score_com_std_2p_foc  	/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ score_math_std_2s_foc 	/*IV*/ none /*label*/ score_math_std_2s_foc  	/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ score_com_std_2s_foc 	/*IV*/ none /*label*/ score_com_std_2s_foc  	/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}

	tables_pres_main 1 table_balance	
	
	*- 0. First Stage

	estimate_reg /*OUTCOME*/ admitted_foc 				/*IV*/ none 						/*label*/ admitted_foc 			/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ enr_uni_major_sem_foc 		/*IV*/ none 						/*label*/ enr_uni_major_sem_foc /*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ enrolled_uni_sem_foc 		/*IV*/ none 						/*label*/ enrolled_uni_sem_foc 	/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ enrolled_sem_foc 			/*IV*/ none 						/*label*/ enrolled_sem_foc 		/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ enrolled_uni_foc 			/*IV*/ none 						/*label*/ enrolled_uni_foc 		/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ enrolled_public_o_foc 		/*IV*/ none 						/*label*/ enrolled_public_o_foc /*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ enrolled_private_foc 		/*IV*/ none 						/*label*/ enrolled_private_foc 	/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ enrolled_foc 				/*IV*/ none 						/*label*/ enrolled_foc 			/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	
	
	tables_pres_main 1 table_first_stage	
	
	
	*- 0. Focal Effects
	replace enrolled_1year_foc = 0 if enrolled_foc==0
	replace enrolled_2year_foc = 0 if enrolled_foc==0
	replace enrolled_3year_foc = 0 if enrolled_foc==0
	replace enrolled_4year_foc = 0 if enrolled_foc==0

	global bw_focal_effects	 = 0.9
	estimate_reg /*OUTCOME*/ enrolled_1year_foc 		/*IV*/ none 						/*label*/ enrolled_1year_foc 	/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${bw_focal_effects}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ enrolled_2year_foc 		/*IV*/ none 						/*label*/ enrolled_2year_foc 	/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${bw_focal_effects}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ enrolled_3year_foc 		/*IV*/ none 						/*label*/ enrolled_3year_foc 	/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${bw_focal_effects}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ enrolled_4year_foc 		/*IV*/ none 						/*label*/ enrolled_4year_foc 	/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${bw_focal_effects}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ graduated_foc 				/*IV*/ none 						/*label*/ graduated_foc 		/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${bw_focal_effects}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	


	tables_pres_main 1 table_focal_effects	
	


	
	*- 1. Peers Quality
	estimate_reg /*OUTCOME*/ peer_score_math_std_2p_foc 	/*IV*/ none /*label*/ peer_math_std_2p_foc  /*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ peer_score_com_std_2p_foc 		/*IV*/ none /*label*/ peer_com_std_2p_foc   /*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ peer_score_math_std_2s_foc 	/*IV*/ none /*label*/ peer_math_std_2s_foc  /*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ peer_score_com_std_2s_foc 		/*IV*/ none /*label*/ peer_com_std_2s_foc   /*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ peer_graduated_uni_ever_foc	/*IV*/ none /*label*/ peer_grad_uni_ever_foc/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ peer_graduated_uni_5_foc 		/*IV*/ none /*label*/ peer_grad_uni_5_foc  	/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ peer_graduated_uni_6_foc 		/*IV*/ none /*label*/ peer_grad_uni_6_foc   /*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	
	tables_pres_main 1 table_peers	
	
	
	//global bw_focal_effects	 = 0.9
	estimate_reg /*OUTCOME*/ enrolled_3year_foc 				/*IV*/ none 						/*label*/ enrolled_1year_foc 	/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${bw_focal_effects}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ rf_graduated_foc 					/*IV*/ none 						/*label*/ enrolled_2year_foc 	/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${bw_focal_effects}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ peer_score_acad_std_2s_foc 		/*IV*/ none 						/*label*/ enrolled_3year_foc 	/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${bw_focal_effects}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ peer_graduated_uni_ever_foc 		/*IV*/ none 						/*label*/ enrolled_4year_foc 	/*stack*/ student /*sibling*/ ${main_sibling_sample} 				/*relative to application*/ all /*semesters*/ ${main_term} /*bw*/ ${bw_focal_effects}	/*covs RD rob*/ ${main_covs_rdrob} /*kernel*/ ${main_kernel}	/*FE*/ ${main_fes}	

	
	//MAIN TABLE
	tables_pres_main 1 table_quality
	
	
	
	*- 1. Extensive margin
	estimate_reg /*OUTCOME*/ applied_sib 			/*IV*/ none /*label*/ applied_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	global bw_set_app = ${bw_${outcome}}
	estimate_reg /*OUTCOME*/ applied_public_sib 	/*IV*/ none /*label*/ app_pu_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_app} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ applied_uni_sib 		/*IV*/ none /*label*/ app_u_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_app} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ applied_public_o_sib 	/*IV*/ none /*label*/ app_puo_sib   /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_app} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ applied_private_sib 	/*IV*/ none /*label*/ app_pr_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_app} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ admitted_sib 			/*IV*/ none /*label*/ admitted_sib  /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_app} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ enrolled_sib 			/*IV*/ none /*label*/ enrolled_sib  /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_app} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	
	tables_pres_main 1 table_main_extensive

	
	*- 2. Application performance/effort
	estimate_reg /*OUTCOME*/ applies_on_time_sib 		/*IV*/ none /*label*/ app_ot_sib   		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_app} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ enrolls_on_time_sib 		/*IV*/ none /*label*/ enr_ot_sib   		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_app} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ N_applications_sib 		/*IV*/ none /*label*/ N_apps_sib   		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_app} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ N_applications_first_sib 	/*IV*/ none /*label*/ N_apps_first_sib  /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_app} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ N_applications_uni_sib 	/*IV*/ none /*label*/ N_apps_uni_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_app} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}

	estimate_reg /*OUTCOME*/ score_std_all_u_sib 	/*IV*/ none /*label*/ app_sco_all_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	global bw_set_score_u = ${bw_${outcome}}
	estimate_reg /*OUTCOME*/ score_std_uni_u_sib 	/*IV*/ none /*label*/ app_sco_uni_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_score_u} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ score_std_pub_u_sib 	/*IV*/ none /*label*/ app_sco_pub_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_score_u} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ score_std_uni_o_u_sib 	/*IV*/ none /*label*/ app_sco_uni_o_sib /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_score_u} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ score_std_pub_o_u_sib 	/*IV*/ none /*label*/ app_sco_pub_o_sib /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_score_u} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}

	
	tables_pres_main 1 table_uni_performance_u
	
	estimate_reg /*OUTCOME*/ score_std_all_f_sib 	/*IV*/ none /*label*/ app_sco_all_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	global bw_set_score_f = ${bw_${outcome}}
	estimate_reg /*OUTCOME*/ score_std_uni_f_sib 	/*IV*/ none /*label*/ app_sco_uni_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_score_f} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ score_std_pub_f_sib 	/*IV*/ none /*label*/ app_sco_pub_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_score_f} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ score_std_uni_o_f_sib 	/*IV*/ none /*label*/ app_sco_uni_o_sib /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_score_f} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ score_std_pub_o_f_sib 	/*IV*/ none /*label*/ app_sco_pub_o_sib /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_set_score_f} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}

	tables_pres_main 1 table_uni_performance_f
		
	*- 03. Persistence and graduation
	replace enrolled_1year_sib = 0 if enrolled_sib==0
	replace enrolled_2year_sib = 0 if enrolled_sib==0
	replace enrolled_3year_sib = 0 if enrolled_sib==0
	replace enrolled_4year_sib = 0 if enrolled_sib==0
	global bw_sibling_persistence = 0.9
	estimate_reg /*OUTCOME*/ enrolled_1year_sib 	/*IV*/ none /*label*/ enrolled_1year_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_sibling_persistence} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ enrolled_2year_sib 	/*IV*/ none /*label*/ enrolled_2year_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_sibling_persistence} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ enrolled_3year_sib 	/*IV*/ none /*label*/ enrolled_3year_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_sibling_persistence} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ enrolled_4year_sib 	/*IV*/ none /*label*/ enrolled_4year_sib 		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_sibling_persistence} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ graduated_sib 		/*IV*/ none /*label*/ graduated_sib 		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_sibling_persistence} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}${main_fes}	


	tables_pres_main 1 table_persistence
	

	*- Summmary: College choices + Extensive margin
	estimate_reg /*OUTCOME*/ applied_uni_sib 		/*IV*/ none /*label*/ applied_uni_sib   		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_sibling_persistence} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ applied_sib 		/*IV*/ none /*label*/ applied_sib   		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_sibling_persistence} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ applies_on_time_sib 		/*IV*/ none /*label*/ app_ot_sib   		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_sibling_persistence} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ enrolls_on_time_sib 		/*IV*/ none /*label*/ enr_ot_sib   		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_sibling_persistence} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ enrolled_1year_sib 	/*IV*/ none /*label*/ enrolled_1year_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${bw_sibling_persistence} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}	
	
	tables_pres_main 1 table_college_choice_persistence
	
	
	*- 3. School performance
	estimate_reg /*OUTCOME*/ std_gpa_m_b2_sib 	/*IV*/ none /*label*/ std_gpa_m_b2_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ std_gpa_c_b2_sib 	/*IV*/ none /*label*/ std_gpa_c_b2_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ std_gpa_m_b1_sib 	/*IV*/ none /*label*/ std_gpa_m_b1_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ std_gpa_c_b1_sib 	/*IV*/ none /*label*/ std_gpa_c_b1_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ std_gpa_m_a0_sib 	/*IV*/ none /*label*/ std_gpa_m_a0_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ std_gpa_c_a0_sib 	/*IV*/ none /*label*/ std_gpa_c_a0_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ std_gpa_m_a1_sib 	/*IV*/ none /*label*/ std_gpa_m_a1_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ std_gpa_c_a1_sib 	/*IV*/ none /*label*/ std_gpa_c_a1_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ std_gpa_m_a2_sib 	/*IV*/ none /*label*/ std_gpa_m_a2_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ std_gpa_c_a2_sib 	/*IV*/ none /*label*/ std_gpa_c_a2_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}	
	estimate_reg /*OUTCOME*/ score_math_std_4p_sib 	/*IV*/ none /*label*/ math_4p_sib  		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ score_com_std_4p_sib 	/*IV*/ none /*label*/ com_4p_sib   		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ score_math_std_2s_sib 	/*IV*/ none /*label*/ math_2s_sib  		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ score_com_std_2s_sib 	/*IV*/ none /*label*/ com_2s_sib   		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
 	
	tables_pres_main 1 table_school_performance
	tables_pres_main 1 table_school_performance_math
	tables_pres_main 1 table_school_performance_com
	
		*- 3b. School performance by grade
	forvalues t = 0(1)2 {
		if inlist(`t',0,1)==1		estimate_reg /*OUTCOME*/ std_gpa_m_7_a`t'_sib 	/*IV*/ none	/*label*/ std_gpa_m_7_a`t'_sib   /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
									estimate_reg /*OUTCOME*/ std_gpa_m_8_a`t'_sib 	/*IV*/ none	/*label*/ std_gpa_m_8_a`t'_sib   /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
									estimate_reg /*OUTCOME*/ std_gpa_m_9_a`t'_sib 	/*IV*/ none	/*label*/ std_gpa_m_9_a`t'_sib   /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
									estimate_reg /*OUTCOME*/ std_gpa_m_10_a`t'_sib 	/*IV*/ none	/*label*/ std_gpa_m_10_a`t'_sib  /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
		if inlist(`t',0,1)==1		estimate_reg /*OUTCOME*/ std_gpa_m_11_a`t'_sib 	/*IV*/ none	/*label*/  std_gpa_m_11_a`t'_sib /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	
	}
	tables_pres_main 1 table_school_performance_grade
	
	*- 4. School progression
	estimate_reg /*OUTCOME*/ approved_a0_sib /*IV*/ none /*label*/ approved_a0_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ approved_a1_sib /*IV*/ none /*label*/ approved_a1_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ dropout_ever_sib 	/*IV*/ none /*label*/ dropout_ever_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ sec_grad_sib 		/*IV*/ none /*label*/ sec_grad_sib  		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	
	tables_pres_main 1 table_school_progression
	
	
	*- 5. School aspirations for college
	estimate_reg /*OUTCOME*/ asp_college2_4p_sib /*IV*/ none /*label*/ asp_college2_4p_sib  /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ asp_college2_2s_sib /*IV*/ none /*label*/ asp_college2_2s_sib  /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ asp_college4_4p_sib /*IV*/ none /*label*/ asp_college4_4p_sib  /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ asp_college4_2s_sib /*IV*/ none /*label*/ asp_college4_2s_sib  /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}	
 
	tables_pres_main 1 table_school_aspirations
	tables_pres_main 1 table_school_aspirations_4
	
	
	*- 5. Heterogeneity
	//Define all heterogeneity vars
	xtile cat_score=score_acad_std_2p_sib, nq(2)	
	xtile cat_sch_applied = sch_applied_foc /*if (exp_graduating_year1_foc+1>=2017 & exp_graduating_year1_foc+1<=2023)*/, nq(2)
	recode cat_score cat_sch_applied (1=0) (2=1)
	gen same_region = (region_siagie_foc==region_foc)
	gen 	same_school = (id_ie_sec_foc==id_ie_sec_sib) if id_ie_sec_foc!="" & id_ie_sec_sib!=""
	replace same_school = (id_ie_pri_foc==id_ie_pri_sib) if id_ie_pri_foc!="" & id_ie_pri_sib!="" & id_ie_sec_sib=="" //For those younger siblings not in secondary yet

	
	foreach var in "h_pared" "cat_score" "cat_sch_applied" "same_region" "same_school" "applied_lpred1_above_foc" "rej_enr_b2_lpred1_above_foc" "rej_npr_b2_lpred1_above_foc"  "rej_one_b2_lpred1_above_foc" {
		forvalues i = 0/1 {
			preserve
				di as error 	"****************"
				di as text 		"****************"
				di as result 	"****************"
				di as text 		"Heterogeneity: `var'"
				keep if `var'==`i'
				estimate_reg /*OUTCOME*/ sec_grad_sib 			/*IV*/ none /*label*/ secg_sib`i'   		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
				estimate_reg /*OUTCOME*/ asp_college4_4p_sib 	/*IV*/ none /*label*/ asp_4_4p_sib`i'  		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
				estimate_reg /*OUTCOME*/ asp_college4_2s_sib 	/*IV*/ none /*label*/ asp_4_2s_sib`i'  		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}

				estimate_reg /*OUTCOME*/ applied_sib 			/*IV*/ none /*label*/ applied_sib`i'  		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
				estimate_reg /*OUTCOME*/ score_std_all_f_sib 	/*IV*/ none /*label*/ app_sco_all_sib`i'  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
				estimate_reg /*OUTCOME*/ score_std_uni_f_sib 	/*IV*/ none /*label*/ app_sco_uni_sib`i'  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}	

				estimate_reg /*OUTCOME*/ admitted_sib 			/*IV*/ none /*label*/ admitted_sib`i'  		/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
				estimate_reg /*OUTCOME*/ enrolled_sib 			/*IV*/ none /*label*/ enrolled_sib`i'   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}	
			restore
		}
	
	if "`var'" == "h_pared" 						tables_pres_main 1 table_heterogeneity "_h_pared" 							"Parents do not have any level of higher education" "Parents have some level of higher education"
	if "`var'" == "cat_score" 						tables_pres_main 1 table_heterogeneity "_cat_score" 						"Baseline academic score below median" 				"Baseline academic score above median"
	if "`var'" == "cat_sch_applied" 				tables_pres_main 1 table_heterogeneity "_cat_sch_applied" 					"Secondary school application rates below median" 	"Secondary school application rates above median"
	if "`var'" == "same_region" 					tables_pres_main 1 table_heterogeneity "_same_region" 						"Older sibling applies outside region" 				"Older sibling applies within region"
	if "`var'" == "same_school" 					tables_pres_main 1 table_heterogeneity "_same_school" 						"Sibling's went to different schools" 				"Siblings went to same schools"
	if "`var'" == "applied_lpred1_above_foc" 		tables_pres_main 1 table_heterogeneity "applied_lpred1_above_foc" 			"Older sibling likely not applying" 				"Older sibling likely applying"
	if "`var'" == "rej_enr_b2_lpred1_above_foc" 	tables_pres_main 1 table_heterogeneity "rej_enr_b2_lpred1_above_foc" 		"Older sibling likely not enrolling if rejected" 	"Older sibling likely enrolling if rejected"
	if "`var'" == "rej_npr_b2_lpred1_above_foc" 	tables_pres_main 1 table_heterogeneity "rej_npr_b2_lpred1_above_foc" 		"Older sibling likely not applying to private if rejected" 	"Older sibling likely applying to private if rejected"
	if "`var'" == "rej_one_b2_lpred1_above_foc" 	tables_pres_main 1 table_heterogeneity "rej_one_b2_lpred1_above_foc" 		"Older sibling likely not applying again if rejected" 	"Older sibling likely applying again if rejected"
	}
	
	
*- Application rates in high school
/*
estimates drop _all
	local groups = 2
	forvalues i = 1/`groups' {
		preserve
			local cat_heterog = "sch_applied_sib"
			xtile cat = `cat_heterog' if (exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023), nq(`groups')
			
			keep if cat==`i'
			
			
			estimate_reg_rf /*OUTCOME*/ applied_sib 		/*IV*/ enr_uni_major_sem_foc 		/*label*/ applied_sib`i'  		/*stack*/ ${main_stack} /*sibling*/ oldest /*relative to application*/ restrict /*semesters*/ first /*bw*/ fixed /*percentile*/  `i'  /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
			estimate_reg_rf /*OUTCOME*/ enrolled_sib 			/*IV*/ enr_uni_major_sem_foc 		/*label*/ enrolled_sib`i'  		/*stack*/ ${main_stack} /*sibling*/ oldest /*relative to application*/ restrict /*semesters*/ first /*bw*/ fixed /*percentile*/  `i'  /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}

		restore
	}	
	
	coefplot rf_applied_sib?   rf_enrolled_sib?   ///
			 /// (MAIN,mcolor(blue) ciopts(color(blue blue blue)) levels(99 95 90)) 
			 , ///
				mcolor(gs0) ciopts(color(gs0 gs0 gs0)) levels(99 95 90) ///
				keep(ABOVE? ABOVE??) ///
				xline(0) ///
				legend(off)	
	graph export 	"$FIGURES/eps/RD_sens_${outcome}_${siblings}_${rel_app}_${sem}_${bw_select_label}.eps", replace	
	graph export 	"$FIGURES/png/RD_sens_${outcome}_${siblings}_${rel_app}_${sem}_${bw_select_label}.png", replace	
	graph export 	"$FIGURES/pdf/RD_sens_${outcome}_${siblings}_${rel_app}_${sem}_${bw_select_label}.pdf", replace			
*/	
	
	**************
	* validation
	**************	
	
	*- 1. Extensive margin - placebo
	estimate_reg /*OUTCOME*/ applied_sib 			/*IV*/ none /*label*/ applied_sib  	/*stack*/ ${main_stack} /*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ applied_public_sib 	/*IV*/ none /*label*/ app_pu_sib   	/*stack*/ ${main_stack} /*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ applied_uni_sib 		/*IV*/ none /*label*/ app_u_sib   	/*stack*/ ${main_stack} /*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ applied_public_o_sib 	/*IV*/ none /*label*/ app_puo_sib   /*stack*/ ${main_stack} /*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ applied_private_sib 	/*IV*/ none /*label*/ app_pr_sib   	/*stack*/ ${main_stack} /*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ admitted_sib 			/*IV*/ none /*label*/ admitted_sib  /*stack*/ ${main_stack} /*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	estimate_reg /*OUTCOME*/ enrolled_sib 			/*IV*/ none /*label*/ enrolled_sib  /*stack*/ ${main_stack} /*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	
	tables_pres_main 1 table_main_extensive_placebo
	
	
	**************
	* Robustness
	**************
	******
	*- A. Sensitivity analysis for some variables
	******
	*- 1. Extensive margin
	rd_sensitivity /*OUTCOME*/ applied_sib 				/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ enrolled_sib 			/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}

	*- 2. Application performance/effort
	rd_sensitivity /*OUTCOME*/ applies_on_time_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ enrolls_on_time_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}	
	rd_sensitivity /*OUTCOME*/ N_applications_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}	
	rd_sensitivity /*OUTCOME*/ score_std_uni_u_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}

	
	*- 3. School performance and completion rates
	rd_sensitivity /*OUTCOME*/ std_gpa_m_b2_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ std_gpa_m_b1_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ std_gpa_m_a0_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ std_gpa_m_a1_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ std_gpa_m_a2_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}

	rd_sensitivity /*OUTCOME*/ std_gpa_c_b2_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ std_gpa_c_b1_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ std_gpa_c_a0_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ std_gpa_c_a1_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ std_gpa_c_a2_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	
	rd_sensitivity /*OUTCOME*/ sec_grad_sib 			/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ score_acad_std_4p_sib 	/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ score_acad_std_2s_sib 	/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ asp_college2_4p_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ asp_college4_4p_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ asp_college4_2s_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ asp_college2_2s_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	
	*- Placebo
	rd_sensitivity /*OUTCOME*/ applied_sib 				/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ oldest_placebo 	/*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ enrolled_sib 			/*IV*/ none	/*label*/ none /*stack*/ ${main_stack} /*sibling*/ oldest_placebo 	/*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ asp_college4_4p_sib 		/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ all_placebo 		/*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ score_acad_std_2p_sib 	/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ all_placebo 		/*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ score_acad_std_4p_sib 	/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ all_placebo		/*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	rd_sensitivity /*OUTCOME*/ score_acad_std_2s_sib 	/*IV*/ none /*label*/ none /*stack*/ ${main_stack} /*sibling*/ all_placebo 		/*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}	
	
	
	
	********
	*- B. Sensitivity to Fixed Effects
	********
	rename std_pred_gpa_?_ie_y_* std_pred_gpa_?_* 
	
	preserve
	//keep if R2==1
	foreach kern in "uniform" "triangular" {
	*- Sibling outcomes
	foreach v in ///
	/*APP PERF*/	"applied_sib" "applies_on_time_sib"  /*"applied_public_sib"*/ "applied_uni_sib" "admitted_sib" "score_std_uni_u_sib" "score_std_pub_o_u_sib" "enrolled_sib" "enrolls_on_time_sib" ///
	/*SCH PROG*/	"approved_a0_sib" "approved_a1_sib" "dropout_ever_sib" "sec_grad_sib" ///
	/*SCH PERF*/	"std_gpa_m_b2_sib"  "std_gpa_m_b1_sib" "std_gpa_m_a0_sib" "std_gpa_m_a1_sib" "std_gpa_m_a2_sib" "std_pred_gpa_m_b2_sib" "std_pred_gpa_m_b1_sib" "std_pred_gpa_m_a0_sib" "std_pred_gpa_m_a1_sib" "std_pred_gpa_m_a2_sib"  "std_gpa_c_b2_sib"  "std_gpa_c_b1_sib" "std_gpa_c_a0_sib" "std_gpa_c_a1_sib" "std_gpa_c_a2_sib" "std_pred_gpa_c_b2_sib" "std_pred_gpa_c_b1_sib" "std_pred_gpa_c_a0_sib" "std_pred_gpa_c_a1_sib" "std_pred_gpa_c_a2_sib" ///
	/*BELIEFS*/ 	"asp_college2_4p_sib" "asp_college4_4p_sib" "asp_college2_2s_sib" "asp_college4_2s_sib" ///
	   {
		estimate_reg /*OUTCOME*/ `v' /*IV*/ none /*label*/ `v'1  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ `kern' /*FE*/ nofe
		estimate_reg /*OUTCOME*/ `v' /*IV*/ none /*label*/ `v'2  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ `kern' /*FE*/ cm
		//estimate_reg /*OUTCOME*/ `v' /*IV*/ none /*label*/ `v'3  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ `kern' /*FE*/ y
		estimate_reg /*OUTCOME*/ `v' /*IV*/ none /*label*/ `v'4  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ `kern' /*FE*/ cm+y
		estimate_reg /*OUTCOME*/ `v' /*IV*/ none /*label*/ `v'5  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ `kern' /*FE*/ cmy

		//tables_pres_main 1 table_main_extensive_fes_`v' "" "" "" "`v'"
	}
	tables_pres_main 1 table_main_summary_fes_`kern'
	}
	restore
	
	
	
	*- Focal Child
	foreach v in "score_math_std_2s_foc"  {
		estimate_reg /*OUTCOME*/ `v' /*IV*/ none /*label*/ `v'1  	/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ nofe
		estimate_reg /*OUTCOME*/ `v' /*IV*/ none /*label*/ `v'2  	/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ cm
		estimate_reg /*OUTCOME*/ `v' /*IV*/ none /*label*/ `v'3  	/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ y
		estimate_reg /*OUTCOME*/ `v' /*IV*/ none /*label*/ `v'4  	/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ cm+y
		estimate_reg /*OUTCOME*/ `v' /*IV*/ none /*label*/ `v'5  	/*stack*/ student /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ cmy

		tables_pres_main 1 table_main_extensive_fes_`v' "" "" "" "`v'"
	}	



	/*
	*- 1. Extensive margin
	estimate_reg /*OUTCOME*/ applied_sib 			/*IV*/ none /*label*/ applied_sib  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ nofe
	estimate_reg /*OUTCOME*/ applied_public_sib 	/*IV*/ none /*label*/ app_pu_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ nofe
	estimate_reg /*OUTCOME*/ applied_uni_sib 		/*IV*/ none /*label*/ app_u_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ nofe
	estimate_reg /*OUTCOME*/ applied_public_o_sib 	/*IV*/ none /*label*/ app_puo_sib   /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ nofe
	estimate_reg /*OUTCOME*/ applied_private_sib 	/*IV*/ none /*label*/ app_pr_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ nofe
	estimate_reg /*OUTCOME*/ admitted_sib 			/*IV*/ none /*label*/ admitted_sib  /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ nofe
	estimate_reg /*OUTCOME*/ enrolled_sib 			/*IV*/ none /*label*/ enrolled_sib  /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ nofe
	
	tables_pres_main 1 table_main_extensive_nofe	
	
	
	*- 3. School performance
	estimate_reg /*OUTCOME*/ std_gpa_m_b2_sib 	/*IV*/ none /*label*/ std_gpa_m_b2_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}/*FE*/ nofe
	estimate_reg /*OUTCOME*/ std_gpa_m_b1_sib 	/*IV*/ none /*label*/ std_gpa_m_b1_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ nofe
	estimate_reg /*OUTCOME*/ std_gpa_m_a0_sib 	/*IV*/ none /*label*/ std_gpa_m_a0_sib   /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ nofe
	estimate_reg /*OUTCOME*/ std_gpa_m_a1_sib 	/*IV*/ none /*label*/ std_gpa_m_a1_sib   /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ nofe
	estimate_reg /*OUTCOME*/ std_gpa_m_a2_sib 	/*IV*/ none /*label*/ std_gpa_m_a2_sib   /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ nofe
	estimate_reg /*OUTCOME*/ score_math_std_4p_sib 	/*IV*/ none /*label*/ math_4p_sib  			/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ nofe
	estimate_reg /*OUTCOME*/ score_math_std_2s_sib 	/*IV*/ none /*label*/ math_2s_sib  			/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ nofe
 	
	tables_pres_main 1 table_school_performance_math_nofe
	*/
	********
	*- C. Subsamples
	********
	
	*- C.1. Leave enough room for applications to see it is not just an unobserved 'delay'. If just delay, you should see a bigger effect in later years and no effect in initial ones.
	preserve
		keep if (exp_graduating_year1_sib+1>=2023 & exp_graduating_year1_sib+1<=2023) 
		estimate_reg /*OUTCOME*/ applied_sib 	/*IV*/ none 	/*label*/ none0  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	restore

	preserve
		keep if (exp_graduating_year1_sib+1>=2020 & exp_graduating_year1_sib+1<=2022) 
		estimate_reg /*OUTCOME*/ applied_sib 	/*IV*/ none 	/*label*/ none1  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	restore
	
	preserve
		keep if (exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2019) 
		estimate_reg /*OUTCOME*/ applied_sib 	/*IV*/ none 	/*label*/ none2  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
	restore	

	estimates replay rf_none0
	estimates replay rf_none1
	estimates replay rf_none2
	// Effects are significant in all samples, not a clear pattern o decay.
	
	*- C.2. Those higly complying cutoffs (R2>0.9)
		preserve
			keep if R2<0.7
			estimate_reg /*OUTCOME*/ applied_sib 	/*IV*/ none /*label*/ applied_sib_R21  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
			estimate_reg /*OUTCOME*/ enrolled_sib 	/*IV*/ none /*label*/ enrolled_sib_R21  /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
		restore	
	
		preserve
			keep if R2>=0.7 & R2<0.9
			estimate_reg /*OUTCOME*/ applied_sib 	/*IV*/ none /*label*/ applied_sib_R22  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
			estimate_reg /*OUTCOME*/ enrolled_sib 	/*IV*/ none /*label*/ enrolled_sib_R22  /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}		
		restore	
	
		preserve
			keep if R2>=0.90
			estimate_reg /*OUTCOME*/ applied_sib 	/*IV*/ none /*label*/ applied_sib_R23  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
			estimate_reg /*OUTCOME*/ enrolled_sib 	/*IV*/ none /*label*/ enrolled_sib_R23  /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}		
		restore
		
	tables_pres_main 1 table_robust_R2
		
	*- B.3. Is the jump in enrolled_foc mainly because of delayed enrollment that is not yet seen? We look at first vs later years
		estimate_reg /*OUTCOME*/ enrolled_foc 		/*IV*/ none /*label*/ fs_enroll  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
		forvalues year = 2017/2023 {
			preserve
				keep if year_applied_foc == `year'
				estimate_reg /*OUTCOME*/ enrolled_foc 	/*IV*/ none /*label*/ fs_enrolled_`year'  	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*Kernel*/ ${main_kernel} /*FE*/ ${main_fes}
			restore
		}
			
	
			
end

	
********************************************
********************************************
********************************************

***** Run program

main


