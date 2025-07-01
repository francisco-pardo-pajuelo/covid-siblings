local cell = "major"

	//local cell major
	use "$TEMP\applied.dta", clear

	keep codigo_modular major_c1_inei_code id_per_umc id_cutoff_`cell' score_std_`cell' rank_score_raw_`cell' public

	//Attach cutoffs, get those marginally rejected
	merge m:1 id_cutoff_`cell' using  "$TEMP/applied_cutoffs_`cell'.dta", keep(master match) keepusing(cutoff_rank_`cell' cutoff_std_`cell' R2_`cell' N_below_`cell' N_above_`cell')
	gen lottery_nocutoff_`cell' = (cutoff_std_`cell'==.)
	drop _merge

	sum  /*avg_applied* avg_enroll**/ 

	merge m:1 id_per_umc using "$OUT\students${data}", keepusing(/*School*/ 		id_ie_* region_siagie public_siagie urban_siagie /*avg_applied* avg_enroll**/ min_dist_uni min_dist_uni_public min_dist_uni_private avg_enrolled_public avg_enrolled_private avg_enrolled ///
																 /*Demog*/ 			male_siagie educ_mother educ_father socioec_index_*  ///
																 /*Academic*/		score_math_std_?? score_com_std_?? ///
																 /*Progression*/	 ///
																 /*Aspiration*/		 aspiration_?? ///
																 /*University*/		enrolled enrolled_private enrolled_public admitted* ///
																 )


	
	bys id_per_umc: gen 	one_app = _N==1
	bys id_per_umc: egen 	priv_app = max(cond(public==0,1,0))
	gen no_priv = priv_app==0
	

	gen score_relative = score_std_`cell' - cutoff_std_`cell'
	drop if score_relative==.

	gen sample = 0
	replace sample = 1 

	gen sample_b = 0 //below
	replace sample_b = 1 if rank_score_raw_`cell'<cutoff_rank_`cell'

	gen sample_b5 = 0
	replace sample_b5 = 1 if rank_score_raw_`cell'<cutoff_rank_`cell' & score_relative>-0.5

	gen sample_b2 = 0
	replace sample_b2 = 1 if rank_score_raw_`cell'<cutoff_rank_`cell' & score_relative>-0.2
	
	
	//binsreg enrolled score_relative if public==1 & abs(score_relative)<2


	//binsreg enrolled score_relative if public==1 & abs(score_relative)<4
	//binsreg one_app score_relative if public==1 & abs(score_relative)<4
	//binsreg no_pri_app score_relative if public==1 & abs(score_relative)<4
	
	
	tab enrolled if one_app==1 & sample_b==1 & public==1
	//How are they enrolled if 'not admitted' and 'didn't reapplied'?
	preserve
		keep if one_app==1 & sample_b==1 & enrolled==1 & public==1
		keep id_per_umc
		tempfile one_app_rej_enrolled
		save `one_app_rej_enrolled', replace
		
		use "$TEMP\enrolled.dta", clear	
		tab semester_admitted if inlist(id_per_umc,607432,615680,617446,617797,619018,619381)==1
	restore
	
	
	tab enrolled if one_app==1 & sample_b==1
	//How are they enrolled if 'not admitted' and 'didn't reapplied'?	
	
	rename enrolled enr
	rename one_app one
	rename no_priv npr
	


local out = "enr"
local sample = "_b5"
			count
			local N`sample' = r(N)

			global covar1 "male_siagie i.educ_mother i.region_siagie i.urban_siagie i.public_siagie min_dist_uni avg_enrolled_public avg_enrolled_private"
			logit `out' ${covar1} if sample`sample'==1			
			local s1`sample' =  e(N) 
			predict rej_`out'`sample'_lpred1

			global covar2 "score_math_std_2p score_com_std_2p"
			logit `out' ${covar1} ${covar2} if sample`sample'==1		
			local s2`sample' =  e(N) 
			predict rej_`out'`sample'_lpred2

			global covar3 "score_math_std_2s score_com_std_2s socioec_index_2s"
			logit `out' ${covar1} ${covar3} if sample`sample'==1			
			local s3`sample' =  e(N) 
			predict rej_`out'`sample'_lpred3

			di as text  _n "Sample 1:" %9.1f `s1`sample''*100/`N`sample'' ///
						_n "Sample 2:" %9.1f `s2`sample''*100/`N`sample'' ///
						_n "Sample 3:" %9.1f `s3`sample''*100/`N`sample''
				
			//Set median cutoffs
			sum	rej_`out'`sample'_lpred1, de
			gen rej_`out'`sample'_lpred1_above = (rej_`out'`sample'_lpred1>r(p50) & rej_`out'`sample'_lpred1!=.)
			sum	rej_`out'`sample'_lpred2, de
			gen rej_`out'`sample'_lpred2_above = (rej_`out'`sample'_lpred2>r(p50) & rej_`out'`sample'_lpred2!=.)
			sum	rej_`out'`sample'_lpred3, de
			gen rej_`out'`sample'_lpred3_above = (rej_`out'`sample'_lpred3>r(p50) & rej_`out'`sample'_lpred3!=.)

	compress

binsreg enr score_relative if public==1 & abs(score_relative)<2 
binsreg enr score_relative if public==1 & abs(score_relative)<2 & rej_enr_b5_lpred3<0.6

binsreg enr score_relative if public==1 & abs(score_relative)<2 & rej_enr_b5_lpred3_above==1
binsreg enr score_relative if public==1 & abs(score_relative)<.5 & rej_enr_b5_lpred3_above==0





bys rej_enr_b5_lpred3_above: sum rej_enr_b5_lpred3
	
	
	
	
	
	
	keep id_per_umc rej_*_*_lpred? rej_*_*_lpred?_above
	
	bys id_per_umc: keep if _n==1 //Based on demographics unrelated to application
	
	