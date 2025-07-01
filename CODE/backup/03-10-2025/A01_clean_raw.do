/********************************************************************************
- Author: Francisco Pardo
- Description: Opens raw (xls, txt), cleans it and appends to a DTA
- Date started: 08/12/2024
- Last update: 08/12/2024

- Output:

match_siagie_ece_2p
match_siagie_ece_4p
match_siagie_ece_2s

siagie_`y'

*******************************************************************************/

capture program drop main 
program define main 

	setup
	
	define_labels

	get_id_match_siagie_ece
	
	schools
	
	siagie
	
	em
	ece
	ece_survey
	
	sibling_id

	db_universities
	
	applied
	enrolled
	graduated
	
	average_data
	additional_data
	
	erase_data

end

********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup

	set seed 1234
	global excel = 1
	global test = 0
	global new = 1
	
end


********************************************************************************
* labels
********************************************************************************

capture program drop define_labels
program define define_labels
	
	capture label define yes_no 1 "Yes" 0 "No", replace
	
	capture label define dep ///
		1 "Amazonas" ///
		2 "Ancash" ///
		3 "Apurímac" ///
		4 "Arequipa" ///
		5 "Ayacucho" ///
		6 "Cajamarca" ///
		7 "Callao" ///
		8 "Cusco" ///
		9 "Huancavelica" ///
		10 "Huánuco" ///
		11 "Ica" ///
		12 "Junín" ///
		13 "La Libertad" ///
		14 "Lambayeque" ///
		15 "Lima" ///
		16 "Loreto" ///
		17 "Madre de Dios" ///
		18 "Moquegua" ///
		19 "Pasco" ///
		20 "Piura" ///
		21 "Puno" ///
		22 "San Martín" ///
		23 "Tacna" ///
		24 "Tumbes" ///
		25 "Ucayali" ///
		99 "Multiple Regions", replace //For universities with multiple locations

		
	capture label define public 0 "Private" 1 "Public", replace
	capture label define level 1 "Pre-school" 2 "Primary" 3 "Secondary" , replace
	
	capture label define type_admission ///
		1 "Examen Ordinario" ///
		2 "Academia Preparatoria" ///
		3 "Modalidad Escolar" ///
		4 "1er y 2do puesto escolar" ///
		5 "Traslado externo" ///
		6 "Tercio superior" ///
		7 "Adulto" ///
		8 "Otra" ///
		, replace
		
		
	capture label define type_in_person ///
		1 "Presencial" ///
		2 "Semi-presencial" ///
		3 "Virtual" ///
		4 "A distancia" ///
		5 "No aplica" ///
		, replace
		
	capture label define type_const ///
		1 "Públicas Institucionalizadas" ///
		2 "Públicas con comisión organizadora" ///
		3 "Privadas Societarias" ///
		4 "Privadas Asociativas" ///
		, replace		
	
	//LABEL
	capture label define universidad_cod ///
	160000001 "UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS" ///
	160000002 "UNIVERSIDAD NACIONAL DE SAN CRISTÓBAL DE HUAMANGA" ///
	160000003 "UNIVERSIDAD NACIONAL DE SAN ANTONIO ABAD DEL CUSCO" ///
	160000004 "UNIVERSIDAD NACIONAL DE TRUJILLO" ///
	160000005 "UNIVERSIDAD NACIONAL DE SAN AGUSTÍN" ///
	160000006 "UNIVERSIDAD NACIONAL DE INGENIERÍA" ///
	160000007 "UNIVERSIDAD NACIONAL AGRARIA LA MOLINA" ///
	160000009 "UNIVERSIDAD NACIONAL SAN LUIS GONZAGA DE ICA" ///
	160000010 "UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ" ///
	160000011 "UNIVERSIDAD NACIONAL DE LA AMAZONÍA PERUANA" ///
	160000012 "UNIVERSIDAD NACIONAL DEL ALTIPLANO" ///
	160000013 "UNIVERSIDAD NACIONAL DE PIURA" ///
	160000016 "UNIVERSIDAD NACIONAL DE CAJAMARCA" ///
	160000021 "UNIVERSIDAD NACIONAL FEDERICO VILLARREAL" ///
	160000022 "UNIVERSIDAD NACIONAL AGRARIA DE LA SELVA" ///
	160000023 "UNIVERSIDAD NACIONAL HERMILIO VALDIZAN" ///
	160000025 "UNIVERSIDAD NACIONAL DE EDUCACIÓN ENRIQUE GUZMÁN Y VALLE" ///
	160000026 "UNIVERSIDAD NACIONAL DANIEL ALCIDES CARRIÓN" ///
	160000027 "UNIVERSIDAD NACIONAL DEL CALLAO" ///
	160000028 "UNIVERSIDAD NACIONAL JOSÉ FAUSTINO SÁNCHEZ CARRIÓN" ///
	160000031 "UNIVERSIDAD NACIONAL PEDRO RUÍZ GALLO" ///
	160000032 "UNIVERSIDAD NACIONAL JORGE BASADRE GROHMANN" ///
	160000033 "UNIVERSIDAD NACIONAL SANTIAGO ANTÚNEZ DE MAYOLO" ///
	160000034 "UNIVERSIDAD NACIONAL DE SAN MARTÍN" ///
	160000035 "UNIVERSIDAD NACIONAL DE UCAYALI" ///
	160000041 "UNIVERSIDAD NACIONAL DE TUMBES" ///
	160000042 "UNIVERSIDAD NACIONAL DEL SANTA" ///
	160000051 "UNIVERSIDAD NACIONAL DE HUANCAVELICA" ///
	160000075 "UNIVERSIDAD NACIONAL AMAZÓNICA DE MADRE DE DIOS" ///
	160000076 "UNIVERSIDAD NACIONAL TORIBIO RODRÍGUEZ DE MENDOZA DE AMAZONAS" ///
	160000077 "UNIVERSIDAD NACIONAL MICAELA BASTIDAS DE APURIMAC" ///
	160000084 "UNIVERSIDAD NACIONAL INTERCULTURAL DE LA AMAZONIA" ///
	160000088 "UNIVERSIDAD NACIONAL TECNOLÓGICA DE LIMA SUR" ///
	160000089 "UNIVERSIDAD NACIONAL JOSE MARIA ARGUEDAS" ///
	160000095 "UNIVERSIDAD NACIONAL DE MOQUEGUA" ///
	160000098 "UNIVERSIDAD NACIONAL DE JULIACA" ///
	160000101 "UNIVERSIDAD NACIONAL DE JAÉN" ///
	160000106 "UNIVERSIDAD NACIONAL DE CAÑETE" ///
	160000120 "UNIVERSIDAD NACIONAL AUTÓNOMA DE CHOTA" ///
	160000121 "UNIVERSIDAD NACIONAL DE BARRANCA" ///
	160000122 "UNIVERSIDAD NACIONAL DE FRONTERA" ///
	160000123 `"UNIVERSIDAD NACIONAL INTERCULTURAL "FABIOLA SALAZAR LEGUÍA" DE BAGUA"' ///
	160000124 "UNIVERSIDAD NACIONAL INTERCULTURAL DE LA SELVA CENTRAL JUAN SANTOS ATAHUALPA" ///
	160000125 "UNIVERSIDAD NACIONAL INTERCULTURAL DE QUILLABAMBA" ///
	160000126 "UNIVERSIDAD NACIONAL AUTÓNOMA DE ALTO AMAZONAS" ///
	160000127 "UNIVERSIDAD NACIONAL AUTÓNOMA ALTOANDINA DE TARMA" ///
	160000128 "UNIVERSIDAD NACIONAL AUTÓNOMA DE HUANTA" ///
	160000138 `"UNIVERSIDAD NACIONAL AUTÓNOMA DE TAYACAJA "DANIEL HERNÁNDEZ MORILLO""' ///
	260000008 "PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ" ///
	260000014 "UNIVERSIDAD PERUANA CAYETANO HEREDIA" ///
	260000015 "UNIVERSIDAD CATÓLICA DE SANTA MARÍA" ///
	260000017 "UNIVERSIDAD DEL PACÍFICO" ///
	260000018 "UNIVERSIDAD DE LIMA" ///
	260000019 "UNIV DE SAN MARTÍN DE PORRES" ///
	260000020 "UNIVERSIDAD FEMENINA DEL SAGRADO CORAZÓN" ///
	260000024 "UNIVERSIDAD INCA GARCILASO DE LA VEGA" ///
	260000029 "UNIVERSIDAD DE PIURA" ///
	260000030 "UNIVERSIDAD RICARDO PALMA" ///
	260000036 "UNIVERSIDAD ANDINA NÉSTOR CÁCERES VELÁSQUEZ" ///
	260000037 "UNIVERSIDAD PERUANA LOS ANDES" ///
	260000038 "UNIVERSIDAD PERUANA UNIÓN" ///
	260000039 "UNIVERSIDAD ANDINA DEL CUSCO" ///
	260000040 "UNIVERSIDAD TECNOLOGICA DE LOS ANDES" ///
	260000043 "UNIVERSIDAD PRIVADA DE TACNA" ///
	260000044 "UNIVERSIDAD PARTICULAR DE CHICLAYO" ///
	260000045 "UNIVERSIDAD SAN PEDRO" ///
	260000046 "UNIVERSIDAD PRIVADA ANTENOR ORREGO" ///
	260000047 "UNIVERSIDAD DE HUANUCO" ///
	260000048 "UNIVERSIDAD JOSÉ CARLOS MARIÁTEGUI" ///
	260000049 "UNIVERSIDAD MARCELINO CHAMPAGNAT" ///
	260000050 "UNIVERSIDAD CIENTÍFICA DEL PERÚ - UCP" ///
	260000052 "UNIVERSIDAD CÉSAR VALLEJO" ///
	260000053 "UNIVERSIDAD CATÓLICA LOS ÁNGELES DE CHIMBOTE" ///
	260000054 "UNIVERSIDAD PERUANA DE CIENCIAS APLICADAS" ///
	260000055 "UNIVERSIDAD PRIVADA DEL NORTE" ///
	260000057 "UNIVERSIDAD SAN IGNACIO DE LOYOLA" ///
	260000059 "UNIVERSIDAD ALAS PERUANAS" ///
	260000061 "UNIVERSIDAD NORBERT WIENER" ///
	260000062 "UNIVERSIDAD CATÓLICA SAN PABLO" ///
	260000063 "UNIVERSIDAD PRIVADA DE ICA" ///
	260000064 "UNIVERSIDAD PRIVADA SAN JUAN BAUTISTA" ///
	260000065 "UNIVERSIDAD TECNOLÓGICA DEL PERÚ" ///
	260000067 "UNIVERSIDAD CONTINENTAL" ///
	260000068 "UNIVERSIDAD CIENTÍFICA DEL SUR" ///
	260000069 "UNIVERSIDAD CATÓLICA SANTO TORIBIO DE MOGROVEJO" ///
	260000070 "UNIVERSIDAD PRIVADA ANTONIO GUILLERMO URRELO" ///
	260000071 "UNIVERSIDAD CATÓLICA SEDES SAPIENTIAE" ///
	260000072 "UNIVERSIDAD SEÑOR DE SIPÁN" ///
	260000074 "UNIVERSIDAD CATÓLICA DE TRUJILLO BENEDICTO XVI" ///
	260000078 "UNIVERSIDAD PERUANA DE LAS AMÉRICAS" ///
	260000079 "UNIVERSIDAD ESAN" ///
	260000080 "UNIVERSIDAD ANTONIO RUIZ DE MONTOYA" ///
	260000081 "UNIVERSIDAD PERUANA DE CIENCIA E INFORMÁTICA" ///
	260000082 "UNIVERSIDAD PARA EL DESARROLLO ANDINO" ///
	260000083 "UNIVERSIDAD PRIVADA TELESUP" ///
	260000085 "UNIVERSIDAD PRIVADA SERGIO BERNALES" ///
	260000086 "UNIVERSIDAD PRIVADA DE PUCALLPA" ///
	260000087 "UNIVERSIDAD AUTÓNOMA DE ICA" ///
	260000090 "UNIVERSIDAD PRIVADA DE TRUJILLO" ///
	260000091 "UNIVERSIDAD PRIVADA SAN CARLOS" ///
	260000092 "UNIVERSIDAD PERUANA SIMÓN BOLÍVAR" ///
	260000093 "UNIVERSIDAD PERUANA DE INTEGRACIÓN GLOBAL" ///
	260000094 "UNIVERSIDAD PERUANA DEL ORIENTE" ///
	260000096 "UNIVERSIDAD AUTÓNOMA DEL PERU" ///
	260000097 "UNIVERSIDAD DE CIENCIAS Y HUMANIDADES" ///
	260000099 "UNIVERSIDAD PRIVADA JUAN MEJÍA BACA" ///
	260000100 "UNIVERSIDAD JAIME BAUSATE Y MEZA" ///
	260000102 "UNIVERSIDAD PERUANA DEL CENTRO" ///
	260000103 "UNIVERSIDAD PRIVADA ARZOBISPO LOAYZA" ///
	260000104 "UNIVERSIDAD LE CORDON BLEU" ///
	260000105 "UNIVERSIDAD PRIVADA DE HUANCAYO FRANKLIN ROOSEVELT" ///
	260000107 "UNIVERSIDAD DE LAMBAYEQUE" ///
	260000108 "UNIVERSIDAD DE CIENCIAS Y ARTES DE AMÉRICA LATINA" ///
	260000109 "UNIVERSIDAD PERUANA DE ARTE ORVAL" ///
	260000110 "UNIVERSIDAD PRIVADA DE LA SELVA PERÚANA" ///
	260000111 "UNIVERSIDAD CIENCIAS DE LA SALUD" ///
	260000112 "UNIVERSIDAD DE AYACUCHO FEDERICO FROEBEL" ///
	260000113 "UNIVERSIDAD PERUANA DE INVESTIGACIÓN Y NEGOCIOS" ///
	260000114 "UNIVERSIDAD PERUANA AUSTRAL DEL CUSCO" ///
	260000115 "UNIVERSIDAD AUTÓNOMA SAN FRANCISCO" ///
	260000116 "UNIVERSIDAD SAN ANDRÉS" ///
	260000117 "UNIVERSIDAD INTERAMÉRICANA PARA EL DESARROLLO" ///
	260000118 "UNIVERSIDAD PRIVADA JUAN PABLO II" ///
	260000119 "UNIVERSIDAD PRIVADA LEONARDO DA VINCI" ///
	260000132 "UTEC" ///
	260000133 "UNIVERSIDAD LA SALLE" ///
	260000134 "UNIVERSIDAD LATINOAMERICANA CIMA" ///
	260000135 "UNIVERSIDAD PRIVADA AUTÓNOMA DEL SUR" ///
	260000136 "UNIVERSIDAD MARÍA AUXILIADORA" ///
	260000137 "UNIVERSIDAD POLITÉCNICA AMAZÓNICA" ///
	260000140 "UNIVERSIDAD SANTO DOMINGO DE GUZMÁN SAC" ///
	260000141 "UNIVERSIDAD MARÍTIMA DEL PERÚ" ///
	260000142 "UNIVERSIDAD PRIVADA LIDER PERUANA" ///
	260000143 "UNIVERSIDAD PRIVADA PERUANO ALEMANA" ///
	260000144 "UNIVERSIDAD GLOBAL DEL CUSCO" ///
	260000145 "UST UNIVERSIDAD SANTO TOMÁS" ///
	260000146 "UNIVERSIDAD PRIVADA SISE" ///
	260000501 "FACULTAD DE TEOLOGÍA PONTIFICIA Y CIVIL DE LIMA" ///
	260000601 "UNIVERSIDAD SEMINARIO BÍBLICO ANDINO" ///
	260000602 "UNIVERSIDAD SEMINARIO EVANGÉLICO DE LIMA" ///
	, replace
	
end





********************************************************************************
* SIAGIE-ECE Match
********************************************************************************

capture program drop get_id_match_siagie_ece
program define get_id_match_siagie_ece

	*- From 2007-2013 match (includes name)
	import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE07_13.xlsx", sheet("Sheet1") firstrow allstring clear 
	tempfile siagie_ece_2007_2013_s1
	save `siagie_ece_2007_2013_s1', replace

	import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE07_13.xlsx", sheet("Sheet2") firstrow allstring clear
	tempfile siagie_ece_2007_2013_s2
	save `siagie_ece_2007_2013_s2', replace

	import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE07_13.xlsx", sheet("Sheet3") firstrow allstring clear
	tempfile siagie_ece_2007_2013_s3
	save `siagie_ece_2007_2013_s3', replace


	*- From 2014-2023 match (include name and ID)
	import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE14_23.xlsx", sheet("Sheet1") firstrow allstring clear
	tempfile siagie_ece_2014_2023_s1
	save `siagie_ece_2014_2023_s1', replace

	import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE14_23.xlsx", sheet("Sheet2") firstrow allstring clear
	tempfile siagie_ece_2014_2023_s2
	save `siagie_ece_2014_2023_s2', replace

	import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE14_23.xlsx", sheet("Sheet3") firstrow allstring clear
	tempfile siagie_ece_2014_2023_s3
	save `siagie_ece_2014_2023_s3', replace

	import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE14_23.xlsx", sheet("Sheet4") firstrow allstring clear
	tempfile siagie_ece_2014_2023_s4
	save `siagie_ece_2014_2023_s4', replace

	import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE14_23.xlsx", sheet("Sheet5") firstrow allstring clear
	tempfile siagie_ece_2014_2023_s5
	save `siagie_ece_2014_2023_s5', replace
	
	*- From EM
	import excel "$IN\MINEDU\ECE EM innominada\EM\empate SIAGIE-EM.xlsx", sheet("Sheet1") firstrow allstring clear
	tempfile siagie_em
	save `siagie_em', replace

	clear
	append using `siagie_ece_2007_2013_s1'
	append using `siagie_ece_2007_2013_s2'
	append using `siagie_ece_2007_2013_s3'
	append using `siagie_ece_2014_2023_s1'
	append using `siagie_ece_2014_2023_s2'
	append using `siagie_ece_2014_2023_s3'
	append using `siagie_ece_2014_2023_s4'
	append using `siagie_ece_2014_2023_s5'
	gen source = 1 // ECE
	append using `siagie_em'
	replace source = 2 if source==. //EM

	rename *, lower
	
	*-Remove duplicates, it should only match with one SIAGIE (one SIAGIE can have multiple ECE)
	bys id_estudiante: drop if _N>1 //1671 cases dropped, ~0.02%
	
	*-There could be multiple tests pear each student. We divide them by grade and keep the first one from each grade.
	gen grade = substr(id_estudiante,5,2)
	replace grade = "2" if grade == "12"
	replace grade = "4" if grade == "14"
	replace grade = "8" if grade == "22"
	destring grade, replace
	
	gen year = substr(id_estudiante,1,4) 
		
	*- There are a few who take multiple times in same grade and year. It could be transfering schools, but most likely double matching. We exclude these.
	bys id_per_umc grade year: drop if _N>1
	//30,894 deleted, ~0.4%
	
	*- We now keep the first exam per each grade (for those who take it in multiple years.)
	bys id_per_umc grade (year): keep if _n==1
	//227,871 observations ~3% 
	
	drop year
	
	//reshape wide id_estudiante, i(id_per_umc) j(grade)

	capture label define source_ece 1 "ECE" 2 "EM", replace
	label values source source_ece
	
	compress
	
	preserve
		keep if grade == 2
		drop grade
		destring id_per_umc, replace
		save "$TEMP\match_siagie_ece_2p", replace
	restore
	
	preserve
		keep if grade == 4
		drop grade
		destring id_per_umc, replace
		save "$TEMP\match_siagie_ece_4p", replace
	restore
	
	preserve
		keep if grade == 8
		drop grade
		destring id_per_umc, replace
		save "$TEMP\match_siagie_ece_2s", replace
	restore	

end



********************************************************************************
* School database
********************************************************************************

capture program drop schools
program define schools

	import dbase using "$IN/MINEDU/Padron/Padron_web.dbf", clear

	define_labels
		
	gen id_ie = COD_MOD + ANEXO

	keep id_ie AREA_CENSO D_COD_CAR
	
	*- Urban
	destring AREA_CENSO, replace
	recode AREA_CENSO (2 = 0), gen(urban)
	drop AREA_CENSO

	label var id_ie "ID school (codmod + anex)"
	label var urban "Area: Urban"
	
	label values urban yes_no

	*- Polidocente Completo or unidocente/multigrado
	gen carac = 1 if D_COD_CAR == "Unidocente"
	replace carac=2 if D_COD_CAR == "Polidocente Multigrado"
	replace carac=3 if D_COD_CAR == "Polidocente Completo"
	replace carac=4 if D_COD_CAR == "No aplica"
	replace carac=. if D_COD_CAR == "No disponible"
	
	label var carac "School type"
	label define carac 1 "Unidocente" 2 "Polidocente Multigrado" 3 "Polidocente Completo" 4 "Does not apply (not primary)", replace 
	label values carac carac

save "$OUT/schools_20241018", replace

end

********************************************************************************
* SIAGIE: clean raw SIAGIE data
********************************************************************************

capture program drop siagie
program define siagie

	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {

		if $test == 0 & $excel ==1 {
			capture import delimited "$IN\MINEDU\ECE EM innominada\SIAGIE\Data_matriculados_siries_`y'_INNOM.txt",  stringcols(_all) clear
			capture import delimited "$IN\MINEDU\ECE EM innominada\SIAGIE\Data_matriculados_siries_`y' INNOM.txt",  stringcols(_all) clear
			capture import delimited "$IN\MINEDU\ECE EM innominada\SIAGIE\Data_SIAGIE_`y' INNOM.txt",  stringcols(_all) clear
		}
			
		if $test == 0 & $excel ==0 {
			assert 1==0 //To save space we don't save the raw excel as dta
		}
				
		if $test == 1 & $excel ==1 {
			capture import delimited "$IN\MINEDU\ECE EM innominada\SIAGIE\Data_matriculados_siries_`y'_INNOM.txt", stringcols(_all) clear
			capture import delimited "$IN\MINEDU\ECE EM innominada\SIAGIE\Data_matriculados_siries_`y' INNOM.txt", stringcols(_all) clear
			capture import delimited "$IN\MINEDU\ECE EM innominada\SIAGIE\Data_SIAGIE_`y' INNOM.txt", stringcols(_all) clear
			keep if u<0.001
			save "$TEMP\siagie_raw_`y'_TEST", replace
		}

		if $test == 1 & $excel ==0 {
			use "$TEMP\siagie_raw_`y'_TEST", clear
		}
			
	
		define_labels
			
		*- Format all strings in UPPER
		ds, has(type string)
		local string_vars = r(varlist)

		foreach v of local string_vars {
			ds `v'
			replace `v' = upper(`v')
			replace `v' = trim(itrim(`v'))
		}

		*- CODMOD and ANEXO in string
		tostring cod_mod_siagie anexo, replace
		forvalues i = 1(1)8 {
			replace cod_mod_siagie = "0" + cod_mod_siagie if strlen(cod_mod_siagie)<7
			}
			
		*- Year
		rename id_anio_siagie year

		*- Region
		rename departamento_siagie region_siagie
		replace region_siagie = "1" if region_siagie == "AMAZONAS"
		replace region_siagie = "2" if region_siagie == "ANCASH"
		replace region_siagie = "3" if region_siagie == "APURIMAC"
		replace region_siagie = "4" if region_siagie == "AREQUIPA"
		replace region_siagie = "5" if region_siagie == "AYACUCHO"
		replace region_siagie = "6" if region_siagie == "CAJAMARCA"
		replace region_siagie = "7" if region_siagie == "CALLAO"
		replace region_siagie = "8" if region_siagie == "CUSCO"
		replace region_siagie = "9" if region_siagie == "HUANCAVELICA"
		replace region_siagie = "10" if region_siagie == "HUANUCO"
		replace region_siagie = "11" if region_siagie == "ICA"
		replace region_siagie = "12" if region_siagie == "JUNIN"
		replace region_siagie = "13" if region_siagie == "LA LIBERTAD"
		replace region_siagie = "14" if region_siagie == "LAMBAYEQUE"
		replace region_siagie = "15" if region_siagie == "LIMA"
		replace region_siagie = "16" if region_siagie == "LORETO"
		replace region_siagie = "17" if region_siagie == "MADRE DE DIOS"
		replace region_siagie = "18" if region_siagie == "MOQUEGUA"
		replace region_siagie = "19" if region_siagie == "PASCO"
		replace region_siagie = "20" if region_siagie == "PIURA"
		replace region_siagie = "21" if region_siagie == "PUNO"
		replace region_siagie = "22" if region_siagie == "SAN MARTIN"
		replace region_siagie = "23" if region_siagie == "TACNA"
		replace region_siagie = "24" if region_siagie == "TUMBES"
		replace region_siagie = "25" if region_siagie == "UCAYALI"
		destring region_siagie, replace
		label values region_siagie dep
		
		
		
		*- Public school
		gen public = 1 if inlist(gestion_siagie,"PUBLICO", "PÚBLICO")==1 
		replace public = 0 if gestion_siagie=="PRIVADO" 
		label var public "School: Public"
		label values public public
		rename public public_siagie

		*- Level 
		gen level = .
		replace level = 1 if strmatch(nivel_educativo_siagie,"*INICIAL*")==1
		replace level = 2 if strmatch(nivel_educativo_siagie,"*PRIMARIA*")==1
		replace level = 3 if strmatch(nivel_educativo_siagie,"*SECUNDARIA*")==1

		*- Basic school
		gen ebr = (strmatch(nivel_educativo_siagie,"*ESPECIAL*")==0)

		*- Grade
		gen grade = 0 if level==1
		replace grade = 1 if level==2 & strmatch(grado_siagie,"*PRIMERO*")==1
		replace grade = 2 if level==2 & strmatch(grado_siagie,"*SEGUNDO*")==1
		replace grade = 3 if level==2 & strmatch(grado_siagie,"*TERCERO*")==1
		replace grade = 4 if level==2 & strmatch(grado_siagie,"*CUARTO*")==1
		replace grade = 5 if level==2 & strmatch(grado_siagie,"*QUINTO*")==1
		replace grade = 6 if level==2 & strmatch(grado_siagie,"*SEXTO*")==1
		replace grade = 7 if level==3 & strmatch(grado_siagie,"*PRIMERO*")==1
		replace grade = 8 if level==3 & strmatch(grado_siagie,"*SEGUNDO*")==1
		replace grade = 9 if level==3 & strmatch(grado_siagie,"*TERCERO*")==1
		replace grade = 10 if level==3 & strmatch(grado_siagie,"*CUARTO*")==1
		replace grade = 11 if level==3 & strmatch(grado_siagie,"*QUINTO*")==1

		*- Male
		gen male_siagie = sexo_siagie == "HOMBRE" if inlist(sexo_siagie,"HOMBRE","MUJER")==1

		*- Approved grade
		if inlist("`y'","2014","2015","2016","2017","2018","2019","2023")== 1 {
			gen approved 		= sf_regular == "APROBADO" | sf_recuperacion=="APROBADO"
			gen approved_first 	= sf_regular == "APROBADO"
			tabstat approved* , by(grade)
		}
		if inlist("`y'","2020","2021","2022")== 1 {
			gen approved 		= sf_regular == "PROMOVIDO" | sf_regular=="PROMOCIóN GUIADA" //Not sure if it should be this or similar to other years. What is promocion guiada?
			gen approved_first 	= sf_regular == "PROMOVIDO"
			tabstat approved* , by(grade)		
		}
		
		//Check ID 
		/*
		forvalues i = 1/8 {
			 gen d`i' = substr( id_persona_apoderado_rec,`i',1)
			 tab d`i'
		}	
		*/


		*- Course grades
		if inlist("`y'","2014","2015","2016","2017","2018","2019")==1 		rename (comunicación matemática) (comm math)
		if inlist("`y'","2020","2021","2022","2023")==1 					rename (comunicación_c1 matemática_c1) (comm math) //What are the different grades (c1, c2, c3, c4?)
		

		//Generally, primary is letters, but in 2019, 7th grade had letter grades
		if inlist("`y'","2014","2015","2016","2017","2018") == 1 {
			gen math_primary = math if level==2 
			gen math_secondary = math if level==3 

			gen comm_primary = comm if level==2 
			gen comm_secondary = comm if level==3 
		}
		
		if inlist("`y'","2019") == 1 {
			gen math_primary = math if level==2 | (level==3 & grade<=7)
			gen math_secondary = math if level==3 & grade>=8

			gen comm_primary = comm if level==2 | (level==3 & grade<=7)
			gen comm_secondary = comm if level==3 & grade>=8
		}	
		
		if inlist("`y'","2020") == 1 {
			gen math_primary = math if level==2 | (level==3 & grade<=8)
			gen math_secondary = math if level==3 & grade>=9

			gen comm_primary = comm if level==2 | (level==3 & grade<=8)
			gen comm_secondary = comm if level==3 & grade>=9
		}
		
		if inlist("`y'","2021") == 1 {
			gen math_primary = math if level==2 | (level==3 & grade<=9)
			gen math_secondary = math if level==3 & grade>=10

			gen comm_primary = comm if level==2 | (level==3 & grade<=9)
			gen comm_secondary = comm if level==3 & grade>=10
		}

		if inlist("`y'","2022") == 1 {
			gen math_primary = math if level==2 | (level==3 & grade<=10)
			gen math_secondary = math if level==3 & grade>=11

			gen comm_primary = comm if level==2 | (level==3 & grade<=10)
			gen comm_secondary = comm if level==3 & grade>=11
		}

		if inlist("`y'","2023") == 1 { //Now all are letters.
			gen math_primary = math if level==2 | (level==3)
			gen math_secondary = .

			gen comm_primary = comm if level==2 | (level==3)
			gen comm_secondary = .
		}	
		destring math_secondary comm_secondary, replace //because there is no variable for 2023

		*- Adult variables
		foreach adult in "caretaker" "mother" "father" {
			if "`adult'" == "caretaker" local adult_sp = "apoderado"
			if "`adult'" == "mother" local adult_sp = "madre"
			if "`adult'" == "father" local adult_sp = "padre"
			
			*- ID
			rename id_persona_`adult_sp'_rec id_`adult'
			
			*- Sex
			rename sexo_`adult_sp' sex_`adult'
			gen male_`adult' = (sex_`adult' == "HOMBRE") if inlist(sex_`adult',"HOMBRE","MUJER")==1
			drop sex_`adult'
			
			*- Date of birth
			gen dob_`adult' = date(fecha_nacimiento_`adult_sp', "YMD") 
			format %td dob_`adult'
			
			*- Lives with adult
			gen lives_with_`adult' = (vive_con_estudiante_`adult_sp'=="SI") if inlist(vive_con_estudiante_`adult_sp',"SI","NO")==1
			drop vive_con_estudiante_`adult_sp'
			
			*- Educ
			
			gen educ_`adult' = .
			replace educ_`adult' = 1 if nivel_instruccion_`adult_sp' == "NINGUNO"
			replace educ_`adult' = 2 if nivel_instruccion_`adult_sp' == "PRIMARIA INCOMPLETA"
			replace educ_`adult' = 3 if nivel_instruccion_`adult_sp' == "PRIMARIA COMPLETA"
			replace educ_`adult' = 4 if nivel_instruccion_`adult_sp' == "SECUNDARIA INCOMPLETA"
			replace educ_`adult' = 5 if nivel_instruccion_`adult_sp' == "SECUNDARIA COMPLETA"
			replace educ_`adult' = 6 if inlist(nivel_instruccion_`adult_sp',"SUPERIOR NO UNIVERSITARIA INCOMPLETA","SUPERIOR UNIVERSITARIA INCOMPLETA")==1
			replace educ_`adult' = 7 if inlist(nivel_instruccion_`adult_sp',"SUPERIOR NO UNIVERSITARIA COMPLETA","SUPERIOR UNIVERSITARIA COMPLETA")==1
			replace educ_`adult' = 8 if nivel_instruccion_`adult_sp' == "SUPERIOR POST GRADUADO"
			drop nivel_instruccion_`adult_sp'
			
			
			
			}
			
		label define educ 1 "None" 2 "Primary Incomplete" 3 "Primary Complete" 4 "Secondary Incomplete" 5 "Secondary Complete" 6 "Higher Incomplete" 7 "Higher Complete" 8 "Post-grad", replace
		label values educ_caretaker educ_mother educ_father educ
		
		*- ID IE
		gen id_ie = cod_mod_siagie + anexo
		
		merge m:1 id_ie using "$OUT/schools_20241018", keep(master match) nogen
		rename urban urban_siagie
		rename carac carac_siagie
		
		*- Drop duplicate students. Not that many observations:
		bys id_per_umc: drop if _N>1

				isvar 	/*ID*/ 			id_per_umc year ///
						/*GEO*/			region_siagie public_siagie urban_siagie carac_siagie ///
						/*School*/		id_ie /*cod_mod_siagie anexo_siagie*/ ebr level grade seccion_siagie ///
						/*Student*/		male_siagie ///
						/*Grades*/		approved approved_first /*math_primary*/ math_secondary /*comm_primary*/ comm_secondary ///
						/*Adult*/ 		 *caretaker *mother *father 
						/*Family*/		// id_fam N_siblings
				local all_vars = r(varlist)
				ds `all_vars', not
				keep `all_vars'
				order `all_vars'

				foreach v of local all_vars {
					capture confirm string variable `v'
						if _rc==0 {
							   replace `v' = trim(itrim(`v'))
						}
				}
				
				*Destring those not IDs
				ds id_per_umc id_ie, not
				local all_vars = r(varlist)
				destring `all_vars', replace
							
				compress	
			
			
		if ${test}==0 save "$TEMP\siagie_`y'", replace
		if ${test}==1 save "$TEMP\siagie_`y'_TEST", replace
	}
	/*
	clear
	foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		append using "$TEMP\siagie_`y'_TEST", keep(id_per_umc)
		
	}
	*/
end



********************************************************************************
* EM : Sample Examination
********************************************************************************


capture program drop em
program define em


	if $excel == 1 {
	import excel "$IN\MINEDU\ECE EM innominada\EM\EM_2P_2018_alumnos_innominado.xlsx", sheet("BD") firstrow allstring clear	
		rename *, lower
		compress
		save "$TEMP\em_raw_2p_2018", replace

		import excel "$IN\MINEDU\ECE EM innominada\EM\EM_2P_2019_alumnos_innominado.xlsx", sheet("BD") firstrow allstring clear	
		rename *, lower
		compress
		save "$TEMP\em_raw_2p_2019", replace
		
		import excel "$IN\MINEDU\ECE EM innominada\EM\EM_2P_2022_alumnos_innominado.xlsx", sheet("BD") firstrow allstring clear	
		rename *, lower
		compress
		save "$TEMP\em_raw_2p_2022", replace
		
		import excel "$IN\MINEDU\ECE EM innominada\EM\EM_2P_2023_alumnos_innominado.xlsx", sheet("BD") firstrow allstring clear	
		rename *, lower
		compress
		save "$TEMP\em_raw_2p_2023", replace
		
		import excel "$IN\MINEDU\ECE EM innominada\EM\EM_4P_2019_alumnos_innominado.xlsx", sheet("BD") firstrow allstring clear	
		rename *, lower
		compress
		save "$TEMP\em_raw_4p_2019", replace
		
		import excel "$IN\MINEDU\ECE EM innominada\EM\EM_4P_2022_alumnos_innominado.xlsx", sheet("BD") firstrow allstring clear
		rename *, lower
		compress
		save "$TEMP\em_raw_4p_2022", replace
			
		import excel "$IN\MINEDU\ECE EM innominada\EM\EM_4P_2023_alumnos_innominado.xlsx", sheet("BD") firstrow allstring clear
		rename *, lower
		compress
		save "$TEMP\em_raw_4p_2023", replace
			
		import excel "$IN\MINEDU\ECE EM innominada\EM\EM_6P_2018_alumnos_innominado.xlsx", sheet("BD") firstrow allstring clear
		rename *, lower
		compress
		save "$TEMP\em_raw_6p_2018", replace
			
		import excel "$IN\MINEDU\ECE EM innominada\EM\EM_6P_2022_alumnos_innominado.xlsx", sheet("BD") firstrow allstring clear
		rename *, lower
		compress
		save "$TEMP\em_raw_6p_2022", replace
			
		import excel "$IN\MINEDU\ECE EM innominada\EM\EM_2S_2018_alumnos_innominado.xlsx", sheet("BD") firstrow allstring clear
		rename *, lower
		compress
		save "$TEMP\em_raw_2s_2018", replace
			
		import excel "$IN\MINEDU\ECE EM innominada\EM\EM_2S_2022_alumnos_innominado.xlsx", sheet("BD") firstrow allstring clear	
		rename *, lower
		compress
		save "$TEMP\em_raw_2s_2022", replace
		
		import excel "$IN\MINEDU\ECE EM innominada\EM\EM_2S_2023_alumnos_innominado.xlsx", sheet("BD") firstrow allstring clear	
		rename *, lower
		compress
		save "$TEMP\em_raw_2s_2023", replace
		

		*- Previous delivery, with additional years (but no info on SOCIO-ECON. Main loss is 6th grade 2013, 66k obs)
		clear
		import delimited "$IN\MINEDU\Entrega-1\ECE EM innominada\Resultados_EM_ConIDPersonaSIAGIE_innom.txt", stringcols(_all) clear
		drop indpe* id_per*
		compress
		keep if inlist(año,"2013","2015","2020")==1
		
		append using "$TEMP\em_raw_2p_2018"
		append using "$TEMP\em_raw_2p_2019"
		append using "$TEMP\em_raw_2p_2022"
		append using "$TEMP\em_raw_2p_2023"
		append using "$TEMP\em_raw_4p_2019"
		append using "$TEMP\em_raw_4p_2022"
		append using "$TEMP\em_raw_4p_2023"
		append using "$TEMP\em_raw_6p_2018"
		append using "$TEMP\em_raw_6p_2022"
		append using "$TEMP\em_raw_2s_2018"
		append using "$TEMP\em_raw_2s_2022"
		append using "$TEMP\em_raw_2s_2023"
		
		save "$TEMP\em_raw", replace
		
		gen u=runiform()
		keep if u<0.01
		drop u
		save "$TEMP\em_raw_TEST", replace
		
		use "$TEMP\em_raw", clear
		} 

	if ${test}==0 & ${excel} == 0 use "$TEMP\em_raw", clear
	if ${test}==1 & ${excel} == 0 use "$TEMP\em_raw_TEST", clear
	
	define_labels

	rename año year
	rename grado grade
	rename nivel level
	rename ise socioec_index //socio-economic-index


	*- Grade
	replace grade = "2" if grade == "2do" & level == "Primaria"
	replace grade = "4" if grade == "4to" & level == "Primaria" 
	replace grade = "6" if grade == "6to" & level == "Primaria"
	replace grade = "8" if grade == "2do" & level == "Secundaria"
	destring grade, replace force

	*- Urban
	gen urban = 1 if area == "Urbana" 
	replace urban = 0 if area == "Rural"
	label var urban "Area: Urban"
	label values urban yes_no

	*- Public school
	gen public = 1 if gestion2=="Estatal" 
	replace public = 0 if gestion2=="No estatal" 
	label var public "School: Public"
	label values public public
	
	*- UBIGEO
	tostring codgeo, replace
	replace codgeo = "0" + codgeo if strlen(codgeo)<6
	assert strlen(codgeo)==6
	//replace codgeo = "0" + codgeo if strlen(codgeo)<6
	drop departamento
	gen dep = substr(codgeo,1,2)
	destring dep, replace
	label values dep dep

	*- Polidocente Completo or unidocente/multigrado
	gen polidoc = 1 if caracteristica2 == "Polidocente completo"
	replace polidoc = 0 if caracteristica2=="Unidocente / Multigrado" 
	label var polidoc "School: Grades in separate classrooms (Polidocente completo)"
	label define polidoc 0 "Unidocente / Multigrado" 1 "Polidocente completo", replace
	label values polidoc polidoc

	*- Male
	gen male = 1 if sexo=="Hombre" 
	replace male = 0 if sexo=="Mujer" 
	label var male "Sex: Male"
	label define male 0 "female" 1 "male", replace
	label values male male

	*- Mother Tongue is Spanish
	gen spanish = 1 if lengua_materna=="Castellano"
	replace spanish = 0 if lengua_materna != "Castellano" & lengua_materna!=""
	label var spanish "Mother Tongue: Spanish"
	label define spanish 0 "Other" 1 "Spanish", replace
	label values spanish spanish

	*- Socio-Economic index
	destring socioec_index, replace force
	gen socioec_index_cat = .
	label define socioec_index_cat 1 "Very Low" 2 "Low" 3 "Medium" 4 "High", replace
	label values socioec_index_cat* socioec_index_cat
	replace socioec_index_cat = 1 if n_ise == "Muy bajo"
	replace socioec_index_cat = 2 if n_ise == "Bajo"
	replace socioec_index_cat = 3 if n_ise == "Medio"
	replace socioec_index_cat = 4 if n_ise == "Alto"

	*- Scores
	destring medida500_l medida500_m medida500_cn medida500_e medida500_ciu, replace force
	rename (medida500_l medida500_m medida500_e medida500_cn medida500_ciu) (score_com score_math score_e score_sci score_ciu)
	
	
	VarStandardiz score_com, by(year grade) newvar(score_com_std)
	VarStandardiz score_math, by(year grade) newvar(score_math_std)
	VarStandardiz score_e, by(year grade) newvar(score_e_std)
	VarStandardiz score_sci, by(year grade) newvar(score_sci_std)
	VarStandardiz score_ciu, by(year grade) newvar(score_ciu_std)
	
	*- Academic index
	egen score_acad = rmean(score_com_std score_math_std)
	VarStandardiz score_acad, by(year grade) newvar(score_acad_std)
	
	*- ID school
	gen id_ie = cod_mod7 + anexo
	
	*- Attach family ID
	/*
	preserve
		keep if grade == 2
		tostring cod_mod7, replace
		replace cod_mod7="0"+cod_mod7 if strlen(cod_mod7)<7
		replace cod_mod7="0"+cod_mod7 if strlen(cod_mod7)<7
		tostring anexo, replace
		gen id_ie_2p = cod_mod7 + anexo
		rename year year_2p
		rename seccion seccion_2p
		rename male male_2p
		keep if year_2p<=2013
		keep id_estudiante id_ie_2p year_2p seccion_2p male_2p score_com score_math
		*- Check if duplicates
		bys id_ie_2p seccion_2p year_2p male_2p score_com score_math: gen N_obs=_N
		tab N_obs	
		keep if N_obs==1
		merge 1:1 id_ie_2p seccion_2p year_2p male_2p score_math score_com  using "$TEMP/ece_siblings_info", keep(match) keepusing(family_id sib_id oldest)
		drop _merge
		tempfile ece_family_merge
		save `ece_family_merge', replace
	restore
	
	merge 1:1 id_estudiante using `ece_family_merge', keep(master match) keepusing(family_id sib_id oldest)
	*/
	
			isvar 			///
				/*Match ID*/ 	/*indpe_pos* id_per_pos* indpe_mat* id_per_mat**/ ///
				/*ID*/  		id_estudiante id_ie fuente year /*cod_mod7 anexo nombre_ie*/ level grade /*cor_est id_seccion seccion*/   ///
				/*LOCATION*/ /*cod_dre nom_dre cod_ugel nom_ugel*/ codgeo dep  /*provincia distrito*/ urban ///
				/*Char school*/ public polidoc 			///
				/*Char Indiv*/ 	male spanish socioec_index socioec_index_cat			///
				/*Scores*/		score_com_std score_math_std score_acad_std /*score_soc_std score_sci_std*/ ///
				/*Scores RAW*/	/*score_com score_math*/ ///
				/*Family info*/ /*family_id sib_id oldest*/
			local all_vars = r(varlist)
			ds `all_vars', not
			keep `all_vars'
			order `all_vars'

			foreach v of local all_vars {
				capture confirm string variable `v'
					if _rc==0 {
						   replace `v' = trim(itrim(`v'))
					}
			}
			
			*Destring those not IDs
			ds id_estudiante id_ie, not
			local all_vars = r(varlist)
			destring `all_vars', replace
						
			
	compress
	
	if ${test}==0 {
		preserve 
			keep if grade==2 
			drop grade
			rename id_estudiante id_estudiante_2p 
			save "$TEMP\em_2p", replace
		restore
		
		preserve 
			keep if grade==4
			drop grade
			rename id_estudiante id_estudiante_4p 
			save "$TEMP\em_4p", replace
		restore
		
		preserve 
			keep if grade==6
			drop grade
			rename id_estudiante id_estudiante_6p
			save "$TEMP\em_6p", replace
		restore
		
		preserve 
			keep if grade==8
			drop grade
			rename id_estudiante id_estudiante_2s
			save "$TEMP\em_2s", replace
		restore
	}
			
	if ${test}==1 {
		preserve 
			keep if grade==2 
			drop grade
			rename id_estudiante id_estudiante_2p 
			save "$TEMP\em_2p_TEST", replace
		restore
		
		preserve 
			keep if grade==4
			drop grade
			rename id_estudiante id_estudiante_4p 
			save "$TEMP\em_4p_TEST", replace
		restore
		
		preserve 
			keep if grade==6
			drop grade
			rename id_estudiante id_estudiante_6p
			save "$TEMP\em_6p_TEST", replace
		restore
		
		preserve 
			keep if grade==8
			drop grade
			rename id_estudiante id_estudiante_2s
			save "$TEMP\em_2s_TEST", replace
		restore
	}
	
end


********************************************************************************
* ECE: National Examination 
********************************************************************************

capture program drop ece
program define ece

	if $excel == 1 {
		import delimited "$IN\MINEDU\Entrega-1\ECE EM innominada\Resultados_ECE_ConIDPersonaSIAGIE_innom.txt", clear stringcols(5) 
		compress
		
		*- We do some trivial cleaning before saving 'raw' to make it more light
		drop nombre_ie
		drop indpe_pos* id_per_pos* indpe_mat* id_per_mat
		
		*- Urban
		gen byte urban = 1 if area == "Urbana" 
		replace urban = 0 if area == "Rural"
		label var urban "Area: Urban"
		label values urban yes_no
		
		*- Public school
		gen byte public = 1 if gestion2=="Estatal" 
		replace public = 0 if gestion2=="No estatal" 
		label var public "School: Public"
		label values public public

		*- Polidocente Completo or unidocente/multigrado
		gen byte polidoc = 1 if caracteristica2 == "Polidocente completo"
		replace polidoc = 0 if caracteristica2=="Unidocente / Multigrado" 
		label var polidoc "School: Grades in separate classrooms (Polidocente completo)"
		label define polidoc 0 "Unidocente / Multigrado" 1 "Polidocente completo", replace
		label values polidoc polidoc

		*- Male
		gen byte male = . 
		replace male = 1 if sexo=="Hombre"
		replace male = 0 if sexo=="Mujer" 
		label var male "Sex: Male"
		label define male 0 "female" 1 "male", replace
		label values male male

		*- Mother Tongue is Spanish
		gen byte spanish = 1 if lengua_materna=="Castellano"
		replace spanish = 0 if lengua_materna != "Castellano" & lengua_materna!=""
		label var spanish "Mother Tongue: Spanish"
		label define spanish 0 "Other" 1 "Spanish", replace
		label values spanish spanish		
		
		save "$TEMP\ece_raw", replace
		gen u=runiform()
		keep if u<0.01
		save "$TEMP\ece_raw_TEST", replace
		
		use "$TEMP\ece_raw", clear
		}
		
	if ${test}==0 & ${excel} == 0 use "$TEMP\ece_raw", clear
	if ${test}==1 & ${excel} == 0 use "$TEMP\ece_raw_TEST", clear

	define_labels
	
	rename ańo year
	rename grado grade
	rename nivel level
	rename ise socioec_index //socio-economic-index

	*- Grade
	replace grade = "2" if grade == "2do" & level == "Primaria"
	replace grade = "4" if grade == "4to" & level == "Primaria" 
	replace grade = "8" if grade == "2do" & level == "Secundaria"
	destring grade, replace force
	
	*- UBIGEO
	tostring codgeo, replace
	replace codgeo = "0" + codgeo if strlen(codgeo)<6
	assert strlen(codgeo)==6
	//replace codgeo = "0" + codgeo if strlen(codgeo)<6
	drop departamento
	gen dep = substr(codgeo,1,2)
	destring dep, replace 
	label values dep dep

	*- Socio-Economic index
	destring socioec_index, replace force
	gen socioec_index_cat = .
	label define socioec_index_cat 1 "Very Low" 2 "Low" 3 "Medium" 4 "High", replace
	label values socioec_index_cat sec_cat
	replace socioec_index_cat = 1 if n_ise == "Muy bajo"
	replace socioec_index_cat = 2 if n_ise == "Bajo"
	replace socioec_index_cat = 3 if n_ise == "Medio"
	replace socioec_index_cat = 4 if n_ise == "Alto"

	*- Scores
	destring medida500_l medida500_m medida500_cs medida500_cn medida_l1 medida_l2 medida500_l1 medida500_l2, replace force

	forval y = 2007/2019 {
		foreach v of var medida_l1 medida_l2 medida500_l1 medida500_l2 {
			capture sum `v' if year == `y'
			if _rc==0 assert `r(N)'<25000 //Scores with few observations. Make sure also true in new versions	
		}
	}
	
	drop medida_l1 medida_l2 medida500_l1 medida500_l2
	
	rename (medida500_l medida500_m medida500_cs medida500_cn) (score_com score_math score_soc score_sci)
	
	VarStandardiz score_com, by(year grade) newvar(score_com_std)
	VarStandardiz score_math, by(year grade) newvar(score_math_std)
	VarStandardiz score_soc, by(year grade) newvar(score_soc_std)
	VarStandardiz score_sci, by(year grade) newvar(score_sci_std)
	
	*- Academic index
	egen score_acad = rmean(score_com_std score_math_std)
	VarStandardiz score_acad, by(year grade) newvar(score_acad_std)	
	
	*- ID school
	gen id_ie = cod_mod7 + string(anexo)
	
	*- Attach family ID
	/*
	preserve
		keep if grade == 2
		tostring cod_mod7, replace
		replace cod_mod7="0"+cod_mod7 if strlen(cod_mod7)<7
		replace cod_mod7="0"+cod_mod7 if strlen(cod_mod7)<7
		tostring anexo, replace
		gen id_ie_2p = cod_mod7 + anexo
		rename year year_2p
		rename seccion seccion_2p
		rename male male_2p
		keep if year_2p<=2013
		keep id_estudiante id_ie_2p year_2p seccion_2p male_2p score_com score_math
		*- Check if duplicates
		bys id_ie_2p seccion_2p year_2p male_2p score_com score_math: gen N_obs=_N
		tab N_obs	
		keep if N_obs==1
		merge 1:1 id_ie_2p seccion_2p year_2p male_2p score_math score_com  using "$TEMP/ece_siblings_info", keep(match) keepusing(family_id sib_id oldest)
		drop _merge
		tempfile ece_family_merge
		save `ece_family_merge', replace
	restore
	
	merge 1:1 id_estudiante using `ece_family_merge', keep(master match) keepusing(family_id sib_id oldest)
	*/
			isvar 			///
				/*Match ID*/ 	/*indpe_pos* id_per_pos* indpe_mat* id_per_mat**/ ///
				/*ID*/  		id_estudiante id_ie fuente year /*cod_mod7 anexo nombre_ie*/ level grade /*cor_est id_seccion seccion*/   ///
				/*LOCATION*/ /*cod_dre nom_dre cod_ugel nom_ugel*/ codgeo dep /*provincia distrito*/ urban ///
				/*Char school*/ public polidoc 			///
				/*Char Indiv*/ 	male spanish socioec_index socioec_index_cat			///
				/*Scores*/		score_com_std score_math_std score_acad_std /*score_soc_std score_sci_std*/ ///
				/*Scores RAW*/	/*score_com score_math*/ ///
				/*Family info*/ /*family_id sib_id oldest*/
			local all_vars = r(varlist)
			ds `all_vars', not
			keep `all_vars'
			order `all_vars'

			foreach v of local all_vars {
				capture confirm string variable `v'
					if _rc==0 {
						   replace `v' = trim(itrim(`v'))
					}
			}
			
			*Destring those not IDs
			ds id_estudiante id_ie, not
			local all_vars = r(varlist)
			destring `all_vars', replace
						
			compress	
	
	if ${test}==0 {
		preserve 
			keep if grade==2 
			drop grade
			rename id_estudiante id_estudiante_2p 
			save "$TEMP\ece_2p", replace
		restore
		
		preserve 
			keep if grade==4
			drop grade
			rename id_estudiante id_estudiante_4p 
			save "$TEMP\ece_4p", replace
		restore
		
		preserve 
			keep if grade==8
			drop grade
			rename id_estudiante id_estudiante_2s
			save "$TEMP\ece_2s", replace
		restore
	}
			
	if ${test}==1 {
		preserve 
			keep if grade==2 
			drop grade
			rename id_estudiante id_estudiante_2p 
			save "$TEMP\ece_2p_TEST", replace
		restore
		
		preserve 
			keep if grade==4
			drop grade
			rename id_estudiante id_estudiante_4p 
			save "$TEMP\ece_4p_TEST", replace
		restore
		
		preserve 
			keep if grade==8
			drop grade
			rename id_estudiante id_estudiante_2s
			save "$TEMP\ece_2s_TEST", replace
		restore
	}

end


********************************************************************************
* ECE Survey
********************************************************************************
	
capture program drop ece_survey 
program define ece_survey 	

*- Family 2P

	if fileexists("$TEMP\ece_family_2015_2p.dta") & ${excel}!=1 use  "$TEMP\ece_family_2015_2p", clear
	else {
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\ECE 2015\2do primaria\ECE 2P 2015 Cuestionario Familia.xlsx"				, sheet("Base de datos") firstrow allstring clear
		local year = 2015
		local grade = "2p"
		local source = 1 //ECE
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		
		*- Recode id student to make compatible with other databases
		/*
		gen id_part1 = substr(id,8,8)
		gen id_part2 = substr(id,16,2)
		gen id_part3 = substr(id,18,2)
		
		replace id_part2 = subinstr(id_part2,"01","A",.)
		replace id_part2 = subinstr(id_part2,"02","B",.)
		replace id_part2 = subinstr(id_part2,"03","C",.)
		replace id_part2 = subinstr(id_part2,"04","D",.)
		replace id_part2 = subinstr(id_part2,"05","E",.)
		replace id_part2 = subinstr(id_part2,"06","F",.)
		replace id_part2 = subinstr(id_part2,"07","G",.)
		replace id_part2 = subinstr(id_part2,"08","H",.)
		replace id_part2 = subinstr(id_part2,"09","I",.)
		replace id_part2 = subinstr(id_part2,"10","J",.)
		replace id_part2 = subinstr(id_part2,"11","K",.)
		replace id_part2 = subinstr(id_part2,"12","L",.)
		replace id_part2 = subinstr(id_part2,"13","M",.)
		replace id_part2 = subinstr(id_part2,"14","N",.)
		replace id_part2 = subinstr(id_part2,"15","O",.)
		replace id_part2 = subinstr(id_part2,"16","P",.)
		replace id_part2 = subinstr(id_part2,"17","Q",.)
		replace id_part2 = subinstr(id_part2,"18","R",.)
		replace id_part2 = subinstr(id_part2,"19","S",.)
		replace id_part2 = subinstr(id_part2,"20","T",.)
		replace id_part2 = subinstr(id_part2,"21","U",.)
		replace id_part2 = subinstr(id_part2,"22","V",.)
		replace id_part2 = subinstr(id_part2,"23","W",.)
		replace id_part2 = subinstr(id_part2,"24","X",.)
		replace id_part2 = subinstr(id_part2,"25","Y",.)
		replace id_part2 = subinstr(id_part2,"26","Z",.)
		replace id_part2 = subinstr(id_part2,"27","0",.)
		replace id_part2 = subinstr(id_part2,"28","1",.)
		
		replace id = substr(id,1,7) + id_part1 + id_part2 + id_part3	
		*/
		
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename pfp41 aspiration
		rename pfp23_01 radio
		rename pfp23_09 phone_internet
		rename pfp23_10 internet
		rename pfp23_11 pc
		rename pfp23_12 laptop
		
		rename pfp03 lengua_materna_mother
		rename pfp05 edu_mother
		
		rename pfp32_1 freq_activities_1
		rename pfp32_2 freq_activities_2
		rename pfp32_3 freq_activities_3
		rename pfp32_4 freq_activities_4

		gen id_ie = cod_mod7 + anexo
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile ece_family_`year'_`grade'
		save `ece_family_`year'_`grade'', replace
		save "$TEMP\ece_family_`year'_2p", replace
	}

	if fileexists("$TEMP\ece_family_2016_2p.dta") & ${excel}!=1  use  "$TEMP\ece_family_2016_2p", clear
	else {
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\ECE 2016\2do y 4to de primaria\ECE 2P 2016 Cuestionario Familia.xlsx"		, sheet("Base de datos") firstrow allstring clear
		local year = 2016
		local grade = "2p"
		local source = 1 //ECE
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename pa_36 aspiration
		rename pa_19_01 radio
		rename pa_19_19 phone_internet
		rename pa_19_20 internet
		rename pa_19_07 pc
		rename pa_19_08 laptop
		
		rename pa_04 lengua_materna_mother
		rename pa_06 edu_mother
		rename pa_27_01 gender_subj_1
		rename pa_27_02 gender_subj_2
		rename pa_27_03 gender_subj_3
		rename pa_27_04 gender_subj_4
		
		rename pa_28_01 importance_success_m_1
		rename pa_28_02 importance_success_m_2
		rename pa_28_03 importance_success_m_3
		rename pa_28_04 importance_success_m_4
		rename pa_28_05 importance_success_m_5
		rename pa_28_06 importance_success_m_6

		rename pa_29_01 importance_success_c_1
		rename pa_29_02 importance_success_c_2
		rename pa_29_03 importance_success_c_3
		rename pa_29_04 importance_success_c_4
		rename pa_29_05 importance_success_c_5
		rename pa_29_06 importance_success_c_6
		
		rename pa_30 current_m
		rename pa_31 future_m
		rename pa_32 past_m
		rename pa_33 current_c
		rename pa_34 future_c
		rename pa_35 past_c

		gen id_ie = cod_mod7 + anexo
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile ece_family_`year'_`grade'
		save `ece_family_`year'_`grade'', replace
		save "$TEMP\ece_family_`year'_2p", replace
	}


	if fileexists("$TEMP\em_family_2019_2p.dta") & ${excel}!=1  use  "$TEMP\em_family_2019_2p", clear
	else {
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\EM 2019\2do primaria\EM 2P 2019 Cuestionario Familia.xlsx"					, sheet("Base de datos") firstrow allstring clear
		local year = 2019
		local grade = "2p"
		local source = 2 //EM
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename p17 aspiration
		rename p11_01 radio
		rename p11_17 phone_internet
		rename p11_18 internet
		rename p11_07 pc
		rename p11_08 laptop

		gen id_ie = cod_mod7 + anexo
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		recode radio phone_internet internet pc laptop (2=0)
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile em_family_`year'_`grade'
		save `em_family_`year'_`grade'', replace
		save "$TEMP\em_family_`year'_2p", replace
	}

	if fileexists("$TEMP\em_family_2022_2p.dta") & ${excel}!=1  use  "$TEMP\em_family_2022_2p", clear
	else {
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\EM 2022\2do grado de primaria\EM 2P 2022 Cuestionario al padre Familia.xlsx"	, sheet("base") firstrow allstring clear
		local year = 2022
		local grade = "2p"
		local source = 2 //EM
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename p14 aspiration
		rename p11_01 radio
		rename p11_19 phone_internet
		rename p11_20 internet
		rename p11_06 pc
		rename p11_07 laptop

		gen id_ie = cod_mod7 + anexo
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		recode radio phone_internet internet pc laptop (2=0)
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile em_family_`year'_`grade'
		save `em_family_`year'_`grade'', replace
		save "$TEMP\em_family_`year'_2p", replace
	}	

	if fileexists("$TEMP\em_family_2023_2p.dta") & ${excel}!=1  use  "$TEMP\em_family_2023_2p", clear
	else {
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\EM 2023\EM 2P 2023\ENLA2023_2Pfamilia_Nacional.xlsx"						, sheet("base") firstrow allstring clear
		local year = 2023
		local grade = "2p"
		local source = 2 //EM
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename p16 aspiration
		//rename p11_01 radio
		rename p10_07 phone_internet
		rename p11_09 internet
		rename p10_05 pc
		rename p10_06 laptop

		gen id_ie = substr( id,8,8)
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		recode phone_internet internet pc laptop (2=0)
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile em_family_`year'_`grade'
		save `em_family_`year'_`grade'', replace
		save "$TEMP\em_family_`year'_2p", replace	
	}
	
	clear
	append using "$TEMP\ece_family_2015_2p"
	append using "$TEMP\ece_family_2016_2p"
	append using "$TEMP\em_family_2019_2p"
	append using "$TEMP\em_family_2022_2p"
	append using "$TEMP\em_family_2023_2p"
	
	bys id_estudiante_2p: drop if _N>1 //a few duplicates
	compress
	
	save "$TEMP\ece_family_2p", replace

	/*
	capture erase  "$TEMP\ece_family_2015_2p.dta"
	capture erase  "$TEMP\ece_family_2016_2p.dta"
	capture erase  "$TEMP\em_family_2019_2p.dta"
	capture erase  "$TEMP\em_family_2022_2p.dta"
	capture erase  "$TEMP\em_family_2023_2p.dta"
	*/
	
*- Family 4P

	if fileexists("$TEMP\ece_family_2016_4p.dta") & ${excel}!=1  use  "$TEMP\ece_family_2016_4p", clear
	else {
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\ECE 2016\2do y 4to de primaria\ECE 4P 2016 Cuestionario Familia.xlsx"			, sheet("Base de datos") firstrow allstring clear
		local year = 2016
		local grade = "4p"
		local source = 1 //ECE
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		foreach v of var pa* {
			replace `v' = "" if `v' == "#NULL!"
		}
		
		rename pa_29 aspiration
		rename pa_19_01 radio
		rename pa_19_19 phone_internet
		rename pa_19_20 internet
		rename pa_19_07 pc
		rename pa_19_08 laptop

		gen id_ie = cod_mod7 + anexo
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile ece_family_`year'_`grade'
		save `ece_family_`year'_`grade'', replace
		save "$TEMP\ece_family_`year'_4p", replace
	}

	if fileexists("$TEMP\ece_family_2018_4p.dta") & ${excel}!=1  use  "$TEMP\ece_family_2018_4p", clear
	else {
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\ECE 2018\4to primaria\ECE 4P 2018 Cuestionario Familia.xlsx"				, sheet("Base de datos") firstrow allstring clear
		local year = 2018
		local grade = "4p"
		local source = 1 //ECE
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename p27 aspiration
		rename p09_01 radio
		rename p09_19 phone_internet
		rename p09_20 internet
		rename p09_07 pc
		rename p09_08 laptop
		
		rename p15 lengua_materna_mother
		rename p17 edu_mother
		rename p25_01 gender_subj_1
		rename p25_02 gender_subj_2
		rename p25_03 gender_subj_3
		rename p25_04 gender_subj_4
		rename p25_05 gender_subj_5
		rename p25_06 gender_subj_6
		rename p21_01 satisfied_opportunities_1
		rename p21_02 satisfied_opportunities_2
		rename p21_03 satisfied_opportunities_3
		rename p21_04 satisfied_opportunities_4
		rename p21_05 satisfied_opportunities_5
		rename p21_06 satisfied_opportunities_6
		rename p21_07 satisfied_opportunities_7
		rename p26_01 importance_success_1
		rename p26_02 importance_success_2
		rename p26_03 importance_success_3
		rename p26_04 importance_success_4
		rename p26_05 importance_success_5
		rename p32_01 asked_activities_1
		rename p32_02 asked_activities_2
		rename p32_03 asked_activities_3
		rename p32_04 asked_activities_4
		rename p32_05 asked_activities_5
		
		label var gender_subj_1 "Boys do better than girls in Mathematics"
		label var gender_subj_2 "Girls do better than boys in Communication"
		label var gender_subj_3 "Boys have an easier time with Mathematics than girls"
		label var gender_subj_4 "Girls have an easier time reading than boys"
		label var gender_subj_5 "Boys understand more about numbers because it is innate in them"
		label var gender_subj_6 "Girls understand more about reading because it's more natural to be more communicative"
		
		gen id_ie = cod_mod7 + anexo
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		recode radio phone_internet internet pc laptop (2=0)
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile ece_family_`year'_`grade'
		save `ece_family_`year'_`grade'', replace
		save "$TEMP\ece_family_`year'_4p", replace
	}

	if fileexists("$TEMP\em_family_2019_4p.dta") & ${excel}!=1  use  "$TEMP\em_family_2019_4p", clear
	else {
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\EM 2019\4to primaria\EM 4P 2019 Cuestionario Familia.xlsx"					, sheet("Base de datos") firstrow allstring clear
		local year = 2019
		local grade = "4p"
		local source = 2 //EM
		
		rename *, lower
		//rename id_estudiante id
		rename cod_modular cod_mod7
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename p17 aspiration
		rename p11_01 radio
		rename p11_17 phone_internet
		rename p11_18 internet
		rename p11_07 pc
		rename p11_08 laptop

		gen id_ie = cod_mod7 + anexo
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		recode radio phone_internet internet pc laptop (2=0)
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile em_family_`year'_`grade'
		save `em_family_`year'_`grade'', replace
		save "$TEMP\em_family_`year'_4p", replace	
	}
	
	if fileexists("$TEMP\em_family_2022_4p.dta") & ${excel}!=1 use  "$TEMP\em_family_2022_4p", clear
	else {
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\EM 2022\4to grado de primaria\EM 4P 2022 Cuestionario al padre familia.xlsx"	, sheet("base") firstrow allstring clear
		local year = 2022
		local grade = "4p"
		local source = 2 //EM
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename p14 aspiration
		rename p11_01 radio
		rename p11_19 phone_internet
		rename p11_20 internet
		rename p11_06 pc
		rename p11_07 laptop

		gen id_ie = cod_mod7 + anexo
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		recode radio phone_internet internet pc laptop (2=0)
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile em_family_`year'_`grade'
		save `em_family_`year'_`grade'', replace
		save "$TEMP\em_family_`year'_4p", replace		
	}
	
	if fileexists("$TEMP\em_family_2023_4p.dta") & ${excel}!=1  use  "$TEMP\em_family_2023_4p", clear
	else { 
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\EM 2023\EM 4P 2023\ENLA2023_4Pfamilia_EBR.xlsx"								, sheet("base") firstrow allstring clear
		local year = 2023
		local grade = "4p"
		local source = 2 //EM
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename p16 aspiration
		//rename p11_01 radio
		rename p10_07 phone_internet
		rename p11_09 internet
		rename p10_05 pc
		rename p10_06 laptop
		

		gen id_ie = substr(id,8,8)
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		recode phone_internet internet pc laptop (2=0)
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile em_family_`year'_`grade'
		save `em_family_`year'_`grade'', replace
		save "$TEMP\em_family_`year'_4p", replace
	}
	
	clear
	append using "$TEMP\ece_family_2016_4p"
	append using "$TEMP\ece_family_2018_4p"
	append using "$TEMP\em_family_2019_4p"
	append using "$TEMP\em_family_2022_4p"
	append using "$TEMP\em_family_2023_4p"
	
	bys id_estudiante_4p: drop if _N>1 //a few duplicates
	compress
	
	save "$TEMP\ece_family_4p", replace

	/*
	capture erase  "$TEMP\ece_family_2016_4p.dta"
	capture erase  "$TEMP\ece_family_2018_4p.dta"
	capture erase  "$TEMP\em_family_2019_4p.dta"
	capture erase  "$TEMP\em_family_2022_4p.dta"
	capture erase  "$TEMP\em_family_2023_4p.dta"	
	*/
	
*- Student 2S
	
	if fileexists("$TEMP\ece_family_2015_2s.dta") & ${excel}!=1  use  "$TEMP\ece_family_2015_2s", clear
	else {
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\ECE 2015\2do secundaria\ECE 2S 2015 Cuestionario Estudiante.xlsx"								, sheet("Base de datos") firstrow allstring clear
		local year = 2015
		local grade = "2s"
		local source = 1 //ECE
		
		rename *, lower
		//rename id_estudiante id
		
		//replace id = substr(id,8,12)

		*- Recode id student to make compatible with other databases
		/*
		gen id_part1 = substr(id,1,8)
		gen id_part2 = substr(id,9,2)
		gen id_part3 = substr(id,11,2)
		
		replace id_part2 = subinstr(id_part2,"01","A",.)
		replace id_part2 = subinstr(id_part2,"02","B",.)
		replace id_part2 = subinstr(id_part2,"03","C",.)
		replace id_part2 = subinstr(id_part2,"04","D",.)
		replace id_part2 = subinstr(id_part2,"05","E",.)
		replace id_part2 = subinstr(id_part2,"06","F",.)
		replace id_part2 = subinstr(id_part2,"07","G",.)
		replace id_part2 = subinstr(id_part2,"08","H",.)
		replace id_part2 = subinstr(id_part2,"09","I",.)
		replace id_part2 = subinstr(id_part2,"10","J",.)
		replace id_part2 = subinstr(id_part2,"11","K",.)
		replace id_part2 = subinstr(id_part2,"12","L",.)
		replace id_part2 = subinstr(id_part2,"13","M",.)
		replace id_part2 = subinstr(id_part2,"14","N",.)
		replace id_part2 = subinstr(id_part2,"15","O",.)
		replace id_part2 = subinstr(id_part2,"16","P",.)
		replace id_part2 = subinstr(id_part2,"17","Q",.)
		replace id_part2 = subinstr(id_part2,"18","R",.)
		replace id_part2 = subinstr(id_part2,"19","S",.)
		replace id_part2 = subinstr(id_part2,"20","T",.)
		replace id_part2 = subinstr(id_part2,"21","U",.)
		replace id_part2 = subinstr(id_part2,"22","V",.)
		replace id_part2 = subinstr(id_part2,"23","W",.)
		replace id_part2 = subinstr(id_part2,"24","X",.)
		replace id_part2 = subinstr(id_part2,"25","Y",.)
		replace id_part2 = subinstr(id_part2,"26","Z",.)
		replace id_part2 = subinstr(id_part2,"27","0",.)
		replace id_part2 = subinstr(id_part2,"28","1",.)
		
		replace id = id_part1 + id_part2 + id_part3
		*/

		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename esp06_1 lives_with_mom
		rename esp06_2 lives_with_dad
		label var lives_with_mom "Lives with mom or caretaker"
		label var lives_with_dad "Lives with dad or caretaker"
		
		rename esp07 total_siblings
		replace total_siblings = "99" if total_siblings == ""
		
		rename esp31 aspiration
		rename esp17_01 radio
		rename esp17_09 phone_internet
		rename esp17_10 internet
		rename esp17_11 pc
		rename esp17_12 laptop

		gen id_ie = cod_mod7 + anexo
		gen year = `year'
		gen source = `source'
		
		ds id* year* source , not
		destring `r(varlist)', replace
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Household*/			lives_with_* total_siblings ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile ece_student_`year'_`grade'
		save `ece_student_`year'_`grade'', replace
		save "$TEMP\ece_student_`year'_2s", replace
	}
		
	if fileexists("$TEMP\ece_family_2016_2s.dta") & ${excel}!=1  use  "$TEMP\ece_family_2016_2s", clear
	else {
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\ECE 2016\2do secundaria\ECE 2S 2016 Cuestionario Estudiante Forma1.xlsx"						, sheet("Base de datos") firstrow allstring clear
		//503,767
		rename *, lower
		tempfile ece_2s_2016_f1
		save `ece_2s_2016_f1', replace
		
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\ECE 2016\2do secundaria\ECE 2S 2016 Cuestionario Estudiante Forma2.xlsx"						, sheet("Base de datos") firstrow allstring clear
		//201,535
		rename *, lower
		bys id_estudiante: drop if _N>1 // few duplicate observations, 772, <0.5%
		tempfile ece_2s_2016_f2
		save `ece_2s_2016_f2', replace
		
		use `ece_2s_2016_f1', clear
		merge 1:1 id_estudiante using `ece_2s_2016_f2', keep(master using match) //
		drop _m
		
		local year = 2016
		local grade = "2s"
		local source = 1 //ECE
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename e1_23 aspiration
		rename e1_13_01 radio
		rename e1_13_19 phone_internet
		rename e1_13_20 internet
		rename e1_13_07 pc
		rename e1_13_08 laptop

		gen id_ie = cod_mod7 + anexo
		gen year = `year'
		gen source = `source'
		
		ds id* year* source , not
		destring `r(varlist)', replace
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Household*/			lives_with_* total_siblings ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile ece_student_`year'_`grade'
		save `ece_student_`year'_`grade'', replace	
		save "$TEMP\ece_student_`year'_2s", replace
	}
	
	**# THERE IS AN EM FOR WRITING THIS YEAR
	if fileexists("$TEMP\ece_family_2018_2s.dta") & ${excel}!=1  use  "$TEMP\ece_family_2018_2s", clear
	else {	
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\ECE 2018\2do secundaria\ECE 2S 2018 Cuestionario Estudiante F1.xlsx"							, sheet("Base de datos") firstrow allstring clear
		local year = 2018
		local grade = "2s"
		local source = 1 //ECE
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename p23 aspiration
		rename p12_01 radio
		rename p12_19 phone_internet
		rename p12_20 internet
		rename p12_07 pc
		rename p12_08 laptop

		gen id_ie = cod_mod7 + anexo
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		recode radio phone_internet internet pc laptop (2=0)
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Household*/			lives_with_* total_siblings ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile ece_student_`year'_`grade'
		save `ece_student_`year'_`grade'', replace	
		save "$TEMP\ece_student_`year'_2s", replace
	}
	
	
	if fileexists("$TEMP\ece_family_2019_2s.dta") & ${excel}!=1  use  "$TEMP\ece_family_2019_2s", clear
	else {	
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\ECE 2019\ECE 2S 2019 Cuestionario Estudiante.xlsx"								, sheet("Base de datos") firstrow allstring clear
		local year = 2019
		local grade = "2s"
		local source = 1 //ECE
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename p05 aspiration
		rename p14_01 radio
		rename p14_19 phone_internet
		rename p14_20 internet
		rename p14_07 pc
		rename p14_08 laptop

		gen id_ie = cod_mod7 + anexo
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		recode radio phone_internet internet pc laptop (2=0)
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Household*/			lives_with_* total_siblings ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile ece_student_`year'_`grade'
		save `ece_student_`year'_`grade'', replace	
		save "$TEMP\ece_student_`year'_2s", replace
	}
	
	if fileexists("$TEMP\em_family_2022_2s.dta") & ${excel}!=1  use  "$TEMP\em_family_2022_2s", clear
	else {		
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\EM 2022\2do grado de secundaria\EM 2S 2022 Cuestionario al Estudiante FFAA - Forma 1 - Día 1.xlsx", sheet("base") firstrow allstring clear
		//
		rename *, lower
		tempfile em_2s_2022_d1
		save `em_2s_2022_d1', replace
		count
		
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\EM 2022\2do grado de secundaria\EM 2S 2022 Cuestionario al Estudiante FFAA - Forma 1 - Día 2.xlsx", sheet("base") firstrow allstring clear
		//
		rename *, lower
		rename p* q* //since numbering in D1 overlaps with D2	
		drop if id_estudiante==""
		tempfile em_2s_2022_d2
		save `em_2s_2022_d2', replace	
		count
		
		use `em_2s_2022_d1', clear
		merge 1:1 id_estudiante using `em_2s_2022_d2', keep(master using match) //
		drop _m	
		
		local year = 2022
		local grade = "2s"
		local source = 2 //EM
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		//rename p05 aspiration
		rename p14_01 radio
		rename p14_19 phone_internet
		rename p14_20 internet
		rename p14_06 pc
		rename p14_07 laptop
		
		rename q03 abs_last_m //absenteism
	

		gen id_ie = cod_mod7 + anexo
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		recode radio phone_internet internet pc laptop (2=0)
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Household*/			lives_with_* total_siblings ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Outcomes*/ 			abs_last_m abs_last_y abs_last_y2 ///
				/*Parents*/				lengua_materna_mother edu_mother ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile em_student_`year'_`grade'
		save `em_student_`year'_`grade'', replace	
		save "$TEMP\em_student_`year'_2s", replace
	}
	
	
	if fileexists("$TEMP\em_family_2023_2s.dta") & ${excel}!=1  use  "$TEMP\em_family_2023_2s", clear
	else {		
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\EM 2023\EM 2S 2023\ENLA2023_2Sestudiante_EBRD2.xlsx"											, sheet("base") firstrow allstring clear
		//
		rename *, lower
		tempfile em_2s_2023_d2
		save `em_2s_2023_d2', replace
		
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\EM 2023\EM 2S 2023\ENLA2023_2Sestudiante_EBRD3.xlsx"											, sheet("base") firstrow allstring clear
		//
		rename *, lower
		rename p* q* //since numbering in D3 overlaps with D2	
		bys id_estudiante: drop if _N>1  // 4 duplicate observations
		tempfile em_2s_2023_d3
		save `em_2s_2023_d3', replace	
		
		use `em_2s_2023_d2', clear
		merge 1:1 id_estudiante using `em_2s_2023_d3', keep(master using match) //
		drop _m	
		
		local year = 2023
		local grade = "2s"
		local source = 2 //EM
		
		rename *, lower
		//rename id_estudiante id
		//replace id = substr(id,8,12)
		drop if id_estudiante=="" | id_estudiante=="0" | id_estudiante=="#NULL!"
		rename p06 aspiration
		//rename p14_01 radio
		rename p15_07 phone_internet
		rename p16_09 internet
		rename p15_05 pc
		rename p15_06 laptop
		
		rename p04 abs_last_m //absenteism
		rename p05_01 abs_last_y  
		rename p05_02 abs_last_y2

		gen id_ie = substr(id,8,8)
		gen year = `year'
		gen source = `source' 
		
		ds id* year* source , not
		destring `r(varlist)', replace
		recode phone_internet internet pc laptop (2=0)
		
		isvar 	/*ID*/ 					id* year* source ///
				/*Household*/			lives_with_* total_siblings ///
				/*Access*/ 				radio internet pc laptop phone* plan_data*  ///
				/*Parents*/				lengua_materna_mother edu_mother /// 
				/*Outcomes*/ 			abs_last_m abs_last_y abs_last_y2 ///
				/*aspiration/beliefs*/	aspiration gender_subj* satisfied_opportunities* importance_success* asked_activities* freq_activities* current* future* past* ///
				/*child labor*/			child_labor
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'
		compress	

		rename * *_`grade'

		tempfile em_student_`year'_`grade'
		save `em_student_`year'_`grade'', replace	
		save "$TEMP\em_student_`year'_2s", replace
	}
	
	clear
	append using "$TEMP\ece_student_2015_2s"
	append using  "$TEMP\ece_student_2016_2s"
	append using  "$TEMP\ece_student_2018_2s"
	append using  "$TEMP\ece_student_2019_2s"
	append using  "$TEMP\em_student_2022_2s"
	append using  "$TEMP\em_student_2023_2s"
	
	bys id_estudiante_2s: drop if _N>1 //a few duplicates
	compress
	
	save "$TEMP\ece_student_2s", replace
	
	
	
	/*
	capture erase  "$TEMP\ece_student_2015_2s.dta"
	capture erase  "$TEMP\ece_student_2016_2s.dta"
	capture erase  "$TEMP\ece_student_2018_2s.dta"
	capture erase  "$TEMP\ece_student_2019_2s.dta"
	capture erase  "$TEMP\em_student_2022_2s.dta"
	capture erase  "$TEMP\em_student_2023_2s.dta"	
	*/	
	
end


********************************************************************************
* Family ID: identify siblings from SIAGIE data
********************************************************************************

capture program drop sibling_id
program define sibling_id

foreach y in "2014" "2015" "2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
		if ${test}==0 use id_* year grade dob_* educ_* level using "$TEMP\siagie_`y'", clear
		if ${test}==1 use id_* year grade dob_* educ_* level using "$TEMP\siagie_`y'_TEST", clear
		tempfile id_`y'
		save `id_`y'', replace
	}
		
	clear 
	append using `id_2014'
	append using `id_2015'
	append using `id_2016'
	append using `id_2017'
	append using `id_2018'
	append using `id_2019'
	append using `id_2020'
	append using `id_2021'
	append using `id_2022'
	append using `id_2023'
	
	*- Remove all pre-elementary observations
	drop if level==1	
	drop level
	
	*- Review same individual across years
	sort id_per_umc year
	duplicates tag id_per_umc, gen(dup)
	list if dup>0 & _n<100, sepby(id_per_umc)
	
	*- Get one ID per adult per individual (first one that is non missing)
	foreach adult in "caretaker" "mother" "father" {
		gen aux_id_`adult' = id_`adult'
		gen no_`adult' = (id_`adult' == "")
		bys id_per_umc (no_`adult' year dob_`adult'): replace id_`adult' = id_`adult'[1]
		drop no_`adult'
		drop aux*
		}
		
	*- We assign the maximum education level for each student-adult 
	**# It could also be the one that matches the chosen ID? Shouldn't make a lot of a difference.
	foreach adult in "caretaker" "mother" "father" {
		rename educ_`adult' aux_educ_`adult'
		bys id_per_umc: egen educ_`adult' = max(aux_educ_`adult')
		drop aux_educ_`adult'
		}	

	*- ID Family	
	*-- Group 1: By caretaker ID
	egen double id_fam_1 = group(id_caretaker)
	replace id_fam_1 = -_n if id_fam_1==.
	//egen id_fam_1_check = group(id_caretaker dob_caretaker)
	//replace id_fam_1 = . if id_caretaker==""
	sort id_fam_1 
	bys id_fam_1 : gen N_siblings_1=_N if id_fam_1!=.
	
	*-- Group 2: By Mother ID
	egen double id_fam_2 = group(id_mother)
	replace id_fam_2 = -_n if id_fam_2==.
	//replace id_fam_2 = . if id_mother==""
	sort id_fam_2 
	bys id_fam_2 : gen N_siblings_2=_N if id_fam_2!=.	
	
	*- Group 3: Best ID (mother>father>caretaker)
	gen id_adult = id_mother
	replace id_adult = id_father if id_adult==""
	replace id_adult = id_caretaker if id_adult==""
	egen double id_fam_3 = group(id_adult)
	replace id_fam_3 = -_n if id_fam_3==.
	//replace id_fam_3 = . if id_adult==""
	sort id_fam_3 
	bys id_fam_3 : gen N_siblings_3=_N if id_fam_3!=.	
	tab N_siblings_3
	
	*- Group 4: father and mother (or mother/father if only one)
	egen double id_fam_4 = group(id_mother id_father), missing
	replace id_fam_4 = -_n if id_mother=="" & id_father==""  //If there is only one, we do keep it.
	//replace id_fam_4 = . if id_mother=="" & id_father==""
	sort id_fam_4 
	bys id_fam_4 : gen N_siblings_4=_N if id_fam_4!=.	
	tab N_siblings_4	
	
	*- Group 4: father and mother (or mother/father if only one)
	egen double id_fam_5 = group(id_caretaker id_mother id_father), missing
	replace id_fam_5 = -_n if id_mother=="" & id_father=="" & id_caretaker!=""  //If there is only one, we do keep it.
	//replace id_fam_4 = . if id_mother=="" & id_father==""
	sort id_fam_5
	bys id_fam_5 : gen N_siblings_5=_N if id_fam_5!=.	
	tab N_siblings_5	
	
	*- Save information per student
	bys id_per_umc (year grade): keep if _n==1
	
	*- In absence of DOB we rank them based on starting year
	gen year_start = year-grade
	bys id_fam_1 (year_start): gen fam_order_1 = _n if id_fam_1!=.
	bys id_fam_2 (year_start): gen fam_order_2 = _n if id_fam_2!=.
	bys id_fam_3 (year_start): gen fam_order_3 = _n if id_fam_3!=.
	bys id_fam_4 (year_start): gen fam_order_4 = _n if id_fam_4!=.
	bys id_fam_5 (year_start): gen fam_order_5 = _n if id_fam_5!=.

	bys id_fam_1 (year_start): gen fam_total_1 = _N if id_fam_1!=.
	bys id_fam_2 (year_start): gen fam_total_2 = _N if id_fam_2!=.
	bys id_fam_3 (year_start): gen fam_total_3 = _N if id_fam_3!=.
	bys id_fam_4 (year_start): gen fam_total_4 = _N if id_fam_4!=.
	bys id_fam_5 (year_start): gen fam_total_5 = _N if id_fam_5!=.
	
	capture label define educ 1 "None" 2 "Primary Incomplete" 3 "Primary Complete" 4 "Secondary Incomplete" 5 "Secondary Complete" 6 "Higher Incomplete" 7 "Higher Complete" 8 "Post-grad", replace
	label values educ_caretaker educ_mother educ_father educ
	
	keep id_per_umc id_fam_* fam_order_* fam_total_* educ_* id_father id_mother id_caretaker
	order id_per_umc id_fam_* fam_order_* fam_total_* educ_* id_father id_mother id_caretaker
	compress

	save "$TEMP\id_siblings_review", replace
	
	keep id_per_umc id_fam_* fam_order_* fam_total_* educ_*
	order id_per_umc id_fam_* fam_order_* fam_total_* educ_*
	bys id_per_umc: keep if _n==1
	
	label var id_fam_1 "Family ID (Caretaker)"
	label var fam_order_1 "Sibling #order (caretaker)"
	label var fam_total_1 "Total siblings (caretaker)"
	label var id_fam_2 "Family ID (mother)"
	label var fam_order_2 "Sibling #order (mother)"
	label var fam_total_2 "Total siblings (mother)"
	label var id_fam_3 "Family ID (adult)"
	label var fam_order_3 "Sibling #order (adult)"
	label var fam_total_3 "Total siblings (adult)"
	label var id_fam_4 "Family ID (father & mother)"
	label var fam_order_4 "Sibling #order (father & mother)"
	label var fam_total_4 "Total siblings (father & mother)"
	label var id_fam_5 "Family ID (father & mother & caretaker)"
	label var fam_order_5 "Sibling #order (father & mother & caretaker)"
	label var fam_total_5 "Total siblings (father & mother & caretaker)"
	
	destring id_per_umc, replace
	
	compress
	
	if ${test}==1 save "$TEMP\id_siblings_TEST", replace
	if ${test}==0 save "$TEMP\id_siblings", replace

end


********************************************************************************
* Family ID: identify siblings from SIAGIE data
********************************************************************************

capture program drop review_sibling_id
program define review_sibling_id

	use "$TEMP\id_siblings_review", clear

	tab fam_total_5

	br id_fam_5 fam_total_5 fam_order_5 id_father id_mother id_caretaker if fam_total_5==138


	erase "$TEMP\id_siblings_review.dta"

end


********************************************************************************
* University database
********************************************************************************

capture program drop db_universities
program define db_universities

	import delimited "$IN\MINEDU\ECE EM innominada\SIRIES\postulantes_INNOM.txt", clear
	keep codigo_modular universidad id_tipo_institucion id_tipo_gestion
	bys codigo_modular universidad: keep if _n==1
	tempfile app_universities
	save `app_universities', replace

	import delimited "$IN\MINEDU\ECE EM innominada\SIRIES\matriculados_INNOM.txt", clear
	keep codigo_modular universidad id_tipo_institucion id_tipo_gestion
	bys codigo_modular universidad: keep if _n==1
	tempfile enr_universities
	save `enr_universities', replace

	define_labels
	
	/*
	INCLUDE EGRESADOS ####
	*/

	append using `app_universities'

	bys codigo_modular universidad: keep if _n==1

	duplicates tag codigo_modular universidad, gen(dup1)
	duplicates tag codigo_modular , gen(dup2)
	duplicates tag universidad, gen(dup3)
	assert (dup1==dup2 & dup2==dup3)
	
	sort codigo_modular id_tipo_institucion id_tipo_gestion universidad
	
	label values codigo_modular universidad_cod

	save "$OUT\universities", replace

end

********************************************************************************
* Applicants
********************************************************************************


capture program drop applied
program define applied

	
	if ${excel} == 1 & ${test}==0 & ${new}==0 {
		import delimited "$IN\MINEDU\ECE EM innominada\SIRIES\postulantes_INNOM.txt", clear
		compress
	}	
	
	if ${excel} == 1 & ${test}==1 & ${new}==0 {
		import delimited "$IN\MINEDU\ECE EM innominada\SIRIES\postulantes_INNOM.txt", clear
		gen u=runiform()
		keep if u<0.01
		drop u
		compress		
		save "$TEMP\applied_raw_TEST", replace
	}
	
	if ${excel} == 1 & ${test}==0 & ${new}==1 {
		/*
		import delimited "$IN\MINEDU\ECE EM innominada\SIRIES\postulantes_INNOM.txt", clear
		keep id_persona_rec periodo_postulacion id_periodo_postulacion
		bys id_persona_rec periodo_postulacion (id_periodo_postulacion): gen mark = id_periodo_postulacion[1] == id_periodo_postulacion[_N]
		assert mark==1 //Check there is no variation at the identified level.
		bys id_persona_rec periodo_postulacion: keep if _n==1
		drop mark
		tempfile previous_id_periodo_postulacion
		save `previous_id_periodo_postulacion', replace //We save this since new data does not include this variable.
		clear
		*/
		
		import delimited "$IN\MINEDU\Entrega-2\db_postulantes.csv", clear
		compress		
	}	
	
	if ${excel} == 1 & ${test}==1 & ${new}==1 {
		import delimited "$IN\MINEDU\Entrega-2\db_postulantes.csv", clear
		keep if runiform()<0.01
		compress		
		save "$TEMP\applied_raw_new_TEST", replace
	}
		
	
	if ${excel} == 0 & ${test}==1 & ${new}==0 {
		use "$TEMP\applied_raw_TEST", clear
	}
	
	if ${excel} == 0 & ${test}==1 & ${new}==1 {
		use "$TEMP\applied_raw_new_TEST", clear
	}	

	if ${excel} == 0 & ${test}==0 {
		assert 1==0 //we don't save the raw in DTA
	}	
	
	*- Rename new variables that are also present in old database
	if ${new}==1 {
		
		*- Rename to common prior name
		rename (tipo_institucion tipo_gestion id_persona) (id_tipo_institucion id_tipo_gestion id_persona_rec)	
		
		*- Create categorical id_anio var as before (but not same value)
		egen id_anio = group(abreviatura_anio)
		//merge m:1 id_persona_rec periodo_postulacion using `previous_id_periodo_postulacion', keepusing(id_periodo_postulacion) keep(master match)
		egen id_periodo_postulacion = group(periodo_postulacion)
	}
			


	
	isvar 			///
		/*Match ID*/ id_per_umc id_persona_rec id_per_pos* ///
		/*ID*/ codigo_modular id_tipo_institucion id_tipo_gestion id_anio id_codigo_facultad id_carrera_primera_opcion id_carrera_segunda_opcion /*id_carrera_homologada_primera_op*/ /*id_estado_persona*/ id_periodo_postulacion periodo_postulacion id_periodo_matricula periodo_matricula	universidad facultad abreviatura_anio ///
		/*Char UNI*/ estatus_licenciamiento tipo_funcionamiento		///
		/*Char Indiv*/ 	fecha_nacimiento edad sexo	///
		/*applic info*/ puntaje_postulante codigo_carrera_inei_primera_opci carrera_primera_opcion carrera_segunda_opcion nombre_carrera_inei_primera_opci codigo?_c2018  nombre1_c2018 codigo_carrera_inei_segunda_opci nombre_carrera_inei_segunda_opci 		///
		/*admitt info*/ es_ingresante codigo_carrera_inei_ingreso carrera_ingreso  nombre_carrera_inei_ingreso ///
		/*enroll info*/ nota_promedio ///
		/*NEW VARS*/ codigo_ubigeo departamento provincia distrito modalidad_admis modalidad_admision duracion_carrera modalidad_estudio modalidad_juridica modalidad_constitucion codigo_modular_colegio nro_creditos periodo_ingreso periodo_primera_matricula
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'

		foreach v of local all_vars {
			capture confirm string variable `v'
				if _rc==0 {
					   replace `v' = trim(itrim(`v'))
				}
		}
		
		*Destring those not IDs
		ds id_per_umc id_persona_rec codigo_modular, not
		local all_vars = r(varlist)
		destring `all_vars', replace
					
		compress	

	define_labels

	rename puntaje_postulante score_raw
	rename abreviatura_anio year	
	gen dob = date(fecha_nacimiento, "YMD") 
	format %td dob
	rename edad age
	
	
	*-----------------
	*- NEW VARIABLES
	*-----------------
	
	if ${new} == 1 {
		*- Region
		gen ubigeo = string(codigo_ubigeo)
		replace ubigeo = "0" + ubigeo if strlen(ubigeo)<6
		gen region = substr(ubigeo,1,2)
		destring region, replace
		drop ubigeo
		
		*- Admission type
		gen type_admission = .
		replace type_admission = 1 if modalidad_admision == "EXAMEN ORDINARIO"
		replace type_admission = 2 if modalidad_admision == "ACADEMIA PREPARATORIA"
		replace type_admission = 3 if modalidad_admision == "MODALIDAD ESCOLAR"
		replace type_admission = 4 if modalidad_admision == "1ER Y 2DO PUESTO ESCOLAR"
		replace type_admission = 5 if modalidad_admision == "TRASLADO EXTERNO"
		replace type_admission = 6 if modalidad_admision == "TERCIO SUPERIOR"
		replace type_admission = 7 if modalidad_admision == "ADULTO"
		replace type_admission = 8 if type_admission== .
		label values type_admission type_admission	
		      
		*- School Codigo Modular
		gen id_ie = string(codigo_modular_colegio)
		replace id_ie = "" if id_ie =="."
		replace id_ie = id_ie + "0"
		replace id_ie = "0" + id_ie if strlen(id_ie)<8
		replace id_ie = "" if strlen(id_ie)!=8
		
		*- Modalidad estudio
		gen type_in_person = .
		replace type_in_person = 1 if modalidad_estudio == "Presencial"
		replace type_in_person = 2 if modalidad_estudio == "Semi-presencial"
		replace type_in_person = 3 if modalidad_estudio == "Virtual"
		replace type_in_person = 4 if modalidad_estudio == "A distancia"
		replace type_in_person = 5 if modalidad_estudio == "No aplica"
		label values type_in_person type_in_person
		
		*- Modalidad Juridica
		ds modalidad_juridica
		
		*- Modalidad Constitucion
		gen type_const = .
		replace type_const = 1 if modalidad_constitucion == "PÚBLICAS INSTITUCIONALIZADAS"
		replace type_const = 2 if modalidad_constitucion == "PÚBLICAS CON COMISIÓN ORGANIZADORA"
		replace type_const = 3 if modalidad_constitucion == "PRIVADAS SOCIETARIAS"
		replace type_const = 4 if modalidad_constitucion == "PRIVADAS ASOCIATIVAS"
		label values type_const type_const
		
	}
	
	*-----------------
	*- OLD VARIABLES
	*-----------------	
	
	*- Male
	gen male = 1 if sexo=="MASCULINO" 
	replace male = 0 if sexo=="FEMENINO" 
	label var male "Sex: Male"
	label define male 0 "female" 1 "male", replace
	label values male male
	
	*- Institution type
	gen university = 1 if id_tipo_institucion=="UNIVERSIDADES" 
	replace university = 0 if id_tipo_institucion!="UNIVERSIDADES" & id_tipo_institucion!=""
	label var university "Type: University"
	label define university 0 "Other" 1 "University", replace
	label values university university		
	
	*- Public
	gen public = 1 if inlist(id_tipo_gestion,"PUBLICA", "PÚBLICA")==1
	replace public = 0 if id_tipo_gestion=="PRIVADA" 
	label var public "Administration: Public"
	label values public public			
	
	*- Licensed
	gen licensed = 1 if estatus_licenciamiento=="LICENCIADA" 
	replace licensed = 0 if estatus_licenciamiento=="LICENCIA DENEGADA" 
	label var licensed "Status: Licensed"
	label define licensed 0 "License Denied" 1 "Licensed", replace
	label values licensed licensed		
	
	*- Academic
	gen academic = 1 if tipo_funcionamiento == "ACADÉMICO"
	replace academic = 0 if tipo_funcionamiento=="AMBOS" 
	label var academic "Type: Academic"
	label define academic 0 "both" 1 "academic", replace
	label values academic academic	
	
	*- Choice/Major
	
	*-- Major category
	rename codigo1_c2018 major_c1_cat
	rename codigo3_c2018 major_c1_cat3
	rename codigo6_c2018 major_c1_cat6
	tab major_c1_cat nombre1_c2018 
	capture label drop major_cat
	label define major_cat 0 "SERVICIOS" 1 "EDUCACIÓN" 2 "ARTE Y HUMANIDADES" 3 "CIENCIAS SOCIALES, PERIODISMO E INFORMACIÓN" 4 "CIENCIAS ADMINISTRATIVAS Y DERECHO" 5 "CIENCIAS NATURALES, MATEMÁTICAS Y ESTADÍSTICA" 6 "TECNOLOGÍA DE LA INFORMACIÓN Y LA COMUNICACIÓN" 7 "INGENIERÍA, INDUSTRIA Y CONSTRUCCIÓN" 8 "AGRICULTURA, SILVICULTURA, PESCA Y VETERINARIA" 9 "SALUD Y BIENESTAR", replace
	label values major_c1_cat major_cat
	
		
	*- Semester
	rename periodo_postulacion		semester
	
	*-- Major Name
	rename carrera_primera_opcion major_c1_name
	//rename nombre_carrera_inei_primera_opci major_inei
	rename nombre_carrera_inei_segunda_opci name_major_choice2
	//rename carrera_ingreso major_admitted	
	//rename nombre_carrera_inei_ingreso name_major_admitted
	
	*-- Major Code
	rename id_carrera_primera_opcion	major_c1_code
	rename codigo_carrera_inei_primera_opci major_c1_inei_code
	rename codigo_carrera_inei_ingreso major_admit_inei_code
	//rename codigo_carrera_inei_segunda_opci id_major_choice2
	
	*-- 2nd major
	rename id_carrera_segunda_opcion			major_c2_code
	rename carrera_segunda_opcion				major_c2_name
	rename codigo_carrera_inei_segunda_opci 	major_c2_inei_code

	preserve
		bys codigo_modular universidad: keep if _n==1
		sort codigo_modular
		list codigo_modular universidad, sep(10000)
	restore
	
	*- Region
	if ${new} == 0 {
		gen region = .
		replace region = 15 if universidad == "UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS"
		replace region = 5 	if universidad == "UNIVERSIDAD NACIONAL DE SAN CRISTÓBAL DE HUAMANGA"
		replace region = 8 	if universidad == "UNIVERSIDAD NACIONAL DE SAN ANTONIO ABAD DEL CUSCO"
		replace region = 13 if universidad == "UNIVERSIDAD NACIONAL DE TRUJILLO"
		replace region = 4 	if universidad == "UNIVERSIDAD NACIONAL DE SAN AGUSTÍN"
		replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE INGENIERÍA"
		replace region = 15 if universidad == "UNIVERSIDAD NACIONAL AGRARIA LA MOLINA"
		replace region = 11 if universidad == "UNIVERSIDAD NACIONAL SAN LUIS GONZAGA DE ICA"
		replace region = 12 if universidad == "UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ"
		replace region = 16 if universidad == "UNIVERSIDAD NACIONAL DE LA AMAZONÍA PERUANA"
		replace region = 21 if universidad == "UNIVERSIDAD NACIONAL DEL ALTIPLANO"
		replace region = 20 if universidad == "UNIVERSIDAD NACIONAL DE PIURA"
		replace region = 6 	if universidad == "UNIVERSIDAD NACIONAL DE CAJAMARCA"
		replace region = 15 if universidad == "UNIVERSIDAD NACIONAL FEDERICO VILLARREAL"
		replace region = 10 if universidad == "UNIVERSIDAD NACIONAL AGRARIA DE LA SELVA"
		replace region = 10 if universidad == "UNIVERSIDAD NACIONAL HERMILIO VALDIZAN"
		replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE EDUCACIÓN ENRIQUE GUZMÁN Y VALLE"
		replace region = 19 if universidad == "UNIVERSIDAD NACIONAL DANIEL ALCIDES CARRIÓN"
		replace region = 7 	if universidad == "UNIVERSIDAD NACIONAL DEL CALLAO"
		replace region = 15 if universidad == "UNIVERSIDAD NACIONAL JOSÉ FAUSTINO SÁNCHEZ CARRIÓN"
		replace region = 14 if universidad == "UNIVERSIDAD NACIONAL PEDRO RUÍZ GALLO"
		replace region = 23 if universidad == "UNIVERSIDAD NACIONAL JORGE BASADRE GROHMANN"
		replace region = 2 	if universidad == "UNIVERSIDAD NACIONAL SANTIAGO ANTÚNEZ DE MAYOLO"
		replace region = 22 if universidad == "UNIVERSIDAD NACIONAL DE SAN MARTÍN"
		replace region = 25 if universidad == "UNIVERSIDAD NACIONAL DE UCAYALI"
		replace region = 24 if universidad == "UNIVERSIDAD NACIONAL DE TUMBES"
		replace region = 2 	if universidad == "UNIVERSIDAD NACIONAL DEL SANTA"
		replace region = 9 	if universidad == "UNIVERSIDAD NACIONAL DE HUANCAVELICA"
		replace region = 17 if universidad == "UNIVERSIDAD NACIONAL AMAZÓNICA DE MADRE DE DIOS"
		replace region = 1 	if universidad == "UNIVERSIDAD NACIONAL TORIBIO RODRÍGUEZ DE MENDOZA DE AMAZONAS"
		replace region = 3 	if universidad == "UNIVERSIDAD NACIONAL MICAELA BASTIDAS DE APURIMAC"
		replace region = 25 if universidad == "UNIVERSIDAD NACIONAL INTERCULTURAL DE LA AMAZONIA"
		replace region = 15 if universidad == "UNIVERSIDAD NACIONAL TECNOLÓGICA DE LIMA SUR"
		replace region = 3 	if universidad == "UNIVERSIDAD NACIONAL JOSE MARIA ARGUEDAS"
		replace region = 18 if universidad == "UNIVERSIDAD NACIONAL DE MOQUEGUA"
		replace region = 21 if universidad == "UNIVERSIDAD NACIONAL DE JULIACA"
		replace region = 6 	if universidad == "UNIVERSIDAD NACIONAL DE JAÉN"
		replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE CAÑETE"
		replace region = 6 	if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA DE CHOTA"
		replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE BARRANCA"
		replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE FRONTERA"
		replace region = 1 	if universidad == `""UNIVERSIDAD NACIONAL INTERCULTURAL ""FABIOLA SALAZAR LEGUÍA"" DE BAGUA""'
		replace region = 12 if universidad == "UNIVERSIDAD NACIONAL INTERCULTURAL DE LA SELVA CENTRAL JUAN SANTOS ATAHUALPA"
		replace region = 8 	if universidad == "UNIVERSIDAD NACIONAL INTERCULTURAL DE QUILLABAMBA"
		replace region = 16 if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA DE ALTO AMAZONAS"
		replace region = 15 if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA ALTOANDINA DE TARMA"
		replace region = 5 	if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA DE HUANTA"
		replace region = 9 	if universidad == `""UNIVERSIDAD NACIONAL AUTÓNOMA DE TAYACAJA ""DANIEL HERNÁNDEZ MORILLO""""'
		replace region = 15 if universidad == "PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ"
		replace region = 15 if universidad == "UNIVERSIDAD PERUANA CAYETANO HEREDIA"
		replace region = 4 	if universidad == "UNIVERSIDAD CATÓLICA DE SANTA MARÍA"
		replace region = 15 if universidad == "UNIVERSIDAD DEL PACÍFICO"
		replace region = 15 if universidad == "UNIVERSIDAD DE LIMA"
		replace region = 15 if universidad == "UNIV DE SAN MARTÍN DE PORRES"
		replace region = 15 if universidad == "UNIVERSIDAD FEMENINA DEL SAGRADO CORAZÓN"
		replace region = 15 if universidad == "UNIVERSIDAD INCA GARCILASO DE LA VEGA"
		replace region = 20 if universidad == "UNIVERSIDAD DE PIURA"
		replace region = 15 if universidad == "UNIVERSIDAD RICARDO PALMA"
		replace region = 21 if universidad == "UNIVERSIDAD ANDINA NÉSTOR CÁCERES VELÁSQUEZ"
		replace region = 12 if universidad == "UNIVERSIDAD PERUANA LOS ANDES"
		replace region = 15 if universidad == "UNIVERSIDAD PERUANA UNIÓN"
		replace region = 8 	if universidad == "UNIVERSIDAD ANDINA DEL CUSCO"
		replace region = 3 	if universidad == "UNIVERSIDAD TECNOLOGICA DE LOS ANDES"
		replace region = 23 if universidad == "UNIVERSIDAD PRIVADA DE TACNA"
		replace region = 14 if universidad == "UNIVERSIDAD PARTICULAR DE CHICLAYO"
		replace region = 2 	if universidad == "UNIVERSIDAD SAN PEDRO"
		replace region = 13 if universidad == "UNIVERSIDAD PRIVADA ANTENOR ORREGO"
		replace region = 10 if universidad == "UNIVERSIDAD DE HUANUCO"
		replace region = 18 if universidad == "UNIVERSIDAD JOSÉ CARLOS MARIÁTEGUI"
		replace region = 15 if universidad == "UNIVERSIDAD MARCELINO CHAMPAGNAT"
		replace region = 16 if universidad == "UNIVERSIDAD CIENTÍFICA DEL PERÚ - UCP"
		replace region = 13 if universidad == "UNIVERSIDAD CÉSAR VALLEJO"
		replace region = 2 	if universidad == "UNIVERSIDAD CATÓLICA LOS ÁNGELES DE CHIMBOTE"
		replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE CIENCIAS APLICADAS"
		replace region = 13 if universidad == "UNIVERSIDAD PRIVADA DEL NORTE"
		replace region = 15 if universidad == "UNIVERSIDAD SAN IGNACIO DE LOYOLA"
		replace region = 99 if universidad == "UNIVERSIDAD ALAS PERUANAS"
		replace region = 15 if universidad == "UNIVERSIDAD NORBERT WIENER"
		replace region = 4 	if universidad == "UNIVERSIDAD CATÓLICA SAN PABLO"
		replace region = 11 if universidad == "UNIVERSIDAD PRIVADA DE ICA"
		replace region = 15 if universidad == "UNIVERSIDAD PRIVADA SAN JUAN BAUTISTA"
		replace region = 99 if universidad == "UNIVERSIDAD TECNOLÓGICA DEL PERÚ"
		replace region = 99 if universidad == "UNIVERSIDAD CONTINENTAL"
		replace region = 15 if universidad == "UNIVERSIDAD CIENTÍFICA DEL SUR"
		replace region = 14 if universidad == "UNIVERSIDAD CATÓLICA SANTO TORIBIO DE MOGROVEJO"
		replace region = 6 	if universidad == "UNIVERSIDAD PRIVADA ANTONIO GUILLERMO URRELO"
		replace region = 99 if universidad == "UNIVERSIDAD CATÓLICA SEDES SAPIENTIAE"
		replace region = 14 if universidad == "UNIVERSIDAD SEÑOR DE SIPÁN"
		replace region = 13 if universidad == "UNIVERSIDAD CATÓLICA DE TRUJILLO BENEDICTO XVI"
		replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE LAS AMÉRICAS"
		replace region = 15 if universidad == "UNIVERSIDAD ESAN"
		replace region = 15 if universidad == "UNIVERSIDAD ANTONIO RUIZ DE MONTOYA"
		replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE CIENCIA E INFORMÁTICA"
		replace region = 9 	if universidad == "UNIVERSIDAD PARA EL DESARROLLO ANDINO"
		replace region = 15 if universidad == "UNIVERSIDAD PRIVADA TELESUP"
		replace region = 15 if universidad == "UNIVERSIDAD PRIVADA SERGIO BERNALES"
		replace region = 99 if universidad == "UNIVERSIDAD PRIVADA DE PUCALLPA"
		replace region = 11 if universidad == "UNIVERSIDAD AUTÓNOMA DE ICA"
		replace region = 13 if universidad == "UNIVERSIDAD PRIVADA DE TRUJILLO"
		replace region = 21 if universidad == "UNIVERSIDAD PRIVADA SAN CARLOS"
		replace region = 15 if universidad == "UNIVERSIDAD PERUANA SIMÓN BOLÍVAR"
		replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE INTEGRACIÓN GLOBAL"
		replace region = 16 if universidad == "UNIVERSIDAD PERUANA DEL ORIENTE"
		replace region = 15 if universidad == "UNIVERSIDAD AUTÓNOMA DEL PERU"
		replace region = 15 if universidad == "UNIVERSIDAD DE CIENCIAS Y HUMANIDADES"
		replace region = 14 if universidad == "UNIVERSIDAD PRIVADA JUAN MEJÍA BACA"
		replace region = 15 if universidad == "UNIVERSIDAD JAIME BAUSATE Y MEZA"
		replace region = 12 if universidad == "UNIVERSIDAD PERUANA DEL CENTRO"
		replace region = 15 if universidad == "UNIVERSIDAD PRIVADA ARZOBISPO LOAYZA"
		replace region = 15 if universidad == "UNIVERSIDAD LE CORDON BLEU"
		replace region = 12 if universidad == "UNIVERSIDAD PRIVADA DE HUANCAYO FRANKLIN ROOSEVELT"
		replace region = 14 if universidad == "UNIVERSIDAD DE LAMBAYEQUE"
		replace region = 15 if universidad == "UNIVERSIDAD DE CIENCIAS Y ARTES DE AMÉRICA LATINA"
		replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE ARTE ORVAL"
		replace region = 16 if universidad == "UNIVERSIDAD PRIVADA DE LA SELVA PERÚANA"
		replace region = 4 	if universidad == "UNIVERSIDAD CIENCIAS DE LA SALUD"
		replace region = 5 	if universidad == "UNIVERSIDAD DE AYACUCHO FEDERICO FROEBEL"
		replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE INVESTIGACIÓN Y NEGOCIOS"
		replace region = 8 	if universidad == "UNIVERSIDAD PERUANA AUSTRAL DEL CUSCO"
		replace region = 4 	if universidad == "UNIVERSIDAD AUTÓNOMA SAN FRANCISCO"
		replace region = 15 if universidad == "UNIVERSIDAD SAN ANDRÉS"
		replace region = 15 if universidad == "UNIVERSIDAD INTERAMÉRICANA PARA EL DESARROLLO"
		replace region = 15 if universidad == "UNIVERSIDAD PRIVADA JUAN PABLO II"
		replace region = 13 if universidad == "UNIVERSIDAD PRIVADA LEONARDO DA VINCI"
		replace region = 15 if universidad == "UTEC"
		replace region = 4 	if universidad == "UNIVERSIDAD LA SALLE"
		replace region = 23 if universidad == "UNIVERSIDAD LATINOAMERICANA CIMA"
		replace region = 4 	if universidad == "UNIVERSIDAD PRIVADA AUTÓNOMA DEL SUR"
		replace region = 15 if universidad == "UNIVERSIDAD MARÍA AUXILIADORA"
		replace region = 1 	if universidad == "UNIVERSIDAD POLITÉCNICA AMAZÓNICA"
		replace region = 15 if universidad == "UNIVERSIDAD SANTO DOMINGO DE GUZMÁN SAC"
		replace region = 7 	if universidad == "UNIVERSIDAD MARÍTIMA DEL PERÚ"
		replace region = 8 	if universidad == "UNIVERSIDAD PRIVADA LIDER PERUANA"
		replace region = 15 if universidad == "UNIVERSIDAD PRIVADA PERUANO ALEMANA"
		replace region = 8 	if universidad == "UNIVERSIDAD GLOBAL DEL CUSCO"
		replace region = 12 if universidad == "UST UNIVERSIDAD SANTO TOMÁS"
		replace region = 15 if universidad == "UNIVERSIDAD PRIVADA SISE"
		replace region = 15 if universidad == "FACULTAD DE TEOLOGÍA PONTIFICIA Y CIVIL DE LIMA"
		replace region = 15 if universidad == "UNIVERSIDAD SEMINARIO BÍBLICO ANDINO"
		replace region = 15 if universidad == "UNIVERSIDAD SEMINARIO EVANGÉLICO DE LIMA"
		
	}
	
	label values region dep
	
	
	/*

     +------------------------------------------------------------------------------------------+
     | codigo_~r                                                                    universidad | Region
     |------------------------------------------------------------------------------------------|
  1. | 160000001                                       UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS | Lima 15
  2. | 160000002                              UNIVERSIDAD NACIONAL DE SAN CRISTÓBAL DE HUAMANGA | Ayacucho 5
  3. | 160000003                             UNIVERSIDAD NACIONAL DE SAN ANTONIO ABAD DEL CUSCO | Cusco 8
  4. | 160000004                                               UNIVERSIDAD NACIONAL DE TRUJILLO | La Libertad 13
  5. | 160000005                                            UNIVERSIDAD NACIONAL DE SAN AGUSTÍN | Arequipa 4
  6. | 160000006                                             UNIVERSIDAD NACIONAL DE INGENIERÍA | Lima 15
  7. | 160000007                                         UNIVERSIDAD NACIONAL AGRARIA LA MOLINA | Lima 15
  8. | 160000009                                   UNIVERSIDAD NACIONAL SAN LUIS GONZAGA DE ICA | Ica 11
  9. | 160000010                                       UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ | Junin 12
 10. | 160000011                                    UNIVERSIDAD NACIONAL DE LA AMAZONÍA PERUANA | Loreto 16
 11. | 160000012                                             UNIVERSIDAD NACIONAL DEL ALTIPLANO | Puno 21
 12. | 160000013                                                  UNIVERSIDAD NACIONAL DE PIURA | Piura 20
 13. | 160000016                                              UNIVERSIDAD NACIONAL DE CAJAMARCA | Cajamarca 6 
 14. | 160000021                                       UNIVERSIDAD NACIONAL FEDERICO VILLARREAL | Lima* 15
 15. | 160000022                                       UNIVERSIDAD NACIONAL AGRARIA DE LA SELVA | Huanuco 10
 16. | 160000023                                         UNIVERSIDAD NACIONAL HERMILIO VALDIZAN | Huanuco 10
 17. | 160000025                       UNIVERSIDAD NACIONAL DE EDUCACIÓN ENRIQUE GUZMÁN Y VALLE | Lima 15
 18. | 160000026                                    UNIVERSIDAD NACIONAL DANIEL ALCIDES CARRIÓN | Pasco 19
 19. | 160000027                                                UNIVERSIDAD NACIONAL DEL CALLAO | Callao 7
 20. | 160000028                             UNIVERSIDAD NACIONAL JOSÉ FAUSTINO SÁNCHEZ CARRIÓN | Lima (Huacho) 15
 21. | 160000031                                          UNIVERSIDAD NACIONAL PEDRO RUÍZ GALLO | Lambayeque 14
 22. | 160000032                                    UNIVERSIDAD NACIONAL JORGE BASADRE GROHMANN | Tacna 23
 23. | 160000033                                UNIVERSIDAD NACIONAL SANTIAGO ANTÚNEZ DE MAYOLO | Ancash 2
 24. | 160000034                                             UNIVERSIDAD NACIONAL DE SAN MARTÍN | San Martin  22
 25. | 160000035                                                UNIVERSIDAD NACIONAL DE UCAYALI | Ucayali 25
 26. | 160000041                                                 UNIVERSIDAD NACIONAL DE TUMBES | Tumbes 24
 27. | 160000042                                                 UNIVERSIDAD NACIONAL DEL SANTA | Ancash  2
 28. | 160000051                                           UNIVERSIDAD NACIONAL DE HUANCAVELICA | Huancavelica 9
 29. | 160000075                                UNIVERSIDAD NACIONAL AMAZÓNICA DE MADRE DE DIOS | Madre de dios
 30. | 160000076                  UNIVERSIDAD NACIONAL TORIBIO RODRÍGUEZ DE MENDOZA DE AMAZONAS | Amazonas 1
 31. | 160000077                              UNIVERSIDAD NACIONAL MICAELA BASTIDAS DE APURIMAC | Apurimac 3
 32. | 160000084                              UNIVERSIDAD NACIONAL INTERCULTURAL DE LA AMAZONIA | Ucayali 25
 33. | 160000088                                   UNIVERSIDAD NACIONAL TECNOLÓGICA DE LIMA SUR | Lima 15
 34. | 160000089                                       UNIVERSIDAD NACIONAL JOSE MARIA ARGUEDAS | Apurimac 3
 35. | 160000095                                               UNIVERSIDAD NACIONAL DE MOQUEGUA | Moquegua 18
 36. | 160000098                                                UNIVERSIDAD NACIONAL DE JULIACA | Puno 21
 37. | 160000101                                                   UNIVERSIDAD NACIONAL DE JAÉN | Cajamarca 6
 38. | 160000106                                                 UNIVERSIDAD NACIONAL DE CAÑETE | Lima* 15
 39. | 160000120                                         UNIVERSIDAD NACIONAL AUTÓNOMA DE CHOTA | Cajamarca 6
 40. | 160000121                                               UNIVERSIDAD NACIONAL DE BARRANCA | Lima* 15
 41. | 160000122                                               UNIVERSIDAD NACIONAL DE FRONTERA | Lima* 15
 42. | 160000123           UNIVERSIDAD NACIONAL INTERCULTURAL "FABIOLA SALAZAR LEGUÍA" DE BAGUA | Amazonas 1
 43. | 160000124   UNIVERSIDAD NACIONAL INTERCULTURAL DE LA SELVA CENTRAL JUAN SANTOS ATAHUALPA | Junin 12
 44. | 160000125                              UNIVERSIDAD NACIONAL INTERCULTURAL DE QUILLABAMBA | Cusco* 8
 45. | 160000126                                 UNIVERSIDAD NACIONAL AUTÓNOMA DE ALTO AMAZONAS | Loreto 16
 46. | 160000127                              UNIVERSIDAD NACIONAL AUTÓNOMA ALTOANDINA DE TARMA | Lima* 15
 47. | 160000128                                        UNIVERSIDAD NACIONAL AUTÓNOMA DE HUANTA | Ayacucho 5
 48. | 160000138           UNIVERSIDAD NACIONAL AUTÓNOMA DE TAYACAJA "DANIEL HERNÁNDEZ MORILLO" | Huancavelica 9
 ----------------------------------------------------------------------------------------------------------
 49. | 260000008                                       PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ | Lima 15
 50. | 260000014                                           UNIVERSIDAD PERUANA CAYETANO HEREDIA | Lima 15
 51. | 260000015                                            UNIVERSIDAD CATÓLICA DE SANTA MARÍA | Arequipa 4
 52. | 260000017                                                       UNIVERSIDAD DEL PACÍFICO | Lima 15
 53. | 260000018                                                            UNIVERSIDAD DE LIMA | Lima 15
 54. | 260000019                                                   UNIV DE SAN MARTÍN DE PORRES | Lima 15
 55. | 260000020                                       UNIVERSIDAD FEMENINA DEL SAGRADO CORAZÓN | Lima 15 
 56. | 260000024                                          UNIVERSIDAD INCA GARCILASO DE LA VEGA | Lima 15 
 57. | 260000029                                                           UNIVERSIDAD DE PIURA | Piura 20
 58. | 260000030                                                      UNIVERSIDAD RICARDO PALMA | Lima 15 
 59. | 260000036                                    UNIVERSIDAD ANDINA NÉSTOR CÁCERES VELÁSQUEZ |
 60. | 260000037                                                  UNIVERSIDAD PERUANA LOS ANDES |
 61. | 260000038                                                      UNIVERSIDAD PERUANA UNIÓN |
 62. | 260000039                                                   UNIVERSIDAD ANDINA DEL CUSCO |
 63. | 260000040                                           UNIVERSIDAD TECNOLOGICA DE LOS ANDES |
 64. | 260000043                                                   UNIVERSIDAD PRIVADA DE TACNA |
 65. | 260000044                                             UNIVERSIDAD PARTICULAR DE CHICLAYO |
 66. | 260000045                                                          UNIVERSIDAD SAN PEDRO |
 67. | 260000046                                             UNIVERSIDAD PRIVADA ANTENOR ORREGO |
 68. | 260000047                                                         UNIVERSIDAD DE HUANUCO |
 69. | 260000048                                             UNIVERSIDAD JOSÉ CARLOS MARIÁTEGUI |
 70. | 260000049                                               UNIVERSIDAD MARCELINO CHAMPAGNAT |
 71. | 260000050                                          UNIVERSIDAD CIENTÍFICA DEL PERÚ - UCP |
 72. | 260000052                                                      UNIVERSIDAD CÉSAR VALLEJO |
 73. | 260000053                                   UNIVERSIDAD CATÓLICA LOS ÁNGELES DE CHIMBOTE |
 74. | 260000054                                      UNIVERSIDAD PERUANA DE CIENCIAS APLICADAS |
 75. | 260000055                                                  UNIVERSIDAD PRIVADA DEL NORTE |
 76. | 260000057                                              UNIVERSIDAD SAN IGNACIO DE LOYOLA |
 77. | 260000059                                                      UNIVERSIDAD ALAS PERUANAS |
 78. | 260000061                                                     UNIVERSIDAD NORBERT WIENER |
 79. | 260000062                                                 UNIVERSIDAD CATÓLICA SAN PABLO |
 80. | 260000063                                                     UNIVERSIDAD PRIVADA DE ICA |
 81. | 260000064                                          UNIVERSIDAD PRIVADA SAN JUAN BAUTISTA |
 82. | 260000065                                               UNIVERSIDAD TECNOLÓGICA DEL PERÚ |
 83. | 260000067                                                        UNIVERSIDAD CONTINENTAL |
 84. | 260000068                                                 UNIVERSIDAD CIENTÍFICA DEL SUR |
 85. | 260000069                                UNIVERSIDAD CATÓLICA SANTO TORIBIO DE MOGROVEJO |
 86. | 260000070                                   UNIVERSIDAD PRIVADA ANTONIO GUILLERMO URRELO |
 87. | 260000071                                          UNIVERSIDAD CATÓLICA SEDES SAPIENTIAE |
 88. | 260000072                                                     UNIVERSIDAD SEÑOR DE SIPÁN |
 89. | 260000074                                 UNIVERSIDAD CATÓLICA DE TRUJILLO BENEDICTO XVI |
 90. | 260000078                                            UNIVERSIDAD PERUANA DE LAS AMÉRICAS |
 91. | 260000079                                                               UNIVERSIDAD ESAN |
 92. | 260000080                                            UNIVERSIDAD ANTONIO RUIZ DE MONTOYA |
 93. | 260000081                                   UNIVERSIDAD PERUANA DE CIENCIA E INFORMÁTICA |
 94. | 260000082                                          UNIVERSIDAD PARA EL DESARROLLO ANDINO |
 95. | 260000083                                                    UNIVERSIDAD PRIVADA TELESUP |
 96. | 260000085                                            UNIVERSIDAD PRIVADA SERGIO BERNALES |
 97. | 260000086                                                UNIVERSIDAD PRIVADA DE PUCALLPA |
 98. | 260000087                                                    UNIVERSIDAD AUTÓNOMA DE ICA |
 99. | 260000090                                                UNIVERSIDAD PRIVADA DE TRUJILLO |
100. | 260000091                                                 UNIVERSIDAD PRIVADA SAN CARLOS |
101. | 260000092                                              UNIVERSIDAD PERUANA SIMÓN BOLÍVAR |
102. | 260000093                                      UNIVERSIDAD PERUANA DE INTEGRACIÓN GLOBAL |
103. | 260000094                                                UNIVERSIDAD PERUANA DEL ORIENTE |
104. | 260000096                                                  UNIVERSIDAD AUTÓNOMA DEL PERU |
105. | 260000097                                          UNIVERSIDAD DE CIENCIAS Y HUMANIDADES |
106. | 260000099                                            UNIVERSIDAD PRIVADA JUAN MEJÍA BACA |
107. | 260000100                                               UNIVERSIDAD JAIME BAUSATE Y MEZA |
108. | 260000102                                                 UNIVERSIDAD PERUANA DEL CENTRO |
109. | 260000103                                           UNIVERSIDAD PRIVADA ARZOBISPO LOAYZA |
110. | 260000104                                                     UNIVERSIDAD LE CORDON BLEU |
111. | 260000105                             UNIVERSIDAD PRIVADA DE HUANCAYO FRANKLIN ROOSEVELT |
112. | 260000107                                                      UNIVERSIDAD DE LAMBAYEQUE |
113. | 260000108                              UNIVERSIDAD DE CIENCIAS Y ARTES DE AMÉRICA LATINA |
114. | 260000109                                              UNIVERSIDAD PERUANA DE ARTE ORVAL |
115. | 260000110                                        UNIVERSIDAD PRIVADA DE LA SELVA PERÚANA |
116. | 260000111                                               UNIVERSIDAD CIENCIAS DE LA SALUD |
117. | 260000112                                       UNIVERSIDAD DE AYACUCHO FEDERICO FROEBEL |
118. | 260000113                                UNIVERSIDAD PERUANA DE INVESTIGACIÓN Y NEGOCIOS |
119. | 260000114                                          UNIVERSIDAD PERUANA AUSTRAL DEL CUSCO |
120. | 260000115                                             UNIVERSIDAD AUTÓNOMA SAN FRANCISCO |
121. | 260000116                                                         UNIVERSIDAD SAN ANDRÉS |
122. | 260000117                                  UNIVERSIDAD INTERAMÉRICANA PARA EL DESARROLLO |
123. | 260000118                                              UNIVERSIDAD PRIVADA JUAN PABLO II |
124. | 260000119                                          UNIVERSIDAD PRIVADA LEONARDO DA VINCI |
125. | 260000132                                                                           UTEC |
126. | 260000133                                                           UNIVERSIDAD LA SALLE |
127. | 260000134                                               UNIVERSIDAD LATINOAMERICANA CIMA |
128. | 260000135                                           UNIVERSIDAD PRIVADA AUTÓNOMA DEL SUR |
129. | 260000136                                                  UNIVERSIDAD MARÍA AUXILIADORA |
130. | 260000137                                              UNIVERSIDAD POLITÉCNICA AMAZÓNICA |
131. | 260000140                                        UNIVERSIDAD SANTO DOMINGO DE GUZMÁN SAC |
132. | 260000141                                                  UNIVERSIDAD MARÍTIMA DEL PERÚ |
133. | 260000142                                              UNIVERSIDAD PRIVADA LIDER PERUANA |
134. | 260000143                                            UNIVERSIDAD PRIVADA PERUANO ALEMANA |
135. | 260000144                                                   UNIVERSIDAD GLOBAL DEL CUSCO |
136. | 260000145                                                    UST UNIVERSIDAD SANTO TOMÁS |
137. | 260000146                                                       UNIVERSIDAD PRIVADA SISE |
138. | 260000501                                FACULTAD DE TEOLOGÍA PONTIFICIA Y CIVIL DE LIMA |
139. | 260000601                                           UNIVERSIDAD SEMINARIO BÍBLICO ANDINO |
140. | 260000602                                       UNIVERSIDAD SEMINARIO EVANGÉLICO DE LIMA |
     +------------------------------------------------------------------------------------------+
	
	
	*/
	
	
	
	/*
	close
	open
	*erase_close
	*/
	*- We do a few manual splits (at least for big cases)
	gen source = 0 //we count different aparent cells
	gen issue = 0 //dummy to indicate problematic cells
	
	*- Public
	//160000006
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE INGENIERÍA" & year==2020 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE INGENIERÍA" & year==2021 & score_raw>20

	//160000010
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ" & year==2023 & score_raw>20
	
	//160000012
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DEL ALTIPLANO" & year==2017 & score_raw>300
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DEL ALTIPLANO" & year==2018 & score_raw>500
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DEL ALTIPLANO" & year==2019 & score_raw>500
	
	//160000013
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE PIURA" & year==2020 & score_raw>1000
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE PIURA" & year==2023 & score_raw>500

	//160000025
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE EDUCACIÓN ENRIQUE GUZMÁN Y VALLE" & year==2017 & score_raw>20
	
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE EDUCACIÓN ENRIQUE GUZMÁN Y VALLE" & year==2019 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE EDUCACIÓN ENRIQUE GUZMÁN Y VALLE" & year==2020 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE EDUCACIÓN ENRIQUE GUZMÁN Y VALLE" & year==2021 & score_raw>20
	replace issue = 1  if universidad == "UNIVERSIDAD NACIONAL DE EDUCACIÓN ENRIQUE GUZMÁN Y VALLE" & year==2022 //bunched above
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE EDUCACIÓN ENRIQUE GUZMÁN Y VALLE" & year==2023 & score_raw>20

	//160000032
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL JORGE BASADRE GROHMANN" & year==2018 & score_raw>500

	//160000095
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE MOQUEGUA" & year==2022 & score_raw>1000
	
	//160000098
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE JULIACA" & year==2020 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE JULIACA" & year==2021 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE JULIACA" & year==2022 & score_raw>20

	//160000122
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL DE FRONTERA" & year==2023 & score_raw>20

	//160000124
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL INTERCULTURAL DE QUILLABAMBA" & year==2020 & score_raw>20
	
	//160000125
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL INTERCULTURAL DE LA SELVA CENTRAL JUAN SANTOS ATAHUALPA" & year==2018 & score_raw>20
	
	//160000127
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA ALTOANDINA DE TARMA" & year==2019 & score_raw>20	
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA ALTOANDINA DE TARMA" & year==2020 & score_raw>20	
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA ALTOANDINA DE TARMA" & year==2021 & score_raw>20	
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA ALTOANDINA DE TARMA" & year==2022 & score_raw>20	
	replace source = 1 if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA ALTOANDINA DE TARMA" & year==2023 & score_raw>20	
	
	*- Private
	
	//260000014
	replace issue = 1 if universidad == "UNIVERSIDAD PERUANA CAYETANO HEREDIA" & year==2017
	replace issue = 1 if universidad == "UNIVERSIDAD PERUANA CAYETANO HEREDIA" & year==2018
	replace issue = 1 if universidad == "UNIVERSIDAD PERUANA CAYETANO HEREDIA" & year==2019
	replace issue = 1 if universidad == "UNIVERSIDAD PERUANA CAYETANO HEREDIA" & year==2020
	replace issue = 1 if universidad == "UNIVERSIDAD PERUANA CAYETANO HEREDIA" & year==2021
	replace issue = 1 if universidad == "UNIVERSIDAD PERUANA CAYETANO HEREDIA" & year==2022
	replace source = 1 if universidad == "UNIVERSIDAD PERUANA CAYETANO HEREDIA" & year==2023 & score_raw>300
	
	//260000015
	replace issue = 1 if universidad == "UNIVERSIDAD CATÓLICA DE SANTA MARÍA"
	
	//260000019
	replace source = 1 if universidad == "UNIV DE SAN MARTÍN DE PORRES" & year==2017 & score_raw>20
	replace source = 1 if universidad == "UNIV DE SAN MARTÍN DE PORRES" & year==2018 & score_raw>20
	replace source = 1 if universidad == "UNIV DE SAN MARTÍN DE PORRES" & year==2019 & score_raw>20
	replace source = 1 if universidad == "UNIV DE SAN MARTÍN DE PORRES" & year==2020 & score_raw>20
	replace source = 1 if universidad == "UNIV DE SAN MARTÍN DE PORRES" & year==2021 & score_raw>20
	replace source = 1 if universidad == "UNIV DE SAN MARTÍN DE PORRES" & year==2022 & score_raw>20
	replace source = 1 if universidad == "UNIV DE SAN MARTÍN DE PORRES" & year==2023 & score_raw>20
	
	replace issue = 1 if universidad == "UNIV DE SAN MARTÍN DE PORRES"
	
	//260000030
	replace source = 1 if universidad == "UNIVERSIDAD RICARDO PALMA" & year==2020 & score_raw>20
	
	//260000037
	replace source = 1 if universidad == "UNIVERSIDAD PERUANA LOS ANDES" & year==2017 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD PERUANA LOS ANDES" & year==2018 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD PERUANA LOS ANDES" & year==2019 & score_raw>20
	replace issue = 1 if universidad == "UNIVERSIDAD PERUANA LOS ANDES" & year==2020 & score_raw>20

	replace source = 1 if universidad == "UNIVERSIDAD PERUANA LOS ANDES" & year==2022 & score_raw>70
	replace issue = 1 if universidad == "UNIVERSIDAD PERUANA LOS ANDES" & year==2023 & score_raw>20

	//260000039
	replace source = 1 if universidad == "UNIVERSIDAD ANDINA DEL CUSCO" & year==2020 & score_raw>150
	
	//260000040
	replace source = 1 if universidad == "UNIVERSIDAD TECNOLOGICA DE LOS ANDES" & year==2019 & score_raw>400	
	replace source = 1 if universidad == "UNIVERSIDAD TECNOLOGICA DE LOS ANDES" & year==2020 & score_raw>20	
	replace issue = 1 if universidad == "UNIVERSIDAD TECNOLOGICA DE LOS ANDES" & year==2021 
	replace issue = 1 if universidad == "UNIVERSIDAD TECNOLOGICA DE LOS ANDES" & year==2022 
	replace issue = 1 if universidad == "UNIVERSIDAD TECNOLOGICA DE LOS ANDES" & year==2023 

	//260000043
	replace issue = 1 if universidad == "UNIVERSIDAD PRIVADA DE TACNA"

	//260000046
	replace issue = 1 if universidad == "UNIVERSIDAD PRIVADA ANTENOR ORREGO"

	//260000047
	replace source = 1 if universidad == "UNIVERSIDAD DE HUANUCO" & year==2017 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD DE HUANUCO" & year==2018 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD DE HUANUCO" & year==2021 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD DE HUANUCO" & year==2022 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD DE HUANUCO" & year==2023 & score_raw>20

	//260000052
	replace issue = 1 if universidad == "UNIVERSIDAD CÉSAR VALLEJO"

	//260000054
	replace issue = 1 if universidad == "UNIVERSIDAD PERUANA DE CIENCIAS APLICADAS"

	//260000055
	replace issue = 1 if universidad == "UNIVERSIDAD PRIVADA DEL NORTE"
	
	//260000057
	replace issue = 1 if universidad == "UNIVERSIDAD SAN IGNACIO DE LOYOLA"
	
	//260000059
	replace issue = 1 if universidad == "UNIVERSIDAD ALAS PERUANAS"
	
	//260000062
	replace issue = 1 if universidad == "UNIVERSIDAD CATÓLICA SAN PABLO" & year==2017
	replace issue = 1 if universidad == "UNIVERSIDAD CATÓLICA SAN PABLO" & year==2018
	replace issue = 1 if universidad == "UNIVERSIDAD CATÓLICA SAN PABLO" & year==2019
	replace issue = 1 if universidad == "UNIVERSIDAD CATÓLICA SAN PABLO" & year==2020 
	*Rest of years look ok
	
	//260000064
	replace issue = 1 if universidad == "UNIVERSIDAD PRIVADA SAN JUAN BAUTISTA"
	
	//260000065
	replace issue = 1 if universidad == "UNIVERSIDAD TECNOLÓGICA DEL PERÚ"
	
	//260000067
	replace issue = 1 if universidad == "UNIVERSIDAD CONTINENTAL"
	replace source = 1 if universidad == "UNIVERSIDAD CONTINENTAL" & year==2018 & score_raw>20 //one case with score 125, seems like a typo
	replace source = 1 if universidad == "UNIVERSIDAD CONTINENTAL" & year==2019 & score_raw>20 & score_raw<1000 //one case with score 22.79, seems like a typo
	replace source = 1 if universidad == "UNIVERSIDAD CONTINENTAL" & year==2020 & score_raw>20 & score_raw<1000 //one case with score 22.79, seems like a typo
	replace source = 2 if universidad == "UNIVERSIDAD CONTINENTAL" & year==2020 & score_raw>1000

	//260000068
	replace source = 1 if universidad == "UNIVERSIDAD CIENTÍFICA DEL SUR" & year==2017 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD CIENTÍFICA DEL SUR" & year==2018 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD CIENTÍFICA DEL SUR" & year==2020 & score_raw>50
	
	//260000069
	replace issue = 1 if universidad == "UNIVERSIDAD CATÓLICA SANTO TORIBIO DE MOGROVEJO" & year==2017
	replace issue = 1 if universidad == "UNIVERSIDAD CATÓLICA SANTO TORIBIO DE MOGROVEJO" & year==2018
	replace issue = 1 if universidad == "UNIVERSIDAD CATÓLICA SANTO TORIBIO DE MOGROVEJO" & year==2019

	//260000071
	replace source = 1 if universidad == "UNIVERSIDAD CATÓLICA SEDES SAPIENTIAE" & year==2020 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD CATÓLICA SEDES SAPIENTIAE" & year==2021 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD CATÓLICA SEDES SAPIENTIAE" & year==2022 & score_raw>20
	replace source = 1 if universidad == "UNIVERSIDAD CATÓLICA SEDES SAPIENTIAE" & year==2023 & score_raw>20
		
	//260000074
	//replace issue = 1 if universidad == "UNIVERSIDAD CATÓLICA DE TRUJILLO BENEDICTO XVI" //almost everyone gets in. Look again later as there is some issue with figure.
	
	//260000079
	replace source = 1 if universidad == "UNIVERSIDAD ESAN" & year==2017 & score_raw>=20 //this one seems like >=20 instead of >20
	replace source = 1 if universidad == "UNIVERSIDAD ESAN" & year==2018 & score_raw>=20

	replace source = 1 if universidad == "UNIVERSIDAD ESAN" & year==2020 & score_raw>=20
	replace source = 1 if universidad == "UNIVERSIDAD ESAN" & year==2021 & score_raw>=20
	replace source = 1 if universidad == "UNIVERSIDAD ESAN" & year==2022 & score_raw>=20
	replace source = 1 if universidad == "UNIVERSIDAD ESAN" & year==2023 & score_raw>=20

	replace source = 2 if universidad == "UNIVERSIDAD ESAN" & year==2017 & score_raw==1
	replace source = 2 if universidad == "UNIVERSIDAD ESAN" & year==2018 & score_raw==1

	replace source = 2 if universidad == "UNIVERSIDAD ESAN" & year==2020 & score_raw==1
	replace source = 2 if universidad == "UNIVERSIDAD ESAN" & year==2021 & score_raw==1
	replace source = 2 if universidad == "UNIVERSIDAD ESAN" & year==2022 & score_raw==1
	replace source = 2 if universidad == "UNIVERSIDAD ESAN" & year==2023 & score_raw==1

	//260000087
	replace issue = 1 if universidad == "UNIVERSIDAD AUTÓNOMA DE ICA"
	
	//260000096
	replace issue = 1 if universidad == "UNIVERSIDAD AUTÓNOMA DEL PERU"
	
	//260000104
	replace issue = 1 if universidad == "UNIVERSIDAD LE CORDON BLEU" & year==2017
	
	//260000105
	replace issue = 1 if universidad == "UNIVERSIDAD PRIVADA DE HUANCAYO FRANKLIN ROOSEVELT"
	
	//260000114
	replace issue = 1 if universidad == "UNIVERSIDAD PERUANA AUSTRAL DEL CUSCO" & year==2019 //no other years
	
	//260000133
	replace issue = 1 if universidad == "UNIVERSIDAD LA SALLE" & year==2017 & score_raw>20
	replace issue = 1 if universidad == "UNIVERSIDAD LA SALLE" & year==2018 & score_raw>20
	replace issue = 1 if universidad == "UNIVERSIDAD LA SALLE" & year==2019 & score_raw>20
	replace issue = 1 if universidad == "UNIVERSIDAD LA SALLE" & year==2020 & score_raw>20
	replace issue = 1 if universidad == "UNIVERSIDAD LA SALLE" & year==2021 & score_raw>20
	replace issue = 1 if universidad == "UNIVERSIDAD LA SALLE" & year==2022 & score_raw>2000
	replace issue = 1 if universidad == "UNIVERSIDAD LA SALLE" & year==2023 & score_raw>20
	
	//260000136
	replace issue = 1 if universidad == "UNIVERSIDAD MARÍA AUXILIADORA"
	
	preserve
		keep if issue==1
		keep if score_raw!=.
		gen admitted = es_ingresante == "True" if es_ingresante !=""
		keep universidad codigo_modular admitted score_raw
		bys universidad: gen N=_N
		bys universidad: egen adm_z = mean(admitted)
		bys universidad: egen adm_nz = mean(cond(score_raw!=0,admitted,.))
		bys universidad: keep if _n==1
		gsort -N
		list codigo_modular universidad N adm_z adm_nz, sep(1000)
	restore
	
/*

     +-----------------------------------------------------------------------------------------------------+
     | codigo_~r                                                universidad        N      adm_z     adm_nz |
     |-----------------------------------------------------------------------------------------------------|
  1. | 260000065                           UNIVERSIDAD TECNOLÓGICA DEL PERÚ   450010   .8971801   .9909871 | 	Likely will not be saved. Too much admittance rate.
  2. | 260000052                                  UNIVERSIDAD CÉSAR VALLEJO   282437   .8179948   .9357125 |	Might be worth trying to explore
  3. | 260000055                              UNIVERSIDAD PRIVADA DEL NORTE   252421   .9702758   .9995049 |	Likely will not be saved. Too much admittance rate.
  4. | 260000054                  UNIVERSIDAD PERUANA DE CIENCIAS APLICADAS   202597   .5534189   .5899198 |	Will be saved once randomness is explained.
  5. | 260000067                                    UNIVERSIDAD CONTINENTAL   177649   .7803759   .9359584 |	ight be worth trying to explore
  6. | 260000019                               UNIV DE SAN MARTÍN DE PORRES    66726   .7688158   .7858803 |
  7. | 260000057                          UNIVERSIDAD SAN IGNACIO DE LOYOLA    58346   .7064066   .5365805 |
  8. | 260000015                        UNIVERSIDAD CATÓLICA DE SANTA MARÍA    57204   .5698203   .7336923 |
  9. | 260000059                                  UNIVERSIDAD ALAS PERUANAS    54885   .9455407   .9540687 |
 10. | 260000046                         UNIVERSIDAD PRIVADA ANTENOR ORREGO    54442   .8563058   .8744874 |
 11. | 260000064                      UNIVERSIDAD PRIVADA SAN JUAN BAUTISTA    46675   .8156186    .922773 |
 12. | 260000096                              UNIVERSIDAD AUTÓNOMA DEL PERU    28110   .9136962   .9830796 |
 13. | 260000014                       UNIVERSIDAD PERUANA CAYETANO HEREDIA    24756   .4541929   .5261768 |
 14. | 260000043                               UNIVERSIDAD PRIVADA DE TACNA    18205   .5884647   .5879074 |
 15. | 260000040                       UNIVERSIDAD TECNOLOGICA DE LOS ANDES    14146   .4397003   .4503005 |
 16. | 260000105         UNIVERSIDAD PRIVADA DE HUANCAYO FRANKLIN ROOSEVELT    12883   .8744857   .8790574 |
 17. | 260000062                             UNIVERSIDAD CATÓLICA SAN PABLO    12365    .858795   .8840737 |
 18. | 260000069            UNIVERSIDAD CATÓLICA SANTO TORIBIO DE MOGROVEJO    11284   .6640376   .6997572 |
 19. | 260000136                              UNIVERSIDAD MARÍA AUXILIADORA     9335   .7782539   .7784207 |
 20. | 260000087                                UNIVERSIDAD AUTÓNOMA DE ICA     8986   .8810372   .8882531 |
 21. | 260000037                              UNIVERSIDAD PERUANA LOS ANDES     7866   .9579201   .9579201 |
 22. | 160000025   UNIVERSIDAD NACIONAL DE EDUCACIÓN ENRIQUE GUZMÁN Y VALLE     3000   .7556667   .7852442 |
 23. | 260000133                                       UNIVERSIDAD LA SALLE     1627   .9262446   .9262446 |
 24. | 260000104                                 UNIVERSIDAD LE CORDON BLEU      603   .3963516   .7940199 |
 25. | 260000114                      UNIVERSIDAD PERUANA AUSTRAL DEL CUSCO      323   .9659443   .9689441 |
     +-----------------------------------------------------------------------------------------------------+


*/	
	
	
	*- Cutoff at exam level
	egen id_cutoff_department 	= group(codigo_modular id_anio id_periodo_postulacion facultad type_admission source)
	egen id_cutoff_major 		= group(codigo_modular id_anio id_periodo_postulacion major_c1_code type_admission source)
	
	egen id_cutoff_department_PRIOR 	= group(codigo_modular id_anio id_periodo_postulacion facultad source)
	egen id_cutoff_major_PRIOR 			= group(codigo_modular id_anio id_periodo_postulacion major_c1_code source)	

	*- 90% do have an standardized score. Among the 10%, most are because of 0's.
	//gen zero = puntaje_postulante==0
	//tab zero if score_std==.

	*- Remove 0's as that 
	clonevar score_all = score_raw //includes 0's. To estimate admission.
	replace score_raw = . if score_raw==0

	*- We check if application grade is normally distributed within college
	VarStandardiz score_raw, by(id_cutoff_department) newvar(score_std_department)
	VarStandardiz score_raw, by(id_cutoff_major) newvar(score_std_major)

	*- How many have the score of application?
	count if score_raw!=. //all of them, but many seem '0', probably unreported
	sum score_std_department
	di r(N)/_N*100
	
	sum score_std_major
	di r(N)/_N*100
	

	*- Rank score
	bys id_cutoff_department: 	egen rank_score_raw_department = rank(score_raw), track
	bys id_cutoff_major: 		egen rank_score_raw_major = rank(score_raw), track

	*- How strict are the cutoffs?
	//bys id_cutoff : egen cutoff = min(cond(es_ingresante=="True",puntaje_postulante_std,.))
	//gen simulated = puntaje_postulante_std>=cutoff if puntaje_postulante_std!=. & cutoff!=.

	*- How can we define alternative cutoff that is not minimum?
	//gen cutoff2 = cutoff+0.5
	//gen simulated2 = puntaje_postulante_std>=cutoff2 if puntaje_postulante_std!=. & cutoff2!=.

	*- admitted student
	gen admitted = es_ingresante == "True" if es_ingresante !=""
	
	*- First semester of application
	bys id_persona_rec (semester): gen first_sem_application = semester==semester[1]
	
	*- First semester of application
	bys id_persona_rec: 			gen one_application 				= (_N==1)
	bys id_persona_rec semester: 	gen one_application_semester 		= (_N==1)
	
	*- Match Family info
	/*
	merge m:1 id_per_umc using "$TEMP\id_siblings",keepusing(id_fam_4 fam_order_4 fam_total_4) keep(master match)
	rename _m merge_siblings
	*/
	
	*- Label
	label var id_cutoff_department 			"Unique ID of application cutoff (department)"
	label var id_cutoff_major 				"Unique ID of application cutoff (major)"
	label var score_std_department 			"Standardized Score of application cutoff (department)"
	label var score_std_major 				"Standardized Score of application cutoff (major)"
	label var rank_score_raw_department 	"Ranked score raw (1=Lowest) (department)"
	label var rank_score_raw_major 			"Ranked score raw (1=Lowest) (major)"
	label var admitted 						"Was admitted to cutoff"
	label var first_sem_application			"First Semester Applying"
	label var one_application				"Only applied once"
	label var one_application_semester		"Only applied once in the semester"

	label values admitted yes_no
	
	label values codigo_modular universidad_cod


		isvar 			///
			/*Match ID*/ id_per_umc id_persona_rec id_per_pos ///
			/*ID*/ year id_cutoff_department* id_cutoff_major* codigo_modular /*id_anio*/ id_codigo_facultad id_carrera id_carrera_homologada id_estado_persona id_periodo_postulacion  id_periodo_matricula semester	/*universidad*/ facultad ///
			/*Char UNI*/ university public licensed academic	region	///
			/*Char Indiv*/ 	dob age male	///
			/*applic info*/ major_c1_cat* major_c1_code major_c1_name major_c1_inei_code major_c2_code major_c2_name major_c2_inei_code   /*id_major* name_major* carrera_primera_opcion*/ score_raw score_std* rank_score_raw*	first_sem_application one_application* source issue 	///
			/*admitt info*/ major_admit_inei_code admitted ///
			/*enroll info*/ nota_promedio ///
			/*Family Info*/ /*educ_caretaker educ_mother educ_father*/ id_fam_4 fam_order_4 fam_total_4 ///
			/*NEW VARS*/ codigo_ubigeo duracion_carrera type_in_person type_admission type_const id_ie
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'

		foreach v of local all_vars {
			capture confirm string variable `v'
				if _rc==0 {
					   replace `v' = trim(itrim(`v'))
				}
		}
		
		*Destring those not IDs
		ds /*id_per_umc*/ id_persona_rec codigo_modular id_ie, not
		local all_vars = r(varlist)
		destring `all_vars', replace
					
		compress
		
	if ${test}==1 save "$TEMP\applied_TEST", replace
	if ${test}==0 save "$TEMP\applied", replace	

end


********************************************************************************
* Enrolled
********************************************************************************

capture program drop enrolled
program define enrolled

	if ${excel} == 1 & ${test}==0 & ${new}==0  {
		import delimited "$IN\MINEDU\ECE EM innominada\SIRIES\matriculados_INNOM.txt", clear
		compress
	}	
	
	if ${excel} == 1 & ${test}==1 & ${new}==0  {
		import delimited "$IN\MINEDU\ECE EM innominada\SIRIES\matriculados_INNOM.txt", clear
		gen u=runiform()
		keep if u<0.01
		drop u
		compress		
		save "$TEMP\enrolled_raw_TEST", replace
	}
	
	if ${excel} == 1 & ${test}==0 & ${new}==1 {
		import delimited "$IN\MINEDU\Entrega-2\db_matriculados.csv", clear
		compress		
	}
	
	if ${excel} == 1 & ${test}==1 & ${new}==1 {
		import delimited "$IN\MINEDU\Entrega-2\db_matriculados.csv", clear
		keep if runiform()<0.01
		compress		
		save "$TEMP\enrolled_raw_new_TEST", replace
	}
		
	
	
	
	if ${excel} == 0 & ${test}==1 & ${new}==0 {
		use "$TEMP\enrolled_raw_TEST", clear
	}
	
	if ${excel} == 0 & ${test}==1 & ${new}==1 {
		use "$TEMP\enrolled_raw_new_TEST", clear
	}	

	if ${excel} == 0 & ${test}==0 {
		assert 1==0 //we don't save the raw in DTA
	}	
	
	*- Rename new variables that are also present in old database
	if ${new}==1 {
		
		*- Rename to common prior name
		rename (tipo_institucion 	tipo_gestion 	id_persona) (id_tipo_institucion id_tipo_gestion id_persona_rec)	
		
		*- Create categorical var as before (but not same value)
		egen id_anio = group(abreviatura_anio)
		egen id_periodo_matricula = group(periodo_matricula)		
	}
			
	
		
	
	rename abreviatura_anio year
	
	isvar 			///
		/*Match ID*/ id_per_umc id_persona_rec ///
		/*ID*/ codigo_modular id_tipo_institucion id_tipo_gestion id_anio id_codigo_facultad id_carrera_primera_opcion /*id_carrera_homologada_primera_op*/ id_estado_persona id_periodo_postulacion periodo_postulacion id_periodo_matricula periodo_matricula	universidad year ///
		/*Char UNI*/ estatus_licenciamiento		///
		/*Char Indiv*/ 	fecha_nacimiento edad sexo	///
		/*applic info*/ carrera_primera_opcion		///
		/*admitt info*/ es_ingresante carrera_ingreso ///
		/*enroll info*/ nota_promedio id_carrera nombre_carrera codigo_carrera_inei nombre_carrera_inei codigo1_c2018 codigo3_c2018 codigo6_c2018 facultad ///
		/*NEW VARS*/ codigo_ubigeo departamento provincia distrito modalidad_admis modalidad_admision duracion_carrera modalidad_estudio modalidad_juridica modalidad_constitucion codigo_modular_colegio nro_creditos periodo_ingreso periodo_primera_matricula
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'

		foreach v of local all_vars {
			capture confirm string variable `v'
				if _rc==0 {
					   replace `v' = trim(itrim(`v'))
				}
		}
		
		*Destring those not IDs
		ds id_per_umc id_persona_rec codigo_modular, not
		local all_vars = r(varlist)
		destring `all_vars', replace
					
		compress

	define_labels
	
	
	*-----------------
	*- NEW VARIABLES
	*-----------------
	
	if ${new} == 1 {
		*- Region
		gen ubigeo = string(codigo_ubigeo)
		replace ubigeo = "0" + ubigeo if strlen(ubigeo)<6
		gen region = substr(ubigeo,1,2)
		destring region, replace
		drop ubigeo
		
		*- Modalidad estudio
		gen type_in_person = .
		replace type_in_person = 1 if modalidad_estudio == "Presencial"
		replace type_in_person = 2 if modalidad_estudio == "Semi-presencial"
		replace type_in_person = 3 if modalidad_estudio == "Virtual"
		replace type_in_person = 4 if modalidad_estudio == "A distancia"
		replace type_in_person = 5 if modalidad_estudio == "No aplica"
		label values type_in_person type_in_person
		
		*- Modalidad Juridica
		ds modalidad_juridica
		
		*- Modalidad Constitucion
		gen type_const = .
		replace type_const = 1 if modalidad_constitucion == "PÚBLICAS INSTITUCIONALIZADAS"
		replace type_const = 2 if modalidad_constitucion == "PÚBLICAS CON COMISIÓN ORGANIZADORA"
		replace type_const = 3 if modalidad_constitucion == "PRIVADAS SOCIETARIAS"
		replace type_const = 4 if modalidad_constitucion == "PRIVADAS ASOCIATIVAS"
		label values type_const type_const
		
		*- Nro Creditos
		rename nro_creditos n_credits 
		label var n_credits "Total Cumulative Credits" 
		
		*- Periodo ingreso
		rename periodo_ingreso semester_admitted
		label var semester_admitted "Semester admitted" 
		
		*- Periodo primera matricula
		rename periodo_primera_matricula semester_first_enrolled
		label var semester_first_enrolled "Semester first enrolled"	
	}
	
	*-----------------
	*- OLD VARIABLES
	*-----------------		
	
		
	*- Male
	gen male = 1 if sexo=="MASCULINO" 
	replace male = 0 if sexo=="FEMENINO" 
	label var male "Sex: Male"
	label define male 0 "female" 1 "male", replace
	label values male male
	
	*- Institution type
	gen university = 1 if id_tipo_institucion=="UNIVERSIDADES" 
	replace university = 0 if id_tipo_institucion!="UNIVERSIDADES" & id_tipo_institucion!=""
	label var university "Type: University"
	label define university 0 "Other" 1 "University", replace
	label values university university		
	
	*- Public
	gen public = 1 if inlist(id_tipo_gestion,"PUBLICA", "PÚBLICA")==1
	replace public = 0 if id_tipo_gestion=="PRIVADA" 
	label var public "Administration: Public"
	label values public public			
	
	*- Licensed
	gen licensed = 1 if estatus_licenciamiento=="LICENCIADA" 
	replace licensed = 0 if estatus_licenciamiento=="LICENCIA DENEGADA" 
	label var licensed "Status: Licensed"
	label define licensed 0 "License Denied" 1 "Licensed", replace
	label values licensed licensed		
	
	*- Major
	rename codigo1_c2018 major_cat 
	rename codigo3_c2018 major_c1_cat3
	rename codigo6_c2018 major_c1_cat6
	capture label drop major_cat
	label define major_cat 0 "SERVICIOS" 1 "EDUCACIÓN" 2 "ARTE Y HUMANIDADES" 3 "CIENCIAS SOCIALES, PERIODISMO E INFORMACIÓN" 4 "CIENCIAS ADMINISTRATIVAS Y DERECHO" 5 "CIENCIAS NATURALES, MATEMÁTICAS Y ESTADÍSTICA" 6 "TECNOLOGÍA DE LA INFORMACIÓN Y LA COMUNICACIÓN" 7 "INGENIERÍA, INDUSTRIA Y CONSTRUCCIÓN" 8 "AGRICULTURA, SILVICULTURA, PESCA Y VETERINARIA" 9 "SALUD Y BIENESTAR", replace
	label values major_cat major_cat

	rename nombre_carrera 			major_name
	rename nombre_carrera_inei 		major_inei_name
	rename id_carrera 				major_code
	rename codigo_carrera_inei 		major_inei_code
	rename periodo_matricula		semester
	gen dob = date(fecha_nacimiento, "YMD") 
	format %td dob
	rename edad age
	

	*- Region
	if ${new} == 0 {
	gen region = .
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS"
	replace region = 5 	if universidad == "UNIVERSIDAD NACIONAL DE SAN CRISTÓBAL DE HUAMANGA"
	replace region = 8 	if universidad == "UNIVERSIDAD NACIONAL DE SAN ANTONIO ABAD DEL CUSCO"
	replace region = 13 if universidad == "UNIVERSIDAD NACIONAL DE TRUJILLO"
	replace region = 4 	if universidad == "UNIVERSIDAD NACIONAL DE SAN AGUSTÍN"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE INGENIERÍA"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL AGRARIA LA MOLINA"
	replace region = 11 if universidad == "UNIVERSIDAD NACIONAL SAN LUIS GONZAGA DE ICA"
	replace region = 12 if universidad == "UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ"
	replace region = 16 if universidad == "UNIVERSIDAD NACIONAL DE LA AMAZONÍA PERUANA"
	replace region = 21 if universidad == "UNIVERSIDAD NACIONAL DEL ALTIPLANO"
	replace region = 20 if universidad == "UNIVERSIDAD NACIONAL DE PIURA"
	replace region = 6 	if universidad == "UNIVERSIDAD NACIONAL DE CAJAMARCA"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL FEDERICO VILLARREAL"
	replace region = 10 if universidad == "UNIVERSIDAD NACIONAL AGRARIA DE LA SELVA"
	replace region = 10 if universidad == "UNIVERSIDAD NACIONAL HERMILIO VALDIZAN"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE EDUCACIÓN ENRIQUE GUZMÁN Y VALLE"
	replace region = 19 if universidad == "UNIVERSIDAD NACIONAL DANIEL ALCIDES CARRIÓN"
	replace region = 7 	if universidad == "UNIVERSIDAD NACIONAL DEL CALLAO"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL JOSÉ FAUSTINO SÁNCHEZ CARRIÓN"
	replace region = 14 if universidad == "UNIVERSIDAD NACIONAL PEDRO RUÍZ GALLO"
	replace region = 23 if universidad == "UNIVERSIDAD NACIONAL JORGE BASADRE GROHMANN"
	replace region = 2 	if universidad == "UNIVERSIDAD NACIONAL SANTIAGO ANTÚNEZ DE MAYOLO"
	replace region = 22 if universidad == "UNIVERSIDAD NACIONAL DE SAN MARTÍN"
	replace region = 25 if universidad == "UNIVERSIDAD NACIONAL DE UCAYALI"
	replace region = 24 if universidad == "UNIVERSIDAD NACIONAL DE TUMBES"
	replace region = 2 	if universidad == "UNIVERSIDAD NACIONAL DEL SANTA"
	replace region = 9 	if universidad == "UNIVERSIDAD NACIONAL DE HUANCAVELICA"
	replace region = 17 if universidad == "UNIVERSIDAD NACIONAL AMAZÓNICA DE MADRE DE DIOS"
	replace region = 1 	if universidad == "UNIVERSIDAD NACIONAL TORIBIO RODRÍGUEZ DE MENDOZA DE AMAZONAS"
	replace region = 3 	if universidad == "UNIVERSIDAD NACIONAL MICAELA BASTIDAS DE APURIMAC"
	replace region = 25 if universidad == "UNIVERSIDAD NACIONAL INTERCULTURAL DE LA AMAZONIA"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL TECNOLÓGICA DE LIMA SUR"
	replace region = 3 	if universidad == "UNIVERSIDAD NACIONAL JOSE MARIA ARGUEDAS"
	replace region = 18 if universidad == "UNIVERSIDAD NACIONAL DE MOQUEGUA"
	replace region = 21 if universidad == "UNIVERSIDAD NACIONAL DE JULIACA"
	replace region = 6 	if universidad == "UNIVERSIDAD NACIONAL DE JAÉN"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE CAÑETE"
	replace region = 6 	if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA DE CHOTA"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE BARRANCA"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE FRONTERA"
	replace region = 1 	if universidad == `""UNIVERSIDAD NACIONAL INTERCULTURAL ""FABIOLA SALAZAR LEGUÍA"" DE BAGUA""'
	replace region = 12 if universidad == "UNIVERSIDAD NACIONAL INTERCULTURAL DE LA SELVA CENTRAL JUAN SANTOS ATAHUALPA"
	replace region = 8 	if universidad == "UNIVERSIDAD NACIONAL INTERCULTURAL DE QUILLABAMBA"
	replace region = 16 if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA DE ALTO AMAZONAS"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA ALTOANDINA DE TARMA"
	replace region = 5 	if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA DE HUANTA"
	replace region = 9 	if universidad == `""UNIVERSIDAD NACIONAL AUTÓNOMA DE TAYACAJA ""DANIEL HERNÁNDEZ MORILLO""""'
	replace region = 15 if universidad == "PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA CAYETANO HEREDIA"
	replace region = 4 	if universidad == "UNIVERSIDAD CATÓLICA DE SANTA MARÍA"
	replace region = 15 if universidad == "UNIVERSIDAD DEL PACÍFICO"
	replace region = 15 if universidad == "UNIVERSIDAD DE LIMA"
	replace region = 15 if universidad == "UNIV DE SAN MARTÍN DE PORRES"
	replace region = 15 if universidad == "UNIVERSIDAD FEMENINA DEL SAGRADO CORAZÓN"
	replace region = 15 if universidad == "UNIVERSIDAD INCA GARCILASO DE LA VEGA"
	replace region = 20 if universidad == "UNIVERSIDAD DE PIURA"
	replace region = 15 if universidad == "UNIVERSIDAD RICARDO PALMA"
	replace region = 21 if universidad == "UNIVERSIDAD ANDINA NÉSTOR CÁCERES VELÁSQUEZ"
	replace region = 12 if universidad == "UNIVERSIDAD PERUANA LOS ANDES"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA UNIÓN"
	replace region = 8 	if universidad == "UNIVERSIDAD ANDINA DEL CUSCO"
	replace region = 3 	if universidad == "UNIVERSIDAD TECNOLOGICA DE LOS ANDES"
	replace region = 23 if universidad == "UNIVERSIDAD PRIVADA DE TACNA"
	replace region = 14 if universidad == "UNIVERSIDAD PARTICULAR DE CHICLAYO"
	replace region = 2 	if universidad == "UNIVERSIDAD SAN PEDRO"
	replace region = 13 if universidad == "UNIVERSIDAD PRIVADA ANTENOR ORREGO"
	replace region = 10 if universidad == "UNIVERSIDAD DE HUANUCO"
	replace region = 18 if universidad == "UNIVERSIDAD JOSÉ CARLOS MARIÁTEGUI"
	replace region = 15 if universidad == "UNIVERSIDAD MARCELINO CHAMPAGNAT"
	replace region = 16 if universidad == "UNIVERSIDAD CIENTÍFICA DEL PERÚ - UCP"
	replace region = 13 if universidad == "UNIVERSIDAD CÉSAR VALLEJO"
	replace region = 2 	if universidad == "UNIVERSIDAD CATÓLICA LOS ÁNGELES DE CHIMBOTE"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE CIENCIAS APLICADAS"
	replace region = 13 if universidad == "UNIVERSIDAD PRIVADA DEL NORTE"
	replace region = 15 if universidad == "UNIVERSIDAD SAN IGNACIO DE LOYOLA"
	replace region = 99 if universidad == "UNIVERSIDAD ALAS PERUANAS"
	replace region = 15 if universidad == "UNIVERSIDAD NORBERT WIENER"
	replace region = 4 	if universidad == "UNIVERSIDAD CATÓLICA SAN PABLO"
	replace region = 11 if universidad == "UNIVERSIDAD PRIVADA DE ICA"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA SAN JUAN BAUTISTA"
	replace region = 99 if universidad == "UNIVERSIDAD TECNOLÓGICA DEL PERÚ"
	replace region = 99 if universidad == "UNIVERSIDAD CONTINENTAL"
	replace region = 15 if universidad == "UNIVERSIDAD CIENTÍFICA DEL SUR"
	replace region = 14 if universidad == "UNIVERSIDAD CATÓLICA SANTO TORIBIO DE MOGROVEJO"
	replace region = 6 	if universidad == "UNIVERSIDAD PRIVADA ANTONIO GUILLERMO URRELO"
	replace region = 99 if universidad == "UNIVERSIDAD CATÓLICA SEDES SAPIENTIAE"
	replace region = 14 if universidad == "UNIVERSIDAD SEÑOR DE SIPÁN"
	replace region = 13 if universidad == "UNIVERSIDAD CATÓLICA DE TRUJILLO BENEDICTO XVI"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE LAS AMÉRICAS"
	replace region = 15 if universidad == "UNIVERSIDAD ESAN"
	replace region = 15 if universidad == "UNIVERSIDAD ANTONIO RUIZ DE MONTOYA"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE CIENCIA E INFORMÁTICA"
	replace region = 9 	if universidad == "UNIVERSIDAD PARA EL DESARROLLO ANDINO"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA TELESUP"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA SERGIO BERNALES"
	replace region = 99 if universidad == "UNIVERSIDAD PRIVADA DE PUCALLPA"
	replace region = 11 if universidad == "UNIVERSIDAD AUTÓNOMA DE ICA"
	replace region = 13 if universidad == "UNIVERSIDAD PRIVADA DE TRUJILLO"
	replace region = 21 if universidad == "UNIVERSIDAD PRIVADA SAN CARLOS"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA SIMÓN BOLÍVAR"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE INTEGRACIÓN GLOBAL"
	replace region = 16 if universidad == "UNIVERSIDAD PERUANA DEL ORIENTE"
	replace region = 15 if universidad == "UNIVERSIDAD AUTÓNOMA DEL PERU"
	replace region = 15 if universidad == "UNIVERSIDAD DE CIENCIAS Y HUMANIDADES"
	replace region = 14 if universidad == "UNIVERSIDAD PRIVADA JUAN MEJÍA BACA"
	replace region = 15 if universidad == "UNIVERSIDAD JAIME BAUSATE Y MEZA"
	replace region = 12 if universidad == "UNIVERSIDAD PERUANA DEL CENTRO"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA ARZOBISPO LOAYZA"
	replace region = 15 if universidad == "UNIVERSIDAD LE CORDON BLEU"
	replace region = 12 if universidad == "UNIVERSIDAD PRIVADA DE HUANCAYO FRANKLIN ROOSEVELT"
	replace region = 14 if universidad == "UNIVERSIDAD DE LAMBAYEQUE"
	replace region = 15 if universidad == "UNIVERSIDAD DE CIENCIAS Y ARTES DE AMÉRICA LATINA"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE ARTE ORVAL"
	replace region = 16 if universidad == "UNIVERSIDAD PRIVADA DE LA SELVA PERÚANA"
	replace region = 4 	if universidad == "UNIVERSIDAD CIENCIAS DE LA SALUD"
	replace region = 5 	if universidad == "UNIVERSIDAD DE AYACUCHO FEDERICO FROEBEL"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE INVESTIGACIÓN Y NEGOCIOS"
	replace region = 8 	if universidad == "UNIVERSIDAD PERUANA AUSTRAL DEL CUSCO"
	replace region = 4 	if universidad == "UNIVERSIDAD AUTÓNOMA SAN FRANCISCO"
	replace region = 15 if universidad == "UNIVERSIDAD SAN ANDRÉS"
	replace region = 15 if universidad == "UNIVERSIDAD INTERAMÉRICANA PARA EL DESARROLLO"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA JUAN PABLO II"
	replace region = 13 if universidad == "UNIVERSIDAD PRIVADA LEONARDO DA VINCI"
	replace region = 15 if universidad == "UTEC"
	replace region = 4 	if universidad == "UNIVERSIDAD LA SALLE"
	replace region = 23 if universidad == "UNIVERSIDAD LATINOAMERICANA CIMA"
	replace region = 4 	if universidad == "UNIVERSIDAD PRIVADA AUTÓNOMA DEL SUR"
	replace region = 15 if universidad == "UNIVERSIDAD MARÍA AUXILIADORA"
	replace region = 1 	if universidad == "UNIVERSIDAD POLITÉCNICA AMAZÓNICA"
	replace region = 15 if universidad == "UNIVERSIDAD SANTO DOMINGO DE GUZMÁN SAC"
	replace region = 7 	if universidad == "UNIVERSIDAD MARÍTIMA DEL PERÚ"
	replace region = 8 	if universidad == "UNIVERSIDAD PRIVADA LIDER PERUANA"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA PERUANO ALEMANA"
	replace region = 8 	if universidad == "UNIVERSIDAD GLOBAL DEL CUSCO"
	replace region = 12 if universidad == "UST UNIVERSIDAD SANTO TOMÁS"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA SISE"
	replace region = 15 if universidad == "FACULTAD DE TEOLOGÍA PONTIFICIA Y CIVIL DE LIMA"
	replace region = 15 if universidad == "UNIVERSIDAD SEMINARIO BÍBLICO ANDINO"
	replace region = 15 if universidad == "UNIVERSIDAD SEMINARIO EVANGÉLICO DE LIMA"
	}
	
	
	
	label values region dep
	
	label values codigo_modular universidad_cod
	
	*- Average Grade
	destring nota_promedio, replace
	VarStandardiz nota_promedio, by(universidad facultad major_inei_code id_anio) newvar(score_std_uni)
	
	

	isvar 			///
		/*Match ID*/ id_per_umc id_persona_rec ///
		/*ID*/ codigo_modular  id_anio id_codigo_facultad id_carrera_primera_opcion /*id_carrera_homologada_primera_op*/ id_estado_persona id_periodo_postulacion  id_periodo_matricula semester		year  ///
		/*Char UNI*/ licensed	public academic university	region ///
		/*Char Indiv*/ 	dob age male ///
		/*applic info*/ carrera_primera_opcion		///
		/*admitt info*/ es_ingresante carrera_ingreso ///
		/*enroll info*/ score_std_uni major_inei_name /*universidad*/ facultad major_code major_inei_code major_cat* ///
		/*NEW VARS*/ codigo_ubigeo duracion_carrera type_admission type_in_person type_const id_ie n_credits semester_admitted semester_first_enrolled 
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'

		foreach v of local all_vars {
			capture confirm string variable `v'
				if _rc==0 {
					   replace `v' = trim(itrim(`v'))
				}
		}
		
		*Destring those not IDs
		ds id_per_umc id_persona_rec codigo_modular, not
		local all_vars = r(varlist)
		destring `all_vars', replace
					
		compress
	
	if ${test}==1 save "$TEMP\enrolled_TEST", replace	
	if ${test}==0 save "$TEMP\enrolled", replace 
	
	
end	




********************************************************************************
* Graduated
********************************************************************************

capture program drop graduated
program define graduated


	if ${excel} == 1 & ${test}==0 & ${new}==1 {
		import delimited "$IN\MINEDU\Entrega-2\db_egresados.csv", clear
		compress		
	}
	
	if ${excel} == 1 & ${test}==1 & ${new}==1 {
		import delimited "$IN\MINEDU\Entrega-2\db_egresados.csv", clear
		keep if runiform()<0.01
		compress		
		save "$TEMP\graduated_raw_new_TEST", replace
	}

	if ${excel} == 0 & ${test}==1 & ${new}==1 {
		use "$TEMP\graduated_raw_new_TEST", clear
	}	

	if ${excel} == 0 & ${test}==0 {
		assert 1==0 //we don't save the raw in DTA
	}	
	
	*- Rename new variables that are also present in old database
	if ${new}==1 {
		
		*- Rename to common prior name
		rename (tipo_institucion 	tipo_gestion 	id_persona) (id_tipo_institucion id_tipo_gestion id_persona_rec)	
		
		*- Create categorical var as before (but not same value)
		egen id_anio = group(abreviatura_anio)
		egen id_periodo_egreso = group(periodo_egreso)		
	}
			
	
		
	
	rename abreviatura_anio year
	
	isvar 			///
		/*Match ID*/ id_per_umc id_persona_rec ///
		/*ID*/ codigo_modular id_tipo_institucion id_tipo_gestion id_anio id_codigo_facultad id_carrera_primera_opcion /*id_carrera_homologada_primera_op*/ id_estado_persona id_periodo_postulacion periodo_postulacion id_periodo_matricula periodo_matricula	universidad year ///
		/*Char UNI*/ estatus_licenciamiento		///
		/*Char Indiv*/ 	fecha_nacimiento edad sexo	///
		/*applic info*/ carrera_primera_opcion		///
		/*admitt info*/ es_ingresante carrera_ingreso ///
		/*enroll info*/ nota_promedio id_carrera nombre_carrera codigo_carrera_inei nombre_carrera_inei codigo1_c2018 codigo3_c2018 codigo6_c2018 facultad ///
		/*NEW VARS*/ codigo_ubigeo departamento provincia distrito modalidad_admis modalidad_admision duracion_carrera modalidad_estudio modalidad_juridica modalidad_constitucion codigo_modular_colegio nro_creditos periodo_ingreso periodo_primera_matricula carrera duracion_carrera id_periodo_egreso periodo_egreso carrera
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'

		foreach v of local all_vars {
			capture confirm string variable `v'
				if _rc==0 {
					   replace `v' = trim(itrim(`v'))
				}
		}
		
		*Destring those not IDs
		ds id_per_umc id_persona_rec codigo_modular, not
		local all_vars = r(varlist)
		destring `all_vars', replace
					
		compress

	define_labels
	
	
	*-----------------
	*- NEW VARIABLES
	*-----------------
	
	if ${new} == 1 {
		*- Region
		gen ubigeo = string(codigo_ubigeo)
		replace ubigeo = "0" + ubigeo if strlen(ubigeo)<6
		gen region = substr(ubigeo,1,2)
		destring region, replace
		drop ubigeo
		
		*- Modalidad Juridica
		ds modalidad_juridica
		
		*- Modalidad Constitucion
		gen type_const = .
		replace type_const = 1 if modalidad_constitucion == "PÚBLICAS INSTITUCIONALIZADAS"
		replace type_const = 2 if modalidad_constitucion == "PÚBLICAS CON COMISIÓN ORGANIZADORA"
		replace type_const = 3 if modalidad_constitucion == "PRIVADAS SOCIETARIAS"
		replace type_const = 4 if modalidad_constitucion == "PRIVADAS ASOCIATIVAS"
		label values type_const type_const
		
		
		
		*- Periodo ingreso
		rename periodo_ingreso semester_admitted
		label var semester_admitted "Semester admitted" 
		
		*- Periodo primera matricula
		rename periodo_primera_matricula semester_first_enrolled
		label var semester_first_enrolled "Semester first enrolled"	
		
		*- Periodo Graduacion
		rename periodo_egreso semester_graduated
		label var semester_graduated "Semester graduated"			
	}
	
	*-----------------
	*- OLD VARIABLES
	*-----------------		
	
		
	*- Male
	gen male = 1 if sexo=="MASCULINO" 
	replace male = 0 if sexo=="FEMENINO" 
	label var male "Sex: Male"
	label define male 0 "female" 1 "male", replace
	label values male male
	
	*- Institution type
	gen university = 1 if id_tipo_institucion=="UNIVERSIDADES" 
	replace university = 0 if id_tipo_institucion!="UNIVERSIDADES" & id_tipo_institucion!=""
	label var university "Type: University"
	label define university 0 "Other" 1 "University", replace
	label values university university		
	
	*- Public
	gen public = 1 if inlist(id_tipo_gestion,"PUBLICA", "PÚBLICA")==1
	replace public = 0 if id_tipo_gestion=="PRIVADA" 
	label var public "Administration: Public"
	label values public public			
	
	*- Licensed
	gen licensed = 1 if estatus_licenciamiento=="LICENCIADA" 
	replace licensed = 0 if estatus_licenciamiento=="LICENCIA DENEGADA" 
	label var licensed "Status: Licensed"
	label define licensed 0 "License Denied" 1 "Licensed", replace
	label values licensed licensed		
	
	*- Major
	rename codigo1_c2018 major_cat 
	rename codigo3_c2018 major_c1_cat3
	rename codigo6_c2018 major_c1_cat6
	capture label drop major_cat
	label define major_cat 0 "SERVICIOS" 1 "EDUCACIÓN" 2 "ARTE Y HUMANIDADES" 3 "CIENCIAS SOCIALES, PERIODISMO E INFORMACIÓN" 4 "CIENCIAS ADMINISTRATIVAS Y DERECHO" 5 "CIENCIAS NATURALES, MATEMÁTICAS Y ESTADÍSTICA" 6 "TECNOLOGÍA DE LA INFORMACIÓN Y LA COMUNICACIÓN" 7 "INGENIERÍA, INDUSTRIA Y CONSTRUCCIÓN" 8 "AGRICULTURA, SILVICULTURA, PESCA Y VETERINARIA" 9 "SALUD Y BIENESTAR", replace
	label values major_cat major_cat

	rename carrera 					major_name
	rename nombre_carrera_inei 		major_inei_name
	rename id_carrera 				major_code
	rename codigo_carrera_inei 		major_inei_code
	//rename periodo_matricula		semester
	gen dob = date(fecha_nacimiento, "YMD") 
	format %td dob
	rename edad age
	

	*- Region
	if ${new} == 0 {
	gen region = .
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS"
	replace region = 5 	if universidad == "UNIVERSIDAD NACIONAL DE SAN CRISTÓBAL DE HUAMANGA"
	replace region = 8 	if universidad == "UNIVERSIDAD NACIONAL DE SAN ANTONIO ABAD DEL CUSCO"
	replace region = 13 if universidad == "UNIVERSIDAD NACIONAL DE TRUJILLO"
	replace region = 4 	if universidad == "UNIVERSIDAD NACIONAL DE SAN AGUSTÍN"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE INGENIERÍA"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL AGRARIA LA MOLINA"
	replace region = 11 if universidad == "UNIVERSIDAD NACIONAL SAN LUIS GONZAGA DE ICA"
	replace region = 12 if universidad == "UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ"
	replace region = 16 if universidad == "UNIVERSIDAD NACIONAL DE LA AMAZONÍA PERUANA"
	replace region = 21 if universidad == "UNIVERSIDAD NACIONAL DEL ALTIPLANO"
	replace region = 20 if universidad == "UNIVERSIDAD NACIONAL DE PIURA"
	replace region = 6 	if universidad == "UNIVERSIDAD NACIONAL DE CAJAMARCA"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL FEDERICO VILLARREAL"
	replace region = 10 if universidad == "UNIVERSIDAD NACIONAL AGRARIA DE LA SELVA"
	replace region = 10 if universidad == "UNIVERSIDAD NACIONAL HERMILIO VALDIZAN"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE EDUCACIÓN ENRIQUE GUZMÁN Y VALLE"
	replace region = 19 if universidad == "UNIVERSIDAD NACIONAL DANIEL ALCIDES CARRIÓN"
	replace region = 7 	if universidad == "UNIVERSIDAD NACIONAL DEL CALLAO"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL JOSÉ FAUSTINO SÁNCHEZ CARRIÓN"
	replace region = 14 if universidad == "UNIVERSIDAD NACIONAL PEDRO RUÍZ GALLO"
	replace region = 23 if universidad == "UNIVERSIDAD NACIONAL JORGE BASADRE GROHMANN"
	replace region = 2 	if universidad == "UNIVERSIDAD NACIONAL SANTIAGO ANTÚNEZ DE MAYOLO"
	replace region = 22 if universidad == "UNIVERSIDAD NACIONAL DE SAN MARTÍN"
	replace region = 25 if universidad == "UNIVERSIDAD NACIONAL DE UCAYALI"
	replace region = 24 if universidad == "UNIVERSIDAD NACIONAL DE TUMBES"
	replace region = 2 	if universidad == "UNIVERSIDAD NACIONAL DEL SANTA"
	replace region = 9 	if universidad == "UNIVERSIDAD NACIONAL DE HUANCAVELICA"
	replace region = 17 if universidad == "UNIVERSIDAD NACIONAL AMAZÓNICA DE MADRE DE DIOS"
	replace region = 1 	if universidad == "UNIVERSIDAD NACIONAL TORIBIO RODRÍGUEZ DE MENDOZA DE AMAZONAS"
	replace region = 3 	if universidad == "UNIVERSIDAD NACIONAL MICAELA BASTIDAS DE APURIMAC"
	replace region = 25 if universidad == "UNIVERSIDAD NACIONAL INTERCULTURAL DE LA AMAZONIA"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL TECNOLÓGICA DE LIMA SUR"
	replace region = 3 	if universidad == "UNIVERSIDAD NACIONAL JOSE MARIA ARGUEDAS"
	replace region = 18 if universidad == "UNIVERSIDAD NACIONAL DE MOQUEGUA"
	replace region = 21 if universidad == "UNIVERSIDAD NACIONAL DE JULIACA"
	replace region = 6 	if universidad == "UNIVERSIDAD NACIONAL DE JAÉN"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE CAÑETE"
	replace region = 6 	if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA DE CHOTA"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE BARRANCA"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL DE FRONTERA"
	replace region = 1 	if universidad == `""UNIVERSIDAD NACIONAL INTERCULTURAL ""FABIOLA SALAZAR LEGUÍA"" DE BAGUA""'
	replace region = 12 if universidad == "UNIVERSIDAD NACIONAL INTERCULTURAL DE LA SELVA CENTRAL JUAN SANTOS ATAHUALPA"
	replace region = 8 	if universidad == "UNIVERSIDAD NACIONAL INTERCULTURAL DE QUILLABAMBA"
	replace region = 16 if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA DE ALTO AMAZONAS"
	replace region = 15 if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA ALTOANDINA DE TARMA"
	replace region = 5 	if universidad == "UNIVERSIDAD NACIONAL AUTÓNOMA DE HUANTA"
	replace region = 9 	if universidad == `""UNIVERSIDAD NACIONAL AUTÓNOMA DE TAYACAJA ""DANIEL HERNÁNDEZ MORILLO""""'
	replace region = 15 if universidad == "PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA CAYETANO HEREDIA"
	replace region = 4 	if universidad == "UNIVERSIDAD CATÓLICA DE SANTA MARÍA"
	replace region = 15 if universidad == "UNIVERSIDAD DEL PACÍFICO"
	replace region = 15 if universidad == "UNIVERSIDAD DE LIMA"
	replace region = 15 if universidad == "UNIV DE SAN MARTÍN DE PORRES"
	replace region = 15 if universidad == "UNIVERSIDAD FEMENINA DEL SAGRADO CORAZÓN"
	replace region = 15 if universidad == "UNIVERSIDAD INCA GARCILASO DE LA VEGA"
	replace region = 20 if universidad == "UNIVERSIDAD DE PIURA"
	replace region = 15 if universidad == "UNIVERSIDAD RICARDO PALMA"
	replace region = 21 if universidad == "UNIVERSIDAD ANDINA NÉSTOR CÁCERES VELÁSQUEZ"
	replace region = 12 if universidad == "UNIVERSIDAD PERUANA LOS ANDES"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA UNIÓN"
	replace region = 8 	if universidad == "UNIVERSIDAD ANDINA DEL CUSCO"
	replace region = 3 	if universidad == "UNIVERSIDAD TECNOLOGICA DE LOS ANDES"
	replace region = 23 if universidad == "UNIVERSIDAD PRIVADA DE TACNA"
	replace region = 14 if universidad == "UNIVERSIDAD PARTICULAR DE CHICLAYO"
	replace region = 2 	if universidad == "UNIVERSIDAD SAN PEDRO"
	replace region = 13 if universidad == "UNIVERSIDAD PRIVADA ANTENOR ORREGO"
	replace region = 10 if universidad == "UNIVERSIDAD DE HUANUCO"
	replace region = 18 if universidad == "UNIVERSIDAD JOSÉ CARLOS MARIÁTEGUI"
	replace region = 15 if universidad == "UNIVERSIDAD MARCELINO CHAMPAGNAT"
	replace region = 16 if universidad == "UNIVERSIDAD CIENTÍFICA DEL PERÚ - UCP"
	replace region = 13 if universidad == "UNIVERSIDAD CÉSAR VALLEJO"
	replace region = 2 	if universidad == "UNIVERSIDAD CATÓLICA LOS ÁNGELES DE CHIMBOTE"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE CIENCIAS APLICADAS"
	replace region = 13 if universidad == "UNIVERSIDAD PRIVADA DEL NORTE"
	replace region = 15 if universidad == "UNIVERSIDAD SAN IGNACIO DE LOYOLA"
	replace region = 99 if universidad == "UNIVERSIDAD ALAS PERUANAS"
	replace region = 15 if universidad == "UNIVERSIDAD NORBERT WIENER"
	replace region = 4 	if universidad == "UNIVERSIDAD CATÓLICA SAN PABLO"
	replace region = 11 if universidad == "UNIVERSIDAD PRIVADA DE ICA"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA SAN JUAN BAUTISTA"
	replace region = 99 if universidad == "UNIVERSIDAD TECNOLÓGICA DEL PERÚ"
	replace region = 99 if universidad == "UNIVERSIDAD CONTINENTAL"
	replace region = 15 if universidad == "UNIVERSIDAD CIENTÍFICA DEL SUR"
	replace region = 14 if universidad == "UNIVERSIDAD CATÓLICA SANTO TORIBIO DE MOGROVEJO"
	replace region = 6 	if universidad == "UNIVERSIDAD PRIVADA ANTONIO GUILLERMO URRELO"
	replace region = 99 if universidad == "UNIVERSIDAD CATÓLICA SEDES SAPIENTIAE"
	replace region = 14 if universidad == "UNIVERSIDAD SEÑOR DE SIPÁN"
	replace region = 13 if universidad == "UNIVERSIDAD CATÓLICA DE TRUJILLO BENEDICTO XVI"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE LAS AMÉRICAS"
	replace region = 15 if universidad == "UNIVERSIDAD ESAN"
	replace region = 15 if universidad == "UNIVERSIDAD ANTONIO RUIZ DE MONTOYA"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE CIENCIA E INFORMÁTICA"
	replace region = 9 	if universidad == "UNIVERSIDAD PARA EL DESARROLLO ANDINO"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA TELESUP"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA SERGIO BERNALES"
	replace region = 99 if universidad == "UNIVERSIDAD PRIVADA DE PUCALLPA"
	replace region = 11 if universidad == "UNIVERSIDAD AUTÓNOMA DE ICA"
	replace region = 13 if universidad == "UNIVERSIDAD PRIVADA DE TRUJILLO"
	replace region = 21 if universidad == "UNIVERSIDAD PRIVADA SAN CARLOS"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA SIMÓN BOLÍVAR"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE INTEGRACIÓN GLOBAL"
	replace region = 16 if universidad == "UNIVERSIDAD PERUANA DEL ORIENTE"
	replace region = 15 if universidad == "UNIVERSIDAD AUTÓNOMA DEL PERU"
	replace region = 15 if universidad == "UNIVERSIDAD DE CIENCIAS Y HUMANIDADES"
	replace region = 14 if universidad == "UNIVERSIDAD PRIVADA JUAN MEJÍA BACA"
	replace region = 15 if universidad == "UNIVERSIDAD JAIME BAUSATE Y MEZA"
	replace region = 12 if universidad == "UNIVERSIDAD PERUANA DEL CENTRO"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA ARZOBISPO LOAYZA"
	replace region = 15 if universidad == "UNIVERSIDAD LE CORDON BLEU"
	replace region = 12 if universidad == "UNIVERSIDAD PRIVADA DE HUANCAYO FRANKLIN ROOSEVELT"
	replace region = 14 if universidad == "UNIVERSIDAD DE LAMBAYEQUE"
	replace region = 15 if universidad == "UNIVERSIDAD DE CIENCIAS Y ARTES DE AMÉRICA LATINA"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE ARTE ORVAL"
	replace region = 16 if universidad == "UNIVERSIDAD PRIVADA DE LA SELVA PERÚANA"
	replace region = 4 	if universidad == "UNIVERSIDAD CIENCIAS DE LA SALUD"
	replace region = 5 	if universidad == "UNIVERSIDAD DE AYACUCHO FEDERICO FROEBEL"
	replace region = 15 if universidad == "UNIVERSIDAD PERUANA DE INVESTIGACIÓN Y NEGOCIOS"
	replace region = 8 	if universidad == "UNIVERSIDAD PERUANA AUSTRAL DEL CUSCO"
	replace region = 4 	if universidad == "UNIVERSIDAD AUTÓNOMA SAN FRANCISCO"
	replace region = 15 if universidad == "UNIVERSIDAD SAN ANDRÉS"
	replace region = 15 if universidad == "UNIVERSIDAD INTERAMÉRICANA PARA EL DESARROLLO"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA JUAN PABLO II"
	replace region = 13 if universidad == "UNIVERSIDAD PRIVADA LEONARDO DA VINCI"
	replace region = 15 if universidad == "UTEC"
	replace region = 4 	if universidad == "UNIVERSIDAD LA SALLE"
	replace region = 23 if universidad == "UNIVERSIDAD LATINOAMERICANA CIMA"
	replace region = 4 	if universidad == "UNIVERSIDAD PRIVADA AUTÓNOMA DEL SUR"
	replace region = 15 if universidad == "UNIVERSIDAD MARÍA AUXILIADORA"
	replace region = 1 	if universidad == "UNIVERSIDAD POLITÉCNICA AMAZÓNICA"
	replace region = 15 if universidad == "UNIVERSIDAD SANTO DOMINGO DE GUZMÁN SAC"
	replace region = 7 	if universidad == "UNIVERSIDAD MARÍTIMA DEL PERÚ"
	replace region = 8 	if universidad == "UNIVERSIDAD PRIVADA LIDER PERUANA"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA PERUANO ALEMANA"
	replace region = 8 	if universidad == "UNIVERSIDAD GLOBAL DEL CUSCO"
	replace region = 12 if universidad == "UST UNIVERSIDAD SANTO TOMÁS"
	replace region = 15 if universidad == "UNIVERSIDAD PRIVADA SISE"
	replace region = 15 if universidad == "FACULTAD DE TEOLOGÍA PONTIFICIA Y CIVIL DE LIMA"
	replace region = 15 if universidad == "UNIVERSIDAD SEMINARIO BÍBLICO ANDINO"
	replace region = 15 if universidad == "UNIVERSIDAD SEMINARIO EVANGÉLICO DE LIMA"
	}
	
	
	
	label values region dep
	
	label values codigo_modular universidad_cod
	
	*- Average Grade
	destring nota_promedio, replace
	VarStandardiz nota_promedio, by(universidad facultad major_inei_code id_anio) newvar(score_std_uni)
	
	

	isvar 			///
		/*Match ID*/ id_per_umc id_persona_rec ///
		/*ID*/ codigo_modular  id_anio id_codigo_facultad id_carrera_primera_opcion /*id_carrera_homologada_primera_op*/ id_estado_persona id_periodo_postulacion  id_periodo_matricula semester		year  ///
		/*Char UNI*/ licensed	public academic university	region ///
		/*Char Indiv*/ 	dob age male ///
		/*applic info*/ carrera_primera_opcion		///
		/*admitt info*/ es_ingresante carrera_ingreso ///
		/*enroll info*/ score_std_uni major_inei_name /*universidad*/ facultad major_code major_inei_code major_cat* ///
		/*NEW VARS*/ codigo_ubigeo duracion_carrera type_admission type_in_person type_const id_ie n_credits semester_admitted semester_first_enrolled semester_graduated
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'

		foreach v of local all_vars {
			capture confirm string variable `v'
				if _rc==0 {
					   replace `v' = trim(itrim(`v'))
				}
		}
		
		*Destring those not IDs
		ds id_per_umc id_persona_rec codigo_modular, not
		local all_vars = r(varlist)
		destring `all_vars', replace
					
		compress
	
	if ${test}==1 save "$TEMP\graduated_TEST", replace	
	if ${test}==0 save "$TEMP\graduated", replace 

end


********************************************************************************
* Average data
********************************************************************************


capture program drop average_data
program define average_data


*-1. Score (individual)
//So that we can merge into incoming peers in uni.
foreach ece_g in "2p" "4p" "2s" {
	use "$TEMP\ece_`ece_g'", clear
		keep id_estudiante_`ece_g' score_com_std score_math_std score_acad_std
		rename id_estudiante_`ece_g' id_estudiante
		rename score* score*_`ece_g'
		merge 1:1 id_estudiante using "$TEMP\match_siagie_ece_`ece_g'", keep(master match) keepusing(id_per_umc)
		drop if id_per_umc == .
		drop _m
		compress
	save "$TEMP\scores_`ece_g'", replace
	}

	
	
*- 3. Applications
use "$TEMP\applied", clear
		
		isvar 			///
			/*Match ID*/ id_per_umc   ///
			/*ID*/ year id_cutoff_* codigo_modular facultad semester  ///
			/*Char UNI*/  public ///
			/*Char Indiv*/ 	dob age male	///
			/*applic info*/ major_c1_cat /*major_c1_code major_c1_name*/ major_c1_inei_code /*score_raw score_std* rank_score_raw* source issue*/	score_std_department score_std_major ///
			/*admitt info*/ major_admit_inei_code admitted ///
			/*enroll info*/ nota_promedio 
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'

		foreach v of local all_vars {
			capture confirm string variable `v'
				if _rc==0 {
					   replace `v' = trim(itrim(`v'))
				}
		}
		
		*Destring those not IDs
		ds id_per_umc, not
		local all_vars = r(varlist)
		destring `all_vars', replace
					
		compress
		
		keep if id_per_umc != .
		
	*- Application outcomes:
		*- Applied in same uni-major 	semester
		*- Applied in same uni 			semester
		*- Applied in same major 		semester
		*- Applied in public 			semester
		*- Applied in private 			semester
		*- Applied 						semester		
		
		*- Applied in same uni-major 	ever
		*- Applied in same uni 			ever
		*- Applied in same major 		ever
		*- Applied in public 			ever
		*- Applied in private 			ever	
		*- Applied 						ever
		
		

***************
*- Overall # of applications per student
***************

	preserve
		keep id_per_umc year semester
		*-- Total applications		
		bys id_per_umc:					gen N_applications = _N
		
		*-- Total applications first semester		
		bys id_per_umc year semester: gen N_applications_first = _N

		bys id_per_umc (year semester): keep if _n==1	
		keep id_per_umc N_applications N_applications_first
		save "$TEMP\total_applications_student", replace
	restore
	
	preserve
		keep id_per_umc codigo_modular
		
		*-- Total applications per student-uni
		bys id_per_umc codigo_modular:					gen N_applications_uni = _N
		bys id_per_umc codigo_modular: keep if _n==1
		keep id_per_umc codigo_modular N_applications_uni
		save "$TEMP\total_applications_student-uni", replace
	restore

	preserve
		keep id_per_umc codigo_modular year semester
		
		*-- Total applications each semester		
		bys id_per_umc year semester: gen N_applications_semester = _N

		bys id_per_umc year semester: keep if _n==1	
		keep id_per_umc codigo_modular semester N_applications_semester
		save "$TEMP\total_applications_student-semester", replace
	restore

***************
*- University-student average scores considering first applications to each university
***************

	foreach period_sample in "first" "first-uni" {
		
		preserve
			keep id_per_umc codigo_modular year semester public score_std_*
			*-- First semester applied in each university
			if "`period_sample'" == "first-uni" bys id_per_umc codigo_modular (year semester): 	keep if semester==semester[1]
			*-- First semester applied (still data at student-uni level, just keeping those from first semester only)
			if "`period_sample'" == "first" 	bys id_per_umc (year semester): 				keep if semester==semester[1]
			
			*- In case there are multiple applications within each cell (student-uni) we average them
			bys id_per_umc codigo_modular: egen score_std_major_uni = mean(score_std_major) 
			bys id_per_umc codigo_modular: egen score_std_department_uni = mean(score_std_department) 
			bys id_per_umc codigo_modular: keep if _n==1
			//This will be used as the same score in 'target college'	
			
			foreach cutoff_level in "major" "department" {		
				*- We scores for other (non-target) colleges.
				//Total sum and # of scores to 'all colleges' and 'all public colleges'
				bys id_per_umc: egen tot_score_std_`cutoff_level' 			= sum(score_std_`cutoff_level'_uni)
				bys id_per_umc: egen num_score_std_`cutoff_level' 			= sum((score_std_`cutoff_level'_uni!=.))
				bys id_per_umc: egen tot_score_std_`cutoff_level'_pub 		= sum(score_std_`cutoff_level'_uni*(public==1))
				bys id_per_umc: egen num_score_std_`cutoff_level'_pub 		= sum((score_std_`cutoff_level'_uni!=.)*(public==1)) 
				
				//We get the average excluding target.
				gen score_std_`cutoff_level'_uni_o 		= (tot_score_std_`cutoff_level'	-	score_std_`cutoff_level'_uni)	/	(num_score_std_`cutoff_level'	-	1) 		if score_std_`cutoff_level'_uni!=.
				replace score_std_`cutoff_level'_uni_o 	= (tot_score_std_`cutoff_level')		/	(num_score_std_`cutoff_level') if score_std_`cutoff_level'_uni==.

				gen score_std_`cutoff_level'_pub_o 		= (tot_score_std_`cutoff_level'_pub	-	score_std_`cutoff_level'_uni)	/	(num_score_std_`cutoff_level'_pub	-	1) 		if score_std_`cutoff_level'_uni!=. & public==1
				replace score_std_`cutoff_level'_pub_o 	= (tot_score_std_`cutoff_level'_pub)		/	(num_score_std_`cutoff_level'_pub) if score_std_`cutoff_level'_uni==. | public==0
			}
			
			*-- Keep one observation per student-university
			bys id_per_umc codigo_modular: 			keep if _n==1
			keep id_per_umc codigo_modular public score_std_*_uni* score_std_*_pub* tot* num*
			order id_per_umc codigo_modular public score_std_*_uni* score_std_*_pub*  tot* num*
			save "$TEMP\application_info_`period_sample'_student-uni", replace	
			
			*-- In order to have an average of 'other universities' for universities that the student does not apply, we also estimate the overall average and get a student level database
			bys id_per_umc: keep if _n==1
			keep id_per_umc public tot* num*
			foreach cutoff_level in "major" "department" {	
				gen score_std_`cutoff_level'_all 	= (tot_score_std_`cutoff_level')			/	(num_score_std_`cutoff_level') 
				gen score_std_`cutoff_level'_pub 	= (tot_score_std_`cutoff_level'_pub)		/	(num_score_std_`cutoff_level'_pub)
			}
			keep id_per_umc public score_std_*_all score_std_*_pub  tot* num*
			order id_per_umc public score_std_*_all score_std_*_pub  tot* num*
			save "$TEMP\application_info_`period_sample'_student", replace		
		restore	
	}	
		
***************
*- Other outcomes
***************		
		*- Ever admitted
		preserve
			keep if admitted==1
			keep id_per_umc year semester dob
			bys id_per_umc (year semester): keep if _n==1
			keep id_per_umc year semester dob
			save "$TEMP\admitted_students", replace				
		restore
		
		*- Ever admitted public
		preserve
			keep if admitted==1 & public==1
			keep id_per_umc year semester dob
			bys id_per_umc (year semester): keep if _n==1
			keep id_per_umc year semester dob
			save "$TEMP\admitted_students_public", replace				
		restore
		
		*- Ever admitted private
		preserve
			keep if admitted==1 & public==0
			keep id_per_umc year semester dob
			bys id_per_umc (year semester): keep if _n==1
			keep id_per_umc year semester dob
			save "$TEMP\admitted_students_private", replace				
		restore		
		
		*- Filter incoming students per major-semester
		preserve
			keep if admitted==1
			keep id_per_umc codigo_modular /*facultad*/ major_admit_inei_code year semester
			bys id_per_umc codigo_modular /*facultad*/ major_admit_inei_code year semester: keep if _n==_N
			rename major_admit_inei_code major_inei_code
			save "$TEMP\incoming_students", replace				
		restore
		
		*- Database per student in STEM (we do it now since for now #### it is done based on major_c1_cat which may overlap with different caterogries of major_inei_code which we later keep. CHECK and if not, do after that.)
		preserve
			gen stem_major = inlist(major_c1_cat,5,6,7)
			keep if stem_major == 1 
			bys id_per_umc (year semester): keep if _n==_N
			keep id_per_umc year dob score_std_major score_std_department
			save "$TEMP\applied_stem_students", replace	
		restore
		
		preserve
			gen stem_major = inlist(major_c1_cat,5,6,7)
			keep if stem_major == 0
			bys id_per_umc (year semester): keep if _n==_N
			keep id_per_umc year dob score_std_major score_std_department
			save "$TEMP\applied_nstem_students", replace	
		restore		
		
		
		*- Database per student-university-major-semester
		bys id_per_umc public codigo_modular /*facultad*/ major_c1_inei_code year semester: keep if _n==_N
		keep id_per_umc public codigo_modular /*facultad*/ major_c1_inei_code year semester dob
		save "$TEMP\applied_students_university_major_semester", replace
		
		*- Database per student-university-semester
		use "$TEMP\applied_students_university_major_semester", clear
		bys id_per_umc codigo_modular semester: keep if _n==_N
		keep id_per_umc codigo_modular year semester
		save "$TEMP\applied_students_university_semester", replace
		
		*- Database per student-major-semester
		use "$TEMP\applied_students_university_major_semester", clear
		bys id_per_umc major_c1_inei_code semester: keep if _n==_N
		keep id_per_umc major_c1_inei_code year semester
		save "$TEMP\applied_students_major_semester", replace		
		
		*- Database per student-public-semester
		use "$TEMP\applied_students_university_major_semester", clear
		keep if public==1
		bys id_per_umc semester: keep if _n==_N
		keep id_per_umc year semester
		save "$TEMP\applied_students_public_semester", replace
		
		*- Database per student-private-semester
		use "$TEMP\applied_students_university_major_semester", clear
		keep if public==0
		bys id_per_umc semester: keep if _n==_N
		keep id_per_umc year semester
		save "$TEMP\applied_students_private_semester", replace
		
		*- Database per student-semester
		use "$TEMP\applied_students_university_major_semester", clear
		bys id_per_umc semester: keep if _n==_N
		keep id_per_umc year semester
		save "$TEMP\applied_students_semester", replace
		
		* applied ever
		*- Database per student-university-major
		use "$TEMP\applied_students_university_major_semester", clear
		bys id_per_umc codigo_modular /*facultad*/ major_c1_inei_code (year semester): keep if _n==_N
		keep id_per_umc year codigo_modular /*facultad*/ major_c1_inei_code
		save "$TEMP\applied_students_university_major", replace		
	
		*- Database per student-university
		use "$TEMP\applied_students_university_major_semester", clear
		bys id_per_umc codigo_modular (year semester): keep if _n==_N	
		keep id_per_umc year codigo_modular public
		save "$TEMP\applied_students_university", replace		
		
		*- Database per student-major
		use "$TEMP\applied_students_university_major_semester", clear
		bys id_per_umc major_c1_inei_code (year semester): keep if _n==_N
		keep id_per_umc year major_c1_inei_code
		save "$TEMP\applied_students_major", replace
			
		*- Database per student-public
		use "$TEMP\applied_students_university_major_semester", clear
		keep if public==1
		bys id_per_umc (year semester): keep if _n==_N
		keep id_per_umc year semester
		save "$TEMP\applied_students_public", replace
		
		*- Database per student-private
		use "$TEMP\applied_students_university_major_semester", clear
		keep if public==0
		bys id_per_umc  (year semester): keep if _n==_N
		keep id_per_umc year semester
		save "$TEMP\applied_students_private", replace

		*- Database per student-university (Applied to other public)
		//For each student-university obs, we keep those who also had other applications
		use "$TEMP\applied_students_university_major_semester", clear
		keep if public==1
		bys id_per_umc codigo_modular (year semester): keep if _n==_N //Keep one per uni (last one)
		bys id_per_umc (codigo_modular year semester): keep if _N>1 //Keep those with more than one obs
		keep id_per_umc year codigo_modular 
		//These are the set of students who applied to more than one public. We can match by 'id_per_umc universidad'
		save "$TEMP\applied_students_multiple_public", replace
		
		*- Database per student
		use "$TEMP\applied_students_university_major_semester", clear
		bys id_per_umc codigo_modular (year semester): keep if _n==1
		bys id_per_umc: egen applied_public_tot = sum(public)	
		bys id_per_umc (year semester): keep if _n==1
		keep id_per_umc year dob semester applied_public_tot
		save "$TEMP\applied_students", replace	
		
*- Enrollment
use "$TEMP\enrolled", clear
		
		isvar 			///
			/*Match ID*/ id_per_umc   ///
			/*ID*/ year codigo_modular facultad major_code major_inei_code semester major_cat ///
			/*Char UNI*/  public ///
			/*Char Indiv*/ 	dob age male	///
			/*enroll info*/ score_std_uni  
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'

		foreach v of local all_vars {
			capture confirm string variable `v'
				if _rc==0 {
					   replace `v' = trim(itrim(`v'))
				}
		}
		
		*Destring those not IDs
		ds id_per_umc, not
		local all_vars = r(varlist)
		destring `all_vars', replace
					
		compress
		
		keep if id_per_umc != .
		
	*- Enrollment outcomes:
		*- Enrolled in same uni-major 	semester
		*- Enrolled in same uni 		semester
		*- Enrolled in same major 		semester
		*- Enrolled in public 			semester
		*- Enrolled in private 			semester
		*- Enrolled 					semester		
		
		*- Enrolled in same uni-major 	ever
		*- Enrolled in same uni 		ever
		*- Enrolled in same major 		ever
		*- Enrolled in public 			ever
		*- Enrolled in private 			ever	
		*- Enrolled 					ever	
		
		*-Average school quality:
		//Incoming peer score
		preserve
			keep id_per_umc codigo_modular /*facultad*/ major_inei_code year semester
			merge m:1 id_per_umc codigo_modular /*facultad*/ major_inei_code year semester using "$TEMP\incoming_students", keep(master match)
			keep if _m==3
			drop _m
			merge m:1 id_per_umc using "$TEMP\scores_2p", keepusing(score*) keep(master match)	
			rename _m m_2p
			merge m:1 id_per_umc using "$TEMP\scores_4p", keepusing(score*) keep(master match)	
			rename _m m_4p
			merge m:1 id_per_umc using "$TEMP\scores_2s", keepusing(score*) keep(master match)	
			rename _m m_2s
			foreach ece_g in "2p" "4p" "2s" {
				foreach subj in "math" "com" "acad" {
					bys codigo_modular /*facultad*/ major_inei_code year semester: egen avg_enr_score_`subj'_std_`ece_g' = mean(score_`subj'_std_`ece_g')
				}
			}
			drop score*
			drop m_*
			drop *4p //not enough naturally, since this were from 2016,2018, which would graduate in 2024 and apply 2025
			bys codigo_modular /*facultad*/ major_inei_code year semester: keep if _n==1
			save "$TEMP\scores_incoming_university_major_semester", replace
		restore
		
		* Enrolled semester
		*- Database per student in STEM (we do it now since for now #### it is done based on major_c1_cat which may overlap with different caterogries of major_inei_code which we later keep. CHECK and if not, do after that.)
		preserve
			gen stem_major = inlist(major_cat,5,6,7)
			keep if stem_major == 1 
			bys id_per_umc (year semester): keep if _n==_N
			keep id_per_umc year dob score_std_uni
			save "$TEMP\enrolled_stem_students", replace	
		restore
		
		preserve
			gen stem_major = inlist(major_cat,5,6,7)
			keep if stem_major == 0
			bys id_per_umc (year semester): keep if _n==_N
			keep id_per_umc year dob score_std_uni
			save "$TEMP\enrolled_nstem_students", replace	
		restore		
		
		*- Database per student-university-major-semester
		gen neg_score_std_uni = -score_std_uni
		bys id_per_umc public codigo_modular /*facultad*/ major_inei_code year semester (neg_score_std_uni): keep if _n==1 //If more than one enrolled, keep the highest score
		keep id_per_umc public codigo_modular /*facultad*/ major_inei_code year semester dob score_std_uni
		save "$TEMP\enrolled_students_university_major_semester", replace
		
		*- Database per student-university-semester
		use "$TEMP\enrolled_students_university_major_semester", clear
		gen neg_score_std_uni = -score_std_uni
		bys id_per_umc codigo_modular semester (neg_score_std_uni): keep if _n==1 //If more than one enrolled, keep the highest score
		keep id_per_umc codigo_modular year semester
		save "$TEMP\enrolled_students_university_semester", replace
		
		*- Database per student-major-semester
		use "$TEMP\enrolled_students_university_major_semester", clear
		gen neg_score_std_uni = -score_std_uni
		bys id_per_umc major_inei_code semester (neg_score_std_uni): keep if _n==1 //If more than one enrolled, keep the highest score
		keep id_per_umc major_inei_code year semester
		save "$TEMP\enrolled_students_major_semester", replace		
		
		*- Database per student-public-semester
		use "$TEMP\enrolled_students_university_major_semester", clear
		keep if public==1
		gen neg_score_std_uni = -score_std_uni
		bys id_per_umc semester (neg_score_std_uni): keep if _n==1 //If more than one enrolled, keep the highest score
		keep id_per_umc year semester
		save "$TEMP\enrolled_students_public_semester", replace
		
		*- Database per student-private-semester
		use "$TEMP\enrolled_students_university_major_semester", clear
		keep if public==0
		gen neg_score_std_uni = -score_std_uni
		bys id_per_umc semester (neg_score_std_uni): keep if _n==1 //If more than one enrolled, keep the highest score
		keep id_per_umc year semester
		save "$TEMP\enrolled_students_private_semester", replace
		
		*- Database per student-semester: This will also identify in what college-major students were enrolled each semester. Keeps one at random? ###
		use "$TEMP\enrolled_students_university_major_semester", clear
		gen neg_score_std_uni = -score_std_uni
		bys id_per_umc semester (neg_score_std_uni): keep if _n==1 //If more than one enrolled, keep the highest score
		keep id_per_umc year semester
		save "$TEMP\enrolled_students_semester", replace
		
		*- Peer score of university first enrolled.
		use "$TEMP\enrolled_students_university_major_semester", clear
			keep id_per_umc codigo_modular /*facultad*/ major_inei_code year semester score_std_uni
			merge m:1 id_per_umc codigo_modular /*facultad*/ major_inei_code year semester using "$TEMP\incoming_students", keep(master match) 
			keep if _m==3
			drop _m
			//This are students in their first term after being admitted.
			merge m:1 codigo_modular /*facultad*/ major_inei_code semester using "$TEMP\scores_incoming_university_major_semester", keep(master match) keepusing(avg_enr_score_*)
			gen neg_score_std_uni = -score_std_uni
			bys id_per_umc (semester neg_score_std_uni): keep if _n==1 //Keep first semester ever. If more than one enrolled, keep the highest score
			keep id_per_umc avg*
		save "$TEMP\enrolled_incoming_students_peer_scores", replace
		
		
		

		
				
		* Enrolled ever
		*- Database per student-university-major
		use "$TEMP\enrolled_students_university_major_semester", clear
		bys id_per_umc codigo_modular /*facultad*/ major_inei_code (year semester): keep if _n==_N
		keep id_per_umc year codigo_modular /*facultad*/ major_inei_code
		save "$TEMP\enrolled_students_university_major", replace	
	
		*- Database per student-university
		use "$TEMP\enrolled_students_university_major_semester", clear
		bys id_per_umc codigo_modular (year semester): keep if _n==_N
		keep id_per_umc year codigo_modular public 
		save "$TEMP\enrolled_students_university", replace
	
		*- Database per student-major
		use "$TEMP\enrolled_students_university_major_semester", clear
		bys id_per_umc major_inei_code (year semester): keep if _n==_N
		keep id_per_umc year  major_inei_code
		save "$TEMP\enrolled_students_major", replace	
			
		*- Database per student-public
		use "$TEMP\enrolled_students_university_major_semester", clear
		keep if public==1
		bys id_per_umc (year semester): keep if _n==_N
		keep id_per_umc year 
		save "$TEMP\enrolled_students_public", replace
		
		*- Database per student-private
		use "$TEMP\enrolled_students_university_major_semester", clear
		keep if public==0
		bys id_per_umc  (year semester): keep if _n==_N
		keep id_per_umc year
		save "$TEMP\enrolled_students_private", replace
		
		*- Database per student-university (Applied to other public)
		//For each student-university obs, we keep those who also had other applications
		use "$TEMP\enrolled_students_university_major_semester", clear
		keep if public==1
		bys id_per_umc codigo_modular (year semester): keep if _n==_N //Keep one per uni (last one)
		bys id_per_umc (codigo_modular year semester): keep if _N>1 //Keep those with more than one obs
		keep id_per_umc year codigo_modular 
		//These are the set of students who applied to more than one public. We can match by 'id_per_umc codigo_modular'
		save "$TEMP\enrolled_students_multiple_public", replace		
		
		*- Database per student
		use "$TEMP\enrolled_students_university_major_semester", clear
		bys id_per_umc codigo_modular (year semester): keep if _n==_N
		bys id_per_umc: egen enroll_public_tot = sum(public)
		//We keep last university score and last university enrolled  ##
		bys id_per_umc (year semester): keep if _n==_N
		keep id_per_umc year dob score_std_uni enroll_public_tot
		save "$TEMP\enrolled_students", replace	
		
		
		
		*********************		
		* Graduated ever
		*********************
		
			
	*- Enrollment
	use "$TEMP\graduated", clear
			
		isvar 			///
			/*Match ID*/ id_per_umc   ///
			/*ID*/ year codigo_modular facultad major_code major_inei_code major_cat ///
			/*Char UNI*/  public ///
			/*Char Indiv*/ 	dob age male	///
			/*enroll info*/ score_std_uni  
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'

		foreach v of local all_vars {
			capture confirm string variable `v'
				if _rc==0 {
					   replace `v' = trim(itrim(`v'))
				}
		}
		
		*Destring those not IDs
		/*
		ds id_per_umc, not
		local all_vars = r(varlist)
		destring `all_vars', replace
		*/
		
		compress
		
		keep if id_per_umc != .
		
	*- Enrollment outcomes:
		*- Enrolled in same uni-major 	semester
		*- Enrolled in same uni 		semester
		*- Enrolled in same major 		semester
		*- Enrolled in public 			semester
		*- Enrolled in private 			semester
		*- Enrolled 					semester		
		
		*- Enrolled in same uni-major 	ever
		*- Enrolled in same uni 		ever
		*- Enrolled in same major 		ever
		*- Enrolled in public 			ever
		*- Enrolled in private 			ever	
		*- Enrolled 					ever	
		
		
		*- Database per student-university-major
		gen neg_score_std_uni = -score_std_uni
		bys id_per_umc public codigo_modular /*facultad*/ major_inei_code year (neg_score_std_uni): keep if _n==1 //If more than one graduated, keep the highest score
		keep id_per_umc public codigo_modular /*facultad*/ major_inei_code year dob score_std_uni
		save "$TEMP\graduated_students_university_major", replace		
		
		*- Database per student-university-major
		/*
		use "$TEMP\graduated_students_university_major_semester", clear
		bys id_per_umc codigo_modular /*facultad*/ major_inei_code (year semester): keep if _n==_N
		keep id_per_umc year codigo_modular /*facultad*/ major_inei_code
		save "$TEMP\enrolled_students_university_major", replace	
	
		*- Database per student-university
		use "$TEMP\enrolled_students_university_major_semester", clear
		bys id_per_umc codigo_modular (year semester): keep if _n==_N
		keep id_per_umc year codigo_modular public 
		save "$TEMP\enrolled_students_university", replace
	
		*- Database per student-major
		use "$TEMP\enrolled_students_university_major_semester", clear
		bys id_per_umc major_inei_code (year semester): keep if _n==_N
		keep id_per_umc year  major_inei_code
		save "$TEMP\enrolled_students_major", replace	
		
		*- Database per student-public-semester
		use "$TEMP\enrolled_students_university_major_semester", clear
		keep if public==1
		bys id_per_umc (year semester): keep if _n==_N
		keep id_per_umc year 
		save "$TEMP\enrolled_students_public", replace
		
		*- Database per student-private-semester
		use "$TEMP\enrolled_students_university_major_semester", clear
		keep if public==0
		bys id_per_umc  (year semester): keep if _n==_N
		keep id_per_umc year
		save "$TEMP\enrolled_students_private", replace
		*/
		
		*- Database per student-university
		use "$TEMP\graduated_students_university_major", clear
		bys id_per_umc codigo_modular (year): keep if _n==_N
		keep id_per_umc year codigo_modular public 
		save "$TEMP\graduated_students_university", replace		
		
		*- Database per student-public
		use "$TEMP\graduated_students_university_major", clear
		keep if public==1
		bys id_per_umc (year): keep if _n==_N
		keep id_per_umc year 
		save "$TEMP\graduated_students_public", replace
		
		*- Database per student-private
		use "$TEMP\graduated_students_university_major", clear
		keep if public==0
		bys id_per_umc  (year): keep if _n==_N
		keep id_per_umc year
		save "$TEMP\graduated_students_private", replace
		
		*- Database per student
		use "$TEMP\graduated_students_university_major", clear
		bys id_per_umc codigo_modular (year): keep if _n==_N
		//bys id_per_umc: egen graduate_public_tot = sum(public)
		//We keep last university score and last university enrolled  ##
		bys id_per_umc (year): keep if _n==_N
		keep id_per_umc year dob score_std_uni /*enroll_public_tot*/
		save "$TEMP\graduated_students", replace	
		

		
end


********************************************************************************
* Average data
********************************************************************************


capture program drop additional_data
program define additional_data

		
	*-1. Graduation rate (at university) - Needs duration and graduation database.

	*-2. Dropout rate (at university): Defined as if still enrolled 1 year after 1st enrollment (after being admitted)
	use "$TEMP\applied_students_university_major_semester", clear

	drop if id_per_umc == .

	rename major_c1_inei_code major_inei_code
	merge 1:1 id_per_umc public codigo_modular /*facultad*/ major_inei_code semester using "$TEMP\enrolled_students_university_major_semester", keep(master match)
	keep if _m==3
	drop _m
	//These are the enrolled in their first semester (of application)

	*- Should we considered deferred enrollments? Perhaps someone got admitted but didn't enroll until later?

	*- Still enrolled after X semesters:
	clonevar app_semester = semester

	forvalues sems = 1/6 {
		di "After `sems' semesters"
		capture drop aux_semester
		clonevar aux_semester = semester
		foreach year in "2017" "2018" "2019" "2020" "2021" "2022" "2023" "2024" "2025" "2026" "2027" { 
			//We only have until 2023 for now, but since we do after 6 sems we include the others
			local next_year = `year'+1
			replace semester = "`year'-2" if aux_semester == "`year'-1"
			replace semester = "`next_year'-1" if aux_semester == "`year'-2"
		}

		merge 1:1 id_per_umc public codigo_modular /*facultad*/ major_inei_code semester using "$TEMP\enrolled_students_university_major_semester", keep(master match)
		gen enrolled_after_`sems'sem = _m==3
		drop _m
	}

	*- Consider as missing those with not enough time to observe future outcomes
	drop semester
	drop aux_semester
	rename app_semester semester
	replace enrolled_after_1sem = . if inlist(semester,"2023-2")==1
	replace enrolled_after_2sem = . if inlist(semester,"2023-1")==1 | enrolled_after_1sem==.
	replace enrolled_after_3sem = . if inlist(semester,"2022-2")==1 | enrolled_after_2sem==.
	replace enrolled_after_4sem = . if inlist(semester,"2022-1")==1 | enrolled_after_3sem==.
	replace enrolled_after_5sem = . if inlist(semester,"2021-2")==1 | enrolled_after_4sem==.
	replace enrolled_after_6sem = . if inlist(semester,"2021-1")==1 | enrolled_after_5sem==.

	keep 	id_per_umc public codigo_modular /*facultad*/ major_inei_code semester ///
			enrolled_after_?sem
			
	compress
	
	/*
	What is the outcome we want to get? 
	
	1. In terms of school quality. Are dropout rates high?
	1.1. Dropout rates are the % of those students who enroll and drop out after X years.
	
	Given that we have started with enrolled students, that would be the average by school here.
	
	2. In terms of individual students outcomes... let's look at the papers..
	Mountjoy
	*/
	
	collapse enrolled_after_?sem, by(codigo_modular)
	
	save "$TEMP\enrolled_after_sems", replace

	*- We then collapse at university level to have a measure of dropout






	//Define incoming classes, see how many graduated after 5 years:	
	*- Score (class)


end

********************************************************************************
* Erase temp files
********************************************************************************

capture program drop erase_data
program define erase_data

	capture erase  "$TEMP\ece_family_2015_2p.dta"
	capture erase  "$TEMP\ece_family_2016_2p.dta"
	capture erase  "$TEMP\em_family_2019_2p.dta"
	capture erase  "$TEMP\em_family_2022_2p.dta"
	capture erase  "$TEMP\em_family_2023_2p.dta"
	
	capture erase  "$TEMP\ece_family_2016_4p.dta"
	capture erase  "$TEMP\ece_family_2018_4p.dta"
	capture erase  "$TEMP\em_family_2019_4p.dta"
	capture erase  "$TEMP\em_family_2022_4p.dta"
	capture erase  "$TEMP\em_family_2023_4p.dta"	
	
	capture erase  "$TEMP\ece_student_2015_2s.dta"
	capture erase  "$TEMP\ece_student_2016_2s.dta"
	capture erase  "$TEMP\ece_student_2018_2s.dta"
	capture erase  "$TEMP\ece_student_2019_2s.dta"
	capture erase  "$TEMP\em_student_2022_2s.dta"
	capture erase  "$TEMP\em_student_2023_2s.dta"		
	
	capture erase "$TEMP\em_raw.dta"
	capture erase "$TEMP\ece_raw.dta"
	
	capture erase "$TEMP\em_raw_2p_2018.dta"
	capture erase "$TEMP\em_raw_2p_2019.dta"
	capture erase "$TEMP\em_raw_2p_2022.dta"
	capture erase "$TEMP\em_raw_2p_2023.dta"
	capture erase "$TEMP\em_raw_4p_2019.dta"
	capture erase "$TEMP\em_raw_4p_2022.dta"
	capture erase "$TEMP\em_raw_4p_2023.dta"
	capture erase "$TEMP\em_raw_6p_2018.dta"
	capture erase "$TEMP\em_raw_6p_2022.dta"
	capture erase "$TEMP\em_raw_2s_2018.dta"
	capture erase "$TEMP\em_raw_2s_2022.dta"
	capture erase "$TEMP\em_raw_2s_2023.dta"

end


********************************************************************************
* MAIN	
********************************************************************************

main