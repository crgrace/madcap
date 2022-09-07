///////////////////////////////////////////////////////////////////
// File Name: sar_adc_core.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description:SystemVerilog model of LArPix 8-bit SAR ADC core
//             includes model of SHA, comparator, and DAC
//             does not include model of SAR controller
//
///////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module sar_adc_core
    #(parameter VREF = 1.0,
    parameter VCM = 0.5,
    parameter ADCBITS = 8)
    (output logic comp,       // comparator output bit
    input logic sample,           // sample commmand
    input logic strobe,           // sampling strobe
    input logic [ADCBITS-1:0] dac_word,   // DAC control word
    input real vin_r       // analog stage input
    );

real sample_r, dac_r, weight, vtp_r;
integer i;

always @(*) 
    if (sample) begin
        #2 vtp_r = VCM;
    end else begin
        #2 vtp_r = -sample_r + dac_r + VCM;
    end

initial begin
    comp <= 1'b0;
end

// SHA model (in LArPix, SAR tracks input until falling edge of sample)
always_ff @(negedge sample) begin
    sample_r = vin_r - VCM;
end

// comparator model
always @(posedge strobe) begin
//    #1 comp = (-sample_r + dac_r) < 0.0 ? 1'b1 : 1'b0;
     comp = (vtp_r - VCM) > 0.0 ? 1'b0 : 1'b1;
end    

// dac model
always @(dac_word) begin
    weight = (VREF-VCM)/2.0;
    dac_r = 0.0;
    for (i = ADCBITS-1; i >= 0; i = i-1) begin
        #1 dac_r = dac_r + weight*dac_word[i];
        weight = weight/2.0;
    end
end

endmodule
