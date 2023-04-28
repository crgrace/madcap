///////////////////////////////////////////////////////////////////
// File Name: external_interface.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: LArPix external interface.  
//              Includes UART for chip-to-chip communications.
//              Includes 255 byte register file for configuration bits.
//
///////////////////////////////////////////////////////////////////

module external_interface
    #(parameter WIDTH = 64, // width of packet (w/o start & stop bits) 
    parameter GLOBAL_ID = 256,      // global broadcast ID
    parameter REGNUM = 256,
    parameter FIFO_BITS = 11)
    (output logic [3:0] tx_out ,     // LArPix TX UART output bits // TP: changed unpacked to packed to remove genus errors
    output logic [WIDTH-1:0] output_event, // event to put into the fifo
    output logic [7:0] config_bits [0:REGNUM-1],// regmap config bit outputs
    output logic [3:0] tx_enable,   // high to enable TX PHY
    output logic [3:0] total_packets_lsbs, // 4 lsbs of total_packets
    output logic write_fifo_n,      // write event into fifo (active low) 
    output logic read_fifo_n,       // read event from fifo (active low)
    output logic fifo_ack,          // acknowledge data consumed from FIFO
    input logic [WIDTH-1:0] tx_data,// fifo data to be transmitted off-chip
    input logic [7:0] chip_id,      // unique id for each chip
    input logic [WIDTH-1:0] pre_event, // event from eb to put into fifo
    input logic fifo_full,            // high if fifo overflows
    input logic fifo_half,            // high if fifo half full
    input logic fifo_empty,           // high if no data waiting in fifo
    input logic load_event,           // high to load event from event builder
    input logic load_config_defaults, // high for soft reset
    input logic [31:0] timestamp_32b, // 32-bit timestamp
    input logic [3:0] enable_piso_upstream, // high to enable upstream uart
    input logic [3:0] enable_piso_downstream, // high to enable downstream
    input logic [3:0] enable_posi, // high to enable rx ports
    input logic [3:0] rx_in,                // rx UART input bit // TP: changed unpacked to packed to remove genus errors 
    input logic enable_fifo_diagnostics, // high to embed fifo counts
    input logic enable_data_stats, // high to write stats to mailbox
    input logic [FIFO_BITS:0] fifo_counter,  // current shared fifo count
    input logic clk,                  // master clock
    input logic reset_n_clk, // digital reset on clk domain (active low)
    input logic reset_n_config); // digital reset for config regs (low)

 
    
// internal nets
logic [15:0] total_packets; // number of packets that have been generated
logic [WIDTH-1:0] data; // data with parity bit
logic fifo_full_delayed; // delayed one clk
logic fifo_half_delayed; // delayed one clk
logic rx_data_flag;
logic [3:0] rx_empty_uart;
logic [3:0] uld_rx_data_uart;
logic ld_tx_data;
logic [3:0] ld_tx_data_uart;
logic [3:0] rx_enable;
logic [3:0] tx_busy;
logic tx_busy_any; // high if any tx is busy (gates FIFO reads)
logic [WIDTH-1:0] rx_data_uart [3:0];
logic [WIDTH-1:0] tx_data_uart [3:0];
logic [WIDTH-1:0] rx_data;
logic [7:0] regmap_write_data;
logic [7:0] regmap_read_data;
logic [7:0] regmap_address;
logic write_regmap;
logic read_regmap;
logic comms_busy;
logic send_config_data; // send config data to hydra network


always_comb begin
    total_packets_lsbs = total_packets[3:0];
end // always_comb

// if this is config data from current chip, append fifo info, otherwise
// just pass it on

always_ff @(posedge clk or negedge reset_n_clk) begin
    if (!reset_n_clk) begin
        data <= 0;
    end 
    else begin
        if ( (chip_id == output_event[9:2]) && (output_event[1:0] == 2'b11) )
            data <= {output_event[63:62],fifo_full_delayed,fifo_half_delayed,output_event[59:0]};
        else if ( (output_event[1:0] == 2'b11) 
                || (output_event[1:0] == 2'b10)) 
            data <= output_event;
        else  
            data <= tx_data;
    end
end // always

always_ff @(posedge clk or negedge reset_n_clk)
    if (!reset_n_clk) begin
        fifo_full_delayed <= 1'b0;
        fifo_half_delayed <= 1'b0;
    end 
    else begin
        fifo_full_delayed <= fifo_full;
        fifo_half_delayed <= fifo_half;
    end


// declare four UARTs for Hydra I/O
genvar i;
generate
    for (i = 0; i < 4; i++) begin : UART
        uart
            #(.WIDTH(WIDTH),
            .FIFO_BITS(FIFO_BITS))
            uart_inst (
                .rx_data                (rx_data_uart[i]),
                .rx_empty               (rx_empty_uart[i]),
                .tx_out                 (tx_out[i]),
                .tx_busy                (tx_busy[i]),   
                .rx_in                  (rx_in[i]),
                .uld_rx_data            (uld_rx_data_uart[i]),
                .fifo_data              (tx_data_uart[i]),
                .timestamp_32b          (timestamp_32b),
                .ld_tx_data             (ld_tx_data_uart[i]),
                .rx_enable              (rx_enable[i]),
                .tx_enable              (tx_enable[i]),
                .clk                    (clk),
                .reset_n                (reset_n_clk)
            );
    end // for
endgenerate

// controller for HYDRA I/O
hydra_ctrl
    hydra_ctrl_inst (
    .tx_data0               (tx_data_uart[0]),
    .tx_data1               (tx_data_uart[1]),
    .tx_data2               (tx_data_uart[2]),
    .tx_data3               (tx_data_uart[3]),
    .uld_rx_data_uart       (uld_rx_data_uart),
    .ld_tx_data_uart        (ld_tx_data_uart),
    .rx_enable              (rx_enable),
    .tx_enable              (tx_enable),
    .tx_busy_any            (tx_busy_any),
    .rx_data_flag           (rx_data_flag),
    .rx_data                (rx_data),
    .rx_data0               (rx_data_uart[0]),
    .rx_data1               (rx_data_uart[1]),
    .rx_data2               (rx_data_uart[2]),
    .rx_data3               (rx_data_uart[3]),
    .enable_piso_upstream   (enable_piso_upstream),
    .enable_piso_downstream (enable_piso_downstream),
    .enable_posi            (enable_posi),
    .fifo_data              (data),
    .ld_tx_data             (ld_tx_data),
    .tx_busy                (tx_busy),
    .comms_busy             (comms_busy),
    .rx_empty_uart          (rx_empty_uart),
    .clk                    (clk),
    .reset_n                (reset_n_clk)
    );



// communication controller
comms_ctrl
    #(.WIDTH(WIDTH),
    .GLOBAL_ID(GLOBAL_ID)
    ) comms_ctrl_inst (
    .output_event       (output_event),
    .regmap_write_data  (regmap_write_data),
    .regmap_address     (regmap_address),
    .total_packets      (total_packets),
    .write_fifo_n       (write_fifo_n),
    .read_fifo_n        (read_fifo_n),
    .ld_tx_data         (ld_tx_data),
    .write_regmap       (write_regmap),
    .read_regmap        (read_regmap),
    .comms_busy         (comms_busy),
    .send_config_data   (send_config_data),
    .fifo_ack           (fifo_ack),
    .rx_data            (rx_data),
    .pre_event          (pre_event),
    .chip_id            (chip_id),
    .regmap_read_data   (regmap_read_data),
    .fifo_counter       (fifo_counter),
    .enable_data_stats  (enable_data_stats),
    .rx_data_flag       (rx_data_flag),
    .fifo_empty         (fifo_empty),
    .tx_busy            (tx_busy_any),
    .load_event         (load_event),
    .clk                (clk),
    .reset_n            (reset_n_clk)
);

// register map
config_regfile
    #(.REGNUM(REGNUM)
     ) config_regfile_inst (
    .config_bits           (config_bits),
    .read_data             (regmap_read_data),
    .write_addr            (regmap_address), 
    .write_data            (regmap_write_data),
    .read_addr             (regmap_address),
    .write                 (write_regmap),
    .read                  (read_regmap),
    .load_config_defaults  (load_config_defaults),
    .clk                   (clk),
    .reset_n               (reset_n_config)
);

endmodule
