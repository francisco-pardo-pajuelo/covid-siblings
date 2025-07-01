*- Sibling-application database


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

