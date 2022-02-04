///////////////////////////////////////////////////////////////////
// File Name: driver_ctrl.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description: Distributes clk, reset_n, and trigger signals to LArPix
//              1. sends clk_rx as primary clock
//              2. retimes reset_n and trigger to negedge of primary clock
//
///////////////////////////////////////////////////////////////////

module driver_ctrl
    (output logic [3:0] trigger_larpix, // triggers sent to LArPix tile
    output logic [3:0] reset_n_larpix,      // resets sent to LArPix tile
    output logic [3:0] clk_larpix,      // clk sent to LArPix tile
    input logic [3:0] pd_trigger_drivers,//pd trigger drivers to LArPix 
    input logic [3:0] pd_reset_n_drivers, //pd reset_n drivers to LArPix
    input logic [3:0] pd_clk_drivers,   // pd clk drivers to LArPix tile
    input logic trigger_found,          // high when K28.0 detected
    input logic embedded_trigger_en,    // high to issue trigger on K28.0
    input logic reset_n_lp,             // reset to send to LArPix
    input logic external_trigger,       // trigger from off_chip
    input logic clk);                    // primary clk

// internal signals
logic external_trigger_resampled;   // sample on negative edge of clk
logic reset_n_larpix_resampled;           // sample on negative edge of clk

// resample external trigger and larpix_reset by negative edge of clk
always_ff @(negedge clk) begin
    external_trigger_resampled <= external_trigger;
    reset_n_larpix_resampled <= reset_n_lp;
end // always_ff

// output muxes mux
always_comb begin
    for (int i = 0; i < 4; i++) begin
        trigger_larpix[i] = !pd_trigger_drivers[i]
            & external_trigger_resampled;
        reset_n_larpix[i] = pd_reset_n_drivers | reset_n_larpix_resampled;
        clk_larpix[i] = !pd_clk_drivers & clk;
        
        if (embedded_trigger_en) begin
            trigger_larpix[i] = !pd_trigger_drivers[i] & trigger_found; 
        end
        else begin
            trigger_larpix[i] = 1'b0;
        end
    end // for loop

end // always_comb

endmodule

