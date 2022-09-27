///////////////////////////////////////////////////////////////////
// File Name: sar_async_adc.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description:SystemVerilog model of LArPix_v3 10-bit SAR ADC 
//
//      ADC is asynchronous. ADC conversion is triggered by falling edge
//      of sample.
//      Digital output is valid and done signal 
//      goes high after ADCDELAY time.
//      "zero" of the ADC is set by vcm_r 
//      Full scale of the ADC is set by vref_r
//
///////////////////////////////////////////////////////////////////

`timescale 1ns/1ps
module sar_async_adc
    #(parameter DELAY = 7,
    parameter ADCBITS = 10)
    (output logic [ADCBITS-1:0] dout,    // adc output bits
    output logic done,                      // high when conversion done
    input logic sample,                     // sample commmand
    input real vref_r,                      // full-scale reference
    input real vcm_r,                       // zero reference
    input real vin_r                        // analog stage input
    );

real vcommon_r, vdac_r;
integer i;
logic done_local;
logic [ADCBITS-1:0] dout_local;

assign #(DELAY) done = done_local;
assign #(DELAY) dout = dout_local;

// ADC model (in LArPix, SAR tracks input until falling edge of sample)
always_ff @(negedge sample) begin
    vcommon_r = vin_r - vcm_r;
    vdac_r = vref_r-vcm_r;
    $display("ADC: vin_r = %f, vref_r = %f, vcommon_r = %f, vcm_r = %f, vdac_r = %f",vin_r,vref_r,vcommon_r,vcm_r,vdac_r);
    for (i = ADCBITS-1; i >= 0; i = i - 1) begin
        vdac_r = vdac_r/2;
        if (vcommon_r > vdac_r) begin
            dout_local[i] = 1'b1;
            vcommon_r = vcommon_r - vdac_r;
        end
        else
            dout_local[i] = 1'b0;
        $display("ADC: step %1d:, vcommon_r = %f, vdac_r = %f, dout_local[%1d] = %d",i,vcommon_r,vdac_r,i,dout_local[i]);
    end // for
    $display("ADC: vin_r = %f, dout = %d, vref_r = %f, vcm_r = %f;\n", vin_r, dout_local,vref_r,vcm_r);
end // always_ff

always_ff @(sample) begin
    if (sample)
        done_local <= 1'b0;
    else 
        done_local <= 1'b1;
end // always_ff

endmodule
