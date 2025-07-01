
********************************************************************************
* preliminary_results
********************************************************************************

capture program drop preliminary_results
program define preliminary_results

	use "$OUT/applied_outcomes.dta", clear

	prepare_rd noz major

	binsreg admitted score_relative

	//Brief descriptives
	preserve
		keep if exp_graduating_year1_sib>=2016 & exp_graduating_year1_sib<=2022
		sum applied_sib applied_uni_sib applied_public_sib 
		sum applied_sib applied_uni_sib applied_public_sib if sec_inc_mother==1
		sum applied_sib applied_uni_sib applied_public_sib if sec_inc_mother==1 & sec_inc_father==1
		sum applied_sib applied_uni_sib applied_public_sib if pgrad_2s_sib==0 & sec_inc_mother==1 & sec_inc_father==1
		sum applied_sib applied_uni_sib applied_public_sib if socioec_index_cat_fam_foc==1
		sum applied_sib applied_uni_sib applied_public_sib if socioec_index_cat_fam_foc==4
	restore

			
	foreach sample in "" "_mother_sec_incomplete" "_low_ses" /*"_no_asp_pgrad"*/ /*"_first_sem_application"*/ /*"_only_one_application"*/ {
		
	//foreach outcome in "admitted" "enroll_sib" "applied_uni_major_sib" "applied_uni_sib" {

		foreach outcome in 		/*BALANCE*/				/*"male_foc"*/ "age" /*"higher_ed_mother" "socioec_index_cat_2s_foc"*/ "score_math_std_2s_foc" /*"score_com_std_2s_foc"*/ ///
								/*FOCAL CHILD*/ ///
									/*FIRST STAGE*/ 	"admitted" ///
									/*OUTCOMES*/		"enroll_uni_major_sem_foc" "enroll_sem_foc" "enroll_public_sem_foc" "enroll_private_sem_foc" "enroll_foc" "N_applications_semester_foc" "N_applications_foc" ///
								/*SIBLING*/ ///
								/*UNIVERSITY*/ 			"applied_sib" "applied_uni_major_sib" "applied_uni_sib" "applied_major_sib" "applied_public_sib" "applied_private_sib" /*"N_applications_semester_sib"*/ "N_applications_sib" "enroll_sib" /*"enroll_uni_major_sib"*/ "enroll_uni_sib" /*"enroll_major_sib"*/ ///
								/*SCORE SCHOOL*/ 		/*"score_math_std_2p_sib" "score_math_std_4p_sib"*/ "score_math_std_2s_sib" ///
								/*ASPIRATIONS*/ 		/*"higher_ed_2p_sib" "higher_ed_4p_sib"*/ "higher_ed_2s_sib" /*"aspiration_2s_sib"*/ /*"pgrad_2s_sib"*/ "aspiration_years_2s_sib" ///
								/*SCORE UNI*/			/*"score_std_uni_enr_sib"*/ ///
								{
									
			
			display as text ///
			"*************************************************" _n  ///
			"******** Showing details of current loop ********" _n ///
			"*************************************************" _n ///
			as input ///
			"Sample: `sample'" _n ///
			as result ///
			"Outcome: `outcome'"
		
			display as text ///
			"***************************************" _n  ///
			"******** ERASING PREVIOUS FILE ********" _n ///
			"***************************************" _n
			
			capture erase "$FIGURES/png/binsreg_`outcome'`sample'.png"
			capture erase "$FIGURES/png/binsreg_`outcome'`sample'.pdf"
			capture erase "$FIGURES/png/binsreg_`outcome'`sample'.eps"
			capture erase "$FIGURES\figure_`outcome'`sample'.tex"
			
			capture erase "$TABLES\inputs/table_`outcome'`sample'_1.tex"
			capture erase "$TABLES\inputs/table_`outcome'`sample'_2.tex"
			capture erase "$TABLES\inputs/table_`outcome'`sample'_3.tex"
			capture erase "$TABLES\inputs/table_`outcome'`sample'_2_3.tex"
			capture erase "$TABLES\inputs/table_`outcome'`sample'_mean.tex"
			capture erase "$TABLES\inputs/table_`outcome'`sample'_obs.tex"
			capture erase "$TABLES\inputs/table_`outcome'`sample'_mean_obs.tex"
			capture erase "$TABLES\table_`outcome'`sample'.tex"

			capture estimates clear	
			
			
			loca id_fam "id_fam_4"

			preserve

				local outcome_est = "`outcome'"
				
				*- Sample selection
				if "`sample'" == ""								keep if 1==1
				if "`sample'" == "_mother_sec_incomplete"		keep if sec_inc_mother==1
				if "`sample'" == "_low_ses"						keep if inlist(socioec_index_cat_fam_foc,1,2)==1
				if "`sample'" == "_no_asp_pgrad"				keep if pgrad_2s_sib==0
				if "`sample'" == "_first_sem_application"		keep if sample_first_semester_app==1
				if "`sample'" == "_only_one_application"		keep if sample_first_app==1
				
				//Balance
				if "`outcome'" == "male_foc" {
					local outcome_label "Focal child is male"
				}
				
				if "`outcome'" == "age" {
					local outcome_label "Focal child age"
				}
				
				if "`outcome'" == "higher_ed_mother" {
					local outcome_label "Focal child's mother has higher education"
				}
				
				if "`outcome'" == "socioec_index_cat_2s_foc" {
					local outcome_label "Focal child SES index"
					local outcome_est = "ses_2s_foc"
				}	
				
				if "`outcome'" == "score_math_std_2s_foc" {
					local outcome_label "Focal child mathematics score in 8th grade"
					local outcome_est = "math_2s_foc"
				}
				
				if "`outcome'" == "score_com_std_2s_foc" {
					local outcome_label "Focal child communication score in 8th grade"
					local outcome_est = "com_2s_foc"
				}
				
				// first stage
				if "`outcome'" == "admitted" {
					local outcome_label "Focal child admitted to cutoff"
				}
				
				//outcomes
				if "`outcome'" == "enroll_uni_major_sem_foc" {
					local outcome_label "Focal child enrolled in applied cutoff"
					local outcome_est = "enroll_u_m_s_f"
				}
				
				if "`outcome'" == "enroll_sem_foc" {
					local outcome_label "Focal child enrolled in ANY university during semester"
				}
				
				if "`outcome'" == "enroll_public_sem_foc" {
					local outcome_label "Focal child enrolled in PUBLIC university during semester"
					local outcome_est = "enroll_pu_s_f"
				}
				
				if "`outcome'" == "enroll_private_sem_foc" {
					local outcome_label "Focal child enrolled in PRIVATE university during semester"
					local outcome_est = "enroll_pr_s_f"
				}
				
				if "`outcome'" == "enroll_foc" {
					local outcome_label "Focal child enrolled in ANY university EVER"
				}
				
				if "`outcome'" == "N_applications_semester_foc" {
					local outcome_label "Focal child total applications during semester"
					local outcome_est = "N_app_sem_foc"
				}
						
				if "`outcome'" == "N_applications_foc" {
					local outcome_label "Focal child total applications EVER"
				}

				//applications sibling
				if "`outcome'" == "applied_sib" {
					keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
					keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies
					local outcome_label "Younger Sibling Applied to University"
				}
				
				if "`outcome'" == "applied_uni_major_sib" {
					keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
					keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies
					local outcome_label "Younger Sibling Applied to same Major-University"
				}
				
				if "`outcome'" == "applied_uni_sib" {
					keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
					keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies
					local outcome_label "Younger Sibling Applied to same University"
				}	

				if "`outcome'" == "applied_major_sib" {
					keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
					keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies
					local outcome_label "Younger Sibling Applied to same major"
				}
				
				if "`outcome'" == "applied_public_sib" {
					keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
					keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies
					local outcome_label "Younger Sibling Applied to PUBLIC University"
				}		

				if "`outcome'" == "applied_private_sib" {
					keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
					keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies
					local outcome_label "Younger Sibling Applied to PRIVATE University"
				}
				
				if "`outcome'" == "N_applications_semester_sib" {
					keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
					keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies
					local outcome_label "Younger sibling total applications during semester"
					local outcome_est = "N_app_sem_sib"
				}
						
				if "`outcome'" == "N_applications_sib" {
					keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
					keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies
					local outcome_label "Younger sibling total applications EVER"
				}
						
				if "`outcome'" == "enroll_sib" {
					keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
					keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies
					local outcome_label "Younger Sibling Enrolled"
				}
						
				if "`outcome'" == "enroll_uni_major_sib" {
					keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
					keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies
					local outcome_label "Younger Sibling Enrolled in same university-major"
				}
						
				if "`outcome'" == "enroll_uni_sib" {
					keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
					keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies
					local outcome_label "Younger Sibling Enrolled in same university"
				}
						
				if "`outcome'" == "enroll_major_sib" {
					keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
					keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies
					local outcome_label "Younger Sibling Enrolled in same major"
				}
				
				//score school sibling
				if "`outcome'" == "score_math_std_2p_sib" {
					keep if year_2p_sib>=year_app
					local outcome_label "Younger Sibling 2nd grade score"
					local outcome_est = "math_2p_sib"
				}
				
				if "`outcome'" == "score_math_std_4p_sib" {
					keep if year_4p_sib>=year_app
					local outcome_label "Younger Sibling 4th grade score"
					local outcome_est = "math_4p_sib"
				}	

				if "`outcome'" == "score_math_std_2s_sib" {
					keep if year_2s_sib>=year_app
					local outcome_label "Younger Sibling 8th grade score"
					local outcome_est = "math_2s_sib"
				}
				
				
				//aspirations sibling
				if "`outcome'" == "higher_ed_2p_sib" {
					keep if year_2p_sib>=year_app
					local outcome_label "Parents aspirations for higher education of sibling (2nd grade)"
				}
				
				if "`outcome'" == "higher_ed_4p_sib" {
					keep if year_4p_sib>=year_app
					local outcome_label "Parents aspirations for higher education of sibling (4th grade)"
				}	

				if "`outcome'" == "higher_ed_2s_sib" {
					keep if year_2s_sib>=year_app
					local outcome_label "Siblings aspirations for higher education (8th grade)"
				}
				
				if "`outcome'" == "aspiration_2s_sib" {
					keep if year_2s_sib>=year_app
					local outcome_label "Siblings aspirations for education (index - 8th grade)"
				}
				
				if "`outcome'" == "pgrad_2s_sib" {
					keep if year_2s_sib>=year_app
					local outcome_label "Siblings aspirations for highere graduate education (8th grade)"
				}		
				
				if "`outcome'" == "aspiration_years_2s_sib" {
					keep if year_2s_sib>=year_app
					local outcome_label "Siblings aspirations for highere graduate education (8th grade)"
					local outcome_est = "asp_y_2s_sib"
				}		
						
				
				
				//score university sibling
				if "`outcome'" == "score_std_uni_enr_sib" {
					keep if exp_graduating_year1_sib+1>=2017 & exp_graduating_year1_sib+1<=2023 //years with data
					keep if exp_graduating_year1_sib+2>=year_app								//After older sibling applies
					local outcome_label "Younger Sibling standardized university grade"
					local outcome_est = "score_uni_enr_sib"
				}	
				
				*- If not enough observations exit loop
				sum `outcome'
				if r(N)<100 {
					restore
					continue
				}
				
				if fileexists("$TABLES\table_`outcome'`sample'.tex") & fileexists("$FIGURES\figure_`outcome'`sample'.tex") & ${redo_all}==0 {
					restore
					continue
				}			
				
				*- Keep necessary sample
				capture drop regsamp
				qui reghdfe `outcome' ABOVE 	$controls , a(id_cutoff) vce(robust)
				gen regsamp=1 if e(sample)
				keep if regsamp==1
					
					
				* Binned scatterplot
				//& socioec_index_cat_2s_foc==1
				binsreg `outcome' score_relative if /// 
							1==1 ///
							, ///
							xline(0) ///
							xtitle("Score relative to cutoff") ///
							ytitle("`outcome_label'") ///
							absorb(id_cutoff) nbins(100)	
				//graph export 	"$FIGURES/png/binsreg_`outcome'`sample'.png", replace			
				//graph export 	"$FIGURES/pdf/binsreg_`outcome'`sample'.pdf", replace			
				graph export 	"$FIGURES/eps/binsreg_`outcome'`sample'.eps", replace			

					
				*- RD Regressions
				foreach bw in 200 100 50 25 {
					set more off
					local bwi =`bw'/100
					
					reghdfe `outcome' ABOVE $scores_1 $ABOVE_scores_1  	$controls  	if abs(score_relative)<`bwi', a(id_cutoff) cluster(`id_fam')
						estimates store `outcome_est'_1_`bw'

					reghdfe `outcome' ABOVE $scores_2 $ABOVE_scores_2 	$controls 	if abs(score_relative)<`bwi', a(id_cutoff) cluster(`id_fam')
						estimates store `outcome_est'_2_`bw'

					reghdfe `outcome' ABOVE $scores_3 $ABOVE_scores_3 	$controls   if abs(score_relative)<`bwi', a(id_cutoff) cluster(`id_fam')
						estimates store `outcome_est'_3_`bw'
				}

				*- Producing Latex Tables				
				*- Write Latex final table & figure
				file open  table_tex	using "$TABLES\table_`outcome'`sample'.tex", replace write
				file write table_tex	/// HEADER OPTIONS OF TABLE
								"\begin{table}[!htbp]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
								"\caption{`outcome_label'}\label{tab:table_`outcome'}" _n ///
								"\scalebox{1}{\setlength{\textwidth}{.1cm}" _n ///
								"\newcommand{\contents}{" _n ///
								"\begin{tabular}{lcccc}" _n ///
								/// HEADER OF TABLE
								"\toprule" _n ///
								"& \multicolumn{4}{c}{Bandwidth}   \\" _n ///
								"\cline{2-5}" _n ///
								"& 2 & 1 & 0.5 & 0.25  \\" _n ///
								"& (1) & (2) & (3) & (4)  \\" _n ///
								"\bottomrule" _n 
				file close table_tex
				
				//"\begin{table}[htbp!] \centering" _n ///
				//"\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
				
				estout ///
					`outcome_est'_1_200 `outcome_est'_1_100 `outcome_est'_1_50 `outcome_est'_1_25   ///
					using "$TABLES/table_`outcome'`sample'.tex", ///
						append style(tex) collabels(, none) label cells(b(star fmt(%9.3f)) se(par))  ///
						keep(ABOVE) varlabels(ABOVE "Linear") mlabels(, none) $slvl
					
				estout ///
					`outcome_est'_2_200 `outcome_est'_2_100 `outcome_est'_2_50 `outcome_est'_2_25   ///
					using "$TABLES/table_`outcome'`sample'.tex", ///
						append style(tex) collabels(, none) label cells(b(star fmt(%9.3f)) se(par))  ///
						keep(ABOVE) varlabels(ABOVE "Quadratic") mlabels(, none) $slvl
					
				estout ///
					`outcome_est'_3_200 `outcome_est'_3_100 `outcome_est'_3_50 `outcome_est'_3_25   ///
					using "$TABLES/table_`outcome'`sample'.tex", ///
						append style(tex) collabels(, none) label cells(b(star fmt(%9.3f)) se(par))  ///
						keep(ABOVE) varlabels(ABOVE "Cubic") mlabels(, none) $slvl

				estout ///
					`outcome_est'_3_200 `outcome_est'_3_100 `outcome_est'_3_50 `outcome_est'_3_25   ///
					using "$TABLES/table_`outcome'`sample'.tex", ///
						append style(tex) collabels(, none) label cells(b(fmt(%9.3f)))  ///
						keep(_cons) varlabels(_cons "Control Mean")  mlabels(, none) $slvl			
						
				estout ///
					`outcome_est'_3_200 `outcome_est'_3_100 `outcome_est'_3_50 `outcome_est'_3_25   ///
					using "$TABLES/table_`outcome'`sample'.tex", ///
						append style(tex) collabels(, none) label cells(none)  ///
						 mlabels(, none) ///
						stats(N, fmt(%9.0g ) labels("Observations"))				
				
				
								/// CONTENT OF TABLE
								///"\input{./TABLES/inputs/table_`outcome'`sample'_1.tex}" _n ///
								///"\input{./TABLES/inputs/table_`outcome'`sample'_2_3.tex}" _n ///
								///"\input{./TABLES/inputs/table_`outcome'`sample'_3.tex}" _n ///
								///"& & & & \\" _n ///
								///"\input{./TABLES/inputs/table_`outcome'`sample'_mean_obs.tex}" _n ///
								///"\input{./TABLES/inputs/table_`outcome'`sample'_obs.tex}" _n ///
								///"\\" _n ///
								/// TABLE NOTES AND CLOSER
								
								
				file open  table_tex	using "$TABLES\table_`outcome'`sample'.tex", append write
				file write table_tex	/// HEADER OPTIONS OF TABLE							
								_n "\bottomrule \multicolumn{5}{p{\textwidth}} {\footnotesize \textit{Notes:} ***p$<$0.01, **p$<$0.05, *p$<$0.1. }\end{tabular}}\setbox0=\hbox{\contents}" _n ///
								"\setlength{\textwidth}{\wd0-2\tabcolsep-.25em} \contents} \end{table}"
				file close table_tex

				file open  figure_tex	using "$FIGURES\figure_`outcome'`sample'.tex", replace write
				file write figure_tex	/// HEADER OPTIONS OF TABLE
						"\begin{figure}[h]" _n ///
						"\centering" _n ///
						"\caption{`outcome_label'}\label{fig:binsreg_`outcome'`sample'}" _n ///
						"\includegraphics[width=1\textwidth]{./FIGURES/eps/binsreg_`outcome'`sample'.eps}" _n ///
						"{\footnotesize \textit{Notes}: }"   _n ///
						"\end{figure}"
				file close figure_tex
					
			restore	

		}	
	}	

end

