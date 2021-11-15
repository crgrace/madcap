///////////////////////////////////////////////////////////////////
// File Name: encode96b120b.sv
//
// Engineer: Carl Grace (crgrace@lbl.gov)
// Description: 96b120b wide encoder implemented with 12 8b10b encoders.
//
///////////////////////////////////////////////////////////////////


module encode96b120b (
         input clk,
         input reset_n,
         input [95:0] data_in,
         input [11:0] k_in,
         output [119:0] data120b
       ) ;

reg       disp_0;
wire      disp_01;
wire      disp_12;
wire      disp_23;
wire      disp_3;


encode24b30b 
    encode24b30b_inst0 (
    .clk          (clk),
    .reset_n      (reset_n),
    .data_in      (data_in[23:0]),
    .k_in         (k_in[2:0]),
    .data30b      (data120b[29:0]),
    .disp_in      (disp_0),
    .disp_out     (disp_01)
     );

encode24b30b 
    encode24b30b_inst1 (
    .clk          (clk),
    .reset_n      (reset_n),
    .data_in      (data_in[47:24]),
    .k_in         (k_in[5:3]),
    .data30b      (data120b[59:30]),
    .disp_in      (disp_01),
    .disp_out     (disp_12)
     );

encode24b30b encode24b30b_inst2 (
    .clk          (clk),
    .reset_n      (reset_n),
    .data_in      (data_in[71:48]),
    .k_in         (k_in[8:6]),
    .data30b      (data120b[89:60]),
    .disp_in      (disp_12),
    .disp_out     (disp_23)
     );

encode24b30b encode24b30b_inst3 (
    .clk          (clk),
    .reset_n      (reset_n),
    .data_in      (data_in[95:72]),
    .k_in         (k_in[11:9]),
    .data30b      (data120b[119:90]),
    .disp_in      (disp_23),
    .disp_out     (disp_3)
     );

always @(posedge clk or negedge reset_n)
  if (!reset_n)
    disp_0 <= 1'b0; // initialize disparity
  else
    disp_0 <= disp_3;



endmodule
