///////////////////////////////////////////////////////////////////
// File Name: fifo_ram.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Synchronous FIFO  
//              Temporarily stores data until it can be 
//              processed or sent off chip.
//              Parity of word is stored in FIFO
//              Adapted from FIFO in B. Zeidman, "Verilog Designer's Library"
//              Key different here is this FIFO uses SRAM for memory elements
//             
///////////////////////////////////////////////////////////////////

module fifo_ram
    #(parameter FIFO_WIDTH = 64, // width of each FIFO word
    parameter integer unsigned FIFO_DEPTH = 2048,   // number of FIFO memory locations
    parameter FIFO_BITS = 11     // number of bits to describe fifo addr range
    )
    (output logic [FIFO_WIDTH-1:0] data_out, // FIFO output data 
    output logic [FIFO_BITS:0] fifo_counter, // how many fifo locations used
    output logic fifo_full,         // high when fifo is in overflow 
    output logic fifo_half,         // high when fifo is half full
    output logic fifo_empty,        // high when fifo is in underflow 
    input logic [FIFO_WIDTH-1:0] data_in, // fifo input data
    input logic read_n,                // read data from fifo (active low)
    input logic write_n,               // write data to fifo (active low)
    input logic clk,                    // master clock
    input logic reset_n);             // digital reset (active low)

//internal signals
logic  [FIFO_BITS:0] read_pointer; // points to location to read from next
logic [FIFO_BITS:0] write_pointer; // points to location to write to next
logic clk_read; // gated read clock
logic clk_write; // gated write clock
logic [63:0] data_out_0; // 64-bit output of SRAM module 0
logic [63:0] data_out_1; // 64-bit output of SRAM module 1
logic [63:0] data_out_2; // 64-bit output of SRAM module 2
logic [63:0] data_out_3; // 64-bit output of SRAM module 3
logic [3:0] module_select_write; // chip enable for write (active low)

logic [FIFO_WIDTH-1:0] data_in_falling_edge;
//logic [1:0] fifo_empty_counter;
//logic fifo_empty_internal;
//logic fifo_empty_sch;
logic enable_write_pointer;
logic enable_read_pointer;

// output assignments
always_comb begin
    fifo_counter = (write_pointer >= read_pointer) ? (write_pointer - read_pointer + 1'b1) : (FIFO_DEPTH + write_pointer - read_pointer + 1'b1);
    fifo_full = (fifo_counter == FIFO_DEPTH-1) ? 1'b1 : 1'b0;
    fifo_half = (fifo_counter >= 12'b0100_0000_0000) ? 1'b1 : 1'b0;
    fifo_empty = (fifo_counter == 1) ? 1'b1 : 1'b0;
end // always_comb

always_comb begin
    enable_read_pointer = !read_n & (!fifo_empty);
    enable_write_pointer = !write_n & (!fifo_full);
end

always_ff @(negedge clk or negedge reset_n) begin
    if (!reset_n) begin
        data_in_falling_edge <= 'b0;
    end
    else begin
        data_in_falling_edge <= data_in;
    end
end

always_ff @ (posedge clk or negedge reset_n) begin
    if (!reset_n) 
        read_pointer <= 0;
    else begin
            // increment read pointer; check to see if read pointer has 
            // gone beyond depth of fifo, in that case set it to the 
            // beginning of the FIFO
        if (enable_read_pointer) begin
            if (read_pointer == FIFO_DEPTH-1'b1) 
                read_pointer <= 0;
            else
                read_pointer <= read_pointer + 1'b1;
        end
    end // else
end // always_ff

always_ff @ (posedge clk or negedge reset_n) begin
    if (!reset_n)
        write_pointer <= 0;
    else begin
            // increment write pointer; check to see if write pointer has 
            // gone beyond depth of fifo, in that case set it to the 
            // beginning of the FIFO
        if (enable_write_pointer) begin
            if (write_pointer == FIFO_DEPTH-1'b1) 
                write_pointer <= 0;
            else
                write_pointer <= write_pointer + 1'b1;
        end
    end // else
end // always_ff

// DG: gate posedge clock then invert
gate_posedge_clk
    ICGP_R(.EN(~read_n),
    .CLK(~clk),
    .ENCLK(clk_read)
    );
gate_posedge_clk
    ICGP_W(.EN(~write_n),
    .CLK(~clk),
    .ENCLK(clk_write)
    );

// address decoders to generate Chip Enables

always_comb begin 
    unique case (write_pointer[10:9])
        2'b00: module_select_write = 4'b1110;
        2'b01: module_select_write = 4'b1101;
        2'b10: module_select_write = 4'b1011;
        2'b11: module_select_write = 4'b0111;   
    endcase

end // always_comb

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        data_out <= 0;
    end
    else if (enable_read_pointer) begin
        unique case (read_pointer[10:9])
            2'b00: data_out <= data_out_0;
            2'b01: data_out <= data_out_1;
            2'b10: data_out <= data_out_2;
            2'b11: data_out <= data_out_3;   
        endcase
    end // if
end // always_ff


// Dual-Port SRAM model
// Hardwired to 2048 FIFO locations
// 4 instances are required to implement 2048 words from 512-word modules

// memory locations 0-511 
rf2p_512x64_4_50
    rf2p_512x64_4_50_inst_0 (
    .QA         (data_out_0),
    .AA         (read_pointer[8:0]),
    .CLKA       (clk_read),
    .CENA       (read_n),
    .DB         (data_in_falling_edge),
    .AB         (write_pointer[8:0]),
    .CLKB       (clk_write),
    .CENB       (module_select_write[0])
    );

// memory locations 512-1023 
rf2p_512x64_4_50
    rf2p_512x64_4_50_inst_1 (
    .QA         (data_out_1),
    .AA         (read_pointer[8:0]),
    .CLKA       (clk_read),
    .CENA       (read_n),
    .DB         (data_in_falling_edge),
    .AB         (write_pointer[8:0]),
    .CLKB       (clk_write),
    .CENB       (module_select_write[1])
    );

// memory locations 1024-1535 
rf2p_512x64_4_50
    rf2p_512x64_4_50_inst_2 (
    .QA         (data_out_2),
    .AA         (read_pointer[8:0]),
    .CLKA       (clk_read),
    .CENA       (read_n),
    .DB         (data_in_falling_edge),
    .AB         (write_pointer[8:0]),
    .CLKB       (clk_write),
    .CENB       (module_select_write[2])
    );

// memory locations 1536-2047 
rf2p_512x64_4_50
    rf2p_512x64_4_50_inst_3 (
    .QA         (data_out_3),
    .AA         (read_pointer[8:0]),
    .CLKA       (clk_read),
    .CENA       (read_n),
    .DB         (data_in_falling_edge),
    .AB         (write_pointer[8:0]),
    .CLKB       (clk_write),
    .CENB       (module_select_write[3])
    );

endmodule // fifo_ram

