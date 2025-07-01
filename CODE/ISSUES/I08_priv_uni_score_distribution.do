*- Some private universities have strange distributions. 

*-- Issue: 
/*


*/


use "$TEMP/applied"

bys universidad: gen N= _N

keep if N>100000

encode universidad, gen(uni)

tab uni source

/*
uni
PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ
UNIVERSIDAD CONTINENTAL
UNIVERSIDAD CÉSAR VALLEJO
UNIVERSIDAD NACIONAL DE SAN AGUSTÍN
UNIVERSIDAD NACIONAL DE SAN ANTONIO ABAD DEL CUSCO
UNIVERSIDAD NACIONAL DE SAN CRISTÓBAL DE HUAMANGA
UNIVERSIDAD NACIONAL DE TRUJILLO
UNIVERSIDAD NACIONAL DEL ALTIPLANO
UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS
UNIVERSIDAD PERUANA DE CIENCIAS APLICADAS
UNIVERSIDAD PRIVADA DEL NORTE
UNIVERSIDAD TECNOLÓGICA DEL PERÚ
*/


tabstat admitted,by(uni)
//Except for public and PUCP, rest has >50% admission rates.

*- 1. PONTIFICIA UNIVERSIDAD CATÓLICA DEL PERÚ
histogram score_raw if uni==1, bins(100)



*- 2. UNIVERSIDAD CONTINENTAL
histogram score_raw if uni==2 & source==0 & score_raw<=20 /*Fixing 2019 having >20 scores. Will be moved to source=1*/, bins(100) xline(10.5)
//Bunching just at the passing grade.

*- 3. UNIVERSIDAD CÉSAR VALLEJO
histogram score_raw if uni==3, bins(20) xline(10)
//Bunching just at the passing grade.


//All public universities look good.
*- 4. UNIVERSIDAD NACIONAL DE SAN AGUSTÍN
histogram score_raw if uni==4, bins(30)

*- 5. UNIVERSIDAD NACIONAL DE SAN ANTONIO ABAD DEL CUSCO
histogram score_raw if uni==5, bins(30)

*- 6. UNIVERSIDAD NACIONAL DE SAN CRISTÓBAL DE HUAMANGA
histogram score_raw if uni==6, bins(30)

*- 7. UNIVERSIDAD NACIONAL DE TRUJILLO
histogram score_raw if uni==7, bins(30)

*- 8. UNIVERSIDAD NACIONAL DEL ALTIPLANO
histogram score_raw if uni==8, bins(30)

*- 9. UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS
histogram score_raw if uni==9, bins(30)

*- 10. UNIVERSIDAD PERUANA DE CIENCIAS APLICADAS
histogram score_raw if uni==10 & year<=2018, bins(20)
histogram score_raw if uni==10 & year>=2019, bins(20)
//This could be percentiles?

binsreg admitted score_raw if uni==10 & year==2017, nbins(100)
binsreg admitted score_raw if uni==10 & year==2018, nbins(100)
binsreg admitted score_raw if uni==10 & year==2019, nbins(100)
binsreg admitted score_raw if uni==10 & year==2020, nbins(100)
binsreg admitted score_raw if uni==10 & year==2021, nbins(100)
binsreg admitted score_raw if uni==10 & year==2022, nbins(100)
binsreg admitted score_raw if uni==10 & year==2023, nbins(100)
//Not a clear pattern really, seems quite random.


*- 11. UNIVERSIDAD PRIVADA DEL NORTE
histogram score_raw if uni==11, bins(20)
binsreg admitted score_raw if uni==11, nbins(100) xline(7.5)
//Seems to have a clear cutoff and no bunching but >97% get in, so rejected could be very strange or below the cutoff.


*- 12. UNIVERSIDAD TECNOLÓGICA DEL PERÚ
histogram score_raw if uni==12, bins(20) xline(10)
binsreg admitted score_raw if uni==12 & score_raw<30, nbins(100)
// Similar to UPN, ~90% admission. And no clear cutoff. Admissions increase from 0 to 10 in score, quite uniformly.




//conclussion: Only salvable seems PUCP.




use "$TEMP/applied",clear

bys universidad: gen N= _N

keep if N<=100000
keep if N>50000
encode universidad, gen(uni)

tab uni source

tabstat admitted,by(uni)

//Again, private ones have pretty high admission rates.













