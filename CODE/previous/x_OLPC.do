*- Test for OLPC:



use "$TEMP\ece_siagie_final", clear

tostring cod_mod7, replace
replace cod_mod7 = "0" + cod_mod7 if strlen(cod_mod7)<7
gen id_ie = cod_mod7 + string(anexo)

merge m:1 id_ie using "$IN\OLPC\school_treated", keepusing(match) keep(estrato group_4 tratada)
keep if _m==3


keep if group_4==1 & tratada!=.

VarStandardiz_control score_math_std tratada  , newvar(c_score_math_std) by(year grade)
VarStandardiz_control score_com_std tratada  , newvar(c_score_com_std) by(year grade)

gen low_ise = .
replace low_ise = 1 if inlist(socioec_index_cat,1)==1
replace low_ise = 0 if inlist(socioec_index_cat,2,3,4)==1


gen tratada_low_ise = tratada*low_ise


*- Grade 4
reghdfe c_score_math_std tratada  if (group_4 == 1 & grade==4), a(estrato year) cl(id_ie)
reghdfe c_score_com_std tratada if (group_4 == 1 & grade==4), a(estrato year) cl(id_ie)

reghdfe c_score_math_std tratada socioec_index if (group_4 == 1 & grade==4), a(estrato year) cl(id_ie)
reghdfe c_score_com_std tratada socioec_index if (group_4 == 1 & grade==4), a(estrato year) cl(id_ie)

reghdfe c_score_math_std tratada 	low_ise tratada_low_ise if (group_4 == 1 & grade==4), a(estrato year) cl(id_ie)
reghdfe c_score_com_std tratada 	low_ise tratada_low_ise if (group_4 == 1 & grade==4), a(estrato year) cl(id_ie)


*- Grade 8 
*- Need to match according to 2nd grade school.
/*
reghdfe c_score_math_std tratada  if (group_4 == 1 & grade==8), a(estrato year) cl(id_ie)
reghdfe c_score_com_std tratada if (group_4 == 1 & grade==8), a(estrato year) cl(id_ie)

reghdfe c_score_math_std tratada socioec_index if (group_4 == 1 & grade==8), a(estrato year) cl(id_ie)
reghdfe c_score_com_std tratada socioec_index if (group_4 == 1 & grade==8), a(estrato year) cl(id_ie)

reghdfe c_score_math_std tratada 	low_ise tratada_low_ise if (group_4 == 1 & grade==8), a(estrato year) cl(id_ie)
reghdfe c_score_com_std tratada 	low_ise tratada_low_ise if (group_4 == 1 & grade==8), a(estrato year) cl(id_ie)
*/

