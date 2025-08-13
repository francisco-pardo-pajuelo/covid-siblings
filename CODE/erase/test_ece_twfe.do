

	
	
	
	
	
	
	
	
	

//gen pair_4 = ((year==2019 | year==2020) & grade==6)

foreach g_pair in "g2_6" "g4_6" "g4_7" "g8_9" /*"g8_u"*/  "g2_8" {

if "`g_pair'" == "g2_6" {
	local g_ece = "2p"
	local ece_db = "ece_`g_ece'"
	local ece_db_survey = "ece_family_`g_ece'"
	
	local year_ece_pre 		=  2015
	local year_ece_post 	=  2016
	local year_siagie_pre 	=  2019
	local year_siagie_post 	=  2020
	local grade_ece			=  2	
	local grade_siagie		=  6
}

if "`g_pair'" == "g4_6" {
	local g_ece = "4p"
	local ece_db = "ece_`g_ece'"
	local ece_db_survey = "ece_family_`g_ece'"
	
	local year_ece_pre 		=  2016
	local year_ece_post 	=  2018
	local year_siagie_pre 	=  2018
	local year_siagie_post 	=  2020
	local grade_ece			=  4	
	local grade_siagie		=  6
}

if "`g_pair'" == "g4_7" {
	local g_ece = "4p"
	local ece_db = "ece_`g_ece'"
	local ece_db_survey = "ece_family_`g_ece'"
	
	local year_ece_pre 		=  2016
	local year_ece_post 	=  2018
	local year_siagie_pre 	=  2019
	local year_siagie_post 	=  2021
	local grade_ece			=  4	
	local grade_siagie		=  7
}

if "`g_pair'" == "g8_9" {
	local g_ece = "2s"
	local ece_db = "ece_`g_ece'"
	local ece_db_survey = "ece_student_`g_ece'"
	
	local year_ece_pre 		=  2018
	local year_ece_post 	=  2019
	local year_siagie_pre 	=  2019
	local year_siagie_post 	=  2020
	local grade_ece			=  8	
	local grade_siagie		=  9
}


preserve
	keep if year == 2019 | year==2020
	keep if fam_total_${fam_type}<=4
	
	reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index, a(id_ie g_pair)
	

restore

	foreach size in "2_4" "2" "3" "4" {
	preserve
		di as result "*********************" _n as text "Size: `size'" _n as result "*********************"
		if "`size'" == "2-4" 	keep if fam_total_${fam_type}<=4
		if "`size'" == "2" 		keep if inlist(fam_total_${fam_type},1,2)==1
		if "`size'" == "3" 		keep if inlist(fam_total_${fam_type},1,3)==1
		if "`size'" == "4" 		keep if inlist(fam_total_${fam_type},1,4)==1	
		foreach subj in "m" "c" {
		
			eststo gpa_`subj'_all_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index, a(id_ie g_pair)
			eststo gpa_`subj'_1_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com if g_pair==1, a(id_ie g_pair)
			eststo gpa_`subj'_2_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com if g_pair==2, a(id_ie g_pair)
			eststo gpa_`subj'_3_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com if g_pair==3, a(id_ie g_pair)
			eststo gpa_`subj'_4_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com if g_pair==4, a(id_ie g_pair)
			
			//Effect by SES
			eststo gpa_`subj'_ses1_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if base_socioec_index_cat==1, a(id_ie g_pair)
			eststo gpa_`subj'_ses2_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if base_socioec_index_cat==2, a(id_ie g_pair)
			eststo gpa_`subj'_ses3_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if base_socioec_index_cat==3, a(id_ie g_pair)
			eststo gpa_`subj'_ses4_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if base_socioec_index_cat==4, a(id_ie g_pair)
			
			//Effect by Resources
			eststo gpa_`subj'_pc_int0_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if internet==0 & pc==0, a(id_ie g_pair)
			eststo gpa_`subj'_pc_int1_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if internet==1 & pc==1, a(id_ie g_pair)

			
			//Effect by Aspirations
			eststo gpa_`subj'_asp_low_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if inlist(aspiration_fam,1)==1, a(id_ie g_pair)
			eststo gpa_`subj'_asp_med_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if inlist(aspiration_fam,2)==1, a(id_ie g_pair)
			eststo gpa_`subj'_asp_hig_`size'	: reghdfe std_gpa_`subj'_adj treated_post treated post base_score_math base_score_com base_socioec_index if inlist(aspiration_fam,4,5)==1, a(id_ie g_pair)
		}
	restore
	}