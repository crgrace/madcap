// File Name: madcap.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Full-chip behavioral model for MADCAP.  
//              Uses production synthesziable RTL.
//              Uses real-value modeling analog circuits.
//
///////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module madcap
    #(parameter FIFO_DEPTH = 32,
    parameter REGNUM = 35,
    parameter NUMCHANNELS = 16)
    (output logic dout,                 // high-speed output to PACMAN
    output logic dout_frame,            // high when LSB output
    output logic [15:0] posi,           // config data to LArPix tiles
    output logic [3:0] clk_larpix,      // clocks to LArPix tiles
    output logic [3:0] reset_n_larpix,  // reset_n to LArPix tiles
    output logic [3:0] trigger_larpix,  // triggers to LArPix tiles
    output logic [1:0] kill_your_neighbor, // disable neighboring chips
    input logic piso [NUMCHANNELS-1:0], // input bits from PHYs
    input logic lvds_rx_bit,            // serial bits from RX (PACMAN)
    input logic external_trigger,       // high for external trigger 
    input logic reset_n_lp,             // reset to send to LArPix
    input logic sync_in,                // sync_pulse (high on first bit)
    input logic clk_fast,               // externally supplied clk
    input logic [1:0] chip_id,          // id for MADCAP
    input logic reset_n);               // digital reset  (active low)

// fast digital internal signals
logic dout_even;                // DDR even bits                 
logic dout_odd;                 // DDR odd bits  
     
// signals to analog core
logic [4:0] ref_current_trim;   // trims ref current
logic override_ref;             // high to enable external bandgap
logic ref_kickstart;            // active high kickstart bit
logic [3:0] current_monitor;    // one hot monitor (see docs)
logic [7:0] voltage_monitor_refgen;  // one hot monitor 
logic [3:0] tx_slices;          // # of TX slices for POSI link
logic [3:0] i_tx_diff;          // TX bias current (diff)
logic [3:0] i_rx;               // RX bias current 
logic [4:0] rx_term;            // RX termination resistor
logic [2:0] v_cm_tx;            // TX CM (MADCAP to tile)
logic [3:0] i_tx_lvds_data;     // link from MADCAP to PACMAN
logic [3:0] i_lvds_rx;          // link from PACMAN to MADCAP
logic [3:0] i_cml_rst;          // bias current for rst drivers
logic [3:0] i_cml_clk;          // bias current for clk drivers
logic [3:0] i_cml_trigger;      // bias current for trigger drivers
logic pd_lvds_tx;               // pd LVDS from MADCAP to PACMAN
logic [3:0] pd_reset_n_drivers; // pd rst drivers to LArPix tile
logic [3:0] pd_clk_drivers;     // pd clk drivers to LArPix tile
logic [3:0] pd_trigger_drivers; // pd trigger to LArPix tile
logic [15:0] pd_rx;             // pd rx from LArPix to MADCAP
logic [15:0] pd_tx;             // pd rx from MADCAP to LArPix
logic [7:0] spare;              // spare control bits


// START output mux
output_mux  
    output_mux_inst (
    .dout       (dout),
    .dout_even  (dout_even),
    .dout_odd   (dout_odd),
    .clk        (clk_fast)
    );
// END output mux

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
    .lvds_rx_bit            (lvds_rx_bit),
    .external_trigger       (external_trigger),
    .reset_n_lp             (reset_n_lp),
    .sync_in                (sync_in),
    .clk_fast               (clk_fast),
    .chip_id                (chip_id),
    .reset_n                (reset_n)
    );

endmodule 
