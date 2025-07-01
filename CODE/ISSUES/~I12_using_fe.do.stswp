*- Simulation on whether FE are neccessary.

set seed 1234

clear
set obs 2
gen id = _n
expand 100000

gen z = rnormal()

gen cutoff = -2*(id==1) + 1.5*(id==2) 

gen x = z-cutoff

gen above = x>0
gen above_x = x*above

gen y = 1*exp(x) + id*2 + 1*(above) + rnormal()/10


keep if abs(x)<0.3
		
		
//reg y above x above_x




preserve
reg y above x above_x if abs(x)<0.3
predict y_pred, xb

reghdfe y above x above_x if abs(x)<0.3, a(id) resid
predict y_pred_fe, xbd	

twoway 	(lfit y_pred_fe x if above==0 & id==1, lpattern(dash) lwidth(thick) lcolor(red))  ///
		(lfit y_pred_fe x if above==1 & id==1, lpattern(dash) lwidth(thick) lcolor(red))  ///
		(lfit y_pred_fe x if above==0 & id==2, lpattern(dash) lwidth(thick) lcolor(red))  ///
		(lfit y_pred_fe x if above==1 & id==2, lpattern(dash) lwidth(thick) lcolor(red))  ///
		(scatter y x if id==1, mcolor(blue%10) msymbol(oh)) ///
		(scatter y x if id==2, mcolor(green%10) msymbol(oh)) ///
		///(kdensity x if id==1, lcolor(blue%50) fcolor(blue%10) yaxis(2)) ///
		///(kdensity x if id==2, lcolor(green%50) fcolor(green%10) yaxis(2)) ///
		, legend(off)
	graph export 	"$FIGURES/eps/fe_explained_1.eps", replace	
	graph export 	"$FIGURES/png/fe_explained_1.png", replace	
	graph export 	"$FIGURES/pdf/fe_explained_1.pdf", replace			
	
restore
	
preserve
	replace x=. if x<-0.1 & id==2
	replace x=. if x>0.1 & id==1
		
	reg y above x above_x if abs(x)<0.3
	predict y_pred, xb

	reghdfe y above x above_x if abs(x)<0.3, a(id) resid
	predict y_pred_fe, xbd	
	twoway 	(lfit y_pred_fe x if above==0 & id==1, lpattern(dash) lwidth(thick) lcolor(red))  ///
			(lfit y_pred_fe x if above==1 & id==1, lpattern(dash) lwidth(thick) lcolor(red))  ///
			(lfit y_pred_fe x if above==0 & id==2, lpattern(dash) lwidth(thick) lcolor(red))  ///
			(lfit y_pred_fe x if above==1 & id==2, lpattern(dash) lwidth(thick) lcolor(red))  ///
			(scatter y x if id==1, mcolor(blue%10) msymbol(oh)) ///
			(scatter y x if id==2, mcolor(green%10) msymbol(oh)) ///
			///(kdensity x if id==1, lcolor(blue%50) fcolor(blue%10) yaxis(2)) ///
			///(kdensity x if id==2, lcolor(green%50) fcolor(green%10) yaxis(2)) ///
			, legend(off)	
	graph export 	"$FIGURES/eps/fe_explained_2.eps", replace	
	graph export 	"$FIGURES/png/fe_explained_2.png", replace	
	graph export 	"$FIGURES/pdf/fe_explained_2.pdf", replace		

		
twoway 	(lfit y_pred x if above==0, lpattern(dash) lwidth(thick) lcolor(red)) 	///
		(lfit y_pred x if above==1, lpattern(dash) lwidth(thick) lcolor(red))  ///
		///(lfit y_pred_fe x if above==0 & id==1, lpattern(dash) lcolor(red))  ///
		///(lfit y_pred_fe x if above==1 & id==1, lpattern(dash) lcolor(red))  ///
		///(lfit y_pred_fe x if above==0 & id==2, lpattern(dash) lcolor(red))  ///
		///(lfit y_pred_fe x if above==1 & id==2, lpattern(dash) lcolor(red))  ///
		(scatter y x if id==1, mcolor(blue%10) msymbol(oh)) ///
		(scatter y x if id==2, mcolor(green%10) msymbol(oh)) ///
		///(kdensity x if id==1, lcolor(blue%50) fcolor(blue%10) yaxis(2)) ///
		///(kdensity x if id==2, lcolor(green%50) fcolor(green%10) yaxis(2)) ///
		, legend(off)
	graph export 	"$FIGURES/eps/fe_explained_3.eps", replace	
	graph export 	"$FIGURES/png/fe_explained_3.png", replace	
	graph export 	"$FIGURES/pdf/fe_explained_3.pdf", replace	
restore	

preserve
	replace x=. if x<-0.1 & id==2
	replace x=. if x>0.1 & id==1
	
	keep if runiform()<0.002
		
	reg y above x above_x if abs(x)<0.3
	predict y_pred, xb

	reghdfe y above x above_x if abs(x)<0.3, a(id) resid
	predict y_pred_fe, xbd	
	twoway 	(lfit y_pred_fe x if above==0 & id==1, lpattern(dash) lwidth(thick) lcolor(red))  ///
			(lfit y_pred_fe x if above==1 & id==1, lpattern(dash) lwidth(thick) lcolor(red))  ///
			(lfit y_pred_fe x if above==0 & id==2, lpattern(dash) lwidth(thick) lcolor(red))  ///
			(lfit y_pred_fe x if above==1 & id==2, lpattern(dash) lwidth(thick) lcolor(red))  ///
			(scatter y x if id==1, mcolor(blue%80) msymbol(oh)) ///
			(scatter y x if id==2, mcolor(green%80) msymbol(oh)) ///
			///(kdensity x if id==1, lcolor(blue%50) fcolor(blue%10) yaxis(2)) ///
			///(kdensity x if id==2, lcolor(green%50) fcolor(green%10) yaxis(2)) ///
			, legend(off)	
	graph export 	"$FIGURES/eps/fe_explained_4.eps", replace	
	graph export 	"$FIGURES/png/fe_explained_4.png", replace	
	graph export 	"$FIGURES/pdf/fe_explained_4.pdf", replace		
restore