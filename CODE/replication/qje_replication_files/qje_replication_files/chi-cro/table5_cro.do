*** Table V: Sibling Spillovers on Younger Siblings’ Applications by Differences
*** between Older Siblings’ Target and Next Best Options

***  Delta
xtile qs1  = ds1, nq(4)

local bw_colmaj   = 80
local bw_college	= 80
local covs c.score_rd c.score_rdc

*** Delta
foreach var of varlist qs1 {
  foreach level in "colmaj" "college" {
	   foreach choice in  "apply" "enroll" {

		if "`level'" == "colmaj" 	  local if "wl_students > 0 & oldest == 1 & codigo_demre_next !=. & ds1 !=."
		if "`level'" == "college" 	local if "wl_students > 0 & college_sample == 1 & oldest == 1 & codigo_demre_next !=. & ds1 !=."

		*** IV
		#delimit;
		ivreghdfe `choice'_`level' `covs' i.`var' (1.enrolls_old#i.`var' =  1.above_cutoff#i.`var') if `if'
		& score_rd >= -1*`bw_`level'' & score_rd <= `bw_`level'',
		absorb(i.year i.mcfe i.nmcfe) cluster(family_id);
		#delimit cr
		summarize `e(depvar)' if e(sample) == 1 & score_rd < 0, meanonly
		estadd scalar yctrl = r(mean)
		estadd scalar fstage = e(widstat)
		estimates store iv_`choice'_`level'_`var'_p1

	 }
  }
}

	#delimit;
	estout iv_*
	using "2SLS. Siblings Heterogeneous Effects by Delta Program Chars.tex",
	cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
	stats(N fstage ymean, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Outcome mean" ))
	mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01)
	indicate("Running variable polynomial =*score_rd*");
	#delimit cr

	estimates drop _all
