*- Testing
set seed 1234
	
	global window = 1
	global mccrary_window = 4

use "$OUT/students.dta", clear

*******************************
*- Descriptive Statistics
*******************************

texdoc init "$TABLES/summary_stats.tex" , replace force
	tex \begin{tabular}{lcccccccc} \hline \hline
	tex & \multicolumn{4}{c}{No cutoff estimated} & \multicolumn{4}{c}{Cutoff estimated} \\
	tex  & Mean  & SD & Min & Max & Mean  & SD & Min & Max \\ \hline	
	
	tex & & & & & & & & \\
	
	tex \multicolumn{4}{l}{PANEL A: 1\% statistical significance} & & & & & \\

	/*
	summ offers if applied==1
	local st_n: display%9.0f round(r(N))
		
	summ offers if lottery_nocutoff==0
	local st: display%9.0f round(r(N))
	*/
	collapse (mean) applied applied_public enrolled enrolled_public if exp_graduating_year1>=2016 & exp_graduating_year1<=2022
	
	local stat "applied applied_public enrolled enrolled_public"
	foreach outcome of local stat {
		
		if "`outcome'" == "applied" 			local rowname "Applied to University"
		if "`outcome'" == "applied_ppublic" 	local rowname "Applied to public University"
		if "`outcome'" == "enrolled" 			local rowname "Enrolled in University"
		if "`outcome'" == "enrolled_public" 	local rowname "Enrolled in public University"
		//if "`outcome'" == "latino" local rowname "Latino applicants"
		//if "`outcome'" == "asian" local rowname "Asian applicants"
		
		summ `outcome' //if lottery_nocutoff==1
		
		local mean_n: display%9.2f round(r(mean), .01)
		local sd_n: display%9.2f round(r(sd), .01)
		local min_n: display%9.0f round(r(min))
		local max_n: display%9.0f round(r(max))
		local n_n: display%9.0f round(r(N))
		
		/*
		summ `outcome' if lottery_nocutoff==0
		
		local mean: display%9.2f round(r(mean), .01)
		local sd: display%9.2f round(r(sd), .01)
		local min: display%9.0f round(r(min))
		local max: display%9.0f round(r(max))
		local n: display%9.0f round(r(N))
		*/
		
    texdoc write `rowname' & `mean_n' & `sd_n' & `min_n' & `max_n' & & & & \\
  }	
	//tex N lotteries & \multicolumn{4}{c}{`n_n'} & \multicolumn{4}{c}{`n'} \\
	//tex N applicants & \multicolumn{4}{c}{`st_n'} & \multicolumn{4}{c}{`st'} \\
		
	
	
	//tex N lotteries & \multicolumn{4}{c}{`n_n'} & \multicolumn{4}{c}{`n'} \\
	//tex N students & \multicolumn{4}{c}{`st_n'} & \multicolumn{4}{c}{`st'} \\
	tex \hline \hline
	tex  \end{tabular}
	texdoc close	
	
*- Sample sizes:
unique id_per_umc
unique id_fam_4
tab fam_total_4
tab year_2p source_2p
tab year_4p source_4p
tab year_2s	source_2s
	

*-- Applied
sum applied 		if exp_graduating_year1>=2016 & exp_graduating_year1<=2022

*-- Applied Public
sum applied_public 	if exp_graduating_year1>=2016 & exp_graduating_year1<=2022

*-- Enrolled
sum enrolled 		if exp_graduating_year1>=2016 & exp_graduating_year1<=2022

*-- Enrolled public
sum enrolled_public if exp_graduating_year1>=2016 & exp_graduating_year1<=2022

*-- Education of mother
graph bar higher_ed_2p if inlist( educ_mother,2,3,4,5,6,7,8)==1, ///
over(educ_mother, relabel(1 "PI" 2 "PC" 3 "SI" 4 "SC" 5 "HI" 6 "HC" 7 "PG")) ///
ytitle("% who expect their kid will get higher education")
	
*-- Education of mother
graph bar applied applied_public if inlist( educ_mother,2,3,4,5,6,7,8)==1 & exp_graduating_year1>=2016 & exp_graduating_year1<=2022, ///
over(educ_mother, relabel(1 "PI" 2 "PC" 3 "SI" 4 "SC" 5 "HI" 6 "HC" 7 "PG")) ///
ytitle("% who expect their kid will get higher education") 

*-- Income	
graph bar applied applied_public if  exp_graduating_year1>=2016 & exp_graduating_year1<=2022, ///
over(socioec_index_cat_2s, relabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4")) ///
ytitle("% who expect their kid will get higher education") 




*******************************
*- Figures
*******************************


*- Correlation of sibling outcomes
//Exams
use "$OUT\students_siblings", clear



//Universities and admission
use "$OUT/applied_outcomes.dta", clear


local cell major
local type noz
	
rename *_`cell' *
rename *_`type' * 

*- Exclude those without estimated cutoffs
keep if lottery_nocutoff == 0


*- Create vars
gen pop = 1
gen byte higher_ed_mother 		= inlist(educ_mother,7,8) if educ_mother!=.
gen score_relative = score_std - cutoff_std 


*1. Issue of decline post admission
binsreg enroll_foc score_relative if abs(score_relative)<2 & public==1 &  exp_graduating_year1_sib>=2016 & exp_graduating_year1_sib<=2022, nbins(100) absorb(id_cutoff)
binsreg higher_ed_2s_sib score_relative if abs(score_relative)<2 & public==1 &  exp_graduating_year1_sib>=2016 & exp_graduating_year1_sib<=2022, nbins(100) absorb(id_cutoff)

preserve
	collapse (mean) admitted cutoff_std  score_math_std_2s_foc higher_ed_mother higher_ed_2s_foc (sum) pop, by(universidad public)

	twoway 	(scatter admitted cutoff_std if public==0 & cutoff_std>-2) ///
			(scatter admitted cutoff_std if public==1) ///
			, ///
			ytitle("% Admitted") ///
			xtitle("Admission Cutoff" "S.D. Above mean in applicant pool") ///
			legend(label(1 "Private") label(2 "Public") pos(6) cols(2))


	twoway 	(scatter higher_ed_2s_foc cutoff_std if public==0 & cutoff_std>-2) ///
			(scatter higher_ed_2s_foc cutoff_std if public==1) ///
			, ///
			ytitle("% Admitted") ///
			xtitle("Admission Cutoff" "S.D. Above mean in applicant pool") ///
			legend(label(1 "Private") label(2 "Public") pos(6) cols(2))

	keep if public == 1 & pop>5000
	extremes cutoff_std admitted universidad 
restore



twoway ///
			(scatter admitted score_relative  				if id_cutoff==5880, yaxis(1)) ///
			(scatter score_math_std_2s_foc score_relative  	if id_cutoff==5880, yaxis(2)) ///
			, ///
			xtitle("Score relative to cutoff") ///
			ytitle("8th grade score", axis(2)) ///
			legend(label(1 "Admitted") label(2 "8th grade score") pos(6) cols(2)) ///
			name(hard, replace)


twoway ///
			(scatter admitted score_relative  				if id_cutoff==11522, yaxis(1)) ///
			(scatter score_math_std_2s_foc score_relative  	if id_cutoff==11522, yaxis(2)) ///
			, ///
			xtitle("Score relative to cutoff") ///
			ytitle("8th grade score", axis(2)) ///
			legend(label(1 "Admitted") label(2 "8th grade score") pos(6) cols(2)) ///
			name(easy, replace)			
			



preserve
	keep if universidad == "UNIVERSIDAD NACIONAL DE PIURA"
	keep if year_app == 2023
	bys id_cutoff: gen N=-_N
	egen g = group(N id_cutoff)
	
	local g = 12
	sum cutoff_std if g == `g'
	local m = r(mean)
	twoway ///
			(scatter admitted score_std  				if g==`g', yaxis(1)) ///
			(scatter score_math_std_2s_foc score_std  	if g==`g', yaxis(2)) ///
			,  ///
			xline(`m') ///
			legend(off)
			
	//WEIRD: 1,2
	//GOOD: 3,6,12
restore


preserve
	keep if universidad == "UNIVERSIDAD NACIONAL DE MOQUEGUA" //UNIVERSIDAD NACIONAL DE MOQUEGUA
	keep if year_app == 2023
	bys id_cutoff: gen N=-_N
	egen g = group(N id_cutoff)
	
	local g = 1
	sum cutoff_std if g == `g'
	local m = r(mean)
	twoway ///
			(scatter admitted score_std  				if g==`g', yaxis(1)) ///
			(scatter score_math_std_2s_foc score_std  	if g==`g', yaxis(2)) ///
			,  ///
			xline(`m') ///
			legend(off)
	
	gen score_relative = score_std - cutoff_std

	histogram score_relative		
			
	//WEIRD: 
	//GOOD: 1
restore



binsreg higher_ed_2s_foc score_std if public==1		
		
		
keep if public==1
extremes admitted cutoff_std_major universidad pop
		
// 	Scores

//	Aspirations

//	Application
sum applied_sib if applied_foc==0 & exp_graduating_year1_sib>=2016 & exp_graduating_year1_sib<=2022


// Overlapping cutoffs
use "$OUT/applied_outcomes.dta", clear

local cell major
local type noz
	
rename *_`cell' *
rename *_`type' * 

//preserve

gen score_com_std_2s_foc_admitted = score_com_std_2s_foc if admitted==1
gen score_math_std_2s_foc_admitted = score_math_std_2s_foc if admitted==1
gen byte higher_ed_mother 		= inlist(educ_mother,7,8) if educ_mother!=.


collapse admitted cutoff_std score_*_std_2s_foc* socioec_index_cat_2s_foc higher_ed_mother , by(universidad public)
sort cutoff_std
drop if cutoff_std==.

keep if universidad == "UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS"
keep if year_app == 2020

gen score_relative = score_std - cutoff_std

binsreg admitted score_relative if year_app==2020, nbins(100)
binsreg score_math_std_2s_foc score_relative if year_app==2020, nbins(100)


restore


*******************************
*- Regressions
*******************************



use "$OUT/applied_outcomes.dta", clear

local cell major
local type noz
	
rename *_`cell' *
rename *_`type' * 

*- Public schools
keep if public==1

*- Exclude those without estimated cutoffs
keep if lottery_nocutoff == 0

*- Exclude those at cutoff
gen not_at_cutoff = (rank_score_raw!=cutoff_rank)		
keep if not_at_cutoff==1

*- Score relative
gen score_relative = score_std - cutoff_std
drop if score_relative==.	
keep if abs(score_relative)<${window} 

*- Run the RD regression
gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=. //To avoid float issues around 0, we use the precisely integer rank scores.

*- Polynomial
forvalues p = 1/5 {
	gen score_relative_`p' 			= score_relative^`p'
	gen ABOVE_score_relative_`p' 	= ABOVE*score_relative_`p'
}

*- Remaining variables
gen byte higher_ed_caretaker 	= inlist(educ_caretaker,7,8) if educ_caretaker!=.
gen byte higher_ed_mother 		= inlist(educ_mother,7,8) if educ_mother!=.
gen byte higher_ed_father 		= inlist(educ_father,7,8) if educ_father!=.


*- Create sample of (i) 1 obs per student, (ii) one per year (iii) oldest sibling (iv) Those whose sibling could've applied
bys id_persona_rec (year_app): gen byte sample_first_year_app = year_app == year_app[1] 
sort id_persona_rec year_app age, stable 
gen n = _n
bys id_persona_rec (year_app age n): gen sample_first_app = (_n==1) //there is some randomness, so we use n for replication.
drop n

gen sample_oldest = (fam_order_4 == 1)

gen sample_applied_sib = (exp_graduating_year1_sib>=2016 & exp_graduating_year1_sib<=2022 & exp_graduating_year1_sib+1>year_app)


*- Age gap
gen age_gap = exp_graduating_year1_sib-exp_graduating_year1_foc


global scores_1 		= "score_relative_1"
global ABOVE_scores_1 	= "ABOVE_score_relative_1"

global scores_2			= "score_relative_1 		score_relative_2"
global ABOVE_scores_2 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2"


global scores_3 		= "score_relative_1 		score_relative_2 		score_relative_3"
global ABOVE_scores_3 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2 	ABOVE_score_relative_3"

global scores_5 		= "score_relative_1 		score_relative_2 		score_relative_3 		score_relative_4 		score_relative_5"
global ABOVE_scores_5 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2 	ABOVE_score_relative_3 	ABOVE_score_relative_4 	ABOVE_score_relative_5"


histogram score_relative if abs(score_relative)<${window} 
graph export 	"$FIGURES/histogram.png", replace

rddensity score_relative if abs(score_relative)<${window}, c(0) plot
graph export 	"$FIGURES/mccrary_default.png", replace

rddensity score_relative if abs(score_relative)<${window}, c(0) plot kernel(triangular)
graph export 	"$FIGURES/mccrary_triangular.png", replace



*- Tentative bins

scatter age age_gap



*- Binsreg
bys id_cutoff: gen  N=_N
rdplot higher_ed_2p_sib score_relative if abs(score_relative)<${window}  & year_2p_sib>=year_app, c(0) graph_options(legend(off))


//FIX ISSUE OF DECLINE

histogram score_relative if N<50
histogram score_relative if N>100 & N<200
histogram score_relative if N>2000

//FIX ISSUE OF SOME VERY HIGH CUTOFFS/LOW ADMITTANCE RATES. ARE WE INCLUDING THEM?

binsreg admitted 						score_relative if abs(score_relative)<${window}, nbins(100) xline(0) ylabel(0(.2)1)
binsreg enroll_foc 						score_relative if abs(score_relative)<${window}, nbins(100) xline(0) ylabel(0(.2)1)
binsreg enroll_sem_foc 					score_relative if abs(score_relative)<${window}, nbins(100) xline(0) ylabel(0(.2)1)
binsreg enroll_public_foc 				score_relative if abs(score_relative)<${window}, nbins(100) xline(0) ylabel(0(.2)1)
binsreg enroll_private_foc 				score_relative if abs(score_relative)<${window}, nbins(100) xline(0) ylabel(0(.2)1)
binsreg enroll_public_sem_foc 			score_relative if abs(score_relative)<${window}, nbins(100) xline(0) ylabel(0(.2)1)
binsreg enroll_private_sem_foc 			score_relative if abs(score_relative)<${window}, nbins(100) xline(0) ylabel(0(.2)1)
binsreg applied_private_foc 			score_relative if abs(score_relative)<${window}, nbins(100) xline(0) ylabel(0(.2)1)
binsreg enroll_same_uni_major_sem_foc 	score_relative if abs(score_relative)<${window}, nbins(100) xline(0) ylabel(0(.2)1)
binsreg enroll_same_uni_sem_foc 		score_relative if abs(score_relative)<${window}, nbins(100) xline(0) ylabel(0(.2)1)
binsreg enroll_same_sem_foc 			score_relative if abs(score_relative)<${window}, nbins(100) xline(0) ylabel(0(.2)1)
binsreg enroll_same_uni_foc 			score_relative if abs(score_relative)<${window}, nbins(100) xline(0) ylabel(0(.2)1)
binsreg enroll_foc 						score_relative if abs(score_relative)<${window}, nbins(100) xline(0) ylabel(0(.2)1)

binsreg applied_sib 					score_relative if abs(score_relative)<${window} & sample_applied_sib==1, nbins(100) xline(0) ylabel(0(.2)1)
binsreg applied_uni_sib 				score_relative if abs(score_relative)<${window} & sample_applied_sib==1 & socioec_index_cat_2s_foc==1, nbins(100) xline(0) ylabel(0(.2)1)
binsreg applied_uni_sib 				score_relative if abs(score_relative)<${window} & sample_applied_sib==1, nbins(100) xline(0) ylabel(0(.2)1)
binsreg applied_public_sib 				score_relative if abs(score_relative)<${window} & sample_applied_sib==1, nbins(100) xline(0) ylabel(0(.2)1)
binsreg applied_private_sib 			score_relative if abs(score_relative)<${window} & sample_applied_sib==1, nbins(100) xline(0) ylabel(0(.2)1)



//eststo enrolled_iv	: ivreghdfe enroll_foc				(admitted=ABOVE)



binsreg higher_ed_2p_sib score_relative if abs(score_relative)<${window}  & year_2p_sib>=year_app & N<50, nbins(40) xline(0)
binsreg higher_ed_2p_sib score_relative if abs(score_relative)<${window}  & year_2p_sib>=year_app & N>50, nbins(40) xline(0)
binsreg higher_ed_2p_sib score_relative if abs(score_relative)<${window}  & year_2p_sib>=year_app, nbins(40) xline(0)
binsreg higher_ed_2p_sib score_relative if abs(score_relative)<${window}  & year_2p_sib>=year_app, nbins(40) xline(0)




binsreg higher_ed_2p_sib score_relative if abs(score_relative)<${window}  & year_2p_sib>=year_app, nbins(40) xline(0)
binsreg higher_ed_4p_sib score_relative if abs(score_relative)<${window}  & year_4p_sib>=year_app, nbins(100) xline(0)
binsreg higher_ed_2s_sib score_relative if abs(score_relative)<${window}  & year_2s_sib>=year_app, nbins(100) xline(0)
binsreg score_math_std_2s_foc score_relative if abs(score_relative)<${window} & universidad=="UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS", nbins(100)
binsreg higher_ed_2s_sib score_relative if abs(score_relative)<${window} & universidad=="UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS" & year_2s_sib>=year_app, nbins(100)



*- First Stage
eststo admitted						: reghdfe admitted							ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window}, a(id_cutoff) vce(robust)
eststo enroll_same_uni_major_sem	: reghdfe enroll_same_uni_major_sem_foc		ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window}, a(id_cutoff) vce(robust)
eststo enroll_same_uni_sem			: reghdfe enroll_same_uni_sem_foc			ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window}, a(id_cutoff) vce(robust)
eststo enroll_same_sem				: reghdfe enroll_same_sem_foc				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window}, a(id_cutoff) vce(robust)
eststo enroll						: reghdfe enroll_foc				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window}, a(id_cutoff) vce(robust)



reghdfe applied_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & socioec_index_cat_2s_foc==1, a(id_cutoff) vce(robust)





eststo admitted		: reghdfe admitted				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window}, a(id_cutoff) vce(robust)
eststo enrolled		: reghdfe score_com_std_4p_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & year_4p_sib>=year_app, a(id_cutoff) vce(robust)
eststo math_2s_sib	: reghdfe score_math_std_2s_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & year_2s_sib>=year_app, a(id_cutoff) vce(robust)
eststo com_2s_sib	: reghdfe score_com_std_2s_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & year_2s_sib>=year_app, a(id_cutoff) vce(robust)


*- Sibling School Outcomes
eststo math_4p_sib	: reghdfe score_math_std_4p_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & year_4p_sib>=year_app, a(id_cutoff) vce(robust)
eststo com_4p_sib	: reghdfe score_com_std_4p_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & year_4p_sib>=year_app, a(id_cutoff) vce(robust)
eststo math_2s_sib	: reghdfe score_math_std_2s_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & year_2s_sib>=year_app, a(id_cutoff) vce(robust)
eststo com_2s_sib	: reghdfe score_com_std_2s_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & year_2s_sib>=year_app, a(id_cutoff) vce(robust)

*- Sibling aspirations
eststo higher_ed_2p_sib	: reghdfe higher_ed_2p_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & year_2p_sib>=year_app, a(id_cutoff) vce(robust)
eststo higher_ed_4p_sib	: reghdfe higher_ed_4p_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & year_4p_sib>=year_app, a(id_cutoff) vce(robust)
eststo higher_ed_2s_sib	: reghdfe higher_ed_2s_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & year_2s_sib>=year_app, a(id_cutoff) vce(robust)

*- Sibling university
eststo applied_sib			: reghdfe applied_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & sample_applied_sib==1, a(id_cutoff) vce(robust)
eststo applied_sib			: reghdfe applied_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & sample_applied_sib==1 & inlist(age_gap,1,2,3)==1, a(id_cutoff) vce(robust)
eststo applied_sib			: reghdfe applied_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & sample_applied_sib==1 & inlist(age_gap,4,5,6)==1, a(id_cutoff) vce(robust)

eststo applied_same_uni_sib	: reghdfe applied_same_uni_sib		ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & sample_applied_sib==1, a(id_cutoff) vce(robust)
eststo enroll_sib			: reghdfe enroll_sib				ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & sample_applied_sib==1, a(id_cutoff) vce(robust)
eststo enroll_same_uni_sib	: reghdfe enroll_same_uni_sib		ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & sample_applied_sib==1, a(id_cutoff) vce(robust)

esttab applied_sib applied_same_uni_sib enroll_sib , ///
				keep(ABOVE _cons) ///  
				order(ABOVE _cons) ///
				///coeflabel(registered_voters "Registered Voters") ///
				b(%9.3f) ///
				se(%9.3f) ///
				stats(N,fmt("%9.0fc")) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nonotes 

esttab applied_sib applied_same_uni_sib enroll_sib ///
				using "$TABLES/table_siblings.tex" ///
				, label replace booktabs ///
				mgroups("Applications" "Applications Same College" "Enrolled", pattern(1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
				///mtitles("\%" "\%" "\%") ///
				nomtitles ///
				keep(ABOVE _cons) ///  
				order(ABOVE _cons) ///
				///coeflabel(registered_voters "Registered Voters") ///
				b(%9.3f) ///
				se(%9.3f) ///
				stats(N,fmt("%9.0fc")) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nonotes ///
				///indicate("Site FE = local_fe" "First Round votes = fr_included") ///
				alignment(D{c}{c}{-1}) width(\hsize)  ///
				title(Mechanisms \label{tab:table_mechanisms_results}) ///
				substitute({l} {p{\linewidth}}) ///
				addnotes("Note: Robust standard errors in parentheses. \sym{*} \(p<0.1\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\).")	




















*-- Heterogeneity

*-- Applied
tabstat applied 		if exp_graduating_year1>=2016 & exp_graduating_year1<=2022, by(educ_mother)
tabstat applied 		if exp_graduating_year1>=2016 & exp_graduating_year1<=2022, by(educ_mother)


*- Validating variables:

*-- Scores in 2nd and 8th grade
binsreg score_math_std_2s score_math_std_2p 

*-- Scores and Socio Economic Index
binsreg score_math_std_2p socioec_index_2p
binsreg score_math_std_2s socioec_index_2s

*-- Scores and parental education
gen byte higher_ed_mother 			= inlist(educ_mother,7,8) if educ_mother!=.
gen byte higher_ed_father 			= inlist(educ_mother,7,8) if educ_mother!=.
gen byte higher_ed_caretaker 		= inlist(educ_mother,7,8) if educ_mother!=.
binsreg higher_ed_mother score_math_std_2p

*-- Scores and aspirations
binsreg higher_ed_2p score_math_std_2p
binsreg higher_ed_2s score_math_std_2s

*- Higher Education and education of mother
graph bar if inlist( educ_mother,1,2,3,4,5,6,7,8)==1, over(educ_mother) stack percent asyvars
graph bar higher_ed_2p if inlist( educ_mother,1,2,3,4,5,6,7,8)==1, ///
over(educ_mother, relabel(1 "None" 2 "PI" 3 "PC" 4 "SI" 5 "SC" 6 "HI" 7 "HC" 8 "PG")) ///
ytitle("% who expect their kid will get higher education")

graph bar higher_ed_2s if inlist( educ_mother,1,2,3,4,5,6,7,8)==1, ///
over(educ_mother, relabel(1 "None" 2 "PI" 3 "PC" 4 "SI" 5 "SC" 6 "HI" 7 "HC" 8 "PG")) ///
ytitle("% who expect will get higher education")

reg higher_ed_2s score_math_std_2s score_math_std_2p score_com_std_2s score_com_std_2p socioec_index_2s higher_ed_mother  higher_ed_father
reg applied score_math_std_2s score_math_std_2p score_com_std_2s score_com_std_2p socioec_index_2s higher_ed_mother  higher_ed_father
reg enrolled score_math_std_2s score_math_std_2p score_com_std_2s score_com_std_2p socioec_index_2s i.educ_mother i.educ_father i.educ_caretaker



use "$OUT/applied_outcomes.dta", clear

local cell major
local type noz
	
rename *_`cell' *
rename *_`type' * 

*- Public schools
keep if public==1

*- Exclude those without estimated cutoffs
keep if lottery_nocutoff == 0

*- Exclude those at cutoff
gen not_at_cutoff = (rank_score_raw!=cutoff_rank)		
keep if not_at_cutoff==1

*- Score relative
gen score_relative = score_std - cutoff_std
drop if score_relative==.	

*- Run the RD regression
gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=. //To avoid float issues around 0, we use the precisely integer rank scores.

*- Polynomial
forvalues p = 1/5 {
	gen score_relative_`p' 			= score_relative^`p'
	gen ABOVE_score_relative_`p' 	= ABOVE*score_relative_`p'
}

*- Remaining variables
gen byte higher_ed_caretaker 	= inlist(educ_caretaker,7,8) if educ_caretaker!=.
gen byte higher_ed_mother 		= inlist(educ_mother,7,8) if educ_mother!=.
gen byte higher_ed_father 		= inlist(educ_father,7,8) if educ_father!=.


global scores_1 		= "score_relative_1"
global ABOVE_scores_1 	= "ABOVE_score_relative_1"

global scores_3 		= "score_relative_1 		score_relative_2 		score_relative_3"
global ABOVE_scores_3 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2 	ABOVE_score_relative_3"

global scores_5 		= "score_relative_1 		score_relative_2 		score_relative_3 		score_relative_4 		score_relative_5"
global ABOVE_scores_5 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2 	ABOVE_score_relative_3 	ABOVE_score_relative_4 	ABOVE_score_relative_5"


histogram score_relative if abs(score_relative)<${window} 

keep if abs(score_relative)<${window} 


*- Create sample of (i) 1 obs per student, (ii) one per year (iii) oldest sibling
bys id_persona_rec (year_app): gen byte sample_first_year_app = year_app == year_app[1] 
sort id_persona_rec year_app age, stable 
gen n = _n
bys id_persona_rec (year_app age n): gen sample_first_app = (_n==1) //there is some randomness, so we use n for replication.
drop n

gen sample_oldest = (fam_order_4 == 1)

gen sample_applied_sib = (exp_graduating_year1_sib>=2016 & exp_graduating_year1_sib<=2022)






///HOW IS THE SIBLING DATA CONSTRUCTED?
///HOW IS THE APPLICATION WORKING? What if we keep first application per student?
///HOW IS app/enr data matched... what if per year?

*- Focal Child (Outcomes)
binsreg admitted 						score_relative if abs(score_relative)<${window} 
binsreg enroll_foc 						score_relative if abs(score_relative)<${window} 
binsreg enroll_same_uni_foc 			score_relative if abs(score_relative)<${window} 
binsreg enroll_same_uni_major_foc 		score_relative if abs(score_relative)<${window} 
binsreg enroll_same_sem_foc 			score_relative if abs(score_relative)<${window} 
binsreg enroll_same_uni_sem_foc 		score_relative if abs(score_relative)<${window} 
binsreg enroll_same_uni_major_sem_foc 	score_relative if abs(score_relative)<${window} 


*- Focal Child (Placebo)
binsreg fam_order_4  score_relative if abs(score_relative)<${window} 
binsreg fam_total_4 score_relative if abs(score_relative)<${window} 
binsreg male score_relative if abs(score_relative)<${window} 

binsreg score_math_std_2p_foc score_relative if abs(score_relative)<${window}
binsreg score_math_std_4p_foc score_relative if abs(score_relative)<${window} 
binsreg score_math_std_2s_foc score_relative if abs(score_relative)<${window}, nbins(100)   
binsreg score_math_std_2s_foc score_relative if abs(score_relative)<${window}  & sample_first_year_app==1
binsreg score_math_std_2s_foc score_relative if abs(score_relative)<${window}  & sample_first_app==1
binsreg score_math_std_2s_foc score_relative if abs(score_relative)<${window}  & sample_oldest==1

//No enough observations as this starts in later years. Perhaps available in 2024.
*binsreg higher_ed_2p_foc score_relative if abs(score_relative)<${window} 
binsreg higher_ed_4p_foc score_relative if abs(score_relative)<${window} 
binsreg higher_ed_2s_foc score_relative if abs(score_relative)<${window}, nbins(100)
*binsreg higher_ed_caretaker score_relative if abs(score_relative)<${window}, nbins(100)
binsreg higher_ed_mother score_relative if abs(score_relative)<${window}, nbins(100)
*binsreg higher_ed_father score_relative if abs(score_relative)<${window}, nbins(100)
//WHY DOES IT FLATTEN AFTER?

*- Sibling (outcomes)

*--- Applications



binsreg applied_sib score_relative if abs(score_relative)<${window} & sample_applied_sib==1, nbins(100)
binsreg applied_sib score_relative if abs(score_relative)<${window} & sample_first_app==1, nbins(100) 
binsreg applied_sib score_relative if abs(score_relative)<${window} & sample_oldest==1, nbins(100) 
binsreg applied_sib score_relative if abs(score_relative)<${window} & sample_oldest==1 & sample_first_app==1, nbins(100) 


 
binsreg applied_same_uni_sib score_relative if abs(score_relative)<${window}, nbins(100)
binsreg applied_same_uni_sib score_relative if abs(score_relative)<${window} & year_applied_sib<=year_app, nbins(100)
binsreg applied_same_uni_sib score_relative if abs(score_relative)<${window} & year_applied_sib>year_app, nbins(100)
binsreg applied_same_major_sib score_relative if abs(score_relative)<${window}, nbins(100)
binsreg applied_same_uni_major_sib score_relative if abs(score_relative)<${window}, nbins(100)

*--- Enrolled
binsreg enroll_sib score_relative if abs(score_relative)<${window}, nbins(100)
binsreg enroll_same_uni_sib score_relative if abs(score_relative)<${window}, nbins(100)
binsreg enroll_same_major_sib score_relative if abs(score_relative)<${window}, nbins(100)
binsreg enroll_same_uni_major_sib score_relative if abs(score_relative)<${window}, nbins(100)


   
//binsreg sib_applied_after score_relative if abs(score_relative)<${window}, nbins(100)
// WHY IS THERE A DROP IN SIBLING APPLIED AFTER?
reghdfe applied_sib				 	ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & sample_applied_sib==1, a(id_cutoff)
reghdfe applied_same_uni_sib 		ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & sample_applied_sib==1, a(id_cutoff)
reghdfe applied_same_major_sib 		ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & sample_applied_sib==1, a(id_cutoff)
reghdfe enroll_sib				 	ABOVE ${scores_1} ${ABOVE_scores_1} 	if abs(score_relative)<${window} & sample_applied_sib==1, a(id_cutoff)


*--- Test Scores
binsreg score_math_std_2p_next score_relative if abs(score_relative)<${window} 
binsreg score_math_std_4p_next score_relative if abs(score_relative)<${window} 
binsreg score_math_std_2s_next score_relative if abs(score_relative)<${window} 

binsreg score_com_std_2p_next score_relative if abs(score_relative)<${window} 
binsreg score_com_std_4p_next score_relative if abs(score_relative)<${window} 
binsreg score_com_std_2s_next score_relative if abs(score_relative)<${window} 
  
*--- Aspirations



*--- Progression


*--- Other (survey)









binsreg score_math_std_2s_foc score_relative if abs(score_relative)<${window} 
binsreg score_math_std_2p_next score_relative if abs(score_relative)<${window} & year<=year_2p_next
binsreg score_math_std_4p_next score_relative if abs(score_relative)<${window} & year<=year_4p_next
binsreg score_math_std_2s_next score_relative if abs(score_relative)<${window} & year<=year_2s_next 
binsreg next_sib_applied_after score_relative if abs(score_relative)<${window} 


reghdfe higher_ed_2p_next ABOVE ${scores_1} ${ABOVE_scores_1} if abs(score_relative)<${window}  & year<=year_2p_next, a(id_cutoff)
reghdfe higher_ed_4p_next ABOVE ${scores_1} ${ABOVE_scores_1} if abs(score_relative)<${window}  & year<=year_4p_next, a(id_cutoff)
reghdfe higher_ed_2s_next ABOVE ${scores_1} ${ABOVE_scores_1} if abs(score_relative)<${window}  & year<=year_2s_next, a(id_cutoff)

*- Aspirations
binsreg higher_ed_2p_next score_relative if abs(score_relative)<${window}  & year<=year_2p_next, nbins(100)
binsreg higher_ed_4p_next score_relative if abs(score_relative)<${window}  & year<=year_4p_next, nbins(100)
binsreg higher_ed_2s_next score_relative if abs(score_relative)<${window}  & year<=year_2s_next, nbins(100) xtitle("Relative Score in College application (Focal child)") ytitle("Expects to get Higher Education (%)" "Younger sibling (8th grade)") xline(0) by(ABOVE) bycolors(gs0 gs0) bysymbols(o o)  polyreg(5)
  


reghdfe higher_ed_2p_next ABOVE ${scores_1} ${ABOVE_scores_1} if abs(score_relative)<${window}  & year<=year_2p_next, a(id_cutoff)
reghdfe higher_ed_4p_next ABOVE ${scores_1} ${ABOVE_scores_1} if abs(score_relative)<${window}  & year<=year_4p_next, a(id_cutoff)
reghdfe higher_ed_2s_next ABOVE ${scores_1} ${ABOVE_scores_1} if abs(score_relative)<${window}  & year<=year_2s_next, a(id_cutoff)

reghdfe higher_ed_2s_next ABOVE ${scores_3} ${ABOVE_scores_3} if abs(score_relative)<${window}  & year<=year_2s_next, a(id_cutoff)
reghdfe higher_ed_2s_next ABOVE ${scores_5} ${ABOVE_scores_5} if abs(score_relative)<${window}  & year<=year_2s_next, a(id_cutoff)


tab year year_2p_next
tab year year_2p_next if year<=year_2p_next
tab year aspiration_2p_next if year<=year_2p_next

tab year year_4p_next
tab year year_4p_next if year<=year_4p_next
tab year aspiration_4p_next if year<=year_4p_next

tab year year_2s_next
tab year year_2s_next if year<=year_2s_next
tab year aspiration_2s_next if year<=year_2s_next

//Check sample size 
keep if inlist(year,2017,2018,2019)==1
tab 


