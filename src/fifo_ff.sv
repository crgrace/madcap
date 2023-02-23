///////////////////////////////////////////////////////////////////
// File Name: fifo_ff.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Asynchronous FIFO (controlled by read and write pulses). 
//              Temporarily stores data until it can be 
//              processed or sent off chip.
//              Parity of word is stored in FIFO
//              Adapted from FIFO in B. Zeidman, "Verilog Designer's Library//"
///////////////////////////////////////////////////////////////////

module fifo_ff
    #(parameter FIFO_WIDTH = 64, // width of each FIFO word
    parameter integer unsigned FIFO_DEPTH = 4,   // number of FIFO memory locations
    parameter FIFO_BITS = $clog2(FIFO_DEPTH)     // number of bits to describe fifo addr range
    )
    (output logic [FIFO_WIDTH-1:0] data_out, // FIFO output data 
    output logic [FIFO_BITS:0] fifo_counter, // how many fifo locations used
    output logic fifo_full,         // high when fifo is in overflow 
    output logic fifo_half,         // high when fifo is half full
    output logic fifo_empty,        // high when fifo is in underflow 
    input logic [FIFO_WIDTH-1:0] data_in, // fifo input data
    input logic read_n,                // read data from fifo (active low)
    input logic write_n,               // write data to fifo (active low)
    input logic clk, 
    input logic reset_n);             // digital reset (active low)


// fifo memory array (latches)
logic [FIFO_WIDTH:0] fifo_mem [0:FIFO_DEPTH-1];

//internal signals
logic  [FIFO_BITS:0] read_pointer; // points to location to read from next
logic [FIFO_BITS:0] write_pointer; // points to location to write to next

// output assignments
always_comb begin
    fifo_counter = (write_pointer >= read_pointer) ? (write_pointer - read_pointer + 1'b1) : (FIFO_DEPTH + write_pointer - read_pointer +1'b1);
//    fifo_counter = (write_pointer - read_pointer); 
    fifo_full = (fifo_counter == FIFO_DEPTH-1) ? 1'b1 : 1'b0;
    fifo_half = (fifo_counter >= (FIFO_DEPTH >> 1)) ? 1'b1 : 1'b0;
    fifo_empty = (fifo_counter == 1) ? 1'b1 : 1'b0;
//    fifo_half = ($signed(fifo_counter) >= ($signed($unsigned(FIFO_DEPTH) >> 1)) ? 1'b1 : 1'b0);
end // always_comb

always_ff @ (posedge clk or negedge reset_n) 
    if (!reset_n) 
        read_pointer <= '0;
//    else begin
    else if (!read_n) begin
        if (!fifo_empty) begin
            // increment read pointer; check to see if read pointer has 
            // gone beyond depth of fifo, in that case set it to the 
            // beginning of the FIFO
            if (read_pointer >= FIFO_DEPTH-1'b1) 
                read_pointer <= '0;
            else
                read_pointer <= read_pointer + 1'b1;
        end
    end

always_ff @ (posedge clk or negedge reset_n)
    if (!reset_n)
        write_pointer <= '0;
//    else begin
    else if (!write_n) begin
        if (!fifo_full) begin
            // increment write pointer; check to see if write pointer has 
            // gone beyond depth of fifo, in that case set it to the 
            // beginning of the FIFO
            if (write_pointer >= FIFO_DEPTH-1'b1) 
                write_pointer <= '0;
            else
                write_pointer <= write_pointer + 1'b1;
        end
    end

// implement memory as latches to save die area

 always_ff  @(negedge clk)
    if (!read_n) 
    data_out <= fifo_mem[read_pointer];

 always_ff  @(negedge clk)
    if (!write_n) 
        fifo_mem[write_pointer] <= data_in;

endmodule // fifo_latch

