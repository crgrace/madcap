///////////////////////////////////////////////////////////////////
// File Name: data_packet_builder.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Finite state machine builds output data packets and
//              sends to serializer when ready
//   
//              Test Modes:
//              testmode[2:0] | Description
//             ------------------------------------
//              000     Normal operaton
//              001     Low-Frequency test pattern (K28.7)
//              010     Mixed-Frequency test pattern (K28.5)
//              011     High-Frequency test pattern (D21.5)
//              100     Alternate comma (K28.3)
//              101     Alternate comma (K28.0)
//              110     Modified RPAT (to stress channel) from 802.3 
//              111     Test Packet (user must handle CRC generation)
//
//              Marker codes:
//              Idle code (comma)               : K28.5  (K_K)
//              Start byte ( nomial data packet): K28.7  (K_F)
//              In data packets:
//              Config half-full marker symbol  : K29.7  (K_T)
//              Config full marker symbol       : K27.7  (K_S)
//              
//              In idle packets
//              Config half-full marker symbol  : K28.3  (K_A)
//              Config full marker symbol       : K28.4  (K_Q)
//
//
//              Outputs are registered to avoid glitches and to
//              standardize input and output delay constraints.
//
///////////////////////////////////////////////////////////////////
`include "../testbench/tasks/k_codes.sv"
module data_packet_builder 
    #(parameter WIDTH = 64)
    (output logic [95:0] output_packet, // superpacket to send to tx
    output logic [11:0] k_in,           // high per byte for k-codes
    output logic enable_8b10b,          // enable 8b10b encoder 
    input logic [WIDTH-1:0] rx_data,    // data from data fifo (w/o parity)
    input logic [3:0] channel_id,       // channel id from rx fifo
    input logic [1:0] chip_id,          // unique id for each MADCAP chip
    input logic packet_rcvd,            // high to acknowledge packet rcvd 
    input logic [4:0] rx_fifo_cnt,      // FIFO usage when FIFO read
    input logic [4:0] config_fifo_cnt,  // FIFO usage when FIFO read
    input logic which_fifo,             // 0 = config_fifo, 1 = data_fifo
    input logic [1:0] enable_fifo_panic,// 0 = idle packets, 1 = data
    input logic config_fifo_half,       // high if config fifo half full 
    input logic config_fifo_full,       // high if config fifo full 
    input logic build_data,             // high to initiate data packet
    input logic build_k,                // high to initiate k (idle) packet
    input logic [2:0] test_mode,        // control various test modes
    input logic [95:0] test_packet,     // user data to send to 8b10b 
    input logic [7:0] crc_word,         // CRC-8 hash of rx_data         
    input logic clk,                    // primary clock
    input logic reset_n);               // asynchronous reset (active low)


localparam COUNT_WIDTH = $clog2(WIDTH); // # of bits in tx packet range

// define states 

enum logic [2:0] // explicit state definitions
            {READY      = 3'h0,
            BUILD_TEST  = 3'h1,
            BUILD_DATA  = 3'h2,
            BUILD_K     = 3'h3,
            SEND_PACKET = 3'h4,
            IDLE        = 3'h5} State, Next;
            
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        State <= READY;
    else
        State <= Next;
end // always_ff

always_comb begin
    Next = READY;
    case (State)
        READY:  if      (test_mode != 3'b000)   Next = BUILD_TEST;
                else if (build_data)            Next = BUILD_DATA; 
                else if (build_k)               Next = BUILD_K;    
                else                            Next = READY;
        BUILD_TEST:                             Next = SEND_PACKET;
        BUILD_DATA:                             Next = SEND_PACKET;
        BUILD_K:                                Next = SEND_PACKET;
        SEND_PACKET:                            Next = IDLE;
        IDLE:   if (packet_rcvd)                Next = READY;
        default:                                Next = READY;
    endcase
end // always_comb

// registered outputs
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        output_packet <= '0;
        k_in <= '0;  
        enable_8b10b <= 1'b0;
    end
    else begin
      //  k_in <= '0;
        enable_8b10b <= 1'b0;
        case (Next)
        READY:       ; 
        BUILD_TEST: begin
                        if (test_mode == 3'b001) begin 
                            output_packet = {12{`K_F}}; // send K28.7
                            k_in <= 12'hFFF;
                        end
                        else if (test_mode == 3'b010) begin
                            output_packet = {12{`K_K}}; // send K28.5
                            k_in <= 12'hFFF;
                        end
                        else if (test_mode == 3'b011) begin
                            output_packet = {12{`D_21_5}}; // send D21.5
                            k_in <= '0;
                        end
                        else if (test_mode == 3'b100) begin
                            output_packet = {12{`K_A}}; // send K28.3
                            k_in <= 12'hFFF;
                        end
                        else if (test_mode == 3'b101) begin
                            output_packet = {12{`K_R}}; // send K28.0
                            k_in <= 12'hFFF;
                        end
                        else if (test_mode == 3'b110) begin
                            output_packet = `RPAT;  // 802.3 modified RPAT
                            k_in <= 12'h000;
                        end
                        else if (test_mode == 3'b111) begin
                            output_packet = test_packet;
                            k_in <= 12'h000;
                        end
                    end
        BUILD_DATA: begin
                            output_packet[95:88]    <= crc_word;
                            output_packet[87:24]    <= rx_data;
                            output_packet[23:20]    <= channel_id;
                            output_packet[19:17]    <= 4'b0000;
                            output_packet[15:14]    <= chip_id;
                            if (which_fifo)
                                output_packet[13:9]     <= rx_fifo_cnt;
                            else
                                output_packet[13:9]     <= config_fifo_cnt;
                            output_packet[8]        <= which_fifo;
                            output_packet[7:0]      <= `K_F;
                            if (config_fifo_full && 
                                enable_fifo_panic[1]) begin
                                output_packet[7:0] <= `K_S;
                            end
                            else if (config_fifo_half &&
                                    enable_fifo_panic[1]) begin
                                output_packet[7:0] <= `K_T;
                            end
                            k_in <= 12'h001;
                    end
        BUILD_K: begin
                        k_in <= 12'hFFF;
                        output_packet[95:0] <= {12{`K_K}};
                        if (config_fifo_full && 
                            enable_fifo_panic[0]) begin
                            output_packet[7:0] <= `K_Q;
                        end
                        else if (config_fifo_half && 
                            enable_fifo_panic[0]) begin
                            output_packet[7:0] <= `K_A;
                        end
                     end
        SEND_PACKET: begin
                        enable_8b10b <= 1'b1;
                     end
        IDLE:       ;
        default:    ;
        endcase
    end
end // always_ff                                ;
                     
endmodule
