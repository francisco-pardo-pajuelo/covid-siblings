*- Checking cutoffs (compared to  prior)

global fam_type = 2
global data = ""



*- Bad cutoffs:

use "$TEMP/previous_cutoffs/applied.dta", clear

keep if codigo_modular == 160000001 & major_c1_cat6==912016 & semester=="2023-1"
sort score_raw
br score_raw admitted if codigo_modular == 160000001 & major_c1_cat6==912016 & semester=="2023-1"
count if codigo_modular == 160000001 & major_c1_cat6==912016 & semester=="2023-1"



/*

         +--------------------------------------------------------------------------------------+
         | id_cut~f                             codigo_modular   semest~c   major_..   major_~6 |
         |--------------------------------------------------------------------------------------|
  99889. |      773   UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS     2023-1     711026     912016 |
         +--------------------------------------------------------------------------------------+


*/


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

