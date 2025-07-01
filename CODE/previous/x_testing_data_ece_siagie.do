* Reviewing data from MINEDU: ECE-SIAGIE


import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE.xlsx", sheet("Sheet1") firstrow clear
tempfile ece_siagie_s1
save `ece_siagie_s1', replace

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE.xlsx", sheet("Sheet2") firstrow clear
tempfile ece_siagie_s2
save `ece_siagie_s2', replace

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE.xlsx", sheet("Sheet3") firstrow clear
tempfile ece_siagie_s3
save `ece_siagie_s3', replace

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE.xlsx", sheet("Sheet4") firstrow clear
tempfile ece_siagie_s4
save `ece_siagie_s4', replace

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE.xlsx", sheet("Sheet5") firstrow clear
tempfile ece_siagie_s5
save `ece_siagie_s5', replace

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE07_13.xlsx", sheet("Sheet1") firstrow clear
tempfile ece_siagie_07_13_s1
save `ece_siagie_07_13_s1', replace

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE07_13.xlsx", sheet("Sheet2") firstrow clear
tempfile ece_siagie_07_13_s2
save `ece_siagie_07_13_s2', replace

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE07_13.xlsx", sheet("Sheet3") firstrow clear
tempfile ece_siagie_07_13_s3
save `ece_siagie_07_13_s3', replace

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE14_23.xlsx", sheet("Sheet1") firstrow clear
tempfile ece_siagie_14_23_s1
save `ece_siagie_14_23_s1', replace

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE14_23.xlsx", sheet("Sheet2") firstrow clear
tempfile ece_siagie_14_23_s2
save `ece_siagie_14_23_s2', replace

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE14_23.xlsx", sheet("Sheet3") firstrow clear
tempfile ece_siagie_14_23_s3
save `ece_siagie_14_23_s3', replace

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE14_23.xlsx", sheet("Sheet4") firstrow clear
tempfile ece_siagie_14_23_s4
save `ece_siagie_14_23_s4', replace

import excel "$IN\MINEDU\ECE EM innominada\ECE\empate SIAGIE-ECE14_23.xlsx", sheet("Sheet5") firstrow clear
tempfile ece_siagie_14_23_s5
save `ece_siagie_14_23_s5', replace

use  `ece_siagie_s1', clear
gen db = "s1"
append using `ece_siagie_s2'
replace db = "s2" if db ==""
append using `ece_siagie_s3'
replace db = "s3" if db ==""
append using `ece_siagie_s4'
replace db = "s4" if db ==""
append using `ece_siagie_s5'
replace db = "s5" if db ==""

append using `ece_siagie_07_13_s1'
replace db = "07_13_s1" if db ==""
append using `ece_siagie_07_13_s2'
replace db = "07_13_s2" if db ==""
append using `ece_siagie_07_13_s3'
replace db = "07_13_s3" if db ==""

append using `ece_siagie_14_23_s1'
replace db = "14_23_s1" if db ==""
append using `ece_siagie_14_23_s2'
replace db = "14_23_s2" if db ==""
append using `ece_siagie_14_23_s3'
replace db = "14_23_s3" if db ==""
append using `ece_siagie_14_23_s4'
replace db = "14_23_s4" if db ==""
append using `ece_siagie_14_23_s5'
replace db = "14_23_s5" if db ==""




duplicates tag *, gen(dup)
duplicates tag id_SIAGIE, gen(dup_siagie)
duplicates tag id_estudiante, gen(dup_ece)

gen year = substr(id_estudiante,1,4)


bys id_SIAGIE: egen has_2016 = max(cond(year=="2016",1,0))

sort id_SIAGIE
br if dup_siagie == 3 & has_2016==1



*- SIAGIE

set seed 1234

global excel = 1
global test = 1

	






