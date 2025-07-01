
********************************************************************************
* Regressions for tables #####
********************************************************************************


capture program drop rd_sensitivity
program define rd_sensitivity

	args outcome iv label semesters bw
	
	global iv = "`iv'"	
	
	//Define outcome globally in case needed to pass (for 'if_condition')
	global outcome = "`outcome'"
	
	//Sample
	global sem = "`semesters'"
	global bw_select "`bw'"

	*- Get "if" condition for each outcome
	if_condition // & h`heterog_type' == `likely_val'
	
	di "if_condition done"
  
	if inlist("`likely_val'","0","1")==1 	global if_final "${if_pre}"
	if inlist("`likely_val'","")==1 		global if_final "${if_pre}"					

			
	*-- Reduced form
	forvalues bw_window=1(1)10 { //We use integers instead of actual window in 0.1 steps for both easier labelling and because 'relocate' works better with integers.
	clonevar ABOVE`bw_window' = ABOVE //In order for ABOVE to be considered as different coefficients in each model and order them with coefplots independently so that we can place the optimal window at the appropriate place.
	label var ABOVE`bw_window'  "`bw_window'" // If we 'rename' in the coefplot command, the option 'relocate' does not work properly but rather would have to use the 'renamed' coefficients. This way it is easier to read the code.
	reghdfe ${outcome} ABOVE`bw_window'  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<`bw_window'/10, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.
		
		estimates store rf_rd_`bw_window'
		drop ABOVE`bw_window'
		//Save estimates
		/*
		preserve
			clear
			set obs 1
			gen outcome = "${outcome}"
			gen fam_type = "${fam_type}"
			gen type = "fixed"
			gen coef = _b[ABOVE]
			gen se = _se[ABOVE]
			gen window = `bw_window'/10
			gen if_final = "${if_final}"
			append using "$OUT\coefficients_rd"
			save "$OUT\coefficients_rd", replace emptyok
		restore
		*/
		}
	
	//temporary "optimal"
	global opt = .68
	global opt100 = int(${opt}*100)
	clonevar ABOVEopt = ABOVE
	label var ABOVEopt  "opt"
	reghdfe ${outcome} ABOVEopt  ${scores_1} ${ABOVE_scores_1} ///
	if ${if_final} ///
	& abs(score_relative)<${opt}, ///
	absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.
	
	estimates store rf_rd_opt
	drop ABOVEopt
	//Save estimates
	/*
		preserve
			clear
			set obs 1
			gen outcome = "${outcome}"
			gen fam_type = "${fam_type}"
			gen type = "optimal"
			gen coef = _b[ABOVE]
			gen se = _se[ABOVE]
			gen window = ${opt}
			gen if_final = "${if_final}"
			append using "$OUT\coefficients_rd"
			save "$OUT\coefficients_rd", replace emptyok
		restore
	*/
	*relocate(3.rep78 = 1.5 2.rep78 = 2.6 5.rep78 = 3.7 4.rep78 = 4.8 1.foreign = 5.9)	

end

global bw_select = "fixed"



open

global if_pre "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023)"

global if_pre "${if_pre}"

*- We get the optimal bandwidths
	if "${bw_select}" == "optimal" 	{
		rdrobust ${outcome} score_relative if ${if_pre} & ${if_apps}, ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(${iv}) ///
		  covs(year_app_foc_*) //  covs(year_app_foc_* uni_*) USING MORE PRECISE FIXED EFFECTS. ULTIMATELY IT SHOULD BE covs(id_cutoff_*)
		  
		  global bw_${outcome} = e(h_l)
	}
	
	if "${bw_select}" == "fixed" 			global bw_${outcome} = 0.694
	if inlist("`likely_val'","0","1")==1 	global if_final "${if_pre} & ${if_apps} & h`heterog_type' == `likely_val'"
	if inlist("`likely_val'","")==1 		global if_final "${if_pre} & ${if_apps}"						



reghdfe ${outcome} ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<${bw_${outcome}}, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.



//capture estimates drop rf_rd*
estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ applied_sib  	/*semesters*/ first /*bw*/ optimal
rd_sensitivity /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ applied_sib  	/*semesters*/ first /*bw*/ optimal

/*
preserve
	use "$OUT\coefficients_rd", clear
	list
	twoway (scatter coef window), yline(0) ylab(0(0.02)0.1)
restore
*/



*- We plot coefficients with 'coefplots' with models placed at the window value. So that 0.3 window is in 3/10s of the axis and optimal window is wherever it should be. This required a few adjustments (e.g. different coefficients for each estimation, labelling the variables, using integers).
coefplot 	(rf_rd_1 rf_rd_2 rf_rd_3 rf_rd_4 rf_rd_5 rf_rd_6 rf_rd_7 rf_rd_8 rf_rd_9 rf_rd_10, mcolor(gs0) ciopts(color(gs0 gs0 gs0)) levels(99 95 90)) ///
			(rf_rd_opt,mcolor(blue) ciopts(color(blue blue blue)) levels(99 95 90)), ///
				keep(ABOVE? ABOVE?? ABOVE???) ///
				xline(0) ///
				relocate(ABOVE1 = 10 ABOVE2 = 20 ABOVE3 = 30 ABOVE4 = 40 ABOVE5 = 50 ABOVE6 = 60 ABOVE7 = 70 ABOVE8 = 80 ABOVE9 = 90 ABOVE10 = 100 ABOVEopt = ${opt100})	///
				legend(off)

				


