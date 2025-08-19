capture program drop main
program define main

twins
pre_k

end


*----------
*- Twins
*----------
capture program drop twins
program define twins


	global fam_type = 2
	
	*- We estimate twin births
	use "$TEMP\siagie_append", clear
	sort id_per_umc
	keep id_per_umc year grade std_gpa_m_adj
	by id_per_umc: keep if _n==1
	
	preserve
			use "$TEMP\id_siblings", clear
			keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} closest_age_gap*${fam_type} exp_entry_year dob_siagie
			tempfile id_siblings_sample
			save `id_siblings_sample', replace
	restore

	
	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} closest_age_gap*${fam_type} exp_entry_year dob_siagie) 
	rename _m merge_siblings	
	
	
	egen twin_id = group(id_fam_2 dob_siagie)
	
	duplicates tag twin_id, gen(ntwins)
	replace ntwins = . if dob_siagie==.
	
	bys id_fam_2 (fam_order_${fam_type}): gen twin_birth = fam_order_${fam_type} if (twin_id==twin_id[_n+1] & twin_id!=twin_id[_n-1] & twin_id!=.)
	
	bys id_fam_2: egen treated_twins = min(cond(twin_birth!=.,twin_birth,.))
	replace treated_twins = 0 if treated_twins==.
	
	label var twin_birth 	"# of birth of a twin. If 2nd and 3rd child are twins, then =2"
	label var treated_twins 		"MIN # of birth of a twin assigned to family. 0 if no twins"
	
	
	keep id_per_umc twin_id ntwins twin_birth treated_twins
	tempfile ntwins
	save `ntwins', replace
	
	*- We attach twin births 

	
	*- We estimate twin births
	use "$TEMP\siagie_append", clear
	sort id_per_umc
	keep id_per_umc id_ie year grade std_gpa_m_adj male_siagie
	
		
	preserve
			use "$TEMP\id_siblings", clear
			keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} closest_age_gap*${fam_type} exp_entry_year dob_siagie
			tempfile id_siblings_sample
			save `id_siblings_sample', replace
	restore
	
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} exp_entry_year dob_siagie) 
	rename _m merge_siblings	
	
	merge m:1 id_per_umc using `ntwins', keep(master match) keepusing(twin_id ntwins twin_birth treated_twins)
	
	close
	*- We now look at families with N children where the Nth birth are twins. We look at outcomes from N-1 children.
	
	*-- Case 0: We don't directly do DID, but estimate this pre and during covid.
	
	/*
	2SLS
	Y = famsize + e
	famsize = twin + v
	*/
	
	forvalues n = 2(1)3 {
		open 
		keep if fam_total_${fam_type}>=`n' & fam_total_${fam_type}<=5
		keep if fam_order_${fam_type}<`n'
		keep if grade>=1 & grade<=6
		keep if treated_twins==0 | treated_twins==`n'
		gen treated=(treated_twins==`n')
		
		ivreghdfe std_gpa_m_adj (fam_total_2=treated) if inlist(year,2017,2018,2019)  & grade>=1 & grade<=6, a(year grade id_ie)  first
		estimates store iv_twin_pre_n`n'
		ivreghdfe std_gpa_m_adj (fam_total_2=treated) if inlist(year,2020,2021,2022)  & grade>=1 & grade<=6, a(year grade id_ie) first
		estimates store iv_twin_post_n`n'
	}
	
	
	
	
	*-- Case 1: families of at least 2 children. We compare first-borns (N=1) in families where the second child are twins or singletons.
	open
	keep if fam_total_${fam_type}>=2 & fam_total_${fam_type}<=4
	keep if fam_order_${fam_type}==1
	keep if treated_twins==0 | treated_twins==2
	
	gen treated=(treated_twins==2)
	gen post = year>=2020
	gen treated_post= treated*post
	
	local suf_2014 = "b6"
	local suf_2015 = "b5"
	local suf_2016 = "b4"
	local suf_2017 = "b3"
	local suf_2018 = "b2"
	local suf_2019 = "o1"
	local suf_2020 = "a0"
	local suf_2021 = "a1"
	local suf_2022 = "a2"
	local suf_2023 = "a3"
	local suf_2024 = "a4"

	forvalues y = 2014(1)2024 {
		gen byte year_`suf_`y'' = year==`y'
		gen byte year_t_`suf_`y'' = year_`suf_`y''*treated
	}	
	
	global x = "male_siagie"
	global x = ""
	
	reghdfe std_gpa_m_adj treated_post treated post, a(year grade id_ie)
	reghdfe std_gpa_m_adj treated_post treated post if year>=2018 & year<=2021 & grade<=6 & grade>=1, a(year grade id_ie)
	reghdfe std_gpa_m_adj year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade<=6 & grade>=1 , a(year grade id_ie)
	
	collapse std_gpa_m_adj, by(grade year treated_twins)
	
	twoway ///
			(line std_gpa_m_adj year if year>=2017 & treated_twins==0) ///
			(line std_gpa_m_adj year if year>=2017 & treated_twins==2)
	
	
	
	*-- Case 2: families of at least 3 children. We compare first-borns (N=1) in families where the second child are twins or singletons.
	open
	keep if fam_total_${fam_type}>=2 & fam_total_${fam_type}<=4
	keep if fam_order_${fam_type}==1
	keep if treated_twins==0 | treated_twins==2
	
	gen treated=(treated_twins==2)
	gen post = year>=2020
	gen treated_post= treated*post
	
	local suf_2014 = "b6"
	local suf_2015 = "b5"
	local suf_2016 = "b4"
	local suf_2017 = "b3"
	local suf_2018 = "b2"
	local suf_2019 = "o1"
	local suf_2020 = "a0"
	local suf_2021 = "a1"
	local suf_2022 = "a2"
	local suf_2023 = "a3"
	local suf_2024 = "a4"

	forvalues y = 2014(1)2024 {
		gen byte year_`suf_`y'' = year==`y'
		gen byte year_t_`suf_`y'' = year_`suf_`y''*treated
	}	
	
	global x = "male_siagie"
	global x = ""
	
	reghdfe std_gpa_m_adj treated_post treated post, a(year grade id_ie)
	reghdfe std_gpa_m_adj treated_post treated post if year>=2018 & year<=2021 & grade<=6 & grade>=1, a(year grade id_ie)
	reghdfe std_gpa_m_adj year_t_b? o.year_t_o1 year_t_a?  treated ${x} if grade<=6 & grade>=1 , a(year grade id_ie)
	
	
	
	/*
	
	
	keep if dup==0 | dup==1
	tab grade year if dup==1
	
	/*
	keep if dup>=1
	keep twins std_gpa_m_adj
	bys twins: gen n=_n
	reshape wide std_gpa_m_adj, i(twins) j(n)
	*/
	*/
end

capture program drop pre_k
program define pre_k
	
*--------	
*- Pre-K
*--------


	use id_per_umc grade year std_gpa_?_adj using "$TEMP\siagie_append", clear
	//use id_per_umc grade year std_gpa_?_adj using "$TEMP\siagie_2024", clear
	keep id_per_umc grade year std_gpa_?_adj
	merge m:1 id_per_umc using "$TEMP\id_dob", keep(master match) keepusing(year_entry_1st dob_siagie)
	beep	
	
	gen prek = .
	replace prek = 5 if grade==0 & (year+1==year_entry_1st)
	replace prek = 4 if grade==0 & (year+2==year_entry_1st)
	replace prek = 3 if grade==0 & (year+3==year_entry_1st)	
	replace prek = 2 if grade==0 & (year+4==year_entry_1st)	
	//replace prek = 1 if grade==0 & (year+5==year_entry_1st)	
	//replace prek = 0 if grade==0 & (year+6==year_entry_1st)	
	
end	
	
	