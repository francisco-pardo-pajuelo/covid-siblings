
	clear
	
		
	//Sample
	global fam_type = 2
	global sem = "all"
	global bw_select "optimal"

	//Outcome
	local outcome "applied_sib"


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
		/*ID*/						id_cutoff id_fam_* fam_order_2 fam_order_2_sib ///
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



global outcome "enroll_sib"
if "${outcome}" == "enroll_sib"  					global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & fam_order_2==1" //exp_graduating_year1_sib+2>=year_app_foc
global if_apps "first_sem_application==1"
global bw_${outcome} =  0.694	
global if_final "${if_pre} & ${if_apps}"					

	di as text "OPTIMAL BANDWIDTH" ${bw_${outcome}}
	
	//global bw_${outcome} = 0.8894
	*-- Reduced form
	reghdfe ${outcome} ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.