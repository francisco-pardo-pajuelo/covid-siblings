*- Issue: Why do some siblings do not have info on region?

use "$OUT/applied_outcomes_2.dta", clear

*- Example:
tab region_siagie_foc, m
// no missing

tab region_siagie_sib, m
//362,724 missing

tab male_siagie_sib, m
//This is actually just siblings not matching. Why?
// We did this in 'clean_final': keep if m_sibling_siagie == 3 //Only keep those who match a younger sibling
// So we should have removed those that didn't match.
// Actually we did this for the siblings_student data, but not for the applications one. The idea was that we wanted to also have unmatched ones (without duplicating per sibling) to produced overall statistics. This can be confusing when producing descriptive stats so I have to be careful. For now, we've recovered the 'any_sib_match' variable and those who don't shouldn't have sibling outcomes.

tab applied_sib, m
//Do not have the same for this

tab exp_graduating_year1_sib, m
//363,333 it is even a bit higher, another issue since this variable should be defined for all.

*- Possibly some sibling orders didn't match. Didn't I remove those?
br if male_siagie_sib == .

*- Conclussion: 
*- After though:  Be careful with (i) Descriptive applicant stats which should be done with "$TEMP\applied" + adding vars and (ii) Descriptive applicant-sibling stats which are the "$OUT\applied_outcomes_?" data.

*- Reference:  in A00_clean_final, when doing applications_sibling data (not student_sibling) we don't remove those without matches since we are interested in keeping them for descriptive stats.

/*
	*- School outcomes
	merge m:1 id_fam_${fam_type} fam_order_${fam_type} using "$OUT\students", keepusing(id_per_umc) keep(master match) 
	rename _m m_sibling_siagie
	//keep if m_sibling_siagie == 3 //Only keep those who match a younger sibling
*/