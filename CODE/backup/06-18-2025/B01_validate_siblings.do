*- Validating Siblings data:



capture program drop main 
program define main 

setup_B01

number_of_siblings_census_household

number_of_siblings_survey

household_info_matches

educ_respondent


end


capture program drop setup_B01 
program define setup_B01 

clear

global fam_type = 5
end



*- We compare the # of siblings distribution from Household Surveys, Census and our data.
*-- CAVEAT: We only see siblings that are IN school
capture program drop number_of_siblings_census_household 
program define number_of_siblings_census_household 

*- ENAHO
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

*- We compare the # of siblings based on actual responses from ECE/EM surveys
capture program drop number_of_siblings_survey 
program define number_of_siblings_survey 

	use "$TEMP\ece_student_2s", clear

		tab total_siblings_2s year
		keep if year==2015

		rename id_estudiante_2s id_estudiante
		merge 1:1 id_estudiante using "$TEMP\match_siagie_ece_2s", keep(master match)
		keep if _m==3
		drop _m

		merge 1:1 id_per_umc using "$TEMP\id_siblings", keep(master match) keepusing(id_fam_${fam_type} fam_total_${fam_type})

		replace total_siblings_2s = 0 if total_siblings_2s ==99
		gen children = total_siblings_2s + 1
		tab children fam_total_${fam_type}

		replace fam_total_${fam_type} = . if fam_total_${fam_type}>10
		replace children = . if children>10

		tab children fam_total_${fam_type}
		pwcorr children fam_total_${fam_type}
		binsreg children fam_total_${fam_type}
		
		//Why decrease when too high?

	use "$TEMP\ece_family_2p", clear

		tab total_siblings_2p year
		keep if year==2015

		rename id_estudiante_2p id_estudiante
		merge 1:1 id_estudiante using "$TEMP\match_siagie_ece_2p", keep(master match)
		keep if _m==3
		drop _m

		merge 1:1 id_per_umc using "$TEMP\id_siblings", keep(master match) keepusing(id_fam_${fam_type} fam_total_${fam_type})

		replace total_siblings_2p = 0 if total_siblings_2p ==99
		gen children = total_siblings_2p + 1
		tab children fam_total_${fam_type}

		replace fam_total_${fam_type} = . if fam_total_${fam_type}>10
		replace children = . if children>10

		tab children fam_total_${fam_type}
		pwcorr children fam_total_${fam_type}
		binsreg children fam_total_${fam_type}
		
		//Why decrease when too high?

//Not perfect but decent relationship. Variable doesn't seem spurious.

	
end

*- We compare if siblings from same grade in same year match in the household characteristics and demographics of respondent. (e.g. same age of mother.)
capture program drop household_info_matches 
program define household_info_matches 

	use "$TEMP\ece_family_4p", clear

	rename id_estudiante_4p id_estudiante
	merge 1:1 id_estudiante using "$TEMP\match_siagie_ece_4p", keep(master match)
	keep if _m==3
	drop _m

	merge 1:1 id_per_umc using "$TEMP\id_siblings", keep(master match) keepusing(id_fam_${fam_type} fam_total_${fam_type} educ_mother educ_father id_mother id_father id_caretaker)
 
	*- Identify siblings in same year and school
	egen same_age_sibling 		= group(id_fam_${fam_type} year)	
	bys same_age_sibling: gen N=_N
	bys same_age_sibling (id_ie): gen same_school=id_ie[1]==id_ie[_N] if N>1
	
	keep if N>1
	
	*- Same characteristics
	bys same_age_sibling (edu_mother_4p): gen same_edu_mother = edu_mother_4p[1]==edu_mother_4p[_N]
	bys same_age_sibling (edu_father_4p): gen same_edu_father = edu_father_4p[1]==edu_father_4p[_N]
	bys same_age_sibling (age_cat_mother_4p): gen same_age_mother = age_cat_mother_4p[1]==age_cat_mother_4p[_N]
	bys same_age_sibling (age_cat_father_4p): gen same_age_father = age_cat_father_4p[1]==age_cat_father_4p[_N]
	bys same_age_sibling (rela_4p): gen same_rela = rela_4p[1]==rela_4p[_N]
	bys same_age_sibling (id_father): gen same_id_father = id_father[1]==id_father[_N]
	
	
	
	tab same_edu_mother
	tab same_edu_mother if same_school==1
	tab same_edu_father if same_school==1
	tab same_age_mother if same_school==1
	tab same_age_father if same_school==1
	
	sort same_age_sibling same_school id_per_umc 
	br same_age_sibling same_school id_per_umc rela_4p age_cat_mother_4p id_mother id_father id_caretaker if same_school==1 & same_rela==0
	
end


*- We compare survey responses of education level VS siagie data.
capture program drop educ_respondent 
program define educ_respondent

	use "$TEMP\ece_family_4p", clear

	rename id_estudiante_4p id_estudiante
	merge 1:1 id_estudiante using "$TEMP\match_siagie_ece_4p", keep(master match)
	keep if _m==3
	drop _m

	merge 1:1 id_per_umc using "$TEMP\id_siblings", keep(master match) keepusing(educ_mother educ_father)
	
	/*
	labels for edu_mother_4p and edu_father_4p. 
	1 Sin Estudios
	2 Primaria incompleta
	3 Primaria completa 
	4 Secundaria incompleta 
	5 Secundaria completa 
	6 Educación ocupacional incompleta
	7 Educación ocupacional completa 
	8 Superior no universitaria incompleta: pedagógica, técnica, artística o militar/policial (escuela de sub oficiales)
	9 Superior no universitaria completa: pedagógica, técnica, artística o militar/policial (escuela de sub oficiales)
	10 Superior universitaria incompleta o militar/policial (escuela de oficiales)
	11 Superior universitaria completa o militar/policial (escuela de oficiales)
	12 Posgrado (maestría y/o doctorado)
	*/
		
	*- Recode to match SIAGIE var
	tab educ_mother
	recode edu_mother_4p edu_father_4p (1=1) (2=2) (3=3) (4=4) (5=5) (6 8 10 =6) (7 9 11 = 7) (12 = 8)
	label define educ 1 "None" 2 "Primary Incomplete" 3 "Primary Complete" 4 "Secondary Incomplete" 5 "Secondary Complete" 6 "Higher Incomplete" 7 "Higher Complete" 8 "Post-grad", replace
	label values edu_mother_4p edu_father_4p educ
	

	tab educ_mother edu_mother_4p
	tab educ_father edu_father_4p
	
	//A lot of noise but modes of distribution match


end 


**************************************************


main