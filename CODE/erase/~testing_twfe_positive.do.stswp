
local v = "std_gpa_m_adj"
local only_covid = "20-21"
local level = "elm"

			if ${covid_test} == 1 & inlist("`v'","std_gpa_m_adj","pass_math")==0 	continue
			if ${covid_test} == 1 & inlist("`level'","sec")==1 						continue
			if ${covid_test} == 1 & inlist("`only_covid'","all")==1 				continue
			if inlist("`v'","std_gpa_c_adj","pass_read")==1 & "`level'"!="elm" 		continue //until final version, not needed.
			if inlist("`v'","std_gpa_c_adj","pass_read")==1 & "`only_covid'"!="all" continue //until final version, not needed.
			if inlist("`v'","prim_on_time")==1 				& "`only_covid'"=="all" continue //testing for now so no need to do it all
			
			if ${main_outcomes} == 1 & inlist("`v'","${main_outcome_1}","${main_outcome_2}","${main_outcome_3}")!=1				continue
			
			estimates clear
				global x = "$x_all"
				if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"	
				
				use ///
				/*OUTCOME*/		`v'  ///
				/*ID*/ 			id_ie id_per_umc year grade ///
				/*FAMILY*/		fam_order_${fam_type} fam_total_${fam_type} ///
				/*DID*/			treated post treated_post ///
				/*EVENT*/		year_t_?? ///
				/*Demog*/		public_siagie urban_siagie male_siagie  ${x} ///
				/*A*/ 			min_socioec_index_ie_cat quart_class_size quart_grade_size /*OTHER IN DEMOG*/ ///
				/*B*/			/*GRADE AND MALE*/ ///
				/*C*/			///closest_age_gap* ///
				/*D*/			educ_cat_mother /*higher_ed_parent*/ lives_with_mother lives_with_father ///
				/*Other*/		/**has_internet *has_comp *low_ses *quiet_room*/ ///
				using "$TEMP\pre_reg_covid${covid_data}", clear
				
				*- School has internet
				merge m:1 id_ie using "$TEMP\school_internet", keepusing(codlocal internet) keep(master match)
				
				if "`type'"=="internet" {
					drop treated treated_post
					gen treated = internet==1
					gen treated_post = treated*post
					local lab_control = "No Internet"
					local lab_treated = "Internet"
				}	

				if "`type'"=="parent_ed" {
					drop treated treated_post
					gen treated = (educ_cat_mother==3)
					gen treated_post = treated*post
					local lab_control = "Mother no higher ed."
					local lab_treated = "Mother some higher ed."
				}

				if "`type'"=="both_parents" {
					drop treated treated_post
					gen treated = (lives_with_mother==1 & lives_with_father==1)
					gen treated_post = treated*post
					local lab_control = "Does not live with both"
					local lab_treated = "Lives with both parents"
				}						
					
				*- Remove early grades and years
				keep if year>=2016
				drop if grade==0
				
				*- Keep only 2020-2021 (exclude 2022,2023,2024) from the TWFE estimates
				if "`only_covid'" == "20-21" keep if year<=2021
				
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

				if "`v'" == "std_gpa_m" 		local vlab = "gpa_m"
				if "`v'" == "std_gpa_c" 		local vlab = "gpa_c"
				if "`v'" == "std_gpa_m_adj" 	local vlab = "gpa_m_adj"
				if "`v'" == "std_gpa_c_adj" 	local vlab = "gpa_c_adj"				
				if "`v'" == "pass_math" 		local vlab = "pass_m"				
				if "`v'" == "pass_read" 		local vlab = "pass_c"				
				if "`v'" == "approved" 			local vlab = "pass"
				if "`v'" == "approved_first" 	local vlab = "passf"
		
				* All students
				reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 , a(grade id_ie)
				estimates store twfe_wrong
				
				compress
				save "$TEMP\test_wrong", replace
				
				

								
local only_covid = "20-21"
local level = "elm"
local young = ""
local area = "all"
local lives_both_parents = "all"
local hed = "all" 
local res = "all"
local v = "std_gpa_m_adj"



							if ${covid_test} == 1 & inlist("`v'","std_gpa_m_adj","pass_math")==0 	continue
							if ${covid_test} == 1 & inlist("`level'","sec")==1 						continue
							if ${covid_test} == 1 & inlist("`only_covid'","all")==1 				continue
							if inlist("`v'","std_gpa_c_adj","pass_read")==1 & "`level'"!="elm" 		continue //until final version, not needed.
							if inlist("`v'","std_gpa_c_adj","pass_read")==1 & "`only_covid'"!="all" continue //until final version, not needed.
							if inlist("`v'","prim_on_time")==1 				& "`only_covid'"=="all" continue //testing for now so no need to do it all								
							
				
							global x = "$x_all"
							if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"							
							
							use `v' id_per_umc year_t_?? urban_siagie higher_ed_parent lives_with_mother lives_with_father *has_internet *has_comp *low_ses *quiet_room year grade treated post treated_post  id_ie fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid${covid_data}", clear
										
							*- Remove early grades and years
							keep if year>=2016
							drop if grade==0
							
							*- Keep only 2020-2021 (exclude 2022,2023,2024) from the TWFE estimates
							if "`only_covid'" == "20-21" keep if year<=2021		

							*- Divide sample based on grade in 2020
							//bys id_per_umc: egen grade_2020	= min(cond(year==2020,grade,.))
							
							*- Not enough pre-years
							//drop if inlist(grade_2020,1,2)==1
							//drop if grade_2020==3 & year<=2017 //<=2017 Would only include those who repeated..
							//drop if grade_2020==4 & year<=2016 //<=2016 Would only include those who repeated..						
										
							
							if "`area'" == "rur" keep if urban_siagie == 0
							if "`area'" == "urb" keep if urban_siagie == 1
							
							if "`hed'" == "no" 	keep if higher_ed_parent == 0
							if "`hed'" == "yes" 	keep if higher_ed_parent == 1
										
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
											
							if "`lives_both_parents'" == "both" {
								keep if lives_with_mother==1 & lives_with_father==1
							}
							
							if "`lives_both_parents'" == "notboth" {
								keep if (lives_with_mother==1 & lives_with_father==0) | (lives_with_mother==0 & lives_with_father==1) | (lives_with_mother==0 & lives_with_father==0)
								//Some missing cases will be excluded so yes/no dont add up to all
							}							
									
							if "`res'" == "all" 		keep if 1==1
							if "`res'" == "alls" 		keep if has_internet!=.
							if "`res'" == "nint" 		keep if has_internet==0
							if "`res'" == "ncom" 		keep if has_comp==0
							if "`res'" == "lses" 		keep if low_ses==1
							if "`res'" == "nqui" 		keep if quiet_room==0
							
							if "`v'" == "std_gpa_m" {
								local vlab = "gm"
								local tlab = "Standardized mathematics GPA"
							}
							
							if "`v'" == "std_gpa_c" {
								local vlab = "gc"
								local tlab = "Standardized reading GPA"
							}
							
							if "`v'" == "std_gpa_m_adj" {
								local vlab = "am"
								local tlab = "Standardized mathematics GPA (adj)"
							}
							
							if "`v'" == "std_gpa_c_adj" {
								local vlab = "ac"
								local tlab = "Standardized reading GPA (adj)"
							}							
							
							if "`v'" == "pass_math" {
								local vlab = "pm"
								local tlab = "Passed mathematics"
							}						
							
							if "`v'" == "pass_read" {
								local vlab = "pc"
								local tlab = "Passed reading"
							}	
							
							if "`v'" == "higher_ed_parent" {
								local vlab = "he"
								local tlab = "Has parent with higher education"
							}	
							
							local level_lab = ""
							if "`level'" == "elm" local level_lab = "p"
							if "`level'" == "sec" local level_lab = "s"
							
							local area_lab = ""
							if "`area'" == "urb" local area_lab = "u"
							if "`area'" == "rur" local area_lab = "r"
							
							local lives_lab = ""
							if "`lives_both_parents'" == "both" local lives_lab = "b"
							if "`lives_both_parents'" == "notboth" local lives_lab = "n"
							
							local hed_lab = ""
							if "`hed'" == "hed" 	local hed_lab = "h"
							if "`hed'" == "nhed" local hed_lab = "n"
							
							local res_lab = ""
							if "`res'" == "alls" local res_lab = "s"
							if "`res'" == "nint" local res_lab = "i"
							if "`res'" == "ncom" local res_lab = "c"
							if "`res'" == "lses" local res_lab = "l"
							if "`res'" == "nqui" local res_lab = "q"
							//merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(`v'_*) nogen
							
							*- Event Study
							//OC vs size =2/3

							
							//OC vs size =2
							reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 , a(year grade id_ie)
							estimates store event_orig
							reghdfe `v' 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2,3,4)==1 , a(grade id_ie)
							estimates store twfe_correct				
							
							compress
							save "$TEMP\test_right", replace
							
							
							
							*- Event Study 
	//event_gpa
	
	//twfe_placebo_grades parent_ed
	//twfe_placebo_grades both_parents	
	
	
	
	
	
	estimates replay event_orig
	estimates replay twfe_correct
	estimates replay twfe_wrong
	
	
	use "$TEMP\test_right", clear
	count
	tab grade year
	use "$TEMP\test_wrong", clear
	count
	tab grade year
	
							
							
							