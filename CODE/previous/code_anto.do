use "$TEMP/applied_final.dta", clear

bys id_cutoff: egen has_score = count(score_raw)


drop if has_cutoff == 1 //has no cutoff estimated

bys id_cutoff: egen max_non_admitted 	= max(cond(admitted==0,rank_score_raw,-1))
bys id_cutoff: egen min_admitted 		= min(cond(admitted==1,rank_score_raw,.))

/*
*****
gen mark = 1 if min_admitted==. | has_score==0
keep if min_admitted==.
keep if has_score>0
list id_cutoff if _n==1
br id_cutoff cutoff_rank rank_score_raw if id_cutoff==1618
*****
*/

count if max_non_admitted<min_admitted & (max_non_admitted!=-1 & min_admitted!=.) // !=-1 & !=. is just a condition to say there is at least 1 non admitted and 1 admitted

tab admitted if max_non_admitted<min_admitted & (max_non_admitted!=-1 & min_admitted!=.)  & score_relative<-0.001
tab admitted if max_non_admitted<min_admitted & (max_non_admitted!=-1 & min_admitted!=.)  & score_relative>0.001

list id_cutoff if max_non_admitted<min_admitted & (max_non_admitted!=-1 & min_admitted!=.)  & score_relative<-0.001 & admitted==1

order  id_cutoff cutoff_rank cutoff_std rank_score_raw score_std admitted max_non_admitted min_admitted score_relative
br id_cutoff cutoff_rank cutoff_std rank_score_raw score_std admitted max_non_admitted min_admitted score_relative if id_cutoff==367
tab admitted if max_non_admitted<min_admitted & (max_non_admitted!=-1 & min_admitted!=.)  & score_relative<-0.001 & id_cutoff==367


binscatter admitted score_relative if max_non_admitted<min_admitted, n(100)

order  id_cutoff cutoff_rank cutoff_std rank_score_raw score_std admitted   score_relative
br id_cutoff cutoff_rank cutoff_std rank_score_raw score_std admitted   score_relative if id_cutoff==367
keep if id_cutoff == 367
gen above = rank_score_raw>=138 if !missing(rank_score_raw)
reg admitted above
di (((2*ttail(e(df_r), abs(_b[above]/_se[above])))<=0.01) | ((2*ttail(e(df_r), abs(_b[above]/_se[above])))==.))
