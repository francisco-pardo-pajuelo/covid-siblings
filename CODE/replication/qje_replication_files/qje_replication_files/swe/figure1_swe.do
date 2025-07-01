preserve
*** Figure I: Older Siblings’ Admission and Enrollment Probabilities in Target
*** Major-College at the Admission Cutoff (First Stage)

// Run first stage estimation with admissions and enrollments.
foreach var of varlist admitted enrolled {
	restore, preserve

	// Limit support
	quietly keep if cutoff_distance_adjusted > $score_min & cutoff_distance_adjusted < $score_max
	quietly keep if !missing(cutoff_distance_adjusted)
	quietly keep if jk_different_instprog == 1
	quietly keep if !missing(`var')

	// We are not interested in the sibling relation here so only count
	// each admission/cutoff once per individual. Otherwise one person could
	// have multiple younger siblings.
	bysort id id_cutoff: generate sample = _n == 1
	quietly keep if sample

	// Generate bins, do not use rdplot because it doesn't work when
	// all bins have admitted == 0
	local bin_size = ($score_max - $score_min) / ($n_bins * 2)
	quietly generate rdplot_id = floor(cutoff_distance_adjusted / `bin_size')
	bysort rdplot_id: egen rdplot_mean_x = mean(cutoff_distance_adjusted)
	bysort rdplot_id: egen rdplot_mean_y = mean(`var')

	// Running id in each bin (for filter)
	quietly bysort rdplot_id: gen rdplot_bin_id = _n

	// Y bounds
	local lb   = 0
	local ub   = 1
	local gap  = 0.1

	#delimit;
	twoway
		(lpolyci `var' cutoff_distance_adjusted if cutoff_distance_adjusted >= 0,
			bwidth($poly_bw) degree(1) kernel(epanechnikov)
			lcolor(red) ciplot(rline) lcolor(red))
		(lpolyci `var' cutoff_distance_adjusted if cutoff_distance_adjusted < 0,
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

	quietly graph save   "first_stage_`var'_p1_swe.gph", replace
	quietly graph export "first_stage_`var'_p1_swe.pdf", replace as(pdf)
	quietly graph export "first_stage_`var'_p1_swe.eps", replace as(eps)
	quietly capture drop rdplot_*
}

restore
exit 0
