///////////////////////////////////////////////////////////////////
// File Name: uart.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: UART module.  
//         Includes TX UART for sending events and config data off chip.
//         Includes RX UART for receiving events and config data.
//         Includes test mux.
//
//              in v2 mode:
//              RX should use a 2X oversampled clock relative to TX
//              in v3 mode:
//              RX should use same clock as TX
//
//    Packet Definition
//
//  bit range     | contents
//  --------------------------
//     1:0        | packet declaration (00: unused, 01: data,
//                    10: configuration write, 11: configuration read)
//     9:2        | chip id
//   15:10        | channel id
//   43:16        | 28-bit time stamp
//   44           | reset sample flag
//   45           | cds flag
//   55:46        | 10-bit ADC data word
//   57:56        | trigger type (00: normal, 01: external, 10: cross, 
//                    11: periodic)
//   59:58        | local FIFO status (58: fifo half full,59: fifo full)
//   61:60        | shared FIFO status (60: fifo half full, 61: fifo full)
//   62           | downstream marker bit (1 if packet is downstream)
//   63           | odd parity bit
//
//  In configuration mode:  [17:10] is register address
//                          [25:18] is register data
//                          [57:26] is magic number (0x89_50_4E_47)
//  Output format: packet is sent LSB-first, preceded by a start bit = 0
//  and followed by a stop bit = 1    
///////////////////////////////////////////////////////////////////

module uart
    #(parameter WIDTH = 64,    // width of packet (w/o start & stop bits) 
    parameter FIFO_BITS = 11)
    (output logic [WIDTH-2:0] rx_data, // data from RX UART
    output logic rx_empty,   // high if no data in rx
    output logic tx_out,     // TX UART output bit
    output logic tx_busy,        // high when tx uart sending data
    output logic tx_powerdown,  // high to power down TX PHY
    input logic rx_in,           // RX UART input bit
    input logic uld_rx_data,     // transfer data to output (rx_data)
    input logic v3_mode,            // high for v3 mode (no oversampling)
    input logic [1:0] test_mode,  
            // 00 = normal, 01 = PRBS5, 10 = UART, 11 = normal 
    input logic [WIDTH-2:0] fifo_data,// fifo data to be tx off-chip
    input logic [31:0] timestamp_32b, // 32b timestamp
    input logic ld_tx_data,     // high to transfer data to tx uart
    input logic rx_enable,      // high to enable RX UART
    input logic tx_enable,      // high to enable TX UART
    input logic enable_tx_dynamic_powerdown, // high to power down idle
    input logic [2:0] tx_dynamic_powerdown_cycles, // how many to wait
    input logic enable_fifo_diagnostics, // high to embed fifo counts
    input logic enable_packet_diagnostics, //high to embed bad packet counts
    input logic [FIFO_BITS:0] fifo_counter,  // current shared fifo count
    input logic [FIFO_BITS:0] bad_packets,  // bad packets received count
    input logic rxclk,     // 2X oversampling receiving clock
    input logic txclk,     // 5 MHz UART TX clock
    input logic reset_n,   // digital reset (active low)
    input logic reset_n_clk2x);  // digital reset  (active low)

localparam PRBS5 = 31'h6B3E3750;
  
// internal nets
logic [WIDTH-1:0] uart_tx_data; // data to send off chip through uart
logic [WIDTH-2:0] test_packet; // test packet to verify event decode
logic ld_tx_data_internal;
logic ld_prbs_data; 
logic parity_error; // high if parity wrong. Don't do anything.

// output assignments

always_comb begin
    test_packet = {timestamp_32b[30:0],timestamp_32b};
    ld_tx_data_internal = ld_tx_data | ld_prbs_data;
end

always_comb begin
    if (test_mode == 2'b00) begin
        if (enable_fifo_diagnostics)
            uart_tx_data = {~^{fifo_data[62:44],fifo_counter,fifo_data[31:0]},{fifo_data[62:44],fifo_counter,fifo_data[31:0]}};
        else if (enable_packet_diagnostics)
            uart_tx_data = {~^{fifo_data[62:44],bad_packets,fifo_data[31:0]},{fifo_data[62:44],bad_packets,fifo_data[31:0]}};
        else 
            uart_tx_data = {~^fifo_data,fifo_data};
        ld_prbs_data = 1'b0;
    end else if (test_mode == 2'b01) begin
        uart_tx_data = {2'b11,{PRBS5},{PRBS5}};
        ld_prbs_data = 1'b1;
    end else if (test_mode == 2'b10) begin
        uart_tx_data = {~^test_packet,test_packet};
        ld_prbs_data = 1'b1;
    end else if (test_mode == 2'b11) begin
        if (enable_fifo_diagnostics)
            uart_tx_data = {~^{fifo_data[62:44],fifo_counter,fifo_data[31:0]},{fifo_data[62:44],fifo_counter,fifo_data[31:0]}};
        else if (enable_packet_diagnostics)
            uart_tx_data = {~^{fifo_data[62:44],bad_packets,fifo_data[31:0]},{fifo_data[62:44],bad_packets,fifo_data[31:0]}};
        else 
            uart_tx_data = {~^fifo_data,fifo_data};
        ld_prbs_data = 1'b0;
    end
end // always_comb        

// transmits off chip
uart_tx 
    #(.WIDTH(WIDTH)
    ) uart_tx_inst (
    .tx_out                         (tx_out),
    .tx_busy                        (tx_busy),
    .tx_powerdown                   (tx_powerdown),
    .tx_data                        (uart_tx_data),
    .ld_tx_data                     (ld_tx_data_internal),
    .txclk                          (txclk),
    .tx_enable                      (tx_enable),
    .enable_tx_dynamic_powerdown    (enable_tx_dynamic_powerdown),
    .tx_dynamic_powerdown_cycles    (tx_dynamic_powerdown_cycles),
    .reset_n                        (reset_n)
    );

// receives from previous chip/fpga
//explicit ICG model
gate_posedge_clk 
    ICGP(.ENCLK(rxclk_gated),
    .EN(rx_enable),
    .CLK(rxclk)
    );

uart_rx
    #(.WIDTH(WIDTH)
    ) uart_rx_inst (
    .rx_data        (rx_data[WIDTH-2:0]),
    .rx_empty       (rx_empty),
    .parity_error   (parity_error),
    .rx_in          (rx_in),
    .uld_rx_data    (uld_rx_data),
    .v3_mode        (v3_mode),
    .clk_rx         (rxclk_gated),
    .reset_n        (reset_n_clk2x)
    );

endmodule



