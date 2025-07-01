
rdrobust std_gpa_m_pre2_sib score_relative if ${if_pre}, ///
	  c(0) ///
	  p(1) ///
	  q(2) ///
	  kernel(triangular) ///
	  bwselect(mserd) ///
	  vce(cluster id_fam_${fam_type}) ///
	  all ///
	  covs(semester_foc_*) //  covs(year_applied_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
	  
	  

rdrobust std_gpa_m_pre2_sib score_relative if ${if_pre}, ///
	  c(0) ///
	  p(1) ///
	  q(2) ///
	  kernel(triangular) ///
	  bwselect(mserd) ///
	  vce(cluster id_fam_${fam_type}) ///
	  all ///
	  covs(year_applied_foc_*) //  covs(year_applied_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
	  	  
rdrobust std_gpa_m_pre2_sib score_relative if ${if_pre}, ///
	  c(0) ///
	  p(1) ///
	  q(2) ///
	  kernel(uniform) ///
	  bwselect(mserd) ///
	  vce(cluster id_fam_${fam_type}) ///
	  all ///
	  covs(year_applied_foc_*) //  covs(year_applied_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
	  	  
		  		  
estimate_reg /*OUTCOME*/ std_gpa_m_pre2_sib 	/*IV*/ none /*label*/ std_gpa_m_pre2_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ cm+y
		  
global if_4p = "fam_order_2 == 1 & year_4p_sib>=year_applied_foc & first_application_sem==1 & year_4p_sib!=."
global if_2s = "fam_order_2 == 1 & year_2s_sib>=year_applied_foc & first_application_sem==1 & year_2s_sib!=."		  
		  
  
reghdfe  asp_college2_4p_sib ABOVE ABOVE_score_relative_1 score_relative_1 if ${if_4p}	& abs(score_relative)<1, a(id_cutoff) cl(id_fam_${fam_type})		  
reghdfe  asp_college4_4p_sib ABOVE ABOVE_score_relative_1 score_relative_1 if ${if_4p}	& abs(score_relative)<1, a(id_cutoff) cl(id_fam_${fam_type})		  
reghdfe  asp_college2_2s_sib ABOVE ABOVE_score_relative_1 score_relative_1 if ${if_2s}	& abs(score_relative)<1, a(id_cutoff) cl(id_fam_${fam_type})		  
reghdfe  asp_college4_2s_sib ABOVE ABOVE_score_relative_1 score_relative_1 if ${if_2s}	& abs(score_relative)<1, a(id_cutoff) cl(id_fam_${fam_type})		  
		 
		 
replace asp_college2_2s_sib=1 if asp_college4_2s_sib==1


estimate_reg /*OUTCOME*/ std_gpa_m_pre1_sib 	/*IV*/ none /*label*/ std_gpa_m_pre2_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ cm+y
estimate_reg /*OUTCOME*/ std_pred_gpa_m_ie_y_pre1_sib 	/*IV*/ none /*label*/ pred   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ cm+y

estimate_reg /*OUTCOME*/ score_math_std_2s_sib 	/*IV*/ none /*label*/ score_math_std_2s_sib   	/*stack*/ ${main_stack} /*sibling*/ ${main_sibling_sample} /*relative to application*/ ${main_rel_app} /*semesters*/ ${main_term} /*bw*/ ${main_bw} /*covs RD rob*/ ${main_covs_rdrob} /*FE*/ cm+y

rdrobust std_gpa_m_pre2_sib score_relative if ${if_pre}, ///
	  c(0) ///
	  p(1) ///
	  q(2) ///
	  kernel(triangular) ///
	  bwselect(mserd) ///
	  vce(cluster id_fam_${fam_type}) ///
	  all ///
	  covs(semester_foc_*) 