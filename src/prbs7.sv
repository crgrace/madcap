///////////////////////////////////////////////////////////////////
// File Name: prbs7.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: PRBS7 sequence to test LVDS TX block.
//              LFSR polynomial is x^7 + x^6 + 1
//              Pseudorandom sequence length is 127 bits 
//              Implemented with ROM
//
///////////////////////////////////////////////////////////////////

module prbs7
    (output logic [1:0] prbs,   // PRBS7 sequence
    input logic enable,         // high to enable PRBS7 output
    input logic clk,            // primary clock
    input logic reset_n);       // asynchronous digital reset (active low)

logic [126:0] prbs7_rom;
logic [6:0] prbs_pntr;

// PRBS7_ROM definition
// located at ../testbench/tasks/
// example compilation: 
//vlog +incdir+../testbench/tasks/ -incr -sv "../src/prbs7.sv"

`include "madcap_constants.sv"
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        prbs_pntr <= '0;
 //       prbs7_rom <= 127'b1000001100001010001111001000101100111010100111110100001110001001001101101011011110110001101001011101110011001010101111111000000;
        prbs7_rom <= PRBS7_ROM;
    end 
    else begin
        if (prbs_pntr ==  7'b1111110) 
            prbs_pntr <= 7'b0000001;
        else if (prbs_pntr == 7'b1111101)
            prbs_pntr <= 7'b0000000;
        else
            prbs_pntr <= (prbs_pntr + 2'b10);
       
    end
end // always_ff

always_ff @(posedge clk or negedge reset_n) begin 
    if (enable) begin
        if (prbs_pntr == 7'b11111110)
            prbs <= {prbs7_rom[0],prbs7_rom[prbs_pntr]};
        else
            prbs <= {prbs7_rom[prbs_pntr + 1'b1],prbs7_rom[prbs_pntr]};
        end
    else
        prbs <= 2'b00;
end // always_ff

endmodule

