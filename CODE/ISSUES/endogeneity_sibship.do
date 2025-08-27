clear
set obs 1000000

gen H=mod(_n,2)

gen S=(rnormal()-H*2)>0

gen E=(rnormal()-H*2)>0

label var H "Unobservable - parents of Type H" //care more about quality and have less children
label var S "Observable - Have more than 1 children"
label var E "Observable - Educated parents"

gen y = rnormal()+(H==1)*1+(H==0)*0.5+0.2 + (S==1)*0.2
//If H affects Y, then does controlling for E helps?

reg y S E

reg y S if E==0
reg y S if E==1
