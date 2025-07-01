*** Table III: Sibling Spillovers on Applications to and Enrollment in Older
*** Sibling’s Target Choice
label variable apply1st_colmaj 	"Applies to the same college-major (1st preference)"
label variable apply_colmaj  	  "Applies to the same college-major (any preference)"
label variable enroll_colma 	  "Enrolls in the same college-major"

label variable apply1st_college "Applies to the same college (1st preference)"
label variable apply_college   	"Applies to the same college (Any preference)"
label variable enroll_college 	"Enrolls in the same college"

label variable apply1st_major 	"Applies to the same major (1st preference)"
label variable apply_major   	  "Applies to the same major(Any preference)"
label variable enroll_major 	  "Enrolls in the same major"

*** I. Estimation:

*** 1.1 Bandwidth choice:
foreach level in "colmaj" "college" "major" {
  foreach choice in  "apply1st" "apply" "enroll" {

      if "`level'" == "colmajor" local if "wl_students > 0 & oldest == 1"
      if "`level'" == "college"  local if "wl_students > 0 & oldest == 1 & college_sample == 1"
      if "`level'" == "major" 	 local if "wl_students > 0 & oldest == 1 & major_sample == 1"

      #delimit;
      rdrobust `choice'_`level' score_rd if `if',
      c(0) p(1) q(2) kernel(triangular) bwselect(mserd) vce(cluster family_id)
      all fuzzy(enrolls_old) covs(yr_2 yr_3 yr_4);
      #delimit cr

      local bw_`choice' = e(h_l)
    }

    *** bw_colmaj : 80
    *** bw_college: 80
    *** bw_major  : 80
    local bw_`level' = round(min(`bw_apply1st', `bw_apply', `bw_enroll'), 0.5)
}

*** 1.2 Coefficients estimation:
local contador = 0
local covs c.score_rd c.score_rdc

foreach level in "colmaj" "college" "major" {
	foreach choice in  "apply1st" "apply" "enroll" {

    if "`level'" == "colmajor" local if "wl_students > 0 & oldest == 1 "
    if "`level'" == "college"  local if "wl_students > 0 & oldest == 1 & college_sample == 1"
    if "`level'" == "major" 	 local if "wl_students > 0 & oldest == 1 & major_sample == 1"

		local vtext1: variable label `choice'_`level'
		local contador = `contador' + 1

		*** Reduced form:
		#delimit;
		reghdfe `choice'_`level' above_cutoff  `covs' if `if'
		& score_rd >= -1*`bw_`level'' & score_rd <= `bw_`level'',
		absorb(i.year i.mcfe) cluster(family_id);
		#delimit cr
		estadd ysumm
		estimates store m`contador'

    *** 2SLS and first stage:
		#delimit;
		ivreghdfe `choice'_`level' `covs' (enrolls_old = above_cutoff) if `if'
		& score_rd >= -1*`bw_`level'' & score_rd <= `bw_`level'',
		absorb(i.year i.mcfe) cluster(family_id) first ffirst savefirst savefprefix(fs_);
		#delimit cr
		estadd ysumm
		estadd scalar fstage = e(widstat)
		estimates store iv`contador'

		estimates restore fs_iv_`choice'_`level'_P`x'
		estimates store fs`contador'
	}
}

*** 1.3 Tables
*** 1.3.1 College-Major
#delimit;
estout m1 m2 m3
using "OLS. Siblings - Main Effects (College-Major).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N ymean, fmt(0 2) labels("Observations"))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

#delimit;
estout fs1 fs2 fs3
using "FS. Siblings - Main Effects (College-Major).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N fstage ymean, fmt(0 2 2) labels("Observations"))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

#delimit;
estout iv1 iv2 iv3
using "IV. Siblings - Main Effects (College-Major).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N fstage ymean, fmt(0 2 2) labels("Observationss"))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

*** 1.3.2 College
#delimit;
estout m4 m5 m6
using "OLS. Siblings - Main Effects (College).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N ymean, fmt(0 2) labels("Observations"))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

#delimit;
estout fs4 fs5 fs6
using "FS. Siblings - Main Effects (College).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N fstage ymean, fmt(0 2 2) labels("Observations"))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

#delimit;
estout iv4 iv5 iv6
using "IV. Siblings - Main Effects (College).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N fstage ymean, fmt(0 2 2) labels("Observations"))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

*** 1.3.3 Major
#delimit;
estout m7 m8 m9
using "OLS. Siblings - Main Effects (Major).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N ymean, fmt(0 2) labels("Observations"))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

#delimit;
estout fs7 fs8 fs9
using "FS. Siblings - Main Effects (Major).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N fstage ymean, fmt(0 2 2) labels("Observations"))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

#delimit;
estout iv7 iv8 iv9
using "IV. Siblings - Main Effects (Major).tex",
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
stats(N fstage ymean, fmt(0 2 2) labels("Observations"))
mlabels() collabels(none) note(" ") style(tex) replace label starlevels(* 0.10 ** 0.05 *** 0.01);
#delimit cr

estimates drop _all
