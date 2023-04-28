///////////////////////////////////////////////////////////////////
// File Name: comms_ctrl.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Finite state machine control communication operations 
//              Outputs are registered to avoid glitches and to
//              standardize input and output delay constraints.
//
//              Note: this is the FSM version. Original procedural
//              version was functional but difficult to extend to 
//              handle edge cases.
///////////////////////////////////////////////////////////////////

module comms_ctrl
    #(parameter WIDTH = 64,
    parameter GLOBAL_ID = 255)      // global broadcast ID
    (output logic [WIDTH-1:0] output_event,  // event to put into the fifo
    output logic [7:0] regmap_write_data, // data to write to regmap
    output logic [7:0] regmap_address, // regmap addr to write
    output logic [15:0] total_packets, // number of packets that have been generated
    output logic write_fifo_n,    // write event into fifo (active low) 
    output logic read_fifo_n,    // read event from fifo (active low)
    output logic ld_tx_data,      // high to transfer data to tx uart
    output logic write_regmap,    // active high to load register data
    output logic read_regmap,       // active high to read register data
    output logic comms_busy,    // comms dealing with event
    output logic send_config_data, // send config data to hydra network
    output logic fifo_ack,          // acknowledge data consumed from FIFO
    input logic [WIDTH-1:0] rx_data,   // data from rx uart 
    input logic [WIDTH-1:0] pre_event, // event from router  
    input logic [7:0] chip_id,        // unique id for each chip
    input logic [7:0] regmap_read_data,       // data to read from regmap
    input logic [11:0] fifo_counter,  // number of words in FIFO
    input logic enable_data_stats,  // high to write stats to mailbox
    input logic rx_data_flag,        // high if rx data ready
    input logic fifo_empty,       // high if no data waiting in fifo
    input logic tx_busy,         // high when tx uart sending data
    input logic load_event,      // load event from event router
    input logic clk,            // primary clock
    input logic reset_n);      // asynchronous digital reset (active low)

// define states 

enum logic [3:0] // explicit state definitions
            {READY = 4'h0,
            CONFIG_WRITE = 4'h1,
            CONFIG_WRITE_MAILBOX_LSB = 4'h2,
            CONFIG_WRITE_MAILBOX_MSB = 4'h3,
            CONFIG_READ = 4'h4,
            CONFIG_READ_LATCH = 4'h5,
            PASS_ALONG = 4'h6,
            PASS_ALONG_CONFIG = 4'h7,
            PASS_ALONG_CONFIG2 = 4'h8,
            WAIT_FOR_WRITE = 4'h9,
            WRITE_FIFO = 4'ha,
            WAIT_STATE = 4'hb,
            DROPPED_PACKET = 4'hc,
            DONE       = 4'hd} State, Next;

// configuration word definitions
// located at ../testbench/larpix_tasks/
// example compilation: 
//vlog +incdir+../testbench/larpix_tasks/ -incr -sv "../src/digital_core.sv"
`include "larpix_constants.sv"
            
// local registers
logic load_mailbox;         // want to load the mailbox into the config registers
logic ch_fifo_high_water;   // high if fifo_counter reaches high water
logic fifo_high_water_executed;   // high if high water written to regmap
logic ch_total_packets;     // high if total_packets changes
logic ch_bad_packets;       // high if bad packets changed
logic parity_error;         // high if word has bad parity
logic magic_number;         // breaks magic number out of word for diagnostics
logic [15:0] fifo_high_water; // max FIFO count since reset
logic [11:0] fifo_mag;      // number of events in FIFO
logic [15:0] bad_packets;   // number of dropped packets since reset
logic [2:0] read_latency;   // counter used to wait for FIFO
logic global_read_flag;     // high when executing a global read
logic [3:0] timeout;        // don't get hung up in wait state
logic ld_tx_data_fifo;      // tells uart to load data from FIFO

always_comb begin
    ld_tx_data = ld_tx_data_fifo || send_config_data;
    fifo_mag = (fifo_counter - 1'b1);
    magic_number = rx_data[57:26];
end // always_comb

// parity checker
always_comb begin
    if ((rx_data[WIDTH-1]) != ~^rx_data[WIDTH-2:0])
        parity_error = 1'b1;
    else
        parity_error = 1'b0;
end // always_comb

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        fifo_high_water <= 11'b0;
        ch_fifo_high_water <= 1'b0;
    end 
    else if (ch_fifo_high_water && fifo_high_water_executed) begin
        ch_fifo_high_water <= 1'b0;
    end
    else if (fifo_mag > fifo_high_water) begin
        fifo_high_water <= {4'b0,(fifo_mag)};
        ch_fifo_high_water <= 1'b1;
    end
end // always_ff

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        load_mailbox <= 1'b0;
    else if (load_mailbox == 1'b0) begin
        if (ch_fifo_high_water || ch_total_packets || ch_bad_packets) begin
            load_mailbox <= 1'b1;
        end
    end
    else begin 
            load_mailbox <= 1'b0;
    end
end // always_ff

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        State <= READY;
    else
        State <= Next;
end // always_ff

always_comb begin
    Next = READY;
    case (State)
        READY:  if ( (rx_data_flag) 
                    && (((rx_data[1:0] == CONFIG_WRITE_OP)
                    || (rx_data[1:0] == CONFIG_READ_OP))
                    && ((rx_data[57:26] != MAGIC_NUMBER)
                    || (parity_error == 1'b1))) ) Next = DROPPED_PACKET;
                else if ((rx_data_flag) && (rx_data[1:0] == 2'b00)) Next = DROPPED_PACKET; 
                else if ( (rx_data_flag) && (rx_data[1:0] == CONFIG_WRITE_OP) 
                    && ( (rx_data[9:2] == chip_id) 
                    || (rx_data[9:2] == GLOBAL_ID) ) ) 
                                                        Next = CONFIG_WRITE;
                else if ( (rx_data_flag) && (rx_data[1:0] == CONFIG_READ_OP) 
                    && ( (rx_data[9:2] == chip_id) 
                    || (rx_data[9:2] == GLOBAL_ID) ) )  Next = CONFIG_READ;
                else if ( (rx_data_flag) 
                    && ((rx_data[1:0] == CONFIG_WRITE_OP)
                    || (rx_data[1:0] == CONFIG_READ_OP)) ) Next = PASS_ALONG_CONFIG;
                else if (rx_data_flag)                  Next = PASS_ALONG;
                else if (load_event)              Next = WAIT_FOR_WRITE;
                else if (load_mailbox)            Next = CONFIG_WRITE_MAILBOX_LSB;
                else                                    Next = READY;
        CONFIG_WRITE:   if (rx_data[9:2] == GLOBAL_ID)  Next = PASS_ALONG;
                else                                    Next = WAIT_STATE;
        CONFIG_WRITE_MAILBOX_LSB:                       Next = CONFIG_WRITE_MAILBOX_MSB;
        CONFIG_WRITE_MAILBOX_MSB:                       Next = WAIT_STATE;
        CONFIG_READ: if (read_latency == 3'b101) Next = CONFIG_READ_LATCH;
                else                                    Next = CONFIG_READ;
        CONFIG_READ_LATCH:                              Next = WAIT_STATE;
        PASS_ALONG:                                     Next = WRITE_FIFO;
        PASS_ALONG_CONFIG:                       Next = PASS_ALONG_CONFIG2;
        PASS_ALONG_CONFIG2:                              Next = WAIT_STATE;
        WAIT_FOR_WRITE:                                 Next = WRITE_FIFO;
        WRITE_FIFO:  if ( (rx_data[9:2] == GLOBAL_ID) 
                     && (global_read_flag == 1'b1))     Next = PASS_ALONG;
                     else                               Next = WAIT_STATE;
        WAIT_STATE: if ( (enable_data_stats)
                        && (ch_total_packets 
                        || ch_fifo_high_water)) Next = CONFIG_WRITE_MAILBOX_LSB;
                    else if (!rx_data_flag || (timeout == 4'hF)) Next = READY;
                    else                                Next = WAIT_STATE;
        DROPPED_PACKET:                                     Next = READY;
        default:                                        Next = READY;
    endcase
end // always_comb

// registered outputs
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        write_fifo_n <= 1'b1;
        output_event <= 64'b0;
        write_regmap <= 1'b0;
        read_regmap <= 1'b0;
        regmap_address <= 8'b0;
        regmap_write_data <= 8'h0;
        read_latency <= 3'b0;
        global_read_flag <= 1'b0;
        timeout <= 4'b0;
        comms_busy <= 1'b0;
        send_config_data <= 1'b0;
        bad_packets <= 16'b0;
        ch_bad_packets <= 1'b0;
        total_packets <= 16'b0;
        ch_total_packets <= 1'b0;
        fifo_ack <= 1'b0;
        fifo_high_water_executed <= 1'b0;
    end
    else begin
        write_fifo_n <= 1'b1;
        write_regmap <= 1'b0;
        read_regmap <= 1'b0;
        regmap_address <= 8'b0;
        regmap_write_data <= 8'h0;
        read_latency <= 3'b0;
        timeout <= 4'b0;
        comms_busy <= 1'b1;
        send_config_data <= 1'b0;
        fifo_ack <= 1'b0;
        fifo_high_water_executed <= 1'b0;
       case (Next)
        READY:       begin
                        comms_busy <= 1'b0;
                    end
        CONFIG_WRITE: begin
                        regmap_address <= rx_data[17:10];
                        regmap_write_data <= rx_data[25:18];
                        write_regmap <= 1'b1;
                    end
        CONFIG_WRITE_MAILBOX_LSB: begin
                        write_regmap <= 1'b1;
                        if (ch_total_packets == 1'b1) begin
                            regmap_address <= TOTAL_PACKETS_LSB;
                            regmap_write_data <= total_packets[7:0];
                        end
                        else if (ch_bad_packets == 1'b1) begin
                            regmap_address <= DROPPED_PACKETS;
                            regmap_write_data <= bad_packets[7:0];
                            ch_bad_packets <= 1'b0;
                        end
                        else if (ch_fifo_high_water == 1'b1) begin
                            regmap_address <= FIFO_HW_LSB;
                            regmap_write_data <= fifo_high_water[7:0];
                        end
                     end
        CONFIG_WRITE_MAILBOX_MSB: begin
                        write_regmap <= 1'b1;
                        if (ch_total_packets == 1'b1) begin
                            regmap_address <= TOTAL_PACKETS_MSB;
                            regmap_write_data <= total_packets[15:8];
                            ch_total_packets <= 1'b0;
                        end
                        else if (ch_fifo_high_water == 1'b1) begin
                            regmap_address <= FIFO_HW_MSB;
                            regmap_write_data <= fifo_high_water[15:8];
                            fifo_high_water_executed <= 1'b1;
                        end
                     end
                     
        CONFIG_READ: begin
                        output_event <= rx_data;
                        output_event[62] <= 1'b1; // flag downstream
                        output_event[25:18] <= regmap_read_data;
                        output_event[9:2] <= chip_id;
                        regmap_address <= rx_data[17:10];
                        read_regmap <= 1'b1;
                        read_latency <= read_latency + 1'b1;
                        //total_packets <= total_packets + 1'b1;
                        //ch_total_packets <= 1'b1;
                        if (rx_data[9:2] == GLOBAL_ID) begin
                            global_read_flag <= 1'b1;
                        end
                     end
        CONFIG_READ_LATCH:  begin
                        // add parity
                        output_event[63] <= ~^output_event[62:0]; 
                        send_config_data <= 1'b1;
                    end
        PASS_ALONG: begin
                        output_event <= rx_data;
                        global_read_flag <= 1'b0;
                    end
        PASS_ALONG_CONFIG: begin
                        output_event <= rx_data;
                    end
        PASS_ALONG_CONFIG2: begin
                        output_event <= rx_data;
                        send_config_data <= 1'b1;
                    end
                    
        WAIT_FOR_WRITE: begin
                            output_event <= pre_event;
                            total_packets <= total_packets + 1'b1;
                            ch_total_packets <= 1'b1;
                        end
        WRITE_FIFO: begin
                        write_fifo_n <= 1'b0;
                        fifo_ack <= 1'b1;
                    end
        WAIT_STATE: begin
                        timeout <= timeout + 1'b1;
                    end
        DROPPED_PACKET: begin
                        bad_packets <= bad_packets + 1'b1;
                        ch_bad_packets <= 1'b1;
                    end
        default:    ;
        endcase
    end
end // always_ff                                ;

fifo_rd_ctrl_async
    fifo_rd_ctrl_async_inst (
    .read_fifo_n    (read_fifo_n),
    .ld_tx_data     (ld_tx_data_fifo),
    .tx_busy        (tx_busy),
    .fifo_empty     (fifo_empty),
    .write_fifo_n   (write_fifo_n),
    .clk            (clk),
    .reset_n        (reset_n)
    );   
                     
endmodule
