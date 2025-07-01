/********************************************************************************
- Author: Francisco Pardo
- Description: Produces final tables and figures
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/

capture program drop main 
program define main 

	setup

	
	//mccrary 2 all 
	//mccrary 2 first
	
	//first_stage 2 all
	
	//visual_balance 2 first

	regressions 2 all all    //family ID, sample, outcomes
					// REMOVE tables 2 all all	

	regressions 2 first all

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
capture program drop prepare_rd
program define prepare_rd

	args type cell sem
	
	//local cell major
	//local type noz
	
	rename *_`cell' *
	rename *_`type' * 

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
	gen byte comp_sec_4p_sib			= inlist(aspiration_4p_sib,2,3,4,5) if aspiration_4p_sib!=.
	

	gen asp_years_4p_sib 	 = 6*(aspiration_4p_sib==1)+ 11*(aspiration_4p_sib==2)+ 14*(aspiration_4p_sib==3)+ 16*(aspiration_4p_sib==4)+18*(aspiration_4p_sib==5) if  aspiration_4p_sib!=.		
	gen asp_years_2s_sib 	 = 8*(aspiration_2s_sib==1)+ 11*(aspiration_2s_sib==2)+ 14*(aspiration_2s_sib==3)+ 16*(aspiration_2s_sib==4)+18*(aspiration_2s_sib==5) if  aspiration_2s_sib!=.
	gen applies_on_time_sib 	= (year_applied_sib<=(exp_graduating_year1_sib+1) & applied_sib==1) if exp_graduating_year1_sib!=.
	gen byte vlow_ses_foc 		= socioec_index_cat_2s_foc==1 if socioec_index_cat_2s_foc!=.

	//USE: comp_sec_4p_sib any_coll_4p_sib asp_years_4p_sib, any_coll_2s_sib higher_ed_2s_sib asp_years_2s_sib
	
	
	gen byte approved_sib = .
	gen byte approved_next_sib = .
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		replace approved_sib = approved_`y'_sib if year_app_foc == `y'
		replace approved_next_sib = approved_`y'_sib if year_app_foc+1 == `y'
	}
	
	//averages of enrolled university ###121
	/*
	rename semester_foc semester
	merge m:1 universidad semester using "$OUT\application_averages", keepusing(*_avg_uni) keep(master match)
	rename semester semester_foc 
	*/
	
	//Dividing sample by likelihood
	sum enrolled_lpred1_foc, de
	gen byte likely_enrolled_simpf = (enrolled_lpred1_foc>r(p50)) if enrolled_lpred1_foc!=.
	sum enrolled_lpred3_foc, de
	gen byte likely_enrolled_fullf = (enrolled_lpred3_foc>r(p50)) if enrolled_lpred3_foc!=.	
	sum enrolled_lpred1_sib, de
	gen byte likely_enrolled_simps = (enrolled_lpred1_sib>r(p50)) if enrolled_lpred1_sib!=.	
	sum enrolled_lpred3_sib, de
	gen byte likely_enrolled_fulls = (enrolled_lpred3_sib>r(p50)) if enrolled_lpred3_sib!=.	
	



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
		if "${outcome}" == "asp_years_4p_sib"  			global if_pre "year_4p_sib>=year_app_foc & year_4p_sib!=."
		if "${outcome}" == "any_coll_2s_sib"  			global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		if "${outcome}" == "higher_ed_2s_sib"  			global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		if "${outcome}" == "asp_years_2s_sib"  			global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		
		//Gender beliefs
		if "${outcome}" == "std_belief_gender_boys_4p_sib"  	global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		if "${outcome}" == "std_belief_gender_girls_4p_sib"  	global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
		if "${outcome}" == "std_belief_gender_4p_sib"  			global if_pre "year_2s_sib>=year_app_foc & year_2s_sib!=."
	
		

end		
		
********************************************************************************
* Regressions for tables
********************************************************************************

capture program drop test_reg
program define test_reg


	args fam_type

	estimates drop _all

	global fam_type = `fam_type'
		
	use "$OUT/applied_outcomes_${fam_type}.dta", clear

	prepare_rd noz major

	//binsreg admitted score_relative
	 
	*- Estimate Bandwidth:
	//Note: The bandwidth is estimated without cutoff fixed effects due to restrictions of 'rdrobust' on using high dimension fixed effects. The final regression will include fixed effects and some robustness of different bandwidths will be shown in the appendix.
	//Similar options as in Altmejd et. al. (2021) for Chile and Croatia have been used.

	capture drop year_app_foc_*
	tab year_app_foc, gen(year_app_foc_)
	
	global iv = "enroll_uni_major_sem_foc"	
	global outcome 		"score_math_std_2s_foc"
	local likely_who  	""  //"f" "s"
	local likely_type  	""  //"s" "f"
	local likely_val  	"" // "0" "1"
	

	isvar ${iv} ${outcome} score_relative ABOVE  ${scores_1} ${ABOVE_scores_1} id_cutoff id_fam_${fam_type} exp_graduating_year?_sib year_app_foc year_2s_sib  likely_enrolled*
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
	
	// Get if condition
	if_condition
	
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
	 
		  
	*- We get the optimal bandwidths
	global bw = e(h_l)


			// ""-"" is the full sample. Otherwise, both most have values
			local continue_est = 0
			if ((inlist("`likely_who'","") & inlist("`likely_type'","") & inlist("`likely_val'",""))) 								local continue_est = 1
			if ((inlist("`likely_who'","f","s") & inlist("`likely_type'","_simp","_full") & inlist("`likely_val'","0","1"))) 	local continue_est = 1
			if `continue_est'==0 continue //Either full sample or likelihood well specified.
			
			if inlist("`likely_val'","0","1")==1 & /// We use one only, but that means all have values by previous condition
			inlist("${outcome}","applied_uni_sib","enroll_uni_sib","applied_sib","admitted_sib","enroll_sib","applies_on_time_sib") ==0 & ///
			inlist("${outcome}","score_math_std_2s_sib","score_com_std_2s_sib","score_acad_std_2s_sib","higher_ed_2s_sib")==0 continue //if heterogeneity, only for some outcomes
			if inlist("`likely_val'","0","1")==1 	global if_final "${if_pre} & likely_enrolled`likely_type'`likely_who' == `likely_val'"
			if inlist("`likely_val'","")==1 		global if_final "${if_pre}"
	

	
			ivreghdfe ${outcome}  ${scores_1} ${ABOVE_scores_1} (${iv} = ABOVE) ///  
					if ${if_final} ///
					& abs(score_relative)<${bw_${outcome}}, ///
					absorb(id_cutoff) cluster(id_fam_${fam_type}) ///
					first ffirst savefirst savefprefix(fs_)
					
			*-- Reduced form
			reghdfe ${outcome} ABOVE  ${scores_1} ${ABOVE_scores_1} ///
				if ${if_final} ///
				& abs(score_relative)<${bw_${outcome}}, ///
				absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

		
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

	prepare_rd noz major `sem'
	
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

	prepare_rd noz major `sem'
	
	
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
	graph export 	"$FIGURES/eps/first_stage_enroll_uni_major.eps", replace	
	graph export 	"$FIGURES/pdf/first_stage_enroll_uni_major.pdf", replace			
		
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

	prepare_rd noz major `sem'
	
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
* Regressions for tables
********************************************************************************

capture program drop regressions
program define regressions

	args fam_type sem t_outcomes

	estimates drop _all

	global fam_type = `fam_type'
		
	use "$OUT/applied_outcomes_${fam_type}.dta", clear

	prepare_rd noz major `sem'

	isvar ///
		/*ID*/					id_cutoff id_fam_* ///
		/*RD*/					score_relative  score_relative_* ABOVE_score_relative_* ABOVE admitted enroll_uni_major_sem_foc ///
		/*First stage*/			admitted enroll_uni_major_sem_foc enroll_sem_foc enroll_uni_foc enroll_foc  avg_enr_score_*_std_??_foc ///
		/*sample*/				first_sem_application one_application oldest sample_oldest ///
		/*Other*/				year_app_foc universidad  ///
		/*Demographics*/		exp_graduating_year?_sib year_2s_sib ///
		/*Balance*/				male_foc age score_math_std_2s_foc score_com_std_2s_foc score_acad_std_2s_foc higher_ed_mother vlow_ses_foc ///
		/*SIBLING CHOICES*/		applied_uni_sib enroll_uni_sib applied_uni_major_sib enroll_uni_major_sib applied_major_sib enroll_major_sib applied_sib enroll_sib ///
		/*SIBLING School*/		score_math_std_2s_sib score_com_std_2s_sib score_acad_std_2s_sib approved_sib approved_next_sib dropout_ever_sib pri_grad_sib sec_grad_sib year_graduate_sib ///
		/*SIBLING Survey*/		comp_sec_4p_sib any_coll_4p_sib asp_years_4p_sib any_coll_2s_sib higher_ed_2s_sib asp_years_2s_sib std_belief_gender*_??_sib ///
 		/*SIBLING University*/	admitted_sib applies_on_time_sib N_applications_sib score_std_*_avg_sib avg_enr_score_*_std_??_sib ///
		/*Heterogeneity*/		age_gap likely_enrolled*
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
	local t_header = ""

	foreach outcome in 	///
	/*First Stage*/						"t_first_stage" 	/**/ "admitted" "enroll_uni_major_sem_foc" "enroll_sem_foc" "enroll_foc" "avg_enr_score_math_std_2s_foc" "avg_enr_score_com_std_2s_foc" /// peer_uni_score
	/*BALANCE*/							"t_balance" 		/**/ "male_foc" "age" "score_math_std_2s_foc" "score_com_std_2s_foc" "score_acad_std_2s_foc" "higher_ed_mother" "vlow_ses_foc" ///
	/*SIBLING choices (6)*/				"t_sib_choices" 	/**/ "applied_uni_sib" "enroll_uni_sib" "applied_uni_major_sib" "enroll_uni_major_sib" "applied_major_sib" "enroll_major_sib" ///
	/*SIBLING school (5)*/ 				"t_sib_school" 		/**/ "score_math_std_2s_sib" "score_com_std_2s_sib" "score_acad_std_2s_sib" "approved_sib" "approved_next_sib" "dropout_ever_sib" "sec_grad_sib" ///
	/*SIBLING university (6)*/ 			"t_sib_univ" 		/**/ "applied_sib" "admitted_sib" "enroll_sib" "applies_on_time_sib" "N_applications_sib" "score_std_major_avg_sib" "avg_enr_score_math_std_2s_sib" "avg_enr_score_com_std_2s_sib" ///
	/*SIBLING aspiration/beliefs (6)*/	"t_sib_asp" 		/**/ "comp_sec_4p_sib" "any_coll_4p_sib" "asp_years_4p_sib" "any_coll_2s_sib" "higher_ed_2s_sib" "asp_years_2s_sib"  ///
	/*SIBLING gender beliefs (3)*/		"t_sib_gender" 		/**/ "std_belief_gender_4p_sib" "std_belief_gender_boys_4p_sib" "std_belief_gender_girls_4p_sib" ///
										"t_sib_heterog"		/**/ /// this is only in order to produce the table
	{		
		 //Produce table when beginning a new section (table from previous section (t_header before change) and only if doing the full run or that specific section)
		 if inlist("`outcome'",/*"t_first_stage",*/"t_balance","t_sib_choices","t_sib_school","t_sib_univ","t_sib_asp","t_sib_gender","t_sib_heterog")==1  & ///
			inlist("`t_outcomes'","all","`t_header'")==1 ///
			tables ${fam_type} `sem' `t_header'
		 	
		//Erase estimates when beginning a new section (and having produced table). Keep those needed for Heterogeneity.	
		if inlist("`outcome'",/*"t_first_stage",*/"t_balance","t_sib_choices","t_sib_school","t_sib_univ","t_sib_asp","t_sib_gender","t_sib_heterog")==1  {	
		 		estimates dir
				local est_list = r(names)
				foreach est_var of local est_list {
					if 	strmatch("`est_var'","??_applied_uni_sib*")==0 & ///
						strmatch("`est_var'","??_enroll_uni_sib*")==0 & ///
						strmatch("`est_var'","??_math_2s_sib*")==0 & ///
						strmatch("`est_var'","??_comm_2s_sib*")==0 & ///
						strmatch("`est_var'","??_applied_sib*")==0 & ///
						strmatch("`est_var'","??_admitted_sib*")==0 & ///
						strmatch("`est_var'","??_enroll_sib*")==0 & ///
						strmatch("`est_var'","??_asp_4_2s_sib*")==0 ///
						estimates drop `est_var' 
				}
		 }
		 	
		 //Define current section
		if inlist("`outcome'","t_first_stage","t_balance","t_sib_choices","t_sib_school","t_sib_univ","t_sib_asp","t_sib_gender","t_sib_heterog")==1 local t_header = "`outcome'"
		//If not doing full regression or only running for a section, then skip.
		if inlist("`t_outcomes'","all","`t_header'")==0 continue
		//The header is not an outcome, so we naturally skip them after the previous steps.
		if inlist("`outcome'","t_first_stage","t_balance","t_sib_choices","t_sib_school","t_sib_univ","t_sib_asp","t_sib_gender","t_sib_heterog")==1 continue 
		
		global outcome = "`outcome'"
		
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
		if "${outcome}" == "asp_years_4p_sib" 		local outcome_est = "asp_y_4p_sib"
		if "${outcome}" == "any_coll_2s_sib" 		local outcome_est = "asp_2_2s_sib"
		if "${outcome}" == "higher_ed_2s_sib" 		local outcome_est = "asp_4_2s_sib"
		if "${outcome}" == "asp_years_2s_sib" 		local outcome_est = "asp_y_2s_sib"	
		
		if "${outcome}" == "std_belief_gender_4p_sib" 		local outcome_est = "gender_4p_all"		
		if "${outcome}" == "std_belief_gender_boys_4p_sib" 	local outcome_est = "gender_4p_boys"		
		if "${outcome}" == "std_belief_gender_girls_4p_sib" local outcome_est = "gender_4p_girls"		

		*- Get "if" condition for each outcome
		if_condition
		
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
			 
			  
		*- We get the optimal bandwidths
		global bw_${outcome} = e(h_l)

		*- Main regression
		// We run the main regression with selected bandwidth, including cutoff fixed effects
			  
		*-- IV estimate
		foreach likely_type in "" "_simp" "_full" {
			foreach likely_who in "" "f" "s" { // f=focal, s=sibling
				foreach likely_val in "" "0" "1" { // "" : general results, "0"/"1": heterogeneity results		
					// ""-"" is the full sample. Otherwise, both most have values
					local continue_est = 0
					if ((inlist("`likely_who'","") & inlist("`likely_type'","") & inlist("`likely_val'",""))) 								local continue_est = 1
					if ((inlist("`likely_who'","f","s") & inlist("`likely_type'","_simp","_full") & inlist("`likely_val'","0","1"))) 	local continue_est = 1
					if `continue_est'==0 continue //Either full sample or likelihood well specified.
					
					if inlist("`likely_val'","0","1")==1 & /// We use one only, but that means all have values by previous condition
					inlist("${outcome}","applied_uni_sib","enroll_uni_sib","applied_sib","admitted_sib","enroll_sib","applies_on_time_sib")==0 & ///
					inlist("${outcome}","score_math_std_2s_sib","score_com_std_2s_sib","score_acad_std_2s_sib","higher_ed_2s_sib")==0 continue //if heterogeneity, only for some outcomes
					if inlist("`likely_val'","0","1")==1 	global if_final "${if_pre} & likely_enrolled`likely_type'`likely_who' == `likely_val'"
					if inlist("`likely_val'","")==1 		global if_final "${if_pre}"
		
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
					"Type of prediction:" 		_column(20) 		"`likely_type'" _n ///
					"Likely college sample:" 	_column(20) 		"`likely_val'" _n ///
					"Likelihood based on:" 		_column(20) 		"`likely_who'" _n ///
					"Condition (if):" 			_column(20) 		"${if_final}" _n ///
					as text ///
					"*************************************************" _n  ///
					"****************** Back to code *****************" _n ///
					"*************************************************" _n

					global bw_${outcome}`likely_type'`likely_who'`likely_val' = ${bw_${outcome}}
					
					ivreghdfe ${outcome}  ${scores_1} ${ABOVE_scores_1} (${iv} = ABOVE) ///  
							if ${if_final} ///
							& abs(score_relative)<${bw_${outcome}`likely_type'`likely_who'`likely_val'}, ///
							absorb(id_cutoff) cluster(id_fam_${fam_type}) ///
							first ffirst savefirst savefprefix(fs_)
							
							local fs = e(widstat)

							estadd ysumm
							estadd scalar bandwidth ${bw_${outcome}`likely_type'`likely_who'`likely_val'}
							estadd scalar fstage = `fs'
							estimates store iv_`outcome_est'`likely_type'`likely_who'`likely_val'
							
							//We save first stage estimate in case needed.
							estimates restore fs_${iv}
							estimates store fs_`outcome_est'`likely_type'`likely_who'`likely_val' //In case we need to rename
							
					*-- Reduced form
					reghdfe ${outcome} ABOVE  ${scores_1} ${ABOVE_scores_1} ///
						if ${if_final} ///
						& abs(score_relative)<${bw_${outcome}`likely_type'`likely_who'`likely_val'}, ///
						absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

						estadd ysumm
						estadd scalar bandwidth ${bw_${outcome}`likely_type'`likely_who'`likely_val'}
						estadd scalar fstage = `fs'
						estimates store rf_`outcome_est'`likely_type'`likely_who'`likely_val'
						
			
				}
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

	args fam_type sem t_header

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

*----------------------
*- Balance table
*----------------------		

if inlist("${t_header}","t_balance") == 1 {
	*- Table 2: Sibling spillovers on college choices
	file open  table_tex	using "$TABLES\table_foc_balance_`sem'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on focal child (Balance)}\label{tab:table_foc_balance_`sem'_1_${fam_type}}" _n ///
					"\scalebox{0.9}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{4}{c}{Demographic}  & \multicolumn{3}{c}{8th grade exam}   \\" _n ///
					"\cline{2-5} \cline{6-8}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& \multirow{2}{*}{Male}  	& \multirow{2}{*}{Age} 	& Mother 	& v.Low & \multirow{2}{*}{Math} & \multirow{2}{*}{Read} & \multirow{2}{*}{Acad} 	\\" _n ///
					"&  						&  						& H. ed. 	& SES 	&  						&  						&  							\\" _n ///
					"& (1) 						& (2) 					& (3) 		& (4) 	& (5) 					& (6) 					& (7)   \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & & & & \\" _n 
	file close table_tex
	
	estout iv_male_foc iv_age iv_higher_ed_mother iv_vlow_ses_foc iv_math_2s_foc iv_comm_2s_foc iv_acad_2s_foc ///
	using "$TABLES/table_foc_balance_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_male_foc rf_age rf_higher_ed_mother rf_vlow_ses_foc rf_math_2s_foc rf_comm_2s_foc rf_acad_2s_foc ///
	using "$TABLES/table_foc_balance_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_foc_balance_`sem'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{8}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex
}


*----------------------
*- First Stage
*----------------------

if inlist("${t_header}","t_first_stage") == 1 {
	*- Table 1: Sibling spillovers on college choices
	file open  table_tex	using "$TABLES\table_foc_fs_`sem'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger sibling choices}\label{tab:table_sib_choices_`sem'_1_${fam_type}}" _n ///
					"\scalebox{0.9}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lccccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"\cline{2-7}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& Admitted & Enrolled & Enrolled any & Enrolled ever & Math & Read \\" _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & &  \\" _n 
	file close table_tex

	estout iv_admitted iv_enroll_target iv_enroll_sem_foc iv_enroll_foc iv_peer_e_m_2s_foc iv_peer_e_c_2s_foc ///
	using "$TABLES/table_foc_fs_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_admitted rf_enroll_target rf_enroll_sem_foc rf_enroll_foc rf_peer_e_m_2s_foc rf_peer_e_c_2s_foc  ///
	using "$TABLES/table_foc_fs_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_foc_fs_`sem'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{7}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex

}


*----------------------
*- Main table
*----------------------


if inlist("${t_header}","t_sib_choices") == 1 {
	*- Table 2: Sibling spillovers on college choices
	file open  table_tex	using "$TABLES\table_sib_choices_`sem'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger sibling choices}\label{tab:table_sib_choices_`sem'_1_${fam_type}}" _n ///
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
	using "$TABLES/table_sib_choices_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib rf_enroll_uni_sib rf_app_u_m_sib rf_enr_u_m_sib rf_applied_major_sib rf_enroll_major_sib  ///
	using "$TABLES/table_sib_choices_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_choices_`sem'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{7}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
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
	file open  table_tex	using "$TABLES\table_sib_school_outcomes_`sem'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger sibling school outcomes}\label{tab:table_sib_school_outcomes_`sem'_1_${fam_type}}" _n ///
					"\scalebox{0.9}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{2}{c}{8th grade exam }  & \multicolumn{4}{c}{Progression}   \\" _n ///
					"\cline{2-3} \cline{4-7}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					"& \multirow{2}{*}{Math} 	& \multirow{2}{*}{Read} & Approved  	& Approved  	& \multirow{2}{*}{Dropout} 	& Completed	 \\" _n ///
					"&  						&  						&  \textit{t} 	& \textit{t+1} 	&  							& Secondary	 \\" _n ///
					"& (1) 						& (2) 					& (3) 			& (4) 			& (5) 	 					& (6)	 \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & &   \\" _n 
	file close table_tex

	estout iv_math_2s_sib iv_comm_2s_sib iv_approved_sib iv_approved_next_sib iv_dropout_ever_sib  iv_sec_grad_sib ///
	using "$TABLES/table_sib_school_outcome_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout  rf_math_2s_sib rf_comm_2s_sib rf_approved_sib rf_approved_next_sib rf_dropout_ever_sib rf_sec_grad_sib ///
	using "$TABLES/table_sib_school_outcomes_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_school_outcomes_`sem'_1_${fam_type}.tex", append write
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
	file open  table_tex	using "$TABLES\table_sib_univ_outcomes_`sem'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger sibling college applications}\label{tab:table_sib_univ_outcomes_`sem'_1_${fam_type}}" _n ///
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
	using "$TABLES/table_sib_univ_outcomes_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout   rf_applied_sib rf_admitted_sib rf_enroll_sib  rf_app_ot_sib rf_N_apps_sib rf_app_sco_m_sib ///
	using "$TABLES/table_sib_univ_outcomes_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_univ_outcomes_`sem'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{7}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex	
		
//Quality of enrollment
	file open  table_tex	using "$TABLES\table_sib_univ_outcomes_`sem'_2_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger quality of enrolled college}\label{tab:table_sib_univ_outcomes_`sem'_2_${fam_type}}" _n ///
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
	using "$TABLES/table_sib_univ_outcomes_`sem'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout   rf_peer_e_m_2s_sib rf_peer_e_c_2s_sib ///
	using "$TABLES/table_sib_univ_outcomes_`sem'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_univ_outcomes_`sem'_2_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{3}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex		
}
*----------------------
*- aspirations and beliefs
*----------------------	
	
if inlist("${t_header}","t_asp") == 1 {	
	file open  table_tex	using "$TABLES\table_sib_asp_outcomes_`sem'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger sibling aspirations and applications}\label{tab:table_sib_asp_outcomes_`sem'_1_${fam_type}}" _n ///
					"\scalebox{1}{\setlength{\textwidth}{.1cm}" _n ///
					"\newcommand{\contents}{" _n ///
					"\begin{tabular}{lcccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					" & \multicolumn{6}{c}{Aspirations}      \\" _n ///
					"\cline{2-4} \cline{5-7}" _n ///
					///"& 2 & 1 & 0.5 & 0.25  \\" _n ///
					" 	& \multicolumn{3}{c}{4th grade}   				& \multicolumn{3}{c}{8th grade}    				\\" _n ///
					" 	& \multicolumn{3}{c}{(parents) }   				& \multicolumn{3}{c}{(students)}    			\\" _n ///
					"	& Complete Sec. & 2+ college  	& Years Ed. 	& 2+ college  	& 4+ College 	& Years Ed. 	\\" _n ///
					"	& (1)  			&  (2) 			&	(3)			& (4) 			& (5)			& (6)			\\" _n ///
					"\bottomrule" _n ///
					"&  &  & & & &  \\" _n 
	file close table_tex

	estout iv_asp_s_4p_sib iv_asp_2_4p_sib iv_asp_y_4p_sib iv_asp_2_2s_sib iv_asp_4_2s_sib iv_asp_y_2s_sib ///
	using "$TABLES/table_sib_asp_outcomes_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout  rf_asp_s_4p_sib rf_asp_2_4p_sib rf_asp_y_4p_sib rf_asp_2_2s_sib rf_asp_4_2s_sib rf_asp_y_2s_sib  ///
	using "$TABLES/table_sib_asp_outcomes_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_asp_outcomes_`sem'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{7}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex	
}		

*----------------------
*- Gender beliefs
*----------------------	
	
if inlist("${t_header}","t_gender") == 1 {	
	file open  table_tex	using "$TABLES\table_sib_asp_outcomes_`sem'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effect on younger sibling aspirations and applications}\label{tab:table_sib_asp_outcomes_`sem'_1_${fam_type}}" _n ///
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

	estout iv_gender_4p_all iv_gender_4p_boys iv_gender_4p_girls ///
	using "$TABLES/table_sib_asp_outcomes_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	estout  rf_gender_4p_all rf_gender_4p_boys rf_gender_4p_girls  ///
	using "$TABLES/table_sib_asp_outcomes_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean bandwidth fstage , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_asp_outcomes_`sem'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{4}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex	
}		
	
*----------------------
*- Heterogeneity by older sibling
*----------------------		

if inlist("${t_header}","t_sib_heterog") == 1 {	
	*- Table 4: Heterogeneity - Likely and unlikely college-goers
	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effects on younger sibling by likelihood of going to college of older sibling}\label{tab:table_sib_heterog_foc_`sem'_1_${fam_type}}" _n ///
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
	using "$TABLES/table_sib_heterog_foc_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib rf_enroll_uni_sib rf_applied_sib rf_admitted_sib rf_enroll_sib  rf_math_2s_sib rf_comm_2s_sib rf_asp_4_2s_sib    ///
	using "$TABLES/table_sib_heterog_foc_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_1_${fam_type}.tex", append write
	file write table_tex ///
						"&  &  &  & & & & & & \\" _n  ///
					"\multicolumn{9}{l}{Panel B: Uncertain college-goers (simple estimate)} \\" _n
	file close table_tex
	
	*- Uncertain college-goers
	estout iv_applied_uni_sib_simpf0 iv_enroll_uni_sib_simpf0 iv_applied_sib_simpf0 iv_admitted_sib_simpf0 iv_enroll_sib_simpf0  iv_math_2s_sib_simpf0 iv_comm_2s_sib_simpf0 iv_asp_4_2s_sib_simpf0   ///
	using "$TABLES/table_sib_heterog_foc_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_simpf0 rf_enroll_uni_sib_simpf0 rf_applied_sib_simpf0 rf_admitted_sib_simpf0 rf_enroll_sib_simpf0  rf_math_2s_sib_simpf0 rf_comm_2s_sib_simpf0 rf_asp_4_2s_sib_simpf0    ///
	using "$TABLES/table_sib_heterog_foc_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_1_${fam_type}.tex", append write
	file write table_tex ///
						"&  &  &  & & & & & & \\" _n  ///
					"\multicolumn{9}{l}{Panel C: Probable college-goers (simple estimate)} \\" _n
	file close table_tex	
	
	*- Probable college-goers
	estout iv_applied_uni_sib_simpf1 iv_enroll_uni_sib_simpf1 iv_applied_sib_simpf1 iv_admitted_sib_simpf1 iv_enroll_sib_simpf1  iv_math_2s_sib_simpf1 iv_comm_2s_sib_simpf1 iv_asp_4_2s_sib_simpf1   ///
	using "$TABLES/table_sib_heterog_foc_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_simpf1 rf_enroll_uni_sib_simpf1 rf_applied_sib_simpf1 rf_admitted_sib_simpf1 rf_enroll_sib_simpf1  rf_math_2s_sib_simpf1 rf_comm_2s_sib_simpf1 rf_asp_4_2s_sib_simpf1    ///
	using "$TABLES/table_sib_heterog_foc_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	
	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{9}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex
	
	**** Continued
	
	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_2_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{(continued) Effects on younger sibling by likelihood of going to college of older sibling}\label{tab:table_sib_heterog_foc_`sem'_2_${fam_type}}" _n ///
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
	using "$TABLES/table_sib_heterog_foc_`sem'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_fullf0 rf_enroll_uni_sib_fullf0 rf_applied_sib_fullf0 rf_admitted_sib_fullf0 rf_enroll_sib_fullf0  rf_math_2s_sib_fullf0 rf_comm_2s_sib_fullf0 rf_asp_4_2s_sib_fullf0    ///
	using "$TABLES/table_sib_heterog_foc_`sem'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_2_${fam_type}.tex", append write
	file write table_tex ///
						"&  &  &  & & & & & & \\" _n  ///
					"\multicolumn{9}{l}{Panel E: Probable college-goers (full estimate)} \\" _n
	file close table_tex	
	
	*- Probable college-goers
	estout iv_applied_uni_sib_fullf1 iv_enroll_uni_sib_fullf1 iv_applied_sib_fullf1 iv_admitted_sib_fullf1 iv_enroll_sib_fullf1  iv_math_2s_sib_fullf1 iv_comm_2s_sib_fullf1 iv_asp_4_2s_sib_fullf1   ///
	using "$TABLES/table_sib_heterog_foc_`sem'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_fullf1 rf_enroll_uni_sib_fullf1 rf_applied_sib_fullf1 rf_admitted_sib_fullf1 rf_enroll_sib_fullf1  rf_math_2s_sib_fullf1 rf_comm_2s_sib_fullf1 rf_asp_4_2s_sib_fullf1    ///
	using "$TABLES/table_sib_heterog_foc_`sem'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	
	file open  table_tex	using "$TABLES\table_sib_heterog_foc_`sem'_2_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{9}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex


*----------------------
*- Heterogeneity by younger sibling
*----------------------		
	
	*- Table 4: Heterogeneity - Likely and unlikely college-goers
	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_1_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Effects on younger sibling by likelihood of going to college of older sibling}\label{tab:table_sib_heterog_sib_`sem'_1_${fam_type}}" _n ///
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
	using "$TABLES/table_sib_heterog_sib_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib rf_enroll_uni_sib rf_applied_sib rf_admitted_sib rf_enroll_sib  rf_math_2s_sib rf_comm_2s_sib rf_asp_4_2s_sib    ///
	using "$TABLES/table_sib_heterog_sib_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_1_${fam_type}.tex", append write
	file write table_tex ///
						"&  &  &  & & & & & & \\" _n  ///
					"\multicolumn{9}{l}{Panel B: Uncertain college-goers (simple estimate)} \\" _n
	file close table_tex
	
	*- Uncertain college-goers
	estout iv_applied_uni_sib_simps0 iv_enroll_uni_sib_simps0 iv_applied_sib_simps0 iv_admitted_sib_simps0 iv_enroll_sib_simps0  iv_math_2s_sib_simps0 iv_comm_2s_sib_simps0 iv_asp_4_2s_sib_simps0   ///
	using "$TABLES/table_sib_heterog_sib_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_simps0 rf_enroll_uni_sib_simps0 rf_applied_sib_simps0 rf_admitted_sib_simps0 rf_enroll_sib_simps0  rf_math_2s_sib_simps0 rf_comm_2s_sib_simps0 rf_asp_4_2s_sib_simps0    ///
	using "$TABLES/table_sib_heterog_sib_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_1_${fam_type}.tex", append write
	file write table_tex ///
						"&  &  &  & & & & & & \\" _n  ///
					"\multicolumn{9}{l}{Panel C: Probable college-goers (simple estimate)} \\" _n
	file close table_tex	
	
	*- Probable college-goers
	estout iv_applied_uni_sib_simps1 iv_enroll_uni_sib_simps1 iv_applied_sib_simps1 iv_admitted_sib_simps1 iv_enroll_sib_simps1  iv_math_2s_sib_simps1 iv_comm_2s_sib_simps1 iv_asp_4_2s_sib_simps1   ///
	using "$TABLES/table_sib_heterog_sib_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_simps1 rf_enroll_uni_sib_simps1 rf_applied_sib_simps1 rf_admitted_sib_simps1 rf_enroll_sib_simps1  rf_math_2s_sib_simps1 rf_comm_2s_sib_simps1 rf_asp_4_2s_sib_simps1    ///
	using "$TABLES/table_sib_heterog_sib_`sem'_1_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)

	
	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_1_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{9}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex
	
	**** Continued
	
	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_2_${fam_type}.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{(continued) Effects on younger sibling by likelihood of going to college of older sibling}\label{tab:table_sib_heterog_sib_`sem'_2_${fam_type}}" _n ///
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
	using "$TABLES/table_sib_heterog_sib_`sem'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_fulls0 rf_enroll_uni_sib_fulls0 rf_applied_sib_fulls0 rf_admitted_sib_fulls0 rf_enroll_sib_fulls0  rf_math_2s_sib_fulls0 rf_comm_2s_sib_fulls0 rf_asp_4_2s_sib_fulls0    ///
	using "$TABLES/table_sib_heterog_sib_`sem'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_2_${fam_type}.tex", append write
	file write table_tex ///
						"&  &  &  & & & & & & \\" _n  ///
					"\multicolumn{9}{l}{Panel E: Probable college-goers (full estimate)} \\" _n
	file close table_tex	
	
	*- Probable college-goers
	estout iv_applied_uni_sib_fulls1 iv_enroll_uni_sib_fulls1 iv_applied_sib_fulls1 iv_admitted_sib_fulls1 iv_enroll_sib_fulls1  iv_math_2s_sib_fulls1 iv_comm_2s_sib_fulls1 iv_asp_4_2s_sib_fulls1   ///
	using "$TABLES/table_sib_heterog_sib_`sem'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(${iv}) varlabels(${iv} "Older sibling enrolled") ///
	mlabels(, none) collabels(, none) note(" ")  label starlevels(* 0.10 ** 0.05 *** 0.01)

	estout  rf_applied_uni_sib_fulls1 rf_enroll_uni_sib_fulls1 rf_applied_sib_fulls1 rf_admitted_sib_fulls1 rf_enroll_sib_fulls1  rf_math_2s_sib_fulls1 rf_comm_2s_sib_fulls1 rf_asp_4_2s_sib_fulls1    ///
	using "$TABLES/table_sib_heterog_sib_`sem'_2_${fam_type}.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) varlabels(ABOVE "Older sibling above cutoff") ///
	stats(blank_line N ymean /*bandwidth fstage*/ , fmt(%9.0fc %9.0fc %9.3f /*%9.3f %9.0fc*/) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	
	file open  table_tex	using "$TABLES\table_sib_heterog_sib_`sem'_2_${fam_type}.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule \multicolumn{9}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
	"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
	file close table_tex
}	
	
	
//table_sib_choices_1_2
//table_sib_school_outcomes_1_2
//table_sib_heterog_1_2	
	
end




***** Run program

main


