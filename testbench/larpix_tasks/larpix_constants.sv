///////////////////////////////////////////////////////////////////
// File Name: larpix_constants.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description:  Constants for LArPix operation and simulation
//          
///////////////////////////////////////////////////////////////////

`ifndef _larpix_constants_
//`ifndef SYNTHESIS 
`define _larpix_constants_
//`endif

// declare needed variables
localparam TRUE = 1;
localparam FALSE = 0;
localparam SILENT = 0;
localparam VERBOSE = 1;          // high to print out verification results

// localparams to define config registers
// configuration word definitions
localparam PIXEL_TRIM = 0;
localparam GLOBAL_THRESH = 64;
localparam CSA_CTRL = 65;
localparam CSA_ENABLE = 66;
localparam IBIAS_TDAC = 74;
localparam IBIAS_COMP = 75;
localparam IBIAS_BUFFER = 76;
localparam IBIAS_CSA = 77;
localparam IBIAS_VREF= 78;
localparam IBIAS_VCM = 79;
localparam IBIAS_TPULSE = 80;
localparam REFGEN = 81;
localparam DAC_VREF = 82;
localparam DAC_VCM = 83;
localparam BYPASS_SELECT = 84;
localparam CSA_MONITOR_SEL = 92;
localparam CSA_TEST_ENABLE = 100;    
localparam CSA_TEST_DAC = 108;
localparam IMONITOR0 = 109;
localparam IMONITOR1 = 110;
localparam IMONITOR2 = 111;
localparam IMONITOR3 = 112;
localparam VMONITOR0 = 113;
localparam VMONITOR1 = 114;
localparam VMONITOR2 = 115;
localparam VMONITOR3 = 116;
localparam VMONITOR4 = 117;
localparam DMONITOR0 = 118;
localparam DMONITOR1 = 119;
localparam ADC_HOLD_DELAY = 120;
localparam CHIP_ID = 122;
localparam DIGITAL = 123;
localparam ENABLE_PISO_UP = 124;
localparam ENABLE_PISO_DOWN = 125;
localparam ENABLE_POSI = 126;
localparam UART_TEST_MODE = 127;
localparam ENABLE_TRIG_MODES = 128;
localparam SHADOW_RESET_LENGTH = 129;
localparam ADC_BURST = 130; 
localparam CHANNEL_MASK = 131;
localparam EXTERN_TRIG_MASK = 139;
localparam CROSS_TRIG_MASK = 147;
localparam PER_TRIG_MASK = 155;
localparam RESET_CYCLES = 163;
localparam PER_TRIG_CYC = 166;
localparam ENABLE_ADC_MODES = 170;
localparam RESET_THRESHOLD = 171;
localparam MIN_DELTA_ADC = 172;
localparam DIGITAL_THRESHOLD = 173;
localparam LIGHTPIX0 = 237;
localparam LIGHTPIX1 = 238;
localparam TRX0 = 239;
localparam TRX1 = 240;
localparam TRX2 = 241;
localparam TRX3 = 242;
localparam TRX4 = 243;
localparam TRX5 = 244;
localparam TRX6 = 245;
localparam TRX7 = 246;
localparam TRX8 = 247;
localparam TRX9 = 248;
localparam TRX10 = 249;
localparam TRX11 = 250;
localparam TRX12 = 251;
localparam TRX13 = 252;
localparam TRX14 = 253;
localparam TRX15 = 254;
localparam TRX16 = 255;


// UART ops
localparam DATA = 2'b00;
localparam TEST = 2'b01;
localparam CONFIG_WRITE = 2'b10;
localparam CONFIG_READ = 2'b11;

// SPI ops
localparam WRITE = 1;
localparam READ = 0;


`endif // _larpix_constants_
