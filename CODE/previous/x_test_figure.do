*- Figure

//keep if runiform()<0.1

*- Figure 1
binsreg admitted score_relative if /// 
						1==1 ///
						, ///
						xline(0) ///
						xtitle("Score relative to cutoff") ///
						ytitle("`outcome_label'") ///
						absorb(id_cutoff) nbins(100)	///
						polyreg(1) ///
						by(ABOVE)


binsreg applied_sib score_relative if /// 
						1==1 ///
						, ///
						xline(0) ///
						xtitle("Score relative to cutoff") ///
						ytitle("`outcome_label'") ///
						absorb(id_cutoff) nbins(100)	///
						polyreg(1) ///
						by(ABOVE)

						
rdplot aspiration_years_2s_sib score_relative , ///
		nbins(30 30) ///
		nselect(qs) ///
		p(1) ///
		graph_options(legend(off) ysize(3) xsize(5.5) xlabel(-2(1)2) xtitle("Score relative to cutoff") ytitle("Admitted") ylabel(, glpattern(dash) glcolor(gs14) angle(0)) graphregion(color(white) lcolor(white))) 
						
//Dont show the same
global outcome applied_sib

reg 	$outcome ABOVE $scores_1 $ABOVE_scores_1   	
reghdfe $outcome ABOVE $scores_1 $ABOVE_scores_1  	  , a(id_cutoff) cluster(id_fam_4)						

capture drop id_cutoff_*
preserve
	keep if id_cutoff<500
	tab id_cutoff, gen(id_cutoff_)
	count
	rdrobust $outcome score_relative, kernel(uniform) c(0) p(1)
	local bw = e(h_l) //Get bandwith for IK
		
	display as text ///
	"******** Bandwidth ********" _n ///
	"Bandwidth :" %9.2f `bw' _n ///
	"***************************"
	
	rdrobust $outcome score_relative, kernel(uniform) c(0) p(1) covs(id_cutoff_*)
	local bw = e(h_l) //Get bandwith for IK
		
	display as text ///
	"******** Bandwidth ********" _n ///
	"Bandwidth :" %9.2f `bw' _n ///
	"***************************"	
	
	//Is it the same if we use demeaned outcomes?
	bys id_cutoff: egen mean_${outcome} = mean($outcome)
	gen dm_applied_sib = $outcome - mean_${outcome}
	
	rdrobust dm_${outcome} score_relative, kernel(uniform) c(0) p(1)
	local bw = e(h_l) //Get bandwith for IK
		
	display as text ///
	"******** Bandwidth ********" _n ///
	"Bandwidth :" %9.2f `bw' _n ///
	"***************************"	
restore
	
															
*With individual controls: sex, religion, district & (5th order polynomial)
reghdfe applied_sib ABOVE $scores_1 $ABOVE_scores_1  if  abs(score_relative)<=`bw'	  , a(id_cutoff) cluster(id_fam_4)
*estimates store e2_`i'_`s'
matrix A = r(table)
/*
local ABOVE_N_`i'_0_`s'_r = e(N)
local ABOVE_b_`i'_0_`s'_r = A[1,1]
local ABOVE_se_`i'_0_`s'_r = A[2,1]
local ABOVE_pv_`i'_0_`s'_r = A[4,1]
local ABOVE_bw_`i'_0_`s'_r = `bw_r'

count if ABOVE==1 & e(sample)==1
local ABOVE_Nr_`i'_0_`s'_r = r(N)
count if ABOVE==0 & e(sample)==1
local ABOVE_Nl_`i'_0_`s'_r = r(N)
*/
