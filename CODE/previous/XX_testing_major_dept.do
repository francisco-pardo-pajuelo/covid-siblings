*- Test if major or department cutoff


use "$TEMP/applied_matched.dta", clear 


gen choices = (id_major_choice2!=.)
gen pop = 1

gen dif = abs(cutoff_std_major-cutoff_std_department)>0.1


collapse (mean) choices dif (sum) pop, by(universidad)

sort choices