///////////////////////////////////////////////////////////////////
// File Name: prbs7.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Linear feedback shift register used to generate
//              PRBS7 sequence to test LVDS TX block.
//              LFSR polynomial is x^7 + x^6 + 1
//              Pseudorandom sequence length is 127 bits 
//
///////////////////////////////////////////////////////////////////

module prbs7
    (output logic prbs,         // PRBS7 sequence
    input logic enable,         // high to enable shift register
    input logic clk,            // primary clock
    input logic reset_n);       // asynchronous digital reset (active low)

// shift register
logic [6:0] srg;                // holds PRBS state

assign prbs = srg[6];

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) 
        srg <= 7'h01;   // start with non-zero state register
    else
        if (enable)
            srg <= { srg[5:0], srg[6]^srg[5] };
        else 
            srg <= srg;
end // always_ff

endmodule

