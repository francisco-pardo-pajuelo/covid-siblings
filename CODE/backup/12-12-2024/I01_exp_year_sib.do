*- Issue: Why is expected year of graduation higher for some siblings. Wasn't order determined by this?

*- Example:
use "$OUT/applied_outcomes_2.dta", clear
count
count if exp_graduating_year1_sib<exp_graduating_year1_foc
//1,342 inconsistencies. Not many but shouldn't be there.
count if exp_graduating_year2_sib<exp_graduating_year2_foc
//Under further review, the ordering was done based on the earliest year, that is why we don't find inconsistencies here.

*- Conclussion: No issue, there may be some 'younger' siblings graduating before as would be expected in real data. Perhaps exclude this from sample? It should be done considering the filters we are imposing. Nothing else to look at except we will have a more refined ordering once we include DOB but we still need to filter for those graduating before/after.

*- After though:  Perhaps order based on graduation order makes more sense?

*- Reference: from 'A00_clean_raw.do', this is how ordering is done

/*
	*- Save information per student
	bys id_per_umc (year grade): keep if _n==1
	
	*- In absence of DOB we rank them based on starting year
	gen year_start = year-grade
	bys id_fam_1 (year_start): gen fam_order_1 = _n if id_fam_1!=.
*/


