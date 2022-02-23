 ///////////////////////////////////////////////////////////////////
// File Name: madcap_tb.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: SystemVerilog testbench for MADCAP full-chip model.
///////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "../testbench/tasks/k_codes.sv"
`include "../testbench/tasks/madcap_tasks_top.sv"
module madcap_tb();

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
logic [NUMCHANNELS-1:0] piso;
logic [NUMCHANNELS-1:0] posi;
logic [NUMCHANNELS-1:0] ld_tx_data; // high to xfer data to UART
logic simulation_done;          // high when simulation done
logic [NUMCHANNELS-1:0] tx_busy;  // not used yet
logic clk_tx;
logic clk_larpix_delayed;   // models LArPix primary clock
logic which_fifo;
logic bypass_8b10b_extern; // high for bypass
logic v3_mode;          // 0 = v2 mode, 1 = v3 mode

// primary clock
initial begin
    forever begin   
        #10 clk_fast = ~clk_fast;
    end
end // initial

assign #1 clk_larpix_delayed = clk_larpix[0];

initial begin
    v3_mode = 0;
end

// INCLUDE PACMAN MODEL
`include "../testbench/sim_models/pacman_model.sv"

// INCLUDE PACMAN ANALYSIS
`include "../testbench/sim_models/pacman_analysis.sv"

// RUN SIMULATION SCRIPTS
initial begin
`include "../mcp/setup_sim.mcp"
//`include "../mcp/bypass_8b10b_enc.mcp"
//`include "../mcp/bypass_8b10b_dec_extern.mcp"
`include "../mcp/madcap_config_rw.mcp"
//`include "../mcp/test_datapath.mcp"
//`include "../mcp/fifo_panic_datapath.mcp"
//`include "../mcp/v3_test.mcp"
`include "../mcp/magic_comma_test.mcp"

end // initial
// END SIMULATION SCRIPTS


//// START DATAPATH MODEL
/// START tile model:
uart_array_tx
    #(.WIDTH(64),
    .NUMCHANNELS(NUMCHANNELS)
    )
    uart_array_tx_inst (
    .tx_out         (piso),
    .tx_busy        (tx_busy),
    .tx_data        (tx_data),
    .ld_tx_data     (ld_tx_data),
    .tx_enable      (tx_enable),
    .clk_tx         (clk_tx),  // v2 mode
//    .clk_tx         (clk_larpix_delay), // v3 mode
    .reset_n        (reset_n)
    );

// this module sets the relationship between core, rx, and tx clock
// simulates clock manager on LArPix
// to emulate LArPix clk manager, set v3_mode to 0;

clk_manager_lp
    clk_manager_lp_inst (
    .clk_core       (),
    .clk_rx         (),
    .clk_tx         (clk_tx),
    .v3_mode        (v3_mode),
    .clk_ctrl       (2'b00),
    .clk            (clk_larpix_delayed),
    .reset_n        (reset_n)
    );

// END tile model

// END DATAPATH model

// DUT connected here   
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
    .piso                   (piso),
    .lvds_rx_bit            (dout_pacman),
    .external_trigger       (external_trigger),
    .reset_n_lp             (reset_n_lp),
    .sync_in                (symbol_start),
    .clk_fast               (clk_fast),
    .bypass_8b10b_extern    (bypass_8b10b_extern),
    .chip_id                (mc_chip_id),
    .reset_n                (reset_n)
    );

endmodule 
