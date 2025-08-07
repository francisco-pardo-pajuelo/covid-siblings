
	
						//twfe_cohorts //Should not be done as it does not address the age trend.
	*- TWFE by grade
	twfe_grades siblings
	*- Placebo TWFE by grade
	//twfe_placebo_grades internet
	twfe_placebo_grades parent_ed
	twfe_placebo_grades both_parents
	
	*- TWFE Estimates
	twfe_summary siblings

	*- Placebo TWFE
	//twfe_placebo internet
	twfe_placebo parent_ed
	twfe_placebo both_parents	
	
	//twfe_A //School characteristics
	//twfe_B //Student demographics - gender and age
	//twfe_C //Family Structure - Siblings
	//twfe_D //Family Structure - Parents	