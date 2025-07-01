use score_*_std_?? satisf_?_?? year_t_?? year grade treated id_ie fam_total_${fam_type} fam_order_${fam_type} ${x} if grade==2 | grade==4 | grade==8 using "$TEMP\pre_reg_covid", clear
keep if inlist(year,2012,2013,2014,2015,2016,2018,2019,2022,2023)==1

forvalues y = 2012(1)2023 {
bys id_ie: egen m_2p_`y' = max(cond(score_math_std_2p!=. & year==`y' & grade==2,1,0))
bys id_ie: egen m_4p_`y' = max(cond(score_math_std_4p!=. & year==`y' & grade==4,1,0))
bys id_ie: egen m_2s_`y' = max(cond(score_math_std_2s!=. & year==`y' & grade==8,1,0))
}

egen years_2p = rsum(m_2p_*)
egen years_4p = rsum(m_4p_*)
egen years_2s = rsum(m_2s_*)

gen mark1=1 if 	(grade==2 & (m_2p_2014==1 & 	m_2p_2015==1 & 		m_2p_2016==1 & /*m_2p_2018==1 &*/ 	m_2p_2019==1 & m_2p_2022==1 /*& m_2p_2023==1*/)) | ///
				(grade==4 & (/*m_4p_2014==1 &*/ /*m_4p_2015==1 &*/ 	m_4p_2016==1 & m_4p_2018==1 & 		m_4p_2019==1 & m_4p_2022==1 & m_4p_2023==1)) | ///
				(grade==8 & (/*m_2s_2014==1 &*/ m_2s_2015==1 & 		m_2s_2016==1 & m_2s_2018==1 & 		m_2s_2019==1 & m_2s_2022==1 & m_2s_2023==1))
				
gen mark2=1 if 	(grade==2 & (m_2p_2014==1 & 	m_2p_2015==1 & 		m_2p_2016==1 & /*m_2p_2018==1 &*/ 	m_2p_2019==1 & m_2p_2022==1 /*& m_2p_2023==1*/)) | ///
				(grade==4 & (/*m_4p_2014==1 &*/ /*m_4p_2015==1 &*/ 	m_4p_2016==1 & m_4p_2018==1 & 		m_4p_2019==1 & m_4p_2022==1 /*& m_4p_2023==1*/)) | ///
				(grade==8 & (/*m_2s_2014==1 &*/ m_2s_2015==1 & 		m_2s_2016==1 & m_2s_2018==1 & 		m_2s_2019==1 & m_2s_2022==1 /*& m_2s_2023==1*/))				

//2014,	2015,	2016,		2019,2022
//				2016,2018,	2019,2022 (2023)
//		2015,	2016,2018,	2019,2022 (2023)
forvalues i = 1/2 {
	preserve
		collapse score_*_std_?? satisf_?_?? if mark`i'==1, by(year fam_total_${fam_type})
		gen mark=`i'
		tempfile mark`i'
		save `mark`i'', replace
	restore
}

clear
append using `mark1'
append using `mark2'
//score_math_std_2p
//satisf_m_2p


preserve
keep if mark==2
local v = "score_math_std_2p"
twoway 	(line `v' year if fam_total_${fam_type}==1 & year<2020, lcolor("${red_3}"))  ///
		(line `v' year if fam_total_${fam_type}==2 & year<2020 , lcolor("${blue_3}"))  ///
		(line `v' year if fam_total_${fam_type}==1 & year>=2020 , lcolor("${red_1}")) ///
		(line `v' year if fam_total_${fam_type}==2 & year>=2020 , lcolor("${blue_1}")) ///
		, ///
		legend(order(3 "Control" 4 "Treated") pos(6) col(2)) ///
		xlabel(2012 "12" 2013 "13" 2014 "14" 2015 "15" 2016 "16" 2017 "17" 2018 "18" 2019 "19" 2020 "20" 2021 "21" 2022 "22" 2023 "23")  ///
		xline(2019.5)
restore