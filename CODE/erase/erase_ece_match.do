*- ECE MATCHED

global g1 = "2"
global g2 = "8"

if "${g1}" == "2" global g1t = "2p"
if "${g1}" == "4" global g1t = "4p"
if "${g1}" == "6" global g1t = "6p"

if "${g2}" == "4" global g2t = "4p"
if "${g2}" == "6" global g2t = "6p"
if "${g2}" == "8" global g2t = "2s"

if "${g1}" == "2" global g1l = "2nd"
if "${g1}" == "4" global g1l = "4th"
if "${g1}" == "6" global g1l = "6th"

if "${g2}" == "4" global g2l = "4th"
if "${g2}" == "6" global g2l = "6th"
if "${g2}" == "8" global g2l = "8th"


use score_*_std_?? satisf_?_?? /*year_t_??*/ urban_siagie higher_ed_parent lives_with_mother lives_with_father year grade treated id_per_umc id_ie fam_total_${fam_type} fam_order_${fam_type} ${x} if grade==${g1} | grade==${g2} using "$TEMP\pre_reg_covid", clear


bys id_per_umc: egen m_${g1t} = max(cond(score_math_std_${g1t}!=. & grade==${g1},1,0))
bys id_per_umc: egen m_${g2t} = max(cond(score_math_std_${g2t}!=. & grade==${g2},1,0))

keep if m_${g1t} == 1 & m_${g2t} == 1

tab year if grade==${g1} & m_${g1t}==1
tab year if grade==${g2} & m_${g2t}==1


if "${g1}" == "2" & "${g2}"=="8" keep if (grade==${g1} & inlist(year,2016)==1) | (grade==${g2} & inlist(year,2022)==1)
if "${g1}" == "4" & "${g2}"=="8" keep if (grade==${g1} & inlist(year,2018,2019)==1) | (grade==${g2} & inlist(year,2022,2023)==1)

collapse score_*_std_?? satisf_?_??, by(id_per_umc fam_total_${fam_type} urban_siagie higher_ed_parent lives_with_mother lives_with_father)

reg satisf_m_${g2t} satisf_m_${g1t} i.fam_total_${fam_type} i.urban_siagie i.lives_with_mother i.lives_with_father i.higher_ed_parent

graph bar satisf_m_${g1t} satisf_m_${g2t}, ///
	over(fam_total_${fam_type}) ///
	legend(order(1 "${g1l} grade (Pre covid)" 2 "${g2l} grade (Post covid)") pos(6) col(2))

	
*- Check each one year by year	
	

