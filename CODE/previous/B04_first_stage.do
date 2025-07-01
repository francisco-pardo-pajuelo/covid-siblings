/********************************************************************************
- Author: Francisco Pardo
- Description: Validation of the RD strategy: (1) McCrary (smooth distribution) (2) Covariates (smooth outcomes) (3) First stage
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/

capture program drop main 
program define main 

	setup
	
	//review_application_cutoffs
	
	main_results 

	score_cutoff_descriptives major
	score_cutoff_descriptives department
	
	mccrary_compare_tests all major
	mccrary_compare_tests all department
	mccrary_compare_tests noz major
	mccrary_compare_tests noz department
	
	mccrary_compare_tests_cutoff major
	mccrary_compare_tests_cutoff department
	
	mccrary_filter noz department
	mccrary_filter noz major
	covariates noz department
	covariates noz major
	first_stage noz department
	first_stage noz major
	
end


//Change in final database (or applicants, enrolled)
/*
	bys id_cutoff: egen rank_score_raw = rank(score_raw), track
*/


********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup

	set seed 1234
	global test = 0
	
	global window = 2
	global mccrary_window = 4
end



********************************************************************************
* main_results: 
*- For discussion with professors
********************************************************************************

capture program drop main_results
program define main_results

	use "$TEMP\applied_matched", clear
	
	local cell major
	local type noz
		
	rename *_`cell' *
	rename *_`type' * 
	
	*- Youngest applied:
	bys family_id: egen applied_youngest = max(cond(oldest==0,1,0)) //Only if starting point is the applied, otherwise, if starting from SIAGIE, have an applied dummy.
	replace applied_youngest = . if oldest!=1
	
	*- Public schools
	keep if public==1
	
	*- Exclude those without estimated cutoffs
	keep if lottery_nocutoff == 0

	*- Exclude those at cutoff
	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)		
	keep if not_at_cutoff==1
	
	*- Score relative
	gen score_relative = score_std - cutoff_std
	drop if score_relative==.	
	
	*- Older siblings
	//keep if oldest==1 & family_id!=.
	
	*- Histogram
	histogram score_relative ///
	if abs(score_relative)<$mccrary_window ///
	,  ///
	fcolor(stc1%20) lcolor(gs0) xline(0, lcolor(red)) xtitle("Standardized score relative to cutoff")
	
	graph export 	"$FIGURES/presentation_histogram.png", replace

	*- Rddensity test
	rddensity score_relative ///
		if abs(score_relative)<$mccrary_window ///
		, ///
		plot
	
	graph export 	"$FIGURES/presentation_mccrary.png", replace
	
	*- First Stage
	local admitted 				"% Admitted to target college"
	local enrolled 				"% Enrolled to target college"
	local enrolled_any 			"% Enrolled to any college"
	local enrolled_any_1delay 	"% Enrolled to any college this or next year"
	local enrolled_ever 		"% Enrolled to any college ever"
	local public_any 			"% Enrolled to any public college"
	local public_ever 			"% Enrolled to any public college ever"
	
	local score_com_std_g8_sch 	"School: 8th grade score - Communication on application year"
	local score_math_std_g8_sch	"School: 8th grade score - Math on application year"

	local applied_year1_sch			"% applicants from school (same year)"
	local applier_year2_sch			"% applicants from school (next year)"

	local enrolled_year1_sch		"% enrolled from school (same year)"
	local enrolled_year2_sch		"% enrolled from school (next year)"
	local enrolled_year4_sch		"% enrolled from school (year 4)"
	
	
	*- Test
	local v applied_year2_sch
	binsreg `v' 			score_relative ///
				if abs(score_relative)<$window 
	
	
	*- Plot the RD graph
	foreach v in 	admitted enrolled enrolled_any enrolled_any_1delay enrolled_ever ///
					public_any public_ever ///
					score_com_std_g8_sch score_math_std_g8_sch ///
					applied_year1_sch applied_year2_sch enrolled_year1_sch enrolled_year2_sch enrolled_year4_sch ///
					/*Sibling effects*/ applied_youngest ///
					/*Covariates*/ male age score_com_std_g8 score_math_std_g8 male_g8_sch spanish_g8_sch socioec_index_g8_sch {		
		
		
		if substr("`v'",1,5)=="score" {	
			binsreg `v' 			score_relative ///
				if abs(score_relative)<$window ///
				,  ///
				ylabel(0(0.1)1) ///
				xsize(5) ///
				ysize(5) ///
				xtitle("Standardized score relative to cutoff")  ///
				ytitle("``v''")  ///
				bycolors(gs0) ///
				name(`v', replace)
			}
			
		if substr("`v'",1,5)!="score" {	
			binsreg `v' 			score_relative ///
				if abs(score_relative)<$window ///
				,  ///
				ylabel(0(0.1)1) ///
				xsize(5) ///
				ysize(5) ///
				xtitle("Standardized score relative to cutoff")  ///
				ytitle("``v''")  ///
				bycolors(gs0) ///
				name(`v', replace)
				
				
			}
			
		graph export "$FIGURES\\presentation_rd_`v'_`cell'.png", replace
		}
	
		
		*- Run the RD regression
		gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=. //To avoid float issues around 0, we use the precisely integer rank scores.
		
		forvalues p = 1/5 {
			gen score_relative_`p' 			= score_relative^`p'
			gen ABOVE_score_relative_`p' 	= ABOVE*score_relative_`p'
		}
		
		global scores_5 		= "score_relative_1 		score_relative_2 		score_relative_3 		score_relative_4 		score_relative_5"
		global ABOVE_scores_5 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2 	ABOVE_score_relative_3 	ABOVE_score_relative_4 	ABOVE_score_relative_5"
		
		
	foreach v in 	admitted enrolled enrolled_any enrolled_any_1delay enrolled_ever ///
					public_any public_ever ///
					score_com_std_g8_sch score_math_std_g8_sch ///
					applied_year1_sch applied_year2_sch enrolled_year1_sch enrolled_year2_sch enrolled_year4_sch ///
					/*Sibling effects*/ applied_youngest ///
					/*Covariates*/ male age score_com_std_g8 score_math_std_g8 male_g8_sch spanish_g8_sch socioec_index_g8_sch {	
						
		eststo e_`v': reghdfe `v' 					///
				ABOVE ${scores_5} ${ABOVE_scores_5} ///
				if abs(score_relative)<$window ///
				, a(id_cutoff)
		}	
		
		esttab e_*  using "$TABLES\presentation.csv", ///
				keep(ABOVE _cons) ///
				b(%9.2f) ///
				se(%9.2f) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				stardrop(_cons) ///
				replace	
/*				
esttab e_* ///
				using "$TABLES/presentation.tex" ///
				, label replace booktabs ///
				, prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
				 ///
				keep(ABOVE _cons) ///  
				order(ABOVE _cons) ///
				///coeflabel(registered_voters "Registered Voters") ///
				b(%9.2f) ///
				se(%9.2f) ///
				stats(N,fmt("%9.0fc")) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nonotes ///
				alignment(D{c}{c}{-1}) width(\hsize)  ///
				title(Main Results \label{tab:table_main_results}) ///
				substitute({l} {p{\linewidth}}) ///
				addnotes("Note: ... Robust standard errors in parentheses. \sym{*} \(p<0.1\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\).")					
*/				
	/*
	ivreghdfe enrolled 					///
				(admitted=ABOVE) ${scores_5} ${ABOVE_scores_5} ///
				if abs(score_relative)<$window ///
				, a(id_cutoff)
	*/
	
	*- Enrollment target, public, any, next 2 years
	
	
	*- Covariates 
	
	
	*- Spillover effects:
	*--	Class test scores:
	
	*-- Class applications

		
end

********************************************************************************
* review_application cutoffs: Check issues on histograms/FS
********************************************************************************

capture program drop review_application_cutoffs
program define review_application_cutoffs

	use "$TEMP\applied_matched", clear

		gen check = 0
		*- Public
		replace check = 1 if inlist(codigo_modular,160000007,160000022,160000023,160000027,160000101,160000122,160000123,160000125,160000127) //Major very similar to department. Not an issue but perhaps better to change cell dimension. Still check if there is actually just one major
		replace check = 2 if inlist(codigo_modular,160000025,160000124) //Peak at 0
		
		*- Private
		replace check = 3 if inlist(codigo_modular,260000037,260000040,260000043,260000046,260000047,260000052,260000054,260000055,260000065,260000067,260000070,260000087,260000105,260000136) //__|---- histrogram, so mostly above cutoff
		replace check = 4 if inlist(codigo_modular,260000030,260000068,260000069,260000071) //Peak at 0
		replace check = 5 if inlist(codigo_modular,260000057,260000019,260000064,260000096) //No effect. e.g. UPC
		replace check = 6 if inlist(codigo_modular,260000015,260000062,260000114,260000133) //bimodal first stage		
		replace check = 7 if inlist(codigo_modular,260000059,260000074,260000079) // Strange behavior. Look closely
		replace check = 8 if inlist(codigo_modular,260000014,260000085,260000103,260000104,260000113,260000116) //Bimodal histogram	
		replace check = 9 if inlist(codigo_modular,260000083) //Peak at left side of interval. At the beginning?
		replace check = 10 if inlist(codigo_modular,260000090,260000100) //Donut
		//replace issue = 11 if inlist(codigo_modular,)
		keep if check>0
		drop check
	
		
	gen score_relative = score_std_major - cutoff_std_major
	drop if score_relative==.
	drop if rank_score_raw_major==cutoff_rank_major		
	
	
	*- Peak at 0 in private universities
	
	preserve
		keep if issue ==4
		bys universidad : gen N=_N
		bys universidad : keep if _n==1
		sort codigo_modular 
		list universidad codigo_modular  N, sep(1000)
	restore
	/*	

     +---------------------------------------------------------------------+
     |                                     universidad   codigo_~r       N |
     |---------------------------------------------------------------------|
  1. |                       UNIVERSIDAD RICARDO PALMA   260000030   22354 |
  2. |                  UNIVERSIDAD CIENTÍFICA DEL SUR   260000068   42085 |
  3. | UNIVERSIDAD CATÓLICA SANTO TORIBIO DE MOGROVEJO   260000069   28605 |
  4. |           UNIVERSIDAD CATÓLICA SEDES SAPIENTIAE   260000071    9302 |
     +---------------------------------------------------------------------+


	*/
	preserve
		keep if issue ==4
		
		histogram score_relative if codigo_modular==260000030 & abs(score_relative)<$window & year==2020
		histogram score_raw if codigo_modular==260000030 & abs(score_relative)<$window & year==2020
		tab score_raw if codigo_modular==260000030 & abs(score_relative)<$window & year==2020 //cut at 20

		histogram score_relative if codigo_modular==260000068 & abs(score_relative)<$window 
		histogram score_raw if codigo_modular==260000068 
		histogram score_raw if codigo_modular==260000068 & year==2017 //cut at 20
		histogram score_raw if codigo_modular==260000068 & year==2018 //cut at 20
		histogram score_raw if codigo_modular==260000068 & year==2019
		histogram score_raw if codigo_modular==260000068 & year==2020 //cut at 50
		binsreg admitted score_raw if codigo_modular==260000068 & year==2020
		histogram score_raw if codigo_modular==260000068 & year==2021
		histogram score_raw if codigo_modular==260000068 & year==2022
		histogram score_raw if codigo_modular==260000068 & year==2023
		histogram score_relative if codigo_modular==260000068 & abs(score_relative)<$window & inlist(year,2019,2021,2022,2023)


		histogram score_relative if codigo_modular==260000069 & abs(score_relative)<$window 
		tab score_raw if codigo_modular==260000069 & year==2017
		binsreg admitted score_raw if codigo_modular==260000069 & year==2017
		tab score_raw if codigo_modular==260000069 & year==2018
		binsreg admitted score_raw if codigo_modular==260000069 & year==2018
		tab score_raw if codigo_modular==260000069 & year==2019
		histogram  score_raw if codigo_modular==260000069 & year==2019	
		binsreg admitted score_raw if codigo_modular==260000069 & year==2019	
		
		tab score_raw if codigo_modular==260000071 & year==2020
		tab score_raw if codigo_modular==260000071 & year==2021
		tab score_raw if codigo_modular==260000071 & year==2022
		tab score_raw if codigo_modular==260000071 & year==2023

	restore
	
	
	*- Distribution mostly above cutoff
	
	preserve
		keep if issue ==3
		bys universidad : gen N=_N
		bys universidad : keep if _n==1
		sort codigo_modular 
		list universidad codigo_modular  N, sep(1000)
	restore
	/*	


     +-------------------------------------------------------------------------+
     |                                        universidad   codigo_~r        N |
     |-------------------------------------------------------------------------|
  1. |                      UNIVERSIDAD PERUANA LOS ANDES   260000037    37921 |
  2. |               UNIVERSIDAD TECNOLOGICA DE LOS ANDES   260000040    21867 |
  3. |                       UNIVERSIDAD PRIVADA DE TACNA   260000043    18205 |
  4. |                 UNIVERSIDAD PRIVADA ANTENOR ORREGO   260000046    54442 |
  5. |                             UNIVERSIDAD DE HUANUCO   260000047    33340 |
  6. |                          UNIVERSIDAD CÉSAR VALLEJO   260000052   282437 |
  7. |          UNIVERSIDAD PERUANA DE CIENCIAS APLICADAS   260000054   202597 |
  8. |                      UNIVERSIDAD PRIVADA DEL NORTE   260000055   252421 |
  9. |                   UNIVERSIDAD TECNOLÓGICA DEL PERÚ   260000065   450010 |
 10. |                            UNIVERSIDAD CONTINENTAL   260000067   177649 |
 11. |       UNIVERSIDAD PRIVADA ANTONIO GUILLERMO URRELO   260000070     3305 |
 12. |                        UNIVERSIDAD AUTÓNOMA DE ICA   260000087     8986 |
 13. | UNIVERSIDAD PRIVADA DE HUANCAYO FRANKLIN ROOSEVELT   260000105    12883 |
 14. |                      UNIVERSIDAD MARÍA AUXILIADORA   260000136     9335 |
     +-------------------------------------------------------------------------+



	*/
	preserve
		keep if issue ==3

		
		histogram score_relative if codigo_modular==260000030 & abs(score_relative)<$window & year==2020
		histogram score_raw if codigo_modular==260000030 & abs(score_relative)<$window & year==2020
		tab score_raw if codigo_modular==260000030 & abs(score_relative)<$window & year==2020 //cut at 20

		histogram score_relative if codigo_modular==260000068 & abs(score_relative)<$window 
		histogram score_raw if codigo_modular==260000068 
		histogram score_raw if codigo_modular==260000068 & year==2017 //cut at 20
		histogram score_raw if codigo_modular==260000068 & year==2018 //cut at 20
		histogram score_raw if codigo_modular==260000068 & year==2019
		histogram score_raw if codigo_modular==260000068 & year==2020 //cut at 50
		binsreg admitted score_raw if codigo_modular==260000068 & year==2020
		histogram score_raw if codigo_modular==260000068 & year==2021
		histogram score_raw if codigo_modular==260000068 & year==2022
		histogram score_raw if codigo_modular==260000068 & year==2023
		histogram score_relative if codigo_modular==260000068 & abs(score_relative)<$window & inlist(year,2019,2021,2022,2023)


		histogram score_relative if codigo_modular==260000069 & abs(score_relative)<$window 
		tab score_raw if codigo_modular==260000069 & year==2017
		binsreg admitted score_raw if codigo_modular==260000069 & year==2017
		tab score_raw if codigo_modular==260000069 & year==2018
		binsreg admitted score_raw if codigo_modular==260000069 & year==2018
		tab score_raw if codigo_modular==260000069 & year==2019
		histogram  score_raw if codigo_modular==260000069 & year==2019	
		binsreg admitted score_raw if codigo_modular==260000069 & year==2019	
		
		tab score_raw if codigo_modular==260000071 & year==2020
		tab score_raw if codigo_modular==260000071 & year==2021
		tab score_raw if codigo_modular==260000071 & year==2022
		tab score_raw if codigo_modular==260000071 & year==2023

	restore
	
	/*
	forvalues y = 2019/2023 {
		capture histogram score_relative if codigo_modular==260000040 & year==`y', title("`y'") name(hist_`y', replace)
	}
	
	graph combine 	 ///
					 ///
					hist_2019 ///
					hist_2020 ///
					hist_2021 ///
					hist_2022 ///
					hist_2023
	*/	
	
	levelsof codigo_modular if inlist(issue,1,2,5,6,7,8,9,10), local(codmods)
	
	foreach cod of local codmods {	
		
		sum issue if codigo_modular==`cod'
		local issue = r(max) 
		
		forvalues y = 2017/2023 {
			capture histogram score_raw if codigo_modular==`cod' & year==`y', title("`y' - `cod'") name(hist_`y', replace)
		}
		
		graph combine 	hist_2017 ///
						hist_2018 ///
						hist_2019 ///
						hist_2020 ///
						hist_2021 ///
						hist_2022 ///
						hist_2023	
						
		graph export 	"$FIGURES/TEMP/TEST/issue_`issue'/hist_raw_`cod'.png", replace	
		
		forvalues y = 2017/2023 {
			capture histogram score_relative if codigo_modular==`cod' & year==`y', title("`y' - `cod'") name(hist_`y', replace)
		}
		
		graph combine 	hist_2017 ///
						hist_2018 ///
						hist_2019 ///
						hist_2020 ///
						hist_2021 ///
						hist_2022 ///
						hist_2023	
						
		graph export 	"$FIGURES/TEMP/TEST/issue_`issue'/hist_rel_`cod'.png", replace	

		forvalues y = 2017/2023 {				
			capture histogram score_relative 		if codigo_modular==`cod' & year==`y'	, title("`y' - `cod'") name(his_rel_`y', replace)		
			capture histogram score_raw 			if codigo_modular==`cod' & year==`y'	, title("`y' - `cod'") name(his_raw_`y', replace)				
			capture binsreg admitted score_relative if codigo_modular==`cod' & year==`y'	, title("`y' - `cod'") name(bins_rel_`y', replace)	
			capture binsreg admitted score_raw 		if codigo_modular==`cod' & year==`y'	, title("`y' - `cod'") name(bins_raw_`y', replace)
			
		
			capture graph combine 	his_rel_`y' ///
							his_raw_`y' ///
							bins_rel_`y' ///
							bins_raw_`y' 
							
			capture graph export 	"$FIGURES/TEMP/TEST/issue_`issue'/all_`y'_`cod'.png", replace			
		}
	
	}
	
	*- Generic revision
	global y = 2018
	global cod = 260000052
	
	tab year admitted  if codigo_modular==$cod
	tab score_raw admitted 	if codigo_modular==$cod & year==$y	
	tab score_raw  	if codigo_modular==$cod & year==$y	
	histogram score_raw if codigo_modular==$cod & year==$y
	binsreg admitted score_raw if codigo_modular==$cod & year==$y & abs(score_relative)<4, ylabel(0(.2)1) 
	binsreg admitted score_relative if codigo_modular==$cod  & abs(score_relative)<2, ylabel(0(.2)1)  nbins(100)
	histogram score_relative if codigo_modular==$cod  & abs(score_relative)<4

	*- Main universities with issues
/*

     +-----------------------------------------------------------------------------------------------------+
     | codigo_~r                                                universidad        N      adm_z     adm_nz |
     |-----------------------------------------------------------------------------------------------------|
  1. | 260000065                           UNIVERSIDAD TECNOLÓGICA DEL PERÚ   450010   .8971801   .9909871 | 	Likely will not be saved. Too much admittance rate.
  2. | 260000052                                  UNIVERSIDAD CÉSAR VALLEJO   282437   .8179948   .9357125 |	Might be worth trying to explore
  3. | 260000055                              UNIVERSIDAD PRIVADA DEL NORTE   252421   .9702758   .9995049 |	Likely will not be saved. Too much admittance rate.
  4. | 260000054                  UNIVERSIDAD PERUANA DE CIENCIAS APLICADAS   202597   .5534189   .5899198 |	Will be saved once randomness is explained.
  5. | 260000067                                    UNIVERSIDAD CONTINENTAL   177649   .7803759   .9359584 |	Might be worth trying to explore

  */
	
	
end


******************************************************************************** 
* score_cutoff_descriptive
* 
* Description: 
********************************************************************************

capture program drop score_cutoff_descriptives
program define score_cutoff_descriptives

	args cell

	if $test == 0 use "$TEMP/applied_cutoffs_`cell'.dta", clear
	if $test == 1 use "$TEMP/applied_cutoffs_`cell'.dta", clear
	
	rename *_`cell' *
	
	/*
	rename id_cutoff_`cell' id_cutoff
	rename cutoff_raw_`cell' cutoff_raw
	rename cutoff_raw_all_`cell' cutoff_raw_all
	rename coeff*_`cell' coeff*
	*/
	
	keep  if cutoff_rank!=cutoff_rank_all & cutoff_rank!=.
	list id_cutoff coef* cutoff_rank* cutoff_raw*, sep(10000) //We list cases where the biggest R2 is not the one estimated with restrictions. We review these cases and see if the restricted estimate is a good one or if we should discard them.
	
	*- Two cases: Negative coefficients and positive ones with pv>0.01
	preserve
		keep if coeff_all <=0
		list id_cutoff coef* cutoff_rank* cutoff_raw*, sep(10000)
		sample 4, count
		levelsof id_cutoff, local(levels_neg) 
	restore
	
	preserve
		keep if coeff_all > 0 & p_val_all>0.01
		list id_cutoff coef* cutoff_raw*, sep(10000)
		sample 4, count
		levelsof id_cutoff, local(levels_pos) 
	restore
	
	
	use "$TEMP/applied_matched.dta", clear
	
	rename *_`cell' *
	
	keep  if cutoff_rank!=cutoff_rank_all & cutoff_rank!=.
	
	*- For the case of negative coefficients
	foreach l of local levels_neg {
			
		sum cutoff_raw if id_cutoff==`l'
		local cutoff_raw = `r(min)'
		sum cutoff_raw_all if id_cutoff==`l'
		local cutoff_raw_all = `r(min)'
		binsreg admitted score_raw if id_cutoff==`l',title("ID: `l'") xline(`cutoff_raw', lcolor(blue)) xline(`cutoff_raw_all', lcolor(red))  name(cutoff_`l', replace)
	}
	
	foreach l of local levels_pos {
		
		sum cutoff_raw if id_cutoff==`l'
		local cutoff_raw = `r(min)'
		sum cutoff_raw_all if id_cutoff==`l'
		local cutoff_raw_all = `r(min)'
		binsreg admitted score_raw if id_cutoff==`l',title("ID: `l'") xline(`cutoff_raw', lcolor(blue)) xline(`cutoff_raw_all', lcolor(red))  name(cutoff_`l', replace)	
	}
	
	*- Save the school ID to use in graph combine
	di "`levels_neg'"
	di "`levels_pos'"
	forvalues i = 1/4 {
		local l_neg_`i' = word("`levels_neg'",`i')
		local l_pos_`i' = word("`levels_pos'",`i')
		di "Neg: " `l_neg_`i'' 
		di "Pos: " `l_pos_`i''
	}
	
	graph combine 					///
		cutoff_`l_neg_1' ///
		cutoff_`l_neg_2' ///
		cutoff_`l_neg_3' ///
		cutoff_`l_neg_4' ///
			, ///
		xsize(8) col(2) ///
		name(cutoff_unrestricted_neg, replace)	
		
	graph export 	"$FIGURES/cutoff_unrestricted_neg_`cell'.png", replace	
		
	graph combine 					///
		cutoff_`l_pos_1' ///
		cutoff_`l_pos_2' ///
		cutoff_`l_pos_3' ///
		cutoff_`l_pos_4' ///
			, ///
		xsize(8) col(2) ///
		name(cutoff_unrestricted_pos, replace)		
	
	graph export 	"$FIGURES/cutoff_unrestricted_pos_`cell'.png", replace
	
end


******************************************************************************** 
* mccrary_compare_tests
* 
* Description: Compares the mccrary test with default options and Biasi's options.
********************************************************************************

capture program drop mccrary_compare_tests
program define mccrary_compare_tests
	args type cell

	*- Comparing mccrary pvues
	use "$TEMP/mccrary_cutoffs_`type'_`cell'.dta", clear
	
	scatter mccrary_pv_def_`type'_`cell' mccrary_pv_biasi_`type'_`cell', name(scatter_mccrary_`type'_`cell', replace)
	binsreg mccrary_pv_def_`type'_`cell' mccrary_pv_biasi_`type'_`cell', name(bins_mccrary_`type'_`cell', replace)
	
	graph combine 					///
					scatter_mccrary_`type'_`cell' ///
					bins_mccrary_`type'_`cell' 	///
					, ///
		xsize(8) col(2) ///
		name(mccrary_pv_`type'_`cell', replace)
		
	graph export 	"$FIGURES/mccrary_pv_`type'_`cell'.png", replace
									 	

end

******************************************************************************** 
* mccrary_compare_tests_cutoff
* 
* Description: Compares the mccrary test with and without observations at cutoff
********************************************************************************

capture program drop mccrary_compare_tests_cutoff
program define mccrary_compare_tests_cutoff
	args cell

	*- Comparing mccrary pvues
	//local cell major
	use "$TEMP/mccrary_cutoffs_all_`cell'.dta", clear
	merge 1:1 id_cutoff_`cell' using "$TEMP/mccrary_cutoffs_noz_`cell'.dta"
	
	scatter mccrary_pv_def_all_`cell' mccrary_pv_def_noz_`cell', xtitle("With cutoff") ytitle("Excluding Cutoff") //name(scatter_mccrary_cutoff_`cell', replace)
	
	graph export 	"$FIGURES/mccrary_cutoff_`cell'.png", replace
									 	

end



******************************************************************************** 
* mccrary_filter
* 
* Description: Does the mccrary test filtering different samples
********************************************************************************

capture program drop mccrary_filter
program define mccrary_filter
	args type cell

	*- Histogram of scores and cutoffs
	use "$TEMP/applied_matched.dta", clear
	
	rename *_`cell' *
	rename *_`type' * 
	
	
	*- Exclude those without estimated cutoffs
	keep if lottery_nocutoff == 0

	*- Exclude those at cutoff
	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)	
	
	*- Only valid cutoffs (pass McCrary test)
	**# Apparently there are some missings in mccrary_pv_def that are not being properly accounted for the 'mccrary_test' indicator.
	count if mccrary_pv_def == . & mccrary_test==1
	gen valid_flex_cutoff = ((mccrary_pv_def>0.1 & mccrary_pv_biasi>0.1) & (mccrary_test==1 & mccrary_pv_def!=. & mccrary_pv_biasi!=.))
	gen valid_strict_cutoff = ((mccrary_pv_def>0.1 | mccrary_pv_biasi>0.1) & (mccrary_test==1 & mccrary_pv_def!=. & mccrary_pv_biasi!=.))
	//gen valid_flex_cutoff_prev = ((mccrary_pv_def_prev>0.1 & mccrary_pv_biasi_prev>0.1) & (mccrary_test_prev==1 & mccrary_pv_def_prev!=. & mccrary_pv_biasi_prev!=.))
	//gen valid_strict_cutoff_prev = ((mccrary_pv_def_prev>0.1 | mccrary_pv_biasi_prev>0.1) & (mccrary_test_prev==1 & mccrary_pv_def_prev!=. & mccrary_pv_biasi_prev!=.))
	
	*- Only valid cutoffs
	gen consistent_cutoff 		= (cutoff_rank == cutoff_rank_all)
	
	*- Cutoffs that come from only one source?
	//This identifies one with big outliers (few observations with different scale)
	bys id_cutoff: egen score_std_max = max(abs(score_std))
	gen one_source_cutoff = (score_std_max<5) //approx
	
	//This aims to identify bimodal distributions. Not enough observations within 0.5sd of mean (Expected is ~40%)
	bys id_cutoff: egen N = count(score_std)
	bys id_cutoff: egen temp_N_half_sd = count(score_std) if abs(score_std)<0.5
	bys id_cutoff: egen N_half_sd = max(temp_N_half_sd)
	gen one_source_cutoff2 = (N_half_sd/N>0.2)
	
	*- Sample to use
	gen sample = (not_at_cutoff==1 & valid_flex_cutoff==1 & consistent_cutoff==1 & one_source_cutoff==1 & one_source_cutoff2==1)	
	
	*- Relative score
	gen score_relative = score_std - cutoff_std	
	
	*- All cutoffs	
	histogram score_relative ///
		if abs(score_relative)<$mccrary_window ///
		,  ///
		fcolor(gs14) lcolor(gs0) xline(0, lcolor(red)) title("All cutoffs") xtitle("Standardized score relative to cutoff")	 ///
		name(mccrary_all_cutoff, replace)		
	
	*- Remove at cutoffs
	sum not_at_cutoff
	local p_not_at_cutoff	: display %9.1f  r(mean)*100
	di `p_not_at_cutoff'
	histogram score_relative ///
	if abs(score_relative)<$mccrary_window ///
		& not_at_cutoff==1 ///
	,  ///
	fcolor(gs14) lcolor(gs0) xline(0, lcolor(red)) title("Exclude at cutoffs (`p_not_at_cutoff'%)") xtitle("Standardized score relative to cutoff")	 ///
	name(mccrary_not_at_cutoff, replace)
	
	*- Cutoffs that pass mccrary
	sum valid_flex_cutoff
	local p_valid_flex_cutoff	: display %9.1f  r(mean)*100
	di `p_valid_flex_cutoff'
	histogram score_relative ///
	if abs(score_relative)<$mccrary_window ///
		& not_at_cutoff==1 ///
		& valid_flex_cutoff==1 ///
	,  ///
	fcolor(gs14) lcolor(gs0) xline(0, lcolor(red)) title("Valid cutoffs (`p_valid_flex_cutoff'%)") xtitle("Standardized score relative to cutoff")	 ///
	name(mccrary_valid_cutoff, replace)
	
	
	keep if not_at_cutoff==1
	
	*- Consistent cutoffs
	sum consistent_cutoff
	local p_consistent_cutoff	: display %9.1f  r(mean)*100
	di `p_consistent_cutoff'
	histogram score_relative ///
	if abs(score_relative)<$mccrary_window ///
		& not_at_cutoff==1 ///
		& consistent_cutoff==1 ///
	,  ///
	fcolor(gs14) lcolor(gs0) xline(0, lcolor(red)) title("Consistent cutoffs (`p_consistent_cutoff'%)") xtitle("Standardized score relative to cutoff")	 ///
	name(mccrary_consistent_cutoff, replace)
	
	*- one source cutoffs
	sum one_source_cutoff
	local p_one_source_cutoff	: display %9.1f  r(mean)*100
	di `p_one_source_cutoff'
	histogram score_relative ///
	if abs(score_relative)<$mccrary_window ///
		& not_at_cutoff==1 ///
		& one_source_cutoff==1 ///
	,  ///
	fcolor(gs14) lcolor(gs0) xline(0, lcolor(red)) title("One Source cutoffs (`p_one_source_cutoff'%)") xtitle("Standardized score relative to cutoff")	 ///
	name(mccrary_one_source_cutoff, replace)	

	*- Sample
	sum sample
	local p_sample	: display %9.1f  r(mean)*100
	di `p_sample'
	histogram score_relative ///
	if abs(score_relative)<$mccrary_window ///
		& not_at_cutoff==1 ///
		& sample==1 ///
	,  ///
	fcolor(gs14) lcolor(gs0) xline(0, lcolor(red)) title("Sample cutoffs (`p_sample'%)") xtitle("Standardized score relative to cutoff")	 ///
	name(mccrary_sample_cutoff, replace)	
	
	graph combine 					///
					mccrary_all_cutoff ///
					mccrary_not_at_cutoff 	///
					mccrary_consistent_cutoff 	///
					mccrary_one_source_cutoff 	///
					mccrary_valid_cutoff  ///
					mccrary_sample_cutoff 	///
					, ///
		xsize(8) col(3) ///
		name(mccrary_all_fail, replace)	
	
	graph export 	"$FIGURES/mccrary_compare_samples_`type'_`cell'.png", replace
	
	
	*-Preferred Histogram and rddensity
	*******
	cap drop N_total
	cap drop condition
	gen N_total = N_above + N_below
	gen condition = N_total<10000
	
	bys id_cutoff: gen N_total2 = _N if _n==1
	
	binsreg sample N_total if not_at_cutoff==1
	
	sum sample if condition==1
	local p_sample	: display %9.1f  r(mean)*100
	di `p_sample'	
	histogram score_relative ///
	if abs(score_relative)<$mccrary_window ///
		& not_at_cutoff==1 ///
		& sample==1 ///
		& condition==1 ///
	,  ///
	fcolor(gs14) lcolor(gs0) xline(0, lcolor(red)) title("Sample cutoffs (`p_sample'%)") xtitle("Standardized score relative to cutoff")
	
	graph export 	"$FIGURES/mccrary_histogram_`type'_`cell'.png", replace
	*******
	
	*******
	
	rddensity score_relative ///
		if abs(score_relative)<$mccrary_window ///
		& not_at_cutoff==1 ///
		& sample==1 ///
		& condition ==1 ///
		, ///
		plot
		
	graph export 	"$FIGURES/mccrary_test_`type'_`cell'.png", replace
	*******
	
	*******
	* Public schools
	rddensity score_relative ///
		if abs(score_relative)<$mccrary_window ///
		& not_at_cutoff==1 ///
		& public==1 ///
		, ///
		plot
		
	graph export 	"$FIGURES/mccrary_test_public_`type'_`cell'.png", replace
	*******	
	
	
	
	foreach i in "2" "3" "4" "5" {
		rddensity score_relative ///
		if abs(score_relative)<`i' ///
		& sample==1 ///
		, ///
		plot
		
		graph export 	"$FIGURES/mccrary_lpdensity`i'_`type'_`cell'.png", replace
		}
		
	forvalues y = 2017/2023 {
		histogram score_relative ///
		if abs(score_relative)<$mccrary_window & year==`y'  ///
		, ///
		fcolor(gs14) lcolor(gs0) xline(0) title("`y'")	 ///
		name(histogram_`y', replace)	
	}
	
	graph combine 					///
					histogram_2017 	///
					histogram_2018 	///
					histogram_2019 	///
					histogram_2020 	///
					histogram_2021 	///
					histogram_2022 	///
					histogram_2023 	///
					, ///
		xsize(8) col(3) ///
		name(mccrary, replace)
		
	graph export 	"$FIGURES/mccrary_year_fail_`type'_`cell'.png", replace	
	
	forvalues y = 2017/2023 {
		histogram score_relative ///
		if abs(score_relative)<$mccrary_window & year==`y' ///
		& sample==1 ///
		,  ///
		fcolor(gs14) lcolor(gs0) xline(0) title("`y'")	 ///
		name(histogram_valid_`y', replace)	
	}
	
	graph combine 					///
					histogram_valid_2017 	///
					histogram_valid_2018 	///
					histogram_valid_2019 	///
					histogram_valid_2020 	///
					histogram_valid_2021 	///
					histogram_valid_2022 	///
					histogram_valid_2023 	///
					, ///
		xsize(8) col(3) ///
		name(mccrary, replace)
	
	graph export 	"$FIGURES/mccrary_year_valid_fail_`type'_`cell'.png", replace
	
	preserve
		clear
		gen year = .
		gen window = .
		gen pv = .
		save "$TEMP/mccrary_year_pv_`type'_`cell'", replace emptyok
	restore
		
	foreach i in "1" "2" "3" "4" "5" {
		forvalues y = 2017/2023 {
			rddensity score_relative ///
			if abs(score_relative)<`i' ///
			& year==`y' ///
			& sample==1 ///
			, ///
			plot
			
			graph export 	"$FIGURES/mccrary_lpdensity`i'_`y'_`type'_`cell'.png", replace
			
			preserve
				clear
				set obs 1
				gen year = `y'
				gen window = `i'
				gen pv = e(pv_q)
				append using "$TEMP/mccrary_year_pv_`type'_`cell'"
				save "$TEMP/mccrary_year_pv_``type'_`cell'", replace
			restore
		}
	}
	
	use "$TEMP/mccrary_year_pv_`type'_`cell'", clear
	
	
	
			
		

//graph export 	"$FIGURES/mccrary_failed.pdf", replace
//graph export 	"$FIGURES/mccrary_failed.gph", replace

										 	

end


********************************************************************************
* covariates
* 
* Description: 
********************************************************************************

capture program drop covariates
program define covariates

	args type cell

di "Smoothness of covariates"

	use "$TEMP/applied_matched.dta", clear
	capture drop _merge

	rename *_`cell' *
	rename *_`type' * 
	
	*- Exclude those without estimated cutoffs
	keep if lottery_nocutoff == 0

	*- Exclude those at cutoff
	gen at_cutoff = rank_score_raw==cutoff_rank	
	
	*- Only valid cutoffs (pass McCrary test)
	**# Apparently there are some missings in mccrary_pv_def that are not being properly accounted for the 'mccrary_test' indicator.
	count if mccrary_pv_def == . & mccrary_test==1
	gen valid_flex_cutoff = ((mccrary_pv_def>0.1 & mccrary_pv_biasi>0.1) & (mccrary_test==1 & mccrary_pv_def!=. & mccrary_pv_biasi!=.))
	gen valid_strict_cutoff = ((mccrary_pv_def>0.1 | mccrary_pv_biasi>0.1) & (mccrary_test==1 & mccrary_pv_def!=. & mccrary_pv_biasi!=.))
	
	*- Only valid cutoffs
	gen consistent_cutoff 		= (cutoff_rank == cutoff_rank_all)
	
	*- Cutoffs that come from only one source?
	//This identifies one with big outliers (few observations with different scale)
	bys id_cutoff: egen score_std_max = max(abs(score_std))
	gen one_source_cutoff = (score_std_max<5) //approx
	
	//This aims to identify bimodal distributions. Not enough observations within 0.5sd of mean (Expected is ~40%)
	bys id_cutoff: egen N = count(score_std)
	bys id_cutoff: egen temp_N_half_sd = count(score_std) if abs(score_std)<0.5
	bys id_cutoff: egen N_half_sd = max(temp_N_half_sd)
	gen one_source_cutoff2 = (N_half_sd/N>0.2)
	
	*- Sample to use
	gen sample = (not_at_cutoff==1 & valid_flex_cutoff==1 & consistent_cutoff==1 & one_source_cutoff==1 & one_source_cutoff2==1)	
	
	*- Relative score
	gen score_relative = score_std - cutoff_std
		
		
	local male 				"% Admitted"
	local age 				"% Enrolled"
	local score_com_std_g8 	"8th grade examination - Communication"
	local score_math_std_g8	"8th grade examination - Math"
	
	local male_g8_sch 			"School: % Male in 8th grade on application year"
	local spanish_g8_sch 		"School: % Spanish speakers in 8th grade on application year"
	local socioec_index_g8_sch		"School: SE Index in 8th grade on application year"

	foreach v in male age score_com_std_g8 score_math_std_g8 male_g8_sch spanish_g8_sch socioec_index_g8_sch {	

		if "`v'" == "age" {
			binsreg `v' score_relative ///
				if abs(score_relative)<$window ///
				& sample==1 ///
				,  ///
				ylabel(15(1)21) ///
				xsize(5) ///
				ysize(5) ///
				xtitle("Standardized score relative to cutoff")  ///
				ytitle("``v''")  ///
				bycolors(gs0) ///
				name(`v', replace)
			}
			
		if substr("`v'",1,5)=="score" | substr("`v'",1,5)=="socio"  {
			binsreg `v' score_relative ///
				if abs(score_relative)<$window ///
				& sample==1 ///
				,  ///
				ylabel(-0.4(0.2)0.4) ///
				xsize(5) ///
				ysize(5) ///
				xtitle("Standardized score relative to cutoff")  ///
				ytitle("``v''")  ///
				bycolors(gs0) ///
				name(`v', replace)
			}			
			
		if "`v'" != "age" & !(substr("`v'",1,5)=="score" | substr("`v'",1,5)=="socio") {
			binsreg `v' score_relative ///
				if abs(score_relative)<$window ///
				& sample==1 ///
				,  ///
				ylabel(0(0.2)1) ///
				xsize(5) ///
				ysize(5) ///
				xtitle("Standardized score relative to cutoff")  ///
				ytitle("``v''")  ///
				bycolors(gs0) ///
				name(`v', replace)
			}
				
		graph export "$FIGURES\\rd_`v'_`cell'.png", replace
		}

		/*
	graph combine 					///
					male 	///
					age 	///
					score_com_std_g8 ///
					score_math_std_g8 /// 
					, ///
		xsize(8) col(2) ///
		name(mccrary, replace)
		
	graph export 	"$FIGURES/covariates.png", replace	
	*/
	 
	
	gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=.
	
	forvalues p = 1/5 {
		gen score_relative_`p' 			= score_relative^`p'
		gen ABOVE_score_relative_`p' 	= ABOVE*score_relative_`p'
	}
	
	global scores_5 		= "score_relative_1 		score_relative_2 		score_relative_3 		score_relative_4 		score_relative_5"
	global ABOVE_scores_5 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2 	ABOVE_score_relative_3 	ABOVE_score_relative_4 	ABOVE_score_relative_5"
	
	foreach v in male age score_com_std_g8 score_math_std_g8 male_g8_sch spanish_g8_sch socioec_index_g8_sch {	
		reghdfe `v' 					///
				ABOVE ${scores_5} ${ABOVE_scores_5} ///
				if abs(score_relative)<$window ///
				& sample==1 ///
				, a(id_cutoff)
		}


end



********************************************************************************
* first stage
* 
* Description: 
********************************************************************************

capture program drop first_stage
program define first_stage

	args type cell

	use "$TEMP/applied_matched.dta", clear
	capture drop _merge
	
	rename *_`cell' *
	rename *_`type' * 
	
	*- Exclude those without estimated cutoffs
	keep if lottery_nocutoff == 0

	*- Exclude those at cutoff
	gen at_cutoff = rank_score_raw==cutoff_rank	
	
	*- Only valid cutoffs (pass McCrary test)
	**# Apparently there are some missings in mccrary_pv_def that are not being properly accounted for the 'mccrary_test' indicator.
	count if mccrary_pv_def == . & mccrary_test==1
	gen valid_flex_cutoff = ((mccrary_pv_def>0.1 & mccrary_pv_biasi>0.1) & (mccrary_test==1 & mccrary_pv_def!=. & mccrary_pv_biasi!=.))
	gen valid_strict_cutoff = ((mccrary_pv_def>0.1 | mccrary_pv_biasi>0.1) & (mccrary_test==1 & mccrary_pv_def!=. & mccrary_pv_biasi!=.))
	
	*- Only valid cutoffs
	gen consistent_cutoff 		= (cutoff_rank == cutoff_rank_all)
	
	*- Cutoffs that come from only one source?
	//This identifies one with big outliers (few observations with different scale)
	bys id_cutoff: egen score_std_max = max(abs(score_std))
	gen one_source_cutoff = (score_std_max<5) //approx
	
	//This aims to identify bimodal distributions. Not enough observations within 0.5sd of mean (Expected is ~40%)
	bys id_cutoff: egen N = count(score_std)
	bys id_cutoff: egen temp_N_half_sd = count(score_std) if abs(score_std)<0.5
	bys id_cutoff: egen N_half_sd = max(temp_N_half_sd)
	gen one_source_cutoff2 = (N_half_sd/N>0.2)

	
	*- Sample to use
	gen sample = (not_at_cutoff==1 & valid_flex_cutoff==1 & consistent_cutoff==1 & one_source_cutoff==1 & one_source_cutoff2==1)
	
	*- Relative score
	gen score_relative = score_std - cutoff_std
	
	//## Strange behavior. Check if defined correctly.
	tab enrolled_any_next enrolled_any, m 
	
	//binscatter admitted 			score_relative if abs(score_relative)<2, n(100)
	//binscatter enrolled 			score_relative if abs(score_relative)<2, n(100)
	//binscatter enrolled_any 		score_relative if abs(score_relative)<2, n(100)
	//binscatter enrolled_any_1delay 	score_relative if abs(score_relative)<2, n(100)
	
	local admitted 				"% Admitted"
	local enrolled 				"% Enrolled"
	local enrolled_any 			"% Enrolled to any college"
	local enrolled_any_1delay 	"% Enrolled to any college this or next year"
	local enrolled_ever 		"% Enrolled to any college ever"
	
	local score_com_std_g8_sch 	"School: 8th grade score - Communication on application year"
	local score_math_std_g8_sch	"School: 8th grade score - Math on application year"

	local applied_year1_sch			"% applicants from school (same year)"
	local applier_year2_sch			"% applicants from school (next year)"

	local enrolled_year1_sch		"% enrolled from school (same year)"
	local enrolled_year2_sch		"% enrolled from school (next year)"
	local enrolled_year4_sch		"% enrolled from school (year 4)"
	
	*- Plot the RD graph
	foreach v in 	admitted enrolled enrolled_any enrolled_any_1delay enrolled_ever ///
					public_any public_ever ///
					score_com_std_g8_sch score_math_std_g8_sch ///
					applied_year1_sch applied_year2_sch enrolled_year1_sch enrolled_year2_sch enrolled_year4_sch {	
		
		if substr("`v'",1,5)=="score" {	
			binsreg `v' 			score_relative ///
				if abs(score_relative)<$window ///
				& sample==1 ///
				,  ///
				ylabel(0(0.2)1) ///
				xsize(5) ///
				ysize(5) ///
				xtitle("Standardized score relative to cutoff")  ///
				ytitle("``v'' to target college")  ///
				bycolors(gs0) ///
				name(`v', replace)
			}
			
		if substr("`v'",1,5)!="score" {	
			binsreg `v' 			score_relative ///
				if abs(score_relative)<$window ///
				& sample==1 ///
				,  ///
				ylabel(0(0.2)1) ///
				xsize(5) ///
				ysize(5) ///
				xtitle("Standardized score relative to cutoff")  ///
				ytitle("``v'' to target college")  ///
				bycolors(gs0) ///
				name(`v', replace)
				
				
			}
			
		graph export "$FIGURES\\rd_`v'_`cell'.png", replace
		}

		/*
		graph combine 					///
						admitted 	///
						enrolled 	///
						, ///
			xsize(8) col(2) ///
			name(mccrary, replace)
			
		graph export 	"$FIGURES/first_stage.png", replace	


		graph combine 					///
						enrolled_any 	///
						enrolled_any_1delay 	///
						, ///
			xsize(8) col(2) ///
			name(mccrary, replace)
			
		graph export 	"$FIGURES/outcomes.png", replace	
		*/
		
		
		*- Run the RD regression
		gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=. //To avoid float issues around 0, we use the precisely integer rank scores.
		
		forvalues p = 1/5 {
			gen score_relative_`p' 			= score_relative^`p'
			gen ABOVE_score_relative_`p' 	= ABOVE*score_relative_`p'
		}
		
		global scores_5 		= "score_relative_1 		score_relative_2 		score_relative_3 		score_relative_4 		score_relative_5"
		global ABOVE_scores_5 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2 	ABOVE_score_relative_3 	ABOVE_score_relative_4 	ABOVE_score_relative_5"
		
		
	foreach v in 	admitted enrolled enrolled_any enrolled_any_1delay enrolled_ever ///
					public_any public_ever ///
					score_com_std_g8_sch score_math_std_g8_sch ///
					applied_year1_sch applied_year2_sch enrolled_year1_sch enrolled_year2_sch enrolled_year4_sch {	
		reghdfe `v' 					///
				ABOVE ${scores_5} ${ABOVE_scores_5} ///
				if abs(score_relative)<$window ///
				& sample==1 ///
				, a(id_cutoff)
		}

end




********************************************************************************
* Run program
********************************************************************************

main