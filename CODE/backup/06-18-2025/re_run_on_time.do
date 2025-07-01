
	setup_A01
	define_labels
	average_data
	additional_data
	erase_data
	
timer clear 4
timer on 4
do "$CODE\A04_clean_final"
timer off 4
timer list 4

do "$CODE\C02_tables_figures"	