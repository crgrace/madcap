///////////////////////////////////////////////////////////////////
// File Name: config_path.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Datapath from LVDS RX input to 16 POSI TX outputs
//
//   Contains:
//      LVDS RX block (80 MHz)
//      8b/10b decoder
//      Comma detect
//      Config Packet Builder 
//      Register File
//      Config FIFO (32 words deep, 64b wide)
//      16 POSI TX UARTs
//    
///////////////////////////////////////////////////////////////////

module config_path
    #(parameter NUMCHANNELS = 16,
    parameter REGNUM = 16,
    parameter FIFO_DEPTH = 32)
    (output logic posi [NUMCHANNELS-1:0],// output bits to PHYs
    output logic [63:0] larpix_packet,  // config read for MADCAP 
    output logic [7:0] config_bits [0:REGNUM-1],// regmap config bits    
    output logic [4:0] config_fifo_cnt, // FIFO usage when FIFO read
    output logic config_fifo_half,      // high if config fifo half full 
    output logic config_fifo_full,      // high if config fifo full  
    output logic write_fifo_data_req,   // req to put data into data FIFO
    output logic lp_trigger_out,        // generate LArPix trigger
    output logic lp_rst_out,            // alternative LArPix reset
    output logic mc_rst_out,            // alternative MADCAP reset
// DEBUG OUTPUTS
    output logic symbol_locked,         // deserializer synchronized
    output logic comma_found,           // high when comma (K28.5) found
    output logic lp_trigger_found,      // LP trigger comma detected
    output logic lp_soft_rst_found,     // high if K28.4 (K_Q) found
    output logic lp_hard_rst_found,     // high if K27.7 (K_S) found
    output logic lp_timestamp_rst_found,// high if K28.3 (K_A) found
    output logic mc_rst_found,          // high if K28.7 (K_T) found    
// INPUTS
    input logic input_bit,              // serial bits from LVDS RX
    input logic [15:0] tx_enable,       // high to enable TX channel
    input logic [1:0] chip_id,          // id for current MADCAP 
    input logic start_sync,             // start sync (also starts on rst)
    input logic sync_in,                // sync_pulse (high on first bit)
    input logic load_config_defaults,   // high for soft reset
    input logic ack_fifo_data,          // acknowledge from data FIFO
    input logic bypass_8b10b_dec,       // high to bypass 8b10b decoders
    input logic clk_tx,                 // 5 MHz tx clk
    input logic clk,                    // MADCAP primary clk
    input logic reset_n_config,         // restore config map to default
    input logic reset_n);               // digital reset (active low)

logic [5:0] fifo_counter;               // 6b fifo counter
logic [9:0] dataword10b;                // 10b symbol from LVDS RX PHY
logic [7:0] dataword8b;                 // 8b decoded symbol 
logic [7:0] dataword8b_muxed;           // symbol after bypass mux 
logic [63:0] tx_data [NUMCHANNELS-1:0]; // data to be sent 
logic k_out;                            // high if k-code detected
logic dataword10b_ready;                // data ready to sample
logic [7:0] regmap_write_data;          // data to write to regmap
logic [7:0] regmap_address;             // regmap addr to write
logic write_regmap;                     // active high to load register data
logic read_regmap;                      // active high to read register data
logic [63:0] config_fifo_out;           // output of config fifo
logic write_fifo_config_n;              // low to put data into config FIFO
logic [7:0] regmap_read_data;           // data to read from regmap
logic [15:0] ld_tx_data;                // high to transfer data to UART TX
logic [15:0] tx_busy;                   // high when tx uart sending data

// internal 8b10 decoder signals
logic disp_in;
logic disp_out;
logic code_err;
logic disp_err;

// sample disparity for 8b10b decoder
always_ff @(posedge clk or negedge reset_n)
  if (!reset_n)
    disp_in <= 1'b0; // initialize disparity
  else
    disp_in <= disp_out;
 
// convert fifo counter to fifo usage
always_comb 
    config_fifo_cnt = fifo_counter - 1'b1;

// 8b10b decoder bypass mux
always_comb begin
    if (bypass_8b10b_dec) begin  
        dataword8b_muxed = dataword10b[7:0];
    end 
    else begin
        dataword8b_muxed = dataword8b;
    end
end // always_comb

// module declarations
deserializer_sdr
    deserializer_sdr_inst (
    .dataword10b            (dataword10b),
    .dataword10b_ready      (dataword10b_ready),
    .din                    (input_bit),
    .symbol_start           (symbol_start),
    .clk                    (clk),
    .reset_n                (reset_n)
    );

comma_detect
    comma_detect_inst (
    .symbol_start           (symbol_start),
    .symbol_locked          (symbol_locked),
    .comma_found            (comma_found),
    .lp_trigger_found       (lp_trigger_found),
    .lp_soft_rst_found      (lp_soft_rst_found),
    .lp_hard_rst_found      (lp_hard_rst_found),
    .lp_timestamp_rst_found (lp_timestamp_rst_found),
    .mc_rst_found           (mc_rst_found),
    .dataword10b            (dataword10b),
    .dataword10b_ready      (dataword10b_ready),
    .start_sync             (start_sync),
    .sync_in                (sync_in),
    .clk                    (clk),
    .reset_n                (reset_n)
    );

reset_ctrl
    reset_ctrl_inst (
    .lp_rst_out             (lp_rst_out),
    .mc_rst_out             (mc_rst_out),
    .lp_trigger_out         (lp_trigger_out),
    .lp_trigger_found       (lp_trigger_found),
    .lp_soft_rst_found      (lp_soft_rst_found),
    .lp_hard_rst_found      (lp_hard_rst_found),
    .lp_timestamp_rst_found (lp_timestamp_rst_found),
    .mc_rst_found           (mc_rst_found),
    .clk                    (clk),
    .reset_n                (reset_n)
    );

decode8b10b    
    decode8b10b_inst (
    .datain                 (dataword10b),
    .dataout                ({k_out,dataword8b}),
    .dispin                 (disp_in),
    .dispout                (disp_out),
    .code_err               (code_err),
    .disp_err               (disp_err)
    ); 

config_packet_builder   
    config_packet_builder_inst (
    .larpix_packet          (larpix_packet),
    .regmap_write_data      (regmap_write_data),
    .regmap_address         (regmap_address),
    .write_regmap           (write_regmap),
    .read_regmap            (read_regmap),
    .write_fifo_config_n    (write_fifo_config_n),
    .write_fifo_data_req    (write_fifo_data_req),
    .dataword8b             (dataword8b_muxed),
    .dataword8b_ready       (dataword10b_ready),
    .regmap_read_data       (regmap_read_data),
    .chip_id                (chip_id),
    .ack_fifo_data          (ack_fifo_data),
    .comma_found            (comma_found),
    .clk                    (clk),
    .reset_n                (reset_n)
    );

// register map
config_regfile_mc
    #(.REGNUM(REGNUM)
     ) config_regfile_mc_inst (
    .config_bits            (config_bits),
    .read_data              (regmap_read_data),
    .write_addr             (regmap_address), 
    .write_data             (regmap_write_data),
    .read_addr              (regmap_address),
    .write                  (write_regmap),
    .read                   (read_regmap),
    .load_config_defaults   (load_config_defaults),
    .clk                    (clk),
    .reset_n                (reset_n_config)
    );

fifo_ff_mc
    #(.FIFO_WIDTH(64),
    .FIFO_DEPTH(FIFO_DEPTH)
    )
    fifo_ff_inst (
    .data_out               (config_fifo_out),
    .fifo_counter           (fifo_counter),
    .fifo_full              (config_fifo_full),
    .fifo_half              (config_fifo_half),
    .fifo_empty             (config_fifo_empty),
    .data_in                (larpix_packet),
    .read_n                 (read_fifo_n),
    .write_n                (write_fifo_config_n),
    .reset_n                (reset_n)
    );

tx_router            
    tx_router_inst (
    .tx_data                (tx_data),
    .read_fifo_n            (read_fifo_n),
    .fifo_out               (config_fifo_out),
    .ld_tx_data             (ld_tx_data),
    .tx_busy                (tx_busy),
    .target_larpix          (config_fifo_out[29:26]),
    .broadcast              (config_fifo_out[30]),
    .fifo_empty             (config_fifo_empty),
    .write_fifo_n           (write_fifo_config_n),
    .clk                    (clk),
    .reset_n                (reset_n)
    );

uart_array_tx
    uart_array_tx_inst (
    .tx_out                 (posi),
    .tx_busy                (tx_busy),
    .tx_data                (tx_data),
    .ld_tx_data             (ld_tx_data),
    .tx_enable              (tx_enable),
    .clk_tx                 (clk_tx),   // 5 MHz UART TX clock
    .reset_n                (reset_n)
    );

endmodule



