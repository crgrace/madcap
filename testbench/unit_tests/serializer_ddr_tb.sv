///////////////////////////////////////////////////////////////////
// File Name: serializer__ddrtb.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: SystemVerilog testbench for serializer block.
///////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module serializer_ddr_tb();

localparam WIDTH = 96;
localparam NUMTRIALS = 4;
logic reset_n;
logic clk;
logic enable;
logic load;
logic dout_even;
logic dout_odd;
logic dout; // DDR output
logic dout_frame;
logic [WIDTH-1:0] din;
logic [WIDTH-1:0] dataword;
logic [WIDTH-1:0] larpix_packet [NUMTRIALS-1:0];
initial begin
    reset_n = 1;
    clk = 0;
    enable = 1;
    load= 0;
    for (int i = 0; i < NUMTRIALS; i++) begin
        larpix_packet[i] = {$urandom(),$urandom(),$urandom()};
    end // for
    din = larpix_packet[0];;
    #40 reset_n = 0;
    #40 reset_n = 1;
    #100 load = 1;
    #20 load = 0;
    #200 enable = 0;
    #30 din = larpix_packet[1];
    #110 enable = 1;
    #40 load = 1;
    #20 load = 0;
end

initial begin
    forever begin   
        #10 clk = ~clk;
    end
end // initial

// DUT connected here
serializer
    #(.WIDTH(WIDTH))
    serializer_inst (
    .dout_even      (dout_even),
    .dout_odd       (dout_odd),
    .dout_frame     (dout_frame),
    .din            (din),
    .enable         (enable),
    .load           (load),
    .clk            (clk),
    .reset_n        (reset_n)
    );

// behavioral deserializer

deserializer_ddr
    #(.WIDTH(WIDTH))
    deserializer_inst (
    .dataword       (dataword),
    .din            (dout),
    .frame_start    (dout_frame),
    .clk            (clk),
    .reset_n        (reset_n)
    );

// output mux

output_mux  
    output_mux_inst (
    .dout       (dout),
    .dout_even  (dout_even),
    .dout_odd   (dout_odd),
    .clk        (clk)
    );

endmodule

