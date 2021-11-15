///////////////////////////////////////////////////////////////////
// File Name: serializer_sdr.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Parallel in series out shift register-based serializer
//              Single Datarate (SDR) version used in MADCAP 
//              deserilizer testbench
//
///////////////////////////////////////////////////////////////////

module serializer_sdr
    #(parameter WIDTH = 8)
    (output logic dout,             // even output bit 
    output logic dout_symbol,        // high when LSB output
    input logic [WIDTH-1:0] din,    // input bits
    input logic enable,             // high to enable shift register
    input logic load,               // high to load shift register
    input logic clk,                // primary clock
    input logic reset_n);           // asynchronous reset (active low)

// local register
logic [WIDTH-1:0] shift_reg;        // shift register

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        shift_reg <= 0;
        dout_symbol <= 1'b0;
    end
    else if (load) begin    
        shift_reg <= din;
        dout_symbol <= 1'b1;
    end
    else if (enable) begin 
        shift_reg <= {1'b0,shift_reg[WIDTH-1:1]};
        dout_symbol <= 1'b0;
    end
end // always_ff

always_comb begin
    dout = shift_reg[0];
end // always_comb
    
endmodule    
