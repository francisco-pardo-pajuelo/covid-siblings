*** Table VIII: Sibling Spillovers on College and College-Major Choice by Older
*** Sibling’s Dropout

local bw_colmaj   = 18.00
local bw_college	= 12.50
local covs c.score_rd c.score_rdc

foreach level in "colmaj" "college" {
		foreach choice in "apply" "enroll" {

			if "`level'" == "colmaj" 	local if = "wl_students > 0 & oldest == 1 & yob - yob_old > 1"
			if "`level'" == "college" local if = "wl_students > 0 & oldest == 1 & yob - yob_old > 1 & college_sample == 1"

			foreach var2 of varlist dropout_1st  {

				local vtext1: variable label `var2'

					gen interaction_1 = above_cutoff*`var2'
					gen aux_1 = `var2'
					gen enrolls_interaction_1 = enrolls_old*`var2'

					#delimit;
					reghdfe `choice'_`level' 1.above_cutoff interaction_*  `covs' if `if'
					& score_rd >= -1*`bw_`level'' & score_rd <= `bw_`level'',
					absorb(i.mcfe i.year) cluster(family_id);
					#delimit cr
					estadd ysumm
					estimates store ols_`choice'_`level'

					#delimit;
					ivreghdfe `choice'_`level' `covs' (enrolls_old enrolls_interaction_* = above_cutoff interaction_*) if `if'
					& score_rd >= -1*`bw_`level'' & score_rd <= `bw_`level'',
					absorb(i.mcfe i.year) cluster(family_id);
					#delimit cr
					estadd ysumm
					estadd scalar fstage = e(widstat)
					estimates store iv_`choice'_`level'

					drop aux_* interaction_* enrolls_interaction_*
			}
	}

  *** Save results
  #delimit;
  estout ols_*
  using "ols_`level'_dropout_p1.tex",
  cells(b(star fmt(%9.5f)) se(par fmt(%9.5f)))
  stats(N ymean, fmt(0 2) labels(Observations"))
  mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
  #delimit cr

  #delimit;
  estout iv_*
  using "iv_`level'_dropout_p1.tex",
  cells(b(star fmt(%9.5f)) se(par fmt(%9.5f)))
  stats(N fstage ymean, fmt(0 2 2) labels("Observations"))
  mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
  #delimit cr

  estimates drop _all
}
