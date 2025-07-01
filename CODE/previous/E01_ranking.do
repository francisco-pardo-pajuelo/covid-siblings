
*---------------------------*
*-----	Rank order within class
*---------------------------*
use "$TEMP\students", clear


label var male_2p "Male"
label var male_4p "Male"
label var male_2s "Male"


VarStandardiz std_m_2p, by(SC_2p) newvar(std_m_2p_SC_std)
VarStandardiz std_m_4p, by(SC_4p) newvar(std_m_4p_SC_std)
VarStandardiz std_m_2s, by(SC_2s) newvar(std_m_2s_SC_std)
VarStandardiz std_m_2p, by(SSC_2p) newvar(std_m_2p_SSC_std)
VarStandardiz std_m_4p, by(SSC_4p) newvar(std_m_4p_SSC_std)
VarStandardiz std_m_2s, by(SSC_2s) newvar(std_m_2s_SSC_std)

VarStandardiz std_c_2p, by(SC_2p) newvar(std_c_2p_SC_std)
VarStandardiz std_c_4p, by(SC_4p) newvar(std_c_4p_SC_std)
VarStandardiz std_c_2s, by(SC_2s) newvar(std_c_2s_SC_std)
VarStandardiz std_c_2p, by(SSC_2p) newvar(std_c_2p_SSC_std)
VarStandardiz std_c_4p, by(SSC_4p) newvar(std_c_4p_SSC_std)
VarStandardiz std_c_2s, by(SSC_2s) newvar(std_c_2s_SSC_std)


gen u = runiform()
//keep if u <0.1
*--------------------
*- Should do before



*--------------------
*- Statistics from Table 1 (Murphy)
*--------------------



*--------------------
*- Ranking vs Test scores
*--------------------
scatter rank_sc_m_2p pct_m_2p_SC_dev, ///
xtitle("De meaned age 7 test score") ///
ytitle("Age 7 ranking") ///
mcolor(gs0) ///
ysize(6) ///
xsize(8) ///
name(rank_vs_score_2p, replace)
graph export 			"$FIG/ranking_vs_score_2p.png", replace

scatter rank_sc_m_4p pct_m_4p_SC_dev, ///
xtitle("De meaned age 9 test score") ///
ytitle("Age 9 ranking") ///
mcolor(gs0) ///
ysize(6) ///
xsize(8) ///
name(rank_vs_score_4p, replace)

scatter rank_sc_m_2s pct_m_2s_SC_dev, ///
xtitle("De meaned age 13 test score") ///
ytitle("Age 13 ranking") ///
mcolor(gs0) ///
ysize(6) ///
xsize(8) ///
name(rank_vs_score_2s, replace)

graph combine  	rank_vs_score_2p ///
				/// rank_vs_score_4p ///
				rank_vs_score_2s, ///
				col(2) ///
				ysize(8) ///
				xsize(18)
graph export 			"$FIG/ranking_vs_score.png", replace

*--------------------
*- Main regression
*--------------------
*- Focus on those with all exams
keep if std_m_2p!=. & std_c_2p!=. & std_t_2p!=.
keep if pct_m_2p!=. & pct_c_2p!=. & pct_t_2p!=.

*--- Control variables
	*- Cubic of STD 2nd grade scores
	forvalues p=1/5 {
		gen std_t_2p_p`p' = std_t_2p^`p'
		gen std_m_2p_p`p' = std_m_2p^`p'
		gen std_c_2p_p`p' = std_c_2p^`p'
		
		gen pct_t_2p_p`p' = pct_t_2p^`p'
		gen pct_m_2p_p`p' = pct_m_2p^`p'
		gen pct_c_2p_p`p' = pct_c_2p^`p'		
	}

*--------------------
*----- Regressions
*--------------------

//edu_mother_2p lengua_materna_mother_2p

//Control for standardized score at the SSC level and see if that reduces rank effect?
//std_m_2p_SSC_std

*- Effect on 4th and 8th grade test scores
gen power3 = 1
gen power5 = 1
gen sc_fe = 1
gen ssc_fe = 1

global power3_m 		= "pct_m_2p_p1 pct_m_2p_p2 pct_m_2p_p3"
global power3_c 		= "pct_c_2p_p1 pct_c_2p_p2 pct_c_2p_p3"
global power5_m 		= "pct_m_2p_p1 pct_m_2p_p2 pct_m_2p_p3 pct_m_2p_p4 pct_m_2p_p5"
global power5_c 		= "pct_c_2p_p1 pct_c_2p_p2 pct_c_2p_p3 pct_c_2p_p4 pct_c_2p_p5"

eststo t_4p_sc_a: reghdfe pct_m_4p rank_sc_m_2p 	 $power3_m  		power3 sc_fe	, a(SC_2p) vce(robust)
eststo t_4p_sc_b: reghdfe pct_m_4p rank_sc_m_2p 	 $power3_m male_2p	power3 sc_fe 	, a(SC_2p) vce(robust)
eststo t_4p_sc_c: reghdfe pct_m_4p rank_sc_m_2p 	 $power5_m male_2p	power5 sc_fe 	, a(SC_2p) vce(robust)
eststo t_2s_sc_a: reghdfe pct_m_2s rank_sc_m_2p 	 $power3_m 			power3 sc_fe	, a(SC_2p) vce(robust)
eststo t_2s_sc_b: reghdfe pct_m_2s rank_sc_m_2p 	 $power3_m male_2p	power3 sc_fe 	, a(SC_2p) vce(robust)
eststo t_2s_sc_c: reghdfe pct_m_2s rank_sc_m_2p 	 $power5_m male_2p	power5 sc_fe 	, a(SC_2p) vce(robust)

eststo t_4p_ssc_a: reghdfe pct_m_4p rank_ssc_m_2p 	 $power3_m  		power3 ssc_fe	, a(SSC_2p) vce(robust)
eststo t_4p_ssc_b: reghdfe pct_m_4p rank_ssc_m_2p 	 $power3_m male_2p	power3 ssc_fe 	, a(SSC_2p) vce(robust)
eststo t_4p_ssc_c: reghdfe pct_m_4p rank_ssc_m_2p 	 $power5_m male_2p	power5 ssc_fe 	, a(SSC_2p) vce(robust)
eststo t_2s_ssc_a: reghdfe pct_m_2s rank_ssc_m_2p 	 $power3_m 			power3 ssc_fe	, a(SSC_2p) vce(robust)
eststo t_2s_ssc_b: reghdfe pct_m_2s rank_ssc_m_2p 	 $power3_m male_2p	power3 ssc_fe 	, a(SSC_2p) vce(robust)
eststo t_2s_ssc_c: reghdfe pct_m_2s rank_ssc_m_2p 	 $power5_m male_2p	power5 ssc_fe 	, a(SSC_2p) vce(robust)

capture erase "$TABLES\tests_ranking.csv"		
/*								
esttab t_4p_a using "$TABLES\tests_ranking.csv", ///
									keep(rank_m _cons) ///
									b(%9.2f) ///
									se(%9.2f) ///
									star(* 0.1 ** 0.05 *** 0.01) ///
									stardrop(_cons) ///
									replace
*/

esttab t_4p_sc_a t_4p_sc_b /*t_4p_sc_c*/ t_2s_sc_a t_2s_sc_b /*t_2s_sc_c*/ t_4p_ssc_a t_4p_ssc_b /*t_4p_ssc_c*/ t_2s_ssc_a t_2s_ssc_b  /*t_2s_ssc_c*/
esttab t_4p_sc_a t_4p_sc_b /*t_4p_sc_c*/ t_2s_sc_a t_2s_sc_b /*t_2s_sc_c*/ /*t_4p_ssc_a t_4p_ssc_b /*t_4p_ssc_c*/ t_2s_ssc_a t_2s_ssc_b*/  /*t_2s_ssc_c*/  using "$TABLES\tests_ranking.tex" ///
									, ///
									label replace booktabs ///
									mgroups("4th grade" "8th grade", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
									///mtitles("4th grade test") ///
									nomtitles ///
									keep(rank_sc_m_2p /*rank_ssc_m_2p*/  male_2p) /// 
									order(rank_sc_m_2p /*rank_ssc_m_2p*/ male_2p) ///
									b(%9.3f) ///
									se(%9.3f) ///
									stats(N,fmt("%9.0fc")) ///
									star(* 0.1 ** 0.05 *** 0.01) ///
									nonotes ///
									indicate("Cubic in grade 2 test scores = power3" /*"5th degree in grade 2 test scores = power5"*/ "School-Subject-Cohort= sc_fe"  /*"School-Subject-Cohort-Class= ssc_fe"*/) ///
									alignment(D{c}{c}{-1}) width(\hsize)  ///
									title(Effects of ranking on academic performance \label{tab:table_main_results}) ///
									substitute({l} {p{\linewidth}}) 
									//addnotes("")		
		
preserve	
	replace aspiration_2p_HE=aspiration_2p_HE*100
	replace aspiration_4p_HE=aspiration_4p_HE*100
	replace aspiration_2s_HE=aspiration_2s_HE*100		
	eststo asp_2p_sc_b: reghdfe aspiration_2p_HE rank_sc_m_2p 	 $power3_m male_2p	power3 sc_fe 	, a(SC_2p) vce(robust)
	eststo asp_4p_sc_b: reghdfe aspiration_4p_HE rank_sc_m_2p 	 $power3_m male_2p	power3 sc_fe 	, a(SC_2p) vce(robust)
	eststo asp_2s_sc_b: reghdfe aspiration_2s_HE rank_sc_m_2p 	 $power3_m male_2p	power3 sc_fe 	, a(SC_2p) vce(robust)

	
	eststo asp_2p_ssc_b: reghdfe aspiration_2p_HE rank_ssc_m_2p 	 $power3_m male_2p	power3 ssc_fe 	, a(SSC_2p) vce(robust)
	eststo asp_4p_ssc_b: reghdfe aspiration_4p_HE rank_ssc_m_2p 	 $power3_m male_2p	power3 ssc_fe 	, a(SSC_2p) vce(robust)
	eststo asp_2s_ssc_b: reghdfe aspiration_2s_HE rank_ssc_m_2p 	 $power3_m male_2p	power3 ssc_fe 	, a(SSC_2p) vce(robust)

restore
		
esttab asp_2p_sc_b asp_4p_sc_b asp_2s_sc_b asp_2p_ssc_b asp_4p_ssc_b asp_2s_ssc_b
esttab asp_2p_sc_b asp_4p_sc_b asp_2s_sc_b /*asp_2p_ssc_b asp_4p_ssc_b asp_2s_ssc_b*/  using "$TABLES\aspiration_ranking.tex" ///
									, ///
									label replace booktabs ///
									mgroups("2nd grade" "4th grade" "8th grade" , pattern(1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
									///mtitles("4th grade test") ///
									nomtitles ///
									keep(rank_sc_m_2p /*rank_ssc_m_2p*/  male_2p) /// 
									order(rank_sc_m_2p /*rank_ssc_m_2p*/ male_2p) ///
									b(%9.3f) ///
									se(%9.3f) ///
									stats(N,fmt("%9.0fc")) ///
									star(* 0.1 ** 0.05 *** 0.01) ///
									nonotes ///
									indicate("Cubic in grade 2 test scores = power3" /*"5th degree in grade 2 test scores = power5"*/ "School-Subject-Cohort= sc_fe"  /*"School-Subject-Cohort-Class= ssc_fe"*/) ///
									alignment(D{c}{c}{-1}) width(\hsize)  ///
									title(Effects of ranking on Higher Ed aspirations \label{tab:table_main_results}) ///
									substitute({l} {p{\linewidth}}) 
									//addnotes("")			
		
bys SC_2p	: gen N_SC_2p=_N if _n==1
bys SSC_2p	: gen N_SSC_2p=_N if _n==1

sum N_SC_2p, de
sum N_SSC_2p, de

*- Effect on aspirations
eststo asp_2p_a: reghdfe aspiration_2p_HE rank_sc_m_2p 	pct_m_2p_p? cubic_2p  													, a(SC_2p) vce(robust)
eststo asp_2p_b: reghdfe aspiration_2p_HE rank_sc_m_2p 	pct_m_2p_p? cubic_2p male_2p 											, a(SC_2p) vce(robust)
eststo asp_2p_b: reghdfe aspiration_2p_HE rank_ssc_m_2p pct_m_2p_p? cubic_2p male_2p 											, a(SSC_2p) vce(robust)
eststo asp_2p_b: reghdfe aspiration_2p_HE rank_ssc_m_2p pct_m_2p_p? cubic_2p male_2p  if inlist(year_2p,2016)==1				, a(SSC_2p) vce(robust)
gen sample_2p_4p = e(sample)
//eststo asp_2p_b: reghdfe aspiration_2p_HE rank_ssc_m_2p pct_m_2p_p? cubic_2p male_2p  if inlist(year_2p,2009,2010,2012,2013)==1	, a(SSC_2p) vce(robust)
eststo asp_4p_a: reghdfe aspiration_4p_HE rank_sc_m_2p 	pct_m_2p_p? cubic_2p 													, a(SC_2p) vce(robust)
eststo asp_4p_b: reghdfe aspiration_4p_HE rank_sc_m_2p 	pct_m_2p_p? cubic_2p male_2p 											, a(SC_2p) vce(robust)
eststo asp_4p_b: reghdfe aspiration_4p_HE rank_ssc_m_2p pct_m_2p_p? cubic_2p male_2p 											, a(SSC_2p) vce(robust)
eststo asp_4p_b: reghdfe aspiration_4p_HE rank_ssc_m_2p pct_m_2p_p? cubic_2p male_2p if sample_2p_4p==1							, a(SSC_2p) vce(robust)
eststo asp_4p_b: reghdfe aspiration_4p_HE rank_ssc_m_2p pct_m_2p_p? cubic_2p male_2p if sample_2p_4p==1							, a(SSC_2p) vce(robust)
eststo asp_2s_a: reghdfe aspiration_2s_HE rank_sc_m_2p 	pct_m_2p_p? cubic_2p 													, a(SC_2p) vce(robust)
eststo asp_2s_b: reghdfe aspiration_2s_HE rank_sc_m_2p 	pct_m_2p_p? cubic_2p male_2p 											, a(SC_2p) vce(robust)
eststo asp_2s_b: reghdfe aspiration_2s_HE rank_ssc_m_2p pct_m_2p_p? cubic_2p male_2p 											, a(SSC_2p) vce(robust)

esttab asp_2p_a asp_2p_b asp_4p_a asp_4p_b asp_2s_a asp_2s_b
esttab asp_2p_a asp_2p_b asp_4p_a asp_4p_b asp_2s_a asp_2s_b using "$TABLES\aspirations_ranking.tex" ///
									, ///
									label replace booktabs ///
									mgroups("2nd grade" "4th grade" "8th grade", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
									///mtitles("4th grade test") ///
									nomtitles ///
									keep(rank_sc_m_2p male_2p) /// 
									order(rank_sc_m_2p  male_2p) ///
									b(%9.3f) ///
									se(%9.3f) ///
									stats(N,fmt("%9.0fc")) ///
									star(* 0.1 ** 0.05 *** 0.01) ///
									nonotes ///
									indicate("Cubic in grade 2 test scores = cubic_2p") ///
									alignment(D{c}{c}{-1}) width(\hsize)  ///
									title(Main Results \label{tab:table_main_results}) ///
									substitute({l} {p{\linewidth}}) 
									//addnotes("")		
									


*- Effect on 2nd grade aspirations
//




bys SC_2p: egen mean = mean(pct_m_2p)
gen dev_pct_m_2p = pct_m_2p - mean
twoway (scatter rank_sc_m_2p dev_pct_m_2p if u<0.05), ///
	xtitle("De-meaned 2nd grade score") ///
	ytitle("Percentile rank within class")  ///
	xlabel(-3(1)3) ///
	ylabel(0(0.1)1, angle(0))	///
	xline(0, lcolor(black) lpattern(dot)) legend(off) 
	
if $PNG == 1	graph export 			"$FIG/ranking_vs_score.png", replace
if $PDF == 1 	capture graph export 	"$FIG/ranking_vs_score.pdf", replace

/*
graph combine direct2_`outcome' indirect2_`outcome', ///
xsize(13) ///
ysize(6) ///
name(`outcome'_2, replace)
*/



capture erase "$TEMP\erase_students.dta"