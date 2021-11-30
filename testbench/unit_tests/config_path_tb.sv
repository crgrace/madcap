///////////////////////////////////////////////////////////////////
// File Name: config_path_tb.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Testbench for Datapath from LVDS RX input 
//              to 16 POSI TX outputs
//
//   config_path.sv Contains:
//      LVDS RX block (80 MHz)
//      8b/10b decoder
//      Comma Detect
//      Config Packet Builder 
//      Register File
//      Config FIFO (32 words deep, 64b wide)
//      16 POSI TX UARTs
//      Event Router
//      32 deep 68-bit FIFO
//    
///////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "../testbench/tasks/k_codes.sv"
`include "../testbench/tasks/madcap_tasks_top.sv"

module config_path_tb();

localparam WIDTH = 10;
localparam REGNUM = 16;
localparam FIFO_DEPTH = 32;
localparam NUMTRIALS = 20;
localparam NUMCHANNELS = 16;
localparam NUMCOMMAS = 20;

// signals for config_path
logic posi [NUMCHANNELS-1:0];  // output bits to PHYs
logic [67:0] madcap_packet; // return config data 
logic [7:0] config_bits [0:REGNUM-1];// regmap config bits    
logic [4:0] config_fifo_cnt;  // FIFO usage when FIFO read
logic config_fifo_half;       // high if config fifo half full 
logic config_fifo_full;       // high if config fifo full  
logic write_fifo_data_n;   // low to put data into data FIFO
logic load_config_defaults; // high for soft reset
logic clk_core;             // MADCAP primary clk
logic clk_fast;             // externally supplied clk
logic clk_tx;               // MADCAP UART TX clk
logic clk_rx;               // MADCAP UART RX clk
logic reset_n;              // digital reset (active low)

// internal signals
logic load_serializer;
logic ready_to_load;
logic [15:0] tx_enable;
logic [3:0] serializer_cnt;
logic disp_out;             // 0 = neg disp; 1 = pos disp; not registered
logic disp_in;              // 0 = neg disp; 1 = pos disp
logic [31:0] upstream_packet; // from FPGA to MADCAP
logic dout;                 // serializer output (single bit)
logic [7:0] data_in8b;      // input to send to 8b10b encoder
logic [7:0] current_byte;   // byte selected from upstream pacet
logic [9:0] data_in10b;     // input to test serializer 
logic next_packet;          // high when ready for new packet
logic [1:0] which_byte;     // byte of packet being serialized
logic k_in;                 // high to indicate 8b symbol represents k-code
logic external_sync;        // high for external sync mode
logic start_sync;           // high to mark first bit in symbol
initial begin
    tx_enable = '0;
    clk_fast = 1'b0;
    external_sync = 1'b0;
    start_sync = 1'b0;
    load_config_defaults = 1'b0;
    #10 reset_n = 1'b0;
    #55 reset_n = 1'b1;
end

initial begin
    forever begin   
        #10 clk_fast = ~clk_fast;
    end
end // initial

always_comb
    if (serializer_cnt == 4'b0010)
        ready_to_load = 1'b1;
    else
        ready_to_load = 1'b0;

// load serializer counter
always_ff @(posedge clk_core or negedge reset_n) begin
    if (!reset_n) begin
        serializer_cnt <= '0;
        load_serializer <= 1'b0;
    end
    else begin
        serializer_cnt <= serializer_cnt + 1'b1;
        load_serializer <= 1'b0;
        if (serializer_cnt == 4'b1001) begin // count to 9
            serializer_cnt <= '0;
            load_serializer <= 1'b1;
        end
    end
end // always_ff

always_comb begin
    case (which_byte)
        2'b00 : current_byte = upstream_packet[7:0];
        2'b01 : current_byte = upstream_packet[15:8];
        2'b10 : current_byte = upstream_packet[23:16];
        2'b11 : current_byte = upstream_packet[31:24];
    endcase
end // always_comb

always_ff @(posedge clk_core or negedge reset_n) begin
    if (!reset_n) begin
        next_packet <= 1'b0;
        which_byte <= 2'b1;
        upstream_packet <= '0;
        k_in <= 1'b0;
    end
    else begin
        if (serializer_cnt == 4'b0100) begin // update a few clocks early
            if (which_byte == 2'b11) begin
                next_packet <= 1'b1;
                which_byte <= 2'b00;
                k_in <= 1'b1;
                upstream_packet <= create_comma_packet();           
            end
            else begin
                next_packet <= 1'b0;
                which_byte <= which_byte + 1'b1;
                k_in <= 1'b0;
            end
        end
    end
end


// update input to 8b10b a few clock cycles before the serializer is ready
always_ff @(posedge clk_core or negedge reset_n) begin
    if (!reset_n)
        data_in8b <= '0;
    else
        if (serializer_cnt == 4'b0111)
            data_in8b <= current_byte;
end // always_ff

// 8b10b encoder disparity flip-flop 
always_ff @(posedge clk_core or negedge reset_n)
  if (!reset_n)
    disp_in <= 1'b0; // initialize disparity
  else
    disp_in <= disp_out;

// 8b10b encoder 
encode8b10b
    encode8b10_inst (
    .clk        (clk_core),
    .reset_n    (reset_n),
    .data_in    (data_in8b),    
    .k_in       (k_in),
    .data_out   (data_in10b),
    .disp_in    (disp_in),
    .disp_out   (disp_out)
    );


// behavioral serializer
serializer_sdr
    #(.WIDTH(WIDTH))
    serializer_inst (
    .dout           (dout),
    .dout_symbol    (symbol_start),
    .din            (data_in10b),
    .enable         (1'b1),
    .load           (load_serializer),
    .clk            (clk_core),
    .reset_n        (reset_n)
    );

// clocks
clk_manager
    clock_manager_inst  (
    .clk_core           (clk_core),
    .clk_rx             (clk_rx),
    .clk_tx             (clk_tx),
    .clk_fast           (clk_fast),
    .reset_n            (reset_n)
    );

// DUT connected here   

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
    .input_bit              (dout),  
    .tx_enable              (tx_enable),  
    .external_sync          (external_sync),
    .start_sync             (start_sync),
    .load_config_defaults   (load_config_defaults),
    .clk_tx                 (clk_tx),
    .clk                    (clk_core),
    .reset_n                (reset_n)
    );

endmodule
