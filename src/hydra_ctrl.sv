///////////////////////////////////////////////////////////////////
// File Name: hydra_ctrl.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Routes packets to appropriate UART based on 
//              Hydra configuration settings
//              Also routes RX inputs
//
///////////////////////////////////////////////////////////////////

module hydra_ctrl
    #(parameter WIDTH = 64)  // width of packet (w/o start & stop bits) 
    (output logic [WIDTH-1:0] tx_data0,   // data to send out to UART 0
    output logic [WIDTH-1:0] tx_data1,   // data to send out to UART 1
    output logic [WIDTH-1:0] tx_data2,   // data to send out to UART 2
    output logic [WIDTH-1:0] tx_data3,   // data to send out to UART 3
    output logic [3:0] uld_rx_data_uart, // distributed unload command
    output logic [3:0] ld_tx_data_uart, // distributed load command
    output logic [3:0] rx_enable,             // high to enable rx UART
    output logic [3:0] tx_enable,             // high to enable tx UART
    output logic tx_busy_any,   // high if any tx is busy
    output logic rx_data_flag,      // high if any rx data ready 
    output logic [WIDTH-1:0] rx_data, // event to put into the FIFO
    input logic [WIDTH-1:0] rx_data0,        // rx data from UART 0
    input logic [WIDTH-1:0] rx_data1,        // rx data from UART 0
    input logic [WIDTH-1:0] rx_data2,        // rx data from UART 0
    input logic [WIDTH-1:0] rx_data3,        // rx data from UART 0
    input logic [3:0] enable_piso_upstream, // high to enable upstream uart
    input logic [3:0] enable_piso_downstream, // high to enable downstream
    input logic [3:0] enable_posi, // high to enable rx ports
    input logic [WIDTH-1:0] fifo_data, // input from the fifo
    input logic ld_tx_data,     // load fifo data into UARTs
    input logic [3:0] tx_busy, // high for each UART busy
    input logic comms_busy,    // comms dealing with event
    input logic [3:0] rx_empty_uart, // high if UART has no rx data
    input logic clk,                // master clock
    input logic reset_n);      // asynchronous digital reset (active low)

// define states for RX state machine
enum logic [2:0] // explicit state definitions
            {READY = 3'h0,
            WAIT_STATE = 3'h1,
            LOAD_RX_DATA = 3'h2,
            WAIT_FOR_COMMS = 3'h3,
            NEXT_DATA = 3'h4} State, Next;

// local registers
logic downstream_flag;          // high if downstream   
logic ld_tx_data_latched;
logic [3:0] rx_data_flag_uart;
logic [3:0] clear_rx_data_flag_uart;
logic [1:0] wait_counter; // make sure time for UART RX to latch data
logic [5:0] timeout; // don't get hung up in a wait state

always_comb begin
    rx_enable = enable_posi;
    tx_enable = enable_piso_upstream | enable_piso_downstream;
    tx_busy_any = |tx_busy;
end

// generate downstream flag

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        downstream_flag <= 1'b0;
        ld_tx_data_latched <= 1'b0;
    end 
    else begin
        if (ld_tx_data) begin
            ld_tx_data_latched <= 1'b1;
            downstream_flag <= fifo_data[62];
        end
        else begin
            ld_tx_data_latched <= 1'b0;
            downstream_flag <= 1'b0;
        end
    end
end

// RX state machine
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        State <= READY;
    else
        State <= Next;
end // always_ff

always_comb begin
    Next = READY;
    case (State)
        READY: if (|rx_data_flag_uart)          Next = WAIT_STATE;
               else                             Next = READY;
        WAIT_STATE: if (wait_counter == 2'b10)  Next = LOAD_RX_DATA;
                else                            Next = WAIT_STATE;
        LOAD_RX_DATA:                           Next = WAIT_FOR_COMMS;
        WAIT_FOR_COMMS: if (comms_busy)         Next = WAIT_FOR_COMMS;
               else if (timeout == 6'h2F)       Next = NEXT_DATA;
               else                             Next = NEXT_DATA;
        NEXT_DATA: if (rx_data_flag_uart != 4'b0) Next = WAIT_STATE;
               else                             Next = READY;
        default:                                Next = READY;
    endcase
end // always_comb

// registered outputs
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        rx_data <= 64'b0;
        timeout <= 6'b0;
        clear_rx_data_flag_uart <= 4'b0;
        rx_data_flag <= 1'b0;
        wait_counter <= 2'b00;
    end
    else begin
        clear_rx_data_flag_uart <= 4'b0;
        rx_data_flag <= 1'b0;
        wait_counter <= 2'b00;
        case (Next)
            READY: begin
                timeout <= 6'b0;
            end
            WAIT_STATE: begin
                wait_counter <= wait_counter + 1'b1;
            end
            LOAD_RX_DATA: begin
        // check each UART for data and then read it if enabled
        // otherwise ignore it. Also, prioritize from 0 - 3 so that
        // no data is lost in the unlikely event that two UARTs request
        // a read at the same time
                if (rx_data_flag_uart[0]) begin
                    rx_data <= rx_data0;
                    clear_rx_data_flag_uart[0] <= 1'b1;
                    rx_data_flag <= 1'b1;
                end
                else if (rx_data_flag_uart[1]) begin
                    rx_data <= rx_data1;
                    clear_rx_data_flag_uart[1] <= 1'b1;
                    rx_data_flag <= 1'b1;
                end
                else if (rx_data_flag_uart[2]) begin
                    rx_data <= rx_data2;
                    clear_rx_data_flag_uart[2] <= 1'b1;
                    rx_data_flag <= 1'b1;
                end
                else if (rx_data_flag_uart[3]) begin
                    rx_data <= rx_data3;
                    clear_rx_data_flag_uart[3] <= 1'b1;
                    rx_data_flag <= 1'b1;
                end 
            end // state LOAD_RX_DATA
            WAIT_FOR_COMMS: begin
                timeout <= timeout + 1'b1;
            end
            NEXT_DATA: begin
                timeout <= 6'b0;
            end
            default:    ;
        endcase
    end
end // always_ff

// RX UART HANDLER                            
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        rx_data_flag_uart <= 4'b0;
        uld_rx_data_uart <= 4'b0;
    end 
    else begin
        for (int i = 0; i < 4; i++) begin
            if (clear_rx_data_flag_uart[i]) begin
                rx_data_flag_uart[i] <= 1'b0;
            end
            if (!rx_empty_uart[i]) begin
                uld_rx_data_uart[i] <= 1'b1;
                if (enable_posi[i]) begin
                    rx_data_flag_uart[i] <= 1'b1;
                end
            end
            else begin
                uld_rx_data_uart[i] <= 1'b0;
            end
        end // for loop    
    end // if
end // always_ff
 
// TX UART HANDLER                            
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        tx_data0 <= 63'b0;
        tx_data1 <= 63'b0;
        tx_data2 <= 63'b0;
        tx_data3 <= 63'b0;
        ld_tx_data_uart <= 4'b0;
    end
    else begin
        ld_tx_data_uart <= 4'b0;
        // see if the event is downstream, and if it is send the
        // FIFO data out the appropriate UARTs.
        // repeat this for upstream
        if (downstream_flag) begin // event is downstream
            if (ld_tx_data_latched & enable_piso_downstream[0]) begin
                tx_data0 <= fifo_data;
                ld_tx_data_uart[0] <= 1'b1;
            end
            if (ld_tx_data_latched & enable_piso_downstream[1]) begin
                tx_data1 <= fifo_data;
                ld_tx_data_uart[1] <= 1'b1;
            end
            if (ld_tx_data_latched & enable_piso_downstream[2]) begin
                tx_data2 <= fifo_data;
                ld_tx_data_uart[2] <= 1'b1;
            end
            if (ld_tx_data_latched & enable_piso_downstream[3]) begin
                tx_data3 <= fifo_data;
                ld_tx_data_uart[3] <= 1'b1;
            end
        end 
        else begin // event is upstream
            if (ld_tx_data_latched & enable_piso_upstream[0] == 1'b1) begin
                tx_data0 <= fifo_data;
                ld_tx_data_uart[0] <= 1'b1;
            end
            if (ld_tx_data_latched & enable_piso_upstream[1] == 1'b1) begin
                tx_data1 <= fifo_data;
                ld_tx_data_uart[1] <= 1'b1;
            end
            if (ld_tx_data_latched & enable_piso_upstream[2] == 1'b1) begin
                tx_data2 <= fifo_data;
                ld_tx_data_uart[2] <= 1'b1;
            end
            if (ld_tx_data_latched & enable_piso_upstream[3] == 1'b1) begin
                tx_data3 <= fifo_data;
                ld_tx_data_uart[3] <= 1'b1;
            end
        end
    end // if
end  // always_ff

endmodule // hydra_ctrl  
