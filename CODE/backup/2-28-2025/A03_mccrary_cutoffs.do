/********************************************************************************
- Author: Francisco Pardo
- Description: Does the mccrary test cutoff by cutoff
- Date started: 08/12/2024
- Last update: 08/12/2024

- Changes to original dofile:
	1. 
*******************************************************************************/

capture program drop main 
program define main 


setup


//test
mccrary_all		noz 	major public

//Plot histograms by university
histograms_university 	noz major critic
histograms_university 	noz major all
histograms_university 	noz department all


// We do the mccrary test for (i) all observations/excluding scores at cutoffs, (ii) department and major cutoffs
mccrary_cutoff 		noz	major
mccrary_cutoff 		all major

mccrary_cutoff		noz department
mccrary_cutoff 		all department

figure_example noz major

end


********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup

	set seed 1234
	global test = 0	
	global window = 2

end

 
********************************************************************************
* mccrary_test
* 
* Description: loop to estimate the mccrary test for every cutoff
********************************************************************************

capture program drop mccrary_all
program define mccrary_all

	args type cell admin

	cap log close
	
	log using "$LOGS/mccrary_all_`type'_`cell'.log", text replace
	
	*- Strange scores
	use "$TEMP/applied.dta", clear 
	merge m:1 id_cutoff_`cell' using   "$TEMP/applied_cutoffs_`cell'.dta", keep(master match)	
	rename  *_`cell' *
	gen lottery_nocutoff = (cutoff_std==.)
	drop _merge
	compress 
	
	/*rename 	(score_std_`cell' 	rank_score_raw_`cell') ///
			(score_std 			rank_score_raw)
	*/
	gen score_relative = score_std - cutoff_std
	
	*- See sample type (noz = not at zero/cutoff)
	if "`type'" == "noz" 	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)
	if "`type'" == "all"	gen not_at_cutoff = (1)
	
	*- Admin (all/public/private)
	if "`admin'" == "public" 	gen admin=(public==1)
	if "`admin'" == "private" 	gen admin=(public==0)
	if "`admin'" == "all" 		gen admin=(1)
	
	keep id_cutoff cutoff_raw score_relative public not_at_cutoff admin universidad year

	
	*All
	rddensity score_relative if abs(score_relative)<5 &   not_at_cutoff==1 & admin==1, c(0) plot kernel(triangular)
	//local mccrary_pv: display %9.3f e(pv_q)
	graph export 	"$FIGURES/mccrary_all_`type'_`cell'_`admin'_triangular.png", replace
	
	rddensity score_relative if abs(score_relative)<5 &   not_at_cutoff==1 & admin==1, c(0) plot kernel(epanechnikov)
	graph export 	"$FIGURES/mccrary_all_`type'_`cell'_`admin'_epanechnikov.png", replace	
	
	rddensity score_relative if abs(score_relative)<5 &  not_at_cutoff==1 & admin==1, c(0) plot kernel(uniform)
	graph export 	"$FIGURES/mccrary_all_`type'_`cell'_`admin'_uniform.png", replace		
	
	
	
	*Donut hoe
	rddensity score_relative if abs(score_relative)<5 &  abs(score_relative)>0.005 & not_at_cutoff==1 & admin==1, c(0) plot kernel(triangular)
	//local mccrary_pv: display %9.3f e(pv_q)
	graph export 	"$FIGURES/mccrary_all_`type'_`cell'_`admin'_triangular_donut.png", replace
	
	rddensity score_relative if abs(score_relative)<5 &  abs(score_relative)>0.005 & not_at_cutoff==1 & admin==1, c(0) plot kernel(epanechnikov)
	graph export 	"$FIGURES/mccrary_all_`type'_`cell'_`admin'_epanechnikov_donut.png", replace	
	
	rddensity score_relative if abs(score_relative)<5 &  abs(score_relative)>0.005 & not_at_cutoff==1 & admin==1, c(0) plot kernel(uniform)
	graph export 	"$FIGURES/mccrary_all_`type'_`cell'_`admin'_uniform_donut.png", replace		
	
end


********************************************************************************
* histograms_university
* 
* Description: We show histograms per university
********************************************************************************

capture program drop histograms_university
program define histograms_university

	args type cell issues

	cap log close
	
	//local cell major
	
	log using "$LOGS/histograms_university_`type'_`cell'.log", text replace
	
	*- Strange scores
	use "$TEMP/applied.dta", clear 
	merge m:1 id_cutoff_`cell' using   "$TEMP/applied_cutoffs_`cell'.dta", keep(master match)	
	rename  *_`cell' *
	gen lottery_nocutoff = (cutoff_std==.)
	drop _merge
	
	if "`issues'" == "all" assert 1==1
	if "`issues'" == "critic" {
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
	}
	
	
	/*rename 	(score_std_`cell' 	rank_score_raw_`cell') ///
			(score_std 			rank_score_raw)
	*/
	gen score_relative = score_std - cutoff_std
	drop if score_relative==.
	
	*- See sample type (noz = not at zero/cutoff)
	if "`type'" == "noz" 	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)
	if "`type'" == "all"	gen not_at_cutoff = (1)	

	gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=.

	keep universidad codigo_modular score_relative not_at_cutoff admitted ABOVE
	
	compress 
	
	levelsof universidad, local(levels)

	foreach l of local levels {
		di `"`l'"'
		sum codigo_modular if universidad == `"`l'"'
		local cod = r(max)
		local N = r(N)
		
		capture binsreg admitted score_relative if abs(score_relative)<$window & not_at_cutoff==1 & universidad == `"`l'"',  savedata($TEMP\binsreg_`cod') replace  by(ABOVE) bycolors(stc1 stc1) bysymbols(O O) bylpatterns(solid solid) legend(off) //nbins(50) 

		//Sometimes it gives an error for ABOVE of the type "<istmt>:  3301  subscript invalid". It can also give and error due to "option nq() incorrectly specified .... r(198);". Finally sometimes it works but produces no graph. So we consider that in making several attempts as we haven't figured out the error.
		
		if _rc!=0 | fileexists("$TEMP\binsreg_`cod'.dta")==0 capture binsreg admitted score_relative if abs(score_relative)<$window & not_at_cutoff==1 & universidad == `"`l'"',  savedata($TEMP\binsreg_`cod') replace  //by(ABOVE) bycolors(stc1 stc1) bysymbols(O O) bylpatterns(solid solid) legend(off) //nbins(50) 		
		
		//It failed a couple of times 
		forvalues nbins = 100(-10)10 {
		if _rc!=0 | fileexists("$TEMP\binsreg_`cod'.dta")==0 capture binsreg admitted score_relative if abs(score_relative)<$window & not_at_cutoff==1 & universidad == `"`l'"',  savedata($TEMP\binsreg_`cod') replace nbins(`nbins')
		}
		
		preserve
			append using "$TEMP\binsreg_`cod'"
			
			twoway 	///
					(histogram score_relative if universidad == `"`l'"' & abs(score_relative)<$window & not_at_cutoff==1, color(green%30) ytitle("Histogram Density", axis(1))) ///
					(scatter dots_fit dots_x, yaxis(2) color(stc1) ytitle("% Admitted", axis(2)) ylab(0(0.2)1, axis(2))) ///
					, ///
					xtitle("Score relative to cutoff") ///
					note("ID: `cod'" "Obs: `N'") ///
					legend(off) ///
					title(`"`l'"')
			
			graph export 	"$FIGURES\TEMP\histogram_score_`cod'_`type'_`cell'.png", replace
			
			erase "$TEMP\binsreg_`cod'.dta"
		restore
		
	}
		//preserve
		
end


********************************************************************************
* mccrary_cutoff
* 
* Description: loop to estimate the mccrary test for every cutoff
********************************************************************************

capture program drop mccrary_cutoff
program define mccrary_cutoff

	args type cell

	cap log close
	
	log using "$LOGS/mccrary_cutoff_`type'_`cell'.log", text replace
	
	*- Strange scores
	use "$TEMP/applied.dta", clear 
	merge m:1 id_cutoff_`cell' using   "$TEMP/applied_cutoffs_`cell'.dta", keep(master match)	
	rename  *_`cell' *
	gen lottery_nocutoff = (cutoff_std==.)
	drop _merge
	compress 
	
	/*rename 	(score_std_`cell' 	rank_score_raw_`cell') ///
			(score_std 			rank_score_raw)
	*/
	gen score_relative = score_std - cutoff_std
	
	*- See sample type (noz = not at zero/cutoff)
	if "`type'" == "noz" 	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)
	if "`type'" == "all"	gen not_at_cutoff = (1)

	keep id_cutoff cutoff_raw score_relative not_at_cutoff
	
	
	if $test == 1 & "`cell'" == "major" 		keep if id_cutoff == 20127
	if $test == 1 & "`cell'" == "department" 	keep if id_cutoff == 7000
	 
	tempfile mccrary_test_`cell'
	save `mccrary_test_`cell'', replace

	clear

	gen id_cutoff = .
	gen double mccrary_pv_def = .
	gen double mccrary_pv_biasi = .
	gen double mccrary_test = .
		
	save "$TEMP/mccrary_cutoffs_`type'_`cell'.dta", replace emptyok
	 

	use `mccrary_test_`cell'', clear

	//keep if id_cutoff>3000

	levelsof id_cutoff, local(levels)

	foreach l of local levels {
		use `mccrary_test_`cell'', clear
		keep if id_cutoff == `l'
		di "`l'"
		sum cutoff_raw 
		local mccrary_pv_def = .
		local mccrary_pv_biasi = .
		local mccrary_test = 0
		
		//replace mccrary_test = 0 //no cutoff
		if `r(N)'>0 {
			capture rddensity score_relative if id_cutoff == `l' & not_at_cutoff==1, c(0) 
			if _rc==0	{
				local mccrary_pv_def = `e(pv_q)'
				local mccrary_test = 1
				}
			if _rc!=0 | `mccrary_pv_def'==.	{
				local mccrary_test = 2
				}	
				
			capture rddensity score_relative if id_cutoff == `l' & not_at_cutoff==1, c(0) p(3) kernel(uniform) 
			if _rc==0	{
				local mccrary_pv_biasi = `e(pv_q)' 
				local mccrary_test = 1
				}
			if _rc!=0 | `mccrary_pv_biasi'==.	{
				if `mccrary_test'==1 local mccrary_test = 3 
				if `mccrary_test'==2 local mccrary_test = 4 
				}				
		}

		keep if _n==1
		gen double mccrary_pv_def = `mccrary_pv_def'
		gen double mccrary_pv_biasi = `mccrary_pv_biasi'
		gen double mccrary_test = `mccrary_test'
		keep id_cutoff mccrary*
		append using  "$TEMP/mccrary_cutoffs_`type'_`cell'.dta"
		save  "$TEMP/mccrary_cutoffs_`type'_`cell'.dta", replace			
				
		compress
		if mod(`l',60)==10 save "$TEMP/mccrary_cutoffs_`type'_`cell'_TEMP.dta", replace //every 60 starting at 5.	
		
	}
	
	
	use  "$TEMP/mccrary_cutoffs_`type'_`cell'.dta", clear
	
	
	label define mccrary_test 0 "No Cutoff" 1 "Test Performed" 2 "Error in test (default)" 3 "Error in test (Biasi)" 4 "Error in test (Both)"
	label values mccrary_test mccrary_test

	label var mccrary_test "Indicates whether test was performed"
	label var mccrary_pv_def "pvalue of McCrary test (default)"
	label var mccrary_pv_biasi "pvalue of McCrary test (similar to Biasi et. al. (2024))"
	
	rename * *_`type'_`cell'
	rename id_cutoff_* id_cutoff_`cell' //This is the same for 'all' and 'noz' so no need to make a distinction by type.
	
	compress
	
	save  "$TEMP/mccrary_cutoffs_`type'_`cell'.dta", replace
	
	
	
	log close

end	


********************************************************************************
* Figure Example
* 
* Description: Example of method
********************************************************************************

capture program drop figure_example
program define figure_example
	args type cell // (1) level (2) score //id_cutoff_department/score_raw_


	use "$TEMP/applied.dta", clear 
	merge m:1 id_cutoff_`cell' using   "$TEMP/applied_cutoffs_`cell'.dta", keep(master match)	
	rename  *_`cell' *
	
	keep if universidad == "UNIVERSIDAD NACIONAL DE TRUJILLO" | universidad == "UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS"
		
	gen score_relative = score_std - cutoff_std
	drop if score_relative==.	
	gen lottery_nocutoff = (cutoff_std==.)
	
	*- See sample type (noz = not at zero/cutoff)
	if "`type'" == "noz" 	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)
	if "`type'" == "all"	gen not_at_cutoff = (1)	

	gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=.

	keep universidad codigo_modular score_relative not_at_cutoff admitted ABOVE	
	
	//levelsof universidad, local(levels)

	//foreach l of local levels {
		local l = "UNIVERSIDAD NACIONAL DE TRUJILLO"
		sum codigo_modular if universidad == `"`l'"'
		local cod = r(max)
		local N = r(N)
		
		binsreg admitted score_relative if abs(score_relative)<$window & not_at_cutoff==1 & universidad == `"`l'"',  savedata($TEMP\binsreg_example_`cod') replace  by(ABOVE) bycolors(stc1 stc1) bysymbols(O O) bylpatterns(solid solid) legend(off) //nbins(50) 

		preserve
			append using "$TEMP\binsreg_example_`cod'"
			
			twoway 	///
					(histogram score_relative if universidad == `"`l'"' & abs(score_relative)<$window & not_at_cutoff==1, color(green%30) ytitle("Histogram Density", axis(1))) ///
					(scatter dots_fit dots_x, yaxis(2) color(stc1) ytitle("% Admitted", axis(2)) ylab(0(0.2)1, axis(2))) ///
					(scatteri .03 -3 .03 -1, c(l) lcolor(red) msym(none) legend(off)) ///
					(scatteri .2 -1 .2 3, c(l) lcolor(red) msym(none) legend(off) ) ///
					, ///
					xtitle("Score relative to cutoff") ///
					xline(-1, lcolor(gs0)) ///
					note("ID: `cod'" "Obs: `N'") ///
					legend(off) ///
					title(`"`l'"')
			
			graph export 	"$FIGURES\TEMP\histogram_score_`cod'_`type'_`cell'_example1.png", replace
			
			twoway 	///
					(histogram score_relative if universidad == `"`l'"' & abs(score_relative)<$window & not_at_cutoff==1, color(green%30) ytitle("Histogram Density", axis(1))) ///
					(scatter dots_fit dots_x, yaxis(2) color(stc1) ytitle("% Admitted", axis(2)) ylab(0(0.2)1, axis(2))) ///
					(scatteri .05 -3 .05 0, c(l) lcolor(red) msym(none) legend(off)) ///
					(scatteri .35 0 .35 3, c(l) lcolor(red) msym(none) legend(off)) ///
					, ///
					xtitle("Score relative to cutoff") ///
					xline(0, lcolor(gs0)) ///
					note("ID: `cod'" "Obs: `N'") ///
					legend(off) ///
					title(`"`l'"')
			
			graph export 	"$FIGURES\TEMP\histogram_score_`cod'_`type'_`cell'_example2.png", replace
			
			twoway 	///
					(histogram score_relative if universidad == `"`l'"' & abs(score_relative)<$window & not_at_cutoff==1, color(green%30) ytitle("Histogram Density", axis(1))) ///
					(scatter dots_fit dots_x, yaxis(2) color(stc1) ytitle("% Admitted", axis(2)) ylab(0(0.2)1, axis(2))) ///
					(scatteri .15 -3 .15 1, c(l) lcolor(red) msym(none) legend(off)) ///
					(scatteri .38 1 .38 3, c(l) lcolor(red) msym(none) legend(off)) ///
					, ///
					xtitle("Score relative to cutoff") ///
					xline(1, lcolor(gs0)) ///
					note("ID: `cod'" "Obs: `N'") ///
					legend(off) ///
					title(`"`l'"')
			
			graph export 	"$FIGURES\TEMP\histogram_score_`cod'_`type'_`cell'_example3.png", replace
						
			erase "$TEMP\binsreg_example_`cod'.dta"
		restore
	//}	
	
end


********************************************************************************
* Run program
********************************************************************************

main


/*
mccrary_cutoff
mccrary_cutoff_not_at_cutoff

*/