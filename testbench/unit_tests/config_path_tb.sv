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
localparam REGNUM = 34;
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
logic [39:0] upstream_packet; // from FPGA to MADCAP
logic dout;                 // serializer output (single bit)
logic [7:0] data_in8b;      // input to send to 8b10b encoder
logic [7:0] current_byte;   // byte selected from upstream pacet
logic [9:0] data_in10b;     // input to test serializer 
logic next_packet;          // high when ready for new packet
logic [2:0] which_byte;     // byte of packet being serialized
logic k_in;                 // high to indicate 8b symbol represents k-code
logic external_sync;        // high for external sync mode
logic start_sync;           // high to mark first bit in symbol
logic enable_8b10b;         // high to enable 8b10b encoder

// packet building
logic [1:0] packet_declaration;
logic [4:0] chip_id;
logic [7:0] regmap_address;
logic [7:0] regmap_data;
logic [25:0] larpix_packet;
logic [3:0] target_larpix;
logic sending_commas;
logic make_madcap_packet;
logic make_larpix_packet;


initial begin
    packet_declaration = '0;
    chip_id = '0;
    regmap_address = '0;
    regmap_data = '0;
    larpix_packet = '0;
    target_larpix = '0;
    make_madcap_packet = 0;
    make_larpix_packet = 0;
    tx_enable = '0;
    clk_fast = 1'b0;
    external_sync = 1'b0;
    start_sync = 1'b0;
    load_config_defaults = 1'b0;
    #10 reset_n = 1'b0;
    #55 reset_n = 1'b1;
    // wait a while and then send a MADCAP regfile packet!
    #5000
    $display("Send first MADCAP packet");
    chip_id = 5'b0_0001;
    regmap_address = '0;
    regmap_data = 8'hF3;
    packet_declaration = 2'b10;
    make_madcap_packet = 1;
    @upstream_packet;
    make_madcap_packet = 0;
    target_larpix = 4'h1;
    larpix_packet = 26'h3_CE_01_8F;
    packet_declaration = 2'b00;
    #1000 make_larpix_packet = 1;
    @upstream_packet;
    make_larpix_packet = 0;

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
        3'b000 : current_byte = upstream_packet[7:0];
        3'b001 : current_byte = upstream_packet[15:8];
        3'b010 : current_byte = upstream_packet[23:16];
        3'b011 : current_byte = upstream_packet[31:24];
        3'b100 : current_byte = upstream_packet[39:32];
        default: current_byte = '0;
    endcase
end // always_comb

always_comb begin
    if ( (sending_commas) || (which_byte == 3'b000) ) begin 
        k_in = 1'b1;
    end
    else begin
        k_in = 1'b0;
    end
end // always_comb

// create next packet
always_ff @(posedge clk_core or negedge reset_n) begin
    if (!reset_n) begin
        next_packet <= 1'b0;
        which_byte <= 3'b000;
        upstream_packet <= '0;
        enable_8b10b <= 1'b0;
        sending_commas <= 1'b0;
    end
    else begin
        enable_8b10b <= 1'b0;
        if (serializer_cnt == 4'b0100) begin // update a few clocks early
               enable_8b10b <= 1'b1;
            if (which_byte == 3'b100) begin
                next_packet <= 1'b1;
                which_byte <= 3'b00;
                if (make_madcap_packet) begin
                    sending_commas <= 1'b0;
                    upstream_packet <= create_madcap_packet(
                                    packet_declaration,
                                    chip_id,
                                    regmap_address,
                                    regmap_data);
                end
                else if (make_larpix_packet) begin
                    sending_commas <= 1'b0;
                    upstream_packet <= create_larpix_packet(
                                    packet_declaration,
                                    larpix_packet,
                                    target_larpix);
                end
                else begin
                    upstream_packet <= create_comma_packet(); 
                    sending_commas <= 1'b1;
                end
            end
            else begin
                next_packet <= 1'b0;
                which_byte <= which_byte + 1'b1;
            end
        end
    end
end
/*
// determine when to send commas (command codes)
always_ff @(posedge clk_core or negedge reset_n) begin
    if (!reset_n) begin
        sending_commas <= 1'b1;
    end
    else begin
        if (make_madcap_packet || make_larpix_packet)
            sending_commas <= 1'b0;
        else if (make_comma_packet)
            sending_commas <= 1;b1;
    end
end // always
  */          
    
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
    if (enable_8b10b)
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
clk_manager_mc
    clock_manager_mc_inst  (
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
