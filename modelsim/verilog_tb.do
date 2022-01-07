
set SIM_LEVEL rtl ;# rtl|post_syn|post_par|libprep
#set SIM_LEVEL post_par ;# rtl|post_syn|post_par|libprep
#set SIM_LEVEL libprep
#variable SIM_CORNER min ;# min|max

switch $SIM_LEVEL {

  rtl      {
# compile source
    do {compile_src.do}
#        vsim serializer_tb
    vsim -L tsmc_cl018g_rvt_neg -L tsmc18_cg_neg -suppress 12027 digital_core_mc_tb -vopt -voptargs="+acc -xprop,mode=resolve" -sv_seed random 
  }

  post_par {
    do {compile_postpar.do}
        vsim uart_trx_tb
  }

  libprep {
    do {compile_reflibs.do}
    exit 
  }
} ;#-sdfreport=digital_core.sdf.report

#
#
#do {wave.gate.do}
#
# Set the window types
#
#view wave
#view structure
#view signals

#
# Source user do file (UDO)
#
#run 3us
#do {verilog_tb.udo}

#
# End
#
