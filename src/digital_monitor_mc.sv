///////////////////////////////////////////////////////////////////
// File Name: digital_monitor_mc.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Muxes various digital outputs and triggers 
//              to the digital monitor port for debugging and
//              chip characterization purposes. MADCAP version.
///////////////////////////////////////////////////////////////////

module digital_monitor_mc
    (output logic digital_monitor,      // monitor port
    input logic digital_monitor_enable, // high to enable output
    input logic [4:0] digital_monitor_select,
    input logic symbol_locked,
    input logic comma_found,
    input logic lp_trigger_found,
    input logic lp_soft_rst_found,
    input logic lp_hard_rst_found,
    input logic lp_timestamp_rst_found,
    input logic mc_rst_found,
    input logic lp_rst_out,
    input logic lp_trigger_out,
    input logic reset_n_config_sync,
    input logic clk_fast,
    input logic clk_rx,
    input logic clk_tx,
    input logic clk_core,
    input logic write_fifo_data_req,
    input logic ack_fifo_data,
    input logic packet_rcvd,
    input logic load_serializer,
    input logic rx_fifo_empty,
    input logic load_event_n,
    input logic enable_8b10b);

// output mux
always_comb begin
    if (digital_monitor_enable) begin
        case (digital_monitor_select)
            5'b00000 : digital_monitor = symbol_locked;
            5'b00001 : digital_monitor = comma_found;
            5'b00010 : digital_monitor = lp_trigger_found;
            5'b00011 : digital_monitor = lp_soft_rst_found;
            5'b00100 : digital_monitor = lp_hard_rst_found;
            5'b00101 : digital_monitor = lp_timestamp_rst_found;
            5'b00110 : digital_monitor = mc_rst_found;
            5'b00111 : digital_monitor = lp_rst_out;
            5'b01000 : digital_monitor = lp_trigger_out;
            5'b01001 : digital_monitor = reset_n_config_sync;
            5'b01010 : digital_monitor = clk_fast;
            5'b01011 : digital_monitor = clk_rx;
            5'b01100 : digital_monitor = clk_tx;
            5'b01101 : digital_monitor = clk_core;
            5'b01110 : digital_monitor = write_fifo_data_req;
            5'b01111 : digital_monitor = ack_fifo_data;
            5'b10000 : digital_monitor = packet_rcvd;
            5'b10001 : digital_monitor = load_serializer;
            5'b10010 : digital_monitor = rx_fifo_empty;
            5'b10011 : digital_monitor = load_event_n;
            5'b10100 : digital_monitor = enable_8b10b;
            default : digital_monitor = 1'b0;
        endcase 
    end
    else begin
        digital_monitor = 1'b0;
    end
end // always_comb
      
endmodule      
