 ///////////////////////////////////////////////////////////////////
// File Name: larpix_v2c_madcap_tb.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Combo LArPix_v2c / MADCAP simulation
//              Mainly to verify v3 mode (RX clk = TX clk)
//
///////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "../testbench/tasks/k_codes.sv"
`include "../testbench/tasks/madcap_tasks_top.sv"
//`include "../testbench/tasks/madcap_tests.sv"

module larpix_v2c_madcap_tb();

localparam WIDTH = 10;
localparam REGNUM = 35;
localparam FIFO_DEPTH = 32;
localparam NUMTRIALS = 20;
localparam NUMCHANNELS = 16;
localparam NUMCOMMAS = 20;

// common signals

logic reset_n;
logic clk_fast;     // 80 MHz input clock
logic [1:0] kill_your_neighbor; // disable neighboring chips

// signals to analog core
logic [3:0] clk_larpix;      // clocks to LArPix tiles
logic [3:0] reset_n_larpix;      // reset to LArPix tiles
logic [3:0] trigger_larpix;  // triggers to LArPix tiles

// LArPix to MADCAP datapath
logic [63:0] tx_data [NUMCHANNELS-1:0]; // data sent (pre serializer)
logic [119:0] dataword_120b; // deserialized data (before 8b10 decoding)
logic [95:0] dataword_96b;   // deserialized data (after 8b10 decoding)
logic [95:0] superpacket;   // final packet ready for analysis
logic [11:0] k_out;
logic [11:0] code_err;
logic [11:0] disp_err;
logic dout; // DDR output
logic dout_frame;
logic new_dataword; // high to indicate new dataword available
logic [3:0] piso;
logic [NUMCHANNELS-1:0] posi;
logic [NUMCHANNELS-1:0] ld_tx_data; // high to xfer data to UART
logic simulation_done;          // high when simulation done
logic [NUMCHANNELS-1:0] tx_busy;  // not used yet
logic clk_tx;
logic clk_larpix_delayed;   // models LArPix primary clock
logic which_fifo;
logic [1:0] physical_chip_id;

//larpix specific
logic external_trigger_larpix;
real charge_in_r[63:0];
real monitor_out_r;

initial begin

    physical_chip_id = 2'b01;
    external_trigger_larpix = 0;
    for (int i = 0; i < 64; i++) begin
        charge_in_r[i] = 0.0;
    end
//    for (int i = 4; i < 15; i++) begin
//        piso[i] = 1;
//    end


end // initial

// primary clock
initial begin
    forever begin   
        #10 clk_fast = ~clk_fast;
    end
end // initial

assign #1 clk_larpix_delayed = clk_larpix[0];


// INCLUDE PACMAN MODEL
`include "../testbench/sim_models/pacman_model.sv"

// INCLUDE PACMAN ANALYSIS
`include "../testbench/sim_models/pacman_analysis.sv"

// RUN SIMULATION SCRIPTS
initial begin
`include "../mcp/setup_sim.mcp"
//`include "../mcp/madcap_config_rw.mcp"
`include "../mcp/larpix_config_rw.mcp"
//`include "../mcp/sync_start.mcp"
//`include "../mcp/test_datapath.mcp"
//`include "../mcp/madcap_testmodes.mcp"
//`include "../mcp/chipid_test.mcp"
//`include "../mcp/test_config_panic.mcp"
//`include "../mcp/larpix_hit.mcp"
//`include "../mcp/lp_mc_v3.mcp"

end // include

// END SIMULATION SCRIPTS

// LARPIX MODEL
// single LArPix
// DUT (LArPix full-chip model) LArPix is connected to MADCAP
larpix_v2c
    larpix_v2c_inst (
    .piso               (piso[3:0]),
    .digital_monitor    (digital_monitor),
    .monitor_out_r      (monitor_out_r),
    .charge_in_r        (charge_in_r),
    .external_trigger   (external_trigger_larpix),
    .posi               (posi[3:0]),
    .clk                (clk_larpix[0]),
    .reset_n            (reset_n_larpix[0])   
    );
// END LARPIX MODEL

// this module sets the relationship between core, rx, and tx clock
// simulates clock manager on LArPix
clk_manager
    clk_manager_inst (
    .clk_core       (),
    .clk_rx         (),
    .clk_tx         (clk_tx),
    .clk_ctrl       (2'b00),
    .clk            (clk_larpix_delayed),
    .reset_n        (reset_n)
    );

// MADCAP
madcap
    #(.NUMCHANNELS(NUMCHANNELS),
    .REGNUM(REGNUM),
    .FIFO_DEPTH(FIFO_DEPTH))
    madcap_inst (
    .dout                   (dout),
    .dout_frame             (dout_frame),
    .posi                   (posi),
    .clk_larpix             (clk_larpix),
    .reset_n_larpix         (reset_n_larpix),
    .trigger_larpix         (trigger_larpix),
    .kill_your_neighbor     (kill_your_neighbor),
    .piso                   ({1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1, piso[3],piso[2],piso[1],piso[0]}),
    .lvds_rx_bit            (dout_pacman),
    .external_trigger       (external_trigger),
    .reset_n_lp             (reset_n_lp),
    .sync_in                (symbol_start),
    .clk_fast               (clk_fast),
    .chip_id                (physical_chip_id),
    .reset_n                (reset_n)
    );
// END MADCAP
endmodule 
