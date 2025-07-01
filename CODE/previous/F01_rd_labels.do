global PDF = 0
global PNG = 1

*---------------------------*
*-----	A. RD ECE
*---------------------------*
use "$TEMP\students", clear

local cutoffs_grade = "std"
local grade = "2p"
local grade_outcome = "4p"

*- A.1. Define cutoffs and other variables
	
	//local subj = "m"
	//local year = "2014"
local year = 2016
	
//HERE GOES ONE YEAR LOOP
		foreach subj in "m" "c" {
			sum `cutoffs_grade'_`subj'_`grade' if year_`grade'==`year' & grupo_`subj'_`grade'==1
			local cutoff_1_`year'_`subj'_`grade' = r(max)
			sum `cutoffs_grade'_`subj'_`grade' if year_`grade'==`year' & grupo_`subj'_`grade'==3
			local cutoff_2_`year'_`subj'_`grade' = r(min)
			
			if `year'==2016 & "`subj'" == "c" replace grupo_`subj'_`grade' = if `cutoffs_grade'_`subj'_`grade'>`cutoff_1_`year'_`subj'_`grade'' 	& `cutoffs_grade'_`subj'_`grade'<`cutoff_2_`year'_`subj'_`grade'' & year_`grade'==`year'

			tab grupo_`subj'_`grade' if year_`grade'==`year'
			tab grupo_`subj'_`grade' if (`cutoffs_grade'_`subj'_`grade'-`cutoff_1_`year'_`subj'_`grade'')<0.0001 	& year_`grade'==`year'
			tab grupo_`subj'_`grade' if (`cutoffs_grade'_`subj'_`grade'-`cutoff_1_`year'_`subj'_`grade'')>0.0001 	& (`cutoffs_grade'_`subj'_`grade'-`cutoff_2_`year'_`subj'_`grade'')<-0.0001 & year_`grade'==`year'
			tab grupo_`subj'_`grade' if (`cutoffs_grade'_`subj'_`grade'-`cutoff_2_`year'_`subj'_`grade'')>-0.0001  	& year_`grade'==`year'
		}
	

//HERE GOES ONE YEAR LOOP
	foreach subj in "m" "c" {	
		*- ABOVE
		gen ABOVE_1_`subj'_`grade' = (`cutoffs_grade'_`subj'_`grade'>=`cutoff_1_`year'_`subj'_`grade'')
		gen ABOVE_2_`subj'_`grade' = (`cutoffs_grade'_`subj'_`grade'>=`cutoff_2_`year'_`subj'_`grade'')

		*- Relative score
		gen rscore_1_`subj'_`grade' = `cutoffs_grade'_`subj'_`grade' - `cutoff_1_`year'_`subj'_`grade''
		gen rscore_2_`subj'_`grade' = `cutoffs_grade'_`subj'_`grade' - `cutoff_2_`year'_`subj'_`grade''
	}
	
*- Relative score polynomial
	foreach subj in "m" "c" {	
		forvalues p = 1/3 {
			gen rscore_1_`subj'_`grade'_`p' = rscore_1_`subj'_`grade'^`p'
			gen rscore_2_`subj'_`grade'_`p' = rscore_2_`subj'_`grade'^`p'
			gen ABOVE_rscore_1_`subj'_`grade'_`p' = ABOVE_1_`subj'_`grade'*(rscore_1_`subj'_`grade'_`p'^`p')
			gen ABOVE_rscore_2_`subj'_`grade'_`p' = ABOVE_2_`subj'_`grade'*(rscore_2_`subj'_`grade'_`p'^`p')
		}	
	}
		
	
*- Example: 2014 and 2016. Students who had BOTH satisfactory:
gen same_school = id_ie_2p == id_ie_4p

*-- A.2. Simple graphical representation of bins
local subj = "c" 
local cutoffs_grade = "std"
local grade = "2p"

local outcome = "aspiration_4p_HE" // std_`subj'_4p aspiration_4p_HE same_school
local ece_label = 1

preserve
	if "`subj'" == "c" local subj_other = "m"
	if "`subj'" == "m" local subj_other = "c"
	keep if year_`grade'==`year'
	keep if grupo_`subj_other'_`grade' == 1
	sum rscore_`ece_label'_`subj'_`grade'_1
	keep if abs(rscore_`ece_label'_`subj'_`grade'_1)<1
	binscatter `outcome'  rscore_`ece_label'_`subj'_`grade'_1, n(50) xline(0)	
	reghdfe `outcome' ABOVE_`ece_label'_`subj'_`grade' rscore_`ece_label'_`subj'_`grade'_? ABOVE_rscore_`ece_label'_`subj'_`grade'_?, a(id_ie_4p)	
restore

*-- A.3. McCrary Test 
	local subj = "c"
	local grade = "2p"

	preserve	
		di `cutoff_1_`year'_`subj'_`grade''
		di `cutoff_2_`year'_`subj'_`grade''	
		
		if "`subj'" == "c" local subj_other = "m"
		if "`subj'" == "m" local subj_other = "c"
		keep if year_`grade'==`year'
		keep if grupo_`subj'_`subj_other' == 3
		kdensity `cutoffs_grade'_`subj'_`grade' ///
		, ///
		xline(`cutoff_1_`year'_`subj'_`grade'' `cutoff_2_`year'_`subj'_`grade'')
	restore

*-- A.4. Regression
reghdfe `outcome' ABOVE_2_`subj'_`grade' rscore_? ABOVE_rscore_2_`subj'_`grade'_?, a(id_ie_4p)
	
	
*-- A.5. Figure with fit and coefficients	
preserve
	local outcome = "aspiration_4p_PG"
	local running_score = "m500_m_2p"
	local cutoff_satisfactory = 639
	local xtitle = "2nd grade score"
	local ytitle = "Effect in 4th grade"
	local xmin = 150
	local xmax = 900
	local ylab = ""
	if "`outcome'" == "m500_m_4p" 		local ylab = "0(50)800"
	if "`outcome'" == "aspiration_4p_HE" 	mylabels 0(20)100, myscale(@/100) local(ylab)
	/*
	local bandwidth
	local min_age = 65-`bandwidth'
	local max_age = 65+`bandwidth'	
	*/
	bys `running_score': egen mean_`outcome' = mean(`outcome')

	//position textbox
	/*
	sum mean_`outcome'
	local min_indirect = r(min)	
	local x_text = `max_age' - 1	
	*/
	
	twoway	///
			(qfitci `outcome' `running_score' if `running_score'<`cutoff_satisfactory'				///
			, clc(gs10) clw(medthick) fc(gs13) alc(white) range(. `cutoff_satisfactory'))		///
			(qfitci `outcome' `running_score' if `running_score'>=`cutoff_satisfactory'			///
			,clc(gs10) clw(medthick) fc(gs13) alc(white))							///
			(scatter mean_`outcome' `running_score' 								///
			,msiz(medsmall) mc(black) mfc(black) mlw(vvthin)) 						///
			,																		///
			xtitle("`xtitle'") 														///
			ytitle("`ytitle'")  													///
			xlabel(`xmin'(50)`xmax') 											///
			ylabel(`ylab', angle(0))												///
			xline(`cutoff_satisfactory', lcolor(black) lpattern(dot)) legend(off)				///
			subtitle("`subtitle_indirect'", color(gs0)) 							///
			
			/*
			text(`min_indirect' `x_text'  											///
				"coef: `slopestar_indirect'" 										///
				"S.E.: `se_indirect'" 												///
				"pval: `pv_indirect'" 												///
				"N: `N_indirect'" 													///
				 ,box bcolor(gs15) place(sw) justification(left)) 					///	 
			///nodraw 																	///
			name(indirect_`outcome', replace)
			*/

restore	

*- Effect of 2nd grade ECE on 4th grade results, aspirations, same school



*- Effect of 2nd grade ECE on 8th grade results, aspirations, same school
	
	

keep if year_2p == 2016

kdensity m500_m_2p, xline(639)

gen aspiration_2p_PG = inlist(aspiration_2p,5) == 1 if aspiration_2p!=.
gen aspiration_4p_PG = inlist(aspiration_4p,5) == 1 if aspiration_4p!=.
gen aspiration_2s_PG = inlist(aspiration_2s,5) == 1 if aspiration_2s!=.

preserve
	local outcome = "aspiration_4p_PG"
	local running_score = "m500_m_2p"
	local cutoff_satisfactory = 639
	local xtitle = "2nd grade score"
	local ytitle = "Effect in 4th grade"
	local xmin = 150
	local xmax = 900
	local ylab = ""
	if "`outcome'" == "m500_m_4p" 		local ylab = "0(50)800"
	if "`outcome'" == "aspiration_4p_HE" 	mylabels 0(20)100, myscale(@/100) local(ylab)
	/*
	local bandwidth
	local min_age = 65-`bandwidth'
	local max_age = 65+`bandwidth'	
	*/
	bys `running_score': egen mean_`outcome' = mean(`outcome')

	//position textbox
	/*
	sum mean_`outcome'
	local min_indirect = r(min)	
	local x_text = `max_age' - 1	
	*/
	
	twoway	///
			(qfitci `outcome' `running_score' if `running_score'<`cutoff_satisfactory'				///
			, clc(gs10) clw(medthick) fc(gs13) alc(white) range(. `cutoff_satisfactory'))		///
			(qfitci `outcome' `running_score' if `running_score'>=`cutoff_satisfactory'			///
			,clc(gs10) clw(medthick) fc(gs13) alc(white))							///
			(scatter mean_`outcome' `running_score' 								///
			,msiz(medsmall) mc(black) mfc(black) mlw(vvthin)) 						///
			,																		///
			xtitle("`xtitle'") 														///
			ytitle("`ytitle'")  													///
			xlabel(`xmin'(50)`xmax') 											///
			ylabel(`ylab', angle(0))												///
			xline(`cutoff_satisfactory', lcolor(black) lpattern(dot)) legend(off)				///
			subtitle("`subtitle_indirect'", color(gs0)) 							///
			
			/*
			text(`min_indirect' `x_text'  											///
				"coef: `slopestar_indirect'" 										///
				"S.E.: `se_indirect'" 												///
				"pval: `pv_indirect'" 												///
				"N: `N_indirect'" 													///
				 ,box bcolor(gs15) place(sw) justification(left)) 					///	 
			///nodraw 																	///
			name(indirect_`outcome', replace)
			*/
restore

