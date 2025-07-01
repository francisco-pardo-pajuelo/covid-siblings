/********************************************************************************
- Author: Francisco Pardo
- Description: Other support figures
- Date started: 03/02/2025
- Last update: 03/02/2025
*******************************************************************************/

capture program drop main 
program define main 

	setup

	type_admission_rd
	
	

		


end





********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup

	set seed 1234
	global fam_type = 2
end



********************************************************************************
* Prepare RD
********************************************************************************
capture program drop type_admission_rd
program define type_admission_rd

	use "$TEMP\applied", clear

	keep if codigo_modular == 160000001 & major_c1_cat6==912016 & semester=="2023-1"
	sort type_admission score_raw

	twoway /// 
		(scatter admitted score_raw if codigo_modular == 160000001 & major_c1_cat6==912016 & semester=="2023-1" & score_raw>1000, mcolor(%20)) ///
		, ///
		xline(1285.13) ///
		xtitle("Raw Score")
		
		graph export 	"$FIGURES/eps/type_admission_RD_1.eps", replace	
		graph export 	"$FIGURES/png/type_admission_RD_1.png", replace	
		graph export 	"$FIGURES/pdf/type_admission_RD_1.pdf", replace		
		
	binsreg  ///
		admitted score_raw if codigo_modular == 160000001 & major_c1_cat6==912016 & semester=="2023-1" & score_raw>1000 ///
		, ///
		nbins(100) ///
		xline(1285.13) ///
		xtitle("Raw Score") ///
		ytitle("Was admitted to cutoff") ///
		dotsplotopt(msymbol(o) mcolor(%100))
		
		graph export 	"$FIGURES/eps/type_admission_RD_2.eps", replace	
		graph export 	"$FIGURES/png/type_admission_RD_2.png", replace	
		graph export 	"$FIGURES/pdf/type_admission_RD_2.pdf", replace			 

	twoway /// 
		(scatter admitted score_raw if codigo_modular == 160000001 & major_c1_cat6==912016 & semester=="2023-1" & score_raw>1000 & type_admission==1, mcolor(%20)) ///
		(scatter admitted score_raw if codigo_modular == 160000001 & major_c1_cat6==912016 & semester=="2023-1" & score_raw>1000 & type_admission==2, mcolor(%20)) ///
		, ///
		xtitle("Raw Score") ///
		ytitle("Was admitted to cutoff") ///	
		legend(label(1 "Exam") label(2 "Academy") pos(6) col(2))
		
		graph export 	"$FIGURES/eps/type_admission_RD_3.eps", replace	
		graph export 	"$FIGURES/png/type_admission_RD_3.png", replace	
		graph export 	"$FIGURES/pdf/type_admission_RD_3.pdf", replace		


	twoway /// 
		(scatter admitted score_raw if codigo_modular == 160000001 & major_c1_cat6==912016 & semester=="2023-1" & score_raw>1000 & type_admission==1, mcolor(%20)) ///
		(scatter admitted score_raw if codigo_modular == 160000001 & major_c1_cat6==912016 & semester=="2023-1" & score_raw>1000 & type_admission==2, mcolor(%20)) ///
		, ///
		xline(1285.13 1735) ///
		xtitle("Raw Score") ///
		ytitle("Was admitted to cutoff") ///	
		legend(label(1 "Exam") label(2 "Academy") pos(6) col(2))
		
		graph export 	"$FIGURES/eps/type_admission_RD_4.eps", replace	
		graph export 	"$FIGURES/png/type_admission_RD_4.png", replace	
		graph export 	"$FIGURES/pdf/type_admission_RD_4.pdf", replace		
		
		
		
	/*
	
		use "$TEMP\applied", clear

	keep if codigo_modular == 260000054 & semester=="2023-1"
	
	sort type_admission major_c1_inei_code score_raw
	
	br type_admission major_c1_inei_code score_raw admitted
	
	
	*/
		

end



********************************


main