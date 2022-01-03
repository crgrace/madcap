///////////////////////////////////////////////////////////////////
// File Name: config_regfile_mc.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Dual-port register file for configuration bits 
//              Regfile has up to 256 distinct 8-bit registers
//
///////////////////////////////////////////////////////////////////

module config_regfile_mc
    #(parameter REGNUM = 256)
    (output logic [7:0] config_bits [0:REGNUM-1], // output bits
    output logic [7:0] read_data,           // RAM data out (for readback)
    input logic [7:0] write_addr,           // RAM write address 
    input logic [7:0] write_data,           // RAM data in
    input logic [7:0] read_addr,            // RAM read address 
    input logic write,                      // high for write op
    input logic read,                       // high for read op
    input logic load_config_defaults,       // load config default values
    input logic clk,                        // system clock
    input logic reset_n                     // digital reset (active low)
);

// configuration word definitions
// located at ../testbench/tasks/
// example compilation: 
//vlog +incdir+../testbench/tasks/ -incr -sv "../src/config_regfile_mc.sv"
`include "madcap_constants.sv"

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        read_data <= 8'b0;
        // SET DEFAULTS
`include "config_regfile_assign_mc.sv" // in ../testbench/tasks
    end 
    else begin
        if (load_config_defaults) begin
        // SET DEFAULTS
`include "config_regfile_assign_mc.sv"
        end // if 
        if (write) begin       
            config_bits[write_addr] <= write_data;
        end // write
        if (read) begin
            read_data <= config_bits[read_addr];
        end // write
    end    // else
end // always_ff

endmodule
                
        

