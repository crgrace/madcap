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
    (output logic [WIDTH-2:0] output_event,  // event to put into the fifo
    output logic [7:0] regmap_write_data, // data to write to regmap
    output logic [7:0] regmap_address, // regmap addr to write
    output logic write_fifo_n,    // write event into fifo (active low) 
    output logic read_fifo_n,    // read event from fifo (active low)
    output logic ld_tx_data,      // high to transfer data to tx uart
    output logic write_regmap,    // active high to load register data
    output logic read_regmap,       // active high to read register data
    output logic comms_busy,    // comms dealing with event
    input logic [WIDTH-2:0] rx_data,   // data from rx uart (without parity)
    input logic [WIDTH-2:0] pre_event, // event from router (pre-parity) 
    input logic [7:0] chip_id,        // unique id for each chip
    input logic [7:0] regmap_read_data,       // data to read from regmap
    input logic rx_data_flag,        // high if rx data ready
    input logic fifo_empty,       // high if no data waiting in fifo
    input logic tx_busy,         // high when tx uart sending data
    input logic load_event,      // load event from event router
    input logic clk,            // primary clock
    input logic reset_n);      // asynchronous digital reset (active low)

// define states 

enum logic [2:0] // explicit state definitions
            {READY = 3'h0,
            CONFIG_WRITE = 3'h1,
            CONFIG_READ = 3'h2,
            CONFIG_READ_LATCH = 3'h3,
            PASS_ALONG = 3'h4,
            WAIT_FOR_WRITE = 3'h5,
            WRITE_FIFO = 3'h6,
            WAIT_STATE = 3'h7} State, Next;
            
// local registers
logic [2:0] read_latency; // counter used to wait for FIFO
logic global_read_flag; // high when executing a global read
logic [3:0] timeout; // don't get hung up in wait state
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        State <= READY;
    else
        State <= Next;
end // always_ff

always_comb begin
    Next = READY;
    case (State)
        READY:  if ( (rx_data_flag) && (rx_data[1:0] == 2'b10) 
                    && ( (rx_data[9:2] == chip_id) 
                    || (rx_data[9:2] == GLOBAL_ID) ) ) 
                                                        Next = CONFIG_WRITE;
                else if ( (rx_data_flag) && (rx_data[1:0] == 2'b11) 
                    && ( (rx_data[9:2] == chip_id) 
                    || (rx_data[9:2] == GLOBAL_ID) ) )  Next = CONFIG_READ;
                else if (rx_data_flag)                  Next = PASS_ALONG;
                else if (load_event)              Next = WAIT_FOR_WRITE;
                else                                    Next = READY;
        CONFIG_WRITE:   if (rx_data[9:2] == GLOBAL_ID)  Next = PASS_ALONG;
                else                                    Next = WAIT_STATE;
        CONFIG_READ: if (read_latency == 3'b101) Next = CONFIG_READ_LATCH;
                else                                    Next = CONFIG_READ;
        CONFIG_READ_LATCH:                              Next = WRITE_FIFO;
        PASS_ALONG:                                     Next = WRITE_FIFO;
        WAIT_FOR_WRITE:                                 Next = WRITE_FIFO;
        WRITE_FIFO:  if ( (rx_data[9:2] == GLOBAL_ID) 
                     && (global_read_flag == 1'b1))     Next = PASS_ALONG;
                     else                               Next = WAIT_STATE;
        WAIT_STATE: if (!rx_data_flag || (timeout == 4'hF)) Next = READY;
                    else                                Next = WAIT_STATE;
        default:                                        Next = READY;
    endcase
end // always_comb

// registered outputs
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        write_fifo_n <= 1'b1;
        output_event <= 63'b0;
        write_regmap <= 1'b0;
        read_regmap <= 1'b0;
        regmap_address <= 8'b0;
        regmap_write_data <= 8'h0;
        read_latency <= 3'b0;
        global_read_flag <= 1'b0;
        timeout <= 4'b0;
        comms_busy <= 1'b0;
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
        case (Next)
        READY:       begin
                        comms_busy <= 1'b0;
                    end
        CONFIG_WRITE:begin
                        regmap_address <= rx_data[17:10];
                        regmap_write_data <= rx_data[25:18];
                        write_regmap <= 1'b1;
                    end
        CONFIG_READ: begin
                        output_event <= rx_data;
                        output_event[25:18] <= regmap_read_data;
                        output_event[9:2] <= chip_id;
                        regmap_address <= rx_data[17:10];
                        read_regmap <= 1'b1;
                        read_latency <= read_latency + 1'b1;
                        if (rx_data[9:2] == GLOBAL_ID) begin
                            global_read_flag <= 1'b1;
                        end
                     end
        CONFIG_READ_LATCH:  begin
                        output_event[62] <= 1'b1; // flag downstream
                    end
        PASS_ALONG: begin
                        output_event <= rx_data;
                        global_read_flag <= 1'b0;
                    end
        WAIT_FOR_WRITE: begin
                            output_event <= pre_event;
                        end
        WRITE_FIFO: begin
                        write_fifo_n <= 1'b0;
                    end
        WAIT_STATE: begin
                    //    write_fifo_n <= 1'b0;
                        timeout <= timeout + 1'b1;
                    
                    end
        default:    ;
        endcase
    end
end // always_ff                                ;

fifo_rd_ctrl_async
    fifo_rd_ctrl_async_inst (
    .read_fifo_n    (read_fifo_n),
    .ld_tx_data     (ld_tx_data),
    .tx_busy        (tx_busy),
    .fifo_empty     (fifo_empty),
    .write_fifo_n   (write_fifo_n),
    .clk            (clk),
    .reset_n        (reset_n)
    );   
                     
endmodule
