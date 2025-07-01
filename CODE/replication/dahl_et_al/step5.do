clear
capture log close

log using "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\output5.log",replace

set more off, permanently		

global file "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"


*** The first rows below merge the files from step1, step2 & step3 to generate the raw sample, sometimes at the basis to to describe data in the paper 

*** The raw sample is slightly larger than the masterfile "step5_AEJ.dta"
*** The masterfile is reduced by dropping indivduals with 

*** 1) erroneous Sint code (flagged in syntax step2)
*** 2) 1st choice program missing 
*** 3) duplicate applications (in different regions) 
*** 4) duplicate applications (with different Sint values) 

*** The raw data is 1,330,543 ind, the master file 1,292,785 ind


*The master file generated in the step5-program goes on to merge data from a number of administrative registers held by Statistics Sweden.
*The data sources merged include:
***			- "Avgångsregister gymnasiet" (row 168-197) which report yearly from 1973 the completion of high school majors
***			- Multiple generation register (info on parents, rows 868-1010)
***			- population data of GPA (rows 1013-1025), only available from 1988 (born 1972) and only used of one digit reported in the paper
***			- Foreign background (row 867-890)
***			- from "LISA" of Statistics Sweden is collected various variables, files with YEARLY data have been compiled containing specific variables, 
***					these are merged and re-modeled to AGE-specific data (e.g. age 38 occurs in different years for diff birth-cohorts).  
***					The variables merged include occupation ("ssyk", row 200-304), income (row 305-565) with and without ("ForvInk") parental and sick-leave ("SjukRe+ForPeng"), 
***			- 		level of education ("631-786") completed (sun), field of study completed (inr)
 



			use "$file\Sint_iter_AEJ.dta",clear													// step2 data 
			sort ProdAr PersonLopNr choice
			merge 1:1 ProdAr PersonLopNr choice using "$file\clean_7791_AEJ.dta", nogen			// merged with step1 data 
			
				sort ProdAr Region Program
				merge m:1 ProdAr Region Program using "$file\cut_AEJ.dta",nogen					// and step3 data 
				
				*** OBS! FROM HERE - Sint is renamed to "Sint_orig"
				** Sint_iter takes the name "Sint"
				rename Sint Sint_orig
				rename Sint_iter Sint
				
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
				gen dist=Jmft-cut													// dist will be our running variable for RD estimations
				replace dist=dist*10					
				replace dist=dist+5 if cut!=. & border_shareacc==1 			// if border_shareacc==1, there is a sharp cutoff & everyone at the border was accepted. We adjust the running variable +5
				gen abvcut=(dist>0 & dist!=.) 
				gen dist2=dist*abvcut										// if above cutoff, the running variable is also generated as a separate variable to allow for different slopes below/above the cutoff
				
				sort ProdAr PersonLopNr 
				
				merge m:1 ProdAr PersonLopNr using "$file\lowestcut_AEJ.dta",nogen 		// merge step4 data, to adjust running variable for small fraction of ind
				replace fst=fst_lowestdist if fst_lowestdist!=.
				replace dist=dist_lowest if dist_lowest!=.  
				
				
				
************************
*
*	HERE START PROCESS TO REDUCE FILE - DROPPING INDIVIDUALS (SEE POINTS 1-4 ABOVE) AND COLLAPSING FILE TO ONE ROW PER INDIVIDUAL
*
************************
	**484,896 extra obs
	
	*** first we generate a flag at individual/year level to indicate if Sint was recoded 
	
	gen help=1 if flag1==1 | flag2==1 						
	gen help1=1 if Program==fst & (flag1==1 | flag2==1) 	
	bysort ProdAr PersonLopNr: egen flagsome=mean(help) 			// ind has flag for one of the valid choices 
	bysort ProdAr PersonLopNr: egen flagfst=mean(help1) 			// ind has flag for the choice we consider the preferred choice
	drop if flag1==1 | flag2==1 							// drop rows where Sint was not equal to Sint_iter in step2.do-file
	drop help*

	***480,239 extra obs remaining
	
		**Sequence to delete obs with two rows
	*********************************************************
	gen help=1 if fst==Program
	bysort PersonLopNr: egen help1=mean(help)
	drop if help==. // no Program==fst - redundant obs (2nd 3rd choice etc)
	drop help*
	*** 45,117 doubles remain [including non-academic]  

	bysort PersonLopNr: egen maxyear=max(ProdAr)
	bysort PersonLopNr: egen minyear=min(ProdAr)
	bysort PersonLopNr: gen diff=maxyear-minyear
	tab diff,m

	bysort PersonLopNr: egen sum16=count(PersonLopNr) if age==16 
	bysort PersonLopNr: egen maxsum16=max(sum16) //used as indicator if there is application aged 16

		**Now, drop if 3 conditions hold
		**1)ind HAS an application aged 16 (maxsum16!=.), 
		**2)appears multiples years (diff!=0) 
		**3)and application is NOT at age 16 (sum16==.)
		drop if maxsum16!=. & diff!=0 & sum16==.

		**40,180 extra obs remain [including non-academic]
		*** drop also if ind has NO application aged 16 (maxsum16==.)
		*** choose to keep earlier application
		**1)ind has NOT an application aged 16 (maxsum16==.), 
		**2)appears multiples years (diff!=0) 
		**3) application is not = fstyear
		bysort PersonLopNr: egen fstyear=min(ProdAr)
		drop if maxsum16==. & diff!=0 & fstyear!=ProdAr 


	**40027 extra obs remaining [including 24 individuals with academic fst choice], all wihtin an application year, but sometimes in different regions (we will eventuelly have to drop those)
	**doubles in same region means there are two rows in the same cell for one ind
	*** The majority of them were nursing electronics etc where we expect double applications to exist 
	bysort ProdAr Region PersonLopNr: gen doubles=_N
	**Condition that Sint == Sint[_n-1] 
	bysort ProdAr Region Program PersonLopNr (choice): gen help=1 if Sint[_n-1]==Sint & doubles!=1
		drop if help==1 //[no-one with academic as first choice since these were dropped in step1-do-file]
		drop help doubles
		
	*** 2498 extra obs remain [including 24 individuals with academic 1st choice] // the same criteria is re-run but now choices have different Sint-values
	// These are dropped since it is not possible to have them fulfill RD conditions, applying in region 1 and maybe accepted to same program in region 2
	bysort ProdAr Program PersonLopNr: gen double_prg=_N
	bysort ProdAr PersonLopNr Region: egen double_reg=count(Region) if double_prg>1
	drop if double_prg!=1 & double_reg==1

	drop maxyear-double_reg

save "$file\step5_AEJ.dta",replace			// THIS WILL BE THE MASTER FILE-NAME
	
	
************************
*
*	FILE NOW CONSISTS OF ONE ROW PER INDIVIDUAL - 1,292,785 observations
*
************************
	
	
******************************
*
*	INDIVIDUALS' COMPLETED PROGRAM 
*		- add information on program completed 
	
	
		use "$file\completion.dta",clear // this file contains data compiled from "Avgångsregister gymnasiet" which was reported yearly 1973 until 2017
				merge 1:1 PersonLopNr using "$file\step5_AEJ.dta",nogen				
				keep if ProdAr!=.
			gen completion=completion1	// up to five completed programs are reported
			
			gen lint=(Lint==fst)
			gen fin=1 if (completion1==fst) 
			
		forvalues x=1/5 { 				// 300 ind had a second completed program, no obs with 3 or more
			replace fin=1 if fin==. & completion`x'==fst
			replace completion=completion`x' if ((completion==. & completion`x'!=.) | (completion!=. & completion`x'!=. & completion`x'==fst))
		}
		
		replace fin=0 if fin==.
	
		drop completion1 completion2 completion3 completion4 completion5 Ar* utbildningst*
		rename completion completed
		save "$file\step5_AEJ.dta",replace

	
	**Merge occupation(ssyk)
	**The file is first reduced to fewer variables to speed up the procedure 
	
				use "$file\step5_AEJ.dta",clear
				
				keep PersonLopNr ProdAr	Fodar Kon completed fst sec Sint 
				bysort PersonLopNr: gen nobs=_n
				keep if nobs==1
				save "$file\xtra_temp.dta",replace
				
		
				
				
				
			******************************
			*
			*	INDIVIDUALS' PROFESSIONS
			*
			*
				
		
				use "$file\ssyk.dta",clear	// occupation (ssyk) from "LISA" of Statistics Sweden, 
											// ssyk is reported yearly from 1998 but for comparability across time we will eventually not use years after 2013 as the classification changed
											
				bysort PersonLopNr: gen nobs=_n
				keep if nobs==1
				
				merge 1:1 PersonLopNr using "$file\xtra_temp.dta",nogen
						keep if ProdAr!=.
			
			forvalues x=2001/2018 {
				destring ssyk`x' ssyk3digit_`x',replace force
				rename ssyk3digit_`x' ssyk3digit`x'
			}	
			
			forvalues x=30/46 {		
			gen ssyk`x'=.
			gen ssyk3digit`x'=.
			}

			forvalues y = 1959/1977 {			// we generate occupation for each age 30-46 
				dis `y'
					forvalues x=30/46 {
						local z =`x'+`y'
						capture replace ssyk`x'=ssyk`z' if Fodar==`y' 
						capture replace ssyk3digit`x'=ssyk3digit`z' if Fodar==`y' 
					}
			}

					
			
			foreach num in 38 {
				local m1 = `num'-1
				local m2 = `num'-2 
				local m3 = `num'-3 
				local m4 = `num'-4 
				local m5 = `num'-5 
				local m6 = `num'-6 
				local m7 = `num'-7 
				local m8 = `num'-8 
				local p1 = `num'+1
				local p2 = `num'+2 
				local p3 = `num'+3 
				local p4 = `num'+4 
				local p5 = `num'+5 
				local p6 = `num'+6 
				local p7 = `num'+7 
				local p8 = `num'+8 
					foreach x in `num' `m1' `p1' `m2' `p2' `m3' `p3' `m4' `p4' `m5' `p5' `m6' `p6' `m7' `p7' `m8' `p8' {	// to minimize missing observations, we use the occupation code that is closest to age 38
						dis `x'																				// about 29 percent have a missing obs at age 38 (375,797)
						replace ssyk`num'=ssyk`x' if ssyk`num'==. & ssyk`x'!=. 								// furthest away, at age 46 and age 30, the share of missing replaced is 0.33% (4,204) and 0.04% (579)
						replace ssyk3digit`num'=ssyk3digit`x' if ssyk3digit`num'==. & ssyk3digit`x'!=.
					}
			}

			
					foreach num in 38 {
						replace ssyk`num'=99999 if ssyk`num'==.
						replace ssyk3digit`num'=99999 if ssyk3digit`num'==.
					}
					
		
						keep PersonLopNr ssyk38 ssyk3digit38 ProdAr Fodar Kon completed fst sec Sint 
						gen tC=(completed==59)									// generate signals that individuals completed certain program types
						gen nC=(completed==44)
						gen eC=(completed==10)
						gen sC=(completed==51)
						gen hC=(completed==28)
						gen stemC=(completed==59 | completed==44 | completed==43)
						gen bshC=(completed==10 | completed==28 | completed==51)
						gen nonac1C=((completed==9) | (completed==54) | (completed==58) | (completed>=1 & completed<=7) | (completed>=11 & completed<=27) | (completed>=30 & completed<=33) | ///
									(completed>=35 & completed<=42) | (completed>=46 & completed<=50) | (completed>=53 & completed<=56) | (completed>=60 & completed<=68) | (completed>=74 & completed<=76))
						gen nonacvC=(nonac1C==1 & completed!=9 & completed!=54 & completed!=58)
						gen nonacgC=((completed==9) | (completed==54) | (completed==58))
						gen fem=(Kon==2) 										// gender (female)
						
						
			foreach x in t n e s h stem bsh nonac1 nonacg nonacv { 						// calculates the "leave-out-mean" (LOM) of specific program completers by profession...
					bysort ssyk38: egen N_share38`x'=count(`x'C) 						// ...by taking the share without calculating the individual's own row
					replace N_share38`x'=N_share38`x'-1
					bysort ssyk38: egen share38`x'_tot=total(`x'C) 
					gen share38`x'LOM=(share38`x'_tot-`x'C)/N_share38`x' 				// LOM 4 digit level occupation
					
					bysort ssyk3digit38: egen N_share3digit`x'=count(`x'C) 
					replace N_share3digit`x'=N_share3digit`x'-1
					bysort ssyk3digit38: egen share3digit`x'_tot=total(`x'C) 
					gen share3digit`x'LOM=(share3digit`x'_tot-`x'C)/N_share3digit`x' 	// LOM 3 digit level occupation	
			}
		
		gen profshare=.															// profshare reflects the share in the profession with the same completed program as the individual
		replace profshare=share38tLOM if fst==59 & profshare==.
		replace profshare=share38nLOM if fst==44 & profshare==.
		replace profshare=share38eLOM if fst==10 & profshare==.
		replace profshare=share38sLOM if fst==51 & profshare==.
		replace profshare=share38hLOM if fst==28 & profshare==.
		
		
		save "$file\xtra_temp.dta", replace		
		
		
				
			******************************
			*
			*	INDIVIDUALS' ABSOLUTE EARNINGS, LOG EARNINGS AND RANK EARNINGS 
			*
			*
		
			use "$file\earn1990_2016.dta",clear	// various earnings measures from "LISA" of Statistics Sweden, 
												// the variables are cpi adjusted (2016 values) 
												// 1	inc`year'=ForvInk
												// 2	incPS`year'=inc`year'+SjukRe+ForPeng 

					drop incX* lon*				// dropped - NOT used - are lon`year'=LoneInk  and incX`year'=inc`x'+ArbLos+SjukRe+ForPeng 
					sort PersonLopNr 

					forvalues x=1990/2018 { 	// find the 35th percentile earnings threshold for each year, based on the population aged 18-64
							dis `x'				// this is done for both measures of earnings (Antelius and Björklund gives the name to the variable "antpct")
							
							_pctile inc`x' if Fodar>=(`x'-64) & Fodar<=(`x'-18),p(35)
							local p=r(r1)
							qui gen antpct`x'=(inc`x'>=(`p'))
							qui replace antpct`x'=. if inc`x'==.
							
							_pctile incPS`x' if Fodar>=(`x'-64) & Fodar<=(`x'-18),p(35)
							local p=r(r1)
							dis `p'
							qui gen antpctPS`x'=(incPS`x'>=(`p'))
							qui replace antpctPS`x'=. if incPS`x'==.
						}
					
					** Generate yearly cpi-based limits corresponding to SEK 100,000 in 1991 - (i.e. not taking overall wage growth into account)
					
					gen cpilimit1990=100*(207.80/227.18) 
					gen cpilimit1991=100*(227.18/227.18) 
					gen cpilimit1992=100*(232.40/227.18) 
					gen cpilimit1993=100*(243.20/227.18) 
					gen cpilimit1994=100*(248.50/227.18) 
					gen cpilimit1995=100*(254.80/227.18) 
					gen cpilimit1996=100*(256.30/227.18) 
					gen cpilimit1997=100*(257.99/227.18) 
					gen cpilimit1998=100*(257.30/227.18) 
					gen cpilimit1999=100*(258.49/227.18) 
					gen cpilimit2000=100*(260.81/227.18) 
					gen cpilimit2001=100*(267.09/227.18) 
					gen cpilimit2002=100*(272.85/227.18) 
					gen cpilimit2003=100*(278.11/227.18) 
					gen cpilimit2004=100*(279.14/227.18) 
					gen cpilimit2005=100*(280.41/227.18) 
					gen cpilimit2006=100*(284.22/227.18) 
					gen cpilimit2007=100*(290.51/227.18) 
					gen cpilimit2008=100*(300.61/227.18) 
					gen cpilimit2009=100*(299.01/227.18) 
					gen cpilimit2010=100*(302.47/227.18) 
					gen cpilimit2011=100*(311.43/227.18) 
					gen cpilimit2012=100*(314.20/227.18) 
					gen cpilimit2013=100*(314.06/227.18) 
					gen cpilimit2014=100*(313.49/227.18) 
					gen cpilimit2015=100*(313.35/227.18) 
					gen cpilimit2016=100*(316.43/227.18) 
					gen cpilimit2017=100*(322.11/227.18) 
					gen cpilimit2018=100*(328.40/227.18) 
					
					keep if Fodar>=1959 & Fodar<=1977 // file is reduced to make the process below quicker (generating earnings for different ages) 
					
					merge 1:1 PersonLopNr using "$file\xtra_temp.dta",nogen
					keep if ProdAr!=.
					
				keep PersonLopNr Kon ProdAr	Fodar inc* cpilimit* completed ssyk* share* *C ant* fst sec Sint  
			save "$file\xtra_temp.dta",replace
					
				
					
use "$file\xtra_temp.dta", clear
sort PersonLopNr ProdAr 
drop if ProdAr==.

forvalues x=17/55 { // age specific limit values (dummies, based on birthyear and the yearly limit values just collected above)
gen antpctPS`x'=.
gen antpct`x'=.
}

forvalues y = 1959/1977 {
	dis `y'
		forvalues x=17/55 {
			local z =`x'+`y'
			capture replace antpctPS`x'=antpctPS`z' if Fodar==`y' & `z' <=2018 
			capture replace antpct`x'=antpct`z' if Fodar==`y' & `z' <=2018 
			}
}

keep PersonLopNr ProdAr antpctPS17-antpct55
bysort PersonLopNr: gen nobs=_n
		keep if nobs==1 
		drop nobs
save "$file\limit_age_AEJ.dta", replace


*/

use "$file\xtra_temp.dta", clear
sort PersonLopNr ProdAr 

forvalues x=17/55 { 	// age specific earnings, based on birthyear and the yearly earnings just collected above
gen earn`x'=.
gen earnPS`x'=.
gen cpilimit`x'=.		
}
forvalues y = 1959/1977 {
	dis `y'
		forvalues x=17/55 {
			local z =`x'+`y'
			capture replace earn`x'=inc`z' if Fodar==`y' & `z' <=2018 
			capture replace cpilimit`x'=cpilimit`z' if Fodar==`y' & `z' <=2018 
			capture replace earnPS`x'=incPS`z' if Fodar==`y' & `z' <=2018 
		}
}
keep PersonLopNr Fodar ProdAr Kon earn* cpilimit*
	bysort PersonLopNr: gen nobs=_n
		keep if nobs==1 
		drop nobs
	
	preserve
	keep PersonLopNr Fodar ProdAr Kon earn17-cpilimit55  // the age specific earnings are mostly not used so put in a specific file "w_age_AEJ.dta"
	save "$file\w_age_AEJ.dta",replace
	restore 
	
	preserve
	use "$file\limit_age_AEJ.dta",clear
	keep PersonLopNr antpctPS35 antpctPS36 antpctPS37 antpctPS38 antpctPS39 antpctPS40 antpctPS41 antpctPS42 antpctPS43 antpct37 antpct38 antpct39 antpct40 antpct41 antpct42 antpct43 ///
						antpctPS27 antpctPS28 antpctPS29 antpctPS30 antpctPS31 antpctPS32 antpctPS33 antpctPS34 ///
						antpctPS26 antpctPS25 antpctPS24 antpctPS23 antpctPS22 antpctPS21 antpctPS20 antpctPS19 // merge on the limit-values to the "w_age_AEJ.dta" file
		
			merge 1:1 PersonLopNr using "$file\w_age_AEJ.dta", nogen
	save "$file\w_age_AEJ.dta",replace
	
	restore 
	
	merge 1:1 PersonLopNr using "$file\w_age_AEJ.dta", nogen
	keep if ProdAr!=.
	keep PersonLopNr Fodar ProdAr Kon earnPS37 earnPS38 earnPS39 earnPS35 earnPS36 earnPS40 earnPS41 earnPS42 earnPS43 earn37 earn38 earn39 earn40 earn41 earn42 earn43 /// 
	antpctPS35 antpctPS36 antpctPS37 antpctPS38 antpctPS39 antpctPS40 antpctPS41 antpctPS42 antpctPS43 antpct37 antpct38 antpct39 antpct40 antpct41 antpct42 antpct43 cpilimit37 cpilimit38 cpilimit39 ///
	antpctPS27 antpctPS28 antpctPS29 antpctPS30 antpctPS31 antpctPS32 antpctPS33 antpctPS34 ///
	earnPS27 earnPS28 earnPS29 earnPS30 earnPS31 earnPS32 earnPS33 earnPS34 ///
	antpctPS26 antpctPS25 antpctPS24 antpctPS23 antpctPS22 antpctPS21 antpctPS20 antpctPS19 ///
	earnPS26 earnPS25 earnPS24 earnPS23 earnPS22 earnPS21 earnPS20 earnPS19 
	
	
	
	
	reshape long earn earnPS antpctPS antpct cpilimit , i(PersonLopNr) j(age) 					// data is reshaped to long in order to facilitate taking averages of e.g. age 37-39
	
		bysort PersonLopNr: egen help=mean(earnPS) if antpctPS==1 & age>=35 & age<=41			// earnPS also includes 35-41 for this robusness variable
		bysort PersonLopNr: egen antpctPS3541=mean(help) 
		replace antpctPS3541=10000 if antpctPS3541>10000 & antpctPS3541!=.
		gen logantearn3541=ln(antpctPS3541)  
		drop help
		
		forvalues y=19/41 {
			dis `y'
			local z = `y' +2
			bysort PersonLopNr: egen help=mean(earnPS) if antpctPS==1 & age>=`y' & age<=`z'		// earnPS also includes 35-41 for this robusness variable
			bysort PersonLopNr: egen antpctPS`y'`z'=mean(help) 
			replace antpctPS`y'`z'=10000 if antpctPS`y'`z'>10000 & antpctPS`y'`z'!=.
			gen logantearn`y'`z'=ln(antpctPS`y'`z')  
			drop help
		}
		
		
		keep if age>=19 & age<=43
		
		bysort PersonLopNr: egen help=mean(earnPS) if earnPS>=cpilimit & age>=37 & age<=39		// Earnings inflation adjusted, average age 37-39 IF earnings above limit value
		replace help=10000 if help>10000 & help!=. 												// We include outliers in mean calculations but top code mean to SEK 10 million 
		bysort PersonLopNr: egen help1=mean(help) if age>=37 & age<=39							
		gen cpiearn3739=help1 if age==38															
		gen logcpiearn3739=ln(cpiearn3739) if age==38
		drop help*
		
		forvalues y=20/42 {
			dis `y'
			local h = `y' +1
			local l = `y' -1
				bysort PersonLopNr: egen help=mean(earnPS) if age>=`l' & age<=`h' 		// Earnings in levels, mean when aged 37-39 used to generate rank
				bysort PersonLopNr: egen meanPS`l'`h'=mean(help)
				replace meanPS`l'`h'=10000 if meanPS`l'`h'>10000 & meanPS`l'`h'!=.			
			drop help
		}
		
		
		foreach var in antpct antpctPS { 					// We now generate earnings measures applying a conditioned floor limit value (if earnings are below, they are set to missing)
			if "`var'" == "antpct" {													// The floor applied here is taken fron Antelius and Björklund 2000
					bysort PersonLopNr: egen help=mean(earn) if `var'==1
					bysort PersonLopNr: egen `var'3739=mean(help) 
					replace `var'3739=10000 if `var'3739>10000 & `var'3739!=.
					gen log`var'=ln(`var'3739)  
					drop help
			}
		}		
		
	
		rename antpctPS emp35pct							// the floor limit is renamed to indicate Labor force participation (as it is used in Table A6)
		
		keep if age==38	// to retain only one row per individual
		gen logantpctPS=logantearn3739
				
		keep PersonLopNr log* emp35pct meanPS*
		sort PersonLopNr 
				merge 1:1 PersonLopNr using "$file\w_age_AEJ.dta",nogen
		
		gen log3739PS=ln(meanPS3739)
		save "$file\w_age_AEJ.dta",replace


		**** Generate earnings rank from population data
		
drop _all
odbc load, table("fodelsear") connectionstring("DRIVER={SQL Server};SERVER={mq02\b};DATABASE={P0484_SU_SOFI_Utbildningsinnehall};Trusted_Connection={Yes}")
destring kon ,replace
rename (personnr_lopnr kon) (PersonLopNr Kon)
keep PersonLopNr Kon 
save "$file\xtra1.dta",replace				// this collects gender and birthyear information to complement possible missing values


use "$file\earn1990_2016.dta",clear	// earnings measures from "LISA" of Statistics Sweden, the variables are cpi adjusted (2016 values) 
									// incPS`year'=inc`year'+SjukRe+ForPeng 
	gen smp=1
	sort PersonLopNr
	merge m:1 PersonLopNr using "$file\xtra1.dta",nogen
	keep if smp==1
	
	keep incPS* PersonLopNr Fodar Kon
	keep if Fodar>=1955 & Fodar<=1977
	
	forvalues y=20/38 {
		dis `y'
			local h = `y' +1
			local l = `y' -1
	preserve 
	reshape long incPS , i(PersonLopNr) j(year) 			// data is reshaped to long in order to facilitate taking averages of age 37-39
	gen Age=year-Fodar
	keep if Age>=`l' & Age<=`h'
	rename incPS earnPS
	bysort PersonLopNr: egen meanPS`l'`h'=mean(earnPS)
	bysort Fodar Kon: egen rankallPS_`l'`h'=rank(meanPS`l'`h') if Kon==1	// The earnigs rank is based on population data, age and gender specific values of all 37-39 year olds 
	sum rankallPS_`l'`h'
	replace rankallPS_`l'`h'=rankallPS_`l'`h'/r(max)
	bysort Fodar Kon: egen rankallPS_`l'`h'2=rank(meanPS`l'`h') if Kon==2	// A different name is given to the rank for females	
	sum rankallPS_`l'`h'2
	replace rankallPS_`l'`h'=rankallPS_`l'`h'2/r(max) if rankallPS_`l'`h'==.
	keep if Age==`y'														// to retain only one row per individual
	
	keep PersonLopNr rankallPS_`l'`h'
	sort PersonLopNr
		merge 1:1 PersonLopNr using "$file\w_age_AEJ.dta",nogen
	keep if ProdAr!=.
	save "$file\w_age_AEJ.dta",replace
	restore
}

	
		
		use "$file\w_age_AEJ.dta",clear
			order _all,seq
		save "$file\w_age_AEJ.dta",replace
	
	**** With earnings measures created - we can now generate typical earnings for educations (accepted or completed) and occupations
	
		use "$file\w_age_AEJ.dta",clear
		keep PersonLopNr log* rank* emp35pct meanPS* 
		merge 1:1 PersonLopNr using "$file\xtra_temp.dta",nogen
		keep if ProdAr!=.
		
		gen fem=(Kon==2) 
		
		gen expected_prog=fst if Sint==1																	// "expected program" is the program where the individual is accepted
		replace expected_prog=sec if Sint==0
		
		
				bysort completed: egen N_earn_completed38=count(logantpctPS)					// # ind completing the program the individual completed
				replace N_earn_completed38=N_earn_completed38-1									// withdraw 1 (to get a leave out mean "LOM")
				bysort completed: egen tot_earn_completed38=total(logantpctPS)					// total earnings of those who completed the same program
				gen earn_completedLOM=(tot_earn_completed38-logantpctPS)/N_earn_completed38 	// leave-out-mean for earnings, completers of the program that the indivdiual completed
				
				bysort expected_prog: egen N_earn_expected_prog38=count(logantpctPS)
				replace N_earn_expected_prog38=N_earn_expected_prog38-1
				bysort expected_prog: egen tot_earn_expected_prog38=total(logantpctPS)
				gen earn_expected_progLOM=(tot_earn_expected_prog38-logantpctPS)/N_earn_expected_prog38		// leave-out-mean for earnings of the expected program (where the individual was accepted)
				
				bysort ssyk38: egen N_femshare=count(fem)
				replace N_femshare=N_femshare-1
				bysort ssyk38: egen tot_femshare=total(fem)
				gen femshare_ssykLOM=(tot_femshare-fem)/N_femshare											// Leave-out-mean female share in occupation
			
				bysort ssyk3digit38: egen N_ssyk3digit38=count(logantpctPS)
				replace N_ssyk3digit38=N_ssyk3digit38-1
				bysort ssyk3digit38: egen tot_ssyk3digit38=total(logantpctPS)
				gen earn_ssyk3digitLOM=(tot_ssyk3digit38-logantpctPS)/N_ssyk3digit38 						// leave-out-mean of earnings at 3-digit occupation when aged 38
				
				bysort ssyk38: egen N_ssyk38=count(logantpctPS)
				replace N_ssyk38=N_ssyk38-1
				bysort ssyk38: egen tot_ssyk38=total(logantpctPS)
				gen earn_ssyk38LOM=(tot_ssyk38-logantpctPS)/N_ssyk38										// leave-out-mean of earnings at 4-digit occupation when aged 38 (ssyk38)
				
				
				*** For certain 4-digit occupations we have too few observations (below 100) and then replace the value with the 3-digit occupation earnings
				
				local restr ssyk38==2112 | ssyk38==2454 | ssyk38==3449 | ssyk38==3474 | ssyk38==4214 | ssyk38==5210 | ssyk38==6122 | ssyk38==6151 | ssyk38==6153 | ssyk38==7215 | ssyk38==7216 | ///
							ssyk38==7312 | ssyk38==7321 | ssyk38==7322 | ssyk38==7323 | ssyk38==7330 | ssyk38==7342 | ssyk38==7343 | ssyk38==7413 | ssyk38==7422 | ssyk38==7432 | ssyk38==7433 | ///
							ssyk38==7441 | ssyk38==7442 | ssyk38==8261 |  ssyk38==8265 | ssyk38==8273 | ssyk38==8276 | ssyk38==8277 | ssyk38==8279 | ssyk38==8285 | ssyk38==9110 | ssyk38==9121 | ssyk38==9123
		
		gen earn438LOM=earn_ssyk38LOM
		replace earn438LOM=earn_ssyk3digitLOM if `restr'

	keep PersonLopNr Kon ProdAr Fodar emp35pct rank* log* earn* ssyk* share* *C femshare* meanPS* 
	sort PersonLopNr 
	
	save "$file\xtra_temp.dta",replace


	***MERGE INFO ON EDUCATION - MEASURED WHEN IND IS AGED 38
	*
	************************************************************

			use "$file\utb1990_2014.dta",clear 						// File contains education (SUN-code) and exam category (inr) collected yearly 1990-2014 from "LISA" of Statistics Sweden, 
			keep if FodelseAr>=1959 & FodelseAr<=1977
			keep PersonLopNr sun_* inr_*
			save "$file\temp.dta",replace
						
			
			use "$file\step5_AEJ.dta",clear 						// Picking up our sample of all applicants 1977-1991
			sort PersonLopNr 
			merge 1:1 PersonLopNr using "$file\temp.dta",nogen 		// Merging educational information from the file created immideately above
			keep if ProdAr!=.
			merge m:1 PersonLopNr using "$file\xtra_temp.dta",nogen // merging earnings and occupation/program specific earnings from the file created above
			
			drop if PersonLopNr==.
	
			*Schooling code (level and category)for each age (eventually collpsed to proxy schooling at age 38)
			
			forvalues x=29/50 {
				gen sun`x'=.
				gen inr`x'="."
			}
			
			forvalues y = 1959/1977 {
				dis `y'
				forvalues x=29/50 {
					local z =`x'+`y'
					capture replace sun`x'=sun_`z' if Fodar==`y' 
					capture replace inr`x'=inr_`z' if Fodar==`y'
				}
			}

foreach x in 39 37 40 36 41 35 42 34 43 33 44 32 45 31 46 30 47 29 48 { // values replaced if not available at age 38
dis `x'
replace sun38=sun`x' if sun38==. & sun`x'!=.
replace inr38=inr`x' if (inr38=="999z" | inr38==".") & inr`x'!="999z" & inr`x'!="."
}			
gen inr383 = substr(inr38,1,3) 

		rename (sun38 inr38 inr383) (help help1 help2)
		drop sun* inr*
		rename (help help1 help2) (sun38 inr38 inr383) 
		
			gen utb38=.
			replace utb38=9 if sun38>99 & sun38<207 & utb38==.		// SUN-code converted to years of schooling
			replace utb38=10 if sun38>309 & sun38<318 & utb38==.
			replace utb38=11 if sun38>319 & sun38<328 & utb38==.
			replace utb38=12 if sun38>329 & sun38<338 & utb38==.
			replace utb38=13 if sun38>409 & sun38<418 & utb38==.
			replace utb38=14 if sun38>519 & sun38<528 & utb38==.
			replace utb38=15 if sun38>529 & sun38<538 & utb38==.
			replace utb38=16 if sun38>539 & sun38<548 & utb38==.
			replace utb38=17 if sun38>554 & sun38<558 & utb38==.
			replace utb38=18 if sun38>599 & sun38<641 & utb38==.
			gen hisk15=(utb38>=15 & utb38!=.)
			gen hisk14=(utb38>=14 & utb38!=.)
			
			gen hsreg_sun38=.
			gen hsex_sun38=.
			foreach x in 412 417 522 526 527 532 536 537 546 547 556 557 620 640 {  // sun-codes used to elicit college enrollment (hsreg) or completion (hsex) 
				replace hsreg_sun38=1 if sun38==`x'
			}
				
			foreach x in 526 527 536 537 546 547 556 557 620 640 {
				replace hsex_sun38=1 if sun38==`x'
			}
				replace hsex_sun38=0 if hsex_sun38==.
				replace hsreg_sun38=0 if hsreg_sun38==.
		
			
		*** variable with details on post-secondary education
		gen postsec=.
		replace postsec=0 if sun38<336									// less than 3 yr upp sec
		replace postsec=1 if (sun38==336 | sun38==337) 					// 3 yr upp sec
		replace postsec=2 if (sun38==410 | sun38==413 | sun38==415) 							// 1 yr non-college
		replace postsec=3 if (sun38==520 | sun38==525) 											// 2 yr non-college
		replace postsec=4 if (sun38==530 | sun38==535) 											// 3 yr non-college
		replace postsec=5 if (sun38==540 | sun38==545 | sun38==550 | sun38==555) 				// 4+ yr non-college
		replace postsec=6 if (sun38==412 | sun38==417) 					// 1 yr college no exam
		replace postsec=7 if (sun38==522) 								// 2 yr college no exam
		replace postsec=8 if (sun38==532) 								// 3 yr college no exam
		replace postsec=9 if (sun38==526 | sun38==527) 											// 2 yr exam
		replace postsec=10 if (sun38==536 | sun38==537) 										// 3 yr exam
		replace postsec=11 if (sun38==546 | sun38==547) 										// 4 yr exam
		replace postsec=12 if (sun38==556 | sun38==557 | sun38==600 | sun38==620 | sun38==640) 	// 5 yr exam
		replace postsec=1 if utb38==12 & postsec==0		
		
		gen somepostsec=(postsec>=3 & postsec<=8)
		
		*YEARS OF UPPER SECONDARY SCHOOL: 
		*********************************
		
		gen yrssec=0	// yrssec indicates actual years of completed upper secondary school - based on information on program completions
		
		***2-years for most vocational programs
		replace yrssec=2 if ((completed==9) | (completed==54) | (completed==58) | (completed>=1 & completed<=3) | (completed==6) | (completed==7) | (completed==11) | (completed==15) | ///
						(completed>=19 & completed<=22) | (completed==26) | (completed==32) | (completed==33) | (completed==36) | (completed==48) | (completed>=53 & completed<=56) | ///
						(completed==61) | (completed==62) | (completed==65) | (completed==66)) 
		
		*Three years if vocational pilot program (1987-1991)
		replace yrssec=3 if (completed==4 | completed==5 | completed==12 | completed==13 | completed==14 | completed==16 | completed==17 | completed==18 | completed==23 | completed==24 | completed==25 | ///
							completed==27 | completed==30 | completed==31 | completed==35 | (completed>=37 & completed<=42) | completed==46 | completed==47 | completed==49 | completed==50 | completed==60 | ///
							completed==63 | completed==64 | completed==67 | completed==68 | completed==75)
		
		*Three years for our academic programs (10, 28, 43, 44 or 51)
		replace yrssec=3 if ((completed==10) | (completed==28) | (completed==43) | (completed==44) | (completed==51))
		
		*Four years if completed the engineering program (59)
		replace yrssec=4 if completed==59 
		
		*Others are given the years stated by the SUN code
		replace yrssec=1 if utb38==10 & yrssec==0
		replace yrssec=2 if utb38==11 & yrssec==0
		replace yrssec=3 if utb38>=12 & utb38!=. & yrssec==0
		replace completed=0 if completed==.
		replace yrssec=3 if yrssec==4 & completed==59 & utb38<=12
		
		gen yrspostsec=1 if postsec==2
		replace yrspostsec=2 if postsec==3
		replace yrspostsec=3 if postsec==4
		replace yrspostsec=4 if postsec==5


		gen collyrs=1 if postsec==6					// We can potentially make a distinction between post-secondary and college-years (but unclear and not used)
		replace collyrs=2 if postsec==7
		replace collyrs=3 if postsec==8
		replace collyrs=2 if postsec==9
		replace collyrs=3 if postsec==10
		replace collyrs=4 if postsec==11
		replace collyrs=5 if postsec==12
				replace yrspostsec=0 if yrspostsec==.
				replace collyrs=0 if collyrs==.

		gen utbactual=9+yrssec+yrspostsec+collyrs	// actual years of schooling rather than based on highest achieved education (rendered similar results in our analysis and not used)



		*************
		
		gen examtype=.
		replace examtype=1 if inr38>="140z" & inr38<="149x"
		replace examtype=2 if inr38>="211a" & inr38<="229z"
		replace examtype=3 if inr38>="310a" & inr38<="380x"
		replace examtype=4 if inr38>="421a" & inr38<="489z"
		replace examtype=5 if inr38>="520a" & inr38<="589z"
		replace examtype=6 if inr38>="620z" & inr38<="640x"
		replace examtype=7 if inr38>="720z" & inr38<="762x"
		replace examtype=8 if inr38>="811a" & inr38<="863x"
		
		label define post 0 "less than 3 yr upp sec" 1 "3 yr upp sec" 2 "1 yr non-college" 3 "2 yr non-college" 4 "3 yr non-college" 5 "4+ yr non-college" ///
			6 "1 yr college no exam" 7 "2 yr college no exam" 8 "3 yr college no exam" 9 "2 yr exam" 10 "3 yr exam" 11 "4 yr exam" 12 "5 yr exam"
			label values postsec post
			label define type 1 "Pedagogics" 2 "Human sciences" 3 "Social sciences" 4 "Natural sciences" 5 "Engineering" 6 "Farming/forestry" 7 "Health" 8 "Services"
			label values examtype type
			
		la var utb38 "Years of schooling"
		la var postsec "Exam-years"
		la var sun38 "SUN-koder"
		
			
		gen expected_prog=fst if Sint==1
		replace expected_prog=sec if Sint==0								// expected program is the program where the individual is accepted
		
		
		bysort ssyk3digit38: egen N_ssyk3digit38=count(hisk15)
		replace N_ssyk3digit38=N_ssyk3digit38-1
		bysort ssyk3digit38: egen tot_ssyk3digit38=total(hisk15)
		gen hisk_ssyk3digitLOM=(tot_ssyk3digit38-hisk15)/N_ssyk3digit38 	// Leave-out-mean of college exam for 3-digit occupation
		
		bysort ssyk38: egen N_ssyk38=count(hisk15)
		replace N_ssyk38=N_ssyk38-1
		bysort ssyk38: egen tot_ssyk38=total(hisk15)
		gen hisk_ssyk38LOM=(tot_ssyk38-hisk15)/N_ssyk38 					// Leave-out-mean of college exam for 4-digit occupation
		
		bysort completed: egen N_hisk_completed=count(hisk15)
		replace N_hisk_completed=N_hisk_completed-1
		bysort completed: egen tot_hisk_completed=total(hisk15)
		gen hisk_completedLOM=(tot_hisk_completed-hisk15)/N_hisk_completed // Leave-out-mean of college exam for program completion
		
		bysort expected_prog: egen N_hisk_expected=count(hisk15)
		replace N_hisk_expected=N_hisk_expected-1
		bysort expected_prog: egen tot_hisk_expected=total(hisk15)
		gen hisk_expectedLOM=(tot_hisk_expected-hisk15)/N_hisk_expected 	// Leave-out-mean of college exam for program acceptance (Sint==1)
		
		bysort utb38: egen N_utb38=count(log3739PS)
		replace N_utb38=N_utb38-1
		bysort utb38: egen tot_utb38=total(log3739PS)
		gen earn_utb38LOM=(tot_utb38-log3739PS)/N_utb38						// Leave-out-mean earnings for years of schooling 
		
		bysort utb38 inr38: egen N_inrutb38=count(log3739PS)
		replace N_inrutb38=N_inrutb38-1
		bysort utb38 inr38: egen tot_inrutb38=total(log3739PS)
		gen earn_inrutb38LOM=(tot_inrutb38-log3739PS)/N_inrutb38 			// Leave-out-mean earnings for years of schooling and ALL category-field of study
		
		gen koll=examtype
		replace koll=9999 if (utb38<15 | postsec==4 | postsec==5)
		bysort koll: egen N_examcoll15=count(log3739PS) 
		replace N_examcoll15=N_examcoll15-1
		bysort koll: egen tot_examcoll15=total(log3739PS)
		gen earn_examcollLOM15=(tot_examcoll15-log3739PS)/N_examcoll15 		// Leave-out-mean earnings for category-field of study (8 categories)
		
		bysort inr383: egen N_inr383=count(log3739PS) if utb38>=15 & utb38!=.
		replace inr383="9999" if N_inr383<100
		drop N_inr383
		
		drop koll
		gen koll=inr383
		replace koll="9999" if (utb38<15 | postsec==4 | postsec==5)
		bysort koll: egen N_inrcoll153=count(log3739PS) 
		replace N_inrcoll153=N_inrcoll153-1
		bysort koll: egen tot_inrcoll153=total(log3739PS)
		gen earn_inrcollLOM153=(tot_inrcoll153-log3739PS)/N_inrcoll153 		// Leave-out-mean earnings for category-field of study
		
		
		bysort inr38: egen N_inr38=count(log3739PS) if utb38>=15 & utb38!=.
		replace inr38="9999" if N_inr38<100
		
		drop koll
		gen koll=inr38
		replace koll="9999" if (utb38<15 | postsec==4 | postsec==5)
		bysort koll: egen N_inrcoll15=count(log3739PS) 
		replace N_inrcoll15=N_inrcoll15-1
		bysort koll: egen tot_inrcoll15=total(log3739PS)
		gen earn_inrcollLOM15=(tot_inrcoll15-log3739PS)/N_inrcoll15 		// Leave-out-mean earnings for category-field of study
																			// if less then 100 obs in a field we replace with earn_inrcollLOM153
		replace earn_inrcollLOM15=earn_inrcollLOM153 if N_inr38<100 & earn_inrcollLOM153!=.
		
		
		drop tot* N_*
		
		save "$file\step5_AEJ.dta",replace
	

	
	
	
	********Foreign born 
			*** Add info on foreign background of the individual and the parents ("utrfod utrFar utrMor") from separate register
	drop _all
odbc load, table("FodelseLand") connectionstring("DRIVER={SQL Server};SERVER={mq02\b};DATABASE={P0484_SU_SOFI_Utbildningsinnehall};Trusted_Connection={Yes}")
sort PersonLopNr 
destring FodGrEg FodGrFar FodGrMor,replace force 	// indicators of country of birth
foreach x in Eg Far Mor {
gen utr`x'=1 if FodGr`x'>0 & FodGr`x'!=.			// if country of birth is Sweden the FodGr-variables are equal to zero 
replace utr`x'=0 if FodGr`x'==0						// dummies utrfod utrFar utrMor
}
rename utrEg utrfod
keep PersonLopNr utrfod utr*
		
bysort PersonLopNr: gen nobs=_n
keep if nobs==1
drop nobs
merge 1:m PersonLopNr using "$file\step5_AEJ.dta",nogen
keep if ProdAr!=.

gen utrpar=(utrFar==1 | utrMor==1)
replace utrpar=. if utrFar==. & utrMor==. 			// utrpar = one parent with foreign background

save "$file\step5_AEJ.dta",replace
	
	*ADD INFO ON PARENTAL BACKGROUND 
	
	use "$file\parents.dta", clear 	// the file parents is set up by linking parents in the multiple generation registers of Statistics Sweden to biological and adopted children 
									// parents' personal id number is used to link them to their year of birth, education and earnings 
									// earnings is measured in year of enrolment (below)
									// education is only available in 1970 (census data) and in 1990 (LISA)
		sort PersonLopNr
	keep PersonLopNr FodarMor FodarFar adopted utbFar1970 utbMor1970 utbMor utbFar
	
	sort PersonLopNr
	
	merge 1:1 PersonLopNr using "$file\step5_AEJ.dta", nogen
	keep if ProdAr!=.
																	
		gen utb7090Far=7 if utbFar1970==1 & ProdAr<=1985			// Parents' education is available from the 1970 census and in LISA 1990 or later.
		replace utb7090Far=9 if utbFar1970==2 & ProdAr<=1985		// Assuming most parents in 1960s had completed their highest level at the time 
		replace utb7090Far=11 if utbFar1970==3 & ProdAr<=1985		// of the child's birth we use census data 1970 for applicants up and until 1985 (born 1969) 
		replace utb7090Far=12 if utbFar1970==4 & ProdAr<=1985		// and for applicants 1986-1991 and other missing values we use LISA data from 1990-1992 (earliest non-missing)
		replace utb7090Far=14 if utbFar1970==5 & ProdAr<=1985
		replace utb7090Far=15 if utbFar1970==6 & ProdAr<=1985
		replace utb7090Far=17 if utbFar1970==7 & ProdAr<=1985
		replace utb7090Far=utbFar if utb7090Far==.
		
		gen utb7090Mor=7 if utbMor1970==1 & ProdAr<=1985
		replace utb7090Mor=9 if utbMor1970==2 & ProdAr<=1985
		replace utb7090Mor=11 if utbMor1970==3 & ProdAr<=1985
		replace utb7090Mor=12 if utbMor1970==4 & ProdAr<=1985
		replace utb7090Mor=14 if utbMor1970==5 & ProdAr<=1985
		replace utb7090Mor=15 if utbMor1970==6 & ProdAr<=1985
		replace utb7090Mor=17 if utbMor1970==7 & ProdAr<=1985
		replace utb7090Mor=utbMor if utb7090Mor==. 
		sum utb*
		drop utbMor utbFar
		rename (utb7090Far utb7090Mor) (utbFar utbMor)
		
		gen utbpar=utbFar									
		replace utbpar=utbMor if (utbMor>utbFar & utbMor!=.)
		replace utbpar=utbMor if utbpar==.								// utbpar = highest achieved level of education between parents
		
		gen ageMor=ProdAr-FodarMor-age
		gen ageFar=ProdAr-FodarFar-age
		replace ageMor=. if (ageMor<15 | ageMor>48) 					// exclude age of mother at birth which represent 0.01 percent at either end of the distribution (deletes incorrect outliers)
		replace ageFar=. if ageFar<15 
		replace FodarFar=. if ageFar<15 
		replace FodarMor=. if (ageMor<15 | ageMor>48)
		
	save "$file\step5_AEJ.dta",replace

		
*ADD INFO ON PARENTAL EARNINGS
	
			
	use "$file\step5_AEJ.dta",clear
		sort PersonLopNr 
		keep PersonLopNr ProdAr	Fodar	
	save "$file\temp.dta",replace

	****
	
	use "$file\w1978_w2018.dta",clear // earnings since 1978 (labor earnings) - we assign parents their earnings in the year of the application
sort PersonLopNr 
keep PersonLopNr w1978-w1992
merge 1:1 PersonLopNr using "$file\fodarkon.dta", nogen // add info of birthyear from population registers
				
					forvalues x=1978/1992 {
							dis `x'
							
							_pctile w`x' if Fodar>=(`x'-64) & Fodar<=(`x'-18),p(35)	// generate limit value of 35th percentile of 18-64 year olds 1978-1992, similar ot the measure defined above for 1996-2016 
							local p=r(r1)
							qui gen antpct`x'=(w`x'>=(`p'))
							qui replace antpct`x'=. if w`x'==.
					}
		
		
					forvalues x=1978/1992 {
							dis `x'
				bysort Fodar Kon: egen rankman`x'=rank(w`x') if Kon==1
				sum rankman`x'
				replace rankman`x'=rankman`x'/r(max)
				bysort Fodar Kon: egen rankman`x'2=rank(w`x') if Kon==2
				sum rankman`x'2
				replace rankman`x'=rankman`x'2/r(max) if rankman`x'==.
			}
		
		
		save "$file\temp12.dta", replace

	
foreach par in Mo Fa {
use "$file\parents.dta",clear		// link between parents and biological or adopted children from the multiple generation registers of Statistics Sweden, 
keep PersonLopNr Lopnr`par'r		
merge 1:1 PersonLopNr using "$file\temp.dta",nogen 		// temp-file created on row 935 above
keep if Fodar>=1959 & Fodar<=1977
sort Lopnr`par'r					 
save "$file\xtra_temp.dta",replace


			use "$file\temp12.dta",clear
sort PersonLopNr 
rename PersonLopNr Lopnr`par'r		// sort on parent id - merge earnings from temp12-file conditioned on year of application (ProdAr); 
merge 1:m Lopnr`par'r using "$file\xtra_temp.dta",nogen
keep if PersonLopNr!=.
qui gen w`par'ther =w1978 if ProdAr==1977 | ProdAr==1978					// For 1977, we use 1978 earnings (earliest available)
qui gen want`par'r=w1978 if (ProdAr==1977 | ProdAr==1978) & antpct1978==1	// "want" is earn according to Antelius and Björklund > 35th percentile, otherwise missing (see above)
qui gen rank`par'r=rankman1978 if ProdAr==1977 | ProdAr==1978
forvalues x=1979/1991 {
dis `x'
qui replace w`par'ther =w`x' if ProdAr==`x' 
qui replace want`par'r=w`x' if ProdAr==`x' & antpct`x'==1
qui replace rank`par'r=rankman`x' if ProdAr==`x' 
}
sort ProdAr PersonLopNr
keep ProdAr PersonLopNr w`par'ther want`par'r rank`par'r
gen lnw`par'r=ln(want`par'r)

merge 1:1 PersonLopNr using "$file\step5_AEJ.dta",nogen
save "$file\step5_AEJ.dta", replace
}




		*** ADD POPULATION GPA WHICH IS USED TO REPORT A DIGIT ON PAGE 13, THAT A GPA CORRESPONDS TO THE 63RD PERCENTILE OF THE POPULATION
		
		use "$file\step5_AEJ.dta",clear
		
		sort ProdAr PersonLopNr 				
		gen help=1
				merge m:1 ProdAr PersonLopNr using "$file\Medelbetyg1988_1991.dta",nogen  // From the population data of GPA, only available from 1988 (born 1972),
																							
				keep if help!=.
				drop help
				gen GPA_original=GPA
				replace gpapop=gpapop*100
				replace GPA=gpapop if GPA_original==. 
				
				
		
		** Define categorical program variables:
	
	gen academic=(fst==10 | fst==28 | fst==43 | fst==44 | fst==51 | fst==59)
	gen nonac1=((fst==9) | (fst==54) | (fst==58) | (fst>=1 & fst<=7) | (fst>=11 & fst<=27) | (fst>=30 & fst<=33) | 						/// 	non-academic first choice
					(fst>=35 & fst<=42) | (fst>=46 & fst<=50) | (fst>=53 & fst<=56) | (fst>=60 & fst<=68) | (fst>=74 & fst<=76))
	gen nonac2=((sec==9) | (sec==54) | (sec==58) | (sec>=1 & sec<=7) | (sec>=11 & sec<=27) | (sec>=30 & sec<=33) | 						/// 	non-academic second choice
					(sec>=35 & sec<=42) | (sec>=46 & sec<=50) | (sec>=53 & sec<=56) | (sec>=60 & sec<=68) | (sec>=74 & sec<=76))
	
	gen nonacv=(nonac1==1 & fst!=9 & fst!=54 & fst!=58) 																				// non-academic vocational first choice
	gen nonacg=((fst==9) | (fst==54) | (fst==58))																						// non-academic general first choice
	
	gen fem=(Kon==2)								// gender dummy
	gen tsec=(sec==59)								// second choice dummies by category-field
	gen nsec=(sec==44)
	gen ssec=(sec==51)
	gen bsec=(sec==10)
	gen hsec=(sec==28)
	gen nonac2v=(nonac2==1 & sec!=9 & sec!=54 & sec!=58)
	gen nonac2g=(nonac2==1 & (sec==9 | sec==54 | sec==58))
		
		
	
				gen Fst=.									// generating Fst which groups the five academic programs and non-academic general & vocational
					replace Fst=1 if (fst==59)
					replace Fst=2 if (fst==44)
					replace Fst=3 if (fst==10)
					replace Fst=4 if (fst==51)
					replace Fst=5 if (fst==28)
					replace Fst=6 if nonac1==1 & (fst==9 | fst==54 | fst==58)
					replace Fst=7 if (nonac1==1 & fst!=9 & fst!=54 & fst!=58)
			gen Sec=.
					replace Sec=1 if (sec==59)
					replace Sec=2 if (sec==44)
					replace Sec=3 if (sec==10)
					replace Sec=4 if (sec==51)
					replace Sec=5 if (sec==28)
					replace Sec=6 if nonac2==1 & (sec==9 | sec==54 | sec==58)
					replace Sec=7 if nonac2==1 & sec!=9 & sec!=54 & sec!=58
			gen FstC=.
					replace FstC=1 if (completed==59)
					replace FstC=2 if (completed==44)
					replace FstC=3 if (completed==10)
					replace FstC=4 if (completed==51)
					replace FstC=5 if (completed==28)
					replace FstC=6 if nonac1C==1 & (completed==9 | completed==54 | completed==58)
					replace FstC=7 if (nonac1C==1 & completed!=9 & completed!=54 & completed!=58)
			label define cat 1 "Engineering" 2 "Natural sci." 3 "Business" 4 "Social sci." 5 "Humanities" 6 "General" 7 "Vocational" 
			label values Fst Sec cat
			

		
label define digit 1 "Junior recr prog" 2 "Textile 2yrs" 3 "Construction 2yrs" 4 "Constr - metal & ventil pilot" 5 "Constr prog" 6 "Office 2yrs" 7 "Mechanics 2yrs" 8 "Less than 20w" 9 "Business 2yrs" ///
10 "Business 3yrs" 11 "Electronics 2yrs" 12 "Electronics pilot" 13 "Electronics prog" 14 "Energy prog" 15 "Estethics 2yrs" 16 "Estethic prog" 17 "Vehicle/transport pilot" 18 "Vehicle prog" 19 "Vehicle engin 2yrs" ///
20 "Hairdresser" 21 "Graphical design" 22 "Trade & office 2yrs" 23 "Trade & office pilot" 24 "Trade & adm prog" 25 "Handicraft prog" 26 "Handicraft 2yrs" 27 "Hotel/restaur prog" 28 "Humanities" 29 "Individual prog" ///
30 "Industrial mechanics pilot" 31 "Industrial prog" 32 "Farming 2yrs" 33 "Consumer stud 2yrs" 34 "Less than 40w" 35 "Food prog" 36 "Food 2yrs" 37 "Food pilot" 38 "Media prog" 39 "Music" 40 "Painting pilot" ///
41 "Natural resources pilot" 42 "Natural res prog" 43 "Science/engineering" 44 "Natural Sciences" 45 "Nat Science prog" 46 "Health care pilot" 47 "Health care prog" 48 "Process techn 2yrs" 49 "Production techn pilot" ///
50 "Restaurant pilot" 51 "Social sciences" 52 "Social sci prog" 53 "Forestry 2yrs" 54 "Social sci 2yrs" 55 "Community care 2yrs" 56 "Community care 2.5yrs" 57 "Special prog" 58 "Engineering 2yrs" 59 "Engineering" ///
60 "Textile/clothing pilot" 61 "Gardening 2yrs" 62 "Woodwork 2yrs" 63 "Woodwork pilot" 64 "Ventilation pilot" 65 "Metal work 2yrs" 66 "Nursing 2yrs" 67 "Nursing pilot" 68 "Nursing youth pilot" 69 "2nd year"  ///
70 "Special courses" 71 "International Baccalaureate" 72 "Estethic 2011" 73 "Rikstäckande" 74 "Food and restaurant prog" 75 "Construction pilot" 76 "Ventilation & premises" 99 "Introductory prog" ///
110 "Business in S-prog" 110 "Humanities in S-prog" ,replace
					
foreach y in fst sec completed Program {
label values `y' digit
}

	save "$file\step5_AEJ.dta", replace	
			
	
	use "$file\w_age_AEJ.dta",clear
	keep PersonLopNr earnPS37-earnPS39
	sort PersonLopNr
	save "$file\temp.dta", replace
	
	use "$file\step5_AEJ.dta",clear
		sort PersonLopNr
		merge 1:1 PersonLopNr using "$file\temp.dta",nogen
		keep if ProdAr!=.
	save "$file\step5_AEJ.dta", replace	
		
	
			****************
			*** Here, the step5 MASTER-file is done.
			************************************
	
	
			***We now create a reduced "competitive_AEJ"-file used for our estimations - this is reduced to the competitive cells where academic programs are oversubscribed
			*****************************
			
		use "$file\step5_AEJ.dta",clear
		
		 tab fst if fst==10 | fst==28 | fst==43 | fst==44 | fst==51 | fst==59
/*
        fst |      Freq.     Percent        Cum.
------------+-----------------------------------
         10 |    161,984       26.65       26.65
         28 |     54,459        8.96       35.61
         43 |      3,657        0.60       36.22
         44 |    108,195       17.80       54.02
         51 |    115,437       18.99       73.01
         59 |    164,026       26.99      100.00
------------+-----------------------------------
      Total |    607,758      100.00

*/
		
		drop if cut==. | dist==.
		keep if fst==10 | fst==28 | fst==43 | fst==44 | fst==51 | fst==59
		drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
						(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		// drop if Jmft is very low or very high
		keep if Sint!=.
		
		*** drop if competitive cell within +1.5 and 1.0 of cutoff and exclude mixed borders (on cutoff), if sec choice is missing or the same as first choice
		keep if diff_count>=3 & app_count>=25 & (abs(dist)<=151) & (abs(dist)>=1) & dist>-101 & sec!=. & fst!=sec & fst!=43 & sec!=43 
		
		// BELOW GENERATES DUMMIES FOR a) ACCEPTANCE (Sint) b) ENROLLMENT (lint) AND c) COMPLETION (fin) 		
		
		gen SintT=(Sint==1 & fst==59)
		gen SintN=(Sint==1 & fst==44)
		gen SintS=(Sint==1 & fst==51)
		gen SintB=(Sint==1 & fst==10)
		gen SintH=(Sint==1 & fst==28)
		gen SintTn=(Sint==1 & fst==59 & nsec==1)
		gen SintTb=(Sint==1 & fst==59 & bsec==1)
		gen SintTs=(Sint==1 & fst==59 & ssec==1)
		gen SintTh=(Sint==1 & fst==59 & hsec==1)
		gen SintTv=(Sint==1 & fst==59 & nonac2v==1)
		gen SintTg=(Sint==1 & fst==59 & nonac2g==1)
		gen SintTnon=(Sint==1 & fst==59 & nonac2==1)
		gen SintNt=(Sint==1 & fst==44 & tsec==1)
		gen SintNb=(Sint==1 & fst==44 & bsec==1)
		gen SintNs=(Sint==1 & fst==44 & ssec==1)
		gen SintNh=(Sint==1 & fst==44 & hsec==1)
		gen SintNv=(Sint==1 & fst==44 & nonac2v==1)
		gen SintNg=(Sint==1 & fst==44 & nonac2g==1)
		gen SintNnon=(Sint==1 & fst==44 & nonac2==1)
		gen SintSt=(Sint==1 & fst==51 & tsec==1)
		gen SintSn=(Sint==1 & fst==51 & nsec==1)
		gen SintSb=(Sint==1 & fst==51 & bsec==1)
		gen SintSh=(Sint==1 & fst==51 & hsec==1)
		gen SintSv=(Sint==1 & fst==51 & nonac2v==1)
		gen SintSg=(Sint==1 & fst==51 & nonac2g==1)
		gen SintSnon=(Sint==1 & fst==51 & nonac2==1)
		gen SintBt=(Sint==1 & fst==10 & tsec==1)
		gen SintBn=(Sint==1 & fst==10 & nsec==1)
		gen SintBs=(Sint==1 & fst==10 & ssec==1)
		gen SintBh=(Sint==1 & fst==10 & hsec==1)
		gen SintBv=(Sint==1 & fst==10 & nonac2v==1)
		gen SintBg=(Sint==1 & fst==10 & nonac2g==1)
		gen SintBnon=(Sint==1 & fst==10 & nonac2==1)
		gen SintHt=(Sint==1 & fst==28 & tsec==1)
		gen SintHn=(Sint==1 & fst==28 & nsec==1)
		gen SintHb=(Sint==1 & fst==28 & bsec==1)
		gen SintHs=(Sint==1 & fst==28 & ssec==1)
		gen SintHv=(Sint==1 & fst==28 & nonac2v==1)
		gen SintHg=(Sint==1 & fst==28 & nonac2g==1)
		gen SintHnon=(Sint==1 & fst==28 & nonac2==1)
		gen SintBSH=(Sint==1 & (fst==51 | fst==10 | fst==28))
		gen SintSTEM=(Sint==1 & (fst==59 | fst==43 | fst==44))
		
		gen lintT=(lint==1 & fst==59)
		gen lintN=(lint==1 & fst==44)
		gen lintS=(lint==1 & fst==51)
		gen lintB=(lint==1 & fst==10)
		gen lintH=(lint==1 & fst==28)
		gen lintTn=(lint==1 & fst==59 & nsec==1)
		gen lintTb=(lint==1 & fst==59 & bsec==1)
		gen lintTs=(lint==1 & fst==59 & ssec==1)
		gen lintTh=(lint==1 & fst==59 & hsec==1)
		gen lintTv=(lint==1 & fst==59 & nonac2v==1)
		gen lintTg=(lint==1 & fst==59 & nonac2g==1)
		gen lintTnon=(lint==1 & fst==59 & nonac2==1)
		gen lintNt=(lint==1 & fst==44 & tsec==1)
		gen lintNb=(lint==1 & fst==44 & bsec==1)
		gen lintNs=(lint==1 & fst==44 & ssec==1)
		gen lintNh=(lint==1 & fst==44 & hsec==1)
		gen lintNv=(lint==1 & fst==44 & nonac2v==1)
		gen lintNg=(lint==1 & fst==44 & nonac2g==1)
		gen lintNnon=(lint==1 & fst==44 & nonac2==1)
		gen lintSt=(lint==1 & fst==51 & tsec==1)
		gen lintSn=(lint==1 & fst==51 & nsec==1)
		gen lintSb=(lint==1 & fst==51 & bsec==1)
		gen lintSh=(lint==1 & fst==51 & hsec==1)
		gen lintSv=(lint==1 & fst==51 & nonac2v==1)
		gen lintSg=(lint==1 & fst==51 & nonac2g==1)
		gen lintSnon=(lint==1 & fst==51 & nonac2==1)
		gen lintBt=(lint==1 & fst==10 & tsec==1)
		gen lintBn=(lint==1 & fst==10 & nsec==1)
		gen lintBs=(lint==1 & fst==10 & ssec==1)
		gen lintBh=(lint==1 & fst==10 & hsec==1)
		gen lintBv=(lint==1 & fst==10 & nonac2v==1)
		gen lintBg=(lint==1 & fst==10 & nonac2g==1)
		gen lintBnon=(lint==1 & fst==10 & nonac2==1)
		gen lintHt=(lint==1 & fst==28 & tsec==1)
		gen lintHn=(lint==1 & fst==28 & nsec==1)
		gen lintHb=(lint==1 & fst==28 & bsec==1)
		gen lintHs=(lint==1 & fst==28 & ssec==1)
		gen lintHv=(lint==1 & fst==28 & nonac2v==1)
		gen lintHg=(lint==1 & fst==28 & nonac2g==1)
		gen lintHnon=(lint==1 & fst==28 & nonac2==1)
		gen lintSTEM=(lint==1 & (fst==59 | fst==43 | fst==44))
		gen lintBSH=(lint==1 & (fst==51 | fst==10 | fst==28))
		
		gen complT=(fin==1 & fst==59)
		gen complN=(fin==1 & fst==44)
		gen complS=(fin==1 & fst==51)
		gen complB=(fin==1 & fst==10)
		gen complH=(fin==1 & fst==28)
		gen complTn=(fin==1 & fst==59 & nsec==1)
		gen complTb=(fin==1 & fst==59 & bsec==1)
		gen complTs=(fin==1 & fst==59 & ssec==1)
		gen complTh=(fin==1 & fst==59 & hsec==1)
		gen complTv=(fin==1 & fst==59 & nonac2v==1)
		gen complTg=(fin==1 & fst==59 & nonac2g==1)
		gen complTnon=(fin==1 & fst==59 & nonac2==1)
		gen complNt=(fin==1 & fst==44 & tsec==1)
		gen complNb=(fin==1 & fst==44 & bsec==1)
		gen complNs=(fin==1 & fst==44 & ssec==1)
		gen complNh=(fin==1 & fst==44 & hsec==1)
		gen complNv=(fin==1 & fst==44 & nonac2v==1)
		gen complNg=(fin==1 & fst==44 & nonac2g==1)
		gen complNnon=(fin==1 & fst==44 & nonac2==1)
		gen complSt=(fin==1 & fst==51 & tsec==1)
		gen complSn=(fin==1 & fst==51 & nsec==1)
		gen complSb=(fin==1 & fst==51 & bsec==1)
		gen complSh=(fin==1 & fst==51 & hsec==1)
		gen complSv=(fin==1 & fst==51 & nonac2v==1)
		gen complSg=(fin==1 & fst==51 & nonac2g==1)
		gen complSnon=(fin==1 & fst==51 & nonac2==1)
		gen complBt=(fin==1 & fst==10 & tsec==1)
		gen complBn=(fin==1 & fst==10 & nsec==1)
		gen complBs=(fin==1 & fst==10 & ssec==1)
		gen complBh=(fin==1 & fst==10 & hsec==1)
		gen complBv=(fin==1 & fst==10 & nonac2v==1)
		gen complBg=(fin==1 & fst==10 & nonac2g==1)
		gen complBnon=(fin==1 & fst==10 & nonac2==1)
		gen complHt=(fin==1 & fst==28 & tsec==1)
		gen complHn=(fin==1 & fst==28 & nsec==1)
		gen complHb=(fin==1 & fst==28 & bsec==1)
		gen complHs=(fin==1 & fst==28 & ssec==1)
		gen complHv=(fin==1 & fst==28 & nonac2v==1)
		gen complHg=(fin==1 & fst==28 & nonac2g==1)
		gen complHnon=(fin==1 & fst==28 & nonac2==1)
		gen complSTEM=(fin==1 & (fst==59 | fst==43 | fst==44))
		gen complBSH=(fin==1 & (fst==51 | fst==10 | fst==28))
		
			save "$file\competitive_AEJ.dta",replace

	use "$file\competitive_AEJ.dta",clear
		sort PersonLopNr
		merge 1:1 PersonLopNr using "$file\temp.dta",nogen
		keep if ProdAr!=.
	save "$file\competitive_AEJ.dta", replace	
	
	
	*** additional variables needed when addressing referee issues
	
	
use "$file\w_age_AEJ.dta",clear
	keep PersonLopNr earnPS37-earnPS39 antpctPS37-antpctPS39
	
	forvalues x=37/39 {
	sum earnPS`x' if antpctPS`x'==1
	local limit6=r(min)*0.5
	local limit18=r(min)*1.5
	gen limit0_`x'=(earnPS`x'>0 & earnPS`x'!=.)
	gen limit6_`x'=(earnPS`x'>=`limit6' & earnPS`x'!=.)
	gen limit18_`x'=(earnPS`x'>=`limit18' & earnPS`x'!=.)
	}
	
	sort PersonLopNr
	reshape long earnPS antpctPS limit0_ limit6_ limit18_ , i(PersonLopNr) j(age) 			
	rename (limit0_ limit6_ limit18_)(limit0 limit6 limit18)
	
	bysort PersonLopNr: egen help=mean(earnPS) if antpctPS==1
	bysort PersonLopNr: egen replica3739=mean(help) 
	replace replica3739=10000 if replica3739>10000 & replica3739!=.
	gen logreplica=ln(replica3739)  
	drop help

	foreach x in 0 6 18 {
			bysort PersonLopNr: egen help=mean(earnPS) if limit`x'==1
			bysort PersonLopNr: egen limit`x'_3739=mean(help) 
			replace limit`x'_3739=10000 if limit`x'_3739>10000 & limit`x'_3739!=.
			gen loglimit`x'=ln(limit`x'_3739)  
			gen emp`x'=limit`x'
			drop help
	}
	
	
	bysort PersonLopNr: gen nobs=_n
	keep if nobs==1
	keep PersonLopNr logreplica loglimit* emp* antpct*
	sum*
	save "$file\temp.dta",replace

use "$file\w_age_AEJ.dta",clear
	keep PersonLopNr earnPS37-earnPS39 antpctPS37-antpctPS39
save "$file\temp1.dta",replace



use "$file\competitive_AEJ.dta",clear
		sort PersonLopNr
		merge 1:1 PersonLopNr using "$file\temp.dta",nogen
		merge 1:1 PersonLopNr using "$file\temp1.dta",nogen
		keep if ProdAr!=.
		sum logreplica logantpctPS
save "$file\competitive_AEJ.dta",replace
		
	
use "$file\competitive_AEJ.dta",clear
		sort PersonLopNr
		merge 1:1 PersonLopNr using "$file\temp.dta",nogen
		keep if ProdAr!=.
		sum logreplica logantpctPS
		
		gen N_missing=0
		gen N_zero=0
		gen N_limit12=0
		forvalues x=37/39 {
		    replace N_missing=N_missing+1 if earnPS`x'==.
			replace N_zero=N_zero+1 if earnPS`x'==0
			replace N_limit12=N_limit12+1 if antpctPS`x'==1
		}

save "$file\competitive_AEJ.dta",replace
	
	*do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\results_AEJ.do"
			
