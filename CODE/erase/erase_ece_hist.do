*- Only child and siblings in COVID

capture program drop main 
program define main 

	setup_COVID_ECE
	
	ece_compile
	
	ece_trends
	
end

/*
2P-2S: 2016 - 2022
4P-2S: 2018/2019-2022/2023
2P-6P: 2018 2022
*/

********************************************************************************
* Setup
********************************************************************************

capture program drop setup_COVID_ECE
program define setup_COVID_ECE

	
	global fam_type=2
	
	global max_sibs = 4

	global x_all = "male_siagie urban_siagie higher_ed_parent"
	global x_nohigher_ed = "male_siagie urban_siagie"
	/*
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
	*/
	
end




********************************************************************************
* ECE - 1
********************************************************************************

capture program drop ece_compile
program define ece_compile


	*- ECE historic plot:
	global g2lab = "2p" 
	global g4lab = "4p" 
	global g6lab = "6p" 
	global g8lab = "2s" 
	// ${g`g'lab}

	use "$TEMP\match_siagie_ece_2p", clear
	gen grade = 2
	rename id_estudiante id_estudiante_2p
	append using "$TEMP\match_siagie_ece_4p" 
	replace grade = 4 if grade==.
	rename id_estudiante id_estudiante_4p

	append using "$TEMP\match_siagie_ece_2s" 
	replace grade = 8 if grade==.
	rename id_estudiante id_estudiante_2s


	gen year = substr(id_estudiante_2p,1,4)
	replace year = substr(id_estudiante_4p,1,4) if year==""
	replace year = substr(id_estudiante_2s,1,4) if year==""
	destring year, replace

	preserve
			use "$TEMP\id_siblings", clear
			keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}	
			tempfile id_siblings_sample
			save `id_siblings_sample', replace
	restore

	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}) 
	rename _m merge_siblings

	
	foreach g in "2" "4" "8"  {	
		merge m:1 id_estudiante_${g`g'lab} year using "$TEMP\ece_${g`g'lab}", update keep(master match match_update) keepusing(id_ie score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat)
		drop _m
		merge m:1 id_estudiante_${g`g'lab} year using "$TEMP\ece_${g`g'lab}", update keep(master match match_update) keepusing(id_ie score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat)
		drop _m
		merge m:1 id_estudiante_${g`g'lab} year using "$TEMP\ece_${g`g'lab}", update keep(master match match_update) keepusing(id_ie score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat)
		drop _m	
		
		merge m:1 id_estudiante_${g`g'lab} year using  "$TEMP\em_${g`g'lab}", update keep(master match match_update) keepusing(id_ie score_math_std score_com_std score_acad_std label_m label_c  socioec_index socioec_index_cat) //m:1 because there are missings	
		drop _m
		merge m:1 id_estudiante_${g`g'lab} year using  "$TEMP\em_${g`g'lab}", update keep(master match match_update) keepusing(id_ie score_math_std score_com_std score_acad_std label_m label_c  socioec_index socioec_index_cat) //m:1 because there are missings
		drop _m
		merge m:1 id_estudiante_${g`g'lab} year using  "$TEMP\em_${g`g'lab}", update keep(master match match_update) keepusing(id_ie score_math_std score_com_std score_acad_std label_m label_c  socioec_index socioec_index_cat) //m:1 because there are missings	
		drop _m
	}
	
	gen satisf_m = label_m==4 if label_m!=.
	gen satisf_c = label_c==4 if label_c!=.
			
	gen init_m = inlist(label_m,1,2)==1 if label_m!=.
	gen init_c = inlist(label_c,1,2)==1 if label_c!=.
	
	compress
	
	drop id_estudiante_*
	keep if merge_siblings==3
	drop merge_siblings
	
	order id_per_umc id_per_umc id_ie year grade source id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type}, last
	order educ_caretaker educ_mother educ_father socioec_index socioec_index_cat, last
	order score* label* satisf* init*, last
	
	close
	
	
	
	
	
end 

capture program drop ece_trends 
program define ece_trends 

	open 
	
	tab fam_total_${fam_type}
	keep if fam_total_${fam_type}<=4
	
	gen pop = 1 
	
	reghdfe satisf_m i.fam_total_${fam_type} i.year i.educ_mother i.educ_father if grade==2, a(id_ie)
	reghdfe satisf_m i.fam_total_${fam_type} i.year i.educ_mother i.educ_father if grade==4, a(id_ie)
	reghdfe satisf_m i.fam_total_${fam_type} i.year i.educ_mother i.educ_father if grade==8, a(id_ie)

	/
	collapse (mean) score_*_std satisf* init* socioec_index (sum) pop, by(grade year fam_total_${fam_type})
	
	
	graph bar satisf_m if grade==2, ///
		by(year) over(fam_total_${fam_type}) ///
		legend(order(1 "${g1l} grade (Pre covid)" 2 "${g2l} grade (Post covid)") pos(6) col(2))

end	


capture program drop ece_baseline
program define ece_baseline 

	open 
	
	keep score_com_std score_math_std score_acad_std satisf_m satisf_c init_m init_c socioec_index socioec_index_cat id_per_umc id_ie year source educ_caretaker educ_mother educ_father grade fam_total_${fam_type}
	reshape wide score_com_std score_math_std score_acad_std satisf_m satisf_c init_m init_c socioec_index socioec_index_cat year id_ie source ,i(id_per_umc educ_caretaker educ_mother educ_father fam_total_${fam_type}) j(grade)
	
	tab fam_total_${fam_type}
	keep if fam_total_${fam_type}<=4
	
	gen sibs = inlist(fam_total_${fam_type},2,3,4) == 1 
	
	local g0 = 2
	local g1 = 8
	reghdfe score_com_std`g1' i.fam_total_${fam_type} score_com_std`g0' i.year`g0' i.educ_mother i.educ_father if year`g1'<=2019, a(id_ie`g0')
	reghdfe score_com_std`g1' i.fam_total_${fam_type} score_com_std`g0' i.year`g0' i.educ_mother i.educ_father if year`g1'>=2020, a(id_ie`g0')	
	
	local g0 = 4
	local g1 = 8
	reghdfe score_com_std`g1' i.fam_total_${fam_type} score_com_std`g0' i.year`g0' i.educ_mother i.educ_father if year`g1'<=2019, a(id_ie`g0')
	reghdfe score_com_std`g1' i.fam_total_${fam_type} score_com_std`g0' i.year`g0' i.educ_mother i.educ_father if year`g1'>=2020, a(id_ie`g0')	
	
	
	local g0 = 2
	local g1 = 8
	gen post = year`g1'>=2020 if year`g1'!=.
	reg score_com_std`g1' score_com_std`g0' i.post
	reg score_math_std`g1' score_math_std`g0' i.post
	reg score_com_std`g1' score_com_std`g0' i.post##i.sibs
	reg score_math_std`g1' score_math_std`g0' i.post##i.sibs
	capture drop post

/*
	local g0 = 2
	local g1 = 4
	gen post = year`g1'>=2020 if year`g1'!=.
	reg score_com_std`g1' score_com_std`g0' i.post##i.sibs
	capture drop post	
	
	
	local g0 = 4
	local g1 = 8
	gen post = year`g1'>=2020 if year`g1'!=.
	reg score_com_std`g1' score_com_std`g0' i.post##i.sibs
	capture drop post	
*/	
	//gen score_com_std = score_com_std`g1' - score_com_std`g0' 
	
	//reg score_com_std i.post##i.fam_total_${fam_type}, vce(cluster id_ie`g1')
	//reg score_com_std i.post##i.sibs, vce(cluster id_ie`g1')
	
	capture drop post score_
	
	reghdfe 	
	
	
	
	gen pop = 1 
	
	reghdfe satisf_m i.fam_total_${fam_type} i.year i.educ_mother i.educ_father if grade==2, a(id_ie)
	reghdfe satisf_m i.fam_total_${fam_type} i.year i.educ_mother i.educ_father if grade==4, a(id_ie)
	reghdfe satisf_m i.fam_total_${fam_type} i.year i.educ_mother i.educ_father if grade==8, a(id_ie)

	/
	collapse (mean) score_*_std satisf* init* socioec_index (sum) pop, by(grade year fam_total_${fam_type})
	
	
	graph bar satisf_m if grade==2, ///
		by(year) over(fam_total_${fam_type}) ///
		legend(order(1 "${g1l} grade (Pre covid)" 2 "${g2l} grade (Post covid)") pos(6) col(2))

end	
		
		
		
main	
	

/	
	
	
	*- Match ECE exams
	foreach g in "2" "4" "8"  {	
		merge m:1 id_estudiante_${g`g'lab} year using "$TEMP\ece_${g`g'lab}", keep(master match) keepusing(score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat) //m:1 because there are missings
		rename _m merge_ece_`g'
	}


	*- Match EM exams
	foreach g in "2" "4" "8"  {
		merge m:1 id_estudiante_${g`g'lab} year using  "$TEMP\em_${g`g'lab}", keep(master match) keepusing(score_math_std score_com_std score_acad_std label_m label_c  socioec_index socioec_index_cat) //m:1 because there are missings
		rename _m merge_m_`g'
		//replace year_`g' = year if year_`g'==.
		replace score_math_std_`g' 		= score_math_std 	if score_math_std_`g'	==.
		replace score_com_std_`g' 		= score_com_std 	if score_com_std_`g'	==.
		replace score_acad_std_`g' 		= score_acad_std 	if score_acad_std_`g'	==.
		replace label_m_`g'				= label_m 			if label_m_`g'			==.
		replace label_c_`g'				= label_c 			if label_c_`g'			==.
		replace socioec_index_`g' 		= socioec_index 	if socioec_index_`g' 	==.
		replace socioec_index_cat_`g' 	= socioec_index_cat if socioec_index_cat_`g' ==.
		drop score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat //year	
	}	
/*	
	foreach g in "2" "4" "8"  {	
		merge m:1 id_estudiante_${g`g'lab} year using "$TEMP\ece_${g`g'lab}", keep(master match) keepusing(score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat) //m:1 because there are missings
		rename _m merge_ece_`g'
		rename (/*year*/ score_math_std score_com_std score_acad_std) (/*year_`g'*/ score_math_std_`g' score_com_std_`g' score_acad_std_`g')
		rename (socioec_index socioec_index_cat) (socioec_index_`g' socioec_index_cat_`g')
		rename (label_m label_c) (label_m_`g' label_c_`g')	
	}


	*- Match EM exams
	foreach g in "2" "4" "8"  {
		merge m:1 id_estudiante_${g`g'lab} year using  "$TEMP\em_${g`g'lab}", keep(master match) keepusing(score_math_std score_com_std score_acad_std label_m label_c  socioec_index socioec_index_cat) //m:1 because there are missings
		rename _m merge_m_`g'
		//replace year_`g' = year if year_`g'==.
		replace score_math_std_`g' 		= score_math_std 	if score_math_std_`g'	==.
		replace score_com_std_`g' 		= score_com_std 	if score_com_std_`g'	==.
		replace score_acad_std_`g' 		= score_acad_std 	if score_acad_std_`g'	==.
		replace label_m_`g'				= label_m 			if label_m_`g'			==.
		replace label_c_`g'				= label_c 			if label_c_`g'			==.
		replace socioec_index_`g' 		= socioec_index 	if socioec_index_`g' 	==.
		replace socioec_index_cat_`g' 	= socioec_index_cat if socioec_index_cat_`g' ==.
		drop score_math_std score_com_std score_acad_std label_m label_c socioec_index socioec_index_cat //year	
	}
*/	
/*
	gen score_math_std = .
	gen score_com_std = .
	gen score_acad_std = .
	gen label_m = .
	gen label_c = .
	gen socioec_index = .
	gen socioec_index_cat = .
	foreach g in "2" "4" "8"  {
		replace score_math_std_`g' 		= score_math_std 	if score_math_std_`g'	==.
		replace score_com_std_`g' 		= score_com_std 	if score_com_std_`g'	==.
		replace score_acad_std_`g' 		= score_acad_std 	if score_acad_std_`g'	==.
		replace label_m_`g'				= label_m 			if label_m_`g'			==.
		replace label_c_`g'				= label_c 			if label_c_`g'			==.
		replace socioec_index_`g' 		= socioec_index 	if socioec_index_`g' 	==.
		replace socioec_index_cat_`g' 	= socioec_index_cat if socioec_index_cat_`g' ==.	
*/

	drop id_estudiante*

	close
	
	open 
	
	tab fam_total_${fam_type}
	keep if fam_total_${fam_type}<=4
	
	collapse 


end

