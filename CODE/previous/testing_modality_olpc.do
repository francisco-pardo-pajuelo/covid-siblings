
use "C:\Users\Francisco\Dropbox\Alfonso_Minedu\SIAGIE\siagie_12_22_ece_12_19_postulantes(27.07.2022).dta", clear

keep if cruce_siries_postulaciones==1


/*
preserve
	bys universidad: gen N=_N
	bys universidad: keep if _n==1
	gsort -N
	list codigo_modular universidad N, sep(1000)
restore
*/
/*

     +----------------------------------------------------+
     | codigo_~r                        universidad     N |
     |----------------------------------------------------|
  1. | 260000065   UNIVERSIDAD TECNOLÓGICA DEL PERÚ   204 | //Almost all get in
  2. | 260000067            UNIVERSIDAD CONTINENTAL   197 | //Bunched at 10.5
  3. | 260000052          UNIVERSIDAD CÉSAR VALLEJO   177 |	//Bunched at 10
  4. | 260000055      UNIVERSIDAD PRIVADA DEL NORTE    61 | //All in 0?
     +----------------------------------------------------+

*/


keep if inlist(codigo_modular,260000065,260000052, 260000055,260000067)

keep codigo_modular puntaje_postulante modalidad_admision es_ingresante

keep if codigo_modular==260000055
drop if puntaje==0
keep if modalidad_admision == "EXAMEN ORDINARIO"

gen admin = (es_ingresante == "True")

tab puntaje admin

histogram puntaje
binsreg admin puntaje



use "C:\Users\Francisco\Dropbox\SIAGIE\bases primarias\db_postulantes.dta", clear

keep if inlist(codigo_modular,260000065,260000052, 260000055,260000067)


keep if codigo_modular==260000065


