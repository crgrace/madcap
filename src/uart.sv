///////////////////////////////////////////////////////////////////
// File Name: uart.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: UART module.  
//         Includes TX UART for sending events and config data off chip.
//         Includes RX UART for receiving events and config data.
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
//
//  Output format: packet is sent LSB-first, preceded by a start bit = 0
//  and followed by a stop bit = 1    
///////////////////////////////////////////////////////////////////

module uart
    #(parameter WIDTH = 64,    // width of packet (w/o start & stop bits) 
    parameter FIFO_BITS = 11)
    (output logic [WIDTH-1:0] rx_data, // data from RX UART
    output logic rx_empty,   // high if no data in rx
    output logic tx_out,     // TX UART output bit
    output logic tx_busy,        // high when tx uart sending data
    input logic rx_in,           // RX UART input bit
    input logic uld_rx_data,     // transfer data to output (rx_data)
    input logic [WIDTH-1:0] fifo_data,// fifo data to be tx off-chip
    input logic [31:0] timestamp_32b, // 32b timestamp
    input logic ld_tx_data,     // high to transfer data to tx uart
    input logic rx_enable,      // high to enable RX UART
    input logic tx_enable,      // high to enable TX UART
    input logic enable_fifo_diagnostics, // high to embed fifo counts
    input logic enable_packet_diagnostics, //high to embed bad packet counts
    input logic [FIFO_BITS:0] fifo_counter,  // current shared fifo count
    input logic [15:0] total_packets,  // total packets received count
    input logic clk,     // 2X oversampling receiving clock
    input logic reset_n);  // digital reset  (active low)

  
// internal nets
logic [WIDTH-1:0] uart_tx_data; // data to send off chip through uart
logic parity_error; // high if parity wrong. Don't do anything.

// output assignments

always_comb begin
    if (enable_fifo_diagnostics)
        uart_tx_data = {fifo_data[63:44],fifo_counter,fifo_data[31:0]};
    else if (enable_packet_diagnostics)
        uart_tx_data ={fifo_data[63:60],total_packets[1:0],fifo_data[57:0]};
    else 
        uart_tx_data = fifo_data;
    //    uart_tx_data = {~^fifo_data,fifo_data};
end // always_comb        

// transmits off chip
uart_tx 
    #(.WIDTH(WIDTH)
    ) uart_tx_inst (
    .tx_out         (tx_out),
    .tx_busy        (tx_busy),
    .tx_data        (uart_tx_data),
    .ld_tx_data     (ld_tx_data),
    .clk            (clk),
    .tx_enable      (tx_enable),
    .reset_n        (reset_n)
    );

// receives from previous chip/fpga
//explicit ICG model
gate_posedge_clk 
    ICGP(.ENCLK(clk_gated),
    .EN(rx_enable),
    .CLK(clk)
    );

uart_rx
    #(.WIDTH(WIDTH)
    ) uart_rx_inst (
    .rx_data        (rx_data[WIDTH-1:0]),
    .rx_empty       (rx_empty),
    .parity_error   (parity_error),
    .rx_in          (rx_in),
    .uld_rx_data    (uld_rx_data),
    .clk            (clk_gated),
    .reset_n        (reset_n)
    );

endmodule



