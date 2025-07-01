
use "C:\Users\Francisco\Dropbox\Alfonso_Minedu\SIAGIE\siagie_12_22_ece_12_19_postulantes(27.07.2022).dta", clear

keep  periodo_postulacion universidad modalidad_admis puntaje_postulante es_ingresante version_ingreso

keep if periodo_postulacion!=""
drop if puntaje_postulante==0

//enough cases
bys  periodo_postulacion universidad modalidad_admis: gen N=_N

//admitted and non admitted
bys  periodo_postulacion universidad modalidad_admis (es_ingresante): gen both = es_ingresante[1]!=es_ingresante[_N]

sort  periodo_postulacion universidad modalidad_admis puntaje_postulante

br  periodo_postulacion universidad modalidad_admis puntaje_postulante es_ingresante version_ingreso if N>10 & both==1
br  periodo_postulacion universidad modalidad_admis puntaje_postulante es_ingresante version_ingreso if strmatch(universidad,"*SAN MARCOS*")==1


bys universidad: egen p_ingresante = mean(es_ingresante=="True")
bys universidad: gen t_postulante = _N

//Interesting pattern: some very high and very low acceptance rates univesities in sample. Is it that students try very high and then go for a safe place?
histogram p_ingresante if t_postulante>20

