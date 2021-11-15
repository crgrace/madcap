///////////////////////////////////////////////////////////////////
// File Name: decode96b120b.sv
//
// Engineer: Carl Grace (crgrace@lbl.gov)
// Description: Decoder for 96b120b. Built from multiple instances of
//          Chuck Benz' 8b10b decoder
//
///////////////////////////////////////////////////////////////////



module decode96b120b (
    input [119:0] datain,
    input clk,
    input reset_n,
    output [95:0] dataout,
    output [11:0] k_out,
    output [11:0] code_err,
    output [11:0] disp_err
    );


reg       disp_0;
wire      disp_01;
wire      disp_12;
wire      disp_23;
wire      disp_3;

decode24b30b    
    decode24b30b_inst0 (
        .datain     (datain[29:0]),
        .dataout    (dataout[23:0]),
        .dispin     (disp_0),
        .dispout    (disp_01),
        .k_out      (k_out[2:0]),
        .code_err   (code_err[2:0]),
        .disp_err   (disp_err[2:0])
    );

decode24b30b    
    decode24b30b_inst1 (
        .datain     (datain[59:30]),
        .dataout    (dataout[47:24]),
        .dispin     (disp_01),
        .dispout    (disp_12),
        .k_out      (k_out[5:3]),
        .code_err   (code_err[5:3]),
        .disp_err   (disp_err[5:3])
    );

decode24b30b    
    decode24b30b_inst2 (
        .datain     (datain[89:60]),
        .dataout    (dataout[71:48]),
        .dispin     (disp_12),
        .dispout    (disp_23),
        .k_out      (k_out[8:6]),
        .code_err   (code_err[8:6]),
        .disp_err   (disp_err[8:6])
     );

decode24b30b   
    decode24b30b_inst3 (
        .datain       (datain[119:90]),
        .dataout      (dataout[95:72]),
        .dispin       (disp_23),
        .dispout      (disp_3),
        .k_out        (k_out[11:9]),
        .code_err     (code_err[11:9]),
        .disp_err     (disp_err[11:9])
    );

// sample disparity
always @(posedge clk or negedge reset_n)
  if (!reset_n)
    disp_0 <= 1'b0; // initialize disparity
  else
    disp_0 <= disp_3;

endmodule
