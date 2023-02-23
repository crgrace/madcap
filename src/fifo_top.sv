///////////////////////////////////////////////////////////////////
// File Name: fifo_top.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Top level of FIFO
//              Allows selection of latch-based or RAM-based FIFO  
//              RAM size is max FIFO. Latch size is as many as we can fit.
//              Temporarily stores data until it can be 
//              processed or sent off chip.
//              Parity of word is NOT stored in FIFO
//             
///////////////////////////////////////////////////////////////////

module fifo_top
    #(parameter FIFO_WIDTH = 64, // width of each FIFO word
    parameter integer unsigned FIFO_DEPTH = 2048,   // FIFO memory size (RAM) -- hardwired
    parameter FIFO_BITS = 11  // number of bits to describe RAM-based fifo addr range
    )
    (output logic [FIFO_WIDTH-1:0] data_out, // FIFO output data 
    output logic [FIFO_BITS:0] fifo_counter, // how many fifo locations used
    output logic fifo_full,         // high when fifo is in overflow 
    output logic fifo_half,         // high when fifo is half full
    output logic fifo_empty,        // high when fifo is in underflow 
    input logic [FIFO_WIDTH-1:0] data_in, // fifo input data
    input logic read_n,                // read data from fifo (active low)
    input logic write_n,               // write data to fifo (active low)
    input logic [7:0] chip_id,          // needed to tag test data
    input logic [31:0] timestamp_32b,   // needed to tag test data
    input logic clk,                    // master clock
    input logic reset_n);             // digital reset (active low)
//`define SRAM
//`define FF_RAM

// FIFO instantion logic
// if SRAM is defined, use macro for FIFO
// else if SRAM is undefined and FF_RAM is undefined, use latches for FIFO
// else if SRAM is undefined and FF_RAM is defined, use flip-flops for FIFO

`ifdef SRAM
fifo_ram 
    #(.FIFO_WIDTH(FIFO_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH),
    .FIFO_BITS(FIFO_BITS)
     ) fifo_ram_inst (
    .data_out       (data_out),
    .fifo_counter   (fifo_counter),
    .fifo_full      (fifo_full),
    .fifo_half      (fifo_half),
    .fifo_empty     (fifo_empty),
    .data_in        (data_in),
    .read_n         (read_n),
    .write_n        (write_n),
    .clk            (clk),
    .reset_n        (reset_n)
    );
`else
`ifdef FF_RAM
fifo_ff 
    #(.FIFO_WIDTH(FIFO_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH),
    .FIFO_BITS(FIFO_BITS)
     ) fifo_ff_inst (
    .data_out       (data_out),
    .fifo_counter   (fifo_counter),
    .fifo_full      (fifo_full),
    .fifo_half      (fifo_half),
    .fifo_empty     (fifo_empty),
    .data_in        (data_in),
    .read_n         (read_n),
    .write_n        (write_n),
    .clk            (clk),
    .reset_n        (reset_n)
    );
`else
fifo_latch 
    #(.FIFO_WIDTH(FIFO_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH),
    .FIFO_BITS(FIFO_BITS)
     ) fifo_latch_inst (
    .data_out       (data_out),
    .fifo_counter   (fifo_counter),
    .fifo_full      (fifo_full),
    .fifo_half      (fifo_half),
    .fifo_empty     (fifo_empty),
    .data_in        (data_in),
    .read_n         (read_n),
    .write_n        (write_n),
    .clk            (clk),
    .reset_n        (reset_n)
    );
`endif // ifdef FF_RAM
`endif // ifdef SRAM

endmodule // fifo_top

