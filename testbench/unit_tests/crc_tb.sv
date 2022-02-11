`timescale 1ns/1ps
///////////////////////////////////////////////////////////////////
// File Name: crc_tb.sv
//
// Engineer: Carl Grace (crgrace@lbl.gov)
// Description: SystemVerilog testbench for crc encoder.
//
///////////////////////////////////////////////////////////////////

module crc_tb();

localparam NUMTRIALS=200;

logic [7:0] crc_in;  // crc polynomial
logic [7:0] data_array[7:0];  // crc input data
logic [63:0] data_in; // crc input data
logic [7:0] crc_out; // crc output data 
logic crc_error;            // high when error in crc
logic [7:0] crc_new;        // crc calculated from rcvd_packet
logic [7:0] current_byte;   // crc calculated from rcvd_packet
logic check_crc;            // high to initiate crc check
logic clk;
logic reset_n;
logic debug;
logic verbose;
integer errors;

initial begin
    debug = 0;
    verbose = 1;
    reset_n = 1;
    current_byte = 0;
    clk = 0;
    check_crc = 0;
    #40 reset_n = 0;
    #40 reset_n = 1;
    crc_in = 8'h00;
/*    $display("CRC test: polyomial = %h",crc_in);
    data_in = '0;
    #100 check_crc = 1;
    #100 check_crc = 0;
    #100 data_in = {8{8'hAC}};
    $display("Data in = %h", data_in);
    #100 check_crc = 1;
    #100 check_crc = 0;
*/
    for (int i = 0; i < NUMTRIALS; i++) begin
        for (int j = 0; j < 8; j++) begin 
            randomize(current_byte);
            data_array[j] = current_byte;
            if (debug) $display("data_in[%d]: data_array[%d] = %h",i,j,current_byte);
        end // for j
        data_in = {data_array[7],data_array[6],data_array[5],
                    data_array[4],data_array[3],data_array[2],
                    data_array[1],data_array[0]};
        #100 check_crc = 1;
        if (verbose) begin       
            $display("TRIAL %d",i);
            $display("Data in = %h", data_in);
            $display("received CRC = %h, expected CRC %h",crc_out,crc_new);
            $display("\n");
        end
        #100 check_crc = 0;
    end // for i   
    $display("CRC encoder test complete. %0d transactions executed. %0d errors.",NUMTRIALS,errors);
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
    if (debug)
        $display("Expected CRC = %h, Received CRC = %h", crc_new, crc_out);

always_ff @(negedge clk or negedge reset_n) begin
    if (!reset_n) errors = 0;
    else if (crc_error) begin
        $display("ERROR IN CRC CALCULATION");  
        errors++;
    end
end 
     
endmodule
