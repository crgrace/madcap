///////////////////////////////////////////////////////////////////
// File Name: uart_tasks.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
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
logic use_correct_parity;
begin
    debug = 0;

// NOTE: normal operation: 
//  use_magic_number = 1;
//  use_correct_parity = 1;
//
// only modify if you are intending to inject errors into packet

    use_magic_number = 1;
    use_correct_parity = 1;
    if (debug) $display("in task: sending word to LArPix");
    #10000
    @(negedge clk)
//    #100 
    @(negedge clk)
    ld_tx_data = 0;
    data_to_larpix= {(WIDTH-1){1'b0}};
    data_to_larpix[1:0] = op;  
    data_to_larpix[9:2] = chip_id;
    data_to_larpix[17:10] = addr;
    data_to_larpix[25:18] = data;

    if (use_magic_number) begin
        data_to_larpix[57:26] = MAGIC_NUMBER;
    end
    else begin
        data_to_larpix[57:26] = $urandom;
        $display("uart_task.sv: intentionally adding incorrect magic number");
        $display("uart_task.sv: magic number used = %h",data_to_larpix[57:26]);
    end // if

    if (debug) begin
        $display("\nin task:sending work to LArPix");
        $display("op = %d",op);
        $display("chip_id = %d", chip_id);
        $display("addr = %d", addr);
        $display("data = %d", data);
    end
    if (use_correct_parity) begin    
        data_to_larpix[WIDTH-1] = ~^data_to_larpix[WIDTH-2:0];
    end
    else begin
        $display("uart_task.sv: intentionally injecting incorrect parity");
        data_to_larpix[WIDTH-1] = ^data_to_larpix[WIDTH-2:0];
    end
    sent_data = data_to_larpix;
    if (debug) $display("word sent (hex) = %h\n",data_to_larpix);
//    #150 
    if (debug) $display("waiting for clk");
    @(negedge clk) 
    if (debug) $display("set ld_tx_data = 1");
    ld_tx_data = 1;
//    #150 
    if (debug) $display("waiting for clk");
    @(negedge clk)
    ld_tx_data = 0;
    wait (!tx_busy);
end
endtask




`endif // _uart_tasks_
