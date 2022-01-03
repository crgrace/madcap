///////////////////////////////////////////////////////////////////
// File Name: comma_detect.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Correlate data stream to find idle codes (K28.5) and 
//              locate 8b10b symbol boundary 
//              
//              Also scans for K28.7 comma codes (used to mark first byte
//              in a packet)
//     
///////////////////////////////////////////////////////////////////
`include "../testbench/tasks/k_codes.sv"
module comma_detect
    (output logic symbol_start,         // high for symbol edge bit
    output logic symbol_locked,         // deserializer synchronized
    output logic comma_found,           // high when comma (K28.7) found
    input logic [9:0] dataword10b,      // 10b symbol under test
    input logic dataword10b_ready,      // data ready to sample
    input logic start_sync,             // start sync (also starts on rst)
    input logic external_sync,          // high for external sync
    input logic clk,                    // MADCAP primary clk
    input logic reset_n);               // digital reset (active low)

    
logic [3:0] bit_cnt;            // bit counter
logic [3:0] symbol_start_loc;   // where is the symbol edge
logic idle_found;               // high if K28.5 found

// bit counter
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        bit_cnt <= '0;
    end
    else begin
        if ( external_sync || (bit_cnt == 4'b1001) )
            bit_cnt <= '0;
        else if (!external_sync)
            bit_cnt <= bit_cnt + 1'b1;
    end
end // always_ff

// symbol start selector
always_comb
    if (bit_cnt == symbol_start_loc)
        symbol_start = 1'b1;
    else
        symbol_start = 1'b0;

// state machine
enum logic [2:0] // explicit state definitions 
            {RESET = 3'h0,
            CHECK_FOR_DATA  = 3'h1,
            GET_DATA        = 3'h2,
            CHECK_SYMBOL    = 3'h3,
            UPDATE_START    = 3'h4,
            DONE = 3'h5} State, Next;


always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n || start_sync)
        State <= RESET;
    else
        State <= Next;
end // always_ff

always_comb begin
    idle_found = ( (dataword10b == `K_K_DISP_N) || 
                   (dataword10b == `K_K_DISP_P));
    comma_found = ( (dataword10b == `K_F_DISP_N) || 
                    (dataword10b == `K_F_DISP_P));
   
end

always_comb begin
    Next = RESET;
    case (State)
        RESET:      if (external_sync)  Next = RESET;             
                else                    Next = CHECK_FOR_DATA;
        CHECK_FOR_DATA: if (dataword10b_ready) Next = CHECK_SYMBOL;
                else                    Next = CHECK_FOR_DATA;
        CHECK_SYMBOL:                   Next = UPDATE_START;
        UPDATE_START: if (idle_found)   Next = DONE;    
                else                    Next = CHECK_FOR_DATA;
        DONE:                           Next = DONE;
        default:                        Next = RESET;
    endcase
end // always

// registered outputs
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        symbol_locked <= 1'b0;
        symbol_start_loc <= 1'b0;
    end
    else begin
    symbol_locked <= 1'b0;
        case (Next)
        RESET: ;
        CHECK_FOR_DATA: ; 
        CHECK_SYMBOL: ;
        UPDATE_START:   if (symbol_start_loc == 4'b1001)
                            symbol_start_loc <= '0;
                        // we increment before test, so if we find a comma
                        // we need to roll back the setting
                        else if (idle_found)    
                            symbol_start_loc <= symbol_start_loc - 1'b1;
                        else
                            symbol_start_loc <= symbol_start_loc + 1'b1;
        DONE:           
                        symbol_locked <= 1'b1;
        default:            ;
        endcase
    end
end // always_ff

endmodule                               
