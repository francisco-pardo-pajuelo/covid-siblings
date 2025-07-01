
preserve
	drop if codigo_modular<160000010
	estimate_reg /*OUTCOME*/ std_gpa_m_pre2_sib 	/*IV*/ none /*label*/ std_gpa_m_pre2_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ cm+y

restore
gen sample_cm = 1 if e(sample)==1


estimate_reg /*OUTCOME*/ std_gpa_m_pre2_sib 	/*IV*/ none /*label*/ std_gpa_m_pre2_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ cmy

gen sample_cmy = 1 if e(sample)==1


histogram score_relative if sample_cmy==1, bins(100)
//seems ok

tab id_cutoff  if sample_cmy==1 //How can there be 1 obs cutoffs

bys id_cutoff: egen N2 = sum(cond(sample_cmy==1,1,0)) if sample_cmy==1

estimate_reg /*OUTCOME*/ std_gpa_m_pre2_sib 	/*IV*/ none /*label*/ std_gpa_m_pre2_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ cmy


reghdfe std_gpa_m_pre2_sib ABOVE score_relative_1 ABOVE_score_relative_1 if abs(score_relative)<0.5 & fam_order_2 == 1 &  first_application_sem==1, a(id_cutoff)


gen has_gpa_pre2_sib = (std_gpa_m_pre2_sib!=.)

estimate_reg /*OUTCOME*/ has_gpa_pre2_sib 	/*IV*/ none /*label*/ has_gpa_pre2_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ cmy

estimate_reg /*OUTCOME*/ std_gpa_m_next1_sib 	/*IV*/ none /*label*/ std_gpa_m_next1_sib   /*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ cm+y

tab FE_cm, gen(FE_cm_)

tab codigo_modular, gen(college_)

rdrobust std_gpa_m_pre2_sib score_relative if ${if_pre}, ///
	  c(0) ///
	  p(1) ///
	  q(2) ///
	  kernel(triangular) ///
	  bwselect(mserd) ///
	  vce(cluster id_fam_${fam_type}) ///
	  all ///
	  covs(semester_foc_*) //  covs(year_applied_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
	  

rdrobust std_gpa_m_pre1_sib score_relative if ${if_pre}, ///
	  c(0) ///
	  p(1) ///
	  q(2) ///
	  kernel(triangular) ///
	  bwselect(mserd) ///
	  vce(cluster id_fam_${fam_type}) ///
	  all ///
	  covs(semester_foc_*)
	  
binsreg  std_gpa_m_pre1_sib score_relative semester_foc_*	if ${if_pre}  , nbins(100)
	  
	  
rdrobust std_gpa_m_next1_sib score_relative if ${if_pre}, ///
	  c(0) ///
	  p(1) ///
	  q(2) ///
	  kernel(triangular) ///
	  bwselect(mserd) ///
	  vce(cluster id_fam_${fam_type}) ///
	  all ///
	  covs(semester_foc_*) //  covs(year_applied_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
	  	  
	  
	  global bw_${outcome} = e(h_l)
	  
	  
reghdfe ${outcome} ABOVE ABOVE_score_relative_1 score_relative_1 if ${if_pre}	& abs(score_relative)<${bw_${outcome}}, a(semester_foc) cl(id_fam_${fam_type})