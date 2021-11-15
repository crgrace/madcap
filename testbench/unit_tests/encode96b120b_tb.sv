///////////////////////////////////////////////////////////////////
// File Name: encode96b120b_tb.sv
//
// Engineer: Carl Grace (crgrace@lbl.gov)
// Description: SystemVerilog testbench for 96b120b encoder.
//
///////////////////////////////////////////////////////////////////

module encode96b120b_tb ();

localparam NUMTRIALS = 10;

logic [119:0] data_out;
logic [95:0] data_in;
logic [11:0] k_in;           // high to denote k character
logic [11:0] k_out;           // high to denote k character
logic clk;            // primary clock
logic reset_n;       // asynchronous reset (active low)

logic [95:0] decode_dataout;
logic [11:0] decode_k_out;
logic [11:0] decode_code_err;
logic [11:0] decode_disp_err;

logic running;

initial begin
    reset_n = 1;
    clk = 0;
    running = 0;
    data_in = '0;
    k_in = 0;
    #40 reset_n = 0;
    #40 reset_n = 1;
    data_in = '0;
    #100 running = 1;
    for (int i = 0; i < NUMTRIALS; i++) begin
        #100 assert(std::randomize(data_in));
        $display("Original 96b data = %h", data_in);
    end
    #100 $display("test k-code");
    data_in = {12{8'b10111100}};
    k_in = 12'hfff;
    #40 k_in = 0;
end

initial begin
    forever begin   
        #10 clk = ~clk;
    end
end // initial


// DUT

encode96b120b  
    encode96b120b_inst (
    .data120b   (data_out),
    .data_in    (data_in),
    .k_in       (k_in),
    .clk        (clk),
    .reset_n    (reset_n)
    );

decode96b120b
    decode96b120b_inst (
    .datain     (data_out),
    .dataout    (decode_dataout),
    .k_out      (decode_k_out),
    .code_err   (decode_code_err),
    .disp_err   (decode_disp_err),
    .clk        (clk),
    .reset_n    (reset_n)
    );

// output monitor
always_ff @(decode_dataout)
    if (running)
        $display("Decoded 96b data = %h", decode_dataout);


endmodule




