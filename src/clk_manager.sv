///////////////////////////////////////////////////////////////////
// File Name: clk_manager.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Performs following functions:
//              1. divides down primary clock to LArPix (rx) clk 
//              2. divides down rx clk to tx clk (to send config to tile)
//
//  Primary clock (nominally 80 MHz) is 8X LArPix clock (nominally 10 MHz) 
//  RX clock is always 2X TX (config) clock
//
///////////////////////////////////////////////////////////////////

module clk_manager
    
    (output logic clk_core, // MADCAP core clock
    output logic clk_rx,    // 2x oversampling rx clock
    output logic clk_tx,    // slow tx clock
    input logic clk_fast, // fast input clock
    input logic reset_n);  // asynchronous digital reset (active low)

// internal counter 
logic [3:0] clk_counter;

always_comb begin
    clk_core = clk_fast;
    clk_rx = ~clk_counter[2];
    clk_tx = clk_counter[3];
end // always_comb

// output assignments

// ripple-carry counter

always_ff @(posedge clk_fast or negedge reset_n) begin
    if (!reset_n) begin
        clk_counter <= '0;
    end
    else
        clk_counter <= clk_counter + 1'b1;
end // always_ff
endmodule 

 
