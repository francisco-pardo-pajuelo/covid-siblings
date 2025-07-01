*- Simulation of bunching that does not cause an issue:

clear
set obs 1000000
gen x=rnormal()
local cutoff= 0.5

gen ABOVE = x>=`cutoff'


expand 50 if x>=0.5 & x<0.51

gen y = 0.5*x+0.3*x*ABOVE + 0.4*ABOVE + rnormal()

gen ABOVE_x = ABOVE*x

reg y  ABOVE x ABOVE_x
//Not biased

reg y  ABOVE x ABOVE_x if !(x>=0.5 & x<0.51)
reg y  ABOVE x ABOVE_x if abs(x-`cutoff')>0.105
//Even possibly better than removing obs.

histogram x

