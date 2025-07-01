*- Issue: Validating the number of siblings found. There are some inconsistencies.


*- Example:

use "$OUT/students", clear
tab fam_total_2 fam_total_4 if fam_total_2 <3 & fam_total_4<3
//Why are there cases of 2 in fam_total_4 and 1 in fam_total_2, if the fam_total_2 only requires ID of mother. Shouldn't it always be bigger?

replace total_siblings_2s = 0 if total_siblings_2s==99
keep if total_siblings_2s!=.
gen fam_size = total_siblings_2s+1
binsreg fam_size fam_total_2 if fam_total_2<10
pwcorr fam_size fam_total_* if fam_size<5 & fam_total_1<5  & fam_total_2<5  & fam_total_3<5  & fam_total_4<5 
count if fam_size==fam_total_2
count if fam_size!=fam_total_2
//Most cases does not match but still seems like overall we have a good proxy on quality of sibling matches based on the plot. It might not be identifying all but it is identifying siblings

// Doesnt this mean the rate of match becomes higher as the age gap increases?

*- Conclussion: 

*- After though:  

*- Reference:  

/*

*/