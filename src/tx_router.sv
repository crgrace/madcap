///////////////////////////////////////////////////////////////////
// File Name: tx_router.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Finite state machine to control reading of FIFO and 
//              coordinating transfer of data to UART TX.
//              Routes FIFO data to one of 16 avaiable UART TX blocks.
//              Also makes sure the TX is ready before it sends it data.
//
//              Outputs are registered to avoid glitches and to
//              standardize input and output delay constraints.
///////////////////////////////////////////////////////////////////

module tx_router
    (output logic [63:0] tx_data [15:0],// data connection to TX array
    output logic read_fifo_n,           // fifo read strobe (active low)
    output logic [15:0] ld_tx_data,     // high to transfer data to UART TX
    input logic [63:0] fifo_out,        // fifo output to be routed
    input logic [15:0] tx_busy,         // high when tx uart sending data
    input logic [3:0] target_larpix,    // which LArPix is this going to?
    input logic broadcast,              // high if we want to send to all
    input logic fifo_empty,             // high when fifo is in underflow 
    input logic write_fifo_n,           // no simultaneous read and write
    input logic clk,                    // primary clock    
    input logic reset_n);       // asynchronous digital reset (active low)

// define states
enum logic [2:0] // explicit state definitions
            {IDLE               = 3'h0,
            READY               = 3'h1,
            GET_FIFO_DATA       = 3'h2,
            WAIT_STATE          = 3'h3,
            CHECK_BROADCAST     = 3'h4,
            BROADCAST_WAIT      = 3'h5,
            TRANSFER_BROADCAST  = 3'h6,
            TRANSFER            = 3'h7} State, Next;

// internal registers
logic [6:0] timeout; // keeps state machine from hanging if all TX off
//logic [15:0] which_larpix; // current TX to access
logic [5:0] broadcast_timer;

// decode target LArPix
always_comb begin
//    which_larpix = (1'b1 << target_larpix);
    if (broadcast) begin
        for (int i = 0; i < 16; i++) begin
            tx_data[i] = fifo_out;
        end
    end
    else begin
        for (int i = 0; i < 16; i++) begin
            if (i == target_larpix) 
                tx_data[i] = fifo_out;
            else
                tx_data[i] = '0;
        end
    end
end // always_comb

always_ff @(posedge clk or negedge reset_n)
    if (!reset_n)
        State <= IDLE;
    else
        State <= Next;

always_comb begin
    Next = IDLE;
    case (State)
        IDLE:   if (!(&tx_busy))    Next = READY; // is UART TX ready?
                else                Next = IDLE;
        READY:  if (!fifo_empty)    Next = GET_FIFO_DATA;
                else                Next = READY;
        GET_FIFO_DATA:              Next = WAIT_STATE;
        WAIT_STATE:                 Next = CHECK_BROADCAST;
        CHECK_BROADCAST: if (broadcast) Next = TRANSFER_BROADCAST;
                   else if (tx_busy[target_larpix]) Next = CHECK_BROADCAST;
                   else             Next = TRANSFER;
        BROADCAST_WAIT:  if (broadcast_timer == 6'h3F) 
                                    Next = TRANSFER_BROADCAST;
                            else    Next = BROADCAST_WAIT;
        TRANSFER_BROADCAST: if (timeout == 6'h3F)
                                    Next = IDLE;
                            else    Next = TRANSFER_BROADCAST;
        TRANSFER: if (timeout == 6'h3F)      
                                    Next = IDLE;
                  else              Next = TRANSFER;
    endcase
end // always

// registered outputs
always_ff @(posedge clk  or negedge reset_n)
    if (!reset_n) begin
        read_fifo_n <= 1'b1;
        ld_tx_data <= '0;
        timeout <= '0;
        broadcast_timer = '0;
    end else begin
        read_fifo_n <= 1'b1;
        ld_tx_data <= '0;
        timeout <= '0;
        broadcast_timer = '0;
        case(Next)
            IDLE:           ;       
            READY:          ;
            GET_FIFO_DATA:  begin 
                                read_fifo_n <= 1'b0;
                            end
            WAIT_STATE:     ;
            CHECK_BROADCAST: ;
            BROADCAST_WAIT: begin
                                broadcast_timer <= broadcast_timer + 1'b1;
                            end
             
            TRANSFER_BROADCAST: begin
                                    ld_tx_data <= 16'hFF;
                                    timeout <= timeout + 1'b1;
                                end                                
            TRANSFER:       begin
                                ld_tx_data[target_larpix] <= 1'b1; 
//                                ld_tx_data <= 1'b1;
                                timeout <= timeout + 1'b1;
                            end
            default:        ;
        endcase
    end // always_ff
     
endmodule
