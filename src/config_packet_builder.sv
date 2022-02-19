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
module config_packet_builder 
    (output logic [63:0] larpix_packet,  // config packet (either chip) 
    output logic [7:0] regmap_write_data,   // data to write to regmap
    output logic [7:0] regmap_address,  // regmap addr to write
    output logic write_regmap,          // high to load register data
    output logic read_regmap,           // high to read register data
    output logic write_fifo_config_n,   // low to put data into config FIFO
    output logic write_fifo_data_req,   // high to req data into data FIFO
    input logic [7:0] dataword8b,       // current 8b symbol
    input logic [7:0] regmap_read_data, // data to read from regmap
    input logic [1:0] chip_id,          // id for current MADCAP 
    input logic ack_fifo_data,          // acknowledge from data FIFO
    input logic dataword8b_ready,       // data ready to sample
    input logic comma_found,            // high when comma (K28.5) found    
    input logic clk,                    // MADCAP primary clk
    input logic reset_n);               // digital reset (active low)


// local signals
logic done;                 // high if new packet received
logic byte_cnt_en;          // high to increment byte counter on next clk
logic byte_cnt_clear;       // high to clear byte counter on next clk
logic [39:0] rcvd_packet;   // packet received from PACMAN
logic [2:0] byte_cnt;       // which byte in packet just received
logic [7:0] rcvd_bytes [4:0]; // 5 bytes make a received packet
                            // (we strip off the start byte)
// byte counter
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        byte_cnt <= '0;
    end
    else begin
        if (byte_cnt_en)  
            byte_cnt <= byte_cnt + 1'b1;
        else if (byte_cnt_clear)
            byte_cnt <= '0;
        else 
            byte_cnt <= byte_cnt;
    end
end // always_ff

always_comb begin 
    done = (byte_cnt == 3'b101);
    rcvd_packet =   {rcvd_bytes[4],rcvd_bytes[3]
                    ,rcvd_bytes[2],rcvd_bytes[1]
                    ,rcvd_bytes[0]
                    };
end // always_comb

// state machine
enum logic [3:0] // explicit state definitions 
            {WAIT_FOR_COMMA     = 4'h0,
            WAIT_FOR_BYTE       = 4'h1,
            GET_NEXT_BYTE       = 4'h2,
            WRITE_REGMAP        = 4'h3,
            READ_REGMAP         = 4'h4,
            LATCH_DATA          = 4'h5,
            BUILD_DATA          = 4'h6,
            BUILD_LARPIX        = 4'h7,
            LOAD_FIFO_DATA      = 4'h8,
            LOAD_FIFO_CONFIG    = 4'h9} State, Next;

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        State <= WAIT_FOR_COMMA;
    else
        State <= Next;
end // always_ff


always_comb begin
    Next = WAIT_FOR_COMMA;
    case (State)
        WAIT_FOR_COMMA: if (comma_found)    Next = WAIT_FOR_BYTE;
                else                        Next = WAIT_FOR_COMMA;
        WAIT_FOR_BYTE:  if (dataword8b_ready) Next = GET_NEXT_BYTE;
                else                        Next = WAIT_FOR_BYTE;
        GET_NEXT_BYTE: if (done && rcvd_packet[1] == 1'b0) 
                                            Next = BUILD_LARPIX;
                else if (done 
                            && (rcvd_packet[1:0] == 2'b10)
                            && ((rcvd_packet[3:2] == chip_id)
                            || (rcvd_packet[3:2] == 2'b11)))     
                                            Next = WRITE_REGMAP;
                else if (done 
                            && (rcvd_packet[1:0] == 2'b11)
                            && ((rcvd_packet[3:2] == chip_id)
                            || (rcvd_packet[3:2] == 2'b11)))
                                            Next = READ_REGMAP;
                else if (done)              Next = WAIT_FOR_COMMA;
                else                        Next = WAIT_FOR_BYTE;
        WRITE_REGMAP:                       Next = WAIT_FOR_COMMA;
        READ_REGMAP:                        Next = LATCH_DATA;
        LATCH_DATA:                         Next = BUILD_DATA;
        BUILD_DATA:                         Next = LOAD_FIFO_DATA;
        BUILD_LARPIX:                       Next = LOAD_FIFO_CONFIG;
        LOAD_FIFO_DATA: if (ack_fifo_data)  Next = WAIT_FOR_COMMA;
                else                        Next = LOAD_FIFO_DATA;    
        LOAD_FIFO_CONFIG:                   Next = WAIT_FOR_COMMA;    
        default:                            Next = WAIT_FOR_COMMA;
    endcase
end // always

// registered outputs
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        byte_cnt_en <= 1'b0;
        byte_cnt_clear <= 1'b1;
        write_fifo_config_n <= 1'b1;    
        write_fifo_data_req <= 1'b0;    
        write_regmap <= 1'b0;
        read_regmap <= 1'b0;
        regmap_address <= '0;
        regmap_write_data <= '0;
        larpix_packet <= '0;
        rcvd_bytes[0] <= '0;
        rcvd_bytes[1] <= '0;
        rcvd_bytes[2] <= '0;
        rcvd_bytes[3] <= '0;   
        rcvd_bytes[4] <= '0;   
    end
    else begin
        byte_cnt_en <= 1'b0;
        byte_cnt_clear <= 1'b1;
        write_fifo_config_n <= 1'b1;    
        write_fifo_data_req <= 1'b0;    
        write_regmap <= 1'b0;
        read_regmap <= 1'b0;
        regmap_address <= '0;
        regmap_write_data <= '0;
        case (Next)
        WAIT_FOR_COMMA: begin
                            larpix_packet <= '0;
                            rcvd_bytes[0] <= '0;
                            rcvd_bytes[1] <= '0;
                            rcvd_bytes[2] <= '0;
                            rcvd_bytes[3] <= '0;
                            rcvd_bytes[4] <= '0;
                        end
        WAIT_FOR_BYTE:  begin
                            byte_cnt_clear <= 1'b0;
                        end
       GET_NEXT_BYTE:  begin
                            byte_cnt_en <= 1'b1;
                            byte_cnt_clear <= 1'b0;
                            rcvd_bytes[byte_cnt] <= dataword8b;
                        end
        WRITE_REGMAP:   begin        
                            regmap_address <= rcvd_packet[15:8];
                            regmap_write_data <= rcvd_packet[23:16];
                            write_regmap <= 1'b1;
                        end
        READ_REGMAP:    begin
                            regmap_address <= rcvd_packet[15:8];
                            read_regmap <= 1'b1;
                        end
        LATCH_DATA:    ;
        BUILD_DATA:     begin
                            larpix_packet[1:0] <= 2'b01; // config read
                            larpix_packet[4:2] <= rcvd_packet[4:2];
                            larpix_packet[7:5] <= 3'b000;
                            larpix_packet[15:8] <= regmap_address;
                            larpix_packet[23:16] <= regmap_read_data;
                            larpix_packet[26] = 1'b1;
                        end
        BUILD_LARPIX:   begin
                            // lowest 5 bits of MADCAP packet are MADCAP
                            // specific, so shift two bits because
                            // rcvd_packet[5] corresponds to 
                            // larpix_packet[0] in the larpix_v2b datasheet
                            larpix_packet[25:0] <= rcvd_packet[31:5];
                            // record target LArPix
                            larpix_packet[29:26] <= rcvd_packet[35:32];
                            if (rcvd_packet[1:0] == 2'b01) // broadcast 
                                larpix_packet[30] <= 1'b1;
                        end
        LOAD_FIFO_DATA: begin
                            write_fifo_data_req <= 1'b1;
                        end     
        LOAD_FIFO_CONFIG: begin
                            write_fifo_config_n <= 1'b0;
                            // calculate parity bit, just in case we use
                            // it in a future LArPix version
                            larpix_packet[63] = ~^larpix_packet[62:0];
                        end          
        default:            ;
        endcase
    end
end // always_ff

endmodule                               
