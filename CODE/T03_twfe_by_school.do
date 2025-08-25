*- TWFE by school
setup_test

capture program drop setup_test
program define setup_test

	*- Define if test run
	global covid_test = 0
	global covid_data = ""
	if ${covid_test} == 1 global covid_data = "_TEST"
	
	*- Only analyze specific outcomes
	global main_outcomes=1
	global main_outcome_1 = "std_gpa_m_adj"
	global main_outcome_2 = "" //pass_math
	global main_outcome_3 = "" //higher_ed_parent
	
	global main_loop = 0
	global main_loop_level	= "all"
	global main_loop_only_covid = "all"

	*- Global variables
	global fam_type=2
	global max_sibs = 4
	global x_all 			= "male_siagie age_mother age_mother_1st_oldest_${fam_type} i.educ_cat_mother"
	global x_all_vars 		= "male_siagie age_mother age_mother_1st_oldest_${fam_type} educ_cat_mother"
	//global x_complete 		= "male_siagie age_mother age_mother_1st_oldest_${fam_type} i.educ_cat_mother"
	//global x_complete_vars 	= "male_siagie age_mother age_mother_1st_oldest_${fam_type} educ_cat_mother"
	global x_nohigher_ed 	= "male_siagie age_mother age_mother_1st_oldest_${fam_type}"
	
	
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

clear

	
	local v = "std_gpa_m_adj"
	local only_covid = "all"
	local level = "all"
	
					
				if ${main_outcomes} == 1 & inlist("`v'","${main_outcome_1}","${main_outcome_2}","${main_outcome_3}")!=1		continue
				if ${main_loop} 	== 1 & inlist("`level'","${main_loop_level}")!=1 										continue	
				if ${main_loop} 	== 1 & inlist("`only_covid'","${main_loop_only_covid}")!=1 								continue

				estimates clear
				global x = "$x_all"
				if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"	
				
				use ///
				/*OUTCOME*/		`v' std_gpa_m_adj std_gpa_c_adj ///
				/*ID*/ 			id_ie id_per_umc year grade ///
				/*FAMILY*/		fam_order_${fam_type} fam_total_${fam_type} ///
				/*DID*/			treated post treated_post ///
				/*EVENT*/		year_t_?? ///
				/*Demog*/		public_siagie urban_siagie male_siagie age_mother_1st_oldest_2 age_mother age_father educ_cat_mother educ_cat_father ${x_all_vars} ///
				/*A*/ 			min_socioec_index_ie_cat quart_class_size quart_grade_size /*OTHER IN DEMOG*/ ///
				/*B*/			/*GRADE AND MALE*/ ///
				/*C*/			///closest_age_gap* ///
				/*D*/			educ_cat_mother /*higher_ed_parent*/ lives_with_mother lives_with_father ///
				/*Other*/		age_mother_1st_oldest_${fam_type} /**has_internet *has_comp *low_ses *quiet_room*/ ///
				using "$TEMP\pre_reg_covid${covid_data}", clear
				
				*- School has internet
				merge m:1 id_ie using "$TEMP\school_internet", keepusing(codlocal internet) keep(master match)

				
				if "`treatment_type'"=="internet" {
					drop treated treated_post
					gen treated = internet==1
					gen treated_post = treated*post
					local lab_control = "No Internet"
					local lab_treated = "Internet"
				}	

				if "`treatment_type'"=="parent_ed" {
					drop treated treated_post
					gen treated = (educ_cat_mother==3)
					gen treated_post = treated*post
					local lab_control = "Mother no higher ed."
					local lab_treated = "Mother some higher ed."
				}

				if "`treatment_type'"=="both_parents" {
					drop treated treated_post
					gen treated = (lives_with_mother==1 & lives_with_father==1)
					gen treated_post = treated*post
					local lab_control = "Does not live with both"
					local lab_treated = "Lives with both parents"
				}	
				
				if "`subsample'" == "oldest" 	keep if fam_order_${fam_type} == 1
				if "`subsample'" == "youngest" 	keep if fam_order_${fam_type} == fam_total_${fam_type}
				if "`subsample'" == "middle" 	keep if (fam_total_${fam_type}==1 | (fam_total_${fam_type}>1 & fam_order_${fam_type}!=1 & fam_order_${fam_type}!=fam_total_${fam_type})) //famsize=1 or famsize>1 and not older or younger
				if "`subsample'" == "all" 		di "All siblings"
					
				*- Remove early grades and years
				keep if year>=2014
				drop if grade==0
				
				*- Keep only 2020-2021 (exclude 2022,2023,2024) from the TWFE estimates
				if "`only_covid'" == "20_21" keep if year<=2021
				
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
		
	
assert 1==0


				di as result "*******" _n as text "WITH CONTROLS" _n as result "*******"
				
				
				bys id_ie year: gen N_year=_N
				bys id_ie year: replace N_year=. if _n>1 
				bys id_ie: egen N_avg=mean(N_year)
				
				preserve

				restore
	
				
				compress
				
				save "$TEMP\temp_reg", replace	
				
				clear
				gen id_ie = ""
				gen b=.
				gen se=.
				gen pv=.
				gen icl95 = .
				gen icu95 = .
				gen N=.	
				gen level = .
				gen group = .
				save "$TEMP\coef_twfe_ie", replace emptyok
			
				use "$TEMP\temp_reg", clear
				local v = "std_gpa_m_adj"
				
				timer clear 1
				timer on 1
				
				levelsof id_ie if N_avg>800 				& grade>=1 & grade<=6 & inlist(year,2016,2017,2018,2019,2020,2021), local(list_ie_1)
				levelsof id_ie if N_avg>600 & N_avg<=800 	& grade>=1 & grade<=6 & inlist(year,2016,2017,2018,2019,2020,2021), local(list_ie_2)
				levelsof id_ie if N_avg>400 & N_avg<=600 	& grade>=1 & grade<=6 & inlist(year,2016,2017,2018,2019,2020,2021), local(list_ie_3)
				levelsof id_ie if N_avg>200 & N_avg<=400 	& grade>=1 & grade<=6 & inlist(year,2016,2017,2018,2019,2020,2021), local(list_ie_4)
				levelsof id_ie if N_avg>100 & N_avg<=200 	& grade>=1 & grade<=6 & inlist(year,2016,2017,2018,2019,2020,2021), local(list_ie_5)
				levelsof id_ie if N_avg>50 & N_avg<=100 	& grade>=1 & grade<=6 & inlist(year,2016,2017,2018,2019,2020,2021), local(list_ie_6)

				forvalues group = 1(1)6 {
					foreach ie of local list_ie_`group' {
						use "$TEMP\temp_reg", clear
						capture reghdfe `v' 	treated_post post treated ${x_all} if inlist(fam_total_${fam_type},1,2,3,4)==1 & inlist(year,2016,2017,2018,2019,2020,2021) & id_ie == "`ie'" , a(grade year)
						if _rc!=0 continue
						mat A = r(table)
						clear
						set obs 1
						gen id_ie 	= "`ie'"
						gen b		=	A[1,1]
						gen se		=	A[2,1]
						gen pv		=	A[4,1]
						gen icl95 	= 	A[5,1]
						gen icu95 	= 	A[6,1]
						gen N		=	e(N)
						gen level 	=   2
						gen group 	= 	`group'
						append using "$TEMP\coef_twfe_ie"
						save "$TEMP\coef_twfe_ie", replace		
					}
				}
				timer off 1
				
				timer clear 2
				timer on 2
				
				use "$TEMP\temp_reg", clear
				local v = "std_gpa_m_adj"
				
				levelsof id_ie if N_avg>800 				& grade>=7 & inlist(year,2016,2017,2018,2019,2020,2021), local(list_ie_1)
				levelsof id_ie if N_avg>600 & N_avg<=800 	& grade>=7 & inlist(year,2016,2017,2018,2019,2020,2021), local(list_ie_2)
				levelsof id_ie if N_avg>400 & N_avg<=600 	& grade>=7 & inlist(year,2016,2017,2018,2019,2020,2021), local(list_ie_3)
				levelsof id_ie if N_avg>200 & N_avg<=400 	& grade>=7 & inlist(year,2016,2017,2018,2019,2020,2021), local(list_ie_4)
				levelsof id_ie if N_avg>100 & N_avg<=200 	& grade>=7 & inlist(year,2016,2017,2018,2019,2020,2021), local(list_ie_5)
				levelsof id_ie if N_avg>50 & N_avg<=100 	& grade>=7 & inlist(year,2016,2017,2018,2019,2020,2021), local(list_ie_6)

				forvalues group = 1(1)6 {
					foreach ie of local list_ie_`group' {
						use "$TEMP\temp_reg", clear
						capture reghdfe `v' 	treated_post post treated ${x_all} if inlist(fam_total_${fam_type},1,2,3,4)==1 & inlist(year,2016,2017,2018,2019,2020,2021) & id_ie == "`ie'" , a(grade year)
						if _rc!=0 continue
						mat A = r(table)
						clear
						set obs 1
						gen id_ie 	= "`ie'"
						gen b		=	A[1,1]
						gen se		=	A[2,1]
						gen pv		=	A[4,1]
						gen icl95 	= 	A[5,1]
						gen icu95 	= 	A[6,1]
						gen N		=	e(N)
						gen level 	=   3
						gen group 	= 	`group'
						append using "$TEMP\coef_twfe_ie"
						save "$TEMP\coef_twfe_ie", replace		
					}
				}
				timer off 2
				
				timer list 1 
				timer list 2
				
				
				
				
				
				
				
				