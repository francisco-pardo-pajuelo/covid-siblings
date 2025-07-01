

*---------------------------*
*-----	Identify Siblings
*---------------------------*
use "$TEMP\students", clear

*- Identify siblings
keep if year_2p <= 2012
drop if paterno_2p =="" | materno_2p==""

sort paterno_2p materno_2p nombres_2p id_ie_2p year_2p, stable
by paterno_2p materno_2p nombres_2p id_ie_2p: keep if _n==1

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
