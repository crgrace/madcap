///////////////////////////////////////////////////////////////////
// File Name: encode8b10b.sv
// Engineer:  Thorsten Stezelberger (tstezelberger@lbl.gov)
//              (ported to SystemVerilog by Carl Grace)
//
// Description: 8b10b encoder based on IBM paper. Added disparity 
//              in and out to combine multiple modules for 
//              parallel operation
//
//              Reference:
//              "A DC-Balanced, Partitioned-Block, 8b/10b Transmission
//              Code" by A. X. Widmer and P. A. Franaszek
//
///////////////////////////////////////////////////////////////////

module encode8b10b_sv (
        output logic [9:0] data_out,
        output logic disp_out,// 0 = neg disp; 1 = pos disp; not registered
        input logic [7:0] data_in,
        input logic disp_in,        // 0 = neg disp; 1 = pos disp
        input logic k_in,           // high to denote k character
        input logic clk,            // primary clock
        input logic reset_n);       // asynchronous reset (active low)

logic   ndl6_n;
logic   pdl6_n;
logic   compls6;
logic   pdl4o;
logic   compls4;

// input mapping
logic   ai = data_in[0];
logic   bi = data_in[1];
logic   ci = data_in[2];
logic   di = data_in[3];
logic   ei = data_in[4];
logic   fi = data_in[5];
logic   gi = data_in[6];
logic   hi = data_in[7];
logic   ki = k_in;

// Figure 3  Encoder  5B/6B classification; L functions
logic   a_ne_b;
logic   c_ne_d;

logic   L22;
logic   L40;
logic   L04; 
logic   L13;
logic   L31;

// Figure 4  Encoder  3B/4B classification; S function
logic   ss;

// Figure 5  Encoder  Disparity classification
logic   pd1s6; 
logic   nd0s6;
logic   nd1s6;
logic   pd0s6;
logic   nd1s4;
logic   nd0s4;
logic   pd1s4;
logic   pd0s4;

// Figure 7  5B/6B encoding
logic   as; 
logic   bs;
logic   cs;
logic   ds;
logic   es;
logic   is;

// Figure 8  3B/4B encoding
logic   fs;
logic   gs;
logic   hs;
logic   js; 

logic   pdl4i = disp_in;

always_comb 
begin
    disp_out = pdl4o;
end // always_comb

// map the input vectors to the 8B/10B naming scheme
// ?i maps to the upper case letter in the paper
always_comb 
begin : MAPPING
    ai = data_in[0];
    bi = data_in[1];
    ci = data_in[2];
    di = data_in[3];
    ei = data_in[4];
    fi = data_in[5];
    gi = data_in[6];
    hi = data_in[7];
    ki = k_in;
end // always_comb : MAPPING

// The following blobks refer to the IBM 8B/10B paper blocks (figures)
// Not all invertian of signals are generated. The will be inverted
// appropratly when used

// _ne_ not equal

// Figure 3  Encoder  5B/6B classification; L functions
always_comb
begin : FIG_3
    a_ne_b = (ai ^ bi);
    c_ne_d = (ci ^ di);
    L22 = (ai & bi & ~ci & ~di) |
        (ci & di & ~ai & ~bi) |
        (a_ne_b & c_ne_d);
    L40 = ai & bi & ci & di;
    L04 = ~ai & ~bi & ~ci & ~di;
    L13 = (a_ne_b & ~ci & ~di) |
        (c_ne_d & ~ai & ~bi);
    L31 = (a_ne_b & ci & di) |
        (c_ne_d & ai & bi);
end // always_comb : FIG_3

// Figure 4  Encoder  3B/4B classification; S function
always_comb
begin : FIG_4
    ss = (~pdl6_n & L31 & di & ~ei) | (~ndl6_n & L13 & ~di & ei);
end // always_comb


// Figure 5  Encoder  Disparity classification
always_comb 
begin : FIG_5
    pd1s6 = (L13 & di & ei) | (~L22 & ~ L31 & ~ei);
    nd0s6 = pd1s6;
    nd1s6 = (L31 & ~di & ~ei) | (ei & ~L22 & ~L13) | ki;
    pd0s6 = (ei & ~L22 & ~L13) | ki;
    nd1s4 = fi & gi;
    nd0s4 = (~fi & ~gi);
    pd1s4 = (~fi & ~gi) | ((fi ^ gi) & ki);
    pd0s4 = fi & gi & hi;
end // always_comb FIG_5

// Figure 6  Encoder control of complementation
always_comb 
begin : FIG_6
    ndl6_n = (pd0s6 & ~compls6) | (compls6 & nd0s6) |
            (~nd0s6 & ~pd0s6 & pdl4i);
    pdl6_n = ~ndl6_n;
    compls6 = (nd1s6 & pdl4i) | (~pdl4i & pd1s6);
    pdl4o = (ndl6_n & ~pd0s4 & ~nd0s4) | (nd0s4 & compls4) |
            (~compls4 & pd0s4);
    compls4 = (nd1s4 & ndl6_n) | (~ndl6_n & pd1s4);
end // always_comb FIG_6

// Figure 7  5B/6B encoding
always_comb 
begin : FIG_7
    as = ai;
    bs = (~L40 & bi) | L04;
    cs = L04 | ci | (L13 & ei & di); // rewrote ~(~L13 | ~ei | ~di)
    ds = ~(~di | L40);
    es = (L13 & ~ei) | ((~L13 | ~ei | ~di) & ei);
    is = (~ei & L22) | (L22 & ki) | (L04 & ei) | (ei & L40) | 
        (ei & L13 & ~di);
end // always_comb FIG_7

// Figure 8  3B/4B encoding
always_comb
begin : FIG_8
    fs = ~(~fi | (ss & fi & gi & hi) | (fi & gi & hi & ki));
    gs = gi | (~fi & ~gi & ~hi);
    hs = hi;
    js = (ss & fi & gi & hi) | (fi & gi & hi & ki) | ((fi ^ gi) & ~hi);
end // always_comb FIG_8

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
