///////////////////////////////////////////////////////////////////
// File Name: timestamp_gen.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: 32-bit Time Stamp Counter
//
///////////////////////////////////////////////////////////////////

module timestamp_gen
    (output logic [31:0] timestamp_32b,  // time stamp for event builder
    input logic sync_timestamp, // timestamp set to 0 when high
    input logic clk,             // master clock
    input logic reset_n);         // digital reset (active low)
 
always_ff @ (posedge clk or negedge reset_n) 
    if (!reset_n) 
        timestamp_32b <= 32'b0;
    else
        if (sync_timestamp) 
            timestamp_32b <= 32'b0;
        else
            timestamp_32b <= timestamp_32b + 1'b1;
endmodule  
