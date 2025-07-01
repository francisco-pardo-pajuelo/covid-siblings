clear
sysuse auto, clear


clonevar mpg1 = mpg
label var mpg1  "1"
reg price mpg1 if mpg>1
estimates store a
clonevar mpg2 = mpg
label var mpg2  "2.1"
reg price mpg2 if mpg>20
estimates store b
clonevar mpg3 = mpg
label var mpg3  "2.99"
reg price mpg3 if mpg>25
estimates store c


coefplot 	(a b, mcolor(gs0) ciopts(color(gs0 gs0 gs0)) levels(99 95 90)) ///
			(c,mcolor(blue) ciopts(color(blue blue blue)) levels(99 95 90)), ///
				keep(mpg?) ///
				relocate(mpg1 = 20 mpg2 = 80 mpg3 = 21 )  ///
				legend(off)
				
	
	
	ciopts(color(ebblue)
	
	
	
estimate_reg /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ applied_sib  	/*sibling*/ oldest /*relative to application*/ restrict /*semesters*/ first /*bw*/ optimal
rd_sensitivity /*OUTCOME*/ applied_sib 				/*IV*/ enroll_uni_major_sem_foc 	/*label*/ applied_sib  	/*sibling*/ oldest /*relative to application*/ restrict /*semesters*/ first /*bw*/ optimal
	