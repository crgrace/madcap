///////////////////////////////////////////////////////////////////
// File Name: fifo_rd_ctrl_asyc.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Finite state machine to control reading of fifo and 
//              coordinating transfer of data to UART TX
//              Outputs are registered to avoid glitches and to
//              standardize input and output delay constraints.
//              ** Asynchronous Version **
///////////////////////////////////////////////////////////////////

module fifo_rd_ctrl_async
    (output logic read_fifo_n,         // fifo read strobe (active low)
    output logic ld_tx_data,          // high to transfer data to UART TX
    input logic tx_busy,              // high when tx uart sending data
    input logic fifo_empty,           // high when fifo is in underflow 
    input logic write_fifo_n,        // no simultaneous read and write
    input logic clk,                 // primary clock    
    input logic reset_n);       // asynchronous digital reset (active low)

// define states
enum logic [2:0] // explicit state definitions
            {IDLE = 3'h0,
            READY = 3'h1,
            GET_FIFO_DATA = 3'h2,
            WAIT_STATE = 3'h3,
            TRANSFER = 3'h4} State, Next;

// internal register
logic [6:0] timeout; // keeps state machine from hanging if all TX off

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n)
        State <= IDLE;
    else
        State <= Next;

always_comb begin
    Next = IDLE;
    case (State)
        IDLE:   if (!tx_busy)       Next = READY; // is UART TX ready?
                else                Next = IDLE;
        READY:  if (!fifo_empty)    Next = GET_FIFO_DATA;
                else                Next = READY;
        GET_FIFO_DATA:              Next = WAIT_STATE;
        WAIT_STATE:                Next = TRANSFER;
        TRANSFER: if (tx_busy | (timeout == 6'h3F))      Next = IDLE;
                  else              Next = TRANSFER;
    endcase
end // always

// registered outputs
always_ff @(posedge clk  or negedge reset_n)
    if (!reset_n) begin
        read_fifo_n <= 1'b1;
        ld_tx_data <= 1'b0;
        timeout <= 6'b0;
    end else begin
        read_fifo_n <= 1'b1;
        ld_tx_data <= 1'b0;
        timeout <= 6'b0;
        case(Next)
            IDLE:           ;       
            READY:          ;
            GET_FIFO_DATA:  begin 
                                read_fifo_n <= 1'b0;
                            end
            WAIT_STATE:     ;
            TRANSFER:       begin
                                ld_tx_data <= 1'b1;
                                timeout <= timeout + 1'b1;
                            end
            default:        ;
        endcase
    end // always_ff
     
endmodule
