///////////////////////////////////////////////////////////////////
// File Name: event_router.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Routes event from one of 16 channels to shared FIFO.
//              LArPix packet is 64 bits. Number of rx channels = 16
//              channel_event_out[67:4] is the LArPix packet 
//              channel_event_out[3:0] is the channel ID
///////////////////////////////////////////////////////////////////

module event_router
    #(parameter WIDTH = 64,
    parameter NUMCHANNELS = 16)
    (output logic [WIDTH+3:0] channel_event_out,// routed event 
    output logic [NUMCHANNELS-1:0] read_rx, // high to read rx uart 
    output logic load_event_n,    // low to put data in FIFO
    input logic [WIDTH-1:0] input_events [NUMCHANNELS-1:0], // data in
    input logic [NUMCHANNELS-1:0] rx_empty, // when low, event ready
    input logic clk,           // primary clock
    input logic reset_n);      // asynchronous digital reset (active low)

// temp storage
logic [NUMCHANNELS-1:0] channel_waiting; // each bit high for waiting chan
logic [NUMCHANNELS-1:0] channel_blacklist; // channel not yet reset
logic [NUMCHANNELS-1:0] read_rx_fast; // read_rx on fast clk domain
logic [1:0] wait_counter; // wait state counter
logic wait_counter_done; // wait state counter (wait for RX reset)
logic [NUMCHANNELS-1:0] veto_event;       // high if already dealing with it

// state machine
enum logic [2:0] // explicit state definitions 
            {READY = 3'h0,
            READ_EVENT = 3'h1,
            VETO_CHECK = 3'h2,
            LATCH_EVENT = 3'h3,
            WAIT_STATE = 3'h4} State, Next;

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        State <= READY;
    else
        State <= Next;
end // always_ff


always_comb begin
    case (State)
        READY:  if (!(&rx_empty))               Next = READ_EVENT; 
                else                            Next = READY;
        READ_EVENT:                             Next = VETO_CHECK;
        VETO_CHECK: if (veto_event)             Next = READY;
                    else                        Next = LATCH_EVENT;
        LATCH_EVENT:                            Next = WAIT_STATE;  
        WAIT_STATE: if (wait_counter_done)      Next = READY;
                    else                        Next = WAIT_STATE;
        default:                                Next = READY;
    endcase
end // always_comb

// state machine 
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        load_event_n <= 1'b1;
        read_rx_fast <= '0;
        channel_event_out <= '0;
        channel_waiting <= '0;
        channel_blacklist <= '0;
        veto_event <= '0;
        wait_counter <= 2'b0;
        wait_counter_done <= 1'b1;
    end
    else begin
        load_event_n <= 1'b1;
        read_rx_fast <= '0;
        case(Next)
            READY:  begin
                channel_waiting <= '0;
                channel_event_out  <= '0;
                for (int i = 0; i < 16; i++) begin
                    if (channel_blacklist[i]) begin
                        if (rx_empty[i]) begin
                            channel_blacklist[i] <= 1'b0;
                            veto_event[i] <= 1'b0;
                        end
                    end
                end 
                                    
            end // READY
            READ_EVENT: begin   
                wait_counter <= 2'b0;
                wait_counter_done <= 1'b0;
                for (int i = 0; i < 16; i++) begin
                    if ( (rx_empty[i] == 1'b0) ) begin
                        channel_waiting[i] <= 1'b1;
                        channel_blacklist[i] <= 1'b1;
                        if (!channel_blacklist[i]) begin
                            read_rx_fast[i] <= 1'b1;
                        end
                        else begin
                            veto_event[i] <= 1'b1;
                        end
                        break; // only read out one 
                    end
                end
            end // READ_EVENT
            VETO_CHECK: ;
            LATCH_EVENT: begin
                for (int i = 0; i < 16; i++) begin
                    if ( (channel_waiting[i] == 1'b1) ) begin
                        channel_event_out[67:4] <= input_events[i];
                        channel_event_out[3:0] <= i;
                        channel_waiting[i] <= 1'b0;
                    end
                end
            end // LATCH_EVENT
            WAIT_STATE: begin
                wait_counter <= wait_counter + 1'b1;
                load_event_n <= 1'b0;
                if (wait_counter >= 2'b10) begin
                    wait_counter_done <= 1'b1;
                end // if
            end // WAIT_STATE
            default: ;
        endcase
    end
end 

// need pulse stretcher for each read_rx_fast signal
genvar i;
generate
    for (i=0; i<NUMCHANNELS; i=i+1) begin : PULSE_STRETCHERS
        pulse_stretcher
            pulse_stretcher_int (
            .pulse_out      (read_rx[i]),
            .pulse_in       (read_rx_fast[i]),
            .stretch_mode   (1'b0),  // 0 = 3 bits (rx), 1 = 4 bits (tx)
            .clk            (clk)
        );
    end
endgenerate
 
endmodule           

