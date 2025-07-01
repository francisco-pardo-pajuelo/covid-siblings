
	use "$TEMP\rd_issue", clear
	

		rddensity score, c(0) plot
	
	graph export 	"$FIGURES/eps/rd_issue.eps", replace	
	graph export 	"$FIGURES/png/rd_issue.png", replace	
	graph export 	"$FIGURES/pdf/rd_issue.pdf", replace