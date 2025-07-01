
******This program uses the baseline data, generates the large set of explanatory variables needed for our baseline regressions. 
******This is needed since the tests require that the data is stacked in two versions on top of one another


** The data is used to compare estimates in Appendix Table A9, cols 1 and 2/3, ie, Baseline vs OLS with and without control for Jmft

** BEWARE! Each GMM took about 2h to converge on the server

clear
capture log close

log using "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\log_TableA9_data.log",replace

set more off, permanently		

global file "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"

cd "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"

		*** THIS FILE CREATES THE DATA NEEDED FOR TESTS RELATED TO TABLE A9
		
		** It requires that baseline data is stacked, we then run GMM where "DRS==1" is the data for our model, while "DRS=0" is the data for KLM
		** GMM is needed, since "ivreg" does not allow testing across models
		** GMM estimation instead of  ivreg in order to run suest-type of tests
		
		* DRS have weight=RD triangular weights=wgt151
		* KLM is unweighted IV=1
		
			
			
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
		
		egen gymnreg=group(Region)			// region dummies
		sum gymnreg
		local regn = r(max)
			forvalues x=1/`regn' {
				gen gymnr`x'=(gymnreg==`x')
			}
		
		tabulate ProdAr, generat(yr)		// year dummies
		
		
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
				
				gen dropout=(completed==0)
		
		save "$file\Table_A9_AEJ.dta",replace
