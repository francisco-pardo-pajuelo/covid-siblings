***************************************************************************
*Replication code for results from US. 
*This code generates all of the US based estimates and figures in the paper
***************************************************************************

clear all
set scheme s1mono, perm
set matsize 1000
global opts	a f plain coll(none) nodep nomti c(b(star fmt(%9.3f)) se(abs par fmt(%9.3f))) star(* .10 ** .05 *** .01) noobs
global optsN	a f plain coll(none) nodep nomti c(b(star fmt(%9.3f)) se(abs par fmt(%9.3f))) star(* .10 ** .05 *** .01) 


global data 	""
global paper 	""


// Results for Main Figures and Tables 
**************************************
*Table 2: Summary Stats
program define t_sumstats
qui {

	// Start with universe of SAT takers

	cd "$data"
	use 	siblings birthorder *cohort *cb_rec_id ///
			oldest_female oldest_race oldest_income oldest_fatheduc oldest_motheduc ///
			oldest_maxtotal oldest_scoresends ///
			oldest_first_collid oldest_first_4yr oldest_first_2yr ///
			female tooksat takes maxtotal scoresends ///
			first_collid first_4yr first_2yr ///
			using siblings.dta, clear
	
	// Merge to target college subset
	
	merge 1:1 cohort cb_rec_id using final.dta, keepusing(cutscore *went uncertain*) nogen
						
	// Merge to IPEDS data
	
	rename oldest_first_collid unitid
	g year = oldest_cohort + 1
	merge m:1 unitid year using ipeds.dta, keep(match master) nogen
	foreach var of varlist instnm-satmt75 {
		rename `var' oldest_`var'
	}
	drop year
	rename unitid oldest_first_collid
	
	rename first_collid unitid
	g year = cohort + 1
	replace year=2014 if year==2015
	merge m:1 unitid year using ipeds.dta, keep(match master) nogen
	drop year
	rename unitid first_collid
	
	drop *satmt75 *grad_*yr *fips *instnm *stabbr *zip* *tuition*
	
	// RD variables
	
	g dist 			= oldest_maxtotal - cutscore
			
	// Define college sector and cost
	
	g oldest_any2 	= inlist(oldest_sector,4,5,6)
	egen oldest_netprice = rowmax(oldest_nprice*) // Having already back-filled 2004 and 2005 with 2006
		replace oldest_netprice = 0 if oldest_netprice==. 
	g any2 	= inlist(sector,4,5,6)
	egen netprice = rowmax(nprice*)
		replace netprice = 0 if netprice==.
	foreach var of varlist oldest_netprice {
		replace `var' = `var'/1000
		replace `var' = `var'/0.80 if oldest_cohort==2004
		replace `var' = `var'/0.82 if oldest_cohort==2005
		replace `var' = `var'/0.85 if oldest_cohort==2006
		replace `var' = `var'/0.88 if oldest_cohort==2007
		replace `var' = `var'/0.91 if oldest_cohort==2008
		replace `var' = `var'/0.91 if oldest_cohort==2009
		replace `var' = `var'/0.92 if oldest_cohort==2010
		replace `var' = `var'/0.95 if oldest_cohort==2011
		replace `var' = `var'/0.97 if oldest_cohort==2012
		replace `var' = `var'/0.98 if oldest_cohort==2013
	}
	foreach var of varlist netprice {
		replace `var' = `var'/1000
		replace `var' = `var'/0.80 if cohort==2004
		replace `var' = `var'/0.82 if cohort==2005
		replace `var' = `var'/0.85 if cohort==2006
		replace `var' = `var'/0.88 if cohort==2007
		replace `var' = `var'/0.91 if cohort==2008
		replace `var' = `var'/0.91 if cohort==2009
		replace `var' = `var'/0.92 if cohort==2010
		replace `var' = `var'/0.95 if cohort==2011
		replace `var' = `var'/0.97 if cohort==2012
		replace `var' = `var'/0.98 if cohort==2013
	}	
	compress
	
	// Define college PSAT scores
		
	rename oldest_first_collid ASC_UnitID_1
	rename oldest_cohort year
	merge m:1 ASC_UnitID_1 year using psat.dta, keep(match master) nogen
	rename psat oldest_psat
	rename ASC_UnitID_1 oldest_first_collid
	rename year oldest_cohort
	
	rename first_collid ASC_UnitID_1
	rename cohort year
	merge m:1 ASC_UnitID_1 year using psat.dta, keep(match master) nogen
	rename ASC_UnitID_1 first_collid
	rename year cohort
	
	// Define college BA completion rates
	
	rename oldest_first_collid ASC_UnitID_1
	merge m:1 ASC_UnitID_1 using gradrate.dta, keep(match master) nogen
	rename gradrate oldest_gradrate
	rename ASC_UnitID_1 oldest_first_collid
	rename first_collid ASC_UnitID_1
	merge m:1 ASC_UnitID_1 using gradrate.dta, keep(match master) nogen
	rename ASC_UnitID_1 first_collid
	replace oldest_gradrate=0 if oldest_gradrate==.
	replace gradrate=0 if gradrate==.
	
	// Variables
	
	label var siblings "Siblings"
	g white = (oldest_race==7)
	label var white "White"
	g black = (oldest_race==3)
	label var black "Black"
	g hisp = (oldest_race==4|oldest_race==5|oldest_race==6)
	label var hisp "Hispanic"
	g asian = (oldest_race==2)
	label var asian "Asian"
	replace oldest_income = oldest_income/1000
		replace oldest_income = . if oldest_income<0
		
	xtile inc_q3 = oldest_inc if oldest_income!=., n(3)
	g lowinc = inc_q3==1
	g midinc = inc_q3==2
	g hiinc = inc_q3==3
	label var lowinc "Income < $50,000"
	label var midinc "Income $50,000-100,000"
	label var hiinc "Income >$100,000"
		
	label var oldest_income "Income (000s)"
	g momcoll = inrange(oldest_motheduc,5,9)
	label var momcoll "Mother attended college"
	label var oldest_female "Oldest sibling female"
	label var female "Female" 
	
	label var oldest_maxtotal "Maximum SAT score"
	label var oldest_scoresends "Score sends"
	label var tooksat "Took SAT"
	label var maxtotal "Maximum SAT score"
	label var scoresends "Score sends"
	
	label var oldest_first_4 "Enrolled in 4-year college"
	label var oldest_gradrate "Colleges BA completion rate"
	label var oldest_psat "Colleges peer quality"
	
	label var first_4 "Enrolled in 4-year college"
	label var gradrate "Colleges BA completion rate"
	label var psat "Colleges peer quality"
		
	// Clean up
	
	drop *sector* *nprice* old_enroll *collid *cb_rec_id *any2 *enroll*
	g fullsample = 1
	g onlykids = (siblings==1)
	g sibs = (siblings>=2)
	g targets = (cutscore!=.)
	g rdsample = (cutscore!=.&inrange(abs(dist),10,93))
	g targetcollege = 1 if (oldest_went==1)
	sort oldest_gradrate targetcollege
	by oldest_gradrate: replace targetcollege = . if _n!=1
	replace targetcollege = 0 if targetcollege==.
	compress
	save meanstable.dta, replace			
		
	// Make means table
	
	cd "$data"
	use meanstable.dta, clear

	g rd_uncertain = (rdsample==1)&(uncertain_33)
	g rd_probable = (rdsample==1)&(!uncertain_33)	
	
	mat t_meansa = (0,0,0,0,0,0,0)
	foreach y of varlist siblings white black hisp asian female oldest_income lowinc midinc hiinc momcoll {
		mat `y' = (0)
		mat rownames `y' = "`: variable label `y''"
		foreach x of varlist onlykids sibs targets rdsample rd_uncertain rd_probable {
			qui sum `y' if `x' 
			mat `y'`x' = (r(mean))
			mat `y' = (`y', `y'`x')
		}
		mat t_meansa = (t_meansa \ `y')
		
		mat `y'sd = (0)
		mat rownames `y'sd = "SD"
		foreach x of varlist onlykids sibs targets rdsample rd_uncertain rd_probable {
			qui sum `y' if `x' 
			mat `y'`x'_sd = (r(sd))
			mat `y'sd = (`y'sd, `y'`x'_sd)
		}
		mat t_meansa = (t_meansa \ `y'sd)		
		
	}
	mat t_meansa = t_meansa[2...,2...]	

	
	
	mat t_meansb = (0,0,0,0,0,0,0)
	foreach y of varlist oldest_maxtotal oldest_scoresends oldest_first_4yr oldest_gradrate oldest_psat {
		mat `y' = (0)
		mat rownames `y' = "`: variable label `y''"
		foreach x of varlist onlykids sibs targets rdsample rd_uncertain rd_probable {
			qui sum `y' if `x' [aw=`x']
			mat `y'`x' = (r(mean))
			mat `y' = (`y', `y'`x')
		}
		mat t_meansb = (t_meansb \ `y')
	
		mat `y'sd = (0)
		mat rownames `y'sd = "SD"
		foreach x of varlist onlykids sibs targets rdsample rd_uncertain rd_probable {
			qui sum `y' if `x' 
			mat `y'`x'_sd = (r(sd))
			mat `y'sd = (`y'sd, `y'`x'_sd)
		}
		mat t_meansb = (t_meansb \ `y'sd)
		}
		
	mat t_meansb = t_meansb[2...,2...]		

	mat t_meansc = (0,0,0,0,0,0,0)
	foreach y of varlist tooksat maxtotal scoresends first_4yr gradrate psat {
		mat `y' = (0)
		mat rownames `y' = "`: variable label `y''"
		foreach x of varlist onlykids sibs targets rdsample rd_uncertain rd_probable {
			qui sum `y' if `x'
			mat `y'`x' = (r(mean))
			mat `y' = (`y', `y'`x')
		}
		mat t_meansc = (t_meansc \ `y')
	
		mat `y'sd = (0)
		mat rownames `y'sd = "SD"
		foreach x of varlist onlykids sibs targets rdsample rd_uncertain rd_probable {
			qui sum `y' if `x' 
			mat `y'`x'_sd = (r(sd))
			mat `y'sd = (`y'sd, `y'`x'_sd)
		}
		mat t_meansc = (t_meansc \ `y'sd)
		}
		
	mat t_meansc = t_meansc[2...,2...]		

	mat t_meansN = (0,0,0,0,0,0,0)
		mat N = (0)
		mat rownames N = "N"
		foreach x of varlist onlykids sibs targets rdsample rd_uncertain rd_probable {
			qui sum cohort if `x'
			mat N`x' = (r(N))
			mat N = (N, N`x')
		}
		mat t_meansN = (t_meansN \ N)
	mat t_meansN = t_meansN[2...,2...]	
		
	cd "$paper"
	file open  t	using t_sum_us.tex, replace write
	file write t	"\begin{table}[htbp] \centering" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Sample Characteristics}" _n "\label{t_sum_us}" _n ///
					"\begin{tabular*}{1\textwidth}{@{\extracolsep{\fill}}l*{6}{c}}" _n "\midrule" _n ///
					"&			&		&Older		&\multicolumn{3}{c}{\underline{Regression discontinuity sample}}\\" _n ///
					"&			&		&sibling							\\" _n ///
					"&			&		&applied to	&			&Uncertain	&Probable	\\" _n ///
					"&Only		&Sibling&target		&All		&college-	&college-	\\" _n ///
					"&children	&sample	&college	&students	&goers		&goers		\\" _n ///
					"&(1)&(2)&(3)&(4)&(5)&(6)\\" _n ///
					"\midrule" _n "(A) Demographics\\" _n "\cmidrule{1-1}" _n
	file close t	
	esttab m(t_meansa, f(2 2 2 2 2 2)) using t_sum_us.tex, s(, lay(`""')) a f plain coll(none) nodep nomti
	file open  t 	using t_sum_us.tex, append write
	file write t	"\cmidrule{1-1}" _n "(B) Older siblings\\" _n "\cmidrule{1-1}" _n
	file close t	
	esttab m(t_meansb, f(2 2 2 2 2 2)) using t_sum_us.tex, s(, lay(`""')) a f plain coll(none) nodep nomti
	file open  t 	using t_sum_us.tex, append write
	file write t	"\cmidrule{1-1}" _n "(C) Younger siblings\\" _n "\cmidrule{1-1}" _n
	file close t	
	esttab m(t_meansc, f(2 2 2 2 2 2)) using t_sum_us.tex, s(, lay(`""')) a f plain coll(none) nodep nomti
	esttab m(t_meansN, f(%11.0fc)) using t_sum_us.tex, a f plain coll(none) nodep nomti
	file open  t 	using t_sum_us.tex, append write
	file write t 	"\midrule" _n "\end{tabular*}" _n ///
					"\begin{tabular*}{1\textwidth}{p{6.3in}}" _n ///
					"\footnotesize Notes: Notes: Mean values of key variables are shown. " ///
					"Columns 1 and 2 divide the high school classes of 2004-14 into those with no observed siblings and those with at least one observed sibling. " ///
					"Column 3 includes only those families in which the oldest sibling applied to one of the target colleges. " ///
					"Column 4 limits that sample to those within 93 SAT points of the relevant threshold, excluding those on the threshold itself. " ///
					"Columns 5 and 6 divide the RD sample into those in the bottom third and top two-thirds of the distribution of predicted four-year college enrollment. " ///
					"College quality is measured by the fraction of students starting at that college who complete a B.A. anywhere within six years and the mean standardized PSAT score of students at that college." ///
					"\end{tabular*}" _n "\end{table}" _n 	
	file close t	
}
end


*Table 4: US Main Results
program define t_us_main 
{

	cd $data
	use final.dta if inrange(abs(dist),10,93), clear
	
	g byte oneminuswent = 1-oldest_went
	foreach y of varlist  first_4yr first_2yr gradrate psat netprice distance50 applied went {
		g `y'_Y0 = `y'*oneminuswent
	}	
	
	expand 2, gen(new)
	g col = 1*!new+2*(new&uncertain_33)+3*(new&!uncertain_33)
	forval x=1/3 {
		preserve
		keep if col==`x'
		foreach y of varlist  first_4yr first_2yr gradrate psat netprice distance50 applied went {
			ivreghdfe `y' dist above_dist (oldest_went = above), cluster(famid) a(oc_tc_c)
			est sto r`x'_`y'
			 ivreghdfe `y'_Y0 dist above_dist (oneminuswent = above), cluster(famid) a(oc_tc_c)
			local ccm = _b[oneminuswent]
			estadd scalar ccm = `ccm'		
			est sto s`x'_`y'
		}	
		restore
	}			
			
	cd $paper	
	file open  t	using t_us_ext_margin.tex, replace write
	file write t	"\begin{table}[htbp!] \centering" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n ///
					"\caption{Sibling Spillovers on Total College Enrollment and College Quality in the US}" _n "\label{t_us_ext_margin}" _n ///
					"\begin{tabular*}{1\textwidth}{@{\extracolsep{\fill}}l*{8}{c}}" _n "\midrule" _n ///
					"&\multicolumn{2}{c}{College type}&\multicolumn{2}{c}{College quality}&\multicolumn{2}{c}{Price, location}&\multicolumn{2}{c}{Target College}\\" _n ///
					"\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9}" _n ///
					"&		&		&			&			&		&50+ & &\\" _n ///
					"&		&		&B.A.		&Peer		&Net	&miles & & \\" _n ///
					"&4-year	&2-year	&completion	&quality	&price	&from& & \\" _n ///
					"&college&college&rate		&(Z-score)	&(000s)	&home & Applies & Enrolls\\" _n ///
					"&(1)&(2)&(3)&(4)&(5)&(6)&(7) &(8)\\" _n ///
					"\midrule" _n 
	file close t	
	esttab r1* using t_us_ext_margin.tex, k(oldest_went) coeflabel(oldest_went "All students") $opts 
	esttab s1* using t_us_ext_margin.tex, drop(*) s(ccm, l("Control complier $\hat{Y}$") f(2) lay(@ `""')) $opts 
	esttab r2* using t_us_ext_margin.tex, k(oldest_went) coeflabel(oldest_went "Uncertain college-goers") $opts 
	esttab s2* using t_us_ext_margin.tex, drop(*) s(ccm, l("Control complier $\hat{Y}$") f(2) lay(@ `""')) $opts 
	esttab r3* using t_us_ext_margin.tex, k(oldest_went) coeflabel(oldest_went "Probable college-goers") $opts 
	esttab s3* using t_us_ext_margin.tex, drop(*) s(ccm, l("Control complier $\hat{Y}$") f(2) lay(@)) $opts 
	file open  t 	using t_us_ext_margin.tex, append write
	file write t 	"\midrule" _n "\end{tabular*}" _n ///
					"\begin{tabular*}{1\textwidth}{p{6.3in}}" _n ///
					"\footnotesize Notes: Heteroskedasticity robust standard errors clustered by family are in parentheses (* p$<$.10 ** p$<$.05 *** p$<$.01). " ///
					"Each coefficient is an instrumental variables estimate of the impact of an older sibling's enrollment in the target college on younger siblings' college choices, using admissibility as an instrument. " ///
					"Each estimate comes from a local linear regression with a bandwidth of 93 SAT points, a donut hole specification that excludes observations on the threshold, and fixed effects for each combination of older sibling's cohort, younger sibling's cohort, and older sibling's target college. " /// 
					"The first row includes all students, while the second and third rows divide the sample into those in the bottom third and top two-thirds of the distribution of predicted four-year college enrollment. " ///
					"College quality is measured by the fraction of students starting at that college who complete a B.A. anywhere within six years (column 4) and the mean standardized PSAT score of students at that college (column 5). " ///
					"Also listed below each coefficient is the predicted value of the outcome for control compliers." ///
					"\end{tabular*}" _n "\end{table}" _n 
	file close t
	estimates clear
	
	*REDUCED FORM
	cd $data
	use final.dta if inrange(abs(dist),10,93), clear
	
	g byte oneminuswent = 1-oldest_went
	foreach y of varlist  first_4yr first_2yr gradrate psat netprice distance50 applied went {
		g `y'_Y0 = `y'*oneminuswent
	}	
	
	expand 2, gen(new)
	g col = 1*!new+2*(new&uncertain_33)+3*(new&!uncertain_33)
	forval x=1/3 {
		preserve
		keep if col==`x'
		foreach y of varlist  first_4yr first_2yr gradrate psat netprice distance50 applied went {
			reghdfe `y' above dist above_dist , cluster(famid) a(oc_tc_c)

		}	
		restore
	}
}
end


*Table 7: Variation in effects by age difference and gender
program define t_mechanisms 
	{
	cd $data
	use final.dta if inrange(abs(dist),10,93), clear
	
	g byte oneminuswent = 1-oldest_went
	foreach y of varlist went first_4yr applied {
		g `y'_Y0 = `y'*oneminuswent
	}	
	
	g same_gender = (female==oldest_female)
	
	
	g above_same = above*same_gender
	g above_diff = above*(1-same_gender)
	g oldest_went_same = oldest_went*same_gender
	g oldest_went_diff = oldest_went*(1-same_gender)
	g diff_gender = same_gender==0
	
	g age5 = agediff>5 
	g above_age5 = above*age5
	g oldest_went_age5 = oldest_went*age5
		
	
	foreach y of varlist  first_4yr applied {
		
		qui reghdfe `y' dist above_dist same_gender above above_same, cluster(famid) a(oc_tc_c)
			est sto rf_gender_`y'

		ivreghdfe `y' dist above_dist same_gender (oldest_went oldest_went_same = above above_same ), cluster(famid) a(oc_tc_c)
			est sto iv_gender_`y'
			
		qui reghdfe `y' dist above_dist age5 above above_age5 , cluster(famid) a(oc_tc_c)
			est sto rf_age_`y'

			 ivreghdfe `y' dist above_dist age5 (oldest_went oldest_went_age5 = above above_age5 ), cluster(famid) a(oc_tc_c)
			est sto iv_age_`y'		
		}	
		
		
		*Also based on enrollment
				foreach y of varlist  first_4yr went {
			 ivreghdfe `y' dist above_dist same_gender (oldest_went oldest_went_same = above above_same ), cluster(famid) a(oc_tc_c)
			 ivreghdfe `y' dist above_dist age5 (oldest_went oldest_went_age5 = above above_age5 ), cluster(famid) a(oc_tc_c)
		}	
		
		
*Checks with additional age groups for referees
foreach x in 2 4 10 {
g age_leq`x' = agediff<=`x'

	g oldest_went_age`x' = oldest_went*age_leq`x'
	g above_age`x' = above*age_leq`x'

	}
	
	foreach y of varlist maxtotal   {
		g `y'_Y0 = `y'*oneminuswent
	}	
	
	
		foreach y of varlist maxtotal  {
		
	
			 ivreghdfe `y' dist above_dist age_leq* ( oldest_went_age2 oldest_went_age4 oldest_went_age10 = above_age2 above_age4 above_age10 ), cluster(famid) a(oc_tc_c)
			est sto iv_age_`y'	
			
				
	ivreghdfe `y'_Y0 dist above_dist (oneminuswent = above), cluster(famid) a(oc_tc_c)
			local ccm = _b[oneminuswent]
			estadd scalar ccm = `ccm'		
			est sto ccm_`out'
		}	
	
*additional gender groupings

foreach y of varlist  first_4yr applied went {
			
			 ivreghdfe `y' dist above_dist same_gender (oldest_went oldest_went_same = above above_same ) if oldest_female==0, cluster(famid) a(oc_tc_c)
			est sto iv2_gender_`y'
			
			 ivreghdfe `y' dist above_dist same_gender (oldest_went oldest_went_same = above above_same ) if oldest_female==1, cluster(famid) a(oc_tc_c)
			est sto iv2_gender_`y'
			
			}
			
foreach y of varlist  first_4yr applied went {
			
			 ivreghdfe `y' dist above_dist (oldest_went  = above  ) if same_gender==0, cluster(famid) a(oc_tc_c)
			est sto iv3_gender_`y'
			
			 ivreghdfe `y' dist above_dist  (oldest_went  = above ) if same_gender==1, cluster(famid) a(oc_tc_c)
			est sto iv3_gender_`y'
			
			}
	}
	
	end


*Table 8: Additional heterogeneity analyss - including variation by older sibling dropout
	program define t_heterog
	{
	    cd $data
	use final.dta if inrange(abs(dist),10,93), clear
	
	g byte oneminuswent = 1-oldest_went
	foreach y of varlist went first_4yr applied {
		g `y'_Y0 = `y'*oneminuswent
	}	
	
	g persist = oldest_first_persist if oldest_cohort<=2010
	g persist2 = (oldest_first_persist>=2) if (oldest_cohort<=2012)
	g persist3 = (oldest_first_persist>=3) if (oldest_cohort<=2011)
	g persist4 = (oldest_first_persist>=4) if (oldest_cohort<=2010)
	g persist5 = (oldest_first_persist>=5) if (oldest_cohort<=2009)
	g persist6 = (oldest_first_persist>=6) if (oldest_cohort<=2008)
	g persist7 = (oldest_first_persist>=7) if (oldest_cohort<=2007)
	g ba = ((oldest_first_badate)!=.) if (oldest_cohort<=2010)
	
	g ba4 = (year(oldest_first_badate)-oldest_cohort<=4) if oldest_cohort<=2010
	
	g oldest_dropout = persist4==0|persist3==0|persist2==0|persist==0
		replace oldest_dropout = 1 if persist5==0 & ba!=1 & oldest_cohort<=2009
		replace oldest_dropout = 1 if persist6==0 & ba!=1 & oldest_cohort<=2008
		replace oldest_dropout = 1 if persist7==0 & ba!=1 & oldest_cohort<=2007
		
	sum oldest_income
	g oldest_inc_sd = (oldest_income - r(mean))/r(sd)
	g oldest_inc_1000 = oldest_income/1000
	g oldest_went_psat = oldest_went*oldest_psat
	g above_psat = above*oldest_psat
	g oldest_went_gradrate = oldest_went*oldest_gradrate
	g above_gradrate = above*oldest_gradrate
	g oldest_went_drop = oldest_went*oldest_dropout
	g above_drop = above*oldest_dropout
	g oldest_went_inc = oldest_went*oldest_inc_sd
	g above_inc = oldest_went*oldest_inc_sd
		
	foreach y in  first_4yr  applied went {
		foreach x in  psat gradrate inc {
				 ivreghdfe `y' dist above_dist (oldest_went oldest_went_`x' = above above_`x' ), cluster(famid) a(oc_tc_c)
				est sto iv_`x'_`y'
			}	
	}
	
	*Table 8 - by older sibling's dropout (this is not first year drop out rate for table 7 - that stat isn't in our data)

	foreach x in drop  {
		foreach y in applied1 applied first_4yr went {
			 ivreghdfe `y' dist above_dist  (oldest_went oldest_went_`x' = above above_`x' ), cluster(famid) a(oc_tc_c)
			est sto iv_`x'_`y'
		}
	}
	
	*variation in dropout effects by sibling age 
		foreach x in drop  {
			foreach y in applied1 applied first_4yr went {
			
				ivreghdfe `y' dist above_dist  (oldest_went oldest_went_`x' = above above_`x' ) if inrange(agediff,2,10), cluster(famid) a(oc_tc_c)
					est sto iv_`x'2_`y'
				ivreghdfe `y' dist above_dist  (oldest_went oldest_went_`x' = above above_`x' ) if inrange(agediff,3,10), cluster(famid) a(oc_tc_c)
					est sto iv_`x'3_`y'
				ivreghdfe `y' dist above_dist  (oldest_went oldest_went_`x' = above above_`x' ) if inrange(agediff,4,10), cluster(famid) a(oc_tc_c)
					est sto iv_`x'4_`y'
			 ivreghdfe `y' dist above_dist  (oldest_went oldest_went_`x' = above above_`x' ) if inrange(agediff,5,10), cluster(famid) a(oc_tc_c)
					est sto iv_`x'5_`y'
				}
		}
	}
	end
	
*Table 9: Impact on academic performance and applications
	program define t_acad_perf 
{
cd $data
	use final.dta if inrange(abs(dist),10,93), clear
	
	g byte oneminuswent = 1-oldest_went
	foreach y of varlist tooksat applied1 maxtotal   {
		g `y'_Y0 = `y'*oneminuswent
	}	
	
foreach out in tooksat applied1 maxtotal {
	ivreghdfe `out'  dist above_dist (oldest_went = above) , cluster(famid) a(oc_tc_c)
		eststo iv_us_`out'	
	
	ivreghdfe `out'_Y0 dist above_dist (oneminuswent = above), cluster(famid) a(oc_tc_c)
			local ccm = _b[oneminuswent]
			estadd scalar ccm = `ccm'		
			est sto ccm_`out'
		}		
		}
		end

	
*Fig 2: First stage
	program define f_oldertarget
qui {

	cd $data
	use final.dta if inrange(abs(dist),0,100), clear
	
	foreach var of varlist oldest_went oldest_first_4yr oldest_first_any oldest_psat oldest_gradrate {

		qui reg `var' above dist above_dist if dist<0
		predict `var'l if dist<=0
		qui reg `var' above dist above_dist if dist>0
		predict `var'r if dist>=0
		
		g `var'0 = `var' if dist==0
		replace `var'=. if dist==0
		
	}
	
	collapse oldest_went* oldest_first_4yr* oldest_first_any* oldest_gradrate* oldest_psat* (count) di, by(dist)
		
	cd $paper
	
	scatter oldest_went oldest_went0 oldest_wentl oldest_wentr dist [aw=di], 	///
								msym(O O none none) connect(i i l l) lp(blank blank solid solid) legend(off) ///
								mcolor(black black) mfcolor(black none) msize(small small) xline(0, lw(vthin)) ///
								xtitle("Older sibling's distance to threshold", height(4)) ///
								ytitle("Older sibling enrolled in target college", height(4)) ylab(minmax, format(%9.2f)) 
	graph export f_oldertarget.pdf, replace
}
end
	
	
*Fig 4: Impact on younger sibs
	program define f_younger
qui {

	cd $data
	use final.dta if inrange(abs(dist),0,100), clear
	grstyle init
	grstyle set plain, horizontal grid
	
	foreach var of varlist applied went first_4yr  {
		qui reg `var' above dist above_dist if dist<0
		predict `var'l if dist<=0
		qui reg `var' above dist above_dist if dist>0
		predict `var'r if dist>=0
		g `var'0 = `var' if dist==0
		replace `var'=. if dist==0
	}
	collapse applied* went* first_4yr*  (count) di, by(dist)
		
	cd $paper
	scatter applied applied0 appliedl appliedr dist [aw=di], ///
								msym(O O none none) connect(i i l l) lp(blank blank solid solid) legend(off) ///
								mcolor(black black) mfcolor(black none) msize(small small) xline(0, lw(vthin)) ///
								 xtitle("(a) Applied to Target", size(medsmall)) ///
								saving(a.gph, replace)
	scatter first_4yr first_4yr0 first_4yrl first_4yrr dist [aw=di], ///									
								msym(O O none none) connect(i i l l) lp(blank blank solid solid) legend(off) ///
								mcolor(black black) mfcolor(black none) msize(small small) xline(0, lw(vthin)) ///
								xtitle("(b) Enroll in 4-Year College", size(medsmall)) ///
								saving(b.gph, replace)
	scatter went went0 wentl wentr dist [aw=di], ///
								msym(O O none none) connect(i i l l) lp(blank blank solid solid) legend(off) ///
								mcolor(black black) mfcolor(black none) msize(small small) xline(0, lw(vthin)) ///
								xtitle("(c) Enroll in Target College", size(medsmall)) ///
								saving(c.gph, replace)
								

	
	graph combine a.gph b.gph c.gph, rows(3) imargin(medsmall) xsize(6) ysize(11) saving(f_us_younger)
	graph export f_us_younger.pdf, replace
	rm a.gph 
	rm b.gph
	rm c.gph
	grstyle init
	grstyle nogrid
}
	end
	
	
*Run programs
t_sumstats
t_us_main
t_mechanisms
t_heterog
t_acad_perf
f_oldertarget
f_younger 
	
