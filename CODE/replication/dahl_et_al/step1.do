clear
capture log close

log using "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\output1.log",replace

set more off, permanently		

global file "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"


***		This step compiles applicants ("sökande") to upper secondary school from yearly registers 1977-1991 into a single file...
***		... where redundant applications (e.g. second choice if accepted to first choice) are deleted from the files
***		The file will in step 2 and 3 to determine the exact GPA cutoffs of each Program/Region/Year. 


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

		
		*** 	drop if general requirements for acceptance are not fulfilled 
		
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
		
	keep PersonLopNr age Kon GRBet GPA Jmft Sint Sgyreg Linje LinjeDigit ProdAr Fodar fst sec fst1 sec2 Sval LinjeDigitInt choice sthlmregion
	rename (Sgyreg LinjeDigit LinjeDigitInt) (Region Program Lint)
	
	tab ProdAr,m
	
	if ProdAr==1977 {
	save "$file\clean_7791_AEJ.dta", replace
	}
	if ProdAr>=1978 {
	append using "$file\clean_7791_AEJ.dta"
	tab ProdAr,m
	save "$file\clean_7791_AEJ.dta", replace
	}
}
		*do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\step2.do"
	
