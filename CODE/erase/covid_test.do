
	use id_per_umc base_math_std_2p score_math_std_2s year_t_?? year grade treated id_ie fam_order_${fam_type} if grade==8 using "$TEMP\pre_reg_covid", clear
	

	reghdfe 	score_math_std_2s 			 year_t_b5 		year_t_b4  			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3  treated, a(year id_ie)
	estimates store test_2s_1
	reghdfe 	score_math_std_2s 			 year_t_b5 		year_t_b4  			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3  treated base_math_std_2p, a(year id_ie)
	gen sample_2s_2p = e(sample)
	estimates store test_2s_2
reghdfe 	score_math_std_2s 			 year_t_b5 		year_t_b4  			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3  treated if sample_2s_2p==1, a(year id_ie)
	estimates store test_2s_3

coefplot 	test_2s_1 test_2s_2 test_2s_3, ///
			omitted ///
			keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
			drop(year_t_b3) ///
			leg(order(1 "STD Math (1)" 3 "STD Math (2)" 5 "STD Math (3)")) ///
			coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023") ///
			yline(0,  lcolor(gs10))  ///
			ytitle("Effect") ///
			subtitle("Panel A: Standardized Exams - 2th Grade") ///
			legend(pos(6) col(3)) ///
			name(test,replace)		
	
	

	
	
	merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(`v'_*) nogen
	reghdfe 	`v' 	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated, a(id_ie)
	*reghdfe 	score_acad_std_2p	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated if score_acad_std_2p_max==2022 & score_acad_std_2p_sum==5 & fam_order_2==1, a(id_ie)
	estimates 	store `v'
	}

*- ECE - 4P
foreach v in "score_math_std_4p" "score_com_std_4p" "score_acad_std_4p" {
	di "`v'"
	use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} if grade==4 using "$TEMP\pre_reg_covid", clear
	merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(`v'_*) nogen
	reghdfe 	`v' 							year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3  treated, a(year id_ie)
	estimates 	store `v'		
	}	

*- ECE - 2S
foreach v in "score_math_std_2s" "score_com_std_2s" "score_acad_std_2s" {
	di "`v'"
	use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} if grade==8 using "$TEMP\pre_reg_covid", clear
	merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(`v'_*) nogen
	reghdfe 	`v' 			 year_t_b5 		year_t_b4  			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3  treated, a(year id_ie)
	estimates 	store `v'		
	}