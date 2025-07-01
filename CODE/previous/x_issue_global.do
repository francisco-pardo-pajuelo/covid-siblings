


clear all

sysuse auto, clear
ivreg2 price  (turn = weigh)


clear all

capture program drop regress
program define regress

	sysuse auto, clear
	ivreg2 price  (turn = weigh)

end


test


