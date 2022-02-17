///////////////////////////////////////////////////////////////////
// File Name: reset_ctrl.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Generate reset pulses for internal and external use
//      Each LArPix clk cycle = 8 MADCAP clock cycles
//
//      lp_soft_reset: low for 8*3 clock cycles 
//////////////////////////////////////////////////////////////////

module reset_ctrl
    (output logic lp_rst_out,           // reset signal for LArPix
    output logic mc_rst_out,            // reset signal for MADCAP
    output logic lp_trigger_out,        // trigger signal for LArPix
    input logic lp_trigger_found,          // high when K28.0 found
    input logic lp_soft_rst_found,      // high if K28.4 (K_Q) found
    input logic lp_hard_rst_found,      // high if K27.7 (K_S) found
    input logic lp_timestamp_rst_found, // high if K28.3 (K_A) found
    input logic mc_rst_found,           // high if K28.7 (K_T) found
    input logic clk,                    // primary clock
    input logic reset_n                 // asynchronous reset (active low)
    );

logic [8:0] cnt; // 9-bit internal counter
logic cnt_en;   // enable bit
// define states 

enum logic [2:0] // explicit state definitions
            {READY          = 3'h0,
            LP_TIMESTAMP    = 3'h1,
            LP_SOFT_RST     = 3'h2,
            LP_HARD_RST     = 3'h3,
            LP_TRIGGER      = 3'h4,
            MC_RST          = 3'h5} State, Next;
            
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        State <= READY;
    else
        State <= Next;
end // always_ff

always_comb begin
    Next = READY;
    case (State)
        READY:  if      (lp_timestamp_rst_found)    Next = LP_TIMESTAMP;
                else if (lp_soft_rst_found)         Next = LP_SOFT_RST; 
                else if (lp_hard_rst_found)         Next = LP_HARD_RST; 
                else if (lp_trigger_found)          Next = LP_TRIGGER;    
                else if (mc_rst_found)              Next = MC_RST;
                else                                Next = READY;
        LP_TIMESTAMP: if (cnt == 9'd36)             Next = READY;
                        else                        Next = LP_TIMESTAMP;
        LP_SOFT_RST:  if (cnt == 9'd192)            Next = READY;
                        else                        Next = LP_SOFT_RST;
        LP_HARD_RST:  if (cnt == 9'd384)            Next = READY;
                        else                        Next = LP_HARD_RST;
        LP_TRIGGER:   if (cnt == 9'd24)             Next = READY;
                        else                        Next = LP_TRIGGER;
        MC_RST:       if (cnt == 9'd384)            Next = READY;
                        else                        Next = MC_RST;
        default:                                    Next = READY;
    endcase
end // always_comb

// registered outputs
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        lp_rst_out <= 1'b1;
        mc_rst_out <= 1'b1;
        lp_trigger_out <= 1'b0;
        cnt <= '0;
        cnt_en <= 1'b0;
    end
    else begin
        lp_rst_out <= 1'b1;
        mc_rst_out <= 1'b1;
        lp_trigger_out <= 1'b0;  
        case (Next)      
        READY:      ;
        LP_TIMESTAMP: begin 
                            lp_rst_out <= 1'b0;
                            cnt_en <= 1'b1;
                      end                       
        LP_SOFT_RST: begin 
                            lp_rst_out <= 1'b0;
                            cnt_en <= 1'b1;
                      end    
        LP_HARD_RST: begin 
                            lp_rst_out <= 1'b0;
                            cnt_en <= 1'b1;
                      end   
        LP_TRIGGER: begin 
                            lp_trigger_out <= 1'b1;
                            cnt_en <= 1'b1;
                    end
        MC_RST:     begin 
                            mc_rst_out <= 1'b0;
                            cnt_en <= 1'b1;
                    end   
        default:        ;    
        endcase
    end // if
end // always_ff
          
always_ff @(posedge clk or negedge reset_n) begin
    if (cnt_en)
        cnt <= cnt + 1'b1;
    else
        cnt <= '0;
end // always_ff

endmodule

