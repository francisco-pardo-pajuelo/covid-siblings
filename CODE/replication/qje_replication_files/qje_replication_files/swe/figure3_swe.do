preserve

*** Figure III: Probabilities of Applying and Enrolling in Older Sibling’s Target College
*** Figure V: Probabilities of Applying and Enrolling in Older Sibling’s Target College-Major
*** Figure VI: Probabilities of Applying and Enrolling in Older Sibling’s Target Major

foreach type in inst prog instprog {
	foreach sib_app in first all enrolls {
		local y = "same_`type'_`sib_app'"
		restore, preserve

		// Limit support
		quietly keep if cutoff_distance_adjusted > $score_min & cutoff_distance_adjusted < $score_max
		quietly keep if !missing(cutoff_distance_adjusted)
		quietly keep if !missing(`y')

		if "`type'" == "instprog" quietly keep if jk_different_instprog == 1
		if "`type'" == "inst" quietly keep if jk_different_insts == 1
		if "`type'" == "prog" quietly keep if jk_different_progs == 1

		// Residuals
		capture drop `y'_pred
		quietly reghdfe `y', residuals(`y'_pred) absorb($absorb_default) cluster(id_family)
		// Center at the first bin
		local bin_size = ($score_max - $score_min) / ($n_bins * 2)
		quietly summarize `y' if cutoff_distance_adjusted < 0 & cutoff_distance_adjusted >= 0 - `bin_size'
		quietly replace `y'_pred = `y'_pred + r(mean)

		// Generate bins
		quietly generate rdplot_id = floor(cutoff_distance_adjusted / `bin_size')
		quietly bysort rdplot_id: gen rdplot_bin_id = _n
		quietly bysort rdplot_id: egen rdplot_mean_x = mean(cutoff_distance_adjusted)
		quietly bysort rdplot_id: egen rdplot_mean_y = mean(`y'_pred)

		// Y bounds
		quietly summarize rdplot_mean_y
		local lb = round(r(min), 0.05) - 0.05
		local ub = round(r(max), 0.05) + 0.05
		local gap = 0.025

		#delimit;
		twoway
			(lpolyci `y'_pred cutoff_distance_adjusted if cutoff_distance_adjusted >= 0,
				bwidth($poly_bw) degree(1) kernel(epanechnikov)
				lcolor(red) ciplot(rline) lcolor(red))
			(lpolyci `y'_pred cutoff_distance_adjusted if cutoff_distance_adjusted < 0,
				bwidth($poly_bw) degree(1) kernel(epanechnikov)
				lcolor(red) ciplot(rline) lcolor(red))
			(scatter rdplot_mean_y rdplot_mean_x if rdplot_bin_id == 1,
				sort mcolor(navy) msize(vsmall) msymbol(circle))
			(scatteri `lb' 0 `ub' 0, recast(line) lpattern(dash) lcolor(black)),
			yscale(range(`lb' `ub'))
			ylabel(`lb'(`gap')`ub', labels labsize(vsmall)
							labcolor(black) angle(horizontal) format(%03.2f))
			xtitle("Older Siblings' Application Score", size(small))
			xlabel($score_min($score_tick)$score_max, labsize(vsmall))
			legend(off);
		#delimit cr

		quietly graph save   "rf_p1_`type'_`sib_app'.gph", replace
		quietly graph export "rf_p1_`type'_`sib_app'.pdf", replace as(pdf)
		quietly graph export "rf_p1_`type'_`sib_app'.eps", replace as(eps)
		quietly capture drop rdplot_*
	}
}

restore
exit 0
