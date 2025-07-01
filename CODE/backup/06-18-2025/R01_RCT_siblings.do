*- RCT sibling spillover analysis.
global fam_type = 2


	preserve
		use "$TEMP\id_siblings", clear
		keep id_per_umc educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} id_mother id_father id_caretaker
		tempfile id_siblings_sample
		save `id_siblings_sample', replace
	restore


	use "$TEMP\siagie_2015.dta", clear
	
	//Simulate sample
	keep if urban_siagie==1
	keep if level==3 
	bys id_ie: gen N_enrollment = _N
	keep if N_enrollment>785 & N_enrollment<835
	distinct id_ie
	
	preserve 
		bys id_ie: keep if _n==1
		tempfile sample_schools
		save `sample_schools'
	restore
	
	keep if inlist(grade,7,8)==1
	//We have 66 schools and 22.3k students in 7th and 8th grade
	
	*- Match Family info
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} id_mother id_father id_caretaker) nogen
	keep id_fam_${fam_type}
	bys id_fam_${fam_type}: keep if _n==1
	tempfile sample_families
	save `sample_families'

	*- Get full observations for those families.
	use "$TEMP\siagie_2015.dta", clear
	/*
	keep if level==3 
	bys id_ie: gen N_enrollment = _N
	keep if N_enrollment>785 & N_enrollment<835
	distinct id_ie
	*/
	merge m:1 id_per_umc using `id_siblings_sample', keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_${fam_type} fam_order_${fam_type} fam_total_${fam_type} id_mother id_father id_caretaker) nogen
	merge m:1 id_fam_${fam_type} using `sample_families', keep(master match)
	rename _m m_families
	merge m:1 id_ie using `sample_schools', keep(master match)
	rename _m m_schools
	
	keep if m_families==3
	tab grade if grade>=1
	tab grade if m_schools==3
	
	//Size of secondary
	bys id_ie level: gen N=_N
	
	gen size_aprox = (N>=750 & N<=850 & level==3)
	
	bys id_fam_${fam_type}: egen sample_size = max(cond(size_aprox==1,1,0))
	
	distinct id_ie if sample_size==1
	
