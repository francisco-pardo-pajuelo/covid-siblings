*- Issue: Based on the # of respondents in survey, I would expect less matches in 2P and 4P, but they remain proportional, why?


*- Example:
foreach g in "2p" "4p" "2s" {
	capture use "$TEMP\ece_family_`g'", clear
	capture use "$TEMP\ece_student_`g'", clear
	tab year_`g'
	count
	local N_`g': di %9.0f r(N)  
}

di "Total 2P: `N_2p'"
di "Total 4P: `N_4p'"
di "Total 2S: `N_2s'"

di `N_2p'/`N_2s' 
di `N_4p'/`N_2s' 

use "$OUT/applied_outcomes_2.dta", clear
foreach g in "2p" "4p" "2s" {
	tab year_`g'_sib aspiration_`g'_sib
	count if year_`g'_sib!=.
	local N_sib_`g': di %9.0f r(N)  
	count if aspiration_`g'_sib!=.
	local N_sib_sur_`g': di %9.0f r(N)  
	
}
di `N_sib_2p'/`N_sib_2s' 
di `N_sib_4p'/`N_sib_2s' 


di "Total sib 2P: `N_sib_2p'"
di "Total sib 4P: `N_sib_4p'"
di "Total sib 2S: `N_sib_2s'"

di `N_sib_sur_2p'/`N_sib_sur_2s' 
di `N_sib_sur_4p'/`N_sib_sur_2s' 

di "Total sib surv 2P: `N_sib_sur_2p'"
di "Total sib surv 4P: `N_sib_sur_4p'"
di "Total sib surv 2S: `N_sib_sur_2s'"


// Doesnt this mean the rate of match becomes higher as the age gap increases?

*- Conclussion: 

*- After though:  

*- Reference:  

/*

*/