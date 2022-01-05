///////////////////////////////////////////////////////////////////
// File Name: datapath_tb.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: SystemVerilog testbench for MADCAP datapath.
///////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "k_codes.sv"
module datapath_tb();

localparam WIDTH = 64;
localparam NUMCHANNELS = 16;
localparam FIFO_DEPTH = 32;
logic reset_n;
logic [WIDTH-1:0] tx_data [NUMCHANNELS-1:0]; // data sent (pre serializer)
logic [119:0] dataword_120b; // deserialized data (before 8b10 decoding)
logic [95:0] dataword_96b;   // deserialized data (after 8b10 decoding)
logic [95:0] superpacket;   // final packet ready for analysis
logic [11:0] k_out;
logic [11:0] code_err;
logic [11:0] disp_err;
logic ack_fifo_data;         // high to ack config write to FIFO
logic write_fifo_data_req;    // req to put data into FIFO
logic dout_even;
logic dout_odd;
logic dout; // DDR output
logic dout_frame;
logic new_dataword; // high to indicate new dataword available
logic [NUMCHANNELS-1:0] piso;
logic [NUMCHANNELS-1:0] tx_busy;  // not used yet
logic [NUMCHANNELS-1:0] tx_enable;  // not used yet
logic clk_fast;     // 80 MHz input clock
logic clk_core;     // MADCAP core clock (80 MHz nomimal)
logic clk_rx;       // 2x oversampling rx clock (10 MHz nominal)
logic clk_tx;       // slow tx clock (5 MHz nominal)
logic v3_mode;
logic serializer_enable;        // high to enable 
logic enable_prbs7;                 // high for PRBS output
logic [1:0] enable_fifo_panic;  // high to insert fifo k-codes
logic config_fifo_half;     // high if config fifo half full 
logic config_fifo_full;     // high if config fifo full  
logic [4:0] config_fifo_cnt;  // FIFO usage when FIFO read
logic which_fifo; // 0 = config_fifo, 1 = data_fifo
logic bypass_8b10b;           // high to bypass 8b10 encoder
logic [2:0] test_mode;        // control various test modes
logic [95:0] test_packet;     // test data to send to 8b10b
logic [7:0] crc_input;        // CRC-8 hash of rx_data         
logic [5:0] chip_id;          // id for MADCAP  
logic [63:0] larpix_packet [NUMCHANNELS-1:0];
logic [NUMCHANNELS-1:0] ld_tx_data; // high to xfer data to UART
logic simulation_done;          // high when simulation done

initial begin
    reset_n = 1;
    tx_enable = '1;
    bypass_8b10b = 0;
    clk_fast = 0; 
    v3_mode = 0;
    test_mode = '0; 
    test_packet = '0;
    serializer_enable = 1;
    which_fifo = 1;  // data fifo
    enable_fifo_panic = 2'b00;
    config_fifo_cnt = '0;
    config_fifo_half = 0; 
    config_fifo_full = 0;
    crc_input = '0;
    chip_id = 5'b00001;
    ld_tx_data = '0;
    simulation_done = 0;
    enable_prbs7 = 0;
 
    for (int i = 0; i < NUMCHANNELS; i++) begin
        larpix_packet[i] = {$urandom(),$urandom()};
         $display ("larpix_packet[%d] = %h",i,larpix_packet[i]);
    end // for
//    larpix_packet = {larpix_packet[63:0],larpix_packet[62:0]}; // parity
    #40 reset_n = 0;
    #35 reset_n = 1;
//    #10 $display ("larpix_packet[2] = %h",larpix_packet[2]);
    for (int i = 0; i < NUMCHANNELS; i++) begin
        tx_data[i] = larpix_packet[i];
    end
    #650 ld_tx_data = 16'hFFFF;
    #200 ld_tx_data = '0; 
    @ (!tx_busy); 
    #40 ld_tx_data = 16'hFFFF;
    #500 ld_tx_data = '0; 
    @ (!tx_busy);     
    #40 ld_tx_data = 16'hFFFF;
    #500 ld_tx_data = '0; 
    $display("Test inputs complete");
    #100 $display("Bypass 8b10b test");
    bypass_8b10b = 1;
    #40 ld_tx_data = 16'hFFFF;
    #500 ld_tx_data = '0;     
    #10000 bypass_8b10b = 0;
    #1000 $display("Bypass 8b10b test complete");
    $display("PRBS7 test");
    enable_prbs7 = 1;
    #20000 $display("PRBS7 test complete");
    enable_prbs7 = 0;
    simulation_done = 1;
end // initial

initial begin
    forever begin   
        #6.25 clk_fast = ~clk_fast; // 80 MHz
    end
end // initial

// mux to bypass 8b10b decoder
always_comb begin
    if (bypass_8b10b) 
        superpacket = dataword_120b[95:0];
    else
        superpacket = dataword_96b;
end // always_comb
    
// DUT connected here
datapath
    #(.WIDTH(WIDTH))
    datapath_inst (
    .dout_even              (dout_even),
    .dout_odd               (dout_odd),
    .dout_frame             (dout_frame),
    .ack_fifo_data          (ack_fifo_data),
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
    .v3_mode                (v3_mode),
    .bypass_8b10b           (bypass_8b10b),
    .serializer_enable      (serializer_enable),    
    .enable_prbs7           (enable_prbs7),
    .clk_core               (clk_core),
    .clk_rx                 (clk_rx),
    .reset_n                (reset_n)
    );

// tile model
uart_array_tx
    #(.WIDTH(WIDTH),
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

// clock gen
clk_manager_mc
    clk_manager_mc_inst (
    .clk_core       (clk_core),
    .clk_rx         (clk_rx),
    .clk_tx         (clk_tx),
    .v3_mode        (v3_mode),
    .clk_fast       (clk_fast),
    .reset_n        (reset_n)
    );

// behavioral double datarate deserializer
deserializer_ddr
    #(.WIDTH(120))
    deserializer_ddr_inst (
    .dataword       (dataword_120b),
    .new_dataword   (new_dataword),
    .din            (dout),
    .frame_start    (dout_frame),
    .clk            (clk_core),
    .reset_n        (reset_n)
    );

// decode deserialized data words
decode96b120b
    decode96b120b_inst (
    .datain         (dataword_120b),
    .clk            (clk_core),
    .reset_n        (reset_n),
    .dataout        (dataword_96b),
    .k_out          (k_out),
    .code_err       (code_err),
    .disp_err       (disp_err)
    );


// output mux
output_mux  
    output_mux_inst (
    .dout       (dout),
    .dout_even  (dout_even),
    .dout_odd   (dout_odd),
    .clk        (clk_core)
    );

// analysis
analyze_superpacket
    analyze_superpacket_inst (
    .superpacket        (superpacket),
    .new_superpacket    (new_dataword),
    .which_fifo         (which_fifo),
    .k_out              (k_out),
    .bypass_8b10b       (bypass_8b10b),
    .simulation_done    (simulation_done)
    );

endmodule

