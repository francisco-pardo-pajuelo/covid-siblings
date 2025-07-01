*- Strange scores
use "$TEMP/applied_withCUTOFFS.dta", clear

gen score_relative = score_std - cutoff_std


keep id_cutoff cutoff_raw score_relative
 
tempfile mccrary_ready_for_test
save `mccrary_ready_for_test'

clear

gen id_cutoff = .
gen double mccrary_pval_def = .
gen double mccrary_pval_biasi = .
gen double mccrary_test = .

label define mccrary_test 0 "No Cutoff" 1 "Test Performed" 2 "Error in test (default)" 3 "Error in test (Biasi)" 4 "Error in test (Both)"
label values mccrary_test mccrary_test

label var mccrary_test "Indicates whether test was performed"
label var mccrary_pval_def "pvalue of McCrary test (default)"
label var mccrary_pval_def "pvalue of McCrary test (similar to Biasi et. al. (2024))"
	
save "$TEMP/mccrary_cutoffs.dta", replace emptyok
 

use `mccrary_ready_for_test', clear

//keep if id_cutoff>3000

levelsof id_cutoff, local(levels)

foreach l of local levels {
	use `mccrary_ready_for_test', clear
	keep if id_cutoff == `l'
	di "`l'"
	sum cutoff_raw 
	local mccrary_pval_def = .
	local mccrary_pval_biasi = .
	local mccrary_test = 0
	
	//replace mccrary_test = 0 //no cutoff
	if `r(N)'>0 {
		capture rddensity score_relative if id_cutoff == `l', c(0) 
		if _rc==0	{
			local mccrary_pval_def = `e(pv_q)'
			local mccrary_test = 1
			}
		if _rc!=0	{
			local mccrary_test = 2
			}	
			
		capture rddensity score_relative if id_cutoff == `l', c(0) p(3) kernel(uniform) 
		if _rc==0	{
			local mccrary_pval_biasi = `e(pv_q)' 
			local mccrary_test = 1
			}
		if _rc!=0	{
			if `mccrary_test'==1 local mccrary_test = 3 
			if `mccrary_test'==2 local mccrary_test = 4 
			}				
	}

	keep if _n==1
	gen double mccrary_pval_def = `mccrary_pval_def'
	gen double mccrary_pval_biasi = `mccrary_pval_biasi'
	gen double mccrary_test = `mccrary_test'
	keep id_cutoff mccrary*
	append using  "$TEMP/mccrary_cutoffs.dta"
	save  "$TEMP/mccrary_cutoffs.dta", replace			
				
	if mod(`l',60)==10 save "$TEMP/mccrary_cutoffs_TEMP.dta", replace //every 60 starting at 5.	
	
}




/*
	
	rename abreviatura_anio year
	keep if year==2017
	keep if lottery_nocutoff == 0
	
	gen score_relative = score_std - cutoff_std
	
	keep
	rddensity score_relative if id_cutoff == 7247, c(0) //0.0000
	rddensity score_relative if id_cutoff == 4883, c(0) //0.0000
	

		histogram score_relative ///
		if abs(score_relative)<5,  ///
		fcolor(gs14) lcolor(gs0) xline(0) title("`y'")	 ///
		name(histogram_`y', replace)	
	
	
histogram score_std	if abs(score_std)<2, xline(0)


bys id_cutoff: gen N=_N
bys id_cutoff admitted: gen N2 = _N 
bys id_cutoff: egen p_adm = mean(admitted)


gen p = N2/N

histogram score_relative	if abs(score_relative)<2 & (p>0.4 & p<0.6), xline(0)

histogram score_relative if N == 4636



       4174 |      4,174        0.76       93.08
       4513 |      4,513        0.82       93.90
       4573 |      4,573        0.83       94.73
       *4636 |      4,636        0.84       95.57
       4992 |      4,992        0.91       96.48
       5167 |      5,167        0.94       97.41
       5968 |      5,968        1.08       98.50
       8274 |      8,274        1.50      100.00



preserve
	bys id_cutoff: keep if _n==1
	histogram cutoff_std if (p>0.4 & p<0.6)
	
restore

*/