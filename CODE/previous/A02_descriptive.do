*- Descriptive Data


*-- 

open

keep if year_2p>=2009 & year_2p<=2016

gen u=runiform()
keep if u<0.01

preserve
	drop if year_2p==2013
	tab grupo_m_2p, gen(grupo_m_2p)
	graph bar grupo_m_2p?, ///
		over(year_2p) ///
		subtitle("Mathematics", color(gs0)) ///
		stack ///
		percent ///
		legend(label(1 "Early Stage") label(2 "In Process") label(3 "Satisfactory") pos(6) col(3))
		graph export "$FIG/grupos_m_2p.png", replace
		
	tab grupo_c_2p, gen(grupo_c_2p)
	graph bar grupo_c_2p?, ///
		over(year_2p) ///
		subtitle("Communications", color(gs0)) ///
		stack ///
		percent ///
		legend(label(1 "Early Stage") label(2 "In Process") label(3 "Satisfactory") pos(6) col(3))
		graph export "$FIG/grupos_c_2p.png", replace		
restore

*- Example 

	preserve	
		keep if year_2p == 2012
		sum cutoff_1_m_2p 
		local cutoff1 = r(mean)
		sum cutoff_2_m_2p 
		local cutoff2 = r(mean)
		kdensity std_m_2p  ///
		, ///
		xline(`cutoff1' `cutoff2')
		//graph export "$FIG/example_mccrary.png", replace
	restore
	

kdensity rscore_1_m_2p, xline(0) title("Score relative to 1st cutoff - Communications", color(gs0))
graph export "$FIG/example_mccrary1.png", replace
	
kdensity rscore_2_m_2p if abs(rscore_2_m_2p)<3, xline(0) title("Score relative to 2nd cutoff - Mathematics", color(gs0))
graph export "$FIG/example_mccrary2_m.png", replace