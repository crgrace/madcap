 ///////////////////////////////////////////////////////////////////
// File Name: digital_core_mc_tb.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: SystemVerilog testbench for MADCAP digital core.
//
// Note: many signals defined in pacman_model.sv (instantiated in tb)
//
///////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "../testbench/tasks/k_codes.sv"
`include "../testbench/tasks/madcap_tasks_top.sv"
module digital_core_mc_tb();

localparam WIDTH = 10;
localparam REGNUM = 35;
localparam FIFO_DEPTH = 32;
localparam NUMTRIALS = 20;
localparam NUMCHANNELS = 16;
localparam NUMCOMMAS = 20;

// common signals

logic reset_n;
logic clk_fast;     // 80 MHz input clock

// signals to analog core
logic [3:0] clk_larpix;      // clocks to LArPix tiles
logic [3:0] reset_n_larpix;      // reset to LArPix tiles
logic [3:0] trigger_larpix;  // triggers to LArPix tiles
logic [4:0] ref_current_trim;// trims ref current
logic override_ref;          // high to enable external bandgap
logic ref_kickstart;         // active high kickstart bit
logic [3:0] current_monitor; // one hot monitor (see docs)
logic [7:0] voltage_monitor_refgen;  // one hot monitor 
logic [3:0] tx_slices;       // # of TX slices for POSI link
logic [3:0] i_tx_diff;       // TX bias current (diff)
logic [3:0] i_rx;            // RX bias current 
logic [4:0] rx_term;         // RX termination resistor
logic [2:0] v_cm_tx;         // TX CM (MADCAP to tile)
logic [3:0] i_tx_lvds_data;  // link from MADCAP to PACMAN
logic [3:0] i_lvds_rx;       // link from PACMAN to MADCAP
logic [3:0] i_cml_rst;       // bias current for rst drivers
logic [3:0] i_cml_clk;       // bias current for clk drivers
logic [3:0] i_cml_trigger;   // bias current for trigger drivers
logic pd_lvds_tx;            // pd LVDS from MADCAP to PACMAN
logic [3:0] pd_reset_n_drivers;  // pd rst drivers to LArPix tile
logic [3:0] pd_clk_drivers;  // pd clk drivers to LArPix tile
logic [3:0] pd_trigger_drivers;// pd trigger to LArPix tile
logic [15:0] pd_rx;          // pd rx from LArPix to MADCAP
logic [15:0] pd_tx;          // pd rx from MADCAP to LArPix
logic [1:0] kill_your_neighbor; // disable neighboring chips
logic [7:0] spare;           // spare control bits

// LArPix to MADCAP datapath
logic [63:0] tx_data [NUMCHANNELS-1:0]; // data sent (pre serializer)
logic [119:0] dataword_120b; // deserialized data (before 8b10 decoding)
logic [95:0] dataword_96b;   // deserialized data (after 8b10 decoding)
logic [95:0] superpacket;   // final packet ready for analysis
logic [11:0] k_out;
logic [11:0] code_err;
logic [11:0] disp_err;
logic dout_even;
logic dout_odd;
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
logic [1:0] chip_id;

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
//`include "../mcp/setup_sim.mcp"
//`include "../mcp/madcap_config_rw.mcp"
//`include "../mcp/test_datapath.mcp"
end // initial

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
    .clk_tx         (clk_tx),
    .reset_n        (reset_n)
    );

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

// END tile model


// START output mux
output_mux  
    output_mux_inst (
    .dout       (dout),
    .dout_even  (dout_even),
    .dout_odd   (dout_odd),
    .clk        (clk_fast)
    );
// END output mux


// END DATAPATH model

// DUT connected here   
digital_core_mc
    #(.NUMCHANNELS(NUMCHANNELS),
    .REGNUM(REGNUM),
    .FIFO_DEPTH(FIFO_DEPTH))
    digital_core_mc_inst (
    .dout_even              (dout_even),
    .dout_odd               (dout_odd),
    .dout_frame             (dout_frame),
    .posi                   (posi),
    .clk_larpix             (clk_larpix),
    .reset_n_larpix         (reset_n_larpix),
    .trigger_larpix         (trigger_larpix),
    .ref_current_trim       (ref_current_trim),
    .override_ref           (override_ref),
    .ref_kickstart          (ref_kickstart),
    .current_monitor        (current_monitor),
    .voltage_monitor_refgen (voltage_monitor_refgen),
    .tx_slices              (tx_slices),
    .i_tx_diff              (i_tx_diff),
    .i_rx                   (i_rx),
    .rx_term                (rx_term),
    .v_cm_tx                (v_cm_tx),
    .i_tx_lvds_data         (i_tx_lvds_data),
    .i_lvds_rx              (i_lvds_rx),
    .i_cml_rst              (i_cml_rst),
    .i_cml_clk              (i_cml_clk),
    .i_cml_trigger          (i_cml_trigger),
    .pd_lvds_tx             (pd_lvds_tx),
    .pd_reset_n_drivers     (pd_reset_n_drivers),
    .pd_clk_drivers         (pd_clk_drivers),
    .pd_trigger_drivers     (pd_trigger_drivers),
    .pd_rx                  (pd_rx),
    .pd_tx                  (pd_tx),
    .kill_your_neighbor     (kill_your_neighbor),
    .spare                  (spare),
    .piso                   (piso),
    .lvds_rx_bit            (dout_pacman),
    .external_trigger       (external_trigger),
    .reset_n_lp             (reset_n_lp),
    .sync_in                (symbol_start),
    .clk_fast               (clk_fast),
    .chip_id                (mc_chip_id),
    .reset_n                (reset_n)
    );

endmodule 
