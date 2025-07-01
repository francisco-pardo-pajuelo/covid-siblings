*- Testing results

/*
1. 					Application rates
2. (USED) 			Correlation between takes 
3. 					Counterfactuals. Who quits and who keeps trying? Who goes private?
4. (DISCARDED)?		Timing of application and expectations 
5. 					How correlated are obs across years
6. (USED) 			Peers spillovers 
7. (USED)			Correlation between sibling exams
8. 					High achievers

*/

global fam_type = 2

***********************************
*-1. Looking at application rates
***********************************
*-- Rate of application by school
use "$OUT\students", clear


replace applied = . if !((exp_graduating_year1+1>=2017 & exp_graduating_year1+1<=2023))

*- Application ratio per region
preserve
	collapse applied, by(region_siagie)
	sort applied
	list
restore


*- Application ration per school-year
preserve
	keep if applied!=.
	gen pop = 1
	collapse applied (sum) pop applicants = applied, by(id_ie_sec exp_graduating_year1)
	sort id_ie_sec exp_graduating_year1
restore

***********************************
*- 2. Correlation between exam takes
***********************************
use "$TEMP\applied", clear

*-- Correlation between exam takes of same individual-uni
drop if id_per_umc==""
drop if score_std_major==.
keep id_per_umc score_std_major semester codigo_modular major_c1_code public

/*
duplicates tag id_per_umc id_cutoff_major score_std_major semester, gen(dup)
duplicates tag id_per_umc id_cutoff_major  semester, gen(dup2)
*/

preserve
	keep if public==1
	bys id_per_umc codigo_modular major_c1_code (semester) : gen n=_n
	bys id_per_umc codigo_modular major_c1_code (semester) : gen N=_N

	drop if N==1
	keep score_std_major semester id_per_umc codigo_modular major_c1_code n
	reshape wide score_std_major semester, i(id_per_umc codigo_modular major_c1_code) j(n)


	*- Takes are highly correlated, more if closer in time.
	pwcorr score_std_major1-score_std_major4 if score_std_major4!=.

	*- The distribution shifts to the right
	twoway 	(kdensity score_std_major1 if abs(score_std_major1)<3) ///
			(kdensity score_std_major2 if abs(score_std_major2)<3) ///
			(kdensity score_std_major3 if abs(score_std_major3)<3) ///
			(kdensity score_std_major4 if abs(score_std_major4)<3), ///
			xtitle("Standardized Score") /// 
			ytitle("Density") ///
			legend(label(1 "1st take") label(2 "2nd take") label(3 "3rd take") label(4 "4th take") pos(6) col(4)) 
	graph export 	"$FIGURES/eps/exam_takes.eps", replace	
	graph export 	"$FIGURES/png/exam_takes.png", replace	
	graph export 	"$FIGURES/pdf/exam_takes.pdf", replace				
			
restore

//between universities
* Lower correlation ~0.2
preserve
	bys id_per_umc codigo_modular: egen score = mean(score_std_major)
	bys id_per_umc codigo_modular: keep if _n==1
	keep id_per_umc codigo_modular score
	bys id_per_umc: gen n=_n
	bys id_per_umc: gen N=_N
	drop if N==1 
	drop N
	keep score codigo_modular id_per_umc n
	reshape wide score codigo_modular , i(id_per_umc) j(n)
restore

* Is there a bigger type between e.g. publics and privates?
preserve
	bys id_per_umc codigo_modular (semester): egen score = mean(score_std_major)
	bys id_per_umc codigo_modular (semester): keep if _n==1
	bys id_per_umc (semester): gen n=_n
	bys id_per_umc (semester): gen N=_N
	drop if N==1 
	drop N
	keep score codigo_modular public id_per_umc n
	reshape wide score codigo_modular public , i(id_per_umc) j(n)
	
	 pwcorr score1 score2 if public1==1 & public2==1
	 pwcorr score1 score2 if public1==1 & public2==0
	 pwcorr score1 score2 if public1==0 & public2==1
	 //Both public is higher correlation than public-private
restore


***********************************
*- 3. Counterfactuals. Who quits and who keeps trying? Who goes private?
************************************


*- Raw descriptives

use "$OUT\students", clear




gen cat_enroll = .
replace cat_enroll = 1 if enrolled_public	==	1
replace cat_enroll = 2 if enrolled_private	== 	1 & cat_enroll==.
replace cat_enroll = 3 if enrolled			== 	0 & cat_enroll==.


tab cat_enroll if applied_public==1
tab cat_enroll if applied_private==1
tab cat_enroll if applied==1

tab cat_enroll if admitted_public==1
tab cat_enroll if admitted_private==1
tab cat_enroll if admitted==1

/*
Things to try in regression:

									1. R2 high
									2. Big enough cutoffs
									3. 
*/


use "$TEMP\applied", clear

drop if id_per_umc==""
drop if score_std_major == .
keep if public==1

bys id_per_umc (semester): gen n=_n
bys id_per_umc: gen N=_N

*- Attach cutoff information (major)
merge m:1 id_cutoff_major using  "$TEMP/applied_cutoffs_major.dta", keep(master match) keepusing(cutoff_rank_major cutoff_std_major R2_major N_below_major N_above_major)
gen lottery_nocutoff_major = (cutoff_std_major==.)
drop _merge	
gen score_relative = score_std_major - cutoff_std_major
gen N_cutoff = N_below_major + N_above_major

//Why this pattern of admitted... first very low until they do get it and stop. Those who get in get it, but those who stop... how to think of them. Are they different? Would those who got in would've continued?... Can we infer something from the behavior to stop by this ~30% who get admitted in their last try?
tabstat admitted if n<=5 & N==5,by(n)


// First stage might be better to work for ~R2>0.8
binsreg admitted score_relative if abs(score_relative)<2
binsreg admitted score_relative if abs(score_relative)<2 & R2_major>0.8 
binsreg admitted score_relative if abs(score_relative)<2 & R2_major<0.7

//When cells are big enough, this seems to work fine
histogram score_relative if abs(score_relative) < 3 & N_cutoff>1000 & (rank_score_raw_major != cutoff_rank_major)


sort id_per_umc semester

br id_per_umc codigo_modular major_c1_code semester score_std_major score_relative admitted if N==3

***********************************
*- 4. Timing of application and expectations
***********************************
*-- Rate of application by school

//year_app, year_enr, year_adm... are estimated based on last? shouldnt it be first?

use "$OUT\students", clear

keep id_fam_2 id_per_umc fam_order_2 exp_graduating_year1 year_2s aspiration_2s  sec_grad applied admitted enrolled year_graduate year_app year_adm year_enr

gen oldest = fam_order_2 == 1
foreach v of var sec_grad applied admitted enrolled exp_graduating_year1 year_graduate year_app year_adm year_enr {
	bys id_fam_2: egen `v'_oldest = max(cond(oldest==1,`v',.))
}

keep if aspiration_2s!=.
keep if oldest!=1

tab aspiration_2s exp_graduating_year1_oldest if year_2s==2018 & (exp_graduating_year1_oldest>=2014 & exp_graduating_year1_oldest<=2020) & applied_oldest==1, col nofreq
tab aspiration_2s exp_graduating_year1_oldest if year_2s==2019 & (exp_graduating_year1_oldest>=2015 & exp_graduating_year1_oldest<=2021) & applied_oldest==1, col nofreq


tab aspiration_2s year_app_oldest if year_2s==2018, col nofreq
tab aspiration_2s year_enr_oldest if year_2s==2018, col nofreq
tab aspiration_2s year_graduate_oldest if year_2s==2019, col nofreq
tab aspiration_2s year_app_oldest if year_2s==2019, col nofreq
tab aspiration_2s year_adm_oldest if year_2s==2019, col nofreq
tab aspiration_2s year_enr_oldest if year_2s==2019, col nofreq


***********************************
*- 5. How correlated are obs across years
***********************************
use "$OUT\students", clear


*-What year of reference to use?
use "$OUT\students", clear

foreach v of var exp_graduating_year1 exp_graduating_year2 year_graduate {
	preserve
		collapse (mean) applied, by(id_ie_sec `v')
		rename `v' year
		rename applied applied_`v'
		tempfile based_on_`v'
		save `based_on_`v'', replace
	restore
}
keep id_ie_sec
bys id_ie_sec: keep if _n==1
expand 10
bys id_ie_sec: gen year = _n+2014

foreach v in "exp_graduating_year1" "exp_graduating_year2" "year_graduate" {
	merge m:1 id_ie_sec year using `based_on_`v'', keep(master match)
	drop _m
}

format %9.2f applied_*

scatter applied_year_graduate applied_exp_graduating_year1, xtitle("cohort") ytitle("Among graduates")
// Perhaps better to include both rates since relationship is not linear.






*-
use "$OUT\students", clear
gen even = mod(year_graduate,2)==0 if year_graduate!=.
gen pop = 1

keep if year_graduate>=2016 & year_graduate<=2023

preserve
	collapse (mean) applied admitted enrolled applied_public enrolled_public applied_private enrolled_private     (sum) school_enrollment = pop, by(id_ie_sec even)

	reshape wide applied admitted enrolled applied_public enrolled_public applied_private enrolled_private school_enrollment, i(id_ie_sec) j(even)
	tempfile even_odd
	save `even_odd', replace
restore

collapse (mean) applied admitted enrolled applied_public enrolled_public applied_private enrolled_private     (sum) school_enrollment = pop, by(id_ie_sec)

merge 1:1 id_ie_sec using `even_odd', keep(master match)


foreach v of var applied admitted enrolled applied_public enrolled_public applied_private enrolled_private school_enrollment {
	pwcorr `v'0 `v'1
	format %9.1f `v' `v'0 `v'1
}

//Correlations are high


*- Other relationships
histogram applied_public



***********************************
*- 6. Peers spillovers
***********************************
use "$OUT\students", clear

clonevar year_graduate_orig = year_graduate

preserve
	keep if year_graduate>=2016 & year_graduate<=2023
	replace year_graduate = year_graduate_orig-1
	gen pop = 1
	bys id_ie_sec year_graduate: egen pre_school_enrollment = sum(pop)
	bys id_ie_sec year_graduate: egen pre_applied = mean(applied)
	bys id_ie_sec year_graduate: egen pre_admitted = mean(admitted)
	bys id_ie_sec year_graduate: egen pre_enrolled = mean(enrolled)
	
	bys id_ie_sec year_graduate: egen pre_applied_public = mean(applied_public)
	bys id_ie_sec year_graduate: egen pre_enrolled_public = mean(enrolled_public)
	
	bys id_ie_sec year_graduate: egen pre_applied_private = mean(applied_private)
	bys id_ie_sec year_graduate: egen pre_enrolled_private = mean(enrolled_private)
		
	bys id_ie_sec year_graduate: keep if _n==1
	keep id_ie_sec year_graduate pre_*
	tempfile pre_vars
	save `pre_vars'
restore

merge m:1 id_ie_sec year_graduate using `pre_vars', keep(master match) 
drop _m



replace year_graduate = year_graduate_orig+1
merge m:1 id_ie_sec year_graduate using "$OUT\applications_school_cohort", keep(master match)

//histogram max_score_relative if abs(max_score_relative)<2 & max_rank_relative!=0

*-
gen ABOVE_max_score_relative 	= max_ABOVE*max_score_relative	
reghdfe applied_public max_ABOVE  max_score_relative ABOVE_max_score_relative ///
	if ///${if_final} & ///
	 abs(max_score_relative)<1, ///
	cluster(id_ie_sec) absorb(id_ie_sec)		


	
	/*
	histogram max_score_relative if n==1 & abs(max_score_relative)<2 & max_rank_relative!=0
	binsreg total_applicants max_score_relative if n==1 & abs(max_score_relative)<2 & max_rank_relative!=0
	binsreg has_admitted max_score_relative if n==1 & abs(max_score_relative)<2 & max_rank_relative!=0
	binsreg has_admitted_public max_score_relative if n==1 & abs(max_score_relative)<2 & max_rank_relative!=0
	binsreg total_admitted max_score_relative if n==1 & abs(max_score_relative)<2 & max_rank_relative!=0
	binsreg total_admitted_public max_score_relative if n==1 & abs(max_score_relative)<2 & max_rank_relative!=0
	*/	
/*	
binsreg total_admitted_public max_score_relative if abs(max_score_relative)<1 & max_rank_relative!=0 & pre_applied<0.2, nbins(100)
binsreg total_admitted_public max_score_relative if abs(max_score_relative)<1 & max_rank_relative!=0 & pre_applied>0.7 & pre_applied!=., nbins(100)

*- If application rates are high, it is one of many admitted.
binsreg total_admitted max_score_relative if abs(max_score_relative)<1 & max_rank_relative!=0 & pre_applied<0.2, nbins(100)
binsreg total_admitted max_score_relative if abs(max_score_relative)<1 & max_rank_relative!=0 & pre_applied>0.7 & pre_applied!=., nbins(100)
	
	
binsreg applied max_score_relative if abs(max_score_relative)<1 & max_rank_relative!=0, nbins(100)


binsreg max_ABOVE max_score_relative if abs(max_score_relative)<1 & max_rank_relative!=0 & pre_applied<0.05, nbins(100)


binsreg applied 				max_score_relative if abs(max_score_relative)<1 & max_rank_relative!=0, nbins(100)
binsreg applied_public 			max_score_relative if abs(max_score_relative)<1 & max_rank_relative!=0, nbins(100)
*/
binsreg total_admitted_public 	max_score_relative if abs(max_score_relative)<1 & max_rank_relative!=0 ///
	, ///
	nbins(50) ///
	by(max_ABOVE) bycolors(gs0 gs0) bysymbols(o o) ///
	xtitle("Maximum Relative Admission Score - Prior peer cohort") ///
	ytitle("# of students admitted to public college") ///
	legend(off)
	graph export 	"$FIGURES/eps/first_stage_peers_total_admitted_public.eps", replace	
	graph export 	"$FIGURES/png/first_stage_peers_total_admitted_public.png", replace	
	graph export 	"$FIGURES/pdf/first_stage_peers_total_admitted_public.pdf", replace	
	
binsreg total_admitted 	max_score_relative if abs(max_score_relative)<1 & max_rank_relative!=0	///
	, ///
	nbins(50) ///
	by(max_ABOVE) bycolors(gs0 gs0) bysymbols(o o) ///
	xtitle("Maximum Relative Admission Score - Prior peer cohort") ///
	ytitle("# of students admitted to any college") ///
	legend(off)
	graph export 	"$FIGURES/eps/first_stage_peers_total_admitted.eps", replace	
	graph export 	"$FIGURES/png/first_stage_peers_total_admitted.png", replace	
	graph export 	"$FIGURES/pdf/first_stage_peers_total_admitted.pdf", replace	
	
binsreg total_enrolled_public 	max_score_relative if abs(max_score_relative)<1 & max_rank_relative!=0	///
	, ///
	nbins(50) ///
	by(max_ABOVE) bycolors(gs0 gs0) bysymbols(o o) ///
	xtitle("Maximum Relative Admission Score - Prior peer cohort") ///
	ytitle("# of students enrolled in public college") ///
	legend(off)
	graph export 	"$FIGURES/eps/first_stage_peers_total_enrolled_public.eps", replace	
	graph export 	"$FIGURES/png/first_stage_peers_total_enrolled_public.png", replace	
	graph export 	"$FIGURES/pdf/first_stage_peers_total_enrolled_public.pdf", replace	
	
binsreg total_enrolled 	max_score_relative if abs(max_score_relative)<1 & max_rank_relative!=0 ///
	, ///
	nbins(50) ///
	by(max_ABOVE) bycolors(gs0 gs0) bysymbols(o o) ///
	xtitle("Maximum Relative Admission Score - Prior peer cohort") ///
	ytitle("# of students enrolled in any college") ///
	legend(off)
	graph export 	"$FIGURES/eps/first_stage_peers_total_enrolled.eps", replace	
	graph export 	"$FIGURES/png/first_stage_peers_total_enrolled.png", replace	
	graph export 	"$FIGURES/pdf/first_stage_peers_total_enrolled.pdf", replace		
	

***********************************
*- 7. Correlation between sibling exams
***********************************
use "$OUT\students", clear


keep id_per_umc id_fam_${fam_type} fam_order_${fam_type} score_acad_std_2p

merge 1:1 id_per_umc using "$TEMP\application_info_first_student", keepusing(score_std_*_all score_std_*_pub) keep(master match)

bys id_fam_${fam_type}: egen sib_app_scores = mean(cond(fam_order_${fam_type}>1,score_std_major_all,.))
bys id_fam_${fam_type}: egen sib_ece_scores = mean(cond(fam_order_${fam_type}>1,score_acad_std_2p,.))
keep if fam_order_${fam_type}==1

binsreg sib_ece_scores score_acad_std_2p
binsreg sib_app_scores score_std_major_all

pwcorr sib_ece_scores score_acad_std_2p
pwcorr sib_app_scores score_std_major_all