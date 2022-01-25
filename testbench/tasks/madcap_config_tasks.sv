///////////////////////////////////////////////////////////////////
// File Name: madcap_config_tasks.sv
// Engineerr:  Carl Grace (crgrace@lbl.gov)
// Description:     Tasks for operating the LArPix/MADCAP UART 
//          
///////////////////////////////////////////////////////////////////

`ifndef _madcap_config_tasks_
`define _madcap_config_tasks_

//`include "madcap_constants.sv"  // all sim constants defined here
function [39:0] create_madcap_packet
    (input logic [1:0] packet_declaration,
    input logic [5:0] chip_id,
    input logic [7:0] regmap_address,
    input logic [7:0] regmap_data
    );
    return {    9'h000, 
                regmap_data, 
                regmap_address, 
                chip_id,
                packet_declaration,
                `K_F 
            };
endfunction : create_madcap_packet

function [39:0] create_larpix_packet
    (input logic [1:0] packet_declaration,
    input logic [25:0] larpix_packet,
    input logic [2:0] target_larpix
    );
    return {    target_larpix,
                larpix_packet,
                packet_declaration,
                `K_F
    };
endfunction : create_larpix_packet 

function [39:0] create_comma_packet
    (input logic [7:0] comma=`K_K);    
    return {    comma,
                comma,
                comma,
                comma,
                comma
    };
endfunction : create_comma_packet

    

`endif // _madcap_config_tasks_
