`timescale 1ns/1ps
///////////////////////////////////////////////////////////////////
// File Name: crc8_tb.sv
//
// Engineer: Carl Grace (crgrace@lbl.gov)
// Description: SystemVerilog testbench for crc8 encoder.
//          used to validate methods
//
///////////////////////////////////////////////////////////////////

module crc8_tb();

localparam NUMTRIALS = 10;

logic [7:0] crcIn;  // crc polynomial
logic [7:0] dataIn;  // crc input data
logic [7:0] crcOut; // crc output data 
logic crc_error;            // high when error in crc
logic [7:0] crc_new;         // crc calculated from rcvd_packet
logic check_crc;              // high to initiate crc check
logic clk;
logic reset_n;

initial begin
    reset_n = 1;
    clk = 0;
    check_crc = 0;
    #40 reset_n = 0;
    #40 reset_n = 1;
    crcIn = 8'h00;
    $display("CRC test: initial value = %h",crcIn);
    dataIn = '0;
    #100 check_crc = 1;
    #100 check_crc = 0;
    for (int i = 0; i < NUMTRIALS; i++) begin
        #100 dataIn = i;
        #100 $display("Data in = %h, CRC out (dec) = %d",dataIn,crcOut);
    end
    $display("CRC8 CHECK DONE");
        

end // initial

initial begin
    forever begin   
        #10 clk = ~clk;
    end
end // initial

crc8 
    crc_inst (
    .crcIn          (crcIn),
    .dataIn         (dataIn),
    .crcOut         (crcOut)
    );
/*
crc_check 
    crc_check_inst (
    .crc_error      (crc_error),
    .crc_new        (crc_new),
    .rcvd_packet    (dataIn),
    .rcvd_crc       (crcOut),
    .check_crc      (check_crc),
    .reset_n        (reset_n)
    );
*/
// output monitor
//always_ff @(crcOut)
//    $display("Output CRC = %h", crcOut);

endmodule
