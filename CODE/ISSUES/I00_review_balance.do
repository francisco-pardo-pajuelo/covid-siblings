*- Testing balance
************************
local fam_type 		2 			//FIXED
local cell 			major 		//FIXED
local type 			noz			//FIXED
local sem 			first		//FLEX: all, first
local bw_select 	fixed		//FLEX: fixed, optimal

global sem = "`sem'"
global fam_type = `fam_type'
global iv 		= "enroll_uni_major_sem_foc"	
global outcome 	= "score_math_std_2s_foc"	
global window =  2


***********************************


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
	
		

************************



capture estimates drop _all


use "$OUT/applied_outcomes_${fam_type}.dta", clear

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
	
		*- Public schools
	keep if public_foc==1

	*- Exclude those without estimated cutoffs
	keep if lottery_nocutoff == 0

	*- Exclude those at cutoff
	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)		
	//keep if not_at_cutoff==1
	
	*- Exclude those without sibling
	//drop if any_sib_match==0
	
	*- Keep specific samples of interest
	if "${sem}" == "one" 			keep if one_application==1
	if "${sem}" == "first" 			keep if first_sem_application==1
	if "${sem}" == "first_sem_out" 	keep if (last_year_foc + 1 == year_app_foc) & substr(semester_foc,6,1)=="1" //First semester after finishing school.
	if "${sem}" == "first_year_out" keep if (last_year_foc + 1 == year_app_foc) //First semester after finishing school.
	if "${sem}" == "all" 			keep if 1==1
	if inlist("${sem}","one","first","all","first_sem_out","first_year_out")==0  assert 1==0
	
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
	//keep if sample_oldest==1 

	
	
	
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
	
	
	gen mark1 = (sample_oldest==1)
	gen mark2 = (not_at_cutoff==1)
	gen mark3 = (any_sib_match==1)


/*
isvar ///
/*ID*/					id_cutoff id_fam_* ///
/*RD*/					score_relative  score_relative_* ABOVE_score_relative_* ABOVE admitted enroll_uni_major_sem_foc ///
/*First stage*/			admitted enroll_uni_major_sem_foc enroll_sem_foc enroll_uni_foc enroll_uni_major_foc enroll_uni_foc enroll_foc  avg_enr_score_*_std_??_foc ///
/*sample*/				first_sem_application one_application oldest sample_oldest any_sib_match not_at_cutoff ///
/*Other*/				year_app_foc universidad  ///
/*Demographics*/		exp_graduating_year?_sib year_4p_sib year_2s_sib ///
/*Balance*/				male_foc age score_math_std_2s_foc score_com_std_2s_foc score_acad_std_2s_foc higher_ed_mother vlow_ses_foc ///
/*SIBLING CHOICES*/		applied_uni_sib enroll_uni_sib applied_uni_major_sib enroll_uni_major_sib applied_major_sib enroll_major_sib applied_sib enroll_sib ///
/*SIBLING School*/		score_math_std_2s_sib score_com_std_2s_sib score_acad_std_2s_sib approved_sib approved_next_sib dropout_ever_sib pri_grad_sib sec_grad_sib year_graduate_sib ///
/*SIBLING Survey*/		comp_sec_4p_sib any_coll_4p_sib higher_ed_4p_sib asp_years_4p_sib any_coll_2s_sib higher_ed_2s_sib asp_years_2s_sib std_belief_gender*_??_sib ///
/*SIBLING University*/	admitted_sib applies_on_time_sib N_applications_sib score_std_*_avg_sib avg_enr_score_*_std_??_sib ///
/*Heterogeneity*/		age_gap likely_enrolled* h_* mark?
local all_vars = r(varlist)
ds `all_vars', not
keep `all_vars'
order `all_vars'
*/
//binsreg admitted score_relative

*- Estimate Bandwidth:
//Note: The bandwidth is estimated without cutoff fixed effects due to restrictions of 'rdrobust' on using high dimension fixed effects. The final regression will include fixed effects and some robustness of different bandwidths will be shown in the appendix.
//Similar options as in Altmejd et. al. (2021) for Chile and Croatia have been used.

	
*- Get "if" condition for each outcome
//if_condition

  
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



global if_final "${if_pre}"	



//keep if not_at_cutoff==1
//drop if any_sib_match==0
//keep if sample_oldest==1
//keep if first_sem_application==1

global if_final "${if_pre}"	
/*
ivreghdfe ${outcome}  ${scores_1} ${ABOVE_scores_1} (${iv} = ABOVE) ///  
	if ${if_final} ///
	& abs(score_relative)<${bw_${outcome}`heterog_type'`likely_val'}, ///
	absorb(id_cutoff) cluster(id_fam_${fam_type}) 
*/
*-- Reduced form
reghdfe score_math_std_2s_foc ABOVE  ${scores_1} ${ABOVE_scores_1} ///
	if ${if_final} ///
	& abs(score_relative)<${bw_${outcome}}, ///
	absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

reghdfe score_com_std_2s_foc ABOVE  ${scores_1} ${ABOVE_scores_1} ///
	if ${if_final} ///
	& abs(score_relative)<${bw_${outcome}}, ///
	absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

preserve
	keep if mark1==1 & mark2==1 & mark3==1
	reghdfe score_math_std_2s_foc ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

	reghdfe score_com_std_2s_foc ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.
		
	reghdfe score_math_std_2p_foc ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

	reghdfe score_com_std_2p_foc ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.		
		
	
restore	


preserve
	keep if mark3==1
	reghdfe score_math_std_4p_foc ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

	reghdfe score_com_std_4p_foc ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.
restore	
	
	
	