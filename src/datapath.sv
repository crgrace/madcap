///////////////////////////////////////////////////////////////////
// File Name: datapath.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Datapath from PISO inputs to LVDS TX output
//     
//  Contains:
//      16 PISO RX UARTs
//      Event Router
//      32 deep 68-bit FIFO
//      CRC8 calculation (uses Maxim 1-wire polynomail x^8 + x^5 + x^4 + 1)
//      Packet Builder (makes 12-bytes super packets (data or idle) )
//      8b/10b encoder
//      Serializer (sends odd and even bit streams for later DDR mux)
//
//              Test Modes:
//              testmode[2:0] | Description
//             ------------------------------------
//              000     Normal operaton
//              001     Low-Frequency test Patter (K28.7 - K_F)
//              010     Mixed-Frequency test pattern (K28.5 - K_K)
//              011     High-Frequency test pattern (D21.5)
//              100     Alternate comma (K28.3 - K_A)
//              101     Alternate comma (K28.0 - K_R)
//              110     Modified RPAT (to stress channel) from IEEE802.3 
//              111     Test Packet (user must handle CRC generation)
//
//              Idle Packet:
//              Config half-full marker symbol  : K28.3 (K_A) 
//              Config full marker symbol       : K24.3 
//
//              Data Packet:
//              Config half-full marker symbol  : K29.7 (K_T) 
//              Config full marker symbol       : K28.4 (K_S)
//
//
//    
///////////////////////////////////////////////////////////////////

module datapath
    #(parameter WIDTH = 64,
    parameter NUMCHANNELS = 16,
    parameter FIFO_DEPTH = 32)
    (output logic dout_even,            // DDR even bits                 
    output logic dout_odd,              // DDR odd bits                 
    output logic dout_frame,            // high when LSB output
    output logic ack_fifo_data,         // high to ack config write to FIFO
    input logic piso [NUMCHANNELS-1:0], // input bits from PHYs
    input logic write_fifo_data_req,    // req to put data into FIFO
    input logic [4:0] config_fifo_cnt,  // FIFO usage when FIFO read
    input logic config_fifo_half,       // high if config fifo half full 
    input logic config_fifo_full,       // high if config fifo full  
    input logic which_fifo,             // 0 = config_fifo, 1 = data_fifo
    input logic [1:0] enable_fifo_panic,// high to insert fifo k-codes
    input logic [2:0] test_mode,        // specify test modes
    input logic [95:0] test_packet,     // test data to send to 8b10b 
    input logic [7:0] crc_input,        // CRC-8 hash of rx_data         
    input logic [5:0] chip_id,          // id for MADCAP  
    input logic bypass_8b10b,           // high to bypass 8b10 encoder
    input logic serializer_enable,      // high to enable 
    input logic enable_prbs7,           // high to enable PRBS7 
    input logic clk_core,               // 80 MHz primary clock
    input logic clk_rx,                 // 10 MHz rx uart sampling clock
    input logic reset_n);               // digital reset  (active low)

// internal signal declarations
logic [95:0] output_packet_96b;     // superpacket before 8b10b encoding
logic [119:0] output_packet_120b;   // superpacket after 8b10b encoding
logic [119:0] serializer_data_120b; // data sent to serializer
logic [WIDTH-1:0] rx_data [NUMCHANNELS-1:0]; // data from UART array
logic [WIDTH+3:0] channel_event_out;// data from event router
logic [WIDTH+3:0] fifo_out;         // data from FIFO (including chan id)
logic rx_empty [NUMCHANNELS-1:0];   // high if no data waiting
logic [NUMCHANNELS-1:0] read_rx;    // high to read rx uart 
logic [7:0] crc_word;               // CRC8 calculated from LArPix data
logic enable_8b10b;                 // enable 8b10b encoder 

// fifo signals
logic load_event_n;                 // low to put data in FIFO
logic rx_fifo_empty;                // high if FIFO empty
logic [5:0] rx_fifo_cnt;            // number of FIFO locations in use
logic [4:0] rx_fifo_cnt_minus_one;  // rebase fifo counter to start at 0
logic rx_fifo_full;                 // high if FIFO full
logic rx_fifo_half;                 // high if FIFO half full
logic get_fifo_data_n;              // low to read FIFO
logic packet_rcvd;                  // high to acknowledge packet rcvd  
logic load_serializer;              // high to load serializer
logic [11:0] k_in;                  // high if byte is intended as k-code
logic [3:0] channel_id;             // channel id from rx fifo

// submodule instantiation

// rebase fifo counter from 1 to 0
always_comb begin
    rx_fifo_cnt_minus_one = rx_fifo_cnt - 1'b1;
end // always_comb

// mux to allow 8b10b bypass
always_comb begin 
    if (bypass_8b10b) 
        serializer_data_120b = {24'haaaa_aa,output_packet_96b};
    else
        serializer_data_120b = output_packet_120b;
end // always_comb

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
    .channel_event_out      (channel_event_out),
    .read_rx                (read_rx),
    .load_event_n           (load_event_n),
    .ack_fifo_data          (ack_fifo_data),
    .input_events           (rx_data),
    .write_fifo_data_req    (write_fifo_data_req),
    .rx_empty               (rx_empty),
    .clk                    (clk_core),
    .reset_n                (reset_n)
    );

fifo_ff
    #(.FIFO_WIDTH(WIDTH+4),
    .FIFO_DEPTH(FIFO_DEPTH)
    )
    fifo_ff_inst        (
    .data_out           (fifo_out),
    .fifo_counter       (rx_fifo_cnt),
    .fifo_full          (rx_fifo_full),
    .fifo_half          (rx_fifo_half),
    .fifo_empty         (rx_fifo_empty),
    .data_in            (channel_event_out),
    .read_n             (get_fifo_data_n),
    .write_n            (load_event_n),
    .reset_n            (reset_n)
    );

crc
    crc_inst            (
    .crc_in             (8'h00),
    .data_in            (fifo_out[67:4]),
    .crc_out            (crc_word)
    );

datapath_fsm
    datapath_fsm_inst   (
    .packet_rcvd        (packet_rcvd),
    .get_fifo_data_n    (get_fifo_data_n),
    .load_serializer    (load_serializer),
    .build_data         (build_data),
    .build_k            (build_k),
    .rx_fifo_empty      (rx_fifo_empty),
    .clk                (clk_core),
    .reset_n            (reset_n)
    );
    
data_packet_builder
    data_packet_builder_inst (
    .output_packet      (output_packet_96b),  
    .k_in               (k_in),
    .enable_8b10b       (enable_8b10b),
    .rx_data            (fifo_out[67:4]),
    .channel_id         (fifo_out[3:0]),
    .chip_id            (chip_id),
    .packet_rcvd        (packet_rcvd),
    .rx_fifo_cnt        (rx_fifo_cnt_minus_one),
    .config_fifo_cnt    (config_fifo_cnt),
    .which_fifo         (which_fifo), 
    .enable_fifo_panic  (enable_fifo_panic),
    .config_fifo_half   (config_fifo_half),
    .config_fifo_full   (config_fifo_full),
    .build_data         (build_data),
    .build_k            (build_k),
    .test_mode          (test_mode),
    .test_packet        (test_packet),
    .crc_word           (crc_word),
    .clk                (clk_core),
    .reset_n            (reset_n)
    );

encode96b120b 
    encode96b120b_inst (
    .clk                (clk_core),
    .reset_n            (reset_n),
    .enable             (enable_8b10b),
    .data_in            (output_packet_96b),
    .k_in               (k_in),
    .data120b           (output_packet_120b)
    );

serializer_ddr
    #(.WIDTH(120))
    serializer_ddr_inst     (
    .dout_even          (dout_even),
    .dout_odd           (dout_odd),
    .dout_frame         (dout_frame),
    .din                (serializer_data_120b),
    .enable             (serializer_enable),
    .enable_prbs7       (enable_prbs7),
    .load               (load_serializer),
    .clk                (clk_core),
    .reset_n            (reset_n)
    );


endmodule
  

    
