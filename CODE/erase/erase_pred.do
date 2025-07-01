	clear
	foreach y in "2014" "2017"  "2020" "2023"  {
		append using "$TEMP\siagie_`y'${data_siagie}", keep(id_ie id_per_umc year grade std_gpa_m std_gpa_c)
	}
	
	*- Get standardized measure
	merge m:1 id_per_umc using "$TEMP\ece_id_per_umc", keepusing(score*std_?? year_??) keep(master match) nogen
	
	*- Regression with full sample (one slope)
	foreach cell in "all" /*"ie_grade"*/ "ie_year" /*"ie"*/  {
		if "`cell'" == "all" 		egen cell_`cell' = group(id_ie year grade)
		//Still very limited, because there is a correlation between ECE being available and Cells
		
		if "`cell'" == "ie_grade" 	egen cell_`cell' = group(id_ie grade)
		if "`cell'" == "ie_year" 	egen cell_`cell' = group(id_ie year)
		if "`cell'" == "ie" 		egen cell_`cell' = group(id_ie)
		
		reghdfe score_math_std_2s std_gpa_m, a(FE_`cell'=cell_`cell') resid
			
		bys cell_`cell' (FE_`cell'): replace FE_`cell' = FE_`cell'[1]
		//replace FE = 0 if FE == .

		*- In sample (only for e(sample), way reghdfe differs from reg.)
		predict pred_gpa_m_`cell', xbd 
		
		*- We force OOS estimation
		predict xvars_`cell', xb
		gen pred_oos_gpa_m_`cell' = xvars_`cell'+FE_`cell'
		
	}
	