/********************************************************************************
- Author: Francisco Pardo
- Description: Looks into potential threats to RD and improve the sample selection.
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/

capture program drop main 
program define main 

	setup
	attach_cuttofs_applied noz major
	first_stage_plot

end





********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup

	set seed 1234
	global window = 2
	global mccrary_window = 4
	global redo_all = 0

end

**********
*Mccrary
***********

capture program drop mctest
program define mctest


rddensity score_relative ///
		if abs(score_relative)<$mccrary_window & ${if_ex} ///
		, ///
		///xtitle("Standardized score relative to cutoff") ///
		c(0) ///
		///p(1) /// are these required for mccrary? Or just for estimating outcomes? ###
		///q(2) ///
		kernel(triangular) ///
		all ///
		plot 

end


********************************************************************************
* attach cutoffs
********************************************************************************

capture program drop attach_cuttofs_applied
program define attach_cuttofs_applied

args type cell


	
	*-- Adding relevant info to database
	use "$TEMP\applied", clear
	
	keep id_per_umc id_persona_rec year id_cutoff_major id_cutoff_department codigo_modular semester public region admitted major_c1_inei_code rank_score_raw* score_raw score_std*
	
	clonevar major_inei_code = major_c1_inei_code
	
	keep if id_per_umc != ""


	*- Covariates
	merge m:1 id_per_umc using "$OUT\students", keepusing(educ_mother score_math_std_2p score_com_std_2p) keep(master match) nogen	
	gen byte higher_ed_mother 		= inlist(educ_mother,7,8) if educ_mother!=. & educ_mother!=1
	
	*-- University (enrollment)
	merge m:1 id_per_umc using "$OUT\students", keepusing(dob_enr score_std_uni_enr avg_enr_score_*_std_??) keep(master match) nogen
	rename (dob_enr score_std_uni_enr avg_enr_score_*_std_??) (dob_enr_foc score_std_uni_enr_foc avg_enr_score_*_std_??_foc)	
	
	
//Same semester
	*- Enrolled in same uni-major 	semester
	merge m:1 id_per_umc codigo_modular /*facultad*/ major_inei_code semester using "$TEMP\enrolled_students_university_major_semester", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enroll_uni_major_sem_foc year_enr_uni_major_sem_foc)

	*- Enrolled in same uni 		semester
	merge m:1 id_per_umc codigo_modular semester using "$TEMP\enrolled_students_university_semester", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enroll_uni_sem_foc year_enr_uni_sem_foc)		
	
	*- Enrolled in public 			semester
	merge m:1 id_per_umc semester using "$TEMP\enrolled_students_public_semester", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enroll_public_sem_foc year_enr_public_sem_foc)		
	
	*- Enrolled in private 			semester
	merge m:1 id_per_umc semester  using "$TEMP\enrolled_students_private_semester", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enroll_private_sem_foc year_enr_private_sem_foc)		
	
	*- Enrolled 					semester
	merge m:1 id_per_umc semester using "$TEMP\enrolled_students_semester", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enroll_sem_foc year_enr_sem_foc)	
	
	
	//Ever
	*- Enrolled in same uni-major 	ever
	merge m:1 id_per_umc codigo_modular /*facultad*/ major_inei_code  using "$TEMP\enrolled_students_university_major", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enroll_uni_major_foc year_enr_uni_major_foc)		
	
	*- Enrolled in same uni 		ever
	merge m:1 id_per_umc codigo_modular using "$TEMP\enrolled_students_university", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enroll_uni_foc year_enr_uni_foc)		
	
	*- Enrolled in public 			ever
	merge m:1 id_per_umc using "$TEMP\enrolled_students_public", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enroll_public_foc year_enr_public_foc)	

	*- Enrolled in (other) public
	merge m:1 id_per_umc codigo_modular using "$TEMP\enrolled_students_other_public", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enroll_public_o_foc year_enroll_public_o_foc)	
	
	*- Enrolled in private 			ever
	merge m:1 id_per_umc using "$TEMP\enrolled_students_private", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enroll_private_foc year_enr_private_foc)
	
	*- Enrolled 					ever
	merge m:1 id_per_umc using "$TEMP\enrolled_students", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (enroll_foc year_enr_foc)	
	
	**************
	*- Attaching cutoff information
	**************
	
	*- Attach cutoff information (department)
		merge m:1 id_cutoff_department using  "$TEMP/applied_cutoffs_department.dta", keep(master match) keepusing(cutoff_rank_department cutoff_std_department)
		gen lottery_nocutoff_department = (cutoff_std_department==.)
		drop _merge
		
	*- Attach cutoff information (major)
		merge m:1 id_cutoff_major using  "$TEMP/applied_cutoffs_major.dta", keep(master match) keepusing(cutoff_rank_major cutoff_std_major coeff_major p_val_major R2_major N_below_major N_above_major)
		gen lottery_nocutoff_major = (cutoff_std_major==.)
		drop _merge	
		
	*- Attach McCrary Tests (removing score=0) (major)
		merge m:1 id_cutoff_department using  "$TEMP/mccrary_cutoffs_noz_department.dta", keep(master match)
		drop _m
	
		merge m:1 id_cutoff_major using  "$TEMP/mccrary_cutoffs_noz_major.dta", keep(master match)
		drop _m
		
	*- Details from university
	//merge 1:1 id_cutoff_major using `id_cutoff_major_database', keep(master match) keepusing(universidad public year) nogen
			

		
	rename *_`cell' *
	rename *_`type' * 

*- Score relative
	gen score_relative = score_std - cutoff_std
	gen rank_score_relative = rank_score_raw - cutoff_rank
	drop if score_relative==.	
	//keep if abs(score_relative)<${window} 
	//keep if abs(score_relative)<5

	*- Run the RD regression
	gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=. //To avoid float issues around 0, we use the precisely integer rank scores.

	*- Polynomial
	forvalues p = 1/5 {
		gen score_relative_`p' 			= score_relative^`p'
		gen ABOVE_score_relative_`p' 	= ABOVE*score_relative_`p'
	}
	
	
end



********************************************************************************
* attach cutoffs
********************************************************************************

capture program drop first_stage_plot
program define first_stage_plot

/*
	binsreg admitted 					score_relative if public==1 & abs(score_relative)<1 & codigo_modular==160000001
	binsreg enroll_uni_major_sem_foc 	score_relative if public==1 & abs(score_relative)<1 & codigo_modular==160000001
	//binsreg enroll_public_sem_foc 		score_relative if public==1 & abs(score_relative)<1 & codigo_modular==160000001
	//binsreg enroll_private_sem_foc 		score_relative if public==1 & abs(score_relative)<1 & codigo_modular==160000001
	binsreg enroll_uni_foc 				score_relative if public==1 & abs(score_relative)<1 & codigo_modular==160000001
	//binsreg enroll_public_foc 			score_relative if public==1 & abs(score_relative)<1 & codigo_modular==160000001
	//binsreg enroll_public_o_foc 		score_relative if public==1 & abs(score_relative)<1 & codigo_modular==160000001
	binsreg enroll_private_foc 			score_relative if public==1 & abs(score_relative)<1 & codigo_modular==160000001
	binsreg enroll_foc 					score_relative if public==1 & abs(score_relative)<1 & codigo_modular==160000001
	
	
	*****
	* Story is as follows. Those who get admitted, not always enroll but there is a big jump (~60pp). If they don't get admitted, most of them keep trying and get in (20pp), some of them later go to private (10pp) and some of them don't ever enroll in any (20pp)
	*****
*/
	gen R2_cat = .
	replace R2_cat = 1 if R2 == 1
	replace R2_cat = 2 if R2>=.95 & R2_cat==.
	replace R2_cat = 3 if R2>=.90 & R2_cat==.
	replace R2_cat = 4 if R2>=.80 & R2_cat==.
	replace R2_cat = 5 if R2>=.70 & R2_cat==.
	replace R2_cat = 6 if R2>=.60 & R2_cat==.
	replace R2_cat = 7 if R2>=.50 & R2_cat==.
	replace R2_cat = 8 if R2>=.40 & R2_cat==.
	replace R2_cat = 9 if R2<=.30 & R2_cat==.


	//First see if there is a jump. We classify this in 4 groups: public/private and R2=1 and R2!=1.
	binsreg admitted 					score_relative if public==1 & (rank_score_raw!=cutoff_rank) & abs(score_relative)<1 & R2_cat==1
	binsreg admitted 					score_relative if public==1 & (rank_score_raw!=cutoff_rank) & abs(score_relative)<1 & R2_cat!=1
	binsreg admitted 					score_relative if public==0 & (rank_score_raw!=cutoff_rank) & abs(score_relative)<1 & R2_cat==1
	binsreg admitted 					score_relative if public==0 & (rank_score_raw!=cutoff_rank) & abs(score_relative)<1 & R2_cat!=1

	//We look at the histograms
	histogram 					score_relative if public==1 & (rank_score_raw!=cutoff_rank) & abs(score_relative)<1 & R2_cat==1, bins(100)
	histogram 					score_relative if public==1 & (rank_score_raw!=cutoff_rank) & abs(score_relative)<1 & R2_cat!=1, bins(100)
	histogram 					score_relative if public==0 & (rank_score_raw!=cutoff_rank) & abs(score_relative)<1 & R2_cat==1, bins(100)
	histogram 					score_relative if public==0 & (rank_score_raw!=cutoff_rank) & abs(score_relative)<1 & R2_cat!=1, bins(100)

	//We look at one covariate
	binsreg score_math_std_2p 					score_relative if public==1 & (rank_score_raw!=cutoff_rank) & abs(score_relative)<1 & R2_cat==1
	binsreg score_math_std_2p 					score_relative if public==1 & (rank_score_raw!=cutoff_rank) & abs(score_relative)<1 & R2_cat!=1
	binsreg score_math_std_2p 					score_relative if public==0 & (rank_score_raw!=cutoff_rank) & abs(score_relative)<1 & R2_cat==1
	binsreg score_math_std_2p 					score_relative if public==0 & (rank_score_raw!=cutoff_rank) & abs(score_relative)<1 & R2_cat!=1

	// Are there really many privates with correct R2? Are these with regular observations?
	// Yes, but these seem like manipulated cutoffs...?

	table R2_cat public, stat(mean N_below N_above)

end



main

assert 1==0

close

open

//CONCLUSSION FOR NOW:
/*
There are some universities that can't perform the mcrrary test for "insufficient observations". Not sure why not. Some of this seem like good schools:

I seem to face 2 issues:

1. Bunching at 0, which seem to happen mechanically due to no tie breaking, which causes some flexibility in the cuttoff (might not be an issue?)

2. Mccrary test not passing: This in many cases seems visually not compelling, the failure seems to be more strict than what I see in the figure... why?



*/


*- 0. Ideal McCrary

*
**
***
****
*****
******
*******
********
 ******** 		RDrobust by default has equal bandwidths it seems. Rddensity doesnt. Include 'fitselect(restricted)' ??? ###
********
*******
******
*****
****
***
**
*

global if_ex `"public==1 & rank_score_relative!=0"'
histogram score_relative if ${if_ex}, bins(50) xline(0) // Looks good
histogram score_relative if ${if_ex}, bins(200) xline(0) // Looks odd when refining the bins.
histogram score_relative if ${if_ex} & abs(score_relative)<2, bins(200) xline(0) // Looks odd when refining the bins.

//Doesn't make a lot of difference filtering by mccrary pval
histogram score_relative if ${if_ex} & abs(score_relative)<2 & mccrary_pv_def>0.05, bins(200) xline(0) // Looks odd when refining the bins.
histogram score_relative if ${if_ex} & abs(score_relative)<2 & mccrary_pv_def>0.5 & mccrary_pv_def<1, bins(200) xline(0) // Looks odd when refining the bins.

mctest //optimal bandwidths fails... but too strongly in my opinion...

//Similar to Biasi et. al?
rddensity score_relative ///
		if ${if_ex} ///
		, ///
		c(0) ///
		p(3) /// are these required for mccrary? Or just for estimating outcomes? ###
		q(3) ///
		kernel(uniform) ///
		h(2 2) ///
		plot 


/*


keep if abs(score_relative)<5


bys id_cutoff: egen avg_admitted = mean(admitted)
histogram score_relative 		if public==1 & N_below>30 & N_above>30 & R2>=0.5, bins(30)
histogram rank_score_relative 	if public==1 & N_below>30 & N_above>30 & R2>=0.5 & abs(rank_score_relative)<30,  discrete
tab rank_score_relative if public==1 & N_below>30 & N_above>30 & R2>=0.5 & abs(rank_score_relative)<30
//This should be uniform if no relevant ties around cutoff (N above/below and rank window are the same), including the 0 and -1, whiy still bunching?

// Identify cutoffs with ties

bys id_cutoff rank_score_relative: gen N_ties = _N
gen has_ties = N_ties>1
tabstat has_ties, by(rank_score_relative)
// Why are there so much more ties in rank=0
// More importantly, why are there NO ties in rank=-1. This seems like a problem....
// Explanation: If ties during slot maximum, then cutoff is likely displaced, so it is expected if there are no tie-breakers that cutoffs will have bunching?
// About no ties in -1, this is because if there are ties in -1 (e.g. two students), they will be ranked as '-2'. This only happens here because it is defined as 'the rank after 0', and 0 is the rank of those last admitted. It has a starting point. Still shouldn't speak about the standardized score bunching.

binsreg has_ties score_relative if public==1 & N_below>30 & N_above>30 & R2>=0.5

*/

// I believe the bunching is ultimately created mechanically because there are no tie-breakers in this system, and the capacity is rather flexible so that if we reach capacity, still a few more applicants close to the cutoff will still be admitted.

*- 1. Ties at cutoff
bys id_cutoff: egen ties_cutoff = max(cond(N_ties>1 & rank_score_relative==0,1,0))
histogram score_relative if public==1 & ties_cutoff==1, bins(200) xline(0)
//Why is there bunching below cutoff when including ties at the cutoff.

histogram score_relative if public==1 & ties_cutoff==0, bins(200) xline(0)
//Why is there bunching still bunching when excluding ties.

histogram score_relative if public==1, bins(100) 
// Why still a dip just after 0?

//Can we redefine the cutoff? What is the lowest score below the cutoff?
/*
bys id_cutoff: egen cutoff_std_low = max(cond(rank_score_raw < cutoff_rank,score_std,.))
egen cuttoff_std_mean = rmean(cutoff_std cutoff_std_low)
gen score_relative_new = score_std - cuttoff_std_mean
global if_ex `"public==1"'
histogram score_relative_new if ${if_ex}, bins(200) xline(0)
*/


*- 3. We get a sense of wellness for each university based on the % of mcrrary below expected
preserve
	bys id_cutoff: keep if _n==1
	bys universidad: egen below_50 = mean(mccrary_pv_def<0.5)
	bys universidad: egen no_test = mean(mccrary_test==4)
	bys universidad: gen N=_N //cuttoffs available
	bys universidad: keep if _n==1
	//In perfect cases, this average should be ~.50. If universities are problematic, then it will be much lower. Let's see.
	sort below_50
	list universidad public below_50 no_test N if no_test<0.5, sep(500)
restore

*- 2. Example of universities:
global if_ex `"codigo_modular == "UNIVERSIDAD NACIONAL DE PIURA" & semester=="2020-1" & strmatch(major_c1_name,"*DERECHO Y CIENCIAS*")"'
histogram score_raw if ${if_ex}, bins(50) 
histogram score_std if ${if_ex}, bins(50) 
mctest

global if_ex = `"universidad == "UNIVERSIDAD NACIONAL DE PIURA" & rank_score_relative!=0"'
di `"${if_ex}"'
sum mccrary_pv_def if ${if_ex}, de
histogram score_relative if ${if_ex}, bins(100) 
mctest
histogram score_relative if ${if_ex} & abs(score_relative)<e(h_l), bins(100) 
//Many mccrarys not performed... why?

global if_ex = `"universidad == "UNIVERSIDAD PERUANA LOS ANDES""'
di `"${if_ex}"'
sum mccrary_pv_def if ${if_ex}, de
histogram score_relative if ${if_ex}, bins(100) 
//Good behavior private. Mcrary pvalues seem ~ to percentiles


global if_ex = `"universidad == "UNIVERSIDAD PERUANA CAYETANO HEREDIA""'
di `"${if_ex}"'
sum mccrary_pv_def if ${if_ex}, de
histogram score_relative if ${if_ex}, bins(100) 
binsreg admitted score_raw if ${if_ex}, nbins(100) 
//Good behavior private. Mcrary pvalues seem ~ to percentiles

global if_ex = `"universidad == "UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ""'
di `"${if_ex}"'
sum mccrary_pv_def if ${if_ex}, de
histogram score_relative if ${if_ex}, bins(100) 
//Good behavior public. Mcrary pvalues seem ~ to percentiles


global if_ex = `"codigo_modular == "PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ""'
di `"${if_ex}"'
sum mccrary_pv_def if ${if_ex}, de
histogram score_relative if ${if_ex} & abs(score_relative)<.7, bins(100) 
mctest
//Good behavior private. Mcrary pvalues seem ~ to percentiles

//global if_ex = `"codigo_modular == 160000001 & semester=="2020-1" & strmatch(major_c1_name,"*DERECHO*")"''
//global if_ex = `"codigo_modular == 160000001 & semester=="2020-1" & strmatch(major_c1_name,"*INGENIERÍA INDUSTRIAL*")"''
global if_ex = `"codigo_modular == 160000001 & semester=="2020-1" & strmatch(major_c1_name,"*MEDICINA HUMANA*")"''
di `"${if_ex}"'
capture drop admitted_mean n
tab major_c1_name if ${if_ex}
sum mccrary_pv_def if ${if_ex}, de
histogram score_raw if ${if_ex}, bins(30) 

bys score_raw: egen admitted_mean = mean(admitted)  if ${if_ex}
bys score_raw: gen n = _n==1  if ${if_ex}

preserve
	twoway 	(scatter admitted_mean score_raw if n==1, yaxis(2)) ///
			(histogram score_raw if ${if_ex}, bins(40) fcolor(green%30) lcolor(green)), ///
		     legend(off) ytitle("% of admitted students", axis(2)) xtitle("Raw admission score")
restore
	graph export 	"$FIGURES/png/raw_example.png", replace
	graph export 	"$FIGURES/eps/raw_example.eps", replace	
	graph export 	"$FIGURES/pdf/raw_example.pdf", replace

//Good behavior public. Mcrary pvalues seem ~ to percentiles

global if_ex = `"universidad == "UNIVERSIDAD CÉSAR VALLEJO""'
di `"${if_ex}"'
sum mccrary_pv_def if ${if_ex}, de
histogram score_relative if ${if_ex}, bins(100) 
//Bad behavior private. Mcrary are well below the percentiles, most of them rejected.

