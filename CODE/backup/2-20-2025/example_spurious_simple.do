/********************************************************************************
- Author: Francisco Pardo
- Description: Simulation of spurious bunching in RD when cutoffs are estimated from data.
- Date started: 02/11/2025
- Last update: 02/11/2025
*******************************************************************************/

	clear
	set seed 1234
	
	global uniform = 0
	
	*- Number of schools/classes (cells/cutoffs)
	set obs 10000
	gen school = _n
	
	*- Number of students per cell/cutoff 
	expand 100
	bys school: gen student = _n
	
	*- Assign randomly distributed scores
	gen score = round((rnormal()*30))
	
	*- Covariate (correlated with score). To test validity
	gen ses = 0.5*(score) + rnormal()*30

	*- Pick one cutoff at random
	//uniform
	if ${uniform} == 1 {
		gen u=runiform()
		bys school (u): gen cutoff = score[1]
		}
		
	//biased towards lower scores	
	if ${uniform} == 0 {
		gen e=score+round((rnormal()*30))
		bys school (e): gen cutoff = score[1]
		}
		
	*- Pick one fixed cutoff
	bys school: gen cutoff_fixed = round((rnormal()*30))-20
		
	*- We create cutoffs like this so that they are slightly shifted to lower scores. We could also use a uniform distribution.	
	twoway (kdensity score) (kdensity cutoff), legen(label(1 "Score") label(2 "Cutoffs"))
	twoway (kdensity score) (kdensity cutoff_fixed), legen(label(1 "Score") label(2 "Cutoffs (fixed)"))
	
	*- Define relative score with respect to cutoff
	gen score_rel 			= score-cutoff
	gen score_rel_fixed 	= score-cutoff_fixed
	
	*- We get spurious bunching at 0 in the first one, but not if the cutoff is fixed and unrelated to applicant pool
	histogram score_rel, discrete
	histogram score_rel_fixed, discrete
	
	*- We can solve this by removing the students at the cutoff
	histogram score_rel if score!=cutoff, discrete
	
	*- Covariates are still smooth around the cutoff:
	keep if score!=cutoff
	collapse ses, by(score_rel)
	bys score_rel: keep if _n==1
	scatter ses score_rel if abs(score_rel)<30, ytitle("Socioeconomic Status") xtitle("Relative score") xline(0)

	
	****
	* This is spurious bunching and my belief is that it does not threatens validity. 
	* Covariates are still smooth around cutoff
	* The issue is solved by removing those at the cutoff
	****


