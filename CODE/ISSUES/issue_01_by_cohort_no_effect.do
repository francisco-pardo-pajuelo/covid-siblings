*- When doing the TWFE by cohort, I get no effect. I think this is because the grader FE is absorbing all the effect as it works like a time fixed effect.

*- Does a time fixed effect absorb the effect in DD?
/*
clear

set obs 1000
gen treated = _n<_N/2
gen id = _n
expand 8

bys id: gen t=_n

gen post = t>=4
gen treated_post = treated*post

gen y = rnormal() + post + treated + treated_post

reghdfe y treated_post treated post, a(t)
*/



*- What if there is a time trend in the treated group?
set seed 1234

clear

set obs 100000 //OC/sibs
gen treated = _n<_N/2
gen cohort = floor(runiform()*20)-10
gen id = _n
expand 8 //years

bys id: gen t=_n

gen post = t>=4
gen treated_post = treated*post

sort id t
expand 10 //grades

bys id (t): gen g = cohort[1] + t - 1
drop if g<1 | g>9

sort id t g
order id t g treated 

gen x = rnormal()
bys t: egen t_fe = max(cond(_n==1,rnormal(),.)) //year fixed effects
gen g_trend = g
gen g_trend_treated = g*treated

gen y = x + post + 1*treated + -1*treated_post + t_fe + 0.2*g + 0.5*g*treated + rnormal()


reg y treated_post treated post
reghdfe y treated_post treated post, a(g)
reghdfe y treated_post treated post g_trend , a(g)
reghdfe y treated_post treated post g_trend g_trend_treated, a(g)
reghdfe y treated_post treated post if cohort==1, a(g)
reghdfe y treated_post treated post g_trend if cohort==1, a(g)
reghdfe y treated_post treated post g_trend g_trend_treated if cohort==1, a(g)

*- It is fixed if I add the time trend. 
*- Note that the subsamples don't average to the full sample treatment
forvalues i = -6(1)9 {
	reghdfe y treated_post treated post if cohort==`i', a(g)
	}

*- But for grades it is fine.
forvalues i = 1(1)9 {
	reghdfe y treated_post treated post if g==`i', a(g)
	}
		
	
