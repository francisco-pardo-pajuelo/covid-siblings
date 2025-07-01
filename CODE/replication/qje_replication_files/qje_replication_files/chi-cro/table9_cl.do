*** Table IX: Sibling Spillovers on Academic Performance

local bw_colmaj   = 18.00
local covs c.score_rd c.score_rdc

foreach level in "colmaj" {

		if "`level'" == "major" local if "wl_students > 0 & oldest == 1"
		local contador = 0

		foreach var of varlist hs_gpa takes_sat avg_sat applies {

			local contador = `contador' + 1

			*** Reduced form
			#delimit;
			reghdfe `var' above_cutoff `covs' if `if'
			& score_rd >= -1*`bw_`level'' & score_rd <= `bw_`level'',
			absorb(i.mcfe i.year) cluster(family_id);
			#delimit cr
			estadd ysumm
			estimates store m`contador'

			*** 2sls
			#delimit;
			ivreghdfe `var' `covs' (enrolls_old = above_cutoff) if `if'
			& score_rd >= -1*`bw_`level'' & score_rd <= `bw_`level'',
			absorb(i.mcfe i.year) cluster(family_id) savefprefix(fs_);
			#delimit cr
			estadd ysumm
			estadd scalar fstage = e(widstat)
			estimates store iv`contador'

			estimates restore fs_iv_`var'_`level'
			estimates store fs`contador'

		}
		
	  *** Tables
      #delimit;
      estout m1 m2 m3 m4
      using "OLS. Academic Performance (`level').tex",
      cells(b(star fmt(%9.4f)) se(par fmt(%9.4f)))
      stats(N ymean, fmt(0 2) labels("Observations"))
      mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01)
      indicate("Older sibling application score = *score_rd");
      #delimit cr

      #delimit;
      estout iv1 iv2 iv3 iv4
      using "IV. Academic Performance.tex",
      cells(b(star fmt(%9.4f)) se(par fmt(%9.4f)))
      stats(N fstage ymean, fmt(0 2 2) labels("Observations"))
      mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
      #delimit cr

	    #delimit;
      estout fs1 fs2 fs3 fs4
      using "FS. Academic Performance.tex",
      cells(b(star fmt(%9.4f)) se(par fmt(%9.4f)))
      stats(N fstage ymean, fmt(0 2 2) labels("Observations"))
      mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
      #delimit cr
	}
