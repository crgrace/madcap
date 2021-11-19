///////////////////////////////////////////////////////////////////
// File Name: deserializer_sdr.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description:
//          Deserializer for MADCAP. Works with 10-bit 8b10b symbols
//          This is a single-date-rate deserializer (for config RX)  
//
///////////////////////////////////////////////////////////////////

module deserializer_sdr
    (output logic [9:0] dataword10b,       // deserialized symbol
    output logic dataword10b_ready,        // high when new word available
    input logic din,                    // input bit
                                        // external input:
    input logic symbol_start,            // high to indicate symbol edge
    input logic clk,                    // primary clock
    input logic reset_n);               // asynchronous active-low reset

logic [3:0] bit_count;              // where are we in the symbol?
logic [9:0] dataword10b_srg;        // in progress dataword10bs

// when we have finished shifting in a new symbol, register it
// and raise the dataword10b_ready flag.
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        dataword10b_ready <= 1'b0;
        dataword10b <= '0;
    end
    else begin  
        dataword10b_ready <= 1'b0;
        if (bit_count == 4'b1001) begin
            dataword10b <= dataword10b_srg;
            dataword10b_ready <= 1'b1;
        end
    end
end // always_ff


// serial-to-parallel shift register
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        bit_count <= '0;
        dataword10b_srg <= '0;
    end 
    else begin
        if (symbol_start) begin
            bit_count <= '0;
        end 
        else begin 
            bit_count <= bit_count + 1'b1;
        end
        dataword10b_srg <= {din,dataword10b_srg[9:1]};
    end
end // always_ff

endmodule
