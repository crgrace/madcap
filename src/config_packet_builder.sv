///////////////////////////////////////////////////////////////////
// File Name: config_packet_builder.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Pulls decoded 8b/10b words out of the datasteam
//              and assembles configuration packets and then either:
//              1. loads data into config registers
//              2. dumps LArPix config data into the config FIFO
//              3. puts requested madcap config data into data FIFO
//     
///////////////////////////////////////////////////////////////////
`include "../testbench/tasks/k_codes.sv"
module config_packet_builder 
    (output logic [63:0] larpix_packet,     // config packet for LArPix
    output logic [67:0] madcap_packet,      // return MADCAP config data
    output logic [7:0] regmap_write_data,   // data to write to regmap
    output logic [7:0] regmap_address,      // regmap addr to write
    output logic write_regmap,      // active high to load register data
    output logic read_regmap,       // active high to read register data
    output logic load_event_n_config, // low to put data into config FIFO
    output logic load_event_n_data,   // low to put data into data FIFO
    output logic madcap_packet_ready,       // high if packet ready    
    input logic [7:0] dataword      ,       // current 8b symbol
    input logic [7:0] regmap_read_data,     // data to read from regmap
    input logic k_in,                       // high to indicate k code
    input logic comma_found,        // high when comma (K28.5) found    
    input logic clk,                        // MADCAP primary clk
    input logic reset_n);                   // digital reset (active low)


// local signals
logic done;                 // high if new packet received
logic [31:0] rcvd_packet;   // packet received from PACMAN
logic [2:0] byte_cnt;       // which byte in packet just received

// byte counter
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        byte_cnt <= '0;
    end
    else begin
        if (byte_cnt_en)  
            byte_cnt <= byte_cnt + 1'b1;
        else
            byte_cnt <= '0;
    end
end // always_ff

always_comb begin
    done = (byte_cnt == 3'b100);

// state machine
enum logic [2:0] // explicit state definitions 
            {WAIT_FOR_COMMA     = 3'h0,
            GET_NEXT_BYTE       = 3'h1,
            BUILD_MADCAP        = 3'h2,
            WRITE_REGMAP        = 3'h3,
            READ_REGMAP         = 3'h4
            BUILD_LARPIX        = 3'h5,
            LOAD_FIFO           = 3'h6} State, Next;


always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        State <= WAIT_FOR_COMMA;
    else
        State <= Next;
end // always_ff


always_comb begin
    Next = WAIT_FOR_COMMA;
    case (State)
        WAIT_FOR_COMMA: if (comma_found)  Next = GET_NEXT_BYTE;
                else                    Next = WAIT_FOR_COMMA;
        GET_NEXT_BYTE: if (done && rcvd_packet[1] == 1'b0) 
                                        Next = BUILD_LARPIX;
                else if (done && rcvd_packet[1] == 1'b1) 
                                        Next = BUILD_MADCAP;
                else                    Next = GET_NEXT_BYTE;
        BUILD_MADCAP if (rcvd_packet[0] == 1'b0):
                                        Next = WRITE_REGMAP;
                     else
                                        Next = READ_REGMAP;
        WRITE_REGMAP:                   Next = WAIT_FOR_COMMMA;
        READ_REGMAP:                    Next = LOAD_FIFO            
        BUILD_LARPIX:                   Next = LOAD_FIFO;
        LOAD_FIFO:                      Next = WAIT_FOR_COMMA:    
        default:                        Next = WAIT_FOR_COMMA;
    endcase
end // always

// registered outputs
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        done <= 1'b0;
        byte_cnt_en <= 1'b0;
        load_event_n_config <= 1'b1;    
        load_event_n_data <= 1'b1;    
        write_regmap <= 1'b0;
        read_regmap <= 1'b0;
        regmap_address <= '0;
        regmap_write_data <= '0;
    end
    else begin
        done <= 1'b0;
        byte_cnt_en <= 1'b0;
        load_event_n_config <= 1'b1;    
        load_event_n_data <= 1'b1;    
        case (Next)
        WAIT_FOR_COMMA: 
        GET_NEXT_BYTE:  begin
                            byte_cnt_en <= 1'b1;
                            rcvd_packet[byte_cnt*8+7:byte_cnt*8]<=dataword;
                        end
        BUILD_LARPIX:   if (symbol_start_loc == 4'b1001)
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
