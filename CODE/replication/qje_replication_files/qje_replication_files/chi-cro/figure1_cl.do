*** Figure I: Older Siblings’ Admission and Enrollment Probabilities in Target
*** Major-College at the Admission Cutoff (First Stage)

label variable enrolls_old  "Older sibling's enrollment"
label variable admitted_old "Older sibling's admission in target college-major"

local bw_colmaj   = 18.00
local covs c.score_rd c.score_rdc

foreach var of varlist admitted_old enrolls_old {

  local vtext1: variable label `var'
  local contador = 0

  local nbins1 = round(100/5)
  local nbins2 = round(100/5)

  gen rdplot_mean_x =.

	 forvalues z = 1/40{
		replace rdplot_mean_x = -97.5 + (`z'-1)*5 if score_rd >= -100 + (`z' - 1)*5 & score_rd < -100 + `z'*5
	}

	bys rdplot_mean_x: egen rdplot_mean_y = mean(`var')
  bys rdplot_mean_x: gen bin_id = _n

	sum rdplot_mean_y
	local lb = 0
	local ub = 1
	local gap = 0.1

	#delimit;
	twoway (lpolyci `var' score_rd if score_rd >= 0, bwidth(`bwc') degree(1) lcolor(red) ciplot(rline) lcolor(red))
	(lpolyci `var' score_rd if score_rd < 0, bwidth(`bwc') degree(1) lcolor(red) ciplot(rline) lcolor(red))
	(scatter rdplot_mean_y rdplot_mean_x if bin_id == 1, sort  mcolor(navy) msize(vsmall) msymbol(circle))
	(scatteri `lb' 0 `ub' 0, recast(line) lpattern(dash) lcolor(black))
	if score_rd >= -100 & score_rd <= 100 & rdplot_mean_y !=.,
	yscale(range(`lb' `ub')) ylabel(`lb'(`gap')`ub' , labels labsize(vsmall) labcolor(black) angle(horizontal) format(%03.2f))
	xtitle(Older Siblings' Application Score ) xtitle(, size(midsmall))
	xlabel(-100(10)100, labsize(vsmall))
	legend(off);
	#delimit cr

  drop rdplot_mean_x rdplot_mean_y bin_id
  graph save   "first_stage_`var'_p1.gph",replace
  graph export "firts_stage_`var'_p1.pdf",replace as(pdf)
  graph export "firts_stage_`var'_p1.eps",replace as(eps)

}
