preserve

*** Table VIII: Sibling Spillovers on College and College-Major Choice by Older
*** Sibling’s Dropout

capture rm dropout_swe.dta
capture rm dropout_swe.sters
estimates clear

foreach type in inst instprog {
	foreach sib_app in all enrolls {

		local y 			= "same_`type'_`sib_app'"
		local bw 			= ${bw_same_`type'_1}
		local est_settings 	= "bw(`bw') p(1) estsave(dropout_swe)"

		if "`type'" == "instprog" local if = "jk_different_instprog == 1"
		if "`type'" == "inst" local if = "jk_different_insts == 1"

		// Dropout (2 year diff) Table 8
		est_reghdfe `y' 1.dropout_any 1.dropout_any#1.above_cutoff if `if' & age_difference >= 2, ///
			m(ols_`type'_`sib_app'_d) `est_settings'
		est_reghdfe `y' 1.dropout_any if `if' & age_difference >= 2, ///
			iv(1.enrolled 1.enrolled#1.dropout_any = 1.above_cutoff 1.above_cutoff#1.dropout_any) ///
			m(iv_`type'_`sib_app'_d) `est_settings'

    }
}

// Table output
estread using dropout_swe

#delimit;
estout ols_*
using "ols_dropout_p1.tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean" ))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01)
indicate("Running variable polynomial =*cutoff_distance*");
#delimit cr

#delimit;
estout iv_*
using "iv_dropout_p1.tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean" ))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01)
indicate("Running variable polynomial =*cutoff_distance*");
#delimit cr

restore
exit 0
