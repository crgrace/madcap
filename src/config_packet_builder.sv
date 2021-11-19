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
    (output logic [63:0] larpix_packet,     // config packet for LArPix
    output logic [67:0] madcap_packet,      // return MADCAP config data
    output logic [7:0] regmap_write_data,   // data to write to regmap
    output logic [7:0] regmap_address,      // regmap addr to write
    output logic write_regmap,      // active high to load register data
    output logic read_regmap,       // active high to read register data
    output logic write_fifo_config_n, // low to put data into config FIFO
    output logic write_fifo_data_n,   // low to put data into data FIFO
    input logic [7:0] dataword8b      ,       // current 8b symbol
    input logic [7:0] regmap_read_data,     // data to read from regmap
    input logic dataword8b_ready,      // data ready to sample
    input logic comma_found,        // high when comma (K28.5) found    
    input logic clk,                        // MADCAP primary clk
    input logic reset_n);                   // digital reset (active low)


// local signals
logic done;                 // high if new packet received
logic byte_cnt_en;
logic [31:0] rcvd_packet;   // packet received from PACMAN
logic [2:0] byte_cnt;       // which byte in packet just received
logic [7:0] rcvd_bytes [3:0]; // 4 bytes make a received packet
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
    rcvd_packet = {rcvd_bytes[3],rcvd_bytes[2],rcvd_bytes[1],rcvd_bytes[0]};
end // always_comb

// state machine
enum logic [2:0] // explicit state definitions 
            {WAIT_FOR_COMMA     = 3'h0,
            WAIT_FOR_BYTE       = 3'h1,
            GET_NEXT_BYTE       = 3'h2,
            WRITE_REGMAP        = 3'h3,
            READ_REGMAP         = 3'h4,
            BUILD_LARPIX        = 3'h5,
            LOAD_FIFO_DATA      = 3'h6,
            LOAD_FIFO_CONFIG    = 3'h7} State, Next;

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
                else if (done && rcvd_packet[1:0] == 2'b10) 
                                            Next = WRITE_REGMAP;
                else if (done && rcvd_packet[1:0] == 2'b11)
                                            Next = READ_REGMAP;
                else                        Next = WAIT_FOR_BYTE;
        WRITE_REGMAP:                       Next = WAIT_FOR_COMMA;
        READ_REGMAP:                        Next = LOAD_FIFO_DATA;
        BUILD_LARPIX:                       Next = LOAD_FIFO_CONFIG;
        LOAD_FIFO_DATA:                     Next = WAIT_FOR_COMMA;    
        LOAD_FIFO_CONFIG:                   Next = WAIT_FOR_COMMA;    
        default:                            Next = WAIT_FOR_COMMA;
    endcase
end // always

// registered outputs
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        byte_cnt_en <= 1'b0;
        write_fifo_config_n <= 1'b1;    
        write_fifo_data_n <= 1'b1;    
        write_regmap <= 1'b0;
        read_regmap <= 1'b0;
        regmap_address <= '0;
        regmap_write_data <= '0;
        madcap_packet <= '0;
        larpix_packet <= '0;
        rcvd_bytes[0] <= '0;
        rcvd_bytes[1] <= '0;
        rcvd_bytes[2] <= '0;
        rcvd_bytes[3] <= '0;   
    end
    else begin
        byte_cnt_en <= 1'b0;
        write_fifo_config_n <= 1'b1;    
        write_fifo_data_n <= 1'b1;    
        write_regmap <= 1'b0;
        read_regmap <= 1'b0;
        regmap_address <= '0;
        regmap_write_data <= '0;
        case (Next)
        WAIT_FOR_COMMA: begin
                            madcap_packet <= '0;
                            larpix_packet <= '0;
                            rcvd_bytes[0] <= '0;
                            rcvd_bytes[1] <= '0;
                            rcvd_bytes[2] <= '0;
                            rcvd_bytes[3] <= '0;
                        end
        GET_NEXT_BYTE:  begin
                            byte_cnt_en <= 1'b1;
                            rcvd_bytes[byte_cnt] <= dataword8b;
                        end
        WRITE_REGMAP:   begin        
                            regmap_address <= rcvd_packet[14:7];
                            regmap_write_data <= rcvd_packet[22:15];
                            write_regmap <= 1'b1;
                        end
        READ_REGMAP:    begin
                            madcap_packet[31:0] <= rcvd_packet;
                            madcap_packet[67:0] <= '0;
                            madcap_packet[22:15] <= regmap_read_data;
                        end

        BUILD_LARPIX:   begin
                            // lowest 2 bits of MADCAP packet are MADCAP
                            // specific, so shift two bits because
                            // rcvd_packet[2] corresponds to 
                            // larpix_packet[0] in the larpix_v2b datasheet
                            larpix_packet[25:0] <= rcvd_packet[27:2];
                            // record target LArPix
                            larpix_packet[29:26] <= rcvd_packet[31:28];
                        end
        LOAD_FIFO_DATA: begin
                            write_fifo_data_n <= 1'b0;
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
