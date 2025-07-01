/********************************************************************************
- Author: Francisco Pardo
- Description: Create Final matched database
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/

capture program drop main 
program define main 

ece_to_match_app
data_cutoff
	
end



********************************************************************************
* Unique ID (id_persona_reco) for data in ECE. Matching with info from applicants
* 
* Description: Assign id_persona_reco to ECE database based on application (ideally the ECE data would have this directly.)
********************************************************************************

capture program drop crosswalk_id_per_pos_year_id_persona_reco
program define crosswalk_id_per_pos_year_id_persona_reco	

	use "$TEMP/applied.dta", clear 
	
	keep id_per_pos year id_persona_reco
	
	bys id_per_pos year id_persona_reco: keep if _n==1
	
	*- ID 1
	ds id_per_pos year
	
	*- ID 2
	ds id_persona_reco
	
	save "$TEMP/crosswalk_id_per_pos_year_id_persona_reco", replace

end

********************************************************************************
* ece_to_match_app
* 
* Description: Prepare examination data to be matched with applications
********************************************************************************

capture program drop ece_to_match_app
program define ece_to_match_app	

*- Examination individual information (1st take for each student)
	
	*-- 2nd grade
	use "$TEMP\ece_siagie_final", clear
	//keep if grade==2
	//keep if year <= 2016
	bys id_estudiante grade (year): keep if year==year[1] //we keep the first year in examination
	rename year year_ece
	
	*--- We put this in long format. One observation per applicant ID (to match with applicants data)
	
	keep id_estudiante cod_mod7 anexo id_per_pos* year_ece grade score_*std /*family vars*/ family_id sib_id oldest
	////
	/*
	gen u=runiform()
	bys id_estudiante: egen umax = max(u)
	keep if umax >0.999
	drop umax u 
	close
	open
	*/
	////
	reshape long id_per_pos, i(id_estudiante grade year_ece cod_mod7 anexo) j(year_pos)
	keep if id_per_pos !=.
	
	rename year_pos year
	merge m:1 id_per_pos year using "$TEMP/crosswalk_id_per_pos_year_id_persona_reco", keep(master match) //Not all from applicants took ECE, so some are _merge==2
	keep if _m==1 | _m==3
	drop _m
	rename year year_pos
	//open
	
	bys id_persona_reco (family_id): replace family_id = family_id[1]
	bys id_persona_reco (sib_id): replace sib_id = sib_id[1]
	bys id_persona_reco (oldest): replace oldest = oldest[1]
	//bys family_id (id_persona_reco): gen sibling_both = id_persona_reco[1] != id_persona_reco[_N] if family_id!=.
	
	
	*- At this point, each 'id_persona_reco', or similarly, each 'id_per_pos' + 'year' has the same family variables
	bys year_pos id_per_pos: gen diff_id = family_id[1] != family_id[_N]
	assert diff_id == 0
	drop diff_id
	
		
	////
	/*
	destring id_per_pos, replace
	*/
	////
	
	
	preserve
		duplicates tag grade year_pos id_per_pos, gen(dup)
		keep if dup>0
		sort grade year_pos id_per_pos id_estudiante
		list if dup==2, sepby(grade year_pos id_per_pos)
			/*
			 *- Some have repeated cases but different 'id_estudiante'. Isn't there a unique ECE identifier?
				 +----------------------------------------------------------------------------------------------------------------------------+
				 |       id_estudiante   grade   cod_mod7   anexo   year_pos   id_per~s   score_c~d   score_m~d   sco~c_std   sco~i_std   dup |
				 |----------------------------------------------------------------------------------------------------------------------------|
		1369888. | 2013121027118900414       2     271189       0       2023     618185     .320724   -1.353195           .           .     2 |
		1369889. | 2014121027118900411       2     271189       0       2023     618185   -1.754535   -1.191401           .           .     2 |
		1369890. | 2015121027118900215       2     271189       0       2023     618185    .1271801    .4710767           .           .     2 |
				 |----------------------------------------------------------------------------------------------------------------------------|
		2132371. | 2016221157562000112       8    1575620       0       2022     302225   -1.034107   -1.205346   -1.025204           .     2 |
		2132372. | 2018221063569800114       8     635698       0       2022     302225   -.2184894   -1.201031   -.6124293    .5208058     2 |
		2132373. | 2019221063569800123       8     635698       0       2022     302225    .0895628   -.2815654           .    .0761505     2 |
				 |----------------------------------------------------------------------------------------------------------------------------|
			
			*/
		
	restore
	
	/*
	bys id_per_pos: gen N_apps = _N
	bys year_pos id_per_pos (id_estudiante): gen diff_id = id_estudiante[1] != id_estudiante[_N]
	tab diff_id
	*/
	
	**## Temporary solution. Keep the first id_estudiante (This because there are cases of 2 different students with same application information)
	bys grade year_pos id_per_pos (id_estudiante): keep if _n==1 //We keep the first take per student
	drop id_estudiante
	keep id_per_pos id_persona_reco  cod_mod7 anexo year_pos grade year_ece score_com_std score_math_std score_soc_std score_sci_std family_id sib_id oldest
	
	reshape wide score* cod_mod7 anexo year_ece,i(id_per_pos year_pos) j(grade)
	rename *std? *std_g?
	rename cod_mod7? cod_mod7_g?
	rename anexo? anexo_g?
	rename  year_ece?  year_ece_g?
	
	foreach v of var score*std* {
		sum `v'
		if `r(N)'==0 drop `v'
	}
	
	rename year_pos year
	
	label var year 			"Year of application"

	ds id_per_pos year //with these 2 variables we match ECE information with application data
	
	save "$TEMP\ece_to_match_app", replace

end

********************************************************************************
* data_cutoff
* 
* Description: Add cutoff scores, mccrary estimates, ECE and averages to each individual
********************************************************************************

capture program drop data_cutoff
program define data_cutoff	

	
	use "$TEMP/applied.dta", clear 
	
	//keep if id_cutoff>1785  //test
	
	*- Attach cutoff information (department)
		merge m:1 id_cutoff_department using  "$TEMP/applied_cutoffs_department.dta"
		gen lottery_nocutoff_department = (cutoff_std_department==.)
		drop _merge
		
	*- Attach cutoff information (major)
		merge m:1 id_cutoff_major using  "$TEMP/applied_cutoffs_major.dta"
		gen lottery_nocutoff_major = (cutoff_std_major==.)
		drop _merge		
	
	*- Attach McCrary Tests
	/*
		merge m:1 id_cutoff using  "$TEMP/mccrary_cutoffs.dta", keep(master match)
		drop _m
		rename (mccrary_pval_def mccrary_pval_biasi mccrary_test) (mccrary_pval_def_prev mccrary_pval_biasi_prev mccrary_test_prev)
	*/
	
	
	*- Attach McCrary Tests (removing score=0) (department)
		/*
		merge m:1 id_cutoff using  "$TEMP/mccrary_cutoffs_not_at_cutoff_department.dta", keep(master match)
		drop _m
		*/
		
	*- Attach McCrary Tests (removing score=0) (major)
		merge m:1 id_cutoff_department using  "$TEMP/mccrary_cutoffs_noz_department.dta", keep(master match)
		drop _m
		
		merge m:1 id_cutoff_major using  "$TEMP/mccrary_cutoffs_noz_major.dta", keep(master match)
		drop _m
		
		
	*- For testing graph purposes
	bys id_cutoff_major: gen n=_n==1
	
			
	*- Attach Enrollment information
		preserve	
			use "$TEMP\enrolled", clear
			**## Imperfect solution. We need to figure out what makes enrollments unique.
			keep id_persona_reco universidad year id_periodo_matricula nota_promedio public/*id_per_mat**/		
			bys id_persona_reco universidad year id_periodo_matricula: keep if _n==1
			rename id_periodo_matricula id_periodo_postulacion
			
			*- Match with
			ds universidad year id_periodo_postulacion id_persona_reco
			tempfile enrolled_unique
			save `enrolled_unique', replace
			
			bys  id_persona_reco year (public): gen public_any = public[_N]
			bys  id_persona_reco year: keep if _n==1
			
			*- Match with
			ds id_persona_reco year
			tempfile enrolled_any 
			save `enrolled_any', replace
			
			bys  id_persona_reco (public): gen public_ever = public[_N]
			bys  id_persona_reco: keep if _n==1
			*- Match with
			ds id_persona_reco
			tempfile enrolled_ever 
			save `enrolled_ever', replace			
		restore
		
		merge m:1  universidad year id_periodo_postulacion id_persona_reco using `enrolled_unique', keep(master match)
		gen enrolled = (_merge==3)
		drop _merge
		
		merge m:1 id_persona_reco year using `enrolled_any', keep(master match) keepusing(public_any)
		gen enrolled_any = (_merge==3)
		drop _merge
		
		rename public_any temp
		replace year = year + 1
		merge m:1 id_persona_reco year using `enrolled_any', keep(master match) keepusing(public_any) 
		gen enrolled_any_next = (_merge==3)
		rename public_any public_any_next
		egen enrolled_any_1delay = rmax(enrolled_any enrolled_any_next)
		egen public_any_1delay = rmax(public_any public_any_next)
		drop _merge	
		replace year = year - 1
		rename temp public_any
		
		merge m:1 id_persona_reco using `enrolled_ever', keep(master match) keepusing(public_ever)
		gen enrolled_ever = (_merge==3)
		drop _merge	

	*- Attach individual examination information
	//We now have school for those who took examination
	merge m:1 id_per_pos year using "$TEMP\ece_to_match_app", keep(master match)
	drop _m
	
	*- Attach School overall information (region, characteristics)
	rename (cod_mod7_g8 anexo_g8) (cod_mod7 anexo)
	merge m:1 cod_mod7 anexo year using "$TEMP\aggregate_school", keep(master match)
	drop _m
	//We have region, public, % male, average socio_ec, etc according to 8th grade from year of application
	
	*- Attach School score average by year of application (OUTCOME)
	merge m:1 cod_mod7 anexo year using "$TEMP\aggregate_ece", keep(master match)
	drop _m
	//We 8th grade exams (these are taken in ~november? likely after application. We can also check next year.)
	
	
	*- Attach School % applications/enrollment by year of application (OUTCOME)
	merge m:1 cod_mod7 anexo year using "$TEMP\aggregate_app_enroll", keep(master match)
	drop _m
	
	*- Attach information of institution applied to from census (is it an institution from same region/district)
	//Student applied in a different region than school
	
	*- Attach School % of out-of-region application
	
			isvar 			///
				/*Match ID*/ 	///
					/*SIAGIE*/	id_persona_reco  ///
					/*APPLICATIONS DATA*/ id_per_pos /// 
					/*CUTOFFS*/ id_cutoff_department id_cutoff_major ///
					/*OTHER ID*/ year codigo_modular  /// id_codigo_facultad id_periodo_postulacion  
				/*CHOICES*/ id_major_choice1 id_major_choice2 id_major_admitted /// id_major_choice1_cat   id_carrera_homologada_primera_op
				/*INSTITUTION*/	universidad  public licensed academic		/// facultad university
				/*DEMOGRAPHIC*/	 dob age male		///
				/*APPLICATION SCORE*/ score_raw score_std_department score_std_major rank_score_raw_department rank_score_raw_major	source issue		///
				/*APPLICATION RESULT*/ admitted ///
				/*ECE OWN SCORE*/ 		score_com*g? score_math*g?			///
				/*ECE CLASS SCORE*/		score_com*g?_sch score_math*g?_sch		///
				/*CLASS COVARIATES*/ 	male*g?_sch spanish*g?_sch	socioec_index*g?_sch		///
				/*CLASS OUTCOMES*/ 	applied*sch enroll*sch		///
				/*ECE SIBLING SCORE*/			///
				/*CUTOFF INFO*/ has_cutoff_department cutoff_raw*_department cutoff_std*_department cutoff_rank*_department has_cutoff*_major cutoff_raw*_major cutoff_std*_major cutoff_rank*_major lottery* N_above* N_below* ///
				/*MCCRARY RESULTS*/ mccrary* ///
				/*ENROLLMENT INFO*/ enroll* nota_promedio public_any public_ever ///
				/*Family info*/ family_id sib_id oldest
				/**/
				/**/
				
				//
				
			local all_vars = r(varlist)
			ds `all_vars', not
			keep `all_vars'
			order `all_vars'
			destring `all_vars', replace
			
			foreach v of local all_vars {
				capture confirm string variable `v'
					if _rc==0 {
						   replace `v' = trim(itrim(`v'))
					}
			}
			
	compress 
	
	save "$TEMP/applied_matched.dta", replace 
	
end	


	/*
*- REVIEW: Why do different students share the same 'id_per_pos2017'	
       +---------------------------------------+
       | year   id~s2017         id_estudiante |
       |---------------------------------------|
11255. | 2007      73201   2007121027716000428 |
81726. | 2013     181828   2013121082040700115 |
81761. | 2014      73201   2014121022011100420 |
81804. | 2014     181828   2014121054222500103 |
       +---------------------------------------+
	*/


********************************************************************************
* Run program
********************************************************************************

main