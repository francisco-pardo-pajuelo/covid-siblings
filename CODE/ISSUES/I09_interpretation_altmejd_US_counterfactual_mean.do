clear
set obs 10000

gen x = runiform()
gen z = x-0.5

gen above = z>=0
gen enr = above
replace enr = (1-above) if runiform()<0.05

gen z_above = z*above

gen y = 2*z*z + 1*above + rnormal()

gen not_enr = 1-enr
gen y_0 = y*(not_enr)


reg y above z z_above

reg y z above z_above
ivreg2 y z z_above (enr = above)
ivreg2 y_0 z z_above (not_enr = above) 
local ccm = _b[not_enr]
di `ccm'