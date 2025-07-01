// Prepare data
global country "swe"

// use ag as fixed effect in some specifications
encode ag, generate(ag_fe)

// ------------------
// Variable labelling
// instprog=college-major, inst=college, prog=major
label variable same_inst_first 			"Sib. applies same inst (1)"
label variable same_inst_all 			"Sib. applies same inst"
label variable same_inst_enrolls 		"Sib. enrolls same inst"
label variable same_prog_first 			"Sib. applies same prog (1)"
label variable same_prog_all 			"Sib. applies same prog"
label variable same_prog_enrolls 		"Sib. enrolls same prog"
label variable same_instprog_first 		"Sib. applies same inst-prog (1)"
label variable same_instprog_all 		"Sib. applies same inst-prog"
label variable same_instprog_enrolls 	"Sib. enrolls same inst-prog"

label variable enrolled	    			"Older sibling enrolls"
label variable admitted 	   			"Older sibling is admitted"

label variable cutoff_distance          "Distance to cutoff (std)"
label variable above_cutoff             "Above cutoff"

label variable female                   "Female (older)"
label variable female_sib               "Female (younger)"
label variable age 						"Age (older)"
label variable age_sib 					"Age (younger)"
label variable foreign_born				"Foreign born (older)"
label variable foreign_parents			"Foreign born parents"
label variable n_siblings				"Number of siblings"

label variable par_earnings				"Parental earnings"
label variable par_dispinc				"Parental disposable income"
label variable par_edu_es				"Highest parental education: Elementary School"
label variable par_edu_hs				"Highest parental education: High School"
label variable par_edu_post_sec			"Highest parental education: Post-sec, not university"
label variable par_edu_tert				"Highest parental education: University"
label variable n_educated_parents 		"Number of parents with university education"

label variable jk_different_instprog	"Target and next-best in different program-institutions."
label variable jk_different_insts		"Target and next-best in institutions."
label variable jk_different_progs		"Target and next-best in different program/field."
label variable jk_different_progsB		"Target and next-best in different program/field (alternative specification)."

label variable sib_enrolls_STEM         "Sibling enrolls in STEM field"
label variable sib_apply1st_STEM        "Siblings top ranked choice is STEM field"

// -----------------
// Interaction terms
// -----------------

// -----------------
// Similarity
// - studying if the effect is stronger among more similar siblings

generate same_gender            		= female == female_sib
label variable same_gender 				"Same gender"

generate application_year_diff  		= application_year_sib - application_year
label variable application_year_diff    "Difference in the year of application"

label variable age_difference 			"Age difference"

generate age_diff_5yrs          		= age_difference >= 5
label variable age_diff_5yrs 			"Age difference, 5 or more years"

generate educated_parents 				= n_educated_parents > 0
label variable educated_parents			"At least one parent with university education."


// -----------------
// Selectivity
// - is the effect stronger when for better/more selective schools

label variable mean_gpa_admitted		"Mean GPA among admitted (standardized)"
label variable mean_gpa_admitted_delta	"Difference in mean GPA among admitted between j and k"

label variable retention_enrolled		"Share of enrolled students who stayed in program after first year."
label variable retention_enrolled_delta	"Difference in retention rate (j/k)"

label variable earnings_degrees			"Average standardized earnings 8 years after (among degree holders)"
label variable earnings_degrees_delta	"Difference in average earnings (j/k)"

// Selectivity for younger siblings' top ranked/enrolled choice
label variable mean_gpa_admitted_sib_top    "Sibling choice (top): Mean GPA among admitted (standardized)"
label variable retention_enrolled_sib_top	"Sibling choice (top): Share of enrolled students who finish the first year."
label variable earnings_degrees_sib_top     "Sibling choice (top): Average earnings 8 years after (among degree holders)"

label variable mean_gpa_admitted_sib_enr	"Sibling choice (enrolled): Mean GPA among admitted (standardized)"
label variable retention_enrolled_sib_enr	"Sibling choice (enrolled): Share of enrolled students who finish the first year."
label variable earnings_degrees_sib_enr		"Sibling choice (enrolled): Average earnings 8 years after (among degree holders)"

// STEM education
label variable is_STEM					"Target program is in STEM field"
generate jk_different_STEM				= (is_STEM == 1 & is_STEM_k == 0) | (is_STEM == 0 & is_STEM_k == 1)

// Individual level dropout
replace dropout_any						= 0 if missing(dropout_any)
label variable dropout_any				"Older sibling drops out (at some point) from whatever they enroll to."

// -----------------------------
// Younger sibling's performance

// Look only at those younger siblings who have yet to finish high school
label variable gpa_hs_sib				"Younger sibling's high school GPA"

// Swesat
label variable gpa_swesat_sib			"SweSAT score (younger sibling)"

generate swesat_w						= !missing(gpa_swesat)
label variable swesat_w					"Has written SweSAT (older sibling)"

generate swesat_w_sib					= !missing(gpa_swesat_sib)
label variable swesat_w_sib				"Has written SweSAT (younger sibling)"

// Age difference groups
egen age_diff_bins 						= cut(age_difference), at(0,3,5,100) label
label variable age_diff_bins			"Age difference in three bins (0-2, 3-4, 4+)"

// ----------------------------
// Additional robustness checks

generate sib_applies					= !missing(id_round_sib)
label variable sib_applies				"Younger sibling applies to university at some point"
label variable enrolled_any				"Older sibling enrolled in any alternative."
label variable enrolled_any_sib			"Younger sib enrolled in any alternative"

// ---
// Balance tests

// Parental education
label variable par_edu_es				"Parental ed: less than high school"
label variable par_edu_hs				"Parental ed: high school"
label variable par_edu_post_sec			"Parental ed: post-secondary not university"
label variable par_edu_tert				"Parental ed: university"

// Income groups
label variable par_dispinc_q12 			"Low income (quintile 1-2)"
label variable par_dispinc_q34 			"Mid income (quintile 3-4)"
label variable par_dispinc_q5 			"High income (quintile 5)"

// Categorical quintile variable
generate par_dispinc_q = 1 if par_dispinc_q5 // 1 is highest income (to align with Chile coding)
replace  par_dispinc_q = 2 if par_dispinc_q4
replace  par_dispinc_q = 3 if par_dispinc_q3
replace  par_dispinc_q = 4 if par_dispinc_q2
replace  par_dispinc_q = 5 if par_dispinc_q1
label variable par_dispinc_q "Parental disposable income quintile"

// Information - exposure to institutions in high school
label variable hs_peers_in_inst_sh      "Share of HS peers enrolling in target inst."

// ---------------------------------
// Select observations for data sets
// ---------------------------------

// 1. Main RD data
// 2. Placebo RD data

preserve

// --
// Main data
keep if sample_main_oldest

quietly compress
save "${path_input}/main_data_swe.dta", replace

exit 0
