///////////////////////////////////////////////////////////////////
// File Name: pulse_stretcher.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Pulses that are generated in the fast clock domain
//              need to be stretched out to be detected in the slower
//              clock domains (RX and TX UART clocks). This module
//              stretches by 3 bits for clk_core -> clk_rx
//              stetches by 4 bits for clk_core -> clk_tx 
//
//
///////////////////////////////////////////////////////////////////

module pulse_stretcher
    (output logic pulse_out,    // stretched output pulse
    input logic pulse_in,       // fast input pulse
    input logic stretch_mode,   // 0 = 3 bits (rx), 1 = 4 bits (tx)
    input logic clk);           // this is the fast clock
    
// temp storage


logic [15:0] stretch_reg;
always_ff @ (posedge clk) begin 
    stretch_reg <= pulse_in ? 16'hFFFF : {stretch_reg[14:0],1'b0}; 
end // always_ff

always_comb begin
    pulse_out = stretch_mode ? stretch_reg[15] : stretch_reg[8];
end

endmodule


