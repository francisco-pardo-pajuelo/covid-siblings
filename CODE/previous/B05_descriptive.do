/********************************************************************************
- Author: Francisco Pardo
- Description: Descriptive statistics
- Date started: 08/28/2024
- Last update: 08/28/2024
*******************************************************************************/




capture program drop main 
program define main 

	descriptive major
	
end

********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup


end


******************************************************************************** 
* test
* 
* Description: 
********************************************************************************

capture program drop test
program define test


	*- Histogram of scores and cutoffs
	use "$TEMP/applied_matched.dta", clear
	
	
	*- Exclude those without estimated cutoffs
	keep if lottery_nocutoff == 0

	*- Exclude those at cutoff
	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)	
	
	*- Only valid cutoffs (pass McCrary test)
	**# Apparently there are some missings in mccrary_pval_def that are not being properly accounted for the 'mccrary_test' indicator.
	count if mccrary_pval_def == . & mccrary_test==1
	gen valid_flex_cutoff = ((mccrary_pval_def>0.1 & mccrary_pval_biasi>0.1) & (mccrary_test==1 & mccrary_pval_def!=. & mccrary_pval_biasi!=.))
	gen valid_strict_cutoff = ((mccrary_pval_def>0.1 | mccrary_pval_biasi>0.1) & (mccrary_test==1 & mccrary_pval_def!=. & mccrary_pval_biasi!=.))
	
	*- Only valid cutoffs
	gen consistent_cutoff 		= (cutoff_rank == cutoff_rank_all)
	
	*- Cutoffs that come from only one source?
	//This identifies one with big outliers (few observations with different scale)
	bys id_cutoff: egen score_std_max = max(abs(score_std))
	gen one_source_cutoff = (score_std_max<5) //approx
	
	//This aims to identify bimodal distributions. Not enough observations within 0.5sd of mean (Expected is ~40%)
	bys id_cutoff: egen N = count(score_std)
	bys id_cutoff: egen temp_N_half_sd = count(score_std) if abs(score_std)<0.5
	bys id_cutoff: egen N_half_sd = max(temp_N_half_sd)
	gen one_source_cutoff2 = (N_half_sd/N>0.2)
	/*
	histogram score_std if one<0.01
	histogram score_std if one>0.01 & one<0.025 & abs(score_std)<5
	histogram score_std if one>0.025 & one<0.05 & abs(score_std)<5
	histogram score_std if one>0.05 & one<0.1 & abs(score_std)<5
	histogram score_std if one>0.1 & one<0.2 & abs(score_std)<5
	histogram score_std if one>0.2 & one<0.3 & abs(score_std)<5
	histogram score_std if one>0.3 & one<0.35 & abs(score_std)<5
	histogram score_std if one>0.35 & one<0.4 & abs(score_std)<5
	drop N temp_N_half_sd N_half_sd
	*/
	
	*- Sample to use
	gen sample = (not_at_cutoff==1 & valid_flex_cutoff==1 & consistent_cutoff==1 & one_source_cutoff==1 & one_source_cutoff2==1)	
	
	
	gen pop = 1
	
	preserve
		collapse (mean) sample (sum) pop , by(universidad id_periodo_postulacion year)
		drop year
		reshape wide sample pop, i(universidad) j(id_periodo_postulacion)
		pwcorr sample70 sample71 sample200 sample201 sample230 sample231	
		//generally >0.5. High correlation: Clean cutoff universities are generally clean.
	restore

	
	*Even vs odd years by university
	keep sample pop id_cutoff universidad facultad year
	preserve
		gen even_years = mod(year,2)==0
		keep sample pop universidad even_years
		collapse (mean) sample (sum) pop , by(universidad even_years)
		reshape wide sample pop, i(universidad) j(even_years)
		pwcorr sample0 sample1
		scatter sample0 sample1
		list , sep(10000)
		list if sample0>0.7 & sample, sep(10000)
	restore

	*Even vs odd years by cell
	preserve
		egen g_department 	= group(codigo_modular id_codigo_facultad)
		egen g_major 		= group(codigo_modular id_carrera_primera_opcion)
		gen even_years = mod(year,2)==0
		keep sample pop id_cutoff universidad facultad  even_years
		collapse (mean) sample (sum) pop , by(id_cutoff universidad facultad even_years)
		reshape wide sample pop, i(id_cutoff universidad facultad) j(even_years)
		pwcorr sample0 sample1
		scatter sample0 sample1
		list  , sep(10000)
	restore	
	
end



******************************************************************************** 
* descriptive
* 
* Description: 
********************************************************************************

capture program drop descriptive
program define descriptive

	args cell

	*- Histogram of scores and cutoffs
	use "$TEMP/applied_matched.dta", clear
	
	rename *_`cell' *
	
	*- Relative score
	gen score_relative = score_std - cutoff_std
	gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=.
	
	egen id_persona = group(id_persona_reco)
	//keep if year == 2019
	tabstat enrolled*
	
	xtile socioec_index_g8_sch_pct = socioec_index_g8_sch, nquantiles(4)
	
	
	*- Applications per student
	bys id_persona: gen N_applications = _N
	bys id_persona year: gen N_applications_year = _N
	bys id_persona year public: gen N_applications_year_public = _N
	tab N_applications
	tab N_applications_year
	
	*- Distribution of ECE by type of application
	twoway (kdensity score_math_std_g8 if public==1) (kdensity score_math_std_g8 if public==0)
	
	*- How many years it takes to get admitted
	bys id_persona: egen first_year = min(cond(public==1,year,.))
	bys id_persona: egen last_year = max(cond(public==1,year,.))
	gen years_applying = last_year - first_year
	
	*- Correlation between ECE exams (has to be done form SIAGIE starting point)
	/*
	reg score_math_std_g8 score_math_std_g4
	reg score_com_std_g8 score_com_std_g4
	reg score_math_std_g8 score_math_std_g2
	reg score_com_std_g8 score_com_std_g2
	reg score_math_std_g4 score_math_std_g2
	reg score_com_std_g4 score_com_std_g2
	*/

	*- Correlations between ECE exams
	reg score_std score_com_std_g2 score_math_std_g2 
	reg score_std score_com_std_g4 score_math_std_g4 
	reg score_std score_com_std_g8 score_math_std_g8
	reg score_std score_com_std_g8 score_math_std_g8 score_com_std_g2 score_math_std_g2 
	
	*- Relation between enrolled in preferred and ECE exam
	forvalues y = 2019/2022 {
		binsreg enrolled score_math_std_g8 if year == `y', name(enrolled_ece_m_`y', replace) ytitle("% Enrolled") xtitle("8th grade Math standardized score") subtitle("`y'", color(gs0))
		binsreg enrolled score_com_std_g8 if year == `y', name(enrolled_ece_c_`y', replace) ytitle("% Enrolled") xtitle("8th grade Communications standardized score") title("`y'") subtitle("`y'", color(gs0))
	}
	
	foreach t in "m" "c" {
		graph combine 					///
					enrolled_ece_`t'_2019 	///
					enrolled_ece_`t'_2020 	///
					enrolled_ece_`t'_2021 	///
					enrolled_ece_`t'_2022 	///
					, ///
		xsize(8) col(2) ///
		name(enrolled_ece_`t', replace)
		
		graph export 	"$FIGURES/enrolled_ece_`t'.png", replace	
	}

	*- Relation between enrolled in preferred and ECE exam
	forvalues y = 2019/2022 {
		binsreg enrolled_any score_math_std_g8 if year == `y', name(enrolled_any_ece_m_`y', replace) ytitle("% Enrolled Any") xtitle("8th grade Math standardized score") subtitle("`y'", color(gs0))
		binsreg enrolled_any score_com_std_g8 if year == `y', name(enrolled_any_ece_c_`y', replace) ytitle("% Enrolled Any") xtitle("8th grade Communications standardized score") title("`y'") subtitle("`y'", color(gs0))
	}
	
	foreach t in "m" "c" {
		graph combine 					///
					enrolled_any_ece_`t'_2019 	///
					enrolled_any_ece_`t'_2020 	///
					enrolled_any_ece_`t'_2021 	///
					enrolled_any_ece_`t'_2022 	///
					, ///
		xsize(8) col(2) ///
		name(enrolled_ece_any_`t', replace)
		
		graph export 	"$FIGURES/enrolled_ece_any_`t'.png", replace	
	}
	
	*- Review odd cases
	keep if year==2020
	bys id_persona_reco: gen n_applied=_N
	binsreg enrolled 		score_math_std_g8 if year_ece_g8==2016, nbins(50) ytitle("% Enrolled")	 	xtitle("8th grade Math standardized score") name(ece_m_2016_enrolled, replace)
	binsreg enrolled_any 	score_math_std_g8 if year_ece_g8==2016, nbins(50) ytitle("% Enrolled Any") xtitle("8th grade Math standardized score") name(ece_m_2016_enrolled_any, replace)
	binsreg n_applied 		score_math_std_g8 if year_ece_g8==2016, nbins(50) ytitle("# Applications") xtitle("8th grade Math standardized score") name(ece_m_2016_n_applied, replace)
	
	binsreg enrolled 		score_com_std_g8 if year_ece_g8==2016, nbins(50) ytitle("% Enrolled")	 	xtitle("8th grade Comm standardized score") name(ece_c_2016_enrolled, replace)
	binsreg enrolled_any 	score_com_std_g8 if year_ece_g8==2016, nbins(50) ytitle("% Enrolled Any") xtitle("8th grade Comm standardized score") name(ece_c_2016_enrolled_any, replace)
	binsreg n_applied 		score_com_std_g8 if year_ece_g8==2016, nbins(50) ytitle("# Applications") xtitle("8th grade Comm standardized score") name(ece_c_2016_n_applied, replace)	
	
		graph combine 					///
					ece_m_2016_enrolled 	///
					ece_m_2016_enrolled_any 	///
					ece_m_2016_n_applied 	///
					ece_c_2016_enrolled 	///
					ece_c_2016_enrolled_any 	///
					ece_c_2016_n_applied 	///
					, ///
		xsize(8) col(3) ///
		name(ece_g8_2016_outcomes, replace)
		
		graph export 	"$FIGURES/ece_g8_2016_outcomes.png", replace		
	
	*- Relation between enrolled in any and ECE exam
	
	reg enrolled_any socioec_index_g8_sch score_math_std_g8 score_com_std_g8 if ABOVE==1
	
	binsreg enrolled score_math_std_g8
	binsreg enrolled score_com_std_g8
	
	binsreg score_std score_math_std_g8
	binsreg score_std score_com_std_g8
	
	binsreg score_math_std_g8 score_com_std_g8
end





********************************************************************************
* Run program
********************************************************************************

main