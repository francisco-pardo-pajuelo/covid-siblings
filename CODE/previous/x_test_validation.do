//Use other family IDs for siblings

open

*- ISSUE:
//too few with soc
tab socioec_index_cat_2p_foc year_2p
bys aux_id_per_umc: gen n = _n==1
tab socioec_index_cat_2p_foc year_2p if n==1
tab socioec_index_cat_2p_foc year_2p if _m==3
//Why so few when considering matches? This should remove only the YOUNGEST sibling. Is that the case? Shouldn't we still have the actual sibling outcome?

//br  id_fam_4 aux_fam_order_4 fam_total_4 socioec_index_cat_2p_foc  year_2p if _m==1 & aux_fam_order_4==1 & fam_total_4==3 & socioec_index_2p_foc!=.
sort id_fam_4 aux_fam_order_4 fam_order_4
list id_fam_4 fam_order_4 aux_fam_order_4 aux_id_per_umc id_per_umc _m  socioec_index_cat_2p_foc year_2p if id_fam_4 == 10069341


