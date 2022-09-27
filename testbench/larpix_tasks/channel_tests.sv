///////////////////////////////////////////////////////////////////
// File Name: channel_tests.sv
// Engineerr:  Carl Grace (crgrace@lbl.gov)
// Description:  Tests for use in channel_tests_tb.sv 
//          
// each test defines
///////////////////////////////////////////////////////////////////

`ifndef _channel_tests_
`define _channel_tests_

`include "larpix_constants.sv"  // all sim constants defined here

task Initialize_Tests;
begin
    vin_r = 0;
    hit = 0;
    cds_mode = 0;
    comp = 0;
    chip_id = 8'h0f;
    channel_id = 6'h03;
    adc_burst = 8'h00;
    adc_hold_delay = 3'b000; // old sample cycles
    reset_length = 3'b000;
    external_trigger = 0;
    cross_trigger = 0;
    enable_dynamic_reset = 0;
    mark_first_packet = 0;
    periodic_reset = 0;
    enable_min_delta_adc = 0;
    threshold_polarity = 1;
    dynamic_reset_threshold = 200;
    digital_threshold = 0;
    min_delta_adc = 30;
    enable_fifo_diagnostics = 0;
    enable_local_fifo_diagnostics = 0;
    channel_mask = 0;
    external_trigger_mask = 0;
    cross_trigger_mask = 1;
    periodic_trigger_mask = 1;
    enable_periodic_trigger_veto = 0;
    enable_periodic_trigger = 0;
    enable_periodic_rolling_trigger = 0;
    periodic_trigger_cycles = 0;
    enable_hit_veto = 0;
    lightpix_mode = 0;
    hit_threshold = 0;
    timeout = 0;
    clk = 0;
// execute reset
    reset_n = 1;
    #42 reset_n = 0;
    #100 reset_n = 1;
end 
endtask

task Test_CDS;
// task for basic CDS test. One hit (450)
begin
    $display("\nTest_CDS running.");
    cds_mode = 1;
    vin_r = 0.72; // ADC code = 450
    #100 hit = 1;
    @(posedge csa_reset)
    hit = 0;
    #1000 cds_mode = 0;
end
endtask

task Test_Normal_Trigger;
// task for normal mode expect three hits
// 450, 552, 819
begin
    $display("\nTest_Normal_Trigger running.");
    //vin_r = 0.89;
    vin_r = 0.72; // ADC code = 450
    #100 hit = 1;
    @(posedge csa_reset)
    hit = 0;
    # 25 vin_r = 0.77; // ADC code = 552 
    #200 hit = 1;
    @(posedge csa_reset)
    hit = 0;
    # 38 vin_r = 0.9; // ADC code = 819
    #200 hit = 1;
    @(posedge csa_reset)
    hit = 0;
end
endtask

task Test_Channel_Mask;
// task for testing channel mask expect two hits
// 112 & 204, code 138 is masked out
begin
    //vin_r = 0.89;
    vin_r = 0.72; // ADC code = 112
    #100 hit = 1;
    #28 hit = 0;
    #100 channel_mask = 1;
    #100 vin_r = 0.77; // ADC code = 138
    #200 hit = 1;
    #28 hit = 0;
    #200 channel_mask = 0;
    #200 vin_r = 0.9; // ADC code = 204
    #100 hit = 1;
    #28 hit = 0;
end
endtask


task Test_Cross_Trigger;
// task for cross mode expect no hits at first, then one hit
// 112
begin
    cross_trigger_mask = 1;
    vin_r = 0.9;
    #100 cross_trigger = 1; // hit should be ignored (204)
    #71 cross_trigger = 0;
    #500 cross_trigger_mask = 0;
    #100 vin_r = 0.72;
    #100 cross_trigger = 1; // ADC_code = 112 
    #28 cross_trigger = 0;
end
endtask

task Test_External_Trigger;
// task for external mode expect no hits at first, then one hit
// 112
begin
    external_trigger_mask = 1;
    vin_r = 0.9;
    #100 external_trigger = 1; // hit should be ignored (204)
    #71 external_trigger = 0;
    #500 external_trigger_mask = 0;
    #100 vin_r = 0.72;
    #100 external_trigger = 1; // ADC_code = 112 
    #28 external_trigger = 0;
end
endtask

task Test_Periodic_Trigger;
// first periodic trigger will be ignored. then code 112
begin
    enable_periodic_trigger = 1;
    periodic_trigger_mask = 1;
    periodic_trigger_cycles = 100;
    vin_r = 0.9;
    #3000 periodic_trigger_mask = 0;
    #1000 vin_r = 0.72;
    #10000 enable_periodic_trigger = 0;
end
endtask

task Test_Periodic_Trigger_Veto;
// first periodic trigger will be ignored. 
// second periodic trigger will be vetoed.
// then code 112
begin
    enable_periodic_trigger = 1;
    periodic_trigger_mask = 1;
    periodic_trigger_cycles = 100;
    vin_r = 0.9;
    #3000 periodic_trigger_mask = 0;
    #500 vin_r = 0.72; 
    #10 enable_periodic_trigger_veto = 1;
    #400 hit = 1;
    #50 hit = 0;
    #1000 enable_periodic_trigger_veto = 0;
    #10000 enable_periodic_trigger = 0;
end
endtask

task Test_Reset_Length;
// task to check if reset length command works
// expect three hits
// 112, 138, 204
begin
    //vin_r = 0.89;
    reset_length = 3'b111; // 7 reset cycles
    vin_r = 0.72;
    #1000 hit = 1;
    #28 hit = 0;
    #200 reset_length = 3'b100; // 4 reset cycles
    vin_r = 0.77; // ADC code = 138
    #200 hit = 1;
    #28 hit = 0;
    vin_r = 0.9; // ADC code = 204
    #200 reset_length = 3'b001; // 1 reset cycle
    #200 hit = 1;
    #28 hit = 0;
end
endtask

task Test_ADC_Hold_Delay;
// task to check if ADC Hold Delay works
// expect three hits
// 112, 138, 204
begin
    //vin_r = 0.89;
    adc_hold_delay = 3'b111; // 7 hold delay cycles
    vin_r = 0.72;
    #100 hit = 1;
    #28 hit = 0;
    #200 adc_hold_delay = 3'b100; // 4 hold delay cycles
    vin_r = 0.77; // ADC code = 138
    #200 hit = 1;
    #28 hit = 0;
    #200 vin_r = 0.9; // ADC code = 204
    #200 adc_hold_delay = 3'b001; // 1 hold cycle
    #200 hit = 1;
    #28 hit = 0;
end
endtask

task Test_ADC_Burst;
// task to check if ADC Burst Mode works
// expect three output codes from a single hit  
// 112, 138, 204
begin
    //vin_r = 0.89;
    reset_length = 1;
    adc_burst = 12; // do 12 conversions with one hit
    vin_r = 0.72;
    #100 hit = 1;
    #28 hit = 0;
    #550 vin_r = 0.77; // ADC code = 138
    #550 vin_r = 0.9; // ADC code = 204
    #2000 adc_burst = 0;
end
endtask

task Test_ADC_Threshold;
// task to check to make sure the ADC converts until user-specified
// threshold mode works
begin
    adc_burst = 100; // sets max conversions so we don't trash memory
    enable_dynamic_reset = 1;
    threshold_polarity = 1;
    dynamic_reset_threshold = 200;
    #200 vin_r = 0.77; // ADC code = 138, too small
    #100 hit = 1; // will continue to converter till ADC >= 200
    #50 hit = 0;
    #1100 vin_r = 0.9; // ADC code = 204, ADC will halt
    #1000 threshold_polarity = 0;
    #100 hit = 1; // not input too BIG, will convert until ADC < 200
    #28 hit = 0;
    #1000 vin_r = 0.72; // ADC code = 112, ADC will halt
    #2000 enable_dynamic_reset = 0;
    #100 adc_burst = 0;
end
endtask

task Test_Min_ADC;
// task to make sure that ADC converts until the input has settled
begin
    adc_burst = 100; // sets max conversions so we don't trash memory
    enable_min_delta_adc = 1;
    min_delta_adc = 10;
    #150 vin_r = 0.77; // ADC code = 138, too small
    #100 hit = 1; // will continue to convert till delta_adc < 10
    #50 hit = 0;     
    #200 vin_r = 0.9; // ADC code = 204, delta ADC too big
    #200 vin_r = 0.92; // ADC code = 215, delta ADC = 11 too big
    #40 vin_r = 0.93; // ADC code = 220, delta ADC = 5, will halt
    #5000 adc_burst = 0;
    enable_min_delta_adc = 0;
end
endtask

task Test_Min_ADC_and_ADC_Threshold;
// task to make sure that ADC converts until the input has settled
// or ADC exceeds threshold
begin
    adc_burst = 100; // sets max conversions so we don't trash memory
    enable_min_delta_adc = 1;
    enable_dynamic_reset = 0; // if this = 0 only min_adc works
    threshold_polarity = 1;
    dynamic_reset_threshold = 230;
    min_delta_adc = 10;
    #150 vin_r = 0.77; // ADC code = 138, too small
    #100 hit = 1; // will continue to convert till delta_adc < 10
    #50 hit = 0;     
    #200 vin_r = 0.9; // ADC code = 204, delta ADC too big
    #200 vin_r = 0.92; // ADC code = 215, delta ADC = 11 too big
    #40 vin_r = 0.93; // ADC code = 220, delta ADC = 5, will halt
    #1000 hit = 1; // ADC code = 220 is too small
    #50 hit = 0;
    vin_r = 0.94; // ADC code = 225 is too small
    #40 vin_r = 0.98; // ADC code = 245, ADC will halt
    #5000 adc_burst = 0;
    enable_min_delta_adc = 0;
    enable_dynamic_reset = 0;
end
endtask

task Test_Hit_Veto;
// task to make sure that backend can veto short hits 
// when configured to do so
begin
    #150 vin_r = 0.77; // ADC code = 138
    #100 hit = 1; // short hit will be converted
    #20 hit = 0;   
    #100 enable_hit_veto = 1;
    #100 vin_r = 0.9; // ADC code = 204
    #100 hit = 1; // short hit will be ignored
    #20 hit = 0;   
    #1000 enable_hit_veto = 0;
end
endtask    
    
    
        

`endif // _channel_tests_
