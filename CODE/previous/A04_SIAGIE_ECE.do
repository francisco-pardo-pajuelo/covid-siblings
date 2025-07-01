/********************************************************************************
- Author: Francisco Pardo
- Description: prepares final databases to be merged
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/



capture program drop main 
program define main 

setup
em
ece_siblings
ece
applied
enrolled
socioecon

aggregate_school_characteristics
aggregates_score
aggregates_app_enr

end


********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup

	set seed 1234
	global excel = 0
	global test = 0

end

********************************************************************************
* EM : Sample Examination
********************************************************************************
//

capture program drop em
program define em

	if $excel == 0 use "$TEMP\em_siagie", clear
	if $excel == 1 {
		import delimited "$IN\MINEDU\ECE EM innominada\Resultados_EM_ConIDPersonaSIAGIE_innom.txt", clear
		compress
		save "$TEMP\em_siagie", replace
		gen u=runiform()
		keep if u<0.01
		drop u
		save "$TEMP\em_siagie_TEST", replace
		}
		
	use "$TEMP\em_siagie", clear
	
end


********************************************************************************
* ECE: Temporary identification of siblings
* Identify siblings with name data
********************************************************************************


capture program drop ece_siblings
program define ece_siblings

	use "$TEMP\students", clear

	keep id_ie_2p seccion_2p year_2p id_2p paterno_2p materno_2p nombres_2p std_?_?? m500_?_?? male_2p

	*- Check if duplicates
	bys id_ie_2p seccion_2p year_2p male_2p m500_m_2p m500_c_2p: gen N_obs=_N
	tab N_obs

	*- Only keep single observations (not possible to properly match the rest)
	keep if N_obs==1

	*- Identify family IDs
	drop if paterno_2p =="" | materno_2p=="" | nombres_2p == ""

	egen last_name_father_id = group(paterno_2p)
	egen last_name_mother_id = group(materno_2p)
	egen first_name_id = group(nombres_2p)

	egen family_id = group(last_name_father_id last_name_mother_id id_ie_2p) // Same family if share both last names and primary school

	*- Keep only a subset of well identified (only 2 siblings and different years)
	bys id_2p (year_2p): keep if _n==1 						//first observation per individual
	bys family_id (year_2p id_2p)	: gen sib_id = _n 	//List siblings in a family
	bys family_id 					: gen sib_tot = _N 		//Total siblings
	keep if inlist(sib_tot,2)==1 							//Keep only cases of 2 siblings
	bys family_id 					: egen oldest_year_2p = min(year_2p)
	bys family_id 					: egen youngest_year_2p = max(year_2p)
	keep if oldest_year_2p!=youngest_year_2p

	*- Oldest sibling
	gen oldest = year_2p == oldest_year_2p

	*- Rename variables to match
	rename (m500_m_2p m500_c_2p) (score_math score_com)

	keep /*id variables*/ id_ie_2p seccion_2p year_2p male_2p score_math score_com /*variables to match*/ family_id sib_id oldest

	save "$TEMP/ece_siblings_info", replace	

end


********************************************************************************
* ECE: National Examination 
********************************************************************************

capture program drop ece
program define ece

	if $excel == 1 {
		import delimited "$IN\MINEDU\ECE EM innominada\Resultados_ECE_ConIDPersonaSIAGIE_innom.txt", clear
		compress
		save "$TEMP\ece_siagie", replace
		gen u=runiform()
		keep if u<0.01
		save "$TEMP\ece_siagie_TEST", replace
		}
		
	if ${test}==0 & ${excel} == 0 use "$TEMP\ece_siagie", clear
	if ${test}==1 & ${excel} == 0 use "$TEMP\ece_siagie_TEST", clear

	rename ańo year
	rename grado grade
	rename nivel level
	rename ise socioec_index //socio-economic-index


	*- Grade
	replace grade = "2" if grade == "2do" & level == "Primaria"
	replace grade = "4" if grade == "4to" & level == "Primaria" 
	replace grade = "8" if grade == "2do" & level == "Secundaria"
	destring grade, replace force


	*- Public school
	gen public = 1 if gestion2=="Estatal" 
	replace public = 0 if gestion2=="No estatal" 
	label var public "School: Public"
	label define public 0 "Private" 1 "Public"
	label values public public
	
	*- UBIGEO
	tostring codgeo, replace
	replace codgeo = "0" + codgeo if strlen(codgeo)<6
	assert strlen(codgeo)==6
	//replace codgeo = "0" + codgeo if strlen(codgeo)<6
	drop departamento
	gen dep = substr(codgeo,1,2)
	destring dep, replace
	label define dep ///
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
		25 "Ucayali" 
	label values dep dep

	*- Polidocente Completo or unidocente/multigrado
	gen polidoc = 1 if caracteristica2 == "Polidocente completo"
	replace polidoc = 0 if caracteristica2=="Unidocente / Multigrado" 
	label var polidoc "School: Grades in separate classrooms (Polidocente completo)"
	label define polidoc 0 "Unidocente / Multigrado" 1 "Polidocente completo"
	label values polidoc polidoc

	*- Male
	gen male = 1 if sexo=="Hombre" 
	replace male = 0 if sexo=="Mujer" 
	label var male "Sex: Male"
	label define male 0 "female" 1 "male"
	label values male male

	*- Mother Tongue is Spanish
	gen spanish = 1 if lengua_materna=="Castellano"
	replace spanish = 0 if lengua_materna != "Castellano" & lengua_materna!=""
	label var spanish "Mother Tongue: Spanish"
	label define spanish 0 "Other" 1 "Spanish"
	label values spanish spanish

	*- Socio-Economic index
	destring socioec_index, replace force
	gen socioec_index_cat = .
	label define socioec_index_cat 1 "Very Low" 2 "Low" 3 "Medium" 4 "High"
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
	
	*- Attach family ID
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

			isvar 			///
				/*Match ID*/ 	indpe_pos* id_per_pos* indpe_mat* id_per_mat* ///
				/*ID*/  id_estudiante fuente year cod_mod7 anexo /*nombre_ie*/ level grade cor_est id_seccion seccion   ///
				/*LOCATION*/ /*cod_dre nom_dre cod_ugel nom_ugel*/ codgeo dep /*provincia distrito*/ ///
				/*Char school*/ public polidoc 			///
				/*Char Indiv*/ 	male spanish socioec_index socioec_index_cat			///
				/*Scores*/		score_com_std score_math_std score_soc_std score_sci_std ///
				/*Scores RAW*/	score_com score_math ///
				/*Family info*/ family_id sib_id oldest
			local all_vars = r(varlist)
			ds `all_vars', not
			keep `all_vars'
			order `all_vars'
			destring `all_vars', replace
			
			foreach v of local all_vars {
				capture confirm string variable `v'
					if _rc==0 {
						   replace `v' = trim(itrim(`v'))
					}
			}
			
	compress
	
	if ${test}==0 save "$TEMP\ece_siagie_final", replace
	if ${test}==1 save "$TEMP\ece_siagie_final_TEST", replace

end


********************************************************************************
* Applicants
********************************************************************************


capture program drop applied
program define applied


	if $excel == 0 use "$TEMP\applied_2017", clear
	if $excel == 1 {
		foreach y in "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
			import delimited "$IN\MINEDU\Data_postulantes_siries_`y'_innominada.txt", clear
			compress
			save "$TEMP\applied_`y'", replace
		}
	}
			
	clear
	forvalues y = 2017/2023 {
		preserve
			use "$TEMP\applied_`y'", clear
			
			isvar 			///
				/*Match ID*/ id_persona_reco id_per_pos* ///
				/*ID*/ codigo_modular id_tipo_institucion id_tipo_gestion id_anio id_codigo_facultad id_carrera_primera_opcion id_carrera_homologada_primera_op /*id_estado_persona*/ id_persona_reco id_periodo_postulacion id_periodo_matricula	universidad facultad abreviatura_anio ///
				/*Char UNI*/ estatus_licenciamiento tipo_funcionamiento		///
				/*Char Indiv*/ 	fecha_nacimiento edad sexo	///
				/*applic info*/ puntaje_postulante carrera_primera_opcion codigo_carrera_inei_primera_opci nombre_carrera_inei_primera_opci codigo1_c2018 codigo_carrera_inei_segunda_opci nombre_carrera_inei_segunda_opci codigo1_c2018 nombre1_c2018		///
				/*admitt info*/ es_ingresante carrera_ingreso codigo_carrera_inei_ingreso nombre_carrera_inei_ingreso ///
				/*enroll info*/ nota_promedio  
			local all_vars = r(varlist)
			ds `all_vars', not
			keep `all_vars'
			order `all_vars'
			destring `all_vars', replace
			compress

			tempfile applied_`y'
			save `applied_`y'', replace	
		restore
		append using `applied_`y'', force
	}

		

	rename puntaje_postulante score_raw
	rename abreviatura_anio year	
	rename fecha_nacimiento dob
	rename edad age
	
	*- Male
	gen male = 1 if sexo=="MASCULINO" 
	replace male = 0 if sexo=="FEMENINO" 
	label var male "Sex: Male"
	label define male 0 "female" 1 "male"
	label values male male
	
	*- Institution type
	gen university = 1 if id_tipo_institucion=="UNIVERSIDADES" 
	replace university = 0 if id_tipo_institucion!="UNIVERSIDADES" & id_tipo_institucion!=""
	label var university "Type: University"
	label define university 0 "Other" 1 "University"
	label values university university		
	
	*- Public
	gen public = 1 if id_tipo_gestion=="PUBLICA" 
	replace public = 0 if id_tipo_gestion=="PRIVADA" 
	label var public "Administration: Public"
	label define public 0 "Private" 1 "Public"
	label values public public			
	
	*- Licensed
	gen licensed = 1 if estatus_licenciamiento=="LICENCIADA" 
	replace licensed = 0 if estatus_licenciamiento=="LICENCIA DENEGADA" 
	label var licensed "Status: Licensed"
	label define licensed 0 "License Denied" 1 "Licensed"
	label values licensed licensed		
	
	*- Academic
	gen academic = 1 if tipo_funcionamiento == "ACADÉMICO"
	replace academic = 0 if tipo_funcionamiento=="AMBOS" 
	label var academic "Type: Academic"
	label define academic 0 "both" 1 "academic"
	label values academic academic	
	
	*- Choice/Major
	rename (codigo1_c2018 codigo_carrera_inei_primera_opci codigo_carrera_inei_segunda_opci codigo_carrera_inei_ingreso) (id_major_choice1_cat id_major_choice1 id_major_choice2 id_major_admitted)
	rename (nombre1_c2018 nombre_carrera_inei_primera_opci nombre_carrera_inei_segunda_opci nombre_carrera_inei_ingreso) (name_major_choice1_cat name_major_choice1 name_major_choice2 name_major_admitted)
	
	preserve
		bys codigo_modular universidad: keep if _n==1
		sort codigo_modular
		list codigo_modular universidad, sep(10000)
	restore
	
	/*

     +------------------------------------------------------------------------------------------+
     | codigo_~r                                                                    universidad |
     |------------------------------------------------------------------------------------------|
  1. | 160000001                                       UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS |
  2. | 160000002                              UNIVERSIDAD NACIONAL DE SAN CRISTÓBAL DE HUAMANGA |
  3. | 160000003                             UNIVERSIDAD NACIONAL DE SAN ANTONIO ABAD DEL CUSCO |
  4. | 160000004                                               UNIVERSIDAD NACIONAL DE TRUJILLO |
  5. | 160000005                                            UNIVERSIDAD NACIONAL DE SAN AGUSTÍN |
  6. | 160000006                                             UNIVERSIDAD NACIONAL DE INGENIERÍA |
  7. | 160000007                                         UNIVERSIDAD NACIONAL AGRARIA LA MOLINA |
  8. | 160000009                                   UNIVERSIDAD NACIONAL SAN LUIS GONZAGA DE ICA |
  9. | 160000010                                       UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ |
 10. | 160000011                                    UNIVERSIDAD NACIONAL DE LA AMAZONÍA PERUANA |
 11. | 160000012                                             UNIVERSIDAD NACIONAL DEL ALTIPLANO |
 12. | 160000013                                                  UNIVERSIDAD NACIONAL DE PIURA |
 13. | 160000016                                              UNIVERSIDAD NACIONAL DE CAJAMARCA |
 14. | 160000021                                       UNIVERSIDAD NACIONAL FEDERICO VILLARREAL |
 15. | 160000022                                       UNIVERSIDAD NACIONAL AGRARIA DE LA SELVA |
 16. | 160000023                                         UNIVERSIDAD NACIONAL HERMILIO VALDIZAN |
 17. | 160000025                       UNIVERSIDAD NACIONAL DE EDUCACIÓN ENRIQUE GUZMÁN Y VALLE |
 18. | 160000026                                    UNIVERSIDAD NACIONAL DANIEL ALCIDES CARRIÓN |
 19. | 160000027                                                UNIVERSIDAD NACIONAL DEL CALLAO |
 20. | 160000028                             UNIVERSIDAD NACIONAL JOSÉ FAUSTINO SÁNCHEZ CARRIÓN |
 21. | 160000031                                          UNIVERSIDAD NACIONAL PEDRO RUÍZ GALLO |
 22. | 160000032                                    UNIVERSIDAD NACIONAL JORGE BASADRE GROHMANN |
 23. | 160000033                                UNIVERSIDAD NACIONAL SANTIAGO ANTÚNEZ DE MAYOLO |
 24. | 160000034                                             UNIVERSIDAD NACIONAL DE SAN MARTÍN |
 25. | 160000035                                                UNIVERSIDAD NACIONAL DE UCAYALI |
 26. | 160000041                                                 UNIVERSIDAD NACIONAL DE TUMBES |
 27. | 160000042                                                 UNIVERSIDAD NACIONAL DEL SANTA |
 28. | 160000051                                           UNIVERSIDAD NACIONAL DE HUANCAVELICA |
 29. | 160000075                                UNIVERSIDAD NACIONAL AMAZÓNICA DE MADRE DE DIOS |
 30. | 160000076                  UNIVERSIDAD NACIONAL TORIBIO RODRÍGUEZ DE MENDOZA DE AMAZONAS |
 31. | 160000077                              UNIVERSIDAD NACIONAL MICAELA BASTIDAS DE APURIMAC |
 32. | 160000084                              UNIVERSIDAD NACIONAL INTERCULTURAL DE LA AMAZONIA |
 33. | 160000088                                   UNIVERSIDAD NACIONAL TECNOLÓGICA DE LIMA SUR |
 34. | 160000089                                       UNIVERSIDAD NACIONAL JOSE MARIA ARGUEDAS |
 35. | 160000095                                               UNIVERSIDAD NACIONAL DE MOQUEGUA |
 36. | 160000098                                                UNIVERSIDAD NACIONAL DE JULIACA |
 37. | 160000101                                                   UNIVERSIDAD NACIONAL DE JAÉN |
 38. | 160000106                                                 UNIVERSIDAD NACIONAL DE CAÑETE |
 39. | 160000120                                         UNIVERSIDAD NACIONAL AUTÓNOMA DE CHOTA |
 40. | 160000121                                               UNIVERSIDAD NACIONAL DE BARRANCA |
 41. | 160000122                                               UNIVERSIDAD NACIONAL DE FRONTERA |
 42. | 160000123           UNIVERSIDAD NACIONAL INTERCULTURAL "FABIOLA SALAZAR LEGUÍA" DE BAGUA |
 43. | 160000124   UNIVERSIDAD NACIONAL INTERCULTURAL DE LA SELVA CENTRAL JUAN SANTOS ATAHUALPA |
 44. | 160000125                              UNIVERSIDAD NACIONAL INTERCULTURAL DE QUILLABAMBA |
 45. | 160000126                                 UNIVERSIDAD NACIONAL AUTÓNOMA DE ALTO AMAZONAS |
 46. | 160000127                              UNIVERSIDAD NACIONAL AUTÓNOMA ALTOANDINA DE TARMA |
 47. | 160000128                                        UNIVERSIDAD NACIONAL AUTÓNOMA DE HUANTA |
 48. | 160000138           UNIVERSIDAD NACIONAL AUTÓNOMA DE TAYACAJA "DANIEL HERNÁNDEZ MORILLO" |
 49. | 260000008                                       PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ |
 50. | 260000014                                           UNIVERSIDAD PERUANA CAYETANO HEREDIA |
 51. | 260000015                                            UNIVERSIDAD CATÓLICA DE SANTA MARÍA |
 52. | 260000017                                                       UNIVERSIDAD DEL PACÍFICO |
 53. | 260000018                                                            UNIVERSIDAD DE LIMA |
 54. | 260000019                                                   UNIV DE SAN MARTÍN DE PORRES |
 55. | 260000020                                       UNIVERSIDAD FEMENINA DEL SAGRADO CORAZÓN |
 56. | 260000024                                          UNIVERSIDAD INCA GARCILASO DE LA VEGA |
 57. | 260000029                                                           UNIVERSIDAD DE PIURA |
 58. | 260000030                                                      UNIVERSIDAD RICARDO PALMA |
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
	egen id_cutoff_department = group(codigo_modular id_anio id_periodo_postulacion id_codigo_facultad source)
	egen id_cutoff_major = group(codigo_modular id_anio id_periodo_postulacion id_carrera_primera_opcion source)

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
	bys id_cutoff_department: egen rank_score_raw_department = rank(score_raw), track
	bys id_cutoff_major: egen rank_score_raw_major = rank(score_raw), track

	*- How strict are the cutoffs?
	//bys id_cutoff : egen cutoff = min(cond(es_ingresante=="True",puntaje_postulante_std,.))
	//gen simulated = puntaje_postulante_std>=cutoff if puntaje_postulante_std!=. & cutoff!=.

	*- How can we define alternative cutoff that is not minimum?
	//gen cutoff2 = cutoff+0.5
	//gen simulated2 = puntaje_postulante_std>=cutoff2 if puntaje_postulante_std!=. & cutoff2!=.

	*- admitted student
	gen admitted = es_ingresante == "True" if es_ingresante !=""
	
	*- Since we have 'year' variable, we only need one 'id_per_pos' instead of a per-year one. This will save space.
	gen id_per_pos = .
	forvalues y = 2017/2023 {
		replace id_per_pos = id_per_pos`y' if year==`y'
		}
		
	
	//gen attended = 

	//tab simulated es_ingresante
	//tab  simulated es_ingresante if universidad == "PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ"
	//235,836 when codigo_modular 
	//212,353 when codigo_modular id_periodo_postulacion
	//170,079 when codigo_modular id_periodo_postulacion id_codigo_facultad
	//133,720 when removing 0'

	//gen rco = puntaje_postulante_std - cutoff
	//gen rco2 = puntaje_postulante_std - cutoff2

	//binsreg admitted rco if abs(rco)<10
	//binsreg admitted rco2 if abs(rco2)<10

	/*
	preserve
		keep if universidad == "PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ"
		keep if id_codigo_facultad == 1439
		keep if id_periodo_postulacion == 70
	restore

	sort id_cutoff puntaje_postulante

	br codigo_modular id_periodo_postulacion id_codigo_facultad puntaje_postulante puntaje_postulante* es_ingresante simulated carrera_primera_opcion /*carrera_segunda_opcion*/ carrera_ingreso  if puntaje_postulante_std!=. & cutoff!=. & universidad == "PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ"
	*/


	label var id_cutoff_department 			"Unique ID of application cutoff (department)"
	label var id_cutoff_major 				"Unique ID of application cutoff (major)"
	label var score_std_department 			"Standardized Score of application cutoff (department)"
	label var score_std_major 				"Standardized Score of application cutoff (major)"
	label var rank_score_raw_department 	"Ranked score raw (1=Lowest) (department)"
	label var rank_score_raw_major 			"Ranked score raw (1=Lowest) (major)"
	label var admitted 						"Was admitted to cutoff"

	label define yes_no 1 "Yes" 0 "No"
	label values admitted yes_no


			isvar 			///
				/*Match ID*/ id_persona_reco id_per_pos ///
				/*ID*/ year id_cutoff_department id_cutoff_major codigo_modular /*id_anio*/ id_codigo_facultad id_carrera id_carrera_homologada id_estado_persona id_periodo_postulacion id_periodo_matricula	universidad facultad ///
				/*Char UNI*/ university public licensed academic		///
				/*Char Indiv*/ 	dob age male	///
				/*applic info*/ id_major* name_major* carrera_primera_opcion score_raw score_std* rank_score_raw*	source issue	///
				/*admitt info*/ carrera_ingreso admitted ///
				/*enroll info*/ nota_promedio
			local all_vars = r(varlist)
			ds `all_vars', not
			keep `all_vars'
			order `all_vars'
			destring `all_vars', replace
			
			foreach v of local all_vars {
				capture confirm string variable `v'
					if _rc==0 {
						   replace `v' = trim(itrim(`v'))
					}
			}
			
	compress
	save "$TEMP\applied", replace

end


********************************************************************************
* Enrolled
********************************************************************************

capture program drop enrolled
program define enrolled

	if $excel == 0 use "$TEMP\enrolled_2017", clear
	if $excel == 1 {
		foreach y in "2017" "2018" "2019" "2020" "2021" "2022" "2023" {
			import delimited "$IN\MINEDU\Data_matriculados_siries_`y'_innominada.txt", clear
			compress
			save "$TEMP\enrolled_`y'", replace
		}
	}
		
	use "$TEMP\enrolled_2023", clear	
	describe, all	


	clear
	forvalues y = 2017/2023 {
		preserve
			use "$TEMP\enrolled_`y'", clear
			
			rename abreviatura_anio year
			
			isvar 			///
				/*ID*/ codigo_modular id_tipo_institucion id_tipo_gestion id_anio id_codigo_facultad id_carrera_primera_opcion id_carrera_homologada_primera_op id_estado_persona id_persona_reco id_periodo_postulacion id_periodo_matricula	universidad	year ///
				/*Char UNI*/ estatus_licenciamiento		///
				/*Char Indiv*/ 	fecha_nacimiento edad sexo	///
				/*applic info*/ carrera_primera_opcion		///
				/*admitt info*/ es_ingresante carrera_ingreso ///
				/*enroll info*/ nota_promedio 
			local all_vars = r(varlist)
			ds `all_vars', not
			keep `all_vars'
			order `all_vars'
			destring `all_vars', replace
			
			foreach v of local all_vars {
				capture confirm string variable `v'
					if _rc==0 {
						   replace `v' = trim(itrim(`v'))
					}
			}
			
			compress

			tempfile enrolled_`y'
			save `enrolled_`y'', replace	
		restore
		append using `enrolled_`y'', force
	}

	
	*- Institution type
	gen university = 1 if id_tipo_institucion=="UNIVERSIDADES" 
	replace university = 0 if id_tipo_institucion!="UNIVERSIDADES" & id_tipo_institucion!=""
	label var university "Type: University"
	label define university 0 "Other" 1 "University"
	label values university university		
	
	*- Public
	gen public = 1 if id_tipo_gestion=="PUBLICA" 
	replace public = 0 if id_tipo_gestion=="PRIVADA" 
	label var public "Administration: Public"
	label define public 0 "Private" 1 "Public"
	label values public public			
	
	*- Licensed
	gen licensed = 1 if estatus_licenciamiento=="LICENCIADA" 
	replace licensed = 0 if estatus_licenciamiento=="LICENCIA DENEGADA" 
	label var licensed "Status: Licensed"
	label define licensed 0 "License Denied" 1 "Licensed"
	label values licensed licensed		
	
	
	
			isvar 			///
				/*ID*/ codigo_modular  id_anio id_codigo_facultad id_carrera_primera_opcion id_carrera_homologada_primera_op id_estado_persona id_persona_reco id_periodo_postulacion id_periodo_matricula	universidad	year  ///
				/*Char UNI*/ licensed	public academic university	///
				/*Char Indiv*/ 	fecha_nacimiento edad sexo	///
				/*applic info*/ carrera_primera_opcion		///
				/*admitt info*/ es_ingresante carrera_ingreso ///
				/*enroll info*/ nota_promedio 
			local all_vars = r(varlist)
			ds `all_vars', not
			keep `all_vars'
			order `all_vars'
			destring `all_vars', replace
			
			foreach v of local all_vars {
				capture confirm string variable `v'
					if _rc==0 {
						   replace `v' = trim(itrim(`v'))
					}
			}
			
			compress
	

	save "$TEMP\enrolled", replace


end	


********************************************************************************
* ECE Socioeconomic
********************************************************************************


capture program drop socioecon
program define socioecon

	if $excel == 0 use "$TEMP\fam_2p_2015", clear
	if $excel == 1 {
		import excel "$IN\MINEDU\ECE EM innominada\Cuestionarios\ECE 2015\2do primaria\ECE 2P 2015 Cuestionario Familia.xlsx", sheet("Base de datos") firstrow clear
		compress
		save "$TEMP\fam_2p_2015", replace
		}

end

********************************************************************************
* School characteristics
********************************************************************************

capture program drop aggregate_school_characteristics
program define aggregate_school_characteristics

	*- FROM ECE DATABASE
	use "$TEMP\ece_siagie_final", clear	
	
	keep cod_mod7 anexo year grade polidoc public socioec_index spanish male 
	collapse socioec_index spanish male  /*indpe_pos* indpe_mat**/, by(cod_mod7 anexo year grade polidoc public)
	reshape wide socioec_index spanish male,i(cod_mod7 anexo year) j(grade)
	rename (socioec_index? spanish? male?) (socioec_index_g?_sch spanish_g?_sch male_g?_sch)
	
	isvar 			///
				/*ID*/  year cod_mod7 anexo public polidoc   ///
				/*Char school*/ male* spanish* socioec*		
			local all_vars = r(varlist)
			ds `all_vars', not
			keep `all_vars'
			order `all_vars'
			destring `all_vars', replace
	save "$TEMP\aggregate_school", replace
	
end

********************************************************************************
* School Aggregates: Score
********************************************************************************

capture program drop aggregates_score
program define aggregates_score

	*- FROM ECE DATABASE
	use "$TEMP\ece_siagie_final", clear	
	keep score_com_std score_math_std score_soc_std score_sci_std /**/ cod_mod7 anexo year grade
	collapse score_com_std score_math_std score_soc_std score_sci_std , by(cod_mod7 anexo year grade)
	reshape wide score_*std,i(cod_mod7 anexo year) j(grade)
	rename *std? *std_g?

	rename score* score*_sch
	save "$TEMP\aggregate_ece", replace
	
end


********************************************************************************
* School Aggregates: Applications and enrollment
********************************************************************************

capture program drop aggregates_app_enr
program define aggregates_app_enr
	
	use "$TEMP\ece_siagie_final", clear	
		
	*- Define expected cohort of begin/end given examination dates
	gen cohort_expected_begin 	= . 
	gen cohort_expected_finish 	= . 
	
	replace cohort_expected_begin 	= year - 1 if grade==2
	replace cohort_expected_finish 	= year + 10 if grade==2
	
	replace cohort_expected_begin 	= year - 3 if grade==4
	replace cohort_expected_finish 	= year + 8 if grade==4	

	replace cohort_expected_begin 	= year - 7 if grade==8
	replace cohort_expected_finish 	= year + 4 if grade==8	
	
	**# Should be ID SIAGIE instead? This ID is not unique within ECE.
	//bys id_estudiante: egen applied_ever 	= max(indpe_pos) if year >= cohort_expected_finish 
	//gen enrolled_ever 	= indpe_mat if year >= cohort_expected_finish 

	** ## If we don't see them in ECE 8 we don't have the CODMOD for now. Until we get SIAGIE data.
	*- Only consider application and enrollment match info for those who were in relevant cohorts
	gen pop = 1
	collapse (sum) pop (mean) indpe*, by(cohort_expected_finish grade cod_mod7 anexo)
	sort grade cohort_expected_finish
	list cohort_expected_finish grade pop indpe_pos*
	list cohort_expected_finish grade pop indpe_mat*
	
	keep if grade==8
	keep cohort_expected_finish grade cod_mod7 anexo indpe_*
	reshape long indpe_pos indpe_mat, i(cohort_expected_finish grade cod_mod7 anexo) j(year)
	drop if year<cohort_expected_finish
	
	gen applied_year1 	= indpe_pos if year == cohort_expected_finish
	gen applied_year2 	= indpe_pos if year == cohort_expected_finish + 1
	
	gen enrolled_year1 	= indpe_mat if year == cohort_expected_finish
	gen enrolled_year2 	= indpe_mat if year == cohort_expected_finish + 1
	gen enrolled_year4 	= indpe_mat if year == cohort_expected_finish + 3
	
	collapse applied* enrolled*, by(cohort_expected_finish cod_mod7 anexo)
	
	rename cohort_expected_finish year 
	rename applied* applied*_sch
	rename enrolled* enrolled*_sch
	
	save "$TEMP\aggregate_app_enroll", replace
	
	
	*- FROM SIAGIE DATABASE
	//Don't have this yet. This won't need to filter for cohorts since we would have all those who finished 11th grade.
	
	
end


********************************************************************************
* Run program
********************************************************************************

main