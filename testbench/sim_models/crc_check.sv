///////////////////////////////////////////////////////////////////
// File Name: crc_check.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Checks data integrity of LArPix packet using 
//          a LUT. 
//
///////////////////////////////////////////////////////////////////

module crc_check
    (output logic crc_error,            // high when error in crc
    output logic [7:0] crc_new,         // crc calculated from rcvd_packet
    input logic [63:0] rcvd_packet,     // 64-bit larpix packet
    input logic [7:0]  rcvd_crc,        // 8-bit crc word appended to packet
    input logic check_crc,              // high to initiate crc check
    input logic reset_n);         

// internal signals
logic [7:0] crc_lut [255:0]; // crc LUT

always_ff @(negedge reset_n) 
    if (!reset_n) 
        $readmemh("../testbench/sim_models/crc_lut.txt",crc_lut);




crc 
    crc_inst (
    .crcIn          (8'h00),
    .dataIn         (rcvd_packet),
    .crcOut         (crc_new)
    );

// check CRC
always_ff @(posedge check_crc or negedge reset_n) begin
    if (!reset_n) begin
        crc_error <= 1'b0;
    end
    else if (crc_new != rcvd_crc) begin
        crc_error <= 1'b1;
    end
    else crc_error <= 1'b0;
end // always_ff

endmodule

