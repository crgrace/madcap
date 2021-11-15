///////////////////////////////////////////////////////////////////
// File Name: uart_trx_tb.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: SystemVerilog testbench for UART rx and tx blocks.
///////////////////////////////////////////////////////////////////

module uart_trx_tb();

logic reset_n;
logic ld_tx_data;
logic [63:0] tx_data;
logic [63:0] sent_data;
logic tx_enable;
logic tx_out;
logic tx_busy;
logic uld_rx_data;
logic [63:0] rx_data;
logic rx_enable;
logic rx_in;
logic rx_empty;
logic clk_fast;
logic clk_core;
logic clk_rx;
logic clk_tx;
integer errors;

function integer getSeed;
// task gets a seed from the Linux date program. 
// call "date" and put out time in seconds since Jan 1, 1970 (when time began)
// and puts the results in a file called "now_in_seconds"
integer fp;
integer fgetsResult;
integer sscanfResult;
integer NowInSeconds;
reg [8*10:1] str;
begin
    $system("date +%s > now_in_seconds");                                       
            
    fp = $fopen("now_in_seconds","r");
    fgetsResult = $fgets(str,fp);
    sscanfResult = $sscanf(str,"%d",NowInSeconds);
    getSeed = NowInSeconds;
    $fclose(fp);
    //$display("seed = %d\n",getSeed);
//    start=$random(seed); 
end
endfunction

task testUART
    (input integer num_trials = 10);
    integer seed, start, errors, verbose;

begin
    verbose = 1;
    errors = 0;
    seed = getSeed();
    start = $random(seed);
    for (int trial = 0; trial < num_trials; trial++) begin
        #400 tx_data = {$urandom(),$urandom()};
        sent_data = tx_data;
        if (verbose) $display("UART TEST: sent data = %h", tx_data);
        #200 ld_tx_data = 1;
        #200 ld_tx_data = 0;
        wait (!rx_empty);
        #100 if (verbose) $display("UART TEST: received data = %h", rx_data);
        if (rx_data != sent_data) begin
            $error("ERROR: rx data different from tx data\n");
            $display("tx data = %h",sent_data);
            $display("rx data = %h",rx_data);
            errors = errors + 1;
        end
        else begin
            if (verbose) $display ("rx data matches tx data\n");
        end
    end // for
   

    $display("UART TRX test complete. Found %0d errors in %0d trials",errors,num_trials);

end
endtask

// connect output of DUT to testbench RX
always_comb begin
    rx_in = tx_out;
end
// RX and TX Clock generation
initial begin
    forever begin   
        #1 clk_fast = ~clk_fast;
    end
end // initial

// read RX data when done to allow another read
always_ff @(negedge clk_rx)
begin
    if (!rx_empty) begin
        uld_rx_data <= 1'b1;
    end
    else begin
        uld_rx_data <= 1'b0;
    end
    
end // always_ff

initial begin
// $dumpfile("uart.vcd");
//  $dumpvars();
    clk_fast = 0;
    reset_n = 1;
    tx_enable = 1;
    rx_enable = 1;
    ld_tx_data = 0;
 //   uld_rx_data = 0;
    errors = 0;
    #40 reset_n = 0;
    #40 reset_n = 1;
    testUART(10);
end // initial

// DUT Connected here
uart_tx 
    uart_tx_inst (
    .tx_out         (tx_out),
    .tx_busy        (tx_busy),
    .tx_data        (tx_data),
    .ld_tx_data     (ld_tx_data),
    .tx_enable      (tx_enable),
    .clk_tx         (clk_tx),
    .reset_n        (reset_n)
);

// UART RX for testing TX here
uart_rx
    uart_rx_inst (
    .rx_data        (rx_data),
    .rx_empty       (rx_empty),
    .parity_error   (parity_error),
    .rx_in          (rx_in),
    .uld_rx_data    (uld_rx_data),
    .clk_rx         (clk_rx),
    .reset_n        (reset_n)
);

// clock gen
clk_manager
    clk_manager_inst (
    .clk_core       (clk_core),
    .clk_rx         (clk_rx),
    .clk_tx         (clk_tx),
    .clk_fast       (clk_fast),
    .reset_n        (reset_n)
    );


endmodule
