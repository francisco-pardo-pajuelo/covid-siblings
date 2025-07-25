
use "$TEMP\pre_reg_covid", clear


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

	replace peso_m_4p = 1 if inlist(year,2016,2018,2024)==1 & grade==4 & peso_m_4p==.
	replace peso_c_4p = 1 if inlist(year,2016,2018,2024)==1 & grade==4 & peso_c_4p==.
	replace peso_m_2s = 1 if inlist(year,2015,2016,2018,2019)==1 & grade==8 & peso_m_2s==.
	replace peso_c_2s = 1 if inlist(year,2015,2016,2018,2019)==1 & grade==8 & peso_c_2s==.

	
	
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





		use "$TEMP\pre_reg_covid", clear
		keep if grade==2
		keep if score_math_2p != .
		keep if inlist(year,2015,2016,2018,2019,2022,2023)==1
		keep if year!=2020
		replace score_math_2p = (score_math_2p-500)/100 //standardize to reference year mean 0 and sd 1
		
		
		reg 		score_math_2p 		i.treated##i.year, robust
		
		
		
		reg 		score_math_2p 		year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated, robust
		reghdfe 	score_math_2p 		year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated, a(id_ie) vce(robust)
		reghdfe 	score_math_2p ${x}	year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated if year>2015, a(id_ie) vce(robust)
	
		preserve
		gen pop = 1 
		gen sibs = (fam_total_${fam_type}>=2)
		collapse (sum) pop (mean) score_math_2p [iw=peso_m_2p], by(id_ie year_?_?? year treated) 
		reg 	score_math_2p 		year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated [aw=pop]
		reg 	score_math_2p 		year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated [aw=pop], robust
		reghdfe 	score_math_2p 		year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated [aw=pop],  a(id_ie)
		reghdfe 	score_math_2p 		year_t_b6 year_t_b5		year_t_b4 			year_t_b2 o.year_t_o1 year_t_a2 year_t_a3 i.year treated [aw=pop], vce(robust) a(id_ie)
		restore
	
			gen pop = 1 
			gen sibs = (fam_total_${fam_type}>=2)
			collapse (sum) pop (mean) score_math_2p [iw=peso_m_2p], by(year sibs) 
			bys year (sibs): gen rel_score = score_math_2p - score_math_2p[1]
			twoway 	(line score_math_2p year if sibs==0 & year<=2019, lcolor("${red_1}")) 	///
					(line score_math_2p year if sibs==1 & year<=2019, lcolor("${blue_1}"))	///
					(line score_math_2p year if sibs==0 & year>=2020, lcolor("${red_1}")) 	///
					(line score_math_2p year if sibs==1 & year>=2020, lcolor("${blue_1}"))	///
					, ///
					xlabel(2014(1)2024) ///
					xtitle("Year") ///
					ytitle("${g${g}tit} standardize exam score") ///
					legend(order(1 "Only Childs" 2 "Children with Siblings") pos(6) col(2))	
					
			twoway 	(line rel_score year if sibs==1 & year<=2019, lcolor("${red_1}")) 	///
					(line rel_score year if sibs==1 & year>=2020, lcolor("${blue_1}"))	///
					, ///
					xlabel(2014(1)2024) ///
					xtitle("Year") ///
					ytitle("${g${g}tit} standardize exam score") ///
					legend(order(1 "Only Childs" 2 "Children with Siblings") pos(6) col(2))	
			
	