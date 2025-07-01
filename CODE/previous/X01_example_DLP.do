global PDF = 0
global PNG = 1

*---------------------------*
*-----	A. RD ECE
*---------------------------*
use "$TEMP\students", clear

local cutoffs_grade = "std"
local grade = "2p"
local grade_outcome = "4p"

local year = 2016

*- Let's keep most potential sample

*-- Those who likely received information
preserve
	gen info_grades_HIGH = inlist(satisfied_opportunities_3,4)==1 if satisfied_opportunities_3!=.
	collapse info_grades_HIGH, by(id_ie_4p)
	xtile pct_info_grades_HIGH = info_grades_HIGH, n(100)
	rename id_ie_4p id_ie
	tempfile info_grades_HIGH
	save `info_grades_HIGH', replace
restore

rename id_ie_2p id_ie
merge m:1 id_ie using `info_grades_HIGH'
rename id_ie id_ie_2p

*-- Those who have big bias:
capture drop positive*
capture drop negative*
gen positive_bias_math = (inlist(current_m,3,4) == 1 & pct_m_2p<40) if current_m!=. & pct_m_2p!=.
gen positive_bias_comm = (inlist(current_c,3,4) == 1 & pct_c_2p<40) if current_c!=. & pct_c_2p!=.
gen negative_bias_math = (inlist(current_m,1,2) == 1 & pct_m_2p>60) if current_m!=. & pct_m_2p!=.
gen negative_bias_comm = (inlist(current_c,1,2) == 1 & pct_c_2p>60) if current_c!=. & pct_c_2p!=.



*- DLP PRESENTATION: Prepare data
//keep if year_`grade' == `year'
gen cutoff_1_m_2p = .
gen cutoff_2_m_2p = .
gen cutoff_1_c_2p = .
gen cutoff_2_c_2p = .
forvalues year = 2007/2016 {
	foreach subj in "m" "c" {	
		sum `cutoffs_grade'_`subj'_`grade' if year_`grade'==`year' & grupo_`subj'_`grade'==2
		replace cutoff_1_`subj'_2p = r(min) if year_`grade'==`year'
		sum `cutoffs_grade'_`subj'_`grade' if year_`grade'==`year' & grupo_`subj'_`grade'==3
		replace cutoff_2_`subj'_2p = r(min) if year_`grade'==`year'
	}
}

tab grupo_m_2p
tab grupo_m_2p if std_m_2p <cutoff_1_m_2p
tab grupo_m_2p if std_m_2p >= cutoff_1_m_2p & std_m_2p <cutoff_2_m_2p
tab grupo_m_2p if std_m_2p >= cutoff_2_m_2p

tab grupo_c_2p
tab grupo_c_2p if std_c_2p <cutoff_1_c_2p
tab grupo_c_2p if std_c_2p >= cutoff_1_c_2p & std_c_2p <cutoff_2_c_2p
tab grupo_c_2p if std_c_2p >= cutoff_2_c_2p
//Fix 2009, seems not sharp? the cutoff is present in both level 2 and 3... how was it defined then?


//Not coded correctly by our algorithm? but actually sharp
//replace grupo_c_2p =  2 if `cutoffs_grade'_c_2p>cutoff_1_c_2p 	& `cutoffs_grade'_c_2p<=cutoff_2_c_2p & year_2p==2016

/*
tab grupo_`subj'_`grade' if year_`grade'==`year'
tab grupo_`subj'_`grade' if (`cutoffs_grade'_`subj'_`grade'-`cutoff_1_`year'_`subj'_`grade'')<0.0001 	& year_`grade'==`year'
tab grupo_`subj'_`grade' if (`cutoffs_grade'_`subj'_`grade'-`cutoff_1_`year'_`subj'_`grade'')>0.0001 	& (`cutoffs_grade'_`subj'_`grade'-`cutoff_2_`year'_`subj'_`grade'')<-0.0001 & year_`grade'==`year'
tab grupo_`subj'_`grade' if (`cutoffs_grade'_`subj'_`grade'-`cutoff_2_`year'_`subj'_`grade'')>-0.0001  	& year_`grade'==`year'
*/

//HERE GOES ONE YEAR LOOP
foreach subj in "m" "c" {
	*- ABOVE
	gen ABOVE_1_`subj'_`grade' = (`cutoffs_grade'_`subj'_`grade'>=cutoff_1_`subj'_2p)
	gen ABOVE_2_`subj'_`grade' = (`cutoffs_grade'_`subj'_`grade'>=cutoff_2_`subj'_2p)

	*- Relative score
	gen rscore_1_`subj'_`grade' = `cutoffs_grade'_`subj'_`grade' - cutoff_1_`subj'_2p
	gen rscore_2_`subj'_`grade' = `cutoffs_grade'_`subj'_`grade' - cutoff_2_`subj'_2p


*- Relative score polynomial
	forvalues p = 1/2 {
		gen rscore_1_`subj'_`grade'_`p' = rscore_1_`subj'_`grade'^`p'
		gen rscore_2_`subj'_`grade'_`p' = rscore_2_`subj'_`grade'^`p'
		gen ABOVE_rscore_1_`subj'_`grade'_`p' = ABOVE_1_`subj'_`grade'*(rscore_1_`subj'_`grade'_`p'^`p')
		gen ABOVE_rscore_2_`subj'_`grade'_`p' = ABOVE_2_`subj'_`grade'*(rscore_2_`subj'_`grade'_`p'^`p')
	}	
}

		
	
*- Example: 2014 and 2016. Students who had BOTH satisfactory:
gen same_school = id_ie_2p == id_ie_4p


close

*- Work with example
local focus_sample = 1

/*
local cutoffs_grade = "std"
local grade = "2p"
local grade_outcome = "4p"

local subj = "m"
local year = 2016
*/
local outcome = "std_`subj'_4p" // std_`subj'_4p aspiration_4p_HE same_school
local ece_label = 2


local cutoff1 = -.70539725
local cutoff2 = .33055851
		
open

*-- Keep focus sample
if `focus_sample' == 1 {
	gen sample = 1 if pct_info_grades_HIGH>50
	keep if sample==1
	}

	

*- Histogram
	preserve	
		kdensity `cutoffs_grade'_`subj'_`grade' ///
		, ///
		xline(`cutoff1' `cutoff2')
		graph export "$FIG/example_mccrary.png", replace
	restore

*-- Overall results
preserve
	if "`subj'" == "c" local subj_other = "m"
	if "`subj'" == "m" local subj_other = "c"
	keep if year_`grade'==`year'
	//keep if grupo_`subj_other'_`grade' == 1
	sum rscore_`ece_label'_`subj'_`grade'_1
	keep if abs(rscore_`ece_label'_`subj'_`grade'_1)<1
	binscatter std_`subj'_4p  rscore_`ece_label'_`subj'_`grade'_1 ///
		, ///
		n(50) ///
		xline(0) ///
		xtitle("Standardized 2nd grade score")	///
		ytitle("Standardized 4th grade score")
		
	graph export "$FIG/example_4th_score.png", replace
	
	binscatter aspiration_4p_HE  rscore_`ece_label'_`subj'_`grade'_1 ///
		, ///
		n(50) ///
		xline(0) ///
		xtitle("Standardized 2nd grade score")	///
		ytitle("4th grade aspiration HE")
		
	graph export "$FIG/example_4th_aspiration.png", replace	
	
	*--- Other perceptions
	keep if male_2p == 0 
	gen boys_better_math 	= inlist(gender_subj_1_4p,3,4) == 1 & gender_subj_1_4p!=.
	gen boys_easy_math 		= inlist(gender_subj_3_4p,3,4) == 1 & gender_subj_3_4p!=.
	binscatter boys_better_math  rscore_`ece_label'_`subj'_`grade'_1 ///
		, ///
		n(50) ///
		xline(0) ///
		xtitle("Standardized 2nd grade score")	///
		ytitle("Boys do better in math")
		
	graph export "$FIG/example_4th_gender_belief_boys_better.png", replace	
	
	binscatter boys_easy_math  rscore_`ece_label'_`subj'_`grade'_1 ///
		, ///
		n(50) ///
		xline(0) ///
		xtitle("Standardized 2nd grade score")	///
		ytitle("Boys easier in math")
		
	graph export "$FIG/example_4th_gender_belief_boys_easier.png", replace		
	
restore	


*-- Focusing on biased parents

preserve
	//Those who think parent support is important
	keep if inlist(importance_success_m_6_2p,3,4)==1
	if "`subj'" == "c" local subj_other = "m"
	if "`subj'" == "m" local subj_other = "c"
	keep if year_`grade'==`year'
	//keep if grupo_`subj_other'_`grade' == 1
	sum rscore_`ece_label'_`subj'_`grade'_1
	keep if abs(rscore_`ece_label'_`subj'_`grade'_1)<1
	binscatter std_`subj'_4p  rscore_`ece_label'_`subj'_`grade'_1 ///
		, ///
		n(50) ///
		xline(0) ///
		xtitle("Standardized 2nd grade score")	///
		ytitle("Standardized 4th grade score")
		
	graph export "$FIG/example_4th_score_math_parent_support_important.png", replace
restore

preserve
	//Those who think parent support is important
	keep if inlist(importance_success_m_6_2p,3,4)==0
	if "`subj'" == "c" local subj_other = "m"
	if "`subj'" == "m" local subj_other = "c"
	keep if year_`grade'==`year'
	//keep if grupo_`subj_other'_`grade' == 1
	sum rscore_`ece_label'_`subj'_`grade'_1
	keep if abs(rscore_`ece_label'_`subj'_`grade'_1)<1
	binscatter std_`subj'_4p  rscore_`ece_label'_`subj'_`grade'_1 ///
		, ///
		n(50) ///
		xline(0) ///
		xtitle("Standardized 2nd grade score")	///
		ytitle("Standardized 4th grade score")
		
	graph export "$FIG/example_4th_score_math_parent_support_not_important.png", replace
restore	

preserve
	//Those who think parent support is important
	keep if inlist(current_m,1,2)==1
	if "`subj'" == "c" local subj_other = "m"
	if "`subj'" == "m" local subj_other = "c"
	keep if year_`grade'==`year'
	//keep if grupo_`subj_other'_`grade' == 1
	sum rscore_`ece_label'_`subj'_`grade'_1
	keep if abs(rscore_`ece_label'_`subj'_`grade'_1)<1
	binscatter std_`subj'_4p  rscore_`ece_label'_`subj'_`grade'_1 ///
		, ///
		n(50) ///
		xline(0) ///
		xtitle("Standardized 2nd grade score")	///
		ytitle("Standardized 4th grade score")
		
	graph export "$FIG/example_4th_score_math_parent_belief_badinmath.png", replace
	
	binscatter aspiration_4p_HE rscore_`ece_label'_`subj'_`grade'_1 ///
		, ///
		n(50) ///
		xline(0) ///
		xtitle("Standardized 2nd grade score")	///
		ytitle("4th grade aspiration HE")
		
	graph export "$FIG/example_4th_aspiration_parent_belief_badinmath.png", replace	
restore		
	













