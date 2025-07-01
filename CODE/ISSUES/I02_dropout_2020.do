*- Why do dropout rates increase so drastically for 2020-2022 for V sec (11 grade)


clear
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		append using "$TEMP\siagie_`y'", keep(id_ie id_per_umc grade year male_siagie region_siagie public_siagie urban_siagie carac_siagie approved approved_first)
	}


table year grade if grade>=7, stat(mean approved)
table year grade if grade>=7, stat(mean approved_first)

*- Conclussion (1): This seems to be by a different measure (delayed) in 2020 and 2021. In 2022 it was mostly fixed by adding the 'sf_regular_promocion_guiada=="PROMOVIDO"' cases. But there are none in 2020 and fewer in 2021. We considered the 'delays' as also 'approved'

*- Example:
use "$TEMP\siagie_raw_2020_TEST", clear
keep if grado_siagie== "QUINTO"
keep if nivel_educativo_siagie=="Secundaria"

tab sf_regular, m
tab sf_regular_promocion_guiada, m //No further info here like in other years... (2021 partially)
tab sf_postergacion, m

*- Is this correct? let's see if they are still enrolled in the following year

use "$OUT\students", clear

//bys id_per_umc: egen year_graduate_CHECK = 	min(cond(grade==11 & approved==1,year,.))
//bys id_per_umc: egen 		last_year 			= max(year) 

//tab year_graduate_CHECK last_year

tab dropout_grade dropout_year, col nofreq
//Dropout measure still would need to be fixed since it is too focused on 11th grade.
