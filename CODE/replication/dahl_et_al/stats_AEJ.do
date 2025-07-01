	clear
capture log close

log using "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\log_stats.log",replace

set more off, permanently		

global file "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"

	cd "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output"

*** THE LOG OUTPUT OF THIS SYNTAX REPORTS INFORMATION IN TABLE 2, 5 (F-TESTS), 6, A1, A3 AND A8 




***** TABLE 2 - FREQUENCIES OF OVERSRUBSCRIBED AND NON-IMPACTED PROGRAMS

	use "$file\step5_AEJ.dta",clear	
			keep if fst==10 | fst==28 | fst==44 | fst==51 | fst==59											// keep only academic programs
			drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
							(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		// drop if Jmft is very low or very high
			keep if sec!=. & fst!=sec & sec!=43 																		// drop if second choice is science/engineering (=43), missing, or same as first choice
		
			gen main=(diff_count>=3 & app_count>=25 & (abs(dist)<=151) & (abs(dist)>=1) & dist>-101 & logantpctPS!=.)		// indicator for being part of our main sample
			egen cellnumbers=group(ProdAr Region fst)
			
			bysort ProdAr Region fst: egen help=max(main) if main!=.
			gen maincell=1 if help==1																						// indicator that cell is represented in our main sample
			bysort ProdAr Region fst: egen help1=min(main) if main!=.
			replace maincell=0 if maincell==. & help1==0 
			egen tag=tag(ProdAr Region Program) if main==1
			
			**** OUTPUT FOR TABLE 2
			
			tab Fst if main==1 & maincell==1 & logantpctPS!=. & Sint!=. // column 1 of Table 2
			tab Fst if tag==1 & main==1									// column 2 of Table 2
			tab Fst if main==0 & maincell==0 & logantpctPS!=. & Sint!=.	// column 3 of Table 2
			
			foreach x in 59 44 10 51 28 {								// column 4 of Table 2
							dis `x'
					codebook cellnumbers if maincell==0 & fst==`x' & main==0
				}
			

***** TESTS FOUND IN LAST THREE COLUMNS OF TABLE 5 

***** THE LAST SET OF TESTS PRESENTED REPRESENTS THE FULL TABLE 6 - TESTS FOR COMPARATIVE ADVANTAGE AND DISADVANTAGE
	

	
	use "$file\competitive_AEJ.dta",clear
	
		set matsize 8000
		set emptycells drop
		
		gen wgt151=max(0,151-abs(dist))
		
			foreach cov in utrfod birth1 adopted FodarFar FodarMor utbFar utbMor utrFar utrMor utb38 {
				qui sum `cov'
				replace `cov'=r(mean) if `cov'==.
			}
		
			
			tabulate ProdAr, generat(yr)
			egen gymnreg=group(Region)
			sum gymnreg
			local regn = r(max)
			
			forvalues x=1/`regn' {
				gen gymnr`x'=(gymnreg==`x')
			}
			
			
			local sint SintTn SintTb SintTs SintTh SintTg SintTv SintNt SintNb SintNs SintNh SintNg SintNv SintBt SintBn SintBs SintBh SintBg SintBv SintSt SintSn SintSb SintSh SintSg SintSv SintHt SintHn SintHb SintHs SintHg SintHv
			local compl complTn complTb complTs complTh complTg complTv complNt complNb complNs complNh complNg complNv complBt complBn complBs complBh complBg complBv complSt complSn complSb complSh complSg complSv complHt complHn complHb complHs complHg complHv
			
			
			
			local sec tsec-hsec nonac2v nonac2g 
			local controls FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod i.age 
			local rv = "dist dist2"
	
			local sint SintNt SintBt SintSt SintHt SintTn SintBn SintSn SintHn SintTb SintNb SintSb SintHb SintTs SintNs SintBs SintHs SintTh SintNh SintBh SintSh SintTv SintNv SintBv SintSv SintHv SintTg SintNg SintBg SintSg SintHg 
			local compl complNt complBt complSt complHt complTn complBn complSn complHn complTb complNb complSb complHb complTs complNs complBs complHs complTh complNh complBh complSh complTv complNv complBv complSv complHv complTg complNg complBg complSg complHg 
			
			local sec tsec-hsec nonac2v nonac2g 
			local controls FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod i.age 
			local rv = "dist dist2"
		
	***IV MODEL
	
	qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 


***** TABLE 5 - F-TESTS PRESNTED IN THREE RIGHTMOST COLUMNS 
	
	
	dis "IV estimates on row are equal"
	test complTn = complTb = complTs = complTh = complTg = complTv
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	test complNt = complNb = complNs = complNh = complNg = complNv
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	test complBt = complBn = complBs = complBh = complBg = complBv
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	test complSt = complSn = complSb = complSh = complSg = complSv
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	test complHt = complHn = complHb = complHs = complHg = complHv
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	
	
	dis "test if row academic are equal"
	test complTn = complTb = complTs = complTh 
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	test complNt = complNb = complNs = complNh 
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	test complBt = complBn = complBs = complBh 
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	test complSt = complSn = complSb = complSh 
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	test complHt = complHn = complHb = complHs 
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	
	
	dis "test if coeff of non-ac are equal to academic"
	test (((complTn + complTb + complTs + complTh)/4) = ((complTg + complTv)/2))
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	
	test ((complNt + complNb + complNs + complNh)/4) = ((complNg + complNv)/2)
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	
	test ((complBt + complBn + complBs + complBh)/4) = ((complBg + complBv)/2)
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	
	test ((complSt + complSn + complSb + complSh)/4) = ((complSg + complSv)/2)
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	
	test ((complHt + complHn + complHb + complHs)/4) = ((complHg + complHv)/2)
	scalar tstat = sqrt(r(chi2))
	dis tstat
	return list chi2
	

***** TABLE 6 - TESTS FOR COMPARATIVE ADVANTAGE AND DISADVANTAGE
	
		dis "IV test of each combination"
	dis _b[complTn]+_b[complNt]
	test complTn+complNt = 0
	scalar tstat = sqrt(r(chi2))
	dis tstat
	dis "standard error" (_b[complTn]+_b[complNt])/tstat
	return list chi2
	dis _b[complTb]+_b[complBt]
	test complTb+complBt = 0
	scalar tstat = sqrt(r(chi2))
	dis tstat
	dis "standard error" (_b[complTb]+_b[complBt])/tstat
	return list chi2
	dis _b[complTs]+_b[complSt]
	test complTs+complSt = 0
	scalar tstat = sqrt(r(chi2))
	dis tstat
	dis "standard error" (_b[complTs]+_b[complSt])/tstat
	return list chi2
	dis _b[complTh]+_b[complHt]
	test complTh+complHt = 0
	scalar tstat = sqrt(r(chi2))
	dis tstat
	dis "standard error" (_b[complTh]+_b[complHt])/tstat
	return list chi2
	dis _b[complNb]+_b[complBn]
	test complNb+complBn = 0
	scalar tstat = sqrt(r(chi2))
	dis tstat
	dis "standard error" (_b[complNb]+_b[complBn])/tstat
	return list chi2
	dis _b[complNs]+_b[complSn]
	test complNs+complSn = 0
	scalar tstat = sqrt(r(chi2))
	dis tstat
	dis "standard error" (_b[complNs]+_b[complSn])/tstat
	return list chi2
	dis _b[complNh]+_b[complHn]
	test complNh+complHn = 0
	scalar tstat = sqrt(r(chi2))
	dis tstat
	dis "standard error" (_b[complNh]+_b[complHn])/tstat
	return list chi2
	dis _b[complBs]+_b[complSb]
	test complBs+complSb = 0
	scalar tstat = sqrt(r(chi2))
	dis tstat
	dis "standard error" (_b[complBs]+_b[complSb])/tstat
	return list chi2
	dis _b[complBh]+_b[complHb]
	test complBh+complHb = 0
	scalar tstat = sqrt(r(chi2))
	dis tstat
	dis "standard error" (_b[complBh]+_b[complHb])/tstat
	return list chi2
	dis _b[complSh]+_b[complHs]
	test complSh+complHs = 0
	scalar tstat = sqrt(r(chi2))
	dis tstat
	dis "standard error" (_b[complSh]+_b[complHs])/tstat
	return list chi2
	
	
				
			
			
************ Table A1

	use "$file\competitive_AEJ.dta",clear
	
		
			**** OUTPUT FOR TABLE A1

			tab Fst Sec if logantpctPS!=.

			
************ Table A3 - COMPARISON OF MAJOR CUTOFFS ACROSS YEARS WITHIN THE SAME SCHOOL REGION

use "$file\step5_AEJ.dta",clear
		drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
						(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		// drop if Jmft is very low or very high
		
		gen competition=(diff_count>=3 & app_count>=25 & cut!=.)
		keep if Sint!=. & academic==1
		
		*** drop if competitive cell within +1.5 and 1.0 of cutoff and exclude mixed borders (on cutoff), if sec choice is missing or the same as first choice
		gen smp=1 if diff_count>=3 & app_count>=25 & (abs(dist)<=151) & (abs(dist)>=1) & dist>-101 & sec!=. & fst!=sec & fst!=43 & sec!=43 
		
		
		**** histogram of how cutoff changes compared with its lagged value (if defined)

				collapse (mean) cut competition academic, by(ProdAr Region fst)
				sort ProdAr Region fst
				replace cut=0 if cut==.

				bysort ProdAr Region (fst): gen cutE=cut if fst==59
				bysort ProdAr Region (fst): gen cutN=cut if fst==44
				bysort ProdAr Region (fst): gen cutB=cut if fst==10
				bysort ProdAr Region (fst): gen cutS=cut if fst==51
				bysort ProdAr Region (fst): gen cutH=cut if fst==28
				
				collapse cutE cutN cutB cutS cutH ,by(ProdAr Region)
				
				gen cutdiffEN=cutE-cutN 
				gen cutdiffEB=cutE-cutB 
				gen cutdiffES=cutE-cutS 
				gen cutdiffEH=cutE-cutH 
				gen cutdiffNB=cutN-cutB 
				gen cutdiffNS=cutN-cutS 
				gen cutdiffNH=cutN-cutH 
				gen cutdiffBS=cutB-cutS 
				gen cutdiffBH=cutB-cutH 
				gen cutdiffSH=cutS-cutH 
			
			label define sum 1 "First prg higher" 2 "Second prg higher" 3 "Draw", replace 
				
label define sum 1 "First prg higher" 2 "Second prg higher" 3 "Draw", replace 
				foreach x in EN EB ES EH NB NS NH BS BH SH {
					if "`x'"=="EN" {
						local f = "E"
						local s = "N"
					}
					if "`x'"=="EB" {
						local f = "E"
						local s = "B"
					}
					if "`x'"=="ES" {
						local f = "E"
						local s = "S"
					}
					if "`x'"=="EH" {
						local f = "E"
						local s = "H"
					}
					if "`x'"=="NB" {
						local f = "N"
						local s = "B"
					}
					if "`x'"=="NS" {
						local f = "N"
						local s = "S"
					}
					if "`x'"=="NH" {
						local f = "N"
						local s = "H"
					}
					if "`x'"=="BS" {
						local f = "B"
						local s = "S"
					}
					if "`x'"=="BH" {
						local f = "B"
						local s = "H"
					}
					if "`x'"=="SH" {
						local f = "S"
						local s = "H"
					}
					
					
					qui gen sum`x'=3 if cutdiff`x'==0 
					qui replace sum`x'=1 if cut`f'>cut`s'
					qui replace sum`x'=2 if cut`f'<cut`s'
					label values sum`x' sum
					tab sum`x'
				}
				

************ TABLE A8 - MULTIPLE HYPOTHESIS TESTING
		use "$file\multhyp_test_AEJ_sep2021.dta", clear
		
				****	Multiple inference correction.
				* Data taken from output on p-values for the 30 estimates appearing in Table 4 and 5.

				
				* Panel A: Reduced form, FDR-corrected: simes
				qqvalue pval_rf, method(simes) qvalue(hochbergP)
				rename hochbergP FDR_pvalrf


				* Panel B: IV, FDR-corrected: simes

				qqvalue pval_iv, method(simes) qvalue(hochbergP)
				rename hochbergP FDR_pvaliv
				
				foreach x in pval_rf FDR_pvalrf pval_iv FDR_pvaliv {
					sum `x' if `x'<.10
				}
				
				
************ CORRELATIONS MENTIONED REGARDING APPENDIX TABLES A5, A7 & A9
				
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

			***Table A5: Correlations by age, gender, and parental education
			pwcorr baseline age_2729 [weight=age_2729_weight]
			pwcorr male female [weight=malefemale_weight]
			pwcorr parent_highed parent_lowed [weight=parented_weight]

			***Table A7: Correlations of baseline with quadratic, smaller bandwidth, 1st-2nd intercepts, 12 slopes, 60 slopes, excluding 1982-84
			foreach var of varlist quadratic halfwidth int1st2nd slope12 slope60 no8284 {
			  local temp = "`var'"+"_weight"
			  pwcorr baseline `var' [weight=`temp']
			  }

			***Table A9: Correlations of baseline with OLS (w/0 GPA), OLS (w/ GPA), KLM IV
			foreach var of varlist ols_nogpa ols_gpa klm {
			  local temp = "`var'"+"_weight"
			  pwcorr baseline `var' [weight=`temp']
			 }
