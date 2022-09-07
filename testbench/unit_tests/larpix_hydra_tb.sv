`timescale 1ns/1ps
`default_nettype none
//
module larpix_hydra_tb();

//`include "larpix_tasks_top.v"

// parameters

parameter E_CHARGE = 1.6e-19;   // electronic charge in Columbs
parameter NUM_E = 100e3;      // number of electrons in charge packet
parameter NUM_E_10 = 75e3;      // number of electrons in charge packet
parameter VREF = 1.0;       // top end of ADC range
parameter VCM = 0.5;        // bottom end of ADC range
parameter WIDTH = 64;       // width of packet (w/o start & stop bits) 
parameter WORDWIDTH = 8;    // width of programming registers
parameter NUMCHANNELS = 64; // number of analog channels
parameter ADCBITS = 8;      // number of bits in ADC
parameter PIXEL_TRIM_DAC_BITS = 5;  // number of bits in pixel trim DAC
parameter GLOBAL_DAC_BITS = 8;  // number of bits in global threshold DAC
parameter TESTPULSE_DAC_BITS = 8;  // number of bits in testpulse DAC
parameter CFB_CSA = 50e-15;         // feedback capacitor in CSA
parameter VOUT_DC_CSA = 0.5;        // nominal dc output voltage of CSA
parameter REGNUM = 256;     // number of programming registers
parameter LOCAL_FIFO_DEPTH = 4; // number of channel FIFO memory locations
parameter FIFO_DEPTH = 512;  // number of FIFO memory locations
parameter FIFO_BITS = 9;    // # of bits to describe fifo addr range
parameter MIP = -2.8e-15;  // electron MIP gives 70 mV at CSA output

logic piso0 [3:0];  // PRIMARY-IN-SECONDARY-OUT TX UART output bit
logic piso1 [3:0];  // PRIMARY-IN-SECONDARY-OUT TX UART output bit
logic piso2 [3:0];  // PRIMARY-IN-SECONDARY-OUT TX UART output bit
logic piso3 [3:0];  // PRIMARY-IN-SECONDARY-OUT TX UART output bit
logic posi_fpga; // data output from outside cryostat
logic th; // tie-high. Models pullup resistor in uart
logic clk, clk_delay;
logic reset_n;
logic digital_monitor0;
logic digital_monitor1;
logic digital_monitor2;
logic digital_monitor3;
real monitor_out_r0;
real monitor_out_r1;
real monitor_out_r2;
real monitor_out_r3;

logic external_trigger;
// real number arrays are not allowed, so we have to do this the hard way 
real charge_in_r [NUMCHANNELS-1:0];
//real charge_in_chan1_r;
//real charge_in_chan10_r;
logic [63:0] sentTag;


always
    clk_delay = #12 clk;

initial begin
//    $sdf_annotate("/home/lxusers/c/crgrace/verilog/verilog_larpix_rev2_syn/par/digital_core.output.sdf",larpix_hydra_tb.larpix_v2_inst0);

    th = 1;
    external_trigger = 0;
#1500000
    for (int trigNum = 0; trigNum < 1; trigNum++) begin
        #100000 external_trigger = 1;
        #200 external_trigger = 0;
        $display("EXTERNAL TRIGGER number %0d",trigNum);
    end // for
end

// MCP goes here
mcp_larpix_hydra
    #(.WIDTH(WIDTH),
    .WORDWIDTH(WORDWIDTH),
    .REGNUM(REGNUM),
    .FIFO_DEPTH(FIFO_DEPTH) 
    ) mcp_inst (
    .posi           (posi_fpga),
    .charge_in_r    (charge_in_r),
    .clk            (clk),
    .reset_n        (reset_n),
    .piso           (piso0[0])
);

// network of 4 LArPix instances
// DUT (LARPIX full-chip model) LArPix1 is connected to FPGA
larpix_v2b
    larpix_v2b_inst0 (
    .piso               (piso0),
    .digital_monitor    (digital_monitor0),
    .monitor_out_r      (monitor_out_r0),
    .charge_in_r        (charge_in_r),
    .external_trigger   (external_trigger),
    .posi               ({th,piso1[0],th,posi_fpga}),
    .clk                (clk_delay),
    .reset_n            (reset_n)   
    );

larpix_v2b
    larpix_v2b_inst1 (
    .piso               (piso1),
    .digital_monitor    (digital_monitor1),
    .monitor_out_r      (monitor_out_r1),
    .charge_in_r        (charge_in_r),
    .external_trigger   (external_trigger),
    .posi               ({piso2[1],piso3[0],th,piso0[2]}),
    .clk                (clk_delay),
    .reset_n            (reset_n)   
    );

larpix_v2b
    larpix_v2b_inst2 (
    .piso               (piso2),
    .digital_monitor    (digital_monitor2),
    .monitor_out_r      (monitor_out_r2),
    .charge_in_r        (charge_in_r),
    .external_trigger   (external_trigger),
    .posi               ({th,th,piso1[3],th}),
    .clk                (clk_delay),
    .reset_n            (reset_n)   
    );

larpix_v2b
    larpix_v2b_inst3 (
    .piso               (piso3),
    .digital_monitor    (digital_monitor3),
    .monitor_out_r      (monitor_out_r3),
    .charge_in_r        (charge_in_r),
    .external_trigger   (external_trigger),
    .posi               ({th,th,th,piso1[2]}),
    .clk                (clk),
    .reset_n            (reset_n)   
    );

endmodule
