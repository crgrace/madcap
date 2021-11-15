///////////////////////////////////////////////////////////////////
// File Name: deserializer_sdr_tb.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: SystemVerilog testbench for deserializer block.
//              The deserilaizer received config bits from the LVDS RX
///////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "../testbench/tasks/k_codes.sv"
module deserializer_sdr_tb();

localparam WIDTH = 10;
localparam NUMTRIALS = 20;
localparam NUMCOMMAS = 20;
logic reset_n;
logic clk;
logic enable;
logic load_serializer;
logic dout; // SDR output
logic dout_symbol; // forwarded symbol marker
logic symbol_start; // high for first bit in 8b10b symbol
logic symbol_start_fsm; // 8b10b symbol marker from comma detect
logic external_sync; // high for external first bit in 8b10b symbol
logic start_sync;       // external signal to force sync
logic [3:0] serializer_cnt;
logic ready_to_load;
logic dataword_ready;
logic [WIDTH-1:0] din;
logic [WIDTH-1:0] dataword;
logic [63:0] random_data;

initial begin
    reset_n = 1;
    clk = 0;
    enable = 1;
    external_sync = 0;
    start_sync = 0;
    #40 reset_n = 0;
    #40 reset_n = 1;
//    for (int i = 0; i < NUMTRIALS; i++) begin
//        larpix_packet[i] = {$urandom(),$urandom(),$urandom()};
//    end // for
    din = 10'b0110_1101_11;
    for (int i = 0; i < 4; i++) begin
        @(posedge ready_to_load)
        random_data = $urandom();
        $display("Send Data # %d",i);
        din = random_data[9:0];
    end // for
    #200 din = 10'b0100_0101_01;
    for (int i = 0; i < NUMCOMMAS; i++) begin
        @(posedge ready_to_load)
        $display("Send Comma # %d",i);
        #1 din = `K_K_DISP_N;
    end // for
    for (int i = 0; i < NUMTRIALS; i++) begin
        @(posedge ready_to_load)
        random_data = $urandom();
        $display("Send Data # %d",i);
        #1 din = random_data[9:0];
    end
end

initial begin
    forever begin   
        #10 clk = ~clk;
    end
end // initial

always_comb
    if (serializer_cnt == 4'b0010)
        ready_to_load = 1'b1;
    else
        ready_to_load = 1'b0;

// load serializer counter
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        serializer_cnt <= '0;
        load_serializer <= 1'b0;
    end
    else begin
        serializer_cnt <= serializer_cnt + 1'b1;
        load_serializer <= 1'b0;
        if (serializer_cnt == 4'b1001) begin // count to 9
            serializer_cnt <= '0;
            load_serializer <= 1'b1;
        end
    end
end // always_ff

// mux to select symbol start
always_comb begin
    if (external_sync)
        symbol_start = dout_symbol;
    else
        symbol_start = symbol_start_fsm;
end // always_comb

// behavioral deserializer
serializer_sdr
    #(.WIDTH(WIDTH))
    serializer_inst (
    .dout           (dout),
    .dout_symbol    (dout_symbol),
    .din            (din),
    .enable         (enable),
    .load           (load_serializer),
    .clk            (clk),
    .reset_n        (reset_n)
    );

// DUT connected here

deserializer_sdr
    #(.WIDTH(WIDTH))
    deserializer_inst (
    .dataword       (dataword),
    .dataword_ready (dataword_ready),
    .din            (dout),
    .symbol_start   (symbol_start),
    .clk            (clk),
    .reset_n        (reset_n)
    );

comma_detect_fsm
    comma_detect_fsm_inst (
    .symbol_start   (symbol_start_fsm),
    .symbol_locked  (symbol_locked),
    .dataword       (dataword),
    .dataword_ready (dataword_ready),
    .start_sync     (start_sync),
    .external_sync  (external_sync),
    .clk            (clk),
    .reset_n        (reset_n)
    );

endmodule


