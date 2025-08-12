*- Only child and siblings in COVID

capture program drop main 
program define main 

	setup_COVID_A04
	
	

	
	event_ece_student
	event_ece_school
	ece_baseline_netherlands   //??
	
	//Pairs of ECE years with pre-post COVID
	//twfe_survey	
	twfe_ece
	twfe_ece_baseline_scores
	twfe_ece_baseline_survey
	
	

	
end

********************************************************************************
* Setup
********************************************************************************

capture program drop setup_COVID_A04
program define setup_COVID_A04

	*- Define if test run
	global covid_test = 0
	global covid_data = ""
	if ${covid_test} == 1 global covid_data = "_TEST"
	
	*- Only analyze specific outcomes
	global main_outcomes=1
	global main_outcome_1 = "std_gpa_m_adj"
	global main_outcome_2 = "" //pass_math
	global main_outcome_3 = "higher_ed_parent" //higher_ed_parent
	
	global main_loop = 0
	global main_loop_level	= "all"
	global main_loop_only_covid = "all"

	*- Global variables
	global fam_type=2
	global max_sibs = 4
	global x_all = "male_siagie urban_siagie public_siagie"
	global x_nohigher_ed = "male_siagie urban_siagie public_siagie"
	
	
	*- Colorpalette
	colorpalette  HCL blues, selec(1 5 9 11) nograph
	return list

	global blue_1 = "`r(p1)'"
	global blue_2 = "`r(p2)'"
	global blue_3 = "`r(p3)'"
	global blue_4 = "`r(p4)'"
	global blue_5 = "`r(p5)'"
	//local blue_6 = "`r(p6)'"

	//colorpalette  HCL reds, selec(1 4 6 8 10 12) nograph
	colorpalette  HCL reds, selec(2 5 9 11) nograph
	return list

	global red_1 = "`r(p1)'"
	global red_2 = "`r(p2)'"
	global red_3 = "`r(p3)'"	
	global red_4 = "`r(p4)'"
	
	colorpalette  HCL greens, selec(2 5 9 11) nograph
	return list

	global green_1 = "`r(p1)'"
	global green_2 = "`r(p2)'"
	global green_3 = "`r(p3)'"		
	global green_4 = "`r(p4)'"
	
	//Ellsworth Kelly - Blue Green Red - https://www.metmuseum.org/art/collection/search/489307
	global ek_blue 	"21 53 162"
	global ek_green "19 151 65"
	global ek_red	"221 63 15"
	
end


********************************************************************************
* Event Study - ECE
********************************************************************************

capture program drop event_ece_student
program define event_ece_student	

	global x = "$x_all"

	*---------
	*- ECE - Student level
	*---------
	*- ECE - 2P
	foreach v in "score_math_2p" "score_com_2p" "score_math_std_2p" "score_com_std_2p" "score_acad_std_2p" "satisf_m_2p" "satisf_c_2p" {
		di "`v'"
		if inlist("`v'","score_math_2p","score_math_std_2p","satisf_m_2p")==1 	local subj = "math"
		if inlist("`v'","score_com_2p","score_com_std_2p","satisf_c_2p")==1 	local subj = "com"
		if inlist("`v'","score_acad_std_2p")==1 				local subj = "acad"
		use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} if grade==2 using "$TEMP\pre_reg_covid${covid_data}", clear
		keep if inlist(year,2015,2016,2018,2019,2022,2023)==1
		merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_2p_*) nogen
		if inlist("`v'","score_math_2p","score_com_2p")==1 replace `v' = (`v'-500)/100 //standardize to reference year mean 0 and sd 1
		reghdfe 	`v' ${x}	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated, a(id_ie)
		*reghdfe 	score_acad_std_2p	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated if score_acad_std_2p_max==2022 & score_acad_std_2p_sum==5 & fam_order_2==1, a(id_ie)
		estimates 	store `v'
		}

	*- ECE - 4P
	foreach v in "score_math_4p" "score_com_4p" "score_math_std_4p" "score_com_std_4p" "score_acad_std_4p" "satisf_m_4p" "satisf_c_4p" {
		di "`v'"
		if inlist("`v'","score_math_4p","score_math_std_4p","satisf_m_4p")==1 	local subj = "math"
		if inlist("`v'","score_com_4p","score_com_std_4p","satisf_c_4p")==1 	local subj = "com"
		if inlist("`v'","score_acad_std_4p")==1 				local subj = "acad"
		use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} if grade==4 using "$TEMP\pre_reg_covid${covid_data}", clear
		keep if inlist(year,2016,2018,2019,2022,2023,2024)==1
		merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_4p_*) nogen
		if inlist("`v'","score_math_4p","score_com_4p")==1 replace `v' = (`v'-500)/100 //standardize to reference year mean 0 and sd 1
		reghdfe 	`v' 	${x}						year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 year_t_a4  treated, a(year id_ie)
		estimates 	store `v'		
		}	

	*- ECE - 2S
	foreach v in "score_math_2s" "score_com_2s" "score_math_std_2s" "score_com_std_2s" "score_acad_std_2s" "satisf_m_2s" "satisf_c_2s" {
		di "`v'"
		if inlist("`v'","score_math_2s","score_math_std_2s","satisf_m_2s")==1 	local subj = "math"
		if inlist("`v'","score_com_2s","score_com_std_2s","satisf_c_2s")==1 	local subj = "com"
		if inlist("`v'","score_acad_std_2s")==1 				local subj = "acad"
		use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} if grade==8 using "$TEMP\pre_reg_covid${covid_data}", clear
		merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_2s_*) nogen
		if inlist("`v'","score_math_2s","score_com_2s")==1 replace `v' = (`v'-500)/100 //standardize to reference year mean 0 and sd 1
		keep if inlist(year,2015,2016,2018,2019,2022,2023)==1
		reghdfe 	`v' ${x}			 year_t_b5 		year_t_b4  			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3  treated, a(year id_ie)
		estimates 	store `v'		
		}	
		
	foreach g in "2p" "4p" "2s" {
		if "`g'" == "2p" local g_label = "2nd Grade"
		if "`g'" == "4p" local g_label = "4th Grade"
		if "`g'" == "2s" local g_label = "8th Grade"

		coefplot 	score_math_`g' score_com_`g', ///
					omitted ///
					keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
					drop(year_t_b3) ///
					leg(order(1 "Mathematics" 3 "Reading")) ///
					coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
					yline(0,  lcolor(gs6))  ///
					ytitle("Effect") ///
					subtitle("Panel A: Standardized Exams - `g_label'") ///
					legend(pos(6) col(3)) ///
					name(panel_A_SATISF_`g',replace)	
		//graph save "$FIGURES\covid_ece_`g'.gph" , replace	
		//capture qui graph export "$FIGURES\covid_ece_`g'.eps", replace	
		capture qui graph export "$FIGURES\Event Study\ece_student_score_`g'${covid_data}.png", replace			
		capture qui graph export "$FIGURES\Event Study\ece_student_score_`g'${covid_data}.pdf", replace		
	}	

	foreach g in "2p" "4p" "2s" {
		if "`g'" == "2p" local g_label = "2nd Grade"
		if "`g'" == "4p" local g_label = "4th Grade"
		if "`g'" == "2s" local g_label = "8th Grade"

		coefplot 	score_math_std_`g' score_com_std_`g' score_acad_std_`g', ///
					omitted ///
					keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
					drop(year_t_b3) ///
					leg(order(1 "Mathematics" 3 "Reading" 5 "Average")) ///
					coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
					yline(0,  lcolor(gs6))  ///
					ytitle("Effect (SD)") ///
					subtitle("Panel A: Standardized Exams - `g_label'") ///
					legend(pos(6) col(3)) ///
					name(panel_A_STD_`g',replace)	
		//graph save "$FIGURES\covid_ece_`g'.gph" , replace	
		//capture qui graph export "$FIGURES\covid_ece_`g'.eps", replace	
		capture qui graph export "$FIGURES\Event Study\ece_student_std_score`g'${covid_data}.png", replace			
		capture qui graph export "$FIGURES\Event Study\ece_student_std_score`g'${covid_data}.pdf", replace		
	}

	foreach g in "2p" "4p" "2s" {
		if "`g'" == "2p" local g_label = "2nd Grade"
		if "`g'" == "4p" local g_label = "4th Grade"
		if "`g'" == "2s" local g_label = "8th Grade"

		coefplot 	satisf_m_`g' satisf_c_`g', ///
					omitted ///
					keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
					drop(year_t_b3) ///
					leg(order(1 "Mathematics" 3 "Reading")) ///
					coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
					yline(0,  lcolor(gs6))  ///
					ytitle("Effect") ///
					subtitle("Panel A: Satisfactory Level - `g_label'") ///
					legend(pos(6) col(3)) ///
					name(panel_A_SATISF_`g',replace)	
		//graph save "$FIGURES\covid_ece_`g'.gph" , replace	
		//capture qui graph export "$FIGURES\covid_ece_`g'.eps", replace	
		capture qui graph export "$FIGURES\Event Study\ece_student_satisf_`g'${covid_data}.png", replace			
		capture qui graph export "$FIGURES\Event Study\ece_student_satisf_`g'${covid_data}.pdf", replace		
	}	

end	


capture program drop event_ece_school
program define event_ece_school	

	
	global x = "$x_all"

	*---------
	*- ECE - Student level
	*---------
	
	foreach weight in "" "_weighted" {
	estimates clear	
		*- ECE - 2P
		foreach v in "score_math_2p" "score_com_2p" "score_math_std_2p" "score_com_std_2p" "score_acad_std_2p" "satisf_m_2p" "satisf_c_2p" {
			di "`v'"
			if inlist("`v'","score_math_2p","score_math_std_2p","satisf_m_2p")==1 	local subj = "math"
			if inlist("`v'","score_com_2p","score_com_std_2p","satisf_c_2p")==1 	local subj = "com"
			if inlist("`v'","score_acad_std_2p")==1 				local subj = "acad"
			use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} peso_?_2p if grade==2 using "$TEMP\pre_reg_covid${covid_data}", clear
			
			keep if inlist(year,2015,2016,2018,2019,2022,2023)==1
			//merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_2p_*) nogen
			if inlist("`v'","score_math_2p","score_com_2p")==1 replace `v' = (`v'-500)/100 //standardize to reference year mean 0 and sd 1
			gen pop = 1
			collapse (sum) pop (mean) `v' [iw=peso_m_2p], by(id_ie year_?_?? year treated) 
			if "`weight'" == "" 		reghdfe 	`v' /*${x}*/	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated, a(id_ie)
			if "`weight'" == "_weighted" 	reghdfe 	`v' /*${x}*/	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated [aw=pop], a(id_ie)
			estimates 	store `v'
			}

		*- ECE - 4P
		foreach v in "score_math_4p" "score_com_4p" "score_math_std_4p" "score_com_std_4p" "score_acad_std_4p" "satisf_m_4p" "satisf_c_4p" {
			di "`v'"
			if inlist("`v'","score_math_4p","score_math_std_4p","satisf_m_4p")==1 	local subj = "math"
			if inlist("`v'","score_com_4p","score_com_std_4p","satisf_c_4p")==1 	local subj = "com"
			if inlist("`v'","score_acad_std_4p")==1 				local subj = "acad"
			use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} peso_?_4p if grade==4 using "$TEMP\pre_reg_covid${covid_data}", clear
			
			keep if inlist(year,2016,2018,2019,2022,2023,2024)==1
			//merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_4p_*) nogen
			if inlist("`v'","score_math_4p","score_com_4p")==1 replace `v' = (`v'-500)/100 //standardize to reference year mean 0 and sd 1
			gen pop = 1
			collapse (sum) pop (mean) `v' [iw=peso_m_4p], by(id_ie year_?_?? year treated) 
			if "`weight'" == "" 		reghdfe 	`v' /*${x}*/	 		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 year_t_a4 i.year treated, a(id_ie)
			if "`weight'" == "_weighted" 	reghdfe 	`v' /*${x}*/	 		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 year_t_a4 i.year treated [aw=pop], a(id_ie)		
			estimates 	store `v'		
			}	

		*- ECE - 2S
		foreach v in "score_math_2s" "score_com_2s" "score_math_std_2s" "score_com_std_2s" "score_acad_std_2s" "satisf_m_2s" "satisf_c_2s" {
			di "`v'"
			if inlist("`v'","score_math_2s","score_math_std_2s","satisf_m_2s")==1 	local subj = "math"
			if inlist("`v'","score_com_2s","score_com_std_2s","satisf_c_2s")==1 	local subj = "com"
			if inlist("`v'","score_acad_std_2s")==1 				local subj = "acad"
			use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} peso_?_2s if grade==8 using "$TEMP\pre_reg_covid${covid_data}", clear
			
			keep if inlist(year,2015,2016,2018,2019,2022,2023)==1
			//merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_2s_*) nogen
			if inlist("`v'","score_math_2s","score_com_2s")==1 replace `v' = (`v'-500)/100 //standardize to reference year mean 0 and sd 1
			gen pop = 1
			collapse (sum) pop (mean) `v' [iw=peso_m_2s], by(id_ie year_?_?? year treated) 
			if "`weight'" == "" 		reghdfe 	`v' /*${x}*/	 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated, a(id_ie)
			if "`weight'" == "_weighted" 	reghdfe 	`v' /*${x}*/	 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated [aw=pop], a(id_ie)					
			estimates 	store `v'
			}	
			
		foreach g in "2p" "4p" "2s" {
			if "`g'" == "2p" local g_label = "2nd Grade"
			if "`g'" == "4p" local g_label = "4th Grade"
			if "`g'" == "2s" local g_label = "8th Grade"

			coefplot 	score_math_`g' score_com_`g', ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						drop(year_t_b3) ///
						leg(order(1 "Mathematics" 3 "Reading")) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
						yline(0,  lcolor(gs6))  ///
						ytitle("Effect") ///
						subtitle("Panel A: Standardized Exams - `g_label'") ///
						legend(pos(6) col(3)) ///
						name(panel_A_SATISF_`g',replace)	
			//graph save "$FIGURES\covid_ece_`g'.gph" , replace	
			//capture qui graph export "$FIGURES\covid_ece_`g'.eps", replace	
			capture qui graph export "$FIGURES\Event Study\ece_school`weight'_score_`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Event Study\ece_school`weight'_score_`g'${covid_data}.pdf", replace		
		}	

		foreach g in "2p" "4p" "2s" {
			if "`g'" == "2p" local g_label = "2nd Grade"
			if "`g'" == "4p" local g_label = "4th Grade"
			if "`g'" == "2s" local g_label = "8th Grade"

			coefplot 	score_math_std_`g' score_com_std_`g' score_acad_std_`g', ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						drop(year_t_b3) ///
						leg(order(1 "Mathematics" 3 "Reading" 5 "Average")) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
						yline(0,  lcolor(gs6))  ///
						ytitle("Effect (SD)") ///
						subtitle("Panel A: Standardized Exams - `g_label'") ///
						legend(pos(6) col(3)) ///
						name(panel_A_STD_`g',replace)	
			//graph save "$FIGURES\covid_ece_`g'.gph" , replace	
			//capture qui graph export "$FIGURES\covid_ece_`g'.eps", replace	
			capture qui graph export "$FIGURES\Event Study\ece_school`weight'_std_score_`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Event Study\ece_school`weight'_std_score_`g'${covid_data}.pdf", replace		
		}

		foreach g in "2p" "4p" "2s" {
			if "`g'" == "2p" local g_label = "2nd Grade"
			if "`g'" == "4p" local g_label = "4th Grade"
			if "`g'" == "2s" local g_label = "8th Grade"

			coefplot 	satisf_m_`g' satisf_c_`g', ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						drop(year_t_b3) ///
						leg(order(1 "Mathematics" 3 "Reading")) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023" year_t_a4 = "2024") ///
						yline(0,  lcolor(gs6))  ///
						ytitle("Effect") ///
						subtitle("Panel A: Satisfactory Level - `g_label'") ///
						legend(pos(6) col(3)) ///
						name(panel_A_SATISF_`g',replace)	
			//graph save "$FIGURES\covid_ece_`g'.gph" , replace	
			//capture qui graph export "$FIGURES\covid_ece_`g'.eps", replace	
			capture qui graph export "$FIGURES\Event Study\ece_school`weight'_satisf_`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Event Study\ece_school`weight'_satisf_`g'${covid_data}.pdf", replace		
		}	
	}
end	


********************************************************************************
* TWFE - GPA
********************************************************************************

capture program drop ece_baseline_netherlands
program define ece_baseline_netherlands 

	use "$TEMP\pre_reg_covid${covid_data}", clear
	
	/*
	keep if grade==2 | grade==8
	keep if score_math_2p!=. | score_math_2s!=.
	bys id_per_umc: egen has_2p = max(cond(score_math_2p!=.,1,0))
	bys id_per_umc: egen has_2s = max(cond(score_math_2s!=.,1,0))
	keep if has_2p == 1 & has_2s==1
	keep if 
		*/

	
	keep score_com_std score_math_std score_acad_std satisf_m satisf_c init_m init_c socioec_index socioec_index_cat id_per_umc id_ie year source educ_caretaker educ_mother educ_father grade fam_total_${fam_type}
	reshape wide score_com_std score_math_std score_acad_std satisf_m satisf_c init_m init_c socioec_index socioec_index_cat year id_ie source ,i(id_per_umc educ_caretaker educ_mother educ_father fam_total_${fam_type}) j(grade)
	
	tab fam_total_${fam_type}
	keep if fam_total_${fam_type}<=4
	
	gen sibs = inlist(fam_total_${fam_type},2,3,4) == 1 
	
	local g0 = 2
	local g1 = 8
	reghdfe score_com_std`g1' i.fam_total_${fam_type} score_com_std`g0' i.year`g0' i.educ_mother i.educ_father if year`g1'<=2019, a(id_ie`g0')
	reghdfe score_com_std`g1' i.fam_total_${fam_type} score_com_std`g0' i.year`g0' i.educ_mother i.educ_father if year`g1'>=2020, a(id_ie`g0')	
	
	local g0 = 4
	local g1 = 8
	reghdfe score_com_std`g1' i.fam_total_${fam_type} score_com_std`g0' i.year`g0' i.educ_mother i.educ_father if year`g1'<=2019, a(id_ie`g0')
	reghdfe score_com_std`g1' i.fam_total_${fam_type} score_com_std`g0' i.year`g0' i.educ_mother i.educ_father if year`g1'>=2020, a(id_ie`g0')	
	
	
	local g0 = 2
	local g1 = 8
	gen post = year`g1'>=2020 if year`g1'!=.
	reg score_com_std`g1' score_com_std`g0' i.post
	reg score_math_std`g1' score_math_std`g0' i.post
	reg score_com_std`g1' score_com_std`g0' i.post##i.sibs
	reg score_math_std`g1' score_math_std`g0' i.post##i.sibs
	capture drop post

/*
	local g0 = 2
	local g1 = 4
	gen post = year`g1'>=2020 if year`g1'!=.
	reg score_com_std`g1' score_com_std`g0' i.post##i.sibs
	capture drop post	
	
	
	local g0 = 4
	local g1 = 8
	gen post = year`g1'>=2020 if year`g1'!=.
	reg score_com_std`g1' score_com_std`g0' i.post##i.sibs
	capture drop post	
*/	
	//gen score_com_std = score_com_std`g1' - score_com_std`g0' 
	
	//reg score_com_std i.post##i.fam_total_${fam_type}, vce(cluster id_ie`g1')
	//reg score_com_std i.post##i.sibs, vce(cluster id_ie`g1')
	
	capture drop post score_
	
	reghdfe 	
	
	
	
	gen pop = 1 
	
	reghdfe satisf_m i.fam_total_${fam_type} i.year i.educ_mother i.educ_father if grade==2, a(id_ie)
	reghdfe satisf_m i.fam_total_${fam_type} i.year i.educ_mother i.educ_father if grade==4, a(id_ie)
	reghdfe satisf_m i.fam_total_${fam_type} i.year i.educ_mother i.educ_father if grade==8, a(id_ie)

	/
	collapse (mean) score_*_std satisf* init* socioec_index (sum) pop, by(grade year fam_total_${fam_type})
	
	
	graph bar satisf_m if grade==2, ///
		by(year) over(fam_total_${fam_type}) ///
		legend(order(1 "${g1l} grade (Pre covid)" 2 "${g2l} grade (Post covid)") pos(6) col(2))

end	



***********************************************

capture program drop twfe_survey
program define twfe_survey
		
	
	clear

	*- TWFE Estimates

	foreach level in "all" /*"elm" "sec"*/ {
		foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj"  "pass_math" "pass_read" /*"approved" "approved_first"*/ {
			
			estimates clear
			global x = "$x_all"
			if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"	
			

			use `v' pass_math pass_read approved approved_first id_per_umc year_t_?? public_siagie urban_siagie male_siagie educ_cat_mother higher_ed_parent lives_with_mother lives_with_father *has_internet *has_comp *low_ses *quiet_room year grade treated post treated_post id_ie fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid${covid_data}", clear
			
			*- Remove early grades and years
			keep if year>=2016
			drop if grade==0
			
			
			*- Divide sample based on grade in 2020
			//bys id_per_umc: egen grade_2020	= min(cond(year==2020,grade,.))
			
			*- Divide sample based on expected cohort
			bys id_per_umc: egen min_year 		= min(year)
			bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
			gen proxy_1st = min_year - grade_min_year  + 1
							
			
			/*
			*- Not enough pre-years
						
			drop if inlist(grade_2020,1,2)==1
			drop if grade_2020==3 & year<=2017 //<=2017 Would only include those who repeated..
			drop if grade_2020==4 & year<=2016 //<=2016 Would only include those who repeated..
			keep if proxy_1st <= 2018
			*/
			
			
			/*
			if "`area'" == "rur" keep if urban_siagie == 0
			if "`area'" == "urb" keep if urban_siagie == 1

			if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
			if "`hed_parent'" == "yes" 	keep if higher_ed_parent == 1
			*/
			
			if "`level'" == "all" {
				keep if grade>=1 & grade<=11
				//gen young = inlist(grade_2020,3,4,5,6)==1 if inlist(grade_2020,3,4,5,6,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2015,2016,2017,2018) if inlist(proxy_1st,2011,2012,2013,2014,2015,2016,2017,2018)==1
				gen young = inlist(grade,1,2,3,4,5,6)==1 if inlist(grade,1,2,3,4,5,6,7,8,9,10,11)
				local young_lab = "Primary" //Primary in 2020
				local old_lab 	= "Secondary"
				}
			if "`level'" == "elm" {
				keep if grade>=1 & grade<=6
				//gen young = inlist(grade_2020,3,4)==1 if inlist(grade_2020,3,4,5,6)
				//gen young = inlist(proxy_1st,2017,2018) if inlist(proxy_1st,2015,2016)==1
				//local young_lab = "2017-2018 cohort" //3rd-4th grade in 2020
				//local old_lab 	= "2015-2016 cohort" //5th-6th grade in 2020
				gen young = inlist(grade,1,2,3)==1 if inlist(grade,1,2,3,4,5,6)
				local young_lab = "1st-3rd grade"
				local old_lab 	= "4th-6th grade"
				}
			if "`level'" == "sec" {
				keep if grade>=7	
				//gen young = inlist(grade_2020,7,8)==1 if inlist(grade_2020,7,8,9,10,11)
				//gen young = inlist(proxy_1st,2014,2013) if inlist(proxy_1st,2011,2012)==1
				//local young_lab = "2014-2013 cohort" //7th-8th grade in 2020
				//local old_lab 	= "2011-2012 cohort" //9th-11th grade in 2020
				gen young = inlist(grade,7,8)==1 if inlist(grade,7,8,9,10,11)
				local young_lab = "7th-8th grade"
				local old_lab 	= "9th-11th grade"
				}


				local vlab 		= "-999-" //to reset value and make sure we are assigning one. This because I had an issue by looping through new outcoms without adding the vlab and replacing wrong files.
				local xtitle 	= "-999-" //to reset value and make sure we are assigning one. This because I had an issue by looping through new outcoms without adding the vlab and replacing wrong files.
				if "`v'" == "std_gpa_m" 		{
					local vlab = "gpa_m"
					local xtitle = "Standardized Mathematics GPA"
					}
				if "`v'" == "std_gpa_c" 		{
					local vlab = "gpa_c"
					local xtitle = "Standardized Reading GPA"
					}
				if "`v'" == "std_gpa_m_adj" 		{
					local vlab = "gpa_m_adj"
					local xtitle = "Standardized Mathematics GPA"
					}
				if "`v'" == "std_gpa_c_adj" 		{
					local vlab = "gpa_c_adj"
					local xtitle = "Standardized Reading GPA"
					}
				if "`v'" == "pass_math" 		{
					local vlab = "pass_m"
					local xtitle = "% A's Mathematics"
					}
				if "`v'" == "pass_read" 		{
					local vlab = "pass_c"
					local xtitle = "% A's Reading"
					}
				if "`v'" == "approved" 		{
					local vlab = "pass"
					local xtitle = "Grade Promotion"
					}
				if "`v'" == "approved_first" 		{
					local vlab = "passf"
					local xtitle = "Grade Promotion without recovery"
					}
				if "`v'" == "higher_ed_parent" 		{
					local vlab = "hed_parent"
					local xtitle = "% Parent with higher education"
					}
	
			* All students
			di as result "*******" _n as text "All" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(grade id_ie)
			estimates store all_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1  , a(grade id_ie)
			estimates store all_`vlab'_3
			if ${max_sibs} == 4 eststo all_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1  , a(grade id_ie)				

			di as result "*******" _n as text "All with Survey info" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & low_ses!=. , a(grade id_ie)
			estimates store alls_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & low_ses!=.  , a(grade id_ie)
			estimates store alls_`vlab'_3
			if ${max_sibs} == 4 eststo alls_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & low_ses!=.  , a(grade id_ie)

			di as result "*******" _n as text "No internet" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & has_internet==0 , a(grade id_ie)
			estimates store nint_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & has_internet==0  , a(grade id_ie)
			estimates store nint_`vlab'_3
			if ${max_sibs} == 4 eststo nint_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & has_internet==0  , a(grade id_ie)

			di as result "*******" _n as text "Low SES" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & low_ses==1 , a(grade id_ie)
			estimates store lses_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & low_ses==1  , a(grade id_ie)
			estimates store lses_`vlab'_3
			if ${max_sibs} == 4 eststo lses_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & low_ses==1  , a(grade id_ie)

			di as result "*******" _n as text "No computer" _n as result "*******"
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & has_comp==0 , a(grade id_ie)
			estimates store ncom_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & has_comp==0  , a(grade id_ie)
			estimates store ncom_`vlab'_3
			if ${max_sibs} == 4 eststo ncom_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & has_comp==0  , a(grade id_ie)

			coefplot alls_`vlab'_?, ///
					bylabel("All Students") ///
					|| lses_`vlab'_?, ///
					bylabel("Low SES") ///
					|| nint_`vlab'_?, ///
					bylabel("No access to Internet") ////
					|| ncom_`vlab'_?, ///
					bylabel("No Computer in the house") ///	
					keep(treated_post) ///
					xline(0, lpattern(dash)) ///
					legend(order(1 "1 sibling" 3 "2 siblings" 5 "`legend_sib_${max_sibs}'") col(3) pos(6)) ///
					xlabel(-.1(0.02)0.02) ///
					///ciopts(recast(rcap) lwidth(medium)) ///
					grid(none) ///
					///yscale(reverse) ///
					bycoefs
					
			//graph save "$FIGURES\covid_twfe_survey_`level'_`vlab'_${max_sibs}.gph" , replace	
			//capture qui graph export "$FIGURES\covid_twfe_survey_`level'_`vlab'_${max_sibs}.eps", replace	
			capture qui graph export "$FIGURES\TWFE\covid_twfe_survey_`level'_`vlab'_${max_sibs}${covid_data}.png", replace	
			capture qui graph export "$FIGURES\TWFE\covid_twfe_survey_`level'_`vlab'_${max_sibs}${covid_data}.pdf", replace			

			}
		}

end
	


************************************************************************************

capture program drop twfe_ece
program define twfe_ece	
	
	
use "$TEMP\siagie_append", clear	


keep id_ie id_per_umc year level grade section_siagie male_siagie region_siagie public_siagie urban_siagie lives_with_mother lives_with_father approved approved_first math comm std_gpa_m_adj std_gpa_c_adj

*- Attach Family variables
	preserve
			use "$TEMP\id_siblings", clear
			keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} born* closest_age_gap*${fam_type} covid_preg_sib covid_0_2_sib covid_2_4_sib exp_graduating_year?
			tempfile id_siblings_sample
			save `id_siblings_sample', replace
	restore

	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}) 
	rename _m merge_siblings
	
	
*- Attach ECE/Survey data

	*- Match ECE IDs
	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2p", keep(master match) keepusing(id_estudiante source)
	rename _m merge_2p
	//tab grade merge_2p, row nofreq
	rename (id_estudiante source) (id_estudiante_2p source_2p)

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_4p", keep(master match) keepusing(id_estudiante source)
	rename _m merge_4p
	//tab grade merge_4p, row nofreq
	rename (id_estudiante source) (id_estudiante_4p source_4p)
	
	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_6p", keep(master match) keepusing(id_estudiante source)
	rename _m merge_6p
	//tab grade merge_4p, row nofreq
	rename (id_estudiante source) (id_estudiante_6p source_6p)	

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2s", keep(master match) keepusing(id_estudiante source)
	rename _m merge_2s
	//tab grade merge_2s, row nofreq
	rename (id_estudiante source) (id_estudiante_2s source_2s)

	*- Match ECE exams
	merge m:1 id_estudiante_2p using  "$TEMP\ece_2p", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year urban) //m:1 because there are missings
	rename _m merge_ece_2p
	rename (year score_math_std score_com_std score_acad_std) (year_2p score_math_std_2p score_com_std_2p score_acad_std_2p)
	rename (socioec_index socioec_index_cat) (socioec_index_2p socioec_index_cat_2p)
	rename (urban) (urban_2p)
	
	merge m:1 id_estudiante_4p using "$TEMP\ece_4p", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year) //m:1 because there are missings
	rename _m merge_ece_4p
	rename (year score_math_std score_com_std score_acad_std) (year_4p score_math_std_4p score_com_std_4p score_acad_std_4p)
	rename (socioec_index socioec_index_cat) (socioec_index_4p socioec_index_cat_4p)
	
	merge m:1 id_estudiante_6p using "$TEMP\em_6p", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year) //m:1 because there are missings
	rename _m merge_ece_6p
	rename (year score_math_std score_com_std score_acad_std) (year_6p score_math_std_6p score_com_std_6p score_acad_std_6p)
	rename (socioec_index socioec_index_cat) (socioec_index_6p socioec_index_cat_6p)
	
	merge m:1 id_estudiante_2s using "$TEMP\ece_2s", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year) //m:1 because there are missings
	rename _m merge_ece_2s
	rename (year score_math_std score_com_std score_acad_std) (year_2s score_math_std_2s score_com_std_2s score_acad_std_2s)
	rename (socioec_index socioec_index_cat) (socioec_index_2s socioec_index_cat_2s)

	*- Match EM exams
	merge m:1 id_estudiante_2p using  "$TEMP\em_2p", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year) //m:1 because there are missings
	rename _m merge_m_2p
	replace year_2p = year if year_2p==.
	replace score_math_std_2p 	= score_math_std 	if score_math_std_2p==.
	replace score_com_std_2p 	= score_com_std 	if score_com_std_2p==.
	replace score_acad_std_2p 	= score_acad_std 	if score_acad_std_2p==.
	replace socioec_index_2p = socioec_index if socioec_index_2p ==.
	replace socioec_index_cat_2p = socioec_index_cat if socioec_index_cat_2p ==.
	drop score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year	
	
	merge m:1 id_estudiante_4p using "$TEMP\em_4p", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year) //m:1 because there are missings
	rename _m merge_m_4p
	replace year_4p = year if year_4p==.
	replace score_math_std_4p 	= score_math_std 	if score_math_std_4p==.
	replace score_com_std_4p 	= score_com_std 	if score_com_std_4p==.
	replace score_acad_std_4p 	= score_acad_std 	if score_acad_std_4p==.
	replace socioec_index_4p = socioec_index if socioec_index_4p ==.
	replace socioec_index_cat_4p = socioec_index_cat if socioec_index_cat_4p ==.
	drop score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year
	
	/*
	merge m:1 id_estudiante_6p using "$TEMP\em_6p", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year) //m:1 because there are missings
	rename _m merge_m_6p
	replace year_6p = year if year_6p==.
	replace score_math_std_6p 	= score_math_std 	if score_math_std_6p==.
	replace score_com_std_6p 	= score_com_std 	if score_com_std_6p==.
	replace score_acad_std_6p 	= score_acad_std 	if score_acad_std_6p==.
	replace socioec_index_6p = socioec_index if socioec_index_6p ==.
	replace socioec_index_cat_6p = socioec_index_cat if socioec_index_cat_6p ==.
	drop score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year
	*/
	merge m:1 id_estudiante_2s using "$TEMP\em_2s", keep(master match) keepusing(score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year) //m:1 because there are missings
	rename _m merge_m_2s
	replace year_2s = year if year_2s==.
	replace score_math_std_2s 	= score_math_std 	if score_math_std_2s==.
	replace score_com_std_2s 	= score_com_std 	if score_com_std_2s==.
	replace score_acad_std_2s 	= score_acad_std 	if score_acad_std_2s==.
	replace socioec_index_2s = socioec_index if socioec_index_2s ==.
	replace socioec_index_cat_2s = socioec_index_cat if socioec_index_cat_2s ==.
	drop score_math_std score_com_std score_acad_std socioec_index socioec_index_cat year

	
	*- Match ECE survey
	merge m:1 id_estudiante_2p using "$TEMP\ece_family_2p", keep(master match) keepusing(aspiration_2p) //m:1 because there are missings
	rename _m merge_ece_survey_fam_2p
	rename aspiration_2p aspiration_fam_2p
	
	merge m:1 id_estudiante_4p using "$TEMP\ece_family_4p", keep(master match) keepusing(aspiration_4p gender_subj_?_4p) //m:1 because there are missings
	rename _m merge_ece_survey_fam_4p
	rename aspiration_4p aspiration_fam_4p
	
	merge m:1 id_estudiante_6p using "$TEMP\ece_family_6p", keep(master match) keepusing(aspiration_6p gender_subj_?_6p) //m:1 because there are missings
	rename _m merge_ece_survey_fam_6p	
	rename aspiration_6p aspiration_fam_6p
	
	merge m:1 id_estudiante_6p using "$TEMP\ece_student_6p", keep(master match) keepusing(aspiration_6p) //m:1 because there are missings
	rename _m merge_ece_survey_stud_6p	
	rename aspiration_6p aspiration_stu_6p	
	
	merge m:1 id_estudiante_2s using "$TEMP\ece_student_2s", keep(master match) keepusing(aspiration_2s lives_with_*_2s total_siblings_2s) //m:1 because there are missings
	rename _m merge_ece_survey_stud_2s
	rename aspiration_2s aspiration_stu_2s


	*- Match with SIRIES (applications and enrollment)
	//merge m:1 id_per_umc using "$TEMP\applied", keep(master match) keepusing()
	
	*- Aspirations
	gen byte asp_college2_fam_2p = inlist(aspiration_fam_2p,3,4,5) if aspiration_fam_2p!=.
	gen byte asp_college2_fam_4p = inlist(aspiration_fam_4p,3,4,5) if aspiration_fam_4p!=.
	gen byte asp_college2_fam_6p = inlist(aspiration_fam_6p,3,4,5) if aspiration_fam_6p!=.
	gen byte asp_college2_stu_6p = inlist(aspiration_stu_6p,3,4,5) if aspiration_stu_6p!=.
	gen byte asp_college2_stu_2s = inlist(aspiration_stu_2s,3,4,5) if aspiration_stu_2s!=.	
	gen byte asp_college4_fam_2p = inlist(aspiration_fam_2p,4,5) if aspiration_fam_2p!=.
	gen byte asp_college4_fam_4p = inlist(aspiration_fam_4p,4,5) if aspiration_fam_4p!=.
	gen byte asp_college4_fam_6p = inlist(aspiration_fam_6p,4,5) if aspiration_fam_6p!=.
	gen byte asp_college4_stu_6p = inlist(aspiration_stu_6p,4,5) if aspiration_stu_6p!=.
	gen byte asp_college4_stu_2s = inlist(aspiration_stu_2s,4,5) if aspiration_stu_2s!=.
	
	*- University variables (application, enrollment, graduation, peers)
	merge 1:1 id_per_umc using "$TEMP\student_umc_uni",  keep(master match) nogen	
	
	
	
	
	
	
*- Potential years
use "$TEMP\ece_2p", clear
append using "$TEMP\em_2p"	
keep if year>=2018 & year<=2024
bys year: gen N=_N
keep if N>50000
tab year

use "$TEMP\ece_4p", clear
append using "$TEMP\em_4p"
keep if year>=2018 & year<=2024
bys year: gen N=_N
keep if N>50000
tab year


use "$TEMP\ece_2s", clear
append using "$TEMP\em_2s"
keep if year>=2018 & year<=2024
bys year: gen N=_N
keep if N>50000
tab year



*-- 2p:
	use "$TEMP\ece_2p", clear
	append using "$TEMP\em_2p"
	keep if year>=2018 & year<=2024
	//keep if year==2018 | year==2024

	merge 1:1 id_estudiante_2p using "$TEMP\ece_family_2p", keep(master match) 
	drop _m

	*- Match ECE IDs - 2p
	rename id_estudiante_2p id_estudiante
	merge m:1 id_estudiante using "$TEMP\match_siagie_ece_2p", keep(master match) keepusing(id_per_umc) 
	keep if _m==3
	drop _m
	rename aspiration_2p aspiration_fam_2p

	*- Attach Family variables
	preserve
			use "$TEMP\id_siblings", clear
			keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} born* closest_age_gap*${fam_type} covid_preg_sib covid_0_2_sib covid_2_4_sib exp_graduating_year?
			tempfile id_siblings_sample
			save `id_siblings_sample', replace
	restore

	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}) 
	rename _m merge_siblings


	gen treated = (fam_total_${fam_type}>1)
	gen post = year>=2020
	gen post_2019 = year>=2019
	gen post_2024 = year>=2024
	gen treated_post = treated*post
	gen treated_post_2019 = treated*post_2019
	gen treated_post_2024 = treated*post_2024
	keep if fam_total_${fam_type}<=4
	gen fe=1
	compress
	
	
	gen byte asp_college2_fam_2p 	= inlist(aspiration_fam_2p,3,4,5) if aspiration_fam_2p!=.
	gen byte asp_college4_fam_2p 	= inlist(aspiration_fam_2p,4,5) if aspiration_fam_2p!=.
	gen byte asp_not_school_fam_2p 	= inlist(aspiration_fam_2p,1,2) if aspiration_fam_2p!=.
	
	global x = "male i.edu_father_2p i.edu_mother_2p urban spanish"

	reghdfe score_math 				treated_post treated post fe, a(id_ie year)
	reghdfe score_com 				treated_post treated post fe, a(id_ie year)
	reghdfe score_math_std 			treated_post treated post fe, a(id_ie year)
	reghdfe score_com_std 			treated_post treated post fe, a(id_ie year)
	reghdfe score_acad_std 			treated_post treated post fe, a(id_ie year)
	reghdfe asp_not_school_fam_2p 	treated_post treated post fe, a(id_ie year)
	//reghdfe asp_college2_fam_2p 	treated_post treated post fe, a(id_ie year)
	reghdfe asp_college4_fam_2p 	treated_post treated post fe, a(id_ie year)	
	reghdfe socioec_index 			treated_post treated post fe, a(id_ie year)
	
	reghdfe score_math 				treated_post treated post ${x} fe, a(id_ie year)
	reghdfe score_com 				treated_post treated post ${x} fe, a(id_ie year)
	reghdfe score_math_std 			treated_post treated post ${x} fe, a(id_ie year)
	reghdfe score_com_std 			treated_post treated post ${x} fe, a(id_ie year)
	reghdfe score_acad_std 			treated_post treated post ${x} fe, a(id_ie year)
	reghdfe asp_not_school_fam_2p 	treated_post treated post ${x} fe, a(id_ie year)
	//reghdfe asp_college2_fam_2p 	treated_post treated post ${x} fe, a(id_ie year)
	reghdfe asp_college4_fam_2p 	treated_post treated post ${x} fe, a(id_ie year)


*-- 4p:
	use "$TEMP\ece_4p", clear
	append using "$TEMP\em_4p"
	keep if year>=2018 & year<=2024
	//keep if year==2018 | year==2024

	merge 1:1 id_estudiante_4p using "$TEMP\ece_family_4p", keep(master match) 
	drop _m

	*- Match ECE IDs - 4p
	rename id_estudiante_4p id_estudiante
	merge m:1 id_estudiante using "$TEMP\match_siagie_ece_4p", keep(master match) keepusing(id_per_umc) 
	keep if _m==3
	drop _m
	rename aspiration_4p aspiration_fam_4p

	*- Attach Family variables
	preserve
			use "$TEMP\id_siblings", clear
			keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} born* closest_age_gap*${fam_type} covid_preg_sib covid_0_2_sib covid_2_4_sib exp_graduating_year?
			tempfile id_siblings_sample
			save `id_siblings_sample', replace
	restore

	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}) 
	rename _m merge_siblings


	gen treated = (fam_total_${fam_type}>1)
	gen post = year>=2020
	gen post_2019 = year>=2019
	gen post_2024 = year>=2024
	gen treated_post = treated*post
	gen treated_post_2019 = treated*post_2019
	gen treated_post_2024 = treated*post_2024
	keep if fam_total_${fam_type}<=4
	gen fe=1
	compress
	
	
	gen byte asp_college2_fam_4p 	= inlist(aspiration_fam_4p,3,4,5) if aspiration_fam_4p!=.
	gen byte asp_college4_fam_4p 	= inlist(aspiration_fam_4p,4,5) if aspiration_fam_4p!=.
	gen byte asp_not_school_fam_4p 	= inlist(aspiration_fam_4p,1,2) if aspiration_fam_4p!=.
	
	global x = "male i.edu_father_4p i.edu_mother_4p urban spanish"

	reghdfe score_math 				treated_post treated post fe, a(id_ie year)
	reghdfe score_com 				treated_post treated post fe, a(id_ie year)
	reghdfe score_math_std 			treated_post treated post fe, a(id_ie year)
	reghdfe score_com_std 			treated_post treated post fe, a(id_ie year)
	reghdfe score_acad_std 			treated_post treated post fe, a(id_ie year)
	reghdfe asp_not_school_fam_4p 	treated_post treated post fe, a(id_ie year)
	//reghdfe asp_college2_fam_4p 	treated_post treated post fe, a(id_ie year)
	reghdfe asp_college4_fam_4p 	treated_post treated post fe, a(id_ie year)	
	reghdfe socioec_index 	treated_post treated post fe, a(id_ie year)
	
	reghdfe score_math 				treated_post treated post ${x} fe, a(id_ie year)
	reghdfe score_com 				treated_post treated post ${x} fe, a(id_ie year)
	reghdfe score_math_std 			treated_post treated post ${x} fe, a(id_ie year)
	reghdfe score_com_std 			treated_post treated post ${x} fe, a(id_ie year)
	reghdfe score_acad_std 			treated_post treated post ${x} fe, a(id_ie year)
	reghdfe asp_not_school_fam_4p 	treated_post treated post ${x} fe, a(id_ie year)
	//reghdfe asp_college2_fam_4p 	treated_post treated post ${x} fe, a(id_ie year)
	reghdfe asp_college4_fam_4p 	treated_post treated post ${x} fe, a(id_ie year)


*-- 2s:
	use "$TEMP\ece_2s", clear
	append using "$TEMP\em_2s"
	keep if year>=2018 & year<=2024
	//keep if year==2018 | year==2024

	merge 1:1 id_estudiante_2s using "$TEMP\ece_student_2s", keep(master match) 
	drop _m

	*- Match ECE IDs - 2s
	rename id_estudiante_2s id_estudiante
	merge m:1 id_estudiante using "$TEMP\match_siagie_ece_2s", keep(master match) keepusing(id_per_umc) 
	keep if _m==3
	drop _m
	rename aspiration_2s aspiration_fam_2s

	*- Attach Family variables
	preserve
			use "$TEMP\id_siblings", clear
			keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} born* closest_age_gap*${fam_type} covid_preg_sib covid_0_2_sib covid_2_4_sib exp_graduating_year?
			tempfile id_siblings_sample
			save `id_siblings_sample', replace
	restore

	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}) 
	rename _m merge_siblings


	drop if year==2020
	gen treated = (fam_total_${fam_type}>1)
	gen post = year>=2020
	gen treated_post = treated*post
	keep if fam_total_${fam_type}<=4
	gen fe=1
	compress
	
	
	gen byte asp_college2_fam_2s 	= inlist(aspiration_fam_2s,3,4,5) if aspiration_fam_2s!=.
	gen byte asp_college4_fam_2s 	= inlist(aspiration_fam_2s,4,5) if aspiration_fam_2s!=.
	gen byte asp_not_school_fam_2s 	= inlist(aspiration_fam_2s,1,2) if aspiration_fam_2s!=.
	
	global x = "male i.edu_father_2s i.edu_mother_2s urban spanish"

	reghdfe score_math 				treated_post treated post fe, a(id_ie year)
	reghdfe score_math 				treated_post treated post fe if inlist(fam_total_${fam_type},1,4)==1 & year==2019 | year==2023, a(id_ie year) //still same sign (positive)
	reghdfe score_com 				treated_post treated post fe, a(id_ie year)
	reghdfe score_math_std 			treated_post treated post fe, a(id_ie year)
	reghdfe score_com_std 			treated_post treated post fe, a(id_ie year)
	reghdfe score_acad_std 			treated_post treated post fe, a(id_ie year)
	reghdfe asp_not_school_fam_2s 	treated_post treated post fe, a(id_ie year)
	//reghdfe asp_college2_fam_2s 	treated_post treated post fe, a(id_ie year)
	reghdfe asp_college4_fam_2s 	treated_post treated post fe, a(id_ie year)	
	
	reghdfe score_math 				treated_post treated post ${x} fe, a(id_ie year)
	reghdfe score_com 				treated_post treated post ${x} fe, a(id_ie year)
	reghdfe score_math_std 			treated_post treated post ${x} fe, a(id_ie year)
	reghdfe score_com_std 			treated_post treated post ${x} fe, a(id_ie year)
	reghdfe score_acad_std 			treated_post treated post ${x} fe, a(id_ie year)
	reghdfe asp_not_school_fam_2s 	treated_post treated post ${x} fe, a(id_ie year)
	//reghdfe asp_college2_fam_2s 	treated_post treated post ${x} fe, a(id_ie year)
	reghdfe asp_college4_fam_2s 	treated_post treated post ${x} fe, a(id_ie year)

		
	reghdfe socioec_index 				treated_post treated post fe, a(id_ie year)
	



	
end


************************************************************************************

capture program drop twfe_ece_baseline_scores
program define twfe_ece_baseline_scores

/*
*- Only scores No survey in (pre)
▶ 4. 2° (2013,2016) → 8° (2019/2022)
*/




local year_ece_pre 		=  2013
local year_ece_post 	=  2016
local year_siagie_pre 	=  2019
local year_siagie_post 	=  2022
local grade_ece			=  2	
local grade_siagie		=  8



use   "$TEMP\siagie_append", clear

keep id_per_umc id_ie year level grade male_siagie region_siagie public_siagie urban_siagie lives_with_mother lives_with_father approved approved_first std_gpa_m_adj std_gpa_c_adj

	keep if year==`year_siagie_pre' | year==`year_siagie_post'
	keep if grade==`grade_siagie'	
	
	*- Match ECE IDs - 2nd
	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2p", keep(master match) keepusing(id_estudiante source)
	rename _m merge_2p
	//tab grade merge_`g_ece', row nofreq
	rename (id_estudiante source) (id_estudiante_2p source_2p)
	
	*- Match ECE IDs - 8th
	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2s", keep(master match) keepusing(id_estudiante source)
	rename _m merge_2s
	//tab grade merge_`g_ece', row nofreq
	rename (id_estudiante source) (id_estudiante_2s source_2s)	
	
	*- Match ECE Scores - 2nd
	rename year year_siagie
	merge m:1 id_estudiante_2p  using  "$TEMP\\ece_2p", keep(master match) keepusing(year score_math score_com score_math_std score_com_std score_acad_std socioec_index socioec_index_cat label_* urban) //m:1 because there are missings
	rename _m merge_ece_base_2p
	rename (year score_math score_com score_math_std score_com_std score_acad_std) (year_2p base_score_math_2p base_score_com_2p base_math_std_2p base_com_std_2p base_acad_std_2p)
	rename (socioec_index socioec_index_cat) (base_socioec_index_2p base_socioec_index_cat_2p)
	rename (label_*) (base_label_*)
	rename (urban) (base_urban_2p)
	rename year_siagie year
	
	*- Match ECE Scores - 8th
	preserve
		clear
		append using "$TEMP\\ece_2s"
		append using "$TEMP\\em_2s"
		tempfile ece_em_2s
		save `ece_em_2s', replace
	restore
	rename year year_siagie
	merge m:1 id_estudiante_2s  using  `ece_em_2s', keep(master match) keepusing(year score_math score_com score_math_std score_com_std score_acad_std socioec_index socioec_index_cat label_* urban) //m:1 because there are missings
	rename _m merge_ece_2s
	rename (year score_math score_com score_math_std score_com_std score_acad_std) (year_2s score_math_2s score_com_2s math_std_2s com_std_2s acad_std_2s)
	rename (socioec_index socioec_index_cat) (socioec_index_2s socioec_index_cat_2s)
	rename label_* label_*_2s
	rename (urban) (urban_2s)
	rename year_siagie year
	
	keep if (merge_ece_2s ==3 & merge_ece_base_2p == 3)==1
	keep if (year_2s==`year_siagie_pre' & year_2p==`year_ece_pre') | (year_2s==`year_siagie_post' & year_2p==`year_ece_post')

	*- Attach Family variables
	preserve
			use "$TEMP\id_siblings", clear
			keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} born* closest_age_gap*${fam_type} covid_preg_sib covid_0_2_sib covid_2_4_sib exp_graduating_year?
			tempfile id_siblings_sample
			save `id_siblings_sample', replace
	restore

	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}) 
	rename _m merge_siblings

			
	gen treated = (fam_total_${fam_type}>1)
	gen post = year>=2020
	gen treated_post = treated*post
	gen fe=1
	
	compress

	
	foreach size in "2_4" "2" "3" "4" {
		preserve
			di as result "*********************" _n as text "Size: `size'" _n as result "*********************"
			if "`size'" == "2-4" 	keep if fam_total_${fam_type}<=4
			if "`size'" == "2" 		keep if inlist(fam_total_${fam_type},1,2)==1
			if "`size'" == "3" 		keep if inlist(fam_total_${fam_type},1,3)==1
			if "`size'" == "4" 		keep if inlist(fam_total_${fam_type},1,4)==1		
			
			eststo gpa_m_`size': 	reghdfe std_gpa_m_adj 	treated_post treated post base_score_math_2p base_score_com_2p fe, a(id_ie )
			eststo gpa_c_`size': 	reghdfe std_gpa_c_adj 	treated_post treated post base_score_math_2p base_score_com_2p fe, a(id_ie )
			//eststo ece_m_`size': 	reghdfe score_math_2s 	treated_post treated post base_score_math_2p base_score_com_2p fe, a(id_ie )
			//eststo ece_c_`size': 	reghdfe score_com_2s 	treated_post treated post base_score_math_2p base_score_com_2p fe, a(id_ie )
			eststo ece_m_`size': 	reghdfe math_std_2s 	treated_post treated post base_score_math_2p base_score_com_2p fe, a(id_ie )
			eststo ece_c_`size': 	reghdfe com_std_2s 		treated_post treated post base_score_math_2p base_score_com_2p fe, a(id_ie )
		restore	
	}
	

	****
	reghdfe socioec_index_2s treated_post treated post base_score_math_2p base_score_com_2p fe if fam_order_2==1, a(id_ie )
	gen satisf_m_2s = label_m_2s == 4
	gen proces_m_2s = label_m_2s == 3
	gen lowest_m_2s = label_m_2s == 2
	reghdfe satisf_m_2s treated_post treated post base_score_math_2p base_score_com_2p fe if fam_order_2==1, a(id_ie )
	reghdfe proces_m_2s treated_post treated post base_score_math_2p base_score_com_2p fe if fam_order_2==1, a(id_ie )
	reghdfe lowest_m_2s treated_post treated post base_score_math_2p base_score_com_2p fe if fam_order_2==1, a(id_ie )

	****	
	
	capture erase "$TABLES\twfe_ece.tex"
	
	****** TABLE HEADER
	


	
	
	file open  table_tex	using "$TABLES\twfe_ece.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
						"\makeatletter" _n ///
						"\@ifclassloaded{beamer}{%" _n ///
						"	\centering" _n ///
						"	\resizebox{0.6\textwidth}{!}%" _n ///
						"}{%" _n ///
						"	\begin{table}[!tbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
						"	\centering" _n ///
						"	\caption{TWFE on 8th grade GPA and standardized exams controlling for baseline 2nd grade standardized exams}" _n ///
						"	\label{tab:twfe_ece}" _n ///
						"	\resizebox{0.95\textwidth}{!}%" _n ///
						"}" _n ///
						"{" _n ///
						"\makeatother"	 _n 
	file close table_tex
	
	file open  table_tex	using "$TABLES\twfe_ece.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"\cmidrule(lr){2-5}" _n ///	
					"& \multicolumn{4}{c}{TWFE} \\"  _n ///
					"\cmidrule(lr){2-5}" _n ///	
					"& 1-3 siblings & 1 sibling & 2 siblings & 3 siblings  \\" _n ///
					"\cmidrule(lr){2-2} \cmidrule(lr){3-3} \cmidrule(lr){4-4} \cmidrule(lr){5-5}" _n ///	
					"& (1) & (2) & (3) & (4) \\" _n ///
					"\bottomrule" _n ///
					"&  &  & &  \\" _n 
	file close table_tex
	
	******* TABLE CONTENT				
	file open  table_tex	using "$TABLES\twfe_ece.tex", append write
	file write table_tex ///	
					"&  &  & &  \\" _n  ///
					"\multicolumn{5}{l}{Panel A: GPA } \\" _n
	file close table_tex	
	
	estout   gpa_m_2_4 gpa_m_2 gpa_m_3 gpa_m_4 ///
	using "$TABLES\twfe_ece.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Mathematics") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\twfe_ece.tex", append write	
	file write table_tex ///	
					"&  &  & &  \\" _n  
	file close table_tex		
	
	estout   gpa_c_2_4 gpa_c_2 gpa_c_3 gpa_c_4 ///
	using "$TABLES\twfe_ece.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Reading") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\twfe_ece.tex", append write
	file write table_tex ///	
					"&  &  & &  \\" _n  ///
					"\multicolumn{5}{l}{Panel B: Standardized Exams } \\" _n
	file close table_tex	
	
	estout   ece_m_2_4 ece_m_2 ece_m_3 ece_m_4 ///
	using "$TABLES\twfe_ece.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Mathematics") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\twfe_ece.tex", append write	
	file write table_tex ///	
					"&  &  & &  \\" _n  
	file close table_tex
	
	estout   ece_c_2_4 ece_c_2 ece_c_3 ece_c_4 ///
	using "$TABLES\twfe_ece.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Reading") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	
	********* END TABLE
	
	file open  table_tex	using "$TABLES\twfe_ece.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule" _n ///
		"\end{tabular}" _n ///
		"}" _n ///
		"\@ifclassloaded{beamer}{%" _n ///
		"}{%" _n ///
		"	\end{table}" _n ///
		"}" _n 
	file close table_tex	


end



************************************************************************************

capture program drop twfe_ece_baseline_survey
program define twfe_ece_baseline_survey

/*
▶ 1. 2° (2015,2016) → 6° (2019,2020)
▶ 2. 4° (2016,2018) → 6°/7° (2018/2019,2020/2021)
▶ 3. 8° (2018,2019) → 9° (2019/2020)
▶ 4. 8° (2015,2016) → college app (2019/2020)
*/

foreach g_pair in "g2_6" "g4_6" "g4_7" "g8_9" /*"g8_u"*/  "g2_8" {

if "`g_pair'" == "g2_6" {
	local g_ece = "2p"
	local ece_db = "ece_`g_ece'"
	local ece_db_survey = "ece_family_`g_ece'"
	
	local year_ece_pre 		=  2015
	local year_ece_post 	=  2016
	local year_siagie_pre 	=  2019
	local year_siagie_post 	=  2020
	local grade_ece			=  2	
	local grade_siagie		=  6
}

if "`g_pair'" == "g4_6" {
	local g_ece = "4p"
	local ece_db = "ece_`g_ece'"
	local ece_db_survey = "ece_family_`g_ece'"
	
	local year_ece_pre 		=  2016
	local year_ece_post 	=  2018
	local year_siagie_pre 	=  2018
	local year_siagie_post 	=  2020
	local grade_ece			=  4	
	local grade_siagie		=  6
}

if "`g_pair'" == "g4_7" {
	local g_ece = "4p"
	local ece_db = "ece_`g_ece'"
	local ece_db_survey = "ece_family_`g_ece'"
	
	local year_ece_pre 		=  2016
	local year_ece_post 	=  2018
	local year_siagie_pre 	=  2019
	local year_siagie_post 	=  2021
	local grade_ece			=  4	
	local grade_siagie		=  7
}

if "`g_pair'" == "g8_9" {
	local g_ece = "2s"
	local ece_db = "ece_`g_ece'"
	local ece_db_survey = "ece_student_`g_ece'"
	
	local year_ece_pre 		=  2018
	local year_ece_post 	=  2019
	local year_siagie_pre 	=  2019
	local year_siagie_post 	=  2020
	local grade_ece			=  8	
	local grade_siagie		=  9
}

use   "$TEMP\siagie_append", clear

keep if year==`year_siagie_pre' | year==`year_siagie_post'
keep if grade==`grade_siagie'	

keep id_per_umc id_ie year level grade male_siagie region_siagie public_siagie urban_siagie lives_with_mother lives_with_father approved approved_first std_gpa_m_adj std_gpa_c_adj

	*- Match ECE IDs
	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_`g_ece'", keep(master match) keepusing(id_estudiante source)
	rename _m merge_`g_ece'
	//tab grade merge_`g_ece', row nofreq
	rename (id_estudiante source) (id_estudiante_`g_ece' source_`g_ece')
	
	*- Match Baseline ECE exams
	rename year year_siagie
	merge m:1 id_estudiante_`g_ece'  using  "$TEMP\\`ece_db'", keep(master match) keepusing(year score_math score_com score_math_std score_com_std score_acad_std socioec_index socioec_index_cat label_* urban) //m:1 because there are missings
	rename _m merge_ece_base_`g_ece'
	rename (year score_math score_com score_math_std score_com_std score_acad_std) (year_`g_ece' base_score_math_`g_ece' base_score_com_`g_ece' base_math_std_`g_ece' base_com_std_`g_ece' base_acad_std_`g_ece')
	rename (socioec_index socioec_index_cat) (base_socioec_index_`g_ece' base_socioec_index_cat_`g_ece')
	rename (urban) (base_urban_`g_ece')
	rename year_siagie year
	
	keep if (year==`year_siagie_pre' & year_`g_ece'==`year_ece_pre') | (year==`year_siagie_post' & year_`g_ece'==`year_ece_post')

	*- Match ECE survey
	merge m:1 id_estudiante_`g_ece' using "$TEMP\\`ece_db_survey'", keep(master match) keepusing(aspiration_`g_ece' internet_`g_ece' pc_`g_ece' laptop_`g_ece' radio_`g_ece') //m:1 because there are missings
	rename _m merge_ece_survey_fam_`g_ece'
	rename aspiration_`g_ece' aspiration_fam_`g_ece'

	preserve
			use "$TEMP\id_siblings", clear
			keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} born* closest_age_gap*${fam_type} covid_preg_sib covid_0_2_sib covid_2_4_sib exp_graduating_year?
			tempfile id_siblings_sample
			save `id_siblings_sample', replace
	restore

	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}) 
	rename _m merge_siblings

	drop year_`g_ece'
	rename *_`g_ece' *
	
	compress
	
	save "$TEMP\erase_twfe_ece_`g_pair'", replace
}		
	
	
clear
append using "$TEMP\erase_twfe_ece_g2_6"
gen g_pair = 1
append using "$TEMP\erase_twfe_ece_g4_6"
replace g_pair = 2 if g_pair==.
append using "$TEMP\erase_twfe_ece_g4_7"
replace g_pair = 3 if g_pair==.
append using "$TEMP\erase_twfe_ece_g8_9"
replace g_pair = 4 if g_pair==.

	
	
	keep if fam_total_${fam_type}<=4
	gen treated = (fam_total_${fam_type}>1)
	gen post = year>=2020
	gen treated_post = treated*post
	
	

	foreach size in "2_4" "2" "3" "4" {
	preserve
		di as result "*********************" _n as text "Size: `size'" _n as result "*********************"
		if "`size'" == "2-4" 	keep if fam_total_${fam_type}<=4
		if "`size'" == "2" 		keep if inlist(fam_total_${fam_type},1,2)==1
		if "`size'" == "3" 		keep if inlist(fam_total_${fam_type},1,3)==1
		if "`size'" == "4" 		keep if inlist(fam_total_${fam_type},1,4)==1	
		foreach subj in "m" "c" {
		
			eststo gpa_`subj'_all_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index, a(id_ie g_pair)
			eststo gpa_`subj'_1_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com if g_pair==1, a(id_ie g_pair)
			eststo gpa_`subj'_2_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com if g_pair==2, a(id_ie g_pair)
			eststo gpa_`subj'_3_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com if g_pair==3, a(id_ie g_pair)
			eststo gpa_`subj'_4_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com if g_pair==4, a(id_ie g_pair)
			
			//Effect by SES
			eststo gpa_`subj'_ses1_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if base_socioec_index_cat==1, a(id_ie g_pair)
			eststo gpa_`subj'_ses2_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if base_socioec_index_cat==2, a(id_ie g_pair)
			eststo gpa_`subj'_ses3_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if base_socioec_index_cat==3, a(id_ie g_pair)
			eststo gpa_`subj'_ses4_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if base_socioec_index_cat==4, a(id_ie g_pair)
			
			//Effect by Resources
			eststo gpa_`subj'_pc_int0_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if internet==0 & pc==0, a(id_ie g_pair)
			eststo gpa_`subj'_pc_int1_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if internet==1 & pc==1, a(id_ie g_pair)

			
			//Effect by Aspirations
			eststo gpa_`subj'_asp_low_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if inlist(aspiration_fam,1)==1, a(id_ie g_pair)
			eststo gpa_`subj'_asp_med_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if inlist(aspiration_fam,2)==1, a(id_ie g_pair)
			eststo gpa_`subj'_asp_hig_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if inlist(aspiration_fam,4,5)==1, a(id_ie g_pair)
		}
	restore
	}
	//Interesting... if Computer or internet, results partly go away. But not if there is a laptop...?


****
***
**
* Table based on household resources
**
***
****

	capture erase "$TABLES\twfe_ece_survey_1.tex"
	
	****** TABLE HEADER
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_1.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
						"\makeatletter" _n ///
						"\@ifclassloaded{beamer}{%" _n ///
						"	\centering" _n ///
						"	\resizebox{0.6\textwidth}{!}%" _n ///
						"}{%" _n ///
						"	\begin{table}[!tbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
						"	\centering" _n ///
						"	\caption{TWFE on GPA controlling for baseline standardized exams}" _n ///
						"	\label{tab:twfe_ece_survey_1}" _n ///
						"	\resizebox{0.7\textwidth}{!}%" _n ///
						"}" _n ///
						"{" _n ///
						"\makeatother"	 _n 
	file close table_tex
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_1.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"\cmidrule(lr){2-5}" _n ///	
					"& \multicolumn{4}{c}{TWFE} \\"  _n ///
					"\cmidrule(lr){2-5}" _n ///	
					"& 1-3 siblings & 1 sibling & 2 siblings & 3 siblings  \\" _n ///
					"\cmidrule(lr){2-2} \cmidrule(lr){3-3} \cmidrule(lr){4-4} \cmidrule(lr){5-5}" _n ///	
					"& (1) & (2) & (3) & (4) \\" _n ///
					"\bottomrule" _n ///
					"&  &  & &  \\" _n 
	file close table_tex
	
	******* TABLE CONTENT	
	

	
	
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_1.tex", append write
	file write table_tex ///	
					"&  &  & &  \\" _n  ///
					"\multicolumn{5}{l}{Panel A: All studentes } \\" _n
	file close table_tex	
	
	estout   gpa_m_all_2_4 gpa_m_all_2 gpa_m_all_3 gpa_m_all_4  ///
	using "$TABLES\twfe_ece_survey_1.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Mathematics") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	///stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_1.tex", append write	
	file write table_tex ///	
					"&  &  & &  \\" _n  
	file close table_tex		
	
	estout   gpa_c_all_2_4 gpa_c_all_2 gpa_c_all_3 gpa_c_all_4  ///
	using "$TABLES\twfe_ece_survey_1.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Reading") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	
	
	
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_1.tex", append write
	file write table_tex ///	
					"&  &  & &  \\" _n  ///
					"\multicolumn{5}{l}{Panel B: Low SES Households (Q1)} \\" _n
	file close table_tex	
	
	estout   gpa_m_ses1_2_4 gpa_m_ses1_2 gpa_m_ses1_3 gpa_m_ses1_4  ///
	using "$TABLES\twfe_ece_survey_1.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Mathematics") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	///stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_1.tex", append write	
	file write table_tex ///	
					"&  &  & &  \\" _n  
	file close table_tex		
	
	estout   gpa_c_ses1_2_4 gpa_c_ses1_2 gpa_c_ses1_3 gpa_c_ses1_4  ///
	using "$TABLES\twfe_ece_survey_1.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Reading") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	
	
	
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_1.tex", append write
	file write table_tex ///	
					"&  &  & &  \\" _n  ///
					"\multicolumn{5}{l}{Panel C: High SES Households (Q4)} \\" _n
	file close table_tex	
	
	estout   gpa_m_ses4_2_4 gpa_m_ses4_2 gpa_m_ses4_3 gpa_m_ses4_4  ///
	using "$TABLES\twfe_ece_survey_1.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Mathematics") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	///stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_1.tex", append write	
	file write table_tex ///	
					"&  &  & &  \\" _n  
	file close table_tex		
	
	estout   gpa_c_ses4_2_4 gpa_c_ses4_2 gpa_c_ses4_3 gpa_c_ses4_4  ///
	using "$TABLES\twfe_ece_survey_1.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Reading") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	


	
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_1.tex", append write
	file write table_tex ///	
					"&  &  & &  \\" _n  ///
					"\multicolumn{5}{l}{Panel D: Households with no PC or Internet} \\" _n
	file close table_tex	
	
	estout   gpa_m_pc_int0_2_4 gpa_m_pc_int0_2 gpa_m_pc_int0_3 gpa_m_pc_int0_4  ///
	using "$TABLES\twfe_ece_survey_1.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Mathematics") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	///stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_1.tex", append write	
	file write table_tex ///	
					"&  &  & &  \\" _n  
	file close table_tex		
	
	estout   gpa_c_pc_int0_2_4 gpa_c_pc_int0_2 gpa_c_pc_int0_3 gpa_c_pc_int0_4  ///
	using "$TABLES\twfe_ece_survey_1.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Reading") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	
	
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_1.tex", append write
	file write table_tex ///	
					"&  &  & &  \\" _n  ///
					"\multicolumn{5}{l}{Panel E: Households with both PC and Internet} \\" _n
	file close table_tex	
	
	estout   gpa_m_pc_int1_2_4 gpa_m_pc_int1_2 gpa_m_pc_int1_3 gpa_m_pc_int1_4  ///
	using "$TABLES\twfe_ece_survey_1.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Mathematics") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	///stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_1.tex", append write	
	file write table_tex ///	
					"&  &  & &  \\" _n  
	file close table_tex		
	
	estout   gpa_c_pc_int1_2_4 gpa_c_pc_int1_2 gpa_c_pc_int1_3 gpa_c_pc_int1_4  ///
	using "$TABLES\twfe_ece_survey_1.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Reading") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	

	********* END TABLE
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_1.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule" _n ///
		"\end{tabular}" _n ///
		"}" _n ///
		"\@ifclassloaded{beamer}{%" _n ///
		"}{%" _n ///
		"	\end{table}" _n ///
		"}" _n 
	file close table_tex	
	
	
****
***
**
* Table based on parental investment (aspirations, actual time, both/single...)
**
***
****


	capture erase "$TABLES\twfe_ece_survey_2.tex"
	
	****** TABLE HEADER
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_2.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
						"\makeatletter" _n ///
						"\@ifclassloaded{beamer}{%" _n ///
						"	\centering" _n ///
						"	\resizebox{0.6\textwidth}{!}%" _n ///
						"}{%" _n ///
						"	\begin{table}[!tbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
						"	\centering" _n ///
						"	\caption{TWFE on GPA controlling for baseline standardized exams}" _n ///
						"	\label{tab:twfe_ece_survey_2}" _n ///
						"	\resizebox{0.95\textwidth}{!}%" _n ///
						"}" _n ///
						"{" _n ///
						"\makeatother"	 _n 
	file close table_tex
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_2.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"\cmidrule(lr){2-5}" _n ///	
					"& \multicolumn{4}{c}{TWFE} \\"  _n ///
					"\cmidrule(lr){2-5}" _n ///	
					"& 1-3 siblings & 1 sibling & 2 siblings & 3 siblings  \\" _n ///
					"\cmidrule(lr){2-2} \cmidrule(lr){3-3} \cmidrule(lr){4-4} \cmidrule(lr){5-5}" _n ///	
					"& (1) & (2) & (3) & (4) \\" _n ///
					"\bottomrule" _n ///
					"&  &  & &  \\" _n 
	file close table_tex
	
	******* TABLE CONTENT	
	
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_2.tex", append write
	file write table_tex ///	
					"&  &  & &  \\" _n  ///
					"\multicolumn{5}{l}{Panel A: All studentes } \\" _n
	file close table_tex	
	
	estout   gpa_m_all_2_4 gpa_m_all_2 gpa_m_all_3 gpa_m_all_4  ///
	using "$TABLES\twfe_ece_survey_2.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Mathematics") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	///stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_2.tex", append write	
	file write table_tex ///	
					"&  &  & &  \\" _n  
	file close table_tex		
	
	estout   gpa_c_all_2_4 gpa_c_all_2 gpa_c_all_3 gpa_c_all_4  ///
	using "$TABLES\twfe_ece_survey_2.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Reading") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	
	
	
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_2.tex", append write
	file write table_tex ///	
					"&  &  & &  \\" _n  ///
					"\multicolumn{5}{l}{Panel B: Parents or students who expect the maximum level of education will be high school graduation} \\" _n
	file close table_tex	
	
	estout   gpa_m_asp_low_2_4 gpa_m_asp_low_2 gpa_m_asp_low_3 gpa_m_asp_low_4  ///
	using "$TABLES\twfe_ece_survey_2.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Mathematics") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	///stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_2.tex", append write	
	file write table_tex ///	
					"&  &  & &  \\" _n  
	file close table_tex		
	
	estout   gpa_c_asp_low_2_4 gpa_c_asp_low_2 gpa_c_asp_low_3 gpa_c_asp_low_4  ///
	using "$TABLES\twfe_ece_survey_2.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Reading") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	
	
	
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_2.tex", append write
	file write table_tex ///	
					"&  &  & &  \\" _n  ///
					"\multicolumn{5}{l}{Panel C: Parents or students expect to finish 4-year college education} \\" _n
	file close table_tex	
	
	estout   gpa_m_asp_hig_2_4 gpa_m_asp_hig_2 gpa_m_asp_hig_3 gpa_m_asp_hig_4  ///
	using "$TABLES\twfe_ece_survey_2.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Mathematics") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	///stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_2.tex", append write	
	file write table_tex ///	
					"&  &  & &  \\" _n  
	file close table_tex		
	
	estout   gpa_c_asp_hig_2_4 gpa_c_asp_hig_2 gpa_c_asp_hig_3 gpa_c_asp_hig_4  ///
	using "$TABLES\twfe_ece_survey_2.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(treated_post) ///
	varlabels(treated_post "Reading") ///   //"\multirow{2}{*}{\shortstack[l]{Younger sibling born after \\ school-entry cutoff}}"
	///indicate("School FE" = fe, labels("Yes" "No")) ///
	stats(blank_line N   , fmt(%9.0fc %9.0fc ) labels(" " "Observations")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	


	

	********* END TABLE
	
	file open  table_tex	using "$TABLES\twfe_ece_survey_2.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule" _n ///
		"\end{tabular}" _n ///
		"}" _n ///
		"\@ifclassloaded{beamer}{%" _n ///
		"}{%" _n ///
		"	\end{table}" _n ///
		"}" _n 
	file close table_tex	
	
	
	


end

************************************************************************************




//main
