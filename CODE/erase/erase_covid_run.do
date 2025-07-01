*- Only child and siblings in COVID
global fam_type=2

use   "$TEMP\siagie_append", clear

keep id_per_umc year region_siagie public_siagie urban_siagie id_ie level grade male_siagie approved approved_first std_gpa_m std_gpa_c

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
merge m:1 id_estudiante_2p year using "$TEMP\ece_family_2p", keep(master match) keepusing(aspiration_2p) //m:1 because there are missings
rename _m merge_ece_survey_2p

merge m:1 id_estudiante_4p year using "$TEMP\ece_family_4p", keep(master match) keepusing(aspiration_4p gender_subj_?_4p) //m:1 because there are missings
rename _m merge_ece_survey_4p

merge m:1 id_estudiante_2s year using "$TEMP\ece_student_2s", keep(master match) keepusing(aspiration_2s lives_with_*_2s total_siblings_2s) //m:1 because there are missings
rename _m merge_ece_survey_2s
	
	
drop id_estudiante_2p source_2p merge_2p id_estudiante_4p source_4p merge_4p id_estudiante_2s source_2s merge_2s merge_ece_2p merge_ece_4p merge_ece_2s merge_m_2p merge_m_4p merge_m_2s merge_ece_survey_2p merge_ece_survey_4p merge_ece_survey_2s


*- Define additional outcomes:
foreach g in "2p" "4p" "2s" {
	gen satisf_m_`g' = label_m_`g'==4 if label_m_`g'!=.
	gen satisf_c_`g' = label_c_`g'==4 if label_c_`g'!=.
	}

describe
compress

save "$TEMP\long_siagie_ece", replace



*- Check how many years of data each school has (to use comparable samples)
use id_ie year grade score_*_std_?? approved approved_first std_gpa_?  using "$TEMP\long_siagie_ece", clear

	collapse score_*_std_?? approved approved_first std_gpa_?, by(id_ie year)

	foreach v of var score_*_std_?? approved approved_first std_gpa_? {
		bys id_ie: egen  `v'_min =  min(cond( `v'!=.,year,.))
		bys id_ie: egen  `v'_max =  max(cond( `v'!=.,year,.))
		bys id_ie: egen  `v'_sum =  sum(cond( `v'!=.,1,0))
		}
		
	collapse *min *max *sum, by(id_ie)
	
	compress
	
save "$TEMP\siagie_ece_ie_obs", replace	


*- Create Event Study vars	
use id_per_umc id_ie grade year male_siagie urban_siagie educ_mother educ_father socioec* approved* std* score* satisf* fam_order_${fam_type} fam_total_${fam_type} base* year_2p using "$TEMP\long_siagie_ece", clear

	keep if fam_total_${fam_type}<=3

	gen treated = fam_total_${fam_type}>1
	gen post = year>=2020
	gen treated_post = treated*post
	
	gen byte higher_ed_mother 		= inlist(educ_mother,7,8) if educ_mother!=. & educ_mother!=1
	gen byte higher_ed_father 		= inlist(educ_father,7,8) if educ_father!=. & educ_father!=1
	drop educ_mother educ_father
	gen byte higher_ed_parent		= (higher_ed_mother==1 | higher_ed_father==1) if higher_ed_mother!=. | higher_ed_father!=.
	drop higher_ed_mother higher_ed_father
	
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

use "$TEMP\pre_reg_covid", clear
clear

*---------
*- ECE
*---------

*- ECE - 2P
foreach v in "score_math_std_2p" "score_com_std_2p" "score_acad_std_2p" "satisf_m_2p" "satisf_c_2p" {
	di "`v'"
	if inlist("`v'","score_math_std_2p","satisf_m_2p")==1 	local subj = "math"
	if inlist("`v'","score_com_std_2p","satisf_c_2p")==1 	local subj = "com"
	if inlist("`v'","score_acad_std_2p")==1 				local subj = "acad"
	use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} if grade==2 using "$TEMP\pre_reg_covid", clear
	keep if inlist(year,2015,2016,2018,2019,2022,2023)==1
	merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_2p_*) nogen
	reghdfe 	`v' 	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated, a(id_ie)
	*reghdfe 	score_acad_std_2p	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated if score_acad_std_2p_max==2022 & score_acad_std_2p_sum==5 & fam_order_2==1, a(id_ie)
	estimates 	store `v'
	}

*- ECE - 4P
foreach v in "score_math_std_4p" "score_com_std_4p" "score_acad_std_4p" "satisf_m_4p" "satisf_c_4p" {
	di "`v'"
	if inlist("`v'","score_math_std_4p","satisf_m_4p")==1 	local subj = "math"
	if inlist("`v'","score_com_std_4p","satisf_c_4p")==1 	local subj = "com"
	if inlist("`v'","score_acad_std_4p")==1 				local subj = "acad"
	use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} if grade==4 using "$TEMP\pre_reg_covid", clear
	keep if inlist(year,2016,2018,2019,2022,2023)==1
	merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_4p_*) nogen
	reghdfe 	`v' 							year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3  treated, a(year id_ie)
	estimates 	store `v'		
	}	

*- ECE - 2S
foreach v in "score_math_std_2s" "score_com_std_2s" "score_acad_std_2s" "satisf_m_2s" "satisf_c_2s" {
	di "`v'"
	if inlist("`v'","score_math_std_2s","satisf_m_2s")==1 	local subj = "math"
	if inlist("`v'","score_com_std_2s","satisf_c_2s")==1 	local subj = "com"
	if inlist("`v'","score_acad_std_2s")==1 				local subj = "acad"
	use `v' year_t_?? year grade treated id_ie fam_order_${fam_type} if grade==8 using "$TEMP\pre_reg_covid", clear
	merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(score_`subj'_std_2s_*) nogen
	keep if inlist(year,2015,2016,2018,2019,2022,2023)==1
	reghdfe 	`v' 			 year_t_b5 		year_t_b4  			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3  treated, a(year id_ie)
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
	graph save "$FIGURES\COVID\covid_ece_`g'.gph" , replace	
	capture qui graph export "$FIGURES\COVID\covid_ece_`g'.eps", replace	
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
	graph save "$FIGURES\COVID\covid_ece_`g'.gph" , replace	
	capture qui graph export "$FIGURES\COVID\covid_ece_`g'.eps", replace	
	capture qui graph export "$FIGURES\COVID\covid_ece_`g'.png", replace			
	capture qui graph export "$FIGURES\COVID\covid_ece_`g'.pdf", replace		
}	
	

*---------
*-	SIAGIE
*---------	
	
*- GPA Overall 


foreach area in  "urb" "rur" "all" {
	foreach hed_parent in "no" "yes" "all" { //none or at least one
		//ds urban_siagie higher_ed_parent
		foreach level in "all" "elm" "sec" {
			foreach v in "std_gpa_m" "std_gpa_c"  {
				di "`v' - `area' - `hed_parent' - `level'"
				
				if "`area'" == "urb" continue
				if "`area'" == "rur" &  "`hed_parent'" =="no" & "`level'" == "all" & inlist("`v'","approved_first")!=1 continue
				
				
				use `v' id_per_umc year_t_?? urban_siagie higher_ed_parent year grade treated id_ie fam_order_${fam_type} using "$TEMP\pre_reg_covid", clear
				
				if "`area'" == "rur" keep if urban_siagie == 0
				if "`area'" == "urb" keep if urban_siagie == 1
				
				if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
				if "`hed_parent'" == "ys" 	keep if higher_ed_parent == 1
				
				if "`level'" == "elm" keep if grade<=6
				if "`level'" == "sec" keep if grade>=7
				
				
				merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(`v'_*) nogen
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated, a(year grade id_ie id_per_umc)
				estimates store `v'_`area'_`hed_parent'_`level'
				}
			
			coefplot 	std_gpa_m_`area'_`hed_parent'_`level' std_gpa_c_`area'_`hed_parent'_`level', ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						leg(order(1 "GPA Math" 3 "GPA Comm")) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
						yline(0,  lcolor(gs10))  ///
						ytitle("Effect") ///
						subtitle("Panel A: GPA") ///
						legend(pos(6) col(3)) ///
						name(panel_A_GPA_`area'_`hed_parent'_`level',replace)	
			graph save "$FIGURES\COVID\covid_ece_gpa_`area'_`hed_parent'_`level'.gph" , replace	
			capture qui graph export "$FIGURES\COVID\covid_ece_gpa_`area'_`hed_parent'_`level'.eps", replace	
			capture qui graph export "$FIGURES\COVID\covid_ece_gpa_`area'_`hed_parent'_`level'.png", replace	
			capture qui graph export "$FIGURES\COVID\covid_ece_gpa_`area'_`hed_parent'_`level'.pdf", replace		
	
				
			}	
		}
	}

	
			

foreach area in  "urb" "rur" "all" {
	foreach hed_parent in "no" "yes" "all" { //none or at least one
		//ds urban_siagie higher_ed_parent
		foreach level in "all" "elm" "sec" {
			foreach v in  "approved" "approved_first" {
				di "`v' - `area' - `hed_parent' - `level'"
				
				if "`area'" == "urb" continue
				if "`area'" == "rur" &  "`hed_parent'" =="no" & "`level'" == "all" & inlist("`v'","approved_first")!=1 continue
					
				use `v' id_per_umc year_t_?? urban_siagie higher_ed_parent year grade treated id_ie fam_order_${fam_type} using "$TEMP\pre_reg_covid", clear
				
				if "`area'" == "rur" keep if urban_siagie == 0
				if "`area'" == "urb" keep if urban_siagie == 1
				
				if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
				if "`hed_parent'" == "ys" 	keep if higher_ed_parent == 1
				
				if "`level'" == "elm" keep if grade<=6
				if "`level'" == "sec" keep if grade>=7
				
				
				merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(`v'_*) nogen
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated, a(year grade id_ie id_per_umc)
				estimates store `v'_`area'_`hed_parent'_`level'
				}
			coefplot 	approved_`area'_`hed_parent'_`level' approved_first_`area'_`hed_parent'_`level', ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						drop(year_t_b6 year_t_b5 year_t_b4) ///
						leg(order(1 "Passed grade" 3 "Passed grade without extension")) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016"  year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
						yline(0,  lcolor(gs10))  ///
						ytitle("Effect") ///
						subtitle("Panel B: Grade Pass Rate") ///
						legend(pos(6) col(3)) ///
						name(panel_B_PASSED_`level',replace)	
			graph save "$FIGURES\COVID\covid_ece_approved_`area'_`hed_parent'_`level'.gph" , replace	
			capture qui graph export "$FIGURES\COVID\covid_ece_approved_`area'_`hed_parent'_`level'.eps", replace	
			capture qui graph export "$FIGURES\COVID\covid_ece_approved_`area'_`hed_parent'_`level'.png", replace			
			capture qui graph export "$FIGURES\COVID\covid_ece_approved_`area'_`hed_parent'_`level'.pdf", replace				
				
			}	
		}
	}

