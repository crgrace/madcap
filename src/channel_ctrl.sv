///////////////////////////////////////////////////////////////////
// File Name: channel_ctrl.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Finite state machine to control ADC opertation, 
//              build event, and send event to FIFO
//              Outputs are registered to avoid glitches and to
//              standardize input and output delay constraints.
//
//              There is one channel_ctrl block per ADC in the system
//              This module merges the functionality of sar_ctrl.v,
//              channel_ctrl.v, and event_builder.v in the original
//              LArPix-v1 verilog code.
///////////////////////////////////////////////////////////////////

module channel_ctrl
    #(parameter integer unsigned WIDTH = 64,  // width of packet (w/o start & stop bits) 
    parameter integer unsigned MAIN_FIFO_BITS = 12,
    parameter integer unsigned LOCAL_FIFO_DEPTH = 8) 
    (output logic [WIDTH-2:0] channel_event, // event to shared fifo
    output logic [9:0] adc_word, // helpful for debugging (not used by RTL)
    output logic fifo_empty,    // is data ready to write to shared FIFO?
    output logic triggered_natural,  // high to indicate valid hit
    output logic csa_reset,     // reset CSA
    output logic sample,        // high to sample CSA output
    //output logic strobe,        // high to strobe SAR ADC
    output logic clk_out,       // copy of master clock used in TDC
    input logic channel_enabled, // high if channel enabled
    input logic hit,            // high when discriminator fires
    input logic [9:0] dout,     // ADC output bits
    input logic done,           // async ADC conversion complete    
    input logic [7:0] chip_id,  // unique id for each chip
    input logic [5:0] channel_id,// unique identifier for each ADC channel 
    input logic [7:0] adc_burst,// how many conversions to do each hit
    input logic [7:0] adc_hold_delay,// number of clock cycles for sampling
    input logic [31:0] timestamp_32b,     // time stamp to write to event
    input logic unsigned [7:0] reset_length,   // # of cycles to hold CSA in reset
    input logic enable_dynamic_reset,  // high for data-driven reset
    input logic cds_mode,           // high to send CDS reset packet
    input logic mark_first_packet, // MSB of timestamp = 1 for first packet 
    input logic read_local_fifo_n,  // low to read out local fifo
    input logic external_trigger,     // high when external trigger raised
    input logic cross_trigger,        // high when another channel is hit
    input logic periodic_trigger,   // high when periodic trigger
    input logic periodic_reset,   // high when periodic reset
    input logic enable_min_delta_adc, // high for rst based on settling
    input logic threshold_polarity, // high for ADC above threshold
    input logic [9:0] dynamic_reset_threshold, // rst threshold
    input logic [9:0] digital_threshold, // only write if adc > this
    input logic [7:0] min_delta_adc, // min delta before rst triggered
    input logic fifo_full,            // high when shared fifo is full 
    input logic fifo_half,            // high when shared fifo is half full 
    input logic enable_local_fifo_diagnostics,// high to embed fifo counts
    input logic channel_mask,         // high to mask out this channel
    input logic external_trigger_mask,// high to disable external trigger
    input logic cross_trigger_mask,       // high to disable cross trigger
    input logic periodic_trigger_mask, // high to disable periodic trigger
    input logic enable_periodic_trigger_veto, // high to enable veto
    input logic enable_hit_veto, // if high hit must = 1 to go into hold
    input logic clk,        // master clock    
    input logic reset_n);   // asynchronous digital reset (active low)

// local FIFO parameters
localparam LOCAL_FIFO_BITS = $clog2(LOCAL_FIFO_DEPTH); // bits in fifo addr

// define states
enum logic [3:0] // explicit state definitions 
            {IDLE = 4'h0,
            SAMPLE = 4'h1,
            GET_RESET_SAMPLE = 4'h2,
            RESET_CSA = 4'h3,
            CONVERT = 4'h4,
            SAR_DONE = 4'h5,
            SAVE_RESET_SAMPLE = 4'h6,
            REQUEST_READOUT = 4'h7,
            TRANSFER_RESET_SAMPLE = 4'h8,
            WAIT_STATE = 4'h9, 
            TRANSFER_ADC_CODE = 4'ha,
            MODE_RESET = 4'hb} State, Next;

// triggers
logic triggered_external;   // high if valid external trigger
logic triggered_cross;      // high if valid cross trigger
logic triggered_periodic;    // high if valid peridodic trigger
logic triggered_channel;    // high if channel triggered (in any way)
logic [1:0] trigger_type; //00: normal, 01: ext, 10: cross,11: periodic
logic [1:0] trigger_type_latched; // latched version of trigger type
// ADC signals
logic [7:0] sample_counter;
logic [31:0] timestamp_latched; // grab timestamp as soon as we have a hit
logic strobe_en;  // enables clk to be used as ADC strobe
//logic strobe;  // ADC strobe (not used anymore)

// internal registers
logic [7:0] adc_burst_counter; // current ADC conversion number
logic [2:0] wait_counter; // waits for event router
logic unsigned [7:0] reset_counter; // clock cycle currently in reset
logic [WIDTH-2:0] pre_event; // event before put into local FIFO
logic [WIDTH-2:0] reset_event; // CDS reset sample for local FIFO
logic [WIDTH-2:0] fifo_event; // event to load into local FIFO

logic [10:0] delta_adc; // difference between two adcs
logic [9:0] previous_adc_word; // value of last conversion
logic first_conversion; // high when ADC is doing 1st conversion after hit
logic periodic_reset_triggered; // execute a periodic reset (not vetoed)
logic csa_reset_triggered; // programmatic reset trigger
logic csa_reset_held; // high when natural reset ouput required
logic csa_reset_flag; // high when CSA in reset
logic last_call; // one additional conversion after threshold 
logic final_conversion; // high during final conversion of reset threshold
logic readout_mode; // high when controller is attempting FIFO write

// internal signals
logic have_reset_sample; // high if reset sample has been taken already
logic write_local_fifo_n; // low to write event to local memory
logic [LOCAL_FIFO_BITS:0] local_fifo_counter; // max 16 memory locations
logic local_fifo_full; // high when fifo is in overflow 
logic local_fifo_half; // high when fifo is half full 
logic strobe_BAR; // inverted strobe


gate_posedge_clk
    ICGP(.EN(strobe_en), //change on posedge clk
    .CLK(clk),
    .ENCLK(strobe_BAR)
    );

//always_comb strobe = ~strobe_BAR; // TP: removed, not used anymore
//always_comb clk_out = clk; // remove if clk_needed
always_comb clk_out = 1'b0;

// trigger logic
always_comb begin
    triggered_natural = hit & ~channel_mask;

    triggered_external = (external_trigger & ~external_trigger_mask);

    triggered_cross = (cross_trigger & ~cross_trigger_mask);

    triggered_periodic = (periodic_trigger & ~periodic_trigger_mask
        & ~(hit & enable_periodic_trigger_veto) & (State == IDLE)); 

    triggered_channel = (triggered_natural | triggered_external
        | triggered_cross | triggered_periodic);

    case ({triggered_natural,triggered_external,
            triggered_cross,triggered_periodic}) 
        4'b1000: trigger_type = 2'b00;
        4'b0100: trigger_type = 2'b01;
        4'b0010: trigger_type = 2'b10;
        4'b0001: trigger_type = 2'b11;
        default: trigger_type = 2'b00;
    endcase
end // always_comb

// reset_logic
always_comb begin
    csa_reset = ( csa_reset_triggered
                | csa_reset_flag 
                | periodic_reset_triggered);
end // always_comb

// FIFO mux
always_comb begin
    if (have_reset_sample)
        fifo_event = reset_event;
    else
        fifo_event = pre_event;
end // always_comb 
    
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        csa_reset_held <= 1'b0;
        csa_reset_flag <= 1'b0;      
        reset_counter <= 8'h00; 
    end
    else begin
        if (csa_reset_triggered & (reset_length >= 8'h01) ) begin
            if (reset_counter < (reset_length - 1'b1)) begin
                csa_reset_flag <= 1'b1;
                csa_reset_held <= 1'b1;
                reset_counter <= reset_counter + 1'b1;
            end
        end
        if (csa_reset_flag & (!csa_reset_triggered)) begin
            if (reset_counter < (reset_length - 2'b10) ) begin
                csa_reset_held <= 1'b1;
                reset_counter <= reset_counter + 1'b1;
            end
            else begin  
                csa_reset_held <= 1'b0;
                reset_counter <= 8'h00;
                csa_reset_flag <= 1'b0;
            end
        end
        else begin 
            csa_reset_held <= 1'b0;
            reset_counter <= 8'h00;
        end
    end
end // always_ff 

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        State <= IDLE;
    else
        State <= Next;
end // always_ff

always_comb begin
    case (State)
        IDLE:   if (channel_enabled) begin
                    if (triggered_channel)      Next = SAMPLE; 
                    else if ((cds_mode == 1'b1)
                            && (have_reset_sample == 1'b0)
                            && (adc_burst_counter == 1'b0)) 
                                                Next = GET_RESET_SAMPLE;
                    else                        Next = IDLE;
                end
                else                        Next = IDLE;
        SAMPLE: if (trigger_type_latched != 2'b00)  Next = RESET_CSA;
                else if (sample_counter < adc_hold_delay) Next = SAMPLE;
                else if (adc_burst_counter < adc_burst) Next = RESET_CSA;
                else if (enable_hit_veto & !hit) Next = IDLE; 
                else                        Next = RESET_CSA;
        GET_RESET_SAMPLE: if ((sample_counter < adc_hold_delay)
                            && (adc_burst_counter < adc_burst)) 
                                            Next = GET_RESET_SAMPLE;
                else                        Next = CONVERT;
        RESET_CSA: if (!first_conversion & enable_dynamic_reset)   Next = CONVERT; 
                else if (adc_burst >= adc_burst_counter) Next = CONVERT;
                else if (reset_counter >= reset_length)   Next = CONVERT;
                else                        Next = CONVERT;
        CONVERT:  if (done == 1'b1)       Next = SAR_DONE;
                else                        Next = CONVERT;
        SAR_DONE: if ((cds_mode == 1'b1)
                        && (have_reset_sample == 1'b0)
                        && (adc_burst_counter == 1'b0)) Next = SAVE_RESET_SAMPLE;
                  else Next = REQUEST_READOUT;
        SAVE_RESET_SAMPLE: Next = IDLE;
        REQUEST_READOUT: if (!local_fifo_full) begin
                            if (have_reset_sample == 1'b1) Next = TRANSFER_RESET_SAMPLE;
                            else              Next = TRANSFER_ADC_CODE;
                            end
                else                        Next = REQUEST_READOUT;
        TRANSFER_RESET_SAMPLE:              Next = WAIT_STATE;
        WAIT_STATE:   if (wait_counter >= 3'b100)  Next = TRANSFER_ADC_CODE;
                    else                            Next = WAIT_STATE;
        TRANSFER_ADC_CODE: if (adc_burst == 8'h00)   Next = IDLE;
                  else if ((adc_burst_counter >= adc_burst) 
                        && (adc_burst > 8'h00)) Next = IDLE;
                  else if (final_conversion == 1'b1)   Next = IDLE;
                  else                      Next = SAMPLE;
        MODE_RESET: if (reset_counter >= reset_length) Next = IDLE;
                  else                      Next = MODE_RESET;
        default:                            Next = IDLE;
    endcase
end // always_comb

// registered outputs
always_ff @(posedge clk  or negedge reset_n) begin
    if (!reset_n) begin
        pre_event <= 63'b0;
        reset_event <= 63'b0;
        csa_reset_triggered <= 1'b1;
        periodic_reset_triggered <= 1'b0;
        sample <= 1'b1;
        strobe_en <= 1'b0;
        adc_word <= 8'b0;
        sample_counter <= 8'b0;
        adc_burst_counter <= 8'b0;
        timestamp_latched <= 32'b0;
        trigger_type_latched <= 2'b0;
        write_local_fifo_n <= 1'b1;
        previous_adc_word <= 8'b0;
        delta_adc <= 9'h1ff;
        first_conversion <= 1'b1;
        final_conversion <= 1'b0;
        readout_mode <= 1'b0;
        last_call <= 1'b0;
        have_reset_sample <= 1'b0;
        wait_counter <= 3'b0;
    end else begin
        csa_reset_triggered <= 1'b0;
        periodic_reset_triggered <= 1'b0;
        sample <= 1'b0;
        strobe_en <= 1'b0;
        write_local_fifo_n <= 1'b1;
        readout_mode <= 1'b0;
        case(Next)
            IDLE:       begin
                            pre_event <= 63'b0;
                            sample <= 1'b1;
                            adc_burst_counter <= 8'b0;
                            trigger_type_latched <= 2'b0;
                            adc_word <= 8'b0;
                            first_conversion <= 1'b1;
                            final_conversion <= 1'b0;
                            delta_adc <= 9'h1ff;
                            previous_adc_word <= 8'b0;
                            last_call <= 1'b0;
                            wait_counter <= 3'b0;
                            // only respond to periodic resets in IDLE state
                            // (else veto them)
                            if (periodic_reset) begin
                                periodic_reset_triggered <= 1'b1;
                            end
                        end
            SAMPLE:     begin
                            adc_word <= 8'b0;
                            sample_counter <= sample_counter + 1'b1;
                            if (adc_burst_counter >= adc_burst)
                                trigger_type_latched <= trigger_type;
                            //strobe_en <= 1'b1; REMOVE IF WANT STROBE
                            sample <= 1'b1;
                            if (last_call) begin
                                final_conversion <= 1'b1;
                            end
                        end
            GET_RESET_SAMPLE: begin
                            adc_word <= 8'b0;
                            timestamp_latched <= timestamp_32b[27:0];
                            sample_counter <= sample_counter + 1'b1;
                        end
            RESET_CSA:  begin
                            timestamp_latched <= timestamp_32b[27:0];
                            if (mark_first_packet) begin
                                if (first_conversion) begin 
                                    timestamp_latched[27] <= 1'b1; 
                                end
                                else begin
                                    timestamp_latched[27] <= 1'b0; 
                                end
                            end
                            if ( ((reset_counter <= reset_length) 
                                && (first_conversion & (adc_burst == 8'h00)))
                                && (!enable_dynamic_reset)
                                && (!enable_min_delta_adc) 
                                || (adc_burst_counter == (adc_burst-1'b1) )
                                || (final_conversion == 1'b1)) begin
                                csa_reset_triggered <= 1'b1;
                            end
                        end
            CONVERT:  begin 
                            first_conversion <= 1'b0;
                            last_call <= 1'b0;
                            sample_counter <= 16'b0;
                        end  
            SAR_DONE:  begin
                           adc_word <= dout;
                           sample <= 1'b1;
                        end
            SAVE_RESET_SAMPLE: begin
                             have_reset_sample <= 1'b1;
                             reset_event[1:0] <= 2'b01; // data packet
                             reset_event[9:2] <= chip_id;
                             reset_event[15:10] <= channel_id;
                             reset_event[43:16] <= timestamp_latched[27:0];
                             reset_event[45:44] <= 2'b11; // CDS reset  
                             reset_event[55:46] <= adc_word;
                             reset_event[57:56] <= trigger_type_latched;
                             reset_event[59:58] <= {fifo_full,fifo_half};
                             reset_event[61:60] <= {local_fifo_full,local_fifo_half};
                             reset_event[62] <= 1'b1; // flag downstream
                            if (enable_local_fifo_diagnostics) begin
                                reset_event[43:40] <= local_fifo_counter;
                            end
                            sample <= 1'b1; // begin tracking again
                            end  

            REQUEST_READOUT:begin
                             readout_mode       <= 1'b1;
                             pre_event[1:0]     <= 2'b01; // data packet
                             pre_event[9:2]     <= chip_id;
                             pre_event[15:10]   <= channel_id;
                             pre_event[43:16]   <= timestamp_latched[27:0];
                             pre_event[44]      <= 1'b0;
                             pre_event[45]      <= cds_mode;
                             pre_event[55:46]   <= adc_word;
                             pre_event[57:56]   <= trigger_type_latched;
                             pre_event[59:58]   <= {fifo_full,fifo_half};
                             pre_event[61:60]   <= {local_fifo_full,local_fifo_half};
                             pre_event[62]      <= 1'b1; // flag downstream
                                                        
                            if (enable_local_fifo_diagnostics) begin
                                pre_event[43:40] <= local_fifo_counter;
                            end
                            if (threshold_polarity)
                                delta_adc <= adc_word - previous_adc_word;
                            else
                                delta_adc <= previous_adc_word - adc_word;
                            previous_adc_word <= adc_word;
                            sample <= 1'b1; // begin tracking again
                            end  
            TRANSFER_RESET_SAMPLE: begin
                            readout_mode <= 1'b1;
                            write_local_fifo_n <= 1'b0;
                            sample <= 1'b1;
                            end
            WAIT_STATE: begin
                            have_reset_sample <= 1'b0;  
                            wait_counter <= wait_counter + 1'b1;
                            sample <= 1'b1;      
                        end                    
            TRANSFER_ADC_CODE:   begin
                            readout_mode <= 1'b1;
                            adc_burst_counter <= adc_burst_counter + 1'b1;
                            if (adc_word >= digital_threshold)
                                write_local_fifo_n <= 1'b0;
                            sample <= 1'b1;
                            if ( (enable_dynamic_reset & threshold_polarity)
                                && (adc_word >= dynamic_reset_threshold) )
                                last_call <= 1'b1;
                            else if ( (enable_dynamic_reset & !threshold_polarity) 
                                && (adc_word <= dynamic_reset_threshold) )
                                last_call <= 1'b1;
                            else if ( (enable_min_delta_adc)
                            && (delta_adc[9:0] < min_delta_adc) )
                                last_call <= 1'b1;
                            if (final_conversion) last_call <= 1'b0;
                        end
            MODE_RESET:  begin
                            readout_mode <= 1'b1;
                            csa_reset_triggered <= 1'b1;
                            sample <= 1'b1;
                        end
            default:    ;
        endcase
    end
end // always_ff

// local derandomizing FIFO
//TP: Move to latch based FIFO to save area
fifo_latch
    #(.FIFO_WIDTH(WIDTH-1),
    .FIFO_DEPTH(LOCAL_FIFO_DEPTH),
    .FIFO_BITS(LOCAL_FIFO_BITS)
    ) fifo_inst (
    .data_out       (channel_event),
    .fifo_counter   (local_fifo_counter),
    .fifo_full      (local_fifo_full),
    .fifo_half      (local_fifo_half),
    .fifo_empty     (fifo_empty),
    .data_in        (fifo_event),
    .read_n         (read_local_fifo_n),
    .write_n        (write_local_fifo_n),
    .clk            (clk),
    .reset_n        (reset_n)
    );

endmodule

