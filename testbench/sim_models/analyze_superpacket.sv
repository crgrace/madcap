///////////////////////////////////////////////////////////////////
// File Name: anaylze_superpacket.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Simulation model to analyze received MADCAP superpacket 
///////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "../testbench/tasks/k_codes.sv"
module analyze_superpacket
    (input [95:0] superpacket,  // superpacket from MADCAP (after 8b10b)
    input logic new_superpacket, // high when new superpacket available
    input logic which_fifo,     // 0 = config fifo, 1 = data fifo
    input logic [11:0] k_out,   // high if corresponding byte is K-code
    input logic bypass_8b10b,    // high to bypass 8b10 encoder 
    input logic simulation_done // high if simulation finished
    );

// internal signals
logic [63:0] packet_number;     // tagged input signal to scoreboard
logic [2:0] rcvd_packet_declare; // 0 = bypass 1 = data, 2 = idle, 3 = test
logic rcvd_which_fifo;          //  0 = config_fifo, 1 = data_fifo
logic [4:0]rcvd_fifo_usage;          // number of FIFO locations in use
logic [5:0] rcvd_chip_id;       // which specific MADCAP is this?
logic [3:0] rcvd_channel_id;    // which channel?
logic [63:0] rcvd_larpix_payload; // 64-bit LArPix message
logic [7:0] rcvd_crc_word;      // Maxim 1-wire CRC8 word
logic [15:0] total_data_packets; // total number of data packets
logic [15:0] total_idle_packets; // total number of idle packets
logic [15:0] total_test_packets; // total number of test packets
logic [15:0] total_bypass_packets; // total number of bypass packets
logic [15:0] total_packets;      // total number of packets
logic [15:0] total_errors;       // total number of packets errors
initial begin
    packet_number = '0;
    rcvd_packet_declare = 0; // data
    rcvd_which_fifo     = 0;
    rcvd_fifo_usage     = '0;
    rcvd_chip_id        = '0;
    rcvd_channel_id     = '0;
    rcvd_larpix_payload = '0;
    rcvd_crc_word       = '0;
    total_data_packets  = '0;
    total_idle_packets  = '0;
    total_test_packets  = '0;
    total_bypass_packets  = '0;
    total_packets       = '0;
    total_errors        = '0;
end

// classify superpacket
always @(posedge new_superpacket) begin
    #10
    if (bypass_8b10b) rcvd_packet_declare = 0; 
    else if (( (superpacket[7:0] == `K_F) ||
               (superpacket[7:0] == `K_S) ||
               (superpacket[7:0] == `K_T) )
               && (k_out[1:0] == 2'b01) ) begin
        rcvd_packet_declare = 1; // data
        rcvd_which_fifo     = superpacket[8];
        rcvd_fifo_usage     = superpacket[13:9];
        rcvd_chip_id        = superpacket[19:14];
        rcvd_channel_id     = superpacket[23:20];
        rcvd_larpix_payload = superpacket[87:24];
        rcvd_crc_word       = superpacket[95:88];
    end 
    else if ((superpacket[7:0] == {`K_K}) && (k_out == 12'hFFF) ) 
        rcvd_packet_declare = 2; // idle   
    else if ((superpacket[7:0] == {`K_A}) && (k_out == 12'hFFF) )
        rcvd_packet_declare = 2; // idle 
    else if ((superpacket[7:0] == {`K_Q}) && (k_out == 12'hFFF) )
        rcvd_packet_declare = 2; // idle 
    else rcvd_packet_declare = 3; // test
end // always
    
// analyze superpacket
always @(posedge new_superpacket) begin
    #10
    $display("\n--------------------");
//    $display("\nData Received: %h",superpacket);
    $display("Superpacket Number: %0d",packet_number++);
    if (packet_number > 1) // allow channel to flush
    case(rcvd_packet_declare)
        0:  begin // BYPASS
                total_bypass_packets++;
                $display("bypassed 8b10b"); 
                $display("received superpacket = %h",superpacket);
            end
        1:  begin  // DATA
                total_data_packets++;
                $display("Data superpacket");
                $display("Chip ID = %d",rcvd_chip_id);
                $display("Channel ID = %d",rcvd_channel_id);  
                if (which_fifo == 1)
                    $display("data FIFO usage reported:");
                else
                    $display("config FIFO usage reported:");
                $display("FIFO usage = %d",rcvd_fifo_usage);
                $display("LArPix payload = %h",rcvd_larpix_payload);
                $display("CRC word = %h",rcvd_crc_word);
            end
        2:  begin // Idle
                total_idle_packets++;
                $display("Idle superpacket");
                if (superpacket[7:0] == `K_Q) begin
                    $display("Config FIFO Full symbol detected");
                end
                if (superpacket[7:0] == `K_A) begin
                    $display("Config FIFO half symbol detected");
                end
            end
        3:  begin // TEST
                total_test_packets++;
                $display("Test superpacket");
                if (superpacket[7:0] == `K_F) begin
                    $display("testmode 001: K_F");
                end
                else if (superpacket[7:0] == `K_K) begin
                    $display("testmode 010: K_K");
                    $display("in here! 7:0] = %b ",superpacket[7:0]);
                end
                else if (superpacket[7:0] == `D_21_5) begin
                    $display("testmode 011: D21.5");
                end
                else if (superpacket[7:0] == `K_R) begin
                    $display("testmode 101: K_R");
                end
                else if (superpacket[95:0] == `RPAT) begin
                    $display("testmode 110: RPAT");
                end
                else $display ("testmode 110: test superpacket");
            end
    endcase
    else $display("flush data stream. Not real superpacket.");
end // always

always @(posedge simulation_done) begin
    total_packets = total_idle_packets + total_data_packets + 
                    total_test_packets + total_bypass_packets;
    $display("\n------ Simulation Complete ------ ");
    $display("Idle Packets Received = %d",total_idle_packets);
    $display("Data Packets Received = %d",total_data_packets);
    $display("Test Packets Received = %d",total_test_packets);
    $display("Bypass Packets Received = %d",total_bypass_packets); 
    $display("Total Packets         = %d",total_packets);
    $display("Total Errors          = %d",total_errors);
end // always
             
endmodule 
                 
          
