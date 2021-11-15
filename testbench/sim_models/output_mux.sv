///////////////////////////////////////////////////////////////////
// File Name: output_mux.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description:
//          Analog output mux for MADCAP serializer  
//          Used to select odd or even output bits for DDR
//
///////////////////////////////////////////////////////////////////

module output_mux
    (output logic dout,
    input logic dout_even,
    input logic dout_odd,
    input logic clk);

// output mux
always_comb begin
    if (clk == 1'b1)
        dout = dout_even;
    else    
        dout = dout_odd;
end // always_comb

endmodule
