///////////////////////////////////////////////////////////////////
// File Name: tff.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Toggle flip-flop.  
//              Q inverts on every rising clock edge.
//
///////////////////////////////////////////////////////////////////
`timescale 1ns / 10ps

module clk_mux4
    (output logic clk_out,  // selected clock output
    input logic clk_in00,   // master clk
    input logic clk_in01,   // master clk
    input logic clk_in10,   // master clk
    input logic clk_in11,   // master clk
    input logic [1:0] clk_sel);     // asynchronous digital reset (active low)

gate_posedge_clk
    ICGP_sel00(.EN(clk_sel==2'b00),
    .CLK(clk_in00),
    .ENCLK(clk_out)
    );
// OUCH requires tri-state logic to avoid unbalanced mux... messy

endmodule   
