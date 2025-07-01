** Program to compare estimates in Appnedix Table A9, cols 1 and 4, ie, Baseline vs KLM IV

** BEWARE! The GMM took about 8h to converge on the server

clear
capture log close

log using "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\Output\log_test_tabA9klm.log",replace

set more off, permanently		

global file "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"

cd "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Marginal\data"

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
		replace w_suest=1 if w_suest==. 

		* generated variables for gmm - simply more visible than fst*
		
		gen fst_NatSc=fst==44
		gen fst_Engin=fst==59
		gen fst_SocSc=fst==51
		gen fst_Hum=fst==28
		
		gen age_15=age==15
		gen age_16=age==16
		gen age_17=age==17
		gen age_18=age==18
		
		gen Jmft_tsec=Jmft*tsec
		gen Jmft_nsec=Jmft*nsec
		gen Jmft_bsec=Jmft*bsec
		gen Jmft_ssec=Jmft*ssec
		gen Jmft_hsec=Jmft*hsec
		gen Jmft_vsec=Jmft*nonac2v
		gen Jmft_gsec=Jmft*nonac2g
		
		
		******* GMM does not allow this many x-variables (200+) so have to residualize ALL variables to fit the gmm-model *****
		* have to residualze differently since DRS and KLM use different weights in estimation, as well as different controls  
		
		**** DRS (Baseline) ****
		

		local xvar dist dist2 fst_Engin fst_NatSc fst_SocSc fst_Hum tsec nsec bsec ssec hsec nonac2v ///
					FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod age_15 age_16 age_17 age_18 ///
					gymnr2 gymnr3 gymnr4 gymnr5 gymnr6 gymnr7 gymnr8 gymnr9 gymnr10 gymnr11 gymnr12 gymnr13 gymnr14 gymnr15 gymnr16 gymnr17 gymnr18 gymnr19 gymnr20 ///
					gymnr21 gymnr22 gymnr23 gymnr24 gymnr25 gymnr26 gymnr27 gymnr28 gymnr29 gymnr30 gymnr31 gymnr32 gymnr33 gymnr34 gymnr35 gymnr36 gymnr37 gymnr38 gymnr39 gymnr40 ///
					gymnr41 gymnr42 gymnr43 gymnr44 gymnr45 gymnr46 gymnr47 gymnr48 gymnr49 gymnr50 gymnr51 gymnr52 gymnr53 gymnr54 gymnr55 gymnr56 gymnr57 gymnr58 gymnr59 gymnr60 ///
					gymnr61 gymnr62 gymnr63 gymnr64 gymnr65 gymnr66 gymnr67 gymnr68 gymnr69 gymnr70 gymnr71 gymnr72 gymnr73 gymnr74 gymnr75 gymnr76 gymnr77 gymnr78 gymnr79 gymnr80 ///
					gymnr81 gymnr82 gymnr83 gymnr84 gymnr85 gymnr86 gymnr87 gymnr88 gymnr89 gymnr90 gymnr91 gymnr92 gymnr93 gymnr94 gymnr95 gymnr96 gymnr97 gymnr98 gymnr99 gymnr100 ///
					gymnr101 gymnr102 gymnr103 gymnr104 gymnr105 gymnr106 gymnr107 gymnr108 gymnr109 gymnr110 gymnr111 gymnr112 gymnr113 gymnr114 gymnr115 gymnr116 gymnr117 gymnr118 ///
					gymnr119 gymnr120 gymnr121 gymnr122 gymnr123 gymnr124 gymnr125 gymnr126 gymnr127 gymnr128 gymnr129 gymnr130 gymnr131 gymnr132 ///
					yr1 yr2 yr3 yr4 yr5 yr6 yr7 yr8 yr9 yr10 yr11 yr12 yr13 yr14
					
		
		reg logantpctPS `xvar' if logantpctPS!=. & drs==1 [pw=w_suest], robust
		predict lnw3739Q, resid
		
		
		foreach x in Tn Tb Ts Th Tg Tv Nt Nb Ns Nh Ng Nv Bt Bn Bs Bh Bg Bv St Sn Sb Sh Sg Sv Ht Hn Hb Hs Hg Hv {

			local xvar dist dist2 fst_Engin fst_NatSc fst_SocSc fst_Hum tsec nsec bsec ssec hsec nonac2v ///
					FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod age_15 age_16 age_17 age_18 ///
					gymnr2 gymnr3 gymnr4 gymnr5 gymnr6 gymnr7 gymnr8 gymnr9 gymnr10 gymnr11 gymnr12 gymnr13 gymnr14 gymnr15 gymnr16 gymnr17 gymnr18 gymnr19 gymnr20 ///
					gymnr21 gymnr22 gymnr23 gymnr24 gymnr25 gymnr26 gymnr27 gymnr28 gymnr29 gymnr30 gymnr31 gymnr32 gymnr33 gymnr34 gymnr35 gymnr36 gymnr37 gymnr38 gymnr39 gymnr40 ///
					gymnr41 gymnr42 gymnr43 gymnr44 gymnr45 gymnr46 gymnr47 gymnr48 gymnr49 gymnr50 gymnr51 gymnr52 gymnr53 gymnr54 gymnr55 gymnr56 gymnr57 gymnr58 gymnr59 gymnr60 ///
					gymnr61 gymnr62 gymnr63 gymnr64 gymnr65 gymnr66 gymnr67 gymnr68 gymnr69 gymnr70 gymnr71 gymnr72 gymnr73 gymnr74 gymnr75 gymnr76 gymnr77 gymnr78 gymnr79 gymnr80 ///
					gymnr81 gymnr82 gymnr83 gymnr84 gymnr85 gymnr86 gymnr87 gymnr88 gymnr89 gymnr90 gymnr91 gymnr92 gymnr93 gymnr94 gymnr95 gymnr96 gymnr97 gymnr98 gymnr99 gymnr100 ///
					gymnr101 gymnr102 gymnr103 gymnr104 gymnr105 gymnr106 gymnr107 gymnr108 gymnr109 gymnr110 gymnr111 gymnr112 gymnr113 gymnr114 gymnr115 gymnr116 gymnr117 gymnr118 ///
					gymnr119 gymnr120 gymnr121 gymnr122 gymnr123 gymnr124 gymnr125 gymnr126 gymnr127 gymnr128 gymnr129 gymnr130 gymnr131 gymnr132 ///
					yr1 yr2 yr3 yr4 yr5 yr6 yr7 yr8 yr9 yr10 yr11 yr12 yr13 yr14
					
				reg compl`x' `xvar' if logantpctPS!=. & drs==1  [pw=w_suest], robust
				predict compl`x'Q, resid
				
		}
		
		

		foreach x in Tn Tb Ts Th Tg Tv Nt Nb Ns Nh Ng Nv Bt Bn Bs Bh Bg Bv St Sn Sb Sh Sg Sv Ht Hn Hb Hs Hg Hv {

				local xvar dist dist2 fst_Engin fst_NatSc fst_SocSc fst_Hum tsec nsec bsec ssec hsec nonac2v ///
					FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod age_15 age_16 age_17 age_18 ///
					gymnr2 gymnr3 gymnr4 gymnr5 gymnr6 gymnr7 gymnr8 gymnr9 gymnr10 gymnr11 gymnr12 gymnr13 gymnr14 gymnr15 gymnr16 gymnr17 gymnr18 gymnr19 gymnr20 ///
					gymnr21 gymnr22 gymnr23 gymnr24 gymnr25 gymnr26 gymnr27 gymnr28 gymnr29 gymnr30 gymnr31 gymnr32 gymnr33 gymnr34 gymnr35 gymnr36 gymnr37 gymnr38 gymnr39 gymnr40 ///
					gymnr41 gymnr42 gymnr43 gymnr44 gymnr45 gymnr46 gymnr47 gymnr48 gymnr49 gymnr50 gymnr51 gymnr52 gymnr53 gymnr54 gymnr55 gymnr56 gymnr57 gymnr58 gymnr59 gymnr60 ///
					gymnr61 gymnr62 gymnr63 gymnr64 gymnr65 gymnr66 gymnr67 gymnr68 gymnr69 gymnr70 gymnr71 gymnr72 gymnr73 gymnr74 gymnr75 gymnr76 gymnr77 gymnr78 gymnr79 gymnr80 ///
					gymnr81 gymnr82 gymnr83 gymnr84 gymnr85 gymnr86 gymnr87 gymnr88 gymnr89 gymnr90 gymnr91 gymnr92 gymnr93 gymnr94 gymnr95 gymnr96 gymnr97 gymnr98 gymnr99 gymnr100 ///
					gymnr101 gymnr102 gymnr103 gymnr104 gymnr105 gymnr106 gymnr107 gymnr108 gymnr109 gymnr110 gymnr111 gymnr112 gymnr113 gymnr114 gymnr115 gymnr116 gymnr117 gymnr118 ///
					gymnr119 gymnr120 gymnr121 gymnr122 gymnr123 gymnr124 gymnr125 gymnr126 gymnr127 gymnr128 gymnr129 gymnr130 gymnr131 gymnr132 ///
					yr1 yr2 yr3 yr4 yr5 yr6 yr7 yr8 yr9 yr10 yr11 yr12 yr13 yr14
					
				reg Sint`x' `xvar' if logantpctPS!=. & drs==1  [pw=w_suest], robust
		        predict Sint`x'Q, resid
				
		}
		
		
		
		
		****************** stop residualize DRS ******************
			
		**** KLM ****
		
	
		local xvar Jmft_tsec Jmft_nsec Jmft_bsec Jmft_ssec Jmft_hsec Jmft_vsec Jmft_gsec fst_Engin fst_NatSc fst_SocSc fst_Hum tsec nsec bsec ssec hsec nonac2v ///
					FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod age_15 age_16 age_17 age_18 ///
					gymnr2 gymnr3 gymnr4 gymnr5 gymnr6 gymnr7 gymnr8 gymnr9 gymnr10 gymnr11 gymnr12 gymnr13 gymnr14 gymnr15 gymnr16 gymnr17 gymnr18 gymnr19 gymnr20 ///
					gymnr21 gymnr22 gymnr23 gymnr24 gymnr25 gymnr26 gymnr27 gymnr28 gymnr29 gymnr30 gymnr31 gymnr32 gymnr33 gymnr34 gymnr35 gymnr36 gymnr37 gymnr38 gymnr39 gymnr40 ///
					gymnr41 gymnr42 gymnr43 gymnr44 gymnr45 gymnr46 gymnr47 gymnr48 gymnr49 gymnr50 gymnr51 gymnr52 gymnr53 gymnr54 gymnr55 gymnr56 gymnr57 gymnr58 gymnr59 gymnr60 ///
					gymnr61 gymnr62 gymnr63 gymnr64 gymnr65 gymnr66 gymnr67 gymnr68 gymnr69 gymnr70 gymnr71 gymnr72 gymnr73 gymnr74 gymnr75 gymnr76 gymnr77 gymnr78 gymnr79 gymnr80 ///
					gymnr81 gymnr82 gymnr83 gymnr84 gymnr85 gymnr86 gymnr87 gymnr88 gymnr89 gymnr90 gymnr91 gymnr92 gymnr93 gymnr94 gymnr95 gymnr96 gymnr97 gymnr98 gymnr99 gymnr100 ///
					gymnr101 gymnr102 gymnr103 gymnr104 gymnr105 gymnr106 gymnr107 gymnr108 gymnr109 gymnr110 gymnr111 gymnr112 gymnr113 gymnr114 gymnr115 gymnr116 gymnr117 gymnr118 ///
					gymnr119 gymnr120 gymnr121 gymnr122 gymnr123 gymnr124 gymnr125 gymnr126 gymnr127 gymnr128 gymnr129 gymnr130 gymnr131 gymnr132 ///
					yr1 yr2 yr3 yr4 yr5 yr6 yr7 yr8 yr9 yr10 yr11 yr12 yr13 yr14
		
		reg logantpctPS `xvar' if logantpctPS!=. & drs==0 [pw=w_suest], robust
		predict lnw3739W, resid
		
		foreach x in Tn Tb Ts Th Tg Tv Nt Nb Ns Nh Ng Nv Bt Bn Bs Bh Bg Bv St Sn Sb Sh Sg Sv Ht Hn Hb Hs Hg Hv {

			local xvar Jmft_tsec Jmft_nsec Jmft_bsec Jmft_ssec Jmft_hsec Jmft_vsec Jmft_gsec fst_Engin fst_NatSc fst_SocSc fst_Hum tsec nsec bsec ssec hsec nonac2v ///
					FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod age_15 age_16 age_17 age_18 ///
					gymnr2 gymnr3 gymnr4 gymnr5 gymnr6 gymnr7 gymnr8 gymnr9 gymnr10 gymnr11 gymnr12 gymnr13 gymnr14 gymnr15 gymnr16 gymnr17 gymnr18 gymnr19 gymnr20 ///
					gymnr21 gymnr22 gymnr23 gymnr24 gymnr25 gymnr26 gymnr27 gymnr28 gymnr29 gymnr30 gymnr31 gymnr32 gymnr33 gymnr34 gymnr35 gymnr36 gymnr37 gymnr38 gymnr39 gymnr40 ///
					gymnr41 gymnr42 gymnr43 gymnr44 gymnr45 gymnr46 gymnr47 gymnr48 gymnr49 gymnr50 gymnr51 gymnr52 gymnr53 gymnr54 gymnr55 gymnr56 gymnr57 gymnr58 gymnr59 gymnr60 ///
					gymnr61 gymnr62 gymnr63 gymnr64 gymnr65 gymnr66 gymnr67 gymnr68 gymnr69 gymnr70 gymnr71 gymnr72 gymnr73 gymnr74 gymnr75 gymnr76 gymnr77 gymnr78 gymnr79 gymnr80 ///
					gymnr81 gymnr82 gymnr83 gymnr84 gymnr85 gymnr86 gymnr87 gymnr88 gymnr89 gymnr90 gymnr91 gymnr92 gymnr93 gymnr94 gymnr95 gymnr96 gymnr97 gymnr98 gymnr99 gymnr100 ///
					gymnr101 gymnr102 gymnr103 gymnr104 gymnr105 gymnr106 gymnr107 gymnr108 gymnr109 gymnr110 gymnr111 gymnr112 gymnr113 gymnr114 gymnr115 gymnr116 gymnr117 gymnr118 ///
					gymnr119 gymnr120 gymnr121 gymnr122 gymnr123 gymnr124 gymnr125 gymnr126 gymnr127 gymnr128 gymnr129 gymnr130 gymnr131 gymnr132 ///
					yr1 yr2 yr3 yr4 yr5 yr6 yr7 yr8 yr9 yr10 yr11 yr12 yr13 yr14
					
				reg compl`x' `xvar' if logantpctPS!=. & drs==0  [pw=w_suest], robust
				predict compl`x'W, resid
				
		}
		
		
		***
		
		foreach x in Tn Tb Ts Th Tg Tv Nt Nb Ns Nh Ng Nv Bt Bn Bs Bh Bg Bv St Sn Sb Sh Sg Sv Ht Hn Hb Hs Hg Hv {

			local xvar Jmft_tsec Jmft_nsec Jmft_bsec Jmft_ssec Jmft_hsec Jmft_vsec Jmft_gsec fst_Engin fst_NatSc fst_SocSc fst_Hum tsec nsec bsec ssec hsec nonac2v ///
					FodarFar utbFar utrFar FodarMor utbMor utrMor fem utrfod age_15 age_16 age_17 age_18 ///
					gymnr2 gymnr3 gymnr4 gymnr5 gymnr6 gymnr7 gymnr8 gymnr9 gymnr10 gymnr11 gymnr12 gymnr13 gymnr14 gymnr15 gymnr16 gymnr17 gymnr18 gymnr19 gymnr20 ///
					gymnr21 gymnr22 gymnr23 gymnr24 gymnr25 gymnr26 gymnr27 gymnr28 gymnr29 gymnr30 gymnr31 gymnr32 gymnr33 gymnr34 gymnr35 gymnr36 gymnr37 gymnr38 gymnr39 gymnr40 ///
					gymnr41 gymnr42 gymnr43 gymnr44 gymnr45 gymnr46 gymnr47 gymnr48 gymnr49 gymnr50 gymnr51 gymnr52 gymnr53 gymnr54 gymnr55 gymnr56 gymnr57 gymnr58 gymnr59 gymnr60 ///
					gymnr61 gymnr62 gymnr63 gymnr64 gymnr65 gymnr66 gymnr67 gymnr68 gymnr69 gymnr70 gymnr71 gymnr72 gymnr73 gymnr74 gymnr75 gymnr76 gymnr77 gymnr78 gymnr79 gymnr80 ///
					gymnr81 gymnr82 gymnr83 gymnr84 gymnr85 gymnr86 gymnr87 gymnr88 gymnr89 gymnr90 gymnr91 gymnr92 gymnr93 gymnr94 gymnr95 gymnr96 gymnr97 gymnr98 gymnr99 gymnr100 ///
					gymnr101 gymnr102 gymnr103 gymnr104 gymnr105 gymnr106 gymnr107 gymnr108 gymnr109 gymnr110 gymnr111 gymnr112 gymnr113 gymnr114 gymnr115 gymnr116 gymnr117 gymnr118 ///
					gymnr119 gymnr120 gymnr121 gymnr122 gymnr123 gymnr124 gymnr125 gymnr126 gymnr127 gymnr128 gymnr129 gymnr130 gymnr131 gymnr132 ///
					yr1 yr2 yr3 yr4 yr5 yr6 yr7 yr8 yr9 yr10 yr11 yr12 yr13 yr14
					
				reg Sint`x' `xvar' if logantpctPS!=. & drs==0  [pw=w_suest], robust
		        predict Sint`x'W, resid
				
		}
		
******
		
		
		keep logantpctPS lnw3739Q lnw3739W drs w_suest ///
		      SintTnQ SintTbQ SintTsQ SintThQ SintTgQ SintTvQ SintNtQ SintNbQ SintNsQ SintNhQ SintNgQ SintNvQ SintBtQ SintBnQ SintBsQ SintBhQ SintBgQ ///
		      SintBvQ SintStQ SintSnQ SintSbQ SintShQ SintSgQ SintSvQ SintHtQ SintHnQ SintHbQ SintHsQ SintHgQ SintHvQ /// 
			  complTnQ complTbQ complTsQ complThQ complTgQ complTvQ complNtQ complNbQ complNsQ complNhQ complNgQ complNvQ complBtQ complBnQ complBsQ complBhQ complBgQ complBvQ ///
			  complStQ complSnQ complSbQ complShQ complSgQ complSvQ complHtQ complHnQ complHbQ complHsQ complHgQ complHvQ ///
			  SintTnW SintTbW SintTsW SintThW SintTgW SintTvW SintNtW SintNbW SintNsW SintNhW SintNgW SintNvW SintBtW SintBnW SintBsW SintBhW SintBgW SintBvW SintStW SintSnW ///
			  SintSbW SintShW SintSgW SintSvW SintHtW SintHnW SintHbW SintHsW SintHgW SintHvW ///
              complTnW complTbW complTsW complThW complTgW complTvW complNtW complNbW complNsW complNhW complNgW complNvW complBtW complBnW complBsW complBhW complBgW complBvW ///
			  complStW complSnW complSbW complShW complSgW complSvW complHtW complHnW complHbW complHsW complHgW complHvW
		
		* select to get the basesample
		keep if logantpctPS!=.
		
		save gmm_drs_klm_tmp, replace
		
						
		*******************************************************************************************
		** C. GMM estimation comparing DRS and KLM, comparing cols 1 and 3 in Table A9 ****
		*******************************************************************************************
		
			
		gmm (eq1: drs*lnw3739Q /// 
		- {b1}*drs*complTnQ - {b2}*drs*complTbQ - {b3}*drs*complTsQ - {b4}*drs*complThQ - {b5}*drs*complTgQ - {b6}*drs*complTvQ - {b7}*drs*complNtQ - {b8}*drs*complNbQ - {b9}*drs*complNsQ ///
		- {b10}*drs*complNhQ - {b11}*drs*complNgQ - {b12}*drs*complNvQ - {b13}*drs*complBtQ - {b14}*drs*complBnQ - {b15}*drs*complBsQ - {b16}*drs*complBhQ - {b17}*drs*complBgQ ///
		- {b18}*drs*complBvQ - {b19}*drs*complStQ - {b20}*drs*complSnQ - {b21}*drs*complSbQ - {b22}*drs*complShQ - {b23}*drs*complSgQ - {b24}*drs*complSvQ ///
		- {b25}*drs*complHtQ - {b26}*drs*complHnQ - {b27}*drs*complHbQ - {b28}*drs*complHsQ - {b29}*drs*complHgQ - {b30}*drs*complHvQ - drs*{b0}) ///
		   (eq2: (1-drs)*lnw3739W /// 
		- {c1}*(1-drs)*complTnW - {c2}*(1-drs)*complTbW - {c3}*(1-drs)*complTsW - {c4}*(1-drs)*complThW - {c5}*(1-drs)*complTgW - {c6}*(1-drs)*complTvW - {c7}*(1-drs)*complNtW ///
		- {c8}*(1-drs)*complNbW - {c9}*(1-drs)*complNsW - {c10}*(1-drs)*complNhW - {c11}*(1-drs)*complNgW - {c12}*(1-drs)*complNvW - {c13}*(1-drs)*complBtW - {c14}*(1-drs)*complBnW ///
		- {c15}*(1-drs)*complBsW - {c16}*(1-drs)*complBhW - {c17}*(1-drs)*complBgW - {c18}*(1-drs)*complBvW ///
		- {c19}*(1-drs)*complStW - {c20}*(1-drs)*complSnW - {c21}*(1-drs)*complSbW - {c22}*(1-drs)*complShW - {c23}*(1-drs)*complSgW - {c24}*(1-drs)*complSvW ///
		- {c25}*(1-drs)*complHtW - {c26}*(1-drs)*complHnW - {c27}*(1-drs)*complHbW - {c28}*(1-drs)*complHsW - {c29}*(1-drs)*complHgW - {c30}*(1-drs)*complHvW - (1-drs)*{c0}) ///
		if logantpctPS!=. [pw=w_suest], ///
		instruments(eq1: SintTnQ SintTbQ SintTsQ SintThQ SintTgQ SintTvQ SintNtQ SintNbQ SintNsQ SintNhQ SintNgQ SintNvQ SintBtQ SintBnQ SintBsQ SintBhQ SintBgQ SintBvQ ///
		SintStQ SintSnQ SintSbQ SintShQ SintSgQ SintSvQ SintHtQ SintHnQ SintHbQ SintHsQ SintHgQ SintHvQ) ///
		instruments(eq2: SintTnW SintTbW SintTsW SintThW SintTgW SintTvW SintNtW SintNbW SintNsW SintNhW SintNgW SintNvW SintBtW SintBnW SintBsW SintBhW SintBgW SintBvW ///
		SintStW SintSnW SintSbW SintShW SintSgW SintSvW SintHtW SintHnW SintHbW SintHsW SintHgW SintHvW) onestep winitial (unadjusted, indep)
		

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
		test [b21]_cons = [c21]_cons
		test [b22]_cons = [c22]_cons
		test [b23]_cons = [c23]_cons
		test [b24]_cons = [c24]_cons
		test [b25]_cons = [c25]_cons
		test [b26]_cons = [c26]_cons
		test [b27]_cons = [c27]_cons
		test [b28]_cons = [c28]_cons
		test [b29]_cons = [c29]_cons
		test [b30]_cons = [c30]_cons	
		
		
			 
		*********** end tests **************
		
