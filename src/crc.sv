// vim: ts=4 sw=4 noexpandtab

// THIS IS GENERATED VERILOG CODE.
// https://bues.ch/h/crcgen
// 
// This code is Public Domain.
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted.
// 
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
// RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
// NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE
// USE OR PERFORMANCE OF THIS SOFTWARE.

`ifndef CRC_V_
`define CRC_V_

// CRC polynomial coefficients: x^8 + x^5 + x^4 + 1
//                              0x8C (hex)
// CRC width:                   8 bits
// CRC shift direction:         right (little endian)
// Input word width:            64 bits

module crc (
	input [7:0] crc_in,
	input [63:0] data_in,
	output [7:0] crc_out
);
	assign crc_out[0] = (crc_in[0] ^ crc_in[2] ^ crc_in[6] ^ data_in[0] ^ data_in[2] ^ data_in[6] ^ data_in[8] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14] ^ data_in[15] ^ data_in[16] ^ data_in[19] ^ data_in[20] ^ data_in[22] ^ data_in[24] ^ data_in[25] ^ data_in[26] ^ data_in[30] ^ data_in[31] ^ data_in[32] ^ data_in[33] ^ data_in[39] ^ data_in[40] ^ data_in[41] ^ data_in[43] ^ data_in[46] ^ data_in[49] ^ data_in[50] ^ data_in[53] ^ data_in[54] ^ data_in[55] ^ data_in[58] ^ data_in[60] ^ data_in[61]);
	assign crc_out[1] = (crc_in[0] ^ crc_in[1] ^ crc_in[3] ^ crc_in[7] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[7] ^ data_in[9] ^ data_in[12] ^ data_in[13] ^ data_in[14] ^ data_in[15] ^ data_in[16] ^ data_in[17] ^ data_in[20] ^ data_in[21] ^ data_in[23] ^ data_in[25] ^ data_in[26] ^ data_in[27] ^ data_in[31] ^ data_in[32] ^ data_in[33] ^ data_in[34] ^ data_in[40] ^ data_in[41] ^ data_in[42] ^ data_in[44] ^ data_in[47] ^ data_in[50] ^ data_in[51] ^ data_in[54] ^ data_in[55] ^ data_in[56] ^ data_in[59] ^ data_in[61] ^ data_in[62]);
	assign crc_out[2] = (crc_in[1] ^ crc_in[2] ^ crc_in[4] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[8] ^ data_in[10] ^ data_in[13] ^ data_in[14] ^ data_in[15] ^ data_in[16] ^ data_in[17] ^ data_in[18] ^ data_in[21] ^ data_in[22] ^ data_in[24] ^ data_in[26] ^ data_in[27] ^ data_in[28] ^ data_in[32] ^ data_in[33] ^ data_in[34] ^ data_in[35] ^ data_in[41] ^ data_in[42] ^ data_in[43] ^ data_in[45] ^ data_in[48] ^ data_in[51] ^ data_in[52] ^ data_in[55] ^ data_in[56] ^ data_in[57] ^ data_in[60] ^ data_in[62] ^ data_in[63]);
	assign crc_out[3] = (crc_in[3] ^ crc_in[5] ^ crc_in[6] ^ data_in[3] ^ data_in[5] ^ data_in[6] ^ data_in[8] ^ data_in[9] ^ data_in[12] ^ data_in[13] ^ data_in[17] ^ data_in[18] ^ data_in[20] ^ data_in[23] ^ data_in[24] ^ data_in[26] ^ data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30] ^ data_in[31] ^ data_in[32] ^ data_in[34] ^ data_in[35] ^ data_in[36] ^ data_in[39] ^ data_in[40] ^ data_in[41] ^ data_in[42] ^ data_in[44] ^ data_in[50] ^ data_in[52] ^ data_in[54] ^ data_in[55] ^ data_in[56] ^ data_in[57] ^ data_in[60] ^ data_in[63]);
	assign crc_out[4] = (crc_in[2] ^ crc_in[4] ^ crc_in[7] ^ data_in[2] ^ data_in[4] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[15] ^ data_in[16] ^ data_in[18] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^ data_in[26] ^ data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[35] ^ data_in[36] ^ data_in[37] ^ data_in[39] ^ data_in[42] ^ data_in[45] ^ data_in[46] ^ data_in[49] ^ data_in[50] ^ data_in[51] ^ data_in[54] ^ data_in[56] ^ data_in[57] ^ data_in[60]);
	assign crc_out[5] = (crc_in[3] ^ crc_in[5] ^ data_in[3] ^ data_in[5] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[16] ^ data_in[17] ^ data_in[19] ^ data_in[21] ^ data_in[22] ^ data_in[23] ^ data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30] ^ data_in[36] ^ data_in[37] ^ data_in[38] ^ data_in[40] ^ data_in[43] ^ data_in[46] ^ data_in[47] ^ data_in[50] ^ data_in[51] ^ data_in[52] ^ data_in[55] ^ data_in[57] ^ data_in[58] ^ data_in[61]);
	assign crc_out[6] = (crc_in[0] ^ crc_in[4] ^ crc_in[6] ^ data_in[0] ^ data_in[4] ^ data_in[6] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14] ^ data_in[17] ^ data_in[18] ^ data_in[20] ^ data_in[22] ^ data_in[23] ^ data_in[24] ^ data_in[28] ^ data_in[29] ^ data_in[30] ^ data_in[31] ^ data_in[37] ^ data_in[38] ^ data_in[39] ^ data_in[41] ^ data_in[44] ^ data_in[47] ^ data_in[48] ^ data_in[51] ^ data_in[52] ^ data_in[53] ^ data_in[56] ^ data_in[58] ^ data_in[59] ^ data_in[62]);
assign crc_out[7] = (crc_in[1] ^ crc_in[5] ^ crc_in[7] ^ data_in[1] ^ data_in[5] ^ data_in[7] ^ data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14] ^ data_in[15] ^ data_in[18] ^ data_in[19] ^ data_in[21] ^ data_in[23] ^ data_in[24] ^ data_in[25] ^ data_in[29] ^ data_in[30] ^ data_in[31] ^ data_in[32] ^ data_in[38] ^ data_in[39] ^ data_in[40] ^ data_in[42] ^ data_in[45] ^ data_in[48] ^ data_in[49] ^ data_in[52] ^ data_in[53] ^ data_in[54] ^ data_in[57] ^ data_in[59] ^ data_in[60] ^ data_in[63]);
endmodule

`endif // CRC_V_
