
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
	forvalues bw_window=1(1)10 {
	reghdfe ${outcome} ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if ${if_final} ///
		& abs(score_relative)<`bw_window'/10, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.

		//Save estimates
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
		}
	
	//temporary "optimal"
	global opt = .68	
	reghdfe ${outcome} ABOVE  ${scores_1} ${ABOVE_scores_1} ///
	if ${if_final} ///
	& abs(score_relative)<${opt}, ///
	absorb(id_cutoff) cluster(id_fam_${fam_type}) //Altmejd et. al. include year FE, but cutoff is already defined at the semester level.
	
	//Save estimates
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
	
	*relocate(3.rep78 = 1.5 2.rep78 = 2.6 5.rep78 = 3.7 4.rep78 = 4.8 1.foreign = 5.9)	

end



open

//capture estimates drop rf_rd*
rd_sensitivity /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ applied_sib  	/*semesters*/ first /*bw*/ optimal

preserve
	use "$OUT\coefficients_rd", clear
	list
	twoway (scatter coef window), yline(0) ylab(0(0.02)0.1)
restore
/*
coefplot rf_rd_1 rf_rd_2 rf_rd_3 rf_rd_4 rf_rd_5 rf_rd_6 rf_rd_7 rf_rd_8 rf_rd_9 rf_rd_10 rf_rd_opt, ///
	keep(ABOVE) ///
	xline(0 .0148394) ///
	relocate(1.ABOVE= 0.1 2.ABOVE= 0.2 3.ABOVE= 0.3 4.ABOVE= 0.4 5.ABOVE= 0.5 6.ABOVE= 0.6 7.ABOVE= 0.7 8.ABOVE= 0.8 9.ABOVE= 0.9 10.ABOVE= 1 11.ABOVE = -1)	///
	legend(off)
*/