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
    parameter MAGIC_NUMBER = 32'h89_50_4E_47,
    parameter FIFO_BITS = 11)
    (output logic [3:0] tx_out ,     // LArPix TX UART output bits // TP: changed unpacked to packed to remove genus errors
    output logic [WIDTH-2:0] output_event, // event to put into the fifo
    output logic [7:0] config_bits [0:REGNUM-1],// regmap config bit outputs
    output logic [3:0] tx_enable,   // high to enable TX PHY
    output logic [3:0] tx_powerdown,  // high to power down TX PHY
    output logic write_fifo_n,      // write event into fifo (active low) 
    output logic read_fifo_n,       // read event from fifo (active low)
    input logic [WIDTH-2:0] tx_data,// fifo data to be transmitted off-chip
    input logic [7:0] chip_id,      // unique id for each chip
    input logic v3_mode,            // high for v3 mode (no oversampling)
    input logic [WIDTH-2:0] pre_event, // event from eb (pre-parity) to put into fifo
    input logic fifo_full,            // high if fifo overflows
    input logic fifo_half,            // high if fifo half full
    input logic fifo_empty,           // high if no data waiting in fifo
    input logic load_event,           // high to load event from event builder
    input logic load_config_defaults, // high for soft reset
    input logic [7:0] test_mode, // UART test modes
// 00 = normal, 01 = PRBS, 10 = UART, 11 = normal 
// bits[1:0] --> UART0, bits[3:2] --> UART1
// bits[5:4] --> UART2, bits[7:6] --> UART3
    input logic [31:0] timestamp_32b, // 32-bit timestamp
    input logic [3:0] enable_piso_upstream, // high to enable upstream uart
    input logic [3:0] enable_piso_downstream, // high to enable downstream
    input logic [3:0] enable_posi, // high to enable rx ports
    input logic [3:0] rx_in,                // rx UART input bit // TP: changed unpacked to packed to remove genus errors 
    input logic enable_tx_dynamic_powerdown, // high to power down idle
    input logic [2:0] tx_dynamic_powerdown_cycles, // how many to wait
    input logic enable_fifo_diagnostics, // high to embed fifo counts
    input logic [FIFO_BITS:0] fifo_counter,  // current shared fifo count
    input logic clk_rx,                // 2X oversampling RX UART clk
    input logic clk_tx,                // slow tx clock
    input logic clk,                  // master clock
    input logic reset_n_clk, // digital reset on clk domain (active low)
    input logic reset_n_config); // digital reset for config regs (low)

 
    
// internal nets
logic [WIDTH-2:0] data_wo_parity; // data without parity bit
logic [WIDTH-2:0] config_data_wo_parity; // config_data without parity bit
logic [11:0] bad_packets;
logic [11:0] packet_count;
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
logic [WIDTH-2:0] rx_data_uart [3:0];
logic [WIDTH-2:0] tx_data_uart [3:0];
logic [WIDTH-2:0] rx_data;
logic [7:0] regmap_write_data;
logic [7:0] regmap_read_data;
logic [7:0] regmap_address;
logic write_regmap;
logic read_regmap;
logic comms_busy;
logic send_config_data; // send config data to hydra network


// if this is config data from current chip, append fifo info, otherwise
// just pass it on

always_ff @(posedge clk or negedge reset_n_clk) begin
    if (!reset_n_clk) begin
        data_wo_parity <= 0;
    end 
    else begin
        if ( (chip_id == output_event[9:2]) && (output_event[1:0] == 2'b11) )
            data_wo_parity <= {output_event[62],fifo_full_delayed,fifo_half_delayed,output_event[59:0]};
        else if ( (output_event[1:0] == 2'b11) 
                || (output_event[1:0] == 2'b10)) 
            data_wo_parity <= output_event;
        else  
            data_wo_parity <= tx_data;
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
                .tx_powerdown           (tx_powerdown[i]),
                .rx_in                  (rx_in[i]),
                .uld_rx_data            (uld_rx_data_uart[i]),
                .v3_mode                (v3_mode),
                .test_mode              (test_mode[i*2+1:i*2]),
                .fifo_data              (tx_data_uart[i]),
                .timestamp_32b          (timestamp_32b),
                .ld_tx_data             (ld_tx_data_uart[i]),
                .rx_enable              (rx_enable[i]),
                .tx_enable              (tx_enable[i]),
                .enable_tx_dynamic_powerdown (enable_tx_dynamic_powerdown),
                .tx_dynamic_powerdown_cycles (tx_dynamic_powerdown_cycles),
                .enable_fifo_diagnostics    (enable_fifo_diagnostics),
                .enable_packet_diagnostics  (enable_packet_diagnostics),
                .fifo_counter           (fifo_counter),
                .rxclk                  (clk_rx),
                .txclk                  (clk_tx),
                .reset_n                (reset_n_clk),
                .reset_n_clk2x          (reset_n_clk)
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
    .fifo_data              (data_wo_parity),
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
    .MAGIC_NUMBER(MAGIC_NUMBER),
    .GLOBAL_ID(GLOBAL_ID)
    ) comms_ctrl_inst (
    .output_event       (output_event),
    .regmap_write_data  (regmap_write_data),
    .regmap_address     (regmap_address),
    .bad_packets        (bad_packets),
    .packet_count       (packet_count),
    .write_fifo_n       (write_fifo_n),
    .read_fifo_n        (read_fifo_n),
    .ld_tx_data         (ld_tx_data),
    .write_regmap       (write_regmap),
    .read_regmap        (read_regmap),
    .comms_busy         (comms_busy),
    .send_config_data   (send_config_data),
    .rx_data            (rx_data),
    .pre_event          (pre_event),
    .chip_id            (chip_id),
    .regmap_read_data   (regmap_read_data),
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
     ) config_regile_inst (
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
