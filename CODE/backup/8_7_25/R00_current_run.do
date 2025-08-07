*- A01

setup_A01
	
define_labels

siagie

sibling_id

average_data
	
additional_data

*- A02

do "C:\Users\franc\Dropbox\\research\projectsX\\18_aspirations_siblings_rank\CODE\A04_clean_final"


*- A01 COVID

	setup_COVID
	
	clean_data
	
	//internet_census
	
	*DOB_scatter
	
	*- Raw trends
	raw_gpa_trends siblings

	raw_gpa_trends parent_ed
	raw_gpa_trends both_parents
	raw_gpa_trends t_born
	raw_gpa_trends t_born_Q2
	*raw_histograms
	
	//ece_baseline_netherlands
	
	*- TWFE Estimates
	twfe_summary siblings
	//twfe_A //School characteristics
	//twfe_B //Student demographics - gender and age
	//twfe_C //Family Structure - Siblings
	//twfe_D //Family Structure - Parents
	
	*- Event Study 
	event_gpa	
	
	*- Placebo TWFE
	//twfe_placebo internet
	twfe_placebo parent_ed
	//twfe_placebo both_parents
	
						//twfe_cohorts //Should not be done as it does not address the age trend.
	*- TWFE by grade
	twfe_grades siblings
	*- Placebo TWFE by grade
	//twfe_placebo_grades internet
	twfe_placebo_grades parent_ed
	//twfe_placebo_grades both_parents
	

	
	