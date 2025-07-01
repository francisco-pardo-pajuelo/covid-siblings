*** Table II: Summary statistics:
bys mrun year: gen id = _n

#delimit;
global outcomes female age fg
high_income mid_income low_income pe_5
academic_track takes_sat hs_gpa avg_sat;
#delimit cr

estpost sum $outcomes if id == 1
estimate store A

#delimit;
esttab A using "summary_statistics_chile.tex", replace
mtitle("Chile")
cells(mean(fmt(%04.3f)) sd(fmt(%04.3f)) count(fmt(%09.3g))) label booktabs nonum collabels(none) gaps f noobs;
#delimit cr;
