
*- We get university-student average scores considering first applications to each university

preserve
	*-- First semester applied in each university
	bys id_per_umc codigo_modular (year semester): 	keep if semester==semester[1]
	bys id_per_umc codigo_modular: 					keep if _n==1

	
	
restore	

*- We get university-student average scores considering first applications overall

preserve
	*-- First semester applied
	bys id_per_umc (year semester): keep if semester==semester[1]

	
	*-- Keep one observation per student
	bys id_per_umc: 			keep if _n==1
	keep id_per_umc N_applications score_std_major_avg score_std_department_avg  
	save "$TEMP\application_info_students", replace	
restore	



* applied semester
		*- Database of # of applications total
		*Total applications overall and average score in first take
		preserve
			keep id_per_umc year semester codigo_modular score_std_department score_std_major
			bys id_per_umc:					gen N_applications = _N
			bys id_per_umc year semester: egen score_std_major_avg = mean(score_std_major)
			bys id_per_umc year semester: egen score_std_department_avg = mean(score_std_department)
			
			bys id_per_umc (year semester): keep if semester==semester[1]
			bys id_per_umc: 			keep if _n==1
			keep id_per_umc N_applications score_std_major_avg score_std_department_avg  
			save "$TEMP\application_info_students", replace
		restore
	
		*Average score in first take on each college
		preserve
			bys id_per_umc codigo_modular year semester: egen score_std_major_uni_avg = mean(score_std_major)
			bys id_per_umc codigo_modular year semester: egen score_std_department_uni_avg = mean(score_std_department)		
		
			bys id_per_umc codigo_modular (year semester): keep if semester==semester[1]
			bys id_per_umc codigo_modular: 			keep if _n==1
			
			//In order to get 'other schools average' we then get sum of scores and # of scores so that we can substract target
			
			*- All other schools
			bys id_per_umc: egen tot_score_std_major_avg 		= sum(score_std_major_uni_avg)
			bys id_per_umc: egen tot_score_std_department_avg 	= sum(score_std_department_uni_avg)
			
			bys id_per_umc: egen num_score_std_major_avg 		= count(score_std_major_uni_avg)
			bys id_per_umc: egen num_score_std_department_avg 	= count(score_std_department_uni_avg)
			
			gen score_std_major_uni_o_avg = (tot_score_std_major_avg-score_std_major_uni_avg)/(num_score_std_major_avg-1) if score_std_major_uni_avg!=.
			replace score_std_major_uni_o_avg = (tot_score_std_major_avg)/(num_score_std_major_avg) if score_std_major_uni_avg==.
			
			gen score_std_department_uni_o_avg = (tot_score_std_department_avg-score_std_department_uni_avg)/(num_score_std_department_avg-1) if score_std_department_uni_avg!=. 
			replace score_std_department_uni_o_avg = (tot_score_std_department_avg)/(num_score_std_department_avg) if score_std_department_uni_avg==.	
			
			drop tot* num*
			
						
			*- All other public schools
			bys id_per_umc: egen tot_score_std_major_pub_avg 		= sum(score_std_major_uni_avg*(public==1))
			bys id_per_umc: egen tot_score_std_department_pub_avg 	= sum(score_std_department_uni_avg*(public==1))
			
			bys id_per_umc: egen num_score_std_major_pub_avg 		= sum((score_std_major_uni_avg!=.)*(public==1)) //Count non missing public scores
			bys id_per_umc: egen num_score_std_department_pub_avg 	= sum((score_std_department_uni_avg!=.)*(public==1)) //Count non missing public scores
			
			gen score_std_major_pub_o_avg = (tot_score_std_major_pub_avg-score_std_major_uni_avg)/(num_score_std_major_pub_avg-1) if score_std_major_uni_avg!=. & public==1
			replace score_std_major_pub_o_avg = (tot_score_std_major_pub_avg)/(num_score_std_major_pub_avg) if score_std_major_uni_avg==. | public==0
			//replace score_std_major_pub_o_avg = . if num_score_std_major_uni_avg
			//make missing those 0s? why 0?
			gen score_std_department_pub_o_avg = (tot_score_std_department_pub_avg-score_std_department_uni_avg)/(num_score_std_department_pub_avg-1) if score_std_department_uni_avg!=. & public==1
			replace score_std_department_pub_o_avg = (tot_score_std_department_pub_avg)/(num_score_std_department_pub_avg) if score_std_department_uni_avg==.	 | public==0
			
			sort id_per_umc codigo_modular 
			keep id_per_umc codigo_modular score_std_major_uni_avg score_std_department_uni_avg public *uni_o_* *pub_o_* tot* num*
			save "$TEMP\application_info_university_students", replace
		restore