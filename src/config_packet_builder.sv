///////////////////////////////////////////////////////////////////
// File Name: config_packet_builder.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Pulls decoded 8b/10b words out of the datasteam
//              and assembles configuration packets and then either:
//              1. loads data into config registers
//              2. dumps LArPix config data into the config FIFO
//     
///////////////////////////////////////////////////////////////////
`include "../testbench/tasks/k_codes.sv"
module config_packet_builder 
    (output logic [63:0] larpix_packet, // config packet for LArPix
    output logic [67:0] madcap_packet, // return MADCAP config data
    output logic symbol_locked,         // deserializer synchronized
    output logic [7:0] regmap_write_data, // data to write to regmap
    output logic [7:0] regmap_address, // regmap addr to write
    output logic write_regmap,    // active high to load register data
    output logic read_regmap,       // active high to read register data    
    input logic [7:0] dataword      ,   // current 8b symbol
    input logic [7:0] regmap_read_data, // data to read from regmap
    input logic k_in,                   // high to indicate k code
    input logic clk,                    // MADCAP primary clk
    input logic reset_n);               // digital reset (active low)

    
logic [3:0] bit_cnt;            // bit counter
logic [3:0] symbol_start_loc;    // where is the symbol edge
logic comma_found;              // high if K28.5 detected

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

always_comb 
    comma_found = ((dataword == `K_K_DISP_N) || (dataword == `K_K_DISP_P));

always_comb begin
    Next = RESET;
    case (State)
        RESET:      if (external_sync)  Next = RESET;             
                else                    Next = CHECK_FOR_DATA;
        CHECK_FOR_DATA: if (dataword_ready) Next = CHECK_SYMBOL;
                else                    Next = CHECK_FOR_DATA;
        CHECK_SYMBOL:                   Next = UPDATE_START;
        UPDATE_START: if (comma_found)  Next = DONE;    
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
                        else if (comma_found)    
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
