///////////////////////////////////////////////////////////////////
// File Name: digital_core_mc.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: MADCAP synthesized digital core.  
//
//
//
// Contains: 
//      16 RX UARTS
//      16 TX UARTS
//      Event Router
//      32 deep 68-bit FIFO
//      CRC8 calculation (uses Maxim 1-wire polynomial x^8 + x^5 + x^4 + 1)
//      Packet Builder (makes 12-byte superpackets (data or idle) )
//      8b/10b encoder
//      Serializer (sends odd and even bit streams for later DDR mux)
//      8b/10 decoder
//      Comma detect for auto-sync
//      32 deep by 64b configuration (upstream) FIFO
//
///////////////////////////////////////////////////////////////////

module digital_core_mc
    #(parameter WIDTH = 64,
    parameter REGNUM = 34,
    parameter NUMCHANNELS = 16,
    parameter FIFO_DEPTH = 32)
    (output logic dout_even,            // DDR even bits                 
    output logic dout_odd,              // DDR odd bits                 
    output logic dout_frame,            // high when LSB output
    output logic [3:0] clk_larpix,      // clocks to LArPix tiles
    output logic [3:0] rst_larpix,      // reset to LArPix tiles

// ANALOG CORE CONFIGURATION SIGNALS
// these are in the same order as the MADCAP config bits google sheet

    output logic [4:0] ref_current_trim,// trims ref current
    output logic override_ref,          // high to enable external bandgap
    output logic ref_kickstart,         // active high kickstart bit
    output logic [3:0] current_monitor, // one hot monitor (see docs)
    output logic [7:0] voltage_monitor_refgen,  // one hot monitor 
    output logic [3:0] tx_slices,       // # of TX slices for POSI link
    output logic [3:0] i_tx_diff,       // TX bias current (diff)
    output logic [3:0] i_rx,            // RX bias current 
    output logic [4:0] rx_term,         // RX termination resistor
    output logic [2:0] v_cm_tx,         // TX CM (MADCAP to tile)
    output logic [3:0] i_tx_lvds_data,  // link from MADCAP to PACMAN
    output logic [3:0] i_lvds_rx,       // link from PACMAN to MADCAP
    output logic [3:0] i_cml_rst,       // bias current for rst drivers
    output logic [3:0] i_cml_clk,       // bias current for clk drivers
    output logic pd_lvds_tx,            // pd LVDS from MADCAP to PACMAN
    output logic [3:0] pd_rst_drivers,  // pd rst drivers to LArPix tile
    output logic [3:0] pd_clk_drivers,  // pd clk drivers to LArPix tile
    output logic [15:0] pd_rx,          // pd rx from LArPix to MADCAP
    output logic [15:0] pd_tx,          // pd rx from MADCAP to LArPix

// INPUTS
    input logic piso [NUMCHANNELS-1:0], // input bits from PHYs
    input logic lvds_rx_bit,            // serial bits from RX (PACMAN)
    input logic external_sync,          // high for external sync 
    input logic start_sync,             // start sync (also starts on rst)  
    input logic clk_fast,               // externally supplied clk
    input logic reset_n);               // digital reset  (active low)

// digital config & local variables
logic [7:0] config_bits [0:REGNUM-1];// regmap config bits    
logic digital_monitor_enable;       // high to enable
logic [3:0] digital_monitor_select; // see docs
logic [4:0] chip_id;                // unique ID for each chip
logic load_config_defaults;         // MADCAP soft reset (set to low after)
logic bypass_8b10b_enc;             // high to bypass 8b10b encoder
logic bypass_8b10b_dec;             // high to bypass 8b10b decoder
logic [2:0] test_mode;              // datapath test modes
logic write_fifo_data_req;          // req to put data into FIFO
logic ack_fifo_data;                // high to ack config write to FIFO
logic which_fifo;                   // selects which fifo diagnositics sent
logic [1:0] enable_fifo_panic;      // embed FIFO diagnostics in stream
logic config_fifo_half;             // high if config fifo half full 
logic config_fifo_full;             // high if config fifo full  
logic [4:0] config_fifo_cnt;        // FIFO usage when FIFO read
logic [95:0] test_packet;           // user-defined test data
logic serializer_enable;            // enable serializer (MADCAP to PACMAN)
logic v3_mode;                      // puts UARTs in v3 mode 
logic [15:0] tx_enable;             // per-channel TX enable
logic lvds_loopback;                // high to enable loopback
logic lvds_prbs;                    // send PRBS7 through TX LVDS
logic clk_core;     // MADCAP core clock (80 MHz nomimal)
logic clk_rx;       // 2x oversampling rx clock (10 MHz nominal)
logic clk_tx;       // slow tx clock (5 MHz nominal)
logic [67:0] madcap_packet;         // return config data via data FIFO
logic write_fifo_data_n;            // low to put MADCAP packet to FIFO  


`include "madcap_constants.sv"
// need to use generates for large config words
// Cadence can't handle two dimensional ports

genvar g_i;
generate 
    for (g_i = 0; g_i < 12; g_i++) begin
        assign test_packet[g_i*8+7:g_i*8]
            = config_bits[TEST_PACKETS+g_i][7:0];
    end // for
endgenerate


// ------- Config registers to MADCAP

always_comb begin
    ref_current_trim        = config_bits[REFGEN][4:0];
    override_ref            = config_bits[REFGEN][5];
    ref_kickstart           = config_bits[REFGEN][6];
    current_monitor         = config_bits[IMONITOR][3:0];
    voltage_monitor_refgen  = config_bits[VMONITOR][7:0];
    digital_monitor_enable  = config_bits[DMONITOR][0];
    digital_monitor_select  = config_bits[DMONITOR][4:1];
    chip_id                 = config_bits[CHIP_ID][4:0];
    load_config_defaults    = config_bits[CHIP_ID][5];
    bypass_8b10b_enc        = config_bits[CHIP_ID][6];
    bypass_8b10b_dec        = config_bits[CHIP_ID][7];
    test_mode               = config_bits[TEST_MODE][2:0];
    which_fifo              = config_bits[TEST_MODE][3];
    enable_fifo_panic       = config_bits[TEST_MODE][5:4];
    serializer_enable       = config_bits[SERIALIZER][0];
    v3_mode                 = config_bits[SERIALIZER][1];
    tx_enable[7:0]          = config_bits[TX_ENABLE][7:0];                
    tx_enable[15:8]         = config_bits[TX_ENABLE+1][7:0];
    tx_slices               = config_bits[TRX0][3:0];
    i_tx_diff               = config_bits[TRX0][7:4];                
    i_rx                    = config_bits[TRX1][3:0];
    rx_term                 = config_bits[TRX2][4:0];
    v_cm_tx                 = config_bits[TRX3][2:0];
    i_tx_lvds_data          = config_bits[TRX4][3:0];
    i_cml_rst               = config_bits[TRX5][3:0];
    i_cml_clk               = config_bits[TRX5][7:4];
    lvds_loopback           = config_bits[TRX6][0];
    lvds_prbs               = config_bits[TRX6][1];
    pd_lvds_tx              = config_bits[PD_LVDS][0];
    pd_rst_drivers          = config_bits[PD_DRIVER][3:0];
    pd_clk_drivers          = config_bits[PD_DRIVER][7:4];
    pd_rx[7:0]              = config_bits[PD_RX][7:0];
    pd_rx[15:8]             = config_bits[PD_RX+1][7:0];
    pd_tx[7:0]              = config_bits[PD_TX][7:0];
    pd_tx[15:8]             = config_bits[PD_TX+1][7:0];
end // always_comb

// instantiate sub-blocks

datapath
    #(.WIDTH(WIDTH))
    datapath_inst (
    .dout_even              (dout_even),
    .dout_odd               (dout_odd),
    .dout_frame             (dout_frame),
    .piso                   (piso),
    .write_fifo_data_req    (write_fifo_data_req),
    .config_fifo_cnt        (config_fifo_cnt),
    .config_fifo_half       (config_fifo_half),
    .config_fifo_full       (config_fifo_full),
    .which_fifo             (which_fifo),
    .enable_fifo_panic      (enable_fifo_panic),
    .test_mode              (test_mode),
    .test_packet            (test_packet),
    .crc_input              (crc_input),
    .chip_id                (chip_id), 
    .bypass_8b10b           (bypass_8b10b_enc),
    .serializer_enable      (serializer_enable),
    .clk_core               (clk_core),
    .clk_rx                 (clk_rx),
    .reset_n                (reset_n)
    );

// clock gen
clk_manager_mc
    clk_manager_mc_inst (
    .clk_core               (clk_core),
    .clk_rx                 (clk_rx),
    .clk_tx                 (clk_tx),
    .clk_fast               (clk_fast),
    .reset_n                (reset_n)
    );

config_path
    #(.NUMCHANNELS(NUMCHANNELS),
    .REGNUM(REGNUM),
    .FIFO_DEPTH(FIFO_DEPTH))
    config_path_inst (
    .posi                   (posi),
    .madcap_packet          (madcap_packet),
    .config_bits            (config_bits),
    .config_fifo_cnt        (config_fifo_cnt),
    .config_fifo_half       (config_fifo_half),
    .config_fifo_full       (config_fifo_full),
    .write_fifo_data_n      (write_fifo_data_n),
    .input_bit              (lvds_rx_bit),  
    .tx_enable              (tx_enable),  
    .external_sync          (external_sync),
    .start_sync             (start_sync),
    .load_config_defaults   (load_config_defaults),
    .ack_fifo_data          (ack_fifo_data),
    .bypass_8b10b_dec       (bypass_8b10b_dec),
    .clk_tx                 (clk_tx),
    .clk                    (clk_core),
    .reset_n                (reset_n)
    );

endmodule

