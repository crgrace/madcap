///////////////////////////////////////////////////////////////////
// File Name: decode24b30b.sv
//
// Engineer: Carl Grace (crgrace@lbl.gov)
// Description: Decoder for 24b30b. Built from multiple instances of
//          Chuck Benz' 8b10b decoder
//
///////////////////////////////////////////////////////////////////



module decode24b30b (
    input   [29:0] datain,
    input   dispin,
    output  [23:0] dataout,
    output  dispout,
    output  [2:0] k_out,
    output  [2:0] code_err,
    output  [2:0] disp_err
    );

wire      disp_0;
wire      disp_01;
wire      disp_12;
wire      disp_2;

assign disp_0 = dispin;
assign dispout = disp_2;

decode8b10b    decode8b10b_byte0 (
              .datain       (datain[9:0]),
              .dataout      ({k_out[0],dataout[7:0]}),
              .dispin       (disp_0),
              .dispout      (disp_01),
              .code_err     (code_err[0]),
              .disp_err     (disp_err[0])
            );

decode8b10b    decode8b10b_byte1 (
              .datain       (datain[19:10]),
              .dataout      ({k_out[1],dataout[15:8]}),
              .dispin       (disp_01),
              .dispout      (disp_12),
              .code_err     (code_err[1]),
              .disp_err     (disp_err[1])
            );

decode8b10b    decode8b10b_byte2 (
              .datain       (datain[29:20]),
              .dataout      ({k_out[2],dataout[23:16]}),
              .dispin       (disp_12),
              .dispout      (disp_2),
              .code_err     (code_err[2]),
              .disp_err     (disp_err[2])
            );

endmodule
