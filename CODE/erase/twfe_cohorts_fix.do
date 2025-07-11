clear

	*- TWFE Estimates

	local level = "all"
	local v = "std_gpa_m"
			
			estimates clear
			global x = "$x_all"
			if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"	
			

			use `v' pass_math pass_read approved approved_first id_per_umc year_t_?? public_siagie urban_siagie male_siagie educ_cat_mother higher_ed_parent lives_with_mother lives_with_father *has_internet *has_comp *low_ses *quiet_room year grade treated post treated_post id_ie fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid", clear
			
			*- Remove early grades and years
			keep if year>=2016
			drop if grade==0
			
			
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
	
			open 
			
			keep std_gpa_m treated_post post treated ${x} fam_total_${fam_type} fam_order_${fam_type} grade proxy_1st grade id_ie year sample*
			
			keep if sample_c2018==1
			keep if year-grade==2017
			
			//gen time_trend 
			
			//keep if fam_order_${fam_type} == 1
			keep if fam_order_${fam_type} == fam_total_${fam_type}
			
			/*
			reghdfe std_gpa_m 	treated_post post treated ${x} if inlist(fam_total_${fam_type},1,2)==1 & grade==3 , a(grade id_ie)
			*/
			
			reghdfe std_gpa_m 	treated_post post treated if inlist(fam_total_${fam_type},1,2)==1 & proxy_1st==2018, a(id_ie)
			
			collapse std_gpa_m, by(treated year)
			
			twoway 	(line std_gpa_m year if treated==1) ///
					(line std_gpa_m year if treated==0)
			
			