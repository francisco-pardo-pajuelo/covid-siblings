
	args type cell
	
	local type "noz"
	local cell "major"

	cap log close
	
	//local cell major
	
	*log using "$LOGS/histograms_university_`type'_`cell'.log", text replace
	
	*- Strange scores
	use "$TEMP/applied.dta", clear 
	merge m:1 id_cutoff_`cell' using   "$TEMP/applied_cutoffs_`cell'.dta", keep(master match)	
	rename  *_`cell' *
	gen lottery_nocutoff = (cutoff_std==.)
	drop _merge
	
	
	/*rename 	(score_std_`cell' 	rank_score_raw_`cell') ///
			(score_std 			rank_score_raw)
	*/
	gen score_relative = score_std - cutoff_std
	
	*- See sample type (noz = not at zero/cutoff)
	if "`type'" == "noz" 	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)
	if "`type'" == "all"	gen not_at_cutoff = (1)	
	
	gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=.

	keep universidad codigo_modular score_relative not_at_cutoff admitted ABOVE
	
	compress 
	
	local l = "UNIVERSIDAD RICARDO PALMA"
	
	sum codigo_modular if universidad == `"`l'"'
	local cod = r(max)
	binsreg admitted score_relative if abs(score_relative)<5 & not_at_cutoff==1 & universidad == `"`l'"', by(ABOVE) bycolors(stc1 stc1) bysymbols(O) bylpatterns(solid) legend(off) savedata($TEMP\binsreg) replace 
	append using "$TEMP\binsreg"
	twoway 	///
			(histogram score_relative if universidad == `"`l'"' & abs(score_relative)<5 & not_at_cutoff==1, color(green%30) ytitle("Histogram Density")) ///
			(scatter dots_fit dots_x, yaxis(2) color(stc1) ytitle("% Admitted", axis(2))) ///
			, ///
			legend(off) ///
 			title(`"`l'"')
			

	
	
	
	/*
	* Run binsreg, save data in the file "result.dta" 
binsreg y x w, line(3,3) ci(3,3) cb(3,3) polyreg(4) savedata(result)

* Read the data produced by binsreg 
use result, clear

* Add the dots
twoway (scatter dots_fit dots_x, sort mcolor(blue) msymbol(smcircle)), ytitle(Y) xtitle(X)

* Add the line
twoway (scatter dots_fit dots_x, sort mcolor(blue) msymbol(smcircle)) ///
       (line line_fit line_x, sort lcolor(blue)), ytitle(Y) xtitle(X) legend(off)

* Add the CI
twoway (scatter dots_fit dots_x, sort mcolor(blue) msymbol(smcircle)) ///
       (line line_fit line_x, sort lcolor(blue)) ///
	   (rcap CI_l CI_r CI_x, sort lcolor(blue)), ytitle(Y) xtitle(X) legend(off)

* Add the CB
twoway (scatter dots_fit dots_x, sort mcolor(blue) msymbol(smcircle)) ///
       (line line_fit line_x, sort lcolor(blue)) ///
	   (rcap CI_l CI_r CI_x, sort lcolor(blue)) ///
	   (rarea CB_l CB_r CB_x, sort lcolor(none%0) fcolor(blue%50) fintensity(50)), ytitle(Y) xtitle(X) legend(off)
	   
* Add the polyreg
twoway (scatter dots_fit dots_x, sort mcolor(blue) msymbol(smcircle)) ///
       (line line_fit line_x, sort lcolor(blue)) ///
	   (rcap CI_l CI_r CI_x, sort lcolor(blue)) ///
	   (rarea CB_l CB_r CB_x, sort lcolor(none%0) fcolor(blue%50) fintensity(50)) ///
	   (line poly_fit poly_x, sort lcolor(red)), ytitle(Y) xtitle(X) legend(off)
	
	
	*/
	
	