/********************************************************************************
- Author: Francisco Pardo
- Description: Descriptive statistics
- Date started: 08/28/2024
- Last update: 08/28/2024
*******************************************************************************/




capture program drop main 
program define main 

	setup
	main_descriptive
	
	
	enaho
	
	stem
	descriptive_admissions
	descriptive_student_aspirations
	descriptive_student_applications
	descriptive_student_region
	
	//descriptive_siblings_vs_rest 1
	descriptive_siblings_vs_rest 2
	correlation_multiple_takes
	
	
	//descriptive_siblings_vs_rest 3
	//descriptive_siblings_vs_rest 4
	
	
	//descriptive_student
	//siblings_enaho
	//validating_family
	//descriptive
	//test
	
end


********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup


clear

global fam_type=2

end



********************************************************************************
* Main Descriptive table
********************************************************************************


capture program drop main_descriptive
program define main_descriptive

clear


//Information about Peruvian context

* Less developed, poorer, less tertiary expenditure from government:
/*
*- Population
Peru : 33,845.62 (2023)

Source: https://data.worldbank.org/indicator/SP.POP.TOTL

*- GPD per capita PPP (2023)
US:				82,769
Netherlands:	80,760
Sweden:			69,223
Croatia:		46,777
Chile:			33,235
Mexico:			25,351
Peru:			16,974

Source: https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.CD?locations=CL-PE-AR-HR-SE-US-NL-MX

*- GINI: 
Peru: 40.3 (2022)
Chile: 43 (2022)
Croatia: 28.9 (2021)
Sweden: 29.8 (2021)
US: 41.3 (2022)
Mexico: 43.5 (2022)
Netherlands 25.7 (2021)

Source: https://data.worldbank.org/indicator/SI.POV.GINI

*- HDI
Peru: 0.762
Chile: 0.860
Sweden: 0.952
Croatia: 0.878
US:	0.927

Source: https://hdr.undp.org/data-center/human-development-index#/indicies/HDI


*- Government Spending in Tertiary (% GDP per capita)
Peru: 10.9
Chile: 20.3
Croatia: 25.7
Sweden: 43.2
US: 19.4

Source: https://data.worldbank.org/indicator/SE.XPD.TERT.PC.ZS?view=chart
*/

*- Comparing Educational Attainments:
clear

gen country = "Peru"

//Source: https://www.oecd.org/en/publications/education-at-a-glance-2024_c00cad36-en/full-report.html



*- Information about my dataset

*-- Define a population of interest
use "$OUT\students", clear

*- Only regular size families
keep if inlist(fam_total_${fam_type},2,3,4,5,6,7)==1

*- Conditioning on older sibling outcomes
bys id_fam_2: egen oldest_grad 			= max(cond(sec_grad==1 & fam_order_${fam_type}==1,1,0))
bys id_fam_2: egen oldest_app 			= max(cond(applied==1 & fam_order_${fam_type}==1,1,0))
bys id_fam_2: egen oldest_app_public 	= max(cond(applied==1 & public==1 & fam_order_${fam_type}==1,1,0))
bys id_fam_2: egen oldest_enr 			= max(cond(applied==1 & enrolled==1 &  fam_order_${fam_type}==1,1,0))
bys id_fam_2: egen oldest_enr_public 	= max(cond(applied==1 & enrolled==1 & public==1 & fam_order_${fam_type}==1,1,0))

//Since the treatment might be 'older sibling' rather than 'oldest', we consider that.
bys id_fam_2: egen order_oldest_app 	= min(cond(applied==1,fam_order_${fam_type},.))
gen older_app = (order_oldest_app<fam_order_${fam_type})

bys id_fam_2: egen order_oldest_enr 	= min(cond(enrolled==1,fam_order_${fam_type},.))
gen older_enr = (order_oldest_enr<fam_order_${fam_type})

// SIAGIE starts in 2014. The first applications in 2017. So we can see it first for those who were in 8th grade in 2014 (II sec):
*- For each outcome, we have a different sample of interest. Essentially we are interested in those that would be observed AFTER older sibling application.
gen sample_ece_2p 		=   (year_2p>=2017 & year_2p<=2023) //
gen sample_ece_4p 		= 	(year_4p>=2017 & year_4p<=2023)
gen sample_ece_2s 		= 	(year_2s>=2017 & year_2s<=2023)
gen sample_dropout		=  	(exp_graduating_year2>=2017 & exp_graduating_year2<=2023) 
gen sample_applied		= 	(exp_graduating_year2>=2016 & exp_graduating_year2<=2022) 
gen sample_enrolled 	= 	(exp_graduating_year2>=2016 & exp_graduating_year2<=2022) 

//keep if exp_graduating_year2>=2017 & exp_graduating_year2<2023

*- Samples of interest
gen sample_1 = 1 															//All students
gen sample_2 = (fam_order_${fam_type}>1) 									//Students with older siblings
gen sample_3 = (oldest_app==1 			& fam_order_${fam_type}>1) 			//Students with older siblings that apply
gen sample_4 = (oldest_app_public==1 	& fam_order_${fam_type}>1) 			//Students with older siblings that apply to public
gen sample_5 = (oldest_enr==1 			& fam_order_${fam_type}>1) 			//Students with older siblings that apply and enroll
gen sample_6 = (oldest_enr_public==1 	& fam_order_${fam_type}>1) 			//Students with older siblings that apply and enroll to public

*- Total number of observations
forvalues i = 1/6 {
	count if sample_`i'==1
	}

*- Average Scores of students
	
	
*- How many drop out of school
di as result "Dropout"
forvalues i = 1/6 {
	sum dropout if sample_`i'==1 & sample_dropout==1
	//tabstat dropout if sample_`i'==1, by(exp_entry_year) //## Something to note is the high dropout rate in students that graduated during COVID?
	}
// 26.4% of students drop out

*- Expectations for educational attainment
di as result "ECE Math"
forvalues i = 1/6 {
	sum score_math_std_2p if sample_`i'==1 & sample_ece_2p==1
	}
	
//Since we are doing those expected to graduate before 2023 (because we wan't applications in 2022)	
forvalues i = 1/6 {
	sum score_math_std_4p if sample_`i'==1 & sample_ece_4p==1
	}
	
forvalues i = 1/6 {
	sum score_math_std_2s if sample_`i'==1
	}	
 score_math_std_4p score_math_std_2s

*- How many applied to college
di as text "Applied"
forvalues i = 1/6 {
	sum applied if sample_`i'==1
	sum applied_public if sample_`i'==1
	sum applied_private if sample_`i'==1
	//sum applied if sec_grad == 1 & sample_`i'==1
	//tabstat applied if sample_`i'==1, by(exp_entry_year)
	}
// 38.3% of students applied
// 48.9% of students who graduate applied


*- How many applied to college
di as text "Enrolled"
forvalues i = 1/6 {
	sum enrolled if sample_`i'==1
	sum enrolled_public if sample_`i'==1
	sum enrolled_private if sample_`i'==1
	//sum enrolled if sec_grad == 1 & sample_`i'==1
	//tabstat enrolled if sample_`i'==1, by(exp_entry_year)
	}
// 27.6% of students applied
// 35.7% of students who graduate applied


tab dropout applied, row nofreq
//## Something to note. How did some of the dropouts applied? Did they finish somewhere else. Did they applied without finishing school?

end


********************************************************************************
* enaho
********************************************************************************

capture program drop enaho
program define enaho

*- Statistics by education level: Employment, formal employment and wage
use "$DB\research\projectsX\databases\ENAHO\2023\enaho01a-2023-300", clear


//source: https://www.oecd.org/en/topics/sub-issues/earnings-by-educational-attainment.html
//Note: 1. Index 100 refers to the combined ISCED levels 3 and 4 in the ISCED 2011 classification. 
//3 Upper secondary education
//4 Post-secondary non-tertiary education

	keep conglome vivienda hogar codperso p207 p208a p301a  
	
	drop if p301a==12
	
	gen educ_level = .
	replace educ_level = 1 if inlist(p301a,1,2,3,4,5)
	replace educ_level = 2 if inlist(p301a,6,7,8,9)
	replace educ_level = 3 if inlist(p301a,10,11)
	
	//In our case, we have to exclude 2+ college completed as it is not relevant for the estimation.
	drop if inlist(p301a,8)==1
	//Should we drop beyond 4+ years? (masters, PhD) ###
	
	label define educ_level 1 "Secondary incomplete" 2 "Secondary Complete" 3 "4+ college complete"
	label values educ_level educ_level
	
	tempfile educ
	save `educ', replace

use "$DB\research\projectsX\databases\ENAHO\2023\enaho01a-2023-500", clear

	keep conglome vivienda hogar codperso ocu500 ocupinf emplpsec  i524a1 i524e1 i538a1 i538e1 i538e1 i530a i541a fac500a

	egen ytot = rsum(i524e1 i538e1 i530a i541a)
	gen yop = i524e1/ytot
	sum yop, de //most of it is the main occupation

	replace ytot = ytot/3.71 //USD to PEN conversion
	
	gen empl = ocu500==1
	gen empl_f = empl==1 & ocupinf==2
	
	keep conglome vivienda hogar codperso ytot empl empl_f fac500a
	tempfile income
	save `income', replace
	
use `educ', clear
merge 1:1 conglome vivienda hogar codperso using `income', keepusing(ytot empl empl_f fac500a) keep(master match )

keep if _m==3
keep if p208a>=25 & p208a<65

tab p208a educ_level  if p208a<65, row nofreq

*- Wage premium
sum ytot if educ_level==1
local ytot_1 = r(mean)
sum ytot if educ_level==2
local ytot_2 = r(mean)
sum ytot if educ_level==3
local ytot_3 = r(mean)
sum ytot if educ_level!=3
local ytot_not3 = r(mean)

local wprem1: display %9.1f `ytot_3'/`ytot_not3'*100-100 "%"
local wprem2: display %9.1f `ytot_3'/`ytot_2'*100-100 "%"

di "`wprem1'"
di "`wprem2'"

*- Formal Employment Gap
sum empl_f if educ_level==1
local empl_f_1 = r(mean)
sum empl_f if educ_level==2
local empl_f_2 = r(mean)
sum empl_f if educ_level==3
local empl_f_3 = r(mean)
sum empl_f if educ_level!=3
local empl_f_not3 = r(mean)

local efprem1: display %9.1f `empl_f_3'/`empl_f_not3'*100 "%"
local efprem2: display %9.1f `empl_f_3'/`empl_f_2'*100 "%"
local efgap: display %9.1f  (`empl_f_3' - `empl_f_2')*100

di "`efprem1'"
di "`efprem2'"
di `efgap'

*- Overall employment gap
sum empl if educ_level==1
local empl_1 = r(mean)
sum empl if educ_level==2
local empl_2 = r(mean)
sum empl if educ_level==3
local empl_3 = r(mean)
sum empl if educ_level!=3
local empl_not3 = r(mean)

local eprem1: display %9.1f `empl_3'/`empl_not3'*100 "%"
local eprem2: display %9.1f `empl_3'/`empl_2'*100 "%"
local egap: display %9.1f  (`empl_3' - `empl_2')*100

di "`eprem1'"
di "`eprem2'"
di `egap'


/*
*- Results are consistent with removing outliers
forvalues i=1/3 {
	sum ytot if educ_level==`i', de
	replace ytot = . if ytot>r(p99) & educ_level==`i'
	}
*/

collapse ytot empl empl_f [pw=fac500a], by(p208a educ_level)

/*
local ytot_3 = 7180.909
local ytot_2 = 3256.712 
local wprem2 = "110.5%"
*/
twoway 	(line ytot p208a if educ_level==3) ///
		(line ytot p208a if educ_level==2) ///
		, ///
		xtitle("Age") ///
		ytitle("Annual Net Income ($)") ///
		yline(`ytot_3',lcolor("26 133 255")) ///
		yline(`ytot_2',lcolor("212 17 89")) ///
		text(10000 25  ///
				"College wage premium = `wprem2' " ///
				 ,box bcolor(gs16) place(ne)  justification(left)) ///
		xlab(25(5)65) ///
		ylab(2000 "2,000" 4000 "4,000" 6000 "6,000" 8000 "8,000" 10000 "10,000" 12000 "12,000") ///
		legend(label(1 "4+ College completed") label(2 "Secondary Completed") pos(6) col(2))
	graph export 	"$FIGURES/png/college_wage_premium.png", replace
	graph export 	"$FIGURES/eps/college_wage_premium.eps", replace	
	graph export 	"$FIGURES/pdf/college_wage_premium.pdf", replace	

/*
local empl_f_3=.6160633
local empl_f_2= .2007
local efgap = "41.5"
*/
twoway 	(line empl_f p208a if educ_level==3) ///
		(line empl_f p208a if educ_level==2) ///
		, ///
		xtitle("Age") ///
		ytitle("Formal Employment (%)") ///
		yline(`empl_f_3',lcolor("26 133 255")) ///
		yline(`empl_f_2',lcolor("212 17 89")) ///
		text(.75 26 ///
				"Formal employment gap = `efgap' " ///
				 ,box bcolor(gs16) place(ne)  justification(left)) ///
		ylab(.2 "20%" .4 "40%" .6 "60%" .8 "80%") ///
		legend(label(1 "4+ College completed") label(2 "Secondary Completed") pos(6) col(2))
	graph export 	"$FIGURES/png/employment_f_gap.png", replace
	graph export 	"$FIGURES/eps/employment_f_gap.eps", replace	
	graph export 	"$FIGURES/pdf/employment_f_gap.pdf", replace	
	
	
	
	
//RESULTS
/*
1. College wage premium in Peru: 210% compared to those who completed secondary.
2. Employment gap is mostly through formal employment: 36.7 pp difference. Overall employment only has a 4.2pp gap.


Output: 
college_wage_premium.png
employment_f_gap.png
*/

end


********************************************************************************
* survey_alumni
********************************************************************************

capture program drop survey_alumni
program define survey_alumni

	*- University Survey
	import dbase using "$IN\Encuesta Nacional a Egresados Universitarios y Universidades 2014\04_EGRESADOS_CAP300.dbf", clear

end



********************************************************************************
* census_college
********************************************************************************

capture program drop census_college
program define census_college


	//IT HAS DATA ON LOCATION AND DATE OF BIRTH... CAN WE MATCH?
	import dbase using "$IN\II Censo Nacional Universitario 2010\01_CENAUN_CED01_PRE-GRADO_01.dbf", clear
	import dbase using "$IN\II Censo Nacional Universitario 2010\01_CENAUN_CED01_PRE-GRADO_02.dbf", clear


end

********************************************************************************
* stem
********************************************************************************

capture program drop stem
program define stem


	use "$OUT/applied_outcomes_${fam_type}.dta", clear
	gen stem_major = inlist(major_c1_cat,5,6,7)
	table  stem_major male_siagie_foc male_siagie_sib , stat(mean applied_major_sib)
	
	// notice how women apply in very low levels if a male older sibling.


end

********************************************************************************
* descriptive_admissions
********************************************************************************

capture program drop descriptive_admissions
program define descriptive_admissions


use "$TEMP\applied", clear

merge m:1 id_per_umc using "$OUT\students", keepusing(score_math_std_?? score_com_std_?? score_acad_std_?? year_??) keep(master match) nogen 
	rename (score_math_std_?? score_com_std_?? score_acad_std_?? year_??) (score_math_std_??_foc score_com_std_??_foc  score_acad_std_??_foc year_??_foc)
	

preserve
	tabstat admitted, by(public)

	sum admitted if public==0
	local m_pri = r(mean)
	local m_pri_text: display %9.1f r(mean)*100 "%"
	local m_pri_coord = r(mean)+0.015

	sum admitted if public==1 
	local m_pub = r(mean)
	local m_pub_text: display %9.1f r(mean)*100 "%"
	local m_pub_coord = r(mean)+0.015

	collapse admitted, by(universidad public year)

	twoway 	(histogram admitted if public==1, bins(30) fcolor(blue%20) lcolor(blue%80) xline(`m_pub', lcolor(blue))) ///
			(histogram admitted if public==0, bins(30) fcolor(green%20) lcolor(green%80) xline(`m_pri', lcolor(green))) ///
			, ///
			xtitle("Admission rates") ///
			legend(label(1 "Public") label(2 "Private") pos(6) col(2)) ///
			text(5.5 `m_pub_coord'  ///
				"Public mean:" "`m_pub_text'" ///
				 ,box bcolor(gs16) place(ne)  justification(left)) ///
			text(5.5 `m_pri_coord'  ///
			"Private mean:" "`m_pri_text'" ///
			 ,box bcolor(gs16) place(ne)  justification(left))	 

			graph export 	"$FIGURES/eps/admission_rates.eps", replace	
			graph export 	"$FIGURES/png/admission_rates.png", replace	
			graph export 	"$FIGURES/pdf/admission_rates.pdf", replace		
			
restore

preserve
	keep if admitted==1	
	
	local out = "score_math_std_2s_foc"
	if "`out'" == "score_math_std_2s_foc" {
		local out_t = "math"
		local out_x = "Admitted peers score in 8th grade Mathematics"
	}
	if "`out'" == "score_com_std_2s_foc" {
		local out_t = "com"
		local out_x = "Admitted peers score in 8th grade Reading"
	}

	sum `out' if public==0
	local m_pri = r(mean)
	local m_pri_text: display %9.2f r(mean)
	local m_pri_coord = r(mean)-1.1

	sum `out' if public==1 
	local m_pub = r(mean)
	local m_pub_text: display %9.2f r(mean)
	local m_pub_coord = r(mean)+0.02

	collapse `out' , by(universidad public year)


	twoway 	(histogram `out' if public==1, bins(30) fcolor(blue%20) lcolor(blue%80) xline(`m_pub', lcolor(blue))) ///
			(histogram `out' if public==0, bins(30) fcolor(green%20) lcolor(green%80) xline(`m_pri', lcolor(green))) ///
			, ///
			xtitle("`out_x'") ///
			legend(label(1 "Public") label(2 "Private") pos(6) col(2)) ///
			text(1 `m_pub_coord'  ///
				"Public mean:" "`m_pub_text'" ///
				 ,box bcolor(gs16) place(ne)  justification(left)) ///
			text(1 `m_pri_coord'  ///
			"Private mean:" "`m_pri_text'" ///
			 ,box bcolor(gs16) place(ne)  justification(left))	 

			graph export 	"$FIGURES/eps/admission_2s_`out_t'_grades.eps", replace	
			graph export 	"$FIGURES/png/admission_2s_`out_t'_grades.png", replace	
			graph export 	"$FIGURES/pdf/admission_2s_`out_t'_grades.pdf", replace		

restore

end



********************************************************************************
* Aspirations
********************************************************************************

capture program drop descriptive_student_aspirations
program define descriptive_student_aspirations

	use "$OUT/students",clear
	
	*- Application % per aspiration level. 
	table year_2p aspiration_2p if inlist(year_2p,2015,2016,2019)==1, stat(mean pri_grad)	
	table year_4p aspiration_4p if inlist(year_4p,2016)==1			, stat(mean pri_grad)

	table year_4p aspiration_4p if inlist(year_4p,2016)==1			, stat(mean sec_grad)	
	
	table year_2s aspiration_2s, stat(mean applied)
	table year_2s aspiration_2s, stat(mean sec_grad)
	//Low application for first 3 levels. Higher at 4 and 5.
	//Thoughts: 
		//What makes someone who thought they wouldn't finish secondary, apply?
		//What makes someone who thought they would achieve graduate studies, not apply?
	
	graph bar higher_ed_2s if inlist( educ_mother,2,3,4,5,6,7,8)==1, ///
	over(educ_mother, relabel(1 "PI" 2 "PC" 3 "SI" 4 "SC" 5 "HI" 6 "HC" 7 "PG")) ///
	ytitle("% who expect will get higher education")
			 
		graph export 	"$FIGURES/eps/asp_2s_mother_ed.eps", replace	
		graph export 	"$FIGURES/png/asp_2s_mother_ed.png", replace	
		graph export 	"$FIGURES/pdf/asp_2s_mother_ed.pdf", replace		
		
	binsreg higher_ed_2s score_math_std_2s if abs(score_math_std_2s)<2 ///
		, ///
		nbins(100) ///
		xline(0) ///
		ylabel(0.6(.1)1) ///
		xtitle("8th grade Mathematics standardized score") ///
		xtitle("% who expect to get 4+ years of college") ///
		xsize(5.5) ///
		ysize(5) ///
		///by(ABOVE) ///
		bycolors(gs0 gs0) ///
		bysymbols(o o) ///
		legend(off) 

		graph export 	"$FIGURES/eps/asp_2s_math.eps", replace	
		graph export 	"$FIGURES/png/asp_2s_math.png", replace	
		graph export 	"$FIGURES/pdf/asp_2s_math.pdf", replace		
end




*******************************
*- Descriptive Statistics
*******************************


capture program drop descriptive_student_applications
program define descriptive_student_applications
	
	use "$OUT/students",clear
	
	//keep if runiform()<0.05
	
	tab applied if sec_grad==1
	
	keep if year_graduate>=2017 & year_graduate!=.
	
	gen semester = string(year_graduate+1) + "-1" //1 term after graduation
	merge 1:1 id_per_umc semester using "$TEMP\total_applications_student_semester", keepusing(id_per_umc semester N_applications_semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m applied_t1
	rename N_applications_semester N_applications_semester_t1

	
	merge 1:1 id_per_umc semester using "$TEMP\enrolled_students_semester", keepusing(id_per_umc semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m enrolled_t1	
	drop semester
	
	gen semester = string(year_graduate+1) + "-2" //1 term after graduation
	merge 1:1 id_per_umc semester using "$TEMP\total_applications_student_semester", keepusing(id_per_umc semester N_applications_semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m applied_t2
	rename N_applications_semester N_applications_semester_t2
	merge 1:1 id_per_umc semester using "$TEMP\enrolled_students_semester", keepusing(id_per_umc semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m enrolled_t2	
	drop semester
	
	gen semester = string(year_graduate+2) + "-1" //1 term after graduation
	merge 1:1 id_per_umc semester using "$TEMP\total_applications_student_semester", keepusing(id_per_umc semester N_applications_semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m applied_t3
	rename N_applications_semester N_applications_semester_t3
	merge 1:1 id_per_umc semester using "$TEMP\enrolled_students_semester", keepusing(id_per_umc semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m enrolled_t3
	drop semester	
	
	gen semester = string(year_graduate+2) + "-2" //1 term after graduation
	merge 1:1 id_per_umc semester using "$TEMP\total_applications_student_semester", keepusing(id_per_umc semester N_applications_semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m applied_t4
	rename N_applications_semester N_applications_semester_t4
	merge 1:1 id_per_umc semester using "$TEMP\enrolled_students_semester", keepusing(id_per_umc semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m enrolled_t4
	drop semester		
	
	gen semester = string(year_graduate+3) + "-1" //1 term after graduation
	merge 1:1 id_per_umc semester using "$TEMP\total_applications_student_semester", keepusing(id_per_umc semester N_applications_semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m applied_t5
	rename N_applications_semester N_applications_semester_t5
	merge 1:1 id_per_umc semester using "$TEMP\enrolled_students_semester", keepusing(id_per_umc semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m enrolled_t5
	drop semester	
	
	gen semester = string(year_graduate+3) + "-2" //1 term after graduation
	merge 1:1 id_per_umc semester using "$TEMP\total_applications_student_semester", keepusing(id_per_umc semester N_applications_semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m applied_t6
	rename N_applications_semester N_applications_semester_t6
	merge 1:1 id_per_umc semester using "$TEMP\enrolled_students_semester", keepusing(id_per_umc semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m enrolled_t6
	drop semester
	
	gen semester = string(year_graduate+4) + "-1" //1 term after graduation
	merge 1:1 id_per_umc semester using "$TEMP\total_applications_student_semester", keepusing(id_per_umc semester N_applications_semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m applied_t7
	rename N_applications_semester N_applications_semester_t7
	merge 1:1 id_per_umc semester using "$TEMP\enrolled_students_semester", keepusing(id_per_umc semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m enrolled_t7
	drop semester	
	
	gen semester = string(year_graduate+4) + "-2" //1 term after graduation
	merge 1:1 id_per_umc semester using "$TEMP\total_applications_student_semester", keepusing(id_per_umc semester N_applications_semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m applied_t8
	rename N_applications_semester N_applications_semester_t8
	merge 1:1 id_per_umc semester using "$TEMP\enrolled_students_semester", keepusing(id_per_umc semester) keep(master match)
	recode _m (1 = 0) (3 = 1)
	rename _m enrolled_t8
	drop semester	
	
	keep if year_graduate>=2017 &  year_graduate<=2019
	collapse applied_t? enrolled_t?  N_applications_semester_t?
	//Applications similar per year, enrollments slightly increase
	gen n=1
	
	
	reshape long applied_t enrolled_t N_applications_semester_t, i(n) j(time)
	
	twoway ///
		(line applied_t enrolled_t time if time<=6) ///
		(line N_applications_semester_t time if time<=6, yaxis(2)) ///
		, ///
		ylabel(0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%") ///
		xlabel(1 "+1 Semester" 2 "+2" 3 "+3" 4 "+4" 5 "+5" 6 "+6") ///
		xtitle("Semester after HS graduation") ///
		ytitle("%Applications/%Enrolled", axis(1)) ///
		ytitle("# of applications per student who applied", axis(2)) ///
		legend(label(1 "Applied") label(2 "Enrolled") label(3 "# of applications") cols(3) pos(6))
		
		
			 
		graph export 	"$FIGURES/eps/applications_after_hs.eps", replace	
		graph export 	"$FIGURES/png/applications_after_hs.png", replace	
		graph export 	"$FIGURES/pdf/applications_after_hs.pdf", replace			
	/*	
	collapse applied_t? enrolled_t?, by(year_graduate)
	reshape long applied_t enrolled_t, i(year_graduate) j(time)
	
	twoway ///
		(line enrolled_t  time if year_graduate==2017) ///
		(line enrolled_t  time if year_graduate==2018) ///
		(line enrolled_t  time if year_graduate==2019) ///
		(line enrolled_t  time if year_graduate==2020) ///
		(line enrolled_t  time if year_graduate==2021) ///	
		(line enrolled_t  time if year_graduate==2022) 	
	*/
end


*******************************
*- Descriptive Statistics
*******************************


capture program drop descriptive_student_region
program define descriptive_student_region

	use "$TEMP/applied.dta", clear
	bys universidad: keep if _n==1
	tab region public
	//12 regions: 1 public school
	//11 regions: 2 public schools
	//3 regions: 3 public schoools
	// Lima: 11 public schools
	
	use "$OUT/applied_outcomes_${fam_type}.dta", clear
	
	bys id_per_umc id_cutoff_major: keep if _n==1
	
	gen same_region = region_siagie_foc == region_foc
	replace same_region = 1 if region_siagie_foc==7 & region_foc==15 //Lima and Callao are in the same city
	replace same_region = 1 if region_siagie_foc==15 & region_foc==7 //Lima and Callao are in the same city
	
	preserve
		keep if public_foc==1
		gen pop = 1
		collapse (sum) pop (mean) same_region, by(region_foc)
		sort pop
		list
		twoway (scatter same_region pop ), ///
		 ytitle("Applies within same region") ///
		 xtitle("# of applications") ///
		 xlabel(50000 "50,000" 100000 "100,000" 150000 "150,000" 200000 "200,000" 250000 "250,000")
			 
		graph export 	"$FIGURES/eps/applications_public_region.eps", replace	
		graph export 	"$FIGURES/png/applications_public_region.png", replace	
		graph export 	"$FIGURES/pdf/applications_public_region.pdf", replace	
	restore
	
	preserve
		keep if public_foc==0
		drop if region_foc == 99
		gen pop = 1
		collapse (sum) pop (mean) same_region, by(region_foc)
		sort pop
		list
		twoway (scatter same_region pop ), ///
		 ytitle("Applies within same region") ///
		 xtitle("# of applications") ///
		 xlabel(50000 "50,000" 100000 "100,000" 150000 "150,000" 200000 "200,000" 250000 "250,000")

		graph export 	"$FIGURES/eps/applications_private_region.eps", replace	
		graph export 	"$FIGURES/png/applications_private_region.png", replace	
		graph export 	"$FIGURES/pdf/applications_private_region.pdf", replace	
	restore	
end


*******************************
*- Descriptive Statistics
*******************************


capture program drop descriptive_siblings_vs_rest
program define descriptive_siblings_vs_rest

	args fam_type
	
	global fam_type = `fam_type'

	use "$OUT/students.dta", clear

	/*
	Panel A: Demographic characteristics
		Female
		Age when applying
		Household size
		Race: white

	Panel B: Socioeconomic characteristics
		High Income
		Mid Income
		Low income
		Parental ed: 4-year college

	Panel C: Academic characteristics
		High school track: academic
		Takes admission test
		High school GPA score
		Admission test avg. score
		Applicants



	*/

	//older sibling applied
	bys id_fam_${fam_type}: egen older_applied = max(cond(fam_order_${fam_type}==1 & applied==1,1,0))

	//Relevant population (potential applicants)
	keep if exp_graduating_year1+1>=2017 & exp_graduating_year1+1<=2023

	//Younger siblings (of an older sibling who applied)
	gen sample_sib_applicants = (applied==1 & older_applied==1 & fam_order_${fam_type}!=1)

	//All applicants
	gen sample_all_applicants = (applied==1) //All applicants

	//All students
	gen sample_all_students = 1 

	count 
	local N = r(N)
	count if sample_sib_applicants == 1
	local obs_sample_sib_applicants: di %9.0fc r(N)
	count if sample_all_applicants == 1
	local obs_sample_all_applicants: di %9.0fc r(N)
	count if sample_all_students == 1
	local obs_sample_all_students: di %9.0fc r(N)

		di as text  _n "Sample younger siblings who apply:" _column(40) %9.0fc `obs_sample_sib_applicants' " obs."  %9.1f `obs_sample_sib_applicants'*100/`N' "% of sample" ///
					_n "Sample all applicants:" _column(40) %9.0fc `obs_sample_all_applicants' " obs."  %9.1f `obs_sample_all_applicants'*100/`N' "% of sample"  ///
					_n "Sample all potential applicants:" _column(40) %9.0fc `obs_sample_all_students' " obs." %9.1f `obs_sample_all_students'*100/`N' "% of sample" 
					

	//Additional variables needed
	tab socioec_index_cat_fam, gen(ses_)
	gen byte higher_ed_mother 		= inlist(educ_mother,7,8) if educ_mother!=. & educ_mother!=1				
					
	texdoc init "$TABLES/summary_stats_1_${fam_type}.tex" , replace force
		tex \begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
		tex \caption{Summary statistics}\label{tab:table_summary} 
		tex \scalebox{1}{\setlength{\textwidth}{.1cm}
		tex	\newcommand{\contents}{
		tex	\begin{tabular}{lccc}
		tex \toprule
		tex 	& Younger 	& All			& All potential			\\
		tex  	& siblings  & applicants 	& applicants 			\\ 
		tex  	& (1) 		& (2)		 	& (3) 					\\ \hline	
		


		foreach outcome in 	/*PANEL A*/ "Panel A" "male_siagie" "fam_total_${fam_type}"  ///
							/*PANEL B*/ "Panel B" "ses_4" "ses_3" "ses_2" "ses_1" "higher_ed_mother" ///
							/*PANEL C*/ "Panel C" /*"score_relative"*/ "enrolled" "enrolled_lpred1" "enrolled_lpred3"  {
								
								
								
		if "`outcome'" == "Panel A" {
			tex 	&			& 				& 						\\
			tex \multicolumn{4}{l}{Panel A: Demographics Characteristics} \\
			continue
		}
		
		if "`outcome'" == "Panel B" {
			tex 	&			& 				& 						\\
			tex \multicolumn{4}{l}{Panel B: Socioeconomic characteristics} \\
			continue
		}
		
		if "`outcome'" == "Panel C" {
			tex 	&			& 				& 						\\
			tex \multicolumn{4}{l}{Panel C: Academic characteristics} \\
			continue
		}
		
		if "`outcome'" == "male_siagie" 			local rowname "\hspace{3mm}Female"
		if "`outcome'" == "fam_total_${fam_type}" 	local rowname "\hspace{3mm}Household size (children)"
		//if "`outcome'" == "applied_ppublic" 		local rowname "Age when applying"
		//if "`outcome'" == "enrolled" 				local rowname "Household size"
		//if "`outcome'" == "enrolled_public" 		local rowname "White"
		
		if "`outcome'" == "ses_4" 				local rowname "\hspace{3mm}High Income"
		if "`outcome'" == "ses_3" 				local rowname "\hspace{3mm}Mid Income"
		if "`outcome'" == "ses_2" 				local rowname "\hspace{3mm}Low income"
		if "`outcome'" == "ses_1" 				local rowname "\hspace{3mm}Very Low income"
		if "`outcome'" == "higher_ed_mother" 	local rowname "\hspace{3mm}Mother ed: Higher ed. complete"			
		
		//if "`outcome'" == "applied" 			local rowname "High school track: academic"
		//if "`outcome'" == "applied_ppublic" 	local rowname "Takes admission test"
		//if "`outcome'" == "enrolled" 			local rowname "High school GPA score"
		if "`outcome'" == "score_relative" 		local rowname "\hspace{3mm}Admission test avg. score"	
		if "`outcome'" == "enrolled" 			local rowname "\hspace{3mm}Enrolled"	
		if "`outcome'" == "enrolled_lpred1" 	local rowname "\hspace{3mm}Likelihood of enrollment 1"
		if "`outcome'" == "enrolled_lpred3" 	local rowname "\hspace{3mm}Likelihood of enrollment 3"	
		//if "`outcome'" == "latino" local rowname "Latino applicants"
		//if "`outcome'" == "asian" local rowname "Asian applicants"
	

		summ `outcome' if sample_sib_applicants == 1
		local mean_sample_sib_applicants: display%9.2f round(r(mean), .01)
		summ `outcome' if sample_all_applicants == 1
		local mean_sample_all_applicants: display%9.2f round(r(mean), .01)	
		summ `outcome' if sample_all_students == 1
		local mean_sample_all_students: display%9.2f round(r(mean), .01)		
	
		//In some cases, we are not interested in the statistic for 'all students' since it is restricted to those who applied.
		if "`outcome'" == "score_relative" local mean_sample_all_students= ""
		
		//Write down statistics
		texdoc write `rowname' & `mean_sample_sib_applicants' & `mean_sample_all_applicants' & `mean_sample_all_students' \\
		
		}
		
		tex 	&			& 				& 						\\
		texdoc write Observations & `obs_sample_sib_applicants' & `obs_sample_all_applicants' & `obs_sample_all_students' \\

		tex \bottomrule \multicolumn{4}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}
		tex \setbox0=\hbox{\contents}\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} 
		tex \end{table}
		texdoc close	
				
				
*******************************************************************
/*
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

*/

end

********************************************************************************
* How correlated are different exam takes. Is there a lot of noise when taking exams? Do students improve between takes?
********************************************************************************

capture program drop correlation_multiple_takes
program define correlation_multiple_takes


	use "$TEMP/applied", clear


	drop if id_per_umc == ""
	bys id_per_umc: drop if _N==1

	bys id_per_umc universidad major_c1_name (semester): drop if _N==1
	bys id_per_umc universidad major_c1_name (semester): gen n = _n
	
	/*
	sort id_per_umc universidad semester

	br id_per_umc universidad semester id_periodo_postulacion major_c1_name score_raw score_std_major

	replace semester=subinstr(semester,"-","",.)
	destring semester, replace
	*/
	
	egen major = group(major_c1_name)
	keep id_per_umc universidad major /*semester*/ score_raw score_std_major n
	reshape wide score_raw score_std_major, i(id_per_umc universidad major) j(n)

	pwcorr score_std_major1 score_std_major2 score_std_major3 score_std_major4
	
end




******************************************************************************** 
* Sibling statistics
* 
* Description: 
********************************************************************************

capture program drop figures
program define figures

use "$OUT/students.dta", clear


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


end





******************************************************************************** 
* Sibling statistics
* 
* Description: 
********************************************************************************

capture program drop descriptive_siblings
program define descriptive_siblings

	use "$OUT/applied_outcomes.dta", clear


end

******************************************************************************** 
* General descriptive
* 
* Description: 
********************************************************************************

capture program drop descriptive_student
program define descriptive_student

	use "$OUT\students", clear

	*- Sample Estimates
	*- # of students in 11th grade
	tab last_year if last_grade==11
	//~450,000 per year
	
	*- # of students applying
	use "$TEMP\applied", clear
	bys id_persona_reco (year): keep if _n==1 //keep first application
	tab year
	//~350,000.... almost all? Something wrong here... perhaps because people apply more than once but still seems too high.
	//That is ~	77% of students who finish HS
	
	use "$OUT\students", clear
	
	*- Expected year of finish
	
	
	*- 2nd sibling variables
	foreach v of var exp_graduating_year1 merge_ece_?? merge_ece_survey_?? source_?? {
		bys id_fam_4: egen younger_`v' = max(cond(fam_order_4==2,`v',.))
	}
	

	
	tab exp_graduating_year1
	tab exp_graduating_year1 if fam_order_4==2 & fam_total_4==2
	tab exp_graduating_year1 if fam_order_4==2 & fam_total_4==2 & merge_ece_survey_2p==3 & source_2p==1
	tab exp_graduating_year1 if fam_order_4==2 & fam_total_4==2 & merge_ece_survey_2p==3 & source_2p==2
	tab exp_graduating_year1 if fam_order_4==2 & fam_total_4==2 & merge_ece_survey_4p==3 & source_4p==1
	tab exp_graduating_year1 if fam_order_4==2 & fam_total_4==2 & merge_ece_survey_4p==3 & source_4p==2
	tab exp_graduating_year1 if fam_order_4==2 & fam_total_4==2 & merge_ece_survey_2s==3 & source_2s==1
	tab exp_graduating_year1 if fam_order_4==2 & fam_total_4==2 & merge_ece_survey_2s==3 & source_2s==2
	
	*- Potential Older sibling sample
	*-- Those who graduate between 2016-2022
	preserve
		keep if exp_graduating_year1>=2016 & exp_graduating_year1<=2021 & fam_order_4==1 & fam_total_4>=2
		tab younger_exp_graduating_year1 if younger_exp_graduating_year1>=2016 & younger_exp_graduating_year1<=2022
		// 250k potential applications
		count if younger_merge_ece_2p==3 //332,780
		count if younger_merge_ece_4p==3 //125,097
		count if younger_merge_ece_2s==3 //183,715
		
		count if younger_merge_ece_survey_2p==3 //47,371
		count if younger_merge_ece_survey_4p==3 //121,413
		count if younger_merge_ece_survey_2s==3 //203,435
		
		count if younger_merge_ece_survey_2s==3 & merge_ece_survey_2s==3 //104,953		
		tab exp_graduating_year1 if younger_merge_ece_survey_2s==3 & merge_ece_survey_2s==3 //104,953		
		//
		tab younger_source_2p
		tab younger_source_4p
		tab younger_source_2s
	restore
	
	*-- Among those:
	*---	Younger siblings graduating 2016-2022 (For application data)
	
	*---	What years are ECE from younger siblings (For exam data)
	
	*---	What years are Survey ECE from younger siblings (For Aspirations)
	
	
	/*
	gen u = runiform()
	keep if u<0.1
	drop u
	*/
	
	*-- Higher Education and STD score
	*- General population
		binsreg higher_ed_2s score_math_std_2p if abs(score_math_std_2p)<2, ///
		ytitle("% who expect their kid will get higher education") ///
		xtitle("2nd grade standardized score")
	binsreg higher_ed_4p score_math_std_4p
	binsreg higher_ed_2s score_math_std_2s if abs(score_math_std_2s)<2, ///
		ytitle("% who expect will get higher education") ///
		xtitle("8th grade standardized score")
	
	*-- Higher Education and Econ Index
	*- General population
	binsreg higher_ed_2p score_math_std_2p
	binsreg higher_ed_4p score_math_std_4p
	binsreg higher_ed_2s score_math_std_2s	
	
	*- With siblings
	binsreg higher_ed_2p score_math_std_2p if fam_total_4==2 & fam_order_4==1
	binsreg higher_ed_4p score_math_std_4p if fam_total_4==2 & fam_order_4==1
	binsreg higher_ed_2s score_math_std_2s if fam_total_4==2 & fam_order_4==1
	
	binsreg higher_ed_2p score_math_std_2p if fam_total_4==2 & fam_order_4==2
	binsreg higher_ed_4p score_math_std_4p if fam_total_4==2 & fam_order_4==2
	binsreg higher_ed_2s score_math_std_2s if fam_total_4==2 & fam_order_4==2	
	
	*- Higher Education and education of mother
	graph bar if inlist( educ_mother,1,2,3,4,5,6,7,8)==1, over(educ_mother) stack percent asyvars
	tab aspiration_2p, gen(aspiration_2p_)
	graph bar higher_ed_2p if inlist( educ_mother,1,2,3,4,5,6,7,8)==1, ///
	over(educ_mother, relabel(1 "None" 2 "PI" 3 "PC" 4 "SI" 5 "SC" 6 "HI" 7 "HC" 8 "PG")) ///
	ytitle("% who expect their kid will get higher education")
	
	graph bar higher_ed_2s if inlist( educ_mother,1,2,3,4,5,6,7,8)==1, ///
	over(educ_mother, relabel(1 "None" 2 "PI" 3 "PC" 4 "SI" 5 "SC" 6 "HI" 7 "HC" 8 "PG")) ///
	ytitle("% who expect will get higher education")	
	
	graph bar higher_ed_2p, over(educ_mother) relabel()
	graph bar higher_ed_2p, over(educ_mother) stack percent legend(label(1 "No") label(2 "Yes"))

	*- Years in 2S
	tab year_2p if fam_total_4==2 & fam_order_4==2
	tab year_4p if fam_total_4==2 & fam_order_4==2
	tab year_2s if fam_total_4==2 & fam_order_4==2

end

********************************************************************************
* % of siblings using survey data
********************************************************************************

capture program drop siblings_enaho
program define siblings_enaho

	use "$DB\research\projectsX\databases\ENAHO\2014\enaho01a-2014-300.dta", clear
	
	keep if inlist(p308a,2,3)==1
	bys conglome vivienda hogar: gen tot_fam: N=_N 
	tab tot_fam [iw=factor07]
	
	use "$DB\research\projectsX\databases\ENAHO\2023\enaho01a-2023-300.dta", clear
	
	keep if inlist(p308a,2,3)==1
	bys conglome vivienda hogar: gen tot_fam: N=_N 
	tab tot_fam [iw=factor07]	
	tabstat tot_fam
	
end



********************************************************************************
* Validating family measures
********************************************************************************

capture program drop validating_family
program define validating_family

	use "$OUT\students", clear
	tabstat family_id
end


******************************************************************************** 
* test
* 
* Description: 
********************************************************************************

capture program drop test
program define test


	*- Histogram of scores and cutoffs
	use "$TEMP/applied_matched.dta", clear
	
	
	*- Exclude those without estimated cutoffs
	keep if lottery_nocutoff == 0

	*- Exclude those at cutoff
	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)	
	
	*- Only valid cutoffs (pass McCrary test)
	**# Apparently there are some missings in mccrary_pval_def that are not being properly accounted for the 'mccrary_test' indicator.
	count if mccrary_pval_def == . & mccrary_test==1
	gen valid_flex_cutoff = ((mccrary_pval_def>0.1 & mccrary_pval_biasi>0.1) & (mccrary_test==1 & mccrary_pval_def!=. & mccrary_pval_biasi!=.))
	gen valid_strict_cutoff = ((mccrary_pval_def>0.1 | mccrary_pval_biasi>0.1) & (mccrary_test==1 & mccrary_pval_def!=. & mccrary_pval_biasi!=.))
	
	*- Only valid cutoffs
	gen consistent_cutoff 		= (cutoff_rank == cutoff_rank_all)
	
	*- Cutoffs that come from only one source?
	//This identifies one with big outliers (few observations with different scale)
	bys id_cutoff: egen score_std_max = max(abs(score_std))
	gen one_source_cutoff = (score_std_max<5) //approx
	
	//This aims to identify bimodal distributions. Not enough observations within 0.5sd of mean (Expected is ~40%)
	bys id_cutoff: egen N = count(score_std)
	bys id_cutoff: egen temp_N_half_sd = count(score_std) if abs(score_std)<0.5
	bys id_cutoff: egen N_half_sd = max(temp_N_half_sd)
	gen one_source_cutoff2 = (N_half_sd/N>0.2)
	/*
	histogram score_std if one<0.01
	histogram score_std if one>0.01 & one<0.025 & abs(score_std)<5
	histogram score_std if one>0.025 & one<0.05 & abs(score_std)<5
	histogram score_std if one>0.05 & one<0.1 & abs(score_std)<5
	histogram score_std if one>0.1 & one<0.2 & abs(score_std)<5
	histogram score_std if one>0.2 & one<0.3 & abs(score_std)<5
	histogram score_std if one>0.3 & one<0.35 & abs(score_std)<5
	histogram score_std if one>0.35 & one<0.4 & abs(score_std)<5
	drop N temp_N_half_sd N_half_sd
	*/
	
	*- Sample to use
	gen sample = (not_at_cutoff==1 & valid_flex_cutoff==1 & consistent_cutoff==1 & one_source_cutoff==1 & one_source_cutoff2==1)	
	
	
	gen pop = 1
	
	preserve
		collapse (mean) sample (sum) pop , by(universidad id_periodo_postulacion year)
		drop year
		reshape wide sample pop, i(universidad) j(id_periodo_postulacion)
		pwcorr sample70 sample71 sample200 sample201 sample230 sample231	
		//generally >0.5. High correlation: Clean cutoff universities are generally clean.
	restore

	
	*Even vs odd years by university
	keep sample pop id_cutoff universidad facultad year
	preserve
		gen even_years = mod(year,2)==0
		keep sample pop universidad even_years
		collapse (mean) sample (sum) pop , by(universidad even_years)
		reshape wide sample pop, i(universidad) j(even_years)
		pwcorr sample0 sample1
		scatter sample0 sample1
		list , sep(10000)
		list if sample0>0.7 & sample, sep(10000)
	restore

	*Even vs odd years by cell
	preserve
		egen g_department 	= group(codigo_modular id_codigo_facultad)
		egen g_major 		= group(codigo_modular id_carrera_primera_opcion)
		gen even_years = mod(year,2)==0
		keep sample pop id_cutoff universidad facultad  even_years
		collapse (mean) sample (sum) pop , by(id_cutoff universidad facultad even_years)
		reshape wide sample pop, i(id_cutoff universidad facultad) j(even_years)
		pwcorr sample0 sample1
		scatter sample0 sample1
		list  , sep(10000)
	restore	
	
end



******************************************************************************** 
* descriptive
* 
* Description: 
********************************************************************************

capture program drop descriptive
program define descriptive

	args cell

	*- Histogram of scores and cutoffs
	use "$TEMP/applied_matched.dta", clear
	
	rename *_`cell' *
	
	*- Relative score
	gen score_relative = score_std - cutoff_std
	gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=.
	
	egen id_persona = group(id_persona_reco)
	//keep if year == 2019
	tabstat enrolled*
	
	xtile socioec_index_g8_sch_pct = socioec_index_g8_sch, nquantiles(4)
	
	
	*- Applications per student
	bys id_persona: gen N_applications = _N
	bys id_persona year: gen N_applications_year = _N
	bys id_persona year public: gen N_applications_year_public = _N
	tab N_applications
	tab N_applications_year
	
	*- Distribution of ECE by type of application
	twoway (kdensity score_math_std_g8 if public==1) (kdensity score_math_std_g8 if public==0)
	
	*- How many years it takes to get admitted
	bys id_persona: egen first_year = min(cond(public==1,year,.))
	bys id_persona: egen last_year = max(cond(public==1,year,.))
	gen years_applying = last_year - first_year
	
	*- Correlation between ECE exams (has to be done form SIAGIE starting point)
	/*
	reg score_math_std_g8 score_math_std_g4
	reg score_com_std_g8 score_com_std_g4
	reg score_math_std_g8 score_math_std_g2
	reg score_com_std_g8 score_com_std_g2
	reg score_math_std_g4 score_math_std_g2
	reg score_com_std_g4 score_com_std_g2
	*/

	*- Correlations between ECE exams
	reg score_std score_com_std_g2 score_math_std_g2 
	reg score_std score_com_std_g4 score_math_std_g4 
	reg score_std score_com_std_g8 score_math_std_g8
	reg score_std score_com_std_g8 score_math_std_g8 score_com_std_g2 score_math_std_g2 
	
	*- Relation between enrolled in preferred and ECE exam
	forvalues y = 2019/2022 {
		binsreg enrolled score_math_std_g8 if year == `y', name(enrolled_ece_m_`y', replace) ytitle("% Enrolled") xtitle("8th grade Math standardized score") subtitle("`y'", color(gs0))
		binsreg enrolled score_com_std_g8 if year == `y', name(enrolled_ece_c_`y', replace) ytitle("% Enrolled") xtitle("8th grade Communications standardized score") title("`y'") subtitle("`y'", color(gs0))
	}
	
	foreach t in "m" "c" {
		graph combine 					///
					enrolled_ece_`t'_2019 	///
					enrolled_ece_`t'_2020 	///
					enrolled_ece_`t'_2021 	///
					enrolled_ece_`t'_2022 	///
					, ///
		xsize(8) col(2) ///
		name(enrolled_ece_`t', replace)
		
		graph export 	"$FIGURES/enrolled_ece_`t'.png", replace	
	}

	*- Relation between enrolled in preferred and ECE exam
	forvalues y = 2019/2022 {
		binsreg enrolled_any score_math_std_g8 if year == `y', name(enrolled_any_ece_m_`y', replace) ytitle("% Enrolled Any") xtitle("8th grade Math standardized score") subtitle("`y'", color(gs0))
		binsreg enrolled_any score_com_std_g8 if year == `y', name(enrolled_any_ece_c_`y', replace) ytitle("% Enrolled Any") xtitle("8th grade Communications standardized score") title("`y'") subtitle("`y'", color(gs0))
	}
	
	foreach t in "m" "c" {
		graph combine 					///
					enrolled_any_ece_`t'_2019 	///
					enrolled_any_ece_`t'_2020 	///
					enrolled_any_ece_`t'_2021 	///
					enrolled_any_ece_`t'_2022 	///
					, ///
		xsize(8) col(2) ///
		name(enrolled_ece_any_`t', replace)
		
		graph export 	"$FIGURES/enrolled_ece_any_`t'.png", replace	
	}
	
	*- Review odd cases
	keep if year==2020
	bys id_persona_reco: gen n_applied=_N
	binsreg enrolled 		score_math_std_g8 if year_ece_g8==2016, nbins(50) ytitle("% Enrolled")	 	xtitle("8th grade Math standardized score") name(ece_m_2016_enrolled, replace)
	binsreg enrolled_any 	score_math_std_g8 if year_ece_g8==2016, nbins(50) ytitle("% Enrolled Any") xtitle("8th grade Math standardized score") name(ece_m_2016_enrolled_any, replace)
	binsreg n_applied 		score_math_std_g8 if year_ece_g8==2016, nbins(50) ytitle("# Applications") xtitle("8th grade Math standardized score") name(ece_m_2016_n_applied, replace)
	
	binsreg enrolled 		score_com_std_g8 if year_ece_g8==2016, nbins(50) ytitle("% Enrolled")	 	xtitle("8th grade Comm standardized score") name(ece_c_2016_enrolled, replace)
	binsreg enrolled_any 	score_com_std_g8 if year_ece_g8==2016, nbins(50) ytitle("% Enrolled Any") xtitle("8th grade Comm standardized score") name(ece_c_2016_enrolled_any, replace)
	binsreg n_applied 		score_com_std_g8 if year_ece_g8==2016, nbins(50) ytitle("# Applications") xtitle("8th grade Comm standardized score") name(ece_c_2016_n_applied, replace)	
	
		graph combine 					///
					ece_m_2016_enrolled 	///
					ece_m_2016_enrolled_any 	///
					ece_m_2016_n_applied 	///
					ece_c_2016_enrolled 	///
					ece_c_2016_enrolled_any 	///
					ece_c_2016_n_applied 	///
					, ///
		xsize(8) col(3) ///
		name(ece_g8_2016_outcomes, replace)
		
		graph export 	"$FIGURES/ece_g8_2016_outcomes.png", replace		
	
	*- Relation between enrolled in any and ECE exam
	
	reg enrolled_any socioec_index_g8_sch score_math_std_g8 score_com_std_g8 if ABOVE==1
	
	binsreg enrolled score_math_std_g8
	binsreg enrolled score_com_std_g8
	
	binsreg score_std score_math_std_g8
	binsreg score_std score_com_std_g8
	
	binsreg score_math_std_g8 score_com_std_g8
end



********************************************************************************
* Run program
********************************************************************************

main