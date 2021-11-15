///////////////////////////////////////////////////////////////////
// File Name: tile_model.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description:
//          Simple model for 4 LArPix tiles (TX UART interfaces)  
//
///////////////////////////////////////////////////////////////////

module tile_model
    #(parameter WIDTH = 8)
    (output logic [WIDTH-1:0] dataword, // deserialized data
    input logic din,                    // input bit
    input logic frame_start,             // high to indicate new frame
    input logic clk,                    // primary clock
    input logic reset_n);               // asynchronous active-low reset

localparam COUNT_WIDTH = $clog2(WIDTH);//bits in fifo addr range

logic [COUNT_WIDTH-1:0] frame_count;// where are we in the frame?
logic [WIDTH-1:0] dataword_filling; // in progress datawords

assign #1 clk_delay = clk;

always_ff @(posedge clk_delay or negedge reset_n) begin
    if (!reset_n) begin
        for (int i = 0; i < WIDTH; i++) begin
            dataword[i] = 0;
        end  
    end
    else begin
        if ((frame_count == WIDTH-1)) begin
            dataword = dataword_filling;
        end
    end
end // always_ff

always_ff @(clk_delay or negedge reset_n) begin
    if (!reset_n) begin
        frame_count = 0;
        for (int i = 0; i < WIDTH; i++) begin
            dataword_filling[i] = 0;
        end
    end 
    else begin
        if (frame_start && clk == 1'b1) begin
            frame_count = 0;
        end 
        else begin 
            frame_count = frame_count + 1;
        end
        dataword_filling[frame_count] = din;
    end
end // always_ff

endmodule

