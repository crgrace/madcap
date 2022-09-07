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
#vlog -L rf2p_512x64_4_50 -L tsmc_cl018g_rvt_neg -L tsmc18_cg_neg "/home/lxusers/c/crgrace/verilog/lightpix/par/digital_core.output.v"
#vlog -L rf2p_512x64_4_50 -L tsmc_cl018g_rvt_neg -L tsmc18_cg_neg "/home/lxusers/c/crgrace/verilog/lightpix/par/postCTS.v"
#vlog -L rf2p_512x64_4_50 -L tsmc_cl018g_rvt_neg -L tsmc18_cg_neg "/home/lxusers/c/crgrace/verilog/lightpix/par/route.v"
vlog -L rf2p_512x64_4_50 -L tsmc_cl018g_rvt_neg -L tsmc18_cg_neg "/home/lxusers/c/crgrace/verilog/larpix_v2b/par/digital_core.signoff.v"


#
# Testbenches
#
vlog -incr -sv "../src/tff.sv"
vlog -incr -sv "../src/clk_manager.sv"
vlog -incr -sv "../src/uart_rx.sv" 
vlog -incr -sv "../src/uart_tx.sv" 

#
vlog -incr -sv "../testbench/unit_tests/fifo_tb.sv" 
vlog -incr -sv "../testbench/unit_tests/fifo_burst_tb.sv" 
vlog -incr -sv "../testbench/unit_tests/rf_2p_64x22_tb.sv" 
vlog -incr -sv "../testbench/unit_tests/uart_tb.sv" 
#vlog -incr "../testbench/unit_tests/event_builder_tb.v" 
#vlog -incr "../testbench/unit_tests/comms_ctrl_tb.v" 
#vlog -incr "../testbench/unit_tests/sar_ctrl_tb.v" 
#vlog -incr "../testbench/unit_tests/sar_ctrl_rev1_tb.v" 
vlog +incdir+../testbench/larpix_tasks/ -incr -sv "../testbench/unit_tests/channel_ctrl_tb.sv" 
vlog -incr -sv "../testbench/unit_tests/timers_tb.sv" 
#vlog -incr -sv "../testbench/unit_tests/channel_ctrl_wip_tb.sv" 
vlog -incr "../testbench/unit_tests/external_interface_tb.sv" 
#vlog -incr "../testbench/unit_tests/analog_core_tb.v" 
#vlog -incr "../testbench/digital_core_tb.v" 
vlog +incdir+../testbench/larpix_tasks/ -incr -sv "../testbench/unit_tests/larpix_single_tb.sv" 
vlog +incdir+../testbench/larpix_tasks/ -incr -sv "../testbench/unit_tests/larpix_hydra_tb.sv" 

#
# analog behavioral models
#
vlog -incr -sv "../testbench/analog_core/sar_adc_core.sv" 
vlog -incr -sv "../testbench/analog_core/discriminator.sv" 
vlog -incr -sv "../testbench/analog_core/csa.sv" 
vlog -incr -sv "../testbench/analog_core/analog_channel.sv" 
vlog -incr -sv "../testbench/analog_core/analog_core.sv" 

#
# full chip model
#
vlog -incr -sv "../testbench/larpix_v2b/larpix_v2b.sv" 

#
# MCP
#

#vlog +incdir+../testbench/larpix_tasks/ -incr "../testbench/mcp/mcp_spi.v"
#vlog +incdir+../testbench/larpix_tasks/ -incr "../testbench/mcp/mcp_regmap.v"
#vlog +incdir+../testbench/larpix_tasks/ -incr "../testbench/mcp/mcp_analog.v"
#vlog +incdir+../testbench/larpix_tasks/ -incr "../testbench/mcp/mcp_external_interface.sv"
vlog +incdir+../testbench/larpix_tasks/ -incr "../testbench/mcp/mcp_larpix_single.sv"
#vlog +incdir+../testbench/larpix_tasks/ -incr "../testbench/mcp/mcp_larpix_hydra.sv"
