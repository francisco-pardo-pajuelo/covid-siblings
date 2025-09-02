*- Why 2022 ECE 8th grade reverse pattern?

*-- Let's compare the baseline 2nd ECE from 2022 (2016) and 2019 (2013)


use "$TEMP\pre_reg_covid${covid_data}", clear

keep if grade==2
keep if score_math_2s!=. & score_com_2s!=.
keep if base_score_com_2p!=. &  base_score_math_2p!=.
keep if year<=2022

tabstat base_score_math*_2p base_score_com*_2p base_*math_std*_2p base_*com_std*_2p, by(year)
tabstat score_*_2p, by(year)
tabstat score_*_2s, by(year)

tab year


ds  