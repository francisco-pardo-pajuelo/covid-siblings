
	use "$OUT\students", clear
	
	keep id_per_umc
	
	merge 1:1 id_per_umc using "$TEMP\id_siblings", keepusing(educ_caretaker educ_mother educ_father id_fam_* fam_order_* fam_total_*) keep(master match) nogen
	
	keep if inlist(fam_total_4,2)==1
	
	**##
	*- We are considering up to next 5 siblings 
	expand 2
	
	*- We recover the IDs (id_per_umc) of each sibling based on sibling order
	rename fam_order_4 aux_fam_order_4
	rename id_per_umc aux_id_per_umc
	clonevar fam_order_4 = aux_fam_order_4
	sort aux_id_per_umc id_fam_4 fam_order_4
	bys aux_id_per_umc: replace fam_order_4 = fam_order_4 + _n //next 5 siblings
	
	*- Recover ID
	merge m:1 id_fam_4 fam_order_4 using "$OUT\students", keepusing(id_per_umc) keep(master match)
	bys id_fam_4: egen m_max= max(_m)
	tab m_max
	//Why would there be families with no matches if all of them had 2+ siblings?
	drop m_max
	
	open
	list aux_id_per_umc aux_fam_order_4 fam_order_4 _m if id_fam_4 == -80254984
	br  *fam*4 if id_fam_4 == -80254984
	
	
	use "$OUT\students",clear
	list id_per_umc fam_order_4 if id_fam_4 == -80254984


	