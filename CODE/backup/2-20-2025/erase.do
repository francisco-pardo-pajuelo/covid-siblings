
	merge m:1 id_per_umc codigo_modular using "$TEMP\applied_students_university", keepusing(year public) keep(master match using) 
	bys id_per_umc: egen applied_other = max(cond(_m==2 & public==1,1,0))
	drop if _m==2
	recode _m (1 = 0) (3 = 1)
	drop _m year
	
	merge m:1 id_per_umc major_c1_inei_code using "$TEMP\applied_students_major", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_major_sib year_applied_major_sib)
	
	merge m:1 id_per_umc using "$TEMP\applied_students_public", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_public_sib year_applied_public_sib)

	merge m:1 id_per_umc using "$TEMP\applied_students_private", keepusing(year) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_private_sib year_applied_private_sib)	

	merge m:1 id_per_umc codigo_modular using "$TEMP\applied_students_multiple_public", keepusing(year) keep(master match) 
	gen applied_mult = 0
	replace applied_mult = 1 if (applied_public_sib==1 & applied_uni_sib==0) 	// Applied to public but not target
	replace applied_mult = 1 if (_m==3) 														// Applied to multiple publics
	bys id_per_umc (applied_mult): replace applied_mult=applied_mult[_N] 		// Make all 1 if there is one, since it's an individual outcome
	drop _m year 
	
	

	
	merge m:1 id_per_umc using "$TEMP\applied_students", keepusing(year semester) keep(master match) 
	recode _m (1 = 0) (3 = 1)
	rename (_m year) (applied_sib year_applied_sib)
	
	
	order id_per_umc applied_other applied_public_o_sib applied_uni_sib applied_public_sib
	
	// New is but not old
	br id_per_umc applied_other applied_mult applied_public_o_sib applied_uni_sib applied_public_sib if id_per_umc == "1003040"
	
	
	/*
	
         +--------------------------------------------------------------------+
         |                               codigo_modular   id_pe~mc   pu~c_foc |
         |--------------------------------------------------------------------|
			OLDER
         |--------------------------------------------------------------------|
 375030. |        UNIVERSIDAD PRIVADA SAN JUAN BAUTISTA    1003040    Private |
 375031. |        UNIVERSIDAD PRIVADA SAN JUAN BAUTISTA    1003040    Private |
         +--------------------------------------------------------------------+
			YOUNGER
         |-----------------------------------------------------|
    353. | UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS    1003040 	Public| 1
    354. |    UNIVERSIDAD PRIVADA SAN JUAN BAUTISTA    1003040 	Private|
         +-----------------------------------------------------+		 

	*/	
	
	// old is but not new 
	br id_per_umc applied_other applied_mult applied_public_o_sib applied_uni_sib applied_public_sib if id_per_umc == "1000182"
		
	/*
	OLDER
	369100. |                UNIVERSIDAD NACIONAL DE PIURA    1000182     Public |
	369101. |                    UNIVERSIDAD CÉSAR VALLEJO    1000182    Private |
	369102. | UNIVERSIDAD CATÓLICA LOS ÁNGELES DE CHIMBOTE    1000182    Private |
	369103. | UNIVERSIDAD CATÓLICA LOS ÁNGELES DE CHIMBOTE    1000182    Private |
	*/
	
	/*
	YOUNGER
	 28. |            UNIVERSIDAD NACIONAL DE PIURA    1000182 Public	|
	*/
	

	
	
	list codigo_modular id_per_umc public if inlist(id_per_umc, "1003040" , "1000182"), sepby(id_per_umc)
	
	
	/*
	aux_id_per_umc	id_per_umc
4889088	1000182
7398541	1003040

inlist(id_per_umc, "4889088" , "7398541")

	*/
	
	
	use "$OUT/applied_outcomes_${fam_type}.dta", clear
	
	tab applied_sib applied_public_o_sib //diagonal
	
	tab applied_public_o_sib if public_foc==0 & applied_public_sib==1 //all yes
	
	
	preserve
		keep if applied_public_tot_sib==. & applied_public_sib==1
		tab applied_public_tot_sib if applied_public_sib==1, m
		
		list id_per_umc id_per_umc_sib if _n<10
		//Sibling applied to public but missing # of applications
	restore
	
	
	list  if app_pub_tot_sib ==. & applied_public_sib==1
	use "$TEMP\applied_students_university", clear
	merge m:1 id_per_umc using "$TEMP\applied_students_public"
	
	br if id_per_umc == "1514693"

	
	
	
	
	
	
 
