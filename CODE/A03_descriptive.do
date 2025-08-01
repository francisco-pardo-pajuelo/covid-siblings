*- Descriptive



capture program drop main 
program define main 

	setup_PARENTAL
	
	descriptive
	
	parental_investment
	

		
end


capture program drop setup_PARENTAL
program define setup_PARENTAL

	global covid_test = 0
	global covid_data = ""
	if ${covid_test} == 1 global covid_data = "_TEST"

	global fam_type=2
	
	global max_sibs = 4

	global x_all = "male_siagie urban_siagie public_siagie"
	global x_nohigher_ed = "male_siagie urban_siagie public_siagie"
	
	colorpalette  HCL blues, selec(2 5 8 11 13) nograph
	return list

	global blue_1 = "`r(p1)'"
	global blue_2 = "`r(p2)'"
	global blue_3 = "`r(p3)'"
	global blue_4 = "`r(p4)'"
	global blue_5 = "`r(p5)'"
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
	
end


capture program drop descriptive
program define descriptive


*- Urb/Rur

*- Prim on time

*- Age

*- Parents Ed

*- Q1-Q4 SES

*- Lives both



end


capture program drop parental_investment
program define parental_investment


/*
2P-2015
*/

foreach g in "2p" "2s" {

	if "`g'" == "2p" use "$TEMP\ece_family_`g'", clear
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

	tabstat std_index*, by(fam_total_${fam_type})

	levelsof year if index!=., local(years)



	foreach y of local years { 
		eststo index_`g'_`y'		: reg std_index i.fam_total_${fam_type} if year==`y'
		eststo index_`g'_`y'_control: reg std_index i.fam_total_${fam_type} score_com score_math socioec* if year==`y'
	}

}




*- Table with relationships
*********************

*- 2nd grade


	file open  table_tex	using "$TABLES\parental_investment_2p.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\makebox[0.1\width][l]{" _n ///
					"\resizebox{`scale'\textwidth}{!}{" _n
	file close table_tex
	
	file open  table_tex	using "$TABLES\parental_investment_2p.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcccccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"\cmidrule(lr){2-7}" _n ///					
					"& \multicolumn{2}{c}{2015} & \multicolumn{2}{c}{2022} & \multicolumn{2}{c}{2023} \\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7}  " _n ///
					"& (1) & (2) & (3) & (4) & (5) & (6) \\" _n ///
					"\bottomrule" _n ///
					"&  &  &  &  & & \\" _n 
	file close table_tex
	
	estout   index_2p* ///
	using "$TABLES\parental_investment_2p.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(2.fam_total_${fam_type} 3.fam_total_${fam_type} 4.fam_total_${fam_type}) varlabels(2.fam_total_${fam_type} "2 Children" 3.fam_total_${fam_type} "3 Children" 4.fam_total_${fam_type} "4 Children") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	indicate("Controls = score_math") ///
	stats(blank_line N, fmt(%9.0fc %9.0fc ) labels(" " "Observations" )) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	
	file open  table_tex	using "$TABLES\parental_investment_2p.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule" _n ///
		"\end{tabular}" _n ///
		"}" _n ///
		"}" _n
	file close table_tex	
	
*- 8th grade


	file open  table_tex	using "$TABLES\parental_investment_2s.tex", replace write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\makebox[0.1\width][l]{" _n ///
					"\resizebox{`scale'\textwidth}{!}{" _n
	file close table_tex
	
	file open  table_tex	using "$TABLES\parental_investment_2s.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE
					"\begin{tabular}{lcccc}" _n ///
					/// HEADER OF TABLE
					"\toprule" _n ///
					"\cmidrule(lr){2-5}" _n ///					
					"& \multicolumn{2}{c}{2015} & \multicolumn{2}{c}{2023}  \\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-5}   " _n ///
					"& (1) & (2) & (3) & (4)\\" _n ///
					"\bottomrule" _n ///
					"&  &  &  &  \\" _n 
	file close table_tex
	
	estout   index_2s* ///
	using "$TABLES\parental_investment_2s.tex", ///
	append style(tex) ///
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	keep(2.fam_total_${fam_type} 3.fam_total_${fam_type} 4.fam_total_${fam_type}) varlabels(2.fam_total_${fam_type} "2 Children" 3.fam_total_${fam_type} "3 Children" 4.fam_total_${fam_type} "4 Children") ///
	///stats(blank_line N ymean bandwidth fstage FE , fmt(%9.0fc %9.0fc %9.3f %9.3f %9.0fc %9.0fc) labels(" " "Observations" "Counterfactual mean" "Bandwidth" "\textit{F}-statistic" "FE: college-major-year")) ///
	indicate("Controls = score_math") ///
	stats(blank_line N, fmt(%9.0fc %9.0fc ) labels(" " "Observations" )) ///
	mlabels(, none) collabels(, none) note(" ") label starlevels(* 0.10 ** 0.05 *** 0.01)	
	
	
	file open  table_tex	using "$TABLES\parental_investment_2s.tex", append write
	file write table_tex	/// HEADER OPTIONS OF TABLE							
	_n "\bottomrule" _n ///
		"\end{tabular}" _n ///
		"}" _n ///
		"}" _n
	file close table_tex	




*********************







end

*********************
*********************

main