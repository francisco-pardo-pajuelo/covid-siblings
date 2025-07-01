*** Table VI: Sibling Spillovers on Younger Siblings’ Application by Older Siblings’
*** Target Option Characteristics

*** Target
xtile qtusd = tusd, nq(4)
xtile qts1  = ts1, nq(4)
xtile qtrc  = trc, nq(4)

local bw_colmaj   	= 18.00
local bw_college	= 12.50
local covs c.score_rd c.score_rdc

*** Target
foreach var of varlist qtusd qts1 qtrc {
  foreach level in "colmaj" "college" {
	   foreach choice in   "apply" "enroll" {

		if "`level'" == "colmaj" 	  local if "wl_students > 0 & oldest == 1  & codigo_demre_next !=. & tusd !=. & trc !=. & ts1 !=."
		if "`level'" == "college" 	local if "wl_students > 0 & college_sample == 1 & oldest == 1 & codigo_demre_next !=. & tusd !=. & trc !=. & ts1 !=."

		*** IV
		#delimit;
		ivreghdfe `choice'_`level' `covs' (1.enrolls_old#i.`var' =  1.above_cutoff#i.`var') if `if'
		& score_rd >= -1*`bw_`level'' & score_rd <= `bw_`level'',
		absorb(i.year i.mcfe i.nmcfe) cluster(family_id);
		#delimit cr
		summarize `e(depvar)' if e(sample) == 1 & score_rd < 0, meanonly
		estadd scalar yctrl = r(mean)
		estadd scalar fstage = e(widstat)
		estimates store iv_`choice'_`level'_`var'_p`x'

	 }
  }
}

#delimit;
estout iv_*
using "2SLS. Siblings Heterogeneous Effects by Target Program Chars.tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N fstage ymean, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Outcome mean" ))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01)
indicate("Running variable polynomial =*score_rd*");
#delimit cr

estimates drop _all

/*
      qtusd |        Mean   Std. Dev.       Freq.
------------+------------------------------------
          1 |   1.6646941    .1172794      87,109
          2 |   2.2976957   .21780389      81,165
          3 |   3.2354339   .30911746      91,254
          4 |   4.8220767   .88472825     101,552
------------+------------------------------------
      Total |   3.0919467   1.3185504     361,080


       qts1 |        Mean   Std. Dev.       Freq.
------------+------------------------------------
          1 |   .56098594    .1079906      70,702
          2 |   .81750752    .0693296      88,129
          3 |   1.0603851   .07652425     100,060
          4 |   1.4638425   .51938029     102,189
------------+------------------------------------
      Total |   1.0175022   .43460677     361,080


       qtrc |        Mean   Std. Dev.       Freq.
------------+------------------------------------
          1 |   .75870153   .06665314      80,732
          2 |    .8585934   .01667497      89,934
          3 |   .90715615   .01347365      95,346
          4 |   .95781814   .01933168      95,068
------------+------------------------------------
      Total |   .87520715   .07986769     361,080

*/
