*- Twins

	global fam_type = 2
	
	use "$TEMP\siagie_append", clear
	sort id_per_umc
	keep id_per_umc grade std_gpa_m_adj
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
	
	
	egen twins = group(id_fam_2 dob_siagie)
	
	duplicates tag twins, gen(dup)
	
	tab grade dup
	
	keep if dup>=1
	keep twins std_gpa_m_adj
	bys twins: gen n=_n
	reshape wide std_gpa_m_adj, i(twins) j(n)
	
	
*- Pre-K

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