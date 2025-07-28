*- TIMSS


import spss using "$IN\TIMSS\2023\T23_Data_SPSS_G4\SPSS Data\asparem8.SAV", clear

ds ASMMAT01



import spss using "$IN\TIMSS\2023\T23_Data_SPSS_G4\SPSS Data\acgadum8.SAV", clear




import spss using "$IN\TIMSS\2015\.SAV", clear
save "$TEMP\COVID\pisa_student_2015.dta", replace


import spss using "$IN\TIMSS\2018\.SAV", clear
save "$TEMP\COVID\pisa_student_2018.dta", replace


import spss using "$IN\TIMSS\2022\.SAV", clear
save "$TEMP\COVID\pisa_student_2022.dta", replace