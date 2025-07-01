*- Final Results

if c(username)=="franc" 	global 	DB = "C:\Users\franc\Dropbox\"
if c(username)=="Francisco" global 	DB = "C:\Users\Francisco\Dropbox\"
if c(username)=="fp4897" 	global 	DB = "C:\Users\fp4897\Dropbox\"

global IN_PREV "$DB\Alfonso_Minedu"



global DB_PROJECT "$DB\research\projectsX\18_aspirations_siblings_rank"
global DATA "$DB_PROJECT\DATA"
	global IN "$DATA\IN"
	global TEMP "$DATA\TEMP"
	global OUT "$DATA\OUT"
global CODE "$DB_PROJECT\CODE"	
global FIGURES "$DB_PROJECT\FIGURES"
global TABLES "$DB_PROJECT\TABLES"
global LOGS "$DB_PROJECT\LOGS"



capture program drop prepare_rd
program define prepare_rd


	local cell major
	local type noz
		
	rename *_`cell' *
	rename *_`type' * 

	*- Public schools
	keep if public==1

	*- Exclude those without estimated cutoffs
	keep if lottery_nocutoff == 0

	*- Exclude those at cutoff
	gen not_at_cutoff = (rank_score_raw!=cutoff_rank)		
	keep if not_at_cutoff==1

	*- Score relative
	gen score_relative = score_std - cutoff_std
	drop if score_relative==.	
	keep if abs(score_relative)<${window} 

	*- Run the RD regression
	gen ABOVE = (rank_score_raw>=cutoff_rank) if score_relative!=. //To avoid float issues around 0, we use the precisely integer rank scores.

	*- Polynomial
	forvalues p = 1/5 {
		gen score_relative_`p' 			= score_relative^`p'
		gen ABOVE_score_relative_`p' 	= ABOVE*score_relative_`p'
	}

	*- Remaining variables
	gen byte higher_ed_caretaker 	= inlist(educ_caretaker,7,8) if educ_caretaker!=. & educ_caretaker!=1 // =none seems to be partly missing
	gen byte higher_ed_mother 		= inlist(educ_mother,7,8) if educ_mother!=. & educ_mother!=1
	gen byte higher_ed_father 		= inlist(educ_father,7,8) if educ_father!=. & educ_father!=1
	gen byte sec_inc_caretaker 		= inlist(educ_caretaker,2,3,4) if educ_caretaker!=. & educ_caretaker!=1 
	gen byte sec_inc_mother 		= inlist(educ_mother,2,3,4) if educ_mother!=. & educ_mother!=1 
	gen byte sec_inc_father 		= inlist(educ_father,2,3,4) if educ_father!=. & educ_father!=1 
	gen byte pgrad_2p_foc			 = inlist(aspiration_2p_foc,5) if aspiration_2p_foc!=.
	gen byte pgrad_4p_foc			 = inlist(aspiration_4p_foc,5) if aspiration_4p_foc!=.
	gen byte pgrad_2s_foc			 = inlist(aspiration_2s_foc,5) if aspiration_2s_foc!=.
	gen byte pgrad_2p_sib			 = inlist(aspiration_2p_sib,5) if aspiration_2p_sib!=.
	gen byte pgrad_4p_sib			 = inlist(aspiration_4p_sib,5) if aspiration_4p_sib!=.
	gen byte pgrad_2s_sib			 = inlist(aspiration_2s_sib,5) if aspiration_2s_sib!=.
	gen aspiration_years_2s_sib 	 = 8*(aspiration_2s_sib==1)+ 11*(aspiration_2s_sib==2)+ 14*(aspiration_2s_sib==3)+ 16*(aspiration_2s_sib==4)+18*(aspiration_2s_sib==5) if  aspiration_2s_sib!=.
	


	*- Create sample of (i) 1 obs per student, (ii) one per year (iii) oldest sibling (iv) Those whose sibling could've applied
	bys id_persona_rec (semester_foc): gen byte sample_first_semester_app = semester_foc == semester_foc[1] 
	sort id_persona_rec semester_foc age, stable 
	gen n = _n
	bys id_persona_rec (semester_foc age n): gen sample_first_app = (_n==1) //there is some randomness, so we use n for replication.
	drop n

	gen sample_oldest = (fam_order_${fam_type} == 1)

	gen sample_applied_sib = (exp_graduating_year1_sib>=2016 & exp_graduating_year1_sib<=2022 & exp_graduating_year1_sib+1>year_app)


	*- Age gap
	gen age_gap = exp_graduating_year1_sib-exp_graduating_year1_foc


	global scores_1 		= "score_relative_1"
	global ABOVE_scores_1 	= "ABOVE_score_relative_1"

	global scores_2			= "score_relative_1 		score_relative_2"
	global ABOVE_scores_2 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2"


	global scores_3 		= "score_relative_1 		score_relative_2 		score_relative_3"
	global ABOVE_scores_3 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2 	ABOVE_score_relative_3"

	global scores_5 		= "score_relative_1 		score_relative_2 		score_relative_3 		score_relative_4 		score_relative_5"
	global ABOVE_scores_5 	= "ABOVE_score_relative_1 	ABOVE_score_relative_2 	ABOVE_score_relative_3 	ABOVE_score_relative_4 	ABOVE_score_relative_5"
	
	global controls = "" //"male o18.age" //omitted variable (constant) is at age 18.


end


