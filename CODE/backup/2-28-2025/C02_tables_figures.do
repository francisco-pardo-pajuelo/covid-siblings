/********************************************************************************
- Author: Francisco Pardo
- Description: Produces final tables and figures
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/

capture program drop main 
program define main 

	setup


	first_stage 2 all student main
	first_stage 2 all student R2
	
	main_reg
	
	
	
	
	
	
	mccrary 2 all student
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
	
	
	
	
	

		


end





********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup

	set seed 1234
	global window = 2
	global mccrary_window = 2
	global redo_all = 0

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
	forvalues p = 1/5 {
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
	gen byte any_coll_2p_sib		= inlist(aspiration_2p_sib,3,4,5) if aspiration_2p_sib!=.
	gen byte any_coll_4p_sib		= inlist(aspiration_4p_sib,3,4,5) if aspiration_4p_sib!=.
	gen byte any_coll_2s_sib		= inlist(aspiration_2s_sib,3,4,5) if aspiration_2s_sib!=.	
	gen byte comp_sec_4p_sib		= inlist(aspiration_4p_sib,2,3,4,5) if aspiration_4p_sib!=.

	

	gen asp_years_4p_sib 	 = 6*(aspiration_4p_sib==1)+ 11*(aspiration_4p_sib==2)+ 14*(aspiration_4p_sib==3)+ 16*(aspiration_4p_sib==4)+18*(aspiration_4p_sib==5) if  aspiration_4p_sib!=.		
	gen asp_years_2s_sib 	 = 8*(aspiration_2s_sib==1)+ 11*(aspiration_2s_sib==2)+ 14*(aspiration_2s_sib==3)+ 16*(aspiration_2s_sib==4)+18*(aspiration_2s_sib==5) if  aspiration_2s_sib!=.
	gen applies_on_time_sib 	= (year_applied_sib<=(exp_graduating_year1_sib+1) & applied_sib==1) if exp_graduating_year1_sib!=.
	gen byte vlow_ses_foc 		= socioec_index_cat_2s_foc==1 if socioec_index_cat_2s_foc!=.

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
	rename (_m year) (enroll_stem_sib year_enroll_stem_sib)
	
	*- Enrolled NOT IN STEM
	merge m:1 id_per_umc using `enrolled_nstem_students', keep(master match) keepusing(year)
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enroll_nstem_sib year_enroll_nstem_sib)	
	
	rename (aux_id_per_umc id_per_umc) (id_per_umc id_per_umc_sib)
	*/
	//STEM
	gen stem_major = inlist(major_c1_cat,5,6,7)
	
	
	gen byte approved_sib = .
	gen byte approved_next_sib = .
	gen byte approved_first_sib = .
	gen byte approved_first_next_sib = .	
	gen byte change_ie_sib = .
	gen byte change_ie_next_sib = .	
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		replace approved_sib = approved_`y'_sib if year_app_foc == `y'
		replace approved_next_sib = approved_`y'_sib if year_app_foc+1 == `y'
		
		replace approved_first_sib = approved_first_`y'_sib if year_app_foc == `y'
		replace approved_first_next_sib = approved_first_`y'_sib if year_app_foc+1 == `y'	
		
		replace change_ie_sib = change_ie_`y'_sib if year_app_foc == `y'
		replace change_ie_next_sib = change_ie_`y'_sib if year_app_foc+1 == `y'			
	}
	
	
	*- Timing of application vars
	capture drop year_app_foc_*
	tab year_app_foc, gen(year_app_foc_)
	
	tab semester_foc, gen(semester_foc_)
	
	gen term = substr(semester_foc,6,1)
	destring term, replace		

end


********************************************************************************
* Prepare RD
********************************************************************************
capture program drop prepare_rd
program define prepare_rd

	estimates drop _all

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

		gen sample_applied_sib = (exp_graduating_year1_sib>=2016 & exp_graduating_year1_sib<=2022 & exp_graduating_year1_sib+1>year_app_foc)
	
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


		* Sibling sample
		if "${siblings}" == "all"				global if_sibs "1==1" //will be filtered by relative to application
		if "${siblings}" == "oldest"			global if_sibs "fam_order_${fam_type} == 1"
		if "${siblings}" == "older"				global if_sibs "fam_order_${fam_type} < fam_order_${fam_type}_sib"
	
		if "${siblings}" == "all_placebo"		global if_sibs "1==1" //will be filtered by relative to application
		if "${siblings}" == "oldest_placebo"	global if_sibs "fam_order_${fam_type}_sib == 1"
		if "${siblings}" == "older_placebo"		global if_sibs "fam_order_${fam_type}_sib < fam_order_${fam_type}"		

		* Applications sample
		if "${sem}" == "one" 			global if_apps "one_application==1"
		if "${sem}" == "first" 			global if_apps "first_sem_application==1"
		if "${sem}" == "first_sem_out" 	global if_apps "(last_year_foc + 1 == year_app_foc) & term==1" 	//First semester after finishing school.
		if "${sem}" == "first_year_out" global if_apps "(last_year_foc + 1 == year_app_foc)" //First semester after finishing school.
		if "${sem}" == "all" 			global if_apps "1==1"
		
		if inlist("${sem}","one","first","all","first_sem_out","first_year_out")==0  assert 1==0
		
		* Sample relative to application period (after (outcome) or before (placebo))
		if "${rel_app}" == "all"		global if_rel_app "1==1"
		
		local gap_after = 2
		local gap_before = 2
		
		local expected_grad_sib = "exp_graduating_year1_sib"
		
		if "${rel_app}" == "restrict" & inlist("${siblings}","all","oldest","older")==1		{ //If actual outcome, then restriction is for after
			if substr("${outcome}",-6,6) == "2p_sib"  			global if_rel_app "year_2p_sib>=year_app_foc" // Interested in cases where spillover sibling takes exam after focal application (often application is at the beginning of year so same year works). 
			if substr("${outcome}",-6,6) == "4p_sib"  			global if_rel_app "year_4p_sib>=year_app_foc"
			if substr("${outcome}",-6,6) == "2s_sib"  			global if_rel_app "year_2s_sib>=year_app_foc"
			if substr("${outcome}",-6,6) == "2p_sib"  			global if_rel_app "year_2p_sib>=year_app_foc"
			if strmatch("${outcome}","sec_grad*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_app_foc)" // Reference is when focal applies same year the other graduates (is ahead). Interested in cases where spillover sibling at least graduates same year  graduates at least on the same year as focal child (application would be after)
			if strmatch("${outcome}","applied*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_app_foc)" // Reference is when focal applies same year the other graduates (is ahead). Interested in cases where spillover sibling at least graduates same year  graduates at least on the same year as focal child (application would be after)
			if strmatch("${outcome}","admitted*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_app_foc)"
			if strmatch("${outcome}","enroll*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_app_foc)"
			if strmatch("${outcome}","applies_on_time*sib")==1	global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_app_foc)"
			if strmatch("${outcome}","N_app*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_app_foc)"
			if strmatch("${outcome}","score_std*sib")==1		global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_app_foc)"
			if strmatch("${outcome}","avg_enr_score*sib")==1	global if_rel_app "(`expected_grad_sib'+`gap_after'>=year_app_foc)"
		}
		
		if "${rel_app}" == "restrict" & inlist("${siblings}","all_placebo","oldest_placebo","older_placebo")==1		{ //If placebo outcome, then restriction is for before
			if substr("${outcome}",-6,6) == "2p_sib"  			global if_rel_app "year_2p_sib<year_app_foc" // Interested in cases where spillover sibling takes exam before focal application
			if substr("${outcome}",-6,6) == "4p_sib"  			global if_rel_app "year_4p_sib<year_app_foc"
			if substr("${outcome}",-6,6) == "2s_sib"  			global if_rel_app "year_2s_sib<year_app_foc"
			if substr("${outcome}",-6,6) == "2p_sib"  			global if_rel_app "year_2p_sib<year_app_foc"
			if strmatch("${outcome}","sec_grad*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_before'<year_app_foc)" // Interested in cases where spillover sibling graduates and has time to apply before focal child.
			if strmatch("${outcome}","admitted*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_before'<year_app_foc)" // Interested in cases where spillover sibling graduates and has time to apply before focal child.
			if strmatch("${outcome}","applied*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_before'<=year_app_foc)"
			if strmatch("${outcome}","enroll*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_before'<=year_app_foc)"
			if strmatch("${outcome}","applies_on_time*sib")==1	global if_rel_app "(`expected_grad_sib'+`gap_before'<=year_app_foc)"
			if strmatch("${outcome}","N_app*sib")==1			global if_rel_app "(`expected_grad_sib'+`gap_before'<=year_app_foc)"
			if strmatch("${outcome}","score_std*sib")==1		global if_rel_app "(`expected_grad_sib'+`gap_before'<=year_app_foc)"
			if strmatch("${outcome}","avg_enr_score*sib")==1	global if_rel_app "(`expected_grad_sib'+`gap_before'<=year_app_foc)"
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
		if "${outcome}" == "admitted" 						global if_out "1==1"
		if "${outcome}" == "enroll_uni_major_sem_foc" 		global if_out "1==1"
		if "${outcome}" == "enroll_sem_foc" 				global if_out "1==1"		
		if "${outcome}" == "enroll_uni_major_foc" 			global if_out "1==1"		
		if "${outcome}" == "enroll_uni_foc" 				global if_out "1==1"		
		if "${outcome}" == "enroll_foc" 					global if_out "1==1"
		if "${outcome}" == "enroll_public_foc" 				global if_out "1==1"
		if "${outcome}" == "enroll_private_foc" 			global if_out "1==1"
		if "${outcome}" == "enroll_public_o_foc" 			global if_out "1==1"
		if "${outcome}" == "avg_enr_score_math_std_2p_foc" 	global if_out "1==1"
		if "${outcome}" == "avg_enr_score_com_std_2p_foc" 	global if_out "1==1"
		if "${outcome}" == "avg_enr_score_acad_std_2p_foc" 	global if_out "1==1"
		if "${outcome}" == "avg_enr_score_math_std_2s_foc" 	global if_out "1==1"
		if "${outcome}" == "avg_enr_score_com_std_2s_foc" 	global if_out "1==1"
		if "${outcome}" == "avg_enr_score_acad_std_2s_foc" 	global if_out "1==1"	
		
		
		
		//school
		if "${outcome}" == "score_math_std_2p_sib" 		global if_out "year_2p_sib!=."
		if "${outcome}" == "score_acad_std_2p_sib" 		global if_out "year_2p_sib!=."
		if "${outcome}" == "score_com_std_2p_sib" 		global if_out "year_2p_sib!=."
		if "${outcome}" == "score_math_std_4p_sib" 		global if_out "year_4p_sib!=."
		if "${outcome}" == "score_com_std_4p_sib" 		global if_out "year_4p_sib!=."
		if "${outcome}" == "score_acad_std_4p_sib" 		global if_out "year_4p_sib!=."
		if "${outcome}" == "score_math_std_2s_sib" 		global if_out "year_2s_sib!=."
		if "${outcome}" == "score_com_std_2s_sib" 		global if_out "year_2s_sib!=."
		if "${outcome}" == "score_acad_std_2s_sib" 		global if_out "year_2s_sib!=."
		if "${outcome}" == "approved_sib" 				global if_out "1==1"
		if "${outcome}" == "approved_next_sib" 			global if_out "1==1"
		if "${outcome}" == "dropout_ever_sib" 			global if_out "1==1"
		if "${outcome}" == "sec_grad_sib" 				global if_out "(exp_graduating_year2_sib+1>=2017 & exp_graduating_year2_sib+1<=2023)" //In this case we use 'exp_graduating_year2_sib' instead of 'exp_graduating_year1_sib' cause it proxies better what we want to measure: who should be already graduated from high school rather than choices in applications (for which we want them to have finished school. Is that endogenous for the other case?)		
		
		//Aspirations and survey measures
		if "${outcome}" == "comp_sec_4p_sib"  			global if_out "year_4p_sib!=."
		if "${outcome}" == "any_coll_4p_sib"  			global if_out "year_4p_sib!=."
		if "${outcome}" == "higher_ed_4p_sib"  			global if_out "year_4p_sib!=."
		if "${outcome}" == "asp_years_4p_sib"  			global if_out "year_4p_sib!=."
		if "${outcome}" == "any_coll_2s_sib"  			global if_out "year_2s_sib!=."
		if "${outcome}" == "higher_ed_2s_sib"  			global if_out "year_2s_sib!=."
		if "${outcome}" == "asp_years_2s_sib"  			global if_out "year_2s_sib!=."
		
		//Gender beliefs
		if "${outcome}" == "std_belief_gender_boy_4p_sib"  		global if_out "year_4p_sib!=."
		if "${outcome}" == "std_belief_gender_girl_4p_sib"  	global if_out "year_4p_sib!=."
		if "${outcome}" == "std_belief_gender_4p_sib"  			global if_out "year_4p_sib!=."
		
		//university	
		if "${outcome}" == "applied_sib"  					global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "admitted_sib"  					global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "enroll_sib"  					global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"	
		if "${outcome}" == "applies_on_time_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
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
		
		//if "${outcome}" == "score_std_major_avg_sib" 		global if_out "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"

		if "${outcome}" == "avg_enr_score_math_std_2p_sib" 	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "avg_enr_score_com_std_2p_sib" 	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "avg_enr_score_acad_std_2p_sib" 	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "avg_enr_score_math_std_2s_sib" 	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "avg_enr_score_com_std_2s_sib" 	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "avg_enr_score_acad_std_2s_sib" 	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		
		//Application choices
		if "${outcome}" == "applied_public_sib" 		global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "applied_uni_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "applied_public_o_sib" 		global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "applied_private_sib" 		global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		
		if "${outcome}" == "enroll_uni_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "applied_uni_major_sib"  	global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "enroll_uni_major_sib"  		global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "applied_major_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "enroll_major_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		
		//STEM*/
		if "${outcome}" == "applied_stem_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "applied_nstem_sib" 			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "enroll_stem_sib"  			global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"
		if "${outcome}" == "enroll_uni_major_sib"  		global if_out "(`expected_grad_sib'+1>=2017 & `expected_grad_sib'+1<=2023)"	
	
	
	*- Consider all restrictions for sample of interest
	global if_pre "${if_sibs} & ${if_rel_app} & ${if_apps} & ${if_out}"
		

end		
	

********************************************************************************
* McCrary
********************************************************************************
capture program drop mccrary
program define mccrary

	args fam_type sem stack

	estimates drop _all

	global fam_type = `fam_type'
	global sem = "`sem'"
		
	use "$OUT/applied_outcomes_${fam_type}.dta", clear
	
	//gen any_sib_match = (region_siagie_sib!=.)

	additional_vars 	noz major
	prepare_rd 			
	
	if "`stack'" == "student" 			bys id_per_umc id_cutoff: keep if _n==1 // Use applicant database instead of applicant-sibling database
	if "`stack'" == "student_sibling" 	keep if 1==1 // Use applicant-sibling database
	
	histogram score_relative ///
	if abs(score_relative)<$mccrary_window ///
	,  ///
	fcolor(gs14) lcolor(gs0) xline(0, lcolor(red)) /*title("All cutoffs")*/ xtitle("Standardized score relative to cutoff")	 ///
	name(histogram_${sem}, replace)
	graph export 	"$FIGURES/eps/histogram_`stack'_${sem}.eps", replace	
	graph export 	"$FIGURES/png/histogram_`stack'_${sem}.png", replace	
	graph export 	"$FIGURES/pdf/histogram_`stack'_${sem}.pdf", replace	
	
			* Public schools
			// Get the estimate
		rddensity score_relative ///
			if abs(score_relative)<$mccrary_window ///
			, ///
			c(0) ///
			///p(1) /// are these required for mccrary? Or just for estimating outcomes? ###
			///q(2) ///
			kernel(triangular) ///
			all 
			
		local pval: display %9.3f e(pv_q)  

		// Plot the estimate directly (otherwise, it will use the previously stored e(pv_q))
		rddensity score_relative ///
			if abs(score_relative)<$mccrary_window ///
			, ///
			graph_opt(xtitle("Standardized score relative to cutoff") legend(off) note("McCrary Test p-val: 0.`pval'")) ///
			c(0) ///
			///p(1) /// are these required for mccrary? Or just for estimating outcomes? ###
			///q(2) ///
			kernel(triangular) ///
			all ///
			plot
		
	graph export 	"$FIGURES/eps/mccrary_`stack'_${sem}.eps", replace	
	graph export 	"$FIGURES/png/mccrary_`stack'_${sem}.png", replace	
	graph export 	"$FIGURES/pdf/mccrary_`stack'_${sem}.pdf", replace	
	
	global mccrary_pval_${sem} = e(pv_q)
end


********************************************************************************
* First Stage
********************************************************************************
capture program drop first_stage
program define first_stage

	args fam_type sem stack results

	estimates drop _all

	global fam_type = `fam_type'
	global sem = "`sem'"
		
	use "$OUT/applied_outcomes_${fam_type}.dta", clear

	additional_vars 	noz major
	prepare_rd 			
	
	if "`stack'" == "student" 			bys id_per_umc id_cutoff: keep if _n==1 // Use applicant database instead of applicant-sibling database
	if "`stack'" == "student_sibling" 	keep if 1==1 // Use applicant-sibling database
	if "`stack'" == ""					keep if 1==1 
	
	if "`results'" == "main" {
		
		foreach var in "admitted" "enroll_uni_major_sem_foc" "enroll_uni_sem_foc" "enroll_sem_foc" "enroll_uni_foc" "enroll_public_o_foc" "enroll_private_foc" "enroll_foc" {
			
		if "`var'" == "admitted" 					local ytitle = "Admitted"	
		if "`var'" == "enroll_uni_major_sem_foc" 	local ytitle = "Enrolled"
		if "`var'" == "enroll_uni_sem_foc" 			local ytitle = "Enrolled in target college"
		if "`var'" == "enroll_uni_sem_foc" 			local ytitle = "Enrolled in any college"
		if "`var'" == "enroll_uni_foc" 				local ytitle = "Enrolled in target college ever"
		if "`var'" == "enroll_public_o_foc" 		local ytitle = "Enrolled in other public college ever"		
		if "`var'" == "enroll_private_foc" 			local ytitle = "Enrolled in private college ever"
		if "`var'" == "enroll_foc" 					local ytitle = "Enrolled in any college ever"		
		
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
		graph export 	"$FIGURES/eps/first_stage_`var'.eps", replace	
		graph export 	"$FIGURES/png/first_stage_`var'.png", replace	
		graph export 	"$FIGURES/pdf/first_stage_`var'.pdf", replace	
		
		estimate_reg /*OUTCOME*/ `var' 				/*IV*/ none 	/*label*/ `var' 	/*sibling*/ oldest /*relative to application*/ restrict /*semesters*/ first /*bw*/ optimal			
		}
		tables_pres_main 1 table_first_stage
	}
	
	// By R2
	
	if "`results'" == "R2" {
		gen R2_cat = .
		replace R2_cat = 1 if R2<0.7
		replace R2_cat = 2 if R2>=0.7 & R2<0.9
		replace R2_cat = 3 if R2>=0.9 & R2!=.

		forvalues i = 1/3 {
			preserve
				keep if R2_cat == `i'
				
				binsreg admitted score_relative if abs(score_relative)<${window}, ///
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
					graph export 	"$FIGURES/eps/first_stage_admitted_R2_cat`i'.eps", replace	
					graph export 	"$FIGURES/png/first_stage_admitted_R2_cat`i'.png", replace	
					graph export 	"$FIGURES/pdf/first_stage_admitted_R2_cat`i'.pdf", replace
					
			estimate_reg /*OUTCOME*/ admitted 					/*IV*/ none 	/*label*/ fs_admitted_R2`i'  	/*sibling*/ oldest /*relative to application*/ restrict /*semesters*/ first /*bw*/ optimal		
			estimate_reg /*OUTCOME*/ enroll_uni_major_sem_foc 	/*IV*/ none 	/*label*/ fs_enrolled_R2`i'  	/*sibling*/ oldest /*relative to application*/ restrict /*semesters*/ first /*bw*/ optimal		
			
			
			
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
		
	use "$OUT/applied_outcomes_${fam_type}.dta", clear

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
	graph export 	"$FIGURES/png/balance_math_2s.png", replace	
	graph export 	"$FIGURES/eps/balance_math_2s.eps", replace	
	graph export 	"$FIGURES/pdf/balance_math_2s.pdf", replace	
		
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
		name(fs_enroll_uni_major_sem_foc, replace)
	graph export 	"$FIGURES/png/balance_com_2s.png", replace	
	graph export 	"$FIGURES/eps/balance_com_2s.eps", replace	
	graph export 	"$FIGURES/pdf/balance_com_2s.pdf", replace			
		
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
		name(fs_enroll_foc, replace)		
	graph export 	"$FIGURES/png/balance_acad_2s.png", replace	
	graph export 	"$FIGURES/eps/balance_acad_2s.eps", replace	
	graph export 	"$FIGURES/pdf/balance_acad_2s.pdf", replace	
	
end

	




********************************************************************************
* Regressions for tables #####
********************************************************************************

capture program drop estimate_reg
program define estimate_reg

	args outcome iv label siblings rel_app semesters bw covs_rdrob
	
	global iv = "`iv'"	
	
	//Define outcome globally in case needed to pass (for 'if_condition')
	global outcome = "`outcome'"
	
	//Sample
	global siblings "`siblings'"
	global rel_app ="`rel_app'"
	global sem = "`semesters'"
	global bw_select "`bw'"

	*- Get "if" condition for each outcome
	if_condition // & h`heterog_type' == `likely_val'
	
	di "if_condition done"
  
	*- We get the optimal bandwidths
	if "${bw_select}" == "optimal" & "${iv}" != "none" 	{
		rdrobust ${outcome} score_relative if ${if_pre}, ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(${iv}) ///
		  covs(`covs_rdrob'_*) //  covs(year_app_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
		  
		  global bw_${outcome} = e(h_l)
	}
	
	//For first stage, when not doing IV
	if "${bw_select}" == "optimal" &  "${iv}" == "none" 	{
		rdrobust ${outcome} score_relative if ${if_pre}, ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  covs(`covs_rdrob'_*) //  covs(year_app_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
		  
		  global bw_${outcome} = e(h_l)
	}	
	
	if "${bw_select}" == "fixed" 			global bw_${outcome} = 0.5	
	if inlist("`likely_val'","0","1")==1 	global if_final "${if_pre} & h`heterog_type' == `likely_val'"
	if inlist("`likely_val'","")==1 		global if_final "${if_pre}"				


	di as text "OPTIMAL BANDWIDTH" ${bw_${outcome}}
	
	//global bw_${outcome} = 0.8894
	*-- Reduced form
	if "${iv}" != "none" {
	ivreghdfe ${outcome}  ${scores_1} ${ABOVE_scores_1} (${iv} = ABOVE) ///  
			if ${if_final} ///
			& abs(score_relative)<${bw_${outcome}}, ///
			absorb(id_cutoff) cluster(id_fam_${fam_type}) ///
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
	reghdfe ${outcome} ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

		estadd ysumm
		estadd scalar bandwidth ${bw_${outcome}}
		estadd scalar FE e(df_a)
		if inlist("${outcome}","admitted","enroll_uni_major_sem_foc")==0 & "${iv}" != "none" estadd scalar fstage = `fs'
		estimates store rf_`label'

//
end


******

capture program drop estimate_reg_rf
program define estimate_reg_rf

	args outcome iv label siblings rel_app semesters bw percentile covs_rdrob
	
	global iv = "`iv'"	
	
	//Define outcome globally in case needed to pass (for 'if_condition')
	global outcome = "`outcome'"
	
	//Sample
	global siblings "`siblings'"
	global rel_app ="`rel_app'"
	global sem = "`semesters'"
	global bw_select "`bw'"
	
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
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(${iv}) ///
		  covs(`covs_rdrob'_*) //  covs(year_app_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
		  
		  global bw_${outcome} = e(h_l)
	}
	
	if "${bw_select}" == "fixed" 			global bw_${outcome} = 0.5	
	if inlist("`likely_val'","0","1")==1 	global if_final "${if_pre} & h`heterog_type' == `likely_val'"
	if inlist("`likely_val'","")==1 		global if_final "${if_pre}"				


	di as text "OPTIMAL BANDWIDTH" ${bw_${outcome}}
	
			
	*-- Reduced form
	reghdfe ${outcome} ABOVE`percentile'  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

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

args outcome iv label siblings rel_app semesters bw covs_rdrob
	
	
	*- Remove preexisting variables
	capture drop ABOVEopt
	capture drop ABOVE?
	capture drop ABOVE??
	
	global iv = "`iv'"	
	
	//Define outcome globally in case needed to pass (for 'if_condition')
	global outcome = "`outcome'"
	
	//Sample
	global siblings "`siblings'"
	global rel_app ="`rel_app'"
	global sem = "`semesters'"
	global bw_select "`bw'"

	*- Get "if" condition for each outcome
	if_condition // & h`heterog_type' == `likely_val'
	
	di "if_condition done"
  
	*- We get the optimal bandwidths
	if "${bw_select}" == "optimal" 	{
		rdrobust ${outcome} score_relative if ${if_pre}, ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(${iv}) ///
		  covs(`covs_rdrob'_*) //  covs(year_app_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
		  
		  global bw_${outcome} = e(h_l)
	}
	
	if "${bw_select}" == "fixed" 			global bw_${outcome} = 0.5	
	if inlist("`likely_val'","0","1")==1 	global if_final "${if_pre} & h`heterog_type' == `likely_val'"
	if inlist("`likely_val'","")==1 		global if_final "${if_pre}"	
	
	//Optimal
	global opt100 = int(${bw_${outcome}}*100)
	clonevar ABOVEopt = ABOVE
	label var ABOVEopt  " "
	reghdfe ${outcome} ABOVEopt  ${scores_1} ${ABOVE_scores_1} ///
	if ${if_final} ///
	& abs(score_relative)<${bw_${outcome}}, ///
	absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.
	
	estimates store rf_rd_opt
	*drop ABOVEopt	
		
	*-- Loop for each fixed window
	forvalues bw_window=1(1)10 { //We use integers instead of actual window in 0.1 steps for both easier labelling and because 'relocate' works better with integers.
	clonevar ABOVE`bw_window' = ABOVE //In order for ABOVE to be considered as different coefficients in each model and order them with coefplots independently so that we can place the optimal window at the appropriate place.
	local window_label = `bw_window'/10
	label var ABOVE`bw_window'  "`window_label'" // If we 'rename' in the coefplot command, the option 'relocate' does not work properly but rather would have to use the 'renamed' coefficients. This way it is easier to read the code.
	reghdfe ${outcome} ABOVE`bw_window'  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<`bw_window'/10, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.
		
		estimates store rf_rd_`bw_window'
		*drop ABOVE`bw_window'
	}
	
	
*- Plot RD estimates for each window	
coefplot 	(rf_rd_1 rf_rd_2 rf_rd_3 rf_rd_4 rf_rd_5 rf_rd_6 rf_rd_7 rf_rd_8 rf_rd_9 rf_rd_10, mcolor(gs0) ciopts(color(/*gs0 gs0*/ gs0)) levels(/*99 95*/ 90)) ///
			(rf_rd_opt,mcolor(blue) ciopts(color(/*blue blue*/ blue)) levels(/*99 95*/ 90)), ///
				keep(ABOVE? ABOVE?? ABOVE???) ///
				xline(0) ///
				relocate(ABOVE1 = 10 ABOVE2 = 20 ABOVE3 = 30 ABOVE4 = 40 ABOVE5 = 50 ABOVE6 = 60 ABOVE7 = 70 ABOVE8 = 80 ABOVE9 = 90 ABOVE10 = 100 ABOVEopt = ${opt100})	///
				legend(off)
	graph export 	"$FIGURES/eps/RD_sens_${outcome}_${siblings}_${rel_app}_${sem}_${bw_select}.eps", replace	
	graph export 	"$FIGURES/png/RD_sens_${outcome}_${siblings}_${rel_app}_${sem}_${bw_select}.png", replace	
	graph export 	"$FIGURES/pdf/RD_sens_${outcome}_${siblings}_${rel_app}_${sem}_${bw_select}.pdf", replace		
	

end




********************************************************************************
* tables for latex document
********************************************************************************

capture program drop tables_pres_main
program define tables_pres_main	

args scale table_type heterog_type panel_A panel_B

	global t_tex = "`table_type'"

	file open  table_tex	using "$TABLES\\${t_tex}`heterog_type'_PRES.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\makebox[0.1\width][l]{" _n ///
					"\resizebox{`scale'\textwidth}{!}{" _n
	file close table_tex
	
	

	tables_input_main PRES "`heterog_type'" "`panel_A'" "`panel_B'"
	
	file open  table_tex	using "$TABLES\\${t_tex}`heterog_type'_PRES.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule" _n ///
		"\end{tabular}" _n ///
		"}" _n ///
		"}" _n
	file close table_tex	


end


********************************************************************************
* tables for latex document
********************************************************************************
		
capture program drop tables_input_main
program define tables_input_main

	args t_suffix heterog_type panel_A panel_B 

	if "`t_suffix'" == "DOC" 	local suffix = ""
	if "`t_suffix'" == "PRES" 	local suffix = "_PRES"

*- We produce Table with estimates

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
					"&  &  &  & &  \\" _n 
	file close table_tex
	
	estout   rf_admitted rf_enroll_uni_major_sem_foc rf_enroll_sem_foc rf_enroll_uni_foc rf_enroll_private_foc rf_enroll_foc ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}
	

if inlist("${t_tex}","table_main_extensive","table_main_extensive_placebo") == 1 {
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

	estout  iv_applied_sib iv_app_pu_sib iv_app_u_sib iv_app_puo_sib iv_app_pr_sib iv_admitted_sib iv_enroll_sib ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout  rf_applied_sib rf_app_pu_sib rf_app_u_sib rf_app_puo_sib rf_app_pr_sib rf_admitted_sib rf_enroll_sib ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}
	
	

if inlist("${t_tex}","table_uni_performance") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& Applies on  		& \multicolumn{3}{c}{Number of Applications}   	& \multicolumn{5}{c}{Application Score}    \\" _n ///
					"\cmidrule(lr){2-2} \cmidrule(lr){3-5} \cmidrule(lr){6-10}" _n ///
					"& time  			& Total & First time 	& Same College 			& Any & Same College 	& Public 	& Other Colleges 	& Other Public		\\" _n ///
					"& (1) 				& (2) 	& (3) 			& (4) 					& (5) & (6) 			& (7) 		& (8)				& (9)	 \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  &  & \\" _n 
	file close table_tex

	estout  iv_app_ot_sib iv_N_apps_sib iv_N_apps_first_sib iv_N_apps_uni_sib iv_app_sco_all_sib iv_app_sco_uni_sib iv_app_sco_pub_sib iv_app_sco_uni_o_sib iv_app_sco_pub_o_sib  ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout  rf_app_ot_sib rf_N_apps_sib rf_N_apps_first_sib rf_N_apps_uni_sib rf_app_sco_all_sib rf_app_sco_uni_sib rf_app_sco_pub_sib rf_app_sco_uni_o_sib rf_app_sco_pub_o_sib  ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}
	
	
	
if inlist("${t_tex}","table_school") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" & Completed  			&  \multicolumn{2}{c}{4th grade}  		& \multicolumn{2}{c}{8th grade}     \\" _n ///
					" & Secondary   		& Academic score  	& 4-year college expectation & Academic score  	& 4-year college expectation  \\" _n ///
					"\cmidrule(lr){2-2} \cmidrule(lr){3-4} \cmidrule(lr){5-6}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& (1) 				& (2) 			& (3) 			& (4) 			& (5) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  &  & \\" _n 
	file close table_tex

	estout  iv_secg_sib iv_acad_4p_sib iv_asp_4_4p_sib iv_acad_2s_sib  iv_asp_4_2s_sib  ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout rf_secg_sib rf_acad_4p_sib rf_asp_4_4p_sib rf_acad_2s_sib  rf_asp_4_2s_sib ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
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
	
	estout  iv_asp_4_4p_sib0 iv_asp_4_2s_sib0 iv_secg_sib0  iv_applied_sib0  iv_app_sco_all_sib0 iv_app_sco_uni_sib0 iv_admitted_sib0 iv_enroll_sib0   ///
	using "$TABLES\\${t_tex}`heterog_type'`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout rf_asp_4_4p_sib0 rf_asp_4_2s_sib0 rf_secg_sib0  rf_applied_sib0  rf_app_sco_all_sib0 rf_app_sco_uni_sib0 rf_admitted_sib0 rf_enroll_sib0 ///
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
	
	
	estout  iv_asp_4_4p_sib1 iv_asp_4_2s_sib1 iv_secg_sib1  iv_applied_sib1  iv_app_sco_all_sib1 iv_app_sco_uni_sib1 iv_admitted_sib1 iv_enroll_sib1   ///
	using "$TABLES\\${t_tex}`heterog_type'`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout rf_asp_4_4p_sib1 rf_asp_4_2s_sib1 rf_secg_sib1  rf_applied_sib1  rf_app_sco_all_sib1 rf_app_sco_uni_sib1 rf_admitted_sib1 rf_enroll_sib1 ///
	using "$TABLES\\${t_tex}`heterog_type'`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
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
	stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
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
	


	estout  iv_applied_sib_R21 iv_enroll_sib_R21  iv_applied_sib_R22 iv_enroll_sib_R22  iv_applied_sib_R23 iv_enroll_sib_R23  ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout rf_applied_sib_R21 rf_enroll_sib_R21  rf_applied_sib_R22 rf_enroll_sib_R22  rf_applied_sib_R23 rf_enroll_sib_R23 ///
	using "$TABLES\\${t_tex}`suffix'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)		
	
}
		

end





	
********************************************************************************
* Regressions for tables
********************************************************************************

capture program drop main_reg
program define main_reg


	clear
	
	global ignore = 1 
	
	//Sample
	global fam_type = 2
	
	//Specification details
	
	global main_sibling_sample = "oldest"
	global main_rel_app = "restrict"
	global main_term = "first"
	global main_bw = "optimal"
	global main_covs_rdrob = "year_app_foc" //semester_foc
	
	
	

	
	use "$OUT/applied_outcomes_${fam_type}.dta", clear

	additional_vars 	noz major
	prepare_rd 			

	isvar ///
		/*ID*/						id_cutoff id_fam_* fam_order_${fam_type} fam_order_${fam_type}_sib id_ie_???_??? ///
		/*RD*/						score_relative  score_relative_* ABOVE_score_relative_* ABOVE admitted enroll_uni_major_sem_foc ///
		/*Geographic*/				region_siagie_foc region_foc ///
		/*cutoff*/					R2 N_below N_above ///		
		/*First stage*/				admitted enroll_uni_major_sem_foc enroll_sem_foc enroll_uni_foc enroll_uni_major_foc enroll_uni_foc enroll_foc  avg_enr_score_*_std_??_foc ///
		/*sample*/					first_sem_application one_application oldest sample_oldest last_year_foc year_app_foc semester_foc term semester_foc_* year_app_foc_* ///
		/*school characteristic*/	sch*_sib ///
		/*Other*/					year_app_foc universidad codigo_modular  ///
		/*Demographics*/			exp_graduating_year?_sib year_2p_sib year_4p_sib year_2s_sib male_siagie_foc male_siagie_sib ///
		/*Choices*/					stem_major ///
		/*Balance*/					male_foc age score_math_std_2?_foc score_com_std_2?_foc score_acad_std_2?_foc higher_ed_mother vlow_ses_foc ///
		/*SIBLING CHOICES*/			applied_uni_sib enroll_uni_sib applied_uni_major_sib enroll_uni_major_sib applied_major_sib enroll_major_sib applied_sib enroll_sib applied_public_sib applied_public_o_sib applied_private_sib  ///
		/*SIBLING CHOICES STEM*/	applied_stem_sib applied_nstem_sib enroll_stem_sib enroll_nstem_sib ///
		/*SIBLING School*/			score_math_std_??_sib score_com_std_??_sib score_acad_std_??_sib approved_sib approved_next_sib approved_first_sib approved_first_next_sib dropout_ever_sib pri_grad_sib sec_grad_sib year_graduate_sib change_ie_sib change_ie_next_sib ///
		/*SIBLING Survey*/			comp_sec_4p_sib any_coll_4p_sib higher_ed_4p_sib asp_years_4p_sib any_coll_2s_sib higher_ed_2s_sib asp_years_2s_sib std_belief_gender*_??_sib ///
 		/*SIBLING University*/		admitted_sib applies_on_time_sib N_applications_*sib score_std_*_sib avg_enr_score_*_std_??_sib  applied_public_tot_sib enroll_public_tot_sib ///
		/*Heterogeneity*/			age_gap likely_enrolled* h_*
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'

	//binsreg admitted score_relative
	 
	*- Estimate Bandwidth:
	//Note: The bandwidth is estimated without cutoff fixed effects due to restrictions of 'rdrobust' on using high dimension fixed effects. The final regression will include fixed effects and some robustness of different bandwidths will be shown in the appendix.
	//Similar options as in Altmejd et. al. (2021) for Chile and Croatia have been used.	
	
	if ${ignore}==0 {
	*- MAIN RESULTS (TEST)
	estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ test  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}

	estimate_reg /*OUTCOME*/ higher_ed_4p_sib 		/*IV*/ enroll_uni_major_sem_foc 		/*label*/ test  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ higher_ed_4p_sib 		/*IV*/ enroll_uni_major_sem_foc 		/*label*/ test  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	
	estimate_reg /*OUTCOME*/ score_std_uni_u_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ test  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ score_std_uni_f_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ test  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}

	
	
	//FIX public_o
	
	*- Potential new results
	//Results higher for those with low expectations
	preserve
		keep if higher_ed_2s_sib==0
		estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ test  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	restore	
	
	
	*- Heterogeneity
	*-- Oldest didn't apply
	preserve
		bys id_fam_${fam_type}: egen oldest_sib_to_apply = min(fam_order_${fam_type})
		keep if oldest_sib_to_apply>1
		estimate_reg /*OUTCOME*/ applied_sib 			/*IV*/ enroll_uni_major_sem_foc 		/*label*/ applied_sib`i'  		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	restore
	
	
	preserve
	// By n of observations above and below
	
	restore
	
	preserve
	// cat_sch_applied
		keep if cat_sch_applied==0
		estimate_reg /*OUTCOME*/ higher_ed_4p_sib 		/*IV*/ enroll_uni_major_sem_foc 		/*label*/ asp_4_4p_sib`i'  		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}	
		
	restore	
	
	}
	
	
	

	
	**************
	* Final results
	**************
	*- 0. First Stage
	

	*- 1. Extensive margin
	estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ applied_sib  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ applied_public_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_pu_sib   	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ applied_uni_sib 			/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_u_sib   	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ applied_public_o_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_puo_sib   /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ applied_private_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_pr_sib   	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ admitted_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ admitted_sib  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ enroll_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ enroll_sib   	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	
	tables_pres_main 1 table_main_extensive
	
	
	*- 2. Application performance/effort
	estimate_reg /*OUTCOME*/ applies_on_time_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_ot_sib   			/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ N_applications_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ N_apps_sib   			/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ N_applications_first_sib 	/*IV*/ enroll_uni_major_sem_foc 	/*label*/ N_apps_first_sib   	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ N_applications_uni_sib 	/*IV*/ enroll_uni_major_sem_foc 	/*label*/ N_apps_uni_sib   		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}

	estimate_reg /*OUTCOME*/ score_std_all_u_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_all_sib  		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ score_std_uni_u_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_uni_sib  		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ score_std_pub_u_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_pub_sib  		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ score_std_uni_o_u_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_uni_o_sib  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ score_std_pub_o_u_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_pub_o_sib  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}


	
	tables_pres_main 1 table_uni_performance
	
	*- 3. School performance and completion rates
	estimate_reg /*OUTCOME*/ sec_grad_sib 			/*IV*/ enroll_uni_major_sem_foc 			/*label*/ secg_sib   	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ score_acad_std_4p_sib 	/*IV*/ enroll_uni_major_sem_foc 			/*label*/ acad_4p_sib   /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ score_acad_std_2s_sib 	/*IV*/ enroll_uni_major_sem_foc 			/*label*/ acad_2s_sib   /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ higher_ed_4p_sib 		/*IV*/ enroll_uni_major_sem_foc 			/*label*/ asp_4_4p_sib  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ higher_ed_2s_sib 		/*IV*/ enroll_uni_major_sem_foc 			/*label*/ asp_4_2s_sib  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
 
	tables_pres_main 1 table_school
	
	
	*- 4. Heterogeneity
	//Define all heterogeneity vars
	xtile cat_score=score_acad_std_2p_sib, nq(2)	
	xtile cat_sch_applied = sch_applied_foc /*if (exp_graduating_year1_foc+1>=2017 & exp_graduating_year1_foc+1<=2023)*/, nq(2)
	recode cat_score cat_sch_applied (1=0) (2=1)
	gen same_region = (region_siagie_foc==region_foc)
	gen 	same_school = (id_ie_sec_foc==id_ie_sec_sib) if id_ie_sec_foc!="" & id_ie_sec_sib!=""
	replace same_school = (id_ie_pri_foc==id_ie_pri_sib) if id_ie_pri_foc!="" & id_ie_pri_sib!="" & id_ie_sec_sib=="" //For those younger siblings not in secondary yet

	
	foreach var in "h_pared" "cat_score" "cat_sch_applied" "same_region" "same_school" {
		forvalues i = 0/1 {
			preserve
				di as text "Heterogeneity: `var'"
				keep if `var'==`i'
				estimate_reg /*OUTCOME*/ sec_grad_sib 			/*IV*/ enroll_uni_major_sem_foc 		/*label*/ secg_sib`i'   		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
				estimate_reg /*OUTCOME*/ higher_ed_4p_sib 		/*IV*/ enroll_uni_major_sem_foc 		/*label*/ asp_4_4p_sib`i'  		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
				estimate_reg /*OUTCOME*/ higher_ed_2s_sib 		/*IV*/ enroll_uni_major_sem_foc 		/*label*/ asp_4_2s_sib`i'  		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}

				estimate_reg /*OUTCOME*/ applied_sib 			/*IV*/ enroll_uni_major_sem_foc 		/*label*/ applied_sib`i'  		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
				estimate_reg /*OUTCOME*/ score_std_all_u_sib 	/*IV*/ enroll_uni_major_sem_foc 		/*label*/ app_sco_all_sib`i'  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
				estimate_reg /*OUTCOME*/ score_std_uni_u_sib 	/*IV*/ enroll_uni_major_sem_foc 		/*label*/ app_sco_uni_sib`i'  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}	

				estimate_reg /*OUTCOME*/ admitted_sib 			/*IV*/ enroll_uni_major_sem_foc 		/*label*/ admitted_sib`i'  		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
				estimate_reg /*OUTCOME*/ enroll_sib 			/*IV*/ enroll_uni_major_sem_foc 		/*label*/ enroll_sib`i'   		/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}	
			restore
		}
	
	if "`var'" == "h_pared" 		tables_pres_main 1 table_heterogeneity "_h_pared" 			"Parents do not have any level of higher education" "Parents have some level of higher education"
	if "`var'" == "cat_score" 		tables_pres_main 1 table_heterogeneity "_cat_score" 		"Baseline academic score below median" 				"Baseline academic score above median"
	if "`var'" == "cat_sch_applied" tables_pres_main 1 table_heterogeneity "_cat_sch_applied" 	"Secondary school application rates below median" 	"Secondary school application rates above median"
	if "`var'" == "same_region" 	tables_pres_main 1 table_heterogeneity "_same_region" 		"Older sibling applies outside region" 				"Older sibling applies within region"
	if "`var'" == "same_school" 	tables_pres_main 1 table_heterogeneity "_same_school" 		"Sibling's went to different schools" 				"Siblings went to same schools"
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
			
			
			estimate_reg_rf /*OUTCOME*/ applied_sib 		/*IV*/ enroll_uni_major_sem_foc 		/*label*/ applied_sib`i'  		/*sibling*/ oldest /*relative to application*/ restrict /*semesters*/ first /*bw*/ fixed /*percentile*/  `i'
			estimate_reg_rf /*OUTCOME*/ enroll_sib 			/*IV*/ enroll_uni_major_sem_foc 		/*label*/ enroll_sib`i'  		/*sibling*/ oldest /*relative to application*/ restrict /*semesters*/ first /*bw*/ fixed /*percentile*/  `i'

		restore
	}	
	
	coefplot rf_applied_sib?   rf_enroll_sib?   ///
			 /// (MAIN,mcolor(blue) ciopts(color(blue blue blue)) levels(99 95 90)) 
			 , ///
				mcolor(gs0) ciopts(color(gs0 gs0 gs0)) levels(99 95 90) ///
				keep(ABOVE? ABOVE??) ///
				xline(0) ///
				legend(off)	
	graph export 	"$FIGURES/eps/RD_sens_${outcome}_${siblings}_${rel_app}_${sem}_${bw_select}.eps", replace	
	graph export 	"$FIGURES/png/RD_sens_${outcome}_${siblings}_${rel_app}_${sem}_${bw_select}.png", replace	
	graph export 	"$FIGURES/pdf/RD_sens_${outcome}_${siblings}_${rel_app}_${sem}_${bw_select}.pdf", replace			
*/	
	
	**************
	* validation
	**************	
	
	*- 1. Extensive margin - placebo
	estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ applied_sib  	/*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ applied_public_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_pu_sib   	/*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ applied_uni_sib 			/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_u_sib   	/*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ applied_public_o_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_puo_sib   /*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ applied_private_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_pr_sib   	/*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ admitted_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ admitted_sib  /*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	estimate_reg /*OUTCOME*/ enroll_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ enroll_sib   	/*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	
	tables_pres_main 1 table_main_extensive_placebo
	
	
	**************
	* Robustness
	**************
	******
	*- A. Sensitivity analysis for some variables
	******
	*- 1. Extensive margin
	rd_sensitivity /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ none  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	rd_sensitivity /*OUTCOME*/ enroll_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ none   	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}

	*- 2. Application performance/effort
	rd_sensitivity /*OUTCOME*/ applies_on_time_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ none   	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	rd_sensitivity /*OUTCOME*/ N_applications_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ none   	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}	
	rd_sensitivity /*OUTCOME*/ score_std_uni_u_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ none  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	
	*- 3. School performance and completion rates
	rd_sensitivity /*OUTCOME*/ sec_grad_sib 			/*IV*/ enroll_uni_major_sem_foc 			/*label*/ none  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	rd_sensitivity /*OUTCOME*/ score_acad_std_4p_sib 	/*IV*/ enroll_uni_major_sem_foc 			/*label*/ none  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	rd_sensitivity /*OUTCOME*/ score_acad_std_2s_sib 	/*IV*/ enroll_uni_major_sem_foc 			/*label*/ none  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	rd_sensitivity /*OUTCOME*/ higher_ed_4p_sib 		/*IV*/ enroll_uni_major_sem_foc 			/*label*/ none  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	rd_sensitivity /*OUTCOME*/ higher_ed_2s_sib 		/*IV*/ enroll_uni_major_sem_foc 			/*label*/ none  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	
	*- Placebo
	rd_sensitivity /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 			/*label*/ none /*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	rd_sensitivity /*OUTCOME*/ enroll_sib 				/*IV*/ enroll_uni_major_sem_foc 			/*label*/ none /*sibling*/ oldest_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	rd_sensitivity /*OUTCOME*/ higher_ed_4p_sib 		/*IV*/ enroll_uni_major_sem_foc 			/*label*/ none /*sibling*/ all_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	rd_sensitivity /*OUTCOME*/ score_acad_std_2p_sib 	/*IV*/ enroll_uni_major_sem_foc 			/*label*/ none /*sibling*/ all_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	rd_sensitivity /*OUTCOME*/ score_acad_std_4p_sib 	/*IV*/ enroll_uni_major_sem_foc 			/*label*/ none /*sibling*/ all_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}	
	rd_sensitivity /*OUTCOME*/ score_acad_std_2s_sib 	/*IV*/ enroll_uni_major_sem_foc 			/*label*/ none /*sibling*/ all_placebo /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}		
	
	
	********
	*- B. Subsamples
	********
	
	*- B.1. Leave enough room for applications to see it is not just an unobserved 'delay'. If just delay, you should see a bigger effect in later years and no effect in initial ones.
	preserve
		keep if (exp_graduating_year1_sib+1>=2023 & exp_graduating_year1_sib+1<=2023) 
		estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ none0  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	restore

	preserve
		keep if (exp_graduating_year1_sib+1>=2020 & exp_graduating_year1_sib+1<=2022) 
		estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ none1  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	restore
	
	preserve
		keep if (exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2019) 
		estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ none2  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
	restore	

	estimates replay rf_none0
	estimates replay rf_none1
	estimates replay rf_none2
	// Effects are significant in all samples, not a clear pattern o decay.
	
	*- B.2. Those higly complying cutoffs (R2>0.9)
		preserve
			keep if R2<0.7
			estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ applied_sib_R21  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
			estimate_reg /*OUTCOME*/ enroll_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ enroll_sib_R21  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
		restore	
	
		preserve
			keep if R2>=0.7 & R2<0.9
			estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ applied_sib_R22  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
			estimate_reg /*OUTCOME*/ enroll_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ enroll_sib_R22  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}		
		restore	
	
		preserve
			keep if R2>=0.90
			estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ applied_sib_R23  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
			estimate_reg /*OUTCOME*/ enroll_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ enroll_sib_R23  /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}		
		restore
		
	tables_pres_main 1 table_robust_R2
		
	*- B.3. Is the jump in enrolled_foc mainly because of delayed enrollment that is not yet seen? We look at first vs later years
		estimate_reg /*OUTCOME*/ enroll_foc 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ fs_enroll  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
		forvalues year = 2017/2023 {
			preserve
				keep if year_app_foc == `year'
				estimate_reg /*OUTCOME*/ enroll_foc 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ fs_enroll_`year'  	/*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob}
			restore
		}
			
	
			
end

	
********************************************
********************************************
********************************************

***** Run program

main


