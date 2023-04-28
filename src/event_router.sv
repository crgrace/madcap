///////////////////////////////////////////////////////////////////
// File Name: event_router.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Routes event from one of 64 channels to shared FIFO.
//     
// For LightPix, there are a lot of dark counts so we integrate for
// some number of clock cycles and only commit events to chip FIFO 
// if we get enough hits before the integration window closes.
// Otherwise, we can just ignore the integration either with a mode 
// bit or by setting the threshold to 1 & integration to 1
///////////////////////////////////////////////////////////////////

module event_router
    #(parameter WIDTH = 64,
    parameter NUMCHANNELS = 64)
    (output logic [WIDTH-1:0] channel_event_out,// routed event (w/ parity)
    output logic [NUMCHANNELS-1:0] read_local_fifo_n, // low to read fifo
    output logic load_event,    // event ready to put in FIFO
    input logic [WIDTH-2:0] input_event [NUMCHANNELS-1:0], // data in
    input logic [NUMCHANNELS-1:0] local_fifo_empty, // when low, event ready
    input logic lightpix_mode, // high to integrate hits for timeout
    input logic enable_tally, // high to embed running tally in packet
    input logic enable_fifo_diagnostics, // high to replace MSBs of tstamp
    input logic [3:0] total_packets_lsbs, // number of packets generated
    input logic [11:0] fifo_counter, // current shared fifo occupancy
    input logic [6:0] hit_threshold, // how many hits to declare event?
    input logic [7:0] timeout, // number of clk cycles to wait for hits
    input logic fifo_ack,   // comms controller acknowledge FIFO read
    input logic clk,           // master clock
    input logic reset_n);      // asynchronous digital reset (active low)

// temp storage
logic [WIDTH-2:0] channel_event;// routed event (pre-parity)
logic [NUMCHANNELS-1:0] channel_waiting; // each bit high for waiting chan
logic [NUMCHANNELS-1:0] fifo_empty_hold; // hold FIFO state so
                        // events do not get stale
logic [6:0] total_hits;     // sum of all waiting channels
logic [8:0] event_timer;    // how many clks we have been integrating for
logic event_accepted;       // hits passed threshold within timeout
logic event_complete;       // event done 
logic [1:0] wait_counter; // wait state counter
logic wait_counter_done; // wait state counter (used to allow time for FIFO)

// count number of waiting channels 
// Local FIFO not empty means event waiting for readout
always_comb begin
    total_hits = 7'b0;  
    for (int i = 0; i < NUMCHANNELS; i++) begin
        total_hits = total_hits + (~local_fifo_empty[i]);
    end // for
end // always_comb

// calculate parity
always_comb begin
    channel_event_out = {~^channel_event,channel_event};
end // always_comb

// state machine
enum logic [2:0] // explicit state definitions 
            {READY = 3'h0,
            INTEGRATE_EVENTS = 3'h1,
            READ_EVENT = 3'h2,
            LATCH_EVENT = 3'h3,
            ADD_TALLY = 3'h4,
            CLEAN_UP = 3'h5,
            WAIT_STATE = 3'h6} State, Next;

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        State <= READY;
    else
        State <= Next;
end // always_ff


always_comb begin
    case (State)
        READY:  if (!(&local_fifo_empty))       Next = INTEGRATE_EVENTS; 
                else                            Next = READY;
        INTEGRATE_EVENTS:  if (event_accepted)  Next = READ_EVENT;
                else if (event_complete)        Next = CLEAN_UP;
                else                            Next = INTEGRATE_EVENTS;
        READ_EVENT:                             Next = LATCH_EVENT;
        LATCH_EVENT: if (fifo_ack) begin
                        if (!(&fifo_empty_hold) && enable_tally)
                                Next = ADD_TALLY;
                        else if (!(&fifo_empty_hold)) Next = READ_EVENT;  
                        else if (!event_complete)Next = INTEGRATE_EVENTS;
                        else                    Next = READY;
                    end
                    else                        Next = LATCH_EVENT;
        ADD_TALLY:                              Next = READ_EVENT;
        CLEAN_UP:                               Next = READY;
        WAIT_STATE: if (wait_counter_done)      Next = READ_EVENT;
                else                            Next = WAIT_STATE;
        default:                                Next = READY;
    endcase
end // always_comb

// state machine 
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        load_event <= 1'b0;
        channel_event <= 63'b0;
        channel_waiting <= 64'b0;
        fifo_empty_hold <= 64'b0;
        read_local_fifo_n <= {64{1'b1}};
        event_accepted <= 1'b0;
        event_complete <= 1'b0;
        event_timer <= 9'b0;
        wait_counter <= 2'b0;
        wait_counter_done <= 1'b1;
    end
    else begin
        load_event <= 1'b0;
        read_local_fifo_n <= {64{1'b1}};
        case(Next)
            READY:  begin
                channel_waiting <= 64'b0;
                channel_event <= 63'b0;
                event_accepted <= 1'b0;
                event_complete <= 1'b0;
                event_timer <= 6'b0;    
            end // READY
            INTEGRATE_EVENTS: begin
                event_timer <= event_timer + 1'b1;
                fifo_empty_hold <= local_fifo_empty;
                if (lightpix_mode) begin
                    if (event_timer >= timeout) begin
                        event_accepted <= 1'b0; // event finished
                        event_complete <= 1'b1;
                    end
                    else if (total_hits >= hit_threshold) begin
                        event_accepted <= 1'b1;
                    end
                end // if lightpix_mode
                else begin
                    event_complete <= 1'b1; // LArPix auto-completes
                    event_accepted <= 1'b1; // LArPix auto-accepts
                end
            end // INTEGRATE EVENTS
            READ_EVENT: begin   
                wait_counter <= 2'b0;
                wait_counter_done <= 1'b0;
                event_timer <= event_timer + 1'b1;
                for (int i = 0; i < 64; i++) begin
                    if ( (fifo_empty_hold[i] == 1'b0) ) begin
                        channel_waiting[i] <= 1'b1;
                        read_local_fifo_n[i] <= 1'b0;
                        fifo_empty_hold[i] <= 1'b1;
                        break; // only read out one 
                    end
                end
            end // READ_EVENT
            LATCH_EVENT: begin
                event_timer <= event_timer + 1'b1;
                if (event_accepted) begin
                    load_event <= 1'b1;
                end
                for (int i = 0; i < 64; i++) begin
                    if ( (channel_waiting[i] == 1'b1) ) begin
                        channel_event <= input_event[i];
                        channel_waiting[i] <= 1'b0;
                    end
                end
                if (enable_tally) begin
                    channel_event[61:58] <= total_packets_lsbs + 1'b1;
                end
                if (enable_fifo_diagnostics) begin
                    channel_event[43:32] <= fifo_counter;
                end

            end // LATCH_EVENT
            ADD_TALLY: begin
                if (enable_tally) begin
                    channel_event[61:58] <= total_packets_lsbs;
                end
                if (enable_fifo_diagnostics) begin
                    channel_event[43:32] <= fifo_counter;
                end
            end // ADD_TALLY
            CLEAN_UP: begin // dump local fifos
                read_local_fifo_n <= fifo_empty_hold;
            end
            WAIT_STATE: begin
                wait_counter <= wait_counter + 1'b1;
                if (wait_counter >= 2'b10) begin
                    wait_counter_done <= 1'b1;
                end // if
            end // WAIT_STATE
            default: ;
        endcase
    end
end 
endmodule           

