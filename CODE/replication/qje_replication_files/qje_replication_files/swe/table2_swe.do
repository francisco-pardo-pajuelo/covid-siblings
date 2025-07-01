preserve

generate swesat_w = !missing(gpa_swesat)

*** Table II: Summary statistics:
bys id id_round: gen id_count = _n

#delimit;
global outcomes female age n_in_household
par_dispinc_q12 par_dispinc_q34 par_dispinc_q5 par_edu_tert
swesat_w gpa_hs gpa_swesat;
#delimit cr

estpost sum $outcomes if id_count == 1
estimate store A

keep if sample_main & abs(cutoff_distance) <= $bw_same_instprog_1
estpost sum $outcomes if id_count == 1
estimate store B

#delimit;
esttab B A using "summary_statistics_swe.tex", replace
mtitle("Sweden - Sample" "Sweden - All")
cells(mean(fmt(%04.3f)) sd(fmt(%04.3f)) count(fmt(%09.3g))) label booktabs nonum collabels(none) gaps f noobs;
#delimit cr;

restore
exit 0
