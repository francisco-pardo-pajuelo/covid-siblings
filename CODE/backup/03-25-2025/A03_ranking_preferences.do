/********************************************************************************
- Author: Francisco Pardo
- Description: Studies preferences over unviersities
- Date started: 12/16/2024
- Last update: 12/16/2024

- Changes to original dofile:
	1. 
*******************************************************************************/

capture program drop main 
program define main 


setup


end


********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup

	clear

end

 
********************************************************************************
* Probability of enrolling given admission
* 
* Description: One measure of preference for school is how many actually choose to enroll given they've been admitted. If being admitted to >1, then people would likely choose the one they prefer.
********************************************************************************

capture program drop prob_admission
program define prob_admission

	clear
	
	use "$TEMP\applied", clear
	
	drop if id_per_umc == ""
	count
	local N=r(N)
	bys id_per_umc semester: keep if _N>1
	keep if admitted==1
	bys id_per_umc semester: keep if _N>1
	count
	local N_mult_adm =  r(N)
	local sample: display %9.2f `N_mult_adm'/`N'*100
	di as text "`sample'% of initial sample"
	
	//Since enrollment is per uni-major-semester, we keep at that level (in case multiple applications). We start with sem-uni
	bys id_per_umc universidad semester: keep if _n==1
	merge 1:1 id_per_umc universidad semester using  "$TEMP\enrolled_students_university_semester", keep(master match)
	gen enrolled = (_m==3)
	
	preserve
		sum enrolled if public==0
		local m_pri = r(mean)
		local m_pri_text: display %9.1f r(mean)*100 "%"
		local m_pri_coord = r(mean)-0.20

		sum enrolled if public==1 
		local m_pub = r(mean)
		local m_pub_text: display %9.1f r(mean)*100 "%"
		local m_pub_coord = r(mean)+0.015

		collapse (sum) tot_admitted=admitted tot_enrolled=enrolled (mean) enrolled, by(universidad public year)		
		sort enrolled
		list enrolled universidad, sep(1000)
			// Why is UNMSM so low? 24% of admitted enroll? This must be wrong...
			// It seems to be that among those who are admitted to multiple ones, this happens to be the case... Many prefer UNI and PUCP, but many others that could be considered lower quality.
		sum enrolled 
		twoway 	(histogram enrolled if public==1, bins(30) fcolor(blue%20) lcolor(blue%80) xline(`m_pub', lcolor(blue))) ///
				(histogram enrolled if public==0, bins(30) fcolor(green%20) lcolor(green%80) xline(`m_pri', lcolor(green))) ///
				, ///
				xtitle("P(Enrollment | Admitted)") ///
				legend(label(1 "Public") label(2 "Private") pos(6) col(2)) ///
				text(4 `m_pub_coord'  ///
					"Public mean:" "`m_pub_text'" ///
					 ,box bcolor(gs16) place(ne)  justification(left)) ///
				text(4 `m_pri_coord'  ///
				"Private mean:" "`m_pri_text'" ///
				 ,box bcolor(gs16) place(ne)  justification(left))	 


	restore

	
	/*
	This measure of P(enroll | admitted) seems strange. Elite publics like UNMSM have really low ranking. Perhaps this is because those admitted to those also have really good options? How can we construct one measure that considers this bias in the alternatives. That is, given the preferences and choices people face and make, how can we infer quality of product?
	
	if A>B 
	and B>C
	We have to be able to say A>B>C, even though B looses more times than C because A-B appears more times than B-C.
	
	Is this choice models?
	*/
	
end


 
********************************************************************************
* counterfactual
* 
* Description: Characterize applicants between those whose counterfactual is no enroll at all and enroll in private
********************************************************************************

capture program drop counterfactual
program define counterfactual

	clear
	
	use "$TEMP\applied", clear
	
	*-1. How many of public-applicants also apply to private?
	
	*-2. How many of privates apply to public?
	
	*-3. Non-admitted, characterize private-enrollers vs keep triyng vs never enrolling.

end



********************************************************************************
* Run program
********************************************************************************

main

