open
	*- Label dummy variables
	foreach v of var applied_sib applied_public* applied_private* applied_uni* applied_major* applied_stem* {
	label values `v' yes_no
	}
	
	
preserve

	merge m:1 id_per_umc codigo_modular using "$TEMP\application_info_university_students",  keepusing(score_std_major_uni_avg score_std_department_uni_avg score_std_major_uni_o_avg score_std_department_uni_o_avg score_std_major_pub_o_avg score_std_department_pub_o_avg) keep(master match)  
	rename (score_std_major_uni_avg score_std_department_uni_avg score_std_major_uni_o_avg score_std_department_uni_o_avg score_std_major_pub_o_avg score_std_department_pub_o_avg) (score_std_major_uni_sib score_std_department_uni_sib score_std_major_uni_o_sib score_std_department_uni_o_sib score_std_major_pub_o_sib score_std_department_pub_o_sib) //No included in focal
	//bys id_per_umc (id_fam_2): replace id_fam_2 = id_fam_2[1]
	//clonevar id_fam_2_aux = id_fam_2
	keep if id_fam_2 == 2113755
	
	
	
	
	bys aux_id_per_umc codigo_modular (semester_foc): keep if semester_foc==semester_foc[1]
	//bys aux_id_per_umc codigo_modular (semester_foc):  gen a=semester_foc[1]
	sort aux_fam_order_2 aux_id_per_umc id_per_umc semester_foc
	
	list public_foc aux_fam_order_2 aux_id_per_umc id_per_umc semester_foc codigo_modular applied_sib score_raw score_std_major score_std_major_uni_sib score_std_major_uni_o_sib score_std_major_pub_o_sib  _m admitted , sepby(aux_id_per_umc)

restore

/*

  1. |   288841 |
  2. |   431710 |
  3. |   708213 |
  4. |  1619249 |
  5. |  1787237 |
     |----------|
  6. |  1846208 |
  7. |  1912058 | Why is there no score for the sibling in others?
  8. |  2113755 |
  9. |  2197602 |
 10. |  2220750 |

*/



	use "$TEMP\applied", clear

	br codigo_modular semester score_raw score_std_major if id_per_umc == "4436995"


	*- # of applications
	merge m:1 id_per_umc using "$TEMP\application_info_students", keepusing(N_applications) keep(master match)  	
	replace N_applications = 0 if applied_sib == 0 
	rename (N_applications) (N_applications_sib) //No included in focal
	drop _m
	
	*- Exam averages on first take (Average of all universities)
	merge m:1 id_per_umc using "$TEMP\application_info_students", keepusing(score_std_major_avg score_std_department_avg) keep(master match)  	
	rename (score_std_major_avg score_std_department_avg) (score_std_major_avg_sib score_std_department_avg_sib) //No included in focal
	drop _m
	
	*- Exam average on first take (Average of all takes in focal child university)
	merge m:1 id_per_umc codigo_modular using "$TEMP\application_info_university_students",  keepusing(score_std_major_uni_avg score_std_department_uni_avg) keep(master match)  	
	rename (score_std_major_uni_avg score_std_department_uni_avg) (score_std_major_uni_avg_sib score_std_department_uni_avg_sib) //No included in focal
	drop _m
	//###