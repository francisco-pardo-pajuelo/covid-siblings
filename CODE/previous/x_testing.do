preserve

open

tab score_raw if id_cutoff==1034
tab score_raw if id_cutoff==1008
tab score_raw if id_cutoff==1013

keep if abs(score_relative)<0.4
	*******
gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=.	
	rddensity score_relative ///
		if abs(score_relative)<$mccrary_window ///
		& not_at_cutoff==1 ///
		& sample==1 ///
		& condition ==1 ///
		, ///
		plot

restore



use  "$TEMP\applied", clear



use "C:\Users\Francisco\Dropbox\Alfonso_Minedu\SIAGIE\siagie_12_22_ece_12_19_postulantes(27.07.2022).dta" , clear





drop if puntaje_postulante==0

sum puntaje_postulante, de

drop if puntaje_postulante<50

bys periodo_postulacion: sum puntaje_postulante, de

histogram puntaje_postulante if puntaje_postulante<2000 & periodo_postulacion == "2017-1"
histogram puntaje_postulante if puntaje_postulante<2000 & periodo_postulacion == "2017-2"
histogram puntaje_postulante if puntaje_postulante<2000 & periodo_postulacion == "2018-1"
histogram puntaje_postulante if puntaje_postulante<2000 & periodo_postulacion == "2018-2"
histogram puntaje_postulante if puntaje_postulante<2000 & periodo_postulacion == "2019-1"
histogram puntaje_postulante if puntaje_postulante<2000 & periodo_postulacion == "2019-2"
histogram puntaje_postulante if puntaje_postulante<2000 & periodo_postulacion == "2020-1"
histogram puntaje_postulante if puntaje_postulante<2000 & periodo_postulacion == "2020-2"
histogram puntaje_postulante if puntaje_postulante<2000 & periodo_postulacion == "2021-1"




/*



118. |  56656                                                 UNIVERSIDAD CIENTÍFICA DEL SUR |
119. |  57204                                            UNIVERSIDAD CATÓLICA DE SANTA MARÍA |
120. |  58346                                              UNIVERSIDAD SAN IGNACIO DE LOYOLA |
121. |  60304                                                UNIVERSIDAD NACIONAL DEL CALLAO |
122. |  66726                                                   UNIV DE SAN MARTÍN DE PORRES |
123. |  68186                                                  UNIVERSIDAD NACIONAL DE PIURA |
124. |  69410                                         UNIVERSIDAD NACIONAL HERMILIO VALDIZAN |
125. |  79221                             UNIVERSIDAD NACIONAL JOSÉ FAUSTINO SÁNCHEZ CARRIÓN |
126. |  85143                                       UNIVERSIDAD NACIONAL FEDERICO VILLARREAL |
127. |  87972                                             UNIVERSIDAD NACIONAL DE INGENIERÍA |
128. |  93890                                       UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ |
129. | 100829                              UNIVERSIDAD NACIONAL DE SAN CRISTÓBAL DE HUAMANGA |
130. | 102158                                       PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ |
131. | 126553                                               UNIVERSIDAD NACIONAL DE TRUJILLO |
132. | 156503                                             UNIVERSIDAD NACIONAL DEL ALTIPLANO |
133. | 177649                                                        UNIVERSIDAD CONTINENTAL |
134. | 197738                             UNIVERSIDAD NACIONAL DE SAN ANTONIO ABAD DEL CUSCO |
135. | 202597                                      UNIVERSIDAD PERUANA DE CIENCIAS APLICADAS |
136. | 222184                                            UNIVERSIDAD NACIONAL DE SAN AGUSTÍN |
137. | 252421                                                  UNIVERSIDAD PRIVADA DEL NORTE |
138. | 282437                                                      UNIVERSIDAD CÉSAR VALLEJO |
139. | 295260                                       UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS |
140. | 450010                                               UNIVERSIDAD TECNOLÓGICA DEL PERÚ |

*/



use "C:\Users\Francisco\Dropbox\Alfonso_Minedu\SIAGIE\siagie_12_22_ece_12_19_postulantes(27.07.2022).dta" , clear

preserve
	drop if puntaje==0
	keep if universidad == "UNIVERSIDAD CIENTÍFICA DEL SUR"
	histogram puntaje
	sum puntaje, de
	gen admitted = es_ingresante == "True"
	tab periodo_postulacion, gen(period_FE)
	//binsreg admitted puntaje period_FE*
restore


use  "$TEMP\applied_matched", clear
 
keep id_cutoff score_raw universidad year id_periodo_postulacion admitted carrera_primera_opcion carrera_ingreso facultad cutoff_raw
preserve
	drop if score_raw==0
	keep if universidad == "PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ"
	keep if id_cutoff==5001
	sort carrera_primera_opcion score_raw
	histogram score_raw
	sum score_raw, de
	tab id_cutoff, gen(period_FE)
	binsreg admitted score_raw period_FE*,xline()
restore

// UNMS seems to be by carrera (180)


use  "$TEMP\applied", clear

keep id_cutoff_department id_cutoff_major score_raw admitted rank* score* universidad facultad
rename id_cutoff_department id_cutoff

merge m:1 id_cutoff using "$TEMP\applied_cutoffs", keep(master match)
foreach v of var has_cutoff-R2_all {
	rename `v' `v'_department
}
drop _merge
rename id_cutoff id_cutoff_department

rename id_cutoff_major id_cutoff
merge m:1 id_cutoff using "$TEMP\applied_cutoffs_major", keep(master match)
foreach v of var has_cutoff-R2_all {
	rename `v' `v'_major
}
drop _merge
rename id_cutoff id_cutoff_major


gen score_relative_department = score_std_department - cutoff_std_department
gen ABOVE_department = (rank_score_raw_department>=cutoff_rank_department) if score_relative_department!=.	

gen score_relative_major = score_std_major - cutoff_std_major
gen ABOVE_major = (rank_score_raw_major>=cutoff_rank_major) if score_relative_major!=.	

binsreg admitted score_relative_department if abs(score_relative_department)<4, name(first_stage_department, replace)
binsreg admitted score_relative_major if abs(score_relative_major)<4, name(first_stage_major, replace)

graph combine 					///
				first_stage_department ///
				first_stage_major 	///
				, ///
	xsize(8) col(2) ///
	name(first_stage_test, replace)	

graph export 	"$FIGURES/first_stage_test.png", replace

preserve
	gen correct_major = .
	replace correct_major = 1 if (admitted==1 & ABOVE_major==1) | (admitted==0 & ABOVE_major==0)
	replace correct_major = 0 if (admitted==1 & ABOVE_major==0) | (admitted==0 & ABOVE_major==1)
	collapse correct_major, by(id_cutoff_department)
	tempfile correct_major
	save `correct_major', replace
restore

preserve
	gen correct_department = .
	replace correct_department = 1 if (admitted==1 & ABOVE_department==1) | (admitted==0 & ABOVE_department==0)
	replace correct_department = 0 if (admitted==1 & ABOVE_department==0) | (admitted==0 & ABOVE_department==1)
	collapse correct_department, by(id_cutoff_department)
	tempfile correct_department
	save `correct_department', replace
restore

merge m:1 id_cutoff_department 	using  `correct_major'		, keep(master match) nogen
merge m:1 id_cutoff_department	using  `correct_department', keep(master match) nogen

scatter correct_major correct_department

br if id_cutoff_department == 7978

list id_cutoff_department if correct_department>0.95 & correct_major<0.5 & correct_department!=.

sort id_cutoff_major score_raw

distinct id_cutoff_department if correct_department>correct_major & correct_department!=. & correct_major!=.
distinct id_cutoff_department if correct_department<correct_major & correct_department!=. & correct_major!=.
distinct id_cutoff_department if correct_department==correct_major & correct_department!=. & correct_major!=.

tab universidad if correct_department>correct_major+0.3 & correct_department!=. & correct_major!=.
tab universidad if correct_department<correct_major & correct_department!=. & correct_major!=.
tab universidad if correct_department==correct_major & correct_department!=. & correct_major!=.

use "$TEMP\applied_cutoffs_major", clear


use "$TEMP\applied_cutoffs", clear







