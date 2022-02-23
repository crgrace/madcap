///////////////////////////////////////////////////////////////////
// File Name: madcap_config_tasks.sv
// Engineerr:  Carl Grace (crgrace@lbl.gov)
// Description:     Tasks for operating the LArPix/MADCAP UART 
//          
///////////////////////////////////////////////////////////////////

`ifndef _madcap_config_tasks_
`define _madcap_config_tasks_

//`include "madcap_constants.sv"  // all sim constants defined here
function [47:0] create_madcap_packet
    (input logic [1:0] mc_packet_declaration,
    input logic [1:0] mc_chip_id,
    input logic [7:0] mc_regmap_address,
    input logic [7:0] mc_regmap_data
    );
    return {    16'h00,                 // bits[47:32]
                mc_regmap_data,         // bits[31:24]
                mc_regmap_address,      // bits[23:16]
                4'h0,                 // bits[15:12]
                mc_chip_id,             // bits[11:10]
                mc_packet_declaration,  // bits[9:8]
                `K_F                    // bits[7:0]
            };
endfunction : create_madcap_packet

function [47:0] create_larpix_packet
    (input logic [1:0] mc_packet_declaration,
    input logic [1:0] mc_chip_id,
    input logic [1:0] lp_packet_declaration,
    input logic [7:0] lp_chip_id,
    input logic [7:0] lp_regmap_address,
    input logic [7:0] lp_regmap_data,
    input logic [3:0] target_larpix
    );
    return {    5'h00,                  // bits[47:43]
                target_larpix,          // bits[42:39]
                lp_regmap_data,         // bits[38:31]
                lp_regmap_address,      // bits[30:23]
                lp_chip_id,             // bits[22:15]
                lp_packet_declaration,  // bits[14:13]
                1'b0,                   // bits[12]
                mc_chip_id,             // bits[11:10]
                mc_packet_declaration,  // bits[9:8]
                `K_F                    // bits[7:0]
    };
endfunction : create_larpix_packet 

function [47:0] create_idle_packet
    (input logic [7:0] idle=`K_K);    
    return {    idle,                  // bits[47:40]
                idle,                  // bits[39:32]
                idle,                  // bits[31:24]
                idle,                  // bits[23:16]
                idle,                  // bits[15:8]
                idle                   // bits[7:0]
    };
endfunction : create_idle_packet

function [47:0] create_lp_trigger_packet
    (input logic [7:0] idle=`K_R);    
    return {    idle,                  // bits[47:40]
                idle,                  // bits[39:32]
                idle,                  // bits[31:24]
                idle,                  // bits[23:16]
                idle,                  // bits[15:8]
                `K_R                   // bits[7:0]
    };
endfunction : create_lp_trigger_packet
`endif // _madcap_config_tasks_
