*- Distance from each school to each university

use "$TEMP\applied", clear
keep codigo_modular codigo_ubigeo public semester
bys codigo_modular codigo_ubigeo semester: gen N_applicants = _N
bys codigo_modular codigo_ubigeo: egen N_applicants_avg = mean(N_applicants)
bys codigo_modular codigo_ubigeo: keep if _n==1
gen dd = floor(codigo_ubigeo/10000)
tempfile add_info_uni
save `add_info_uni', replace

use "$IN\ADDITIONAL\universities_coord", clear
count 
local uni_N = r(N)
merge 1:1 codigo_modular codigo_ubigeo using `add_info_uni', keepusing(public dd N_applicants_avg) nogen
gen id=1
tempfile uni_coord
save `uni_coord', replace

use "$OUT/schools_20241018", clear
keep id_ie lat_ie lon_ie ubigeo
drop if lat_ie==0 | lon_ie==0
drop if lon_ie>-50
gen dd = floor(ubigeo/10000)
count 
local school_N = r(N)
gen id=1

di `uni_N'*`school_N' //If including all possible combinations

joinby id dd using `uni_coord'

//geodist lat1 lon1 lat2 lon2 [if] [in] , generate(new_dist_var)

geodist lat_ie lon_ie lat_uni lon_uni, gen(dist_school_uni)

//Distance to closest UNI
bys id_ie: egen min_dist_uni = min(dist_school_uni)

//Distance to closest PUBLIC
bys id_ie: egen min_dist_uni_public = min(cond(public==1,dist_school_uni,.))

//Distance to closest PRIVATE
bys id_ie: egen min_dist_uni_private = min(cond(public==0,dist_school_uni,.))

//Distance to closest PRIVATE > 100
bys id_ie: egen min_dist_uni_public50 = min(cond(public==1 & N_applicants_avg>50,dist_school_uni,.))

//Distance to closest PRIVATE > 100
bys id_ie: egen min_dist_uni_private50 = min(cond(public==0 & N_applicants_avg>50,dist_school_uni,.))


bys id_ie: keep if _n==1

//keep id_ie min_dist*

order id_ie ubigeo lat_ie lon_ie codigo_modular codigo_ubigeo lat_uni lon_uni public min_dist_uni min_dist_uni_public min_dist_uni_private min_dist_uni_public50 min_dist_uni_private50

drop dd id N_applicants_avg dist_school_uni

save "$TEMP\school_uni_distances", replace


scatter min_dist_uni_public min_dist_uni_private, ///
	xtitle("Distance to closest Private University (KM)") ///
	ytitle("Distance to closest Public University (KM)") ///
	mcolor(gs0%20) ///
	msymbol(oh)
	graph export 	"$FIGURES/png/distances_school_to_public_private_uni.png", replace	
	graph export 	"$FIGURES/eps/distances_school_to_public_private_uni.eps", replace	
	graph export 	"$FIGURES/pdf/distances_school_to_public_private_uni.pdf", replace	
	
	
	