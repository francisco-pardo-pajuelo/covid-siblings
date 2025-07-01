capture program drop est_reghdfe
program define est_reghdfe
	syntax varlist(fv ts) [aweight/] [if/], bw(real) p(string) [fe(string) kernel(string) iv(string) NOFirst indepvar(string) estsave(string) m(string) comment(string) NOSters verbose]

	// Defaults

	// Forcing var
	if ("`indepvar'" == "") {
		local indepvar $forcing_var_default
	}
	else {
		if ("`iv'" != "") {
			display as error "Cannot set both indepvar() and iv()."
			exit 1
		}
	}

	// Fixeed effects defaults to global setting
	if ("`fe'" == "") {
		if ("$absorb_default" == "") {
			display as error "No global absorb_default set."
			exit 1
		}
		local fe $absorb_default
	}

	if ("`if'" != "") local ifcmd = "& `if'"

	if ("`iv'" != "") {
		local cmd = "iv"
		local x = "(`iv')"
		if ("`nofirst'" == "") local opts = "first ffirst savefirst savefprefix(fs_)"
		tokenize "`iv'", parse("#= ")
		local endogvar = "`1'"
	}
	else {
		local x = "`indepvar'"
		local opts = "summarize(mean)"
	}

	// Allow for uniform and triangular kernel weights
	tempvar w
	if ("`kernel'" == "") local kernel = "uniform"
	if ("`kernel'" == "uniform") {
		quietly generate `w' = 1
	}
	else if ("`kernel'" == "triangular") {
		quietly generate `w' = (1 - abs(cutoff_distance / `bw'))
	}
	else {
		display as error "Kernel must be uniform or triangular."
		exit 1
	}

	// If another kind of weight is applied as well.
	if ("`weight'" != "") quietly replace `w' = `w' * `exp'

	// Include linear or quadratic polynomials
	if ("`p'" == "1") {
		if ("$p1_covs_default" == "") {
			display as error "No global p1_covs_default set."
			exit 1
		}
		local covs $p1_covs_default
	}
	else if ("`p'" == "2") {
		if ("$p2_covs_default" == "") {
			display as error "No global p2_covs_default set."
			exit 1
		}
		local covs $p2_covs_default

	}
	else if ("`p'" == "custom") {
		local covs = ""
	}
	else {
		display as error "No valid p() set."
		exit 1
	}



	if ("`verbose'" != "") local verb = "noisily"
	if ("`verbose'" == "") local verb = "quietly"

	`verb' {
		noisily display "[$S_TIME] - est_reghdfe(`cmd'reghdfe, `varlist', bw=`bw', p=`p')"

		`cmd'reghdfe `varlist' `covs' `x' [aw=`w'] ///
			if cutoff_distance >= -1 * `bw' & cutoff_distance <= `bw' `ifcmd', ///
			absorb(`fe') cluster(id_family) noconstant `opts'

		if ("`estsave'" != "") {

			// Outcome mean
			estadd ysumm

			// Control group outcome mean
			summarize `e(depvar)' [aw=`w'] if e(sample) & `indepvar' == 0, meanonly
			estadd scalar yctrl = r(mean)

			if ("`iv'" != "") local ivopt = "endogvar(`endogvar')"
			if ("`iv'" != "" & "`nofirst'" == "") local ivopt = "`ivopt' savefirst"
			estSave, f("`estsave'") m("`m'") bw("`bw'") p("`p'") fe("`fe'") ///
				filter("`if'") k("`kernel'") weights("`exp'") outcome("`varlist'") ///
				comment(`comment') `ivopt' `verbose' `nosters'
		}
	}
end

// Program saves estimates with eststo and in file using regsave
// If iv, option iv needs to be set to varname of endog. var.
// Syntax example (to save estimates in memory): estsave, m(model_name) f(file_name)
capture program drop estSave
program define estSave
	syntax, f(string) m(string) ///
		[bw(string) p(string) fe(string) filter(string) k(string) weights(string) ///
		 savefirst endogvar(string) outcome(string) comment(string) verbose NOSters]

	// Dots not allowed in model names
	local m = strtoname("`m'")

	if (length("`m'") > 32 | ("`savefirst'" != "" & length("`m'") > 25)) {
		display as error "estSave(): Model name too long."
		exit 1
	}

	// Store estimates
	quietly eststo `m'

	// Save to file using regsave
	capture confirm file `f'.dta // If file exists, append
	if (_rc == 0) local rs_append = "append"

	local labels = "modelname, `m'," ///
				 + "comment, `comment'," ///
				 + "endogvar, `endogvar'," ///
				 + "outcome, `outcome'," ///
				 + "bandwidth, `bw'," ///
				 + "polynomial, `p'," ///
				 + "fixedeffects, `fe'," ///
				 + "filter, `filter'," ///
				 + "kernel_settings, `k'," ///
				 + "weights, `weights'"

	if ("`verbose'" != "") local verb = "noisily"
	if ("`verbose'" == "") local verb = "quietly"

	`verb' {
		noisily display "[$S_TIME] - estSave(`m', `f') - addlabels(`labels') - `ew_append'"

		regsave using `f'.dta, `rs_append' tstat pval ci detail(all) ///
			addlabel(`labels', "firststage", "no")
		if ("`nosters'" == "") {
			capture confirm file `f'.sters
			if (_rc == 0) local ew_append = "append"
			estwrite `m' using `f'.sters, `ew_append'
		}

		// Save First Stage (if IV)
		if ("`savefirst'" != "") {
			// Save to file using regsave
			capture confirm file `f'.dta // If file exists, append
			if (_rc == 0) local rs_append = "append"

			local fs_name = subinstr("fs_`endogvar'", ".", "_", .)
			estimates restore `fs_name'
			eststo fs_`m'
			regsave using `f'.dta, `rs_append' tstat pval ci detail(all) ///
				addlabel(`labels', "firststage", "yes")

			if ("`nosters'" == "") {
				capture confirm file `f'.sters
				if (_rc == 0) local ew_append = "append"
				estwrite fs_`m' using `f'.sters, `ew_append'
			}

			estimates drop `fs_name'
		}
	}
end
