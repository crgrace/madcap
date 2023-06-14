///////////////////////////////////////////////////////////////////
// File Name: digital_core.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: LArPix-v3 synthesized digital core.  
//              Includes:
//              UARTs for chip-to-chip communications.
//              New channel controller for asynchronous ADC.
//              255-byte Register Map for configuration bits.
//              2048-word deep latch-based FIFO memory.
//              Hydra I/O resilient data routing.
//              Fault protection and mitigation capability.
//              Event builder.
//
//              Note that the "primary" is the chip writing to and reading
//              from the current chip. It could also be the FPGA.
//              The "secondary" is always the current chip.
//
///////////////////////////////////////////////////////////////////

module digital_core
    #(parameter WIDTH = 64,    // width of packet (w/o start & stop bits) 
    parameter NUMCHANNELS = 64,     // number of analog channels
    parameter WORDWIDTH = 8,     // size of word
    parameter REGNUM = 256,          // number of configuration registers
    parameter CHIP_ID_W = 8,        // width of chip ID
    parameter GLOBAL_ID = 255,      // global broadcast ID
    parameter integer unsigned FIFO_DEPTH = 2048,      // number of FIFO memory locations
    parameter LOCAL_FIFO_DEPTH = 8, // number of locations in channel FIFO
    parameter PIXEL_TRIM_DAC_BITS = 5, // number of bits per dac
    parameter ADCBITS = 10,         // number of bits in ADC
    parameter GLOBAL_DAC_BITS = 8,
    parameter TESTPULSE_DAC_BITS = 8)
    
    (output logic [3:0] piso,// PRIMARY-IN-SECONDARY-OUT TX UART output bit
    output logic digital_monitor, // digital test port
    output logic [NUMCHANNELS-1:0] sample,   // high to sample CSA output
    output logic [3:0] tx_enable, // high to enable TX (PHY + keepalive)
    
// ANALOG CORE CONFIGURATION SIGNALS
// these are in the same order as the LArPix_v3 config bits google sheet

    output logic [PIXEL_TRIM_DAC_BITS*NUMCHANNELS-1:0] pixel_trim_dac,
    output logic [GLOBAL_DAC_BITS-1:0] threshold_global,
    output logic [NUMCHANNELS-1:0] csa_gain, // active high
    output logic [NUMCHANNELS-1:0] csa_reset, // active high
    output logic [NUMCHANNELS-1:0] bypass_caps_enable, // active high
    output logic [15:0] ibias_tdac, // threshold dac ibias 
    output logic [15:0] ibias_comp, // discriminator ibias 
    output logic [15:0] ibias_buffer, // ab buffer ibias 
    output logic [15:0] ibias_csa, // csa ibias 
    output logic [3:0] ibias_vref_buffer, // vref buffer ibias
    output logic [3:0] ibias_vcm_buffer,  // vcm buffer ibias
    output logic [3:0] ibias_tpulse,  // tpulse ibias
    output logic [15:0] adc_ibias_delay, // ADC delay line
    output logic [4:0] ref_current_trim, // trims ref voltage
    output logic [1:0] adc_comp_trim, // trims ref of delay ramp 
    output logic [7:0] vref_dac, // sets vref for adc
    output logic [7:0] vcm_dac, // sets vcm for adc
    output logic [NUMCHANNELS-1:0] csa_bypass_enable, // inject into adc
    output logic [NUMCHANNELS-1:0] csa_bypass_select, // adc channels(s)
    output logic [NUMCHANNELS-1:0] csa_monitor_select, // monitor channels 
    output logic [NUMCHANNELS-1:0] csa_testpulse_enable,
    output logic [TESTPULSE_DAC_BITS-1:0] csa_testpulse_dac,
    output logic [3:0] adc_ibias_delay_monitor, // one hot monitor(see docs)
    output logic [3:0] current_monitor_bank0, // one hot monitor (see docs)
    output logic [3:0] current_monitor_bank1, // one hot monitor (see docs)
    output logic [3:0] current_monitor_bank2, // one hot monitor (see docs)
    output logic [3:0] current_monitor_bank3, // one hot monitor (see docs)
    output logic [2:0] voltage_monitor_bank0, // one hot monitor (see docs)
    output logic [2:0] voltage_monitor_bank1, // one hot monitor (see docs)
    output logic [2:0] voltage_monitor_bank2, // one hot monitor (see docs)
    output logic [2:0] voltage_monitor_bank3, // one hot monitor (see docs)
    output logic [7:0] voltage_monitor_refgen, // one hot monitor 
    output logic en_analog_monitor, // high to enable monitor buffer
    output logic [3:0] tx_slices0, // number of LVDS slices for POSI0 link
    output logic [3:0] tx_slices1, // number of LVDS slices for POSI1 link
    output logic [3:0] tx_slices2, // number of LVDS slices for POSI2 link
    output logic [3:0] tx_slices3, // number of LVDS slices for POSI3 link
    output logic [3:0] i_tx_diff0, // TX0 bias current (diff)
    output logic [3:0] i_tx_diff1, // TX1 bias current (diff)
    output logic [3:0] i_tx_diff2, // TX2 bias current (diff)
    output logic [3:0] i_tx_diff3, // TX3 bias current (diff)
    output logic [3:0] i_rx0, // RX0 bias current 
    output logic [3:0] i_rx1, // RX1 bias current 
    output logic [3:0] i_rx2, // RX2 bias current 
    output logic [3:0] i_rx3, // RX3 bias current 
    output logic [3:0] i_rx_clk, // RX_CLK bias current 
    output logic [3:0] i_rx_rst, // RX_RST bias current 
    output logic [3:0] i_rx_ext_trig, // RX_EXT_TRIG bias current 
    output logic [4:0] r_term0, // RX0 termination resistor
    output logic [4:0] r_term1, // RX1 termination resistor
    output logic [4:0] r_term2, // RX2 termination resistor
    output logic [4:0] r_term3, // RX3 termination resistor
    output logic [4:0] r_term_clk, // RX_CLK termination resistor
    output logic [4:0] r_term_rst, // RX_RST termination resistor
    output logic [4:0] r_term_ext_trig, // RX_EXT_TRIG termination resistor
    output logic [3:0] v_cm_lvds_tx0,   // TX0 CM output voltage (lvds mode)
    output logic [3:0] v_cm_lvds_tx1,   // TX1 CM output voltage (lvds mode)
    output logic [3:0] v_cm_lvds_tx2,   // TX2 CM output voltage (lvds mode)
    output logic [3:0] v_cm_lvds_tx3,   // TX3 CM output voltage (lvds mode)
// INPUTS
    input logic [ADCBITS*NUMCHANNELS-1:0] dout,                 // bits from ADC
    input logic [NUMCHANNELS-1:0] done,   // high when ADC conversion finished
    input logic [NUMCHANNELS-1:0] hit,    // high when discriminator fires
    input logic external_trigger,     // high to trigger channel
    input logic [3:0] posi,// PRIMARY-OUT-SECONDARY-IN: RX UART input bit  
    input clk,    // primary clk
    input reset_n);        // asynchronous digital reset (active low)

// calculate register widths
localparam REGMAP_ADDR_WIDTH = $clog2(REGNUM); // bits in regmap addr range
localparam FIFO_BITS = $clog2(FIFO_DEPTH);//bits in fifo addr range


// constants (e.g. register definitions)
// located at ../testbench/larpix_tasks/
// example compilation: 
//vlog +incdir+../testbench/larpix_tasks/ -incr -sv "../src/digital_core.sv"
`include "larpix_constants.sv"
    
// internal nets
logic [ADCBITS-1:0] adc_word [NUMCHANNELS-1:0]; // useful for simulation debugging, not brought to pins

// digital config 
logic [7:0] chip_id; // unique id for each chip
logic load_config_defaults; // high to soft reset LArPix (set to low after)
logic [3:0] enable_piso_upstream; // enable different upstream PISOs
logic [3:0] enable_piso_downstream; // enable different downstream PISOs
logic [3:0] enable_posi;              // high for different POSIs
logic enable_cross_trigger;      // high for cross trigger mode
logic enable_periodic_trigger;      // high for periodic trigger mode
logic enable_rolling_periodic_trigger; // make the trigger rolling
logic enable_periodic_reset;      // high for periodic reset mode
logic enable_rolling_periodic_reset; // make the reset rolling
logic enable_periodic_trigger_veto; // does hit veto periodic trigger?
logic enable_hit_veto;   // is hit required to go into hold mode?
logic enable_fifo_diagnostics;   // high for diagnostics
logic enable_local_fifo_diagnostics;   // high for local diagnostics
logic enable_tally;   // high to embed running tally in packet
logic enable_data_stats;   // high to write stats to mailbox
logic enable_external_trigger;  // high to process external triggers
logic enable_external_sync;     // high to process external syncs
logic [7:0] adc_hold_delay;     // how many clock cycles for sampling?
logic [7:0] adc_burst_length;  // how long is max adc burst?
logic [2:0] reset_length;       // how many cycles to reset CSA?
logic digital_monitor_enable;
logic [3:0] digital_monitor_select;
logic [5:0] digital_monitor_chan;
logic mark_first_packet;    // sets MSB of timestamp to 1 on first hit
logic [NUMCHANNELS-1:0] channel_mask; // high to disable channel
logic [NUMCHANNELS-1:0] external_trigger_mask; // high to disable channel
logic [NUMCHANNELS-1:0] cross_trigger_mask; // high to disable channel
logic [NUMCHANNELS-1:0] periodic_trigger_mask; // high to disable channel
logic [23:0] periodic_reset_cycles; // time between periodic reset
logic [31:0] periodic_trigger_cycles; // time between periodic triggers
logic fifo_ack;         // acknowledge data consumed from FIFO
logic enable_dynamic_reset; // high to enable dynamic reset mode
logic enable_min_delta_adc; // high to enable min delta ADC mode
logic threshold_polarity; // high to trigger when ABOVE threshold
logic [9:0] dynamic_reset_threshold; // ADC threshold that triggers 
logic [7:0] min_delta_adc; // difference in ADC values that triggers
logic [WIDTH-2:0] input_events [NUMCHANNELS-1:0]; // pre-parity routed 
logic [63:0] csa_enable; // enable from config bits
logic [63:0] csa_reset_channel; // reset from channel_ctrl
logic [63:0] local_fifo_empty; // when low, event is ready
logic [63:0] triggered_natural; // low for external or cross trigger
logic [31:0] timestamp_32b;  //32-bit timestamp
logic [NUMCHANNELS-1:0] read_local_fifo_n; // low to read local fifo
logic cross_trigger; // high when any channels naturally hit
logic [NUMCHANNELS-1:0] periodic_trigger;
logic fifo_full;    // high when shared fifo full
logic fifo_half;    // high when shared fifo more than half full
logic shared_fifo_empty;    // high when shared fifo empty 
logic [FIFO_BITS:0] fifo_counter; // how full is shared fifo?
logic reset_n_sync;  // synced version of reset_n
logic reset_n_config_sync;  // synced version of reset_n_config
logic cds_mode; // high for correlated double sampling
logic read_fifo_n;  // read data from shared fifo (active low)
logic write_fifo_n;  // write data from shared fifo (active low)
logic [WIDTH-1:0] output_event; // event to put into the fifo
logic [7:0] config_bits [0:REGNUM-1];// regmap config bit outputs
logic [WIDTH-1:0] tx_data; // fifo data to be transmitted off-chip
logic [WIDTH-1:0] pre_event; // event (pre-parity) to put into fifo
logic load_event;     // high to load event from event builder
logic sync_timestamp; // timestamp set to 0 when high   
logic [4:0] digital_threshold_msb; // 5-bit shared value
logic [NUMCHANNELS*8-1:0] digital_threshold_lsb; // per channel value
logic [NUMCHANNELS-1:0] periodic_reset; // from reset pulser
logic lightpix_mode; // high to integrate hits for timeout
logic [6:0] hit_threshold; // how many hits to declare event?
logic [7:0] timeout; // number of clk cycles to wait for hits
logic [7:0] shadow_reset_length; // just in case...
logic [7:0] reset_length_channel; // just in case...
logic external_trigger_sync_active;
logic external_trigger_gated;
logic [ADCBITS-1:0] dout_channel [NUMCHANNELS-1:0]; 
logic [3:0] total_packets_lsbs; // 4 LSBs of total packets to embed

// need to use generates for large config words
// Cadence can't handle two dimensional ports
genvar g_i;
generate 
    for (g_i = 0; g_i < 64; g_i++) begin
        assign pixel_trim_dac[g_i*PIXEL_TRIM_DAC_BITS+(PIXEL_TRIM_DAC_BITS-1):g_i*PIXEL_TRIM_DAC_BITS] 
            = config_bits[PIXEL_TRIM+g_i][PIXEL_TRIM_DAC_BITS-1:0];
        // assign digital_threshold LSBs. Shared MSBs assigned below
        assign digital_threshold_lsb[g_i*8+7:g_i*8] 
            = config_bits[DIGITAL_THRESHOLD+g_i][7:0];
        // distribute ADC bits to internal channels
        assign dout_channel[g_i] = dout[g_i*10+9:g_i*10];
    end
endgenerate

generate
    for (g_i = 0; g_i < 8; g_i++) begin
        assign csa_enable[g_i*8+7:g_i*8] 
            = config_bits[CSA_ENABLE+g_i][7:0]; //DG: mod
        assign csa_bypass_select[g_i*8+7:g_i*8] 
            = config_bits[BYPASS_SELECT+g_i][7:0]; //DG: mod
        assign csa_monitor_select[g_i*8+7:g_i*8] 
            = config_bits[CSA_MONITOR_SEL+g_i][7:0]; //DG: mod
        assign csa_testpulse_enable[g_i*8+7:g_i*8] 
            = config_bits[CSA_TEST_ENABLE+g_i][7:0]; //DG: mod
        assign channel_mask[g_i*8+7:g_i*8] 
            = config_bits[CHANNEL_MASK+g_i][7:0]; //DG: mod
        assign external_trigger_mask[g_i*8+7:g_i*8] 
            = config_bits[EXTERN_TRIG_MASK+g_i][7:0]; //DG: mod
        assign cross_trigger_mask[g_i*8+7:g_i*8] 
            = config_bits[CROSS_TRIG_MASK+g_i][7:0]; //DG: mod
        assign periodic_trigger_mask[g_i*8+7:g_i*8] 
            = config_bits[PER_TRIG_MASK+g_i][7:0]; //DG: mod
    end // for
endgenerate

generate
    for (g_i = 0; g_i < 4; g_i++) begin
        assign periodic_trigger_cycles[g_i*8+7:g_i*8] 
            = config_bits[PER_TRIG_CYC+g_i][7:0]; //DG: mod
    end // for
endgenerate

generate
    for (g_i = 0; g_i < 3; g_i++) begin
        assign periodic_reset_cycles[g_i*8+7:g_i*8] 
            = config_bits[RESET_CYCLES+g_i][7:0]; //DG: mod
    end // for
endgenerate


// ------- Config registers to LArPix
always_comb begin
    threshold_global = config_bits[GLOBAL_THRESH][7:0];
    csa_gain = {64{config_bits[CSA_CTRL][0]}};
    csa_bypass_enable = {64{config_bits[CSA_CTRL][1]}};
    bypass_caps_enable = {64{config_bits[CSA_CTRL][2]}};
    ibias_tdac[15:12] = config_bits[IBIAS_TDAC][3:0];
    ibias_tdac[11:8] = config_bits[IBIAS_TDAC][3:0];
    ibias_tdac[7:4] = config_bits[IBIAS_TDAC][3:0];
    ibias_tdac[3:0] = config_bits[IBIAS_TDAC][3:0];
    ibias_comp[15:12] = config_bits[IBIAS_COMP][3:0];
    ibias_comp[11:8] = config_bits[IBIAS_COMP][3:0];
    ibias_comp[7:4] = config_bits[IBIAS_COMP][3:0];
    ibias_comp[3:0] = config_bits[IBIAS_COMP][3:0];
    ibias_buffer[15:12] = config_bits[IBIAS_BUFFER][3:0];
    ibias_buffer[11:8] = config_bits[IBIAS_BUFFER][3:0];
    ibias_buffer[7:4] = config_bits[IBIAS_BUFFER][3:0];
    ibias_buffer[3:0] = config_bits[IBIAS_BUFFER][3:0];
    ibias_csa[15:12] = config_bits[IBIAS_CSA][3:0];
    ibias_csa[11:8] = config_bits[IBIAS_CSA][3:0];
    ibias_csa[7:4] = config_bits[IBIAS_CSA][3:0];
    ibias_csa[3:0] = config_bits[IBIAS_CSA][3:0];
    ibias_vref_buffer = config_bits[IBIAS_VREF][3:0];
    ibias_vcm_buffer = config_bits[IBIAS_VCM][3:0];
    ibias_tpulse[3:0] = config_bits[IBIAS_TPULSE][3:0];
    ref_current_trim = config_bits[REFGEN][4:0];
    adc_comp_trim = config_bits[REFGEN][6:5];
    vref_dac = {{config_bits[DAC_VREF][7:1]},1'b0};
    vcm_dac = vref_dac >> 1;
    adc_ibias_delay = {4{config_bits[ADC_IBIAS_DELAY][3:0]}};
    adc_ibias_delay_monitor = config_bits[ADC_IBIAS_DELAY][7:4];
    csa_testpulse_dac = config_bits[CSA_TEST_DAC][7:0]; 
    current_monitor_bank0 = config_bits[IMONITOR0][3:0];
    current_monitor_bank1 = config_bits[IMONITOR0][7:4];
    current_monitor_bank2 = config_bits[IMONITOR1][3:0];
    current_monitor_bank3 = config_bits[IMONITOR1][7:4];
    voltage_monitor_bank0 = config_bits[VMONITOR0][2:0];
    voltage_monitor_bank1 = config_bits[VMONITOR0][5:3];
    voltage_monitor_bank2 = config_bits[VMONITOR1][2:0];
    voltage_monitor_bank3 = config_bits[VMONITOR1][5:3];
    voltage_monitor_refgen = config_bits[VMONITOR2][7:0];
    digital_monitor_enable = config_bits[DMONITOR0][0];
    digital_monitor_select = config_bits[DMONITOR0][4:1];
    digital_monitor_chan = config_bits[DMONITOR1][5:0];
    chip_id = config_bits[CHIP_ID][7:0];
    cds_mode = config_bits[DIGITAL][0];
    load_config_defaults = config_bits[DIGITAL][1];
    enable_fifo_diagnostics = config_bits[DIGITAL][2];
    enable_local_fifo_diagnostics = config_bits[DIGITAL][3];
    enable_tally = config_bits[DIGITAL][4];
    enable_external_trigger = config_bits[DIGITAL][5];
    enable_external_sync = config_bits[DIGITAL][6];
    enable_data_stats = config_bits[DIGITAL][7];
    enable_piso_upstream = config_bits[ENABLE_PISO_UP][3:0];
    enable_piso_downstream = config_bits[ENABLE_PISO_DOWN][3:0];
    enable_posi = config_bits[ENABLE_POSI][3:0];
    en_analog_monitor = config_bits[ANALOG_MONITOR][0];
    enable_cross_trigger = config_bits[ENABLE_TRIG_MODES][0];
    enable_periodic_reset = config_bits[ENABLE_TRIG_MODES][1];
    enable_rolling_periodic_reset = config_bits[ENABLE_TRIG_MODES][2];
    enable_periodic_trigger = config_bits[ENABLE_TRIG_MODES][3];
    enable_rolling_periodic_trigger = config_bits[ENABLE_TRIG_MODES][4];
    enable_periodic_trigger_veto = config_bits[ENABLE_TRIG_MODES][5];
    enable_hit_veto = config_bits[ENABLE_TRIG_MODES][6];
    adc_hold_delay = config_bits[ADC_HOLD_DELAY][7:0];
    shadow_reset_length = config_bits[SHADOW_RESET_LENGTH][7:0];
    adc_burst_length = config_bits[ADC_BURST][7:0];
    enable_dynamic_reset = config_bits[ENABLE_ADC_MODES][0];
    enable_min_delta_adc = config_bits[ENABLE_ADC_MODES][1];
    threshold_polarity = config_bits[ENABLE_ADC_MODES][2];
    reset_length = config_bits[ENABLE_ADC_MODES][5:3];
    mark_first_packet = config_bits[ENABLE_ADC_MODES][6];
    dynamic_reset_threshold[7:0] = config_bits[RESET_THRESHOLD][7:0];
    dynamic_reset_threshold[9:8] = config_bits[ANALOG_MONITOR][2:1];
    min_delta_adc = config_bits[MIN_DELTA_ADC][7:0];
    digital_threshold_msb[4:2] = config_bits[DIGITAL_THRESHOLD][7:5];
    digital_threshold_msb[1:0] = config_bits[DIGITAL_THRESHOLD+1][6:5];
    lightpix_mode = config_bits[LIGHTPIX0][0];
    hit_threshold = config_bits[LIGHTPIX0][7:1];
    timeout = config_bits[LIGHTPIX1][7:0];
    tx_slices0 = config_bits[TRX0][3:0];
    tx_slices1 = config_bits[TRX0][7:4];
    tx_slices2 = config_bits[TRX1][3:0];
    tx_slices3 = config_bits[TRX1][7:4];
    i_tx_diff0 = config_bits[TRX2][3:0];
    i_tx_diff1 = config_bits[TRX2][7:4];
    i_tx_diff2 = config_bits[TRX3][3:0];
    i_tx_diff3 = config_bits[TRX3][7:4];
    i_rx0 = config_bits[TRX4][3:0];
    i_rx1 = config_bits[TRX4][7:4];
    i_rx2 = config_bits[TRX5][3:0];
    i_rx3 = config_bits[TRX5][7:4];
    i_rx_clk = config_bits[TRX6][3:0];
    i_rx_rst = config_bits[TRX6][7:4];
    i_rx_ext_trig = config_bits[TRX7][7:4];
// HARDWIRE LSBs OF RX CURRENT
// control is active low so setting LSBs to 0 forces current to be non-zero
    i_rx0[1:0] = 2'b0;
    i_rx1[1:0] = 2'b0;
    i_rx2[1:0] = 2'b0;
    i_rx3[1:0] = 2'b0;
    i_rx_clk[1:0] = 2'b0;
    i_rx_rst[1:0] = 2'b0;
    i_rx_ext_trig[1:0] = 2'b0;
// END HARDWIRING LSB OF RX CURRENT

    r_term0 = config_bits[TRX8][4:0];
    r_term1 = config_bits[TRX9][4:0];
    r_term2 = config_bits[TRX10][4:0];
    r_term3 = config_bits[TRX11][4:0];
    r_term_clk = config_bits[TRX12][4:0];
    r_term_rst = config_bits[TRX13][4:0];
    r_term_ext_trig = config_bits[TRX14][4:0];

// HARDWIRE TERMINATION RESISTORS TO MAKE SURE THEY ARE NOT TOO SMALL
// control is active high, so set MSBs to 0 reduces number of parallel R
// set MSBs to 0, min resistance is 2.5k/7 = 357 ohms
    r_term0[4:3] = 2'b0;
    r_term1[4:3] = 2'b0;
    r_term2[4:3] = 2'b0;
    r_term3[4:3] = 2'b0;

// HARDWIRE SHARED INPUTS TO GUARANTEE HIGH IMPEDENCE 
    r_term_clk[4:0] = 5'b0;
    r_term_rst[4:0] = 5'b0;
    r_term_ext_trig[4:0] = 5'b0;
// END HARDWIRING OF TERMINATION RESISTORS

    v_cm_lvds_tx0 = config_bits[TRX15][3:0];
    v_cm_lvds_tx1 = config_bits[TRX15][7:4];
    v_cm_lvds_tx2 = config_bits[TRX16][3:0];
    v_cm_lvds_tx3 = config_bits[TRX16][7:4]; 

end // always_comb
// combine reset length

always_comb begin
    reset_length_channel = {5'b0,reset_length} | shadow_reset_length;
end
 // always_comb

// cross trigger
always_comb begin
    cross_trigger = |triggered_natural;
end // always_comb

// reset logic
always_comb begin
    for (int i=0; i<NUMCHANNELS; i=i+1) begin 
        csa_reset[i] = csa_reset_channel[i] | !csa_enable[i];
    end
end // always_comb

// external trigger/sync logic
always_comb begin
    if (enable_external_trigger) begin
        external_trigger_gated = external_trigger_sync_active;
    end
    else
        external_trigger_gated = 1'b0;

    if (enable_external_sync) begin
        sync_timestamp = external_trigger_sync_active;
    end
    else 
        sync_timestamp = 1'b0;
end // always_comb

// instantiate sub-blocks
genvar i;
generate
for (i=0; i<NUMCHANNELS; i=i+1) begin : CHANNELS
     channel_ctrl
        #(.MAIN_FIFO_BITS(FIFO_BITS)
        ) 
        channel_ctrl_inst (
        .channel_event          (input_events[i]),
        .adc_word               (adc_word[i]),
        .fifo_empty             (local_fifo_empty[i]),
        .triggered_natural      (triggered_natural[i]),
        .csa_reset              (csa_reset_channel[i]),
        .sample                 (sample[i]),
        .clk_out                (),
        .channel_enabled        (csa_enable[i]),
        .hit                    (hit[i]),
        .chip_id                (chip_id),
        .dout                   (dout_channel[i]),
        .done                   (done[i]),
        .channel_id             (i[5:0]),
        .adc_burst              (adc_burst_length),
        .adc_hold_delay         (adc_hold_delay),
        .timestamp_32b          (timestamp_32b),
        .reset_length           (reset_length_channel),
        .enable_dynamic_reset   (enable_dynamic_reset),
        .cds_mode               (cds_mode),
        .mark_first_packet      (mark_first_packet),
        .read_local_fifo_n      (read_local_fifo_n[i]),
        .external_trigger       (external_trigger_gated),
        .cross_trigger          (cross_trigger),
        .periodic_trigger       (periodic_trigger[i]),
        .periodic_reset         (periodic_reset[i]),
        .enable_min_delta_adc   (enable_min_delta_adc),
        .threshold_polarity     (threshold_polarity),
        .dynamic_reset_threshold    (dynamic_reset_threshold),
        .digital_threshold      ({digital_threshold_msb,digital_threshold_lsb[i*8+4:i*8]}),
        .min_delta_adc          (min_delta_adc),
        .fifo_full              (fifo_full),
        .fifo_half              (fifo_half),
        .enable_local_fifo_diagnostics    (enable_local_fifo_diagnostics),
        .channel_mask           (channel_mask[i]),
        .external_trigger_mask  (external_trigger_mask[i]),
        .cross_trigger_mask     (cross_trigger_mask[i]), 
        .periodic_trigger_mask  (periodic_trigger_mask[i]),
        .enable_periodic_trigger_veto  (enable_periodic_trigger_veto),
        .enable_hit_veto        (enable_hit_veto),
        .clk                    (clk),
        .reset_n                (reset_n_sync)
        );
    end // for loop
endgenerate

event_router
    #(.WIDTH(WIDTH)
    ) event_router_inst (
    .channel_event_out  (pre_event),
    .read_local_fifo_n  (read_local_fifo_n),
    .load_event         (load_event),
    .input_event        (input_events),
    .local_fifo_empty   (local_fifo_empty),
    .lightpix_mode      (lightpix_mode),
    .enable_fifo_diagnostics    (enable_fifo_diagnostics),
    .enable_tally       (enable_tally),
    .total_packets_lsbs (total_packets_lsbs),
    .fifo_counter       (fifo_counter),
    .hit_threshold      (hit_threshold),
    .timeout            (timeout),
    .fifo_ack           (fifo_ack),
    .clk                (clk),
    .reset_n            (reset_n_sync)
    );

fifo_top
    #(.FIFO_WIDTH(WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH),
    .FIFO_BITS(FIFO_BITS)
     ) fifo_top_inst (
    .data_out           (tx_data),
    .fifo_counter       (fifo_counter),
    .fifo_full          (fifo_full),
    .fifo_half          (fifo_half),
    .fifo_empty         (shared_fifo_empty),
    .data_in            (output_event),
    .read_n             (read_fifo_n),
    .write_n            (write_fifo_n),
    .chip_id            (chip_id),
    .timestamp_32b      (timestamp_32b),
    .clk                (clk),
    .reset_n            (reset_n_sync)
    );

external_interface
    #(.WIDTH(WIDTH),
    .GLOBAL_ID(255),
    .REGNUM(REGNUM),
    .FIFO_BITS(FIFO_BITS)
    ) external_interface_inst (
    .tx_out                     (piso),
    .output_event               (output_event),
    .config_bits                (config_bits),
    .tx_enable                  (tx_enable),
    .total_packets_lsbs         (total_packets_lsbs),
    .write_fifo_n               (write_fifo_n),
    .read_fifo_n                (read_fifo_n),
    .fifo_ack                   (fifo_ack),
    .tx_data                    (tx_data),
    .chip_id                    (chip_id),
    .pre_event                  (pre_event),
    .fifo_full                  (fifo_full),
    .fifo_half                  (fifo_half),
    .fifo_empty                 (shared_fifo_empty),
    .load_event                 (load_event),
    .load_config_defaults       (load_config_defaults),
    .timestamp_32b              (timestamp_32b),
    .enable_piso_upstream       (enable_piso_upstream),
    .enable_piso_downstream     (enable_piso_downstream),
    .enable_posi                (enable_posi),
    .rx_in                      (posi),
    .enable_fifo_diagnostics    (enable_fifo_diagnostics),
    .enable_data_stats          (enable_data_stats),
    .fifo_counter               (fifo_counter),
    .clk                        (clk),
    .reset_n_clk                (reset_n_sync),
    .reset_n_config             (reset_n_config_sync)
    );

// this module generates the 32b timestamp
timestamp_gen
    timestamp_gen_inst (
        .timestamp_32b      (timestamp_32b),
        .sync_timestamp     (sync_timestamp),
        .clk                (clk),
        .reset_n            (reset_n_sync)
    );

// this module does clock domain crossing for the reset_n pulse 
reset_sync
    reset_sync_inst (
        .reset_n_sync           (reset_n_sync),
        .reset_n_config_sync    (reset_n_config_sync),
        .clk                    (clk),
        .reset_n                (reset_n)
    );

// this module synchronizes the external trigger/sync
async2sync
    async2sync_inst (
        .sync                   (external_trigger_sync_active),
        .async                  (external_trigger),
        .clk                    (clk)
    );

// this pulser generates the periodic trigger pulse    
periodic_pulser
    #(.PERIODIC_PULSER_W(32),
    .NUMCHANNELS(NUMCHANNELS))
    periodic_trigger_inst (
    .periodic_pulse     (periodic_trigger),
    .pulse_cycles       (periodic_trigger_cycles),
    .enable             (enable_periodic_trigger),
    .enable_rolling_pulse   (enable_rolling_periodic_trigger),
    .clk                (clk),
    .reset_n            (reset_n_sync)
    );

// this pulser generates the periodic reset pulse    
periodic_pulser
    #(.PERIODIC_PULSER_W(24),
    .NUMCHANNELS(NUMCHANNELS))
    periodic_reset_inst (
    .periodic_pulse         (periodic_reset),
    .pulse_cycles           (periodic_reset_cycles),
    .enable                 (enable_periodic_reset),
    .enable_rolling_pulse   (enable_rolling_periodic_reset),
    .clk                    (clk),
    .reset_n                (reset_n_sync)
    );

// digital monitor

digital_monitor
    digital_monitor_inst (
    .digital_monitor        (digital_monitor),
    .digital_monitor_enable (digital_monitor_enable),
    .digital_monitor_select (digital_monitor_select),
    .digital_monitor_chan   (digital_monitor_chan),
    .hit                    (hit),
    .comp                   ({64{1'b0}}),
    .sample                 (sample),
    .csa_reset              (csa_reset),
    .triggered_natural      (triggered_natural),
    .periodic_trigger       (periodic_trigger),
    .periodic_reset         (periodic_reset),
    .external_trigger       (external_trigger_sync_active),
    .cross_trigger          (cross_trigger),
    .reset_n_config_sync    (reset_n_config_sync),
    .sync_timestamp         (sync_timestamp)
    );

endmodule
