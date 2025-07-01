*- 

use "$TEMP\previous_cutoffs\applied", clear

keep id_cutoff_major codigo_modular semester facultad major_c1_inei_code
bys id_cutoff_major: keep if _n==1

tempfile id_cutoff
save `id_cutoff', replace


use "$TEMP\previous_cutoffs\applied_cutoffs_major", clear

merge 1:1 id_cutoff_major using `id_cutoff'

keep if _m==3

order codigo_modular semester facultad major_c1_inei_code id_cutoff_major, first


