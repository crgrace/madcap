`timescale 1ns/1ps

module event_router_tb();

localparam WIDTH = 64;
localparam NUMCHANNELS = 16;
localparam FIFO_DEPTH = 32;
logic reset_n;
logic clk_fast;     // 80 MHz input clock
logic [WIDTH-2:0] rx_data [NUMCHANNELS-1:0]; // data received
logic [WIDTH-1:0] tx_data [NUMCHANNELS-1:0]; // data sent (pre serializer)
logic [WIDTH+3:0] channel_event_out;// routed event (pre-parity)
logic [WIDTH+3:0] fifo_out;// routed event output from FIFO (pre-parity)
logic [NUMCHANNELS-1:0] piso;
logic [NUMCHANNELS-1:0] tx_busy;  // not used yet
logic [NUMCHANNELS-1:0] tx_enable;  // not used yet
logic [15:0] read_rx;
logic [NUMCHANNELS-1:0] ld_tx_data; // high to xfer data to UART
logic clk_core;     // MADCAP core clock
logic clk_rx;       // 2x oversampling rx clock
logic clk_tx;       // slow tx clock
logic [15:0] rx_empty;
logic [63:0] larpix_packet [NUMCHANNELS-1:0];
// fifo signals
logic load_event_n;     // low to put data in FIFO
logic rx_fifo_empty;    // high if FIFO empty
logic [5:0] rx_fifo_counter;  // number of FIFO locations in use
logic rx_fifo_full;      // high if FIFO full
logic rx_fifo_half;      // high if FIFO half full
logic get_fifo_data_n;  // low to read FIFO

initial begin
    reset_n = 1;
    tx_enable = '1;
    clk_fast = 0;    
    ld_tx_data = '0;
    for (int i = 0; i < NUMCHANNELS; i++) begin
        larpix_packet[i] = {$urandom(),$urandom()};
    end // for
//    larpix_packet = {larpix_packet[63:0],larpix_packet[62:0]}; // parity
    #40 reset_n = 0;
    #35 reset_n = 1;
    #10 $display ("larpix_packet[2] = %h",larpix_packet[2]);
    for (int i = 0; i < NUMCHANNELS; i++) begin
        tx_data[i] = '0;
    end
    tx_data[0] = larpix_packet[0];   
    tx_data[2] = larpix_packet[2];   
    tx_data[15] = larpix_packet[15];
    #650 ld_tx_data[0] = 1;
    ld_tx_data[2] = 1;
    ld_tx_data[15] = 1;
    #100 ld_tx_data = '0; 
end // initial

initial begin
    forever begin   
        #6.25 clk_fast = ~clk_fast; // 80 MHz
    end
end // initial

uart_array_rx
    #(.WIDTH(WIDTH),
    .NUMCHANNELS(NUMCHANNELS)
    )
    uart_array_rx_inst (
    .rx_data        (rx_data),
    .rx_empty       (rx_empty),
    .rx_in          (piso),
    .uld_rx_data    (read_rx),
    .clk_rx         (clk_rx),
    .reset_n        (reset_n)
    );

event_router
    #(.WIDTH(WIDTH),
    .NUMCHANNELS(NUMCHANNELS)
    )
    event_router_inst   (
    .channel_event_out  (channel_event_out),
    .read_rx        (read_rx),
    .load_event_n   (load_event_n),
    .input_events   (rx_data),
    .rx_empty       (rx_empty),
    .clk            (clk_core),
    .reset_n        (reset_n)
    );

clk_manager
    clk_manager_inst (
    .clk_core       (clk_core),
    .clk_rx         (clk_rx),
    .clk_tx         (clk_tx),
    .clk_fast       (clk_fast),
    .reset_n        (reset_n)
    );

fifo_ff
    #(.FIFO_WIDTH(WIDTH+3),
    .FIFO_DEPTH(FIFO_DEPTH)
    )
    fifo_ff_inst        (
    .data_out           (fifo_out),
    .fifo_counter       (rx_fifo_counter),
    .fifo_full          (rx_fifo_full),
    .fifo_half          (rx_fifo_half),
    .fifo_empty         (rx_fifo_empty),
    .data_in            (channel_event_out),
    .read_n             (get_fifo_data_n),
    .write_n            (load_event_n),
    .reset_n            (reset_n)
    );

// tile model 
uart_array_tx
    #(.WIDTH(WIDTH),
    .NUMCHANNELS(NUMCHANNELS)
    )
    uart_array_tx_inst (
    .tx_out         (piso),
    .tx_busy        (tx_busy),
    .tx_data        (tx_data),
    .ld_tx_data     (ld_tx_data),
    .tx_enable      (tx_enable),
    .clk_tx         (clk_tx),
    .reset_n        (reset_n)
    );

endmodule
