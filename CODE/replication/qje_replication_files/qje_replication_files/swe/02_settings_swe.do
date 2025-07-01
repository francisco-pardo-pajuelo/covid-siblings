// --------
// SETTINGS (plots)
global score_max		= 2
global score_min		= -2
global score_tick		= 0.5
global n_bins 			= 20
global poly_bw			= 0.3

// Analysis (default values)
global absorb_default i.id_cutoff i.birthyear_sib
global forcing_var_default 1.above_cutoff
global p1_covs_default c.cutoff_distance c.cutoff_distance#1.above_cutoff
global p2_covs_default c.cutoff_distance c.cutoff_distance#c.cutoff_distance c.cutoff_distance#1.above_cutoff c.cutoff_distance#c.cutoff_distance#1.above_cutoff

// -----------------------------------
// OPTIMAL BANDWIDTHS (pooled)
// -----------------------------------
global bw_same_instprog_1     = 0.3860
global bw_same_instprog_2     = 1.1300
global bw_same_inst_1         = 0.3600
global bw_same_inst_2         = 0.9330
global bw_same_prog_1         = 0.3890
global bw_same_prog_2         = 1.2130
// -----------------------------------
// GENERATED: [ 6 Aug 2020] [09:25:40]
// -----------------------------------

exit 0
