*- Why so few observations from 8th grader when 4+ years of age-gap?

*-- Issue: Those who take it in 8th grade, have an age gap of 4 years with those applying, righ?
/*
2018: take 8th grade
2018: 9 (1), 10 (2), 11 (3), applying(4)
So those taking exam in 2018 and siblings applying in 2017-2018, or those taking exam in 2019 and applying in 2017-2019? Should be more than 200 obs.

*/


use "$OUT/applied_outcomes_2.dta", clear

keep if year_2s_sib>=year_app_foc & year_2s_sib!=.

gen age_gap = exp_graduating_year1_sib-exp_graduating_year1_foc

tab year_2s_sib year_app_foc
table year_2s_sib year_app_foc, stat(mean age_gap)
//conclussion: I had the labels wrong, it was actually <=3 the one that didn't have observations. And that makes sense. If age gap is <3, most likely they won't have information on standardized exam and someone applying at or after that since that implies 4+ years of gap. Perhaps use another measure like dropout.
