///////////////////////////////////////////////////////////////////
// File Name: fifo_ff_mc.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Asynchronous FIFO (controlled by read and write pulses). 
//              Temporarily stores data until it can be 
//              processed or sent off chip.
//              Parity of word is NOT stored in FIFO
//              Adapted from FIFO in B. Zeidman, "Verilog Designer's Library//
//              Yes, there are some hardwired magic numbers in here. 
//              Sue me.
///////////////////////////////////////////////////////////////////

module fifo_ff_mc
    #(parameter FIFO_WIDTH = 68, // width of each FIFO word
    parameter integer unsigned FIFO_DEPTH = 32)   // FIFO memory locations
    (output logic [FIFO_WIDTH-1:0] data_out, // FIFO output data 
    output logic [5:0] fifo_counter, // how many fifo locations used
    output logic fifo_full,         // high when fifo is in overflow 
    output logic fifo_half,         // high when fifo is half full
    output logic fifo_empty,        // high when fifo is in underflow 
    input logic [FIFO_WIDTH-1:0] data_in, // fifo input data
    input logic read_n,                // read data from fifo (active low)
    input logic write_n,               // write data to fifo (active low)
    input logic reset_n);             // digital reset (active low)


// fifo memory array (latches)
logic [67:0] fifo_mem [0:31];

//internal signals
logic  [5:0] read_pointer; // points to location to read from next
logic [5:0] write_pointer; // points to location to write to next

// output assignments
always_comb begin
    fifo_counter = (write_pointer >= read_pointer) ? (write_pointer - read_pointer + 1'b1) : (6'b100001 + write_pointer - read_pointer);
//    fifo_counter = (write_pointer - read_pointer); 
    fifo_full = (fifo_counter == 6'b100000) ? 1'b1 : 1'b0;
    fifo_half = (fifo_counter >= 6'b010000) ? 1'b1 : 1'b0;
    fifo_empty = (fifo_counter == 1) ? 1'b1 : 1'b0;
//    fifo_half = ($signed(fifo_counter) >= ($signed($unsigned(FIFO_DEPTH) >> 1)) ? 1'b1 : 1'b0);
end // always_comb

always_ff @ (negedge read_n or negedge reset_n)
    if (!reset_n) 
        read_pointer <= 0;
//    else begin
    else if (!fifo_empty) begin
            // increment read pointer; check to see if read pointer has 
            // gone beyond depth of fifo, in that case set it to the 
            // beginning of the FIFO
        if (read_pointer >= FIFO_DEPTH-1'b1) 
            read_pointer <= 0;
        else
            read_pointer <= read_pointer + 1'b1;
   end

always_ff @ (negedge write_n or negedge reset_n)
    if (!reset_n)
        write_pointer <= 0;
//    else begin
    else if (!fifo_full) begin
            // increment write pointer; check to see if write pointer has 
            // gone beyond depth of fifo, in that case set it to the 
            // beginning of the FIFO
        if (write_pointer >= FIFO_DEPTH-1'b1) 
            write_pointer <= 0;
        else
            write_pointer <= write_pointer + 1'b1;
    end

// implement memory as latches to save die area        
always_ff  @ (negedge read_n) 
    data_out <= fifo_mem[read_pointer];

always_ff  @ (negedge write_n )
    fifo_mem[write_pointer] <= data_in;

endmodule // fifo_ff

