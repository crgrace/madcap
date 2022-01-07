#
# Create work library
#
vlib work

#
# Map libraries
#
vmap work  

#
# Design sources
#
#vlog -incr -sv "../src/fifo_latch.sv" 
vlog -incr -sv "../src/fifo_ff.sv" 
#vlog -incr -sv "../src/fifo_ram.sv" 
#vlog -incr -sv "../src/fifo_top.sv"
vlog -incr -sv "../src/gate_posedge_clk.sv" 
vlog -incr -sv "../src/gate_negedge_clk.sv" 
vlog +incdir+../testbench/tasks/ -incr -sv "../src/config_regfile_mc.sv"
vlog -incr -sv "../src/tff.sv"
vlog -incr -sv "../src/clk_manager_mc.sv"
vlog -incr -sv "../src/uart_rx.sv" 
vlog -incr -sv "../src/uart_rx_config.sv" 
vlog -incr -sv "../src/uart_tx.sv" 
vlog -incr -sv "../src/uart_array_rx.sv" 
vlog -incr -sv "../src/uart_array_tx.sv" 
vlog -incr -sv "../src/pulse_stretcher.sv" 
vlog -incr -sv "../src/driver_ctrl.sv" 
vlog -incr -sv "../src/reset_sync.sv" 
vlog +incdir+../testbench/tasks/ -incr -sv "../src/prbs7.sv" 
vlog -incr "../src/datapath_fsm.sv" 
vlog -incr "../src/datapath.sv" 
vlog -incr "../src/config_path.sv" 
vlog -incr "../src/event_router.sv" 
vlog -incr "../src/tx_router.sv" 
vlog +incdir+../testbench/tasks/ -incr "../src/data_packet_builder.sv" 
vlog -incr "../src/config_packet_builder.sv" 
vlog -incr "../src/encode8b10b.v" 
vlog -incr "../src/encode24b30b.v" 
vlog -incr "../src/encode96b120b.v" 
vlog -incr "../src/serializer_ddr.sv" 
vlog -incr "../src/deserializer_sdr.sv" 
vlog +incdir+../testbench/tasks/ -incr "../src/comma_detect.sv" 
vlog +incdir+../testbench/tasks/ -incr "../src/digital_core_mc.sv" 
vlog -incr "../src/crc.sv" 
vlog -incr "../src/crc8.sv" 
#vlog -incr -sv "../src/fifo_rd_ctrl_async.sv" 
#vlog -incr -sv "../src/comms_ctrl.sv" 
#vlog -incr -sv "../src/hydra_ctrl.sv" 
#vlog -incr -sv "../src/channel_ctrl.sv"
#vlog -incr -sv "../src/external_interface.sv"
vlog -incr -sv "../src/timestamp_gen.sv"
vlog -incr -sv "../src/async2sync.sv"
#vlog -incr -sv "../src/periodic_pulser.sv"
#vlog -incr -sv "../src/digital_monitor.sv"
#vlog +incdir+../testbench/tasks/ -incr -sv -L rf2p_512x64_4_50 -L tsmc_cl018g_rvt_neg -L tsmc18_cg_neg "../src/digital_core.sv"
#vlog -L rf2p_512x64_4_50 -L tsmc_cl018g_rvt_neg -L tsmc18_cg_neg "../par/digital_core.output.v"
#vlog -incr -sv "../src/reset_sync.sv"

#
# Standard Cells
#
#vlog -incr -vopt "/eda/foundry/ARM/TSMC/cl018g/tsmc/cl018g/sc9tap_cg_rvt/r9p0-00rel0/verilog/tsmc18_cg_neg.v"
#vlog -incr -vopt  "/eda/foundry/ARM/TSMC/cl018g/tsmc/cl018g/sc9_base_rvt/2008q3v01/verilog/sage-x_tsmc_cl018g_rvt_neg.v"
#
# Testbenches
#
vlog -incr -sv "../testbench/unit_tests/uart_trx_tb.sv" 
vlog -incr -sv "../testbench/unit_tests/serializer_ddr_tb.sv" 
vlog +incdir+../testbench/larpix_tasks/ -incr -sv "../testbench/unit_tests/deserializer_sdr_tb.sv" 
vlog -incr -sv "../testbench/unit_tests/clk_manager_tb.sv" 
vlog +incdir+../testbench/tasks/ -incr -sv "../testbench/unit_tests/crc_tb.sv" 
vlog +incdir+../testbench/tasks/ -incr -sv "../testbench/unit_tests/crc8_tb.sv" 
vlog +incdir+../testbench/tasks/ -incr -sv "../testbench/unit_tests/event_router_tb.sv" 
vlog +incdir+../testbench/tasks/ -incr -sv "../testbench/unit_tests/datapath_tb.sv" 
vlog +incdir+../testbench/tasks/ -incr -sv "../testbench/unit_tests/config_path_tb.sv" 
vlog +incdir+../testbench/tasks/ -incr -sv "../testbench/unit_tests/encode8b10b_tb.sv" 
vlog +incdir+../testbench/tasks/ -incr -sv "../testbench/unit_tests/encode24b30b_tb.sv" 
vlog +incdir+../testbench/tasks/ -incr -sv "../testbench/unit_tests/encode96b120b_tb.sv" 
vlog +incdir+../testbench/tasks/ -incr -sv "../testbench/unit_tests/digital_core_mc_tb.sv" 

#
# aux modules for testbenches
#
vlog -incr "../testbench/sim_models/deserializer_ddr.sv" 
vlog -incr "../testbench/sim_models/serializer_sdr.sv" 
vlog -incr "../testbench/sim_models/output_mux.sv" 
vlog -incr "../testbench/sim_models/decode8b10b.v" 
vlog -incr "../testbench/sim_models/decode24b30b.v" 
vlog -incr "../testbench/sim_models/decode96b120b.v" 
vlog -incr "../testbench/sim_models/crc_check.sv" 
vlog +incdir+../testbench/tasks/ -incr -sv "../testbench/sim_models/analyze_superpacket.sv" 
#
# full chip model
#

#
# MCP
#

