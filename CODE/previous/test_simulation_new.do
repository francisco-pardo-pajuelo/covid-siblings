/********************************************************************************
- Author: Francisco Pardo
- Description: it estimates the score cutoffs of the potential university application cutoffs
- Date started: 08/12/2024
- Last update: 08/12/2024

- Changes to original dofile:
	1. No need to open full database in every simulation. Created reduced `applied_for_simulation'
	2. Avoid saving variables in wide format database. Instead, save them already in long and avoide reshape
*******************************************************************************/

capture program drop main 
program define main 


score_cutoff
	
end


********************************************************************************
* Test enrollment 
* 
* Description: 
********************************************************************************

capture program drop enrollment_validation
program define enrollment_validation


	use "$TEMP\enrolled", clear
	**## Imperfect solution. We need to figure out what makes enrollments unique.
	bys universidad id_anio abreviatura_anio id_periodo_matricula id_persona_reco: keep if _n==1

	rename id_periodo_matricula id_periodo_postulacion
	tempfile enrolled_unique
	save `enrolled_unique', replace


	use "$TEMP\applied", clear

	merge m:1  universidad id_anio abreviatura_anio id_periodo_postulacion id_persona_reco using `enrolled_unique', keep(master match)


end



********************************************************************************
* score_cutoff
* 
* Description: loop to estimate all the cutoffs and saved them in a new dataset
********************************************************************************

capture program drop score_cutoff
program define score_cutoff

	cap log close
	
	log using "$LOGS/score_cutoff.log", text replace
	
	*Now create a loop to have all the cutoffs from all the loteries 
	
	use "$TEMP/applied.dta", clear
	
	bys id_cutoff: egen has_score = count(score_raw)
	drop if has_score==0
	drop has_score
	
	keep id_cutoff score_raw score_std admitted
	
	//keep if id_cutoff==1038  //test
	
	tempfile applied_for_simulation
	save `applied_for_simulation'
	
	
	
	*Gen a dataset to save the cutoffs
	keep id_cutoff
	duplicates drop id_cutoff, force
	
	levelsof id_cutoff, local(levels)
	
	clear 
	gen id_cutoff = .
	*- Statistics following restrictions of them being coef>0, pval<0.01, etc.
	gen double  cutoff_rank = .
	gen double 	cutoff_raw = .
	gen double 	cutoff_std = .
	gen double 	coeff = .
	gen double 	p_val = .
	gen double 	R2 = .
	gen int		has_cutoff = .	
	
	*- Statistics only requiring max R2
	gen double  cutoff_rank_all = .
	gen double 	cutoff_raw_all = .
	gen double 	cutoff_std_all = .
	gen double 	coeff_all = .
	gen double 	p_val_all = .
	gen double 	R2_all = .
	gen int		has_cutoff_all = .	
	
	save "$TEMP/applied_cutoffs.dta", replace emptyok
	
	foreach l of local levels {
		
		use `applied_for_simulation', clear
		
		//keep if id_cutoff>1785  //test
	
		keep if id_cutoff==`l'
		
		//generate rank of running variable. This is important because 'levelsof' works better with integer variables. With floats, you may not be able to properly do logical comparisons (e.g. '>' or '<'). Ultimately, this will only be used to define the 'above' variable correctly and then the regression will use the actual scores, not the rank. This is why rank + track is used.
		egen rank_score_raw = rank(score_raw), track
		
		sum score_raw	
		levelsof rank_score_raw if score_raw != `r(min)' & score_raw != `r(max)', c
		local score `r(levels)'
		
		//Generate a dummy variable fore each rank, thta takes value one if the lottery num is equal or greater to the ranked
		foreach val in `score' {
			gen above_`val' = rank_score_raw >= `val' & !missing(rank_score_raw)
			}
	
			gen double cutoff_rank = .
			gen double 	cutoff_raw = .
			gen double 	cutoff_std = .
			gen double 	coeff = .
			gen double 	p_val = .
			gen double 	R2 = .
			gen int		has_cutoff = .
					
			gen double  cutoff_rank_all = .
			gen double 	cutoff_raw_all = .
			gen double 	cutoff_std_all = .
			gen double 	coeff_all = .
			gen double 	p_val_all = .
			gen double 	R2_all = .
			gen int		has_cutoff_all = .
			
			local R2 		0
			local R2_all 	0
	
	*Regress the dummy for offer against each of the dummies and keep the cutoff with the largest R2 where the beta is positive and significant at the 1% level 
	foreach val in `score' {
		reg admitted above_`val', robust
		local reg_R2 = `e(r2)' 
		di "`e(r2)'"
		if `e(rank)' >= 1 {
			
			*- Save statistics with restriction
			if (`reg_R2' > `R2') & (_b[above_] > 0) & ((2*ttail(e(df_r), abs(_b[above_]/_se[above_])))<=0.01) {
				replace cutoff_rank = `val'
				replace coeff = _b[above_]
				replace p_val = (2*ttail(e(df_r), abs(_b[above_]/_se[above_])))
				replace R2 = `reg_R2'
				local R2 `reg_R2'
				}
			
			*- Save statistics without restriction  //remove
			if (`reg_R2' > `R2_all') {
				replace cutoff_rank_all = `val'
				replace coeff_all = _b[above_]
				replace p_val_all = (2*ttail(e(df_r), abs(_b[above_]/_se[above_])))
				replace R2_all = `reg_R2'
				local R2_all `reg_R2'
				}	
			}		
		}	
	*Summarize the estimated cutoff_rank
	sum cutoff_rank
	local min `r(min)'
	local N = `r(N)'
	
	sum cutoff_rank_all 		//remove
	local min_all `r(min)'	 	//remove
	local N_all = `r(N)'

	*If the obs are more than zero, means it was estimated so we keep it and store the corresponding lottery number
		
		local min_raw = .
		local min_std = .
		local min_raw_all = .
		local min_std_all = . 
		local has_cutoff = 0
		
		preserve
				use `applied_for_simulation', clear
				keep if id_cutoff==`l'
				egen rank_score_raw = rank(score_raw), track
				
				if `N' > 0 {
					sum score_raw if rank_score_raw == `min'
					local min_raw = `r(min)'
					sum score_std if rank_score_raw == `min'
					local min_std = `r(min)'
					local has_cutoff = 1
					}
					
				if `N_all'>0 {
					sum score_raw if rank_score_raw == `min_all' 	//remove
					local min_raw_all = `r(min)'					//remove
					sum score_std if rank_score_raw == `min_all'	//remove
					local min_std_all = `r(min)'					//remove	
					local has_cutoff_all = 1 	
					}
		restore
		
		replace cutoff_raw = `min_raw'
		replace cutoff_std = `min_std'
		replace has_cutoff = `has_cutoff'
		
		replace cutoff_raw_all = `min_raw_all'					//remove
		replace cutoff_std_all = `min_std_all'					//remove
		replace has_cutoff_all = `has_cutoff_all'				//remove
		
		if `N' == 0 { 
			replace cutoff_rank = .
			replace cutoff_raw = .
			replace cutoff_std = .
			replace coeff = .
			replace p_val = .
			replace R2 = .
			replace has_cutoff = 0	
			}
			
		if `N_all'==0 {
			replace cutoff_rank_all = .
			replace cutoff_raw_all = .
			replace cutoff_std_all = .
			replace coeff_all = .
			replace p_val_all = .
			replace R2_all = .
			replace has_cutoff_all = 0	
			}			
		
		keep id_cutoff cutoff_rank cutoff_raw cutoff_std coeff p_val R2 has_cutoff /*without restrictions*/ cutoff_rank_all cutoff_raw_all cutoff_std_all coeff_all p_val_all R2_all has_cutoff_all
		keep if _n==1
		append using  "$TEMP/applied_cutoffs.dta"
		save  "$TEMP/applied_cutoffs.dta", replace		
				
	
	
	if mod(`l',60)==10 {
		use "$TEMP/applied_cutoffs.dta", clear
		save "$TEMP/applied_cutoffs_TEMP.dta", replace //every 60 starting at 5.	
		}
	
	}
	log close
	
	
	use "$TEMP/applied_cutoffs.dta", clear
	sort id_cutoff
	order id_cutoff has_cutoff cutoff_raw cutoff_std cutoff_rank coeff p_val R2 /*without restrictions*/ has_cutoff_all cutoff_raw_all cutoff_std_all cutoff_rank_all coeff_all p_val_all R2  
	
	label var has_cutoff 	"Has a valid cutoff (both admitted and non admitted students)"
	label var cutoff_raw 	"Cutoff score based on raw score"
	label var cutoff_std 	"Cutoff score based on standardized score"
	label var cutoff_rank 	"Cutoff score based on rank (rank #1 = highest score)"
	label var coeff 		"Coefficient testing cutoff 'admitted ~ above(cutoff)"
	label var p_val 		"pvalue testing cutoff 'admitted ~ above(cutoff)"
	label var R2			"R2 testing cutoff 'admitted ~ above(cutoff)"
	
	label var has_cutoff_all 	"Has a valid cutoff (both admitted and non admitted students) - without restrictions"
	label var cutoff_raw_all 	"Cutoff score based on raw score - without restrictions"
	label var cutoff_std_all 	"Cutoff score based on standardized score - without restrictions"
	label var cutoff_rank_all 	"Cutoff score based on rank (rank #1 = highest score) - without restrictions"
	label var coeff_all 		"Coefficient testing cutoff 'admitted ~ above(cutoff) - without restrictions"
	label var p_val_all 		"pvalue testing cutoff 'admitted ~ above(cutoff) - without restrictions"
	label var R2_all			"R2 testing cutoff 'admitted ~ above(cutoff) - without restrictions"	
	
	compress

	save "$TEMP/applied_cutoffs.dta", replace
	
	/*
	use "$TEMP/applied_cutoffs.dta", clear
	
	keep cutoff* coeff* p_val* R2* has_cutoff*
	duplicates drop

	gen id = _n
	reshape long cutoff_rank cutoff_raw cutoff_std coeff p_val R2 has_cutoff, i(id) j(id_cutoff)
	drop if cutoff_rank == .
	
	drop id
	sort id_cutoff

	save  "$TEMP/applied_cutoffs2.dta", replace	
	*/
	
	use "$TEMP/applied.dta", clear 
	
	//keep if id_cutoff>1785  //test
	
	merge m:1 id_cutoff using  "$TEMP/applied_cutoffs.dta"
			

	gen lottery_nocutoff = (_merge==1)
	drop _merge

	compress 
	
	save "$TEMP/applied_withCUTOFFS.dta", replace 


end


********************************************************************************
* Run program
********************************************************************************

main