
local area = "all"
local hed_parent = "all"		
local level = "all"
local v = "std_gpa_m"

keep if year>=2016
				
				
				use `v' id_per_umc year_t_?? urban_siagie higher_ed_parent year grade treated id_ie fam_order_${fam_type} fam_total_${fam_type} using "$TEMP\pre_reg_covid_TEST", clear
				
				if "`area'" == "rur" keep if urban_siagie == 0
				if "`area'" == "urb" keep if urban_siagie == 1
				
				if "`hed_parent'" == "no" 	keep if higher_ed_parent == 0
				if "`hed_parent'" == "ys" 	keep if higher_ed_parent == 1
				
				if "`level'" == "elm" keep if grade>=1 & grade<=6
				if "`level'" == "sec" keep if grade>=7
				
				
				//merge m:1 id_ie using "$TEMP\siagie_ece_ie_obs", keep(master match) keepusing(`v'_*) nogen
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated, a(year grade id_ie id_per_umc)
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated, a(year grade id_ie)
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated if inlist(fam_total_${fam_type},1,2)==1, a(year grade id_ie)
				reghdfe `v' 			year_t_b? o.year_t_o1 year_t_a?  treated if inlist(fam_total_${fam_type},1,3)==1, a(year grade id_ie)
				estimates store `v'_`area'_`hed_parent'_`level'
				}
			
			coefplot 	a, ///
						omitted ///
						keep(year_t_??) msy(O) msize(1.5) vert recast(connected) ciopts(recast(rcap)) offset(0) ///
						leg(order(1 "GPA Math" 3 "GPA Comm")) ///
						coeflabels(year_t_b6 = "2014" year_t_b5 = "2015" year_t_b4 = "2016" year_t_b3 = "2017" year_t_b2 = "2018" year_t_o1 = "2019" year_t_a0 = "2020" year_t_a1 = "2021" year_t_a2 = "2022" year_t_a3 = "2023") ///
						yline(0,  lcolor(gs10))  ///
						ytitle("Effect") ///
						subtitle("Panel A: GPA") ///
						legend(pos(6) col(3)) ///
						name(panel_A_GPA_`area'_`hed_parent'_`level',replace)	
			graph save "$FIGURES\COVID\covid_ece_gpa_`area'_`hed_parent'_`level'.gph" , replace	
			capture qui graph export "$FIGURES\COVID\covid_ece_gpa_`area'_`hed_parent'_`level'.eps", replace	
			capture qui graph export "$FIGURES\COVID\covid_ece_gpa_`area'_`hed_parent'_`level'.png", replace	
			capture qui graph export "$FIGURES\COVID\covid_ece_gpa_`area'_`hed_parent'_`level'.pdf", replace		
	