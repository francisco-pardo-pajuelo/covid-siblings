preserve

*** Table VII: Sibling Spillovers on Applications to College and College-Major by
*** Age Difference and Gender

capture rm age_gender_swe.dta
capture rm age_gender_swe.sters
estimates clear

foreach type in inst instprog {
	foreach sib_app in all enrolls {

		local y 			= "same_`type'_`sib_app'"
		local bw 			= ${bw_same_`type'_1}
		local est_settings 	= "bw(`bw') p(1) nofirst estsave(age_gender_swe)"

		if "`type'" == "instprog" local if = "jk_different_instprog == 1"
		if "`type'" == "inst" local if = "jk_different_insts == 1"

		// Same Gender (all)
		est_reghdfe `y' 1.same_gender 1.same_gender#1.above_cutoff if `if', ///
			m(ols_`type'_`sib_app'_g) `est_settings'
		est_reghdfe `y' 1.same_gender if `if', ///
			iv(1.enrolled 1.enrolled#1.same_gender = 1.above_cutoff 1.above_cutoff#1.same_gender) ///
			m(iv_`type'_`sib_app'_g) `est_settings'

		// Age difference (5 years)
		est_reghdfe `y' 1.age_diff_5yrs 1.age_diff_5yrs#1.above_cutoff if `if', ///
			m(ols_`type'_`sib_app'_a) `est_settings'
		est_reghdfe `y' 1.age_diff_5yrs if `if', ///
			iv(1.enrolled 1.enrolled#1.age_diff_5yrs = 1.above_cutoff 1.above_cutoff#1.age_diff_5yrs) ///
			m(iv_`type'_`sib_app'_a) `est_settings'
    }
}

// Table output
estread using age_gender_swe

#delimit;
estout ols_*
using "ols_closeness_p1.tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean" ))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01)
indicate("Running variable polynomial =*cutoff_distance*");
#delimit cr

#delimit;
estout iv_*
using "iv_closeness_p1.tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean" ))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01)
indicate("Running variable polynomial =*cutoff_distance*");
#delimit cr

restore
exit 0
