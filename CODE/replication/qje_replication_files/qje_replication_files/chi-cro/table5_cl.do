*** Table V: Sibling Spillovers on Younger Siblings’ Applications by Differences
*** between Older Siblings’ Target and Next Best Options

***  Delta
xtile qusd = dusd, nq(4)
xtile qs1  = ds1, nq(4)
xtile qrc  = drc, nq(4)

local bw_colmaj   = 18.00
local bw_college	= 12.50
local covs c.score_rd c.score_rdc

*** Delta
foreach var of varlist qusd qs1 qrc {
  foreach level in "colmaj" "college" {
	   foreach choice in  "apply" "enroll" {

		if "`level'" == "colmaj" 	  local if "wl_students > 0 & oldest == 1 & codigo_demre_next !=. & dusd !=. & drc !=. & ds1 !=."
		if "`level'" == "college" 	local if "wl_students > 0 & college_sample == 1 & oldest == 1 & codigo_demre_next !=. & dusd !=. & drc !=. & ds1 !=."

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


/*
       qusd |        Mean   Std. Dev.       Freq.
------------+------------------------------------
          1 |  -.85408627    .6554467      88,259 ->
          2 |  -.03217778   .06332802      90,517 ->
          3 |   .33567262    .1853972      88,664 ->
          4 |   1.7129695   .95181772      93,640 ->
------------+------------------------------------
      Total |   .30982359   1.1048038     361,080


        qs1 |        Mean   Std. Dev.       Freq.
------------+------------------------------------
          1 |  -.21816941   .80671949      90,358
          2 |   .07461296   .04043648      82,390
          3 |   .21380369   .04298718      92,896
          4 |    .5161018   .48933762      95,436
------------+------------------------------------
      Total |    .1538446   .54650524     361,080


        qrc |        Mean   Std. Dev.       Freq.
------------+------------------------------------
          1 |  -.08647413   .06462455      84,708
          2 |   .00025722   .01279715      91,064
          3 |   .05141949   .01675914      92,874
          4 |   .15343681   .07044897      92,434
------------+------------------------------------
      Total |   .03228283   .09890787     361,080

*/
