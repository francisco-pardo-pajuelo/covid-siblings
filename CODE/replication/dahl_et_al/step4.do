clear
capture log close

log using "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\output4.log",replace

set more off, permanently		

global file "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"


		use "$file\Sint_iter_AEJ.dta",clear
			sort ProdAr PersonLopNr choice
			merge 1:1 ProdAr PersonLopNr choice using "$file\clean_7791_AEJ.dta", nogen			
			
				sort ProdAr Region Program
				merge m:1 ProdAr Region Program using "$file\cut_AEJ.dta",nogen		// Merges Sint_iter (step2) with clean_7791 (step1) and cut (step3)
				
				*** OBS! FROM HERE - Sint is renamed to "Sint_orig"
				** Sint_iter takes the name "Sint"
				rename Sint Sint_orig
				rename Sint_iter Sint
				
				replace Sint=Sint_orig if Program!=10 & Program!=28 & Program!=43 & Program!=44 & Program!=51 & Program!=59
				
				**Characteristics of cells to be retained 
				drop if PersonLopNr==.
				bysort ProdAr Region Program: egen app_count = count(Sint) 			// # of applicants
				bysort ProdAr Region Program: egen acc_count = sum(Sint) 			// # of accepted
				bysort ProdAr Region Program: gen diff_count = app_count-acc_count 	// # difference between accepted and applicants

				*** Before reducing the file to one row per individual, we want to make a distinction between mixed borders and sharp borders by defining the share accepted at the cutoff, 
				bysort ProdAr Region Program Jmft: egen help=mean(Sint) if cut==Jmft	
				bysort ProdAr Region Program: egen border_shareacc=mean(help) 		// border_shareacc = share accepted at the cutoff (always > 0, if zero share is accpeted, the cutoff is by definition higher)
				drop help																
	
				gen bordercell=1 if border_shareacc>0 & border_shareacc<1 & cut!=. 	// bordercell==1 if the share accepted at the border is below 100%		
				replace bordercell=0 if bordercell==. & cut!=.						// bordercell==0 means we have a sharp cutoff at the border
				gen dist=Jmft-cut													// dist will be our running variable
				replace dist=dist*10					
				replace dist=dist+5 if cut!=. & border_shareacc==1 					// if border_shareacc==1, there is a sharp cutoff & everyone at the border was accepted. We adjust the running variable +5
				gen abvcut=(dist>0 & dist!=.) 
				gen dist2=dist*abvcut										// if above cutoff, the running variable is also generated as a separate variable to allow for different slopes below/above the cutoff
				
		***
				codebook PersonLopNr																	// 1330 453
				bysort ProdAr PersonLopNr (choice): gen maxchoice=_N
				codebook PersonLopNr if choice==maxchoice & maxchoice>=3								// 130,127 not acc to 1st or 2nd list-choice
				keep if maxchoice>=3
				
				replace dist=. if diff_count<3 | app_count<25
				
				gen cutfst=1 if cut!=. & fst==Program & Jmft!=.
				bysort ProdAr PersonLopNr (choice): egen maxcutfst=mean(cutfst)							// mean of value is missing if an individual has a cutoff for choice defined as fst
				keep if maxcutfst==1
				codebook PersonLopNr  																	// 15 052 have cutoff for defined fst choice (if not we are not interested)
				
				
				gen sintkoll=1 if Sint==1
				bysort ProdAr PersonLopNr (choice): egen maxsint=mean(sintkoll)							//   mean of value is missing if an individual is never accepted to a program
				keep if maxsint==1
				codebook PersonLopNr if maxsint==1														//   9 208 of these individuals are accepted to some program (have Sint=1 on one row)
				
				gen error=1 if dist==. & choice!=maxchoice
				bysort ProdAr PersonLopNr (choice): egen error2=mean(error) 							// all choices ranked higher than the last, must have a cutoff 
				keep if error2!=1
				codebook PersonLopNr if error2!=1														// 5 211 ind have cutoff for all choices ranked higher than the last
				
				gen help=dist if choice!=maxchoice
				bysort ProdAr PersonLopNr (choice): egen maxdist=max(help) if help!=.					// all RV are below zero, so we look if one is closer to zero (max value)
				gen only=1 if maxdist==help & maxdist!=.												// if a tie; dummy for lowest priority choice (alternative closer to accepted choice)
				bysort ProdAr PersonLopNr (choice): replace only=. if only==1 & (only[_n+1]==1 | only[_n+2]==1 | only[_n+3]==1 | only[_n+4]==1)		
				replace maxdist=. if only!=1
				bysort ProdAr PersonLopNr (choice): gen help1=Program if maxdist!=. 
				bysort ProdAr PersonLopNr (choice): egen fst_lowestdist=mean(help1)
				drop help*
				keep if (fst!=fst_lowestdist) & (fst==10 | fst==28 | fst==43 | fst==44 | fst==51 | fst==59)
				codebook PersonLopNr  																	//   2 401 have a higher ranked choice than fst, with a RV (dist) closer to cutoff
				
												
				gen help=flag1 if Program==fst_lowestdist
				bysort ProdAr PersonLopNr (choice): egen maxflag=mean(help)								// 		fst_lowestdistoff was a Sint-misreported case
				keep if maxflag!=1
				codebook PersonLopNr  																	//      2 366 have fst_lowestdistoff defined for a correctly reported case
				
				****	201 have dist=0 and mixed cutoff where they were thrown out
				
				gen border_shareacc_lowestdist=border_shareacc if only==1 & dist==0 
				drop help*
				gen help=dist if only==1 
				bysort ProdAr PersonLopNr (choice): egen dist_lowest=mean(help)							// 		dist_lowestdistoff all rows of ind
				gen help1=dist if Program==fst
				bysort ProdAr PersonLopNr (choice): egen dist_fst=mean(help1)							// 		dist_fst all rows of ind
				keep if dist_lowest>=dist_fst & dist_lowest!=. & dist_lowest>-101 						// 		keep only cases where dist_lowest is closer to the distoff, GIVEN the GPA-bonus 
				codebook PersonLopNr  																	//      2 363 have fst_lowestdistoff closer to distoff than original dist of the defined fst
																										// 		OF THESE 	- 1678 have non-ac 2nd choice (first paper)
																										//					- 685 have ac 2nd choice (spillover paper)
				
				******************* kolla fst nonobserved trots att fst_lowestdist finns
				
				*foreach x in Jmft cut app_count diff_count sec Kon {
				*	gen `x'_lowestdist=`x' if Program==fst_lowestdist & dist<=0 
				*}
				
				*keep if Program==fst_lowestdist & dist<=0 
				*rename (Jmft dist cut app_count diff_count sec Kon) (Jmft_lowestdist dist_lowestdist cut_lowestdist app_count_lowestdist diff_count_lowestdist sec_lowestdist Kon_lowestdist)
				keep if choice==1
				keep ProdAr PersonLopNr fst_lowestdist dist_lowest
				sort ProdAr PersonLopNr 
				save "$file\lowestcut_AEJ.dta",replace
				

	*do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\step5.do"

