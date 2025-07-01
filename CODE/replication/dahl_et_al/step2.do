
clear
capture log close

log using "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\output2.log",replace

set more off, permanently		

global file "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"



****
*	The clean_7791-file contains all valid applications 


foreach progr in 43 10 28 44 51 59 {			// the program numbers represent our academic programs of interest
												// 43 = Engineerng/Science (combined) 	10 = Busniess 28 = Humanities
												// 44 Natural science 	51 Social science 	59 = Engineering
forvalues year = 1977/1991 {

if (`progr'==43 & `year'>=1979 & `year'<=1981) | (`progr'!=43) {  // *OBS - FOR PROGR 43 only three years exist - 1979 1980 1981


use "$file\clean_7791_AEJ.dta", clear

*The key variable here is "Sint" which is 1 if accepted and 0 if not accepted. 
*For each value of the adjusted GPA (=Jmft), we are supposed to only observe accepted or not accepted individuals, unless we are exactly at a cutoff point.

*We will in this program generate an iteration to signal where Sint values are incoherent. A new variable "Sint_iter" is generated.
*The loop will first look for Jmft-cells where the Sint values are all 1. We then go from top Jmft to bottom. This variable is called Sint_iter1
*The second part of the loop looks for Jmft-cells where the Sint values are all 0. We then go from bottom Jmft to top. This variable is called Sint_iter2.

*The logic is that we only replace a Sint=1 with Sint=0 if individuals with higher Jmft are overwhelmingly zeros (Sint=0 for lower Jmft may occur naturally)
*Conversly, we only replace a Sint=0 with a one if individuals with lower Jmft are overwhelmingly ones (Sint=1 for higher Jmft may occur naturally)

*The new variable Sint_iter1 is expected to take a value one or be missing. The new variable Sint_iter2 is expected to take value zero or be missing. 
*For a given row, one of these should be missing. The new variable Sint_iter is then the non-missing value of these two variables. 
*A flag is issued if both Sint_iter1==1 and Sint_iter2==0. For that row, we will set Sint_iter==. 

*If Jmft-cell is a mix of Sint=1 and Sint=0 we set Sint_iter=. 
*Missing values will be complemented with original Sint values unless we issue a flag.
		
		dis `progr'
		dis `year'
			keep if Program==`progr' & ProdAr==`year'
		*** Impossible to get a Jmft above 52 in normal years. Impossible to get Jmft above 57 if you come directly from compulsory school bc of bonus points 82-84
		drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
						(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))			
		
			bysort ProdAr Region Program Jmft: egen number= count(Sint) 
			egen grp=group(ProdAr Region Program) 
			
			sort ProdAr Region Program Jmft
			
			levelsof grp, local(groups)		
			
			gen wind_size=.
			gen Sint_iter1=.
			gen Sint_iter2=.
			gen flag1=.
			gen flag2=.
			
			foreach y of local groups {	 // 1
								dis `y'
						qui sum Jmft if grp==`y',meanonly 
						local hi = r(max)
						local lo = r(min)
						local totwindow = `hi' - `lo'
						
						forvalues j=`hi'(-1)`lo' {
							qui sum Sint if grp==`y' & Jmft==`j',meanonly 
							local condition = r(mean)
							qui replace Sint_iter1=1 if grp==`y' & Jmft==`j' & r(mean)>=.9 & r(mean)!=. 
							qui replace wind_size=0 if grp==`y' & Jmft==`j' & r(mean)>=.9 & r(mean)!=.
								if `condition'<.9 {
									local done = `hi'-`j' // ex 52-43 = 9 // to calculate how many Jmft values remain I have to know how many values are done
									local remaining = `totwindow'-`done' // Max 32 (52-20) Example for Jmft=43: 32 - (52-43) --> 32-9=24
									forvalues window = 1/`remaining' {
											qui sum Sint if grp==`y' & Jmft>=(`j'-`window') & Jmft<=`j',meanonly 
											qui replace Sint_iter1=1 if grp==`y' & Jmft==`j' & r(mean)>=.9 & r(mean)!=. 
											qui replace wind_size=`window' if grp==`y' & Jmft==`j' & r(mean)>=.9 & r(mean)!=.
											 
										}
								}
						}	
						
						
						forvalues j=`lo'/`hi' {
							qui sum Sint if grp==`y' & Jmft==`j',meanonly 
							local condition = r(mean)
							qui replace Sint_iter2=0 if grp==`y' & Jmft==`j' & r(mean)<=.1 & r(mean)!=. 
							qui replace wind_size=0 if grp==`y' & Jmft==`j' & r(mean)<=.1 & r(mean)!=.
								
								if `condition'>.1 {
									local done = `j'-`lo' // ex 31-21 = 10 // to calculate how many Jmft values remain I have to know how many values are done
									local remaining = `hi'-`j' // Max 32 (52-20) Example for Jmft=31: 52 - 31 = 21
										local window = 1 
										while `condition'>.1 & `window'<=`remaining'{
										*dis "inside window loop"
										*dis `j' 
										qui sum Sint if grp==`y' & Jmft>=`j' & Jmft<=`j'+`window',meanonly 
											qui replace Sint_iter2=0 if grp==`y' & Jmft==`j' & r(mean)<=.1 & r(mean)!=. 
											qui replace wind_size=`window' if grp==`y' & Jmft==`j' & r(mean)<=.1 & r(mean)!=. 
											local condition = r(mean)
											local window = `window'+1
										}
								}
						}	
			}
						
			qui replace flag1=1 if Sint_iter1==1 & Sint==0	//flag1 says Sint_iter1 deviates from Sint (coded in upper part of loop)
			qui replace flag2=1 if Sint_iter2==0 & Sint==1	//flag2 says Sint_iter2 deviates from Sint (coded in lower part of loop)
			
			qui gen Sint_iter=Sint_iter1 if flag1!=1 											// Sint_iter is equal to Sint_iter1 if no flag was issued (Sint_iter1=Sint in the UPPER part of the loop)
			qui replace Sint_iter=Sint_iter2 if flag2!=1 & Sint_iter==. 						// Sint_iter is equal to Sint_iter2 if Sint_iter is missing and ther is no flag (Sint_iter2=Sint in LOWER part of the loop)
			qui replace Sint_iter=. if Sint_iter1!=Sint_iter2 & Sint_iter1!=. & Sint_iter2!=. 	//If both Sint_iter1 and Sint_iter2 are non-missing, they cannot both be right, so we set Sint_iter==.
			
			qui replace Sint_iter=Sint if flag1!=1 & flag2!=1  									// Sint_iter is replaced by Sint if we have not defined it (which happens if between 10 and 90 percent are Sint==1)
			sort ProdAr Region Program Jmft
			merge m:m ProdAr Region Program Jmft using "$file\clean_7791_AEJ.dta", nogen			
			
			keep ProdAr Region Program Jmft PersonLopNr choice wind_size flag* Sint_iter* Sint
			
			save "$file\Sint_iter_`progr'_`year'.dta", replace
}
}
}



*			*** BELOW - each of the files are appended back into a big file (the program generates one file for each year and program. It makes it almost 100 times faster to run)
*
*
*
***************************************************


			foreach progr in 43 10 28 44 51 59 {
				forvalues year = 1977/1991 {
					if (`progr'==43 & `year'>=1979 & `year'<=1981) | (`progr'!=43) {  // *OBS - FOR PROGR 43 only three years exist - 1979 1980 1981

					use "$file\Sint_iter_`progr'_`year'.dta",clear
						dis `progr'
						dis `year'
						
						keep ProdAr PersonLopNr choice Sint_iter* flag* Program Region Jmft Sint
						sort ProdAr PersonLopNr choice
						keep if Program==`progr' & ProdAr==`year'
						
						if `year'==1979 & `progr'==43 {
							save "$file\Sint_iter_AEJ.dta", replace
						}
						else {
							append using "$file\Sint_iter_AEJ.dta"
							save "$file\Sint_iter_AEJ.dta", replace
						}	
					}	
				}		
			}
			


*do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\step3.do"
	