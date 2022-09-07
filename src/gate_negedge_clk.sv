///////////////////////////////////////////////////////////////////
// File Name: gate_negedge_clk.sv
// Engineer:  Dario Gnani (dgnani@lbl.gov)
// Description: Clock gating logic for negedge-sensitive seq logic.
//              Basic description of integrated clock gating (ICG) cell.
//
///////////////////////////////////////////////////////////////////
`timescale 1ns / 10ps
module gate_negedge_clk
    (output logic ENCLK,           // gated negedge clock
    input logic EN,                // clock-gating: enable clock (active high)
    input logic CLK);             // negedge clock

/*//DG: no mapping correctly to ICGs !?
// Internal Variables 
logic Esync;

// UART TX Logic
always_latch  
    if (CKN)
        Esync <= E; 
    // always_latch

always_comb
   ECKN = Esync | CKN;
*/
logic EN_dly;
always EN_dly = #0.5 EN; // avoid (false) hold violations

//TP: updaed to 130nm Standard cells
/*TLATCOX4 
    mapped_ICGN(
    .ECKN(ENCLK),
    .E(EN_dly),
    .CKN(CLK)
    );
*/
 CKLHQD4
    mapped_ICGN(
    .Q(ENCLK),
    .E(EN_dly),
    .TE(1'b0),
    .CPN(CLK)
    );


endmodule

