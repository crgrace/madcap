///////////////////////////////////////////////////////////////////
// File Name: uart_tasks.sv
// Engineerr:  Carl Grace (crgrace@lbl.gov)
// Description:     Tasks for operating the LArPix/MADCAP UART 
//          
///////////////////////////////////////////////////////////////////

`ifndef _uart_tasks_
`define _uart_tasks_

`include "madcap_constants.sv"  // all sim constants defined here

task sendWordToLarpix;
input [1:0] op;
input [7:0] chip_id;
input [7:0] addr;
input [7:0] data;
logic debug;
begin
    debug = 0;
    if (debug) $display("in task: sending word to LArPix");
    #100
    @(negedge clk_tx)
//    #100 
    @(negedge clk_tx)
    ld_tx_data = 0;
    data_to_larpix= {(WIDTH-1){1'b0}};
    data_to_larpix[1:0] = op;  
    data_to_larpix[9:2] = chip_id;
    data_to_larpix[17:10] = addr;
    data_to_larpix[25:18] = data;
    if (debug) begin
        $display("\nin task:sending work to LArPix");
        $display("op = %d",op);
        $display("chip_id = %d", chip_id);
        $display("addr = %d", addr);
        $display("data = %d", data);
    end
    data_to_larpix[WIDTH-1]= ~^data_to_larpix[WIDTH-2:0];
    sent_data = data_to_larpix;
    if (debug) $display("word sent (hex) = %h\n",data_to_larpix);
//    #150 
    @(negedge clk_tx) 
    ld_tx_data = 1;
//    #150 
    @(negedge clk_tx)
    ld_tx_data = 0;
    wait (!tx_busy);
end
endtask

function [31:0] logic create_madcap_packet
    (input logic [1:0] packet_declaration,
    input logic [4:0] chip_id,
    input logic [7:0] regmap_address,
    input logic [7:0] regmap_data
    );
    return {    9'h000, 
                regmap_data, 
                regmap_address, 
                chip_id,
                packet_declaration }
endfunction : create_madcap_command

function [31:0] logic create_larpix_packet
    (input logic [1:0] packet_declaration,
    input logic [25:0] larpix_packet,
    input logic [2:0] target_larpix
    );
    return {    target_larpix,
                larpix_packet,
                packet_declaration
    );
endfunction : create_larpix_command 

function [31:0] logic create_comma_packet
    (input logic [7:0] comma=`K_K);    
    return { 4{comma} };
endfunction : create_comma_packet

    

`endif // _uart_tasks_
