`timescale 1ns/1ps

module clk_manager_tb();

logic clk_fast;     // 80 MHz primary clk
logic clk_core;     // MADCAP core clock
logic clk_rx;       // 2x oversampling rx clock
logic clk_tx;       // slow tx clock
logic reset_n;      // asynchronous digital reset (active low)



initial begin
    forever begin   
        #6.25 clk_fast = ~clk_fast; // 80 MHz
    end
end // initial

initial begin
    reset_n = 1;
    clk_fast = 0;
    #40 reset_n = 0;
    #35 reset_n = 1;
end // initial

clk_manager_mc
    clk_manager_mc_inst (
    .clk_core       (clk_core),
    .clk_rx         (clk_rx),
    .clk_tx         (clk_tx),
    .clk_fast       (clk_fast),
    .reset_n        (reset_n)
    );

endmodule
