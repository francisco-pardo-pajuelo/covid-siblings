clear
set obs 1000

*- Objective
*-- To predict GRE given SAT and GPA in college:
*-- Challenge #1: The GPA is a good measure of ability but within college. GRE is a measure of ability comparable across colleges but we don't observe that.
*-- Challenge #2: We could proxy GRE by SAT, but that wouldn't take into account (i) their individual improvement compared to their college peers, (ii) their improvement from college FE.
*-- Method: Let's ignore (ii) for now, assuming there are no college FE, but only that GPA proxies a more updated measure of performance relative to your peers. Then, we can predict GRE by their GPA performance above their expected GPA performance given their SAT. That is, we add the residual of GPA ~ SAT + i.college to


//3 different colleges
gen college = mod(_n,3) + 1

//An observed measure of ability in t0 - comparable across colleges, but consider colleges have different means because different admission standards
gen SAT = 2*rnormal() + 3.5*(college==1)

//An unobserved measure of ability in t1 - comparable across colleges
gen GRE = SAT + 3*rnormal()

//An observed measure of ability in t1 - comparable within colleges. This is estimated from the unobserved measure (GRE)
bys college: egen GRE_mean = mean(GRE)
gen GPA = GRE - GRE_mean //demean them for each college so you miss the between college variation.
forvalues i = 1/3 {
	sum GPA if college==`i'
	replace GPA = (GPA-r(min))*3/(r(max)-r(min))+1 if college == `i'
}

replace GPA = GPA/2 if college==2
replace GPA = GPA - 1 if college==3


twoway 	(scatter GPA SAT if college==1) ///
		(scatter GPA SAT if college==2) ///
		(scatter GPA SAT if college==3)

//Can we recreate x_t1_unobs? And have a comparable measure of ability in t1?


*- To simplify things, we get standardized versions of the observed exams in t1
/*
bys college: egen x_t1_obs_mean = mean(x_t1_obs)
bys college: egen x_t1_obs_sd = sd(x_t1_obs)
gen z_t1_obs = (x_t1_obs-x_t1_obs_mean)/x_t1_obs_sd
*/

*- Method 1. We scale 'x_t1_obs' by the mean of 'SAT' in each class

reg GPA SAT i.college
predict resid, residual
/*
//Prediction accounting for different class averages
gen GRE_pred = SAT*_b[SAT]

//It is the same as SAT. Of course.. it is a linear prediction of it...
pwcorr SAT GRE GRE_pred
scatter GRE_pred SAT
*/
//We need to add the INDIVIDUAL information of the observed t1 exam
gen GRE_pred = SAT*_b[SAT] + resid
pwcorr GRE GRE_pred SAT
scatter GRE GRE_pred 


//Do results change if one of the GPAs has more variance? Or does it just affect the S.E. 
//Is it the same if we work with standardized measures of GPA (mean 0 , sd 1)?


//This is analogous to removing the fixed effect?
tab college, gen(college_)
reg z_t1_obs SAT college_?
gen z_t1_unobs3 = z_t1_obs
replace z_t1_unobs3 = z_t1_unobs3 - _b[college_1] if college==1
replace z_t1_unobs3 = z_t1_unobs3 - _b[college_2] if college==2
replace z_t1_unobs3 = z_t1_unobs3 - _b[college_3] if college==3

// The original measure does not explain all of it but the adjusted ones do.
pwcorr x_t1_unobs SAT z_t1_unobs2 z_t1_unobs3



reg z_t1_obs x_t0 if class==2
reg z_t1_obs x_t0 if class==3

twoway 	(scatter z_t1_obs x_t0 if class==1) ///
		(scatter z_t1_obs x_t0 if class==2) ///
		(scatter z_t1_obs x_t0 if class==3)