/*
timer clear 1
timer on 1

setup_A01
	
//define_labels

//schools

//siagie

applied
enrolled
graduated

average_data

timer off 1
timer list 1
*/


timer clear 4
timer on 4

do "$CODE\A04_clean_final"


timer off 4
timer list 4


timer list 3
timer list 4
clear
set obs 4
gen dofile = _n
gen t = .
replace t = r(t1)/3600 in 1 //9477.06  	(2.6h)
replace t = r(t2)/3600 in 2 //9477.06  	(2.6h)
replace t = r(t3)/3600 in 3 //60612.20		(16h)
replace t = r(t4)/3600 in 4 // 1h)
save "$TEMP\DURATION_DOFILE", replace


