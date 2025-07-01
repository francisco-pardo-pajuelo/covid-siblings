clear
capture log close

log using "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\log_results.log",replace

set more off, permanently		

global file "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"

	cd "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output"

*** THE SYNTAX BELOW PERFORMS MULTIPLE REGRESSION ANALYSES INCLUDING:
			** Footnote 18 - impact on dropping out and switching programs
			** Footnote 24 - 3 alternative earnings measures

*** THEN FOLLOWS WORD-FILE RESULTS FOR TABLES 3, 4 AND 5 
*** FURTHER: TABLES 7, 8, 9 and TABLES A2, A4, A5, A6, A7, A9 	[COLUMNS 3-6 OF TABLE A5 ARE ESTIMATED SEPARATELY IN THE LAST PART OF THIS SYNTAX FILE]				

		
		use "$file\competitive_AEJ.dta",clear
		
		gen wgt151=max(0,151-abs(dist))
			
			forvalues x=101(-5)11 {
				gen wgt`x'=max(0,`x'-abs(dist))
			}
		
		gen secondchoice=sec
		replace secondchoice=100 if nonac2g==1
		replace secondchoice=101 if nonac2v==1			// collapse non-academic second choices into two categories (general & vocational)
			
		egen combo=group(fst secondchoice)				// combinations of fst and sec choices
		sum combo
		local m = r(max)
		
		tabulate combo, generat(c)
		forvalues x=1/`m' {
			gen c`x'd=c`x'*dist
			gen c`x'd2=c`x'*dist2						// rv separately for each combination of fst and sec choices [and separately above or below cutoff]
		}
		
			foreach cov in utrfod FodarFar FodarMor utbFar utbMor utrFar utrMor utb38 { // replace missing covariates with its mean value so we retain obs.
				qui sum `cov'
				replace `cov'=r(mean) if `cov'==.
			}
						
		gen gtdist=dist if sec==59 & Sint==0			// The 12-slope (or Gordon-)model, hence the "g" in the variable names, 
		gen gndist=dist if sec==44 & Sint==0			// rv is here separate for first choices and for second choices (but not combined)
		gen gbdist=dist if sec==10 & Sint==0
		gen gsdist=dist if sec==51 & Sint==0
		gen ghdist=dist if sec==28 & Sint==0
		gen gtdist2=dist2 if fst==59 & Sint==1
		gen gndist2=dist2 if fst==44 & Sint==1
		gen gbdist2=dist2 if fst==10 & Sint==1
		gen gsdist2=dist2 if fst==51 & Sint==1
		gen ghdist2=dist2 if fst==28 & Sint==1
		
		foreach x in t n b s h {
			replace g`x'dist=0 if g`x'dist==.
			replace g`x'dist2=0 if g`x'dist2==.
		}
		
		gen gnonvdist=dist if nonac2v==1 & Sint==0
		gen gnongdist=dist if nonac2g==1 & Sint==0
		replace gnonvdist=0 if gnonvdist==.
		replace gnongdist=0 if gnongdist==.
		
				foreach x in compl Sint {		// generate labels to our output table ("T" or "t" in variable name stands for Teknik, yields label "E" for engineering)
					la var `x'Tn "E vs. N"
					la var `x'Tb "E vs. B"
					la var `x'Ts "E vs. S"
					la var `x'Th "E vs. H"
					la var `x'Tg "E vs. G"
					la var `x'Tv "E vs. V"
					la var `x'Nt "N vs. E"
					la var `x'Nb "N vs. B"
					la var `x'Ns "N vs. S"
					la var `x'Nh "N vs. H"
					la var `x'Ng "N vs. G"
					la var `x'Nv "N vs. V"
					la var `x'Bt "B vs. E"
					la var `x'Bn "B vs. N"
					la var `x'Bs "B vs. S"
					la var `x'Bh "B vs. H"
					la var `x'Bg "B vs. G"
					la var `x'Bv "B vs. V"
					la var `x'St "S vs. E"
					la var `x'Sn "S vs. N"
					la var `x'Sb "S vs. B"
					la var `x'Sh "S vs. H"
					la var `x'Sg "S vs. G"
					la var `x'Sv "S vs. V"
					la var `x'Ht "H vs. E"
					la var `x'Hn "H vs. N"
					la var `x'Hb "H vs. B"
					la var `x'Hs "H vs. S"
					la var `x'Hg "H vs. G"
					la var `x'Hv "H vs. V"
				}
		
			
			***list of first stage estimates (Sint) and iv estimates (lint = enrolment) and compl = completion for different combination of first and second choices (in total 30 combinations)
		
			local sint SintTn SintTb SintTs SintTh SintTg SintTv SintNt SintNb SintNs SintNh SintNg SintNv SintBt SintBn SintBs SintBh SintBg SintBv SintSt SintSn SintSb SintSh SintSg SintSv SintHt SintHn ///
						SintHb SintHs SintHg SintHv
			local compl complTn complTb complTs complTh complTg complTv complNt complNb complNs complNh complNg complNv complBt complBn complBs complBh complBg complBv complSt complSn complSb complSh complSg complSv 						complHt complHn complHb complHs complHg complHv
			local lint lintTn lintTb lintTs lintTh lintTg lintTv lintNt lintNb lintNs lintNh lintNg lintNv lintBt lintBn lintBs lintBh lintBg lintBv lintSt lintSn lintSb lintSh lintSg lintSv lintHt lintHn lintHb 						lintHs lintHg lintHv
			
			local sintordersec SintNt SintBt SintSt SintHt SintTn SintBn SintSn SintHn SintTb SintNb SintSb SintHb SintTs SintNs SintBs SintHs SintTh SintNh SintBh SintSh SintTg SintNg SintBg SintSg ///
					SintHg SintTv SintNv SintBv SintSv SintHv 
			local complordersec complNt complBt complSt complHt complTn complBn complSn complHn complTb complNb complSb complHb complTs complNs complBs complHs complTh complNh complBh complSh complTg ///
					complNg complBg complSg complHg complTv complNv complBv complSv complHv 
			
			
			tabulate ProdAr, generat(yr)		// year dummies
			egen gymnreg=group(Region)			// region dummies
			sum gymnreg
			local regn = r(max)
			
			forvalues x=1/`regn' {
				gen gymnr`x'=(gymnreg==`x')
			}
			
			replace emp35pct=(logantpctPS==.)
			gen distsq=dist*dist
			gen dist2sq=dist2*dist2															// rv in squared model 
			
			
			local controls FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod i.age 	// covariates
			
			local sec tsec-hsec nonac2v nonac2g 											// second choice slopes
			local rv = "dist dist2"															// rv in 2-slope model (benchmark)
			local rvsq = "dist dist2 distsq dist2sq"										// rv in squared model 
				
			local rv12 = "gtdist-ghdist2 gnonvdist gnongdist"								// rv in 12-slope model 
			local rv60 = "c1d-c`m'd2"														// rv in 60-slope model 
			
			encode inr383,gen(eductype)														// field of study
			replace eductype=9999 if (utb38<15 | postsec==4 | postsec==5)					// coded into one category if no completed college 
			
			gen hi=1 if utbpar>11 & utbpar!=.
			replace hi=0 if utbpar!=. & hi==.
			gen lo=1 if utbpar<=11 
			replace lo=0 if utbpar!=. & lo==. 
			
			local complGV complTg complTv complNg complNv complBg complBv complSg complSv complHg complHv
			
			gen dropout=(completed==0)
			gen switchnac=1 if fst!=completed & nonac2==0 & (completed==9 | completed==54 | completed==58 | FstC==7) 
																	// switchnac = switchers from being accepted to academic but completing a non-ac major
			replace switchnac=0 if switchnac==. & nonac2==0 		// switchnac=1 if second choice is NOT non-academic (in that case they would not ind accepted to academic major completes a non-academic major
			
			
			*** for ols estimates we need program specific completions 
			*nonacG_compl 
			gen complTo=(completed==59)
			gen complNo=(completed==44 | completed==45)
			gen complBo=(completed==10)
			gen complSo=(completed==51 | completed==52)
			gen complHo=(completed==28)
			
			gen kollvar=0 if dropout==1
			replace kollvar=1 if complTo==1 
			replace kollvar=2 if complNo==1  
			replace kollvar=3 if complBo==1 
			replace kollvar=4 if complSo==1 
			replace kollvar=5 if complHo==1 
			replace kollvar=6 if nonacgC==1 
			replace kollvar=7 if nonacvC==1 
			
			
			** for KLM regression - adjusted GPA interacted with second choice
			gen Jmft59=Jmft*sec if sec==59
			gen Jmft44=Jmft*sec if sec==44
			gen Jmft10=Jmft*sec if sec==10
			gen Jmft51=Jmft*sec if sec==51
			gen Jmft28=Jmft*sec if sec==28
			gen Jmft100=Jmft*secondchoice if secondchoice==100
			gen Jmft101=Jmft*secondchoice if secondchoice==101
			foreach x in 59 44 10 51 28 100 101 {
			    replace Jmft`x'=0 if Jmft`x'==.
			}
			
			
			*cells(b(star fmt(%9.3fc)) p(par fmt(5)))
			***observed all three years above 12K - 
			gen emp12=(N_limit12==3)
			
			** Footnote 18 - dropouts and swithcers
			eststo clear
			qui reg dropout Sint `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			qui reg switchnac Sint `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m2
			esttab using tables.rtf,replace cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(Sint) ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("Dropout" "Switcher") ///
			title("PAGE 17 footnote 18 - impact on dropping out and switching programs") compress collabels(none) 
			
			
			** Footnote 24 - 3 alternative earnings measures
			eststo clear
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			qui ivregress 2sls logantpct (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m2
			qui ivregress 2sls logcpiearn3739 (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m3
			qui ivregress 2sls logantearn3941 (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantearn3941!=. [pw=wgt151],robust nocons 
			eststo m4
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`compl') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("Baseline" "Log ForvInk" "Alternative threshold" "Age 39-41") ///
			title(Alternative earnings measures - footnote 24 on page 25) compress collabels(none) 
		
		use "$file\Table_A9_AEJ.dta",clear
		
		gen switchnac=1 if fst!=completed & nonac2==0 & (completed==9 | completed==54 | completed==58 | FstC==7) 
																	// switchnac = switchers from being accepted to academic but completing a non-ac major
			replace switchnac=0 if switchnac==. & nonac2==0 		// switchnac=1 if second choice is NOT non-academic (in that case they would not ind accepted to academic major completes a non-academic major
			eststo clear
			qui reg dropout Sint `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			qui reg switchnac Sint `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m2
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(Sint) ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("Dropout" "Switcher") ///
			title("PAGE 17 footnote 18 - impact on dropping out and switching programs") compress collabels(none) 
			
			
			** PAGE 25 footnote 24 - 3 alternative earnings measures
			eststo clear
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			qui ivregress 2sls logantpct (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m2
			qui ivregress 2sls logcpiearn3739 (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m3
			qui ivregress 2sls logantearn3941 (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantearn3941!=. [pw=wgt151],robust nocons 
			eststo m4
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`compl') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("Baseline" "Log ForvInk" "Alternative threshold" "Age 39-41") ///
			title(Alternative earnings measures - footnote 24 on page 25) compress collabels(none) 
		
		exit
		
		***		SEE DO-FILE "stats_AEJ" FOR OUTPUT REPRODUCING TABLE 2

		eststo clear
			qui reg fin `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 `sintordersec' if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`sintordersec') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("Completion") ///
		title("TABLE 3: FIRST STAGE RESULTS") compress collabels(none) 
	
		eststo clear
			qui reg logantpctPS `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 `sintordersec' if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`sintordersec') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("RF Log earnings") ///
		title("TABLE 4: REDUCED FORM RESULTS") compress collabels(none) 
	
		eststo clear
			ivregress 2sls logantpctPS (`complordersec' = `sintordersec') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`complordersec') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("IV Log earnings") ///
		title("TABLE 5: IV ESTIMATION RESULTS") compress collabels(none) 
		
		*** SEE DO-FILE "stats_AEJ" FOR TABLE 6 AND F-TEST-STATISTICS REPORTED IN TABLE 5 
		
		replace meanPS3739=meanPS3739/8.5
		eststo clear
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			qui ivregress 2sls meanPS3739 (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if meanPS3739!=. [pw=wgt151],robust nocons 
			eststo m2
			qui ivregress 2sls rankallPS_3739 (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if meanPS3739!=. [pw=wgt151],robust nocons 
			eststo m3
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`compl') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("Baseline" "Earnings in levels" "Earnings rank") ///
		title("TABLE 7 - ROBUSTNESS TO ALERNATIVE EARNINGS MEASURES") compress collabels(none) 
			
			
			
		eststo clear
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 utb38 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m2
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 i.eductype if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m3
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 i.ssyk38 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m4
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 utb38  i.eductype i.ssyk38 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m5
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`compl') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("Baseline" "Yrs of sch" "College type of degree" "Profession" "All") ///
		title("TABLE 8 - MEDIATION ANALYSES") compress collabels(none) 
		
		eststo clear
			qui ivregress 2sls earn_utb38LOM (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			qui ivregress 2sls earn_inrcollLOM15 (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m2
			qui ivregress 2sls earn438LOM (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m3
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`compl') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("Av earn by yrsofsch" "By 3yr college fields" "By profession") ///
		title("ESTIMATES USED IN TABLE 9 AND FOR ILLUSTRATIONS IN FIGURE 7") compress collabels(none) 
		
		
		
		
***** TABLE 9 - MECHANISMS - YEARS OF SCHOOLING, COLLEGE MAJOR AND OCCUPATION

			preserve			
				drop _all
				import excel using "$file\coeffs_and_ses.xlsx",first

				drop if baseline==""
				gen n=_n
				*coeff=1 if coefficient, coeff=0 if std error
				gen coeff = mod(n,2)
				gen i=int((n+1)/2)
				drop n
				quietly reshape wide margin baseline quadratic halfwidth int1st2nd slope12 slope60 no8284 levels rank ///
				earn_occup earn_collegemajor earn_yrsofsch male female parent_highed parent_lowed age_2729 ols_nogpa ols_gpa klm, i(i) j(coeff)
				*Note: 0 at end of variable denotes estimate, 1 denotes standard error (do not confuse with the coeff variable used temporarily above)
				drop margin0
				rename margin1 margin

				*remove "*" from estimates and rename coefficient variables to remove trailing 1's
				foreach var of varlist baseline1 quadratic1 halfwidth1 int1st2nd1 slope121 slope601 no82841 levels1 rank1 ///
				earn_occup1 earn_collegemajor1 earn_yrsofsch1 male1 female1 parent_highed1 parent_lowed1 age_27291 ols_nogpa1 ols_gpa1 klm1 {
				quietly replace `var'=subinstr(`var',"*","",.)
				local new = substr("`var'",1,length("`var'")-1)
				rename `var' `new'
				}

				quietly destring *, replace

				*rename variables for se's to have trailing "_se" instead of trailing "0"
				foreach var of varlist baseline0 quadratic0 halfwidth0 int1st2nd0 slope120 slope600 no82840 levels0 rank0 ///
				earn_occup0 earn_collegemajor0 earn_yrsofsch0 male0 female0 parent_highed0 parent_lowed0 age_27290 ols_nogpa0 ols_gpa0 klm0 {
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

				***Table 9: Mechanisms: Years of schooling, college major, and occupation
				la var earn_yrsofsch "Yrs of sch"
				la var earn_collegemajor "College major"
				la var earn_occup "Occupation" 
				local cov earn_yrsofsch earn_collegemajor earn_occup
		
		eststo clear
			qui reg baseline earn_yrsofsch [weight=baseline_weight]
			eststo m1
			qui reg baseline earn_collegemajor [weight=baseline_weight]
			eststo m2
			reg baseline earn_occup [weight=baseline_weight] 
			eststo m3
			reg baseline earn_yrsofsch earn_collegemajor earn_occup [weight=baseline_weight] 
			eststo m4
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`cov') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("Yrs of sch" "College type of degree" "Occupation" "All") ///
		title("TABLE 9 - MECHANISMS") compress collabels(none) 
		
		restore	
			
			
		**** SEE DO-FILE "stats_AEJ" FOR OUTPUT REPRODUCING TABLE A1

		
		
************ Tabel A2 - descriptive stats for baseline sample and non-impacted cells fulfilling our sample conditions 
	
		preserve
			
			use "$file\step5_AEJ.dta",clear
			
			keep if fst==10 | fst==28 | fst==44 | fst==51 | fst==59											// keep only academic programs
			drop if ((Jmft>=55 & ProdAr>=1982 & ProdAr<=1984) | ((Jmft>=50 & (ProdAr<1982 | ProdAr>1984))) | ///
							(Jmft<=25 & ProdAr>=1982 & ProdAr<=1984) | (Jmft<=20 & (ProdAr<1982 | ProdAr>1984)))		// drop if Jmft is very low or very high
			keep if sec!=. & fst!=sec & sec!=43 																		// drop if second choice is science/engineering (=43), missing, or same as first choice
		
			la var ageFar "Father age" 
			la var ageMor "Mother age" 
			la var utbFar "Father schooling" 
			la var utbMor "Mother schooling" 
			la var lnwFar "Father earnings" 
			la var lnwMor "Mother earnings" 
			la var utrpar "Foreing born parent" 
			la var utrfod "Foreign born"
			la var fem "Female"
			la var age "Age when applying"
			la var Jmft "Jmft"
			la var GPA "Unadjusted GPA"
			la var hisk15 "College degree"
			la var log3739PS "Log earnings"
			
			replace GPA=GPA/100
			replace Jmft=Jmft/10
			
			foreach x in ageFar ageMor utbFar utbMor lnwFar lnwMor utrpar utrfod fem age Jmft GPA hisk15 log3739PS {
				gen `x'miss=(`x'==.)
			}
			
			gen main=(diff_count>=3 & app_count>=25 & (abs(dist)<=151) & (abs(dist)>=1) & dist>-101 & logantpctPS!=.)		// indicator for being part of our main sample
			egen cellnumbers=group(ProdAr Region fst)
			
			bysort ProdAr Region fst: egen help=max(main) if main!=.
			gen maincell=1 if help==1																						// indicator that cell is represented in our main sample
			
			bysort ProdAr Region fst: egen help1=min(main) if main!=.
			
			replace maincell=0 if maincell==. & help1==0 
			egen tag=tag(ProdAr Region Program) if main==1
			
			eststo clear
			eststo: estpost sum ageFar ageMor utbFar utbMor lnwFar lnwMor utrpar utrfod fem age Jmft GPA hisk15 log3739PS if main==1
			eststo: estpost sum ageFarmiss ageMormiss utbFarmiss utbMormiss lnwFarmiss lnwMormiss utrparmiss utrfodmiss femmiss agemiss Jmftmiss GPAmiss hisk15miss log3739PSmiss if main==1
			eststo: estpost sum ageFar ageMor utbFar utbMor lnwFar lnwMor utrpar utrfod fem age Jmft GPA hisk15 log3739PS if maincell==0 & logantpctPS!=.
			eststo: estpost sum ageFarmiss ageMormiss utbFarmiss utbMormiss lnwFarmiss lnwMormiss utrparmiss utrfodmiss femmiss agemiss Jmftmiss GPAmiss hisk15miss log3739PSmiss  if maincell==0 & logantpctPS!=.
			esttab using tables.rtf,cells ("mean(fmt(2) label(Mean))") append onecell nonumbers nogap label ///
			mtit("Sample" "Share missing" "All" "Share missing") note("Parent characteristics measured in the year of application.") ///
			title("TABLE A2: MEAN CHARACTERISTICS.") compress
	restore		

	
	**** SEE DO-FILE "stats_AEJ" FOR OUTPUT REPRODUCING TABLE A3

************ Table A4 - falsification tests
		
		eststo clear
			local cov i.age i.fst i.ProdAr i.Region
			qui ivregress 2sls utbFar (fin = Sint) dist dist2 `cov' [pw=wgt151],robust 
			eststo m1
			qui ivregress 2sls utbMor (fin = Sint) dist dist2 `cov' [pw=wgt151],robust 
			eststo m2
			qui ivregress 2sls lnwFar (fin = Sint) dist dist2 `cov' [pw=wgt151],robust 
			eststo m3
			qui ivregress 2sls lnwMor (fin = Sint) dist dist2 `cov' [pw=wgt151],robust 
			eststo m4
			qui ivregress 2sls ageFar (fin = Sint) dist dist2 `cov' [pw=wgt151],robust 
			eststo m5
			qui ivregress 2sls ageMor (fin = Sint) dist dist2 `cov' [pw=wgt151],robust 
			eststo m6
			qui ivregress 2sls utrpar (fin = Sint) dist dist2 `cov' [pw=wgt151],robust 
			eststo m7
			qui ivregress 2sls utrfod (fin = Sint) dist dist2 `cov' [pw=wgt151],robust 
			eststo m8
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(fin) star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) ///
			addnot("Standard errors within parantheses") ///
			mtitles("Yrs of sch father" "Yrs of sch mother" "Log earn father" "Log earn mother" "Age father" "Age mother" "One parent foreign born" "Child foreign born") ///
		title("TABLE A4 - FALSIFICATION TESTS") compress collabels(none) 
					

		
		**** TABLE A5 - columns 1 and 2 (COLUMNS 3-6 ESTIMATED SEPARATELY) - last part of this syntax file
		
		eststo clear
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			qui ivregress 2sls logantearn2729 (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantearn2729!=. [pw=wgt151],robust nocons 
			eststo m2
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`compl') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("Baseline" "27-29") ///
		title("TABLE A5 - HETEROGENEITY BY AGE (COLUMNS 3-6 ESTIMATED SEPARATELY)") compress collabels(none) 
				
		exit
		
		eststo clear
			qui ivregress 2sls emp35pct (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if meanPS3739!=. [pw=wgt151],robust nocons 
			eststo m1
			qui ivregress 2sls emp12 (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m2
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`compl') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("Table A6" "Abv limit 12K all 3 yrs" ) ///
		title("TABLE A6 - PROBABILITY OF ABOVE THRSHOLD EARNINGS AND EARNINGS IN ALL THREE YEARS") compress collabels(none) 
		
		
		**** TABLE A7 
		eststo clear
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rvsq' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m2
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt76],robust nocons 
			eststo m3
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' i.combo gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m4
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv12' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m5
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv60' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m6
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if (ProdAr<1982 | ProdAr>1984) & logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m7
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`compl') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("Baseline" "Quadratic" "Narrow bandwidth 75" "Combo intercepts" "12 slope model" "60 slope model" "Excluding 1982-1984") ///
		title("TABLE A7 - SPECIFICATION CHECKS") compress collabels(none) 
			
		
		
		***		SEE DO-FILE "stats_AEJ" FOR TABLE A8

			
		**** TABLE A9 - column 2 [COLUMN 1 REPEATS THE BASELINE]
		eststo clear
			qui reg logantpctPS complNo complBo complSo complHo nonacgC nonacvC dropout `controls' yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m1
			qui reg logantpctPS complTo complBo complSo complHo nonacgC nonacvC dropout `controls' yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m2
			qui reg logantpctPS complTo complNo complSo complHo nonacgC nonacvC dropout `controls' yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m3
			qui reg logantpctPS complTo complNo complBo complHo nonacgC nonacvC dropout `controls' yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m4
			qui reg logantpctPS complTo complNo complBo complSo nonacgC nonacvC dropout `controls' yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m5
			qui reg logantpctPS complTo complNo complBo complSo complHo nonacvC dropout `controls' yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m6
			qui reg logantpctPS complTo complNo complBo complSo complHo nonacgC dropout `controls' yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m7
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(complTo complNo complBo complSo complHo nonacgC nonacvC dropout) ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("E" "N" "B" "S" "H" "G" "V") title("OLS TABLE A9 column 2 - OLS without control for GPA") compress collabels(none) 
			
		**** TABLE A9 contd - column 3
			
			eststo clear
			qui reg logantpctPS complNo complBo complSo complHo nonacgC nonacvC dropout `controls' Jmft yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m1
			qui reg logantpctPS complTo complBo complSo complHo nonacgC nonacvC dropout `controls' Jmft yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m2
			qui reg logantpctPS complTo complNo complSo complHo nonacgC nonacvC dropout `controls' Jmft yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m3
			qui reg logantpctPS complTo complNo complBo complHo nonacgC nonacvC dropout `controls' Jmft yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m4
			qui reg logantpctPS complTo complNo complBo complSo nonacgC nonacvC dropout `controls' Jmft yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m5
			qui reg logantpctPS complTo complNo complBo complSo complHo nonacvC dropout `controls' Jmft yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m6
			qui reg logantpctPS complTo complNo complBo complSo complHo nonacgC dropout `controls' Jmft yr1-yr14 gymnr2-gymnr`regn' if logantpctPS!=.,robust 
			eststo m7
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(complTo complNo complBo complSo complHo nonacgC nonacvC dropout) ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("E" "N" "B" "S" "H" "G" "V") title("TABLE A9 column 3 - OLS w GPA") compress collabels(none) 
			
		**** TABLE A9 - contd columns 1 and 4
		eststo clear
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' Jmft59-Jmft101 gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=.,robust nocons 
			eststo m2
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`compl') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses") ///
			mtitles("Baseline" "KLM") ///
		title("TABLE A9 - KLM ESTIMATES") compress collabels(none) 
			
			
		
			
			
			**** ESTIMATES SEPARATELY FOR MALES AND FEMALES
			
			gen femdist=dist if fem==1
			gen femdist2=dist2 if fem==1
			gen maledist=dist if fem==0
			gen maledist2=dist2 if fem==0
			
			foreach x in femdist femdist2 maledist maledist2 {
					replace `x'=0 if `x'==.
				}
			
			gen male=(Kon==1)
			sum fem if male==1 & logantpctPS!=.
			local nmales = r(N)
			sum fem if male==0 & logantpctPS!=.
			local nfemales = r(N)
			
			
			foreach x in SintNt SintBt SintSt SintHt SintTn SintBn SintSn SintHn SintTb SintNb SintSb SintHb SintTs SintNs SintBs ///
			SintHs SintTh SintNh SintBh SintSh SintTv SintNv SintBv SintSv SintHv SintTg SintNg SintBg SintSg SintHg {
				gen fem`x'=fem*`x'
				gen male`x'=male*`x'
			}
			
			foreach x in complNt complBt complSt complHt complTn complBn complSn complHn complTb complNb complSb complHb complTs complNs ///
							complBs complHs complTh complNh complBh complSh complTv complNv complBv complSv complHv complTg complNg complBg complSg complHg {
				gen fem`x'=fem*`x'
				gen male`x'=male*`x'
			}
			
			local sint femSintTn femSintTb femSintTs femSintTh femSintTg femSintTv femSintNt femSintNb femSintNs femSintNh femSintNg femSintNv femSintBt femSintBn femSintBs femSintBh ///
						femSintBg femSintBv femSintSt femSintSn femSintSb femSintSh femSintSg femSintSv femSintHt femSintHn femSintHb femSintHs femSintHg femSintHv ///
						maleSintTn maleSintTb maleSintTs maleSintTh maleSintTg maleSintTv maleSintNt maleSintNb maleSintNs maleSintNh maleSintNg maleSintNv maleSintBt ///
						maleSintBn maleSintBs maleSintBh maleSintBg maleSintBv maleSintSt maleSintSn maleSintSb maleSintSh maleSintSg maleSintSv maleSintHt maleSintHn maleSintHb maleSintHs maleSintHg maleSintHv
			
			local compl femcomplTn femcomplTb femcomplTs femcomplTh femcomplTg femcomplTv femcomplNt femcomplNb femcomplNs femcomplNh femcomplNg femcomplNv femcomplBt femcomplBn femcomplBs ///
						femcomplBh femcomplBg femcomplBv femcomplSt femcomplSn femcomplSb femcomplSh femcomplSg femcomplSv femcomplHt femcomplHn femcomplHb femcomplHs femcomplHg femcomplHv ///
						malecomplTn malecomplTb malecomplTs malecomplTh malecomplTg malecomplTv malecomplNt malecomplNb malecomplNs malecomplNh malecomplNg malecomplNv malecomplBt malecomplBn ///
						malecomplBs malecomplBh malecomplBg malecomplBv malecomplSt malecomplSn malecomplSb malecomplSh malecomplSg malecomplSv malecomplHt malecomplHn malecomplHb malecomplHs malecomplHg malecomplHv 
			
			local rv = "femdist-maledist2"		// 4-slope model 
			
			local sec tsec-hsec nonac2v nonac2g 
			local controls FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod i.age 
			
			eststo clear
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`compl') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses" "N males = `nmales'" "N females = `nfemales'") ///
			mtitles("Log earnings 4-slope") ///
			title("TABLE A5 COLUMN 3-4 - HETEROGENEITY BY GENDER") compress collabels(none) 

			*** ESTIMATES SEPARATELY FOR INDIVIDUALS WITH HIGH-SKILLED LOW SKILLED PARENTS
			
			sum hi if hi==1 & logantpctPS!=.
			local nhi = r(N)
			sum lo if lo==1 & logantpctPS!=.
			local nlo = r(N)
			gen hidist=dist if hi==1
			gen hidist2=dist2 if hi==1
			gen lodist=dist if lo==1
			gen lodist2=dist2 if lo==1
			
			foreach x in hidist hidist2 lodist lodist2 {
					replace `x'=0 if `x'==.
				}
			
			
			foreach x in SintNt SintBt SintSt SintHt SintTn SintBn SintSn SintHn SintTb SintNb SintSb SintHb SintTs SintNs SintBs SintHs SintTh ///
							SintNh SintBh SintSh SintTv SintNv SintBv SintSv SintHv SintTg SintNg SintBg SintSg SintHg {
				gen hi`x'=hi*`x'
				gen lo`x'=lo*`x'
			}
			
			foreach x in complNt complBt complSt complHt complTn complBn complSn complHn complTb complNb complSb complHb complTs complNs complBs ///
							complHs complTh complNh complBh complSh complTv complNv complBv complSv complHv complTg complNg complBg complSg complHg {
				gen hi`x'=hi*`x'
				gen lo`x'=lo*`x'
			}
			
			local sint hiSintTn hiSintTb hiSintTs hiSintTh hiSintTg hiSintTv hiSintNt hiSintNb hiSintNs hiSintNh hiSintNg hiSintNv hiSintBt hiSintBn hiSintBs hiSintBh hiSintBg hiSintBv ///
							hiSintSt hiSintSn hiSintSb hiSintSh hiSintSg hiSintSv hiSintHt hiSintHn hiSintHb hiSintHs hiSintHg hiSintHv ///
							loSintTn loSintTb loSintTs loSintTh loSintTg loSintTv loSintNt loSintNb loSintNs loSintNh loSintNg loSintNv loSintBt loSintBn loSintBs loSintBh loSintBg loSintBv ///
							loSintSt loSintSn loSintSb loSintSh loSintSg loSintSv loSintHt loSintHn loSintHb loSintHs loSintHg loSintHv
			
			local compl hicomplTn hicomplTb hicomplTs hicomplTh hicomplTg hicomplTv hicomplNt hicomplNb hicomplNs hicomplNh hicomplNg hicomplNv hicomplBt hicomplBn hicomplBs hicomplBh ///
							hicomplBg hicomplBv hicomplSt hicomplSn hicomplSb hicomplSh hicomplSg hicomplSv hicomplHt hicomplHn hicomplHb hicomplHs hicomplHg hicomplHv ///
							locomplTn locomplTb locomplTs locomplTh locomplTg locomplTv locomplNt locomplNb locomplNs locomplNh locomplNg locomplNv locomplBt locomplBn locomplBs locomplBh ///
							locomplBg locomplBv locomplSt locomplSn locomplSb locomplSh locomplSg locomplSv locomplHt locomplHn locomplHb locomplHs locomplHg locomplHv
			local rv = "hidist-lodist2"
			
			local sec tsec-hsec nonac2v nonac2g 
			local controls FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod i.age 
		
			eststo clear
			qui ivregress 2sls logantpctPS (`compl' = `sint') `controls' i.fst `sec' `rv' gymnr2-gymnr`regn' yr1-yr14 if logantpctPS!=. [pw=wgt151],robust nocons 
			eststo m1
			esttab using tables.rtf,append cells(b(star fmt(%9.3fc)) se(par fmt(%9.3fc))) nolz onecell keep(`compl') ///
			star(* 0.10 ** 0.05 *** 0.01) label varwidth(5) modelwidth(5) nonumbers stats(N,fmt(%11.0gc)) addnot("Standard errors within parantheses" "N lowskilled = `nlo'" "N highskilled = `nhi'") ///
			mtitles("Log earnings 4-slope") ///
			title("TABLE A5 COLUMN 5-6 - HETEROGENEITY BY PARENTAL BACKGROUND") compress collabels(none) 
