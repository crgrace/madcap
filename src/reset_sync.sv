// File Name: reset_sync_mc.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Synchronizes an asynchronous reset 
//              to the core "clk" domains
//              if reset_n is held low for more than 4 clk cycles
//              then reset_n_sync will be asserted.
//              
///////////////////////////////////////////////////////////////////

module reset_sync_mc
(
    output logic reset_n_sync,      // synchronized reset
    input logic clk,                // primary clk
    input logic reset_n             // asynchronous external reset
);

// local registers
logic [4:0] srg_sync;
logic all_1_sync;
logic all_0_sync;
logic sync_reg;

always_comb begin
    reset_n_sync = sync_reg;
end // always_comb

// only change sync_reg value when the input is identical 
// for 4 consecution clock clk cycles

//shift register for sync
always_ff @(posedge clk) begin
    srg_sync <= {srg_sync[3:0],reset_n};
    if (all_0_sync)
        sync_reg <= 1'b0;
    else if (all_1_sync)
        sync_reg <= 1'b1;
    else
        sync_reg <= sync_reg;
    if (srg_sync [4:1] == 4'b0000) begin
        all_0_sync <= 1'b1;
    end
    else
        all_0_sync <= 1'b0;
    if (srg_sync [4:1] == 4'b1111) begin
        all_1_sync <= 1'b1;
    end
    else
        all_1_sync <= 1'b0;
end // always_ff

endmodule

