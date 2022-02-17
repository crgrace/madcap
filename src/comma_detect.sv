///////////////////////////////////////////////////////////////////
// File Name: comma_detect.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Correlate data stream to find idle codes (K28.5) and 
//              locate 8b10b symbol boundary 
//              
//              Also scans for: 
//              K28.7 comma codes (used to mark first byte in a packet)
//              K28.0 comma codes (used to request a trigger for LArPix)
//              K28.4 comma codes (used to request LArPix soft reset
//              K27.7 comma codes (used to request LArPix hard reset
//              K28.7 comma codes (used to request MADCAP hard reset
//     
///////////////////////////////////////////////////////////////////
`include "../testbench/tasks/k_codes.sv"
module comma_detect
    (output logic symbol_start,         // high for symbol edge bit
    output logic symbol_locked,         // deserializer synchronized
    output logic comma_found,           // high when comma (K28.7) found
    output logic lp_trigger_found,         // high when K28.0 found
    output logic lp_soft_rst_found,     // high if K28.4 (K_Q) found
    output logic lp_hard_rst_found,     // high if K27.7 (K_S) found
    output logic lp_timestamp_rst_found, // high if K28.3 (K_A) found
    output logic mc_rst_found,          // high if K28.7 (K_T) found
    input logic [9:0] dataword10b,      // 10b symbol under test
    input logic dataword10b_ready,      // data ready to sample
    input logic start_sync,             // start sync (also starts on rst)
    input logic sync_in,                // external sync pulse 
    input logic clk,                    // MADCAP primary clk
    input logic reset_n);               // digital reset (active low)

logic [3:0] bit_cnt;            // bit counter
logic [3:0] symbol_start_loc;   // where is the symbol edge
logic idle_found;               // high if K28.5 (K_K) found
logic [4:0] sync_cnt;           // clocks since sync_in received  
logic en_sync_cnt;              // high if counting  

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        en_sync_cnt <= '0;
    end
    else begin
        if (sync_in) 
            en_sync_cnt <= 1'b1;
        else
            if (sync_cnt == 4'b1111)
                en_sync_cnt <= 1'b0;
    end
end // always

// sync_count
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        sync_cnt <= '0;
    end
    else begin
        if (sync_in)
            sync_cnt <= '0;
        else if (en_sync_cnt) 
            sync_cnt <= sync_cnt + 1'b1;
        else
            sync_cnt <= '0;
    end
end // always

// bit counter
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        bit_cnt <= '0;
    end
    else begin
        if ( en_sync_cnt || (bit_cnt == 4'b1001) )
            bit_cnt <= '0;
        else
            bit_cnt <= bit_cnt + 1'b1;
    end
end // always_ff

// symbol start selector
always_comb
    if (sync_in == 1'b1)
        symbol_start = 1'b1;
    else if (!en_sync_cnt && (bit_cnt == symbol_start_loc))
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

// identify k-codes
always_comb begin
    idle_found = ( (dataword10b == `K_K_DISP_N) || 
                   (dataword10b == `K_K_DISP_P));
    comma_found = ( (dataword10b == `K_F_DISP_N) || 
                    (dataword10b == `K_F_DISP_P));
    lp_trigger_found = ( (dataword10b == `K_R_DISP_N) || 
                    (dataword10b == `K_R_DISP_P));
    lp_timestamp_rst_found = ( (dataword10b == `K_A_DISP_N) || 
                    (dataword10b == `K_A_DISP_P));
    lp_soft_rst_found = ( (dataword10b == `K_Q_DISP_N) || 
                    (dataword10b == `K_Q_DISP_P));
    lp_hard_rst_found = ( (dataword10b == `K_S_DISP_N) || 
                    (dataword10b == `K_S_DISP_P));
    mc_rst_found = ( (dataword10b == `K_T_DISP_N) || 
                    (dataword10b == `K_T_DISP_P));
end
         
always_comb begin
    Next = RESET;
    case (State)
        RESET:                          Next = CHECK_FOR_DATA;          
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
        UPDATE_START:   
                        // we increment before test, so if we find a comma
                        // we need to roll back the setting
                        if (idle_found)
                            if (symbol_start_loc == 0000)
                                symbol_start_loc <= 4'b1001;
                            else      
                                symbol_start_loc <= symbol_start_loc - 1'b1;
                        else begin
                            symbol_start_loc <= symbol_start_loc + 1'b1;
                            if (symbol_start_loc == 4'b1001)
                                symbol_start_loc <= '0;
                        end
        DONE:           
                        symbol_locked <= 1'b1;
        default:            ;
        endcase
    end
end // always_ff

endmodule                               
