clear
set obs 100000

gen id = _n
gen t = _n<_N/2

expand 5

sort id
bys id: gen year = _n

replace year = year-3

gen y = rnormal() + t

replace y=0 if y<0 & year>=0

collapse y, by(t year)

twoway (line y year if t==0) (line y year if t==1), legend(order(1 "Control" 2 "Treated"))

