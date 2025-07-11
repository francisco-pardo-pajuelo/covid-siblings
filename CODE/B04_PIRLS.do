*- PIRLS




import spss using "$IN\PIRLS\2015\.SAV", clear
save "$TEMP\COVID\pisa_student_2015.dta", replace


import spss using "$IN\PIRLS\2018\.SAV", clear
save "$TEMP\COVID\pisa_student_2018.dta", replace


import spss using "$IN\PIRLS\2022\.SAV", clear
save "$TEMP\COVID\pisa_student_2022.dta", replace