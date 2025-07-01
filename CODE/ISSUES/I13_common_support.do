*- ISSUE: Check common support in stacked RD

//first_stage 2 major all student main


set seed 1234
global window = 2
global mccrary_window = 2
global redo_all = 0
global test_C02 = 0

local fam_type = 2
local cell = "major"
local type = "noz"


local sem = "first"
local stack = "student_sibling"
local results = "main" 


global siblings = "oldest"
global fam_type = `fam_type'
global sem = "`sem'"
global main_cell = "`cell'"
	
use id_per_umc id_cutoff_major score_std_major cutoff_std_major rank_score_raw_major cutoff_rank_major public_foc lottery_nocutoff_major  any_sib_match admitted_foc id_fam_${fam_type} fam_total_${fam_type}* fam_order_${fam_type}* one_application first_application_sem* last_year_foc year_applied_??? exp_graduating_* applied_sib enrolled_sib applied_private_sib mccrary_pv_def_noz_major std_gpa_m_????_sib grade_????_sib last_grade_foc last_grade_sib last_year_foc last_year_sib type_admission applied_uni_sib ///
codigo_modular semester_foc year_applied_foc	major_c1_inei_code 	type_admission  using "$OUT/applied_outcomes_${fam_type}${data}.dta", clear

egen FE_cm = group(codigo_modular major_c1_inei_code)
egen FE_y = group(semester_foc)

/*
drop  *lpred* socioec* peer* score_std* std_gpa_?_????_sib mccrary*
drop *deprt* *major_full*
drop *2p* *4p* *2s*
*/
**********************
*- Additional Vars
**********************
rename *_`cell' *
rename *_`type' * 

	

*- Score relative
gen score_relative = score_std - cutoff_std
drop if score_relative==.	
keep if abs(score_relative)<${window} 
sort score_relative

*- Run the RD regression
gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=. //To avoid float issues around 0, we use the precisely integer rank scores.
gen score_relative_1			= score_relative^1
gen ABOVE_score_relative_1 	= ABOVE*score_relative_1

**********************
*- Prepare RD
**********************

*- Public schools
keep if public_foc==1

*- Exclude those without estimated cutoffs
keep if lottery_nocutoff == 0

*- Exclude those at cutoff
gen not_at_cutoff = (rank_score_raw!=cutoff_rank)		
keep if not_at_cutoff==1

*- Exclude those without sibling
drop if any_sib_match==0

*- Only those that apply once
//keep if one_application==1
	
//Covariates used
global scores_1 		= "score_relative_1"
global ABOVE_scores_1 	= "ABOVE_score_relative_1"


//drop year_applied_foc_? semester_foc_?	 term  h_*  std_gpa_?_*_*_sib  approved_*_*_sib approved_first_*_*_sib

if "`stack'" == "student" 			bys id_per_umc id_cutoff: keep if _n==1 // Use applicant database instead of applicant-sibling database
if "`stack'" == "student_sibling" 	keep if 1==1 // Use applicant-sibling database
if "`stack'" == ""					keep if 1==1 

/*
binsreg admitted_foc score_relative if abs(score_relative)<${window}, ///
	nbins(100) ///
	xline(0) ///
	ylabel(0(.2)1) ///
	ytitle("`ytitle'") ///
	xtitle("Relative Application Exam Score") ///
	xsize(5.5) ///
	ysize(5) ///
	by(ABOVE) ///
	bycolors(gs0 gs0) ///
	bysymbols(o o) ///
	legend(off)
*/	


label var year_applied_foc "Year Applied Focal"
label var year_applied_sib "Year Applied Sibling"


* Sibling sample	
if "${siblings}" == "oldest"			global if_sibs "fam_order_${fam_type} == 1"
if "${siblings}" == "oldest_placebo"	global if_sibs "fam_order_${fam_type}_sib == 1"
if "${siblings}" == "older"				global if_sibs "fam_order_${fam_type} < fam_order_${fam_type}_sib"
if "${siblings}" == "older_placebo"		global if_sibs "fam_order_${fam_type}_sib < fam_order_${fam_type}"		

keep if ${if_sibs}

* Applications sample
if "${sem}" == "one" 			global if_apps "one_application==1"
if "${sem}" == "first" 			global if_apps "first_application_sem==1"
if "${sem}" == "first_type" 	global if_apps "first_application_sem_type==1"
if "${sem}" == "first_sem_out" 	global if_apps "(last_year_foc + 1 == year_applied_foc) & term==1" 	//First semester after finishing school.
if "${sem}" == "first_year_out" global if_apps "(last_year_foc + 1 == year_applied_foc)" //First semester after finishing school.
if "${sem}" == "all" 			global if_apps "1==1"
keep if ${if_apps}

* Relative timing
global expected_grad_sib = "exp_graduating_year1_sib"
global gap_after = 0
global gap_before = 2
if inlist("${siblings}","all_placebo","oldest_placebo","older_placebo")==1 	global if_rel_app "(${expected_grad_sib}+${gap_after}<=year_applied_foc)"
if inlist("${siblings}","all","oldest","older")==1 							global if_rel_app "(${expected_grad_sib}+${gap_after}>=year_applied_foc)"
//keep if ${if_rel_app}

*- Relative potential outcome
global if_out "(${expected_grad_sib}>=2016 & ${expected_grad_sib}<=2022)"
//keep if ${if_out}
	
local t = 2
gen grade_pre`t'_sib = .
foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
			replace grade_pre`t'_sib = grade_`y'_sib if year_applied_foc-`t' == `y'
			replace grade_pre`t'_sib = . if grade_pre`t'_sib<7
		}
gen std_gpa_m_pre`t'_sib = .
foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022"  {
			replace std_gpa_m_pre`t'_sib = std_gpa_m_`y'_sib if year_applied_foc-`t' == `y'
			replace std_gpa_m_pre`t'_sib = . if grade_pre`t'_sib<7
		}
	

local t = 0
gen grade_next`t'_sib = .
foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
			replace grade_next`t'_sib = grade_`y'_sib if year_applied_foc-`t' == `y'
			replace grade_next`t'_sib = . if grade_next`t'_sib<7
		}
gen std_gpa_m_next`t'_sib = .
foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022"  {
			replace std_gpa_m_next`t'_sib = std_gpa_m_`y'_sib if year_applied_foc-`t' == `y'
			replace std_gpa_m_next`t'_sib = . if grade_next`t'_sib<7
		}
	
/*
bys id_cutoff ABOVE: gen N=_N

bys id_cutoff: egen min_score = min(score_relative)
bys id_cutoff: egen max_score = max(score_relative)
sum min_score max_score
//Why some min positive and some max negative. Why do we not have cases on both sides?
*/
/*
reghdfe admitted_foc ABOVE	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<${window}, a(id_cutoff)
gen sample = e(sample)
*/
reghdfe applied_sib 		ABOVE	score_relative_1 ABOVE_score_relative_1  if ${if_out} & abs(score_relative)<0.688 , a(id_cutoff)
reghdfe applied_sib 		ABOVE	score_relative_1 ABOVE_score_relative_1  if ${if_out} & abs(score_relative)<0.688 , a(FE_cm FE_y)
reghdfe applied_sib 		ABOVE	score_relative_1 ABOVE_score_relative_1  if ${if_out} & abs(score_relative)<0.688 , a(FE_cm)
reghdfe applied_sib 		ABOVE	score_relative_1 ABOVE_score_relative_1  if ${if_out} & abs(score_relative)<0.688 , a(FE_y)
reg applied_sib 			ABOVE	score_relative_1 ABOVE_score_relative_1  if ${if_out} & abs(score_relative)<0.688 

bys id_cutoff: egen mean_applied_sib = mean(applied_sib)

/*
reghdfe enrolled_sib 		ABOVE 	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<0.6 , a(id_cutoff)
reghdfe applied_private_sib ABOVE 	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<0.4847 , a(id_cutoff)
*/


reghdfe std_gpa_m_pre2_sib 		ABOVE	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<0.439, a(id_cutoff)
reghdfe std_gpa_m_pre2_sib 		ABOVE	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<0.439, a(FE_cm FE_y)
reghdfe std_gpa_m_pre2_sib 		ABOVE	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<0.439, a(FE_cm)
reghdfe std_gpa_m_pre2_sib 		ABOVE	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<0.439, a(FE_y)
reg 	std_gpa_m_pre2_sib 		ABOVE	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<0.439

reghdfe std_gpa_m_next0_sib 	ABOVE	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<0.439, a(id_cutoff)
reghdfe std_gpa_m_next0_sib 	ABOVE	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<0.439, a(FE_cm FE_y)
reghdfe std_gpa_m_next0_sib 	ABOVE	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<0.439, a(FE_cm)
reghdfe std_gpa_m_next0_sib 	ABOVE	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<0.439, a(FE_y)
reg 	std_gpa_m_next0_sib 	ABOVE	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<0.439

gen sample=e(sample)
keep if sample==1

bys id_cutoff: egen N_below = sum(cond(ABOVE==0,1,0))
bys id_cutoff: egen N_above = sum(cond(ABOVE==1,1,0))
list id_cutoff rank_score_raw score_std cutoff_rank cutoff_std if ABOVE==1 & N_above==1 & type_admission==1 &  score_relative >1, sep(1000)

reghdfe std_gpa_m_pre2_sib 		ABOVE	score_relative_1 ABOVE_score_relative_1  if abs(score_relative)<0.439 & N_below>5 & N_above>5, a(id_cutoff)


/*
binsreg std_gpa_m_pre2_sib score_relative if abs(score_relative)<${window} & sample==1 & year_applied_foc==2019, ///
	nbins(20) ///
	xline(0) ///
	ylabel(0(.2)1) ///
	ytitle("`ytitle'") ///
	xtitle("Relative Application Exam Score") ///
	xsize(5.5) ///
	ysize(5) ///
	by(ABOVE) ///
	bycolors(gs0 gs0) ///
	bysymbols(o o) ///
	legend(off)
*/