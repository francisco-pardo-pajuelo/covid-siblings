*- Only child and siblings in COVID

capture program drop main 
program define main 

	setup_COVID
	
	*clean_data
	
	*raw_trends
	
	twfe
	
	//event_ece
	event_gpa
	//event_approved
	event_cohort_grade
	
end

********************************************************************************
* Setup
********************************************************************************

capture program drop setup_COVID
program define setup_COVID

	global covid_test = 1

	global fam_type=2
	
	global max_sibs = 4

	global x_all = "male_siagie urban_siagie higher_ed_parent"
	global x_nohigher_ed = "male_siagie urban_siagie"
	
	colorpalette  HCL blues, selec(1 6 11) nograph
	return list

	global blue_1 = "`r(p1)'"
	global blue_2 = "`r(p2)'"
	global blue_3 = "`r(p3)'"
	//local blue_4 = "`r(p4)'"
	//local blue_5 = "`r(p5)'"
	//local blue_6 = "`r(p6)'"

	//colorpalette  HCL reds, selec(1 4 6 8 10 12) nograph
	colorpalette  HCL reds, selec(1 6 11) nograph
	return list

	global red_1 = "`r(p1)'"
	global red_2 = "`r(p2)'"
	global red_3 = "`r(p3)'"		
	
end

********************************************************************************
* Clean data
********************************************************************************

capture program drop clean_data
program define clean_data

	use   "$TEMP\siagie_append", clear

	keep id_per_umc year region_siagie public_siagie urban_siagie id_ie level grade male_siagie approved approved_first std_gpa_m std_gpa_c math comm

	preserve
			use "$TEMP\id_siblings", clear
			keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}	
			tempfile id_siblings_sample
			save `id_siblings_sample', replace
	restore

	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}) 
	rename _m merge_siblings



	*- Match ECE IDs
	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2p", keep(master match) keepusing(id_estudiante source)
	rename _m merge_2p
	//tab grade merge_2p, row nofreq
	rename (id_estudiante source) (id_estudiante_2p source_2p)

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_4p", keep(master match) keepusing(id_estudiante source)
	rename _m merge_4p
	//tab grade merge_4p, row nofreq
	rename (id_estudiante source) (id_estudiante_4p source_4p)

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2s", keep(master match) keepusing(id_estudiante source)
	rename _m merge_2s
	//tab grade merge_2s, row nofreq
	rename (id_estudiante source) (id_estudiante_2s source_2s)



	*- Match Baseline ECE exams
	rename year year_siagie
	merge m:1 id_estudiante_2p  using  "$TEMP\ece_2p", keep(master match) keepusing(year score_math_std score_com_std score_acad_std socioec_index socioec_index_cat label_* urban) //m:1 because there are missings
	rename _m merge_ece_baseline_2p
	rename (year score_math_std score_com_std score_acad_std) (year_2p base_math_std_2p base_com_std_2p base_acad_std_2p)
	rename (socioec_index socioec_index_cat) (base_socioec_index_2p base_socioec_index_cat_2p)
	rename (urban) (base_urban_2p)
	rename year_siagie year

	*- Match ECE exams
	foreach g in "2p" "4p" "2s" {
		merge m:1 id_estudiante_`g' year using "$TEMP\ece_`g'", keep(master match) keepusing(score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat) //m:1 because there are missings
		rename _m merge_ece_`g'
		rename (/*year*/ score_math_std score_com_std score_acad_std) (/*year_`g'*/ score_math_std_`g' score_com_std_`g' score_acad_std_`g')
		rename (socioec_index socioec_index_cat) (socioec_index_`g' socioec_index_cat_`g')
		rename (label_m label_c) (label_m_`g' label_c_`g')	
	}





	*- Match EM exams
	foreach g in "2p" "4p" "2s" {
		merge m:1 id_estudiante_`g' year using  "$TEMP\em_`g'", keep(master match) keepusing(score_math_std score_com_std score_acad_std label_m label_c  socioec_index socioec_index_cat) //m:1 because there are missings
		rename _m merge_m_`g'
		//replace year_`g' = year if year_`g'==.
		replace score_math_std_`g' 		= score_math_std 	if score_math_std_`g'	==.
		replace score_com_std_`g' 		= score_com_std 	if score_com_std_`g'	==.
		replace score_acad_std_`g' 		= score_acad_std 	if score_acad_std_`g'	==.
		replace label_m_`g'				= label_m 			if label_m_`g'			==.
		replace label_c_`g'				= label_c 			if label_c_`g'			==.
		replace socioec_index_`g' 		= socioec_index 	if socioec_index_`g' 	==.
		replace socioec_index_cat_`g' 	= socioec_index_cat if socioec_index_cat_`g' ==.
		drop score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat //year	
	}


	*- Match ECE survey
	merge m:1 id_estudiante_2p year using "$TEMP\ece_family_2p", keep(master match) keepusing(aspiration_2p internet_2p pc_2p laptop_2p radio_2p) //m:1 because there are missings
	rename _m merge_ece_survey_2p

	merge m:1 id_estudiante_4p year using "$TEMP\ece_family_4p", keep(master match) keepusing(aspiration_4p gender_subj_?_4p internet_4p pc_4p laptop_4p radio_4p study_desk_4p quiet_room_4p pc_hw_4p) //m:1 because there are missings
	rename _m merge_ece_survey_4p

	merge m:1 id_estudiante_2s year using "$TEMP\ece_student_2s", keep(master match) keepusing(aspiration_2s lives_with_*_2s total_siblings_2s) //m:1 because there are missings
	rename _m merge_ece_survey_2s
		
		
	drop id_estudiante_2p source_2p merge_2p id_estudiante_4p source_4p merge_4p id_estudiante_2s source_2s merge_2s merge_ece_2p merge_ece_4p merge_ece_2s merge_m_2p merge_m_4p merge_m_2s merge_ece_survey_2p merge_ece_survey_4p merge_ece_survey_2s


	*- Define additional outcomes:

	*-- Satisfactory level in ECE
	foreach g in "2p" "4p" "2s" {
		gen satisf_m_`g' = label_m_`g'==4 if label_m_`g'!=.
		gen satisf_c_`g' = label_c_`g'==4 if label_c_`g'!=.
		}
		
	*-- Baseline Resources/SES
	foreach g in "2p" "4p" {
		//We used family before, but OC have no siblings so better to have a comparable sample.
		bys id_per_umc: egen has_internet_`g' = max(cond(year<=2019,internet_`g',.)) 	
		bys id_per_umc: egen has_pc_`g' = max(cond(year<=2019,pc_`g',.)) 	
		bys id_per_umc: egen has_laptop_`g' = max(cond(year<=2019,laptop_`g',.)) 	
		bys id_per_umc: egen is_low_ses_`g' = min(cond(year<=2019,socioec_index_cat_`g',.)) 		
		}

	bys id_per_umc: egen quiet_room = min(cond(year<=2019,quiet_room_4p,.)) 

	egen has_internet 	= rmax(has_internet_2p has_internet_4p) if has_internet_2p!=. | has_internet_4p!=.
	egen has_comp 		= rmax(has_pc_2p has_laptop_2p has_pc_4p has_laptop_4p) if has_pc_2p!=. | has_laptop_2p!=. | has_pc_4p!=. | has_laptop_4p!=.
	egen low_ses 		= rmin(is_low_ses_2p is_low_ses_4p) if is_low_ses_2p!=. | is_low_ses_4p!=.

	//rename quiet_room_4p quiet_room

	describe
	compress

	save "$TEMP\long_siagie_ece", replace



	*- Check how many years of data each school has (to use comparable samples)
	use id_ie year grade score_*_std_?? approved approved_first std_gpa_? math comm  using "$TEMP\long_siagie_ece", clear

		collapse score_*_std_?? approved approved_first std_gpa_? math comm, by(id_ie year)

		foreach v of var score_*_std_?? approved approved_first std_gpa_? math comm {
			bys id_ie: egen  `v'_min =  min(cond( `v'!=.,year,.))
			bys id_ie: egen  `v'_max =  max(cond( `v'!=.,year,.))
			bys id_ie: egen  `v'_sum =  sum(cond( `v'!=.,1,0))
			}
			
		collapse *min *max *sum, by(id_ie)
		
		compress
		
	save "$TEMP\siagie_ece_ie_obs", replace	


	*- Create Event Study vars	
	use id_per_umc id_ie grade year male_siagie urban_siagie educ_mother educ_father socioec* has_internet has_comp low_ses quiet_room approved* std* math comm score* satisf* fam_order_${fam_type} fam_total_${fam_type} base* year_2p using "$TEMP\long_siagie_ece", clear

		keep if fam_total_${fam_type}<=${max_sibs}
		
		gen treated = fam_total_${fam_type}>1

		gen post = year>=2020
		gen treated_post = treated*post
		
		*- Other vars
		gen byte higher_ed_mother 		= inlist(educ_mother,7,8) if educ_mother!=. & educ_mother!=1
		gen byte higher_ed_father 		= inlist(educ_father,7,8) if educ_father!=. & educ_father!=1
		drop educ_mother educ_father
		gen byte higher_ed_parent		= (higher_ed_mother==1 | higher_ed_father==1) if higher_ed_mother!=. | higher_ed_father!=.
		drop higher_ed_mother higher_ed_father
		
		
		*- Passed Math and Reading
		gen letter = 0
		replace letter = 1 if grade<=6 
		replace letter = 1 if grade==7 & year>=2019
		replace letter = 1 if grade==8 & year>=2020
		replace letter = 1 if grade==9 & year>=2021
		replace letter = 1 if grade==10 & year>=2022
		replace letter = 1 if grade==11 & year>=2023
		
		local fail_letter = 2 //2=B, they need to get an A, otherwise they either fail or need to take extra classes?
		local fail_number = 10 //
		
		gen byte pass_math = 1 if math!=.	
		replace pass_math = 0 if math<=`fail_letter' & math!=. & letter==1
		replace pass_math = 0 if math<=`fail_number' & math!=. &letter==0
		
		gen byte pass_read = 1 if comm!=.
		replace pass_read = 0 if comm<=`fail_letter' & comm!=. &letter==1
		replace pass_read = 0 if comm<=`fail_number' & comm!=. &letter==0
		
		*- Events
		ds urban_siagie higher_ed_parent

		local suf_2014 = "b6"
		local suf_2015 = "b5"
		local suf_2016 = "b4"
		local suf_2017 = "b3"
		local suf_2018 = "b2"
		local suf_2019 = "o1"
		local suf_2020 = "a0"
		local suf_2021 = "a1"
		local suf_2022 = "a2"
		local suf_2023 = "a3"

		forvalues y = 2014(1)2023 {
			gen byte year_`suf_`y'' = year==`y'
			gen byte year_t_`suf_`y'' = year_`suf_`y''*treated
		}




		reghdfe score_acad_std_2s treated_post treated post , a(year grade)

		bys id_per_umc: egen first_year = min(year)
		bys id_per_umc: egen last_year = max(year)
		compress
	save "$TEMP\pre_reg_covid", replace

	if ${covid_test}==1  {
		use "$TEMP\pre_reg_covid", clear

		bys id_ie: egen u = max(cond(_n==1,runiform(),.))
		keep if u <0.1

		save "$TEMP\pre_reg_covid_TEST", replace
	}
	
end

	
		



********************************************************************************
* RAW TRENDS
********************************************************************************


capture program drop raw_trends
program define raw_trends

	*- Primary letters
	*- Secondary numbers
	*- But secondary changed to letters starting with cohort 2013 (7th grade in 2019)
	
	local ytitle_std_gpa_m = "Standardized GPA"		
	local ytitle_std_gpa_c = "Standardized GPA"		
	local ytitle_pass_math = "Passed GPA"		
	local ytitle_pass_read = "Passed GPA"	

	use std_gpa_? pass_math pass_read id_per_umc year grade treated fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid", clear
	
	*- Remove early grades and years
	keep if year>=2014
	drop if grade==0	

	*- Divide sample based on expected cohort
	bys id_per_umc: egen min_year 		= min(year)
	bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
	gen proxy_1st = min_year - grade_min_year  + 1
	
	*- Collapse data
	preserve 	
		collapse std_gpa_m std_gpa_c pass_math pass_read, by(year treated)
		foreach v in "std_gpa_m" "std_gpa_c" "pass_math" "pass_read" {
		twoway 		(line `v' year if treated==0 & year<=2019, lcolor("${red_3}")) /// 
					(line `v' year if treated==0 & year>=2020, lcolor("${red_1}")) /// 
					(line `v' year if treated==1 & year<=2019, lcolor("${blue_3}")) ///
					(line `v' year if treated==1 & year>=2020, lcolor("${blue_1}")) ///
					, ///
					xline(2019.5) ///
					xlabel(2014 "14" 2015 "15" 2016 "16" 2017 "17" 2018 "18" 2019 "19" 2020 "20" 2021 "21" 2022 "22" 2023 "23")  ///
					ytitle("`ytitle_`v''", size(small)) ///
					xtitle("Year") ///
					///legend(off) ///
					legend(order(1 "Only childs" 3 "Children with siblings") col(3) pos(6)) ///
					name(total_`v', replace)	
					
					capture qui graph export "$FIGURES\COVID\raw_total_`v'.png", replace			
					capture qui graph export "$FIGURES\COVID\raw_total_`v'.pdf", replace		
				}	
	restore
	
	collapse std_gpa_m std_gpa_c pass_math pass_read, by(year proxy_1st treated)
	
	foreach v of var std_gpa_? pass_math pass_read {
		replace `v' = . if proxy_1st == 2008 & year>=2019 //Should be 2021 but there are no grades for 2020 for 11th which is the on time grade for cohort 2010, so all left are delayed students
		replace `v' = . if proxy_1st == 2009 & year>=2020 //Should be 2021 but there are no grades for 2020 for 11th which is the on time grade for cohort 2010, so all left are delayed students
		replace `v' = . if proxy_1st == 2010 & year>=2020 //Should be 2021 but there are no grades for 2020 for 11th which is the on time grade for cohort 2010, so all left are delayed students
		replace `v' = . if proxy_1st == 2011 & year>=2022
		replace `v' = . if proxy_1st == 2012 & year>=2023
	}
	
	*- All individual plots	
	forvalues y = 2008(1)2018 {
		foreach v in "std_gpa_m" "std_gpa_c" "pass_math" "pass_read" {
			twoway 	(line `v' year if proxy_1st == `y' & treated==0 & year<=2019, lcolor("${red_1}")) /// 
					(line `v' year if proxy_1st == `y' & treated==0 & year>=2020, lcolor("${red_1}")) /// 
					(line `v' year if proxy_1st == `y' & treated==1 & year<=2019, lcolor("${blue_1}")) ///
					(line `v' year if proxy_1st == `y' & treated==1 & year>=2020, lcolor("${blue_1}")) ///
					, ///
					xline(2019.5) ///
					xlabel(2014 "14" 2015 "15" 2016 "16" 2017 "17" 2018 "18" 2019 "19" 2020 "20" 2021 "21" 2022 "22" 2023 "23")  ///
					ytitle("`ytitle_`v''", size(small)) ///
					xtitle("Year") ///
					subtitle("`y' cohort") ///
					legend(off) ///
					///legend(order(1 "Only childs" 3 "Children with siblings") col(3) pos(6)) ///
					name(`v'_`y', replace)	
				}
			}
	
	foreach v in "std_gpa_m" "std_gpa_c" "pass_math" "pass_read" {
	graph combine   `v'_2010 	///
					`v'_2011 `v'_2012 	///
					`v'_2013 `v'_2014 	///
					`v'_2015 `v'_2016 	///
					`v'_2017 `v'_2018 	///
					, 				///
					col(3) ///
					xsize(40) ///
					ysize(30) 
					
		///graph save "$FIGURES\COVID\raw_m.gph" , replace	
		///capture qui graph export "$FIGURES\COVID\raw_m.eps", replace	
		capture qui graph export "$FIGURES\COVID\raw_cohorts_`v'.png", replace			
		capture qui graph export "$FIGURES\COVID\raw_cohorts_`v'.pdf", replace	
	}	
	
	
end




********************************************************************************
* Event Study - ECE
********************************************************************************

capture program drop event_ece
program define event_ece	

	*---------
	*- ECE
	*---------
	*- ECE - 2P
	foreach v in "score_math_std_2p" "score_com_std_2p" "score_acad_std_2p" "satisf_m_2p" "satisf_c_2p" {
		di "`v'"
		if inlist("`v'","score_math_std_2p","satisf_m_2p")==1 	local subj = "math"
		if inlist("`v'","score_com_std_2p","satisf_c_2p")==1 	local subj = "com"
		if inlist("`v'","score_acad_std_2p")==1 				local subj = "acad"
		use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} if grade==2 using "$TEMP\pre_reg_covid", clear
		keep if inlist(year,2015,2016,2018,2019,2022,2023)==1
		merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_2p_*) nogen
		reghdfe 	`v' ${x}	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated, a(id_ie)
		*reghdfe 	score_acad_std_2p	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated if score_acad_std_2p_max==2022 & score_acad_std_2p_sum==5 & fam_order_2==1, a(id_ie)
		estimates 	store `v'
		}

	*- ECE - 4P
	foreach v in "score_math_std_4p" "score_com_std_4p" "score_acad_std_4p" "satisf_m_4p" "satisf_c_4p" {
		di "`v'"
		if inlist("`v'","score_math_std_4p","satisf_m_4p")==1 	local subj = "math"
		if inlist("`v'","score_com_std_4p","satisf_c_4p")==1 	local subj = "com"
		if inlist("`v'","score_acad_std_4p")==1 				local subj = "acad"
		use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} if grade==4 using "$TEMP\pre_reg_covid", clear
		keep if inlist(year,2016,2018,2019,2022,2023)==1
		merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_4p_*) nogen
		reghdfe 	`v' 	${x}						year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3  treated, a(year id_ie)
		estimates 	store `v'		
		}	

	*- ECE - 2S
	foreach v in "score_math_std_2s" "score_com_std_2s" "score_acad_std_2s" "satisf_m_2s" "satisf_c_2s" {
		di "`v'"
		if inlist("`v'","score_math_std_2s","satisf_m_2s")==1 	local subj = "math"
		if inlist("`v'","score_com_std_2s","satisf_c_2s")==1 	local subj = "com"
		if inlist("`v'","score_acad_std_2s")==1 				local subj = "acad"
		use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} ${x} if grade==8 using "$TEMP\pre_reg_covid", clear
		merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_2s_*) nogen
		keep if inlist(year,2015,2016,2018,2019,2022,2023)==1
		reghdfe 	`v' ${x}			 year_t_b5 		year_t_b4  			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3  treated, a(year id_ie)
		estimates 	store `v'		
		}	
		


	foreach g in "2p" "4p" "2s" {
		if "`g'" == "2p" local g_label = "2nd Grade"
		if "`g'" == "4p" local g_label = "4th Grade"
		if "`g'" == "2s" local g_label = "8th Grade"

		coefplot 	score_math_std_`g' score_com_std_`g' score_acad_std_`g', ///
					omitted ///
					keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
					drop(year_t_b3) ///
					leg(order(1 "Mathematics" 3 "Communications" 5 "Average")) ///
					coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023") ///
					yline(0,  lcolor(gs10))  ///
					ytitle("Effect (SD)") ///
					subtitle("Panel A: Standardized Exams - `g_label'") ///
					legend(pos(6) col(3)) ///
					name(panel_A_STD_`g',replace)	
		//graph save "$FIGURES\COVID\covid_ece_`g'.gph" , replace	
		//capture qui graph export "$FIGURES\COVID\covid_ece_`g'.eps", replace	
		capture qui graph export "$FIGURES\COVID\covid_ece_`g'.png", replace			
		capture qui graph export "$FIGURES\COVID\covid_ece_`g'.pdf", replace		
	}

	foreach g in "2p" "4p" "2s" {
		if "`g'" == "2p" local g_label = "2nd Grade"
		if "`g'" == "4p" local g_label = "4th Grade"
		if "`g'" == "2s" local g_label = "8th Grade"

		coefplot 	satisf_m_`g' satisf_c_`g', ///
					omitted ///
					keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
					drop(year_t_b3) ///
					leg(order(1 "Mathematics" 3 "Communications")) ///
					coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" /*year_t_b3 = "2017"*/ year_t_b2 = "2018" year_t_o1 = "2019" /*year_t_a0 = "2020" year_t_a1 = "2021"*/ year_t_a2 = "2022" year_t_a3 = "2023") ///
					yline(0,  lcolor(gs10))  ///
					ytitle("Effect") ///
					subtitle("Panel A: Satisfactory Level - `g_label'") ///
					legend(pos(6) col(3)) ///
					name(panel_A_SATISF_`g',replace)	
		//graph save "$FIGURES\COVID\covid_ece_`g'.gph" , replace	
		//capture qui graph export "$FIGURES\COVID\covid_ece_`g'.eps", replace	
		capture qui graph export "$FIGURES\COVID\covid_ece_`g'.png", replace			
		capture qui graph export "$FIGURES\COVID\covid_ece_`g'.pdf", replace		
	}	

end	




********************************************************************************
* TWFE - GPA
********************************************************************************

capture program drop twfe
program define twfe	
		
	estimates clear
	clear

	*- TWFE Estimates

	foreach level in "all" /*"elm" "sec"*/ {
		foreach v in "std_gpa_m" "std_gpa_c" "pass_math" "pass_read" /*"approved" "approved_first"*/ {
			
			global x = "$x_all"
			if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"	
			

			use std_gpa_? pass_math pass_read approved approved_first id_per_umc year_t_?? urban_siagie higher_ed_parent has_internet has_comp low_ses quiet_room year grade treated post treated_post id_ie fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid", clear
			
			*- Remove early grades and years
			keep if year>=2016
			drop if grade==0
			
			*- Divide sample based on grade in 2020
			bys id_per_umc: egen grade_2020	= min(cond(year==2020,grade,.))
			
			*- Divide sample based on expected cohort
			bys id_per_umc: egen min_year 		= min(year)
			bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
			gen proxy_1st = min_year - grade_min_year  + 1
								
			*- Not enough pre-years
			/*
			drop if inlist(grade_2020,1,2)==1
			drop if grade_2020==3 & year<=2017 //<=2017 Would only include those who repeated..
			drop if grade_2020==4 & year<=2016 //<=2016 Would only include those who repeated..
			*/
			//keep if proxy_1st <= 2018
			if "`area'" == "rur" keep if urban_siagie == 0
			if "`area'" == "urb" keep if urban_siagie == 1

			if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
			if "`hed_parent'" == "yes" 	keep if higher_ed_parent == 1

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
				gen young = inlist(grade_2020,7,8)==1 if inlist(grade_2020,7,8,9,10,11)
				local young_lab = "7th-8th grade"
				local old_lab 	= "9th-11th grade"
				}

			if "`v'" == "std_gpa_m" 		local vlab = "gpa_m"
			if "`v'" == "std_gpa_c" 		local vlab = "gpa_c"				
			if "`v'" == "pass_math" 		local vlab = "pass_m"				
			if "`v'" == "pass_read" 		local vlab = "pass_c"				
			if "`v'" == "approved" 			local vlab = "pass"
			if "`v'" == "approved_first" 	local vlab = "passf"
			
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(grade id_ie)
			estimates store all_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1  , a(grade id_ie)
			estimates store all_`vlab'_3
			if ${max_sibs} == 4 eststo all_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1  , a(grade id_ie)
			//estimates store all_`vlab'_4
			
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & inlist(fam_order_${fam_type},1)==1 , a(grade id_ie)
			estimates store first_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1& inlist(fam_order_${fam_type},1)==1  , a(grade id_ie)
			estimates store first_`vlab'_3
			if ${max_sibs} == 4 eststo first_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & inlist(fam_order_${fam_type},1)==1  , a(grade id_ie)
			//estimates store all_`vlab'_4
			
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & fam_order_${fam_type}==fam_total_${fam_type} , a(grade id_ie)
			estimates store last_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1& fam_order_${fam_type}==fam_total_${fam_type}  , a(grade id_ie)
			estimates store last_`vlab'_3
			if ${max_sibs} == 4 eststo last_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & fam_order_${fam_type}==fam_total_${fam_type}  , a(grade id_ie)
			//estimates store all_`vlab'_4
			
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & urban_siagie==1 , a(grade id_ie)
			estimates store urb_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & urban_siagie==1  , a(grade id_ie)
			estimates store urb_`vlab'_3
			if ${max_sibs} == 4 eststo urb_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & urban_siagie==1  , a(grade id_ie)
			//estimates store urb_`vlab'_4

			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & urban_siagie==0 , a(grade id_ie)
			estimates store rur_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & urban_siagie==0  , a(grade id_ie)
			estimates store rur_`vlab'_3
			if ${max_sibs} == 4 eststo rur_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & urban_siagie==0  , a(grade id_ie)
			//estimates store rur_`vlab'_4		
			
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & higher_ed_parent==1 , a(grade id_ie)
			estimates store yhed_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & higher_ed_parent==1  , a(grade id_ie)
			estimates store yhed_`vlab'_3
			if ${max_sibs} == 4 eststo yhed_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & higher_ed_parent==1  , a(grade id_ie)
			//estimates store yhed_`vlab'_4
			
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & higher_ed_parent==0 , a(grade id_ie)
			estimates store nhed_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & higher_ed_parent==0  , a(grade id_ie)
			estimates store nhed_`vlab'_3
			if ${max_sibs} == 4 eststo nhed_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & higher_ed_parent==0  , a(grade id_ie)
			//estimates store nhed_`vlab'_4
			
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & young==1 , a(grade id_ie)
			estimates store young_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & young==1  , a(grade id_ie)
			estimates store young_`vlab'_3
			if ${max_sibs} == 4 eststo young_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & young==1  , a(grade id_ie)
			//estimates store young_`vlab'_4	
			
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & young==0 , a(grade id_ie)
			estimates store old_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & young==0  , a(grade id_ie)
			estimates store old_`vlab'_3
			if ${max_sibs} == 4 eststo old_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & young==0  , a(grade id_ie)
			//estimates store young_`vlab'_4	
			
			if ${max_sibs}==4 local legend_${max_sibs} = "4 children"
			coefplot all_`vlab'_?, ///
					bylabel("All Students") ///
					|| first_`vlab'_?, ///
					bylabel("Oldest child") ///
					|| last_`vlab'_?, ///
					bylabel("Youngest child") ///
					|| urb_`vlab'_?, ///
					bylabel("Urban Areas") ///
					|| rur_`vlab'_?, ///
					bylabel("Rural Areas") ///
					|| yhed_`vlab'_?, ///
					bylabel("At least one parent" "with Higher Ed.") ///
					|| nhed_`vlab'_?, ///
					bylabel("Parents with no Higher Ed.") ///
					|| young_`vlab'_?, ///
					bylabel("`young_lab'") ///
					|| old_`vlab'_?, ///
					bylabel("`old_lab'") ///
					keep(treated_post) ///
					legend(order(1 "2 children" 3 "3 children" 5 "`legend_${max_sibs}'") col(3) pos(6)) ///
					xtitle("Standard Deviations", size(medsmall) height(5)) ///
					xlabel(-.1(0.02)0.02) ///
					xline(0, lcolor(gs12)) ///
					xline(-.1 -.08 -.06 -.04 -.02 .02, lcolor(gs15))  ///
					///xlabel(-.1 "-0.8" -.4 "-0.4" 0 "0" .4 "0.4" .8 "0.8", labsize(medsmall)) ///
					///ciopts(recast(rcap) lwidth(medium)) ///
					grid(none) ///
					///yscale(reverse) ///
					bycoefs	
			
					
			//graph save "$FIGURES\COVID\covid_twfe_`level'_`vlab'_${max_sibs}.gph" , replace	
			//capture qui graph export "$FIGURES\COVID\covid_twfe_`level'_`vlab'_${max_sibs}.eps", replace	
			capture qui graph export "$FIGURES\COVID\covid_twfe_`level'_`vlab'_${max_sibs}.png", replace	
			capture qui graph export "$FIGURES\COVID\covid_twfe_`level'_`vlab'_${max_sibs}.pdf", replace	
			
						
			if "`level'" == "all" {
				forvalues cohort = 2011(1)2018 {
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & proxy_1st==`cohort' , a(grade id_ie)
				estimates store c`cohort'_`vlab'_2
				reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & proxy_1st==`cohort' , a(grade id_ie)
				estimates store c`cohort'_`vlab'_3
				if ${max_sibs} == 4 eststo c`cohort'_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & proxy_1st==`cohort'  , a(grade id_ie)	
				}
				
				if ${max_sibs}==4 local legend_${max_sibs} = "4 children"
				coefplot all_`vlab'_?, ///
						bylabel("All Students") ///
						|| c2011_`vlab'_?, ///
						bylabel("2011 cohort") ///
						|| c2012_`vlab'_?, ///
						bylabel("2012 cohort") ///
						|| c2013_`vlab'_?, ///
						bylabel("2013 cohort") ///
						|| c2014_`vlab'_?, ///
						bylabel("2014 cohort") ///
						|| c2015_`vlab'_?, ///
						bylabel("2015 cohort") ///
						|| c2016_`vlab'_?, ///
						bylabel("2016 cohort") ///
						|| c2017_`vlab'_?, ///
						bylabel("2017 cohort") ///
						|| c2018_`vlab'_?, ///
						bylabel("2018 cohort") ///
						keep(treated_post) ///
						legend(order(1 "2 children" 3 "3 children" 5 "`legend_${max_sibs}'") col(3) pos(6)) ///
						xtitle("Standard Deviations", size(medsmall) height(5)) ///
						xlabel(-.1(0.02)0.02) ///
						xline(0, lcolor(gs12)) ///
						xline(-.1 -.08 -.06 -.04 -.02 .02, lcolor(gs15))  ///
						///xlabel(-.1 "-0.8" -.4 "-0.4" 0 "0" .4 "0.4" .8 "0.8", labsize(medsmall)) ///
						///ciopts(recast(rcap) lwidth(medium)) ///
						grid(none) ///
						///yscale(reverse) ///
						bycoefs	
				
						
				//graph save "$FIGURES\COVID\covid_twfe_`level'_`vlab'_${max_sibs}.gph" , replace	
				//capture qui graph export "$FIGURES\COVID\covid_twfe_`level'_`vlab'_${max_sibs}.eps", replace	
				capture qui graph export "$FIGURES\COVID\covid_twfe_cohort_`vlab'_${max_sibs}.png", replace	
				capture qui graph export "$FIGURES\COVID\covid_twfe_cohort_`vlab'_${max_sibs}.pdf", replace					
				
				}
				

			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & low_ses!=. , a(grade id_ie)
			estimates store alls_`vlab'_2
			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & low_ses!=.  , a(grade id_ie)
			estimates store alls_`vlab'_3
			if ${max_sibs} == 4 eststo alls_`vlab'_4: reghdfe `v' 		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & low_ses!=.  , a(grade id_ie)

			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & has_internet==0 , a(grade id_ie)
			estimates store nint_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & has_internet==0  , a(grade id_ie)
			estimates store nint_`vlab'_3
			if ${max_sibs} == 4 eststo nint_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & has_internet==0  , a(grade id_ie)

			reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & low_ses==1 , a(grade id_ie)
			estimates store lses_`vlab'_2
			reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,3)==1 & low_ses==1  , a(grade id_ie)
			estimates store lses_`vlab'_3
			if ${max_sibs} == 4 eststo lses_`vlab'_4: reghdfe `v'		treated_post post treated ${x} if inlist(fam_total_${fam_type},1,4)==1 & low_ses==1  , a(grade id_ie)

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
					legend(order(1 "2 children" 3 "3 children" 5 "`legend_${max_sibs}'") col(3) pos(6)) ///
					xlabel(-.1(0.02)0.02) ///
					///ciopts(recast(rcap) lwidth(medium)) ///
					grid(none) ///
					///yscale(reverse) ///
					bycoefs
					
			//graph save "$FIGURES\COVID\covid_twfe_survey_`level'_`vlab'_${max_sibs}.gph" , replace	
			//capture qui graph export "$FIGURES\COVID\covid_twfe_survey_`level'_`vlab'_${max_sibs}.eps", replace	
			capture qui graph export "$FIGURES\COVID\covid_twfe_survey_`level'_`vlab'_${max_sibs}.png", replace	
			capture qui graph export "$FIGURES\COVID\covid_twfe_survey_`level'_`vlab'_${max_sibs}.pdf", replace			

			}
		}

end
	
********************************************************************************
* Event Study - GPA
********************************************************************************

capture program drop event_gpa
program define event_gpa	
	
	
colorpalette  HCL blues, selec(1 6 11) nograph
return list

local blue_1 = "`r(p1)'"
local blue_2 = "`r(p2)'"
local blue_3 = "`r(p3)'"

if ${max_sibs}==4 local legend_${max_sibs} = "4 children"
	
*- GPA Overall 
estimates clear

clear

*- Event Study


foreach level in "all" /*"elm" "sec"*/ {
	foreach young in "" /*"0" "1"*/ {
		foreach area in  "all" "urb" "rur"  { 
			foreach hed_parent in "all" /*"no" "yes"*/  { //none or at least one. # No change
				foreach res in "all" /*"alls"*/ "nint" /*"ncom" "lses" "nqui"*/ { //all sample with data, No internet, no computer, low ses, no quiet room
					foreach v in "std_gpa_m" "std_gpa_c" "pass_math" "pass_read"  {
						di "`v' - `area' - `hed_parent' - `level' - `res'"
						
						//if "`area'" == "urb" continue
						//if "`area'" == "rur" &  "`hed_parent'" =="no" & "`level'" == "all" & inlist("`v'","approved_first")!=1 continue
			
						global x = "$x_all"
						if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"							
						
						use `v' id_per_umc year_t_?? urban_siagie higher_ed_parent has_internet has_comp low_ses quiet_room year grade treated post treated_post  id_ie fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid", clear
						
						*- Remove early grades and years
						keep if year>=2016
						drop if grade==0
						
						*- Divide sample based on grade in 2020
						bys id_per_umc: egen grade_2020	= min(cond(year==2020,grade,.))
						
						*- Not enough pre-years
						drop if inlist(grade_2020,1,2)==1
						drop if grade_2020==3 & year<=2017 //<=2017 Would only include those who repeated..
						drop if grade_2020==4 & year<=2016 //<=2016 Would only include those who repeated..						
									
						
						if "`area'" == "rur" keep if urban_siagie == 0
						if "`area'" == "urb" keep if urban_siagie == 1
						
						if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
						if "`hed_parent'" == "yes" 	keep if higher_ed_parent == 1
						
						if "`level'" == "all" {
							keep if grade>=1 & grade<=11
							if "`young'" == "1" keep if inlist(grade_2020,3,4,5,6)==1
							if "`young'" == "0" keep if inlist(grade_2020,7,8,9,10,11)==1
							}
						if "`level'" == "elm" {
							keep if grade>=1 & grade<=6
							if "`young'" == "1" keep if inlist(grade_2020,3,4)==1
							if "`young'" == "0" keep if inlist(grade_2020,5,6)==1
							}
						if "`level'" == "sec" {
							keep if grade>=7
							if "`young'" == "1" keep if inlist(grade_2020,7,8)==1
							if "`young'" == "0" keep if inlist(grade_2020,9,10,11)==1
							}
								
						if "`res'" == "all" 		keep if 1==1
						if "`res'" == "alls" 		keep if has_internet!=.
						if "`res'" == "nint" 		keep if has_internet==0
						if "`res'" == "ncom" 		keep if has_comp==0
						if "`res'" == "lses" 		keep if low_ses==1
						if "`res'" == "nqui" 		keep if quiet_room==0
						
						if "`v'" == "std_gpa_m" {
							local vlab = "gpa_m"
							local tlab = "Standardized mathematics GPA"
						}
						
						if "`v'" == "std_gpa_c" {
							local vlab = "gpa_c"
							local tlab = "Standardized reading GPA"
						}
						
						if "`v'" == "pass_math" {
							local vlab = "pass_m"
							local tlab = "Passed mathetics"
						}						
						
						if "`v'" == "pass_read" {
							local vlab = "pass_c"
							local tlab = "Passed reading"
						}	
						
						if "`v'" == "higher_ed_parent" {
							local vlab = "hed"
							local tlab = "Has parent with higher education"
						}	
						
						//merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(`v'_*) nogen
						
						*- Event Study
						//OC vs size =2/3
						reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if fam_total_${fam_type}<=${max_sibs}, a(year grade id_ie)
						estimates store e`vlab'_`area'_`hed_parent'_`level'`young'_`res'1 //'e' for event study
						
						//OC vs size =2
						reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(year grade id_ie)
						estimates store e`vlab'_`area'_`hed_parent'_`level'`young'_`res'2
						
						//OC vs size =3
						reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,3)==1 , a(year grade id_ie)
						estimates store e`vlab'_`area'_`hed_parent'_`level'`young'_`res'3
						
						if ${max_sibs} == 4 eststo e`vlab'_`area'_`hed_parent'_`level'`young'_`res'4 :reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,4)==1 , a(year grade id_ie)
						/*
						*- TWFE 
						//OC vs size =2
						reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(year grade id_ie)
						estimates store t`vlab'_`area'_`hed_parent'_`level'_`res'2
						
						//OC vs size =3
						reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,3)==1 , a(year grade id_ie)
						estimates store t`vlab'_`area'_`hed_parent'_`level'_`res'3	
						
						if ${max_sibs} == 4 eststo t`vlab'_`area'_`hed_parent'_`level'_`res'4 :reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,4)==1 , a(year grade id_ie)
						*/
						}
						
						local drop_vars = ""
						if "`level'" == "elm" & "`young'" == "1" local drop_vars = "year_t_b5 year_t_b4 year_t_b3"
						
						coefplot 	(em_`area'_`hed_parent'_`level'`young'_`res'1, drop(year_t_b6 `drop_vars') mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
									(em_`area'_`hed_parent'_`level'`young'_`res'2, drop(year_t_b6 `drop_vars') mcolor("`blue_3'") ciopts(bcolor("`blue_3'")) lcolor("`blue_3'")) ///
									(em_`area'_`hed_parent'_`level'`young'_`res'3, drop(year_t_b6 `drop_vars') mcolor("`blue_2'") ciopts(bcolor("`blue_2'")) lcolor("`blue_2'")) ///
									(em_`area'_`hed_parent'_`level'`young'_`res'4, drop(year_t_b6 `drop_vars') mcolor("`blue_1'") ciopts(bcolor("`blue_1'")) lcolor("`blue_1'")) ///
									, ///
									omitted ///
									keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
									drop(year_t_b6 year_t_b5 year_t_b4) ///
									leg(order(1 "Children with siblings" 3 "2 children" 5 "3 children" 7 "`legend_${max_sibs}'")) ///
									coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
									yline(0,  lcolor(gs10))  ///
									ytitle("Effect") ///
									ylab(-.1(.02).04) ///
									subtitle("`tlab'") ///
									legend(pos(6) col(4))
									
					/*				
					forvalues i = 1/4 {
						coefplot 	em_`area'_`hed_parent'_`level'_`res'`i' ec_`area'_`hed_parent'_`level'_`res'`i', ///
									omitted ///
									keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
									leg(order(1 "GPA Math" 3 "GPA Comm")) ///
									coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
									yline(0,  lcolor(gs10))  ///
									ytitle("Effect") ///
									ylab(-.1(.02).04) ///
									subtitle("Panel A: GPA") ///
									legend(pos(6) col(3)) ///
									name(panel_A_GPA_`area'_`hed_parent'_`level'_`res'`i',replace)	
						*/
						//graph save "$FIGURES\COVID\covid_gpa_`vlab'_`area'_`hed_parent'_`level'`young'_`res'`i'.gph" , replace	
						//capture qui graph export "$FIGURES\COVID\covid_gpa_`vlab'_`area'_`hed_parent'_`level'`young'_`res'`i'.eps", replace	
						capture qui graph export "$FIGURES\COVID\covid_gpa_`vlab'_`area'_`hed_parent'_`level'`young'_`res'`i'.png", replace	
						capture qui graph export "$FIGURES\COVID\covid_gpa_`vlab'_`area'_`hed_parent'_`level'`young'_`res'`i'.pdf", replace	
					
					}
					estimates drop e*	
					
				}
			
			}
		}
	}

end

********************************************************************************
* Event Study - Approved
********************************************************************************

capture program drop event_approved
program define event_approved	

if ${max_sibs}==4 local legend_${max_sibs} = "4 children"	
			
estimates clear
foreach level in "all" "elm" "sec" {
	foreach area in  "all" "urb" "rur"  {
		foreach hed_parent in "no" "yes" "all" { //none or at least one
			//ds urban_siagie higher_ed_parent	
			foreach res in "all" "alls" "nint" "ncom" "lses" "nqui" { //all sample with data, No internet, no computer, low ses, no quiet room
				foreach v in  "approved" "approved_first" {
					di "`v' - `area' - `hed_parent' - `level' - `res'"
					
					//if "`area'" == "urb" continue
					//if "`area'" == "rur" &  "`hed_parent'" =="no" & "`level'" == "all" & inlist("`v'","approved_first")!=1 continue
						
					use `v' id_per_umc year_t_?? urban_siagie higher_ed_parent has_internet has_comp low_ses quiet_room year grade treated post treated_post  id_ie fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid", clear
					
					if "`area'" == "rur" keep if urban_siagie == 0
					if "`area'" == "urb" keep if urban_siagie == 1
					
					if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
					if "`hed_parent'" == "yes" 	keep if higher_ed_parent == 1
					
					if "`level'" == "all" keep if grade>=1 & grade<=11
					if "`level'" == "elm" keep if grade>=1 & grade<=6
					if "`level'" == "sec" keep if grade>=7
					
					if "`res'" == "all" 		keep if 1==1
					if "`res'" == "alls" 		keep if has_internet!=.
					if "`res'" == "nint" 		keep if has_internet==0
					if "`res'" == "ncom" 		keep if has_comp==0
					if "`res'" == "lses" 		keep if low_ses==1
					if "`res'" == "nqui" 		keep if quiet_room==0
									
					if "`v'" == "approved" 			local vlab = "pass"
					if "`v'" == "approved_first" 	local vlab = "passf"
					
					
					//merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(`v'_*) nogen
					
					//OC vs size =2/3
					reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if fam_total_${fam_type}<=${max_sibs}, a(year grade id_ie)
					estimates store e`vlab'_`area'_`hed_parent'_`level'_`res'1
					
					//OC vs size =2
					reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,2)==1 , a(year grade id_ie)
					estimates store e`vlab'_`area'_`hed_parent'_`level'_`res'2
					
					//OC vs size =3
					reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,3)==1 , a(year grade id_ie)
					estimates store e`vlab'_`area'_`hed_parent'_`level'_`res'3		
					
					if ${max_sibs} == 4 eststo e`vlab'_`area'_`hed_parent'_`level'_`res'4: reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,4)==1 , a(year grade id_ie)
					
					}
				forvalues i = 1/4 {
		
					coefplot 	epass_`area'_`hed_parent'_`level'_`res'`i' epassf_`area'_`hed_parent'_`level'_`res'`i', ///
								omitted ///
								keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
								drop(year_t_b6 year_t_b5 year_t_b4) ///
								leg(order(1 "Passed grade" 3 "Passed grade without extension")) ///
								coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016"  year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
								yline(0,  lcolor(gs10))  ///
								ytitle("Effect") ///
								subtitle("Panel B: Grade Pass Rate") ///
								legend(pos(6) col(3)) ///
								name(panel_B_PASSED_`level'_`res'`i',replace)	
					//graph save "$FIGURES\COVID\covid_approved_`area'_`hed_parent'_`level'_`res'`i'.gph" , replace	
					//capture qui graph export "$FIGURES\COVID\covid_approved_`area'_`hed_parent'_`level'_`res'`i'.eps", replace	
					capture qui graph export "$FIGURES\COVID\covid_approved_`area'_`hed_parent'_`level'_`res'`i'.png", replace			
					capture qui graph export "$FIGURES\COVID\covid_approved_`area'_`hed_parent'_`level'_`res'`i'.pdf", replace				
					}
				}	
			}
		estimates clear
		}
	}

end


********************************************************************************
* Event Study - Cohort Grade
********************************************************************************

capture program drop event_cohort_grade
program define event_cohort_grade	

	//colorpalette  HCL blues, selec(1 4 6 8 10 12) nograph
	colorpalette  HCL blues, selec(1 6 10) nograph
	return list

	local blue_1 = "`r(p1)'"
	local blue_2 = "`r(p2)'"
	local blue_3 = "`r(p3)'"
	//local blue_4 = "`r(p4)'"
	//local blue_5 = "`r(p5)'"
	//local blue_6 = "`r(p6)'"

	//colorpalette  HCL reds, selec(1 4 6 8 10 12) nograph
	colorpalette  HCL reds, selec(1 6 11) nograph
	return list

	local red_1 = "`r(p1)'"
	local red_2 = "`r(p2)'"
	local red_3 = "`r(p3)'"
	//local red_4 = "`r(p4)'"
	//local red_5 = "`r(p5)'"
	//local red_6 = "`r(p6)'"

	foreach v in "std_gpa_m" "std_gpa_c" "pass_math" "pass_read" /*"higher_ed_parent"*/ {
		foreach area in "all" "urb" "rur"  {
			foreach res in "all" /*"alls" "nint"*/ { 
				
				global x = "$x_all"
				if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"
				 
				estimates clear
				use `v' id_per_umc year_t_?? urban_siagie higher_ed_parent has_internet has_comp low_ses quiet_room year grade treated post treated_post  id_ie fam_order_${fam_type} fam_total_${fam_type} ${x_all} using "$TEMP\pre_reg_covid", clear
						
				di as result "*******************************"
				di as text "`v' - `area' - `res'"
				di as result "*******************************"
			
				drop if grade==0

				bys id_per_umc: egen year_1st 	= min(cond(grade==1,year,.))
				//bys id_per_umc: egen grade_2016	= max(cond(year==2016,grade,.))
				bys id_per_umc: egen grade_2019	= max(cond(year==2019,grade,.))

				bys id_per_umc: egen min_grade 		= min(grade)
				bys id_per_umc: egen year_min_grade = min(cond(grade==min_grade,year,.))

				//Expected grade based on first year in primary			
				gen grade_exp = year-year_1st+1 
				tab grade_exp grade

				//Expected grade based on first year and grade observed (proxy because it could've repeated before.)
				gen grade_exp_proxy = year-year_min_grade+min_grade

				*- On time variables
				gen byte on_time 		=  (grade_exp==grade)		if grade_exp!=.
				gen byte on_time_proxy 	=  (grade_exp_proxy==grade)	if grade_exp_proxy!=.
				
				drop min_grade year_min_grade grade_exp grade_exp_proxy on_time
				compress
				
				keep if year>=2015
				
				/*
				bys id_per_umc: egen year_1st 	= min(cond(grade==1,year,.))
				bys id_per_umc: egen grade_2016	= max(cond(year==2016,grade,.))
				*/
				if "`area'" == "rur" keep if urban_siagie == 0
				if "`area'" == "urb" keep if urban_siagie == 1
				
				if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
				if "`hed_parent'" == "ys" 	keep if higher_ed_parent == 1
				
				if "`level'" == "all" keep if grade>=1 & grade<=11
				if "`level'" == "elm" keep if grade>=1 & grade<=6
				if "`level'" == "sec" keep if grade>=7
				
				if "`res'" == "all" 		keep if 1==1
				if "`res'" == "alls" 		keep if has_internet!=.
				if "`res'" == "nint" 		keep if has_internet==0
				if "`res'" == "ncom" 		keep if has_comp==0
				if "`res'" == "lses" 		keep if low_ses==1
				if "`res'" == "nqui" 		keep if quiet_room==0
				
				if "`res'" != "all" 		keep if on_time_proxy==1
				
				if "`v'" == "std_gpa_m" {
					local vlab = "gpa_m"
					local tlab = "Standardized mathematics GPA"
				}
				if "`v'" == "std_gpa_c" {
					local vlab = "gpa_c"
					local tlab = "Standardized reading GPA"
				}
						
				if "`v'" == "pass_math" {
					local vlab = "pass_m"
					local tlab = "Passed mathetics"
				}						
				
				if "`v'" == "pass_read" {
					local vlab = "pass_c"
					local tlab = "Passed reading"
				}					
				if "`v'" == "higher_ed_parent" {
					local vlab = "hed"
					local tlab = "Has parent with higher education"
				}			
				
				keep `v' /*event*/ year_t_?? treated /*covariates*/ ${x} /*conditional*/ year_1st grade_2019 /*FE*/ year grade id_ie
				
				*- Results by cohort
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(year_1st,2015,2016,2017,2018) & year>=2015, a(year grade id_ie)
				estimates store c_all_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year_1st==2014 & year>=2015, a(year grade id_ie)
				estimates store c_2014_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year_1st==2015 & year>=2015, a(year grade id_ie)
				estimates store c_2015_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year_1st==2016 & year>=2016, a(year grade id_ie)
				estimates store c_2016_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year_1st==2017 & year>=2017, a(year grade id_ie)
				estimates store c_2017_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year_1st==2018 & year>=2018, a(year grade id_ie)
				estimates store c_2018_`res'_`area'_`vlab'
				
				
				local add_coef = ""
				//if "`res'" == "all" local add_coef = `"(c_2017*, drop(year_t_b6 year_t_b5 year_t_b4) mcolor("`blue_4'") ciopts(bcolor("`blue_4'")))"'
				
				if "`res'" == "all" {
				coefplot 	(c_all*, 													mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
							///(c_2013*, drop(year_t_b6) 									mcolor("`blue_1'") ciopts(bcolor("`blue_1'"))) ///
							(c_2014*, drop(year_t_b6)									mcolor("`blue_2'") ciopts(bcolor("`blue_2'")) lcolor("`blue_2'")) ///
							(c_2015*, drop(year_t_b6)									mcolor("`blue_3'") ciopts(bcolor("`blue_3'")) lcolor("`blue_3'")) ///
							(c_2016*, drop(year_t_b6 year_t_b5)							mcolor("`red_3'") ciopts(bcolor("`red_3'")) lcolor("`red_3'")) ///
							(c_2017*, drop(year_t_b6 year_t_b5 year_t_b4) 				mcolor("`red_2'") ciopts(bcolor("`red_2'")) lcolor("`red_2'")) /// 2007 not included for survey sample since that cohort wouldn't be surveyed in 2nd or 4th grade.
							(c_2018*, drop(year_t_b6 year_t_b5 year_t_b4 year_t_b3) 	mcolor("`red_1'") ciopts(bcolor("`red_1'")) lcolor("`red_1'")), ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							leg(order(1 "All" 3 "2014" 5 "2015" 7 "2016" 9 "2017" 11 "2018")) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							subtitle("`tlab' by year in 1st grade") ///
							legend(pos(6) col(6)) ///
							name(check_cohorts,replace)	
					}
					
				if "`res'" != "all" {
				coefplot 	(c_all*, 													mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
							///(c_2013*, drop(year_t_b6) 									mcolor("`blue_1'") ciopts(bcolor("`blue_1'"))) ///
							(c_2014*, drop(year_t_b6)									mcolor("`blue_2'") ciopts(bcolor("`blue_2'")) lcolor("`blue_2'")) ///
							(c_2015*, drop(year_t_b6)									mcolor("`blue_3'") ciopts(bcolor("`blue_3'")) lcolor("`blue_3'")) ///
							(c_2016*, drop(year_t_b6 year_t_b5)							mcolor("`red_3'") ciopts(bcolor("`red_3'")) lcolor("`red_3'")) ///
							(c_2018*, drop(year_t_b6 year_t_b5 year_t_b4 year_t_b3) 	mcolor("`red_1'") ciopts(bcolor("`red_1'")) lcolor("`red_1'")) ///
							, ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							leg(order(1 "All" 3 "2014" 5 "2015" 7 "2016" 9 "2018")) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							subtitle("`tlab' by year in 1st grade") ///
							legend(pos(6) col(6)) ///
							name(check_cohorts,replace)	
					}				
							
				capture qui graph export "$FIGURES\COVID\covid_cohort_`res'_`area'_`v'.png", replace				
						
				coefplot 	(c_all*, 													mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
							, ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							subtitle("`tlab'") ///
							legend(off) 		
							
				capture qui graph export "$FIGURES\COVID\covid_cohort_full_`res'_`area'_`v'.png", replace				
						
							
				*- Results by grade in 2016
				//reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(grade_2016,1,2,3,4,5), a(year grade id_ie)
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(grade_2019,2,4,5,6,7), a(year grade id_ie)
				estimates store g_all_`res'_`area'_`vlab'
					
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==2 & year>=2018, a(year grade id_ie)
				estimates store g_2_`res'_`area'_`vlab'
				
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==4 & year>=2016, a(year grade id_ie)
				estimates store g_4_`res'_`area'_`vlab'

				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==5, a(year grade id_ie)
				estimates store g_5_`res'_`area'_`vlab'

				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==6, a(year grade id_ie)
				estimates store g_6_`res'_`area'_`vlab'

				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==7, a(year grade id_ie)
				estimates store g_7_`res'_`area'_`vlab'
				/*
				if "`res'" == "all" {
					reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2016==5, a(year grade id_ie)
					estimates store g_5_`res'_`area'_`vlab'				
					}
				*/
				coefplot 	(g_all*,												mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
							(g_2_*, drop(year_t_b6 year_t_b5 year_t_b4 year_t_b3)	mcolor("`red_1'") ciopts(bcolor("`red_1'")) lcolor("`red_1'")) ///
							(g_4_*, drop(year_t_b6 year_t_b5)						mcolor("`red_3'") ciopts(bcolor("`red_3'")) lcolor("`red_3'")) ///
							(g_5_*, drop(year_t_b6)									mcolor("`blue_3'") ciopts(bcolor("`blue_3'")) lcolor("`blue_3'")) ///
							(g_6_*,													mcolor("`blue_2'") ciopts(bcolor("`blue_2'")) lcolor("`blue_2'")) ///
							(g_7_*,													mcolor("`blue_1'") ciopts(bcolor("`blue_1'")) lcolor("`blue_1'")) ///
							, ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							leg(order(1 "All" 3 "2nd" 5 "4th" 7 "5th" 9 "6th" 11 "7th" /*11 "5th"*/)) ///
							/// leg(order(1 "All" 3 "1st" 5 "2nd" 7 "3rd" 9 "4th" /*11 "5th"*/)) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							subtitle("`tlab' by grade in 2019") ///
							legend(pos(6) col(6)) ///
							name(check_cohorts,replace)		
							
				capture qui graph export "$FIGURES\COVID\covid_grade_`res'_`area'_`v'.png", replace	
				
				coefplot 	(g_all*, 													mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
							, ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							subtitle("`tlab'") ///
							legend(off) 		
							
				capture qui graph export "$FIGURES\COVID\covid_grade_full_`res'_`area'_`v'.png", replace					
				
				
				reghdfe `v' 			year_t_b6 year_t_b5 year_t_b4 year_t_b3 o.year_t_b2 year_t_o1 year_t_a?  treated ${x} if inlist(grade_2019,2,4,5,6,7), a(year grade id_ie)
				estimates store test
				
							coefplot 	(test, mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)), ///
							omitted ///
							keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
							drop(year_t_b6) ///
							coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
							yline(0,  lcolor(gs10))  ///
							ytitle("Effect") ///
							ylab(-.1(.02).04) ///
							subtitle("`tlab' by grade in 2019") ///
							legend(pos(6) col(6))
							
				capture qui graph export "$FIGURES\COVID\test_grade_`res'_`area'_`v'.png", replace	
				
			}
		}
	}	

end


************************************************************************************







main
