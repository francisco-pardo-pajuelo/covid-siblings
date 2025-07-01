/********************************************************************************
- Author: Francisco Pardo
- Description: Produces final tables and figures
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/






********************************************************************************
* Regressions for tables
********************************************************************************

capture program drop test
program define test


	args fam_type

	estimates drop _all

	global fam_v1 = `fam_type'
		
	use if _n<100000  using "$OUT/applied_outcomes_${fam_v1}.dta", clear

	//prepare_rd noz major
	
	keep age admitted male_foc
	
		
	global pre = ${fam_v1}
	di "$pre"
	qui ivreg2 age  (admitted = male_foc)
	di "${fam_v1}"
	assert $pre == ${fam_v1}
end


test 2