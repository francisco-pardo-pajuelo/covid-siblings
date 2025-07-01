
	//db_universities //Not currently used


timer clear 3
timer on 3	
	persistence
	
	average_data
	additional_data
	
	erase_data

timer off 3
timer list 3	
	
	

*- Final applications-sibling database
do "$CODE\A04_clean_final"



timer list 2
timer list 3
timer list 4
clear
set obs 3
gen dofile = _n
gen t = .
replace t = r(t2)/3600 in 1 //9477.06  	(2.6h)
replace t = r(t3)/3600 in 2 //60612.20		(16h)
replace t = r(t4)/3600 in 3 // 1h)
save "$TEMP\DURATION_DOFILE", replace



standardize_uni_exams_beta

do "$CODE\C02_tables_figures"
