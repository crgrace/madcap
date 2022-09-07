///////////////////////////////////////////////////////////////////
// File Name: larpix_stim.v
// Author:  Carl Grace (crgrace@lbl.gov)
//          (c) 2017 Lawrence Berkeley National Laboratory
// Description:     Creates stimulus and tagging for LArPix sim
//                      NOT SYNTHESIZABLE   
///////////////////////////////////////////////////////////////////


`timescale 1ns/10ps

module larpix_stim
    #(parameter NUMCHANNELS = 32,
    parameter NUMCHIPS = 1,
    parameter MAX_E = 20000
    )
    (output [NUMCHANNELS*64-1):0] chargeSignal, // charge input to larpix
    output [63:0] setTag,  // tagged input signal to scoreboard
    input [7:0] whichChip,
    input [




endmodule


