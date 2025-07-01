/********************************************************************************
- Author: Francisco Pardo
- Description: Produces final tables and figures
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/

capture program drop main 
program define main 

	setup

	
	*mccrary 2 all 
	*mccrary 2 first
	
	*first_stage 2 all
	*visual_balance 2 first

	
	/*
	all
	t_first_stage
	t_balance
	t_sib_choices
	t_sib_stem
	t_sib_school
	t_sib_prog
	t_sib_univ
	t_sib_asp
	t_sib_gender
	t_sib_heterog
	t_sib_heterog_stem
	*/
	
	
						//regressions 2 all all   
						//regressions 2 all first   //family ID, sample, outcomes

	*regressions 2 all all optimal //family ID, sample (all, first...), outcomes (all, t_balance,...) , bandwidth (optimal, fixed)
	*regressions 2 all all fixed
	
	*regressions 2 first all optimal
	*regressions 2 first all fixed
	
	regressions 2 all all optimal
	regressions 2 all all fixed
	regressions 2 first all optimal
	regressions 2 first all fixed	

					//e.g.
					//regressions 2 first t_sib_heterog_stem fixed

					//regressions 2 first_sem_out
					//regressions 2 first_year_out
					//regressions 2 one

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

	args sem

	*- Public schools
	keep if public_foc==1

	*- Exclude those without estimated cutoffs
	keep if lottery_nocutoff == 0

	*- Exclude those at cutoff
	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)		
	keep if not_at_cutoff==1
	
	*- Exclude those without sibling
	drop if any_sib_match==0
	
	*- Keep specific samples of interest
	if "`sem'" == "one" 			keep if one_application==1
	if "`sem'" == "first" 			keep if first_sem_application==1
	if "`sem'" == "first_sem_out" 	keep if (last_year_foc + 1 == year_app_foc) & substr(semester_foc,6,1)=="1" //First semester after finishing school.
	if "`sem'" == "first_year_out" 	keep if (last_year_foc + 1 == year_app_foc) //First semester after finishing school.
	if "`sem'" == "all" 			keep if 1==1
	if inlist("`sem'","one","first","all","first_sem_out","first_year_out")==0  assert 1==0
	
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
	
	/*
	variables for dividing sample heterogeneity:
	h_simpf
	h_fullf
	h_simps
	h_fulls
	h_pared
	h_acad
	h_ses
	h_ssex
	h_gap
	
	*/

	//What division explains differences in sibling enrollment?
	/*
	global covar1_sib "male_siagie_sib i.educ_mother i.region_siagie_sib i.urban_siagie_sib i.public_siagie_sib"
	global covar2_sib "score_math_std_2p_sib score_com_std_2p_sib"
	global covar3_sib "score_math_std_2s_sib score_com_std_2s_sib i.aspiration_2s_sib i.socioec_index_cat_2s_sib"
	
	count if (exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)
	local N = r(N)
	
	local out = "applied_sib"
	logit `out' ${covar1_sib}						if (exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)
	local s1 =  e(N) 
	predict `out'_lpred1
	
	logit `out' ${covar1_sib}	${covar2_sib} 					if (exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)
	local s2 =  e(N) 
	predict `out'_lpred2
	
	logit `out' ${covar1_sib}	${covar3_sib}					if (exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)
	local s3 =  e(N) 
	predict `out'_lpred3
	
	logit `out' ${covar1_sib} ${covar2_sib} ${covar3_sib}						if (exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)
	local s4 =  e(N) 
	predict `out'_lpred4	

	
		di as text  _n "Sample 1:" %9.1f `s1'*100/`N' ///
					_n "Sample 2:" %9.1f `s2'*100/`N' ///
					_n "Sample 4:" %9.1f `s4'*100/`N' ///
					_n "Sample 3:" %9.1f `s3'*100/`N'
					
	sum ${covar1_sib} ${covar3_sib} if applied_sib_lpred3<0.2
		
	//Aspirations, scores, parents education and socioeconomic status
	

	sum score_math_std_2s_sib, de
	gen byte above_math = (score_math_std_2s_sib>r(p50)) if score_math_std_2s_sib!=.	
	sum score_com_std_2s_sib, de
	gen byte above_com = (score_com_std_2s_sib>r(p50)) if score_com_std_2s_sib!=.	
	sum score_acad_std_2s_sib, de
	gen byte above_acad = (score_acad_std_2s_sib>r(p50)) if score_acad_std_2s_sib!=.	
	
	tabstat applied_sib, by(above_math)
	tabstat applied_sib, by(above_com)
	tabstat applied_sib, by(above_acad)
	
	*/
	
	
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

		//Balance
		if "${outcome}" == "male_foc" 					global if_pre "1==1"
		if "${outcome}" == "age" 						global if_pre "1==1"
		if "${outcome}" == "score_math_std_2s_foc" 		global if_pre "1==1"		
		if "${outcome}" == "score_com_std_2s_foc" 		global if_pre "1==1"
		if "${outcome}" == "score_acad_std_2s_foc" 		global if_pre "1==1"
		if "${outcome}" == "higher_ed_mother" 			global if_pre "1==1"
		if "${outcome}" == "vlow_ses_foc" 				global if_pre "1==1"	
		
		//First Stage
		if "${outcome}" == "admitted" 						global if_pre "1==1"
		if "${outcome}" == "enroll_uni_major_sem_foc" 		global if_pre "1==1"
		if "${outcome}" == "enroll_sem_foc" 				global if_pre "1==1"		
		if "${outcome}" == "enroll_uni_major_foc" 			global if_pre "1==1"		
		if "${outcome}" == "enroll_uni_foc" 				global if_pre "1==1"		
		if "${outcome}" == "enroll_foc" 					global if_pre "1==1"
		if "${outcome}" == "avg_enr_score_math_std_2s_foc" 	global if_pre "1==1"
		if "${outcome}" == "avg_enr_score_com_std_2s_foc" 	global if_pre "1==1"

		//Application choices
		if "${outcome}" == "applied_uni_sib" 			global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
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
		if "${outcome}" == "avg_enr_score_math_std_2s_sib" 	global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		if "${outcome}" == "avg_enr_score_com_std_2s_sib" 	global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app_foc)"
		
		//Aspirations and survey measures
		if "${outcome}" == "comp_sec_4p_sib"  			global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "any_coll_4p_sib"  			global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "higher_ed_4p_sib"  			global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "asp_years_4p_sib"  			global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "any_coll_2s_sib"  			global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		if "${outcome}" == "higher_ed_2s_sib"  			global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		if "${outcome}" == "asp_years_2s_sib"  			global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		
		//Gender beliefs
		if "${outcome}" == "std_belief_gender_boy_4p_sib"  	global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		if "${outcome}" == "std_belief_gender_girl_4p_sib"  	global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		if "${outcome}" == "std_belief_gender_4p_sib"  			global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
	
		

end		
		
********************************************************************************
* Regressions for tables
********************************************************************************

capture program drop test_reg
program define test_reg


	clear
		
end



********************************************************************************
* McCrary
********************************************************************************
capture program drop mccrary
program define mccrary

	args fam_type sem

	estimates drop _all

	global fam_type = `fam_type'
		
	use "$OUT/applied_outcomes_${fam_type}.dta", clear
	
	//gen any_sib_match = (region_siagie_sib!=.)

	additional_vars 	noz major
	prepare_rd 			`sem'
	
	bys id_per_umc id_cutoff: keep if _n==1 // Use applicant database instead of applicant-sibling database
	
	histogram score_relative ///
	if abs(score_relative)<$mccrary_window ///
	,  ///
	fcolor(gs14) lcolor(gs0) xline(0, lcolor(red)) /*title("All cutoffs")*/ xtitle("Standardized score relative to cutoff")	 ///
	name(histogram_`sem', replace)
	graph export 	"$FIGURES/eps/histogram_`sem'.eps", replace	
	graph export 	"$FIGURES/png/histogram_`sem'.png", replace	
	graph export 	"$FIGURES/pdf/histogram_`sem'.pdf", replace	
	
		* Public schools
	rddensity score_relative ///
		if abs(score_relative)<$mccrary_window ///
		, ///
		xtitle("Standardized score relative to cutoff") ///
		c(0) ///
		///p(1) /// are these required for mccrary? Or just for estimating outcomes? ###
		///q(2) ///
		kernel(triangular) ///
		all ///
		plot 
		
	graph export 	"$FIGURES/eps/mccrary_`sem'.eps", replace	
	graph export 	"$FIGURES/png/mccrary_`sem'.png", replace	
	graph export 	"$FIGURES/pdf/mccrary_`sem'.pdf", replace	
	
	global mccrary_pval_`sem' = e(pv_q)
end


********************************************************************************
* First Stage
********************************************************************************
capture program drop first_stage
program define first_stage

	args fam_type sem

	estimates drop _all

	global fam_type = `fam_type'
		
	use "$OUT/applied_outcomes_${fam_type}.dta", clear

	additional_vars 	noz major
	prepare_rd 			`sem'
	
	
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
		
	binsreg enroll_uni_foc score_relative if abs(score_relative)<${window}, ///
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
	graph export 	"$FIGURES/eps/first_stage_enroll_uni.eps", replace	
	graph export 	"$FIGURES/png/first_stage_enroll_uni.png", replace	
	graph export 	"$FIGURES/pdf/first_stage_enroll_uni.pdf", replace		
	
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

	args fam_type sem

	estimates drop _all

	global fam_type = `fam_type'
		
	use "$OUT/applied_outcomes_${fam_type}.dta", clear

	additional_vars 	noz major
	prepare_rd 			`sem'
	
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

capture program drop regressions
program define regressions

	args fam_type sem t_outcomes bw_select

	estimates drop _all

	global fam_type = `fam_type'
		
	use "$OUT/applied_outcomes_${fam_type}.dta", clear

	additional_vars 	noz major
	prepare_rd 			`sem'

	isvar ///
		/*ID*/						id_cutoff id_fam_* ///
		/*RD*/						score_relative  score_relative_* ABOVE_score_relative_* ABOVE admitted enroll_uni_major_sem_foc ///
		/*First stage*/				admitted enroll_uni_major_sem_foc enroll_sem_foc enroll_uni_foc enroll_uni_major_foc enroll_uni_foc enroll_foc  avg_enr_score_*_std_??_foc ///
		/*sample*/					first_sem_application one_application oldest sample_oldest ///
		/*Other*/					year_app_foc universidad  ///
		/*Demographics*/			exp_graduating_year?_sib year_4p_sib year_2s_sib male_siagie_foc male_siagie_sib ///
		/*Choices*/					stem_major ///
		/*Balance*/					male_foc age score_math_std_2s_foc score_com_std_2s_foc score_acad_std_2s_foc higher_ed_mother vlow_ses_foc ///
		/*SIBLING CHOICES*/			applied_uni_sib enroll_uni_sib applied_uni_major_sib enroll_uni_major_sib applied_major_sib enroll_major_sib applied_sib enroll_sib ///
		/*SIBLING CHOICES STEM*/	applied_stem_sib applied_nstem_sib enroll_stem_sib enroll_nstem_sib ///
		/*SIBLING School*/			score_math_std_2s_sib score_com_std_2s_sib score_acad_std_2s_sib approved_sib approved_next_sib approved_first_sib approved_first_next_sib dropout_ever_sib pri_grad_sib sec_grad_sib year_graduate_sib change_ie_sib change_ie_next_sib ///
		/*SIBLING Survey*/			comp_sec_4p_sib any_coll_4p_sib higher_ed_4p_sib asp_years_4p_sib any_coll_2s_sib higher_ed_2s_sib asp_years_2s_sib std_belief_gender*_??_sib ///
 		/*SIBLING University*/		admitted_sib applies_on_time_sib N_applications_sib score_std_*_avg_sib avg_enr_score_*_std_??_sib ///
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
	encode universidad, gen(uni)
	tab uni, gen(uni_)
	
	global iv = "enroll_uni_major_sem_foc"	
	

	foreach heterog_type in 	/*Full sample*/ 		""  ///
								/*Heterog for all*/ 	"_simps" "_fulls" "_pared" "_acad" "_ses" "_ssex" "_malef" "_males" "_pubs" "_gap" "_sie" ///
								/*Heterog for STEM*/ 	"_stem_sm" "_stem_sf" "_nstem_sm" "_nstem_sf" {
		capture estimates drop * //"_simpf" "_fullf"
		
		local t_header = ""
		foreach outcome in 	///
		/*First Stage*/						"t_first_stage" 		/**/ "admitted" "enroll_uni_major_sem_foc" "enroll_sem_foc" "enroll_uni_major_foc" "enroll_uni_foc"  "enroll_foc" "avg_enr_score_math_std_2s_foc" "avg_enr_score_com_std_2s_foc" /// peer_uni_score
		/*BALANCE*/							"t_balance" 			/**/ "male_foc" "age" "score_math_std_2s_foc" "score_com_std_2s_foc" "score_acad_std_2s_foc" "higher_ed_mother" "vlow_ses_foc" ///
		/*SIBLING choices (6)*/				"t_sib_choices" 		/**/ "applied_uni_sib" "enroll_uni_sib" "applied_uni_major_sib" "enroll_uni_major_sib" "applied_major_sib" "enroll_major_sib" ///
		/*SIBLING STEM*/					"t_sib_stem" 			/**/ "applied_stem_sib" "applied_nstem_sib" "enroll_stem_sib" "enroll_nstem_sib" ///
		/*SIBLING school outcome (5)*/ 		"t_sib_school" 			/**/ "score_math_std_2s_sib" "score_com_std_2s_sib" "score_acad_std_2s_sib" "dropout_ever_sib" "sec_grad_sib" ///
		/*SIBLING progression (5)*/ 		"t_sib_prog" 			/**/ "approved_sib" "approved_next_sib" "approved_first_sib" "approved_first_next_sib" "change_ie_sib" "change_ie_next_sib" ///
		/*SIBLING university (6)*/ 			"t_sib_univ" 			/**/ "applied_sib" "admitted_sib" "enroll_sib" "applies_on_time_sib" "N_applications_sib" "score_std_major_avg_sib" "avg_enr_score_math_std_2s_sib" "avg_enr_score_com_std_2s_sib" ///
		/*SIBLING aspiration/beliefs (6)*/	"t_sib_asp" 			/**/ "comp_sec_4p_sib" "any_coll_4p_sib" "higher_ed_4p_sib" "asp_years_4p_sib" "any_coll_2s_sib" "higher_ed_2s_sib" "asp_years_2s_sib"  ///
		/*SIBLING gender beliefs (3)*/		"t_sib_gender" 			/**/ "std_belief_gender_4p_sib" "std_belief_gender_boy_4p_sib" "std_belief_gender_girl_4p_sib" ///
											"t_sib_heterog"			/**/ /// this is only in order to produce the table
											"t_sib_heterog_stem"	/**/ /// this is only in order to produce the table
		{	
			
			//Define outcome globally in case needed to pass (for 'if_condition')
			global outcome = "`outcome'"
			
							display as text ///
						"*************************************************" _n  ///
						"******** Loop pre estimation (OUTCOME)   ********" _n ///
						"*************************************************" _n ///
						as result ///
						"Outcome:"					_column(20) 		"${outcome}" _n ///	
						"Subsample based on:" 		_column(20) 		"`heterog_type'" _n ///
						"*************************************************" _n  ///
						"********* 		Loop pre estimation 	*********" _n ///
						"*************************************************" _n 		
			 //Produce table when beginning a new section (table from previous section (t_header before change): only if doing the full run or that specific section and when not doing heterogeneity)
			 if (inlist("${outcome}",/*"t_first_stage",*/"t_balance","t_sib_choices","t_sib_stem","t_sib_school","t_sib_prog","t_sib_univ")==1  | ///
				inlist("${outcome}","t_sib_asp","t_sib_gender","t_sib_heterog"/*,"t_sib_heterog_stem"*/)==1)  & ///
				inlist("`t_outcomes'","all","`t_header'")==1 & /// Note that because t_header updates later, it will not enter heare being 't_sib_heterog'. So this won't apply when doing heterogeneity only.
				"`heterog_type'"=="" {
				di "TABLE1"
				tables ${fam_type} `sem' `t_header' `bw_select'
				}
			
			//If doing full run or heterogeneity, then produce those tables whenever the loop has finished
			if 	(inlist("${outcome}","t_sib_heterog")==1  & ///
				inlist("`t_outcomes'","all","t_sib_heterog")==1 & ///
				(inlist("`heterog_type'","_simps","_fulls","_pared","_acad","_ses","_ssex") == 1 | inlist("`heterog_type'","_malef","_males","_pubs","_gap","_sie" )==1)) |  ///
				(inlist("${outcome}","t_sib_heterog_stem")==1  & ///
				inlist("`t_outcomes'","all","t_sib_heterog_stem")==1 & ///
				(inlist("`heterog_type'","_stem_sm","_stem_sf","_nstem_sm","_nstem_sf") == 1))  ///
				{
				di "TABLE2"
				tables ${fam_type} `sem' ${outcome} `bw_select' `heterog_type' //e.g. tables 2 t_sib_heterog_stem first optimal _stemsm
			}
			di "1"	
			
			
			 //Define current section (after doing table)
			if inlist("${outcome}","t_first_stage","t_balance","t_sib_choices","t_sib_stem","t_sib_school","t_sib_prog","t_sib_univ")==1 	local t_header = "${outcome}"
			if inlist("${outcome}","t_sib_asp","t_sib_gender","t_sib_heterog","t_sib_heterog_stem")==1 										local t_header = "${outcome}"
			di "2"	
			
			*- Skip if current loop does not apply:
			 *1. Only do heterogeneity if doing full run or heterogenity only.
			 if inlist("`t_outcomes'","all","t_sib_heterog","t_sib_heterog_stem")==0 & "`heterog_type'" != "" continue
			 di "1s"
			 // & strmatch("`heterog_type'","*stem*")==0
			 
			 *2. If doing heterogeneity only, avoid full sample
			 if inlist("`t_outcomes'","t_sib_heterog","t_sib_heterog_stem")==1 & "`heterog_type'" == "" continue
			 di "2s"
			 
			 *2. If doing heterogeneity only, consider only the corresponding heterogeneity loops for each type
			 if inlist("`t_outcomes'","t_sib_heterog")==1 		& inlist("`heterog_type'","_simps","_fulls","_pared","_acad","_ses","_ssex") == 0 & inlist("`heterog_type'","_malef","_males","_pubs","_gap","_sie" )==0 continue
			 if inlist("`t_outcomes'","t_sib_heterog_stem")==1 	& inlist("`heterog_type'","_stem_sm","_stem_sf","_nstem_sm","_nstem_sf")==0 continue
			 di "2s"			 
			 
			 *3. If doing heterogeneity, only do some outcomes
			 if inlist("`t_outcomes'","t_sib_heterog")==1 		& inlist("${outcome}","applied_uni_sib","enroll_uni_sib","applied_sib"/*,"admitted_sib"*/,"enroll_sib","dropout_ever_sib","sec_grad_sib","score_math_std_2s_sib","score_com_std_2s_sib","higher_ed_2s_sib")==0 continue		
			 if inlist("`t_outcomes'","t_sib_heterog_stem")==1 	& inlist("${outcome}","dropout_ever_sib","sec_grad_sib","applied_sib","enroll_sib","applied_stem_sib","applied_nstem_sib","enroll_stem_sib","enroll_nstem_sib")==0 continue				 
			 di "3s"

			*4. If not doing full regression or heterogeneity, or only running for a section, then skip.
			if inlist("`t_outcomes'","all","t_sib_heterog","t_sib_heterog_stem","`t_header'")==0 continue		 
			di "4s"
	 			
				
						display as text ///
						"*************************************************" _n  ///
						"******** Loop pre estimation (OUTCOME)   ********" _n ///
						"*************************************************" _n ///
						as result ///
						"Outcome:"					_column(20) 		"${outcome}" _n ///	
						"Subsample based on:" 		_column(20) 		"`heterog_type'" _n ///
						"*************************************************" _n  ///
						"********* 		Loop pre estimation 	*********" _n ///
						"*************************************************" _n 


			*5. Erase estimates when beginning a new section (and having produced table). Keep those needed for Heterogeneity.	 ###CHANGE IF HETEROG CHANGES
			if 	inlist("${outcome}",/*"t_first_stage",*/"t_balance","t_sib_choices","t_sib_stem","t_sib_school","t_sib_prog","t_sib_univ")==1 | ///
				inlist("${outcome}","t_sib_asp","t_sib_gender","t_sib_heterog","t_sib_heterog")==1 {	
					capture estimates drop fs*
					estimates dir
					local est_list = r(names)
					foreach est_var of local est_list {
						if 	strmatch("`est_var'","??_applied_uni_sib*")==0 & ///
							strmatch("`est_var'","??_enroll_uni_sib*")==0 & ///
							strmatch("`est_var'","??_math_2s_sib*")==0 & ///
							strmatch("`est_var'","??_comm_2s_sib*")==0 & ///
							strmatch("`est_var'","??_applied_sib*")==0 & ///
							///strmatch("`est_var'","??_admitted_sib*")==0 & ///
							strmatch("`est_var'","??_enroll_sib*")==0 & ///
							strmatch("`est_var'","??_asp_4_2s_sib*")==0 ///
							estimates drop `est_var' 
					}
			 }

			di "ERASED ESTIMATES"

			
			*6.The header is not an outcome, so we naturally skip them after the previous steps.
			if inlist("${outcome}","t_first_stage","t_balance","t_sib_choices","t_sib_stem","t_sib_school","t_sib_prog","t_sib_univ")==1 | ///
			inlist("t_sib_asp","t_sib_gender","t_sib_heterog","t_sib_heterog_stem")==1 continue 
			di "5s"	
			
			
			//create a different abbreviation for some outcomes that are too large and give error in 'estimates store'
			local outcome_est = "${outcome}"
			
			if "${outcome}" == "enroll_uni_major_sem_foc" 		local outcome_est = "enroll_target"
			if "${outcome}" == "avg_enr_score_math_std_2s_foc" 	local outcome_est = "peer_e_m_2s_foc" //e=enrolled, as oppossed to school-class.
			if "${outcome}" == "avg_enr_score_com_std_2s_foc" 	local outcome_est = "peer_e_c_2s_foc" //e=enrolled, as oppossed to school-class.
			if "${outcome}" == "avg_enr_score_acad_std_2s_foc" 	local outcome_est = "peer_e_a_2s_foc" //e=enrolled, as oppossed to school-class.

			if "${outcome}" == "score_math_std_2s_foc" 	local outcome_est = "math_2s_foc"
			if "${outcome}" == "score_com_std_2s_foc" 	local outcome_est = "comm_2s_foc"
			if "${outcome}" == "score_acad_std_2s_foc" 	local outcome_est = "acad_2s_foc"
			
			if "${outcome}" == "score_math_std_2s_sib" 	local outcome_est = "math_2s_sib"
			if "${outcome}" == "score_com_std_2s_sib" 	local outcome_est = "comm_2s_sib"
			if "${outcome}" == "score_acad_std_2s_sib" 	local outcome_est = "acad_2s_sib"
			
			if "${outcome}" == "dropout_ever_sib" 	local outcome_est = "dout_e_sib"
			if "${outcome}" == "sec_grad_sib" 		local outcome_est = "secg_sib"
			
			if "${outcome}" == "applied_uni_major_sib" 		local outcome_est = "app_u_m_sib"
			if "${outcome}" == "enroll_uni_major_sib" 		local outcome_est = "enr_u_m_sib"
			
			if "${outcome}" == "applies_on_time_sib" 			local outcome_est = "app_ot_sib"
			if "${outcome}" == "N_applications_sib" 			local outcome_est = "N_apps_sib"
			if "${outcome}" == "score_std_major_avg_sib" 		local outcome_est = "app_sco_m_sib"
			if "${outcome}" == "avg_enr_score_math_std_2s_sib" 	local outcome_est = "peer_e_m_2s_sib" 
			if "${outcome}" == "avg_enr_score_com_std_2s_sib" 	local outcome_est = "peer_e_c_2s_sib" 
			if "${outcome}" == "avg_enr_score_acad_std_2s_sib" 	local outcome_est = "peer_e_a_2s_sib" 
				
			if "${outcome}" == "comp_sec_4p_sib" 		local outcome_est = "asp_s_4p_sib"
			if "${outcome}" == "any_coll_4p_sib" 		local outcome_est = "asp_2_4p_sib"
			if "${outcome}" == "higher_ed_4p_sib" 		local outcome_est = "asp_4_4p_sib"
			if "${outcome}" == "asp_years_4p_sib" 		local outcome_est = "asp_y_4p_sib"
			if "${outcome}" == "any_coll_2s_sib" 		local outcome_est = "asp_2_2s_sib"
			if "${outcome}" == "higher_ed_2s_sib" 		local outcome_est = "asp_4_2s_sib"
			if "${outcome}" == "asp_years_2s_sib" 		local outcome_est = "asp_y_2s_sib"	
			
			if "${outcome}" == "std_belief_gender_4p_sib" 		local outcome_est = "gender_4p_all"		
			if "${outcome}" == "std_belief_gender_boy_4p_sib" 	local outcome_est = "gender_4p_boy"		
			if "${outcome}" == "std_belief_gender_girl_4p_sib" local outcome_est = "gender_4p_girl"		
			
			
			if "${outcome}" == "applied_stem_sib" 		local outcome_est = "app_stem"		
			if "${outcome}" == "applied_nstem_sib" 		local outcome_est = "app_nstem"		
			if "${outcome}" == "enroll_stem_sib" 		local outcome_est = "enr_stem"		
			if "${outcome}" == "enroll_nstem_sib" 		local outcome_est = "enr_nstem"				

			*- Get "if" condition for each outcome
			if_condition
		  
			*- We get the optimal bandwidths
			if "`bw_select'" == "optimal" 	{
				rdrobust ${outcome} score_relative if ${if_pre}, ///
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
			if "`bw_select'" == "fixed" 	global bw_${outcome} = 0.5
			//Can we change this to the max so that we can have a few extra observations and a common bandwidth?
			//global bw_${outcome} = max(e(h_l),e(h_r))
			//Or we can also use: fitselect(restricted)

			*- Main regression
			// We run the main regression with selected bandwidth, including cutoff fixed effects
				  
			*-- IV estimate
			//foreach heterog_type in "" /*"_simpf" "_fullf"*/ "_simps" "_fulls" "_pared" "_acad" "_ses" "_ssex" "_malef" "_males" "_pubs" "_gap" "_sie" {		
			/*
			foreach likely_type in "" "_simp" "_full" {
				foreach likely_who in "" "f" "s" { // f=focal, s=sibling
				*/
					foreach likely_val in "" "0" "1" { // "" : general results, "0"/"1": heterogeneity results	
								
						//If not doing full regression or heterogeneity, and looking at subsamples, then skip.
						if inlist("`t_outcomes'","all","t_sib_heterog","t_sib_heterog_stem")==0 & (inlist("`heterog_type'","")==0 | inlist("`likely_val'","") == 0) continue					
						// ""-"" is the full sample. Otherwise, both most have values
						local continue_est = 0
						if inlist("`heterog_type'","")==1 & inlist("`likely_val'","")==1 	local continue_est = 1
						if inlist("`heterog_type'","")==0 & inlist("`likely_val'","")==0 	local continue_est = 1
						if `continue_est'==0 continue //Either full sample or likelihood well specified.
						
						if inlist("`likely_val'","0","1")==1 & /// We use one only, but that means all have values by previous condition
						inlist("${outcome}","applied_uni_sib","enroll_uni_sib","applied_sib","admitted_sib","enroll_sib","applies_on_time_sib")==0 & /// ###CHANGE IF HETEROG CHANGES
						inlist("${outcome}","score_math_std_2s_sib","score_com_std_2s_sib","score_acad_std_2s_sib","higher_ed_2s_sib")==0 & /// if heterogeneity, only for some outcomes
						inlist("${outcome}","dropout_ever_sib","sec_grad_sib")==0 & ///
						inlist("${outcome}","applied_stem_sib","applied_nstem_sib","enroll_stem_sib","enroll_nstem_sib")==0 continue //if heterogeneity, only for some outcomes
			
						display as text ///
						"*************************************************" _n  ///
						"******** Showing details of current loop ********" _n ///
						"*************************************************" _n ///
						as result ///
						"Outcome:"					_column(20) 		"${outcome}" _n ///
						"IV:" 						_column(20) 		"${iv}" _n ///
						"Bandwidth:" 				_column(20) %9.2f 	${bw_${outcome}} _n ///
						"Family Type:"				_column(20)			${fam_type}	_n ///
						"Current section:"			_column(20)			"`t_header'"	_n ///
						as input ///
						"Subsample based on:" 		_column(20) 		"`heterog_type'" _n ///
						"Likely college sample:" 	_column(20) 		"`likely_val'" _n ///
						"Condition (if):" 			_column(20) 		"${if_final}" _n ///
						as text ///
						"*************************************************" _n  ///
						"****************** Back to code *****************" _n ///
						"*************************************************" _n
						
						if inlist("`likely_val'","0","1")==1 	global if_final "${if_pre} & h`heterog_type' == `likely_val'"
						if inlist("`likely_val'","")==1 		global if_final "${if_pre}"					

						global bw_${outcome}`heterog_type'`likely_val' = ${bw_${outcome}}
						
						if inlist("${outcome}","admitted","enroll_uni_major_sem_foc")==0 { //Not needed since admitted is before being enrolled, and enrolling is the same as the variable instrumenting for (would give coefficient = 1)
						ivreghdfe ${outcome}  ${scores_1} ${ABOVE_scores_1} (${iv} = ABOVE) ///  
								if ${if_final} ///
								& abs(score_relative)<${bw_${outcome}`heterog_type'`likely_val'}, ///
								absorb(id_cutoff) cluster(id_fam_${fam_type}) ///
								first ffirst savefirst savefprefix(fs_)
								
								local fs = e(widstat)

								estadd ysumm
								estadd scalar bandwidth ${bw_${outcome}`heterog_type'`likely_val'}
								estadd scalar fstage = `fs'
								estimates store iv_`outcome_est'`heterog_type'`likely_val'
								
								//We save first stage estimate in case needed.
								estimates restore fs_${iv}
								estimates store fs_`outcome_est'`heterog_type'`likely_val' //In case we need to rename
								}
						*-- Reduced form
						reghdfe ${outcome} ABOVE  ${scores_1} ${ABOVE_scores_1} ///
							if ${if_final} ///
							& abs(score_relative)<${bw_${outcome}`heterog_type'`likely_val'}, ///
							absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

							estadd ysumm
							estadd scalar bandwidth ${bw_${outcome}`heterog_type'`likely_val'}
							if inlist("${outcome}","admitted","enroll_uni_major_sem_foc")==0 estadd scalar fstage = `fs'
							estimates store rf_`outcome_est'`heterog_type'`likely_val'
							
			
				}
			}
		}

	
	//If doing full regression, also include heterogeneity in the end.
	//if "`t_outcomes'" == "all" tables ${fam_type} `sem' t_sib_heterog
		
	
end


********************************************************************************
* tables for latex document
********************************************************************************
		
capture program drop tables
program define tables	

	args fam_type sem t_header bw_select heterog_type

	global fam_type = `fam_type'
	global t_header = "`t_header'"


*- We produce Table with estimates

//Format:
/*
IV

RF

Observations
Counterfactual
Bandwidth
Fstatistic

*/

*- Write Latex final table & figure

/*
table_foc_balance_all_1_2
table_foc_fs_all_1_2
table_sib_choices_all_1_2
table_sib_school_outcomes_all_1_2
table_sib_univ_outcomes_all_1_2
table_sib_univ_outcomes_all_2_2
table_sib_asp_outcomes_all_1_2
table_sib_gender_outcomes_all_1_2
table_sib_heterog_foc_all_1_2
table_sib_heterog_foc_all_2_2
table_sib_heterog_sib_all_1_2
table_sib_heterog_sib_all_2_2
*/


*----------------------
*- Balance table
*----------------------		

if inlist("${t_header}","t_balance") == 1 {
	*- Table 2: Sibling spillovers on college choices
	file open  table_tex	using "$TABLES\table_foc_balance_`sem'_bw`bw_select'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on focal child (Balance)}\label{tab:table_foc_balance_`sem'_bw`bw_select'_1_${fam_type}}" _n ///
					"\scalebox{0.9}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{4}{c}{Demographic} & & \multicolumn{3}{c}{8th grade exam}   \\" _n ///
					"\cline{2-5} \cline{6-8}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& \multirow{2}{*}{Male}  	& \multirow{2}{*}{Age} 	& Mother 	& v.Low &  \multirow{2}{*}{Mathematics 8th grade} & \multirow{2}{*}{Reading 8th grade} & \multirow{2}{*}{Academic 8th grade} 	\\" _n ///
					"&  						&  						& H. ed. 	& SES 	&   						&  						&  							\\" _n ///
					"& (1) 						& (2) 					& (3) 		& (4) 	&  (5) 					& (6) 					& (7)   \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & & & & & \\" _n 
	file close table_tex
	
	estout iv_male_foc iv_age iv_higher_ed_mother iv_vlow_ses_foc  iv_math_2s_foc iv_comm_2s_foc iv_acad_2s_foc ///
	using "$TABLES/table_foc_balance_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_male_foc rf_age rf_higher_ed_mother rf_vlow_ses_foc   rf_math_2s_foc rf_comm_2s_foc rf_acad_2s_foc ///
	using "$TABLES/table_foc_balance_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_foc_balance_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{8}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex
}


*----------------------
*- First Stage
*----------------------

if inlist("${t_header}","t_first_stage") == 1 {
	*- Table 1: Focal child first stage effects
	file open  table_tex	using "$TABLES\table_foc_fs_`sem'_bw`bw_select'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on focal child}\label{tab:table_foc_fs_`sem'_bw`bw_select'_1_${fam_type}}" _n ///
					"\scalebox{0.7}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& Admitted target 	& Enrolled target  	& Enrolled any 	& Enrolled target  	& Enrolled target  	& Enrolled any \\" _n ///
					"\cline{2-7}" _n ///
					"& college-major 	& college-major 	& college		& college-major 	& college 			& college \\" _n ///
					"& Semester 		& Semester 			& Semester 		& ever 				& ever 				& ever \\" _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & &  \\" _n 
	file close table_tex

	estout . .  iv_enroll_sem_foc iv_enroll_uni_major_foc iv_enroll_uni_foc  iv_enroll_foc ///
	using "$TABLES/table_foc_fs_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_admitted rf_enroll_target rf_enroll_sem_foc rf_enroll_uni_major_foc rf_enroll_uni_foc  rf_enroll_foc   ///
	using "$TABLES/table_foc_fs_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_foc_fs_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{7}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex
	
	*- Table 1: Focal child effect on school quality enrolled
	file open  table_tex	using "$TABLES\table_foc_fs_`sem'_bw`bw_select'_2_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on focal child}\label{tab:table_foc_fs_`sem'_bw`bw_select'_2_${fam_type}}" _n ///
					"\scalebox{0.9}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"\cline{2-3}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& 8th Mathematics  & 8th grade Reading 	\\" _n ///
					"& Peers 			&  Peers 				\\" _n ///
					"& (1) & (2) 								\\" _n ///
					"\bottomrule" _n ///
					"&  &   									\\" _n 
	file close table_tex

	estout iv_peer_e_m_2s_foc iv_peer_e_c_2s_foc ///
	using "$TABLES/table_foc_fs_`sem'_bw`bw_select'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_peer_e_m_2s_foc rf_peer_e_c_2s_foc  ///
	using "$TABLES/table_foc_fs_`sem'_bw`bw_select'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_foc_fs_`sem'_bw`bw_select'_2_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{3}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex	

}


*----------------------
*- Main table
*----------------------


if inlist("${t_header}","t_sib_choices") == 1 {
	*- Table 2: Sibling spillovers on college choices
	file open  table_tex	using "$TABLES\table_sib_choices_`sem'_bw`bw_select'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger sibling choices}\label{tab:table_sib_choices_`sem'_bw`bw_select'_1_${fam_type}}" _n ///
					"\scalebox{0.9}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{2}{c}{Older sibling's }  & \multicolumn{2}{c}{Older sibling's}   & \multicolumn{2}{c}{Older sibling's }   \\" _n ///
					"& \multicolumn{2}{c}{target college}  & \multicolumn{2}{c}{target college-major}   & \multicolumn{2}{c}{target major}    \\" _n ///
					"\cline{2-3} \cline{4-5} \cline{6-7} " _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& Applied & Enrolled & Applied & Enrolled & Applied & Enrolled \\" _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6)  \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & & & \\" _n 
	file close table_tex
	
	estout iv_applied_uni_sib iv_enroll_uni_sib iv_app_u_m_sib iv_enr_u_m_sib iv_applied_major_sib iv_enroll_major_sib ///
	using "$TABLES/table_sib_choices_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib rf_enroll_uni_sib rf_app_u_m_sib rf_enr_u_m_sib rf_applied_major_sib rf_enroll_major_sib  ///
	using "$TABLES/table_sib_choices_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_choices_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{7}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex
}


*----------------------
*- STEM
*----------------------


if inlist("${t_header}","t_sib_stem") == 1 {
	*- Table 2: Sibling spillovers on college choices
	file open  table_tex	using "$TABLES\table_sib_stem_`sem'_bw`bw_select'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger sibling choices over STEM majors}\label{tab:table_sib_stem_`sem'_bw`bw_select'_1_${fam_type}}" _n ///
					"\scalebox{0.9}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"&  \multicolumn{2}{c}{STEM Major} 		&  	\multicolumn{2}{c}{Non-STEM Major} 	 	 \\" _n ///
					"\cline{2-3} \cline{4-5} " _n ///
					"&  Applied 		& Enrolled 			& Applied 	& Enrolled 						\\" _n ///
					"& (1) 				& (2) 				& (3) 		& (4) 			 				\\" _n ///					
					"\bottomrule" _n ///
					"&  &  &  &  \\" _n 
	file close table_tex
	
	estout iv_app_stem iv_enr_stem  iv_app_nstem iv_enr_nstem ///
	using "$TABLES/table_sib_choices_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_app_stem rf_enr_stem  rf_app_nstem rf_enr_nstem  ///
	using "$TABLES/table_sib_stem_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_stem_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{5}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex
}



*----------------------
*- Other school and university outcomes
*----------------------	
	
	*- Table 3: Sibling spillovers on other outcomes
	// 8th grade math exam
	// 8th grade comm exam	
	// 8th grade aspirations for higher education
	// 8th grade aspiration in years of education
	// Applies on time
	// # of applications
	
	// PENDING
	// Pass grade (X years after application)
	// Pass Math/Comm
	// Complete primary
	// Complete secondary
	// Dropout
	
	
	// Heterogeneity
	// Unlikely college-goers
	// Likely college-goers
	
	
*----------------------
*- School outcomes
*----------------------	
if inlist("${t_header}","t_sib_school") == 1 {	
	file open  table_tex	using "$TABLES\table_sib_school_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger sibling school outcomes}\label{tab:table_sib_school_outcomes_`sem'_bw`bw_select'_1_${fam_type}}" _n ///
					"\scalebox{0.9}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{2}{c}{8th grade exam }  & \multicolumn{2}{c}{School Completion}   \\" _n ///
					"\cline{2-3} \cline{4-5}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& \multirow{2}{*}{Math} 	& \multirow{2}{*}{Read} 	& \multirow{2}{*}{Dropout} 	& Completed	 \\" _n ///
					"&  						&  						 	&  							& Secondary	 \\" _n ///
					"& (1) 						& (2) 						& (3) 						& (4) 			 \\" _n ///
					"\bottomrule" _n ///
					"&  &  &    \\" _n 
	file close table_tex

	estout iv_math_2s_sib iv_comm_2s_sib iv_dout_e_sib  iv_secg_sib ///
	using "$TABLES/table_sib_school_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout  rf_math_2s_sib rf_comm_2s_sib rf_dout_e_sib rf_secg_sib ///
	using "$TABLES/table_sib_school_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_school_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{5}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex	
}	
	

*----------------------
*- School Progression
*----------------------	
if inlist("${t_header}","t_sib_prog") == 1 {	
	file open  table_tex	using "$TABLES\table_sib_school_progression_`sem'_bw`bw_select'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger sibling school progression}\label{tab:table_sib_school_progression_`sem'_bw`bw_select'_1_${fam_type}}" _n ///
					"\scalebox{0.9}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& \multicolumn{2}{c}{Approved grade} 	& \multicolumn{2}{c}{Approved grade directly}  	& \multicolumn{2}{c}{Changed schools} \\" _n ///
					"\cline{2-3} \cline{4-5}  \cline{6-7}" _n ///
					"&  \textit{t} 	& \textit{t+1} 			&  \textit{t} 	& \textit{t+1} 					&  \textit{t} 	& \textit{t+1} \\" _n ///
					"& (1) 			& (2) 					& (3) 			& (4) 							& (5) 	 		& (6)	 \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & &   \\" _n 
	file close table_tex

	estout  iv_approved_sib iv_approved_next_sib   iv_approved_first_sib iv_approved_first_next_sib  iv_change_ie_sib iv_change_ie_next_sib ///
	using "$TABLES/table_sib_school_progression_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout   rf_approved_sib rf_approved_next_sib   rf_approved_first_sib rf_approved_first_next_sib  rf_change_ie_sib rf_change_ie_next_sib  ///
	using "$TABLES/table_sib_school_progression_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_school_progression_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{7}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex	
}	
		
	
*----------------------
*- University outcomes
*----------------------	
if inlist("${t_header}","t_sib_univ") == 1 {	
// In terms of applications/enrollment	
	file open  table_tex	using "$TABLES\table_sib_univ_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger sibling college applications}\label{tab:table_sib_univ_outcomes_`sem'_bw`bw_select'_1_${fam_type}}" _n ///
					"\scalebox{1}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" & \multicolumn{3}{c}{Any }   			& \multicolumn{3}{c}{\multirow{2}{*}{Applications}}    \\" _n ///
					" & \multicolumn{3}{c}{college-major}   & \multicolumn{3}{c}{}   \\" _n ///
					"\cline{2-4} \cline{5-7}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& Applied 			& Admitted 		& Enrolled 		& On Time 		& Total & App. Score		\\" _n ///
					"& (1) 				& (2) 			& (3) 			& (4) 			& (5)	 &  (6) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  &  & \\" _n 
	file close table_tex

	estout  iv_applied_sib iv_admitted_sib iv_enroll_sib  iv_app_ot_sib iv_N_apps_sib iv_app_sco_m_sib  ///
	using "$TABLES/table_sib_univ_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout   rf_applied_sib rf_admitted_sib rf_enroll_sib  rf_app_ot_sib rf_N_apps_sib rf_app_sco_m_sib ///
	using "$TABLES/table_sib_univ_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_univ_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{7}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex	
		
//Quality of enrollment
	file open  table_tex	using "$TABLES\table_sib_univ_outcomes_`sem'_bw`bw_select'_2_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger quality of enrolled college}\label{tab:table_sib_univ_outcomes_`sem'_bw`bw_select'_2_${fam_type}}" _n ///
					"\scalebox{1}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" & \multicolumn{2}{c}{Peer 8th grade score }   			   \\" _n ///
					"\cline{2-3}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& Math 			& Reading 		\\" _n ///
					"& (1) 				& (2) 			\\" _n ///
					"\bottomrule" _n ///
					"&  &  &  &  & \\" _n 
	file close table_tex

	estout  iv_peer_e_m_2s_sib iv_peer_e_c_2s_sib ///
	using "$TABLES/table_sib_univ_outcomes_`sem'_bw`bw_select'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout   rf_peer_e_m_2s_sib rf_peer_e_c_2s_sib ///
	using "$TABLES/table_sib_univ_outcomes_`sem'_bw`bw_select'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_univ_outcomes_`sem'_bw`bw_select'_2_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{3}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex		
}
*----------------------
*- aspirations and beliefs
*----------------------	
	
if inlist("${t_header}","t_sib_asp") == 1 {	
	file open  table_tex	using "$TABLES\table_sib_asp_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger sibling aspirations}\label{tab:table_sib_asp_outcomes_`sem'_bw`bw_select'_1_${fam_type}}" _n ///
					"\scalebox{0.8}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" & \multicolumn{7}{c}{Aspirations}      \\" _n ///
					"\cline{2-5} \cline{6-8}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					" 	& \multicolumn{4}{c}{4th grade}   				& \multicolumn{3}{c}{8th grade}    				\\" _n ///
					" 	& \multicolumn{4}{c}{(parents) }   				& \multicolumn{3}{c}{(students)}    			\\" _n ///
					"\cline{2-5} \cline{6-8}" _n ///
					"	& Complete Sec. & 2+ college  	& 4+ College 	& Years Ed. 	& 2+ college  	& 4+ College 	& Years Ed. 	\\" _n ///
					"	& (1)  			&  (2) 			&	(3)			& (4) 			& (5)			& (6)			& (7)			\\" _n ///
					"\bottomrule" _n ///
					"&  &  & & & &  \\" _n 
	file close table_tex

	estout iv_asp_s_4p_sib iv_asp_2_4p_sib iv_asp_4_4p_sib iv_asp_y_4p_sib iv_asp_2_2s_sib iv_asp_4_2s_sib iv_asp_y_2s_sib ///
	using "$TABLES/table_sib_asp_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout  rf_asp_s_4p_sib rf_asp_2_4p_sib rf_asp_4_4p_sib rf_asp_y_4p_sib rf_asp_2_2s_sib rf_asp_4_2s_sib rf_asp_y_2s_sib  ///
	using "$TABLES/table_sib_asp_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_asp_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{8}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex	
}		

*----------------------
*- Gender beliefs
*----------------------	
	
if inlist("${t_header}","t_sib_gender") == 1 {	
	file open  table_tex	using "$TABLES\table_sib_gender_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on parents beliefs over gender}\label{tab:table_sib_gender_outcomes_`sem'_bw`bw_select'_1_${fam_type}}" _n ///
					"\scalebox{1}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" & \multicolumn{4}{c}{Gender beliefs about Mathematics/reading}      \\" _n ///
					"\cline{2-4}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"	& Gender bias 	& Gender bias  	& Gender bias  		\\" _n ///
					"	& index  		& index (boys) 	& index (girls) 	\\" _n ///
					"	& (1)  			&  (2) 			&	(3)				\\" _n ///
					"\bottomrule" _n ///
					"&  &  &   \\" _n 
	file close table_tex

	estout iv_gender_4p_all iv_gender_4p_boy iv_gender_4p_girl ///
	using "$TABLES/table_sib_gender_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout  rf_gender_4p_all rf_gender_4p_boy rf_gender_4p_girl  ///
	using "$TABLES/table_sib_gender_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_gender_outcomes_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{4}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex	
}		
	
*----------------------
*- Heterogeneity by older sibling ###CHANGE IF HETEROG CHANGES
*----------------------		

if inlist("${t_header}","t_sib_heterog") == 1 {	
	
	local title_simpf = "likelihood of focal child going to college (simple)"	
	local panel_a_simpf = "Focal is uncertain college-goer (simple model)"	
	local panel_b_simpf = "Focal is probable college-goer (simple model)"	
	
	local title_fullf = "likelihood of focal child going to college (full)"	
	local panel_a_fullf = "Focal is uncertain college-goers (full model)"	
	local panel_b_fullf = "Focal is probable college-goers (full model)"
		
	local title_simps = "likelihood of going to college (simple)"	
	local panel_a_simps = "Uncertain college-goers (simple model)"	
	local panel_b_simps = "Probable college-goers (simple model)"	
	
	local title_fulls = "likelihood of going to college (full)"	
	local panel_a_fulls = "Uncertain college-goers (full model)"	
	local panel_b_fulls = "Probable college-goers (full model)"	
	
	local title_pared = "parent's education"	
	local panel_a_pared = "Parents do not have any level of higher education"	
	local panel_b_pared = "Parents have some level of higher education"	
	
	local title_acad = "acadmic skills"	
	local panel_a_acad = "Below median of academic score (8th grade)"	
	local panel_b_acad = "Above median of academic score (8th grade)"	
	
	local title_ses = "socio-economic status"	
	local panel_a_ses = "Lower SES"	
	local panel_b_ses = "Medium-Upper SES"	
	
	local title_ssex = "sex match between siblings"	
	local panel_a_ssex = "Focal child and sibling are from different sex"	
	local panel_b_ssex = "Focal child and sibling are from the same sex"	
	
	local title_gap = "age gap between siblings"	
	local panel_a_gap = "Focal child and sibling are $<=$3 years apart"	
	local panel_b_gap = "Focal child and sibling are 4+ years apart"	
	
	local title_malef = "sex of focal child"	
	local panel_a_malef = "Focal child is a female"	
	local panel_b_malef = "Focal child is a male"		
	
	local title_males = "sex"	
	local panel_a_males = "Younger sibling is a female"	
	local panel_b_males = "Younger sibling is a male"		
	
	local title_pubs = "type of school"	
	local panel_a_pubs = "Younger sibling goes to private school"	
	local panel_b_pubs = "Younger sibling goes to public school"		
	
	local title_sie = "school match beween siblings"	
	local panel_a_sie = "Focal child and sibling did not go to same school"	
	local panel_b_sie = "Focal child and sibling went to same school"		
		
	*- Table 4: Heterogeneity - Likely and unlikely college-goers
	file open  table_tex	using "$TABLES\table_sib_heterog`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Heterogeneous effect on younger sibling by `title`heterog_type''}\label{tab:table_sib_heterog`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}}" _n ///
					"\scalebox{0.65}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lccccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{2}{c}{Older sibling's }  	& \multicolumn{2}{c}{Any }  		& 	 \multicolumn{2}{c}{School} 		& 	\multicolumn{3}{c}{\multirow{2}{*}{8th grade}}    	\\" _n ///
					"& \multicolumn{2}{c}{target college}  		& \multicolumn{2}{c}{college-major} &  	\multicolumn{2}{c}{Progression}  	&  	\multicolumn{3}{c}{}   								\\" _n ///
					"\cline{2-3} \cline{4-5} \cline{6-7} \cline{8-10}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& Applied & Enrolled & Applied  & Enrolled & Dropout & Sec Complete & Math  & Reading & Aspirations 4+ \\" _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) & (9)  \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & &  & &  & & \\" _n  ///
					"\multicolumn{10}{l}{Panel A: `panel_a`heterog_type''} \\" _n
	file close table_tex
	
	*- Dummy=0
	estout iv_applied_uni_sib`heterog_type'0 iv_enroll_uni_sib`heterog_type'0 iv_applied_sib`heterog_type'0 /*iv_admitted_sib`heterog_type'0*/ iv_enroll_sib`heterog_type'0 iv_dout_e_sib`heterog_type'0 iv_secg_sib`heterog_type'0 iv_math_2s_sib`heterog_type'0 iv_comm_2s_sib`heterog_type'0 iv_asp_4_2s_sib`heterog_type'0   ///
	using "$TABLES/table_sib_heterog`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib`heterog_type'0 rf_enroll_uni_sib`heterog_type'0 rf_applied_sib`heterog_type'0 /*rf_admitted_sib`heterog_type'0*/ rf_enroll_sib`heterog_type'0  rf_dout_e_sib`heterog_type'0 rf_secg_sib`heterog_type'0 rf_math_2s_sib`heterog_type'0 rf_comm_2s_sib`heterog_type'0  rf_asp_4_2s_sib`heterog_type'0    ///
	using "$TABLES/table_sib_heterog`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\table_sib_heterog`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex ///
						"&  &  &  & & & & & & & \\" _n  ///
					"\multicolumn{10}{l}{Panel B: `panel_b`heterog_type''} \\" _n
	file close table_tex	
	
	*- Dumm=1
	estout iv_applied_uni_sib`heterog_type'1 iv_enroll_uni_sib`heterog_type'1 iv_applied_sib`heterog_type'1 /*iv_admitted_sib`heterog_type'1*/ iv_enroll_sib`heterog_type'1 iv_dout_e_sib`heterog_type'1 iv_secg_sib`heterog_type'1 iv_math_2s_sib`heterog_type'1 iv_comm_2s_sib`heterog_type'1 iv_asp_4_2s_sib`heterog_type'1   ///
	using "$TABLES/table_sib_heterog`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib`heterog_type'1 rf_enroll_uni_sib`heterog_type'1 rf_applied_sib`heterog_type'1 /*rf_admitted_sib`heterog_type'1*/ rf_enroll_sib`heterog_type'1  rf_dout_e_sib`heterog_type'1 rf_secg_sib`heterog_type'1 rf_math_2s_sib`heterog_type'1 rf_comm_2s_sib`heterog_type'1  rf_asp_4_2s_sib`heterog_type'1    ///
	using "$TABLES/table_sib_heterog`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	
	file open  table_tex	using "$TABLES\table_sib_heterog`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{10}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex
		
	/*
	*- Table 4: Heterogeneity - Likely and unlikely college-goers
	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_bw`bw_select'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effects on younger sibling by likelihood of going to college of older sibling}\label{tab:table_sib_heterog_foc_`sem'_bw`bw_select'_1_${fam_type}}" _n ///
					"\scalebox{0.9}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{2}{c}{Older sibling's }  	& \multicolumn{3}{c}{Any }  		& 	\multicolumn{3}{c}{\multirow{2}{*}{8th grade}}    	\\" _n ///
					"& \multicolumn{2}{c}{target college}  		& \multicolumn{3}{c}{college-major} &  	\multicolumn{3}{c}{}   								\\" _n ///
					"\cline{2-3} \cline{4-6} \cline{7-9}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& Applied & Enrolled & Applied & Admitted & Enrolled & Math  & Read & Aspirations \\" _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8)  \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & & & & &  \\" _n  ///
					"\multicolumn{9}{l}{Panel A: All students} \\" _n
	file close table_tex

	estout iv_applied_uni_sib iv_enroll_uni_sib iv_applied_sib iv_admitted_sib iv_enroll_sib  iv_math_2s_sib iv_comm_2s_sib iv_asp_4_2s_sib   ///
	using "$TABLES/table_sib_heterog_foc_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib rf_enroll_uni_sib rf_applied_sib rf_admitted_sib rf_enroll_sib  rf_math_2s_sib rf_comm_2s_sib rf_asp_4_2s_sib    ///
	using "$TABLES/table_sib_heterog_foc_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex ///
						"&  &  &  & & & & & & \\" _n  ///
					"\multicolumn{9}{l}{Panel B: Uncertain college-goers (simple estimate)} \\" _n
	file close table_tex
	
	*- Uncertain college-goers
	estout iv_applied_uni_sib_simpf0 iv_enroll_uni_sib_simpf0 iv_applied_sib_simpf0 iv_admitted_sib_simpf0 iv_enroll_sib_simpf0  iv_math_2s_sib_simpf0 iv_comm_2s_sib_simpf0 iv_asp_4_2s_sib_simpf0   ///
	using "$TABLES/table_sib_heterog_foc_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_simpf0 rf_enroll_uni_sib_simpf0 rf_applied_sib_simpf0 rf_admitted_sib_simpf0 rf_enroll_sib_simpf0  rf_math_2s_sib_simpf0 rf_comm_2s_sib_simpf0 rf_asp_4_2s_sib_simpf0    ///
	using "$TABLES/table_sib_heterog_foc_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex ///
						"&  &  &  & & & & & & \\" _n  ///
					"\multicolumn{9}{l}{Panel C: Probable college-goers (simple estimate)} \\" _n
	file close table_tex	
	
	*- Probable college-goers
	estout iv_applied_uni_sib_simpf1 iv_enroll_uni_sib_simpf1 iv_applied_sib_simpf1 iv_admitted_sib_simpf1 iv_enroll_sib_simpf1  iv_math_2s_sib_simpf1 iv_comm_2s_sib_simpf1 iv_asp_4_2s_sib_simpf1   ///
	using "$TABLES/table_sib_heterog_foc_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_simpf1 rf_enroll_uni_sib_simpf1 rf_applied_sib_simpf1 rf_admitted_sib_simpf1 rf_enroll_sib_simpf1  rf_math_2s_sib_simpf1 rf_comm_2s_sib_simpf1 rf_asp_4_2s_sib_simpf1    ///
	using "$TABLES/table_sib_heterog_foc_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	
	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{9}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex
	
	**** Continued
	
	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_bw`bw_select'_2_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{(continued) Effects on younger sibling by likelihood of going to college of older sibling}\label{tab:table_sib_heterog_foc_`sem'_bw`bw_select'_2_${fam_type}}" _n ///
					"\scalebox{0.9}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{2}{c}{Older sibling's }  	& \multicolumn{3}{c}{Any }  		& 	\multicolumn{3}{c}{\multirow{2}{*}{8th grade}}    	\\" _n ///
					"& \multicolumn{2}{c}{target college}  		& \multicolumn{3}{c}{college-major} &  	\multicolumn{3}{c}{}   								\\" _n ///
					"\cline{2-3} \cline{4-6} \cline{7-9}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& Applied & Enrolled & Applied & Admitted & Enrolled & Math  & Read & Aspirations \\" _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8)  \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & & & & &  \\" _n  ///
					"\multicolumn{9}{l}{Panel D: Uncertain college-goers (full estimate)} \\" _n
	file close table_tex
	
	*- Uncertain college-goers
	estout iv_applied_uni_sib_fullf0 iv_enroll_uni_sib_fullf0 iv_applied_sib_fullf0 iv_admitted_sib_fullf0 iv_enroll_sib_fullf0  iv_math_2s_sib_fullf0 iv_comm_2s_sib_fullf0 iv_asp_4_2s_sib_fullf0   ///
	using "$TABLES/table_sib_heterog_foc_`sem'_bw`bw_select'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_fullf0 rf_enroll_uni_sib_fullf0 rf_applied_sib_fullf0 rf_admitted_sib_fullf0 rf_enroll_sib_fullf0  rf_math_2s_sib_fullf0 rf_comm_2s_sib_fullf0 rf_asp_4_2s_sib_fullf0    ///
	using "$TABLES/table_sib_heterog_foc_`sem'_bw`bw_select'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_bw`bw_select'_2_${fam_type}.tex", append write
	file write table_tex ///
						"&  &  &  & & & & & & \\" _n  ///
					"\multicolumn{9}{l}{Panel E: Probable college-goers (full estimate)} \\" _n
	file close table_tex	
	
	*- Probable college-goers
	estout iv_applied_uni_sib_fullf1 iv_enroll_uni_sib_fullf1 iv_applied_sib_fullf1 iv_admitted_sib_fullf1 iv_enroll_sib_fullf1  iv_math_2s_sib_fullf1 iv_comm_2s_sib_fullf1 iv_asp_4_2s_sib_fullf1   ///
	using "$TABLES/table_sib_heterog_foc_`sem'_bw`bw_select'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_fullf1 rf_enroll_uni_sib_fullf1 rf_applied_sib_fullf1 rf_admitted_sib_fullf1 rf_enroll_sib_fullf1  rf_math_2s_sib_fullf1 rf_comm_2s_sib_fullf1 rf_asp_4_2s_sib_fullf1    ///
	using "$TABLES/table_sib_heterog_foc_`sem'_bw`bw_select'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	
	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_bw`bw_select'_2_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{9}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex


*----------------------
*- Heterogeneity by younger sibling
*----------------------		
	
	*- Table 4: Heterogeneity - Likely and unlikely college-goers
	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_bw`bw_select'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effects on younger sibling by likelihood of going to college of older sibling}\label{tab:table_sib_heterog_sib_`sem'_bw`bw_select'_1_${fam_type}}" _n ///
					"\scalebox{0.9}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{2}{c}{Older sibling's }  	& \multicolumn{3}{c}{Any }  		& 	\multicolumn{3}{c}{\multirow{2}{*}{8th grade}}    	\\" _n ///
					"& \multicolumn{2}{c}{target college}  		& \multicolumn{3}{c}{college-major} &  	\multicolumn{3}{c}{}   								\\" _n ///
					"\cline{2-3} \cline{4-6} \cline{7-9}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& Applied & Enrolled & Applied & Admitted & Enrolled & Math  & Read & Aspirations \\" _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8)  \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & & & & &  \\" _n  ///
					"\multicolumn{9}{l}{Panel A: All students} \\" _n
	file close table_tex

	estout iv_applied_uni_sib iv_enroll_uni_sib iv_applied_sib iv_admitted_sib iv_enroll_sib  iv_math_2s_sib iv_comm_2s_sib iv_asp_4_2s_sib   ///
	using "$TABLES/table_sib_heterog_sib_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib rf_enroll_uni_sib rf_applied_sib rf_admitted_sib rf_enroll_sib  rf_math_2s_sib rf_comm_2s_sib rf_asp_4_2s_sib    ///
	using "$TABLES/table_sib_heterog_sib_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex ///
						"&  &  &  & & & & & & \\" _n  ///
					"\multicolumn{9}{l}{Panel B: Uncertain college-goers (simple estimate)} \\" _n
	file close table_tex
	
	*- Uncertain college-goers
	estout iv_applied_uni_sib_simps0 iv_enroll_uni_sib_simps0 iv_applied_sib_simps0 iv_admitted_sib_simps0 iv_enroll_sib_simps0  iv_math_2s_sib_simps0 iv_comm_2s_sib_simps0 iv_asp_4_2s_sib_simps0   ///
	using "$TABLES/table_sib_heterog_sib_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_simps0 rf_enroll_uni_sib_simps0 rf_applied_sib_simps0 rf_admitted_sib_simps0 rf_enroll_sib_simps0  rf_math_2s_sib_simps0 rf_comm_2s_sib_simps0 rf_asp_4_2s_sib_simps0    ///
	using "$TABLES/table_sib_heterog_sib_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex ///
						"&  &  &  & & & & & & \\" _n  ///
					"\multicolumn{9}{l}{Panel C: Probable college-goers (simple estimate)} \\" _n
	file close table_tex	
	
	*- Probable college-goers
	estout iv_applied_uni_sib_simps1 iv_enroll_uni_sib_simps1 iv_applied_sib_simps1 iv_admitted_sib_simps1 iv_enroll_sib_simps1  iv_math_2s_sib_simps1 iv_comm_2s_sib_simps1 iv_asp_4_2s_sib_simps1   ///
	using "$TABLES/table_sib_heterog_sib_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_simps1 rf_enroll_uni_sib_simps1 rf_applied_sib_simps1 rf_admitted_sib_simps1 rf_enroll_sib_simps1  rf_math_2s_sib_simps1 rf_comm_2s_sib_simps1 rf_asp_4_2s_sib_simps1    ///
	using "$TABLES/table_sib_heterog_sib_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	
	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{9}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex
	
	**** Continued
	
	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_bw`bw_select'_2_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{(continued) Effects on younger sibling by likelihood of going to college of older sibling}\label{tab:table_sib_heterog_sib_`sem'_bw`bw_select'_2_${fam_type}}" _n ///
					"\scalebox{0.9}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{2}{c}{Older sibling's }  	& \multicolumn{3}{c}{Any }  		& 	\multicolumn{3}{c}{\multirow{2}{*}{8th grade}}    	\\" _n ///
					"& \multicolumn{2}{c}{target college}  		& \multicolumn{3}{c}{college-major} &  	\multicolumn{3}{c}{}   								\\" _n ///
					"\cline{2-3} \cline{4-6} \cline{7-9}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& Applied & Enrolled & Applied & Admitted & Enrolled & Math  & Read & Aspirations \\" _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8)  \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & & & & &  \\" _n  ///
					"\multicolumn{9}{l}{Panel D: Uncertain college-goers (full estimate)} \\" _n
	file close table_tex
	
	*- Uncertain college-goers
	estout iv_applied_uni_sib_fulls0 iv_enroll_uni_sib_fulls0 iv_applied_sib_fulls0 iv_admitted_sib_fulls0 iv_enroll_sib_fulls0  iv_math_2s_sib_fulls0 iv_comm_2s_sib_fulls0 iv_asp_4_2s_sib_fulls0   ///
	using "$TABLES/table_sib_heterog_sib_`sem'_bw`bw_select'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_fulls0 rf_enroll_uni_sib_fulls0 rf_applied_sib_fulls0 rf_admitted_sib_fulls0 rf_enroll_sib_fulls0  rf_math_2s_sib_fulls0 rf_comm_2s_sib_fulls0 rf_asp_4_2s_sib_fulls0    ///
	using "$TABLES/table_sib_heterog_sib_`sem'_bw`bw_select'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_bw`bw_select'_2_${fam_type}.tex", append write
	file write table_tex ///
						"&  &  &  & & & & & & \\" _n  ///
					"\multicolumn{9}{l}{Panel E: Probable college-goers (full estimate)} \\" _n
	file close table_tex	
	
	*- Probable college-goers
	estout iv_applied_uni_sib_fulls1 iv_enroll_uni_sib_fulls1 iv_applied_sib_fulls1 iv_admitted_sib_fulls1 iv_enroll_sib_fulls1  iv_math_2s_sib_fulls1 iv_comm_2s_sib_fulls1 iv_asp_4_2s_sib_fulls1   ///
	using "$TABLES/table_sib_heterog_sib_`sem'_bw`bw_select'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_fulls1 rf_enroll_uni_sib_fulls1 rf_applied_sib_fulls1 rf_admitted_sib_fulls1 rf_enroll_sib_fulls1  rf_math_2s_sib_fulls1 rf_comm_2s_sib_fulls1 rf_asp_4_2s_sib_fulls1    ///
	using "$TABLES/table_sib_heterog_sib_`sem'_bw`bw_select'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	
	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_bw`bw_select'_2_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{9}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex
	*/
}	

	
*----------------------
*- Heterogeneity by older sibling ###CHANGE IF HETEROG CHANGES
*----------------------		

if inlist("${t_header}","t_sib_heterog_stem") == 1 {	
	
	local title_stem_sf = "Focal child applied to STEM and younger sibling is female"	
	local panel_a_stem_sf = "Focal child is a female (sex-match)"		
	local panel_b_stem_sf = "Focal child is a male"	
	
	local title_stem_sm = "Focal child applied to STEM and younger sibling is male"	
	local panel_a_stem_sm = "Focal child is a female"		
	local panel_b_stem_sm = "Focal child is a male (sex-match)"	
	
	local title_nstem_sf = "Focal child applied to non-STEM and younger sibling is female"	
	local panel_a_nstem_sf = "Focal child is a female (sex-match)"		
	local panel_b_nstem_sf = "Focal child is a male"	
	
	local title_nstem_sm = "Focal child applied to non-STEM and younger sibling is male"	
	local panel_a_nstem_sm = "Focal child is a female"		
	local panel_b_nstem_sm = "Focal child is a male (sex-match)"		
	
		
	*- Table 4: Heterogeneity - Likely and unlikely college-goers
	file open  table_tex	using "$TABLES\table_sib_heterog_stem`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger sibling choices over STEM majors: `title`heterog_type''}\label{tab:table_sib_stem_`sem'_bw`bw_select'_1_${fam_type}}" _n ///
					"\scalebox{0.7}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"&  \multicolumn{2}{c}{School}  	&  \multicolumn{3}{c}{Applies} 				&  	\multicolumn{3}{c}{Enrolls} 	 	\\" _n ///
					"&  \multicolumn{2}{c}{Progression} &  \multicolumn{3}{c}{ever} 				&  	\multicolumn{3}{c}{ever} 	 	\\" _n ///
					"\cline{2-3} \cline{4-6} \cline{7-9} " _n ///
					"&  \multirow{2}{*}{Dropout}  	& Secondary 		&  Any 			& STEM  			& Non-STEM  	&  Any 		& STEM  		& Non-STEM 		\\" _n ///
					"&   							& Complete 			&  Major 		& Major 			& Major 		&  Major 	& Major 		& Major			\\" _n ///
					"& (1) 							& (2) 				& (3) 			& (4) 				& (5) 			& (6) 		& (7) 			& (9)		 	\\" _n ///					
					"\bottomrule" _n ///
					"&  &  &  & & & & & \\" _n ///
					"\multicolumn{9}{l}{Panel A: `panel_a`heterog_type''} \\" _n
	file close table_tex
	
	*- Dummy=0
	estout  iv_dout_e_sib`heterog_type'0 iv_secg_sib`heterog_type'0 iv_applied_sib`heterog_type'0 iv_app_stem`heterog_type'0 iv_app_nstem`heterog_type'0  iv_enroll_sib`heterog_type'0 iv_enr_stem`heterog_type'0  iv_enr_nstem`heterog_type'0 ///
	using "$TABLES/table_sib_heterog_stem`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout rf_dout_e_sib`heterog_type'0 rf_secg_sib`heterog_type'0 rf_applied_sib`heterog_type'0 rf_app_stem`heterog_type'0 rf_app_nstem`heterog_type'0  rf_enroll_sib`heterog_type'0 rf_enr_stem`heterog_type'0  rf_enr_nstem`heterog_type'0 ///
	using "$TABLES/table_sib_heterog_stem`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\table_sib_heterog_stem`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex ///
					"&  &  &  &  \\" _n ///
					"\multicolumn{10}{l}{Panel B: `panel_b`heterog_type''} \\" _n
	file close table_tex	
	
	*- Dummy=0
	estout iv_dout_e_sib`heterog_type'1 iv_secg_sib`heterog_type'1 iv_applied_sib`heterog_type'1 iv_app_stem`heterog_type'1 iv_app_nstem`heterog_type'1  iv_enroll_sib`heterog_type'1 iv_enr_stem`heterog_type'1  iv_enr_nstem`heterog_type'1 ///
	using "$TABLES/table_sib_heterog_stem`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout rf_dout_e_sib`heterog_type'1 rf_secg_sib`heterog_type'1 rf_applied_sib`heterog_type'1 rf_app_stem`heterog_type'1 rf_app_nstem`heterog_type'1  rf_enroll_sib`heterog_type'1 rf_enr_stem`heterog_type'1  rf_enr_nstem`heterog_type'1 ///
	using "$TABLES/table_sib_heterog_stem`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	
	file open  table_tex	using "$TABLES\table_sib_heterog_stem`heterog_type'_`sem'_bw`bw_select'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{9}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex
	
}

end

//table_sib_choices_1_2
//table_sib_school_outcomes_1_2
//table_sib_heterog_1_2	
	


***** Run program

main


