
clear
capture log close

log using "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\output3.log",replace

set more off, permanently		

global file "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"


			
			**** DETERMINING THE CUTOFF
			**This is based on the reclassified Sint variable - Sint_iter 
			
			use "$file\Sint_iter_AEJ.dta",clear
			keep if Program==10 | Program==28 | Program==43 | Program==44 | Program==51 | Program==59 		// only academic programs
			
			drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///	excluding very high and very low Jmft
						(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		
			
			bysort ProdAr Region Program Jmft: egen help=mean(Sint_iter)			
			gen mixedJmftcell=(help<.9 & help>.1) 								// indicator of a Jmft-cell with a mix of Sint=1 and Sint=0
			drop help
			
			** a Jmftcell is mixed only in cases where Sint_iter could not replace original Sint values, Sint_iter alwyas take same value 0 or 1 in a Jmftcell
			
			**We allow max one mixed Jmftcell in a Program/Year-cell
			**To sum the number of mixed Jmftcells in a Program/Year-cell, a tag ensures every Jmftcell is only counted once
			
			drop if Sint_iter==. // individual rows are now not important - but obs with Sint_iter missing are dropped as it otherwise risks altering the syntax and cutoff below
			egen tag=tag(ProdAr Region Program Jmft)
			
			** There cannot be two cells that are mixed if there is a Jmft cutoff. 
			** Sum the number of mixed Jmft cells-- if this sum is > 1, the entire cell is dropped. 
			bysort ProdAr Region Program: egen Ncells_mixed=sum(mixedJmftcell) if tag==1
			drop if Ncells_mixed>1
			
			
			**WE HAVE THE FOLLOWING VARIABLES
			*
			*********************************
			**Sint_iter = re-classfied Sint-variable which for each Jmft-cell takes value one or zero 
			**mixedJmftcell = 1  (if >=.10 and <=.90) otherwise zero
			**NJmftcells_mixed = sums the number of mixed Jmftcells, now only takes value 0 or 1 since we just dropped entire cells if 2 or higher
			 
			
			collapse (mean) Ncells_mixed mixedJmftcell Sint_iter ,by(ProdAr Region Program Jmft)
			gen cut=.
			gen help=Jmft if mixedJmftcell==1
			bysort ProdAr Region Program: egen pot_border=mean(help) // if there is a mixed cell, pot_border gives the Jmft value for that cell
			drop help
			
			*keep if ((ProdAr==1985 & Region==1 & Program==10) | (ProdAr==1988 & Region==15 & Program==10) | (ProdAr==1988 & Region==32 & Program==59) | (ProdAr==1991 & Region==107 & Program==51))
			
			egen grp=group(ProdAr Region Program)
			levelsof grp, local(groups)		
			
			
			sort ProdAr Region Program Jmft
			bysort ProdAr Region Program: gen seq = sum(Sint_iter)  // In a given cell, seq==1 for the first person accepted when calculating from the lowest Jmft
								
				foreach y of local groups {	 
								dis `y'
						
						sum Ncells_mixed if grp==`y',meanonly
						local ncellsmixed = r(min)
						dis "Ncellmixed"
						dis `ncellsmixed'
						if `ncellsmixed'==1 {		// if there is a mixed cell, only this upper part of the loop is run
							sum Sint_iter if grp==`y' & Jmft<pot_border,meanonly
							local meantotheleft = r(mean)
							sum Sint_iter if grp==`y' & Jmft>pot_border,meanonly
							local meantotheright = r(mean)
							replace cut=pot_border if grp==`y' & `meantotheleft'==0 & `meantotheright'==1
						}
						
						
						if `ncellsmixed'==0 {		// if no mixed cell, only this lower part of the loop is run
							qui sum Jmft if grp==`y' & seq==1,meanonly
							local jmft = r(min)
							qui sum Sint_iter if grp==`y' & Jmft<`jmft',meanonly
							local meanleft=r(mean)
							qui sum Sint_iter if grp==`y' & Jmft>`jmft',meanonly
							local meanright=r(mean)
							replace cut=`jmft' if grp==`y' & (`meanleft'==0 & `meanright'==1)
						}
					}			
					
				
			sort ProdAr Region Program
			
			collapse (mean) cut Ncells_mixed mixedJmftcell,by(ProdAr Region Program)
					
			save "$file\cut_AEJ.dta", replace

	*do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\step4.do"

