*- Only child and siblings in COVID

capture program drop main 
program define main 

	setup_COVID_A02
		
	*- Raw trends
	raw_gpa_trends siblings
	
	*- Other placebo raw trends
	raw_gpa_trends urban
	raw_gpa_trends ses
	raw_gpa_trends internet
	raw_gpa_trends parent_ed
	raw_gpa_trends both_parents
	raw_gpa_trends t_born
	raw_gpa_trends t_born_Q2

end

********************************************************************************
* Setup
********************************************************************************

capture program drop setup_COVID
program define setup_COVID

	*- Define if test run
	global covid_test = 0
	global covid_data = ""
	if ${covid_test} == 1 global covid_data = "_TEST"
	
	*- Only analyze specific outcomes
	global main_outcomes=1
	global main_outcome_1 = "std_gpa_m_adj"
	global main_outcome_2 = "" //pass_math
	global main_outcome_3 = "higher_ed_parent" //higher_ed_parent
	
	global main_loop = 0
	global main_loop_level	= "all"
	global main_loop_only_covid = "all"

	*- Global variables
	global fam_type=2
	global max_sibs = 4
	global x_all = "male_siagie urban_siagie public_siagie"
	global x_nohigher_ed = "male_siagie urban_siagie public_siagie"
	
	
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




********************************************************************************
* RAW TRENDS
********************************************************************************
capture program drop raw_ece_trends
program define raw_ece_trends

use "$TEMP\pre_reg_covid${covid_data}", clear


	global g2lab = "2p" 
	global g4lab = "4p" 
	global g6lab = "6p" 
	global g8lab = "2s" 
	
	global g2tit = "2nd grade" 
	global g4tit = "4th grade" 
	global g6tit = "6th grade" 
	global g8tit = "8th grade" 	
	
	
	

	keep fam_total_${fam_type} grade year score_*_??  peso_?_?? id_ie
	keep if inlist(grade,2,4,8)==1

	/*
	replace peso_m_4p = 1 if inlist(year,2016,2018,2024)==1 & grade==4 & peso_m_4p==.
	replace peso_c_4p = 1 if inlist(year,2016,2018,2024)==1 & grade==4 & peso_c_4p==.
	replace peso_m_2s = 1 if inlist(year,2015,2016,2018,2019)==1 & grade==8 & peso_m_2s==.
	replace peso_c_2s = 1 if inlist(year,2015,2016,2018,2019)==1 & grade==8 & peso_c_2s==.
	*/
	
	//keep if year<=2016 | year==2019
	//bys id_ie year: gen n=_n==1
	//bys id_ie : egen N=sum(n)


	
/*
	open
	local subj = `com'
	keep if score_`subj'_${g`g'lab}!=.
	keep if N==4
	collapse score_`subj'_${g`g'lab}, by(year id_ie) 
	list 

	open
	keep if N==4
	collapse score_math_${g`g'lab}, by(year) 
	list 
	 
	open
	keep if N==4
	collapse score_math_${g`g'lab} [iw=peso_m_${g`g'lab}], by(year) 
	list
*/

	
	
	
	foreach g in 2 4 8 {
		global g = `g'
		foreach subj in "com" "math" {
		preserve
			keep if inlist(grade,${g})==1
			
			keep if score_`subj'_${g${g}lab}!=.
			keep if year!=2020
			gen score_${g${g}lab} = (score_`subj'_${g${g}lab}-500)/100

			gen pop = 1 
			gen sibs = (fam_total_${fam_type}>=2)
			collapse (sum) pop (mean) score_${g${g}lab} [iw=peso_m_${g${g}lab}], by(year sibs) 
			twoway 	(line score_${g${g}lab} year if sibs==0 & year<=2019, lcolor("${red_1}")) 	///
					(line score_${g${g}lab} year if sibs==1 & year<=2019, lcolor("${blue_1}"))	///
					(line score_${g${g}lab} year if sibs==0 & year>=2020, lcolor("${red_1}")) 	///
					(line score_${g${g}lab} year if sibs==1 & year>=2020, lcolor("${blue_1}"))	///
					, ///
					xlabel(2014(1)2024) ///
					xtitle("Year") ///
					ytitle("${g${g}tit} standardize exam score") ///
					legend(order(1 "Only Childs" 2 "Children with Siblings") pos(6) col(2))

			capture qui graph export "$FIGURES\Descriptive\raw_ece_`subj'_`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\raw_ece_`subj'_`g'${covid_data}.pdf", replace		
			
			twoway 	(line pop year if sibs==0 & year<=2019, lcolor("${red_1}")) 	///
					(line pop year if sibs==1 & year<=2019, lcolor("${blue_1}"))	///
					(line pop year if sibs==0 & year>=2020, lcolor("${red_1}")) 	///
					(line pop year if sibs==1 & year>=2020, lcolor("${blue_1}"))	///
					, ///
					xlabel(2014(1)2024) ///
					xtitle("Year") ///
					ytitle("${g${g}tit} standardize exam population") /// 
					legend(order(1 "Only Childs" 2 "Children with Siblings") pos(6) col(2))				
					
			capture qui graph export "$FIGURES\Descriptive\raw_ece_pop_`subj'_`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\raw_ece_pop_`subj'_`g'${covid_data}.pdf", replace				

			bys year (sibs): gen score = score_${g${g}lab} - score_${g${g}lab}[1]		
			twoway 	(line score year if sibs==0 & year<=2019, lcolor("${red_1}")) 	///
					(line score year if sibs==1 & year<=2019, lcolor("${blue_1}"))	///
					(line score year if sibs==0 & year>=2020, lcolor("${red_1}")) 	///
					(line score year if sibs==1 & year>=2020, lcolor("${blue_1}"))	///
					, ///
					xlabel(2014(1)2024) ///
					xtitle("Year") ///
					ytitle("${g${g}tit} standardize exam score relative to only childs") /// 
					legend(order(1 "Only Childs" 2 "Children with Siblings") pos(6) col(2))
			capture qui graph export "$FIGURES\Descriptive\raw_ece_rel_`subj'_`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\raw_ece_rel_`subj'_`g'${covid_data}.pdf", replace		
		restore
		}
	}
	

end








capture program drop raw_gpa_trends
program define raw_gpa_trends

args type

	*- Primary letters
	*- Secondary numbers
	*- But secondary changed to letters starting with cohort 2013 (7th grade in 2019)
	
	local ytitle_std_gpa_m 		= "Standardized GPA"		
	local ytitle_std_gpa_c 		= "Standardized GPA"			
	local ytitle_std_gpa_m_adj 	= "Standardized GPA (adj)"		
	local ytitle_std_gpa_c_adj 	= "Standardized GPA (adj)"		
	local ytitle_pass_math = "Passed GPA"		
	local ytitle_pass_read = "Passed GPA"	
	
	local g1 "1st"
	local g2 "2nd"
	local g3 "3rd"
	local g4 "4th"
	local g5 "5th"
	local g6 "6th"
	local g7 "7th"
	local g8 "8th"
	local g9 "9th"
	local g10 "10th"
	local g11 "11th"

	use id_ie std_gpa_?* pass_math pass_read prim_on_time id_per_umc year grade treated min_socioec_index_ie_cat urban_siagie educ_cat_mother lives_with_mother lives_with_father t_born* fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid${covid_data}", clear
	
	*- School has internet
	merge m:1 id_ie using "$TEMP\school_internet", keepusing(codlocal internet) keep(master match)
	
	if "`type'"=="siblings" | "`type'"=="" {
		di "Continue, since treated is already defined as having siblings"
		local lab_control = "Only childs"
		local lab_treated = "Children with siblings"
	}
	if "`type'"=="urban" {
		drop treated
		gen treated = urban_siagie==1
		local lab_control = "Rural"
		local lab_treated = "Urban"
	}
	if "`type'"=="ses" {
		drop treated
		gen treated = inlist(min_socioec_index_ie_cat,3,4)==1 if min_socioec_index_ie_cat<=4
		local lab_control = "Low SES"
		local lab_treated = "High SES"
	}
	
	if "`type'"=="internet" {
		drop treated
		gen treated = internet==1
		local lab_control = "No Internet"
		local lab_treated = "Internet"
	}	
	
	if "`type'"=="parent_ed" {
		drop treated
		gen treated = (educ_cat_mother==3)
		local lab_control = "Mother no higher ed."
		local lab_treated = "Mother some higher ed."
	}
	
	if "`type'"=="both_parents" {
		drop treated
		gen treated = (lives_with_mother==1 & lives_with_father==1)
		local lab_control = "Does not live with both"
		local lab_treated = "Lives with both parents"
	}	
	
	if "`type'" == "t_born" {
		drop treated
		gen treated = (t_born)
		local lab_control = "Sibling born during same year"
		local lab_treated = "Sibling born next year"
	}
	
	if "`type'" == "t_born_Q2" {
		drop treated
		gen treated = (t_born_Q2)
		local lab_control = "Sibling born during same year (Q2)"
		local lab_treated = "Sibling born next year (Q2)"
	}	
		
	*- Remove early grades and years
	keep if year>=2014
	drop if grade==0	

	*- Divide sample based on expected cohort
	bys id_per_umc: egen min_year 		= min(year)
	bys id_per_umc: egen grade_min_year = min(cond(year==min_year,grade,.))
	gen proxy_1st = min_year - grade_min_year  + 1
	
	*- Collapse data
	foreach level in "all" "elm" "sec" {
	preserve 	
		if "`level'" == "elm" keep if grade>=1 & grade<=6
		if "`level'" == "sec" keep if grade>=7
		
		collapse std_gpa_m std_gpa_c std_gpa_m_adj std_gpa_c_adj pass_math pass_read prim_on_time, by(year treated)
		
		gen areax = 2019.5 if mod(_n,2)==0
		replace areax = 2021.5 if mod(_n,2)==1
		
		foreach v in /*"std_gpa_m" "std_gpa_c"*/ "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" "prim_on_time" {
			if inlist("`type'","siblings","parent_ed","both_parents","t_born","t_born_Q2")==0 & inlist("`v'","std_gpa_m","std_gpa_c","std_gpa_m_adj","std_gpa_c_adj")==1 continue
			sum `v' 
			gen miny = r(min)
			gen maxy = r(max)
			
			twoway 		///(rarea miny maxy areax if inrange(areax, 2019.5, 2021.5), color(gs15)) ///
						(line `v' year if treated==0 & year<=2019, lcolor("${red_3}")) /// 
						(line `v' year if treated==0 & year>=2020, lcolor("${red_1}")) /// 
						(line `v' year if treated==1 & year<=2019, lcolor("${blue_3}")) ///
						(line `v' year if treated==1 & year>=2020, lcolor("${blue_1}")) ///
						, ///
						xline(2019.5 2021.5, lcolor(gs8)) ///
						xlabel(2014 "14" 2015 "15" 2016 "16" 2017 "17" 2018 "18" 2019 "19" 2020 "20" 2021 "21" 2022 "22" 2023 "23" 2024 "24")  ///
						ytitle("`ytitle_`v''", size(small)) ///
						xtitle("Year") ///
						///legend(off) ///
						legend(order(2 "`lab_control'" 4 "`lab_treated'") col(3) pos(6)) ///
						name(total_`v', replace)	
					if "`type'" == "siblings" {	
						capture qui graph export "$FIGURES\Descriptive\raw_total_`level'_`v'_`type'${covid_data}.png", replace			
						capture qui graph export "$FIGURES\Descriptive\raw_total_`level'_`v'_`type'${covid_data}.pdf", replace	
					}
					if "`type'" != "siblings" {	
						capture qui graph export "$FIGURES_TEMP\Descriptive\raw_total_`level'_`v'_`type'${covid_data}.png", replace			
						capture qui graph export "$FIGURES_TEMP\Descriptive\raw_total_`level'_`v'_`type'${covid_data}.pdf", replace	
					}
						
			drop miny maxy
				}	
	restore
	}
	/*
	preserve
		collapse std_gpa_m std_gpa_c std_gpa_m_adj std_gpa_c_adj pass_math pass_read, by(year proxy_1st treated)
		
		foreach v of var std_gpa_? pass_math pass_read {
			replace `v' = . if proxy_1st == 2008 & year>=2019 //Should be 2021 but there are no grades for 2020 for 11th which is the on time grade for cohort 2010, so all left are delayed students
			replace `v' = . if proxy_1st == 2009 & year>=2020 //Should be 2021 but there are no grades for 2020 for 11th which is the on time grade for cohort 2010, so all left are delayed students
			replace `v' = . if proxy_1st == 2010 & year>=2020 //Should be 2021 but there are no grades for 2020 for 11th which is the on time grade for cohort 2010, so all left are delayed students
			replace `v' = . if proxy_1st == 2011 & year>=2022
			replace `v' = . if proxy_1st == 2012 & year>=2023
			replace `v' = . if proxy_1st == 2013 & year>=2024
		}
		
		*- All individual plots	
		
		gen areax = 2019.5 if mod(_n,2)==0
		replace areax = 2021.5 if mod(_n,2)==1
		
		forvalues y = 2008(1)2018 {
			foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" {
				sum `v' if proxy_1st>=2008 & proxy_1st<=2018 & `v'!=. & year>=2014 & year<=2024
				gen miny = r(min)
				gen maxy = r(max)
				twoway 	(rarea miny maxy areax if inrange(areax, 2019.5, 2021.5), color(gs15)) ///
						(line `v' year if proxy_1st == `y' & treated==0 & year<=2019, lcolor("${red_1}")) /// 
						(line `v' year if proxy_1st == `y' & treated==0 & year>=2020, lcolor("${red_1}")) /// 
						(line `v' year if proxy_1st == `y' & treated==1 & year<=2019, lcolor("${blue_1}")) ///
						(line `v' year if proxy_1st == `y' & treated==1 & year>=2020, lcolor("${blue_1}")) ///
						, ///
						xline(2019.5) ///
						xlabel(2014 "14" 2015 "15" 2016 "16" 2017 "17" 2018 "18" 2019 "19" 2020 "20" 2021 "21" 2022 "22" 2023 "23" 2024 "24")  ///
						ytitle("`ytitle_`v''", size(small)) ///
						xtitle("Year") ///
						subtitle("`y' cohort") ///
						legend(off) ///
						///legend(order(1 "Only childs" 3 "Children with siblings") col(3) pos(6)) ///
						name(`v'_`y', replace)	
				drop miny maxy
					}
				}
		
		foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" {
		graph combine   `v'_2010 	///
						`v'_2011 `v'_2012 	///
						`v'_2013 `v'_2014 	///
						`v'_2015 `v'_2016 	///
						`v'_2017 `v'_2018 	///
						, 				///
						col(3) ///
						xsize(40) ///
						ysize(30) 
						
			///graph save "$FIGURES\raw_m.gph" , replace	
			///capture qui graph export "$FIGURES\raw_m.eps", replace	
			capture qui graph export "$FIGURES\Descriptive\raw_cohorts_`v'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\raw_cohorts_`v'${covid_data}.pdf", replace	
		}	
	restore
	*/
	
	preserve
		collapse std_gpa_m std_gpa_c std_gpa_m_adj std_gpa_c_adj pass_math pass_read prim_on_time, by(year grade treated)
		
		/*
		foreach v of var std_gpa_? pass_math pass_read {
			replace `v' = . if proxy_1st == 2008 & year>=2019 
			replace `v' = . if proxy_1st == 2009 & year>=2020 
			replace `v' = . if proxy_1st == 2010 & year>=2020 
			replace `v' = . if proxy_1st == 2011 & year>=2022
			replace `v' = . if proxy_1st == 2012 & year>=2023
		}
		*/
		
		*- All individual plots	
		
		gen areax = 2019.5 if mod(_n,2)==0
		replace areax = 2021.5 if mod(_n,2)==1
		
		forvalues g = 1(1)11 {
			foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" "prim_on_time" {
				if inlist("`type'","siblings","parent_ed","both_parents")==0 & inlist("`v'","std_gpa_m","std_gpa_c","std_gpa_m_adj","std_gpa_c_adj")==1 continue
				sum `v' if grade>=1 & grade<=11 & `v'!=. & year>=2014 & year<=2024
				gen miny = r(min)
				gen maxy = r(max)
				twoway 	///(rarea miny maxy areax if inrange(areax, 2019.5, 2021.5), color(gs15)) ///
						(line `v' year if grade == `g' & treated==0 & year<=2019, lcolor("${red_1}")) /// 
						(line `v' year if grade == `g' & treated==0 & year>=2020, lcolor("${red_1}")) /// 
						(line `v' year if grade == `g' & treated==1 & year<=2019, lcolor("${blue_1}")) ///
						(line `v' year if grade == `g' & treated==1 & year>=2020, lcolor("${blue_1}")) ///
						, ///
						xline(2019.5 2021.5, lcolor(gs8)) ///
						xlabel(2014 "14" 2015 "15" 2016 "16" 2017 "17" 2018 "18" 2019 "19" 2020 "20" 2021 "21" 2022 "22" 2023 "23" 2024 "24")  ///
						ytitle("`ytitle_`v''", size(small)) ///
						xtitle("Year") ///
						subtitle("`g`g'' grade") ///
						legend(off) ///
						///legend(order(1 "Only childs" 3 "Children with siblings") col(3) pos(6)) ///
						name(`v'_`g', replace)	
				drop miny maxy
					}
				}
		
		foreach v in "std_gpa_m" "std_gpa_c" "std_gpa_m_adj" "std_gpa_c_adj" "pass_math" "pass_read" "prim_on_time" {
			if inlist("`type'","siblings","parent_ed","both_parents")==0 & inlist("`v'","std_gpa_m","std_gpa_c","std_gpa_m_adj","std_gpa_c_adj")==1 continue
			graph combine   `v'_1 	///
							`v'_2 `v'_3 	///
							`v'_4 `v'_5 	///
							`v'_6 `v'_7 	///
							`v'_8 `v'_9 	///
							`v'_10 `v'_11 	///
							, 				///
							col(3) ///
							xsize(40) ///
							ysize(40) 
							
				///graph save "$FIGURES\raw_m.gph" , replace	
				///capture qui graph export "$FIGURES\raw_m.eps", replace	
				if "`type'" == "siblings" {
					capture qui graph export "$FIGURES\Descriptive\raw_grades_`v'_`type'${covid_data}.png", replace			
					capture qui graph export "$FIGURES\Descriptive\raw_grades_`v'_`type'${covid_data}.pdf", replace	
					}
					
				if "`type'" != "siblings" {
					capture qui graph export "$FIGURES_TEMP\Descriptive\raw_grades_`v'_`type'${covid_data}.png", replace			
					capture qui graph export "$FIGURES_TEMP\Descriptive\raw_grades_`v'_`type'${covid_data}.pdf", replace	
					}				
			}
			
	restore
		
end


********************************************************************************
* Grade distributions
********************************************************************************

capture program drop raw_histograms
program define raw_histograms	

	use std_gpa_? math comm pass_math pass_read id_per_umc year grade treated fam_order_${fam_type} fam_total_${fam_type} ${x} using "$TEMP\pre_reg_covid${covid_data}", clear
	
	*- Aggregate: Elementary
	twoway 	(histogram math if inlist(grade,1,2,3,4,5,6)==1 & (inlist(year,2019)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
			(histogram math if inlist(grade,1,2,3,4,5,6)==1 & (inlist(year,2019)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
			, ///
			/// legend(order(1 "No siblings" 2 "1 sibling" 3 "2 siblings" 4 "3 siblings") pos(6) col(4))
			legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
			xtitle("Mathematics grade") ///
			xlabel(1 "D" 2 "C" 3 "B" 4 "A")
	capture qui graph export "$FIGURES\Descriptive\histogram_pre_elm${covid_data}.png", replace			
	capture qui graph export "$FIGURES\Descriptive\histogram_pre_elm${covid_data}.pdf", replace	
	
	twoway 	(histogram math if inlist(grade,1,2,3,4,5,6)==1 & (inlist(year,2020)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
			(histogram math if inlist(grade,1,2,3,4,5,6)==1 & (inlist(year,2020)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
			, ///
		legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
		xtitle("Mathematics grade") ///
		xlabel(1 "D" 2 "C" 3 "B" 4 "A") 
	capture qui graph export "$FIGURES\Descriptive\histogram_post_elm${covid_data}.png", replace			
	capture qui graph export "$FIGURES\Descriptive\histogram_post_elm${covid_data}.pdf", replace	
	
	
	*- Aggregate: High school
	twoway 	(histogram math if inlist(grade,9,10)==1 & (inlist(year,2019)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
			(histogram math if inlist(grade,9,10)==1 & (inlist(year,2019)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
			, ///
			/// legend(order(1 "No siblings" 2 "1 sibling" 3 "2 siblings" 4 "3 siblings") pos(6) col(4))
			legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
			xtitle("Mathematics grade") 
	capture qui graph export "$FIGURES\Descriptive\histogram_pre_9-10${covid_data}.png", replace			
	capture qui graph export "$FIGURES\Descriptive\histogram_pre_9-10${covid_data}.pdf", replace	
	
	twoway 	(histogram math if inlist(grade,9,10)==1 & (inlist(year,2020)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
			(histogram math if inlist(grade,9,10)==1 & (inlist(year,2020)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
			///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
			, ///
		legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
		xtitle("Mathematics grade")
	capture qui graph export "$FIGURES\Descriptive\histogram_post_9-10${covid_data}.png", replace			
	capture qui graph export "$FIGURES\Descriptive\histogram_post_9-10${covid_data}.pdf", replace		
	
	
	*- Grade by grade
	forvalues g = 1/7 {
		twoway 	(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
				(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
				, ///
				/// legend(order(1 "No siblings" 2 "1 sibling" 3 "2 siblings" 4 "3 siblings") pos(6) col(4))
				legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
				xtitle("Mathematics grade") ///
				xlabel(1 "D" 2 "C" 3 "B" 4 "A")
			capture qui graph export "$FIGURES\Descriptive\histogram_pre_grade`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\histogram_pre_grade`g'${covid_data}.pdf", replace	
			
		twoway 	(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
				(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
				, ///
				legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
				xtitle("Mathematics grade") ///
				xlabel(1 "D" 2 "C" 3 "B" 4 "A") 
			capture qui graph export "$FIGURES\Descriptive\histogram_post_grade`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\histogram_post_grade`g'${covid_data}.pdf", replace				
		}
		
	forvalues g = 9/10 {
		twoway 	(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
				(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2019)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
				, ///
				legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
				xtitle("Mathematics grade") ///
				xline(10.5)
			capture qui graph export "$FIGURES\Descriptive\histogram_pre_grade`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\histogram_pre_grade`g'${covid_data}.pdf", replace	
			
		twoway 	(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==1, lcolor("${red_1}%40") fcolor("${red_1}%40") discrete fraction) ///
				(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}>=2, lcolor("${blue_1}%40") fcolor("${blue_1}%40") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==3, lcolor(gs0) fcolor("${blue_2}%20") discrete fraction) ///
				///(histogram math if grade==`g' & (inlist(year,2020)==1)  & fam_total_${fam_type}==4, lcolor(gs0) fcolor("${blue_3}%20") discrete fraction) ///
				, ///
				legend(order(1 "No siblings" 2 "Siblings") pos(6) col(2)) ///
				xtitle("Mathematics grade") ///
				xline(10.5)
			capture qui graph export "$FIGURES\Descriptive\histogram_post_grade`g'${covid_data}.png", replace			
			capture qui graph export "$FIGURES\Descriptive\histogram_post_grade`g'${covid_data}.pdf", replace				
		}		
		
end




//main
