preserve

*** Table IX: Sibling Spillovers on Academic Performance

capture rm younger_sib_perf_swe.dta
capture rm younger_sib_perf_swe.sters
estimates clear

foreach type in instprog {
	foreach y in gpa_hs_sib gpa_swesat_sib swesat_w_sib sib_applies {
		local bw 			= ${bw_same_`type'_1}
		local est_settings 	= "bw(`bw') p(1) estsave(younger_sib_perf_swe)"
		local if 			= "jk_different_instprog == 1"

		est_reghdfe `y' if `if', ///
			`est_settings' m("ols_`y'")
		est_reghdfe `y' if `if', iv(1.enrolled=1.above_cutoff) ///
			`est_settings' m("iv_`y'")
	}
}

// Table output
estread using younger_sib_perf_swe

#delimit;
estout ols_*
using "OLS. Academic Performance.tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean" ))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01)
indicate("Running variable polynomial =*cutoff_distance*");
#delimit cr

#delimit;
estout iv_*
using "IV. Academic Performance.tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean" ))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01)
indicate("Running variable polynomial =*cutoff_distance*");
#delimit cr

#delimit;
estout iv_*
using "FS. Academic Performance.tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean" ))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01)
indicate("Running variable polynomial =*cutoff_distance*");
#delimit cr

restore
exit 0
