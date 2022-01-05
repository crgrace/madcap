///////////////////////////////////////////////////////////////////
// File Name: uart_array_rx.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Array of 16 UART RX modules.
//         Implements PISO data connections from LArPix to MADCAP  
//
//    Packet Definition
//
//  bit range     | contents
//  --------------------------
//     1:0        | packet declaration (00: data, 01: test.
//                    10: configuration write, 11: configuration read)
//     9:2        | chip id
//   15:10        | channel id
//   47:16        | 32-bit time stamp
//   55:48        | 8-bit ADC data word
//   57:56        | trigger type (00: normal, 01: external, 10: cross, 
//                    11: periodic)
//   59:58        | local FIFO status (58: fifo half full,59: fifo full)
//   61:60        | shared FIFO status (60: fifo half full, 61: fifo full)
//   62           | downstream marker bit (1 if packet is downstream)
//   63           | odd parity bit
//
//  Output format: packet is sent LSB-first, preceded by a start bit = 0
//  and followed by a stop bit = 1    
///////////////////////////////////////////////////////////////////

module uart_array_rx
    #(parameter WIDTH = 64,     // width of packet (w/o start & stop bits)
    parameter NUMCHANNELS = 16) // number of RX UARTs in array
    
    (output logic [WIDTH-1:0] rx_data [NUMCHANNELS-1:0], // output data
    output logic rx_empty [NUMCHANNELS-1:0], // high if no data waiting
    input logic rx_in [NUMCHANNELS-1:0], // input bits from PHYs
    input logic uld_rx_data[NUMCHANNELS-1:0], // xfer data to output
    input logic v3_mode,    // high for v3 mode (no oversampling)
    input logic clk_rx,     // receive clock
    input logic reset_n);   // digital reset  (active low)

// instantiate RX UART sub-blocks
genvar i;
generate
    for (i=0; i<NUMCHANNELS; i=i+1) begin : RX_CHANNELS

        uart_rx
            #(.WIDTH(WIDTH)
            )
            uart_rx_inst (
            .rx_data        (rx_data[i]),
            .rx_empty       (rx_empty[i]),
            .parity_error   (),
            .rx_in          (rx_in[i]),
            .uld_rx_data    (uld_rx_data[i]),
            .v3_mode        (v3_mode),
            .clk_rx         (clk_rx),
            .reset_n        (reset_n)
        );
    end
endgenerate   

endmodule 
