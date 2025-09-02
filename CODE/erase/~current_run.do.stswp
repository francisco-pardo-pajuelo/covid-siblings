*- 1. Final gender
*- 2. Robust TWFE (Private, Rural, Internet, )
*- 3. Event study placebo




	
	
capture noisily {
	//twfe_ece_gender siblings oldest
	//twfe_ece_gender siblings all
	
	
	setup_COVID_A03
	twfe_summary 	siblings oldest
	
	
	event_gpa		parent_ed oldest
}
if _rc == 0 {
    finished
    display as result "Program completed successfully"
}
else {
    finished
    display as error "Program ended with errors"
}

