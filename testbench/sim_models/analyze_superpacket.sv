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
    input logic bypass_8b10b_enc,    // high to bypass 8b10 encoder 
    input logic simulation_done, // high if simulation finished
    input logic reset_n         // active low reset
    );

// internal signals
logic [63:0] packet_number;     // tagged input signal to scoreboard
logic [2:0] rcvd_packet_declare; // 0 = bypass 1 = data, 2 = idle, 3 = test
logic rcvd_which_fifo;          //  0 = config_fifo, 1 = data_fifo
logic [4:0]rcvd_fifo_usage;          // number of FIFO locations in use
logic [2:0] rcvd_chip_id;       // which specific MADCAP is this?
logic [3:0] rcvd_channel_id;    // which channel?
logic [63:0] rcvd_larpix_payload; // 64-bit LArPix message
logic [7:0] rcvd_crc_word;      // Maxim 1-wire CRC8 word
logic [15:0] total_data_packets; // total number of data packets
logic [15:0] total_idle_packets; // total number of idle packets
logic [15:0] total_test_packets; // total number of test packets
logic [15:0] total_bypass_packets; // total number of bypass packets
logic [15:0] total_packets;      // total number of packets
logic [15:0] total_errors;       // total number of packets errors

logic [7:0] expected_crc_word;      // Maxim 1-wire CRC8 word
logic check_crc;            // high to check LArPix CRC
logic crc_error;            // high when error in crc

logic [7:0] madcap_reg_addr;    // address of MADCAP regmap location
logic [7:0] madcap_reg_data;    // data in MADCAP regmap location
logic [7:0] larpix_reg_addr;    // address of LArPix regmap location
logic [7:0] larpix_reg_data;    // data in LArPix regmap location

logic verbose;

initial begin
    check_crc = 1;
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
    madcap_reg_addr     = '0;
    madcap_reg_data     = '0;
    larpix_reg_addr     = '0;
    larpix_reg_data     = '0;
    verbose             = 1;
end

// classify superpacket
always @(posedge new_superpacket) begin
    #10
    if (bypass_8b10b_enc) rcvd_packet_declare = 0; 
    else if (( (superpacket[7:0] == `K_F) ||
               (superpacket[7:0] == `K_S) ||
               (superpacket[7:0] == `K_T) )
               && (k_out[1:0] == 2'b01) ) begin
        rcvd_packet_declare = 1; // data
        rcvd_which_fifo     = superpacket[8];
        rcvd_fifo_usage     = superpacket[13:9];
        rcvd_chip_id        = superpacket[16:14];
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
    if (verbose) begin
        $display("\n--------------------");
        $display("Superpacket Number: %0d",packet_number);
    end
    packet_number++;
    if (packet_number > 1) // allow channel to flush
    case(rcvd_packet_declare)
        0:  begin // BYPASS
                total_bypass_packets++;
                $display("bypassed 8b10b"); 
                $display("received superpacket = %h",superpacket);
            end
        1:  begin  // DATA
                total_data_packets++;
                $display("Data superpacket #%d",total_data_packets);
                $display("MC Chip ID = %d",rcvd_chip_id);
                $display("MC Channel ID = %d",rcvd_channel_id);  
                if (rcvd_which_fifo == 1)
                    $display("Data FIFO usage reported:");
                else
                    $display("Config FIFO usage reported:");
                $display("FIFO usage = %d",rcvd_fifo_usage);
                $display("LArPix payload = %h",rcvd_larpix_payload);
                $display("LP: packet dec = %d",rcvd_larpix_payload[1:0]);
                $display("LP: chip id = %d",rcvd_larpix_payload[9:2]);
                $display("LP: chan id = %d",rcvd_larpix_payload[15:10]);
                $display("LP: timestamp = %h",rcvd_larpix_payload[47:16]);
                $display("LP: data word = %d",rcvd_larpix_payload[55:48]);
                $display("LP: trig type = %d",rcvd_larpix_payload[57:56]);
                $display("LP: local fifo = %b",rcvd_larpix_payload[59:58]);
                $display("LP: shared fifo = %b",rcvd_larpix_payload[61:60]);
                $display("LP: downstream = %b",rcvd_larpix_payload[62]);
                $display("CRC word = %h",rcvd_crc_word);
                if ( (rcvd_larpix_payload[1:0] == 2'b01)
                    && (rcvd_larpix_payload[26] == 1'b1) ) begin
                    $display("MADCAP Config Read:");
                    madcap_reg_addr = rcvd_larpix_payload[15:8];
                    madcap_reg_data = rcvd_larpix_payload[23:16];
                    $display("MADCAP Regmap Address = %d",madcap_reg_addr);
                    $display("MADCAP Regmap Data = 0x%h",madcap_reg_data);
                end
                if  (rcvd_larpix_payload[1:0] == 2'b11) begin
                    $display("LArPix Config Read:");
                    larpix_reg_addr = rcvd_larpix_payload[17:10];
                    larpix_reg_data = rcvd_larpix_payload[25:18];
                    $display("LArPix Regmap Address = %d",larpix_reg_addr);
                    $display("LArPix Regmap Data = 0x%h",larpix_reg_data);
                end

            end
        2:  begin // Idle
                total_idle_packets++;
                if (verbose) 
                    $display("Idle superpacket #%d",total_idle_packets);
                if (superpacket[7:0] == `K_Q) begin
                    $display("Config FIFO Full symbol detected");
                end
                if (superpacket[7:0] == `K_A) begin
                    $display("Config FIFO half symbol detected");
                end
                 if (superpacket[7:0] == `K_T) begin
                    $display("Data FIFO half symbol detected");
                end           
                if (superpacket[7:0] == `K_S) begin
                    $display("Data FIFO half symbol detected");
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
                else 
                    $display ("testmode 110: test superpacket");
            end
    endcase
    else $display("flush data stream. Not real superpacket.");
end // always

// CRC check
always @(expected_crc_word) begin
    if (check_crc == 1) begin
        $display("CRC check:");
        $display("Expected CRC: %h",expected_crc_word);
        $display("Received CRC: %h",rcvd_crc_word);
        end
        
        if (rcvd_crc_word != expected_crc_word) begin
            $display("CRC ERROR");
        end
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

crc_check 
    crc_check_inst (
    .crc_error      (crc_error),
    .crc_new        (expected_crc_word),
    .rcvd_packet    (rcvd_larpix_payload),
    .rcvd_crc       (rcvd_crc_word),
    .check_crc      (check_crc),
    .reset_n        (reset_n)
    );
             
endmodule 
                 
          
