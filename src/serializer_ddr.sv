///////////////////////////////////////////////////////////////////
// File Name: serializer_ddr.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Parallel in series out shift register-based serializer
//              Dual data rate (MADCAP data to FPGA)
//
///////////////////////////////////////////////////////////////////

module serializer_ddr
    #(parameter WIDTH = 8)
    (output logic dout_even,        // serializer even output bit 
    output logic dout_odd,          // serializer odd output bit 
    output logic dout_frame,        // high when LSB output
    input logic [WIDTH-1:0] din,    // input bits
    input logic enable,             // high to enable shift register
    input logic enable_prbs7,       // high to output prbs7 sequence
    input logic load,               // high to load shift register
    input logic clk,                // primary clock
    input logic reset_n);           // asynchronous reset (active low)

// local registers
logic [WIDTH-1:0] shift_reg;        // shift register
logic [1:0] prbs;                   // two bits of PRBS sequence
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        shift_reg <= 0;
        dout_frame <= 1'b0;
    end
    else if (load) begin    
        shift_reg <= din;
        dout_frame <= 1'b1;
    end
    else if (enable) begin 
        shift_reg <= {1'b0,1'b0,shift_reg[WIDTH-1:2]};
        dout_frame <= 1'b0;
    end
end // always_ff

always_comb begin
    if (enable_prbs7) begin
        dout_even = prbs[0];
        dout_odd = prbs[1];
    end
    else begin
        dout_even = shift_reg[0];
        dout_odd = shift_reg[1];
    end
end // always_comb
    
// instantiate submodules
prbs7
    prbs7_inst (
    .prbs           (prbs),
    .enable         (enable_prbs7),
    .clk            (clk),
    .reset_n        (reset_n)
    );

endmodule    
