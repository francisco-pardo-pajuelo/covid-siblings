*- Some private universities have strange distributions. 

*-- Issue: # of obs with All application scores > # obs same + # obs different. It should be '<'?
/*


*/


use "$OUT/applied_outcomes_${fam_type}.dta", clear

keep score_std_major_all_u_sib score_std_major_uni_u_sib score_std_major_pub_u_sib score_std_major_uni_o_u_sib score_std_major_pub_o_f_sib

rename *_major* **

sum score_std_all_u_sib score_std_uni_u_sib score_std_uni_o_u_sib

br score_std_all_u_sib score_std_uni_u_sib score_std_uni_o_u_sib

//conclussion: 






