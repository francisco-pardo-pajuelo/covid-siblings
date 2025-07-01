//save "$TEMP\erase", replace

use "$TEMP\erase", clear


keep if codigo_modular == 160000005

preserve
	drop ABOVE
	keep if id_cutoff == 8288
	gen ABOVE = score_raw>55
	reg admitted ABOVE
	tab ABOVE
	list id_cutoff score_raw admitted R2 major_c1_name cutoff_raw
restore


//R-squared       =    0.6000
//Why R-Squared figures as .20833333
????

gen ABOVE = score_raw 




use "$TEMP\erase", clear

keep if id_cutoff == 11584
sum cutoff_raw
gen ABOVE

reg admitted ABOVE if cutoff_raw != score_raw

id_cutoff	R2
11584	.87266817


use "$TEMP\applied.dta", clear

keep if id_cutoff_major == 11584

gen ABOVE = (score_raw>=10.8)

reg admitted ABOVE if score_raw!=.



use "$TEMP\applied.dta", clear

keep if id_cutoff_major == 8288

gen ABOVE = (score_raw>=58)

reg admitted ABOVE if score_raw!=.

sort score_raw admitted
br admitted score_raw

preserve
	drop ABOVE
	keep if id_cutoff == 8288
	gen ABOVE = score_raw>=55
	reg admitted ABOVE
	tab ABOVE
	list id_cutoff score_raw admitted R2 major_c1_name cutoff_raw
restore