///////////////////////////////////////////////////////////////////
// File Name: encode8b10b_tb.sv
//
// Engineer: Carl Grace (crgrace@lbl.gov)
// Description: SystemVerilog testbench for 8b10b encoder.
//
///////////////////////////////////////////////////////////////////

module encode8b10b_tb ();

localparam NUMTRIALS = 10;

logic [9:0] data_out;   // 10-bit encoded output
logic disp_out;         // 0 = neg disp; 1 = pos disp; not registered
logic [7:0] data_in;    // 8-bit raw input
logic disp_in;          // 0 = neg disp; 1 = pos disp
logic k_in;             // high to denote k character
logic clk;              // primary clock
logic reset_n;          // asynchronous reset (active low)

logic [8:0] decode_dataout;
logic decode_dispin;
logic decode_dispout;
logic decode_code_err;
logic decode_disp_err;

logic first;

initial begin
    reset_n = 1;
    first = 1;
    clk = 0;
    data_in = '0;
    k_in = 0;
    #40 reset_n = 0;
    #40 reset_n = 1;
    data_in = '0;
    for (int i = 0; i < NUMTRIALS; i++) begin
        #100 assert(std::randomize(data_in));
        $display("Original 8b data = %h", data_in);
    end
    #100 $display("test k-code");
    data_in = 8'b10111100;
    k_in = 1;
    #40 k_in = 0;
end

initial begin
    forever begin   
        #10 clk = ~clk;
    end
end // initial


always_ff @(posedge clk or negedge reset_n)
  if (!reset_n)
    decode_dispin <= 1'b0; // initialize disparity
  else
    decode_dispin <= decode_dispout;

always_ff @(posedge clk or negedge reset_n)
  if (!reset_n)
    disp_in <= 1'b0; // initialize disparity
  else
    disp_in <= disp_out;

// DUT

encode8b10b  
    encode8b10b_inst (
    .data_out   (data_out),
    .disp_out   (disp_out),
    .data_in    (data_in),
    .disp_in    (disp_in),
    .k_in       (k_in),
    .clk        (clk),
    .reset_n   (reset_n)
    );

decode8b10b
    decode8b10b_inst (
    .datain     (data_out),
    .dispin     (decode_dispin),
    .dataout    (decode_dataout),
    .dispout    (decode_dispout),
    .code_err   (decode_code_err),
    .disp_err   (decode_disp_err)
    );

// output monitor
always_ff @(decode_dataout)
    $display("Decoded 8b data = %h", decode_dataout);


endmodule




