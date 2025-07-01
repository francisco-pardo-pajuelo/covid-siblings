clear
capture log close

log using "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\log_pagebypage.log",replace

set more off, permanently		

global file "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"


*** In the bits of syntaxes below, we alternate between using the baseline file ("competitive_AEJ.dta") or the master-file "step5_AEJ.dta" 
***	Sometimes we also use the raw sample, merging the files from step1, step2 & step3 - this is slightly larger (1.33m obs) than the masterfile "step5_AEJ.dta" (1.29m obs)

*** In contrast to the masterfile, the raw sample also includes individuals with 
*** 1) erroneous Sint code (flagged in syntax step2)
*** 2) 1st choice program missing 
*** 3) duplicate applications (in different regions) 
*** 4) duplicate applications (with different Sint values) 


****
*	- Footnote 8 states that 
*		"only 0.2% of applicants are admitted to their 6th choice" [using the raw data merging step1 step2 step3]
****

		use "$file\Sint_iter_AEJ.dta",clear
			sort ProdAr PersonLopNr choice
			merge 1:1 ProdAr PersonLopNr choice using "$file\clean_7791_AEJ.dta", nogen			
			
				sort ProdAr Region Program
				merge m:1 ProdAr Region Program using "$file\cut_AEJ.dta",nogen		// Merges Sint_iter (step2) with clean_7791 (step1) and cut (step3)
				
				bysort ProdAr PersonLopNr: gen nobs=_n
				bysort ProdAr PersonLopNr: egen maxchoice=max(choice)
				tab maxchoice if nobs==1,m									// this is the statistic used to state that .2 percent were accepted to 6th choice
				
****
*	- Footnote 8 states that 
*		"only 1.03% even list a 6th choice" - this requires a specially designed data set (re-running step1 but retaining all redundant choices) 
****
		** The file "$file\clean_7791_AEJstated.dta" is identical to "clean_7791_AEJ" produced in step 1 - 
		** but retains ALL rows of choices even if the individual is accpeted to first choice
		** the full syntax for this file is found at the very end of this do-file
		
		use "$file\clean_7791_AEJstated.dta",clear
				bysort ProdAr PersonLopNr: gen nobs=_n
				bysort ProdAr PersonLopNr: egen maxchoice=max(choice) if Program!=. | Sint!=.
				tab maxchoice if nobs==1,m									// percentage stating a 6th choice 
				
	
****
*	- Section 2.3 we state that 
*		"only 60% of ninth-grade cohort appled to high-school"
*		"but by 1991 this had risen to 80%" 
****
			
		use "$file\step5_AEJ.dta",clear
			sum PersonLopNr if Fodar==1961			// No applied 1977 (born 1961)
			local app1961=r(N)				
			sum PersonLopNr if Fodar==1975			// No applied 1991 (born 1975)		
			local app1975=r(N)			
		
		drop _all
		odbc load, exec("select PersonLopNr, Fodelsear from dbo.LISA1990") connectionstring("DRIVER={SQL Server};SERVER={mq02\b};DATABASE={P0484_SU_SOFI_Utbildningsinnehall};Trusted_Connection={Yes}")
			destring ,replace force
			sum Fodelsear if Fodelsear==1961 
			local cohort1961=r(N)					// cohort size 1961 

		drop _all
		odbc load, exec("select PersonLopNr, Fodelsear from dbo.LISA1993") connectionstring("DRIVER={SQL Server};SERVER={mq02\b};DATABASE={P0484_SU_SOFI_Utbildningsinnehall};Trusted_Connection={Yes}")
			destring ,replace force
			sum Fodelsear if Fodelsear==1975 
			local cohort1975=r(N)					// cohort size 1975

			dis `app1961'/`cohort1961'				// percent of cohort aged 16 applied 1977 (rounding to even 5%)
			dis `app1975'/`cohort1975'				// percent of cohort aged 16 applied 1991 (rounding to even 5%)


		
****
*	- Section 2.3 we state that 
*		"first time applicants between 1991-1991 is 1,330,453..."
*		"..Roughly half of applicants have an academic first choice (611,837 obs)"
****
	
		use "$file\Sint_iter_AEJ.dta",clear			
			sort ProdAr PersonLopNr choice
			merge 1:1 ProdAr PersonLopNr choice using "$file\clean_7791_AEJ.dta", nogen			
			
				sort ProdAr Region Program
				merge m:1 ProdAr Region Program using "$file\cut_AEJ.dta",nogen		// Merges Sint_iter (step2) with clean_7791 (step1) and cut (step3)
				
				codebook PersonLopNr
				codebook PersonLopNr if (fst==59 | fst==43 | fst==44 | fst==10 | fst==51 | fst==28)
				
		
****
*	- Section 2.3 we state that 
*		"of which 326,211 apply to an oversubscribed major"
*		"and have an observed GPA within -1 and +1.5 of cutoff, leaving us with 250,522 observations"
*		"with 96% being accepted to their 1st or 2nd choice"
****
			
			
			use "$file\step5_AEJ.dta",clear
				gen drop=1 if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
						(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		// drop if Jmft is very low or very high
					gen competition=(diff_count>=3 & app_count>=25 & cut!=.)							// competition is defined cutoff is defined, at least 25 applied and at least 3 were not accpted)
					gen smp=1 if competition==1 & (abs(dist)<=151) & (abs(dist)>=1) & dist>-101 		// smp=1 if distance to cutoff is bewtween -1.01 and +1.51 excluding zeros
					
				sum PersonLopNr if drop==. & competition==1 & (fst==59 | fst==43 | fst==44 | fst==10 | fst==51 | fst==28)
				sum PersonLopNr if meanPS3739!=. & drop==. & smp==1 & sec!=. & fst!=sec & fst!=43 & sec!=43 & (fst==59 | fst==44 | fst==10 | fst==51 | fst==28)
			
	use "$file\competitive_AEJ.dta",clear
		
		gen firstorsecond=(Sval==1 | Sval==2)		// "Sval" states the rank or the choice the individual was accepted (see step1).
		
		tab firstorsecond if logantpctPS!=. 		
		 
			
			
****
*	- Section 2.3 we state that 
*		"Forty-five percent of individuals have a first choice academic major which is non-impacted"
*		"about 5% are no longer part of the Swedish population"
*		"a sample which includes 93% of all individuals in the population of which 87% are observed all three years"
****
		*FROM TABLE 2: 
		dis 194024/(194024+233034)				//Forty-five percent of individuals have a first choice academic major which is non-impacted
		
		sum PersonLopNr 
		local appliedat16=r(N)
		sum PersonLopNr if meanPS3739!=.
		local pop=r(N)
		dis 1-`pop'/`appliedat16'					// about 5% are no longer part of the Swedish population
		
		sum PersonLopNr if logantpctPS!=.
		local baseline=r(N)
		dis `baseline'/`pop'					// a sample whish includes 93% of all individuals in the population
		
		gen all3yrs=(antpctPS37==1 & antpctPS38==1 & antpctPS39==1) 		// The variable antpctPS+age is an indicator of above threshold earnings at "age"
		tab all3yrs if logantpctPS!=.										// "of which 87% are observed all three years"
		
		

		
****
*	- Footnote 13 we state that 
*		"This procedure drops just 0.3% of data"
****
			use "$file\Sint_iter_AEJ.dta",clear
			sort ProdAr PersonLopNr choice
			merge 1:1 ProdAr PersonLopNr choice using "$file\clean_7791_AEJ.dta", nogen			
			
				sort ProdAr Region Program
				merge m:1 ProdAr Region Program using "$file\cut_AEJ.dta",nogen		// Merges Sint_iter (step2) with clean_7791 (step1) and cut (step3)
				
				gen dropmiscoded=(flag1==1 | flag2==1)								// In step2, flags were created to indicate erroneous codings
				tab dropmiscoded 
	
		
****
*	- Footnote 14 we state that 
*		"The fraction of students with GPAs above the cutoff for the second best choices by first best major..."
*		"..are 95% (E) 97% (N) 92% (B) 96% (S) and 90% (H)"
****
	
		*do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\basedata\sec_choice_cutoff.do"	
		
		** The file "$file\clean_7791_2ndchoice.dta" is identical to "clean_7791_AEJ" produced in step 1 - 
		** but retains the row with the second choice also when the individual is accpeted to first choice
		** This is exploited below to attach second choice cut-offs for footnote 14 on page 12
		

use "$file\step5_AEJ.dta",clear
		drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
						(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		// drop if Jmft is very low or very high
		
		gen competition=(diff_count>=3 & app_count>=25 & cut!=.)
		
		*** drop if competitive cell within +1.5 and 1.0 of cutoff and exclude mixed borders (on cutoff), if sec choice is missing or the same as first choice
		gen smp=1 if diff_count>=3 & app_count>=25 & (abs(dist)<=151) & (abs(dist)>=1) & dist>-101 & sec!=. & fst!=sec & fst!=43 & sec!=43 
		replace cut=0 if cut==. | competition!=1 | cut<20
				
		
		**** histogram of how cutoff changes compared with its lagged value (if defined)

				*collapse (mean) cut competition academic, by(ProdAr Region fst)
				sort ProdAr Region fst
				
				collapse cut,by(ProdAr Region fst)
				rename fst Program
				merge 1:m ProdAr Region Program using "$file\clean_7791_2ndchoice.dta",nogen
				keep if PersonLopNr!=.
				sort ProdAr PersonLopNr choice 
				
				gen help=cut if Program==sec
				
				bysort ProdAr PersonLopNr: egen cutsecond=mean(help)
				keep if Program==sec
				rename Jmft Jmftsec
				bysort ProdAr PersonLopNr: gen nobs=_n
				keep if nobs==1
				keep ProdAr PersonLopNr cutsecond Jmftsec
				merge 1:1 ProdAr PersonLopNr using "$file\step5_AEJ.dta",nogen
				keep if dist!=.
				
				gen diffcut12=cut-cutsecond
				tab diffcut12  if logantpctPS!=.
				
				gen distsec=Jmftsec-cutsecond if Jmftsec>20 & Jmftsec<=54 & (sec==59 | sec==44 | sec==10 | sec==51 | sec==28)
				
				gen profilecutsec=1 if distsec>=0 & distsec!=.
				replace profilecutsec=2 if distsec<0
				
				label define post 1 "Jmft abv 2nd cutoff" 2 "Jmft below 2nd cutoff",replace
				label values profilecutsec post
				
				foreach x in 59 44 10 51 28 {
				if `x'==59 {
				    local tit = "Engineering"
				}
				if `x'==44 {
				    local tit = "Natural science"
				}
				if `x'==10 {
				    local tit = "Business"
				}
				if `x'==51 {
				    local tit = "Social science"
				}
				if `x'==28 {
				    local tit = "Humanities"
				}
				dis "`tit'"			
				tab profilecutsec if fst==`x'
	}
		
		
		
		
		
		
		
	
****
*	- Section 3.2 we state "with a cutoff in successive years, the threshold differs over 80% of the time" 
*
****
	use "$file\step5_AEJ.dta",clear
		gen competition=(diff_count>=3 & app_count>=25 & cut!=.)
		keep if Sint!=. & academic==1											// retain only competitive cells
		collapse (mean) cut competition academic, by(ProdAr Region fst)
				sort fst Region ProdAr
				
				gen lagcut=cut[_n-1] if (ProdAr-ProdAr[_n-1]==1) & Region==Region[_n-1] & fst==fst[_n-1]
				gen diff=cut-lagcut
				gen diff0=1 if (diff==0)													// variable taking value 1 if successive obs are identical
				replace diff0=0 if diff!=. & diff0==.
				
				tab diff0 if diff!=. & ProdAr!=1982 & ProdAr!=1985 & ProdAr!=1977  			// we disregard lags 1982 and 1985 as cutoff values were expected to change these years (see footnote 8)
																							// and 1977 which is the first observed year


****
*	- Footnote 17 we state "About 9% of individuals swithch from the major they are iniitially admitted to and completee another major..." 
*		".. Switching rates vary somewhat by major 11%(E) 13%(N) 6%(B) 9%(S) 15%(H)"
****

	use "$file\competitive_AEJ.dta",clear
		replace completed=51 if completed==52 		// social science (51) was also coded 52 from 1992
		replace completed=44 if completed==45		// natural science (44) was also coded 45 from 1992
		gen finished=1 if fst!=completed & (completed==10 | completed==28 | completed==43 | completed==44 | completed==45 | completed==51 | completed==52 | completed==59)
		replace finished=2 if fst!=completed & (completed==9 | completed==54 | completed==58)
		replace finished=2 if FstC==7 
		replace finished=3 if fst==completed | (completed!=. & finished==.) 
		
		label define switch 1 "Switcher acad" 2 "Switcher non-ac" 3 "Non-switcher" 
			label values finished switch
	
	tab finished if Sint==1 & logantpctPS!=.

	foreach x in 59 44 10 51 28 {
		
			preserve 
				keep if fst==`x' 
				if `x'==59 {
				    local tit = "Engineering"
				}
				if `x'==44 {
				    local tit = "Natural science"
				}
				if `x'==10 {
				    local tit = "Business"
				}
				if `x'==51 {
				    local tit = "Social science"
				}
				if `x'==28 {
				    local tit = "Humanities"
				}
			dis "`tit'"	
		dis "ACCEPTED - All above cutoff"
		tab finished if fst==`x' & Sint==1 & logantpctPS!=.
		restore
		}
	

****
*	- Section 3.2 we state that the share of dropouts among accepted is 5% 
*		"... small share applying to academic track switch to non-academic track (5%)"
****	
	
		gen dropout=(completed==0)
		tab dropout if logantpctPS!=. & Sint==1			// the share of dropouts among accepted is 5%
		
		gen switch=(FstC==6 | FstC==7) 					// completing non-academic==1
		tab switch if logantpctPS!=. & Sint==1 			// among accepted (Sint==1) a small share switch to non-academic track (5%)


		
****
*	- Section 3.2 we state "when we re-run our analysis excluding those who drop out or switch to the non-academic track..." 
*		"none of the reslting estimates are statistically different from the baseline" 
****

	**** these tests are run using GMM and take 3-8 hours
	**** see do-file "tests_section_3_2_AEJ.do"  [step 13 in "main.do"]
	
	
	
****
*	- Section 4.4 we state "students with a GPA near the average cutoff of 3.44 would be at the 20th percentile of the GPA distribution for academic majors..." 
* 		"... but the 72nd percentile for non-academic majors"
****

		use "$file\step5_AEJ.dta",clear
			drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
					(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		// drop outlier adjusted GPA (=Jmft)
				
		*Population percentile of academics
		centile Jmft if Fst<6,centile(10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30) // 3.44 would be at the 20th percentile of the GPA distribution for academic majors
		centile Jmft if (Fst==6 | Fst==7),centile(65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85)	
		
		
			
****
*	- Footnote 22 we state "Students with second-best non-academic majors have fathers and mothers with 10.9 and 10.6 years or schooling compared to 11.9 and 11.6 for those with second best academic choices. " 
****

			use "$file\competitive_AEJ.dta",clear
	
			gen acnac=(Fst<6 & Sec>=6 & Sec!=.)
			gen acac=(Fst<6 & Sec<6)
		
			sum utbFar utbMor if acnac==1 & logantpctPS!=. & (Jmft==34 | Jmft==35)
			sum utbFar utbMor if acac==1 & logantpctPS!=. & (Jmft==34 | Jmft==35)
			
			
			
			
			
****
*	- Section 4.5 we state that baseline estimates correlate with estimates based on earnings level (.97) and earnings rank (.95)
*	- The data file imported contains the estimates from this table - correlation weights as described in the paper footnote 23 (p25)
****
				
drop _all
import excel using "$file\coeffs_and_ses.xlsx",first

			drop if baseline==""
			gen n=_n
			*coeff=1 if coefficient, coeff=0 if std error
			gen coeff = mod(n,2)
			gen i=int((n+1)/2)
			drop n
			quietly reshape wide margin baseline quadratic halfwidth int1st2nd slope12 slope60 no8284 levels rank earn_occup earn_collegemajor earn_yrsofsch male female parent_highed parent_lowed age_2729 ols_nogpa ols_gpa klm, i(i) j(coeff)
			*Note: 0 at end of variable denotes estimate, 1 denotes standard error (do not confuse with the coeff variable used temporarily above)
			drop margin0
			rename margin1 margin

			*remove "*" from estimates and rename coefficient variables to remove trailing 1's
			foreach var of varlist baseline1 quadratic1 halfwidth1 int1st2nd1 slope121 slope601 no82841 levels1 rank1 earn_occup1 earn_collegemajor1 earn_yrsofsch1 male1 female1 parent_highed1 parent_lowed1 age_27291 ols_nogpa1 ols_gpa1 klm1 {
			  quietly replace `var'=subinstr(`var',"*","",.)
			  local new = substr("`var'",1,length("`var'")-1)
			  rename `var' `new'
			  }

			quietly destring *, replace

			*rename variables for se's to have trailing "_se" instead of trailing "0"
			foreach var of varlist baseline0 quadratic0 halfwidth0 int1st2nd0 slope120 slope600 no82840 levels0 rank0 earn_occup0 earn_collegemajor0 earn_yrsofsch0 male0 female0 parent_highed0 parent_lowed0 age_27290 ols_nogpa0 ols_gpa0 klm0 {
			  local new = substr("`var'",1,length("`var'")-1)+"_se"
			  rename `var' `new'
			  }
			  
			*create weights which equal 1 / (baseline_se^2 + `other'_se^2) for estimates baseline and `other'
			foreach var of varlist quadratic halfwidth int1st2nd slope12 slope60 no8284 levels rank earn_yrsofsch earn_collegemajor earn_occup age_2729 ols_nogpa ols_gpa klm {
			  local temp = "`var'"+"_se"
			  gen `var'_weight = 1/(baseline_se^2 + `temp'^2)
			  }  

			*create weights for male/female and high/low parent educ
			gen malefemale_weight = 1/(male_se^2 + female_se^2)
			gen parented_weight = 1/(parent_highed_se^2 + parent_lowed_se^2)

			*create weights based on inverse variance for Table 9
			gen baseline_weight=1/(baseline_se^2)

			*shorten labels for margin
			replace margin=subinstr(margin," vs. ","",.)

			***Mentioned in text when discussing Table 7: Correlations of baseline with earnings in levels and earnings rank
			foreach var of varlist levels rank {
			  local temp = "`var'"+"_weight"
			  pwcorr baseline `var' [weight=`temp']
			  }

			
			
			
****
*	- Footnote 23 we state that "the average earnings of this group (individuals choosing Engineering over Natural Science) if $54668" 
****
			
			sum meanPS3739 if fst==59 & sec==44 & logantpctPS!=.	// fst==44 stands for Engineering and sec==44 stands for Natural Science
			dis r(mean)/8.5

			
****
*	- Section 4.6 we state that estimates in last column of Table A9 (KLM estimates) are partly significantly different from our baseline estimates 
****

			**see separate do-file syntax
			
			
			
			exit
*** Extra syntax for footnote 8, "only 1.0 percent even list a sixth choice"
*** To calculate the number we copy the step 1 procedure but with all choices listed by individuals on their ranking list 
*** All of the remaining code in this program is for this note

		use "$file\clean_7791_AEJstated.dta",clear
				bysort ProdAr PersonLopNr: gen nobs=_n
				bysort ProdAr PersonLopNr: egen maxchoice=max(choice)
				tab maxchoice if nobs==1,m									
				

		forvalues x=1977/1991{

			if `x'<1985 {					// Registers with applicants slightly differ across years - syntaxes adjusted to set the data long and in choice-order
					drop _all
					odbc load, table("SokInt_`x'_Ny") connectionstring("DRIVER={SQL Server};SERVER={mq02\b};DATABASE={P0484_SU_SOFI_Utbildningsinnehall};Trusted_Connection={Yes}")
				rename (Kund_Lopnr_Personnr Ar Födår) (PersonLopNr ProdAr Fodar)
				destring ProdAr,replace
				replace ProdAr=`x'
			
			if ProdAr>=1977 & ProdAr<=1981 {
				forvalues val=1/6{
					drop TillVal`val'1 TillVal`val'2 Fill`val'1 Fill`val' KursVal`val' EstAmne`val'
					}
					drop HGSortKod SGSortkod KommunSortKod ForUtbSUN KursLangd1 KursLangd2 Nat Fill7 Fill8 Fill9 Fill12
				}
			
				if ProdAr==1982 {
					drop Avd Ptyp Box Avd Lopnr LKom HGYLan Skolkod SGyLan1 SGyLan2 SGyLan3 SGyLan4 SGyLan5 SGyLan6 
				}
				
				if ProdAr==1983 | ProdAr==1984 {
					drop Avd Ptyp Box Avd Lopnr HGYLan Skolkod SGyLan1 SGyLan2 SGyLan3 SGyLan4 SGyLan5 SGyLan6 LanKomFors Sektor1 Sektor2 Sektor3 Sektor4 Sektor5 Sektor6
				}
				destring,replace force
			}	
			
				
			if `x'>=1985 {
					use "$file\sokintdestring_1985_1991.dta", clear		// registers 1985-1991 come in one single file
					keep if ProdAr==`x'
			}	
			
		*** Delete duplicates (files are still wide)
			sort PersonLopNr 	
			bysort PersonLopNr: gen multiple=_N
			sum multiple if multiple>=2
			local n = r(N)/r(mean)
			dis "Multiple rows for same individual: `n' number of individuals dropped in year `x'"
			drop if multiple>=2 
			drop multiple
				*** Make file long
						
			if ProdAr>=1977 & ProdAr<=1981 {
				reshape long Linje SVGGrupp Gren Beh JfTal SlutBet KompGrp, i(PersonLopNr) j(choice)
				rename (BetMedvSlut SGRegion KurstidAr JfTal SlutInt PrelInt SVGGrupp Hkommun) (GRBet Sgyreg Kursl Jmft Sval Kval Svgg munic)
				replace Beh=1 if Beh!=0 & Beh!=.
			}
				
					*** KonP Alefu UppAns explicitly state bonus for gender, work experience or repeated application
					*** Between 1982 and 1985, also bonus for "1st choice (0.5)" and for "2nd choice (0.3)" 
					*** Jmft (from 1977) is the GPA including bonus points, and is the relevant measure for finding cutoff
					***	As a measure of ability, the variable GPA (without bonuses) is also retained (but contains some missing values)
					
			if ProdAr>=1982 & ProdAr<=1984 {
				reshape long Linje Gren SVGG KursL SGyReg Beh Grupp ALEFU UppAns KonP Jmft SInt, i(PersonLopNr) j(choice)
				rename (ILinje ISVGG SVGG SVal KVal KursL SGyReg ALEFU SInt) (LinjeInt SVGInt Svgg Sval Kval Kursl Sgyreg Alefu Sint)
				replace Beh=1 if Beh!=0 & Beh!=.
				gen munic=.
			}

					*** Skola refers to the compulsory school unit (not used)
			if ProdAr>=1985 {
				reshape long Linje Gren Sektor Svgg Kursl Sgyreg Skola SgyLan Beh Jmft Sint, i(PersonLopNr) j(choice)
				rename (ILinje Isvgg) (LinjeInt SVGInt)
				replace Beh=1 if Beh!=0 & Beh!=.
				gen munic=round(Lakofo/100)
					*drop cases where individuals are accepted to several programs
				bysort PersonLopNr (choice): egen sumSint=sum(Sint)
				keep if sumSint==1 | sumSint==0
			}	
		
		*From 1982 - there is an indicator of acceptance (Sint) for each choice 
		** This piece is to drop individuals where Sint = 1 to several programs (contradictory information)
		capture bysort PersonLopNr (choice): egen sumSint=sum(Sint)
		capture replace sumSint=2 if sumSint>1 & sumSint!=.
		capture sum sumSint if sumSint>1 & sumSint!=.
		capture local n = r(N)/r(mean)
		capture dis "Same ind accepted to several programs: `n' number of individuals dropped in year `x'"
		capture keep if sumSint==1 | sumSint==0
		
		*Note: we will replace Sint by using Sval - the choice (row) which was finally accepted. this is unambigous and avoids errors in the original Sint coding (e.g. often missing for first choice)
		capture drop Sint
		sort PersonLopNr choice
		gen Sint=1 if choice==Sval
		replace Sint=0 if choice<Sval
		replace Sint=. if choice>Sval
        
	   *If Sval==0, that means a person did not get into any of their stated choices; Sint=0 for these cases, because they were still in the competitions
		replace Sint=0 if Sval==0
		
***for the moment, choices ranked lower than Sval are retained (where the individual wasn't in the competition because they already got into something else)
***these rows are needed below to construct fst and sec best choices (sec best for ind accepted to first choice are otherwise lost)
		
						***************************************************************	
		*** GPA is constructed from GRBet, 1 to 5, but to avoid rounding problems lowest is set to 100 and highest 500 
				if ProdAr<=1987 {
					gen GPA=GRBet 
				}
				if ProdAr>=1988 {
					gen GPA=(gpa`x'*100)
					replace GPA=round(GPA,1)
					replace GPA=. if GPA==0
				}
			replace GPA=. if GPA<10 | GPA==99 
			replace GPA=GPA*10 if GPA<100 & ProdAr!=1984
			replace GPA=. if GPA>500
			replace GPA=. if GPA<100 & ProdAr==1984 
	
				*** From 1977 - applications were only considered on one decimal place 
				***	(SÖ FS 1977:108, punkt 6, sid 8)
				
				***		from 1977 also Jmft = GPA + bonus for gender, work experience or repeated application
						if ProdAr>=1977 {
							gen Jmftorig=Jmft
							replace Jmft=. if Jmft==99 | Jmft==999 
						}
				replace munic=. if munic>2584
				replace munic=. if munic<114
				bysort PersonLopNr: gen multiple=_N
				sum multiple
				local ntot = r(N)
				sum multiple if Beh!=1 | Linje==. | Sgyreg==. | PersonLopNr==.
				local n = r(N)
				drop multiple
				dis "Basic info or qualification not met: `n' of in total `ntot' rows dropped in year `x'"
				drop if Beh!=1 | Linje==. | Sgyreg==. | PersonLopNr==.
				gen sthlmregion=Sgyreg if Sgyreg<11
				replace Sgyreg=1 if Sgyreg<11
	
				sort PersonLopNr 
				
				save "$file\xtra1.dta", replace
				
				
				
*********************
*
*		Harmonize program codes across years LinjeInt --> LinjeDigitInt
*		Program codes differ in the original files (e.g. Business taking one value 10 one year, and some other value another year)
*
*********************
			
	
				**BELOW FOLLOWS HARMONIZATION OF PROGRAM CODES TO BE IDENTICAL 1971-1991
				
				use "$file\Linjecoding71_92.dta",clear
				keep if ProdAr==`x'
				sort ProdAr Linje
				keep ProdAr Linje ProgName LinjeDigit
				save "$file\lisatemp.dta",replace

				use "$file\xtra1.dta", clear
				sort ProdAr Linje
				merge m:1 ProdAr Linje using "$file\lisatemp.dta"
				drop _merge 
				save "$file\xtra1.dta", replace
						
				use "$file\Linjecoding71_92.dta",clear
				keep if ProdAr==`x'
				gen IntDigit=Linje
				rename (ProgName LinjeDigit) (ProgNameInt LinjeDigitInt)
				sort ProdAr IntDigit
				keep ProdAr IntDigit ProgNameInt LinjeDigitInt
				save "$file\lisatemp.dta",replace

				use "$file\xtra1.dta", clear
				gen IntDigit=LinjeInt
				sort ProdAr IntDigit
				merge m:1 ProdAr IntDigit using "$file\lisatemp.dta"
				drop _merge IntDigit 
				sort PersonLopNr choice
				save "$file\xtra1.dta", replace

							
*********************
*
*		Def 1st and 2nd choice - "fstbest" and "secbest" 
*		[Note 1: chioces>accepted remain so that 2nd best is visible
*		[Note 2: sample conditions include svgg==0 & Beh==1]
*				
*********************
			
		
***	Two cases of Svgg (Svgg!=0 stands for complementary, often local, courses of between a few weeks or several years, which are not nationwide upper secondary programs):

*** case 1: Svgg!=0 and Sint==0 in first choice, in the first "normal" choice (choice 2) Sint==1
	*-	2nd choices will be 1st best [automatically, bc fstbest is defined with Svgg!=0 deleted]

*** case 2: Svgg!=0 in first choice, Sint==1. 
	*- 	Ind is deleted (all choices)
	
		
		
	use "$file\xtra1.dta", clear
			***		To construct 1st best and 2nd best choices
			*** 	First, need to clean the data --> [Svgg==0 & Beh==1 & applicants directly from compulsory school)
					
		gen out_=((SVGInt!=0 | Svgg!=0) & choice==1 & Sval==1)
		bysort PersonLopNr choice: egen out=mean(out_)
		bysort PersonLopNr: gen multiple=_N if out==1
		sum multiple if out==1 
		local n = r(N)
		drop multiple
		dis "First choice is accepted and Svgg non-zero: `n' number of individuals dropped in year `x'"
		drop if out==1  
				
		sum PersonLopNr if (SVGInt!=0 | Svgg!=0)
		local n = r(N)
		dis "Row with Svgg non-zero: `n' number of rows dropped in year `x'"
		keep if SVGInt==0 & Svgg==0 	
		
		*** 	Condition that application is direct from compulsory school
		if ProdAr<=1981 {
			bysort PersonLopNr: gen multiple=_n if (ForUtb>8 | KompGrp!=11)
			sum multiple if multiple==1
			local n = r(N)
			sum multiple if multiple!=.
			local nrow = r(N)
			drop multiple 
			dis "Application not direct from compulsory school: `n' individuals (`nrow' rows) dropped in year `x'"
			keep if ForUtb<=8 & KompGrp==11
		}

		if ProdAr>=1982 {
			bysort PersonLopNr: gen multiple=_N if DirGR!=9
			sum multiple if multiple==1
			local n = r(N)
			sum multiple if multiple!=.
			local nrow = r(N)
			drop multiple 
			dis "Application not direct from compulsory school: `n' individuals (`nrow' rows) dropped in year `x'"
			keep if DirGR==9 		
		}

*skip this dropping command! we're looking for how many STATE a secoond choice
		
		*** 	drop if general requirements for acceptance are not fulfilled 
		/*
		sum PersonLopNr if Beh==0
		local n = r(N)
		dis "Row with unqualified: `n' rows dropped in year `x'"
		keep if Beh==1
		
		***		or if individual have two identical rows (same program in same region)
		***		this cleaing is only done for academic programs (10,28,43,44,51 or 59)
		
		bysort ProdAr Sgyreg LinjeDigit PersonLopNr (choice): egen countid=count(PersonLopNr) if (LinjeDigit==10 | LinjeDigit==28 | LinjeDigit==43 | LinjeDigit==44 | LinjeDigit==51 | LinjeDigit==59)
		*** countid never takes a value above 2
		bysort ProdAr Sgyreg LinjeDigit PersonLopNr (choice): egen sumsint=sum(Sint) if (LinjeDigit==10 | LinjeDigit==28 | LinjeDigit==43 | LinjeDigit==44 | LinjeDigit==51 | LinjeDigit==59)
		bysort ProdAr Sgyreg LinjeDigit PersonLopNr (choice): gen countidn=_n
		
		*** cases with countid=2 for the most part solve themselves as they are accepted to first or second choice and their doubles do not affect the definitions of first and second choices
		drop if countid==2 & sumsint==1 & Sint==0 						//	if one value is Sint==1 drop the one that is Sint==0
		drop if countid==2 & countidn==2 & (sumsint==0 | sumsint==2) 	// 	if both values are Sint==0, or both Sint==1, drop the second one
		
		drop countid sumsint countidn
			
			
			*** redefine choice# after the data has been cleaned
			***	set order without Svgg and without doubles (academic)
			
			sort ProdAr PersonLopNr choice
			bysort ProdAr PersonLopNr (choice): gen order=_n
			replace choice=order
			
*********************		*** GENERATING FIRST AND SECOND BEST	
*					*		*** 'egen' commands so that information is personspecific rather than choice/row specific
*   ABOUT CUTOFF	*		*** (allows us to eventually collaps the file one row for each individual) 
*					*
*	1st and 2nd		*		***		if 3rd choice is accepted, 2nd choice is fst choice
*		best		*		*** 	as a back up, fst1 and sec2 are defined as actual 1st and 2nd choice 
*					*
*********************
			
			**Sint is zero if ranked above accepted choice and missing if ranked below
			**Sval # is no longer a correct reflection of accepted choice since Svgg and other rows have been deleted
			*We need a variable to replace the original Sval (here gen "Svalone") when construction fst and sec best - reflecting the choice rank of accepted choice (Sint==1)
			
			gen Svalone_=choice if Sint==1
			bysort ProdAr PersonLopNr (choice): egen Svalone=mean(Svalone_)
			
			**Svalone is set to zero if missing or zero to avoid mistake if Svalone is zero
			**it means Svalone==0 or missing does not yield ANY fst and sec best choices for our margins
			replace Svalone=0 if Svalone==.
			
			*Below fst and sec reflect the firstbest and 2nd best option according to our definition here above
			*Also, fst1 and sec2 just reflect actual first ranked and actual second ranked choices, in case we want to use that (a sort of back-up)
			bysort ProdAr PersonLopNr (choice): gen fst1best=LinjeDigit if choice==1
			bysort ProdAr PersonLopNr (choice): gen sec2best=LinjeDigit if choice==2
			
			bysort ProdAr PersonLopNr (choice): gen Svaltwo=Svalone-1 if Svalone>=3 & Svalone!=.
		
			bysort ProdAr PersonLopNr (choice): gen fstbest=LinjeDigit if choice==1 & Svalone<=2
			bysort ProdAr PersonLopNr (choice): gen secbest=LinjeDigit if choice==2 & Svalone<=2
		
			bysort ProdAr PersonLopNr (choice): replace fstbest=LinjeDigit if choice==Svaltwo & Svalone>=3 & fstbest==.
			bysort ProdAr PersonLopNr (choice): replace secbest=LinjeDigit if choice==Svalone & Svalone>=3 & secbest==.
			
			foreach v in fst sec fst1 sec2  {
				bysort ProdAr PersonLopNr (choice): egen `v'=mean(`v'best)
			} 
	
				drop out_ out Svalone_ Svalone Svaltwo fst1best sec2best fstbest secbest 
		
		***HERE - CHOICES RANKED BELOW THE ACCEPTED CHOICE ARE DELETED
			keep if Sint!=.		
		*/		
		save "$file\xtra1.dta", replace
		
				*****************
				***
				***DATA IS MERGED WITH LISA POPULATION DATA (Gender (new) and birthyear (to confirm - slight changes sometimes))

drop _all
odbc load, table("fodelsear") connectionstring("DRIVER={SQL Server};SERVER={mq02\b};DATABASE={P0484_SU_SOFI_Utbildningsinnehall};Trusted_Connection={Yes}")
destring kon fodelsear,replace
rename (personnr_lopnr kon fodelsear) (PersonLopNr Kon Fodar)
keep PersonLopNr Kon Fodar
save "$file\xtra_temp.dta",replace


	use "$file\xtra1.dta", clear
	drop Fodar 
	sort PersonLopNr
	merge m:1 PersonLopNr using "$file\xtra_temp.dta",nogen
	
	drop if Sgyreg==.
	gen age=ProdAr-Fodar
	keep if age<=18
		
	keep PersonLopNr age Kon GRBet GPA Jmft Sint Sgyreg Linje LinjeDigit ProdAr Fodar Sval LinjeDigitInt choice sthlmregion
	rename (Sgyreg LinjeDigit LinjeDigitInt) (Region Program Lint)
	
	tab ProdAr,m
	
	if ProdAr==1977 {
	save "$file\clean_7791_AEJstated.dta", replace
	}
	if ProdAr>=1978 {
	append using "$file\clean_7791_AEJstated.dta"
	tab ProdAr,m
	save "$file\clean_7791_AEJstated.dta", replace
	}
}
		
			
			
			*/

	
	
	
	
	*** drop if competitive cell within +1.5 and 1.0 of cutoff and exclude mixed borders (on cutoff), if sec choice is missing or the same as first choice
		gen smp=1 if diff_count>=3 & app_count>=25 & (abs(dist)<=151) & (abs(dist)>=1) & dist>-101 & sec!=. & fst!=sec & fst!=43 & sec!=43 
		








		forvalues x=1983/1991{

			if `x'<1985 {					// Registers with applicants slightly differ across years - syntaxes adjusted to set the data long and in choice-order
					drop _all
					odbc load, table("SokInt_`x'_Ny") connectionstring("DRIVER={SQL Server};SERVER={mq02\b};DATABASE={P0484_SU_SOFI_Utbildningsinnehall};Trusted_Connection={Yes}")
				rename (Kund_Lopnr_Personnr Ar Födår) (PersonLopNr ProdAr Fodar)
				destring ProdAr Beh*,replace force
				replace ProdAr=`x'
			
			if ProdAr>=1977 & ProdAr<=1981 {
				forvalues val=1/6{
					drop TillVal`val'1 TillVal`val'2 Fill`val'1 Fill`val' KursVal`val' EstAmne`val'
					}
					drop HGSortKod SGSortkod KommunSortKod ForUtbSUN KursLangd1 KursLangd2 Nat Fill7 Fill8 Fill9 Fill12
				}
			
				if ProdAr==1982 {
					drop Avd Ptyp Box Avd Lopnr LKom HGYLan Skolkod SGyLan1 SGyLan2 SGyLan3 SGyLan4 SGyLan5 SGyLan6 
				}
				
				if ProdAr==1983 | ProdAr==1984 {
					drop Avd Ptyp Box Avd Lopnr HGYLan Skolkod SGyLan1 SGyLan2 SGyLan3 SGyLan4 SGyLan5 SGyLan6 LanKomFors Sektor1 Sektor2 Sektor3 Sektor4 Sektor5 Sektor6
				}
				*destring,replace force
			}	
			
				
			if `x'>=1985 {
					use "$file\sokintdestring_1985_1991.dta", clear		// registers 1985-1991 come in one single file
					keep if ProdAr==`x'
			}	
			
					
		*** Delete duplicates (files are still wide)
			sort PersonLopNr 	
			bysort PersonLopNr: gen multiple=_N
			sum multiple if multiple>=2
			local n = r(N)/r(mean)
			dis "Multiple rows for same individual: `n' number of individuals dropped in year `x'"
			drop if multiple>=2 
			drop multiple
				
			if ProdAr>=1977 & ProdAr<=1981 {
				reshape long Linje SVGGrupp Gren Beh JfTal SlutBet KompGrp, i(PersonLopNr) j(choice)
				rename (BetMedvSlut SGRegion KurstidAr JfTal SlutInt PrelInt SVGGrupp Hkommun) (GRBet Sgyreg Kursl Jmft Sval Kval Svgg munic)
				replace Beh=1 if Beh!=0 & Beh!=.
			}
				
					*** KonP Alefu UppAns explicitly state bonus for gender, work experience or repeated application
					*** Between 1982 and 1985, also bonus for "1st choice (0.5)" and for "2nd choice (0.3)" 
					*** Jmft (from 1977) is the GPA including bonus points, and is the relevant measure for finding cutoff
					***	As a measure of ability, the variable GPA (without bonuses) is also retained (but contains some missing values)
					
			if ProdAr>=1982 & ProdAr<=1984 {
				reshape long Linje Gren SVGG KursL SGyReg Beh Grupp ALEFU UppAns KonP Jmft SInt, i(PersonLopNr) j(choice)
				rename (ILinje ISVGG SVGG SVal KVal KursL SGyReg ALEFU SInt) (LinjeInt SVGInt Svgg Sval Kval Kursl Sgyreg Alefu Sint)
				destring Beh,replace force
				replace Beh=1 if Beh!=0 & Beh!=.
}

			*** Skola refers to the compulsory school unit (not used)
			if ProdAr>=1985 {
				reshape long Linje Gren Sektor Svgg Kursl Sgyreg Skola SgyLan Beh Jmft Sint, i(PersonLopNr) j(choice)
				rename (ILinje Isvgg) (LinjeInt SVGInt)
				replace Beh=1 if Beh!=0 & Beh!=.
					*drop cases where individuals are accepted to several programs
				bysort PersonLopNr (choice): egen sumSint=sum(Sint)
				keep if sumSint==1 | sumSint==0
				keep PersonLopNr ProdAr choice 
			}	
		
		if ProdAr==1977 {
	save "$file\choice_number7791.dta", replace
	}
	if ProdAr>=1978 {
	append using "$file\choice_number7791.dta"
	tab ProdAr,m
	save "$file\choice_number7791.dta", replace
	}
}
	
	exit		
	
	