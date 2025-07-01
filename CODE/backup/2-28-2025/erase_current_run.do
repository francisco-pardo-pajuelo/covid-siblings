do "$CODE\A04_clean_final"

do "$CODE\C02_tables_figures"


use "$OUT/applied_outcomes_${fam_type}.dta", clear
tab  year_applied_sib if year_app_foc==2017 & fam_order_2 == 1

		local gap_after = 2
		local gap_before = 2
		
		local expected_grad_sib = "exp_graduating_year1_sib"
		

tab  year_applied_sib if year_app_foc==2020 & fam_order_2 == 1 & (`expected_grad_sib'+`gap_after'>=year_app_foc)



		local gap_after = 0
		local gap_before = 2
		
		local expected_grad_sib = "exp_graduating_year2_sib"
		

tab  year_applied_sib if year_app_foc==2020 & fam_order_2 == 1 & (`expected_grad_sib'+`gap_after'>=year_app_foc)