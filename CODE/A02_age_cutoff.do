*- Age cutoff




//Why is there one observation _m==1? between ECE and IDs





capture program drop main 
program define main 

	setup_AGE_CUTOFF
	
	*DOB_scatter //Shows figure of cutoffdates
	
	prepare_data 
	
	*exposure_covid //attempt to asses impact of covid by cutoff dates
	*sibling_spillover_1st //First attempt of sibling spillover with GPA
	*analysis
	
	
	student_sibling_combinations_dob
	
	//first_stage_1
	//first_stage_size2
	//first_stage_size3_mid
	
	*- RD with GPA
	
	*- RD with ECE
	ece_dob_prepare
	ece_dob_analysis_trend
	ece_dob_analysis_sibling
	ece_dob_analysis_own
	
end

********************************************************************************
* Setup
********************************************************************************

capture program drop setup_AGE_CUTOFF
program define setup_AGE_CUTOFF

	global age_test = 0
	global age_data = ""
	if ${age_test} == 1 global age_data = "_TEST"

	global fam_type=2
	
	global max_sibs = 4

	global x_all = "male_siagie urban_siagie public_siagie"
	global x_nohigher_ed = "male_siagie urban_siagie public_siagie"
	
	colorpalette  HCL blues, selec(2 5 8 11) nograph
	return list

	global blue_1 = "`r(p1)'"
	global blue_2 = "`r(p2)'"
	global blue_3 = "`r(p3)'"
	global blue_4 = "`r(p4)'"
	//local blue_5 = "`r(p5)'"
	//local blue_6 = "`r(p6)'"

	//colorpalette  HCL reds, selec(1 4 6 8 10 12) nograph
	colorpalette  HCL reds, selec(2 5 8 11) nograph
	return list

	global red_1 = "`r(p1)'"
	global red_2 = "`r(p2)'"
	global red_3 = "`r(p3)'"	
	global red_4 = "`r(p4)'"
	
	colorpalette  HCL greens, selec(2 5 8 11) nograph
	return list

	global green_1 = "`r(p1)'"
	global green_2 = "`r(p2)'"
	global green_3 = "`r(p3)'"		
	global green_4 = "`r(p4)'"
	
	
	global cutoff_last_1_2014 = 17622
	global cutoff_last_1_2015 = 17987
	global cutoff_last_1_2016 = 18352
	global cutoff_last_1_2017 = 18717
	global cutoff_last_1_2018 = 19083
	global cutoff_last_1_2019 = 19448
	global cutoff_last_1_2020 = 19813
	global cutoff_last_1_2021 = 20178
	global cutoff_last_1_2022 = 20544
	global cutoff_last_1_2023 = 20909
	global cutoff_last_1_2024 = 21274
	global cutoff_last_1_2025 = 21274+365 //31mar2019
	global cutoff_last_1_2026 = 21274+365+366 //31mar2020
	global cutoff_last_1_2027 = 21274+365+366+365 //31mar2021
	
	global cutoff_window = 100
	
end












capture program drop DOB_scatter
program define DOB_scatter

use "$TEMP\siagie_2024", clear


gen pop =1
collapse (sum)pop (mean)grade, by(dob_siagie)
sort dob_siagie
drop if pop < 1000
scatter grade dob

*- Identify cutoff dates
gen jump = grade-grade[_n+1]
replace jump = (jump>.5 & jump!=.) 
br if jump==1 //Always march 31st in our data
gen dob_num=dob_siagie
list if jump==1, sep(1000)

local lab_text = "03/31/"
twoway 						///
		(scatter grade dob_siagie) ///
		, 					///
		xlabel(17622 "`lab_text'08" 17987 "`lab_text'09" 18352 "`lab_text'10" 18717 "`lab_text'11" 19083 "`lab_text'12" 19448 "`lab_text'13" 19813 "`lab_text'14" 20178 "`lab_text'15" 20544 "`lab_text'16" 20909 "`lab_text'17" 21274 "`lab_text'18" , angle(45)) ///
		xline(17622 17987  18352 18717 19083  19448 19813 20178 20544  20909  21274, lcolor(gs12)) ///
		xtitle(Date of Birth) ///
		ylabel(0(1)11) ///
		ytitle("Average Grade in 2024 by DOB") 

	capture qui graph export "$FIGURES\Descriptive\dob_cutoffs.png", replace			
	capture qui graph export "$FIGURES\Descriptive\dob_cutoffs.pdf", replace	
	
	
*- How was grade=0 in 2020?
forvalues y = 2017(1)2024 {
	use "$TEMP\siagie_`y'", clear
	tab grade
}

//Seems to me enrollments where quite similar even in 2020.
	

end





capture program drop prepare_data
program define prepare_data



	*- Let's look at those who should've started 1st grade in 2020
/*
	use "$TEMP\siagie_2024", clear

	//gen dob_num=dob_siagie
	
	keep id_per_umc dob_siagie
	
	tempfile dobs
	save `dobs', replace
	
	use "$TEMP\siagie_append", clear

	keep id_per_umc
	sort id_per_umc
	by id_per_umc: keep if _n==1

	merge 1:1 id_per_umc using `dobs', keep(master match)
	drop _m
	*/
	use "$TEMP\siagie_append", clear
	sort id_per_umc
	keep id_per_umc 
	by id_per_umc: keep if _n==1
	
	preserve
			use "$TEMP\id_siblings", clear
			keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} closest_age_gap*${fam_type} exp_entry_year dob_siagie
			tempfile id_siblings_sample
			save `id_siblings_sample', replace
	restore

	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} closest_age_gap*${fam_type} exp_entry_year dob_siagie) 
	rename _m merge_siblings	
	
gen dob_num=dob_siagie

	gen year_entry_1st = .
	gen year_entry_K = .
	forvalues y = 2015(1)2027 {
		local y_pre = `y'-1
		replace year_entry_1st = `y' 	if ${cutoff_last_1_`y_pre'}<dob_num & dob_num<=${cutoff_last_1_`y'}
		replace year_entry_K = `y'-3 	if ${cutoff_last_1_`y_pre'}<dob_num & dob_num<=${cutoff_last_1_`y'}
	}
	
	
	forvalues y = 2015(1)2027 {
		gen around_cutoff_`y' = abs(dob_num-${cutoff_last_1_`y'})<${cutoff_window}
	}	
	   	
	  
	*- Relevant sample
	forvalues y = 2015(1)2027 {
		bys id_fam_${fam_type}: egen sib_around_cutoff_`y' = max(around_cutoff_`y')
	  }
	  
	 
	*- Relative DOB
	gen dob_relative = .
	gen stack_year_1st = .
	gen stack_year_k = .

	forvalues y = 2015(1)2027 {
		replace dob_relative = dob_num - ${cutoff_last_1_`y'} if around_cutoff_`y'==1
		replace stack_year_1st 	= `y' 	if around_cutoff_`y'==1
		replace stack_year_k 	= `y'-3 if around_cutoff_`y'==1
		}

	order id_per_umc id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}, first  
	  
	compress 
	
 
	save "$TEMP\id_dob", replace 
	  
end


capture program drop pass_subject
program define pass_subject
	*- Passed Math and Reading
	gen letter = 0
	replace letter = 1 if grade<=6 
	replace letter = 1 if grade==7 & year>=2019
	replace letter = 1 if grade==8 & year>=2020
	replace letter = 1 if grade==9 & year>=2021
	replace letter = 1 if grade==10 & year>=2022
	replace letter = 1 if grade==11 & year>=2023

	local fail_letter = 2 //2=B, they need to get an A, otherwise they either fail or need to take extra classes?
	local fail_number = 13 //

	gen byte pass_math = 1 if math!=.	
	replace pass_math = 0 if math<=`fail_letter' & math!=. & letter==1
	replace pass_math = 0 if math<=`fail_number' & math!=. & letter==0

	gen byte pass_read = 1 if comm!=.
	replace pass_read = 0 if comm<=`fail_letter' & comm!=. & letter==1
	replace pass_read = 0 if comm<=`fail_number' & comm!=. & letter==0  

end


capture program drop exposure_covid
program define exposure_covid
	  
	use "$TEMP\siagie_2024", clear
		
	/*
	pass_subject
	
	global current_cutoff_year = 2020
	  
	keep if around_cutoff_${current_cutoff_year}==1 
	  
	gen running_dob = dob_num-${cutoff_last_1_${current_cutoff_year}} 
	gen ABOVE = running_dob>0
	gen ABOVE_running_dob = running_dob*ABOVE		  
	
	binsreg grade 			running_dob, nbins(50) xline(${cutoff_last_1_${current_cutoff_year}})
	
	  
	bys id_fam_${fam_type} (around_cutoff_${current_cutoff_year} dob_num):  gen sib_dob 	= dob_num[_N]
	bys id_fam_${fam_type} (around_cutoff_${current_cutoff_year} dob_num):  gen sib_grade 	= grade[_N]	  	
	
	
	
	keep if grade>=2
	drop if around_cutoff_${current_cutoff_year}==1
	keep if fam_total_${fam_type}<=5
	
	binsreg sib_grade sib_dob, nbins(50) xline(${cutoff_last_1_${current_cutoff_year}})
	binsreg fam_total_${fam_type} sib_dob, nbins(50) xline(${cutoff_last_1_${current_cutoff_year}})
	

	binsreg grade 			sib_dob, nbins(50) xline(${cutoff_last_1_${current_cutoff_year}})
	binsreg std_gpa_m_adj 	sib_dob, nbins(50) xline(${cutoff_last_1_${current_cutoff_year}})
	binsreg approved 		sib_dob, nbins(50) xline(${cutoff_last_1_${current_cutoff_year}})
	binsreg approved_first 	sib_dob, nbins(50) xline(${cutoff_last_1_${current_cutoff_year}})
	

	reghdfe std_gpa_m_adj ABOVE running_dob ABOVE_running_dob if  abs(running_dob)<${cutoff_window}, a(id_ie grade)  
	reghdfe std_gpa_c_adj ABOVE running_dob ABOVE_running_dob if  abs(running_dob)<${cutoff_window}, a(id_ie grade)  
	reghdfe approved_first ABOVE running_dob ABOVE_running_dob if  abs(running_dob)<${cutoff_window}, a(id_ie grade)  
	reghdfe approved_first ABOVE running_dob ABOVE_running_dob if  abs(running_dob)<${cutoff_window}, a(id_ie grade)  
	
	binsreg std_gpa_m_adj 	sib_dob if  abs(running_dob)<${cutoff_window}, nbins(100) xline(${cutoff_last_1_${current_cutoff_year}})
	binsreg std_gpa_c_adj 	sib_dob if  abs(running_dob)<${cutoff_window}, nbins(100) xline(${cutoff_last_1_${current_cutoff_year}})
	binsreg approved_first 	sib_dob if  abs(running_dob)<${cutoff_window}, nbins(100) xline(${cutoff_last_1_${current_cutoff_year}})

	  
	drop if in_dob_range==1
	drop if grade<=1
	keep if fam_total_${fam_type}==2

	binsreg grade sib_dob, nbins(50)
	binsreg fam_total_${fam_type} sib_dob, nbins(50)
	binsreg sib_grade sib_dob, nbins(100) xline(19813)
	binsreg std_gpa_m_adj sib_dob, nbins(100) xline(19813)	  
	 */
end




capture program drop sibling_spillover_1st
program define sibling_spillover_1st
	  
	di "GPA"
	/*
	global current_cutoff_year = 2020
	  
	keep if sib_around_cutoff_${current_cutoff_year}==1 
	  
	bys id_fam_${fam_type} (around_cutoff_${current_cutoff_year} dob_num):  gen sib_dob 	= dob_num[_N]
	bys id_fam_${fam_type} (around_cutoff_${current_cutoff_year} dob_num):  gen sib_grade 	= grade[_N]	  	
	
	
	
	keep if grade>=2
	drop if around_cutoff_${current_cutoff_year}==1
	keep if fam_total_${fam_type}<=5
	
	binsreg sib_grade sib_dob, nbins(50) xline(${cutoff_last_1_${current_cutoff_year}})
	binsreg fam_total_${fam_type} sib_dob, nbins(50) xline(${cutoff_last_1_${current_cutoff_year}})
	

	binsreg grade 			sib_dob, nbins(50) xline(${cutoff_last_1_${current_cutoff_year}})
	binsreg std_gpa_m_adj 	sib_dob, nbins(50) xline(${cutoff_last_1_${current_cutoff_year}})
	binsreg approved 		sib_dob, nbins(50) xline(${cutoff_last_1_${current_cutoff_year}})
	binsreg approved_first 	sib_dob, nbins(50) xline(${cutoff_last_1_${current_cutoff_year}})
	
	
	gen running_dob = sib_dob-${cutoff_last_1_${current_cutoff_year}}
	gen ABOVE = running_dob>0
	gen ABOVE_running_dob = running_dob*ABOVE	
	
	  
	reghdfe std_gpa_m_adj ABOVE running_dob ABOVE_running_dob if  abs(running_dob)<${cutoff_window}, a(id_ie grade)  
	reghdfe std_gpa_c_adj ABOVE running_dob ABOVE_running_dob if  abs(running_dob)<${cutoff_window}, a(id_ie grade)  
	reghdfe approved_first ABOVE running_dob ABOVE_running_dob if  abs(running_dob)<${cutoff_window}, a(id_ie grade)  
	reghdfe approved_first ABOVE running_dob ABOVE_running_dob if  abs(running_dob)<${cutoff_window}, a(id_ie grade)  
	
	binsreg std_gpa_m_adj 	sib_dob if  abs(running_dob)<${cutoff_window}, nbins(100) xline(${cutoff_last_1_${current_cutoff_year}})
	binsreg std_gpa_c_adj 	sib_dob if  abs(running_dob)<${cutoff_window}, nbins(100) xline(${cutoff_last_1_${current_cutoff_year}})
	binsreg approved_first 	sib_dob if  abs(running_dob)<${cutoff_window}, nbins(100) xline(${cutoff_last_1_${current_cutoff_year}})

	  
	drop if in_dob_range==1
	drop if grade<=1
	keep if fam_total_${fam_type}==2

	binsreg grade sib_dob, nbins(50)
	binsreg fam_total_${fam_type} sib_dob, nbins(50)
	binsreg sib_grade sib_dob, nbins(100) xline(19813)
	binsreg std_gpa_m_adj sib_dob, nbins(100) xline(19813)	  
	 */
end


capture program drop student_sibling_combinations_dob
program define student_sibling_combinations_dob

	*- For those families, we create all potential student-sibling-ece combinations
	use "$TEMP\id_dob", clear
	keep id_per_umc id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} year_entry* dob_siagie

	keep if fam_total_${fam_type} <=5
	
	*- Create all sibling combinations
	expand 5
	bys id_fam_${fam_type} fam_order_${fam_type}: gen fam_order_${fam_type}_sib = _n
	drop if fam_order_${fam_type}_sib>fam_total_${fam_type} //We did 5 as an upper bound, but some of them don't have that many.

	*- Recover ID_per_umc from siblings family order
	//rename (id_per_umc fam_order_${fam_type}) (aux_id_per_umc aux_fam_order_${fam_type})
	
	rename fam_order_${fam_type} 	aux_fam_order_${fam_type}
	rename dob_siagie				aux_dob_siagie
	rename year_entry*				aux_year_entry*
	
	rename fam_order_${fam_type}_sib fam_order_${fam_type}
	merge m:1 id_fam_${fam_type} fam_order_${fam_type} using "$TEMP\id_dob", keepusing(dob_relative stack_year* year_entry* dob_siagie) keep(master match) 
	rename (dob_relative year_entry* stack* dob_siagie) (dob_relative_sib year_entry*_sib stack*_sib  dob_siagie_sib)
	drop _m
	rename fam_order_${fam_type} fam_order_${fam_type}_sib
	rename aux_* *
	
	compress
	
	save "$TEMP\student_sibling_combinations_dob", replace
	
end


capture program drop first_stage_1
program define first_stage_1


	use if year==2020 using "$TEMP\siagie_append", clear
	keep id_per_umc std_gpa_m_adj
	tempfile info_siagie
	save `info_siagie'

	use "$TEMP\student_sibling_combinations_dob", clear
	
	drop if fam_order_${fam_type}==fam_order_${fam_type}_sib
	keep if fam_total_${fam_type}==2
	
	keep if year_entry_1st==2018
	
	//keep if fam_order_${fam_type}==1
	//assert fam_order_${fam_type}_sib==2
	
	format dob_siagie_sib %td
	
	keep if year_entry_1st_sib>=2015 & year_entry_1st_sib<=2025
	
	local lab_text = "03/31/"	
	binsreg year_entry_1st_sib	dob_siagie_sib if abs(dob_siagie_sib-dob_siagie)>365 ///if dob_siagie_sib>=19083 ///
	, ///
		xlabel(17622 "`lab_text'08" 17987 "`lab_text'09" 18352 "`lab_text'10" 18717 "`lab_text'11" 19083 "`lab_text'12" 19448 "`lab_text'13" 19813 "`lab_text'14" 20178 "`lab_text'15" 20544 "`lab_text'16" 20909 "`lab_text'17" 21274 "`lab_text'18" , angle(45)) ///
		xline(17622 17987  18352 18717 19083  19448 19813 20178 20544  20909  21274, lcolor(gs12)) ///
		xtitle(Date of Birth) ///
		ylabel(2015(1)2025) 
	capture qui graph export "$FIGURES\Descriptive\fs_age_cutoff_sample.png", replace			
	capture qui graph export "$FIGURES\Descriptive\fs_age_cutoff_sample.pdf", replace	
	
	
	histogram dob_siagie_sib if abs(dob_siagie_sib-dob_siagie)>365
	capture qui graph export "$FIGURES\Descriptive\histogra_age_cutoff_sample.png", replace			
	capture qui graph export "$FIG2RES\Descriptive\histogra_age_cutoff_sample.pdf", replace	
		
	*- Attach grades
	merge 1:1 id_per_umc using `info_siagie', keep(master match) keepusing(std_gpa_m_adj)
	
	local lab_text = "03/31/"	
	binsreg std_gpa_m_adj	dob_siagie_sib if abs(dob_siagie_sib-dob_siagie)>365 ///if dob_siagie_sib>=19083 ///
	, ///
		nbins(100) ///
		xlabel(17622 "`lab_text'08" 17987 "`lab_text'09" 18352 "`lab_text'10" 18717 "`lab_text'11" 19083 "`lab_text'12" 19448 "`lab_text'13" 19813 "`lab_text'14" 20178 "`lab_text'15" 20544 "`lab_text'16" 20909 "`lab_text'17" 21274 "`lab_text'18" , angle(45)) ///
		xline(17622 17987  18352 18717 19083  19448 19813 20178 20544  20909  21274, lcolor(gs12)) ///
		xtitle(Sibling Date of Birth)
	
	
end


capture program drop first_stage_size2
program define first_stage_size2


	use "$TEMP\student_sibling_combinations_dob", clear
	
	drop if fam_order_${fam_type}==fam_order_${fam_type}_sib
	keep if fam_total_${fam_type}==2
	//keep if fam_order_${fam_type}==2 & fam_order_${fam_type}_sib==
	tempfile dob_sib
	save `dob_sib'
	
	use id_per_umc grade year std_gpa_?_adj using "$TEMP\siagie_append", clear
	keep id_per_umc grade year std_gpa_?_adj
	merge m:1 id_per_umc using `dob_sib', keep(master match) keepusing(year_entry_1st dob_siagie year_entry_1st_sib dob_siagie_sib)
	beep
	
	
	keep if year_entry_1st_sib>=2015 & year_entry_1st_sib<=2025
	
	*- Example of first stage
	
	*-- Pre COVID
	preserve
		keep if grade==4 & year==2018
		keep if year_entry_1st_sib>=2018 & year_entry_1st_sib<=2019
		//binsreg year_entry_1st_sib dob_siagie_sib
		
		gen y = 2018.5 + rnormal()/5
		replace y = y - 0.2 if year_entry_1st_sib>=2019
		//binsreg y dob_siagie_sib
		
		collapse year_entry_1st_sib y, by(dob_siagie_sib)
		
		twoway /// 
				(scatter year_entry_1st_sib dob_siagie_sib) ///
				(scatter y dob_siagie_sib) ///
				, ///
				xtitle("Sibling DOB") ///
				ytitle("Standardized GPA Mathematics") ///
				ylabel(2018(1)2019) ///
				legend(order(1 "Sibling year of school start" 2 "Focal Child GPA in 2018") pos(6) col(2))
					capture qui graph export "$FIGURES\Descriptive\example_pre_covid.png", replace			
					capture qui graph export "$FIGURES\Descriptive\example_pre_covid.pdf", replace	
		
	restore	
	
	*-- During COVID
	preserve
		keep if grade==4 & year==2020
		keep if year_entry_1st_sib>=2020 & year_entry_1st_sib<=2021
		//binsreg year_entry_1st_sib dob_siagie_sib
		
		gen y = 2020.5 + rnormal()/5
		replace y = y + 0.2 if year_entry_1st_sib>=2021
		//binsreg y dob_siagie_sib
		
		collapse year_entry_1st_sib y, by(dob_siagie_sib)
		
		twoway /// 
				(scatter year_entry_1st_sib dob_siagie_sib) ///
				(scatter y dob_siagie_sib) ///
				, ///
				xtitle("Sibling DOB") ///
				ytitle("Standardized GPA Mathematics") ///
				ylabel(2020(1)2021) ///
				legend(order(1 "Sibling year of school start" 2 "Focal Child GPA in 2020") pos(6) col(2))
					capture qui graph export "$FIGURES\Descriptive\example_post_covid.png", replace			
					capture qui graph export "$FIGURES\Descriptive\example_post_covid.pdf", replace	
		
	restore
	
	
	forvalues g = 1(1)8 {
		forvalues y = 2017(1)2023 {
			preserve
				drop if year_entry_1st_sib==year_entry_1st
				local g = `g'
				local y = `y'
				local lab_text = "03/31/"	
				sum dob_siagie if grade==`g' & year==`y'
				binsreg std_gpa_m_adj dob_siagie_sib if grade==`g' & year==`y' & abs(dob_siagie_sib-dob_siagie)>365 ///if dob_siagie_sib>=19083 ///
				, ///
					nbins(50) ///
					xlabel(17622 "`lab_text'08" 17987 "`lab_text'09" 18352 "`lab_text'10" 18717 "`lab_text'11" 19083 "`lab_text'12" 19448 "`lab_text'13" 19813 "`lab_text'14" 20178 "`lab_text'15" 20544 "`lab_text'16" 20909 "`lab_text'17" 21274 "`lab_text'18" , angle(45)) ///
					xline(17622 17987  18352 18717 19083  19448 19813 20178 20544  20909  21274, lcolor(gs12)) ///
					xtitle(Sibling Date of Birth) ///
					ytitle("Standardized GPA Mathematics")
					capture qui graph export "$FIGURES\Descriptive\first_stage_m_`g'_`y'.png", replace			
					capture qui graph export "$FIGURES\Descriptive\first_stage_m_`g'_`y'.pdf", replace			
	
					
			restore
		}
		
	}
	
	
	preserve
		local g = 2
		local y = 2022
					//drop if year_entry_1st_sib==year_entry_1st
					local g = `g'
					local y = `y'
					local lab_text = "03/31/"	
					sum dob_siagie if grade==`g' & year==`y'
		histogram dob_siagie_sib if grade==`g' & year==`y'	
	restore
	
end


capture program drop first_stage_size3_mid
program define first_stage_size3_mid


	use "$TEMP\student_sibling_combinations_dob", clear
	
	drop if fam_order_${fam_type}==fam_order_${fam_type}_sib
	keep if fam_total_${fam_type}==3
	keep if fam_order_${fam_type}==2
	keep if fam_order_${fam_type}_sib==3
	keep if year_entry_1st_sib>=2018 & year_entry_1st_sib<=2023
	histogram dob_siagie_sib
	tempfile dob_sib
	save `dob_sib', replace
	
	use id_per_umc grade year std_gpa_?_adj using "$TEMP\siagie_append", clear
	keep id_per_umc grade year std_gpa_?_adj
	merge m:1 id_per_umc using `dob_sib', keep(master match) keepusing(year_entry_1st dob_siagie year_entry_1st_sib dob_siagie_sib dob_relative_sib)
	beep
	
	
	
	
	forvalues g = 2(1)8 {
		forvalues y = 2017(1)2023 {
			//local g=2
			//local y=2020
			preserve
				drop dob_relative_sib 
				gen dob_relative_sib = dob_siagie_sib - ${cutoff_last_1_`y'}
				gen ABOVE= dob_relative_sib>0
				gen ABOVE_dob_relative_sib = dob_relative_sib*ABOVE
				
				//drop if year_entry_1st_sib==year_entry_1st
				keep if year_entry_1st_sib>=`y' & year_entry_1st_sib<=`y'+1
				keep if grade==`g' & year==`y'
				local lab_text = "03/31/"	
				//sum dob_siagie if grade==`g' & year==`y'
				histogram dob_siagie_sib
				capture qui graph export "$FIGURES\RD_age\histogram_2_3_m_`g'_`y'.png", replace			
				capture qui graph export "$FIGURES\RD_age\histogram_2_3_m_`g'_`y'.pdf", replace				
				binsreg std_gpa_m_adj dob_siagie_sib ///
				, ///
					nbins(50) ///
					xlabel(${cutoff_last_1_`y'} "`lab_text'`y'") ///
					///xlabel(17622 "`lab_text'08" 17987 "`lab_text'09" 18352 "`lab_text'10" 18717 "`lab_text'11" 19083 "`lab_text'12" 19448 "`lab_text'13" 19813 "`lab_text'14" 20178 "`lab_text'15" 20544 "`lab_text'16" 20909 "`lab_text'17" 21274 "`lab_text'18" , angle(45)) ///
					xline(${cutoff_last_1_`y'}, lcolor(gs12)) ///
					xtitle(Sibling Date of Birth)
					capture qui graph export "$FIGURES\RD_age\first_stage_2_3_m_`g'_`y'.png", replace			
					capture qui graph export "$FIGURES\RD_age\first_stage_2_3_m_`g'_`y'.pdf", replace			
				
				eststo rd_2_3_`g'_`y': reg std_gpa_m_adj ABOVE dob_relative_sib ABOVE_dob_relative_sib
					
			restore
		}
		
	}
	
	erase "$TABLES\rd_2_3.tex"
	
	estout   rd* ///
	using "$TABLES\rd_2_3.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) ///
	stats(blank_line N, fmt(%9.0fc %9.0fc ) labels(" " "Observations" )) 
	
	
	
	///
	keep(_cons 2.fam_total_${fam_type} 3.fam_total_${fam_type} 4.fam_total_${fam_type}) varlabels(2.fam_total_${fam_type} "2 Children" 3.fam_total_${fam_type} "3 Children" 4.fam_total_${fam_type} "4 Children") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	indicate("Controls = score_math") ///
	stats(blank_line N, fmt(%9.0fc %9.0fc ) labels(" " "Observations" )) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)		
	
	
	
		
	/*
	preserve
		local g = 3
		local y = 2021
		//drop if year_entry_1st_sib==`y'-`g'
		keep if year_entry_1st_sib>=2021 & year_entry_1st_sib<=2022
		//drop if dob_siagie_sib<=${cutoff_last_1_2019}
					local g = `g'
					local y = `y'
					local lab_text = "03/31/"	
					sum dob_siagie if grade==`g' & year==`y'
		//histogram dob_siagie_sib if grade==`g' & year==`y'	
		//binsreg year_entry_1st_sib dob_siagie_sib if grade==`g' & year==`y'	, nbins(50)	 xline(${cutoff_last_1_2020})
		binsreg std_gpa_m_adj dob_siagie_sib if grade==`g' & year==`y', nbins(100)	xline(${cutoff_last_1_2020})
	restore
	*/
end



capture program drop ece_dob_prepare
program define ece_dob_prepare


	foreach g in "2p" "4p" "6p" "2s" {
		use "$TEMP\em_`g'", clear
		keep id_estudiante_`g' id_ie year score_math score_com
		rename id_estudiante_`g' id_estudiante
		merge m:1 id_estudiante using "$TEMP\match_siagie_ece_`g'" 
		keep if _m==3
		drop id_estudiante
		gen gr = "`g'"
		keep id_per_umc id_ie year gr score_math score_com
		order id_per_umc id_ie year gr score_math score_com
		compress
		tempfile em_`g'
		save `em_`g''
	}

	foreach g in "2p" "4p" "2s" {
		use "$TEMP\ece_`g'", clear
		keep id_estudiante_`g' id_ie year score_math score_com
		rename id_estudiante_`g' id_estudiante
		merge m:1 id_estudiante using "$TEMP\match_siagie_ece_`g'" 
		keep if _m==3
		drop id_estudiante
		gen gr = "`g'"
		keep id_per_umc id_ie year gr score_math score_com
		order id_per_umc id_ie year gr score_math score_com
		compress
		tempfile ece_`g'
		save `ece_`g''
	}

	clear
	foreach g in "2p" "4p" "6p" "2s" {
		capture append using `em_`g''
		capture append using `ece_`g''
	}

	//keep if year>=2022

	bys id_per_umc gr (year): keep if _n==1 //First take if many in the same grade

	compress
	save "$TEMP\ece_post", replace


	*- Let's define families that are in the relevant sample (>2 and member in ECE)
	use "$TEMP\ece_post", clear
	merge m:1 id_per_umc using "$TEMP\id_dob", keep(master match)
	keep if _m==3

	keep if fam_total_${fam_type}>=2 & fam_total_${fam_type}<=5

	keep id_fam_${fam_type}

	bys id_fam_${fam_type}: keep if _n==1

	tempfile fams_in_ece 
	save `fams_in_ece', replace

	*- For those families, we create all potential student-sibling-ece combinations
	use "$TEMP\id_dob", clear
	keep id_per_umc id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} year_entry* dob_siagie

	merge m:1 id_fam_${fam_type}  using `fams_in_ece', keep(master match) 
	keep if _m==3
	drop _m

	*- Create all sibling combinations
	expand 5
	bys id_fam_${fam_type} fam_order_${fam_type}: gen fam_order_${fam_type}_sib = _n
	drop if fam_order_${fam_type}_sib>fam_total_${fam_type} //We did 5 as an upper bound, but some of them don't have that many.

	*- Recover ID_per_umc from siblings family order
	//rename (id_per_umc fam_order_${fam_type}) (aux_id_per_umc aux_fam_order_${fam_type})
	
	rename fam_order_${fam_type} 	aux_fam_order_${fam_type}
	rename dob_siagie				aux_dob_siagie
	rename year_entry*				aux_year_entry*
	
	rename fam_order_${fam_type}_sib fam_order_${fam_type}
	merge m:1 id_fam_${fam_type} fam_order_${fam_type} using "$TEMP\id_dob", keepusing(dob_relative stack_year* year_entry* dob_siagie) keep(master match) 
	rename (dob_relative year_entry* stack* dob_siagie) (dob_relative_sib year_entry*_sib stack*_sib  dob_siagie_sib)
	drop _m
	rename fam_order_${fam_type} fam_order_${fam_type}_sib
	rename aux_* *

	*- Create all ECE-grade combinations
	expand 4
	bys id_fam_${fam_type} fam_order_${fam_type} fam_order_${fam_type}_sib: gen ece=_n

	gen gr= ""
	replace gr = "2p" if ece==1
	replace gr = "4p" if ece==2
	replace gr = "6p" if ece==3
	replace gr = "2s" if ece==4
	drop ece

	merge m:1 id_per_umc gr using "$TEMP\ece_post", keep(master match) keepusing(id_ie year score_math score_com)

	keep if _m==3

	//Check histograms
	histogram dob_relative_sib if  year==2022 & fam_order_2!= fam_order_2_sib, discrete
	capture qui graph export "$FIGURES\Descriptive\histogram_dob_siblings_2022.png", replace
	histogram dob_relative_sib if  year==2023 & fam_order_2!= fam_order_2_sib, discrete
	histogram dob_relative_sib if  year==2024 & fam_order_2!= fam_order_2_sib, discrete	

	label var dob_relative_sib 		"Relative DOB of sibling (for entering in stack year)"
	label var stack_year_1st_sib 	"Year for which DOB is estimated - 1st"
	label var stack_year_k_sib		"Year for which DOB is estimated - Pre K"

	compress

	save "$TEMP\ece_siblings_dob", replace



	//Why is there lower density on the right?

			

	//Why is there one observation _m==1?

end 

capture program drop ece_dob_analysis_trend
program define ece_dob_analysis_trend


use "$TEMP\siagie_append_TEST", clear


	preserve
			use "$TEMP\id_siblings", clear
			keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} closest_age_gap*${fam_type} exp_entry_year dob_siagie
			tempfile id_siblings_sample
			save `id_siblings_sample', replace
	restore

	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} closest_age_gap*${fam_type} exp_entry_year dob_siagie) 
	rename _m merge_siblings	

	keep if fam_total_${fam_type}==2
	
	
	bys id_fam_${fam_type}: 

keep if year==2020
keep if grade==3


end



capture program drop ece_dob_analysis_own
program define ece_dob_analysis_own

	*- Own effects
	use "$TEMP\ece_siblings_dob", clear

	rename dob_relative_sib dob_relative

	keep if fam_order_2==fam_order_2_sib

	gen date_ece = mdy(11, 15, year)

	gen age = (date_ece - dob_siagie) / 365.25	

	gen ABOVE= dob_relative>0
	gen ABOVE_dob_relative = dob_relative*ABOVE

	compress
	close

	assert 1==0
	/*
	gen age = year(date_ece) - year(dob_siagie)
	replace age = age - 1 if (month(dob_siagie) > 11 | (month(dob_siagie) == 11 & day(dob_siagie) > 30))
	*/

	open
		keep if gr=="4p"
		keep if dob_relative!=.
		tab year
		
		binsreg score_math dob_relative if stack_year==2015, nbins(100)
		binsreg score_math dob_relative if stack_year==2019, nbins(100)
		binsreg score_math dob_relative if stack_year==2020, nbins(100) //One year of difference in exposure to pandemic
		
		binsreg score_com dob_relative if stack_year==2015, nbins(100)
		binsreg score_com dob_relative if stack_year==2019, nbins(100)
		binsreg score_com dob_relative if stack_year==2020, nbins(100) //One year of difference in exposure to pandemic	
		
		reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year==2015, a(year)
		reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year==2019, a(year)
		reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year==2020, a(year)

		reg score_com ABOVE dob_relative ABOVE_dob_relative if stack_year==2015, a(year)
		reg score_com ABOVE dob_relative ABOVE_dob_relative if stack_year==2019, a(year)
		reg score_com ABOVE dob_relative ABOVE_dob_relative if stack_year==2020, a(year)	
		
		//Is there really a benefit of using the DOB here? What do I gain from this variation? Why not use the whole cohort.
		
	open
		keep if gr=="2s"
		keep if dob_relative!=.
		
		binsreg score_math dob_relative if stack_year==2015, nbins(100)
		
	open
		keep if gr=="2p"
		keep if dob_relative!=.
		binsreg score_math dob_relative if stack_year==2015, nbins(100)	

	//Too good to be true...


	binsreg age dob_relative if gr=="4p" & (stack_year==2019 & inlist(year,2022,2023)), nbins(100)
	binsreg age dob_relative if gr=="4p" & ((stack_year==2019 & dob_relative>0) | (stack_year==2020 & dob_relative<0)), nbins(100)

	binsreg year dob_relative if gr=="4p" & ((stack_year==2019 & dob_relative<0 & year==2022) | (stack_year==2019 & dob_relative>0 & year==2023)), nbins(100)
	binsreg age dob_relative if gr=="4p" & ((stack_year==2019 & dob_relative<0 & year_entry_1st==2019) | (stack_year==2019 & dob_relative>0 & year_entry_1st==2020)), nbins(100)

	sort dob_siagie 
	br dob_siagie if gr=="4p" & (((stack_year==2019 & dob_relative<0 & year_entry_1st==2019) | (stack_year==2019 & dob_relative>0 & year_entry_1st==2020)))

	binsreg year_entry_1st dob_relative if stack_year==2019

	binsreg stack_year dob_relative if gr=="4p" & year==2023, nbins(100)


	binsreg year_entry_1st dob_relative if gr=="2p", nbins(100)
	binsreg age dob_relative if gr=="2p", nbins(100)
	binsreg stack_year dob_relative if gr=="2p", nbins(100)
	binsreg score_math dob_relative if gr=="2p", nbins(100)
	binsreg score_math dob_relative if gr=="4p", nbins(100)
	binsreg score_math dob_relative if gr=="6p", nbins(100)
	binsreg score_math dob_relative if gr=="2s", nbins(100)


	binsreg score_math dob_relative if gr=="2p", nbins(100)


end 


capture program drop ece_dob_analysis_sibling
program define ece_dob_analysis_sibling


	*- Sibling spillovers
	use "$TEMP\ece_siblings_dob", clear
	
	keep if fam_order_2!=fam_order_2_sib

	gen date_ece = mdy(11, 15, year)

	gen age = (date_ece - dob_siagie) / 365.25	

	gen ABOVE= dob_relative>0
	gen ABOVE_dob_relative = dob_relative*ABOVE


	compress
	close


	open
	
	*- First Stage
	//Younger sibling education is delayed after Covid
	binsreg year_entry_1st_sib dob_relative if stack_year_1st_sib==2020
	binsreg year_entry_1st_sib dob_relative if stack_year_1st_sib==2021
	
	//Older sibling age when taking ECE exam
	tab year gr
	//All the possible cases of older sibling after covid (where older sibling wouldn't be in 1st grade during covid. That is for the younger sibling)
	binsreg age dob_relative if stack_year_1st_sib==2020 & gr=="4p" & year==2022, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2020 & gr=="6p" & year==2024, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2020 & gr=="2s" & year==2022, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2020 & gr=="2s" & year==2023, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2021 & gr=="4p" & year==2022, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2021 & gr=="6p" & year==2024, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2021 & gr=="2s" & year==2022, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2021 & gr=="2s" & year==2023, nbins(100)
	
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2020 & gr=="4p" & year==2022
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2020 & gr=="6p" & year==2024
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2020 & gr=="2s" & year==2022
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2020 & gr=="2s" & year==2023
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2021 & gr=="4p" & year==2022
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2021 & gr=="6p" & year==2024
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2021 & gr=="2s" & year==2022
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2021 & gr=="2s" & year==2023	
	
	
	//I do find <<NEGATIVE>> effects in 8th grade students for the most part.
	//How to explain this? This is against my hypothesis... parent's should be less focused on their younger siblings if they haven't started school?

end



capture program drop ece_dob_analysis_sibling_draft
program define ece_dob_analysis_sibling_draft


	*- Sibling spillovers
	use "$TEMP\ece_siblings_dob", clear
	
	keep if fam_order_2!=fam_order_2_sib

	gen date_ece = mdy(11, 15, year)

	gen age = (date_ece - dob_siagie) / 365.25	

	gen ABOVE= dob_relative>0
	gen ABOVE_dob_relative = dob_relative*ABOVE


	compress
	close


	open
	
	*- First Stage
	//Younger sibling education is delayed after Covid
	binsreg year_entry_1st_sib dob_relative if stack_year_1st_sib==2020
	binsreg year_entry_1st_sib dob_relative if stack_year_1st_sib==2021
	
	//Older sibling age when taking ECE exam
	tab year gr
	//All the possible cases of older sibling after covid (where older sibling wouldn't be in 1st grade during covid. That is for the younger sibling)
	binsreg age dob_relative if stack_year_1st_sib==2020 & gr=="4p" & year==2022, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2020 & gr=="6p" & year==2024, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2020 & gr=="2s" & year==2022, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2020 & gr=="2s" & year==2023, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2021 & gr=="4p" & year==2022, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2021 & gr=="6p" & year==2024, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2021 & gr=="2s" & year==2022, nbins(100)
	binsreg age dob_relative if stack_year_1st_sib==2021 & gr=="2s" & year==2023, nbins(100)
	
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2020 & gr=="4p" & year==2022
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2020 & gr=="6p" & year==2024
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2020 & gr=="2s" & year==2022
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2020 & gr=="2s" & year==2023
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2021 & gr=="4p" & year==2022
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2021 & gr=="6p" & year==2024
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2021 & gr=="2s" & year==2022
	reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year_1st_sib==2021 & gr=="2s" & year==2023	
	
	
	//assert 1==0
	
	//stack-3==year --> When starting preK

	*- Looking for potential years
	clear
	tempfile results
	save `results', replace emptyok
	
	open
	keep if dob_relative!=.
	tab year gr 
	
	local g = "2p"
	local y = 2022
	reg score_math ABOVE dob_relative ABOVE_dob_relative if year==`y' & stack_year_1st_sib==`y' & gr=="`g'"
	
	
	foreach g in "2p" "4p" "6p" "2s" {
		forvalues y = 2018(1)2024 {
			matrix res = .
			cap reg score_math ABOVE dob_relative ABOVE_dob_relative if year==`y' & stack_year_k_sib==`y' & gr=="`g'"
			matrix res_k = r(table)
			local b = res[1,1]
			local pv = res[4,1]
			
			cap reg score_math ABOVE dob_relative ABOVE_dob_relative if year==`y' & stack_year_1st_sib==`y' & gr=="`g'"
			matrix res_1 = r(table)
			local b = res[1,1]
			local pv = res[4,1]
						
			preserve
				clear 
				set obs 2
				gen grade = "`g'"
				gen year = `y'
				gen sib_1st = _n==2
				gen b = res_k[1,1] in 1
				gen pv = res_k[4,1] in 1
				replace b = res_1[1,1] in 2
				replace pv = res_1[4,1] in 2
				append using `results'
				save `results', replace
			restore
			
			}
	}
	
	use `results', clear
	gen valid = (pv<0.1)
	sort year grade
	
	reg score_math ABOVE dob_relative ABOVE_dob_relative if year==2015 & stack_year_1st_sib==2015 & gr=="2p"
	reg score_math ABOVE dob_relative ABOVE_dob_relative if year==2022 & stack_year_1st_sib==2022 & gr=="2p"
	
	
	
	open
		//replace stack_year_sib = stack_year_sib-3 //When starting pre-k
		keep if gr=="2p"
		keep if dob_relative!=.
		tab stack_year_1st_sib year if stack_year_1st_sib==year
		tab stack_year_k_sib year if stack_year_k_sib==year	
		
		forvalues y = 2012(1)2016 {
			reg score_math ABOVE dob_relative ABOVE_dob_relative if year==`y' & stack_year_k_sib==`y'
			//if `y'>=2015 reg score_math ABOVE dob_relative ABOVE_dob_relative if year==`y' & stack_year_1st_sib==`y', a(id_ie)
			}
	open
		//replace stack_year_sib = stack_year_sib-3 //When starting pre-k
		keep if gr=="4p"
		keep if dob_relative!=.
		tab stack_year_1st_sib year if stack_year_1st_sib==year
		tab stack_year_k_sib year if stack_year_k_sib==year
		
		reg score_math ABOVE dob_relative ABOVE_dob_relative if year==2018 & stack_year_k_sib==2018
		reg score_math ABOVE dob_relative ABOVE_dob_relative if abs(dob_relative)<50 & year==2018 & stack_year_k_sib==2018
		binsreg score_math dob_relative if year==2018 & stack_year_k_sib==2018, nbins(50)

		
		reg score_math ABOVE dob_relative ABOVE_dob_relative if year==2022 & stack_year_k_sib==2022
		reg score_math ABOVE dob_relative ABOVE_dob_relative if year==2018 & stack_year_k_sib==2018
		reg score_math ABOVE dob_relative ABOVE_dob_relative if year==2018 & stack_year_k_sib==2018
		
		reg score_com ABOVE dob_relative ABOVE_dob_relative if year==2018 & stack_year_k_sib==2018
		reg score_math ABOVE dob_relative ABOVE_dob_relative if year==2016 & stack_year_k_sib==2016
		reg score_com ABOVE dob_relative ABOVE_dob_relative if year==2016 & stack_year_k_sib==2016

	open
		//replace stack_year_sib = stack_year_sib-3 //When starting pre-k
		keep if gr=="2s"
		keep if dob_relative!=.
		tab prek year if prek==year
		
		reg score_math ABOVE dob_relative ABOVE_dob_relative if year==2018 & stack==(2018+3)
		reg score_math ABOVE dob_relative ABOVE_dob_relative if year==2016 & stack==(2016+3)


		
		di 2021-3
		
		
	}	
		reg age ABOVE dob_relative ABOVE_dob_relative
		

		binsreg age dob_relative, nbins(100)
		binsreg year_entry_1st dob_relative, nbins(100)
		binsreg score_math dob_relative, nbins(100)

	open
		keep if gr=="4p"
		keep if dob_relative!=.
		tab year
		

		binsreg age dob_relative, nbins(100)
		binsreg year_entry_1st dob_relative, nbins(100)
		binsreg score_math dob_relative, nbins(100)
		
		reg age ABOVE dob_relative ABOVE_dob_relative
		reg age ABOVE dob_relative ABOVE_dob_relative, a(year)
		reg year_entry_1st ABOVE dob_relative ABOVE_dob_relative
		reg year_entry_1st ABOVE dob_relative ABOVE_dob_relative, a(year)
		reg age ABOVE dob_relative ABOVE_dob_relative, a(year)
		//Why is there a slight age effect?
		
		//Is it enough to explain the math effect? ( 1.73 ~ 0.02sd) (If 1 year difference is 1sd, then .03 year (or 10 days, size of the effect) can explain that effect in math...)
		reg score_math ABOVE dob_relative ABOVE_dob_relative, a(year)
		reg score_com ABOVE dob_relative ABOVE_dob_relative, a(year)
		
		binsreg score_math dob_relative if stack_year==2015, nbins(100)
		binsreg score_math dob_relative if stack_year==2019, nbins(100)
		binsreg score_math dob_relative if stack_year==2020, nbins(100) //One year of difference in exposure to pandemic
		
		binsreg score_com dob_relative if stack_year==2015, nbins(100)
		binsreg score_com dob_relative if stack_year==2019, nbins(100)
		binsreg score_com dob_relative if stack_year==2020, nbins(100) //One year of difference in exposure to pandemic	
		
		reg score_math ABOVE dob_relative ABOVE_dob_relative if stack_year==2015, a(year)

end 


main
