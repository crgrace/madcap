///////////////////////////////////////////////////////////////////
// File Name: channel_ctrl_tb.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Testbench for larpix-v3 channel_ctrl.sv.
//
//
///////////////////////////////////////////////////////////////////

`timescale 1ns/10ps
//
module channel_ctrl_tb();

// parameters
parameter VREF = 1.0;
parameter VCM = 0.5;
parameter WIDTH = 64;
parameter NUMCHANNELS = 64;

// channel controller signals
logic [WIDTH-2:0] input_event [NUMCHANNELS-1:0]; // event router input
logic [WIDTH-1:0] channel_event_routed; // event to write to fifo
logic [WIDTH-2:0] channel_event; // event to write to fifo before router
logic [9:0] adc_word; // for debuging
logic triggered_natural;  // high to indicate valid hit
logic csa_reset; // reset CSA
logic sample;        // high to sample CSA output
logic comp;           // bit from comparator in SAR
logic hit;            // high when discriminator fires
logic [7:0] chip_id; // unique id for each chip
logic [5:0] channel_id;// unique identifier for each ADC channel 
logic [7:0] adc_burst;// how many conversions to do each hit
logic [7:0] adc_hold_delay;// number of clock cycles for sampling
logic [31:0] timestamp_32b;     // time stamp to write to event
logic unsigned [7:0] reset_length;   // # of cycles to hold CSA in reset
logic external_trigger;     // high when external trigger raised
logic cross_trigger;        // high when another channel is hit
logic [63:0] periodic_trigger;   // high when peridoic trigger
logic enable_dynamic_reset; // high to enable data-driven rst
logic mark_first_packet;   // MSB of timestamp = 1 for first packet
logic periodic_reset; // periodic reset
logic enable_min_delta_adc; // high for rst based on settling
logic threshold_polarity; // high for ADC above threshold
logic [9:0] dynamic_reset_threshold; // rst threshold
logic [9:0] digital_threshold; // rst threshold
logic [7:0] min_delta_adc; // min delta before rst triggered
logic enable_fifo_diagnostics; // high to embed fifo counts
logic enable_local_fifo_diagnostics; // high to embed local fifo counts
logic channel_mask;         // high to mask out this channel
logic external_trigger_mask;// high to disable external trigger
logic cross_trigger_mask;       // high to disable cross trigger
logic periodic_trigger_mask; // high to disable periodic trigger
logic enable_periodic_trigger_veto; // high to enable veto
logic enable_hit_veto; // if high hit must = 1 to go into hold
logic clk;        // master clock    
logic reset_n;   // asynchronous digital reset (active low)
logic read_local_fifo_n; // low to read local fifo
logic [NUMCHANNELS-1:0] read_local_fifo_n_concat; // concat version
logic cds_mode;    // high for CDS mode
logic fifo_full;  // high when shared fifo is full 
logic fifo_half; // high when shared fifo is half full 
logic fifo_empty; // high when shared fifo is empty 
logic [NUMCHANNELS-1:0] fifo_empty_concat; // concat version 
logic [31:0] periodic_trigger_cycles;
logic enable_periodic_trigger;
logic enable_periodic_rolling_trigger;
logic [11:0] fifo_counter;
logic clk_out;              // copy of master clock used in TDC
logic done;                 // async ADC conversion complete
logic [9:0] dout;           // ADC output bits
logic async_mode;           // high if async SAR ADC used
logic load_event;           // high to load event into FIFO
logic fifo_ack;             // high to acknowledge successful FIFO write
logic [3:0] total_packets_lsbs; // number of packets generated
logic enable_tally; // high to embed running tally in packet
real vin_r;                         // LArPix analog input
real vref_r;                        // full-scale reference
real vcm_r;                         // zero reference
real y;
// stuff for LightPix (not used here)
logic lightpix_mode;        // high to integrate hits for timeout
logic [6:0] hit_threshold;  // how many hits to declare event?
logic [7:0] timeout;        // number of clk cycles to wait for hits

`include "channel_tests.sv"

initial begin


    //vin_r = 0.89;
    async_mode = 1;
    vin_r = 0.72;
    hit = 0;
    fifo_full = 0;
    fifo_half = 0;
    fifo_counter = 0;
    fifo_ack = 0;
    enable_tally = 0;
    total_packets_lsbs = 0;
/*
    $display("test real random numbers");
    repeat(5)
        begin
            y = 1 +($urandom%1000)/1000.0;
            $display("y = %f",y);
        end
*/
    Initialize_Tests;
/*
    Test_CDS;
    Test_Normal_Trigger;
    Test_Channel_Mask;
    Test_Cross_Trigger;
    Test_External_Trigger;
    Test_Periodic_Trigger;
    Test_Periodic_Trigger_Veto;
*/

//    Test_Reset_Length;
//    Test_ADC_Hold_Delay;
//   Test_ADC_Burst;
//    Test_ADC_Threshold;
//    Test_Min_ADC;
//    Test_Min_ADC_and_ADC_Threshold;
    Test_Hit_Veto;

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
    vref_r = VREF;
    vcm_r = VCM;
end

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

// model for FIFO 

task FifoAcknowledge;
begin
    @(posedge clk);
    @(posedge clk);
    fifo_ack <= 1'b1;
    @(posedge clk);
    @(posedge clk);
    fifo_ack <= 1'b0;
end
endtask

always_ff @(posedge load_event) begin
    FifoAcknowledge;
end // always_ff

// DUT Connected here
channel_ctrl
     channel_ctrl_inst (
    .channel_event          (channel_event),
    .adc_word               (adc_word),
    .fifo_empty             (fifo_empty),
    .triggered_natural      (triggered_natural),
    .csa_reset              (csa_reset),
    .sample                 (sample),
    .clk_out                (clk_out),
    .channel_enabled        (1'b1),
    .hit                    (hit),
    .dout                   (dout),
    .done                   (done),
    .chip_id                (chip_id),
    .channel_id             (channel_id),
    .adc_burst              (adc_burst),
    .adc_hold_delay         (adc_hold_delay),
    .timestamp_32b          (timestamp_32b),
    .reset_length           (reset_length),
    .enable_dynamic_reset   (enable_dynamic_reset),
    .cds_mode               (cds_mode),
    .mark_first_packet      (mark_first_packet),
    .read_local_fifo_n      (read_local_fifo_n),
    .external_trigger       (external_trigger),
    .cross_trigger          (cross_trigger),
    .periodic_trigger       (periodic_trigger[0]),
    .periodic_reset         (periodic_reset),
    .enable_min_delta_adc   (enable_min_delta_adc),
    .threshold_polarity     (threshold_polarity),
    .dynamic_reset_threshold    (dynamic_reset_threshold),
    .digital_threshold      (digital_threshold),
    .min_delta_adc          (min_delta_adc),
    .fifo_full              (fifo_full),
    .fifo_half              (fifo_half),
    .enable_local_fifo_diagnostics    (enable_local_fifo_diagnostics),
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
        .lightpix_mode      (lightpix_mode),
        .enable_tally       (enable_tally),
        .enable_fifo_diagnostics    (enable_fifo_diagnostics),
        .total_packets_lsbs (total_packets_lsbs),
        .fifo_counter       (fifo_counter),
        .hit_threshold      (hit_threshold),
        .timeout            (timeout),
        .fifo_ack           (fifo_ack),
        .clk                (clk),
        .reset_n            (reset_n)
    );

// analog model of SAR ADC
sar_async_adc
    sar_async_adc_inst (
        .dout                   (dout),
        .done                   (done),
        .sample                 (sample),
        .vref_r                 (vref_r),
        .vcm_r                  (vcm_r),
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
