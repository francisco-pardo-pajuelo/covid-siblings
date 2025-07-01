*** Figure III: Probabilities of Applying and Enrolling in Older Sibling’s Target College
*** Figure V: Probabilities of Applying and Enrolling in Older Sibling’s Target College-Major
*** Figure VI: Probabilities of Applying and Enrolling in Older Sibling’s Target Major

foreach level in "colmaj" "college" "major" {

		if "`level'" == "colmaj" 	local if = "wl_students > 0 & oldest == 1 "
		if "`level'" == "college" local if = "wl_students > 0 & oldest == 1  & college_sample == 1"
		if "`level'" == "major" 	local if = "wl_students > 0 & oldest == 1  & major_sample == 1"

		foreach choice in "apply1st" "apply" "enroll" {

		*** Adjust parameters to have 40 bins in total (20 on each side).
		local nbins1 = round(100/5)
		local nbins2 = round(100/5)

		#delimit;
		areg `choice'_`level' i.year if `if'
		, absorb(mcfe) cluster(family_id);
		#delimit cr

		predict `choice'_`level'2, residuals
		sum `choice'_`level' if `if' & score_rd >= -5 & score_rd < 0
		replace `choice'_`level'2 = `choice'_`level'2 + r(mean)

		*** Plot:
		#delimit;
		rdplot `choice'_`level'2 score_rd if `if' & score_rd >= -100 & score_rd <= 100 , c(0) p(`x')
		nbins(`nbins1' `nbins2')  kernel(triangular) ci(95) genvars
		h(100 100) support(100 100)
		graph_options(
		ylabel(, labsize(vsmall) angle(horizontal) format(%3.2f))
		xtitle(Sibling' PSU Score) xtitle(, size(small))
		xlabel(-100(10)100, labsize(vsmall))
		legend(off));
		#delimit cr;

		bys rdplot_id: gen bin_id = _n

		sum rdplot_mean_y
		local lb = round(r(min),0.05) - 0.05
		local ub = round(r(max),0.05) + 0.05
		local gap = 0.025

		#delimit;
		twoway (lpolyci `choice'_`level'2 score_rd if score_rd >= 0, bwidth($bwc) degree(1) lcolor(red) ciplot(rline) lcolor(red))
		(lpolyci `choice'_`level'2 score_rd if score_rd < 0, bwidth($bwc) degree(1) lcolor(red) ciplot(rline) lcolor(red))
		(scatter rdplot_mean_y rdplot_mean_x if bin_id == 1, sort  mcolor(navy) msize(vsmall) msymbol(circle))
		(scatteri `lb' 0 `ub' 0, recast(line) lpattern(dash) lcolor(black))
		if score_rd >= -100 & score_rd <= 100 & `choice'_`level' !=. & `if' ,
		yscale(range(`lb' `ub')) ylabel(`lb'(`gap')`ub' , labels labsize(vsmall) labcolor(black) angle(horizontal) format(%04.3f))
		xtitle(Older Siblings' Application Score ) xtitle(, size(midsmall))
		xlabel(-100(10)100, labsize(vsmall))
		legend(off);
		#delimit cr

		drop rdplot_id rdplot_mean_x rdplot_mean_y rdplot_ci_l rdplot_ci_r bin_id rdplot_N rdplot_min_bin rdplot_max_bin rdplot_mean_bin rdplot_se_y rdplot_hat_y `choice'_`level'2
		graph save   "rf_p1_`choice'_`level'.gph",replace
		graph export "rf_p1_`choice'_`level'.pdf",replace as(pdf)
    graph export "rf_p1_`choice'_`level'.eps",replace as(eps)

	}
}
