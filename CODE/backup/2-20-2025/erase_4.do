open

***************
*- Overall # of applications per student
***************
preserve
	keep id_per_umc codigo_modular
	
	*-- Total applications per student-uni
	bys id_per_umc codigo_modular:					gen N_applications_uni = _N
	bys id_per_umc codigo_modular: keep if _n==1
	keep id_per_umc codigo_modular N_applications_uni
	save "$TEMP\total_applications_student-uni", replace
restore

preserve
	keep id_per_umc codigo_modular year semester
	*-- Total applications		
	bys id_per_umc:					gen N_applications = _N
	
	*-- Total applications first semester		
	bys id_per_umc year semester: gen N_applications_semester = _N	

	bys id_per_umc year semester: keep if _n==1	
	rename N_applications_semester N_applications_first
	keep id_per_umc codigo_modular N_applications N_applications_first
	save "$TEMP\total_applications_student=", replace
restore

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
		bys id_per_umc codigo_modular: egen score_std_department_uni = mean(score_std_department) 
		bys id_per_umc codigo_modular: keep if _n==1
		//This will be used as the same score in 'target college'	
		
		foreach cutoff_level in "major" "department" {		
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
		keep id_per_umc codigo_modular public tot* num*
		foreach cutoff_level in "major" "department" {	
			gen score_std_`cutoff_level'_uni_o 	= (tot_score_std_`cutoff_level')			/	(num_score_std_`cutoff_level') 
			gen score_std_`cutoff_level'_pub_o 	= (tot_score_std_`cutoff_level'_pub)		/	(num_score_std_`cutoff_level'_pub)
		}
		keep id_per_umc codigo_modular public score_std_*_uni* score_std_*_pub*  tot* num*
		order id_per_umc codigo_modular public score_std_*_uni* score_std_*_pub*  tot* num*
		save "$TEMP\application_info_`period_sample'_student", replace		
	restore	
}
	
	