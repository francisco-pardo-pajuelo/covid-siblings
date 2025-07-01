//close
open

drop  if score_raw==0

bys universidad year: egen max_score = max(score_raw)
bys universidad year: egen min_score = min(score_raw)
bys universidad year: gen N=_N


gen mark = 1 if min_score<50 & max_score>1000

keep if mark==1



tab universidad year if N<10000 & N>5000

histogram score_raw if year==2017


	levelsof universidad if year==2023 & N<10000 & N>5000, local(levels)

	foreach l of local levels {
		histogram score_raw if universidad==`"`l'"' & year==`y's
	}
	
local y = 2023
local l = `"UNIVERSIDAD NACIONAL SANTIAGO ANTÚNEZ DE MAYOLO"'

tab score_raw  if universidad == `"`l'"' & year==`y' & score_raw<200
tab score_raw  if universidad == `"`l'"' & year==`y'
sum score_raw  if universidad == `"`l'"' & year==`y', de 
histogram score_raw if universidad == `"`l'"' & year==`y', bins(50)
histogram score_raw if universidad == `"`l'"' & year==`y' & score_raw<1500, bins(50)



*>5,000

/*
2018
2019
UNIVERSIDAD ANDINA DEL CUSCO
???
*/


2022
UNIVERSIDAD NACIONAL DE MOQUEGUA
1000

2021
UNIVERSIDAD NACIONAL DE JULIACA
20

2022 (//2023?)
UNIVERSIDAD NACIONAL DE JULIACA
20

2018
UNIVERSIDAD NACIONAL JORGE BASADRE GROHMANN
500


//
2020
UNIVERSIDAD NACIONAL DE PIURA
1000

2020
UNIVERSIDAD ANDINA DEL CUSCO
150

2021
UNIVERSIDAD NACIONAL DE JULIACA
20


2017
UNIV DE SAN MARTÍN DE PORRES
20

2018
UNIV DE SAN MARTÍN DE PORRES
20

2019
UNIV DE SAN MARTÍN DE PORRES
20

2021
UNIV DE SAN MARTÍN DE PORRES
20



*>10,000
local y = 2017
local l = `"UNIVERSIDAD NACIONAL DEL ALTIPLANO"'
300

local y = 2018
local l = `"UNIVERSIDAD NACIONAL DEL ALTIPLANO"'
500

local y = 2019
local l = `"UNIVERSIDAD NACIONAL DEL ALTIPLANO"'
500

local y = 2020
local l = `"UNIVERSIDAD CONTINENTAL"'
1000


local y = 2020
local l = `"UNIV DE SAN MARTÍN DE PORRES"'
20.1

local y = 2023
local l = `"UNIVERSIDAD NACIONAL DE PIURA"'
500


local y = 2023
local l = `"UNIVERSIDAD NACIONAL DEL CENTRO DEL PERÚ"'
20.1

