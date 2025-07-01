												clear
capture log close

log using "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\log_figures.log",replace

set more off, permanently		

global file "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"



	***************************************************************
	
	
use "$file\step5_AEJ.dta",clear
		drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
						(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		// drop if Jmft is very low or very high

***FIGURE 1 - mean GPA and mean log earnings of completers from the seven different categories

		preserve
			keep if GPA!=.   		// the sample is conditioned to be the same as in Figure 1
			replace GPA=GPA/100
			sum GPA 
			local ngpa=trim("`: di %11.0gc [r(N)]'")
			sum log3739PS 
			local nlog=trim("`: di %11.0gc [r(N)]'")
			collapse GPA  log3739PS,by(FstC)
			gen FstC1 = FstC-0.2
			gen FstC2 = FstC+0.2
			la var GPA "GPA"
			la var  log3739PS "Log earnings"
			la var FstC1 " "
			la var FstC2 " "
			twoway (bar GPA FstC1,fcol(gs5)lc(gs0)barw(0.4)yaxis(1)ylabel(2.5(.5)4.5)) ///
				(bar  log3739PS FstC2,fc(gs12)lc(gs12)barw(0.4)yaxis(2)),ytitle(GPA,axis(1)) ytitle(Log earnings,axis(2)) ylabel(5.2(.2)6,axis(2)) ///
				xlabel(1 "Engineering" 2 `""Natural" "Science""' 3 "Business" 4 `""Social" "Science""' ///
				5 "Humanities" 6 `""Non-acad." "General""' 7 `""Non-acad." "Vocational""', labsize(small)) ///
				graphregion(color(white)) note(" " "Applicants 1977-1991: Ngpa = `ngpa' & Nlog = `nlog'.") 
				graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig1.wmf",replace 
		restore		
		
		
**** FIGURE 2 - double histogram of individuals' Jmft and the cutoffs 

		gen competition=(diff_count>=3 & app_count>=25 & cut!=.)
		keep if Sint!=. & academic==1
		*** drop if competitive cell within +1.5 and 1.0 of cutoff and exclude mixed borders (on cutoff), if sec choice is missing or the same as first choice
		gen smp=1 if diff_count>=3 & app_count>=25 & (abs(dist)<=151) & (abs(dist)>=1) & dist>-101 & sec!=. & fst!=sec & fst!=43 & sec!=43 
		
	preserve
		keep if logantpctPS!=. & smp==1
		egen tag=tag(ProdAr Region fst)
				gen help1=cut/10
				gen help2=Jmft/10
				replace help2=round(help2,.1)
				
			sum cut if tag==1 
				local n=trim("`: di %11.0gc [r(N)]'")
			sum Jmft 
				local nind=trim("`: di %11.0gc [r(N)]'")
			twoway (hist help2 if help2>2,frac discr col(gs12)) ///
				(hist help1 if help1>2,discr frac fcolor(none)lcol(gs2) ///
					graphregion(color(white))),ylabel(0(.05).20,nogrid) ///
					legend(region(style(none))) note(" " "Applicants 1977-1991: N(cells) = `nind'(`n').") legend(order (1 "Individual GPA" 2 "Cutoff GPA"))  xtitle("GPA") 	
					graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig2.wmf",replace 
	restore			

**** FIGURE 3 - histogram of how cutoff changes compared with its lagged value (if defined)

				
				collapse (mean) cut competition academic, by(ProdAr Region fst)
				sort fst Region ProdAr
				
				gen lagcut=cut[_n-1] if (ProdAr-ProdAr[_n-1]==1) & Region==Region[_n-1] & fst==fst[_n-1]
				gen diff=cut-lagcut
				gen ettor=1
				bysort cut lagcut: egen weight=count(ettor)
				
			preserve 
				sum ProdAr 
				local ntot=trim("`: di %11.0gc [r(N)]'")
				tab ProdAr
				keep if ProdAr!=1982 & ProdAr!=1985 & ProdAr!=1977 // we disregard lags 1982 and 1985 - the first year of new regimes
				sum ProdAr if ProdAr!=1977 			// and 1977 which is the first observed year
				local n=trim("`: di %11.0gc [r(N)]'")
				sum cut if lagcut!=.
				local nlag=trim("`: di %11.0gc [r(N)]'")
				gen help=diff/10
				twoway (hist help if abs(help)<1.1,disc frac fcol(none) lcol(gs2)graphregion(color(white))), ytitle("Fraction") ///
				ylabel(0(.05).20,nogrid)xtit(First difference of cutoff GPA) 
				graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig3.wmf",replace 
			restore
	
*** FIGURE 4 - Sharp cutoff 
	
	use "$file\competitive_AEJ.dta", clear
				
		forvalues x=-95(10)145 {		
				replace dist=dist-5 if dist==`x'
			}
		keep if logantpctPS!=.
		
		egen tag_smp=tag(ProdAr Region Program)
				sum tag_smp if tag_smp==1
				local tcells=trim("`: di %11.0gc [r(N)]'")
				sum Sint 
				local tot=trim("`: di %11.0gc [r(N)]'")
		collapse (mean) Sint fin, by(dist)
		replace dist=-75 if dist<=-60 
		replace dist=dist/100
		local margin="Sample in competitive cells."
		local var="Share accepted to preferred choice."
								twoway (scatter Sint dist if dist<0,msymbol(o)msize(small)mc(black)) ///
								(scatter Sint dist if dist>0,msymbol(o)msize(small)mc(black)graphregion(color(white))) , ///
								ytitle(Share accepted) xtitle(Distance to cutoff) xline(0,lwidth(thin)lc(black)lp(dash)) legend(off) note("N (cells): `tot' (`tcells').")
		graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig4.wmf",replace 

***** FIGURE 5, PANEL A AND PANEL B (Figures are generated in a loop where the outcomes are "fin" (completd) and "logantpctPS" (log earnings))

	use "$file\competitive_AEJ.dta", clear
		
		gen wgt151=max(0,151-abs(dist))
		
		forvalues x=145(-10)-95 {							// set rv to 10-decimal places
			replace dist=dist-5 if dist==`x' & dist<0
			replace dist=dist+5 if dist==`x' & dist>0
		}
		gen tn=(fst==59 & sec==44)
		
foreach sample in tn { // tn = engineering first and natural science second: te = engingeering first and business second 
	foreach var in fin logantpctPS { // fin = 1 if program completed is the same as program accepted: logantpctPS = log earnings if abv 35th percentile
		preserve
		keep if tn==1 & logantpctPS!=. 
		replace dist=-75 if dist<=-60 
		replace dist=dist/100
		
			reg `var' Sint dist dist2 [pw=wgt151],robust 
			predict estim,xb
			predict err,stdp
			gen lb=estim-1.96*err
			gen ub=estim+1.96*err
			local tot=trim("`: di %11.0gc [e(N)]'")
		
		** local value of # cells for note in figure			
			egen tag_smp=tag(ProdAr Region Program)
			sum tag_smp if tag_smp==1
			local tcells=trim("`: di %11.0gc [r(N)]'")
			
		qui	bysort dist: egen ndot=count(dist)
		
		collapse (mean) fin Sint logantpctPS estim ub lb ndot tn, by(dist)
		
					la var fin "Completed 1st choice"
					la var logantpctPS "Log annual earnings"
					la var tn "Engineering vs. Natural science "
					
					if "`var'"=="fin" {
						local scale = "0(.2)1"
						local v = "a"
					}
					if "`var'"=="logantpctPS" {
						local scale = "5.8(.1)6.2"
						local v = "b"
					}
						local margin: var la `sample'
						local text: var la `var'
					
								twoway (scatter `var' dist if dist<0,msize(small)msymbol(o)mc(black)) (scatter `var' dist if dist>=0,msize(small)msymbol(o)mc(black)graphregion(color(white))) ///
								(connected estim dist if dist<=-0.05,lc(black)lw(thin)msym(i)mfcolor(black)mcol(black)) ///
								(connected estim dist if dist>=0.05,lc(black)lw(thin)msym(i)mfcolor(black)mcol(black)graphregion(color(white))) , ///
								note(" " "Number of individuals: `tot'") title(`margin'`gender') subtitle(" ") t2(`digital')  ///
								ytitle(`text')ylab(`scale',nogrid) xtitle(Distance to cutoff) xline(0,lwidth(thin)) legend(off)
								graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig5`v'.wmf",replace 
			restore
							}	
						}								
								
								
								
***FIGURE 6 CAN BE READ FROM TABLE 5
	use "$file\colors.dta", clear
		

gen Type=.
replace Type=1 if Prog=="E"
replace Type=2 if Prog=="N"
replace Type=3 if Prog=="B"
replace Type=4 if Prog=="S"
replace Type=5 if Prog=="H"
replace Type=6 if Prog=="G"
replace Type=7 if Prog=="V"

label define second 1 "Engineering" 2 "Natural Science" 3 "Business" 4 "Social science" 5 "Humanities" 6 "General non-ac." 7 "Vocational non-ac"
label values Type second
gen type=Type

foreach x in E N B S H {
separate `x', by(`x' < 0)
}

replace type=Type-1
la var type " "
twoway (bar E type if Prog!="E",barw(0.5)bcolor(navy)graphregion(color(white))), tit("Engineering") ytit("Earnings return" " ") ylab(,nogrid)xtit(" " "Next best field") ///
xlabel(1 `""Natural" "Science**""' 2 "Business" 3 `""Social" "Science**""' 4 "Humanities*" 5 `""Non-acad." "General""' 6 `""Non-acad." "Vocational""',labsize(small))legend(off)
graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig6a.wmf",replace 

replace type=Type
replace type=. if Prog=="N"
replace type=Type-1 if Type>2
twoway (bar N type if Prog=="V",barw(0.5)bcolor(red*1.5)) (bar N type if Prog!="N" & Prog!="V",barw(0.5)bcolor(navy)graphregion(color(white))), ///
tit("Natural Science") ytit("Earnings return" " ") ylab(,nogrid)xtit(" " "Next best field") ///
xlabel(1 "Engineering" 2 "Business**" 3 `""Social" "Science**""' 4 "Humanities" 5 `""Non-acad." "General""' 6 `""Non-acad." "Vocational""',labsize(small))legend(off)
graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig6b.wmf",replace 

replace type=Type
replace type=. if Prog=="B"
replace type=Type-1 if Type>3
twoway (bar B type if Prog=="V" | Prog=="G" | Prog=="H",barw(0.5)bcolor(red*1.5)) (bar B type if Prog!="B" & Prog!="V" & Prog!="G" & Prog!="H",barw(0.5)bcolor(navy)graphregion(color(white))), ///
tit("Business") ytit("Earnings return" " ") ylab(,nogrid)xtit(" " "Next best field") ///
xlabel(1 "Engineering**" 2 `""Natural" "Science***""' 3 `""Social" "Science***""' 4 "Humanities" 5 `""Non-acad." "General""' 6 `""Non-acad." "Vocational""',labsize(small))legend(off)
graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig6c.wmf",replace 

replace type=Type
replace type=. if Prog=="S"
replace type=Type-1 if Type>4
twoway (bar S type if Prog=="N",barw(0.5)bcolor(navy)) (bar S type if Prog!="S" & Prog!="N",barw(0.5)bcolor(red*1.5)graphregion(color(white))), ///
tit("Social Science") ytit("Earnings return" " ") ylab(,nogrid)xtit(" " "Next best field") ///
xlabel(1 "Engineering***" 2 `""Natural" "Science""' 3 "Business***" 4 "Humanities*" 5 `""Non-acad." "General***""' 6 `""Non-acad." "Vocational***""',labsize(small))legend(off)
graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig6d.wmf",replace 

replace type=Type
replace type=. if Prog=="H"
replace type=Type-1 if Type>5
twoway (bar H type if Prog=="E",barw(0.5)bcolor(navy)) (bar H type if Prog!="H" & Prog!="E",barw(0.5)bcolor(red*1.5)graphregion(color(white))), ///
tit("Humanities") ytit("Earnings return" " ") ylab(,nogrid)xtit(" " "Next best field") ///
xlabel(1 "Engineering" 2 `""Natural" "Science""' 3 "Business***" 4 `""Social" "Science**""' 5 `""Non-acad." "General***""' 6 `""Non-acad." "Vocational***""',labsize(small))legend(off)
graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig6e.wmf",replace 


***FIGURE 7 CONVERTS AN EXCEL-FILE OF ESTIMATES INTO ILLUSTRATIONS OF ESTIMATED COEFFICIENTS								

***Requires coeffs_and_ses.xlsx
***This Excel file contains the necessary coefficients and standard errors

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

				***Figure 7a
				*Graph of baseline estimates against years of schooling estimates
				capture drop hat pos
				replace margin=upper(margin)
				qui reg baseline earn_yrsofsch [weight=earn_yrsofsch_weight]
				predict hat
				gen pos=3
				replace pos=9 if baseline > hat
				replace pos=3 if margin=="BE" | margin=="ES" | margin=="NE"
				replace pos=9 if margin=="SG"
				replace pos=9 if margin==""
				graph twoway ( scatter baseline earn_yrsofsch, mlabel(margin) mlabv(pos) mlabcolor(black) msize(small) msymbol(o) mcolor(black)) || ///
				lfit baseline earn_yrsofsch [weight=earn_yrsofsch_weight],lw(thin) lc(black) title(" ") ytitle(Baseline estimates) xtitle(Years of schooling estimates) graphregion(color(white)) legend(off) ylab(,nogrid)
				graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig7a.wmf",replace 
				
				***Figure 7b
				*Graph of baseline estimates against college major estimates
				capture drop hat pos
				replace margin=upper(margin)
				qui reg baseline earn_collegemajor [weight=earn_collegemajor_weight]
				predict hat
				gen pos=3
				replace pos=9 if baseline > hat
				replace pos=3 if margin=="BG"
				replace pos=9 if margin==""
				graph twoway ( scatter baseline earn_collegemajor, mlabel(margin) mlabv(pos) mlabcolor(black) msize(small) msymbol(o) mcolor(black) yscale(range(-.12,.1)) ///
				ylab(-.1(.05).1,nogrid) xscale(range(-.12,.13)) xlab(-.1(.05).13,nogrid) ) || lfit baseline earn_collegemajor [weight=earn_collegemajor_weight] ,  ///
				lw(thin) lc(black) title(" ") ytitle(Baseline estimates) xtitle(College major estimates) graphregion(color(white)) legend(off) ylab(,nogrid)
				graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig7b.wmf",replace 
				
				***Figure 7c
				*Graph of baseline estimates against occupation estimates
				capture drop hat pos
				replace margin=upper(margin)
				qui reg baseline earn_occup [weight=earn_occup_weight]
				predict hat
				gen pos=3
				replace pos=9 if baseline > hat
				replace pos=3 if margin=="SG" | margin=="NB"
				replace pos=9 if margin=="HN"
				graph twoway ( scatter baseline earn_occup, mlabel(margin) mlabv(pos) mlabcolor(black) msize(small) msymbol(o) mcolor(black) ylab(-.1(.05).1,nogrid) ///
				yscale(range(-.13,.05)) xlab(-.05(.05).05,nogrid) xscale(range(-.09,.07)) ) || lfit baseline earn_occup [weight=earn_occup_weight], ///
				lw(thin) lc(black) title(" ") ytitle(Baseline estimates) xtitle(Occupation estimates) graphregion(color(white)) legend(off) ylab(,nogrid)
				graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig7c.wmf",replace 
				
	

	
***FIGURE A1 - number of admits to the seven differnt categories
					
			use "$file\step5_AEJ.dta",clear
					drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
									(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		// drop if Jmft is very low or very high
		preserve
		sum GPA		
				local nind=trim("`: di %11.0gc [r(N)]'")
		keep if GPA!=.   		// we limit the sample to be the same as in Figure 2, where we condition that GPA is non-missing   
		la var Fst " "
		collapse (count) PersonLopNr,by(Fst)
		twoway (bar PersonLopNr Fst,fcol(gs5)lc(gs0)barw(0.6)graphregion(color(white))) , ylab(0(200000)600000) ///
			ytit("Number of admits" " ") xlabel(1 "Engineering" 2 `""Natural" "Science""' 3 "Business" 4 `""Social" "Science""' ///
			5 "Humanities" 6 `""Non-acad." "General""' 7 `""Non-acad." "Vocational""', labsize(small)) note(" " "Applicants 1977-1991: N = `nind'.") 
			graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig_A1.wmf",replace 
		restore	

		
		
***Figure A2 - comparing GPA and log earnings for individuals in oversubscripbed and non-impacted cells

		use "$file\step5_AEJ.dta",clear
		drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
							(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		// drop if Jmft is very low or very high
			keep if fst==10 | fst==28 | fst==44 | fst==51 | fst==59											// keep only academic programs
			keep if sec!=. & fst!=sec & sec!=43 																		// drop if second choice is science/engineering (=43), missing, or same as first choice
		
			gen main=(diff_count>=3 & app_count>=25 & (abs(dist)<=151) & (abs(dist)>=1) & dist>-101 & logantpctPS!=.)		// indicator for being part of our main sample
			bysort ProdAr Region fst: egen help=max(main) if main!=.
			gen maincell=1 if help==1																						// indicator that cell is represented in our main sample
			bysort ProdAr Region fst: egen help1=min(main) if main!=.
			replace maincell=0 if maincell==. & help1==0 
			gen noncomp=(main==0 & maincell==0 & logantpctPS!=. & Sint!=.)
			
	preserve
			gen help2=Jmft/10
			replace help2=round(help2,.1)
			sum help2 if main==1
				local nmain=trim("`: di %11.0gc [r(N)]'")
			sum help2 if noncomp==1
				local nind=trim("`: di %11.0gc [r(N)]'")
			twoway (hist help2 if help2>2 & main==1,frac discr col(gs12)) ///
				(hist help2 if help2>2 & noncomp==1,discr frac fcolor(none)lcol(gs2) ///
					graphregion(color(white))),ylabel(0(.05).15,nogrid) note("N baseline = `nmain'" "N non-impacted = `nind'.") ///
					legend(region(style(none))) legend(order (1 "Oversubscribed" 2 "Non-impacted"))  xtitle("GPA") 
					graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig_A2a.wmf",replace 
	restore			
			
	preserve
				gen help2=logantpctPS
				replace help2=round(help2,.1)
			sum help2 if main==1
				local nmain=trim("`: di %11.0gc [r(N)]'")
			sum help2 if noncomp==1
				local nind=trim("`: di %11.0gc [r(N)]'")
			twoway (hist help2 if help2>2 & help2<8 & main==1,frac discr col(gs12)) ///
				(hist help2 if help2>2 & help2<8 & noncomp==1,discr frac fcolor(none)lcol(gs2) ///
					graphregion(color(white))),ylabel(0(.05).15,nogrid) note("N baseline = `nmain'" "N non-impacted = `nind'.") ///
					legend(region(style(none))) legend(order (1 "Oversubscribed" 2 "Non-impacted"))  xtitle("Log earnings") 
					graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig_A2b.wmf",replace 
	restore			
	
	
***FIGURE A3 - COMPARING CUTOFF DISTRIBUTION BY PROGRAM 
		
use "$file\step5_AEJ.dta",clear
		drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
						(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		// drop if Jmft is very low or very high
		
		*** drop if competitive cell within +1.5 and 1.0 of cutoff and exclude mixed borders (on cutoff), if sec choice is missing or the same as first choice
		gen smp=1 if diff_count>=3 & app_count>=25 & (abs(dist)<=151) & (abs(dist)>=1) & dist>-101 & sec!=. & fst!=sec & fst!=43 & sec!=43 
		keep if logantpctPS!=. & smp==1 
		egen tag=tag(ProdAr Region fst)
				replace cut=cut/10
		keep if tag==1
		keep Fst cut 
		
		
		twoway (kdensity cut if Fst==1,lc(navy)lw(thin)bw(0.2)) (kdensity cut if Fst==2,lc(dkgreen)lw(thin)bw(0.2)) ///
		 (kdensity cut if Fst==3,lc(cranberry)lw(thin)bw(0.2))  (kdensity cut if Fst==4,lc(purple)lw(thin)bw(0.2))  ///
		 (kdensity cut if Fst==5,lc(dkorange)lw(thin)bw(0.2)graphregion(color(white))) , tit(" ") xtit("Cutoff GPA")ytit("Density")ylab(0(.5)1,nogrid) ///
		 legend(order (1 "Engineering" 2 "Natural Science" 3 "Business" 4 "Social Science" 5 "Humanities")size(small)region(style(none))colgap(5) cols(3))
		 graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig_A3.wmf",replace 
		
	
***FIGURE A4 -**SHARE OF TIMES IN A REGION THAT CUTOFF OF PRG X EXCEEDS THE CUTOFF OF PRG Y

use "$file\step5_AEJ.dta",clear
		drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
						(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		// drop if Jmft is very low or very high
		
		gen competition=(diff_count>=3 & app_count>=25 & cut!=.)
		keep if Sint!=. & academic==1
		*** drop if competitive cell within +1.5 and 1.0 of cutoff and exclude mixed borders (on cutoff), if sec choice is missing or the same as first choice
		gen smp=1 if diff_count>=3 & app_count>=25 & (abs(dist)<=151) & (abs(dist)>=1) & dist>-101 & sec!=. & fst!=sec & fst!=43 & sec!=43 
		
				collapse (mean) cut competition academic, by(ProdAr Region fst)
				sort ProdAr Region fst
				replace cut=0 if cut==.

				bysort ProdAr Region (fst): gen cutE=cut if fst==59
				bysort ProdAr Region (fst): gen cutN=cut if fst==44
				bysort ProdAr Region (fst): gen cutB=cut if fst==10
				bysort ProdAr Region (fst): gen cutS=cut if fst==51
				bysort ProdAr Region (fst): gen cutH=cut if fst==28
				
				collapse cutE cutN cutB cutS cutH ,by(ProdAr Region)
		
				gen cutdiffEN=cutE-cutN if cutE!=0 | cutN!=0
				gen cutdiffEB=cutE-cutB if cutE!=0 | cutB!=0
				gen cutdiffES=cutE-cutS if cutE!=0 | cutS!=0
				gen cutdiffEH=cutE-cutH if cutE!=0 | cutH!=0
				gen cutdiffNB=cutN-cutB if cutN!=0 | cutB!=0
				gen cutdiffNS=cutN-cutS if cutN!=0 | cutS!=0
				gen cutdiffNH=cutN-cutH if cutN!=0 | cutH!=0
				gen cutdiffBS=cutB-cutS if cutB!=0 | cutS!=0
				gen cutdiffBH=cutB-cutH if cutB!=0 | cutH!=0
				gen cutdiffSH=cutS-cutH if cutS!=0 | cutH!=0
				
				egen tag=tag(Region)
				
				foreach x in E N B S H {
					gen help`x'=1 if cut`x'>0 & cut`x'!=.
					bysort Region: egen number`x'=count(cut`x')
					bysort Region: egen number`x'1=count(help`x')
					bysort Region: gen oversub_share`x'=(number`x'1/number`x') if tag==1
				}
				
				foreach x in EN EB ES EH NB NS NH BS BH SH {
					gen koll`x'1=1 if cutdiff`x'>0 & cutdiff`x'!=.
					
					bysort Region: egen antal`x'=count(cutdiff`x')
					bysort Region: egen antal`x'1=count(koll`x'1)
					bysort Region: gen first`x'=(antal`x'1/antal`x') if tag==1
				}
				
		*** HERE STARTS WHAT GIVES THE OUTPUT
		
		foreach x in BS EN EB ES EH NB NS NH BS BH SH { // 
					if "`x'"=="EN" {
						local f = "E"
						local s = "N"
						local tit = "Engineering vs. Natural Science"
					}
					if "`x'"=="EB" {
						local f = "E"
						local s = "B"
						local tit = "Engineering vs. Business"
					}
					if "`x'"=="ES" {
						local f = "E"
						local s = "S"
						local tit = "Engineering vs. Social Science"
					}
					if "`x'"=="EH" {
						local f = "E"
						local s = "H"
						local tit = "Engineering vs. Humanities"
					}
					if "`x'"=="NB" {
						local f = "N"
						local s = "B"
						local tit = "Natural Science vs. Business"
					}
					if "`x'"=="NS" {
						local f = "N"
						local s = "S"
						local tit = "Natural Science vs. Social Science"
					}
					if "`x'"=="NH" {
						local f = "N"
						local s = "H"
						local tit = "Natural Science vs. Humanities"
					}
					if "`x'"=="BS" {
						local f = "B"
						local s = "S"
						local tit = "Business vs. Social Science"
					}
					if "`x'"=="BH" {
						local f = "B"
						local s = "H"
						local tit = "Business vs. Humanities"
					}
					if "`x'"=="SH" {
						local f = "S"
						local s = "H"
						local tit = "Social Science vs. Humanities"
					}
			twoway (hist first`x' if tag==1,bin(10)frac fcolor(none)lcol(black)graphregion(color(white))), ///
			tit("`tit'")ytit("Fraction")xtit("Share of years `f' exceeds `s' in a school region")ylab(0(.05).25)xlab(0(.2)1)
			graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig_A4`x'.wmf",replace 
		}			
						
***FIGURE A5 - SMOOTHNESS OF PREDETERMINED VARIABLES AROUND CUTOFF
	
	
		use "$file\competitive_AEJ.dta", clear
		
		forvalues x=145(-10)-95 {							// set rv to 10-decimal places
			replace dist=dist-5 if dist==`x' & dist<0
			replace dist=dist+5 if dist==`x' & dist>0
		}
	replace dist=-75 if dist<=-60 
	replace dist=dist/100

	*** 4 times parental background	
	preserve 
	collapse (mean) utbFar utbMor, by(dist)
	twoway (scatter utbFar dist,msymbol(o)mc(black)) (scatter utbMor dist,msymbol(+)mc(black)graphregion(color(white))), title("Parental education") /// 
	ytitle(Years of schooling) xtitle(Distance to cutoff) ylabel(11(0.5)12.5) ///
	xline(0,lwidth(thin)lc(black)lp(dash))  legend(order (1 "Fathers" 2 "Mothers") ring(0) textfirst position(5) cols(1))
	graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig_A5a.wmf",replace 
	restore

	preserve 
	collapse (mean) lnwFar lnwMor , by(dist)
	twoway (scatter lnwFar dist,msymbol(o)mc(black)) (scatter lnwMor dist,msymbol(+)mc(black)graphregion(color(white))), ///
	title("Parental earnings") ytitle(Log annual earnings) xtitle(Distance to cutoff) ylabel(4.8(.20)5.8)xline(0,lwidth(thin)lc(black)lp(dash))  /// 
	legend(order (1 "Fathers" 2 "Mothers") ring(0) textfirst position(3) cols(1))
	graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig_A5b.wmf",replace 
	restore
	
	preserve 
	collapse (mean) ageFar ageMor, by(dist)
	twoway (scatter ageFar dist,msymbol(o)mc(black)) (scatter ageMor dist,msymbol(+)mc(black)graphregion(color(white))), title(Parental age at birth) /// 
	ytitle("Age" " ") xtitle(Distance to cutoff) ylabel(26(1)29) xline(0,lwidth(thin)lc(black)lp(dash)) legend(order (1 "Fathers" 2 "Mothers") ring(0) textfirst position(5) cols(1))
	graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig_A5c.wmf",replace 
	restore

	preserve 
	collapse (mean) utrpar utrfod, by(dist)
	twoway (scatter utrpar dist,msymbol(o)mc(black)) (scatter utrfod dist,msymbol(+)mc(black)graphregion(color(white))), title("Parent / child foreign born") /// 
	ytitle(Foreign born) xtitle(Distance to cutoff)ylab(0(.05).25) xline(0,lwidth(thin)lc(black)lp(dash)) legend(order (1 "Parent" 2 "Child") ring(0) textfirst position(1) cols(1))
	graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig_A5d.wmf",replace 
	restore

	

*** FIGURE A6 - EQUAL TO FIG 1 BUT FOR ADJUSTED GPA (=JMFT) OF 3.4-3.5

use "$file\step5_AEJ.dta",clear
		drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
						(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		// drop if Jmft is very low or very high
		
		preserve
		replace GPA=GPA/100
		keep if GPA>=3.4 & GPA<=3.5 & FstC!=. 
		sum GPA		
		local nind=trim("`: di %11.0gc [r(N)]'")
		collapse log3739PS,by(FstC)
		la var log3739PS "Log earnings"
		la var FstC " "
	twoway (bar log3739PS FstC,fc(gs12)lc(gs12)barw(0.5)) , tit("Log earnings for completers at GPA 3.4 or 3.5") ///
			xlabel(1 "Engineering" 2 `""Natural" "Science""' 3 "Business" 4 `""Social" "Science""' ///
				5 "Humanities" 6 `""Non-acad." "General""' 7 `""Non-acad." "Vocational""', labsize(small)) ///
				note(" " "Applicants 1977-1991: N = `nind'.") ylab(5.2(.2)6,nogrid)graphregion(color(white))legend(off)
				graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig_A6.wmf",replace 
		restore		
				
		
		

		
***FIGURE A7 PANEL A (5 SLOPES - ONE FOR EACH FIRST CHOICE) and PANEL B (7 SLOPES FOR EACH SECOND CHOICE)
		
	use "$file\competitive_AEJ.dta", clear
		
		gen wgt151=max(0,151-abs(dist))
		
		forvalues x=145(-10)-95 {							// set rv to 10-decimal places
			replace dist=dist-5 if dist==`x' & dist<0
			replace dist=dist+5 if dist==`x' & dist>0
		}
		
		gen secondchoice=sec
		replace secondchoice=100 if nonac2g==1
		replace secondchoice=101 if nonac2v==1			// collapse non-academic second choices into two categories (general & vocational)
		
		keep if logantpctPS!=. 
		
		preserve
		gen logantpctPST=logantpctPS if fst==59
		gen logantpctPSN=logantpctPS if fst==44
		gen logantpctPSB=logantpctPS if fst==10
		gen logantpctPSS=logantpctPS if fst==51
		gen logantpctPSH=logantpctPS if fst==28
		
		gen distT=dist2 if fst==59
		gen distN=dist2 if fst==44
		gen distB=dist2 if fst==10
		gen distS=dist2 if fst==51
		gen distH=dist2 if fst==28
		
		foreach x in T N B S H {
			replace dist`x'=0 if dist`x'==.
		}
		
		replace fst=0 if dist<0  // to retain a common intercept to the left of the cutoff 
		
		foreach x in T N B S H {
			replace dist`x'=-75 if dist`x'<=-60
		}
		replace dist=-75 if dist<=-60 
		
		
		reg logantpctPS Sint i.fst dist distT distN distB distS distH [pw=wgt151],robust 
			predict estim1,xb
			predict estim2T if dist>0 & fst==59,xb
			predict estim2N if dist>0 & fst==44,xb
			predict estim2B if dist>0 & fst==10,xb
			predict estim2S if dist>0 & fst==51,xb
			predict estim2H if dist>0 & fst==28,xb
		
		qui	bysort dist: egen ndot=count(dist)
			collapse (mean) logantpctPS* estim* ndot, by(dist)
				*2T estim2N estim2B estim2S estim2H estim1
						la var logantpctPS "Log annual earnings"
						local text: var la logantpctPS
		
							keep if ndot>3 
								replace dist=dist/100
								twoway (scatter logantpctPS dist if dist<0,msize(small)msymbol(o)mc(black)) (scatter logantpctPST dist if dist>0,msize(small)msymbol(o)mc(navy)) ///
								(scatter logantpctPSN dist if dist>0,msize(small)msymbol(o)mc(dkgreen)) (scatter logantpctPSB dist if dist>0,msize(small)msymbol(o)mc(cranberry)) ///
								(scatter logantpctPSS dist if dist>0,msize(small)msymbol(o)mc(purple)) (scatter logantpctPSH dist if dist>0,msize(small)msymbol(o)mc(dkorange)) ///
								(connected estim1 dist if dist<=-0.05,lc(black)lw(thin)msym(i)mcol(black)) ///
								(connected estim2T dist if dist>=0.05,lc(navy)lw(thin)msym(i)mcol(navy)) ///
								(connected estim2N dist if dist>=0.05,lc(dkgreen)lw(thin)msym(i)mcol(dkgreen)) ///
								(connected estim2B dist if dist>=0.05,lc(cranberry)lw(thin)msym(i)mcol(cranberry)) ///
								(connected estim2S dist if dist>=0.05,lc(purple)lw(thin)msym(i)mcol(purple)) ///
								(connected estim2H dist if dist>=0.05,lc(dkorange)lw(thin)msym(i)mcol(dkorange)graphregion(color(white))) , ///
								title(" ")  ytitle(`text') xtitle(Distance to cutoff) xline(0,lwidth(thin)) ///
								legend(order (8 "Engineeing" 9 "Natural Sci." 10 "Business" 11 "Social Sci." 12 "Humanities")size(small)region(lstyle(none))colgap(3)cols(3)textfirst)
								graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig_A7a.wmf",replace 
								
		restore	
		
		
		***PANEL B (7 SLOPES - ONE FOR EACH SECOND CHOICE)
		
		gen logantpctPST=logantpctPS if sec==59
		gen logantpctPSN=logantpctPS if sec==44
		gen logantpctPSB=logantpctPS if sec==10
		gen logantpctPSS=logantpctPS if sec==51
		gen logantpctPSH=logantpctPS if sec==28
		
		gen logantpctPSV=logantpctPS if nonac2v==1
		gen logantpctPSG=logantpctPS if nonac2g==1
		gen distT=dist if sec==59 & dist<0
		gen distN=dist if sec==44 & dist<0
		gen distB=dist if sec==10 & dist<0
		gen distS=dist if sec==51 & dist<0
		gen distH=dist if sec==28 & dist<0
		gen distG=dist if nonac2g==1 & dist<0
		gen distV=dist if nonac2v==1 & dist<0
		
		
		foreach x in T N B S H G V {
			replace dist`x'=0 if dist`x'==.
		}
		
		replace secondchoice=0 if dist>0  // to retain a common intercept to the left of the cutoff 
		
		foreach x in T N B S H G V {
			replace dist`x'=-75 if dist`x'<=-60
		}
		replace dist=-75 if dist<=-60 
		
		
		reg logantpctPS i.secondchoice dist2 distT distN distB distS distH distG distV [pw=wgt151],robust 
			predict estim1,xb
			predict estim2T if dist<0 & sec==59,xb
			predict estim2N if dist<0 & sec==44,xb
			predict estim2B if dist<0 & sec==10,xb
			predict estim2S if dist<0 & sec==51,xb
			predict estim2H if dist<0 & sec==28,xb
			predict estim2G if dist<0 & nonac2g==1,xb
			predict estim2V if dist<0 & nonac2v==1,xb
		
		
		
		qui	bysort dist: egen ndot=count(dist)
		
		collapse (mean) logantpctPS* estim* ndot, by(dist)
		*2T estim2N estim2B estim2S estim2H estim2G estim2V estim1 
					la var logantpctPS "Log annual earnings"
					local text: var la logantpctPS
			
								keep if ndot>3 
								replace dist=dist/100
								twoway (scatter logantpctPS dist if dist>0,msize(small)msymbol(o)mc(black)) (connected estim1 dist if dist>=0.05,lc(black)lw(thin)msym(i)mcol(black)) ///
								(scatter logantpctPST dist if dist<0,msize(small)msymbol(o)mc(navy)) (connected estim2T dist if dist<0.05,lc(navy)lw(thin)msym(i)mcol(navy)) ///
								(scatter logantpctPSN dist if dist<0,msize(small)msymbol(o)mc(dkgreen)) (connected estim2N dist if dist<0.05,lc(dkgreen)lw(thin)msym(i)mcol(dkgreen)) ///
								(scatter logantpctPSB dist if dist<0,msize(small)msymbol(o)mc(cranberry)) (connected estim2B dist if dist<0.05,lc(cranberry)lw(thin)msym(i)mcol(cranberry)) ///
								(scatter logantpctPSS dist if dist<0,msize(small)msymbol(o)mc(purple)) (connected estim2S dist if dist<0.05,lc(purple)lw(thin)msym(i)mcol(purple)) ///
								(scatter logantpctPSH dist if dist<0,msize(small)msymbol(o)mc(dkorange)) (connected estim2H dist if dist<0.05,lc(dkorange)lw(thin)msym(i)mcol(dkorange)) ///
								(scatter logantpctPSG dist if dist<0,msize(small)msymbol(o)mc(maroon)) (connected estim2G dist if dist<0.05,lc(maroon)lw(thin)msym(i)mcol(black)) ///
								(scatter logantpctPSV dist if dist<0,msize(small)msymbol(o)mc(gs8)) (connected estim2V dist if dist<0.05,lc(sand)lw(thin)msym(i)mcol(sand)graphregion(color(white))) , ///
								title(" ")  ytitle(`text') xtitle(Distance to cutoff) xline(0,lwidth(thin)) ///
								legend(order (3 "Engineeing" 4 " " 5 "Natural Sci." 6 " " 7 "Business" 8 " " 9 "Social Sci." 10 " " 11 "Humanities" ///
								12 " " 13 "General" 14 " " 15 "Vocational" 16 " ")size(small)region(lstyle(none))colgap(3)cols(6)textfirst)
								graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig_A7b.wmf",replace 
								

								
								
**** FIGURE A8 - CONVERTS EXCEL-FILE OF ESTIMATES INTO ILLUSTRATION OF ESTIMATED COEFFICIENTS								
***This Excel file contains the necessary coefficients and standard errors

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
				*Comparison of fuzzy RD estimates using the 60 slope, 12 slope, and 2 slope models
				graph twoway (scatter slope12 slope60 baseline, msize(msmall msmall) msymbol(t oh) mcolor(black black) ), ///
				legend(position(4) ring(0) order(1 "12 slope model" 2 "60 slope model" ) cols(2) hole(2) region(style(none)) ) || ///
				function y=x, range(-.2 .2) lw(thin) lc(black) lp(-) title(" ")  ytitle(12 or 60 slope model estimates) xtitle(2 slope model estimates) graphregion(color(white)) ylab(,nogrid)
				graph export "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\Figures\fig_A8.wmf",replace 
				




