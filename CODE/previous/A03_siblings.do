

*---------------------------*
*-----	Identify Siblings
*---------------------------*
use "$TEMP\students", clear

*- Identify family IDs
keep id_ie_2p year_2p id_2p paterno_2p materno_2p nombres_2p std_?_?? m500_?_?? male_2p

bys id_ie_2p year_2p m500_m_2p m500_c_2p male_2p: gen N=_N
bys id_ie_2p seccion_2p year_2p  m500_m_2p m500_c_2p male_2p: gen N2=_N
bys id_ie_2p seccion_2p year_2p  m500_m_2p m500_c_2p male_2p: gen N3=_N

drop if paterno_2p =="" | materno_2p=="" | nombres_2p == ""

egen last_name_father_id = group(paterno_2p)
egen last_name_mother_id = group(materno_2p)
egen first_name_id = group(nombres_2p)

egen family_id = group(last_name_father_id last_name_mother_id id_ie_2p) // Same family if share both last names and primary school

*- We keep one individual per family
preserve
	bys id_2p (year_2p): keep if _n==1 						//first observation per individual
	bys family_id (year_2p id_2p)	: gen sib_order = _n 	//List siblings in a family
	bys family_id 					: gen sib_tot = _N 		//Total siblings
	keep if inlist(sib_tot,2)==1 							//Keep only cases of 2 siblings
	bys family_id 					: egen oldest_year_2p = min(year_2p)
	bys family_id 					: egen youngest_year_2p = max(year_2p)
	keep if oldest_year_2p!=youngest_year_2p
	
	*- Consider match in other variables (demographics of parents)
	*-- Education level
	
	*-- ISE
	
	*-- Mother tongue
	
	
	*- Create outcomes
	bys family_id:			egen 
restore

compress 

sort paterno_2p materno_2p nombres_2p id_ie_2p year_2p, stable
by paterno_2p materno_2p nombres_2p id_ie_2p (year_2p): keep if _n==1

duplicates tag paterno_2p materno_2p nombres_2p id_ie_2p, gen(dup_student) //We should have a unique ID for student 
tab dup_student

duplicates tag paterno_2p materno_2p id_ie_2p, gen(dup_ie)
tab dup_ie 

sort paterno_2p materno_2p year_2p  nombres_2p 
br id_2p id_ie_2p paterno_2p materno_2p nombres_2p year_2p if dup_ie==10

*- Let's drop cases with more than 5 siblings (0=only child, 5=6 siblings)
drop if dup_ie>=5

egen hh_id = group(paterno_2p materno_2p id_ie_2p)

sort hh_id year_2p nombres_2p
by hh_id: gen sib_order = _n

*- Potential applicants:
  //2P: 2007,2008,2009: Applying 2017,2018,2019
  //Outcome on younger sibling from 2012,2013 (2S 2018,2019 and applying 2022,2023)
  // For 2009 we also may have outcome from 2S 2015.
  
*- Siblings in 2S 2015 (applied 2019) and 2S 2019
