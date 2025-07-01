clear
capture log close

	*cd "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files"
	
*** STEP 1-5 GENERATES DATA, REQUIRES ABOUT 4 HRS  ON BATCH (one master file 1.3m obs and a baseline file 263K obs)
*** STEP 6-9 GENERATES ALL FIGURES, ALL TABLES AND ALL DIGITS MENTIONED IN THE PAPER, REQUIRES ABOUT 45 MINS ON BATCH
*** STEP 10-13 ARE TABLE A9 GMM TESTS, AND A SIMILAR TEST FOLLOWING A STATEMENT ON PAGE - THESE REQUIRE SEVERAL HOURS
	
	*** The output is found in the folder "\AEJ_do_files\Output  
	***								1) the subfolder "Figures" contains all figures
	***								2) tables.rtf stores all tables in a single word-file EXCEPT Tables 2, 5 (F-TESTS), 6, A1, A3 AND A8
	***								3) two log files contain analyses to complements tables (step 8) and digits from the paper (step 9) 
	***								4) separate log-files are produced for each step 10-13

******		1
******The step1-program sets up all years of applicants into one file, each individuals choices in rank-order, deleting redundant choices (e.g. choice 3 if ind i accepted to choice 2). 
	do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\step1.do"
	
	*do step1.do

******		2
******The step2-program looks for improbable / potentially erroneous values of being accepted (variable name "Sint"). Essentially, if only one out of a large number of individuals is 
*accepted below a certain GPA value, this is likely to be a typo. That observation will later be dropped. Concerns only a small fraction of the sample. 
	do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\step2.do"
	
	*do step2.do

******		3
******The step3-program applies the corrected values of Sint to identify cells and define the cutoff GPA.
	do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\step3.do"
	
	*do step3.do

******		4
******The step4-program focus on individuals accepted to 3rd, 4th, 5th or 6th choice, and identfies the non-accepted program with the lowest cutoff GPA (the ind was closest to be accepted to) 
*This is the field we will later refer to as the first (preferred) choice. 
	do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\step4.do"
	
	*do step4.do

******		5
******The step5-program merges the info from the ALL previous files, step1, step2, step3 & step4, and cleans up doubles (same individual applying to the same program twice in the same year/region). 
*It then goes on to merge data with explanatory variables and outcome variables from a number of administrative registers held by Statistics Sweden.
*The data sources merged include:
***			- "Avgångsregister gymnasiet" which report yearly from 1973 the completion of high school majors
***			- Multiple generation register (info on parents)
***			- population data of GPA, only available from 1988 (born 1972) and only used in one number reported in the paper
***			- Foreign background 
***			- from "LISA" of Statistics Sweden is collected various variables, compiled in files with yearly data, and re-modeled to age-specific data 
***					(e.g. age 38 occurs in different years for diff birth-cohorts), including occupation (ssyk), income (ForvInk), income including parental and sick-leave (SjukRe ForPeng),  
***					level of education completed (sun), field of study completed (inr)
***			- 
 
	do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\step5.do"
	
	*do step5.do

	
******		6
******This program runs all figures in the paper, including appendix figures. All figures can then be found in the folder "\AEJ_do_files\Output\Figures".
	do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\figures_AEJ.do"
	
	*do figures_AEJ.do

		
	
	

******		7
******This program runs most of the regressions of the paper (including, to start, two "page-by-page"-numbers requiring regressions).
******All output is stored (appended) in "tables.rtf" found under "\AEJ_do_files\Output\".
	do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\results_AEJ.do"
	
	*do results_AEJ.do

	
	
******		8
******This program adds extra analyses not contained in the previous step but presented in various tables in the paper
******Results are stored in output-log-file "log_stats.log" found under "\AEJ_do_files\Output\". 
	do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\stats_AEJ.do"
	
	*do stats_AEJ.do

	
	
******		9
******This program consists of small bits of syntaxes for numbers mentioned on various pages in the manuscript but not reported in tables 
******The output is contained in the log-file "log_pagebypage.log" under "\AEJ_do_files\Output\".
	do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\page_by_page_AEJ.do"
	
	*do page_by_page_AEJ.do

		
	
******		10
******This program generates the data needed for tests related to Table A9 and section 3.2
	do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\TableA9_data.do"
	
	*do TableA9_data.do

	
******		11
******This program contains Table A9 tests for statistical difference between estimates presented.
******It is the first of several GMM regressions to test which require between 3 and 7 hours each
	do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\tests_table_A9ols_AEJ.do"
	
	*do tests_table_A9ols_AEJ.do

	
	
******		12
******This program contains the second Table A9 tests for statistical difference between estimates presented.
******It is the second GMM regressions to test which require between 3 and 7 hours each
	do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\tests_table_A9klm_AEJ.do"
	
	*do tests_table_A9klm_AEJ.do

	
	
******		13
******This program contains the third GMM regressions to test for statistical difference between estimates presented.
******It requires between 3 and 7 hours 
******The test is for a note in Section 3.2 where we state:
****** "when we re-run our analysis excluding those who drop out or switch to the non-academic track none of the resulting estimates are statistically different from the baseline" 
	do "\\micro.intra\projekt\P0484$\P0484_Gem\Educ content\Main\AEJ_do_files\tests_section_3_2_AEJ.do"
	
	*do tests_section_3_2_AEJ.do

			
****
****

	
