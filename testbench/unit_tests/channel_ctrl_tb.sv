///////////////////////////////////////////////////////////////////
// File Name: channel_ctrl_tb.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Testbench for larpix-v2 channel_ctrl.sv.
//
//          The new channel_ctrl.sv combines sar_ctrl, channel_ctrl, 
//          and event_builder from larpix-v1 and adds a local FIFO
//
///////////////////////////////////////////////////////////////////

`timescale 1ns/10ps
//
module channel_ctrl_tb();

// parameters
parameter VREF = 1.0;
parameter VCM = 0.5;
parameter ADCBITS = 8;
parameter WIDTH = 64;
parameter NUMCHANNELS = 64;

// channel controller signals
logic [WIDTH-2:0] input_event [NUMCHANNELS-1:0]; // event router input
logic [WIDTH-2:0] channel_event_routed; // event to write to fifo
logic [WIDTH-2:0] channel_event; // event to write to fifo before router
logic [7:0] dac_word; // DAC control word sent to SAR ADC
logic [7:0] adc_word; // for debuging
logic triggered_natural;  // high to indicate valid hit
logic csa_reset; // reset CSA
logic sample;        // high to sample CSA output
logic strobe;        // high to stgrobe SAR ADC
logic comp;           // bit from comparator in SAR
logic hit;            // high when discriminator fires
logic [7:0] chip_id; // unique id for each chip
logic [5:0] channel_id;// unique identifier for each ADC channel 
logic [7:0] adc_burst;// how many conversions to do each hit
logic [3:0] adc_hold_delay;// number of clock cycles for sampling
logic [31:0] timestamp_32b;     // time stamp to write to event
logic [2:0] reset_length;   // # of cycles to hold CSA in reset
logic external_trigger;     // high when external trigger raised
logic cross_trigger;        // high when another channel is hit
logic [63:0] periodic_trigger;   // high when peridoic trigger
logic enable_dynamic_reset; // high to enable data-driven rst
logic periodic_reset; // periodic reset
logic enable_min_delta_adc; // high for rst based on settling
logic threshold_polarity; // high for ADC above threshold
logic [7:0] dynamic_reset_threshold; // rst threshold
logic [7:0] digital_threshold; // rst threshold
logic [7:0] min_delta_adc; // min delta before rst triggered
logic [12:0] fifo_counter;  // current fifo count
logic enable_fifo_diagnostics; // high to embed fifo counts
logic channel_mask;         // high to mask out this channel
logic external_trigger_mask;// high to disable external trigger
logic cross_trigger_mask;       // high to disable cross trigger
logic periodic_trigger_mask; // high to disable periodic trigger
logic enable_periodic_trigger_veto; // high to enable veto
logic enable_hit_veto; // if high hit must = 1 to go into hold
logic clk;        // master clock    
logic reset_n;   // asynchronous digital reset (active low)
logic read_local_fifo_n; // low to read local fifo
logic [NUMCHANNELS-1:0]read_local_fifo_n_concat; // concat version

logic fifo_full;  // high when shared fifo is full 
logic fifo_half; // high when shared fifo is half full 
logic fifo_empty; // high when shared fifo is empty 
logic [NUMCHANNELS-1:0] fifo_empty_concat; // concat version 
logic [31:0] periodic_trigger_cycles;
logic enable_periodic_trigger;
logic enable_periodic_rolling_trigger;
real vin_r;  // LArPix analog input

`include "channel_tests.sv"

initial begin


    //vin_r = 0.89;
    vin_r = 0.72;
    hit = 0;
    fifo_full = 0;
    fifo_half = 0;
    Initialize_Tests;
//    Test_Normal_Trigger;
//    Test_Channel_Mask;
//    Test_Cross_Trigger;
//    Test_External_Trigger;
//    Test_Periodic_Trigger;
//    Test_Periodic_Trigger_Veto;
//    Test_Reset_Length;
//    Test_ADC_Hold_Delay;
    Test_ADC_Burst;
//    Test_ADC_Threshold;
//    Test_Min_ADC;
//    Test_Min_ADC_and_ADC_Threshold;
//    Test_Hit_Veto;

 /*   
    #100 hit = 1;
    #28 hit = 0;
    vin_r = 0.77;
    #200 hit = 1;
    #28 hit = 0;
    vin_r = 0.9;
    #100 hit = 1;
    #28 hit = 0;
*/    

end // initial

always_comb begin
  
    for (int i = 1; i < NUMCHANNELS; i++) begin
        input_event[i] = 0;
//        read_local_fifo_n_concat[i] = 0;
//        fifo_empty_concat[i] = 0;
    end // for    
    input_event[0] =  channel_event;
    read_local_fifo_n = read_local_fifo_n_concat[NUMCHANNELS-1:0];
    if (fifo_empty == 1'b1) begin
//      $display("FIFO_EMPTY = 1");
        fifo_empty_concat = 64'hffffffffffffffff;
    end
    else begin
        fifo_empty_concat = 64'hfffffffffffffffe;
       // fifo_empty_concat[0] = 1'b0;
    end
end // always_comb

always #10 clk = ~clk;


// DUT Connected here
channel_ctrl
     channel_ctrl_inst (
    .channel_event          (channel_event),
    .dac_word               (dac_word),
    .adc_word               (adc_word),
    .fifo_empty             (fifo_empty),
    .triggered_natural      (triggered_natural),
    .csa_reset              (csa_reset),
    .sample                 (sample),
    .strobe                 (strobe),
    .comp                   (comp),
    .hit                    (hit),
    .chip_id                (chip_id),
    .channel_id             (channel_id),
    .adc_burst              (adc_burst),
    .adc_hold_delay         (adc_hold_delay),
    .timestamp_32b          (timestamp_32b),
    .reset_length           (reset_length),
    .enable_dynamic_reset   (enable_dynamic_reset),
    .read_local_fifo_n      (read_local_fifo_n),
    .external_trigger       (external_trigger),
    .cross_trigger          (cross_trigger),
    .periodic_trigger       (periodic_trigger[0]),
    .periodic_reset       (periodic_reset),
    .enable_min_delta_adc   (enable_min_delta_adc),
    .threshold_polarity     (threshold_polarity),
    .dynamic_reset_threshold    (dynamic_reset_threshold),
    .digital_threshold      (digital_threshold),
    .min_delta_adc          (min_delta_adc),
    .fifo_full              (fifo_full),
    .fifo_half              (fifo_half),
    .fifo_counter           (fifo_counter),
    .enable_fifo_diagnostics    (enable_fifo_diagnostics),
    .channel_mask           (channel_mask),
    .external_trigger_mask  (external_trigger_mask),
    .cross_trigger_mask     (cross_trigger_mask), 
    .periodic_trigger_mask  (periodic_trigger_mask),
    .enable_periodic_trigger_veto    (enable_periodic_trigger_veto),
    .enable_hit_veto    (enable_hit_veto),
    .clk                    (clk),
    .reset_n                (reset_n)
    );

// event router (only channel 0 is connected, of course)
event_router    
    event_router_inst (
        .channel_event_out  (channel_event_routed),
        .read_local_fifo_n  (read_local_fifo_n_concat),
        .load_event         (load_event),
        .input_event        (input_event),
        .local_fifo_empty   (fifo_empty_concat),
        .clk                (clk),
        .reset_n            (reset_n)
    );

// analog model of SAR core
sar_adc_core
    sar_adc_core_inst (
        .comp                   (comp),
        .sample                 (sample),
        .strobe                 (strobe),
        .dac_word               (dac_word),
        .vin_r                  (vin_r)
    );

// this module generates the 32b timestamp
timestamp_gen
    timestamp_gen_inst (
        .timestamp_32b  (timestamp_32b),
        .sync_timestamp (1'b0),
        .clk            (clk),
        .reset_n        (reset_n)
    );


// this pulser generates the periodic trigger pulse    
periodic_pulser
    #(.PERIODIC_PULSER_W(32),
    .NUMCHANNELS(64))
    periodic_trigger_inst (
    .periodic_pulse     (periodic_trigger),
    .pulse_cycles       (periodic_trigger_cycles),
    .enable             (enable_periodic_trigger),
    .enable_rolling_pulse   (enable_periodic_rolling_trigger),
    .clk                (clk),
    .reset_n            (reset_n)
    );

endmodule
