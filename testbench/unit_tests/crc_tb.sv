`timescale 1ns/1ps
///////////////////////////////////////////////////////////////////
// File Name: crc_tb.sv
//
// Engineer: Carl Grace (crgrace@lbl.gov)
// Description: SystemVerilog testbench for crc encoder.
//
///////////////////////////////////////////////////////////////////

module crc_tb();

localparam NUMTRIALS=10;

logic [7:0] crc_in;  // crc polynomial
logic [63:0] data_in;  // crc input data
logic [7:0] crc_out; // crc output data 
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
    crc_in = 8'h00;
    $display("CRC test: polyomial = %h",crc_in);
    data_in = '0;
    #100 check_crc = 1;
    #100 check_crc = 0;
    #100 data_in = {8{8'h22}};
    $display("Data in = %h", data_in);
    #100 check_crc = 1;
    #100 check_crc = 0;
        

end // initial

initial begin
    forever begin   
        #10 clk = ~clk;
    end
end // initial

crc 
    crc_inst (
    .crc_in          (crc_in),
    .data_in         (data_in),
    .crc_out         (crc_out)
    );

crc_check 
    crc_check_inst (
    .crc_error      (crc_error),
    .crc_new        (crc_new),
    .rcvd_packet    (data_in),
    .rcvd_crc       (crc_out),
    .check_crc      (check_crc),
    .reset_n        (reset_n)
    );

// output monitor
always_ff @(crc_out)
    $display("Output CRC = %h", crc_out);

endmodule
