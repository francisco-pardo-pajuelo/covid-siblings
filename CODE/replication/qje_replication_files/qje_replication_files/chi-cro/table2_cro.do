*** Table II: Summary statistics:
bys mrun year: gen id = _n

#delimit;
global outcomes female age fg
academic_track takes_sat hs_gpa avg_sat;
#delimit cr

estpost sum $outcomes if id == 1
estimate store A

#delimit;
esttab A using "summary_statistics_croatia.tex", replace
mtitle("Croatia")
cells(mean(fmt(%04.3f)) sd(fmt(%04.3f)) count(fmt(%09.3g))) label booktabs nonum collabels(none) gaps f noobs;
#delimit cr;
