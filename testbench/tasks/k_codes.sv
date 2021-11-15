///////////////////////////////////////////////////////////////////
// File Name: k_codes.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: k_codes used in MADCAP
//              (These come from the 802.3z GbE standard
///////////////////////////////////////////////////////////////////

`ifndef _k_codes_v_
`define _k_codes_v_

`define K_A 8'b01111100 // K28.3
`define K_F 8'b11111100 // K28.7
`define K_K 8'b10111100 // K28.5
`define K_Q 8'b10011100 // K28.4
`define K_R 8'b00011100 // K28.0
`define K_T 8'b11111101 // K29.7 --> config half when in data packet
`define K_S 8'b11111011 // K27.7 --> config full when in data packet
`define K_K_DISP_N 10'b00_1111_1010 // K_K 10b character when DISP = -1
`define K_K_DISP_P 10'b11_0000_0101 // K_K 10b character when DISP = +1
`define D_21_5 8'b10110101 // D21.5 (01010101... after 8b/10b)
`define RPAT 96'h59_35_FB_5E_14_B3_8F_6B_47_23_D7 // 802.3 modified RPAT
`endif
