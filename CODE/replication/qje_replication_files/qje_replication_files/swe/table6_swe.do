preserve

*** Table VI: Sibling Spillovers on Younger Siblings’ Application by Older Siblings’
*** Target Option Characteristics

capture rm choice_heterogeneity_swe.dta
capture rm choice_heterogeneity_swe.sters
estimates clear

foreach char in earnings_degrees mean_gpa_enrolled retention_enrolled {
    xtile `char'_p4 = `char' if abs(cutoff_distance) <= ${bw_same_instprog_1}, nquantiles(4)
}

foreach type in instprog inst {
	foreach sib_app in all enrolls {
		local y 			= "same_`type'_`sib_app'"
		local bw 			= ${bw_same_`type'_1}
		local est_settings 	= "bw(`bw') p(1) nofirst estsave(choice_heterogeneity_swe)"

		if "`type'" == "instprog" local if = "jk_different_instprog == 1"
		if "`type'" == "inst" local if = "jk_different_insts == 1"

		// earnings
		est_reghdfe `y' if `if', ///
			iv(1.enrolled#i.earnings_degrees_p4 = 1.above_cutoff#i.earnings_degrees_p4) ///
			fe(i.birthyear_sib i.id_cutoff i.id_cutoff_k) ///
			`est_settings' m("`type'_`sib_app'_1")

		// peer quality
		est_reghdfe `y' if `if', ///
			iv(1.enrolled#i.mean_gpa_enrolled_p4 = 1.above_cutoff#i.mean_gpa_enrolled_p4) ///
			fe(i.birthyear_sib i.id_cutoff i.id_cutoff_k) ///
			`est_settings' m("`type'_`sib_app'_2")

		// retention
		est_reghdfe `y' if `if', ///
			iv(1.enrolled#i.retention_enrolled_p4 = 1.above_cutoff#i.retention_enrolled_p4) ///
			fe(i.birthyear_sib i.id_cutoff i.id_cutoff_k) ///
			`est_settings' m("`type'_`sib_app'_3")
	}
}

// Table output
estread using choice_heterogeneity_swe

#delimit;
estout *
using "2SLS. Siblings Heterogeneous Effects by Target Program Chars.tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean" ))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01)
indicate("Running variable polynomial =*cutoff_distance*");
#delimit cr

restore
exit 0
