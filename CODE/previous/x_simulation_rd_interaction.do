*- Simulation of RD with interaction when score has different slopes.
clear
set obs 1000000

gen below_med = mod(_n,2)
gen rel_score = rnormal()

gen ABOVE = rel_score>0
gen ABOVE_below = ABOVE*below_med

gen ABOVE_rel_score = ABOVE*rel_score


*-- With exponential relationship
gen y_exp1 =  		0.2*exp(rel_score) + 0.3*ABOVE 	- 0.2*ABOVE_below + rnormal()/5

gen y_exp2 		=  	0.2*exp(rel_score) + 0.3*ABOVE 					 + rnormal()/5 if below_med == 0
replace y_exp2 	=  	0.1*exp(rel_score) + 0.3*ABOVE - 0.2*ABOVE_below + rnormal()/5 if below_med == 1

// Here, it works well.
rdrobust y1 rel_score
local bw1 = e(h_l)
reg y1 ABOVE ABOVE_below rel_score ABOVE_rel_score if abs(rel_score) < `bw1'

rdrobust y2 rel_score
local bw2 = e(h_l)
reg y2 ABOVE ABOVE_below rel_score ABOVE_rel_score if abs(rel_score) < `bw2'


//What if the jump for those below_median occurs in cases were the slope for running variable is different.


