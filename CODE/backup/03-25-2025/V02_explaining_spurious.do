/********************************************************************************
- Author: Francisco Pardo
- Description: Simulation of spurious bunching in RD when cutoffs are estimated from data.
- Date started: 02/11/2025
- Last update: 02/11/2025
*******************************************************************************/

	clear
	set seed 1234
	
	*- Number of schools/classes (cells/cutoffs)
	set obs 100
	gen school = _n
	
	*- Number of students per cell/cutoff 
	expand 10
	bys school: gen student = _n
	
	*- Assign randomly distributed scores
	gen score = round((rnormal()*30))

	*- Pick one cutoff at random
	gen u=runiform()
	bys school (u): gen cutoff = score[1]
	
	*- Define relative score with respect to cutoff
	gen score_rel = score-cutoff
	
	*- We get spurious bunching at 0.
	histogram score_rel
	
	****
	* My reading is that this is caused by each cell always having some student EXACTLY at 0. 
	* Still, this is spurious and does not threat validity. 
	* Covariates should still be smooth around cutoff
	****
	
	*- Illustrating issue by looking at some cutoff/cells
	twoway 	(histogram score_rel if school==2, discrete frequency) (scatteri 0 0 1 0 , c(l) m(i) lpattern(dash)), name(school_2, replace) legend(off) xlabel(-50 65) xsize(10) ysize(2)
	twoway 	(histogram score_rel if school==3, discrete frequency) (scatteri 0 0 1 0 , c(l) m(i) lpattern(dash)), name(school_3, replace) legend(off) xlabel(-50 65) xsize(10) ysize(2)
	twoway 	(histogram score_rel if school==7, discrete frequency) (scatteri 0 0 1 0 , c(l) m(i) lpattern(dash)), name(school_7, replace) legend(off) xlabel(-50 65) xsize(10) ysize(2)

	twoway 	(histogram score_rel if inlist(school,2,3,7)==1, discrete frequency) (scatteri 0 0 3 0 , c(l) m(i) lpattern(dash)), name(school_pool, replace) legend(off) xlabel(-50 65) xsize(10) ysize(2)
	
	graph combine school_2 school_3 school_7 school_pool, col(1) xsize(10) ysize(20)
	