*- School closures: UNESCO


import excel "$IN\UNESCO\school_closures\UNESCO_school_closures_database.xlsx", sheet("database") firstrow allstring clear


destring Weekspartiallyopen Weeksfullyclosed, replace

gen weeks_not_fully_open = Weekspartiallyopen + Weeksfullyclosed

gen radio 	= DistancelearningmodalitiesRa=="Yes" if inlist(Status,"Closed due to COVID-19","Partially open")==1
gen tv 		= DistancelearningmodalitiesTV=="Yes" if inlist(Status,"Closed due to COVID-19","Partially open")==1
gen online 	= DistancelearningmodalitiesOn=="Yes" if inlist(Status,"Closed due to COVID-19","Partially open")==1

bys Country: egen p_radio 	= mean(radio)
bys Country: egen p_tv 		= mean(tv)
bys Country: egen p_online 	= mean(online)

bys Country: keep if _n==1

rename CountryID CNT

graph hbar (mean) Weeksfullyclosed if Weeksfullyclosed>=30, over(Country, sort(1) label(labsize(*0.3)))  
graph hbar (mean) weeks_not_fully_open if weeks_not_fully_open>=70, over(Country, sort(1) label(labsize(*0.3)))  

compress
save "$TEMP\COVID\school_closure_country", replace