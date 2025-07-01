
timer clear 3
timer on 3
	use "$TEMP\standardized_gpa_school", clear
	
	keep id_per_umc year std_pred_gpa_?_all std_pred_gpa_?_ie_y 
	reshape wide std_pred_gpa_?_all std_pred_gpa_?_ie_y, i(id_per_umc) j(year)
	
	rename std_pred_gpa_?_all* std_pred_gpa_?_all_*
	rename std_pred_gpa_?_ie_y* std_pred_gpa_?_ie_y_*
	
	merge 1:1 id_per_umc using "$TEMP\siagie_yearvars", keep(master match) nogen
	
	keep 	id_per_umc  grade_???? approved_???? approved_first_???? /*math_secondary_????*/ std_gpa_m_???? std_pred_gpa_m_ie_y_???? std_gpa_c_???? std_pred_gpa_c_ie_y_????
	order 	id_per_umc  grade_???? approved_???? approved_first_???? /*math_secondary_????*/ std_gpa_m_???? std_pred_gpa_m_ie_y_???? std_gpa_c_???? std_pred_gpa_c_ie_y_????
	capture drop math_secondary_2023 comm_secondary_2023
	capture drop std_gpa_m_2023 std_gpa_c_2023
	compress
	save "$TEMP\standardized_gpa_school_yearvars", replace
timer off 3
timer list 3	
	
	

timer clear 4
timer on 4
do "$CODE\A04_clean_final"
timer off 4
timer list 4


timer list 3
timer list 4