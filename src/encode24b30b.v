//                              -*- Mode: Verilog -*-
// Filename        : encode24b30b.v
// Description     : Combines 3 8b10 encoders to form a 24b30b encoder
// Author          :
// Created On      : Wed Jun 18 14:32:26 2014
// Last Modified By:
// Last Modified On: Wed Jun 18 14:32:26 2014
// Update Count    : 0
// Status          : Unknown, Use with caution!


module encode24b30b (
         input    clk,
         input    reset_n,
         input [23:0]  data_in,
         input [2:0]   k_in,
         input disp_in,
         output [29:0] data30b,
         output disp_out
       ) ;

wire      disp_0;
wire      disp_01;
wire      disp_12;
wire      disp_2;

assign disp_0 = disp_in;
assign disp_out = disp_2;

encode8b10b encode8b10b_byte0 (
              .clk(clk),
              .reset_n(reset_n),
              .data_in(data_in[7:0]),
              .k_in(k_in[0]),
              .data_out(data30b[9:0]),
              .disp_in(disp_0),
              .disp_out(disp_01)
            );

encode8b10b encode8b10b_byte1 (
              .clk(clk),
              .reset_n(reset_n),
              .data_in(data_in[15:8]),
              .k_in(k_in[1]),
              .data_out(data30b[19:10]),
              .disp_in(disp_01),
              .disp_out(disp_12)
            );

encode8b10b encode8b10b_byte2 (
              .clk(clk),
              .reset_n(reset_n),
              .data_in(data_in[23:16]),
              .k_in(k_in[2]),
              .data_out(data30b[29:20]),
              .disp_in(disp_12),
              .disp_out(disp_2)
            );

endmodule
