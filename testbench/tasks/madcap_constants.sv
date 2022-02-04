///////////////////////////////////////////////////////////////////
// File Name: madcap_constants.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description:  Constants for MADCAP operation and simulation
//          
///////////////////////////////////////////////////////////////////

`ifndef _madcap_constants_
`ifndef SYNTHESIS 
`define _madcap_constants_
`endif

// declare needed variables

localparam TRUE = 1;
localparam FALSE = 0;
localparam SILENT = 0;
localparam VERBOSE = 1;          // high to print out verification results

// localparams to define config registers
// configuration word definitions
localparam REFGEN       = 0;
localparam IMONITOR     = 1;
localparam VMONITOR     = 2;
localparam DMONITOR     = 3;
localparam CONFIG       = 4;
localparam TEST_MODE    = 5;
localparam TEST_PACKETS = 6;
localparam SERIALIZER   = 18;
localparam TX_ENABLE    = 19;
localparam TRX0         = 21;
localparam TRX1         = 22;
localparam TRX2         = 23;
localparam TRX3         = 24;
localparam TRX4         = 25;
localparam TRX5         = 26;
localparam TRX6         = 27;
localparam PD_LVDS      = 28;
localparam PD_DRIVER    = 29;
localparam PD_TRIGGER   = 30;
localparam PD_RX        = 31;
localparam PD_TX        = 33;
localparam SPARE        = 34;

// PRBS7
localparam PRBS7_ROM = 127'b1000001100001010001111001000101100111010100111110100001110001001001101101011011110110001101001011101110011001010101111111000000;

// SPI ops
localparam WRITE = 1;
localparam READ = 0;


`endif // _madcap_constants_
