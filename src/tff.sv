///////////////////////////////////////////////////////////////////
// File Name: tff.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Toggle flip-flop.  
//              Q inverts on every rising clock edge.
//
///////////////////////////////////////////////////////////////////
`define GATE_IMPL
`timescale 1ns / 10ps

module tff
    (output logic q,  // true output
    input logic clk,          // master clk
    input logic reset_n);     // asynchronous digital reset (active low)

logic qn;

`ifdef GATE_IMPL
logic qn_dly, rstn_dly;
always @(*) qn_dly = #1 qn;
always @(*) rstn_dly = #1 reset_n;
 /* DFFRX2 tff_inst(
    .Q(q),
    .QN(qn),
    .D(qn_dly),
    .RN(rstn_dly),
    .CK(clk));
  */
  //TP: updated the to 130nm D Flip-flop with Async Clear 
  DFCND2 tff_inst(
    .Q(q),
    .QN(qn),
    .D(qn_dly),
    .CDN(rstn_dly),
    .CP(clk));

`else
  always_ff @(posedge clk or negedge reset_n) 
    if (!reset_n)
        q <= 1'b0;
    else 
        q <= ~q; 
`endif

endmodule   
