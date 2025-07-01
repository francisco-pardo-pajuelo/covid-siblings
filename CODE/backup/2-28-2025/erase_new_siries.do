
*-------------------
*- Applied
*-------------------
use "$TEMP\applied_raw_TEST", clear
isvar *


local all_vars = r(varlist)
ds `all_vars', not
	
use "$TEMP\applied_raw_new_TEST", clear

isvar `all_vars'

foreach v of local all_vars {
	capture drop `v'
}

isvar tipo_institucion tipo_gestion id_persona abreviatura_anio periodo_postulacion 
local all_vars = r(varlist)
drop `all_vars'

describe

use "$TEMP\applied_raw_new_TEST", clear

desc tipo_institucion

use "$TEMP\applied_raw_TEST", clear

desc id_tipo_institucion


use

/*
NEW:
Precise region 
	codigo_ubigeo 
	departamento 
	provincia 
	distrito
Modalidad admision
	modalidad_admis modalidad_admision
Duracion:
	duracion_carrera

Otras:
	modalidad_estudio
	codigo_modular_colegio

*/



*-------------------
*- Enrolled
*-------------------
use "$TEMP\enrolled_raw_TEST", clear
isvar *


local all_vars = r(varlist)
ds `all_vars', not
	
use "$TEMP\enrolled_raw_new_TEST", clear

isvar `all_vars'

foreach v of local all_vars {
	capture drop `v'
}

isvar tipo_institucion tipo_gestion id_persona abreviatura_anio periodo_postulacion 
local all_vars = r(varlist)
drop `all_vars'

describe




*-------------------
*- Graduated
*-------------------
use "$TEMP\graduated_raw_new_TEST", clear
isvar *