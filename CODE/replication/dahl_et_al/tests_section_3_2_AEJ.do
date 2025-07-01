** Program to arrive at estimates mentioned in Section 3.2 on the exclusion restrictionre
* we write in footnote 18 "...we find a0.7 percentage point increase (se=.3) in dropping out of high school and a 
* 2.8 percentage point decrease (se=.6) in the probability of switching to the non-academic track"
* We also write (but dont show the results) that "When we re-run our analysis excluding those who drop out or switch 
* to the non-academic track, none of the resulting estimates are statsitically different from baseline"

clear
capture log close

log using "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\log_test_section3_2.log",replace

set more off, permanently		

global file "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"

cd "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"

		
****
*	- Section 3.2 we state "when we re-run our analysis excluding those who drop out or switch to the non-academic track..." 
*		"none of the resulting estimates are statistically different from the baseline" 
****

	**** these tests are run using GMM and take 3-8 hours
		
		*** THE DO-FILE "Table A9_data.do" CREATES THE DATA FILE USED HERE (BASELINE FILE EXTENDED WITH LARGE NUMBER OF EXPLANATORY DUMMY VARIABLES)
		
		** The test here requires that baseline data is stacked, we then run GMM where "DRS==1" is the data for our model, while "DRS=0" is the data for KLM
		** GMM is needed, since "ivreg" does not allow testing across models
		** GMM estimation instead of  ivreg in order to run suest-type of tests
		
		* DRS have weight=RD triangular weights=wgt151
		* KLM is unweighted IV=1
		
			
		
		use "$file\Table_A9_AEJ.dta",clear
		
		gen drs=1
		gen w_suest=wgt151
		
		append using "$file\Table_A9_AEJ.dta", force
		
		replace drs=0 if drs==.
		replace w_suest=wgt151 if w_suest==. 

	
		gen fst_NatSc=fst==44
		gen fst_Engin=fst==59
		gen fst_SocSc=fst==51
		gen fst_Hum=fst==28
		
		gen age_15=age==15
		gen age_16=age==16
		gen age_17=age==17
		gen age_18=age==18
				
		* 1. exclude those with second choice non-academic n=192124
		* (the exclusion restriction only relates to academic choices)
		
		gen nosample=(nonac2v==1 | nonac2g==1)
		
		keep if nosample!=1
		
		* 2. what do they complete and not complete
		
		* dropout
		
		drop dropout
		gen dropout = completed==0 
		
		replace complT=(completed==59)
		replace complN=(completed==44 | completed==45)
		replace complB=(completed==10)
		replace complS=(completed==51 | completed==52)
		replace complH=(completed==28)
		
		gen compl_academic = complT==1 | complN==1 | complB==1 | complS==1 | complH==1
		
		gen switchers= compl_academic==0 & dropout==0
		
		drop if (switchers==1 | dropout==1) & drs==0
		
		keep if logantpctPS!=.
		
		
		*3. gmm exclusion restriction by dropping non-completers within all academic
		
		
		* Our Table 5 model - 
		
		
		local xvar dist dist2 fst_Engin fst_NatSc fst_SocSc fst_Hum tsec nsec bsec ssec ///
					FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod age_15 age_16 age_17 age_18 ///
					gymnr2 gymnr3 gymnr4 gymnr5 gymnr6 gymnr7 gymnr8 gymnr9 gymnr10 gymnr11 gymnr12 gymnr13 gymnr14 gymnr15 gymnr16 gymnr17 gymnr18 gymnr19 gymnr20 ///
					gymnr21 gymnr22 gymnr23 gymnr24 gymnr25 gymnr26 gymnr27 gymnr28 gymnr29 gymnr30 gymnr31 gymnr32 gymnr33 gymnr34 gymnr35 gymnr36 gymnr37 gymnr38 gymnr39 gymnr40 ///
					gymnr41 gymnr42 gymnr43 gymnr44 gymnr45 gymnr46 gymnr47 gymnr48 gymnr49 gymnr50 gymnr51 gymnr52 gymnr53 gymnr54 gymnr55 gymnr56 gymnr57 gymnr58 gymnr59 gymnr60 ///
					gymnr61 gymnr62 gymnr63 gymnr64 gymnr65 gymnr66 gymnr67 gymnr68 gymnr69 gymnr70 gymnr71 gymnr72 gymnr73 gymnr74 gymnr75 gymnr76 gymnr77 gymnr78 gymnr79 gymnr80 ///
					gymnr81 gymnr82 gymnr83 gymnr84 gymnr85 gymnr86 gymnr87 gymnr88 gymnr89 gymnr90 gymnr91 gymnr92 gymnr93 gymnr94 gymnr95 gymnr96 gymnr97 gymnr98 gymnr99 gymnr100 ///
					gymnr101 gymnr102 gymnr103 gymnr104 gymnr105 gymnr106 gymnr107 gymnr108 gymnr109 gymnr110 gymnr111 gymnr112 gymnr113 gymnr114 gymnr115 gymnr116 gymnr117 gymnr118 ///
					gymnr119 gymnr120 gymnr121 gymnr122 gymnr123 gymnr124 gymnr125 gymnr126 gymnr127 gymnr128 gymnr129 gymnr130 gymnr131 gymnr132 ///
					yr1 yr2 yr3 yr4 yr5 yr6 yr7 yr8 yr9 yr10 yr11 yr12 yr13 yr14
					
		
		reg logantpctPS `xvar' if logantpctPS!=. & drs==1 [pw=wgt151], robust
		predict lnwQ, resid
		
		foreach x in Tn Tb Ts Th Nt Nb Ns Nh Bt Bn Bs Bh St Sn Sb Sh Ht Hn Hb Hs {

			local xvar dist dist2 fst_Engin fst_NatSc fst_SocSc fst_Hum tsec nsec bsec ssec ///
					FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod age_15 age_16 age_17 age_18 ///
					gymnr2 gymnr3 gymnr4 gymnr5 gymnr6 gymnr7 gymnr8 gymnr9 gymnr10 gymnr11 gymnr12 gymnr13 gymnr14 gymnr15 gymnr16 gymnr17 gymnr18 gymnr19 gymnr20 ///
					gymnr21 gymnr22 gymnr23 gymnr24 gymnr25 gymnr26 gymnr27 gymnr28 gymnr29 gymnr30 gymnr31 gymnr32 gymnr33 gymnr34 gymnr35 gymnr36 gymnr37 gymnr38 gymnr39 gymnr40 ///
					gymnr41 gymnr42 gymnr43 gymnr44 gymnr45 gymnr46 gymnr47 gymnr48 gymnr49 gymnr50 gymnr51 gymnr52 gymnr53 gymnr54 gymnr55 gymnr56 gymnr57 gymnr58 gymnr59 gymnr60 ///
					gymnr61 gymnr62 gymnr63 gymnr64 gymnr65 gymnr66 gymnr67 gymnr68 gymnr69 gymnr70 gymnr71 gymnr72 gymnr73 gymnr74 gymnr75 gymnr76 gymnr77 gymnr78 gymnr79 gymnr80 ///
					gymnr81 gymnr82 gymnr83 gymnr84 gymnr85 gymnr86 gymnr87 gymnr88 gymnr89 gymnr90 gymnr91 gymnr92 gymnr93 gymnr94 gymnr95 gymnr96 gymnr97 gymnr98 gymnr99 gymnr100 ///
					gymnr101 gymnr102 gymnr103 gymnr104 gymnr105 gymnr106 gymnr107 gymnr108 gymnr109 gymnr110 gymnr111 gymnr112 gymnr113 gymnr114 gymnr115 gymnr116 gymnr117 gymnr118 ///
					gymnr119 gymnr120 gymnr121 gymnr122 gymnr123 gymnr124 gymnr125 gymnr126 gymnr127 gymnr128 gymnr129 gymnr130 gymnr131 gymnr132 ///
					yr1 yr2 yr3 yr4 yr5 yr6 yr7 yr8 yr9 yr10 yr11 yr12 yr13 yr14
					
				reg compl`x' `xvar' if logantpctPS!=. & drs==1  [pw=wgt151], robust
				predict compl`x'Q, resid
				
		}
		
		
		***
		
		foreach x in Tn Tb Ts Th Nt Nb Ns Nh Bt Bn Bs Bh St Sn Sb Sh Ht Hn Hb Hs {

			local xvar dist dist2 fst_Engin fst_NatSc fst_SocSc fst_Hum tsec nsec bsec ssec ///
					FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod age_15 age_16 age_17 age_18 ///
					gymnr2 gymnr3 gymnr4 gymnr5 gymnr6 gymnr7 gymnr8 gymnr9 gymnr10 gymnr11 gymnr12 gymnr13 gymnr14 gymnr15 gymnr16 gymnr17 gymnr18 gymnr19 gymnr20 ///
					gymnr21 gymnr22 gymnr23 gymnr24 gymnr25 gymnr26 gymnr27 gymnr28 gymnr29 gymnr30 gymnr31 gymnr32 gymnr33 gymnr34 gymnr35 gymnr36 gymnr37 gymnr38 gymnr39 gymnr40 ///
					gymnr41 gymnr42 gymnr43 gymnr44 gymnr45 gymnr46 gymnr47 gymnr48 gymnr49 gymnr50 gymnr51 gymnr52 gymnr53 gymnr54 gymnr55 gymnr56 gymnr57 gymnr58 gymnr59 gymnr60 ///
					gymnr61 gymnr62 gymnr63 gymnr64 gymnr65 gymnr66 gymnr67 gymnr68 gymnr69 gymnr70 gymnr71 gymnr72 gymnr73 gymnr74 gymnr75 gymnr76 gymnr77 gymnr78 gymnr79 gymnr80 ///
					gymnr81 gymnr82 gymnr83 gymnr84 gymnr85 gymnr86 gymnr87 gymnr88 gymnr89 gymnr90 gymnr91 gymnr92 gymnr93 gymnr94 gymnr95 gymnr96 gymnr97 gymnr98 gymnr99 gymnr100 ///
					gymnr101 gymnr102 gymnr103 gymnr104 gymnr105 gymnr106 gymnr107 gymnr108 gymnr109 gymnr110 gymnr111 gymnr112 gymnr113 gymnr114 gymnr115 gymnr116 gymnr117 gymnr118 ///
					gymnr119 gymnr120 gymnr121 gymnr122 gymnr123 gymnr124 gymnr125 gymnr126 gymnr127 gymnr128 gymnr129 gymnr130 gymnr131 gymnr132 ///
					yr1 yr2 yr3 yr4 yr5 yr6 yr7 yr8 yr9 yr10 yr11 yr12 yr13 yr14
					
				reg Sint`x' `xvar' if logantpctPS!=. & drs==1  [pw=wgt151], robust
		        predict Sint`x'Q, resid
				
		}
		
		
	    *** Dropping non-completers sample - already dropped above when creating the data (drs=0)
		
		local xvar dist dist2 fst_Engin fst_NatSc fst_SocSc fst_Hum tsec nsec bsec ssec ///
					FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod age_15 age_16 age_17 age_18 ///
					gymnr2 gymnr3 gymnr4 gymnr5 gymnr6 gymnr7 gymnr8 gymnr9 gymnr10 gymnr11 gymnr12 gymnr13 gymnr14 gymnr15 gymnr16 gymnr17 gymnr18 gymnr19 gymnr20 ///
					gymnr21 gymnr22 gymnr23 gymnr24 gymnr25 gymnr26 gymnr27 gymnr28 gymnr29 gymnr30 gymnr31 gymnr32 gymnr33 gymnr34 gymnr35 gymnr36 gymnr37 gymnr38 gymnr39 gymnr40 ///
					gymnr41 gymnr42 gymnr43 gymnr44 gymnr45 gymnr46 gymnr47 gymnr48 gymnr49 gymnr50 gymnr51 gymnr52 gymnr53 gymnr54 gymnr55 gymnr56 gymnr57 gymnr58 gymnr59 gymnr60 ///
					gymnr61 gymnr62 gymnr63 gymnr64 gymnr65 gymnr66 gymnr67 gymnr68 gymnr69 gymnr70 gymnr71 gymnr72 gymnr73 gymnr74 gymnr75 gymnr76 gymnr77 gymnr78 gymnr79 gymnr80 ///
					gymnr81 gymnr82 gymnr83 gymnr84 gymnr85 gymnr86 gymnr87 gymnr88 gymnr89 gymnr90 gymnr91 gymnr92 gymnr93 gymnr94 gymnr95 gymnr96 gymnr97 gymnr98 gymnr99 gymnr100 ///
					gymnr101 gymnr102 gymnr103 gymnr104 gymnr105 gymnr106 gymnr107 gymnr108 gymnr109 gymnr110 gymnr111 gymnr112 gymnr113 gymnr114 gymnr115 gymnr116 gymnr117 gymnr118 ///
					gymnr119 gymnr120 gymnr121 gymnr122 gymnr123 gymnr124 gymnr125 gymnr126 gymnr127 gymnr128 gymnr129 gymnr130 gymnr131 gymnr132 ///
					yr1 yr2 yr3 yr4 yr5 yr6 yr7 yr8 yr9 yr10 yr11 yr12 yr13 yr14
					
		
		reg logantpctPS `xvar' if logantpctPS!=. & drs==0 [pw=wgt151], robust
		predict lnwW, resid
		
		foreach x in Tn Tb Ts Th Nt Nb Ns Nh Bt Bn Bs Bh St Sn Sb Sh Ht Hn Hb Hs {

			local xvar dist dist2 fst_Engin fst_NatSc fst_SocSc fst_Hum tsec nsec bsec ssec ///
					FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod age_15 age_16 age_17 age_18 ///
					gymnr2 gymnr3 gymnr4 gymnr5 gymnr6 gymnr7 gymnr8 gymnr9 gymnr10 gymnr11 gymnr12 gymnr13 gymnr14 gymnr15 gymnr16 gymnr17 gymnr18 gymnr19 gymnr20 ///
					gymnr21 gymnr22 gymnr23 gymnr24 gymnr25 gymnr26 gymnr27 gymnr28 gymnr29 gymnr30 gymnr31 gymnr32 gymnr33 gymnr34 gymnr35 gymnr36 gymnr37 gymnr38 gymnr39 gymnr40 ///
					gymnr41 gymnr42 gymnr43 gymnr44 gymnr45 gymnr46 gymnr47 gymnr48 gymnr49 gymnr50 gymnr51 gymnr52 gymnr53 gymnr54 gymnr55 gymnr56 gymnr57 gymnr58 gymnr59 gymnr60 ///
					gymnr61 gymnr62 gymnr63 gymnr64 gymnr65 gymnr66 gymnr67 gymnr68 gymnr69 gymnr70 gymnr71 gymnr72 gymnr73 gymnr74 gymnr75 gymnr76 gymnr77 gymnr78 gymnr79 gymnr80 ///
					gymnr81 gymnr82 gymnr83 gymnr84 gymnr85 gymnr86 gymnr87 gymnr88 gymnr89 gymnr90 gymnr91 gymnr92 gymnr93 gymnr94 gymnr95 gymnr96 gymnr97 gymnr98 gymnr99 gymnr100 ///
					gymnr101 gymnr102 gymnr103 gymnr104 gymnr105 gymnr106 gymnr107 gymnr108 gymnr109 gymnr110 gymnr111 gymnr112 gymnr113 gymnr114 gymnr115 gymnr116 gymnr117 gymnr118 ///
					gymnr119 gymnr120 gymnr121 gymnr122 gymnr123 gymnr124 gymnr125 gymnr126 gymnr127 gymnr128 gymnr129 gymnr130 gymnr131 gymnr132 ///
					yr1 yr2 yr3 yr4 yr5 yr6 yr7 yr8 yr9 yr10 yr11 yr12 yr13 yr14
					
				reg compl`x' `xvar' if logantpctPS!=. & drs==0  [pw=wgt151], robust
				predict compl`x'W, resid
				
		}
		

		***
		
		foreach x in Tn Tb Ts Th Nt Nb Ns Nh Bt Bn Bs Bh St Sn Sb Sh Ht Hn Hb Hs {

			local xvar dist dist2 fst_Engin fst_NatSc fst_SocSc fst_Hum tsec nsec bsec ssec ///
					FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod age_15 age_16 age_17 age_18 ///
					gymnr2 gymnr3 gymnr4 gymnr5 gymnr6 gymnr7 gymnr8 gymnr9 gymnr10 gymnr11 gymnr12 gymnr13 gymnr14 gymnr15 gymnr16 gymnr17 gymnr18 gymnr19 gymnr20 ///
					gymnr21 gymnr22 gymnr23 gymnr24 gymnr25 gymnr26 gymnr27 gymnr28 gymnr29 gymnr30 gymnr31 gymnr32 gymnr33 gymnr34 gymnr35 gymnr36 gymnr37 gymnr38 gymnr39 gymnr40 ///
					gymnr41 gymnr42 gymnr43 gymnr44 gymnr45 gymnr46 gymnr47 gymnr48 gymnr49 gymnr50 gymnr51 gymnr52 gymnr53 gymnr54 gymnr55 gymnr56 gymnr57 gymnr58 gymnr59 gymnr60 ///
					gymnr61 gymnr62 gymnr63 gymnr64 gymnr65 gymnr66 gymnr67 gymnr68 gymnr69 gymnr70 gymnr71 gymnr72 gymnr73 gymnr74 gymnr75 gymnr76 gymnr77 gymnr78 gymnr79 gymnr80 ///
					gymnr81 gymnr82 gymnr83 gymnr84 gymnr85 gymnr86 gymnr87 gymnr88 gymnr89 gymnr90 gymnr91 gymnr92 gymnr93 gymnr94 gymnr95 gymnr96 gymnr97 gymnr98 gymnr99 gymnr100 ///
					gymnr101 gymnr102 gymnr103 gymnr104 gymnr105 gymnr106 gymnr107 gymnr108 gymnr109 gymnr110 gymnr111 gymnr112 gymnr113 gymnr114 gymnr115 gymnr116 gymnr117 gymnr118 ///
					gymnr119 gymnr120 gymnr121 gymnr122 gymnr123 gymnr124 gymnr125 gymnr126 gymnr127 gymnr128 gymnr129 gymnr130 gymnr131 gymnr132 ///
					yr1 yr2 yr3 yr4 yr5 yr6 yr7 yr8 yr9 yr10 yr11 yr12 yr13 yr14
					
				reg Sint`x' `xvar' if logantpctPS!=. & drs==0  [pw=wgt151], robust
		        predict Sint`x'W, resid
				
		}
		
				
		*** 
		
		keep logantpctPS lnwQ lnwW wgt151 drs ///
		      SintTnQ SintTbQ SintTsQ SintThQ SintNtQ SintNbQ SintNsQ SintNhQ SintBtQ SintBnQ SintBsQ SintBhQ ///
		      SintStQ SintSnQ SintSbQ SintShQ SintHtQ SintHnQ SintHbQ SintHsQ /// 
			  complTnQ complTbQ complTsQ complThQ complNtQ complNbQ complNsQ complNhQ complBtQ complBnQ complBsQ complBhQ ///
			  complStQ complSnQ complSbQ complShQ complHtQ complHnQ complHbQ complHsQ ///
			  SintTnW SintTbW SintTsW SintThW SintNtW SintNbW SintNsW SintNhW SintBtW SintBnW SintBsW SintBhW SintStW SintSnW ///
			  SintSbW SintShW SintHtW SintHnW SintHbW SintHsW ///
              complTnW complTbW complTsW complThW complNtW complNbW complNsW complNhW complBtW complBnW complBsW complBhW ///
			  complStW complSnW complSbW complShW complHtW complHnW complHbW complHsW 
		
		keep if logantpctPS!=.
		
		save gmm_dropping_switchers_&_dropouts_tmp, replace
		
		
		gmm (eq1: drs*lnwQ /// 
		- {b1}*drs*complTnQ - {b2}*drs*complTbQ - {b3}*drs*complTsQ - {b4}*drs*complThQ - {b5}*drs*complNtQ - {b6}*drs*complNbQ - {b7}*drs*complNsQ ///
		- {b8}*drs*complNhQ - {b9}*drs*complBtQ - {b10}*drs*complBnQ - {b11}*drs*complBsQ - {b12}*drs*complBhQ - {b13}*drs*complStQ ///
		- {b14}*drs*complSnQ - {b15}*drs*complSbQ - {b16}*drs*complShQ - {b17}*drs*complHtQ - {b18}*drs*complHnQ - {b19}*drs*complHbQ - {b20}*drs*complHsQ - drs*{b0}) ///
		   (eq2: (1-drs)*lnwW /// 
		- {c1}*(1-drs)*complTnW - {c2}*(1-drs)*complTbW - {c3}*(1-drs)*complTsW - {c4}*(1-drs)*complThW - {c5}*(1-drs)*complNtW ///
		- {c6}*(1-drs)*complNbW - {c7}*(1-drs)*complNsW - {c8}*(1-drs)*complNhW - {c9}*(1-drs)*complBtW - {c10}*(1-drs)*complBnW ///
		- {c11}*(1-drs)*complBsW - {c12}*(1-drs)*complBhW - {c13}*(1-drs)*complStW - {c14}*(1-drs)*complSnW - {c15}*(1-drs)*complSbW ///
		- {c16}*(1-drs)*complShW - {c17}*(1-drs)*complHtW - {c18}*(1-drs)*complHnW - {c19}*(1-drs)*complHbW - {c20}*(1-drs)*complHsW - (1-drs)*{c0}) ///
		if logantpctPS!=. [pw=wgt151], ///
		instruments(eq1: SintTnQ SintTbQ SintTsQ SintThQ SintNtQ SintNbQ SintNsQ SintNhQ SintBtQ SintBnQ SintBsQ SintBhQ ///
		SintStQ SintSnQ SintSbQ SintShQ SintHtQ SintHnQ SintHbQ SintHsQ) ///
		instruments(eq2: SintTnW SintTbW SintTsW SintThW SintNtW SintNbW SintNsW SintNhW SintBtW SintBnW SintBsW SintBhW ///
		SintStW SintSnW SintSbW SintShW SintHtW SintHnW SintHbW SintHsW) onestep winitial (unadjusted, indep)
		
		
	
		** test individual coefficients **
		
		test [b1]_cons = [c1]_cons
		test [b2]_cons = [c2]_cons
		test [b3]_cons = [c3]_cons
		test [b4]_cons = [c4]_cons
		test [b5]_cons = [c5]_cons
		test [b6]_cons = [c6]_cons
		test [b7]_cons = [c7]_cons
		test [b8]_cons = [c8]_cons
		test [b9]_cons = [c9]_cons
		test [b10]_cons = [c10]_cons
		test [b11]_cons = [c11]_cons
		test [b12]_cons = [c12]_cons
		test [b13]_cons = [c13]_cons
		test [b14]_cons = [c14]_cons
		test [b15]_cons = [c15]_cons
		test [b16]_cons = [c16]_cons
		test [b17]_cons = [c17]_cons
		test [b18]_cons = [c18]_cons
		test [b19]_cons = [c19]_cons
		test [b20]_cons = [c20]_cons
	
		
		
		
        ********************* stop here *************************************************************
		
		
		