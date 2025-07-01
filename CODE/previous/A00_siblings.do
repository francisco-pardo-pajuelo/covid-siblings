/********************************************************************************
- Author: Francisco Pardo
- Description: Siblings identification
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/


capture program drop main 
program define main 

	setup
	sibling_id		// 	identify siblings

end




********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup

	set seed 1234
	global excel = 1
	global test = 0

end


********************************************************************************
* Family ID: identify siblings from SIAGIE data
********************************************************************************

capture program drop sibling_id
program define sibling_id

foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		if ${test}==0 use id_* year grade dob_* educ_* using "$TEMP\siagie_`y'", clear
		if ${test}==1 use id_* year grade dob_* educ_* using "$TEMP\siagie_`y'_TEST", clear
		tempfile id_`y'
		save `id_`y'', replace
	}
		
	clear 
	append using `id_2014'
	append using `id_2015'
	append using `id_2016'
	append using `id_2017'
	append using `id_2018'
	append using `id_2019'
	append using `id_2020'
	append using `id_2021'
	append using `id_2022'
	append using `id_2023'
	
	*- Review same individual across years
	sort id_per_umc year
	duplicates tag id_per_umc, gen(dup)
	list if dup>0 & _n<100, sepby(id_per_umc)
	
	*- Get one ID per adult per individual (first one that is non missing)
	foreach adult in "caretaker" "mother" "father" {
		gen aux_id_`adult' = id_`adult'
		gen no_`adult' = (id_`adult' == "")
		bys id_per_umc (no_`adult' year dob_`adult'): replace id_`adult' = id_`adult'[1]
		drop no_`adult'
		drop aux*
		}
		
	*- We assign the maximum education level for each student-adult 
	**# It could also be the one that matches the chosen ID? Shouldn't make a lot of a difference.
	foreach adult in "caretaker" "mother" "father" {
		rename educ_`adult' aux_educ_`adult'
		bys id_per_umc: egen educ_`adult' = max(aux_educ_`adult')
		drop aux_educ_`adult'
		}	

	*- ID Family	
	*-- Group 1: By caretaker ID
	egen id_fam_1 = group(id_caretaker)
	replace id_fam_1 = -id_per_umc if id_fam_1==.
	//egen id_fam_1_check = group(id_caretaker dob_caretaker)
	//replace id_fam_1 = . if id_caretaker==""
	sort id_fam_1 
	bys id_fam_1 : gen N_siblings_1=_N if id_fam_1!=.
	
	*-- Group 2: By Mother ID
	egen id_fam_2 = group(id_mother)
	replace id_fam_2 = -id_per_umc if id_fam_2==.
	//replace id_fam_2 = . if id_mother==""
	sort id_fam_2 
	bys id_fam_2 : gen N_siblings_2=_N if id_fam_2!=.	
	
	*- Group 3: Best ID (mother>father>caretaker)
	gen id_adult = id_mother
	replace id_adult = id_father if id_adult==""
	replace id_adult = id_caretaker if id_adult==""
	egen id_fam_3 = group(id_adult)
	replace id_fam_3 = -id_per_umc if id_fam_3==.
	//replace id_fam_3 = . if id_adult==""
	sort id_fam_3 
	bys id_fam_3 : gen N_siblings_3=_N if id_fam_3!=.	
	tab N_siblings_3
	
	*- Group 4: father and mother (or mother/father if only one)
	egen id_fam_4 = group(id_mother id_father), missing
	replace id_fam_4 = -id_per_umc if id_mother=="" & id_father==""  //If there is only one, we do keep it.
	//replace id_fam_4 = . if id_mother=="" & id_father==""
	sort id_fam_4 
	bys id_fam_4 : gen N_siblings_4=_N if id_fam_4!=.	
	tab N_siblings_4	
	
	*- Save information per student
	bys id_per_umc (year grade): keep if _n==1
	
	*- In absence of DOB we rank them based on starting year
	gen year_start = year-grade
	bys id_fam_1 (year_start): gen fam_order_1 = _n if id_fam_1!=.
	bys id_fam_2 (year_start): gen fam_order_2 = _n if id_fam_2!=.
	bys id_fam_3 (year_start): gen fam_order_3 = _n if id_fam_3!=.
	bys id_fam_4 (year_start): gen fam_order_4 = _n if id_fam_4!=.

	bys id_fam_1 (year_start): gen fam_total_1 = _N if id_fam_1!=.
	bys id_fam_2 (year_start): gen fam_total_2 = _N if id_fam_2!=.
	bys id_fam_3 (year_start): gen fam_total_3 = _N if id_fam_3!=.
	bys id_fam_4 (year_start): gen fam_total_4 = _N if id_fam_4!=.
	
	capture label define educ 1 "None" 2 "Primary Incomplete" 3 "Primary Complete" 4 "Secondary Incomplete" 5 "Secondary Complete" 6 "Higher Incomplete" 7 "Higher Complete" 8 "Post-grad"
	label values educ_caretaker educ_mother educ_father educ
	
	keep id_per_umc id_fam_4 fam_order_4 fam_total_4 educ_*
	order id_per_umc id_fam_4 fam_order_4 fam_total_4 educ_*
	bys id_per_umc: keep if _n==1
	
	label var fam_order_4 "Sibling #order"
	label var fam_total_4 "Total siblings"
	
	compress
	
	if ${test}==1 save "$TEMP\id_siblings_TEST", replace
	if ${test}==0 save "$TEMP\id_siblings", replace

end

main