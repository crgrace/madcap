// File Name: reset_sync_mc.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Synchronizes an asynchronous reset 
//              Performs a config register reset
//              Also a re-sync signal (in case of comms difficulties)
//
//              if reset_n is held low for more than 4 clk cycles
//              then start_sync will be asserted.
//              if reset_n is held low for more than 16 clk cycles
//              then the internal reset (minus config) will be asserted
//              if reset_n is held low for more than 32 clk cycles
//              then the config register reset will be asserted
//              
///////////////////////////////////////////////////////////////////

module reset_sync_mc
(
    output logic reset_n_sync,          //synchronized reset 
    output logic start_sync,        // high to reset start_sync
    output logic reset_n_config_sync,   // reset config registers
    input clk,                          // primary clk
    input reset_n                       // asynchronous external reset
);

// local registers
logic [15:0] srg_clk;
logic [3:0] srg_start_sync;
logic [31:0] srg_config;
logic all_0;
logic all_0_start_sync;
logic all_0_config;

//always_comb begin
//    reset_n_sync = reset_n_sync_clk_reg;
//    reset_n_config_sync = ~sync_config_armed;
//end // always_comb

always_comb begin
    reset_n_sync = ~all_0;
    start_sync = all_0_start_sync;
    reset_n_config_sync = ~all_0_config;
end

// only change start_sync value when the input is identical 
// for 4 consecutive clock clk cycles
// this should filter out all meta stable states
// only sync reset when input is identical for another 12 clk cycles
// only sync reset_clk when input is identical for another 16 clk cycles
// this should make it easy to use the start_sync function

// shift register for clk
always_ff @(negedge clk) begin
    srg_clk <= {srg_clk[14:0],reset_n};
    if (srg_clk [15:1] == 15'h0000)
        all_0 <= 1'b1;
    else
        all_0 <= 1'b0;
end // always_ff

//shift register for start_sync
always_ff @(negedge clk) begin
    srg_start_sync <= {srg_start_sync[2:0],reset_n};
    if (srg_start_sync [3:1] == 3'b000) begin
        all_0_start_sync <= 1'b1;
    end
    else
        all_0_start_sync <= 1'b0;
end // always_ff

//shift register for sync_config
always_ff @(negedge clk) begin
    srg_config <= {srg_config[30:0],reset_n};
    if (srg_config [31:1] == 30'h000000) begin
        all_0_config <= 1'b1;
    end
    else
        all_0_config <= 1'b0;
end // always_ff

endmodule

