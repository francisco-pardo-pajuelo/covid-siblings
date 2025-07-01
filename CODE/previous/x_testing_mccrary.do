local cell major
local type noz

global window = 4 


*- Histogram of scores and cutoffs
	use "$TEMP/applied_matched.dta", clear
	
	rename *_`cell' *
	rename *_`type' * 
	
	
	*- Exclude those without estimated cutoffs
	keep if lottery_nocutoff == 0

	*- Exclude those at cutoff
	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)	
	
	gen score_relative = score_std - cutoff_std
	drop if score_relative==.
	
	
	histogram score_relative if not_at_cutoff==1 & public==1 & abs(score_relative)<$window
	
	rddensity score_relative if not_at_cutoff==1 & public==1 & abs(score_relative)<$window, plot
	binsreg admitted score_relative if not_at_cutoff==1 & public==1 & abs(score_relative)<$window
	
	
	use "$TEMP/applied.dta", clear 
	
	//keep if id_cutoff>1785  //test
	
	*- Attach cutoff information (department)
		merge m:1 id_cutoff_department using  "$TEMP/applied_cutoffs_department.dta"
		gen lottery_nocutoff_department = (cutoff_std_department==.)
		drop _merge
		
	*- Attach cutoff information (major)
		merge m:1 id_cutoff_major using  "$TEMP/applied_cutoffs_major.dta"
		gen lottery_nocutoff_major = (cutoff_std_major==.)
		drop _merge		
	