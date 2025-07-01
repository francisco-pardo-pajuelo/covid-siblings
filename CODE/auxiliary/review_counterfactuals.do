*- Review

global fam_type=2
global data = ""

local cutoff_level = "major"
use "$OUT/applied_outcomes_${fam_type}${data}.dta", clear

bys id_per_umc id_cutoff_major: keep if _n==1
keep   enroll_foc enroll_private_foc educ_mother educ_father region_siagie_foc public_siagie_foc urban_siagie_foc carac_siagie_foc /*avg_applied* avg_enroll**/ male_siagie_foc socioec_index_*_foc score_*_std_??_foc admitted public_foc score_std_`cutoff_level' cutoff_std_`cutoff_level' rank_score_raw_`cutoff_level' cutoff_rank_`cutoff_level'

//Attach cutoffs, get those marginally rejected
/*

merge m:1 id_cutoff_`cutoff_level' using  "$TEMP/applied_cutoffs_`cutoff_level'.dta", keep(master match) keepusing(cutoff_rank_`cutoff_level' cutoff_std_`cutoff_level' R2_`cutoff_level' N_below_`cutoff_level' N_above_`cutoff_level')
gen lottery_nocutoff_`cutoff_level' = (cutoff_std_`cutoff_level'==.)
drop _merge
*/


//We have those below the cutoff that were likely not admitted.


//We attach some explanatory vars

/*
*-- School
merge m:1 id_per_umc using "$OUT\students${data}", keepusing(region_siagie public_siagie urban_siagie carac_siagie /*avg_applied* avg_enroll**/) keep(master match) nogen

*-- Demographic
merge m:1 id_per_umc using "$OUT\students${data}", keepusing(male_siagie socioec_index_*) keep(master match) nogen
*/
gen score_relative = score_std_`cutoff_level' - cutoff_std_`cutoff_level'
drop if score_relative==.

gen sample_all = 0
replace sample_all = 1 

gen sample_below = 0
replace sample_below = 1 if rank_score_raw_`cutoff_level'<cutoff_rank_`cutoff_level'

gen sample_below5 = 0
replace sample_below5 = 1 if rank_score_raw_`cutoff_level'<cutoff_rank_`cutoff_level' & score_relative>-0.5

gen sample_below2 = 0
replace sample_below2 = 1 if rank_score_raw_`cutoff_level'<cutoff_rank_`cutoff_level' & score_relative>-0.2


sum educ_mother educ_father region_siagie_foc public_siagie_foc urban_siagie_foc carac_siagie_foc /*avg_applied* avg_enroll**/ male_siagie_foc socioec_index_*_foc score_*_std_??_foc

rename enroll_foc enrolled

foreach sample in "all" "below" "below5" "below2" {
	local out = "enrolled"
	count if sample_`sample'
	local N_`sample' = r(N)

	global covar1 "male_siagie_foc i.educ_mother i.region_siagie_foc i.urban_siagie_foc i.public_siagie_foc"
	logit `out' ${covar1} if sample_`sample'==1			
	local s1_`sample' =  e(N) 
	predict rej_`out'_`sample'_lpred1

	global covar2 "male_siagie_foc i.educ_mother i.region_siagie_foc i.urban_siagie_foc i.public_siagie_foc score_math_std_2p_foc score_com_std_2p_foc"
	logit `out' ${covar2} if sample_`sample'==1		
	local s2_`sample' =  e(N) 
	predict rej_`out'_`sample'_lpred2

	global covar3 "male_siagie_foc i.educ_mother i.region_siagie_foc i.urban_siagie_foc i.public_siagie_foc score_math_std_2s_foc score_com_std_2s_foc socioec_index_2s_foc"
	logit `out' ${covar3} if sample_`sample'==1			
	local s3_`sample' =  e(N) 
	predict rej_`out'_`sample'_lpred3


	//Set median cutoffs

	sum	rej_enrolled_`sample'_lpred1 if sample_`sample', de
	gen rej_enrolled_`sample'_lpred1_above = (rej_enrolled_`sample'_lpred1>r(p50) & rej_enrolled_`sample'_lpred1!=.)
	sum	rej_enrolled_`sample'_lpred2 if sample_`sample', de
	gen rej_enrolled_`sample'_lpred2_above = (rej_enrolled_`sample'_lpred2>r(p50) & rej_enrolled_`sample'_lpred2!=.)
	sum	rej_enrolled_`sample'_lpred3 if sample_`sample', de
	gen rej_enrolled_`sample'_lpred3_above = (rej_enrolled_`sample'_lpred3>r(p50) & rej_enrolled_`sample'_lpred3!=.)
					
		
}


foreach sample in "all" "below" "below5" "below2" {
	di as result "Sample: `sample'" _n
	di as text  _n "Sample 1:" %9.1f `s1_`sample''*100/`N_`sample'' ///
				_n "Sample 2:" %9.1f `s2_`sample''*100/`N_`sample'' ///
				_n "Sample 3:" %9.1f `s3_`sample''*100/`N_`sample'' _n
}
	
	
	
binsreg admitted score_relative if abs(score_relative)<2


binsreg enrolled score_relative if abs(score_relative)<2
binsreg enrolled score_relative if abs(score_relative)<2 & lpred1_above==1
binsreg enrolled score_relative if abs(score_relative)<2 & lpred1_above==0


binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_all_lpred1_above==1
binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_all_lpred1_above==0

binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_below2_lpred1_above==1
binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_below2_lpred1_above==0


binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_all_lpred2_above==1
binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_all_lpred2_above==0

binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_below2_lpred2_above==1
binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_below2_lpred2_above==0

binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_all_lpred3_above==1
binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_below_lpred3_above==1
binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_below5_lpred3_above==1
binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_below2_lpred3_above==1

binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_all_lpred3_above==0
binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_below_lpred3_above==0
binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_below5_lpred3_above==0
binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_below2_lpred3_above==0

binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_all_lpred2_above==1
binsreg enrolled score_relative if abs(score_relative)<2 & rej_enrolled_all_lpred2_above==0
