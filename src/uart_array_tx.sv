///////////////////////////////////////////////////////////////////
// File Name: uart_array_tx.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Array of 16 UART TX modules.
//         Implements POSI data connections from MADCAP to Tile 
//          Sends configuration packetes to LArPix (no data packets) 
//
//    Packet Definition
//
//  bit range     | contents
//  --------------------------
//     1:0        | packet declaration (00: data, 01: test.
//                    10: configuration write, 11: configuration read)
//     9:2        | chip id
//   17:10        | register map address
//   25:18        | register map data
//   61:26        | all zeros
//   62           | downstream marker bit (always zero here)
//   63           | odd parity bit
//
//  Output format: packet is sent LSB-first, preceded by a start bit = 0
//  and followed by a stop bit = 1    
///////////////////////////////////////////////////////////////////

module uart_array_tx
    #(parameter WIDTH = 64,     // width of packet (w/o start & stop bits)
    parameter NUMCHANNELS = 16) // number of RX UARTs in array
    
    (output logic tx_out [NUMCHANNELS-1:0],  // TX UART output bit
    output logic tx_busy [NUMCHANNELS-1:0],  // high when sending data
    input logic [WIDTH-1:0] tx_data [NUMCHANNELS-1:0], // data to be sent  
    input logic ld_tx_data [NUMCHANNELS-1:0],// high to xfer data to UART
    input logic tx_enable [NUMCHANNELS-1:0], // high to enable TX UART   
    input logic clk_tx,     // 5 MHz UART TX clock
    input logic reset_n);  // digital reset  (active low)

// instantiate TX UART sub-blocks
genvar i;
generate
    for (i=0; i<NUMCHANNELS; i=i+1) begin : TX_CHANNELS

        uart_tx_mc
            #(.WIDTH(WIDTH)
            )
            uart_tx_inst (
            .tx_out     (tx_out[i]),
            .tx_busy    (tx_busy[i]),
            .tx_data    (tx_data[i]),
            .ld_tx_data (ld_tx_data[i]),
            .clk_tx     (clk_tx),
            .tx_enable  (tx_enable[i]),
            .reset_n    (reset_n)          
        );
    end
endgenerate   

endmodule 
