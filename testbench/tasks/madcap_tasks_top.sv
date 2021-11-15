///////////////////////////////////////////////////////////////////
// File Name: madcap_tasks_top.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: LArPix sim and verification tasks  
// tasks used to enable simulation of AFE and digital blocks
// to use include this file:
// ~crgrace/verilog/madcap/testbench/madcap_tasks/madcap_tasks_top.sv
// in testbench
// example invocation : vlog +incdir+madcap_tasks/ src/*.sv 
//  
///////////////////////////////////////////////////////////////////

`ifndef _madcap_tasks_top_
`define _madcap_tasks_top_
// include tests and tasks

`include "madcap_constants.sv"
//`include "spi_tasks.v"
//`include "spi_tests.v"
//`include "uart_tests.sv"
`include "uart_tasks.sv"
//`include "channel_tests.sv"
//`include "regmap_tests.v"
//`include "regmap_tasks.v"
//`include "analog_tasks.sv"

/*`include "adc_tests.v"
`include "pga_tests.v"
`include "common_block_tests.v"
`include "backend_tests.v"
`include "cl_regmap_tests.v"
`include "offset_dac_tests.v"
`include "spi_defaults_tests.v"
`include "jesd204b_tasks.v"
`include "set2default.v"
*/
`endif // _madcap_tasks_top_

