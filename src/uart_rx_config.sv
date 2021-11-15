///////////////////////////////////////////////////////////////////
// File Name: uart_rx_config.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Simple UART receiver
//              Adapted from orignal design by Deepak Tala
//              Designed without oversampling (samples on falling edge)
//              Only works for single data rate input data
//              Input data should be launched on rising edge of clk
//              Clock should be forwarded to MADCAP
//              In other words, FPGA sending data to MADCAP must be synced
//              to MADCAP's clock
//
// If rx_empty is low then data is waiting. It should be read and then
// uld_rx_data should be asserted to enable rx for another reception.
//
//    Configuration Packet Definition
//
//  bit range     | contents
//    ------------------------
//     1:0        | packet declaration 
//                      00: LArPix configuration write
//                      00: LArPix configuration read 
//                      10: MADCAP configuration write 
//                      11: MADCAP configuration read
//     9:2        | chip id
//   17:10        | Register Address (LArPix or MADCAP) 
//   25:18        | Register Data (LArPix or MADCAP)
//   30:26        | MADCAP output port
//   31           | LArPix Broadcast 
//
//  Output format: packet is sent LSB-first, preceded by a start bit = 0
//  and ended by a stop bit = 1       
///////////////////////////////////////////////////////////////////

module uart_rx_config
    #(parameter WIDTH = 32)
    (output logic [WIDTH-1:0] rx_data,    // data received by UART
    output logic rx_empty,           // high if no data in rx
    input logic rx_in,               // input bit
    input logic uld_rx_data,         // transfer data to output (rx_data)
    input logic clk_rx,              // oversampling receiving clock
    input logic reset_n);            // digital reset (active low) 

// Internal Variables 
logic [WIDTH-1:0] rx_reg;
logic [7:0] rx_cnt;  
logic rx_d1;
logic rx_d2;
logic rx_busy;

// UART RX Logic
always_ff @ (negedge clk_rx or negedge reset_n) begin
    if (!reset_n) begin
        rx_reg <= 0; 
        rx_data <= 0;
        rx_cnt <= '0;;
        rx_empty <= 1'b1;
        rx_d1 <= 1'b1;
        rx_d2 <= 1'b1;
        rx_busy <= 1'b0;
    end else begin
        // Synchronize the asynch signal
        rx_d1 <= rx_in;
        rx_d2 <= rx_d1;
        // Unload the rx data
        if (uld_rx_data) begin
            rx_data  <= rx_reg[WIDTH-1:0];
            rx_empty <= 1'b1;
        end
        // Check if just received start of frame
        if (!rx_busy && !rx_d2) begin
            rx_busy <= 1'b1;
            rx_cnt <= 8'b0;
        end
        // Start of frame detected, Proceed with rest of data
        if (rx_busy) begin
            // Logic to sample at middle of data
            // makes sure we don't start based on runt start bit
            if ((rx_d2 == 1'b1) && (rx_cnt == 8'b0)) begin
                rx_busy <= 1'b0;
            end 
            else begin
                rx_cnt <= rx_cnt + 1'b1; 
                // Start storing the rx data
                if ((rx_cnt >= 8'd1) && (rx_cnt <= WIDTH)) begin
                    rx_reg[rx_cnt - 1'b1] <= rx_d2;
                end
                if ((rx_cnt > WIDTH)) begin
                    rx_busy <= 1'b0;
                    rx_empty <= 1'b0;
                    rx_data <= rx_reg[WIDTH-1:0];
                end
            end
        end 
    end
end // always_ff
endmodule


