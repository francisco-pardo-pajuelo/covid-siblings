
*- Work with example
local focus_sample = 0

local cutoffs_grade = "std"
local grade = "2p"

local subj = "m"

local grade_outcome = "2s"
local outcome = "std_`subj'_`grade_outcome'" // std_`subj'_`grade_outcome' aspiration_`grade_outcome'_HE same_school std_m_2p_ie
local ece_label = 1

local cutoff = 0

local bandwidth = 0.5
		
open

keep if year_2p>=2009
//keep if year_2p==2016

*-- Keep focus sample
if `focus_sample' == 1 {
	gen sample = . 
	replace sample = 1 if pct_info_grades_HIGH>50
	//replace sample = 1 if positive_bias_math==1
	//replace sample = 1 if negative_bias_math==1
	keep if sample==1
	}

	
	
*-- Overall results

	if "`subj'" == "c" local subj_other = "m"
	if "`subj'" == "m" local subj_other = "c"
	//keep if year_`grade'==`year'
	//keep if grupo_`subj_other'_`grade' == 1
	sum rscore_`ece_label'_`subj'_`grade'_1
	keep if abs(rscore_`ece_label'_`subj'_`grade'_1)<`bandwidth'

	global x_running_1 			= "rscore_`ece_label'_`subj'_`grade'_1  ABOVE_rscore_`ece_label'_`subj'_`grade'_1" //event_time_self1_? above_event_time_self1_?
	global x_running 			= "rscore_`ece_label'_`subj'_`grade'_?  ABOVE_rscore_`ece_label'_`subj'_`grade'_?" //event_time_self1_? above_event_time_self1_?
	
	reghdfe `outcome' ABOVE_`ece_label'_`subj'_`grade' $x_running_1

	reghdfe `outcome' ABOVE_`ece_label'_`subj'_`grade' $x_running_1,  a(year_`grade')	
	mat res = r(table)
	local slope	: display %9.3f  res[1,1]
	local se	: display %9.3f  res[2,1]
	local pv	: display %9.3f  res[4,1]
	local N		: display %9.0fc  e(N)	
	local slopestar = "`slope'"
	if `pv'<=0.01 local slopestar = "`slope'" + "***"
	if `pv'>0.01 & `pv'<=0.05 local slopestar = "`slope'" + "**"
	if `pv'>0.05 & `pv'<=0.1 local slopestar = "`slope'" + "*"	

	reghdfe `outcome' ABOVE_`ece_label'_`subj'_`grade' $x_running, a(year_`grade')	
	
	
	reghdfe `outcome' ABOVE_`ece_label'_`subj'_`grade' $x_running_1,  a(id_ie_`grade_outcome')	
	
	reghdfe `outcome' ABOVE_`ece_label'_`subj'_`grade' $x_running, a(id_ie_`grade_outcome')	
	

//Details of graph
local running_age = "rscore_`ece_label'_`subj'_`grade'_1"
local xtitle = "Standardized 2nd grade score"

if "`grade_outcome'"=="4p" local ygrade = "4th"
if "`grade_outcome'"=="2s" local ygrade = "8th"

if "`outcome'" == "std_`subj'_`grade_outcome'"  	local ytitle = "Standardized `ygrade' grade score"
if "`outcome'" == "aspiration_`grade_outcome'_HE" 	local ytitle = "% expects HE in `ygrade'"
if "`outcome'" == "std_`subj'_`grade_outcome'_ie" 	local ytitle = "Standardized `ygrade' grade score of class"



distinct rscore_`ece_label'_`subj'_`grade'_1
bys year_`grade' rscore_`ece_label'_`subj'_`grade'_1: egen mean_`outcome' 	= mean(`outcome')
sum mean_`outcome'
local text_y = r(max) //below results
local text_x = 0.2 //right of cutoff


//rdplot `outcome' `running_age'

twoway	///
		(lfitci `outcome' `running_age' if `running_age'<`cutoff'				///
		, clc(gs10) clw(medthick) fc(gs13) alc(white) range(. `cutoff'))		///
		(lfitci `outcome' `running_age' if `running_age'>=`cutoff'			///
		,clc(gs10) clw(medthick) fc(gs13) alc(white))							///
		(scatter mean_`outcome' `running_age' 		if mean_`outcome'< 1500						///
		,msiz(medsmall) mc(black) mfc(black) mlw(vvthin)) 						///
		,																		///
		xtitle("`xtitle'") 														///
		ytitle("`ytitle'")  													///
		xlabel(-`bandwidth'(0.2)`bandwidth') 											///
		///ylabel(`ylab', angle(0))												///
		xline(`cutoff', lcolor(black) lpattern(dot)) legend(off)				///
		///subtitle("`subtitle_indirect'", color(gs0)) 							///
		text(`text_y' `text_x'  											///
			"coef: `slopestar'" 										///
			"S.E.: `se'" 												///
			"pval: `pv'" 												///
			"N: `N'" 													///
			 ,box bcolor(gs15) place(sw) justification(left)) 					///	 
		///nodraw 																	///
		name(`outcome', replace)
		graph export 	"$FIG//RD_overall_m_`grade_outcome'_`outcome'.png", replace
		//graph export 	"$FIG//RD_`outcome'_sample`same_plan'.pdf", replace	
	
	