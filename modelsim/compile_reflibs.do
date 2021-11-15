
#exec "rm -rf [pwd]/tsmc_cl018g_rvt_neg"
vdel -all -lib [pwd]/tsmc_cl018g_rvt_neg
vlib tsmc_cl018g_rvt_neg
vmap tsmc_cl018g_rvt_neg    [pwd]/tsmc_cl018g_rvt_neg

#exec "rm -rf [pwd]/tsmc18_cg_neg"
#vdel -all -lib [pwd]/tsmc18_cg_neg
vlib tsmc18_cg_neg
vmap tsmc18_cg_neg    [pwd]/tsmc18_cg_neg

#exec "rm -rf [pwd]/tsmc18_cg_neg"
#vdel -all -lib [pwd]/rf2p_512x64_4_50
#vlib rf2p_512x64_4_50
#vmap rf2p_512x64_4_50    [pwd]/rf2p_512x64_4_50

vlog -work tsmc_cl018g_rvt_neg "/eda/foundry/ARM/TSMC/cl018g/tsmc/cl018g/sc9_base_rvt/2008q3v01/verilog/sage-x_tsmc_cl018g_rvt_neg.v"
vlog -work tsmc18_cg_neg "/eda/foundry/ARM/TSMC/cl018g/tsmc/cl018g/sc9tap_cg_rvt/r9p0-00rel0/verilog/tsmc18_cg_neg.v"
#vlog -work rf2p_512x64_4_50 "[pwd]/../ip/memory/rf_2p_512x64_4mux_50MHz/rf2p_512x64_4_50.v"
