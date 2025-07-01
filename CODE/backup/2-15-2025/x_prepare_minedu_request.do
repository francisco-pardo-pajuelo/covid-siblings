*- Prepare data dictionary for MINEDU


*-- ECE

//List data given


//Cross with OLPC and see what's missing

//Add extra things


*-- SIAGIE

//List data given
use  "$TEMP\applied_raw_TEST", clear

use  "$TEMP\enrolled_raw_TEST", clear


*** Is there anything else needed when adding "INSTITUTOS TECNICOS?" OR would the new variables be enough?


//Cross with OLPC and see what's missing
use "C:\Users\franc\Dropbox\Alfonso_Minedu\SIAGIE\siagie_12_22_ece_12_19_postulantes(27.07.2022).dta", clear


use "C:\Users\franc\Dropbox\Alfonso_Minedu\SIAGIE\siagie_12_22_ece_12_19_matriculados(27.07.2022).dta", clear


use "C:\Users\franc\Dropbox\Alfonso_Minedu\SIAGIE\siagie_12_22_ece_14_19_postulantes(16.05.2022).dta", clear


use "C:\Users\franc\Dropbox\Alfonso_Minedu\SIAGIE\siagie_12_22_ece_14_19_matricula(16.05.2022) (1).dta", clear


use "C:\Users\franc\Dropbox\Alfonso_Minedu\SIAGIE\SIAGIE_variables_UPDATE", clear

//Cross with OLPC urban

use "C:\Users\franc\Dropbox\SIAGIE\bases primarias\base_OLPC_SIAGIE_12al22.dta", clear
use "C:\Users\franc\Dropbox\SIAGIE\bases primarias\db_egresados.dta", clear
use "C:\Users\franc\Dropbox\SIAGIE\bases primarias\db_matriculados.dta", clear
use "C:\Users\franc\Dropbox\SIAGIE\bases primarias\db_postulantes.dta", clear
use "C:\Users\franc\Dropbox\SIAGIE\bases primarias\Minedu.dta", clear



//Add extra things


*-- SIRIES

//List data given

//Cross with OLPC and see what's missing

//Add extra things


*-- External: Census

//Check CNPV variable list


*-- External: Planilla

//Check planilla variable list

use "C:\Users\franc\Dropbox\SIAGIE\00_Planilla_Electronica\Bases\MTPE\OLPC_201901.dta", clear
use "C:\Users\franc\Dropbox\SIAGIE\00_Planilla_Electronica\Bases\MTPE\OLPC_202008.dta", clear

