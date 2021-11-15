///////////////////////////////////////////////////////////////////
// File Name: deserializer_sdr.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description:
//          Deserializer for MADCAP. Works with 10-bit 8b10b symbols
//          This is a single-date-rate deserializer (for config RX)  
//
///////////////////////////////////////////////////////////////////

module deserializer_sdr
    #(parameter WIDTH = 10)
    (output logic [WIDTH-1:0] dataword,       // deserialized symbol
    output logic dataword_ready,        // high when new word available
    input logic din,                    // input bit
    input logic symbol_start,            // high to indicate symbol edge
    input logic clk,                    // primary clock
    input logic reset_n);               // asynchronous active-low reset

logic [3:0] bit_count;            // where are we in the symbol?
logic [WIDTH-1:0] dataword_srg;     // in progress datawords

// when we have finished shifting in a new symbol, register it
// and raise the dataword_ready flag.
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        dataword_ready <= 1'b0;
        dataword <= '0;
    end
    else begin  
        dataword_ready <= 1'b0;
        if (bit_count == WIDTH-1) begin
            dataword <= dataword_srg;
            dataword_ready <= 1'b1;
        end
    end
end // always_ff


// serial-to-parallel shift register
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        bit_count <= '0;
        dataword_srg <= '0;
    end 
    else begin
        if (symbol_start) begin
            bit_count <= '0;
        end 
        else begin 
            bit_count <= bit_count + 1'b1;
        end
        dataword_srg <= {din,dataword_srg[WIDTH-1:1]};
    end
end // always_ff

endmodule
