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
vlog -incr -sv "../../larpix_v2c/src/fifo_latch.sv" 
vlog -incr -sv "../../larpix_v2c/src/fifo_ff.sv" 
vlog -incr -sv "../../larpix_v2c/src/fifo_ram.sv" 
vlog -incr -sv "../../larpix_v2c/src/fifo_top.sv"
vlog -incr -sv "../../larpix_v2c/src/gate_posedge_clk.sv" 
vlog -incr -sv "../../larpix_v2c/src/gate_negedge_clk.sv" 
vlog +incdir+../../larpix_v2c/testbench/larpix_tasks/ -incr -sv "../../larpix_v2c/src/config_regfile.sv"
vlog -incr -sv "../../larpix_v2c/src/tff.sv"
vlog -incr -sv "../../larpix_v2c/src/clk_manager.sv"
vlog -incr -sv "../../larpix_v2c/src/uart_rx.sv" 
vlog -incr -sv "../../larpix_v2c/src/uart_tx.sv" 
vlog -incr -sv "../../larpix_v2c/src/uart.sv" 
vlog -incr "../../larpix_v2c/src/event_router.sv" 
vlog -incr -sv "../../larpix_v2c/src/fifo_rd_ctrl_async.sv" 
vlog -incr -sv "../../larpix_v2c/src/comms_ctrl.sv" 
vlog -incr -sv "../../larpix_v2c/src/hydra_ctrl.sv" 
vlog -incr -sv "../../larpix_v2c/src/channel_ctrl.sv"
vlog -incr -sv "../../larpix_v2c/src/external_interface.sv"
vlog -incr -sv "../../larpix_v2c/src/timestamp_gen.sv"
vlog -incr -sv "../../larpix_v2c/src/async2sync.sv"
vlog -incr -sv "../../larpix_v2c/src/periodic_pulser.sv"
vlog -incr -sv "../../larpix_v2c/src/digital_monitor.sv"
vlog +incdir+../../larpix_v2c/testbench/larpix_tasks/ -incr -sv -L rf2p_512x64_4_50 -L tsmc_cl018g_rvt_neg -L tsmc18_cg_neg "../../larpix_v2c/src/digital_core.sv"
#vlog +incdir+../../larpix_v2c/testbench/larpix_tasks/ -incr -sv -L rf2p_512x64_4_50 -L tsmc_cl018g_rvt_neg -L tsmc18_cg_neg "../../larpix_v2c/src/digital_core.sv"
#vlog -L rf2p_512x64_4_50 -L tsmc_cl018g_rvt_neg -L tsmc18_cg_neg "../../larpix_v2c/par/digital_core.output.v"
vlog -incr -sv "../../larpix_v2c/src/reset_sync.sv"

#
# Memory behavioral model
#
#vlog -incr -vopt "../../larpix_v2c/ip/memory/rf_2p_64x22_2mux/rf_2p_64x22.v"
#vlog -incr -vopt "../../larpix_v2c/ip/memory/rf_2p_512x64_4mux/rf_2p_512x64_4mx.v"
vlog -incr -vopt "../../larpix_v2c/ip/memory/rf_2p_512x64_4mux_50MHz/rf2p_512x64_4_50.v"

#
# Standard Cells
#
vlog -incr -vopt "/eda/foundry/ARM/TSMC/cl018g/tsmc/cl018g/sc9tap_cg_rvt/r9p0-00rel0/verilog/tsmc18_cg_neg.v"
#vlog -incr -vopt  "/eda/foundry/ARM/TSMC/cl018g/tsmc/cl018g/sc9_base_rvt/2008q3v01/verilog/sage-x_tsmc_cl018g_rvt_neg.v"
#
# Testbenches
#
vlog -incr -vopt  -sv "../../larpix_v2c/testbench/unit_tests/fifo_tb.sv" 
vlog -incr -vopt -sv "../../larpix_v2c/testbench/unit_tests/fifo_burst_tb.sv" 
vlog -incr -vopt -sv "../../larpix_v2c/testbench/unit_tests/rf_2p_64x22_tb.sv" 
vlog -incr -vopt  -sv "../../larpix_v2c/testbench/unit_tests/uart_tb.sv" 
#vlog -incr -vopt  "../../larpix_v2c/testbench/unit_tests/event_builder_tb.v" 
#vlog -incr -vopt  "../../larpix_v2c/testbench/unit_tests/comms_ctrl_tb.v" 
#vlog -incr -vopt "../../larpix_v2c/testbench/unit_tests/sar_ctrl_tb.v" 
#vlog -incr -vopt "../../larpix_v2c/testbench/unit_tests/sar_ctrl_rev1_tb.v" 
vlog +incdir+../../larpix_v2c/testbench/larpix_tasks/ -incr -vopt -sv "../../larpix_v2c/testbench/unit_tests/channel_ctrl_tb.sv" 
vlog -incr -vopt  -sv "../../larpix_v2c/testbench/unit_tests/timers_tb.sv" 
#vlog -incr -vopt -sv "../../larpix_v2c/testbench/unit_tests/channel_ctrl_wip_tb.sv" 
vlog -incr -vopt "../../larpix_v2c/testbench/unit_tests/external_interface_tb.sv" 
#vlog -incr -vopt  "../../larpix_v2c/testbench/unit_tests/analog_core_tb.v" 
vlog -incr -vopt "../../larpix_v2c/testbench/digital_core_tb.v" 
vlog +incdir+../../larpix_v2c/testbench/larpix_tasks/ -incr -vopt -sv "../../larpix_v2c/testbench/unit_tests/larpix_single_tb.sv" 
vlog +incdir+../../larpix_v2c/testbench/larpix_tasks/ -incr -vopt -sv "../../larpix_v2c/testbench/unit_tests/larpix_hydra_tb.sv" 


#
# analog behavioral models
#
vlog -incr -vopt -sv "../../larpix_v2c/testbench/analog_core/sar_adc_core.sv" 
vlog -incr -vopt -sv "../../larpix_v2c/testbench/analog_core/discriminator.sv" 
vlog -incr -vopt -sv "../../larpix_v2c/testbench/analog_core/csa.sv" 
vlog -incr -vopt -sv "../../larpix_v2c/testbench/analog_core/analog_channel.sv" 
vlog -incr -vopt -sv "../../larpix_v2c/testbench/analog_core/analog_core.sv" 

#
# full chip model
#
vlog -incr -vopt -sv "../../larpix_v2c/testbench/larpix_v2c/larpix_v2c.sv" 

#
# MCP
#

#vlog +incdir+../../larpix_v2c/testbench/larpix_tasks/ -incr "../../larpix_v2c/testbench/mcp/mcp_spi.v"
#vlog +incdir+../../larpix_v2c/testbench/larpix_tasks/ -incr "../../larpix_v2c/testbench/mcp/mcp_regmap.v"
#vlog +incdir+../../larpix_v2c/testbench/larpix_tasks/ -incr "../../larpix_v2c/testbench/mcp/mcp_analog.v"
vlog +incdir+../../larpix_v2c/testbench/larpix_tasks/ -vopt -incr "../../larpix_v2c/testbench/mcp/mcp_external_interface.sv"
vlog +incdir+../../larpix_v2c/testbench/larpix_tasks/ -vopt -incr "../../larpix_v2c/testbench/mcp/mcp_larpix_single.sv"
vlog +incdir+../../larpix_v2c/testbench/larpix_tasks/ -vopt -incr "../../larpix_v2c/testbench/mcp/mcp_larpix_hydra.sv"
vlog +incdir+../../larpix_v2c/testbench/larpix_tasks/ -vopt -incr "../../larpix_v2c/testbench/mcp/mcp.sv"
#vlog -incr "../../larpix_v2c/testbench/mcp/mcp_regmap.v"
