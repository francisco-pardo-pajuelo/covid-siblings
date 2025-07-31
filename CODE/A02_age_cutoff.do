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

	
	*- RD with GPA
	
	first_stage //Results with RD
	
	//first_stage_1
	//first_stage_size2
	//first_stage_size3_mid
	
	*- RD with ECE
	ece_dob_prepare
	ece_dob_analysis_trend
	ece_dob_analysis_sibling
	ece_dob_analysis_own
	
	*- Mechanisms
	//Reduced parental investment (in regular times)
	ece_parental_investment_dob //Shows reduction in parental investment when school entry is delayed for a younger sibling.
	
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

	capture qui graph export "$FIGURES_TEMP\Descriptive\dob_cutoffs.png", replace			
	capture qui graph export "$FIGURES_TEMP\Descriptive\dob_cutoffs.pdf", replace	
	
	
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
	capture qui graph export "$FIGURES_TEMP\Descriptive\fs_age_cutoff_sample.png", replace			
	capture qui graph export "$FIGURES_TEMP\Descriptive\fs_age_cutoff_sample.pdf", replace	
	
	
	histogram dob_siagie_sib if abs(dob_siagie_sib-dob_siagie)>365
	capture qui graph export "$FIGURES_TEMP\Descriptive\histogra_age_cutoff_sample.png", replace			
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
					capture qui graph export "$FIGURES_TEMP\Descriptive\example_pre_covid.png", replace			
					capture qui graph export "$FIGURES_TEMP\Descriptive\example_pre_covid.pdf", replace	
		
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
					capture qui graph export "$FIGURES_TEMP\Descriptive\example_post_covid.png", replace			
					capture qui graph export "$FIGURES_TEMP\Descriptive\example_post_covid.pdf", replace	
		
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
					capture qui graph export "$FIGURES_TEMP\Descriptive\first_stage_m_`g'_`y'.png", replace			
					capture qui graph export "$FIGURES_TEMP\Descriptive\first_stage_m_`g'_`y'.pdf", replace			
	
					
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


capture program drop first_stage
program define first_stage


/*
estimates clear
 forvalues size = 2(1)3 {
 	forvalues foc_order = 1(1)2 {
		forvalues sib_order = 2(1)3 {
			
			//local size = 3
			//local foc_order = 2
			//local sib_order = 3
			
			if `foc_order'>=`sib_order' continue
			if `size' == 2 & `foc_order'==2 continue
			if `size' == 2 & `sib_order'==3 continue
			
			di "Size: `size'" _n ///
				"Foc: `foc_order'" _n ///
				"Sib: `sib_order'"

			use "$TEMP\student_sibling_combinations_dob", clear
			
			drop if fam_order_${fam_type}==fam_order_${fam_type}_sib
			keep if fam_total_${fam_type}==`size'
			keep if fam_order_${fam_type}==`foc_order'
			keep if fam_order_${fam_type}_sib==`sib_order'
			//keep if year_entry_1st_sib>=2018 & year_entry_1st_sib<=2023
			histogram dob_siagie_sib
			tempfile dob_sib
			save `dob_sib', replace
			
			use id_per_umc grade year std_gpa_?_adj using "$TEMP\siagie_append", clear
			keep id_per_umc grade year std_gpa_?_adj
			merge m:1 id_per_umc using `dob_sib', keep(master match) keepusing(year_entry_1st dob_siagie year_entry_1st_sib dob_siagie_sib dob_relative_sib)
			beep
			
			gen cutoff = .
			forvalues y = 2016(1)2023 {
				replace cutoff = ${cutoff_last_1_`y'} if year==`y'
			}
			
			//forvalues g = 3(1)4 {
				forvalues y = 2016(1)2023 {
					//local g=2
					//local y=2020
					
					di "***************" _n "Year: `y'" _n "***************"
					//local y = 2016
					preserve
						drop dob_relative_sib 
						gen dob_relative_sib = dob_siagie_sib - cutoff
						gen ABOVE= dob_relative_sib>0
						gen ABOVE_dob_relative_sib = dob_relative_sib*ABOVE
						keep if abs(dob_relative_sib)<365
						
						//drop if year_entry_1st_sib==year_entry_1st
						//keep if year_entry_1st_sib>=`y' & year_entry_1st_sib<=`y'+1
						keep if grade>=2 & grade<=6 
						keep if year==`y'
						local lab_text = "03/31/"	
						//sum dob_siagie if grade==`g' & year==`y'
						
						tab year year_entry_1st_sib
						
						*- First stage
						di as result "***************"  _n "First Stage" _n "***************" 
						binsreg year_entry_1st_sib dob_siagie_sib
						capture qui graph export "$FIGURES_TEMP\RD_age\first_stage_s`size'_`foc_order'_`sib_order'_`y'.png", replace			
						capture qui graph export "$FIGURES_TEMP\RD_age\first_stage_s`size'_`foc_order'_`sib_order'_`y'.pdf", replace	
						
						*- Histogram
						di as result "***************"  _n "Histogram" _n "***************" 
						
						histogram dob_siagie_sib
						capture qui graph export "$FIGURES_TEMP\RD_age\histogram_s`size'_`foc_order'_`sib_order'_`y'.png", replace			
						capture qui graph export "$FIGURES_TEMP\RD_age\histogram_s`size'_`foc_order'_`sib_order'_`y'.pdf", replace				
						
						*- Outcome
						di as result "***************"  _n "Plot" _n "***************" 
						
						binsreg std_gpa_`subj'_adj dob_relative_sib ///
						, ///
							nbins(50) ///
							///xlabel(${cutoff_last_1_`y'} "`lab_text'`y'") ///
							///xlabel(17622 "`lab_text'08" 17987 "`lab_text'09" 18352 "`lab_text'10" 18717 "`lab_text'11" 19083 "`lab_text'12" 19448 "`lab_text'13" 19813 "`lab_text'14" 20178 "`lab_text'15" 20544 "`lab_text'16" 20909 "`lab_text'17" 21274 "`lab_text'18" , angle(45)) ///
							xline(0, lcolor(gs12)) ///
							xtitle(Sibling Date of Birth)
							capture qui graph export "$FIGURES_TEMP\RD_age\\`subj'_s`size'_`foc_order'_`sib_order'_`y'.png", replace			
							capture qui graph export "$FIGURES_TEMP\RD_age\\`subj'_s`size'_`foc_order'_`sib_order'_`y'.pdf", replace			
						
						di as result "***************"  _n "Reg" _n "***************" 
						
						eststo rd_s`size'_`foc_order'_`sib_order'_`y': reg std_gpa_`subj'_adj ABOVE dob_relative_sib ABOVE_dob_relative_sib
							
					restore
				}
				

			capture erase "$TABLES_TEMP\rd_`subj'_s`size'_`foc_order'_`sib_order'.tex"
			
			file open  table_tex	using "$TABLES_TEMP\rd_`subj'_s`size'_`foc_order'_`sib_order'.tex", replace write
			file write table_tex	/// HEADER OPTIONS OF TABLE
							"\makebox[0.1\width][l]{" _n ///
							"\resizebox{`scale'\textwidth}{!}{" _n
			file close table_tex
			
			file open  table_tex	using "$TABLES_TEMP\rd_`subj'_s`size'_`foc_order'_`sib_order'.tex", append write
			file write table_tex	/// HEADER OPTIONS OF TABLE
							"\begin{tabular}{lcccc}" _n ///
							/// HEADER OF TABLE
							"\toprule" _n ///
							"\cmidrule(lr){2-5}" _n ///					
							"& 2018 & 2019 & 2020 & 2021 \\" _n ///
							"& (1) & (2) & (3) & (4)  \\" _n ///
							"\bottomrule" _n ///
							"&  &  &  & \\" _n 
			file close table_tex			
			
			estout   rd_s`size'_`foc_order'_`sib_order'_???? ///
			using "$TABLES_TEMP\rd_`subj'_s`size'_`foc_order'_`sib_order'.tex", ///
			append style(tex) ///
			cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
			keep(ABOVE) ///
			stats(blank_line N, fmt(%9.0fc %9.0fc ) labels(" " "Observations" ))  ///
			starlevels(* 0.10 ** 0.05 *** 0.001)
			
			file open  table_tex	using "$TABLES_TEMP\rd_`subj'_s`size'_`foc_order'_`sib_order'.tex", append write
			file write table_tex	/// HEADER OPTIONS OF TABLE							
			_n "\bottomrule" _n ///
				"\end{tabular}" _n ///
				"}" _n ///
				"}" _n
			file close table_tex				
			
				}
			}
		 }
*/	

*- Grouping Years	
/*
local rel_cutoff = "K"
local bw = "365"
local subj = "m"
local size = "a"
local foc_order = ""
local sib_order = ""
*/
foreach bw in "365" "300" "250" "200" "150" "100" "50" {
	foreach subj in "m" "c" {
		foreach size in "a" "2" "3" /*"4"*/ { //a="all"={2,3}
			foreach foc_order in "" "1" "2" "3"  {
				foreach sib_order in "" "2" "3" "4" {
					foreach rel_cutoff in "K" "1" "2" { //In order to consider other possible cutoffs
							
							
							
							
						estimates clear
						//local size = 3
						//local foc_order = 2
						//local sib_order = 3

						if !(("`size'" == "a" & "`foc_order'"=="" & "`sib_order'"=="") | ("`size'" != "a" & "`foc_order'"!="" & "`sib_order'"!="")) continue
						
						if "`size'" != "a" {
							if `foc_order'>=`sib_order' continue
							if `foc_order'>=`size'		continue
							if `sib_order'>`size'		continue
							}
							
						di 	"**************" _n ///
							"Cutoff: `rel_cutoff'" _n ///
							"Subj: `subj'" _n ///
							"Bw: `bw'" _n ///
							"Size: `size'" _n ///
							"Foc: `foc_order'" _n ///
							"Sib: `sib_order'" _n ///
							"**************"

						use "$TEMP\student_sibling_combinations_dob", clear
						
						drop if fam_order_${fam_type}==fam_order_${fam_type}_sib
						
						if "`size'" != "a" {
							keep if fam_total_${fam_type}==`size'
							keep if fam_order_${fam_type}==`foc_order'
							keep if fam_order_${fam_type}_sib==`sib_order'
							}
							
						if "`size'" == "a" {
							keep if fam_total_${fam_type}>=2 & fam_total_${fam_type}<=3
							keep if fam_order_${fam_type}<fam_order_${fam_type}_sib
							keep if fam_order_${fam_type}_sib == fam_total_${fam_type} //Base it on the youngest sibling's DOB		
						}
						
						//keep if year_entry_1st_sib>=2018 & year_entry_1st_sib<=2023
						//histogram dob_siagie_sib
						tempfile dob_sib
						save `dob_sib', replace
						
						use id_per_umc grade year std_gpa_?_adj using "$TEMP\siagie_append", clear
						keep id_per_umc grade year std_gpa_?_adj
						merge m:1 id_per_umc using `dob_sib', keep(master match) keepusing(year_entry_1st dob_siagie year_entry_1st_sib dob_siagie_sib dob_relative_sib)
						beep
						
						gen cutoff = .
						forvalues y = 2016(1)2023 {
							if "`rel_cutoff'" == "K" local cutoff_year = `y'+1
							if "`rel_cutoff'" == "1" local cutoff_year = `y'
							if "`rel_cutoff'" == "2" local cutoff_year = `y'-1	
							replace cutoff = ${cutoff_last_1_`cutoff_year'} if year==`y'
						}
						
						//forvalues g = 3(1)4 {
							foreach pair_year in /*"2016_2017"*/"18_19" "20_21" "22_23" {
								//local g=2
								//local y=2020
								
								di "***************" _n "Year: `pair_year'" _n "***************"
								//local y = 2016
								preserve
									drop dob_relative_sib 
									gen dob_relative_sib = dob_siagie_sib - cutoff
									gen ABOVE= dob_relative_sib>0
									gen ABOVE_dob_relative_sib = dob_relative_sib*ABOVE
									keep if abs(dob_relative_sib)<`bw'
									
									//drop if year_entry_1st_sib==year_entry_1st
									//keep if year_entry_1st_sib>=`y' & year_entry_1st_sib<=`y'+1
									keep if grade>=2 & grade<=6 
									if "`pair_year'" == "16_17" keep if inlist(year,2016,2017)
									if "`pair_year'" == "18_19" keep if inlist(year,2018,2019)
									if "`pair_year'" == "20_21" keep if inlist(year,2020,2021)
									if "`pair_year'" == "22_23" keep if inlist(year,2022,2023)
									local lab_text = "03/31/"	
									//sum dob_siagie if grade==`g' & year==`y'
									
									tab year year_entry_1st_sib
									
									*- First stage
									di as result "***************"  _n "First Stage" _n "***************" 
									capture binsreg year_entry_1st_sib dob_siagie_sib
									if _rc==0 { //If no error
										capture qui graph export "$FIGURES_TEMP\RD_age\first_stage_`rel_cutoff'_`subj'_`size'`foc_order'`sib_order'_`bw'_`pair_year'.png", replace			
										capture qui graph export "$FIGURES_TEMP\RD_age\first_stage_`rel_cutoff'_`subj'_`size'`foc_order'`sib_order'_`bw'_`pair_year'.pdf", replace	
										}
									*- Histogram
									di as result "***************"  _n "Histogram" _n "***************" 
									
									histogram dob_siagie_sib, xtitle("DOB younger sibling") name(histog_dob, replace)
									histogram dob_relative_sib, xtitle("DOB relative to school entry cutoff") name(histog_rel, replace)
									
									graph combine histog_dob histog_rel
									capture qui graph export "$FIGURES_TEMP\RD_age\histogram_`rel_cutoff'_`subj'_`size'`foc_order'`sib_order'_`bw'_`pair_year'.png", replace			
									capture qui graph export "$FIGURES_TEMP\RD_age\histogram_`rel_cutoff'_`subj'_`size'`foc_order'`sib_order'_`bw'_`pair_year'.pdf", replace		
									
									*- Outcome
									di as result "***************"  _n "Plot" _n "***************" 
									
									capture binsreg std_gpa_`subj'_adj dob_relative_sib ///
									, ///
										nbins(100) ///
										///xlabel(${cutoff_last_1_`y'} "`lab_text'`y'") ///
										///xlabel(17622 "`lab_text'08" 17987 "`lab_text'09" 18352 "`lab_text'10" 18717 "`lab_text'11" 19083 "`lab_text'12" 19448 "`lab_text'13" 19813 "`lab_text'14" 20178 "`lab_text'15" 20544 "`lab_text'16" 20909 "`lab_text'17" 21274 "`lab_text'18" , angle(45)) ///
										xline(0, lcolor(gs12)) ///
										xtitle(Sibling Date of Birth)
										if _rc==0 { //If no error
										capture qui graph export "$FIGURES_TEMP\RD_age\\`rel_cutoff'_`subj'_`size'`foc_order'`sib_order'_`bw'_`pair_year'.png", replace			
										capture qui graph export "$FIGURES_TEMP\RD_age\\`rel_cutoff'_`subj'_`size'`foc_order'`sib_order'_`bw'_`pair_year'.pdf", replace			
										}
									di as result "***************"  _n "Reg" _n "***************" 					
									sum std_gpa_`subj'_adj if ABOVE==0 //Counterfactual Mean
									local y_below=r(mean)		
									
									gen local_linear = 1 
									
									reghdfe std_gpa_`subj'_adj ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear, a(year)
									estadd scalar y_below `y_below'
									estadd scalar bandwidth `bw' 
									estimates store rd_`rel_cutoff'_`subj'_`size'`foc_order'`sib_order'_`bw'_`pair_year'
										
								restore
							}
							

						capture erase "$TABLES_TEMP\rd_summ_`rel_cutoff'_`subj'_`size'`foc_order'`sib_order'_`bw'.tex"
						
						file open  table_tex	using "$TABLES_TEMP\rd_summ_`rel_cutoff'_`subj'_`size'`foc_order'`sib_order'_`bw'.tex", replace write
						file write table_tex	/// HEADER OPTIONS OF TABLE
										"\makebox[0.1\width][l]{" _n ///
										"\resizebox{`scale'\textwidth}{!}{" _n
						file close table_tex
						
						file open  table_tex	using "$TABLES_TEMP\rd_summ_`rel_cutoff'_`subj'_`size'`foc_order'`sib_order'_`bw'.tex", append write
						file write table_tex	/// HEADER OPTIONS OF TABLE
										"\begin{tabular}{lccc}" _n ///
										/// HEADER OF TABLE
										"\toprule" _n ///
										"\cmidrule(lr){2-4}" _n ///	
										"& \multicolumn{3}{c}{Standardized GPA}" _n ///
										"\cmidrule(lr){2-4}" _n ///	
										"& Pre-Covid & Covid & Post-Covid  \\" _n ///
										"& 2018-2019 & 2020-2021 & 2022-2023  \\" _n ///
										"\cmidrule(lr){2-2} \cmidrule(lr){3-3} \cmidrule(lr){4-4}" _n ///	
										"& (1) & (2) & (3)  \\" _n ///
										"\bottomrule" _n ///
										"&  &  &   \\" _n 
						file close table_tex			
						
						estout   rd_`rel_cutoff'_`subj'_`size'`foc_order'`sib_order'_`bw'_??_?? ///
						using "$TABLES_TEMP\rd_summ_`rel_cutoff'_`subj'_`size'`foc_order'`sib_order'_`bw'.tex", ///
						append style(tex) ///
						cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
						keep(ABOVE) ///
						varlabels(ABOVE "Delay School (After SSA)") ///
						indicate("Local Linear" = local_linear, labels("Yes" "No")) ///
						stats(blank_line N y_below bandwidth , fmt(%9.0fc %9.0fc %9.3f %9.0fc ) labels(" " "Observations" "Counterfactual mean" "Bandwidth")) ///
						mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
						
						file open  table_tex	using "$TABLES_TEMP\rd_summ_`rel_cutoff'_`subj'_`size'`foc_order'`sib_order'_`bw'.tex", append write
						file write table_tex	/// HEADER OPTIONS OF TABLE							
						_n "\bottomrule" _n ///
							"\end{tabular}" _n ///
							"}" _n ///
							"}" _n
						file close table_tex				
					
						}
					}
				 }	
			}	
		}	
	}	
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
	capture qui graph export "$FIGURES_TEMP\Descriptive\histogram_dob_siblings_2022.png", replace
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



capture program drop ece_parental_investment_dob
program define ece_parental_investment_dob

foreach g in "2p" "4p" "2s" {

	if "`g'" == "2p" use "$TEMP\ece_family_`g'", clear
	if "`g'" == "4p" use "$TEMP\ece_family_`g'", clear
	if "`g'" == "2s" use "$TEMP\ece_student_`g'", clear

	merge 1:1 id_estudiante_`g' using "$TEMP\ece_`g'", keepusing(score_com score_math socioec_index) keep(master match) nogen
	rename (score_com score_math socioec_index) (_score_com _score_math _socioec_index)
	merge 1:1 id_estudiante_`g' using "$TEMP\em_`g'", keepusing(score_com score_math socioec_index) keep(master match) nogen
	replace score_com  = _score_com if score_com==.
	replace score_math = _score_math if score_math==.
	replace socioec_index  = _socioec_index if socioec_index==.
	drop _score* _socio*

	rename id_estudiante_`g' id_estudiante
	merge m:1 id_estudiante using "$TEMP\match_siagie_ece_`g'", keep(master match)
	keep if _m==3
	drop _m

	merge m:1 id_per_umc using "$TEMP\id_dob", keep(master match)

	keep if fam_total_${fam_type}<=4

	egen index_parent_educ_inv = rmean(freq_parent_student_edu*)


	VarStandardiz index_parent_educ_inv, by(year) newvar(std_index)
	
	keep id_per_umc year std_index score*
	tempfile ece_parental_score
	save `ece_parental_score', replace
	
	use "$TEMP\student_sibling_combinations_dob", clear	

	keep if fam_order_2!=fam_order_2_sib //Keep dob of the sibling
	keep if dob_siagie_sib!=.

	//keep if fam_total_2==2

	keep id_per_umc year_entry_1st_sib dob_siagie_sib

	merge m:1 id_per_umc using `ece_parental_score', keep(master match)
	drop _m
	
	local rel_cutoff = "1"
	local bw = 365
	gen cutoff = .
	forvalues y = 2015(1)2023 {
		if "`rel_cutoff'" == "K" local cutoff_year = `y'+1
		if "`rel_cutoff'" == "1" local cutoff_year = `y'
		if "`rel_cutoff'" == "2" local cutoff_year = `y'-1	
		replace cutoff = ${cutoff_last_1_`cutoff_year'} if year==`y'
	}	
	
	capture drop dob_relative_sib 
	gen dob_relative_sib = dob_siagie_sib - cutoff
	gen ABOVE= dob_relative_sib>0
	gen ABOVE_dob_relative_sib = dob_relative_sib*ABOVE
	keep if abs(dob_relative_sib)<`bw'	
	

	gen grade = "`g'"
	
	order 	id_per_umc year grade ///
			score_math score_com std_index ///
			dob_relative_sib ABOVE ABOVE_dob_relative_sib ///
			dob_siagie_sib year_entry_1st_sib
			
	tempfile data_`g'
	save `data_`g'', replace
}

clear
append using `data_2p'
append using `data_4p'
append using `data_2s'
	
gen local_linear = 1

binsreg score_math dob_relative_sib if inlist(year,2018,2019) & abs(dob_relative_sib)<365, nbins(100)

*- Without grade FE
reghdfe score_math 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2018,2019) & abs(dob_relative_sib)<365, a(year)
reghdfe std_index 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2022,2023) & abs(dob_relative_sib)<365, a(year)
reghdfe score_math 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2022,2023) & abs(dob_relative_sib)<365, a(year)

*- Without Year FE
reghdfe score_math 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2018,2019) & abs(dob_relative_sib)<365, a(grade)
reghdfe std_index 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2022,2023) & abs(dob_relative_sib)<365, a(grade)
reghdfe score_math 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2022,2023) & abs(dob_relative_sib)<365, a(grade)

*- With grade and year FE
reghdfe score_math 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2018,2019) & abs(dob_relative_sib)<365, a(year grade)
reghdfe std_index 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2022,2023) & abs(dob_relative_sib)<365, a(year grade)
reghdfe score_math 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2022,2023) & abs(dob_relative_sib)<365, a(year grade)
	
*- Varying Window
foreach bw in "100" "200" "300" "365" {
	reghdfe std_index 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2022,2023) & abs(dob_relative_sib)<`bw', a(year grade)
	reghdfe score_math 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2022,2023) & abs(dob_relative_sib)<`bw', a(year grade)
	}
	
*- What if we exclude 2S, only focus on Primary students

//Scores are measured with SD of 100, so we standardize them
gen std_math = (score_math-500)/100
gen std_read = (score_com-500)/100


reghdfe std_index 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2015) & abs(dob_relative_sib)<365 & inlist(grade,"2p","4p")==1, a(year grade)	
reghdfe std_index 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2022,2023) & abs(dob_relative_sib)<365 & inlist(grade,"2p","4p")==1, a(year grade)	


foreach bw in "50" "100" "200" "300" "365" {
	estimates clear
	reghdfe std_math 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2018,2019) & abs(dob_relative_sib)<`bw' & inlist(grade,"2p","4p")==1, a(year grade)
	estimates store	rd_math_pre_`bw'
	reghdfe std_read 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2018,2019) & abs(dob_relative_sib)<`bw' & inlist(grade,"2p","4p")==1, a(year grade)	
	estimates store	rd_read_pre_`bw'
	reghdfe std_math 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2022,2023) & abs(dob_relative_sib)<`bw' & inlist(grade,"2p","4p")==1, a(year grade)	
	estimates store	rd_math_post_`bw'
	reghdfe std_read 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2022,2023) & abs(dob_relative_sib)<`bw' & inlist(grade,"2p","4p")==1, a(year grade)	
	estimates store	rd_read_post_`bw'
	reghdfe std_index 	ABOVE dob_relative_sib ABOVE_dob_relative_sib local_linear if inlist(year,2022,2023) & abs(dob_relative_sib)<`bw' & inlist(grade,"2p","4p")==1, a(year grade)
	estimates store	rd_index_post_`bw'
			
	capture erase "$TABLES_TEMP\rd_ece_index_`bw'.tex"
	
	file open  table_tex	using "$TABLES_TEMP\rd_ece_index_`bw'.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\makebox[0.1\width][l]{" _n ///
					"\resizebox{`scale'\textwidth}{!}{" _n
	file close table_tex
	
	file open  table_tex	using "$TABLES_TEMP\rd_ece_index_`bw'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"& \multicolumn{2}{c}{Pre-Covid}  & \multicolumn{3}{c}{Post-Covid} \\" _n ///
					"& \multicolumn{2}{c}{2018-2019}  & \multicolumn{3}{c}{2022-2023}  \\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-6}" _n ///	
					"& Mathematics & Reading & Mathematics & Reading & Parental Investment  \\" _n ///
					"& (1) & (2) & (3) & (4) & (5) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  & &  \\" _n 
	file close table_tex			
	
	estout   rd_math_pre_`bw' rd_read_pre_`bw'  rd_math_post_`bw'   rd_read_post_`bw'  rd_index_post_`bw'  ///
	using "$TABLES_TEMP\rd_ece_index_`bw'.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(ABOVE) ///
	varlabels(ABOVE "Delay School (After SSA)") ///
	indicate("Local Linear" = local_linear, labels("Yes" "No")) ///
	stats(blank_line N y_below bandwidth , fmt(%9.0fc %9.0fc %9.3f %9.0fc ) labels(" " "Observations" "Counterfactual mean" "Bandwidth")) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)
	
	file open  table_tex	using "$TABLES_TEMP\rd_ece_index_`bw'.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule" _n ///
		"\end{tabular}" _n ///
		"}" _n ///
		"}" _n
	file close table_tex		
}
		
end	
	
	
main