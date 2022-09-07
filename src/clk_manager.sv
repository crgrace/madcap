///////////////////////////////////////////////////////////////////
// File Name: clk_manager.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Counter and mux to generate different clocks 
//
//  Core clock can be 2X, 4X, 8X, or 16X rx clock
//  RX clock is always 2X tx clock
//  It may be useful to use a high channel clock to reduce deadtime
//
//          clock speeds relative to clk_core
//  clk_ctrl    clk_rx    clk_tx note
//      00         1       1/2      core_clock is 2X to tx clock
//      01         1/2       1/4    core_clock is 4X tx clock
//      10         1/4       1/8    core_clock is 8X tx clock
//      11         1/8       1/16   core_clock is 16X tx clock
//
//  in v2 mode RX clock is always 2X TX clock
//  in v3 mode RX clock is same as TX clock
///////////////////////////////////////////////////////////////////

module clk_manager
    
    (output logic clk_core, // LArPix core clock
    output logic clk_rx,    // 2x oversampling rx clock
    output logic clk_tx,  // slow tx clock
    input logic v3_mode,    // high for v3 mode (no 2X RX clk) 
    input logic [1:0] clk_ctrl, // clock configuration
    input logic clk, // fast input clock
    input logic reset_n);  // asynchronous digital reset (active low)
 
logic [3:0] clk_counter;
/*
always_ff @(posedge clk, negedge reset_n) 
    if (!reset_n) begin
        clk_counter <= 4'b0000;
    end    
    else begin
        clk_counter <= clk_counter + 1'b1;
    end
*/
always_comb
    clk_core = clk;
// output mux
always_comb  begin :mux
    case (clk_ctrl) /* synopsys infer_mux */
        2'b00:  begin
                    clk_tx = (v3_mode) ? clk : clk_counter[0];
                    clk_rx = clk;
                end
        2'b01: begin
                    clk_tx = (v3_mode) ? clk_counter[0] : clk_counter[1];
                    clk_rx = clk_counter[0];
                end
        2'b10: begin
                    clk_tx = (v3_mode) ? clk_counter[1] : clk_counter[2];
                    clk_rx = clk_counter[1];
                end
        2'b11: begin
                    clk_tx = (v3_mode) ? clk_counter[2] : clk_counter[3];
                    clk_rx = clk_counter[2];
                end
        default: begin
                    clk_tx = (v3_mode) ? clk : clk_counter[0];
                    clk_rx = clk;
                end
    endcase 
end // always_comb

// ripple-carry counter
tff
    tff_inst_0 (
    .q          (clk_counter[0]),
    .clk        (clk),
    .reset_n    (reset_n)
    );

tff
    tff_inst_1 (
    .q          (clk_counter[1]),
    .clk        (clk_counter[0]),
    .reset_n    (reset_n)
    );

tff
    tff_inst_2 (
    .q          (clk_counter[2]),
    .clk        (clk_counter[1]),
    .reset_n    (reset_n)
    );

tff
    tff_inst_3 (
    .q          (clk_counter[3]),
    .clk        (clk_counter[2]),
    .reset_n    (reset_n)
    );

endmodule 

 
