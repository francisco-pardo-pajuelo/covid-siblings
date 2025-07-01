preserve

*** Table III: Sibling Spillovers on Applications to and Enrollment in Older
*** Sibling’s Target Choice

// Regression results saved to file
capture rm main_swe.dta
capture rm main_swe.sters
estimates clear

foreach type in inst prog instprog {
	foreach sib_app in first all enrolls {
		estimates clear

		local y 	= "same_`type'_`sib_app'"
		if "`type'" == "instprog" local if = "jk_different_instprog == 1"
		if "`type'" == "inst" local if = "jk_different_insts == 1"
		if "`type'" == "prog" local if = "jk_different_progs == 1"

		local p 	= 1
		local bw 	= ${bw_same_`type'_`p'}

		// Reduced Form
		est_reghdfe `y' if `if', ///
			p(`p') bw(`bw') ///
			estsave("main_swe") m("ols_`type'_`sib_app'_`p'")

		// 2SLS
		est_reghdfe `y' if `if', iv(1.enrolled=1.above_cutoff) ///
			p(`p') bw(`bw') ///
			estsave("main_swe") m("iv_`type'_`sib_app'_`p'")
	}
}

*** 1.3 Tables
estread using main_swe

*** 1.3.1 College-Major
#delimit;
estout ols_instprog_first_1 ols_instprog_all_1 ols_instprog_enrolls_1
using "OLS. Siblings - Main Effects (College-Major).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N yctrl, fmt(0 2) labels("Observations" "Counterfactual mean"))
indicate("Running variable polynomial =*cutoff_distance*")
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

#delimit;
estout fs_iv_instprog_first_1 fs_iv_instprog_all_1 fs_iv_instprog_enrolls_1
using "FS. Siblings - Main Effects (College-Major).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean"))
indicate("Running variable polynomial =*cutoff_distance*")
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

#delimit;
estout iv_instprog_first_1 iv_instprog_all_1 iv_instprog_enrolls_1
using "IV. Siblings - Main Effects (College-Major).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean"))
indicate("Running variable polynomial =*cutoff_distance*")
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

*** 1.3.2 College
#delimit;
estout ols_inst_first_1 ols_inst_all_1 ols_inst_enrolls_1
using "OLS. Siblings - Main Effects (College).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N yctrl, fmt(0 2) labels("Observations" "Counterfactual mean"))
indicate("Running variable polynomial =*cutoff_distance*")
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

#delimit;
estout fs_iv_inst_first_1 fs_iv_inst_all_1 fs_iv_inst_enrolls_1
using "FS. Siblings - Main Effects (College).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean"))
indicate("Running variable polynomial =*cutoff_distance*")
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

#delimit;
estout iv_inst_first_1 iv_inst_all_1 iv_inst_enrolls_1
using "IV. Siblings - Main Effects (College).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean"))
indicate("Running variable polynomial =*cutoff_distance*")
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

*** 1.3.3 Major
#delimit;
estout ols_prog_first_1 ols_prog_all_1 ols_prog_enrolls_1
using "OLS. Siblings - Main Effects (Major).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N yctrl, fmt(0 2) labels("Observations" "Counterfactual mean"))
indicate("Running variable polynomial =*cutoff_distance*")
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

#delimit;
estout fs_iv_prog_first_1 fs_iv_prog_all_1 fs_iv_prog_enrolls_1
using "FS. Siblings - Main Effects (Major).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean"))
indicate("Running variable polynomial =*cutoff_distance*")
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

#delimit;
estout iv_prog_first_1 iv_prog_all_1 iv_prog_enrolls_1
using "IV. Siblings - Main Effects (Major).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N widstat yctrl, fmt(0 2 2) labels("Observations" "Kleibergen-Paap F statistic" "Counterfactual mean"))
indicate("Running variable polynomial =*cutoff_distance*")
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

restore
exit 0
