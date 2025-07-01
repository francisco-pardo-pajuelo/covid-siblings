/********************************************************************************
- Author: Francisco Pardo
- Description: Simulation of spurious bunching in RD when cutoffs are estimated from data.
- Date started: 02/11/2025
- Last update: 02/11/2025
*******************************************************************************/

	clear
	set seed 123456
	
	global uniform = 0
	
	*- Number of schools/classes (cells/cutoffs)
	set obs 10000
	gen school = _n
	
	*- Number of students per cell/cutoff 
	expand 300
	bys school: gen student = _n
	
	*- Assign randomly distributed scores
	gen score = round((rnormal()*10))
	
	*- Covariate (correlated with score). To test validity
	gen ses = 0.5*(score) + rnormal()*10

	*- Pick one cutoff at random
	if ${uniform} == 1 {
		gen u=runiform()
		bys school (u): gen cutoff = score[1]
		}
		
	if ${uniform} == 0 {
		gen e=score+round((rnormal()*30))
		bys school (e): gen cutoff = score[1]
		}
		
	*- We create cutoffs like this so that they are slightly shifted to lower scores. We could also use a uniform distribution.	
	twoway (kdensity score) (kdensity cutoff), legen(label(1 "Score") label(2 "Cutoffs"))
	
	*- Alternative cutoff: average between marginal students
	bys school: egen max_below = max(cond(score<cutoff,score,.))
	bys school: egen min_above = min(cond(score>=cutoff,score,.))
	gen cutoff_mean = (max_below+min_above)/2
	
	*- Define relative score with respect to cutoff
	gen score_rel 	= score-cutoff
	gen score_rel_2 = score-cutoff_mean
	
	*- We get spurious bunching at 0 in the first one
	histogram score_rel, discrete
	
	*- We can solve this by removing the students at the cutoff
	histogram score_rel if score!=cutoff, discrete
	
	*- We also get bunching in the second one, but more spread around the cutoff
	histogram score_rel_2, discrete
	
	*- This is not neccessarilly solved by removing the one at the cutoff since the problem happens in an interval around the cutoff
	histogram score_rel_2 if score!=cutoff, discrete	
	
	*- Covariates are still smooth around the cutoff:
	preserve
		keep if score!=cutoff
		collapse ses, by(score_rel)
		bys score_rel: keep if _n==1
		scatter ses score_rel if abs(score_rel)<10
	restore
	
	*- Weird pattern when taking averages. Probably caused by continuous scores giving .5 but more spread giving integers....?
	preserve
		keep if score!=cutoff
		collapse ses, by(score_rel_2)
		bys scorescore_rel_2_rel: keep if _n==1
		scatter ses score_rel_2 if abs(score_rel_2)<10
	restore
	
	****
	* This is spurious bunching and my belief is that it does not threatens validity. 
	* Covariates are still smooth around cutoff
	* Doing the average actually makes it worst, as it spreads the issue into a bunching not at 0 but around 0. 
	* Attenuated, but less easy to fix compared to just removing 0.
	****


