/********************************************************************************
- Author: Francisco Pardo
- Description: Produces final tables and figures
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/

capture program drop main 
program define main 

	setup

	
	/*
	RESTRICT TO RELEVANT SAMPLE (if_apps) 
	mccrary 2 all student
	mccrary 2 all student_sibling
	mccrary 2 first student
	mccrary 2 first student_sibling
	*/
	
	
	*first_stage 2 all
	*visual_balance 2 first
	*visual_balance 2 all
	
	/*
	all
	t_first_stage_1
	t_first_stage_2
	t_balance
	t_sib_choices
	t_sib_stem
	t_sib_school
	t_sib_prog
	t_sib_univ_1
	t_sib_univ_2
	t_sib_asp
	t_sib_gender
	t_sib_heterog
	t_sib_heterog_asp_gen
	t_sib_heterog_stem
	*/
	
	//family ID, sample (all, first...), outcomes (all, t_balance,...) , bandwidth (optimal, fixed)
	//e.g.
	//regressions 2 first t_sib_heterog_stem fixed
	
	*Full run
	/*
	regressions 2 all all optimal
	regressions 2 all all fixed
	regressions 2 first all optimal
	regressions 2 first all fixed	
	*/
	
	*Test Run
	//test_reg
	main_reg

		


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

end


********************************************************************************
* Prepare RD
********************************************************************************
capture program drop prepare_rd
program define prepare_rd

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

		gen sample_oldest = (fam_order_${fam_type} == 1)

		gen sample_applied_sib = (exp_graduating_year1_sib>=2016 & exp_graduating_year1_sib<=2022 & exp_graduating_year1_sib+1>year_app_foc)
	
	*- Only oldest brother
	keep if sample_oldest==1 

	
	
	
	
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


		* Applications sample
		if "${sem}" == "one" 			global if_apps "one_application==1"
		if "${sem}" == "first" 			global if_apps "first_sem_application==1"
		if "${sem}" == "first_sem_out" 	global if_apps "(last_year_foc + 1 == year_app_foc) & term==1" 	//First semester after finishing school.
		if "${sem}" == "first_year_out" global if_apps "(last_year_foc + 1 == year_app_foc)" //First semester after finishing school.
		if "${sem}" == "all" 			global if_apps "1==1"
		
		if inlist("${sem}","one","first","all","first_sem_out","first_year_out")==0  assert 1==0

		* Variable sample
		//Balance
		if "${outcome}" == "male_foc" 					global if_pre "1==1"
		if "${outcome}" == "age" 						global if_pre "1==1"
		if "${outcome}" == "higher_ed_mother" 			global if_pre "1==1"
		if "${outcome}" == "vlow_ses_foc" 				global if_pre "1==1"
		if "${outcome}" == "score_math_std_2p_foc" 		global if_pre "1==1"		
		if "${outcome}" == "score_com_std_2p_foc" 		global if_pre "1==1"
		if "${outcome}" == "score_acad_std_2p_foc" 		global if_pre "1==1"
		if "${outcome}" == "score_math_std_2s_foc" 		global if_pre "1==1"		
		if "${outcome}" == "score_com_std_2s_foc" 		global if_pre "1==1"
		if "${outcome}" == "score_acad_std_2s_foc" 		global if_pre "1==1"	
		
		//First Stage
		if "${outcome}" == "admitted" 						global if_pre "1==1"
		if "${outcome}" == "enroll_uni_major_sem_foc" 		global if_pre "1==1"
		if "${outcome}" == "enroll_sem_foc" 				global if_pre "1==1"		
		if "${outcome}" == "enroll_uni_major_foc" 			global if_pre "1==1"		
		if "${outcome}" == "enroll_uni_foc" 				global if_pre "1==1"		
		if "${outcome}" == "enroll_foc" 					global if_pre "1==1"
		if "${outcome}" == "enroll_public_foc" 				global if_pre "1==1"
		if "${outcome}" == "enroll_private_foc" 			global if_pre "1==1"
		if "${outcome}" == "enroll_public_o_foc" 			global if_pre "1==1"
		if "${outcome}" == "avg_enr_score_math_std_2p_foc" 	global if_pre "1==1"
		if "${outcome}" == "avg_enr_score_com_std_2p_foc" 	global if_pre "1==1"
		if "${outcome}" == "avg_enr_score_acad_std_2p_foc" 	global if_pre "1==1"
		if "${outcome}" == "avg_enr_score_math_std_2s_foc" 	global if_pre "1==1"
		if "${outcome}" == "avg_enr_score_com_std_2s_foc" 	global if_pre "1==1"
		if "${outcome}" == "avg_enr_score_acad_std_2s_foc" 	global if_pre "1==1"

		//Application choices
		if "${outcome}" == "applied_public_sib" 		global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "applied_uni_sib" 			global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "applied_public_o_sib" 		global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "applied_private_sib" 		global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		
		if "${outcome}" == "enroll_uni_sib" 			global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "applied_uni_major_sib"  	global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "enroll_uni_major_sib"  		global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "applied_major_sib" 			global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "enroll_major_sib" 			global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		
		//STEM*/
		if "${outcome}" == "applied_stem_sib" 			global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "applied_nstem_sib" 			global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "enroll_stem_sib"  			global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "enroll_uni_major_sib"  		global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"		
		
		//school
		if "${outcome}" == "score_math_std_2p_sib" 		global if_pre "year_2p_sib>=year_app_foc & year_2p_sib!=."
		if "${outcome}" == "score_acad_std_2p_sib" 		global if_pre "year_2p_sib>=year_app_foc & year_2p_sib!=."
		if "${outcome}" == "score_com_std_2p_sib" 		global if_pre "year_2p_sib>=year_app_foc & year_2p_sib!=."
		if "${outcome}" == "score_math_std_4p_sib" 		global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "score_com_std_4p_sib" 		global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "score_acad_std_4p_sib" 		global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "score_math_std_2s_sib" 		global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		if "${outcome}" == "score_com_std_2s_sib" 		global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		if "${outcome}" == "score_acad_std_2s_sib" 		global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		if "${outcome}" == "approved_sib" 				global if_pre "1==1"
		if "${outcome}" == "approved_next_sib" 			global if_pre "1==1"
		if "${outcome}" == "dropout_ever_sib" 			global if_pre "1==1"
		if "${outcome}" == "sec_grad_sib" 				global if_pre "(exp_graduating_year2_sib+1>=2017 & exp_graduating_year2_sib+1<=2023) & (exp_graduating_year2_sib+2>=year_app_foc)" //In this case we use 'exp_graduating_year2_sib' instead of 'exp_graduating_year1_sib' cause it proxies better what we want to measure: who should be already graduated from high school rather than choices in applications (for which we want them to have finished school. Is that endogenous for the other case?)
		
		//university	
		if "${outcome}" == "applied_sib"  					global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "admitted_sib"  					global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "enroll_sib"  					global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"	
		if "${outcome}" == "applies_on_time_sib" 			global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "N_applications_sib" 			global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "score_std_major_avg_sib" 		global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "avg_enr_score_math_std_2p_sib" 	global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "avg_enr_score_com_std_2p_sib" 	global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "avg_enr_score_acad_std_2p_sib" 	global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "avg_enr_score_math_std_2s_sib" 	global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "avg_enr_score_com_std_2s_sib" 	global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "avg_enr_score_acad_std_2s_sib" 	global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		
		//Aspirations and survey measures
		if "${outcome}" == "comp_sec_4p_sib"  			global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "any_coll_4p_sib"  			global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "higher_ed_4p_sib"  			global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "asp_years_4p_sib"  			global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "any_coll_2s_sib"  			global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		if "${outcome}" == "higher_ed_2s_sib"  			global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		if "${outcome}" == "asp_years_2s_sib"  			global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		
		//Gender beliefs
		if "${outcome}" == "std_belief_gender_boy_4p_sib"  		global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "std_belief_gender_girl_4p_sib"  	global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "std_belief_gender_4p_sib"  			global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
	
	
	
		

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

	args fam_type sem stack

	estimates drop _all

	global fam_type = `fam_type'
	global sem = "`sem'"
		
	use "$OUT/applied_outcomes_${fam_type}.dta", clear

	additional_vars 	noz major
	prepare_rd 			
	
	if "`stack'" == "student" 			bys id_per_umc id_cutoff: keep if _n==1 // Use applicant database instead of applicant-sibling database
	if "`stack'" == "student_sibling" 	keep if 1==1 // Use applicant-sibling database
	if "`stack'" == ""					keep if 1==1 
		
	binsreg admitted score_relative if abs(score_relative)<${window}, ///
		nbins(100) ///
		xline(0) ///
		ylabel(0(.2)1) ///
		ytitle("Admitted in target college-major-semester") ///
		xsize(5.5) ///
		ysize(5) ///
		by(ABOVE) ///
		bycolors(gs0 gs0) ///
		bysymbols(o o) ///
		legend(off) ///
		name(fs_admitted_foc, replace)
	graph export 	"$FIGURES/eps/first_stage_admitted.eps", replace	
	graph export 	"$FIGURES/png/first_stage_admitted.png", replace	
	graph export 	"$FIGURES/pdf/first_stage_admitted.pdf", replace	
		
	binsreg enroll_uni_major_sem_foc score_relative if abs(score_relative)<${window}, ///
		nbins(100) ///
		xline(0) ///
		ylabel(0(.2)1) /// 
		ytitle("Enrolled in target college-major-semester") ///
		xtitle("Score relative to cutoff") ///
		xsize(5.5) ///
		ysize(5) ///
		by(ABOVE) ///
		bycolors(gs0 gs0) ///
		bysymbols(o o) ///
		legend(off) ///
		name(fs_enroll_uni_major_sem_foc, replace)
	graph export 	"$FIGURES/eps/first_stage_enroll_uni_major_sem.eps", replace	
	graph export 	"$FIGURES/png/first_stage_enroll_uni_major_sem.png", replace	
	graph export 	"$FIGURES/pdf/first_stage_enroll_uni_major_sem.pdf", replace			


	binsreg enroll_uni_sem_foc score_relative if abs(score_relative)<${window}, ///
		nbins(100) ///
		xline(0) ///
		ylabel(0(.2)1) ///
		ytitle("Enrolled in target college") ///
		xsize(5.5) ///
		ysize(5) ///
		by(ABOVE) ///
		bycolors(gs0 gs0) ///
		bysymbols(o o) ///
		legend(off) ///
		name(fs_enroll_foc, replace)		
	graph export 	"$FIGURES/eps/first_stage_enroll_uni.eps", replace	
	graph export 	"$FIGURES/png/first_stage_enroll_uni.png", replace	
	graph export 	"$FIGURES/pdf/first_stage_enroll_uni.pdf", replace		
	
	binsreg enroll_uni_foc score_relative if abs(score_relative)<${window}, ///
		nbins(100) ///
		xline(0) ///
		ylabel(0(.2)1) ///
		ytitle("Enrolled in target college ever") ///
		xsize(5.5) ///
		ysize(5) ///
		by(ABOVE) ///
		bycolors(gs0 gs0) ///
		bysymbols(o o) ///
		legend(off) ///
		name(fs_enroll_foc, replace)		
	graph export 	"$FIGURES/eps/first_stage_enroll_uni.eps", replace	
	graph export 	"$FIGURES/png/first_stage_enroll_uni.png", replace	
	graph export 	"$FIGURES/pdf/first_stage_enroll_uni.pdf", replace		
	
	binsreg enroll_public_o_foc score_relative if abs(score_relative)<${window}, ///
		nbins(100) ///
		xline(0) ///
		ylabel(0(.05).05) ///
		ytitle("Enrolled in other public college") ///
		xsize(5.5) ///
		ysize(5) ///
		bycolors(gs0 gs0) ///
		bysymbols(o o) ///
		legend(off) ///
		name(fs_public_other, replace)
	graph export 	"$FIGURES/eps/fs_public_other.eps", replace	
	graph export 	"$FIGURES/png/fs_public_other.png", replace	
	graph export 	"$FIGURES/pdf/fs_public_other.pdf", replace
	
	binsreg enroll_private_foc score_relative if abs(score_relative)<${window}, ///
		nbins(100) ///
		xline(0) ///
		ylabel(0(.2)1) ///
		ytitle("Enrolled in private college") ///
		xsize(5.5) ///
		ysize(5) ///
		by(ABOVE) ///
		bycolors(gs0 gs0) ///
		bysymbols(o o) ///
		legend(off) ///
		name(fs_public_other, replace)
	graph export 	"$FIGURES/eps/fs_private.eps", replace	
	graph export 	"$FIGURES/png/fs_private.png", replace	
	graph export 	"$FIGURES/pdf/fs_private.pdf", replace	
	
	binsreg enroll_foc score_relative if abs(score_relative)<${window} & inlist(region_foc,8,15)==0, ///
		nbins(100) ///
		xline(0) ///
		ylabel(0(.2)1) ///
		ytitle("Enrolled in any college major ever") ///
		xsize(5.5) ///
		ysize(5) ///
		by(ABOVE) ///
		bycolors(gs0 gs0) ///
		bysymbols(o o) ///
		legend(off) ///
		name(fs_enroll_foc, replace)		
	graph export 	"$FIGURES/eps/first_stage_enroll.eps", replace	
	graph export 	"$FIGURES/png/first_stage_enroll.png", replace	
	graph export 	"$FIGURES/pdf/first_stage_enroll.pdf", replace		
	/*	
	graph combine ///
		fs_admitted_foc ///
		fs_enroll_uni_major_sem_foc ///
		fs_enroll_foc ///
		, ///
		xsize(15) ///
		ysize(5) ///
		col(3)
		
	graph export 	"$FIGURES/first_stage_enrolled.eps", replace	
	*/
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
* Regressions for tables ###TEST
********************************************************************************

capture program drop test_reg
program define test_reg


	clear
	
		
	//Sample
	global fam_type = 2
	global sem = "all"
	global bw_select "optimal"

	//Outcome
	local outcome "score_math_std_2s_sib"


	//Heterogeneity
	local heterog_type = "" 		/*
									/*Full sample*/ 		""  ///
									/*Heterog for all*/ 	"_simps" "_fulls" "_pared" "_acad" "_ses" "_ssex" "_malef" "_males" "_pubs" "_gap" "_sie" ///
									/*Heterog for STEM*/ 	"_stem_sm" "_stem_sf" "_nstem_sm" "_nstem_sf" 
									*/
	local likely_val = ""			


	
	use "$OUT/applied_outcomes_${fam_type}.dta", clear

	additional_vars 	noz major
	prepare_rd 			

	isvar ///
		/*ID*/						id_cutoff id_fam_* ///
		/*RD*/						score_relative  score_relative_* ABOVE_score_relative_* ABOVE admitted enroll_uni_major_sem_foc ///
		/*First stage*/				admitted enroll_uni_major_sem_foc enroll_sem_foc enroll_uni_foc enroll_uni_major_foc enroll_uni_foc enroll_foc  avg_enr_score_*_std_??_foc ///
		/*sample*/					first_sem_application one_application oldest sample_oldest last_year_foc year_app_foc semester_foc term ///
		/*Other*/					year_app_foc universidad codigo_modular  ///
		/*Demographics*/			exp_graduating_year?_sib year_4p_sib year_2s_sib male_siagie_foc male_siagie_sib ///
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

	
	capture drop year_app_foc_*
	tab year_app_foc, gen(year_app_foc_)

	
	global iv = "enroll_uni_major_sem_foc"	
	

	//Define outcome globally in case needed to pass (for 'if_condition')
	global outcome = "`outcome'"

	*- Get "if" condition for each outcome
	if_condition
	
	di "if_condition done"
  
	*- We get the optimal bandwidths
	if "${bw_select}" == "optimal" 	{
		rdrobust ${outcome} score_relative if ${if_pre} & ${if_apps}, ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(${iv}) ///
		  covs(year_app_foc_*) //  covs(year_app_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
		  
		  global bw_${outcome} = e(h_l)
	}

	
	if "${bw_select}" == "fixed" 			global bw_${outcome} = 0.5	
	if inlist("`likely_val'","0","1")==1 	global if_final "${if_pre} & ${if_apps} & h`heterog_type' == `likely_val'"
	if inlist("`likely_val'","")==1 		global if_final "${if_pre} & ${if_apps}"					

	di as text "OPTIMAL BANDWIDTH" ${bw_${outcome}}
	
	//global bw_${outcome} = 0.8894
	*-- Reduced form
	reghdfe ${outcome} ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

	ivreghdfe ${outcome}  ${scores_1} ${ABOVE_scores_1} (${iv} = ABOVE) ///  
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type})


end




********************************************************************************
* Regressions for tables #####
********************************************************************************

capture program drop estimate_reg
program define estimate_reg

	args outcome iv label semesters bw
	
	global iv = "`iv'"	
	
	//Define outcome globally in case needed to pass (for 'if_condition')
	global outcome = "`outcome'"
	
	//Sample
	global sem = "`semesters'"
	global bw_select "`bw'"

	*- Get "if" condition for each outcome
	if_condition // & h`heterog_type' == `likely_val'
	
	di "if_condition done"
  
	*- We get the optimal bandwidths
	if "${bw_select}" == "optimal" 	{
		rdrobust ${outcome} score_relative if ${if_pre} & ${if_apps}, ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(${iv}) ///
		  covs(year_app_foc_*) //  covs(year_app_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
		  
		  global bw_${outcome} = e(h_l)
	}
	
	if "${bw_select}" == "fixed" 			global bw_${outcome} = 0.5	
	if inlist("`likely_val'","0","1")==1 	global if_final "${if_pre}"
	if inlist("`likely_val'","")==1 		global if_final "${if_pre}"					


	di as text "OPTIMAL BANDWIDTH" ${bw_${outcome}}
	
	//global bw_${outcome} = 0.8894
	*-- Reduced form
	ivreghdfe ${outcome}  ${scores_1} ${ABOVE_scores_1} (${iv} = ABOVE) ///  
			if ${if_final} ///
			& abs(score_relative)<${bw_${outcome}}, ///
			absorb(id_cutoff) cluster(id_fam_${fam_type}) ///
			first ffirst savefirst savefprefix(fs_)
			
			local fs = e(widstat)

			estadd ysumm
			estadd scalar bandwidth ${bw_${outcome}}
			estadd scalar fstage = `fs'
			estimates store iv_`label'
			
			//We save first stage estimate in case needed.
			estimates restore fs_${iv}
			estimates store fs_`label' //In case we need to rename
			
	*-- Reduced form
	reghdfe ${outcome} ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

		estadd ysumm
		estadd scalar bandwidth ${bw_${outcome}}
		if inlist("${outcome}","admitted","enroll_uni_major_sem_foc")==0 estadd scalar fstage = `fs'
		estimates store rf_`label'


end


	
********************************************************************************
* Regressions for tables
********************************************************************************

capture program drop main_reg
program define main_reg


	clear
	
	//Sample
	global fam_type = 2

	
	use "$OUT/applied_outcomes_${fam_type}.dta", clear

	additional_vars 	noz major
	prepare_rd 			

	isvar ///
		/*ID*/						id_cutoff id_fam_* ///
		/*RD*/						score_relative  score_relative_* ABOVE_score_relative_* ABOVE admitted enroll_uni_major_sem_foc ///
		/*First stage*/				admitted enroll_uni_major_sem_foc enroll_sem_foc enroll_uni_foc enroll_uni_major_foc enroll_uni_foc enroll_foc  avg_enr_score_*_std_??_foc ///
		/*sample*/					first_sem_application one_application oldest sample_oldest last_year_foc year_app_foc semester_foc term ///
		/*Other*/					year_app_foc universidad codigo_modular  ///
		/*Demographics*/			exp_graduating_year?_sib year_4p_sib year_2s_sib male_siagie_foc male_siagie_sib ///
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

	
	capture drop year_app_foc_*
	tab year_app_foc, gen(year_app_foc_)
	
	gen term = substr(semester_foc,6,1)
	destring term, replace

		
	*- Testing
	preserve
		keep if  score_acad_std_2p_sib < - 0.2
		estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ test  	/*semesters*/ first /*bw*/ optimal
	restore
	estimate_reg /*OUTCOME*/ higher_ed_4p_sib 		/*IV*/ enroll_uni_major_sem_foc 			/*label*/ test  /*semesters*/ all /*bw*/ fixed
	
	//FIX public_o
	
	*- Potential new results
	//Results higher for those with low expectations
	preserve
		keep if higher_ed_2s_sib==0
		estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ test  	/*semesters*/ first /*bw*/ optimal
	restore	
	
	//Results higher for those with low score
	preserve
		 _pctile score_acad_std_2p_sib, p(33 50 66)
		keep if score_acad_std_2p_sib<r(r1) & score_acad_std_2p_sib!=.
		estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ test  	/*semesters*/ first /*bw*/ optimal
	restore
	preserve
		 _pctile score_acad_std_2p_sib, p(33 50 66)
		keep if score_acad_std_2p_sib>r(r3) & score_acad_std_2p_sib!=.
		estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ test  	/*semesters*/ first /*bw*/ optimal
	restore
	
	
	**************
	* Final results
	**************
	preserve
		clear
		save "$OUT\coefficients_rd", replace emptyok
	restore
	
	*- 1. Extensive margin
	estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ applied_sib  	/*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ applied_public_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_pu_sib   	/*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ applied_uni_sib 			/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_u_sib   	/*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ applied_public_o_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_puo_sib   /*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ applied_private_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_pr_sib   	/*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ admitted_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ admitted_sib  /*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ enroll_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ enroll_sib   	/*semesters*/ first /*bw*/ optimal
	
	tables_pres_main 1 table_main_extensive
	
	
	*- 2. Application performance/effort
	estimate_reg /*OUTCOME*/ applies_on_time_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_ot_sib   			/*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ N_applications_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ N_apps_sib   			/*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ N_applications_first_sib 	/*IV*/ enroll_uni_major_sem_foc 	/*label*/ N_apps_first_sib   	/*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ N_applications_uni_sib 	/*IV*/ enroll_uni_major_sem_foc 	/*label*/ N_apps_uni_sib   		/*semesters*/ first /*bw*/ optimal
	  
	estimate_reg /*OUTCOME*/ score_std_major_all_u_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_all_sib  		/*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ score_std_major_uni_u_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_uni_sib  		/*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ score_std_major_pub_u_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_pub_sib  		/*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ score_std_major_uni_o_u_sib 	/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_uni_o_sib  	/*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ score_std_major_pub_o_u_sib 	/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_pub_o_sib  	/*semesters*/ first /*bw*/ optimal
     
	 
	 
	/*
	preserve
		keep if applied_uni_sib==1
		estimate_reg /*OUTCOME*/ score_std_major_avg_sib 		/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_u_sib 	/*semesters*/ first /*bw*/ optimal
		estimate_reg /*OUTCOME*/ score_std_major_uni_avg_sib 	/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_u_sib 	/*semesters*/ first /*bw*/ optimal
		
		
	restore
	
	preserve
		keep if applied_public_sib==1
		estimate_reg /*OUTCOME*/ score_std_major_avg_sib 	/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_pub_sib 	/*semesters*/ first /*bw*/ optimal
	restore	

	preserve
		keep if applied_public_o_sib==1
		estimate_reg /*OUTCOME*/ score_std_major_avg_sib 	/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_u_sib 	/*semesters*/ first /*bw*/ optimal
	restore		
	
	preserve
		keep if applied_uni_sib==0 & applied_public_sib==1
		estimate_reg /*OUTCOME*/ score_std_major_avg_sib 	/*IV*/ enroll_uni_major_sem_foc 	/*label*/ app_sco_puo_sib  	/*semesters*/ first /*bw*/ optimal 
	restore
	*/
	
	tables_pres_main 1 table_uni_performance
	
	*- 3. School performance and completion rates
	estimate_reg /*OUTCOME*/ sec_grad_sib 			/*IV*/ enroll_uni_major_sem_foc 			/*label*/ secg_sib   	/*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ score_acad_std_4p_sib 	/*IV*/ enroll_uni_major_sem_foc 			/*label*/ acad_4p_sib   /*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ score_acad_std_2s_sib 	/*IV*/ enroll_uni_major_sem_foc 			/*label*/ acad_2s_sib   /*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ higher_ed_4p_sib 		/*IV*/ enroll_uni_major_sem_foc 			/*label*/ asp_4_4p_sib  /*semesters*/ first /*bw*/ optimal
	estimate_reg /*OUTCOME*/ higher_ed_2s_sib 		/*IV*/ enroll_uni_major_sem_foc 			/*label*/ asp_4_2s_sib  /*semesters*/ first /*bw*/ optimal
 
	tables_pres_main 1 table_school
	
	
	

end




********************************************************************************
* tables for latex document
********************************************************************************

capture program drop tables_pres_main
program define tables_pres_main	

args scale table_type

	global t_tex = "`table_type'"

	file open  table_tex	using "$TABLES\\${t_tex}_PRES.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\makebox[0.1\width][l]{" _n ///
					"\resizebox{`scale'\textwidth}{!}{" _n
	file close table_tex
	
	tables_input_main PRES
	
	file open  table_tex	using "$TABLES\\${t_tex}_PRES.tex", append write
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

	args t_suffix heterog_type

	if "`t_suffix'" == "DOC" 	local suffix = ""
	if "`t_suffix'" == "PRES" 	local suffix = "_PRES"

*- We produce Table with estimates

if inlist("${t_tex}","table_main_extensive") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" & \multicolumn{5}{c}{Applied to}   			& Admitted to 		& Enrolled in     \\" _n ///
					" & \multicolumn{5}{c}{4-year college}   		& 4-year college  	& 4-year college  \\" _n ///
					"\cline{2-6} \cline{7-8}" _n ///
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
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}
	
	

if inlist("${t_tex}","table_uni_performance") == 1 {
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\\${t_tex}`suffix'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& Applies on  		& \multicolumn{3}{c}{Number of Applications}   	& \multicolumn{3}{c}{Application Score}    \\" _n ///
					"\cline{2-3} \cline{4-6}" _n ///
					"& time  			& Total & First time 	& Same College 			& All & Same College 	& Public 	& Other Colleges 	& Other Public		\\" _n ///
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
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
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
					"\cline{2-3} \cline{3-4} \cline{5-6}" _n ///
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
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
}
	

end


********************************************
********************************************
********************************************

***** Run program

main


