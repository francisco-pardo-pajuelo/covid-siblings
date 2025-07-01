*- Simulation: Check how weights work in stacked RD

clear 

set obs 2
gen id = _n

expand 1000000

tab id, gen(id)
gen z = rnormal() if id==1
replace z = rnormal()-2 if id==2

gen above = z>0

gen z_above = z*above

gen y = above*1*(id==1) + above*3*(id==2) + rnormal()/10

reghdfe y above z z_above , a(id)
reghdfe y above z z_above if abs(z)<0.01, a(id)

tab id if abs(z)<0.01 

di .88*1+.11*3


//Conclussion: Weights is not overall N but just around the cutoff.