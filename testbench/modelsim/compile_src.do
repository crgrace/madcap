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
vlog -incr -sv "../src/fifo_latch.sv" 
vlog -incr -sv "../src/fifo_ff.sv" 
vlog -incr -sv "../src/fifo_ram.sv" 
vlog -incr -sv "../src/fifo_top.sv"
vlog -incr -sv "../src/gate_posedge_clk.sv" 
vlog -incr -sv "../src/gate_negedge_clk.sv" 
vlog +incdir+../testbench/larpix_tasks/ -incr -sv "../src/config_regfile.sv"
vlog -incr -sv "../src/tff.sv"
vlog -incr -sv "../src/clk_manager.sv"
vlog -incr -sv "../src/uart_rx.sv" 
vlog -incr -sv "../src/uart_tx.sv" 
vlog -incr -sv "../src/uart.sv" 
vlog -incr "../src/event_router.sv" 
vlog -incr -sv "../src/fifo_rd_ctrl_async.sv" 
vlog -incr -sv "../src/comms_ctrl.sv" 
vlog -incr -sv "../src/hydra_ctrl.sv" 
vlog -incr -sv "../src/channel_ctrl.sv"
vlog -incr -sv "../src/external_interface.sv"
vlog -incr -sv "../src/timestamp_gen.sv"
vlog -incr -sv "../src/async2sync.sv"
vlog -incr -sv "../src/periodic_pulser.sv"
vlog -incr -sv "../src/digital_monitor.sv"
vlog +incdir+../testbench/larpix_tasks/ -incr -sv -L rf2p_512x64_4_50 -L tsmc_cl018g_rvt_neg -L tsmc18_cg_neg "../src/digital_core.sv"
#vlog -L rf2p_512x64_4_50 -L tsmc_cl018g_rvt_neg -L tsmc18_cg_neg "../par/digital_core.output.v"
vlog -incr -sv "../src/reset_sync.sv"

#
# Memory behavioral model
#
#vlog -incr -vopt "../ip/memory/rf_2p_64x22_2mux/rf_2p_64x22.v"
#vlog -incr -vopt "../ip/memory/rf_2p_512x64_4mux/rf_2p_512x64_4mx.v"
#vlog -incr -vopt "../ip/memory/rf_2p_512x64_4mux_50MHz/rf2p_512x64_4_50.v"

#
# Standard Cells
#
vlog -incr -vopt "/eda/foundry/ARM/TSMC/cl018g/tsmc/cl018g/sc9tap_cg_rvt/r9p0-00rel0/verilog/tsmc18_cg_neg.v"
#vlog -incr -vopt  "/eda/foundry/ARM/TSMC/cl018g/tsmc/cl018g/sc9_base_rvt/2008q3v01/verilog/sage-x_tsmc_cl018g_rvt_neg.v"
#
# Testbenches
#
vlog -incr -vopt  -sv "../testbench/unit_tests/fifo_tb.sv" 
vlog -incr -vopt -sv "../testbench/unit_tests/fifo_burst_tb.sv" 
vlog -incr -vopt -sv "../testbench/unit_tests/rf_2p_64x22_tb.sv" 
vlog -incr -vopt  -sv "../testbench/unit_tests/uart_tb.sv" 
#vlog -incr -vopt  "../testbench/unit_tests/event_builder_tb.v" 
#vlog -incr -vopt  "../testbench/unit_tests/comms_ctrl_tb.v" 
#vlog -incr -vopt "../testbench/unit_tests/sar_ctrl_tb.v" 
#vlog -incr -vopt "../testbench/unit_tests/sar_ctrl_rev1_tb.v" 
vlog +incdir+../testbench/larpix_tasks/ -incr -vopt -sv "../testbench/unit_tests/channel_ctrl_tb.sv" 
vlog -incr -vopt  -sv "../testbench/unit_tests/timers_tb.sv" 
#vlog -incr -vopt -sv "../testbench/unit_tests/channel_ctrl_wip_tb.sv" 
vlog -incr -vopt "../testbench/unit_tests/external_interface_tb.sv" 
#vlog -incr -vopt  "../testbench/unit_tests/analog_core_tb.v" 
vlog -incr -vopt "../testbench/digital_core_tb.v" 
vlog +incdir+../testbench/larpix_tasks/ -incr -vopt -sv "../testbench/unit_tests/larpix_single_tb.sv" 
vlog +incdir+../testbench/larpix_tasks/ -incr -vopt -sv "../testbench/unit_tests/larpix_hydra_tb.sv" 


#
# analog behavioral models
#
vlog -incr -vopt -sv "../testbench/analog_core/sar_adc_core.sv" 
vlog -incr -vopt -sv "../testbench/analog_core/discriminator.sv" 
vlog -incr -vopt -sv "../testbench/analog_core/csa.sv" 
vlog -incr -vopt -sv "../testbench/analog_core/analog_channel.sv" 
vlog -incr -vopt -sv "../testbench/analog_core/analog_core.sv" 

#
# full chip model
#
vlog -incr -vopt -sv "../testbench/larpix_v2b/larpix_v2b.sv" 

#
# MCP
#

#vlog +incdir+../testbench/larpix_tasks/ -incr "../testbench/mcp/mcp_spi.v"
#vlog +incdir+../testbench/larpix_tasks/ -incr "../testbench/mcp/mcp_regmap.v"
#vlog +incdir+../testbench/larpix_tasks/ -incr "../testbench/mcp/mcp_analog.v"
vlog +incdir+../testbench/larpix_tasks/ -vopt -incr "../testbench/mcp/mcp_external_interface.sv"
vlog +incdir+../testbench/larpix_tasks/ -vopt -incr "../testbench/mcp/mcp_larpix_single.sv"
vlog +incdir+../testbench/larpix_tasks/ -vopt -incr "../testbench/mcp/mcp_larpix_hydra.sv"
vlog +incdir+../testbench/larpix_tasks/ -vopt -incr "../testbench/mcp/mcp.sv"
#vlog -incr "../testbench/mcp/mcp_regmap.v"
