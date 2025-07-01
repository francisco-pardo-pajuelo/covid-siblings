/********************************************************************************
- Author: Francisco Pardo
- Description: it estimates the score cutoffs of the potential university application cutoffs
- Date started: 08/12/2024
- Last update: 08/12/2024

- File based on Bütikofer, et al. 2023 EJ replication files from 'cutoff_simulation_literature\Bütikofer, et al. 2023 EJ\3 replication package\replication_ej\cutoffs.do' but adapted to my own needs 
Main Changes to original dofile:
	1. I believe there was a mistake with the condition 'if `e(rank)' >= 1' since some 'perfect/sharp cutoffs', which estimated a coefficient of 1, had no S.E. and Rank=0. (some, not all, seems like an issue of chance and precision of floating points). I have changed this condition to 'if (`e(rank)' >= 1 | (`e(rank)' == 0 & _b[above_]>0.5))'. Why '_b[above_]>0.5' and not '_b[above_]==1', since a rank of 0 would be only when 'b=1 or b=-1'? This because sometimes by floating point precision, the 'b=1' would fail if b is actually stored as something like 
e.g. '1.000000001'. To avoid this issue I do 0.5 (it could be also'_b[above_]>0.99', it doesn't matter.)
	
	2. No need to open full database in every simulation. Created reduced `applied_for_simulation'. This is important if you have many more loops in data.
	3. Avoid saving variables in wide format database. Instead, save them already in long and avoid reshape
	4. Added more stats (N_below, N_above, etc.)
	
	
- Reglamentos licencia universidad: https://www.sunedu.gob.pe/universidades-publicas/	
	
*******************************************************************************/

capture program drop main 
program define main 


setup_A02



*- When considering the college-major as a cell (all admission types in one cell)
score_cutoff major_full

*- When considering the college-department as a cell
score_cutoff deprt_full

*- When considering the college-major as a cell
score_cutoff major

*- When considering the college-department as a cell
score_cutoff deprt


//review_cutoff_methods department

end


********************************************************************************
* Setup
********************************************************************************

capture program drop setup_A02
program define setup_A02

	set seed 1234
	global test = 0
	
	timer clear 10
	timer clear 11
	timer clear 12
	timer clear 13
	timer clear 14
	timer clear 15
	timer clear 16
	timer clear 17
	
	if ${test} == 0 global data = ""
	if ${test} == 1 global data = "_TEST"	

end



********************************************************************************
* score_cutoff
* 
* Description: loop to estimate all the cutoffs and saved them in a new dataset
********************************************************************************

capture program drop score_cutoff
program define score_cutoff
	args cell // (1) level (2) score //id_cutoff_department/score_raw_


	cap log close
	
	log using "$LOGS/score_cutoff_`cell'.log", text replace
		
	clear 
	gen 		id_cutoff = .
	*- Statistics following restrictions of them being coef>0, pval<0.01, etc.
	
	gen double  cutoff_rank = .
	//gen double 	cutoff_raw = .
	//gen double 	cutoff_std = .
	gen double 	coeff = .
	gen double 	p_val = .
	gen double 	R2 = .
	gen double 	N_below = .
	gen double 	N_above = .
	gen int		has_cutoff = .	
	
	*- Statistics only requiring max R2
	gen double  cutoff_rank_all = .
	//gen double 	cutoff_raw_all = .
	//gen double 	cutoff_std_all = .
	gen double 	coeff_all = .
	gen double 	p_val_all = .
	gen double 	R2_all = .
	gen double 	N_below_all = .
	gen double 	N_above_all = .
	gen int		has_cutoff_all = .	
	
	save "$TEMP\applied_cutoffs_`cell'${data}.dta", replace emptyok
	
	
	*Now create a loop to have all the cutoffs from all the loteries 
	
	use "$TEMP\applied.dta", clear
	
	if $test == 1 {
		bys id_cutoff_`cell': egen u = max(cond(_n==1,runiform(),.))
		egen u_rank = group(u)
		keep if u_rank<20
	}
	
	//local cell "major"
	if inlist("`cell'","deprt","deprt_full")==1  {
		keep 	codigo_modular semester type_admission facultad source ///
				id_cutoff_`cell' 	rank_score_raw_`cell' 	score_raw score_std_`cell' 	admitted 
		rename 	(id_cutoff_`cell' 	rank_score_raw_`cell' 	score_raw score_std_`cell' 	admitted) ///
				(id_cutoff 			rank_score_raw 				score_raw score_std 			admitted)
		}
	if inlist("`cell'","major","major_full")==1  {
		keep 	codigo_modular semester type_admission facultad major_c1_code source ///
				id_cutoff_`cell' rank_score_raw_`cell' score_raw score_std_`cell' admitted 
		rename 	(id_cutoff_`cell' 	rank_score_raw_`cell' 	score_raw score_std_`cell' 	admitted) ///
				(id_cutoff 			rank_score_raw 			score_raw score_std 		admitted)
		}
	

	*- We save id_cutoff information
	preserve
		bys id_cutoff: keep if _n==1
		isvar id_cutoff codigo_modular semester type_admission facultad major_c1_code source 
		keep `r(varlist)'
		save "$TEMP\id_cutoff_info_`cell'", replace
	restore
	
	*- We save the rank-score correspondence
	preserve
		bys id_cutoff rank_score_raw: keep if _n==1
		rename (rank_score_raw score_raw score_std) (cutoff_rank cutoff_raw cutoff_std)
		isvar id_cutoff cutoff_rank cutoff_raw cutoff_std
		keep `r(varlist)'
		save "$TEMP\rank_score_correspondence", replace
		rename (cutoff_rank cutoff_raw cutoff_std) (cutoff_rank_all cutoff_raw_all cutoff_std_all)
		save "$TEMP\rank_score_correspondence_all", replace
	restore
	
	*- We exclude cutoffs with no score or no variation
	bys id_cutoff: egen has_score_below 	= max(cond(admitted==0 & score_raw!=.,1,0))
	bys id_cutoff: egen has_score_above 	= max(cond(admitted==1 & score_raw!=.,1,0))
	bys id_cutoff: egen sd_score 	= sd(rank_score_raw)
	bys id_cutoff: egen sd_admitted = sd(admitted)
		
	drop codigo_modular semester type_admission facultad source score_raw score_std
	capture drop major_c1_code
		
	preserve
		keep if sd_score==0 | sd_score==. | sd_admitted==0 | sd_admitted==. | has_score_below==0 | has_score_above==0
		bys id_cutoff: keep if _n==1
		drop admitted
		drop sd_score sd_admitted
		
		gen int		has_cutoff = 0	
		gen int		has_cutoff_all = 0
		//other variables are missing
	
		append using "$TEMP\applied_cutoffs_`cell'${data}.dta"
		
		save "$TEMP\applied_cutoffs_`cell'${data}.dta", replace emptyok
	restore

	drop if sd_score==0 | sd_score==. | sd_admitted==0 | sd_admitted==. | has_score_below==0 | has_score_above==0
	drop sd_score
	
	*- We only look within relevant scores
	gen relevant_scores = 0

	*-- 1. Just before first admitted and just after last non-admitted)
	bys id_cutoff: egen first_1 	=  min(cond(admitted==1,rank_score_raw,.))
	bys id_cutoff: egen last_0 	=  max(cond(admitted==0,rank_score_raw,.))

	bys id_cutoff: egen lower_bound = max(cond(rank_score_raw<first_1,rank_score_raw,.))
	bys id_cutoff: egen upper_bound = min(cond(rank_score_raw>last_0,rank_score_raw,.))

	bys id_cutoff (rank_score_raw): replace lower_bound = first_1 	if first_1==rank_score_raw[1]
	bys id_cutoff (rank_score_raw): replace upper_bound = last_0 	if last_0==rank_score_raw[_N]

	replace relevant_scores = 1 if (rank_score_raw>=lower_bound & rank_score_raw<=upper_bound) & rank_score_raw!=.
	capture drop first_1 last_0 lower_bound upper_bound
	
	*-- 2. A score with 0% admitted will not be a cutoff.
	bys id_cutoff rank_score_raw: egen max_admitted = max(admitted)
	replace relevant_scores = 0 if max_admitted==0
	drop max_admitted
	
	*-- 3. A score after 100% admitted will not be a cutoff. If it was, the previous score would be better.
	bys id_cutoff rank_score_raw: egen min_admitted = min(admitted)
	preserve
		bys id_cutoff rank_score_raw: keep if _n==1
		bys id_cutoff (rank_score_raw): gen min_admitted_prev = min_admitted[_n-1]
		tempfile min_admitted_prev 
		save `min_admitted_prev', replace
	restore
	
	merge m:1 id_cutoff rank_score_raw using `min_admitted_prev', keep(master match) keepusing(min_admitted_prev) nogen
	replace relevant_scores = 0 if min_admitted_prev==1
	drop min_admitted_prev
	
	
	
	//if $test == 1 keep if id_cutoff==3002  //test
	
	//Divide data in 3 for speeding purposes
	sum id_cutoff, de
	local p25 = r(p25)
	local p50 = r(p50)
	local p75 = r(p75)
	
	sort id_cutoff
	
	compress
	
	preserve
		keep if id_cutoff<`p25'
		save "$TEMP\applied_for_simulation1", replace
	restore
		
	preserve
		keep if id_cutoff>= `p25' & id_cutoff<`p50'
		save "$TEMP\applied_for_simulation2", replace
	restore
	
	preserve
		keep if id_cutoff>= `p50' & id_cutoff<`p75'
		save "$TEMP\applied_for_simulation3", replace
	restore

	preserve
		keep if id_cutoff>=`p75'
		save "$TEMP\applied_for_simulation4", replace
	restore
	
	*Gen a dataset to save the cutoffs
	keep id_cutoff
	duplicates drop id_cutoff, force
	
	levelsof id_cutoff, local(levels)
	
	local cont=1
	foreach l of local levels {
		
		di as text "CURRENT CUTOFF IS `l'"
		
		if `l' == `p25' local cont = 2
		if `l' == `p50' local cont = 3
		if `l' == `p75' local cont = 4
		
		timer on 10
		use if id_cutoff==`l' using "$TEMP\applied_for_simulation`cont'", clear
		timer off 10
		
		//keep if id_cutoff>1785  //test
		timer on 11
		//keep if id_cutoff==`l'
		
		//generate rank of running variable. This is important because 'levelsof' works better with integer variables. With floats, you may not be able to properly do logical comparisons (e.g. '>' or '<'). Ultimately, this will only be used to define the 'above' variable correctly and then the regression will use the actual scores, not the rank. This is why rank + track is used.
		//egen rank_score_raw = rank(score_raw), track
		
		//sum rank_score_raw	
		levelsof rank_score_raw if /*rank_score_raw != `r(min)' & rank_score_raw != `r(max)' &*/ relevant_scores==1, c
		local score `r(levels)'
		timer off 11
		
		//Generate a dummy variable fore each rank, thta takes value one if the lottery num is equal or greater to the ranked
		timer on  12 
		foreach val in `score' {
			gen above_`val' = rank_score_raw >= `val' if !missing(rank_score_raw)
			}
		timer off 12
	
		timer on 13
			gen double 	cutoff_rank = .
			//gen double 	cutoff_raw = .
			//gen double 	cutoff_std = .
			gen double 	coeff = .
			gen double 	p_val = .
			gen double 	R2 = .
			gen double 	N_below = .
			gen double 	N_above = .
			gen int		has_cutoff = 1
					
			gen double  cutoff_rank_all = .
			//gen double 	cutoff_raw_all = .
			//gen double 	cutoff_std_all = .
			gen double 	coeff_all = .
			gen double 	p_val_all = .
			gen double 	R2_all = .
			gen double 	N_below_all = .
			gen double 	N_above_all = .
			gen int		has_cutoff_all = 1
			
			local R2 		0
			local R2_all 	0
		timer off 13
	*Regress the dummy for offer against each of the dummies and keep the cutoff with the largest R2 where the beta is positive and significant at the 1% level 
	timer on 14
	foreach val in `score' {
		reg admitted above_`val', robust
		local reg_R2 = `e(r2)' 
		di "`e(r2)'"
		if (`e(rank)' >= 1 | (`e(rank)' == 0 & _b[above_]>0.5))  { //since the estimated coefficient is a float, we cannot do '==1' or simply '>0', since a float '0' could be '0.000001'. So just in case we do '0.5' which added to rank being 0, means coefficient is 1.
			
			*- Save statistics with restriction
			if (`reg_R2' > `R2') & (_b[above_] > 0) & (((2*ttail(e(df_r), abs(_b[above_]/_se[above_])))<=0.01) | ((2*ttail(e(df_r), abs(_b[above_]/_se[above_])))==.))  { //Either significant at 1% level or pvalue missing (which in this case based on previous filter would be a coefficient of 1 with 100% accuracy.)
				replace cutoff_rank = `val'
				replace coeff = _b[above_]
				replace p_val = (2*ttail(e(df_r), abs(_b[above_]/_se[above_])))
				count if above_`val'==0
				replace N_below = r(N)
				count if above_`val'==1
				replace N_above = r(N)
				replace R2 = `reg_R2'
				local R2 `reg_R2'
				}
			
			*- Save statistics without restriction  //remove
			if (`reg_R2' > `R2_all') {
				replace cutoff_rank_all = `val'
				replace coeff_all = _b[above_]
				replace p_val_all = (2*ttail(e(df_r), abs(_b[above_]/_se[above_])))
				count if above_`val'==0
				replace N_below_all = r(N)
				count if above_`val'==1
				replace N_above_all = r(N)
				replace R2_all = `reg_R2'
				local R2_all `reg_R2'
				}	
			}		
		}
	 timer off 14
	
	timer on 15
	*Summarize the estimated cutoff_rank
	
	sum cutoff_rank
	local min `r(min)'
	local N = `r(N)'
	
	sum cutoff_rank_all 		//remove
	local min_all `r(min)'	 	//remove
	local N_all = `r(N)'
	
	*If the obs are more than zero, means it was estimated so we keep it and store the corresponding lottery number
		/*
		local min_raw = .
		local min_std = .
		local min_raw_all = .
		local min_std_all = . 
		local has_cutoff = 1
		local has_cutoff_all = 1
	*/
		timer off 15
	
	timer on 16

	keep if _n==1
	keep id_cutoff cutoff_rank coeff p_val R2 N_below N_above has_cutoff cutoff_rank_all coeff_all p_val_all R2_all N_below_all N_above_all has_cutoff_all
	/*
	preserve
				use "$TEMP\applied_for_simulation`cont'", clear
				keep if id_cutoff==`l'
				//egen rank_score_raw = rank(score_raw), track
				
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
	*/
	timer off 16
	
	timer on 17
	/*
		replace cutoff_raw = `min_raw'
		replace cutoff_std = `min_std'
		replace has_cutoff = `has_cutoff'
		
		replace cutoff_raw_all = `min_raw_all'					//remove
		replace cutoff_std_all = `min_std_all'					//remove
		replace has_cutoff_all = `has_cutoff_all'				//remove
	*/	
		if `N' == 0 { 
			replace cutoff_rank = .
			//replace cutoff_raw = .
			//replace cutoff_std = .
			replace coeff = .
			replace p_val = .
			replace N_below = .
			replace N_above = .
			replace R2 = .
			replace has_cutoff = 0	
			}
			
		if `N_all'==0 {
			replace cutoff_rank_all = .
			//replace cutoff_raw_all = .
			//replace cutoff_std_all = .
			replace coeff_all = .
			replace p_val_all = .
			replace N_below_all = .
			replace N_above_all = .
			replace R2_all = .
			replace has_cutoff_all = 0	
			}			
		
		keep if _n==1
		append using  "$TEMP\applied_cutoffs_`cell'${data}.dta"
		save  "$TEMP\applied_cutoffs_`cell'${data}.dta", replace		
				
		if mod(`l',60)==10 {
			use "$TEMP\applied_cutoffs_`cell'${data}.dta", clear
			save "$TEMP\applied_cutoffs_`cell'${data}_TEMP.dta", replace //every 60 starting at 5.	
			}

				
	timer off 17

	}
	log close
	
	close
	
	merge 1:1 id_cutoff using 					"$TEMP\id_cutoff_info_`cell'", keep(match) nogen
	merge 1:1 id_cutoff cutoff_rank using 		"$TEMP\rank_score_correspondence", keep(master match) keepusing(cutoff_raw cutoff_std) nogen
	merge 1:1 id_cutoff cutoff_rank_all using 	"$TEMP\rank_score_correspondence_all", keep(master match) keepusing(cutoff_raw_all cutoff_std_all) nogen
	
	//use "$TEMP/applied_cutoffs_`cell'${data}.dta", clear
	
	sort id_cutoff
	
	isvar codigo_modular semester type_admission facultad major_c1_code source id_cutoff cutoff_rank cutoff_raw cutoff_std coeff p_val R2 N_below N_above has_cutoff /*without restrictions*/ cutoff_rank_all cutoff_raw_all cutoff_std_all coeff_all p_val_all R2_all N_below_all N_above_all has_cutoff_all
	local all_vars = r(varlist)
	keep `all_vars'
	order `all_vars'	
	
	label var codigo_modular 			"College ID"
	label var semester 					"Semester"
	label var type_admission 			"Admission type: exam, academy, transfer, etc."
	label var facultad 					"Department"
	capture label var major_c1_code 	"Major"
	label var source					"Potential different sources of exam within major-admission_type"
	

	label var has_cutoff 	"Has a valid cutoff (both admitted and non admitted students)"
	label var cutoff_raw 	"Cutoff score based on raw score"
	label var cutoff_std 	"Cutoff score based on standardized score"
	label var cutoff_rank 	"Cutoff score based on rank (rank #1 = highest score)"
	label var coeff 		"Coefficient testing cutoff 'admitted ~ above(cutoff)"
	label var p_val 		"pvalue testing cutoff 'admitted ~ above(cutoff)"
	label var N_below 		"Observations below cutoff"
	label var N_above		"Observations above cutoff (included)"
	label var R2			"R2 testing cutoff 'admitted ~ above(cutoff)"
	
	label var has_cutoff_all 	"Has a valid cutoff (both admitted and non admitted students) - without restrictions"
	label var cutoff_raw_all 	"Cutoff score based on raw score - without restrictions"
	label var cutoff_std_all 	"Cutoff score based on standardized score - without restrictions"
	label var cutoff_rank_all 	"Cutoff score based on rank (rank #1 = highest score) - without restrictions"
	label var coeff_all 		"Coefficient testing cutoff 'admitted ~ above(cutoff) - without restrictions"
	label var p_val_all 		"pvalue testing cutoff 'admitted ~ above(cutoff) - without restrictions"
	label var N_below_all		"Observations below cutoff - without restrictions"
	label var N_above_all		"Observations above cutoff (included) - without restrictions"
	label var R2_all			"R2 testing cutoff 'admitted ~ above(cutoff) - without restrictions"	
	
	rename * *_`cell'

	if inlist("`cell'","major","major_full")==1   	rename (codigo_modular_`cell' semester_`cell' type_admission_`cell' facultad_`cell' major_c1_code_`cell' 	source_`cell') (codigo_modular semester type_admission facultad major_c1_code 	source)
	if inlist("`cell'","deprt","deprt_full")==1  rename (codigo_modular_`cell' semester_`cell' type_admission_`cell' facultad_`cell'  						source_`cell') (codigo_modular semester type_admission facultad  				source)
	
	compress

		
	save "$TEMP/applied_cutoffs_`cell'${data}.dta", replace

	/*
	erase "$TEMP\applied_for_simulation1.dta"
	erase "$TEMP\applied_for_simulation2.dta"
	erase "$TEMP\applied_for_simulation3.dta"
	erase "$TEMP\applied_for_simulation4.dta"
	erase "$TEMP\id_cutoff_info_`cell'.dta"
	erase "$TEMP\rank_score_correspondence.dta"
	erase "$TEMP\rank_score_correspondence_all.dta"
	*/
	
end




********************************************************************************
* review_cutoff_methods
* 
* Description: loop to estimate the mccrary test for every cutoff
********************************************************************************

capture program drop review_cutoff_methods
program define review_cutoff_methods
	
	args cell
	
	set seed 1234

	cap log close
		
	log using "$LOGS/review_cutoff_methods_`cell'.log", text replace
	
	use "$TEMP/applied_cutoffs_`cell'.dta", clear
	
	rename *_`cell' *
	
	list id_cutoff cutoff_rank cutoff_raw  coeff p_val R2 cutoff_rank_all cutoff_raw_all coeff_all p_val_all R2_all if p_val>0.009 & p_val!=.
	
	keep if has_cutoff==1 & has_cutoff_all==1
	keep if cutoff_rank!=cutoff_rank_all
	scatter coeff coeff_all

	preserve
		keep  if coeff_all<0
		sample 3,count
		list id_cutoff cutoff_rank cutoff_raw  coeff p_val R2 cutoff_rank_all cutoff_raw_all coeff_all p_val_all R2_all
	restore
	
	preserve
		keep  if coeff_all>0
		sample 3,count
		list id_cutoff cutoff_rank cutoff_raw  coeff p_val R2 cutoff_rank_all cutoff_raw_all coeff_all p_val_all R2_all
	restore

	preserve
		keep   if R2_all>0.9
		sample 3,count
		list id_cutoff cutoff_rank cutoff_raw  coeff p_val R2 cutoff_rank_all cutoff_raw_all coeff_all p_val_all R2_all
	restore
	


	use "$TEMP/applied.dta", clear
	
/*
     +-------------------------------------------------------------------------------------------------------------------------------+
     | id_cut~f   cutoff~k   cutoff~w       coeff       p_val          R2   cu~k_all   cu~w_all    coeff_all   p_val_all      R2_all |
     |-------------------------------------------------------------------------------------------------------------------------------|
  1. |     7367         24         34   .39327296   2.995e-86   .01838471        250         65   -.25074338   2.955e-11   .05725414 |
  2. |     7730        438         64   .03203661   .00015989   .01096121        389       2.77   -.05204461   .00013652   .03140483 |
  3. |     6082       1481      866.5   .48716216   7.986e-08   .01436407        861        496   -.21359012   5.476e-20   .05134279 |
     +-------------------------------------------------------------------------------------------------------------------------------+
*/
	
	if "`cell'" == "deprt" {
		rename id_cutoff_`cell' id_cutoff
		*- unrestricted is negative
		scatter admitted score_raw if id_cutoff==6082, xline(866.5, lcolor(blue)) xline(496, lcolor(red))
		scatter admitted score_raw if id_cutoff==7730, xline(64, lcolor(blue)) xline(2.77, lcolor(red))
		scatter admitted score_raw if id_cutoff==7367, xline(34, lcolor(blue)) xline(65, lcolor(red))
		
		scatter admitted score_raw if id_cutoff==8213, xline(77, lcolor(blue)) xline(42, lcolor(red))
		scatter admitted score_raw if id_cutoff==6640, xline(6, lcolor(blue)) xline(62, lcolor(red))
		
		/*
		 +------------------------------------------------------------------------------------------------------------------------------+
		 | id_cut~f   cutoff~k   cutoff~w       coeff       p_val          R2   cu~k_all   cu~w_all   coeff_all   p_val_all      R2_all |
		 |------------------------------------------------------------------------------------------------------------------------------|
	  1. |     5833        146     1303.5   .09655172   .00013535   .01050903         26      11.01   .13382353   .11018648   .02958683 |
	  2. |     5831        196      16.01   .10769231   2.615e-06   .01159763         10       9.29   .24637681   .12293755   .02761586 |
	  3. |     3002          2        143   .88235294   1.142e-08   .29411765          6      206.5          .6   .02006086         .52 |
		 +------------------------------------------------------------------------------------------------------------------------------+
		*/
		
		*- Both positive but unrestricted not significant
		scatter admitted score_raw if id_cutoff==3002, xline(143, lcolor(blue)) xline(206.5 , lcolor(red))
		scatter admitted score_raw if id_cutoff==5831, xline(16.01, lcolor(blue)) xline(9.29, lcolor(red))	
		scatter admitted score_raw if id_cutoff==5833, xline(1303.5, lcolor(blue)) xline(11.01, lcolor(red))	
		//All 3 cases look strange. Either 1 observation below or seem like 2 different score scales 
		
		
		/*
		 +-------------------------------------------------------------------------------------------------------------------------------+
		 | id_cut~f   cutoff~k   cutoff~w       coeff       p_val          R2   cu~k_all   cu~w_all    coeff_all   p_val_all      R2_all |
		 |-------------------------------------------------------------------------------------------------------------------------------|
	211. |     6890          3         22         .25   1.610e-11   .00409836         43         60   -.95238095   3.379e-65   .93676815 |
	213. |     6892          2         23   .10566038   6.133e-08   .00044395         30         60   -.96551724   3.392e-82   .96146045 |
		 +-------------------------------------------------------------------------------------------------------------------------------+
		*/	
		
		*-  Unrestricted has high R2
		scatter admitted score_raw if id_cutoff==6890, xline(22, lcolor(blue)) xline(60 , lcolor(red))
		scatter admitted score_raw if id_cutoff==6892, xline(23, lcolor(blue)) xline(60, lcolor(red))		
		//Conclussion: Seems like these are 2 cutoffs or an inverted score. It found rank 2 as the cutoff because that leaves 1 "No" and then a mix above which makes it significant
		
		** Overall: All cases seem like not good cutoffs. Better to exclude them from analysis unless more refined cells avoid this issue (type of evaluation.)
	}
	
end

********************************************************************************
* Run program
********************************************************************************

main

