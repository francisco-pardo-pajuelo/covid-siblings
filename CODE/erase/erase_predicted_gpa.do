	global data_siagie = ""
	
	
 
********************************************************************************
* Creating Standardized measures of achievement based on standardized national examinations for cross school comparissons and GPA/application score for within school/pool comparison
********************************************************************************	
	
*- Standardized measures of achievement 


capture program drop standardized_achievement_ece 
program define standardized_achievement_ece	
	
	*- 1. Get Standardized measure
	use "$TEMP\match_siagie_ece_2p", clear
	append using "$TEMP\match_siagie_ece_4p"
	append using "$TEMP\match_siagie_ece_2s"
	keep id_per_umc
	bys id_per_umc: keep if _n==1
	
	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2p", keep(master match) keepusing(id_estudiante) nogen
	rename id_estudiante id_estudiante_2p

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_4p", keep(master match) keepusing(id_estudiante) nogen
	rename id_estudiante id_estudiante_4p

	merge m:1 id_per_umc using "$TEMP\match_siagie_ece_2s", keep(master match) keepusing(id_estudiante) nogen
	rename id_estudiante id_estudiante_2s

	merge m:1 id_estudiante_2p using  "$TEMP\ece_2p", keep(master match) keepusing(year score_math_std score_com_std score_acad_std) nogen //m:1 because there are missings
	rename (year score_math_std score_com_std score_acad_std) (year_2p score_math_std_2p score_com_std_2p score_acad_std_2p)
	
	merge m:1 id_estudiante_4p using "$TEMP\ece_4p", keep(master match) keepusing(score_math_std score_com_std score_acad_std year) nogen //m:1 because there are missings
	rename (year score_math_std score_com_std score_acad_std) (year_4p score_math_std_4p score_com_std_4p score_acad_std_4p)
	
	merge m:1 id_estudiante_2s using "$TEMP\ece_2s", keep(master match) keepusing(score_math_std score_com_std score_acad_std year) nogen //m:1 because there are missings
	rename (year score_math_std score_com_std score_acad_std) (year_2s score_math_std_2s score_com_std_2s score_acad_std_2s)

	order id_per_umc *2p *4p *2s 
	
	drop if year_2p ==. & year_4p == . & year_2s ==. 
	
	save "$TEMP\ece_id_per_umc", replace

	*- 2. Standardized school GPA
	
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		append using "$TEMP\siagie_`y'${data_siagie}", keep(id_ie id_per_umc year grade std_gpa_m std_gpa_c)
	}
	
	*- Get standardized measure
	merge m:1 id_per_umc using "$TEMP\ece_id_per_umc", keepusing(score*std_?? year_??) keep(master match) nogen
	
	*- Regression with full sample (one slope)
	/*
	egen cell = group(id_ie year grade)
	reghdfe score_math_std_2s std_gpa_m, a(cell) resid
	predict predict_gpa_m, xbd 
	label var predict_gpa_m "Predicted National GPA - Mathematics"
	rename predict_gpa_m temp
	VarStandardiz temp, newvar(predict_gpa_m)
	
	keep id_per_umc id_ie year grade predict_gpa_m
	
	save "$TEMP\standardized_gpa_school", replace
	*/
	
	*- 3. Standardized uni GPA
	
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		//append using "$TEMP\siagie_`y'${data_siagie}", keep(id_ie id_per_umc year grade std_gpa_m std_gpa_c)
	}
	
	*- Get standardized measure
	merge m:1 id_per_umc using "$TEMP\ece_id_per_umc", keepusing(score*std_?? year_??) keep(master match) nogen
	
	*- Regression with full sample (one slope)
	egen cell = group(id_ie year grade)
	reghdfe score_math_std_2s std_gpa_m, a(cell) resid
	predict predict_gpa_m, xbd 
	label var predict_gpa_m "Predicted National GPA - Mathematics"
	rename predict_gpa_m temp
	VarStandardiz temp, newvar(predict_gpa_m)
	
	keep id_per_umc id_ie year grade predict_gpa_m
	
	save "$TEMP\standardized_gpa_school", replace
	
	*- 4. Standardized uni applications
	
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		//append using "$TEMP\siagie_`y'${data_siagie}", keep(id_ie id_per_umc year grade std_gpa_m std_gpa_c)
	}
	
	*- Get standardized measure
	merge m:1 id_per_umc using "$TEMP\ece_id_per_umc", keepusing(score*std_?? year_??) keep(master match) nogen
	
	*- Regression with full sample (one slope)
	/*
	egen cell = group(id_ie year grade)
	reghdfe score_math_std_2s std_gpa_m, a(cell) resid
	predict predict_gpa_m, xbd 
	label var predict_gpa_m "Predicted National GPA - Mathematics"
	rename predict_gpa_m temp
	VarStandardiz temp, newvar(predict_gpa_m)
	
	keep id_per_umc id_ie year grade predict_gpa_m
	
	save "$TEMP\standardized_gpa_school", replace
	*/
end


	