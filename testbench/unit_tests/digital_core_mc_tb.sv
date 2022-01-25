///////////////////////////////////////////////////////////////////
// File Name: digital_core_mc_tb.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: SystemVerilog testbench for MADCAP digital core.
///////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "../testbench/tasks/k_codes.sv"
`include "../testbench/tasks/madcap_tasks_top.sv"
module digital_core_mc_tb();

localparam WIDTH = 10;
localparam REGNUM = 35;
localparam FIFO_DEPTH = 32;
localparam NUMTRIALS = 20;
localparam NUMCHANNELS = 16;
localparam NUMCOMMAS = 20;

// common signals

logic reset_n;
logic clk_fast;     // 80 MHz input clock

// signals to analog core
logic [3:0] clk_larpix;      // clocks to LArPix tiles
logic [3:0] reset_n_larpix;      // reset to LArPix tiles
logic [3:0] trigger_larpix;  // triggers to LArPix tiles
logic [4:0] ref_current_trim;// trims ref current
logic override_ref;          // high to enable external bandgap
logic ref_kickstart;         // active high kickstart bit
logic [3:0] current_monitor; // one hot monitor (see docs)
logic [7:0] voltage_monitor_refgen;  // one hot monitor 
logic [3:0] tx_slices;       // # of TX slices for POSI link
logic [3:0] i_tx_diff;       // TX bias current (diff)
logic [3:0] i_rx;            // RX bias current 
logic [4:0] rx_term;         // RX termination resistor
logic [2:0] v_cm_tx;         // TX CM (MADCAP to tile)
logic [3:0] i_tx_lvds_data;  // link from MADCAP to PACMAN
logic [3:0] i_lvds_rx;       // link from PACMAN to MADCAP
logic [3:0] i_cml_rst;       // bias current for rst drivers
logic [3:0] i_cml_clk;       // bias current for clk drivers
logic [3:0] i_cml_trigger;   // bias current for trigger drivers
logic pd_lvds_tx;            // pd LVDS from MADCAP to PACMAN
logic [3:0] pd_reset_n_drivers;  // pd rst drivers to LArPix tile
logic [3:0] pd_clk_drivers;  // pd clk drivers to LArPix tile
logic [3:0] pd_trigger_drivers;// pd trigger to LArPix tile
logic [15:0] pd_rx;          // pd rx from LArPix to MADCAP
logic [15:0] pd_tx;          // pd rx from MADCAP to LArPix

// LArPix to MADCAP datapath
logic [WIDTH-1:0] tx_data [NUMCHANNELS-1:0]; // data sent (pre serializer)
logic [119:0] dataword_120b; // deserialized data (before 8b10 decoding)
logic [95:0] dataword_96b;   // deserialized data (after 8b10 decoding)
logic [95:0] superpacket;   // final packet ready for analysis
logic [11:0] k_out;
logic [11:0] code_err;
logic [11:0] disp_err;
logic dout_even;
logic dout_odd;
logic dout; // DDR output
logic dout_frame;
logic new_dataword; // high to indicate new dataword available
logic [NUMCHANNELS-1:0] piso;
logic [NUMCHANNELS-1:0] posi;
logic [NUMCHANNELS-1:0] ld_tx_data; // high to xfer data to UART
logic simulation_done;          // high when simulation done
logic [NUMCHANNELS-1:0] tx_busy;  // not used yet
logic load_tx_data;
logic clk_tx;
logic which_fifo;

// PACMAN to MADCAP config path
logic load_serializer;
logic ready_to_load;
logic [15:0] tx_enable;
logic [3:0] serializer_cnt;
logic disp_out;             // 0 = neg disp; 1 = pos disp; not registered
logic disp_in;              // 0 = neg disp; 1 = pos disp
logic [39:0] upstream_packet; // from FPGA to MADCAP
logic dout_pacman;                 // serializer output (single bit)
logic [7:0] data_in8b;      // input to send to 8b10b encoder
logic [7:0] current_byte;   // byte selected from upstream pacet
logic [9:0] data_in10b;     // input to test serializer 
logic next_packet;          // high when ready for new packet
logic [2:0] which_byte;     // byte of packet being serialized
logic k_in;                 // high to indicate 8b symbol represents k-code
logic external_sync;        // high for external sync mode
logic start_sync;           // high to mark first bit in symbol
logic enable_8b10b;         // high to enable 8b10b encoder (for PACMAN)
logic bypass_8b10b_dec;     // high to bypass 8b10b decoders
logic bypass_8b10b_enc;     // high to bypass 8b10b encoders

// packet building
logic [1:0] packet_declaration;
logic [5:0] chip_id;
logic [7:0] regmap_address;
logic [7:0] regmap_data;
logic [25:0] larpix_packet;
logic [3:0] target_larpix;
logic sending_commas;
logic make_madcap_packet;
logic make_larpix_packet;

initial begin
/*
// temp:
    load_tx_data = '0;
    simulation_done = 0;
    bypass_8b10b_dec = 0;
    clk_tx = 0;
    which_fifo = 0;
// end temp
    packet_declaration = '0;
    chip_id = '0;
    regmap_address = '0;
    regmap_data = '0;
    larpix_packet = '0;
    target_larpix = '0;
    make_madcap_packet = 0;
    make_larpix_packet = 0;
    tx_enable = '0;
    clk_fast = 1'b0;
    external_sync = 1'b0;
    start_sync = 1'b0;
    bypass_8b10b_enc = 1'b0;
    #10 reset_n = 1'b0;
    #155 reset_n = 1'b1;
    // wait a while and then send a MADCAP regfile packet!'
`include "../mcp/test.mcp"
    #5000
    $display("Send first MADCAP packet");
    chip_id = 5'b0_0001;
    regmap_address = 8'h01;
    regmap_data = 8'hF3;
    packet_declaration = 2'b10; // MADCAP config write
    make_madcap_packet = 1;
    @upstream_packet;
    make_madcap_packet = 0;
    #1000
    $display("Readback first MADCAP config packet");
    regmap_address = 8'h01;
    regmap_data = '0;
    packet_declaration = 2'b11; // MADCAP config read
    make_madcap_packet = 1;
    @upstream_packet;
    make_madcap_packet = 0;
//    target_larpix = 4'h1;
//    larpix_packet = 26'h3_CE_01_8F;
//    packet_declaration = 2'b00;
//    #1000 make_larpix_packet = 1;
//    @upstream_packet;
//    make_larpix_packet = 0;]*/

`include "../mcp/setup_sim.mcp"
`include "../mcp/madcap_config_rw.mcp"

end // initial

// primary clock
initial begin
    forever begin   
        #10 clk_fast = ~clk_fast;
    end
end // initial

//// START CONFIG MODEL
/////////////// MODEL FOR DOWNSTREAM PACMAN CONTROLLER 
////////////// SENDS CONFIG INFORMATION TO MADCAP
always_comb
    if (serializer_cnt == 4'b0010)
        ready_to_load = 1'b1;
    else
        ready_to_load = 1'b0;

// load serializer counter
always_ff @(posedge clk_fast or negedge reset_n) begin
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

always_comb begin
    case (which_byte)
        3'b000 : current_byte = upstream_packet[7:0];
        3'b001 : current_byte = upstream_packet[15:8];
        3'b010 : current_byte = upstream_packet[23:16];
        3'b011 : current_byte = upstream_packet[31:24];
        3'b100 : current_byte = upstream_packet[39:32];
        default: current_byte = '0;
    endcase
end // always_comb

always_comb begin
    if ( (sending_commas) || (which_byte == 3'b000) ) begin 
        k_in = 1'b1;
    end
    else begin
        k_in = 1'b0;
    end
end // always_comb
// create next packet
always_ff @(posedge clk_fast or negedge reset_n) begin
    if (!reset_n) begin
        next_packet <= 1'b0;
        which_byte <= 3'b000;
        upstream_packet <= '0;
        enable_8b10b <= 1'b0;
        sending_commas <= 1'b0;
    end
    else begin
        enable_8b10b <= 1'b0;
        if (serializer_cnt == 4'b0100) begin // update a few clocks early
               enable_8b10b <= 1'b1;
            if (which_byte == 3'b100) begin
                next_packet <= 1'b1;
                which_byte <= 3'b00;
                if (make_madcap_packet) begin
                    sending_commas <= 1'b0;
                    upstream_packet <= create_madcap_packet(
                                    packet_declaration,
                                    chip_id,
                                    regmap_address,
                                    regmap_data);
                end
                else if (make_larpix_packet) begin
                    sending_commas <= 1'b0;
                    upstream_packet <= create_larpix_packet(
                                    packet_declaration,
                                    larpix_packet,
                                    target_larpix);
                end
                else begin
                    upstream_packet <= create_comma_packet(); 
                    sending_commas <= 1'b1;
                end
            end
            else begin
                next_packet <= 1'b0;
                which_byte <= which_byte + 1'b1;
            end
        end
    end
end

// update input to 8b10b a few clock cycles before the serializer is ready
always_ff @(posedge clk_fast or negedge reset_n) begin
    if (!reset_n)
        data_in8b <= '0;
    else
        if (serializer_cnt == 4'b0111)
            data_in8b <= current_byte;
end // always_ff

// 8b10b encoder disparity flip-flop 
always_ff @(posedge clk_fast or negedge reset_n)
  if (!reset_n)
    disp_in <= 1'b0; // initialize disparity
  else
    if (enable_8b10b)
        disp_in <= disp_out;

// 8b10b encoder 
encode8b10b
    encode8b10_inst (
    .clk        (clk_fast),
    .reset_n    (reset_n),
    .data_in    (data_in8b),    
    .k_in       (k_in),
    .data_out   (data_in10b),
    .disp_in    (disp_in),
    .disp_out   (disp_out)
    );


// behavioral serializer
serializer_sdr
    #(.WIDTH(WIDTH))
    serializer_inst (
    .dout           (dout_pacman),
    .dout_symbol    (symbol_start),
    .din            (data_in10b),
    .enable         (1'b1),
    .load           (load_serializer),
    .clk            (clk_fast),
    .reset_n        (reset_n)
    );
///// END PACMAN CONFIG MODEL

//// START DATAPATH MODEL
/// START tile model:
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
// END tile mode

// START PACMAN data rx 
// behavioral double datarate deserializer
deserializer_ddr
    #(.WIDTH(120))
    deserializer_ddr_inst (
    .dataword       (dataword_120b),
    .new_dataword   (new_dataword),
    .din            (dout),
    .frame_start    (dout_frame),
    .clk            (clk_fast),
    .reset_n        (reset_n)
    );

// decode deserialized data words
decode96b120b
    decode96b120b_inst (
    .datain                 (dataword_120b),
    .clk                    (clk_fast),
    .reset_n                (reset_n),
    .dataout                (dataword_96b),
    .k_out                  (k_out),
    .code_err               (code_err),
    .disp_err               (disp_err)
    );

// mux to bypass 8b10b decoder
always_comb begin
    if (bypass_8b10b_enc) 
        superpacket = dataword_120b[95:0];
    else
        superpacket = dataword_96b;
end // always_comb
// END PACMAN data rx


// START output mux
output_mux  
    output_mux_inst (
    .dout       (dout),
    .dout_even  (dout_even),
    .dout_odd   (dout_odd),
    .clk        (clk_fast)
    );
// END output mux

// START PACMAN analysis
// analysis
analyze_superpacket
    analyze_superpacket_inst (
    .superpacket            (superpacket),
    .new_superpacket        (new_dataword),
    .which_fifo             (which_fifo),
    .k_out                  (k_out),
    .bypass_8b10b_enc       (bypass_8b10b_enc),
    .simulation_done        (simulation_done)
    );
// END PACMAN analysis
// END DATAPATH model

// DUT connected here   
digital_core_mc
    #(.NUMCHANNELS(NUMCHANNELS),
    .REGNUM(REGNUM),
    .FIFO_DEPTH(FIFO_DEPTH))
    digital_core_mc_inst (
    .dout_even              (dout_even),
    .dout_odd               (dout_odd),
    .dout_frame             (dout_frame),
    .posi                   (posi),
    .clk_larpix             (clk_larpix),
    .reset_n_larpix         (reset_n_larpix),
    .trigger_larpix         (trigger_larpix),
    .ref_current_trim       (ref_current_trim),
    .override_ref           (override_ref),
    .ref_kickstart          (ref_kickstart),
    .current_monitor        (current_monitor),
    .voltage_monitor_refgen (voltage_monitor_refgen),
    .tx_slices              (tx_slices),
    .i_tx_diff              (i_tx_diff),
    .i_rx                   (i_rx),
    .rx_term                (rx_term),
    .v_cm_tx                (v_cm_tx),
    .i_tx_lvds_data         (i_tx_lvds_data),
    .i_lvds_rx              (i_lvds_rx),
    .i_cml_rst              (i_cml_rst),
    .i_cml_clk              (i_cml_clk),
    .i_cml_trigger          (i_cml_trigger),
    .pd_lvds_tx             (pd_lvds_tx),
    .pd_reset_n_drivers     (pd_reset_n_drivers),
    .pd_clk_drivers         (pd_clk_drivers),
    .pd_trigger_drivers     (pd_trigger_drivers),
    .pd_rx                  (pd_rx),
    .pd_tx                  (pd_tx),
    .piso                   (piso),
    .lvds_rx_bit            (dout_pacman),
    .external_sync          (external_sync),
    .start_sync             (start_sync),
    .clk_fast               (clk_fast),
    .reset_n                (reset_n)
    );

endmodule 
