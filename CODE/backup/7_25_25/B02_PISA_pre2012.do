*- PISA

*https://webfs.oecd.org/pisa2022/index.html
/*

//






*/


capture program drop main 
program define main 

	setup_PISA
	
	import_data_2000
	import_data_2003
	import_data_2006
	import_data_2009
	import_data_2012
	import_data_2015
	import_data_2018
	import_data_2022
	
	import_data_2018_D //Pisa for LMIC

	append_years
	
end


capture program drop setup_PISA
program define setup_PISA

	di "SETUP"
	
	colorpalette  HCL blues, selec(2 5 8 11) nograph
	return list

	global blue_1 = "`r(p1)'"
	global blue_2 = "`r(p2)'"
	global blue_3 = "`r(p3)'"
	global blue_4 = "`r(p4)'"
	
	colorpalette  HCL reds, selec(2 5 8 11) nograph
	return list

	global red_1 = "`r(p1)'"
	global red_2 = "`r(p2)'"
	global red_3 = "`r(p3)'"	
	global red_4 = "`r(p4)'"	
	
		colorpalette  HCL greens, selec(2 5 8 11) nograph
	return list

	global green_1 = "`r(p1)'"
	global green_2 = "`r(p2)'"
	global green_3 = "`r(p3)'"		
	global green_4 = "`r(p4)'"
	
	
end

capture program drop import_data_2000 
program define import_data_2000 



end

capture program drop import_data_2000 
program define import_data_2000 



end

capture program drop import_data_2003
program define import_data_2003



end

capture program drop import_data_2006
program define import_data_2006



end

capture program drop import_data_2009
program define import_data_2009


	clear
	set more off

	*-----------------------------*
	* 1. Import fixed-width data  *
	*-----------------------------*

	infix ///
		str3   CNT         1-3 ///
		str3   COUNTRY     4-6 ///
		byte   OECD        7 ///
		str5   SUBNATIO    8-12 ///
		str5   SCHOOLID    13-17 ///
		str5   StIDStd     18-22 ///
		byte   ST01Q01     23-24 ///
		byte   ST02Q01     25-26 ///
		str2   ST03Q02     27-28 ///
		str4   ST03Q03     29-32 ///
		byte   ST04Q01     33 ///
		byte   ST05Q01     34 ///
		int    ST06Q01     35-39 ///
		byte   ST07Q01     40 ///
		byte   ST07Q02     41 ///
		byte   ST07Q03     42 ///
		byte   ST08Q01     43 ///
		byte   ST08Q02     44 ///
		byte   ST08Q03     45 ///
		byte   ST08Q04     46 ///
		byte   ST08Q05     47 ///
		byte   ST08Q06     48 ///
		str4   ST09Q01     49-52 ///
		byte   ST10Q01     53 ///
		byte   ST11Q01     54 ///
		byte   ST11Q02     55 ///
		byte   ST11Q03     56 ///
		byte   ST11Q04     57 ///
		byte   ST12Q01     58 ///
		str4   ST13Q01     59-62 ///
		byte   ST14Q01     63 ///
		byte   ST15Q01     64 ///
		byte   ST15Q02     65 ///
		byte   ST15Q03     66 ///
		byte   ST15Q04     67 ///
		byte   ST16Q01     68 ///
		byte   ST17Q01     69 ///
		byte   ST17Q02     70 ///
		byte   ST17Q03     71 ///
		int    ST18Q01     72-76 ///
		byte   ST19Q01     77 ///
		byte   ST20Q01     78 ///
		byte   ST20Q02     79 ///
		byte   ST20Q03     80 ///
		byte   ST20Q04     81 ///
		byte   ST20Q05     82 ///
		byte   ST20Q06     83 ///
		byte   ST20Q07     84 ///
		byte   ST20Q08     85 ///
		byte   ST20Q09     86 ///
		byte   ST20Q10     87 ///
		float 	PV1MATH    745  -  752  ///
		float 	PV2MATH    753  -  760  ///
		float 	PV3MATH    761  -  768  ///
		float 	PV4MATH    769  -  776  ///
		float 	PV5MATH    777  -  784  ///
		float 	PV1READ    785  -  792  ///
		float 	PV2READ    793  -  800  ///
		float 	PV3READ    801  -  808  ///
		float 	PV4READ    809  -  816  ///
		float 	PV5READ    817  -  824  ///
		float 	PV1SCIE    825  -  832  ///
		float 	PV2SCIE    833  -  840  ///
		float 	PV3SCIE    841  -  848  ///
		float 	PV4SCIE    849  -  856  ///
		float 	PV5SCIE    857  -  864  ///
		float 	PV1READ1   865  -  872  ///
		float 	PV2READ1   873  -  880  ///
		float 	PV3READ1   881  -  888  ///
		float 	PV4READ1   889  -  896  ///
		float 	PV5READ1   897  -  904  ///
		float 	PV1READ2   905  -  912  ///
		float 	PV2READ2   913  -  920  ///
		float 	PV3READ2   921  -  928  ///
		float 	PV4READ2   929  -  936  ///
		float 	PV5READ2   937  -  944  ///
		float 	PV1READ3   945  -  952  ///
		float 	PV2READ3   953  -  960  ///
		float 	PV3READ3   961  -  968  ///
		float 	PV4READ3   969  -  976  ///
		float 	PV5READ3   977  -  984  ///
		float 	PV1READ4   985  -  992  ///
		float 	PV2READ4   993  -  1000 ///
		float 	PV3READ4   1001  -  1008	///
		float 	PV4READ4   1009  -  1016	///
		float 	PV5READ4   1017  -  1024	///
		float 	PV1READ5   1025  -  1032	///
		float 	PV2READ5   1033  -  1040	///
		float 	PV3READ5   1041  -  1048	///
		float 	PV4READ5   1049  -  1056	///
		float 	PV5READ5   1057  -  1064	///
		using "$IN\PISA\2009\INT_STQ09_DEC11.txt"

	*-----------------------------*
	* 2. Variable Labels          *
	*-----------------------------*

	label variable CNT      "Country code 3-character"
	label variable COUNTRY  "Country code ISO 3-digit"
	label variable OECD     "OECD country"
	label variable SUBNATIO "Adjudicated sub-region"
	label variable SCHOOLID "School ID 5-digit"
	label variable StIDStd  "Student ID 5-digit"
	label variable ST01Q01  "Grade"
	label variable ST02Q01  "<Programme>"
	label variable ST03Q02  "Birth Month"
	label variable ST03Q03  "Birth Year"
	label variable ST04Q01  "Sex"
	label variable ST05Q01  "Attend <ISCED 0>"

	*-----------------------------*
	* 3. Value Labels             *
	*-----------------------------*
	/*
	label define CNT_lbl ///
		"ALB" "Albania" ///
		"ARG" "Argentina" ///
		"AUS" "Australia" ///
		"AUT" "Austria" ///
		"AZE" "Azerbaijan" ///
		"BEL" "Belgium" ///
		"BRA" "Brazil" ///
		"BGR" "Bulgaria" ///
		"CAN" "Canada" ///
		"CHL" "Chile" ///
		"USA" "United States" 
	label values CNT CNT_lbl

	label define COUNTRY_lbl ///
		"008" "Albania" ///
		"032" "Argentina" ///
		"036" "Australia" ///
		"040" "Austria" ///
		"056" "Belgium" ///
		"076" "Brazil" ///
		"124" "Canada" ///
		"152" "Chile" ///
		"840" "United States"
	label values COUNTRY COUNTRY_lbl
*/

	*-------------------------------*
	* 		Has siblings			*	
	*-------------------------------*
	
	*- Who usually lives at home with you?	
	gen sibs = .
	replace sibs = 0 if inlist(ST08Q03,1,2)==1 	| inlist(ST08Q04,1,2)==1 //Defined if yes/no at least for one.
	replace sibs = 1 if inlist(ST08Q03,1)==1 	| inlist(ST08Q04,1)==1 //Defined as YES if yes at least for one.

	
	*-----------------------------*
	* 4. Save the dataset         *
	*-----------------------------*


	destring COUNTRY
	rename COUNTRY CNTRYID
	gen year = 2009
	compress	
	
	save "$TEMP\COVID\pisa_student_2009.dta", replace


end

capture program drop import_data_2012
program define import_data_2012

*************************************
* PISA Student Data Import Do-file
* Generated from SPSS syntax: SPSS syntax to read in student questionnaire data file.txt
*************************************

	clear
	set more off

	*************************************
	* PISA Student Data Import Do-file
	* Generated from SPSS syntax: SPSS syntax to read in student questionnaire data file.txt
	*************************************

	*-----------------------------*
	* 1. Import fixed-width data  *
	*-----------------------------*

	infix ///
		str3 CNT       	1-3     ///
		str3 CNTRYID   	4-6     ///
		str5 SUBNATIO  	7-11    ///
		str5 SCHOOLID  	12-16   ///
		str5 STIDSTD   	17-21   ///
		byte OECD		18-18	///
		str6 NC 		19 - 24 ///
		byte ST01Q01   	22-22   ///
		byte ST02Q01   	23-23   ///
		str2 ST03Q02   	24-25   ///
		str4 ST03Q03   	26-29   ///
		byte ST04Q01   	30-30   ///
		byte ST05Q01   	31-31   ///
		int  ST06Q01   	32-36   ///
		byte ST07Q01   	37-37   ///
		byte ST07Q02   	38-38   ///
		byte ST07Q03   	39-39   ///
		byte ST08Q01   	40-40   ///
		byte ST08Q02   	41-41   ///
		byte ST08Q03   	42-42   ///
		byte ST08Q04   	43-43   ///
		byte ST08Q05   	44-44   ///
		byte ST08Q06   	45-45   ///
		str4 ST09Q01   	46-49   ///
		byte ST10Q01   	50-50   ///
		byte ST11Q01   	60-60   ///
		byte ST11Q02   	61-61   ///
		byte ST11Q03   	62-62   ///
		byte ST11Q04   	63-63   ///
		byte ST12Q01   	64-64   ///
		str4 ST13Q01   	65-68   ///
		byte ST14Q01   	69-69   ///
		byte ST15Q01   	70-70   ///
		byte ST15Q02   	71-71   ///
		byte ST15Q03   	72-72   ///
		byte ST15Q04   	73-73   ///
		byte ST16Q01   	74-74   ///
		byte ST17Q01   	75-75   ///
		byte ST17Q02   	76-76   ///
		byte ST17Q03   	77-77   ///
		int  ST18Q01   	78-82   ///
		byte ST19Q01   	83-83   ///
		byte ST20Q01   	84-84   ///
		byte ST20Q02   	85-85   ///
		byte ST20Q03   	86-86   ///
		byte ST20Q04   	87-87   ///
		byte ST20Q05   	88-88   ///
		byte ST20Q06   	89-89   ///
		byte ST20Q07   	90-90   ///
		byte ST20Q08   	91-91   ///
		byte ST20Q09   	92-92   ///
		byte ST20Q10   	93-93   ///
		float PV1MATH 1150 - 1158 ///
		float PV2MATH 1159 - 1167 ///
		float PV3MATH 1168 - 1176 ///
		float PV4MATH 1177 - 1185 ///
		float PV5MATH 1186 - 1194 ///
		float PV1MACC 1195 - 1203 ///
		float PV2MACC 1204 - 1212 ///
		float PV3MACC 1213 - 1221 ///
		float PV4MACC 1222 - 1230 ///
		float PV5MACC 1231 - 1239 ///
		float PV1MACQ 1240 - 1248 ///
		float PV2MACQ 1249 - 1257 ///
		float PV3MACQ 1258 - 1266 ///
		float PV4MACQ 1267 - 1275 ///
		float PV5MACQ 1276 - 1284 ///
		float PV1MACS 1285 - 1293 ///
		float PV2MACS 1294 - 1302 ///
		float PV3MACS 1303 - 1311 ///
		float PV4MACS 1312 - 1320 ///
		float PV5MACS 1321 - 1329 ///
		float PV1MACU 1330 - 1338 ///
		float PV2MACU 1339 - 1347 ///
		float PV3MACU 1348 - 1356 ///
		float PV4MACU 1357 - 1365 ///
		float PV5MACU 1366 - 1374 ///
		float PV1MAPE 1375 - 1383 ///
		float PV2MAPE 1384 - 1392 ///
		float PV3MAPE 1393 - 1401 ///
		float PV4MAPE 1402 - 1410 ///
		float PV5MAPE 1411 - 1419 ///
		float PV1MAPF 1420 - 1428 ///
		float PV2MAPF 1429 - 1437 ///
		float PV3MAPF 1438 - 1446 ///
		float PV4MAPF 1447 - 1455 ///
		float PV5MAPF 1456 - 1464 ///
		float PV1MAPI 1465 - 1473 ///
		float PV2MAPI 1474 - 1482 ///
		float PV3MAPI 1483 - 1491 ///
		float PV4MAPI 1492 - 1500 ///
		float PV5MAPI 1501 - 1509 ///
		float PV1READ 1510 - 1518 ///
		float PV2READ 1519 - 1527 ///
		float PV3READ 1528 - 1536 ///
		float PV4READ 1537 - 1545 ///
		float PV5READ 1546 - 1554 ///
		float PV1SCIE 1555 - 1563 ///
		float PV2SCIE 1564 - 1572 ///
		float PV3SCIE 1573 - 1581 ///
		float PV4SCIE 1582 - 1590 ///
		float PV5SCIE 1591 - 1599 ///
		using "$IN\PISA\2012\INT_STU12_DEC03.txt", clear



	*-----------------------------*
	* 2. Variable Labels          *
	*-----------------------------*
	capture label variable NC			"National Centre 6-digit Code"
	capture label variable CNT			"Country code 3-character" 
	capture label variable OECD			"OECD country" 
	capture label variable SUBNATIO		"Adjudicated sub-region code 7-digit code (3-digit country code + region ID + stratum ID)"
	capture label variable STRATUM		"Stratum ID 7-character (cnt + region ID + original stratum ID)"
	capture label variable SCHOOLID		"School ID 7-digit (region ID + stratum ID + 3-digit school ID)"
	capture label variable STIDSTD		"Student ID" 
	capture label variable ST01Q01		"International Grade"
	capture label variable ST02Q01		"National Study Programme"
	capture label variable ST03Q01		"Birth - Month"
	capture label variable ST03Q02		"Birth -Year"
	capture label variable ST04Q01		"Gender"
	capture label variable ST05Q01		"Attend <ISCED 0>"
	capture label variable ST06Q01		"Age at <ISCED 1>" 
	capture label variable ST07Q01		"Repeat - <ISCED 1>"
	capture label variable ST07Q02		"Repeat - <ISCED 2>"
	capture label variable ST07Q03		"Repeat - <ISCED 3>"
	capture label variable ST08Q01		"Truancy - Late for School"
	capture label variable ST09Q01		"Truancy - Skip whole school day"
	capture label variable ST115Q01		"Truancy - Skip classes within school day" 
	capture label variable ST11Q01		"At Home - Mother" 
	capture label variable ST11Q02		"At Home - Father" 
	capture label variable ST11Q03		"At Home - Brothers" 
	capture label variable ST11Q04		"At Home - Sisters" 
	capture label variable ST11Q05		"At Home - Grandparents" 
	capture label variable ST11Q06		"At Home - Others" 
	capture label variable ST13Q01		"Mother<Highest Schooling>"
	capture label variable ST14Q01		"Mother Qualifications - <ISCED level 6>" 
	capture label variable ST14Q02		"Mother Qualifications - <ISCED level 5A>"
	capture label variable ST14Q03		"Mother Qualifications - <ISCED level 5B>"
	capture label variable ST14Q04		"Mother Qualifications - <ISCED level 4>" 
	capture label variable ST15Q01		"Mother Current Job Status" 
	capture label variable ST17Q01		"Father<Highest Schooling>" 
	capture label variable ST18Q01		"Father Qualifications - <ISCED level 6>" 
	capture label variable ST18Q02		"Father Qualifications - <ISCED level 5A>"
	capture label variable ST18Q03		"Father Qualifications - <ISCED level 5B>"
	capture label variable ST18Q04		"Father Qualifications - <ISCED level 4>" 
	capture label variable ST19Q01		"Father Current Job Status" 
	capture label variable ST20Q01		"Country of Birth - Self" 
	capture label variable ST20Q02		"Country of Birth - Mother" 
	capture label variable ST20Q03		"Country of Birth - Father" 
	capture label variable ST21Q01		"Age of arrival in <country of test>" 
	capture label variable ST25Q01		"International Language at Home"
	capture label variable ST26Q01		"Possessions - desk" 
	capture label variable ST26Q02		"Possessions - own room" 
	capture label variable ST26Q03		"Possessions - study place" 
	capture label variable ST26Q04		"Possessions - computer" 
	capture label variable ST26Q05		"Possessions - software" 
	capture label variable ST26Q06		"Possessions - Internet" 
	capture label variable ST26Q07		"Possessions - literature" 
	capture label variable ST26Q08		"Possessions - poetry" 
	capture label variable ST26Q09		"Possessions - art" 
	capture label variable ST26Q10		"Possessions - textbooks" 
	capture label variable ST26Q11		"Possessions - <technical reference books>" 
	capture label variable ST26Q12		"Possessions - dictionary" 
	capture label variable ST26Q13		"Possessions - dishwasher" 
	capture label variable ST26Q14		"Possessions - <DVD>" 
	capture label variable ST26Q15		"Possessions - <Country item 1>" 
	capture label variable ST26Q16		"Possessions - <Country item 2>" 
	capture label variable ST26Q17		"Possessions - <Country item 3>" 
	capture label variable ST27Q01		"How many - cellular phones" 
	capture label variable ST27Q02		"How many - televisions" 
	capture label variable ST27Q03		"How many - computers" 
	capture label variable ST27Q04		"How many - cars" 
	capture label variable ST27Q05		"How many - rooms bath or shower" 
	capture label variable ST28Q01		"How many books at home" 
	capture label variable ST29Q01		"Maths Interest - Enjoy Reading" 
	capture label variable ST29Q02		"Instrumental Motivation - Worthwhile for Work" 
	capture label variable ST29Q03		"Maths Interest - Look Forward to Lessons" 
	capture label variable ST29Q04		"Maths Interest - Enjoy Maths" 
	capture label variable ST29Q05		"Instrumental Motivation - Worthwhile for Career Chances" 
	capture label variable ST29Q06		"Maths Interest - Interested" 
	capture label variable ST29Q07		"Instrumental Motivation - importnt for Future Study" 
	capture label variable ST29Q08		"Instrumental Motivation - Helps to Get a Job" 
	capture label variable ST35Q01		"Subjective Norms - Friends Do Well in Mathematics" 
	capture label variable ST35Q02		"Subjective Norms - Friends Work Hard on Mathematics" 
	capture label variable ST35Q03		"Subjective Norms - Friends Enjoy Mathematics Tests" 
	capture label variable ST35Q04		"Subjective Norms - Parents Believe Studying Mathematics Is importnt" 
	capture label variable ST35Q05		"Subjective Norms - Parents Believe Mathematics Is importnt for Career" 
	capture label variable ST35Q06		"Subjective Norms - Parents Like Mathematics" 
	capture label variable ST37Q01		"Maths Self-Efficacy - Using a <Train Timetable>" 
	capture label variable ST37Q02		"Maths Self-Efficacy - Calculating TV Discount" 
	capture label variable ST37Q03		"Maths Self-Efficacy - Calculating Square Metres of Tiles" 
	capture label variable ST37Q04		"Maths Self-Efficacy - Understanding Graphs in Newspapers" 
	capture label variable ST37Q05		"Maths Self-Efficacy - Solving Equation 1" 
	capture label variable ST37Q06		"Maths Self-Efficacy - Distance to Scale" 
	capture label variable ST37Q07		"Maths Self-Efficacy - Solving Equation 2" 
	capture label variable ST37Q08		"Maths Self-Efficacy - Calculate Petrol Consumption Rate" 
	capture label variable ST42Q01		"Maths Anxiety - Worry That It Will Be Difficult" 
	capture label variable ST42Q02		"Maths Self-Concept - Not Good at Maths" 
	capture label variable ST42Q03		"Maths Anxiety - Get Very Tense" 
	capture label variable ST42Q04		"Maths Self-Concept - Get Good <Grades>" 
	capture label variable ST42Q05		"Maths Anxiety - Get Very Nervous" 
	capture label variable ST42Q06		"Maths Self-Concept - Learn Quickly" 
	capture label variable ST42Q07		"Maths Self-Concept - One of Best Subjects" 
	capture label variable ST42Q08		"Maths Anxiety - Feel Helpless" 
	capture label variable ST42Q09		"Maths Self-Concept - Understand Difficult Work" 
	capture label variable ST42Q10		"Maths Anxiety - Worry About Getting Poor <Grades>" 
	capture label variable ST43Q01		"Perceived Control - Can Succeed with Enough Effort" 
	capture label variable ST43Q02		"Perceived Control - Doing Well is Completely Up to Me" 
	capture label variable ST43Q03		"Perceived Control - Family Demands and Problems" 
	capture label variable ST43Q04		"Perceived Control - Different Teachers" 
	capture label variable ST43Q05		"Perceived Control - If I Wanted I Could Perform Well" 
	capture label variable ST43Q06		"Perceived Control - Perform Poorly Regardless" 
	capture label variable ST44Q01		"Attributions to Failure - Not Good at Maths Problems" 
	capture label variable ST44Q03		"Attributions to Failure - Teacher Did Not Explain Well" 
	capture label variable ST44Q04		"Attributions to Failure - Bad Guesses" 
	capture label variable ST44Q05		"Attributions to Failure - Material Too Hard" 
	capture label variable ST44Q07		"Attributions to Failure - Teacher Didnt Get Students Interested" 
	capture label variable ST44Q08		"Attributions to Failure - Unlucky" 
	capture label variable ST46Q01		"Maths Work Ethic - Homework Completed in Time" 
	capture label variable ST46Q02		"Maths Work Ethic - Work Hard on Homework" 
	capture label variable ST46Q03		"Maths Work Ethic - Prepared for Exams" 
	capture label variable ST46Q04		"Maths Work Ethic - Study Hard for Quizzes" 
	capture label variable ST46Q05		"Maths Work Ethic - Study Until I Understand Everything" 
	capture label variable ST46Q06		"Maths Work Ethic - Pay Attention in Classes" 
	capture label variable ST46Q07		"Maths Work Ethic - Listen in Classes" 
	capture label variable ST46Q08		"Maths Work Ethic - Avoid Distractions When Studying" 
	capture label variable ST46Q09		"Maths Work Ethic - Keep Work Organized" 
	capture label variable ST48Q01		"Maths Intentions - Mathematics vs. Language Courses After School" 
	capture label variable ST48Q02		"Maths Intentions - Mathematics vs. Science Related Major in College" 
	capture label variable ST48Q03		"Maths Intentions - Study Harder in Mathematics vs. Language Classes" 
	capture label variable ST48Q04		"Maths Intentions - Take Maximum Number of Mathematics vs. Science Classes" 
	capture label variable ST48Q05		"Maths Intentions - Pursuing a Career That Involves Mathematics vs. Science" 
	capture label variable ST49Q01		"Maths Behaviour - Talk about Maths with Friends" 
	capture label variable ST49Q02		"Maths Behaviour - Help Friends with Maths" 
	capture label variable ST49Q03		"Maths Behaviour - <Extracurricular> Activity" 
	capture label variable ST49Q04		"Maths Behaviour - Participate in Competitions" 
	capture label variable ST49Q05		"Maths Behaviour - Study More Than 2 Extra Hours a Day" 
	capture label variable ST49Q06		"Maths Behaviour - Play Chess" 
	capture label variable ST49Q07		"Maths Behaviour - Computer programming" 
	capture label variable ST49Q09		"Maths Behaviour - Participate in Maths Club" 
	capture label variable ST53Q01		"Learning Strategies - importnt Parts vs. Existing Knowledge vs. Learn by Heart" 
	capture label variable ST53Q02		"Learning Strategies - Improve Understanding vs. New Ways vs. Memory" 
	capture label variable ST53Q03		"Learning Strategies - Other Subjects vs. Learning Goals vs. Rehearse Problems" 
	capture label variable ST53Q04		"Learning Strategies - Repeat Examples vs. Everyday Applications vs. More Information" 
	capture label variable ST55Q01		"Out of school lessons - <test lang>" 
	capture label variable ST55Q02		"Out of school lessons - <maths>" 
	capture label variable ST55Q03		"Out of school lessons - <science>" 
	capture label variable ST55Q04		"Out of school lessons - other" 
	capture label variable ST57Q01		"Out-of-School Study Time - Homework" 
	capture label variable ST57Q02		"Out-of-School Study Time - Guided Homework" 
	capture label variable ST57Q03		"Out-of-School Study Time - Personal Tutor" 
	capture label variable ST57Q04		"Out-of-School Study Time - Commercial Company" 
	capture label variable ST57Q05		"Out-of-School Study Time - With Parent" 
	capture label variable ST57Q06		"Out-of-School Study Time - Computer" 
	capture label variable ST61Q01		"Experience with Applied Maths Tasks - Use <Train Timetable>" 
	capture label variable ST61Q02		"Experience with Applied Maths Tasks - Calculate Price including Tax" 
	capture label variable ST61Q03		"Experience with Applied Maths Tasks - Calculate Square Metres" 
	capture label variable ST61Q04		"Experience with Applied Maths Tasks - Understand Scientific Tables" 
	capture label variable ST61Q05		"Experience with Pure Maths Tasks - Solve Equation 1" 
	capture label variable ST61Q06		"Experience with Applied Maths Tasks - Use a Map to Calculate Distance" 
	capture label variable ST61Q07		"Experience with Pure Maths Tasks - Solve Equation 2" 
	capture label variable ST61Q08		"Experience with Applied Maths Tasks - Calculate Power Consumption Rate" 
	capture label variable ST61Q09		"Experience with Applied Maths Tasks - Solve Equation 3" 
	capture label variable ST62Q01		"Familiarity with Maths Concepts - Exponential Function" 
	capture label variable ST62Q02		"Familiarity with Maths Concepts - Divisor" 
	capture label variable ST62Q03		"Familiarity with Maths Concepts - Quadratic Function" 
	capture label variable ST62Q04		"Overclaiming - Proper Number" 
	capture label variable ST62Q06		"Familiarity with Maths Concepts - Linear Equation" 
	capture label variable ST62Q07		"Familiarity with Maths Concepts - Vectors" 
	capture label variable ST62Q08		"Familiarity with Maths Concepts - Complex Number" 
	capture label variable ST62Q09		"Familiarity with Maths Concepts - Rational Number" 
	capture label variable ST62Q10		"Familiarity with Maths Concepts - Radicals" 
	capture label variable ST62Q11		"Overclaiming - Subjunctive Scaling" 
	capture label variable ST62Q12		"Familiarity with Maths Concepts - Polygon" 
	capture label variable ST62Q13		"Overclaiming - Declarative Fraction" 
	capture label variable ST62Q15		"Familiarity with Maths Concepts - Congruent Figure" 
	capture label variable ST62Q16		"Familiarity with Maths Concepts - Cosine" 
	capture label variable ST62Q17		"Familiarity with Maths Concepts - Arithmetic Mean" 
	capture label variable ST62Q19		"Familiarity with Maths Concepts - Probability" 
	capture label variable ST69Q01		"Min in <class period> - <test lang>" 
	capture label variable ST69Q02		"Min in <class period> - <Maths>" 
	capture label variable ST69Q03		"Min in <class period> - <Science>" 
	capture label variable ST70Q01		"No of <class period> p/wk - <test lang>" 
	capture label variable ST70Q02		"No of <class period> p/wk - <Maths>" 
	capture label variable ST70Q03		"No of <class period> p/wk - <Science>" 
	capture label variable ST71Q01		"No of ALL <class period> a week" 
	capture label variable ST72Q01		"Class Size - No of Students in <Test Language> Class" 
	capture label variable ST73Q01		"OTL - Algebraic Word Problem in Maths Lesson" 
	capture label variable ST73Q02		"OTL - Algebraic Word Problem in Tests" 
	capture label variable ST74Q01		"OTL - Procedural Task in Maths Lesson" 
	capture label variable ST74Q02		"OTL - Procedural Task in Tests" 
	capture label variable ST75Q01		"OTL - Pure Maths Reasoning in Maths Lesson" 
	capture label variable ST75Q02		"OTL - Pure Maths Reasoning in Tests" 
	capture label variable ST76Q01		"OTL - Applied Maths Reasoning in Maths Lesson" 
	capture label variable ST76Q02		"OTL - Applied Maths Reasoning in Tests" 
	capture label variable ST77Q01		"Maths Teaching - Teacher shows interest" 
	capture label variable ST77Q02		"Maths Teaching - Extra help" 
	capture label variable ST77Q04		"Maths Teaching - Teacher helps" 
	capture label variable ST77Q05		"Maths Teaching - Teacher continues" 
	capture label variable ST77Q06		"Maths Teaching - Express opinions" 
	capture label variable ST79Q01		"Teacher-Directed Instruction - Sets Clear Goals" 
	capture label variable ST79Q02		"Teacher-Directed Instruction - Encourages Thinking and Reasoning" 
	capture label variable ST79Q03		"Student Orientation - Differentiates Between Students When Giving Tasks" 
	capture label variable ST79Q04		"Student Orientation - Assigns Complex Projects" 
	capture label variable ST79Q05		"Formative Assessment - Gives Feedback" 
	capture label variable ST79Q06		"Teacher-Directed Instruction - Checks Understanding" 
	capture label variable ST79Q07		"Student Orientation - Has Students Work in Small Groups" 
	capture label variable ST79Q08		"Teacher-Directed Instruction - Summarizes Previous Lessons" 
	capture label variable ST79Q10		"Student Orientation - Plans Classroom Activities" 
	capture label variable ST79Q11		"Formative Assessment - Gives Feedback on Strengths and Weaknesses" 
	capture label variable ST79Q12		"Formative Assessment - Informs about Expectations" 
	capture label variable ST79Q15		"Teacher-Directed Instruction - Informs about Learning Goals" 
	capture label variable ST79Q17		"Formative Assessment - Tells How to Get Better" 
	capture label variable ST80Q01		"Cognitive Activation - Teacher Encourages to Reflect Problems" 
	capture label variable ST80Q04		"Cognitive Activation - Gives Problems that Require to Think" 
	capture label variable ST80Q05		"Cognitive Activation - Asks to Use Own Procedures" 
	capture label variable ST80Q06		"Cognitive Activation - Presents Problems with No Obvious Solutions" 
	capture label variable ST80Q07		"Cognitive Activation - Presents Problems in Different Contexts" 
	capture label variable ST80Q08		"Cognitive Activation - Helps Learn from Mistakes" 
	capture label variable ST80Q09		"Cognitive Activation - Asks for Explanations" 
	capture label variable ST80Q10		"Cognitive Activation - Apply What We Learned" 
	capture label variable ST80Q11		"Cognitive Activation - Problems with Multiple Solutions" 
	capture label variable ST81Q01		"Disciplinary Climate - Students Don t Listen" 
	capture label variable ST81Q02		"Disciplinary Climate - Noise and Disorder" 
	capture label variable ST81Q03		"Disciplinary Climate - Teacher Has to Wait Until its Quiet" 
	capture label variable ST81Q04		"Disciplinary Climate - Students Don t Work Well" 
	capture label variable ST81Q05		"Disciplinary Climate - Students Start Working Late" 
	capture label variable ST82Q01		"Vignette Teacher Support - Homework Every Other Day/Back in Time" 
	capture label variable ST82Q02		"Vignette Teacher Support - Homework Once a Week/Back in Time" 
	capture label variable ST82Q03		"Vignette Teacher Support - Homework Once a Week/Not Back in Time" 
	capture label variable ST83Q01		"Teacher Support - Lets Us Know We Have to Work Hard" 
	capture label variable ST83Q02		"Teacher Support - Provides Extra Help When Needed" 
	capture label variable ST83Q03		"Teacher Support - Helps Students with Learning" 
	capture label variable ST83Q04		"Teacher Support - Gives Opportunity to Express Opinions" 
	capture label variable ST84Q01		"Vignette Classroom Management - Students Frequently Interrupt/Teacher Arrives Early" 
	capture label variable ST84Q02		"Vignette Classroom Management - Students Are Calm/Teacher Arrives on Time" 
	capture label variable ST84Q03		"Vignette Classroom Management - Students Frequently Interrupt/Teacher Arrives Late" 
	capture label variable ST85Q01		"Classroom Management - Students Listen" 
	capture label variable ST85Q02		"Classroom Management - Teacher Keeps Class Orderly" 
	capture label variable ST85Q03		"Classroom Management - Teacher Starts On Time" 
	capture label variable ST85Q04		"Classroom Management - Wait Long to <Quiet Down>" 
	capture label variable ST86Q01		"Student-Teacher Relations - Get Along with Teachers" 
	capture label variable ST86Q02		"Student-Teacher Relations - Teachers Are Interested" 
	capture label variable ST86Q03		"Student-Teacher Relations - Teachers Listen to Students" 
	capture label variable ST86Q04		"Student-Teacher Relations - Teachers Help Students" 
	capture label variable ST86Q05		"Student-Teacher Relations - Teachers Treat Students Fair" 
	capture label variable ST87Q01		"Sense of Belonging - Feel Like Outsider" 
	capture label variable ST87Q02		"Sense of Belonging - Make Friends Easily" 
	capture label variable ST87Q03		"Sense of Belonging - Belong at School" 
	capture label variable ST87Q04		"Sense of Belonging - Feel Awkward at School" 
	capture label variable ST87Q05		"Sense of Belonging - Liked by Other Students" 
	capture label variable ST87Q06		"Sense of Belonging - Feel Lonely at School" 
	capture label variable ST87Q07		"Sense of Belonging - Feel Happy at School" 
	capture label variable ST87Q08		"Sense of Belonging - Things Are Ideal at School" 
	capture label variable ST87Q09		"Sense of Belonging - Satisfied at School" 
	capture label variable ST88Q01		"Attitude towards School - Does Little to Prepare Me for Life" 
	capture label variable ST88Q02		"Attitude towards School - Waste of Time" 
	capture label variable ST88Q03		"Attitude towards School - Gave Me Confidence" 
	capture label variable ST88Q04		"Attitude towards School - Useful for Job" 
	capture label variable ST89Q02		"Attitude toward School - Helps to Get a Job" 
	capture label variable ST89Q03		"Attitude toward School - Prepare for College" 
	capture label variable ST89Q04		"Attitude toward School - Enjoy Good Grades" 
	capture label variable ST89Q05		"Attitude toward School - Trying Hard is importnt" 
	capture label variable ST91Q01		"Perceived Control - Can Succeed with Enough Effort" 
	capture label variable ST91Q02		"Perceived Control - My Choice Whether I Will Be Good" 
	capture label variable ST91Q03		"Perceived Control - Problems Prevent from Putting Effort into School"
	capture label variable ST91Q04		"Perceived Control - Different Teachers Would Make Me Try Harder" 
	capture label variable ST91Q05		"Perceived Control - Could Perform Well if I Wanted" 
	capture label variable ST91Q06		"Perceived Control - Perform Poor Regardless" 
	capture label variable ST93Q01		"Perseverance - Give up easily" 
	capture label variable ST93Q03		"Perseverance - Put off difficult problems" 
	capture label variable ST93Q04		"Perseverance - Remain interested" 
	capture label variable ST93Q06		"Perseverance - Continue to perfection" 
	capture label variable ST93Q07		"Perseverance - Exceed expectations" 
	capture label variable ST94Q05		"Openness for Problem Solving - Can Handle a Lot of Information" 
	capture label variable ST94Q06		"Openness for Problem Solving - Quick to Understand" 
	capture label variable ST94Q09		"Openness for Problem Solving - Seek Explanations" 
	capture label variable ST94Q10		"Openness for Problem Solving - Can Link Facts" 
	capture label variable ST94Q14		"Openness for Problem Solving - Like to Solve Complex Problems" 
	capture label variable ST96Q01		"Problem Text Message - Press every button" 
	capture label variable ST96Q02		"Problem Text Message - Trace steps" 
	capture label variable ST96Q03		"Problem Text Message - Manual" 
	capture label variable ST96Q05		"Problem Text Message - Ask a friend" 
	capture label variable ST101Q01		"Problem Route Selection - Read brochure" 
	capture label variable ST101Q02		"Problem Route Selection - Study map" 
	capture label variable ST101Q03		"Problem Route Selection - Leave it to brother" 
	capture label variable ST101Q05		"Problem Route Selection - Just drive" 
	capture label variable ST104Q01		"Problem Ticket Machine - Similarities" 
	capture label variable ST104Q04		"Problem Ticket Machine - Try buttons" 
	capture label variable ST104Q05		"Problem Ticket Machine - Ask for help" 
	capture label variable ST104Q06		"Problem Ticket Machine - Find ticket office" 
	capture label variable IC01Q01		"At Home - Desktop Computer" 
	capture label variable IC01Q02		"At Home - Portable laptop" 
	capture label variable IC01Q03		"At Home - Tablet computer" 
	capture label variable IC01Q04		"At Home - Internet connection" 
	capture label variable IC01Q05		"At Home - Video games console" 
	capture label variable IC01Q06		"At Home - Cell phone w/o Internet" 
	capture label variable IC01Q07		"At Home - Cell phone with Internet" 
	capture label variable IC01Q08		"At Home - Mp3/Mp4 player" 
	capture label variable IC01Q09		"At Home - Printer" 
	capture label variable IC01Q10		"At Home - USB (memory) stick" 
	capture label variable IC01Q11		"At Home - Ebook reader" 
	capture label variable IC02Q01		"At school - Desktop Computer" 
	capture label variable IC02Q02		"At school - Portable laptop" 
	capture label variable IC02Q03		"At school - Tablet computer" 
	capture label variable IC02Q04		"At school - Internet connection" 
	capture label variable IC02Q05		"At school - Printer" 
	capture label variable IC02Q06		"At school - USB (memory) stick" 
	capture label variable IC02Q07		"At school - Ebook reader" 
	capture label variable IC03Q01		"First use of computers" 
	capture label variable IC04Q01		"First access to Internet" 
	capture label variable IC05Q01		"Internet at School" 
	capture label variable IC06Q01		"Internet out-of-school - Weekday" 
	capture label variable IC07Q01		"Internet out-of-school - Weekend" 
	capture label variable IC08Q01		"Out-of-school 8 - One player games." 
	capture label variable IC08Q02		"Out-of-school 8 - ColLabourative games." 
	capture label variable IC08Q03		"Out-of-school 8 - Use email" 
	capture label variable IC08Q04		"Out-of-school 8 - Chat on line" 
	capture label variable IC08Q05		"Out-of-school 8 - Social networks" 
	capture label variable IC08Q06		"Out-of-school 8 - Browse the Internet for fun" 
	capture label variable IC08Q07		"Out-of-school 8 - Read news" 
	capture label variable IC08Q08		"Out-of-school 8 - Obtain practical information from the Internet"
	capture label variable IC08Q09		"Out-of-school 8 - Download music" 
	capture label variable IC08Q11		"Out-of-school 8 - Upload content" 
	capture label variable IC09Q01		"Out-of-school 9 - Internet for school" 
	capture label variable IC09Q02		"Out-of-school 9 - Email students" 
	capture label variable IC09Q03		"Out-of-school 9 - Email teachers" 
	capture label variable IC09Q04		"Out-of-school 9 - Download from School" 
	capture label variable IC09Q05		"Out-of-school 9 - Announcements" 
	capture label variable IC09Q06		"Out-of-school 9 - Homework" 
	capture label variable IC09Q07		"Out-of-school 9 - Share school material" 
	capture label variable IC10Q01		"At School - Chat on line" 
	capture label variable IC10Q02		"At School - Email" 
	capture label variable IC10Q03		"At School - Browse for schoolwork" 
	capture label variable IC10Q04		"At School - Download from website" 
	capture label variable IC10Q05		"At School - Post on website" 
	capture label variable IC10Q06		"At School - Simulations" 
	capture label variable IC10Q07		"At School - Practice and drilling" 
	capture label variable IC10Q08		"At School - Homework" 
	capture label variable IC10Q09		"At School - Group work" 
	capture label variable IC11Q01		"Maths lessons - Draw graph" 
	capture label variable IC11Q02		"Maths lessons - Calculation with numbers" 
	capture label variable IC11Q03		"Maths lessons - Geometric figures" 
	capture label variable IC11Q04		"Maths lessons - Spreadsheet" 
	capture label variable IC11Q05		"Maths lessons - Algebra" 
	capture label variable IC11Q06		"Maths lessons - Histograms" 
	capture label variable IC11Q07		"Maths lessons - Change in graphs" 
	capture label variable IC22Q01		"Attitudes - Useful for schoolwork" 
	capture label variable IC22Q02		"Attitudes - Homework more fun" 
	capture label variable IC22Q04		"Attitudes - Source of information" 
	capture label variable IC22Q06		"Attitudes - Troublesome" 
	capture label variable IC22Q07		"Attitudes - Not suitable for schoolwork" 
	capture label variable IC22Q08		"Attitudes - Too unreliable" 
	capture label variable EC01Q01		"Miss 2 months of <ISCED 1>" 
	capture label variable EC02Q01		"Miss 2 months of <ISCED 2>" 
	capture label variable EC03Q01		"Future Orientation - Internship" 
	capture label variable EC03Q02		"Future Orientation - Work-site visits" 
	capture label variable EC03Q03		"Future Orientation - Job fair" 
	capture label variable EC03Q04		"Future Orientation - Career advisor at school" 
	capture label variable EC03Q05		"Future Orientation - Career advisor outside school" 
	capture label variable EC03Q06		"Future Orientation - Questionnaire" 
	capture label variable EC03Q07		"Future Orientation - Internet search" 
	capture label variable EC03Q08		"Future Orientation - Tour<ISCED 3-5> institution" 
	capture label variable EC03Q09		"Future Orientation - web search <ISCED 3-5> prog" 
	capture label variable EC03Q10		"Future Orientation - <country specific item>" 
	capture label variable EC04Q01A		"Acquired skills - Find job info - Yes, at school" 
	capture label variable EC04Q01B		"Acquired skills - Find job info - Yes, out of school" 
	capture label variable EC04Q01C		"Acquired skills - Find job info - No, never" 
	capture label variable EC04Q02A		"Acquired skills - Search for job - Yes, at school" 
	capture label variable EC04Q02B		"Acquired skills - Search for job - Yes, out of school" 
	capture label variable EC04Q02C		"Acquired skills - Search for job - No, never" 
	capture label variable EC04Q03A		"Acquired skills - Write resume - Yes, at school" 
	capture label variable EC04Q03B		"Acquired skills - Write resume - Yes, out of school" 
	capture label variable EC04Q03C		"Acquired skills - Write resume - No, never" 
	capture label variable EC04Q04A		"Acquired skills - Job interview - Yes, at school" 
	capture label variable EC04Q04B		"Acquired skills - Job interview - Yes, out of school" 
	capture label variable EC04Q04C		"Acquired skills - Job interview - No, never" 
	capture label variable EC04Q05A		"Acquired skills - ISCED 3-5 programs - Yes, at school" 
	capture label variable EC04Q05B		"Acquired skills - ISCED 3-5 programs - Yes, out of school" 
	capture label variable EC04Q05C		"Acquired skills - ISCED 3-5 programs - No, never" 
	capture label variable EC04Q06A		"Acquired skills - Student financing - Yes, at school" 
	capture label variable EC04Q06B		"Acquired skills - Student financing - Yes, out of school" 
	capture label variable EC04Q06C		"Acquired skills - Student financing - No, never" 
	capture label variable EC05Q01		"First language learned" 
	capture label variable EC06Q01		"Age started learning <test language>" 
	capture label variable EC07Q01		"Language spoken - Mother" 
	capture label variable EC07Q02		"Language spoken - Father" 
	capture label variable EC07Q03		"Language spoken - Siblings" 
	capture label variable EC07Q04		"Language spoken - Best friend" 
	capture label variable EC07Q05		"Language spoken - Schoolmates" 
	capture label variable EC08Q01		"Activities language - Reading" 
	capture label variable EC08Q02		"Activities language - Watching TV" 
	capture label variable EC08Q03		"Activities language - Internet surfing" 
	capture label variable EC08Q04		"Activities language - Writing emails" 
	capture label variable EC09Q03		"Types of support <test language> - remedial lessons" 
	capture label variable EC10Q01		"Amount of support <test language>" 
	capture label variable EC11Q02		"Attend lessons <heritage language> - focused" 
	capture label variable EC11Q03		"Attend lessons <heritage language> - school subjects" 
	capture label variable EC12Q01		"Instruction in <heritage language>" 
	capture label variable ST22Q01		"Acculturation - Mother Immigrant (Filter)" 
	capture label variable ST23Q01		"Acculturation - Enjoy <Host Culture> Friends" 
	capture label variable ST23Q02		"Acculturation - Enjoy <Heritage Culture> Friends" 
	capture label variable ST23Q03		"Acculturation - Enjoy <Host Culture> Celebrations" 
	capture label variable ST23Q04		"Acculturation - Enjoy <Heritage Culture> Celebrations" 
	capture label variable ST23Q05		"Acculturation - Spend Time with <Host Culture> Friends"
	capture label variable ST23Q06		"Acculturation - Spend Time with <Heritage Culture> Friends"
	capture label variable ST23Q07		"Acculturation - Participate in <Host Culture> Celebrations"
	capture label variable ST23Q08		"Acculturation - Participate in <Heritage Culture> Celebrations"
	capture label variable ST24Q01		"Acculturation - Perceived Host-Heritage Cultural Differences - Values"
	capture label variable ST24Q02		"Acculturation - Perceived Host-Heritage Cultural Differences - Mother Treatment" 
	capture label variable ST24Q03		"Acculturation - Perceived Host-Heritage Cultural Differences - Teacher Treatment"
	capture label variable CLCUSE1		"Calculator Use"
	capture label variable CLCUSE301	"Effort-real 1"
	capture label variable CLCUSE302	"Effort-real 2"
	capture label variable DEFFORT		"Difference in Effort"
	capture label variable QUESTID		"Student Questionnaire Form"
	capture label variable BOOKID		"Booklet ID"
	capture label variable EASY			"Standard or simplified set of booklets"
	capture label variable AGE			"Age of student"
	capture label variable GRADE		"Grade compared to modal grade in country"
	capture label variable progn		"Unique national study programme code"
	capture label variable ANXMAT		"Mathematics Anxiety"
	capture label variable ATSCHL		"Attitude towards School: Learning Outcomes" 
	capture label variable ATTLNACT		"Attitude towards School: Learning Activities" 
	capture label variable BELONG		"Sense of Belonging to School" 
	capture label variable BFMJ2		"Father SQ ISEI" 
	capture label variable BMMJ1		"Mother SQ ISEI" 
	capture label variable CLSMAN		"Mathematics Teacher's Classroom Management"
	capture label variable COBN_F		"Country of Birth National Categories- Father" 
	capture label variable COBN_M		"Country of Birth National Categories- Mother" 
	capture label variable COBN_S		"Country of Birth National Categories- Self" 
	capture label variable COGACT		"Cognitive Activation in Mathematics Lessons"
	capture label variable CULTDIST		"Cultural Distance between Host and Heritage Culture" 
	capture label variable CULTPOS		"Cultural Possessions" 
	capture label variable DISCLIMA		"Disciplinary Climate" 
	capture label variable ENTUSE		"ICT Entertainment Use" 
	capture label variable ESCS			"Index of economic, social and cultural status"
	capture label variable EXAPPLM		"Experience with Applied Mathematics Tasks at School"
	capture label variable EXPUREM		"Experience with Pure Mathematics Tasks at School" 
	capture label variable FAILMAT		"Attributions to Failure in Mathematics"
	capture label variable FAMCON		"Familiarity with Mathematical Concepts" 
	capture label variable FAMCONC		"Familiarity with Mathematical Concepts (Signal Detection Adjusted)" 
	capture label variable FAMSTRUC		"Family Structure" 
	capture label variable FISCED		"Educational level of father (ISCED)"
	capture label variable HEDRES		"Home educational resources" 
	capture label variable HERITCUL		"Acculturation: Heritage Culture Oriented Strategies"
	capture label variable HISCED		"Highest educational level of parents" 
	capture label variable HISEI		"Highest parental occupational status" 
	capture label variable HOMEPOS		"Home Possessions" 
	capture label variable HOMSCH		"ICT Use at Home for School-related Tasks" 
	capture label variable HOSTCUL		"Acculturation: Host Culture Oriented Strategies" 
	capture label variable ICTATTNEG	"Attitudes Towards Computers: Limitations of the Computer as a Tool for School Learning"
	capture label variable ICTATTPOS	"Attitudes Towards Computers: Computer as a Tool for School Learning" 
	capture label variable ICTHOME		"ICT Availability at Home" 
	capture label variable ICTSCH		"ICT Availability at School" 
	capture label variable IMMIG		"Immigration status" 
	capture label variable INFOCAR		"Information about Careers"
	capture label variable INFOJOB1		"Information about the Labour Market provided by the School"
	capture label variable INFOJOB2		"Information about the Labour Market provided outside of School"
	capture label variable INSTMOT		"Instrumental Motivation for Mathematics" 
	capture label variable INTMAT		"Mathematics Interest"
	capture label variable ISCEDD		"ISCED designation"
	capture label variable ISCEDL		"ISCED level"
	capture label variable ISCEDO		"ISCED orientation"
	capture label variable LANGCOMM		"Preference for Heritage Language in Conversations with Family and Friends"
	capture label variable LANGN		"Language at home (3-digit code)"
	capture label variable LANGRPPD		"Preference for Heritage Language in Language Reception and Production"
	capture label variable LMINS		"Learning time (minutes per week) - <test language>" 
	capture label variable MATBEH		"Mathematics Behaviour"
	capture label variable MATHEFF		"Mathematics Self-Efficacy"
	capture label variable MATINTFC		"Mathematics Intentions" 
	capture label variable MATWKETH		"Mathematics Work Ethic" 
	capture label variable MISCED		"Educational level of mother (ISCED)"
	capture label variable MMINS		"Learning time (minutes per week)- <Mathematics>" 
	capture label variable MTSUP		"Mathematics Teacher's Support"
	capture label variable OCOD1		"ISCO-08 Occupation code - Mother" 
	capture label variable OCOD2		"ISCO-08 Occupation code - Father" 
	capture label variable OPENPS		"Openness for Problem Solving"
	capture label variable OUTHOURS		"Out-of-School Study Time"
	capture label variable PARED		"Highest parental education in years"
	capture label variable PERSEV		"Perseverance" 
	capture label variable REPEAT		"Grade Repetition"
	capture label variable SCMAT		"Mathematics Self-Concept" 
	capture label variable SMINS		"Learning time (minutes per week) - <Science>" 
	capture label variable STUDREL		"Teacher Student Relations"
	capture label variable SUBNORM		"Subjective Norms in Mathematics"
	capture label variable TCHBEHFA		"Teacher Behaviour: Formative Assessment" 
	capture label variable TCHBEHSO		"Teacher Behaviour: Student Orientation"
	capture label variable TCHBEHTD		"Teacher Behaviour: Teacher-directed Instruction" 
	capture label variable TEACHSUP		"Teacher Support" 
	capture label variable TESTLANG		"Language of the test" 
	capture label variable TIMEINT		"Time of computer use (mins)" 
	capture label variable USEMATH		"Use of ICT in Mathematic Lessons"
	capture label variable USESCH		"Use of ICT at School" 
	capture label variable WEALTH		"Wealth" 
	capture label variable ANCATSCHL	"Attitude towards School: Learning Outcomes (Anchored)"
	capture label variable ANCATTLNACT	"Attitude towards School: Learning Activities (Anchored)"
	capture label variable ANCBELONG	"Sense of Belonging to School (Anchored)"
	capture label variable ANCCLSMAN	"Mathematics Teacher's Classroom Management (Anchored)"
	capture label variable ANCCOGACT	"Cognitive Activation in Mathematics Lessons (Anchored)"
	capture label variable ANCINSTMOT	"Instrumental Motivation for Mathematics (Anchored)"
	capture label variable ANCINTMAT	"Mathematics Interest (Anchored)"
	capture label variable ANCMATWKETH	"Mathematics Work Ethic (Anchored)"
	capture label variable ANCMTSUP		"Mathematics Teacher's Support (Anchored)"
	capture label variable ANCSCMAT		"Mathematics Self-Concept (Anchored)"
	capture label variable ANCSTUDREL	"Teacher Student Relations (Anchored)"
	capture label variable ANCSUBNORM	"Subjective Norms in Mathematics (Anchored)"
	capture label variable PV1MATH		"Plausible value 1 in mathematics"
	capture label variable PV2MATH		"Plausible value 2 in mathematics"
	capture label variable PV3MATH		"Plausible value 3 in mathematics"
	capture label variable PV4MATH		"Plausible value 4 in mathematics"
	capture label variable PV5MATH		"Plausible value 5 in mathematics"
	capture label variable PV1MACC		"Plausible value 1 in content subscale of Maths - Change and Relationships" 
	capture label variable PV2MACC		"Plausible value 2 in content subscale of Maths - Change and Relationships" 
	capture label variable PV3MACC		"Plausible value 3 in content subscale of Maths - Change and Relationships" 
	capture label variable PV4MACC		"Plausible value 4 in content subscale of Maths - Change and Relationships" 
	capture label variable PV5MACC		"Plausible value 5 in content subscale of Maths - Change and Relationships" 
	capture label variable PV1MACQ		"Plausible value 1 in content subscale of Maths - Quantity"
	capture label variable PV2MACQ		"Plausible value 2 in content subscale of Maths - Quantity"
	capture label variable PV3MACQ		"Plausible value 3 in content subscale of Maths - Quantity"
	capture label variable PV4MACQ		"Plausible value 4 in content subscale of Maths - Quantity"
	capture label variable PV5MACQ		"Plausible value 5 in content subscale of Maths - Quantity"
	capture label variable PV1MACS		"Plausible value 1 in content subscale of Maths - Space and Shape"
	capture label variable PV2MACS		"Plausible value 2 in content subscale of Maths - Space and Shape"
	capture label variable PV3MACS		"Plausible value 3 in content subscale of Maths - Space and Shape"
	capture label variable PV4MACS		"Plausible value 4 in content subscale of Maths - Space and Shape"
	capture label variable PV5MACS		"Plausible value 5 in content subscale of Maths - Space and Shape"
	capture label variable PV1MACU		"Plausible value 1 in content subscale of Maths - Uncertainty and Data"
	capture label variable PV2MACU		"Plausible value 2 in content subscale of Maths - Uncertainty and Data"
	capture label variable PV3MACU		"Plausible value 3 in content subscale of Maths - Uncertainty and Data"
	capture label variable PV4MACU		"Plausible value 4 in content subscale of Maths - Uncertainty and Data"
	capture label variable PV5MACU		"Plausible value 5 in content subscale of Maths - Uncertainty and Data"
	capture label variable PV1MAPE		"Plausible value 1 in process subscale of Maths - Employ"
	capture label variable PV2MAPE		"Plausible value 2 in process subscale of Maths - Employ"
	capture label variable PV3MAPE		"Plausible value 3 in process subscale of Maths - Employ"
	capture label variable PV4MAPE		"Plausible value 4 in process subscale of Maths - Employ"
	capture label variable PV5MAPE		"Plausible value 5 in process subscale of Maths - Employ"
	capture label variable PV1MAPF		"Plausible value 1 in process subscale of Maths - Formulate"
	capture label variable PV2MAPF		"Plausible value 2 in process subscale of Maths - Formulate"
	capture label variable PV3MAPF		"Plausible value 3 in process subscale of Maths - Formulate"
	capture label variable PV4MAPF		"Plausible value 4 in process subscale of Maths - Formulate"
	capture label variable PV5MAPF		"Plausible value 5 in process subscale of Maths - Formulate"
	capture label variable PV1MAPI		"Plausible value 1 in process subscale of Maths - Interpret"
	capture label variable PV2MAPI		"Plausible value 2 in process subscale of Maths - Interpret"
	capture label variable PV3MAPI		"Plausible value 3 in process subscale of Maths - Interpret"
	capture label variable PV4MAPI		"Plausible value 4 in process subscale of Maths - Interpret"
	capture label variable PV5MAPI		"Plausible value 5 in process subscale of Maths - Interpret"
	capture label variable PV1READ		"Plausible value 1 in reading"
	capture label variable PV2READ		"Plausible value 2 in reading"
	capture label variable PV3READ		"Plausible value 3 in reading"
	capture label variable PV4READ		"Plausible value 4 in reading"
	capture label variable PV5READ		"Plausible value 5 in reading"
	capture label variable PV1SCIE		"Plausible value 1 in science"
	capture label variable PV2SCIE		"Plausible value 2 in science"
	capture label variable PV3SCIE		"Plausible value 3 in science"
	capture label variable PV4SCIE		"Plausible value 4 in science"
	capture label variable PV5SCIE		"Plausible value 5 in science"
	capture label variable W_FSTUWT		"FINAL STUDENT WEIGHT" 
	capture label variable W_FSTR1		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT1" 
	capture label variable W_FSTR2		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT2" 
	capture label variable W_FSTR3		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT3" 
	capture label variable W_FSTR4		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT4" 
	capture label variable W_FSTR5		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT5" 
	capture label variable W_FSTR6		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT6" 
	capture label variable W_FSTR7		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT7" 
	capture label variable W_FSTR8		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT8" 
	capture label variable W_FSTR9		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT9" 
	capture label variable W_FSTR10		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT10"
	capture label variable W_FSTR11		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT11"
	capture label variable W_FSTR12		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT12"
	capture label variable W_FSTR13		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT13"
	capture label variable W_FSTR14		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT14"
	capture label variable W_FSTR15		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT15"
	capture label variable W_FSTR16		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT16"
	capture label variable W_FSTR17		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT17"
	capture label variable W_FSTR18		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT18"
	capture label variable W_FSTR19		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT19"
	capture label variable W_FSTR20		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT20"
	capture label variable W_FSTR21		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT21"
	capture label variable W_FSTR22		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT22"
	capture label variable W_FSTR23		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT23"
	capture label variable W_FSTR24		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT24"
	capture label variable W_FSTR25		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT25"
	capture label variable W_FSTR26		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT26"
	capture label variable W_FSTR27		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT27"
	capture label variable W_FSTR28		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT28"
	capture label variable W_FSTR29		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT29"
	capture label variable W_FSTR30		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT30"
	capture label variable W_FSTR31		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT31"
	capture label variable W_FSTR32		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT32"
	capture label variable W_FSTR33		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT33"
	capture label variable W_FSTR34		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT34"
	capture label variable W_FSTR35		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT35"
	capture label variable W_FSTR36		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT36"
	capture label variable W_FSTR37		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT37"
	capture label variable W_FSTR38		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT38"
	capture label variable W_FSTR39		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT39"
	capture label variable W_FSTR40		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT40"
	capture label variable W_FSTR41		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT41"
	capture label variable W_FSTR42		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT42"
	capture label variable W_FSTR43		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT43"
	capture label variable W_FSTR44		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT44"
	capture label variable W_FSTR45		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT45"
	capture label variable W_FSTR46		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT46"
	capture label variable W_FSTR47		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT47"
	capture label variable W_FSTR48		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT48"
	capture label variable W_FSTR49		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT49"
	capture label variable W_FSTR50		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT50"
	capture label variable W_FSTR51		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT51"
	capture label variable W_FSTR52		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT52"
	capture label variable W_FSTR53		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT53"
	capture label variable W_FSTR54		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT54"
	capture label variable W_FSTR55		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT55"
	capture label variable W_FSTR56		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT56"
	capture label variable W_FSTR57		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT57"
	capture label variable W_FSTR58		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT58"
	capture label variable W_FSTR59		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT59"
	capture label variable W_FSTR60		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT60"
	capture label variable W_FSTR61		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT61"
	capture label variable W_FSTR62		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT62"
	capture label variable W_FSTR63		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT63"
	capture label variable W_FSTR64		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT64"
	capture label variable W_FSTR65		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT65"
	capture label variable W_FSTR66		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT66"
	capture label variable W_FSTR67		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT67"
	capture label variable W_FSTR68		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT68"
	capture label variable W_FSTR69		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT69"
	capture label variable W_FSTR70		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT70"
	capture label variable W_FSTR71		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT71"
	capture label variable W_FSTR72		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT72"
	capture label variable W_FSTR73		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT73"
	capture label variable W_FSTR74		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT74"
	capture label variable W_FSTR75		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT75"
	capture label variable W_FSTR76		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT76"
	capture label variable W_FSTR77		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT77"
	capture label variable W_FSTR78		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT78"
	capture label variable W_FSTR79		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT79"
	capture label variable W_FSTR80		"FINAL STUDENT REPLICATE BRR-FAY WEIGHT80"
	capture label variable WVARSTRR		"RANDOMIZED FINAL VARIANCE STRATUM (1-80)"
	capture label variable VAR_UNIT		"RANDOMLY ASSIGNED VARIANCE UNIT" 
	capture label variable senwgt_STU	"Senate weight - sum of weight within the country is 1000"
	capture label variable VER_STU		"Date of the database creation"       

/*
			"ALB"  "Albania"
			"ARG"  "Argentina"
			"AUS"  "Australia"
			"AUT"  "Austria"
			"BEL"  "Belgium"
			"BRA"  "Brazil"
			"BGR"  "Bulgaria"
			"CAN"  "Canada"
			"CHL"  "Chile"
			"QCN"  "Shanghai-China"
			"TAP"  "Chinese Taipei"
			"COL"  "Colombia"
			"CRI"  "Costa Rica"
			"HRV"  "Croatia"
			"CZE"  "Czech Republic"
			"DNK"  "Denmark"
			"EST"  "Estonia"
			"FIN"  "Finland"
			"FRA"  "France"
			"DEU"  "Germany"
			"GRC"  "Greece"
			"HKG"  "Hong Kong-China"
			"HUN"  "Hungary"
			"ISL"  "Iceland"
			"IDN"  "Indonesia"
			"IRL"  "Ireland"
			"ISR"  "Israel"
			"ITA"  "Italy"
			"JPN"  "Japan"
			"JOR"  "Jordan"
			"KAZ"  "Kazakhstan"
			"KOR"  "Korea"
			"LVA"  "Latvia"
			"LIE"  "Liechtenstein"
			"LTU"  "Lithuania"
			"LUX"  "Luxembourg"
			"MAC"  "Macao-China"
			"MYS"  "Malaysia"
			"MEX"  "Mexico"
			"MNE"  "Montenegro"
			"NLD"  "Netherlands"
			"NZL"  "New Zealand"
			"NOR"  "Norway"
			"QRS"  "Perm(Russian Federation)"
			"PER"  "Peru"
			"POL"  "Poland"
			"PRT"  "Portugal"
			"QAT"  "Qatar"
			"ROU"  "Romania"
			"RUS"  "Russian Federation"
			"SRB"  "Serbia"
			"SGP"  "Singapore"
			"SVK"  "Slovak Republic"
			"SVN"  "Slovenia"
			"ESP"  "Spain"
			"SWE"  "Sweden"
			"CHE"  "Switzerland"
			"THA"  "Thailand"
			"TUN"  "Tunisia"
			"TUR"  "Turkey"
			"GBR"  "United Kingdom"
			"ARE"  "United Arab Emirates"
			"USA"  "United States of America"
			"URY"  "Uruguay"
			"VNM"  "Viet Nam"
			"QUA"  "Florida (USA)"
			"QUB"  "Connecticut (USA)"
			"QUC"  "Massachusetts (USA)"
			"N/A"  "Not applicable"

*/

		*-------------------------------*
		* 		Has siblings			*	
		*-------------------------------*

		*-Who usually lives at home with you? 
		gen sibs = .
		replace sibs = 0 if inlist(ST11Q03,1,2)==1 	| inlist(ST11Q04,1,2)==1 //Defined if yes/no at least for one.
		replace sibs = 1 if inlist(ST11Q03,1)==1 	| inlist(ST11Q04,1)==1 //Defined as YES if yes at least for one.

	*-----------------------------*
	* 3. Save the dataset         *
	*-----------------------------*

		destring CNTRYID, replace
		gen year = 2012
		compress
		save "$TEMP\COVID\pisa_student_2012.dta", replace


end

capture program drop import_data_2015
program define import_data_2015

	//import spss using "$IN\PISA\2015\CY6_MS_CMB_STU_QQ2.SAV", clear
	import spss using "$IN\PISA\2015\CY07_MSU_STU_QQQ.SAV", clear
	
	gen year = 2015
	compress
	save "$TEMP\COVID\pisa_student_2015.dta", replace


end

capture program drop import_data_2018
program define import_data_2018



	import spss using "$IN\PISA\2018\CY07_MSU_STU_QQQ.SAV", clear
	
	//use "$TEMP\COVID\pisa_student_2018.dta", clear

	
	*- Which language do you usually speak with: My mother
	//ST023Q01TA
	tab ST023Q01TA

	
	
	*- Which language do you usually speak with: My father
	//ST023Q02TA
	tab ST023Q02TA

	
	
	*- Which language do you usually speak with: My brother(s) and/or sister(s)
	//ST023Q03TA
	tab ST023Q03TA
		//Could define based on 'not applicable' not it also includes cases of 'heritage and test language are the same' plus, has similar number of cases than for father or mother.
	tab ST023Q01TA ST023Q03TA
	 
	 
	 
	*- How easy is it for you to talk to the following people about things that really bother you? Your brother(s)
	//WB162Q05HA
	tab WB162Q05HA
	gen brother = inlist(WB162Q05HA,5)==1 if inlist(WB162Q05HA,1,2,3,4,5)
	
	*- How easy is it for you to talk to the following people about things that really bother you? Your sister(s)
	//WB162Q06HA
	tab WB162Q06HA
	gen sister = inlist(WB162Q05HA,5)==1 if inlist(WB162Q05HA,1,2,3,4,5)
	
	
	*- Sibling definition
	gen sibs = (brother==1 | sister==1) if brother!=. & sister!=.
	
	
	*- How often do the following people work with you on your schoolwork? Your brothers and sisters
	//EC155Q03DA

	

	
	
	gen year = 2018
	compress
	save "$TEMP\COVID\pisa_student_2018.dta", replace


end

capture program drop import_data_2022
program define import_data_2022



	import spss using "$IN\PISA\2022\CY08MSP_STU_QQQ.SAV", clear


	//Country
	ds CNTRYID

	//Test Scores (Plausible Values)
	ds PV*MATH PV*READ PV*SCIE

	//Number of siblings
	tab ST230Q01JA
	gen sibs = inlist(ST230Q01JA,2,3,4)==1 if ST230Q01JA!=.
	
	*-How easy is it for you to talk to the following people about things that really bother you: Your brother(s)
	ds WB162Q05HA
	
	*-How easy is it for you to talk to the following people about things that really bother you: Your sister(s)
	ds WB162Q06HA
	
	tab WB162Q05HA if sibs==1
	tab WB162Q05HA if sibs==0
	tab WB162Q06HA if sibs==1
	tab WB162Q06HA if sibs==0
	//Seems accurate

	//SES
	sum ESCS


	*-----------------------------*
	* x. Save the dataset         *
	*-----------------------------*

	gen year = 2022
	compress

	save "$TEMP\COVID\pisa_student_2022.dta", replace

end

capture program drop import_data_2018_D
program define import_data_2018_D


	import spss using "$IN\PISA\2018-D\CY1MDAI_STU_QQQ.SAV", clear

	//Test Scores (Plausible Values)
	ds PV*MATH PV*READ PV*SCIE
	
	*- Siblings
	tab ST029Q05NA
	gen sibs = inlist(ST029Q05NA,1)==1 if ST029Q05NA!=.
	*-----------------------------*
	* x. Save the dataset         *
	*-----------------------------*

	gen year = 2018
	compress

	save "$TEMP\COVID\pisa_student_2018_D.dta", replace
end

*- Review
capture program drop review
program define review

	use "$TEMP\COVID\pisa_student_2009.dta", clear
	use "$TEMP\COVID\pisa_student_2012.dta", clear
	use "$TEMP\COVID\pisa_student_2015.dta", clear
	use "$TEMP\COVID\pisa_student_2018.dta", clear
	use "$TEMP\COVID\pisa_student_2022.dta", clear

	
	*- Does 2018-D has countries in 2022?
	use "$TEMP\COVID\pisa_student_2018_D.dta", clear
	
	bys CNT: keep if _n==1
	tempfile pisa_2018_D
	save `pisa_2018_D', replace
	
	use "$TEMP\COVID\pisa_student_2022.dta", clear
	
	bys CNT: keep if _n==1
	tempfile pisa_2022
	save `pisa_2022', replace
	
	merge 1:1 CNT using `pisa_2018_D'
	
	tab CNT if _m==3
	
	
end

*- Append years
capture program drop append_years
program define append_years

	use CNT CNTRYID sibs year PV*MATH PV*READ PV*SCIE using "$TEMP\COVID\pisa_student_2022.dta", clear
	append using "$TEMP\COVID\pisa_student_2018.dta", keep(CNT CNTRYID sibs year PV*MATH PV*READ PV*SCIE)
	append using "$TEMP\COVID\pisa_student_2018_D.dta", keep(CNT CNTRYID sibs year PV*MATH PV*READ PV*SCIE)
	//append using "$TEMP\COVID\pisa_student_2015.dta", keep(CNT /*sibs*/ year PV*MATH PV*READ PV*SCIE)
	append using "$TEMP\COVID\pisa_student_2012.dta", keep(CNT CNTRYID sibs year PV*MATH PV*READ PV*SCIE)
	append using "$TEMP\COVID\pisa_student_2009.dta", keep(CNT CNTRYID sibs year PV*MATH PV*READ PV*SCIE)


	*-----------------------------*
	* x. Keep countries with information pre and post
	*-----------------------------*
	/*
	local n_years = 4

	bysort CNT (year): 	gen tag = year != year[_n-1]   // tag unique years
	bysort CNT (year): 	replace tag = 1 if _n == 1      // make sure first obs is tagged
	
	//keep if CNTRYID==383
	bysort CNT:			egen n_years = total(tag)
	keep if n_years == `n_years' 
	*/
	
	bys CNT: egen min_year = min(year)
	bys CNT: egen max_year = max(year)	
	//keep if max_year==2022 & min_year<2022

		
	bys CNT: egen min_year_sibs = min(cond(sibs!=.,year,.))
	bys CNT: egen max_year_sibs = max(cond(sibs!=.,year,.))
	
	*-----------------------------*
	* x. Fill country name when missing
	*-----------------------------*

	//No need
	bysort CNT (year): replace CNTRYID = CNTRYID[_N]

	compress
	
	save "$TEMP\COVID_pisa_append", replace

end 


capture program drop analyze_2009_2012_vs_2022
program define analyze_2009_2012_vs_2022

	use  "$TEMP\COVID_pisa_append", clear
	
	tab year sibs, row nofreq
	// Year more similar to 2022 is 2009. Closer year in time is 2018
	
	keep if max_year==2022 & min_year<2022
	keep if sibs!=.
	keep if max_year_sibs==2022 & min_year_sibs<2022

	//collapse PV1MATH, by(CNTRYID year)
	

	//Country averages
	preserve
		collapse PV*MATH PV*READ PV*SCIE, by(CNTRYID year)
		*graph hbar (mean) PV1MATH, over(CNTRYID, sort(1) label(labsize(*0.3)))  
		rename (PV*MATH PV*READ PV*SCIE) (PV*MATH_avg PV*READ_avg PV*SCIE_avg)
		reshape wide PV*MATH_avg PV*READ_avg PV*SCIE_avg, i(CNTRYID) j(year)
		tempfile PV_CNTRYID
		save `PV_CNTRYID', replace
	restore

	//How is the gap by # children in each country?
	preserve
		collapse PV*MATH PV*READ PV*SCIE /*[iw=SENWT]*/, by(CNTRYID year sibs)
		foreach v of var PV*MATH PV*READ PV*SCIE {
			bys CNTRYID year (sibs): gen gap_`v' = `v'-`v'[1] if _n!=1
			}
		keep if sibs==1
		tempfile gap_long_PV_CNTRYID
		save `gap_long_PV_CNTRYID', replace		
		drop PV*MATH PV*READ PV*SCIE		
		reshape wide gap*, i(CNTRYID) j(year)
		tempfile gap_wide_PV_CNTRYID
		save `gap_wide_PV_CNTRYID', replace	
	restore
	
	preserve
		
		bys CNTRYID: keep if _n==1
		keep CNTRYID
		
		merge m:1 CNTRYID using `PV_CNTRYID', keep(master match) nogen
		merge m:1 CNTRYID using `gap_wide_PV_CNTRYID', keep(master match) nogen
		
		*graph hbar (mean) gap, over(CNTRYID, sort(1) label(labsize(*0.3)))  
		/*
		merge m:1 CNTRYID using `PV1MATH_CNTRYID'


		scatter gap PV1MATH_avg
		*/

		graph hbar (mean) gap_PV1MATH2018, over(CNTRYID, sort(1) label(labsize(*0.3)))  
		graph hbar (mean) gap_PV1MATH2022, over(CNTRYID, sort(1) label(labsize(*0.3)))  
		gen gap_PV1MATH = gap_PV1MATH2022 - gap_PV1MATH2018
		histogram gap_PV1MATH
	restore

	
	//preserve
		
		bys CNTRYID year: keep if _n==1
		keep CNT CNTRYID year
		merge m:1 CNTRYID  using `PV_CNTRYID', keep(master match) nogen	
		merge m:1 CNTRYID year using `gap_long_PV_CNTRYID', keep(master match) nogen	
		foreach year in "2009" "2012" {
		foreach subj in "PV1MATH" "PV1READ" /*"PV1SCIE"*/ {
		
			local ytitle_PV1MATH = "Siblings - Only Child Gap (Mathematics)"
			local ytitle_PV1READ = "Siblings - Only Child Gap (Reading)"
			local ytitle_PV1SCIE = "Siblings - Only Child Gap (Science)"
			
			twoway 	///
					(scatter gap_`subj' year if CNT=="KHM", mcolor("${blue_1}")) ///
					(scatter gap_`subj' year if CNT=="GTM", mcolor("${blue_3}")) ///
					(scatter gap_`subj' year if CNT=="PRY", mcolor("${blue_4}")) ///
					, ///
					legend(order(1 "Cambodia" 2 "Guatemala" 3 "Paraguay") col(3) pos(6)) ///
					ytitle(`ytitle_`subj'') ///
					xlabel(2018 2022)
				capture qui graph export "$FIGURES\Descriptive\PISA_gap_`subj'_2009_2022.png", replace			
				capture qui graph export "$FIGURES\Descriptive\PISA_gap_`subj'_2018D_2022.pdf", replace		
			}
		}	
	restore



	graph hbar (mean) gap_PV1MATH2009, over(CNTRYID, sort(1) label(labsize(*0.3)))  
	graph hbar (mean) gap_PV1MATH2012, over(CNTRYID, sort(1) label(labsize(*0.3)))  
	graph hbar (mean) gap_PV1MATH2022, over(CNTRYID, sort(1) label(labsize(*0.3)))  
	graph hbar (mean) gap_PV1MATH, over(CNTRYID, sort(1) label(labsize(*0.3)))  

	gen gap_PV1MATH = gap_PV1MATH2022 - gap_PV1MATH2012
	
	capture erase "$TEMP\COVID\erase_test.dta"
	
end


capture program drop analyze_2018_D_vs_2022
program define analyze_2018_D_vs_2022

	use  "$TEMP\COVID_pisa_append", clear
		
	keep if sibs!=.

	//collapse PV1MATH, by(CNTRYID year)
	keep if min_year_sibs==2018 
	keep if max_year_sibs==2022
	
	tab CNTRYID
	//  Cambodia  Guatemala   Paraguay
	
	//Country averages
	preserve
		collapse PV*MATH PV*READ PV*SCIE, by(CNTRYID year)
		*graph hbar (mean) PV1MATH, over(CNTRYID, sort(1) label(labsize(*0.3)))  
		rename (PV*MATH PV*READ PV*SCIE) (PV*MATH_avg PV*READ_avg PV*SCIE_avg)
		reshape wide PV*MATH_avg PV*READ_avg PV*SCIE_avg, i(CNTRYID) j(year)
		tempfile PV_CNTRYID
		save `PV_CNTRYID', replace
	restore

	//How is the gap by # children in each country?
	preserve
		collapse PV*MATH PV*READ PV*SCIE /*[iw=SENWT]*/, by(CNTRYID year sibs)
		foreach v of var PV*MATH PV*READ PV*SCIE {
			bys CNTRYID year (sibs): gen gap_`v' = `v'-`v'[1] if _n!=1
			}
		keep if sibs==1
		tempfile gap_long_PV_CNTRYID
		save `gap_long_PV_CNTRYID', replace		
		drop PV*MATH PV*READ PV*SCIE		
		reshape wide gap*, i(CNTRYID) j(year)
		tempfile gap_wide_PV_CNTRYID
		save `gap_wide_PV_CNTRYID', replace	
	restore
	

	
	preserve
		
		bys CNTRYID: keep if _n==1
		keep CNTRYID
		
		merge m:1 CNTRYID using `PV_CNTRYID', keep(master match) nogen
		merge m:1 CNTRYID using `gap_wide_PV_CNTRYID', keep(master match) nogen
		
		*graph hbar (mean) gap, over(CNTRYID, sort(1) label(labsize(*0.3)))  
		/*
		merge m:1 CNTRYID using `PV1MATH_CNTRYID'


		scatter gap PV1MATH_avg
		*/

		graph hbar (mean) gap_PV1MATH2018, over(CNTRYID, sort(1) label(labsize(*0.3)))  
		graph hbar (mean) gap_PV1MATH2022, over(CNTRYID, sort(1) label(labsize(*0.3)))  
		gen gap_PV1MATH = gap_PV1MATH2022 - gap_PV1MATH2018
		histogram gap_PV1MATH
	restore

	
	preserve
		bys CNTRYID year: keep if _n==1
		keep CNT CNTRYID year
		merge m:1 CNTRYID  using `PV_CNTRYID', keep(master match) nogen	
		merge m:1 CNTRYID year using `gap_long_PV_CNTRYID', keep(master match) nogen	
		
		foreach subj in "PV1MATH" "PV1READ" /*"PV1SCIE"*/ {
		
			local ytitle_PV1MATH = "Siblings - Only Child Gap (Mathematics)"
			local ytitle_PV1READ = "Siblings - Only Child Gap (Reading)"
			local ytitle_PV1SCIE = "Siblings - Only Child Gap (Science)"
			
			twoway 	///
					(scatter gap_`subj' year if CNT=="KHM", mcolor("${blue_1}")) ///
					(scatter gap_`subj' year if CNT=="GTM", mcolor("${blue_3}")) ///
					(scatter gap_`subj' year if CNT=="PRY", mcolor("${blue_4}")) ///
					, ///
					legend(order(1 "Cambodia" 2 "Guatemala" 3 "Paraguay") col(3) pos(6)) ///
					ytitle(`ytitle_`subj'') ///
					xlabel(2018 2022)
				capture qui graph export "$FIGURES\Descriptive\PISA_gap_`subj'_2018D_2022.png", replace			
				capture qui graph export "$FIGURES\Descriptive\PISA_gap_`subj'_2018D_2022.pdf", replace		
			}
	restore
	
	capture erase "$TEMP\COVID\erase_test.dta"
	
end
