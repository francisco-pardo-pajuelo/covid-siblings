/********************************************************************************
- Author: Francisco Pardo
- Description: Create Final matched database
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/

capture program drop main 
program define main 

setup

*- Student-year Database
student_year_final

*- Test construction
test_student_year

	
end


********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup

	global fam_type = 2
	global test = 0
	set seed 1234
	
	if ${test} == 0 global data = ""
	if ${test} == 1 global data = "_TEST"

end
 
********************************************************************************
* Final database: Student-year level
********************************************************************************

*- We keep most relevant data
capture program drop student_year_final 
program define student_year_final 


	clear
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		append using "$TEMP\siagie_`y'", keep(id_ie id_per_umc level grade year male_siagie region_siagie public_siagie urban_siagie carac_siagie approved approved_first lives_with_mother lives_with_father)
	}
	
	
	*- Match Family info
	merge m:1 id_per_umc using "$TEMP\id_siblings", keep(master match) keepusing(educ_caretaker educ_mother educ_father id_fam_* fam_order_* fam_total_*) 
	rename _m merge_siblings
	
	*- Keep sample for test run
	if ${test}==1 {
		bys id_fam_${fam_type}: egen sample =max(cond(_n==1,runiform()<0.05,.))
		keep if sample==1
		drop sample
		}
		
	
	*- Remove all pre-elementary observations
	drop if level==1
	
	*- Fill in gaps. Start with those who were in 1st grade 2014
	
	
	
	compress
	
	save "$TEMP\student_year", replace
	
	
end



********************************************************************************
* Final database: Student-year level
********************************************************************************

*- We keep most relevant data
capture program drop test_student_year 
program define test_student_year 

	use "$TEMP\student_year", clear
	
	bys id_per_um: egen mark = max(cond(year==2014 & grade==3,1,0))
	
	keep if mark==1
	drop mark
	
	egen id_student = group(id_per_umc)
	tsset id_student year
	tsfill, full
	
	gen school=(id_per_umc!="")
	
	bys id_student (school): replace id_per_umc = id_per_umc[_N]
	
	*- First event of parent moving out
	gen school=1
	bys id_student (year): egen no_father_first_year 	= min(cond(lives_with_father==0,year,.))
	bys id_student (year): egen no_mother_first_year 	= min(cond(lives_with_mother==0,year,.))
	bys id_student (year): egen school_first_year 		= min(cond(school==1,year,.))
	
	
end




********************************************************************************
* Run program
********************************************************************************

main