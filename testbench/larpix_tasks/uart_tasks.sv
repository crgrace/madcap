///////////////////////////////////////////////////////////////////
// File Name: uart_tasks.sv
// Engineerr:  Carl Grace (crgrace@lbl.gov)
// Description:     Tasks for operating the LArPix UART 
//          
///////////////////////////////////////////////////////////////////

`ifndef _uart_tasks_
`define _uart_tasks_

`include "larpix_constants.sv"  // all sim constants defined here

task sendWordToLarpix;
input [1:0] op;
input [7:0] chip_id;
input [7:0] addr;
input [7:0] data;
logic debug;
logic use_magic_number;
begin
    debug = 0;
    use_magic_number = 1;
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
    if (use_magic_number) begin
        data_to_larpix[57:26] = MAGIC_NUMBER;
    end
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
    if (debug) $display("waiting for clk_tx");
    @(negedge clk_tx) 
    if (debug) $display("set ld_tx_data = 1");
    ld_tx_data = 1;
//    #150 
    if (debug) $display("waiting for clk_tx");
    @(negedge clk_tx)
    ld_tx_data = 0;
    wait (!tx_busy);
end
endtask




`endif // _uart_tasks_
