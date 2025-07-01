use "$TEMP\graduated", clear
bys id_persona_rec codigo_modular facultad major_inei_code semester_first_enrolled: keep if _N==1
//There's few cases of multiple graduations with same id_persona_rec. keep one (first uni enrolled)
keep id_per_umc id_persona_rec year  codigo_modular facultad major_inei_code semester_admitted semester_first_enrolled semester_graduated duracion_carrera score_std_uni
rename score_std_uni score_std_uni_grad
tempfile graduated_unique_rec
save `graduated_unique_rec', replace

*- We construct a database of enrollment (for individual and peer outcomes) and attach other variables
/*
We are interested in having all students first:
1. We then keep incoming (first semester)
2. We choose 1 observation per student to attach outcomes.
*/
use "$TEMP\enrolled", clear
keep id_persona_rec id_per_umc public year semester  codigo_modular facultad major_inei_code semester_first_enrolled semester_admitted score_std_uni n_credits type_in_person

*We keep the first semester observed  (major changes still keep same value of 'semester_first_enrolled' in many cases so those would be excluded)
keep if semester==semester_first_enrolled

*If multiple observations, we keep the one with more credits (most duplicates have 0 credits)
bys id_persona_rec codigo_modular facultad major_inei_code semester_first_enrolled (n_credits): keep if n_credits==n_credits[_N]

*We keep the ID of first semester of specific
//bys id_persona_rec codigo_modular facultad major_inei_code semester_first_enrolled (semester): keep if _n==_N //Last observation to estimate years studying
//rename semester semester_last_obs
//rename year year_last_obs

*- Attach graduation
merge 1:1 id_persona_rec codigo_modular facultad major_inei_code semester_first_enrolled using `graduated_unique_rec', keep(master match)
drop _m
**## Not all match, why?

*- Create graduation outcomes
gen year_first = substr(semester_first_enrolled,1,4)
gen term_first = substr(semester_first_enrolled,6,1)
gen year_grad = substr(semester_graduated,1,4)
gen term_grad = substr(semester_graduated,6,1)
destring year_first term_first year_grad term_grad, replace

gen years_to_grad_uni = year_grad-year_first
replace years_to_grad_uni = years_to_grad_uni + 0.5 if (term_first==1 & term_grad==2)
replace years_to_grad_uni = years_to_grad_uni - 0.5 if (term_first==2 & term_grad==1)

gen grad_uni_ever = 0 
replace grad_uni_ever = (years_to_grad_uni>0) if years_to_grad_uni!=. 

gen grad_uni_5 = 0 
replace grad_uni_5 = (years_to_grad_uni>0 & years_to_grad_uni<=5) if years_to_grad_uni!=. 

gen grad_uni_6 = 0 
replace grad_uni_6 = (years_to_grad_uni>0 & years_to_grad_uni<=6) if years_to_grad_uni!=. 


*- Attach ECE scores
merge m:1 id_per_umc using "$TEMP\scores_2p", keepusing(score*) keep(master match)	
rename _m m_2p
merge m:1 id_per_umc using "$TEMP\scores_4p", keepusing(score*) keep(master match)	
rename _m m_4p
merge m:1 id_per_umc using "$TEMP\scores_2s", keepusing(score*) keep(master match)	
rename _m m_2s

*- Peer Quality
preserve
	rename grad_uni* peer_grad_uni*
	rename score_*_std_?? peer_score_*_std_??
	collapse peer*, by(codigo_modular facultad major_inei_code semester_first_enrolled)
	save "$TEMP\first_uni_enrolled_peer_quality", replace	 
restore

merge m:1 codigo_modular facultad major_inei_code semester_first_enrolled using "$TEMP\first_uni_enrolled_peer_quality", keep(master match) keepusing(peer*)



isvar	/*ID*/ 			id_persona_rec id_per_umc codigo_modular facultad major_inei_code ///
		/*Uni*/			public ///
		/*SEMESTER*/	semester_first_enrolled semester_admitted semester_graduated /*semester_last_obs year_last_obs*/ year_grad score_std_uni ///
		/*IND*/			score_*std_?? score_std_uni score_std_uni_grad grad_uni_ever grad_uni_5 grad_uni_6 years_to_grad_uni duracion_carrera ///
		/*PEERS*/		peer*
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'		
		
save "$TEMP\enrollment_graduation_outcomes", replace		

*- First uni enrolled
use "$TEMP\enrollment_graduation_outcomes", clear
keep if id_per_umc != . 

*We keep first uni enrolled in (if discrepancy, we keep highest score since it seems like one enrollment was the most relevant (other possibly skipping))
bys id_per_umc (semester_first_enrolled score_std_uni): keep if semester_first_enrolled==semester_first_enrolled[1]

save "$TEMP\first_enrollment_outcomes", replace






