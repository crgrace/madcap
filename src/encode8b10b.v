///////////////////////////////////////////////////////////////////
// File Name: encode8b10b.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Finite state machine builds output packets and
//              sends to serializer when ready
//   
//              Block algorithm:
//              When the serializer is empty
//
//              Outputs are registered to avoid glitches and to
//              standardize input and output delay constraints.
//
///////////////////////////////////////////////////////////////////
//                              -*- Mode: Verilog -*-
// Filename        : encode8b10b.v
// Description     : 8b10b encoder based on IBM paper. Added disparity in and out
//                   to combine multiple modules for parallel operation
//                   ¡°A DC-Balanced, Partitioned-Block, 8b/10b Transmission
//                    Code¡± by A. X. Widmer and P. A. Franaszek
// Author          : Thorsten Stezelberger
// Created On      : Fri May 09 08:36:06 2014
// Last Modified By:
// Last Modified On: Fri May 09 08:36:06 2014
// Update Count    : 0

module encode8b10b (/*AUTOARG*/
         // Outputs
         data_out, disp_out,
         // Inputs
         clk, reset_n, data_in, disp_in, k_in
       ) ;
input  clk; // for the output registers
input  reset_n;
input  [7:0] data_in;
input  disp_in; // 0 = neg disp; 1 = pos disp
input  k_in;
output reg [9:0] data_out;
output  disp_out; // 0 = neg disp; 1 = pos disp; not registered

wire    disp_out;


wire   ndl6_n;
wire   pdl6_n;
wire   compls6;
wire   pdl4o;
wire   compls4;

wire   pdl4i = disp_in;
assign disp_out = pdl4o;


// map the input vectors to the 8B/10B naming scheme
// ?i maps to the upper case letter in the paper
wire   ai = data_in[0];
wire   bi = data_in[1];
wire   ci = data_in[2];
wire   di = data_in[3];
wire   ei = data_in[4];
wire   fi = data_in[5];
wire   gi = data_in[6];
wire   hi = data_in[7];
wire   ki = k_in;


// The following blobks refer to the IBM 8B/10B paper blocks (figures)
// Not all invertian of signals are generated. The will be inverted
// appropratly when used

// _ne_ not equal

// Figure 3  Encoder  5B/6B classification; L functions
wire   a_ne_b = (ai ^ bi);
wire   c_ne_d = (ci ^ di);

wire   L22 = (ai & bi & ~ci & ~di) |
       (ci & di & ~ai & ~bi) |
       (a_ne_b & c_ne_d);
wire   L40 = ai & bi & ci & di;
wire   L04 = ~ai & ~bi & ~ci & ~di;
wire   L13 = (a_ne_b & ~ci & ~di) |
       (c_ne_d & ~ai & ~bi);
wire   L31 = (a_ne_b & ci & di) |
       (c_ne_d & ai & bi);

// Figure 4  Encoder  3B/4B classification; S function
wire   ss = (~pdl6_n & L31 & di & ~ei) | (~ndl6_n & L13 & ~di & ei);



// Figure 5  Encoder  Disparity classification
//
wire   pd1s6 = (L13 & di & ei) | (~L22 & ~ L31 & ~ei);
wire   nd0s6 = pd1s6;
wire   nd1s6 = (L31 & ~di & ~ei) | (ei & ~L22 & ~L13) | ki;
wire   pd0s6 = (ei & ~L22 & ~L13) | ki;
wire   nd1s4 = fi & gi;
wire   nd0s4 = (~fi & ~gi);
wire   pd1s4 = (~fi & ~gi) | ((fi ^ gi) & ki);
wire   pd0s4 = fi & gi & hi;

// Figure 6  Encoder control of complementation
assign ndl6_n = (pd0s6 & ~compls6) | (compls6 & nd0s6) | (~nd0s6 & ~pd0s6 & pdl4i);
assign pdl6_n = ~ndl6_n;
assign compls6 = (nd1s6 & pdl4i) | (~pdl4i & pd1s6);
assign pdl4o = (ndl6_n & ~pd0s4 & ~nd0s4) | (nd0s4 & compls4) | (~compls4 & pd0s4);
//   assign disp_out = (~ndl6_n & ~pd0s4 & ~nd0s4) | (nd0s4 & compls4) | (~compls4 & pd0s4);
assign compls4 = (nd1s4 & ndl6_n) | (~ndl6_n & pd1s4);


// Figure 7  5B/6B encoding
wire   as = ai;
wire   bs = (~L40 & bi) | L04;
wire   cs = L04 | ci | (L13 & ei & di); // rewrote ~(~L13 | ~ei | ~di)
wire   ds = ~(~di | L40);
wire   es = (L13 & ~ei) | ((~L13 | ~ei | ~di) & ei);
wire   is = (~ei & L22) | (L22 & ki) | (L04 & ei) | (ei & L40) | (ei & L13 & ~di);

// Figure 8  3B/4B encoding
wire   fs = ~(~fi | (ss & fi & gi & hi) | (fi & gi & hi & ki));
wire   gs = gi | (~fi & ~gi & ~hi);
wire   hs = hi;
wire   js = (ss & fi & gi & hi) | (fi & gi & hi & ki) | ((fi ^ gi) & ~hi);


// assign and complement out put
always @(posedge clk or negedge reset_n)
  if (reset_n == 0)
    data_out <= 10'b0;
  else
    begin
      data_out [0] <= as ^ compls6;
      data_out [1] <= bs ^ compls6;
      data_out [2] <= cs ^ compls6;
      data_out [3] <= ds ^ compls6;
      data_out [4] <= es ^ compls6;
      data_out [5] <= is ^ compls6;
      data_out [6] <= fs ^ compls4;
      data_out [7] <= gs ^ compls4;
      data_out [8] <= hs ^ compls4;
      data_out [9] <= js ^ compls4;
    end // else: !if(reset == 0)



endmodule // encode8b10b
