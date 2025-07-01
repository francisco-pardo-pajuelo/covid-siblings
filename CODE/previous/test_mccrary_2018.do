
	*- Histogram of scores and cutoffs
	use "$TEMP/applied_matched.dta", clear
	
	keep if lottery_nocutoff == 0
	
	gen score_relative = score_std - cutoff_std
	
	//bys id_cutoff: egen rank_score_raw = rank(score_raw), track
	gen at_cutoff = rank_score_raw==cutoff_rank
		
	*- Only valid cutoffs
	gen valid_cutoff 		= (mccrary_pval_def>0.1 & mccrary_pval_biasi>0.1 & mccrary_test==1)
	
	*- Only valid cutoffs
	gen consistent_cutoff 		= (cutoff_rank == cutoff_rank_all)
	
	*- Cutoffs that come from only one source?
	bys id_cutoff: egen score_std_max = max(abs(score_std))
	gen one_source_cutoff = (score_std_max<5) //approx
	
	*- Sample to use
	gen sample = (at_cutoff!=1 & valid_cutoff==1 & consistent_cutoff==1 & one_source_cutoff==1)
	
	
	*-ABOVE 
	gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=.
	
	*- Observations above and below
	bys id_cutoff ABOVE: gen N=_N
	bys id_cutoff: egen min_N = min(N)
	
	global y = 2018

	histogram score_relative ///
	if abs(score_relative)<5 & year==$y ///
	& at_cutoff!=1  ///
	& valid_cutoff==1 ///
	,  ///
	fcolor(gs14) lcolor(gs0) xline(0) title("`y'")	 
	
	histogram score_relative ///
	if abs(score_relative)<5 & year==$y  ///
	& at_cutoff!=1  ///
	& valid_cutoff==1 ///
	& consistent_cutoff==1 ///
	,  ///
	fcolor(gs14) lcolor(gs0) xline(0) title("`y'")	
	
	histogram score_relative ///
	if abs(score_relative)<5 & year==$y  ///
	& at_cutoff!=1  ///
	& valid_cutoff==1 ///
	& consistent_cutoff==1 ///
	& min_N>5 ///
	,  ///
	fcolor(gs14) lcolor(gs0) xline(0) title("`y'")	
	
	
	histogram score_relative ///
	if abs(score_relative)<5 & year==$y  ///
	& at_cutoff!=1  ///
	& valid_cutoff==1 ///
	& consistent_cutoff==1 ///
	& one_source_cutoff==1 ///
	& min_N>5 ///
	,  ///
	fcolor(gs14) lcolor(gs0) xline(0) title("`y'")	
	
	rddensity score_relative ///
	if abs(score_relative)<5 ///
	& year==$y ///
	& at_cutoff!=1 ///
	& valid_cutoff==1 ///
	& consistent_cutoff==1 ///
	& one_source_cutoff==1 ///
	& min_N>5 ///
	, ///
	plot
	

		*- Run the RD regression
		//gen ABOVE = (score_relative >= 0) if score_relative!=.
		
		forvalues p = 1/5 {
			gen score_relative_`p' 			= score_relative^`p'
			gen ABOVE_score_relative_`p' 	= ABOVE*score_relative_`p'
		}
		
		global scores_5 		= "score_relative_1 		score_relative_2 		score_relative_3 		score_relative_4 		score_relative_5"
		global ABOVE_scores_5 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2 	ABOVE_score_relative_3 	ABOVE_score_relative_4 	ABOVE_score_relative_5"
		global window 1
			
	
	reghdfe age 					///
				ABOVE ${scores_5} ${ABOVE_scores_5} ///
				if abs(score_relative)<$window ///
				& sample==1 ///
				, a(id_cutoff)
	
	gen sample_reg = e(sample)
	/*
	rddensity score_relative ///
	if e(sample)==1 ///
	, ///
	plot
	*/