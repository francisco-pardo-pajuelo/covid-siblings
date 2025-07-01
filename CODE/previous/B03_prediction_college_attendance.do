/********************************************************************************
- Author: Francisco Pardo
- Description: Produces final tables and figures
- Date started: 08/12/2024
- Last update: 08/12/2024
*******************************************************************************/

capture program drop main 
program define main 

setup
prediction_college_attendance

end





********************************************************************************
* Setup
********************************************************************************

capture program drop setup
program define setup

	

end



********************************************************************************
* prediction_college_attendance
********************************************************************************

capture program drop prediction_college_attendance
program define prediction_college_attendance

use "$OUT\students", clear


	isvar ///
		/*ID*/				 ///
		/*Enrollment*/				enrolled enrolled_public ///
		/*Other*/			  ///
		/*Demographics*/	male_siagie exp_graduating_year1  ///
		/*SIBLING CHOICES*/	 ///
		/*ECE outcomes*/	year_?? score_math_std_?? score_com_std_?? aspiration_?? aspiration_?? aspiration_??
 
		local all_vars = r(varlist)
		ds `all_vars', not
		keep `all_vars'
		order `all_vars'

//Sample old enough to be enrolled
keep if exp_graduating_year1+1>=2017 & exp_graduating_year1+1<=2023

tab enrolled
tab enrolled_public

reg enrolled male_siagie score_math_std_2p score_com_std_2p  i.aspiration_2s socioec_index_2s i.educ_mother
predict enrolled_pred


logit enrolled male_siagie score_math_std_2p score_com_std_2p  i.aspiration_2s socioec_index_2s i.educ_mother
predict enrolled_lpred

scatter enrolled_pred enrolled_lpred 
//very similar. Let's stick with logit.

logit enrolled male_siagie score_math_std_2p score_com_std_2p  i.educ_mother
predict enrolled_lpred2
//In case we loose too many observations including 2S measures.


end


***** Run program

main


