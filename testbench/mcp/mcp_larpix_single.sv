///////////////////////////////////////////////////////////////////
// File Name: mcp_larpix_single.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description:     LArPix Master Control Program
//                  Captures functionality of FPGA-based master interface
//                  Programs LArPix and reads out data
//                  This version is to simulate a single LArPix.
//
///////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module mcp_larpix_single
    #(parameter WIDTH = 64,
    parameter WORDWIDTH = 8,
    parameter REGNUM = 256,
    parameter FIFO_DEPTH = 512
    ) 
    (output logic posi,       // PRIMARY OUT, SECONDARY IN (input of larpix from FPGA)
    output real charge_in_r [63:0], 
    output logic clk,       // 4x oversampled clock sent to larpix 
    output logic reset_n,     // digital reset (active low)
    input piso);            // PRIMARY IN, SECONDARY OUT (output of larpix to FPGA) 


// scoreboard
localparam SCOREBOARDSIZE = 100;
integer debug;
integer eventCount; // number of events digitized and written to scoreboard
integer scoreBoardCount; // number of events currently unmatched in scoreboard
logic [63:0] scoreBoard [SCOREBOARDSIZE-1:0]; // elements in scoreboard
                                // this should be linked list

logic ld_tx_data;
logic [WIDTH-1:0] data_to_larpix; // sent to DUT from FPGA
logic [WIDTH-2:0] data_from_larpix; // received by FPGA from DUT
logic [WIDTH-2:0] sent_data;
logic [WIDTH-2:0] receivedData;

//          clock speeds relative to clk_core
//  clk_ctrl    clk_rx    clk_tx note
//      00         1       1/2      core_clock is 2X to tx clock
//      01         1/2       1/4    core_clock is 4X tx clock
//      10         1/4       1/8    core_clock is 8X tx clock
//      11         1/8       1/16   core_clock is 16X tx clock

logic clk_master;
logic posi_predelay;
//logic [1:0] clk_ctrl; // clock config
logic clk_rx;
logic clk_tx;
logic [7:0] chip_id;      // unique id for each chip
logic [7:0] chip_id1;      // unique id for each chip
logic [7:0] chip_id2;      // unique id for each chip
//logic [7:0] chip_id3;      // unique id for each chip
logic [63:0] sentTag;     // tagged input signal to scoreboard
logic [63:0] packetNumber;     // tagged input signal to scoreboard
//logic [63:0] chargeSignal;
logic local_reset_n;
// control FPGA rx uart
logic uld_rx_data;
//logic [1:0] uart_op;
logic rx_empty;
logic tx_busy;

// parse rx data
logic [1:0] rcvd_packet_declare;
logic [7:0] rcvd_chip_id;
logic [5:0] rcvd_channel_id;
logic [31:0] rcvd_time_stamp;
logic [7:0] rcvd_data_word;
logic [1:0] rcvd_trigger_type;
logic [7:0] rcvd_regmap_data;
logic [7:0] rcvd_regmap_addr;
logic [10:0] rcvd_fifo_cnt;
logic [2:0] rcvd_local_fifo_cnt;
logic rcvd_downstream_marker_bit;
logic rcvd_fifo_half_bit;
logic rcvd_fifo_full_bit;
logic rcvd_local_fifo_half_bit;
logic rcvd_local_fifo_full_bit;
logic parity_error;
logic [1:0] local_clk_ctrl; // keep track of what LArPix clock is doing

always_comb begin
    rcvd_packet_declare = receivedData[1:0];
    rcvd_chip_id = receivedData[9:2];
    rcvd_channel_id = receivedData[15:10];
    rcvd_time_stamp = receivedData[47:16];
    rcvd_local_fifo_cnt = receivedData[46:44];
    rcvd_fifo_cnt = receivedData[43:32];
    rcvd_data_word = receivedData[55:48];
    rcvd_trigger_type = receivedData[57:56];
    rcvd_fifo_half_bit = receivedData[58];
    rcvd_fifo_full_bit = receivedData[59];
    rcvd_local_fifo_half_bit = receivedData[60];
    rcvd_local_fifo_full_bit = receivedData[61];
    rcvd_downstream_marker_bit = receivedData[62];

    rcvd_regmap_addr = receivedData[17:10];
    rcvd_regmap_data = receivedData[25:18];
end


parameter WRITE_TO_LOG = 0;     // high to write verification results to file
parameter NUMTRIALS_REGMAP = 100; // number of random REGMAP trials to run
parameter TEST_BURST_SIZE = 20;     // number of values to load into fifo
parameter GLOBAL_ID = 255;          // global broadcast ID
                                // during uart burst test
//`include "./input/testbench/larpix_tasks/larpix_tasks_top.sv"
//`include "larpix_tasks_top.sv"
`include "larpix_constants.sv"
`include "uart_tasks.sv"

always begin
    posi = #1 posi_predelay;
end

always_comb begin
    clk_rx = larpix_single_tb.larpix_v2c_inst.digital_core_inst.clk_rx;
    clk_tx = larpix_single_tb.larpix_v2c_inst.digital_core_inst.clk_tx;
    clk = clk_master;
end

initial begin
    for (int i = 0; i < 64; i++) begin
        charge_in_r[i] = 0.0;
    end
    local_clk_ctrl = 0;
    debug = TRUE;
    sentTag = 0;
    packetNumber = 0;
    //clk_ctrl = 2'b00;
//  debug = FALSE;
    ld_tx_data = 0;
    data_to_larpix = 0;
    eventCount = 0;
    scoreBoardCount = 0;
    chip_id = 8'b0000_0000; // chip ID is 0
    chip_id1 = 8'b0001_0000; // chip ID is 16
    chip_id2 = 8'b0001_1111; // chip ID is 31
    receivedData = 0;
    uld_rx_data = 0;
    clk_master = 0;
    reset_n = 1;
    local_reset_n = 1;
    #25
    @(posedge clk) 
    reset_n = 0;
    local_reset_n = 0;
    #3500
    //@(negedge clk) 
    @(posedge clk) 
       reset_n = 1;
     //#3   reset_n = 1;
    local_reset_n = 1;
	#1000
    @(posedge clk) 
    reset_n = 0;
    local_reset_n = 0;
    #3500
    //@(negedge clk) 
    @(posedge clk) 
       reset_n = 1;
     //#3   reset_n = 1;
    local_reset_n = 1;
    $display("RESET COMPLETE");
//    #1000

// send word to register 1 of chip 1
    @(posedge clk)



// function def:
//    sendWordToLarpix(op,chip_id,register,value);

//`include "lightpix_debug.mcp"
//`include "hydra_broadcast_read.mcp"

//`include "./testbench/mcp/config_test.mcp"
//`include "config_test.mcp"

//`include "hardwired_test.mcp"
//`include "ext_trig.mcp"
//`include "ext_trig_short.mcp"
//`include "ext_trig_debug.mcp"
//`include "fifo_debug.mcp"
//`include "per_trig_debug.mcp"
//`include "burst_debug.mcp"
`include "sanity_check.mcp"
//`include "single_larpix.mcp"
//`include "./testbench/mcp/single_larpix.mcp"
//`include "larpix_minimal.mcp"
// `include "hydra_larpix.mcp"
//   #25000 $display("TEST RESET SYNC");
//    #25 reset_n = 0;
//    local_reset_n = 0;
//   #20000 reset_n = 1;
//    local_reset_n = 1;

//#20000000 
//$finish;

end //initial


initial begin
    clk_master = 0;
    #50 clk_master = 1;
    forever #50 clk_master = ~clk_master;
end 



// read out FPGA received UART
always @(negedge rx_empty) begin
//    #20
    @(posedge clk_tx);
    uld_rx_data = 1;
    @(posedge clk_tx);
    //#100
    receivedData = data_from_larpix;
    packetNumber++;
//    #20 
    @(posedge clk_tx);
    uld_rx_data = 0;
end

always @(negedge uld_rx_data) begin
    #10
    $display("\n--------------------");
    $display("\nData Received: %h",receivedData);
    $display("Packet Number: %0d",packetNumber);
    if (parity_error) $display("ERROR: PARITY BAD");
    else $display("Parity good.");
    case(rcvd_packet_declare)
        0 : begin
                $display("data packet");
                $display("Chip ID = %d",rcvd_chip_id);
                $display("Channel ID = %d",rcvd_channel_id);
                $display("time stamp (hex) = %h",rcvd_time_stamp);
                $display("local fifo counter (if configured) = %d",rcvd_local_fifo_cnt);
                $display("fifo counter (if configured) = %d",rcvd_fifo_cnt);
                $display("data word = %d",rcvd_data_word);
                case(rcvd_trigger_type) 
                    2'b00 : $display("trigger_type = NATURAL");
                    2'b01 : $display("trigger_type = EXTERNAL");
                    2'b10 : $display("trigger_type = CROSS");
                    2'b11 : $display("trigger_type = PERIODIC");
                endcase 
              //  $display("trigger_type = %d", rcvd_trigger_type);
                $display("shared fifo half bit = %d",rcvd_fifo_half_bit);
                $display("shared fifo full bit = %d",rcvd_fifo_full_bit);
                $display("local fifo half bit = %d",rcvd_local_fifo_half_bit);
                $display("local fifo full bit = %d",rcvd_local_fifo_full_bit);
                $display("downstream marker bit = %d",rcvd_downstream_marker_bit);
            end
        1 : begin
                $display("test packet");
                $display("Chip ID = %d",rcvd_chip_id);
                $display("Channel ID = %d",rcvd_channel_id);
                $display("time stamp (hex) = %h",rcvd_time_stamp);
                $display("local fifo counter (if configured) = %d",rcvd_fifo_cnt);
                $display("fifo counter (if configured) = %d",rcvd_fifo_cnt);
                $display("data word = %d",rcvd_data_word);
                $display("trigger_type = %d", rcvd_trigger_type);
                $display("fifo half bit = %d",rcvd_fifo_half_bit);
                $display("fifo full bit = %d",rcvd_fifo_full_bit);
                $display("local fifo half bit = %d",rcvd_local_fifo_half_bit);
                $display("local fifo full bit = %d",rcvd_local_fifo_full_bit);
                $display("marker bit = %d",rcvd_downstream_marker_bit);
            end
        2 : begin
                $display("configuration write");
                $display("Chip ID = %d",rcvd_chip_id);
                $display("register map address = %d",rcvd_regmap_addr);
                $display("register map data = %d",rcvd_regmap_data);
                $display("fifo half bit = %d",rcvd_fifo_half_bit);
                $display("fifo full bit = %d",rcvd_fifo_full_bit);
                $display("local fifo half bit = %d",rcvd_local_fifo_half_bit);
                $display("local fifo full bit = %d",rcvd_local_fifo_full_bit);
               $display("marker bit = %d",rcvd_downstream_marker_bit);
            end
        3 : begin
                $display("configuration read");
                $display("Chip ID = %d",rcvd_chip_id);
                $display("register map address = %d",rcvd_regmap_addr);
                $display("register map data = %d",rcvd_regmap_data);
                $display("fifo half bit = %d",rcvd_fifo_half_bit);
                $display("fifo full bit = %d",rcvd_fifo_full_bit);
                $display("local fifo half bit = %d",rcvd_local_fifo_half_bit);
                $display("local fifo full bit = %d",rcvd_local_fifo_full_bit);
               $display("marker bit = %d",rcvd_downstream_marker_bit);
            end
    endcase
    $display("\n--------------------\n");
end // always



// add to scoreboard when new data generated

always @(sentTag) begin
    scoreBoard[eventCount] = sentTag;
    eventCount = eventCount + 1;
    scoreBoardCount = scoreBoardCount + 1;
    if (debug) begin
        $display("event %h written to scoreboard at time %0d",sentTag,$time);
        $display("currently %0d events digitized",eventCount);
        $display("currently %0d events in scoreboard",scoreBoardCount);
    end
end // always

// check scoreboard when new data packet is received
always @(receivedData) begin
    // make sure this is a data packet, otherwise ignore
//    if (debug) $display("PACKET RECEIVED");
    if (rcvd_packet_declare == 0) begin
        // make tag to compare with data in scoreboard
 //       for (i = 0; i < eventCount; eventCount = eventCount + 1) begin
 //       $display("DATA RECEIVED");
 //       end // for
    end // if
end // always
 
// This UART instance models the programming FPGA
uart_tx_fpga 
    #(.WIDTH(WIDTH)
    ) uart_tx_inst (
    .tx_out         (posi_predelay),
    .tx_busy        (tx_busy),
    .tx_powerdown   (),
    .tx_data        (data_to_larpix),
    .ld_tx_data     (ld_tx_data),
    .tx_enable      (1'b1), 
    .enable_tx_dynamic_powerdown (1'b0),
    .tx_dynamic_powerdown_cycles (3'b0), 
    .reset_n        (local_reset_n),
    .txclk          (clk_tx)
);

// UART RX for testing TX here (this is in the receive FPGA)
uart_rx_fpga
    #(.WIDTH(WIDTH)
    ) uart_rx_inst  (
    .reset_n        (local_reset_n),
    .clk_rx         (clk_rx),
    .uld_rx_data    (uld_rx_data),
    .rx_data        (data_from_larpix),
    .rx_in          (piso),
    .v3_mode        (1'b0),
    .rx_empty       (rx_empty),
    .parity_error   (parity_error)
);



endmodule   
