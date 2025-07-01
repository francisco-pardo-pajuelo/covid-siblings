reghdfe 	admitted 			ABOVE $scores_1 $ABOVE_scores_1   	if abs(score_relative)<1, a(id_cutoff) cluster(id_fam_4)
reghdfe 	applied_sib 		ABOVE $scores_1 $ABOVE_scores_1   	if abs(score_relative)<1 & exp_graduating_year1_sib+1>year_app, a(id_cutoff) cluster(id_fam_4)
reghdfe 	applied_uni_sib 	ABOVE $scores_1 $ABOVE_scores_1   	if abs(score_relative)<1 & exp_graduating_year1_sib+1>year_app, a(id_cutoff) cluster(id_fam_4)
reghdfe 	enroll_sib 	ABOVE $scores_1 $ABOVE_scores_1   	if abs(score_relative)<1 & exp_graduating_year1_sib+1>year_app, a(id_cutoff) cluster(id_fam_4)



ivreghdfe	applied_sib 		(admitted=ABOVE) $scores_1 $ABOVE_scores_1   	if abs(score_relative)<1, a(id_cutoff) cluster(id_fam_4)
ivreghdfe	applied_uni_sib 		\(admitted=ABOVE) $scores_1 $ABOVE_scores_1   if abs(score_relative)<1, a(id_cutoff) cluster(id_fam_4)
ivreghdfe	enroll_sib 		(admitted=ABOVE) $scores_1 $ABOVE_scores_1   		if abs(score_relative)<1, a(id_cutoff) cluster(id_fam_4)



preserve
	gen pop = 1
	collapse (sum) pop, by(universidad)
	sort pop
	list , sep(10000)
restore

*** Why downward slope after 0?
preserve
	tab year_app
	//keep if universidad == "UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS"
	//keep if universidad == "UNIVERSIDAD NACIONAL DE TRUJILLO"
	keep if universidad == "UNIVERSIDAD NACIONAL DE SAN ANTONIO ABAD DEL CUSCO"
	keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
	keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies	
	keep if abs(score_relative)<1 
	reghdfe 	applied_sib 		ABOVE $scores_1 $ABOVE_scores_1   	, a(id_cutoff) cluster(id_fam_4)
	binsreg enroll_foc score_relative, nbins(100)
restore
