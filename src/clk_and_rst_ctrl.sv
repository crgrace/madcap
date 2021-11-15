///////////////////////////////////////////////////////////////////
// File Name: clk_and_rst_ctrl.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Performs following functions:
//              1. distributes reset pulse to tile
//              2. divides down primary clock to LArPix (rx) clk 
//              3. divides down rx clk to tx clk (to send config to tile)
//              3. distributes LArPix clks to tile
//              4. syncronizes reset for MADCAP internal use
//
//  Core Clock (nominally 80 MHz) is 8X LArPix clock (nominally 10 MHz) 
//  LArPix rx clock is always tx (config) clock
//
///////////////////////////////////////////////////////////////////

module clk_and_rst_ctrl



