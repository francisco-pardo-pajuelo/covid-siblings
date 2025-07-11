*- This is the event study but by year and by grade. Eventually add it to the other analysis.



//local area 			= "rur"
//local hed_parent 	= "no"
local level 		= "all"
//local res 			= "nint"

global x_all = "male_siagie urban_siagie higher_ed_parent"
global x_nohigher_ed = "male_siagie urban_siagie"

/*
use std_gpa_m id_per_umc year_t_?? urban_siagie higher_ed_parent has_internet has_comp low_ses quiet_room year grade treated post treated_post  id_ie fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid", clear

drop if grade==0

bys id_per_umc: egen year_1st 	= min(cond(grade==1,year,.))
bys id_per_umc: egen grade_2016	= max(cond(year==2016,grade,.))

bys id_per_umc: egen min_grade 		= min(grade)
bys id_per_umc: egen year_min_grade = min(cond(grade==min_grade,year,.))

//Expected grade based on first year in primary			
gen grade_exp = year-year_1st+1 
tab grade_exp grade

//Expected grade based on first year and grade observed (proxy because it could've repeated before.)
gen grade_exp_proxy = year-year_min_grade+min_grade

gen on_time 		=  (grade_exp==grade)
gen on_time_proxy 	=  (grade_exp_proxy==grade)

tab grade year    if year_1st==2017 & year>=2017 & fam_total_2==1 & has_internet!=.

reghdfe std_gpa_m			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year_1st==2017 & year>=2017 &  has_internet!=., a(year grade id_ie)

*/

//Why delayed students in 2019 (should be in 3rd grade). 
//Because 'internet' or survey happens in 2nd grade, and hence since these are OC, they have to be the respondents and for that they need to be in 2nd grade in 2019 since that is a survey year.
//What if we only include those on time?


//colorpalette  HCL blues, selec(1 4 6 8 10 12) nograph
colorpalette  HCL blues, selec(1 6 10) nograph
return list

local blue_1 = "`r(p1)'"
local blue_2 = "`r(p2)'"
local blue_3 = "`r(p3)'"
//local blue_4 = "`r(p4)'"
//local blue_5 = "`r(p5)'"
//local blue_6 = "`r(p6)'"

//colorpalette  HCL reds, selec(1 4 6 8 10 12) nograph
colorpalette  HCL reds, selec(1 6 11) nograph
return list

local red_1 = "`r(p1)'"
local red_2 = "`r(p2)'"
local red_3 = "`r(p3)'"
//local red_4 = "`r(p4)'"
//local red_5 = "`r(p5)'"
//local red_6 = "`r(p6)'"

foreach v in "std_gpa_m" "std_gpa_c" /*"higher_ed_parent"*/ {
	foreach area in "all" "urb" "rur"  {
		foreach res in "all" "alls" "nint" { 
			
			global x = "$x_all"
			if "`v'" == "higher_ed_parent" global x = "$x_nohigher_ed"
			 
			estimates clear
			use `v' id_per_umc year_t_?? urban_siagie higher_ed_parent has_internet has_comp low_ses quiet_room year grade treated post treated_post  id_ie fam_order_${fam_type} fam_total_${fam_type} ${x_all} using "$TEMP\pre_reg_covid", clear
					
			di as result "*******************************"
			di as text "`v' - `area' - `res'"
			di as result "*******************************"
		
			drop if grade==0

			bys id_per_umc: egen year_1st 	= min(cond(grade==1,year,.))
			//bys id_per_umc: egen grade_2016	= max(cond(year==2016,grade,.))
			bys id_per_umc: egen grade_2019	= max(cond(year==2019,grade,.))

			bys id_per_umc: egen min_grade 		= min(grade)
			bys id_per_umc: egen year_min_grade = min(cond(grade==min_grade,year,.))

			//Expected grade based on first year in primary			
			gen grade_exp = year-year_1st+1 
			tab grade_exp grade

			//Expected grade based on first year and grade observed (proxy because it could've repeated before.)
			gen grade_exp_proxy = year-year_min_grade+min_grade

			*- On time variables
			gen byte on_time 		=  (grade_exp==grade)		if grade_exp!=.
			gen byte on_time_proxy 	=  (grade_exp_proxy==grade)	if grade_exp_proxy!=.
			
			drop min_grade year_min_grade grade_exp grade_exp_proxy on_time
			compress
			
			keep if year>=2015
			
			/*
			bys id_per_umc: egen year_1st 	= min(cond(grade==1,year,.))
			bys id_per_umc: egen grade_2016	= max(cond(year==2016,grade,.))
			*/
			if "`area'" == "rur" keep if urban_siagie == 0
			if "`area'" == "urb" keep if urban_siagie == 1
			
			if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
			if "`hed_parent'" == "ys" 	keep if higher_ed_parent == 1
			
			if "`level'" == "all" keep if grade>=1 & grade<=11
			if "`level'" == "elm" keep if grade>=1 & grade<=6
			if "`level'" == "sec" keep if grade>=7
			
			if "`res'" == "all" 		keep if 1==1
			if "`res'" == "alls" 		keep if has_internet!=.
			if "`res'" == "nint" 		keep if has_internet==0
			if "`res'" == "ncom" 		keep if has_comp==0
			if "`res'" == "lses" 		keep if low_ses==1
			if "`res'" == "nqui" 		keep if quiet_room==0
			
			if "`res'" != "all" 		keep if on_time_proxy==1
			
			if "`v'" == "std_gpa_m" {
				local vlab = "m"
				local tlab = "Standardized mathematics GPA"
			}
			if "`v'" == "std_gpa_c" {
				local vlab = "c"
				local tlab = "Standardized reading GPA"
			}
			if "`v'" == "higher_ed_parent" {
				local vlab = "hed"
				local tlab = "Has parent with higher education"
			}			
			
			keep `v' /*event*/ year_t_?? treated /*covariates*/ ${x} /*conditional*/ year_1st grade_2019 /*FE*/ year grade id_ie
			
			*- Results by cohort
			reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(year_1st,2015,2016,2017,2018) & year>=2015, a(year grade id_ie)
			estimates store c_all_`res'_`area'_`vlab'
			
			reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year_1st==2014 & year>=2015, a(year grade id_ie)
			estimates store c_2014_`res'_`area'_`vlab'
			
			reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year_1st==2015 & year>=2015, a(year grade id_ie)
			estimates store c_2015_`res'_`area'_`vlab'
			
			reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year_1st==2016 & year>=2016, a(year grade id_ie)
			estimates store c_2016_`res'_`area'_`vlab'
			
			reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year_1st==2017 & year>=2017, a(year grade id_ie)
			estimates store c_2017_`res'_`area'_`vlab'
			
			reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if year_1st==2018 & year>=2018, a(year grade id_ie)
			estimates store c_2018_`res'_`area'_`vlab'
			
			
			local add_coef = ""
			//if "`res'" == "all" local add_coef = `"(c_2017*, drop(year_t_b6 year_t_b5 year_t_b4) mcolor("`blue_4'") ciopts(bcolor("`blue_4'")))"'
			
			if "`res'" == "all" {
			coefplot 	(c_all*, 													mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
						///(c_2013*, drop(year_t_b6) 									mcolor("`blue_1'") ciopts(bcolor("`blue_1'"))) ///
						(c_2014*, drop(year_t_b6)									mcolor("`blue_2'") ciopts(bcolor("`blue_2'")) lcolor("`blue_2'")) ///
						(c_2015*, drop(year_t_b6)									mcolor("`blue_3'") ciopts(bcolor("`blue_3'")) lcolor("`blue_3'")) ///
						(c_2016*, drop(year_t_b6 year_t_b5)							mcolor("`red_3'") ciopts(bcolor("`red_3'")) lcolor("`red_3'")) ///
						(c_2017*, drop(year_t_b6 year_t_b5 year_t_b4) 				mcolor("`red_2'") ciopts(bcolor("`red_2'")) lcolor("`red_2'")) /// 2007 not included for survey sample since that cohort wouldn't be surveyed in 2nd or 4th grade.
						(c_2018*, drop(year_t_b6 year_t_b5 year_t_b4 year_t_b3) 	mcolor("`red_1'") ciopts(bcolor("`red_1'")) lcolor("`red_1'")), ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						drop(year_t_b6) ///
						leg(order(1 "All" 3 "2014" 5 "2015" 7 "2016" 9 "2017" 11 "2018")) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
						yline(0,  lcolor(gs10))  ///
						ytitle("Effect") ///
						ylab(-.1(.02).04) ///
						subtitle("`tlab' by year in 1st grade") ///
						legend(pos(6) col(6)) ///
						name(check_cohorts,replace)	
				}
				
			if "`res'" != "all" {
			coefplot 	(c_all*, 													mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
						///(c_2013*, drop(year_t_b6) 									mcolor("`blue_1'") ciopts(bcolor("`blue_1'"))) ///
						(c_2014*, drop(year_t_b6)									mcolor("`blue_2'") ciopts(bcolor("`blue_2'")) lcolor("`blue_2'")) ///
						(c_2015*, drop(year_t_b6)									mcolor("`blue_3'") ciopts(bcolor("`blue_3'")) lcolor("`blue_3'")) ///
						(c_2016*, drop(year_t_b6 year_t_b5)							mcolor("`red_3'") ciopts(bcolor("`red_3'")) lcolor("`red_3'")) ///
						(c_2018*, drop(year_t_b6 year_t_b5 year_t_b4 year_t_b3) 	mcolor("`red_1'") ciopts(bcolor("`red_1'")) lcolor("`red_1'")) ///
						, ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						drop(year_t_b6) ///
						leg(order(1 "All" 3 "2014" 5 "2015" 7 "2016" 9 "2018")) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
						yline(0,  lcolor(gs10))  ///
						ytitle("Effect") ///
						ylab(-.1(.02).04) ///
						subtitle("`tlab' by year in 1st grade") ///
						legend(pos(6) col(6)) ///
						name(check_cohorts,replace)	
				}				
						
			capture qui graph export "$FIGURES\COVID\covid_cohort_`res'_`area'_`v'.png", replace				
					
			coefplot 	(c_all*, 													mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
						, ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						drop(year_t_b6) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
						yline(0,  lcolor(gs10))  ///
						ytitle("Effect") ///
						ylab(-.1(.02).04) ///
						subtitle("`tlab'") ///
						legend(off) 		
						
			capture qui graph export "$FIGURES\COVID\covid_cohort_full_`res'_`area'_`v'.png", replace				
					
						
			*- Results by grade in 2016
			//reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(grade_2016,1,2,3,4,5), a(year grade id_ie)
			reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if inlist(grade_2019,2,4,5,6,7), a(year grade id_ie)
			estimates store g_all_`res'_`area'_`vlab'
				
			reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==2 & year>=2018, a(year grade id_ie)
			estimates store g_2_`res'_`area'_`vlab'
			
			reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==4 & year>=2016, a(year grade id_ie)
			estimates store g_4_`res'_`area'_`vlab'

			reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==5, a(year grade id_ie)
			estimates store g_5_`res'_`area'_`vlab'

			reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==6, a(year grade id_ie)
			estimates store g_6_`res'_`area'_`vlab'

			reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2019==7, a(year grade id_ie)
			estimates store g_7_`res'_`area'_`vlab'
			/*
			if "`res'" == "all" {
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade_2016==5, a(year grade id_ie)
				estimates store g_5_`res'_`area'_`vlab'				
				}
			*/
			coefplot 	(g_all*,												mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
						(g_2_*, drop(year_t_b6 year_t_b5 year_t_b4 year_t_b3)	mcolor("`red_1'") ciopts(bcolor("`red_1'")) lcolor("`red_1'")) ///
						(g_4_*, drop(year_t_b6 year_t_b5)						mcolor("`red_3'") ciopts(bcolor("`red_3'")) lcolor("`red_3'")) ///
						(g_5_*, drop(year_t_b6)									mcolor("`blue_3'") ciopts(bcolor("`blue_3'")) lcolor("`blue_3'")) ///
						(g_6_*,													mcolor("`blue_2'") ciopts(bcolor("`blue_2'")) lcolor("`blue_2'")) ///
						(g_7_*,													mcolor("`blue_1'") ciopts(bcolor("`blue_1'")) lcolor("`blue_1'")) ///
						, ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						drop(year_t_b6) ///
						leg(order(1 "All" 3 "2nd" 5 "4th" 7 "5th" 9 "6th" 11 "7th" /*11 "5th"*/)) ///
						/// leg(order(1 "All" 3 "1st" 5 "2nd" 7 "3rd" 9 "4th" /*11 "5th"*/)) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
						yline(0,  lcolor(gs10))  ///
						ytitle("Effect") ///
						ylab(-.1(.02).04) ///
						subtitle("`tlab' by grade in 2019") ///
						legend(pos(6) col(6)) ///
						name(check_cohorts,replace)		
						
			capture qui graph export "$FIGURES\COVID\covid_grade_`res'_`area'_`v'.png", replace	
			
			coefplot 	(g_all*, 													mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)) ///
						, ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						drop(year_t_b6) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
						yline(0,  lcolor(gs10))  ///
						ytitle("Effect") ///
						ylab(-.1(.02).04) ///
						subtitle("`tlab'") ///
						legend(off) 		
						
			capture qui graph export "$FIGURES\COVID\covid_grade_full_`res'_`area'_`v'.png", replace					
			
			
			reghdfe `v' 			year_t_b6 year_t_b5 year_t_b4 year_t_b3 o.year_t_b2 year_t_o1 year_t_a?  treated ${x} if inlist(grade_2019,2,4,5,6,7), a(year grade id_ie)
			estimates store test
			
						coefplot 	(test, mcolor(gs0) ciopts(bcolor(gs0)) lcolor(gs0)), ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						drop(year_t_b6) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
						yline(0,  lcolor(gs10))  ///
						ytitle("Effect") ///
						ylab(-.1(.02).04) ///
						subtitle("`tlab' by grade in 2019") ///
						legend(pos(6) col(6))
						
			capture qui graph export "$FIGURES\COVID\test_grade_`res'_`area'_`v'.png", replace	
			
		}
	}
}								