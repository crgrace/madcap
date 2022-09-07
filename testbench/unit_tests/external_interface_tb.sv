`timescale 1ns/10ps
//
module external_interface_tb();

// parameters
parameter WIDTH = 64;
parameter WORDWIDTH = 8;
parameter REGMAP_ADDR_WIDTH = 8;
parameter REGNUM = 248; 
parameter FIFO_DEPTH = 16;
parameter CHIP_ID_W = 8;
localparam FIFO_BITS = $clog2(FIFO_DEPTH);//bits in fifo addr range

logic [7:0] config_bits [0:185];
logic [WIDTH-2:0] tx_data;
//logic [WIDTH-2:0] data_to_larpix; // sent to DUT from FPGA
//logic [WIDTH-2:0] data_from_larpix; // received by FPGA from DUT
//logic [WIDTH-2:0] sent_data;
logic [WIDTH-2:0] receivedData;
logic [FIFO_BITS-1:0] fifo_counter;
logic [3:0] enable_piso_upstream;
logic [3:0] enable_piso_downstream;
logic [3:0] enable_posi;
logic [1:0] test_mode; // 00 = normal, 01 = PRBS, 10 = UART, 11 = burst  
logic     tx_enable;
logic       tx_busy;
logic     fifo_empty;
logic     fifo_half;
logic     fifo_full;
logic    rxclk;
logic     clktx;
logic     reset_n_clk2x;
logic     reset_n;

logic     [7:0] chip_id;      // unique id for each chip
logic    [WIDTH-2:0] finished_event; // event to put into fifo
logic    write_fifo_n;
logic     [WIDTH-2:0] pre_event;
logic     load_event;
logic       load_config_defaults;

logic     [WORDWIDTH-1:0] addr;
logic     [WORDWIDTH-1:0] data;
logic piso [3:0];
logic piso_bar [3:0];
logic posi [3:0];
logic [3:0] differential_uart;
logic [31:0] timestamp_32b;
//logic [REGNUM*WORDWIDTH-1:0] regmap_bits;
logic ld_tx_data;
// control FPGA rx uart
// logic uld_rx_data;
logic [1:0] uart_op;


// parse rx data
/*logic [1:0] rcvd_packet_declare;
logic [7:0] rcvd_chip_id;
logic [6:0] rcvd_channel_id;
logic [23:0] rcvd_time_stamp;
logic [7:0] rcvd_data_word;
logic [7:0] rcvd_regmap_data;
logic [7:0] rcvd_regmap_addr;
logic [10:0] rcvd_fifo_cnt;
logic rcvd_panic_bit;
logic rcvd_fifo_half_flag;
logic rcvd_fifo_full_flag;
logic rcvd_parity_bit;
*/
/*
always_comb begin
    rcvd_packet_declare = receivedData[1:0];
    rcvd_chip_id = receivedData[9:2];
    rcvd_channel_id = receivedData[16:10];
    rcvd_time_stamp = receivedData[40:17];
    rcvd_fifo_cnt = receivedData[40:30];

    rcvd_data_word = receivedData[50:41];
    rcvd_fifo_half_flag = receivedData[51];
    rcvd_fifo_full_flag = receivedData[52];
    rcvd_parity_bit = receivedData[53];

    rcvd_regmap_addr = receivedData[17:10];
    rcvd_regmap_data = receivedData[25:18];
end
*/
`include "../larpix_tasks/larpix_constants.sv"


always_comb begin // config_bits
//    enable_piso_upstream = config_bits[ENABLE_MISO_UP][3:0];
//    enable_piso_downstream = config_bits[ENABLE_MISO_DOWN][3:0];
    enable_piso_upstream = 4'b1101;
    enable_piso_downstream = 4'b0010;
    differential_uart       = config_bits[ENABLE_PISO_DOWN][7:4];
    enable_posi            = config_bits[ENABLE_POSI][3:0];
//    enable_posi            = 4'b1111;
    chip_id                 = config_bits[CHIP_ID];
    load_config_defaults   = config_bits[DIGITAL][5];
end

initial begin
    timestamp_32b = 32'h01234567;
    ld_tx_data = 0;
 //   chip_id = 8'b0000_0000;
//    uld_rx_data = 0;
    uart_op = 0;
    clktx = 0;
    reset_n_clk2x = 1;
    tx_enable = 1;
    load_event = 0;
    test_mode = 0;
// currently unused posi
    posi[0] = 1;
    posi[2] = 1;
    posi[3] = 1;
// define event from eb
    pre_event = 0;
    pre_event[1:0] = 2'b00; // data packet
    pre_event[9:2] = 0; // chip_id
    pre_event[15:10] = 3; // channel_id
    pre_event[47:16] = 16; // time-stamp
    pre_event[55:48] = 100; // data payload;
    pre_event[57:56] = 0; // trigger type
    pre_event[58] = 1; // shared fifo half full if = 1
    pre_event[59] = 0; // 1 if shared fifo in overflow
    pre_event[60] = 0; // local fifo half full if = 1
    pre_event[61] = 0; // 1 if localfifo in overflow
    pre_event[62] = 1; // send data back upstream
    addr = 8'h03;
    data = 8'h01;

// define event from fifo
//    tx_data = {54{1'b0}};

// reset chip
    #40 reset_n_clk2x = 0;
    #40 reset_n_clk2x = 1; 

// transmit event from FIFO to next stage
// load event into FIFO 
//


    #20000
    $display("Build event from FIFO");
    @(posedge clktx)
        load_event = 1;  // data available from EB
    @(posedge clktx)
        load_event = 0;


    
end


// RX and TX Clock generation

always #100 clktx = ~clktx;

// MCP goes here
mcp_external_interface
//mcp_regmap
    #(.WIDTH(WIDTH),
    .WORDWIDTH(WORDWIDTH),
    .REGNUM(REGNUM),
    .FIFO_DEPTH(FIFO_DEPTH)
    ) mcp_inst (
    .posi       (posi[1]),
    .clk2x      (rxclk),
    .reset_n    (reset_n),
    .piso       (piso[1])
);
// DUT Connected here

external_interface
    #(.WIDTH(WIDTH)
    ) external_interface_inst (
    .tx_out         (piso),
    .tx_out_bar    (piso_bar),
    .finished_event (finished_event),
    .config_bits    (config_bits),
    .write_fifo_n   (write_fifo_n),
    .read_fifo_n    (read_fifo_n),
    .tx_data        (tx_data),
    .chip_id        (chip_id),
    .pre_event      (pre_event),
    .fifo_full      (fifo_full),
    .fifo_half      (fifo_half),
    .fifo_empty     (fifo_empty),
    .load_event     (load_event),
    .load_config_defaults (load_config_defaults),
    .test_mode      (test_mode),
    .timestamp_32b  (timestamp_32b),
    .enable_piso_upstream   (enable_piso_upstream),
    .enable_piso_downstream (enable_piso_downstream),
    .enable_posi    (enable_posi),
    .differential_uart (differential_uart),
    .rx_in          (posi),
    .rxclk          (rxclk),
    .clk            (clktx),
    .reset_n_clk  (reset_n)
);

// FIFO goes here
//

fifo_async 
    #(.FIFO_WIDTH(WIDTH-1),
    .FIFO_DEPTH(FIFO_DEPTH),
    .FIFO_BITS(FIFO_BITS)
     ) fifo_inst (
    .data_out       (tx_data),
    .fifo_counter   (fifo_counter),
    .fifo_full      (fifo_full),
    .fifo_half      (fifo_half),
    .fifo_empty     (fifo_empty),
    .data_in        (finished_event),
    .read_n         (read_fifo_n),
    .write_n        (write_fifo_n),
    .reset_n        (reset_n)
    );

endmodule
