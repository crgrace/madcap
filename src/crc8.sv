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

`ifndef CRC8_V_
`define CRC8_V_

// CRC polynomial coefficients: x^8 + x^5 + x^4 + 1
//                              0x8C (hex)
// CRC width:                   8 bits
// CRC shift direction:         right (little endian)
// Input word width:            8 bits

module crc8 (
	input [7:0] crcIn,
	input [7:0] dataIn,
	output [7:0] crcOut
);
	assign crcOut[0] = (crcIn[2] ^ crcIn[4] ^ crcIn[5] ^ dataIn[2] ^ dataIn[4] ^ dataIn[5]);
	assign crcOut[1] = (crcIn[0] ^ crcIn[3] ^ crcIn[5] ^ crcIn[6] ^ dataIn[0] ^ dataIn[3] ^ dataIn[5] ^ dataIn[6]);
	assign crcOut[2] = (crcIn[0] ^ crcIn[1] ^ crcIn[4] ^ crcIn[6] ^ crcIn[7] ^ dataIn[0] ^ dataIn[1] ^ dataIn[4] ^ dataIn[6] ^ dataIn[7]);
	assign crcOut[3] = (crcIn[0] ^ crcIn[1] ^ crcIn[4] ^ crcIn[7] ^ dataIn[0] ^ dataIn[1] ^ dataIn[4] ^ dataIn[7]);
	assign crcOut[4] = (crcIn[0] ^ crcIn[1] ^ crcIn[4] ^ dataIn[0] ^ dataIn[1] ^ dataIn[4]);
	assign crcOut[5] = (crcIn[1] ^ crcIn[2] ^ crcIn[5] ^ dataIn[1] ^ dataIn[2] ^ dataIn[5]);
	assign crcOut[6] = (crcIn[0] ^ crcIn[2] ^ crcIn[3] ^ crcIn[6] ^ dataIn[0] ^ dataIn[2] ^ dataIn[3] ^ dataIn[6]);
	assign crcOut[7] = (crcIn[1] ^ crcIn[3] ^ crcIn[4] ^ crcIn[7] ^ dataIn[1] ^ dataIn[3] ^ dataIn[4] ^ dataIn[7]);
endmodule

`endif // CRC8_V_
