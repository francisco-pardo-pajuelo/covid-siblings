
local if "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app)"
reghdfe applied_sib ABOVE  ${scores_1} ${ABOVE_scores_1} ///
		if `if' ///
		& abs(score_relative)<0.616, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type})

ivreghdfe applied_sib (enroll_foc=ABOVE)  ${scores_1} ${ABOVE_scores_1} ///
		if `if' ///
		& abs(score_relative)<0.616, ///
		absorb(id_cutoff) cluster(id_fam_${fam_type})		
		
local if "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app)"

keep id_cutoff year_app universidad applied_sib score_relative exp_graduating_year1_sib  enroll_uni_major_sem_foc id_fam_4

drop id_cutoff_department
capture drop year_app_* uni uni_* id_cutoff_*
tab year_app, gen(year_app_)
encode universidad, gen(uni)
tab uni, gen(uni_)
tab id_cutoff, gen(id_cutoff_)

timer clear 1
timer on 1
	rdrobust applied_sib score_relative if `if', ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(enroll_uni_major_sem_foc)
timer off 1

timer clear 2
timer on 2		  
	rdrobust applied_sib score_relative if `if', ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(enroll_uni_major_sem_foc) ///
		  covs(year_app_*)		
timer off 2

timer clear 3
timer on 3		  
	rdrobust applied_sib score_relative if `if', ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(enroll_uni_major_sem_foc) ///
		  covs(year_app_* uni_*)	  
timer off 3

timer clear 4
timer on 4		  
	rdrobust applied_sib score_relative if `if', ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(enroll_uni_major_sem_foc) ///
		  covs(id_cutoff_*)	  
timer off 4

timer list 1 
timer list 2
timer list 3
timer list 4


local if "(exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023) & (exp_graduating_year1_sib+2>=year_app)"

keep if `if'
capture drop year_app_* uni uni_* id_cutoff_*
tab year_app, gen(year_app_)
encode universidad, gen(uni)
tab uni, gen(uni_)
tab id_cutoff, gen(id_cutoff_)


timer clear 5
timer on 5
	rdrobust applied_sib score_relative if `if', ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(enroll_uni_major_sem_foc)
timer off 5

timer clear 6
timer on 6		  
	rdrobust applied_sib score_relative if `if', ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(enroll_uni_major_sem_foc) ///
		  covs(year_app_*)		
timer off 6

timer clear 7
timer on 7		  
	rdrobust applied_sib score_relative if `if', ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(enroll_uni_major_sem_foc) ///
		  covs(year_app_* uni_*)  
timer off 7

timer clear 8
timer on 8		  
	rdrobust applied_sib score_relative if `if', ///
		  c(0) ///
		  p(1) ///
		  q(2) ///
		  kernel(triangular) ///
		  bwselect(mserd) ///
		  vce(cluster id_fam_${fam_type}) ///
		  all ///
		  fuzzy(enroll_uni_major_sem_foc) ///
		  covs(id_cutoff_*)  
timer off 8


timer list 5
timer list 6
timer list 7
timer list 8




timer list 1 
timer list 2
timer list 3
timer list 4
timer list 5
timer list 6
timer list 7
timer list 8