use "$TEMP\applied", clear
		
		isvar 			///
			/*Match ID*/ id_per_umc   ///
			/*ID*/ year id_cutoff_* codigo_modular facultad semester  ///
			/*Char UNI*/  public ///
			/*Char Indiv*/ 	dob age male	///
			/*applic info*/ major_c1_cat /*major_c1_code major_c1_name*/ major_c1_inei_code /*score_raw score_std* rank_score_raw* source issue*/	score_std_deprt* score_std_major* ///
			/*admitt info*/ major_admit_inei_code admitted ///
			/*enroll info*/ nota_promedio 
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'

		foreach v of local all_vars {
			capture confirm string variable `v'
				if _rc==0 {
					   replace `v' = trim(itrim(`v'))
				}
		}
		
		*Destring those not IDs
		ds id_per_umc, not
		local all_vars = r(varlist)
		destring `all_vars', replace
					
		compress
		
		keep if id_per_umc != .
		
	

***************
*- University-student average scores considering first applications to each university
***************

	foreach period_sample in "first" "first-uni" {
		
		preserve
			keep id_per_umc codigo_modular year semester public score_std_*
			*-- First semester applied in each university
			if "`period_sample'" == "first-uni" bys id_per_umc codigo_modular (year semester): 	keep if semester==semester[1]
			*-- First semester applied (still data at student-uni level, just keeping those from first semester only)
			if "`period_sample'" == "first" 	bys id_per_umc (year semester): 				keep if semester==semester[1]
			
			*- In case there are multiple applications within each cell (student-uni) we average them
			bys id_per_umc codigo_modular: egen score_std_major_uni = mean(score_std_major) 
			bys id_per_umc codigo_modular: egen score_std_deprt_uni = mean(score_std_deprt)  
			bys id_per_umc codigo_modular: egen score_std_major_full_uni = mean(score_std_major_full)  
			bys id_per_umc codigo_modular: egen score_std_deprt_full_uni = mean(score_std_deprt_full) 
			bys id_per_umc codigo_modular: keep if _n==1
			//This will be used as the same score in 'target college'	
			
			foreach cutoff_level in "major" "deprt" "major_full" "deprt_full" {		
				*- We scores for other (non-target) colleges.
				//Total sum and # of scores to 'all colleges' and 'all public colleges'
				bys id_per_umc: egen tot_score_std_`cutoff_level' 			= sum(score_std_`cutoff_level'_uni)
				bys id_per_umc: egen num_score_std_`cutoff_level' 			= sum((score_std_`cutoff_level'_uni!=.))
				bys id_per_umc: egen tot_score_std_`cutoff_level'_pub 		= sum(score_std_`cutoff_level'_uni*(public==1))
				bys id_per_umc: egen num_score_std_`cutoff_level'_pub 		= sum((score_std_`cutoff_level'_uni!=.)*(public==1)) 
				
				//We get the average excluding target.
				gen score_std_`cutoff_level'_uni_o 		= (tot_score_std_`cutoff_level'	-	score_std_`cutoff_level'_uni)	/	(num_score_std_`cutoff_level'	-	1) 		if score_std_`cutoff_level'_uni!=.
				replace score_std_`cutoff_level'_uni_o 	= (tot_score_std_`cutoff_level')		/	(num_score_std_`cutoff_level') if score_std_`cutoff_level'_uni==.
				gen score_std_`cutoff_level'_pub_o 		= (tot_score_std_`cutoff_level'_pub	-	score_std_`cutoff_level'_uni)	/	(num_score_std_`cutoff_level'_pub	-	1) 		if score_std_`cutoff_level'_uni!=. & public==1
				replace score_std_`cutoff_level'_pub_o 	= (tot_score_std_`cutoff_level'_pub)		/	(num_score_std_`cutoff_level'_pub) if score_std_`cutoff_level'_uni==. | public==0
			}
			
			*-- Keep one observation per student-university
			bys id_per_umc codigo_modular: 			keep if _n==1
			keep id_per_umc codigo_modular public score_std_*_uni* score_std_*_pub* tot* num*
			order id_per_umc codigo_modular public score_std_*_uni* score_std_*_pub*  tot* num*
			save "$TEMP\application_info_`period_sample'_student-uni", replace	
			
			*-- In order to have an average of 'other universities' for universities that the student does not apply, we also estimate the overall average and get a student level database
			bys id_per_umc: keep if _n==1
			keep id_per_umc public tot* num*
			foreach cutoff_level in "major" "deprt" "major_full" "deprt_full" {	
				gen score_std_`cutoff_level'_all 	= (tot_score_std_`cutoff_level')			/	(num_score_std_`cutoff_level') 
				gen score_std_`cutoff_level'_pub 	= (tot_score_std_`cutoff_level'_pub)		/	(num_score_std_`cutoff_level'_pub)
			}
			keep id_per_umc public score_std_*_all score_std_*_pub  tot* num*
			order id_per_umc public score_std_*_all score_std_*_pub  tot* num*
			save "$TEMP\application_info_`period_sample'_student", replace		
		restore	
	}	
		