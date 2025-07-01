*- Different sources of variables

global data "_TEST"
global fam_type = "2"
** Issue: We have created graduation and enrollment from 'ever' to 'first college enrolled'. We should test and validate this different measures

use "$OUT/applied_outcomes_${fam_type}${data}.dta", clear



*- Only variables with 'grad' are school ones and college that are too long?
//ds score_std_uni_grad years_to_grad_uni pri_grad sec_grad year_grad_school

tab enrolled_foc graduated_f_uni_ever_foc //Only defined for those enrolled

tab enrolled_sib graduated_f_uni_ever_sib //Only defined for those enrolled


use "$TEMP\first_uni_enrolled_peer_quality", clear

merge m:1 codigo_modular using "$OUT\universities_info", keepusing(public) keep(master match)



