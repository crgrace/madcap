///////////////////////////////////////////////////////////////////
// File Name: pacman_model.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description:
//          Simple analysis for PACMAN superpackets.
//          This is NOT an independent module. 
//          include this file in testbenche 
//           
///////////////////////////////////////////////////////////////////

// START PACMAN analysis
// analysis
analyze_superpacket
    analyze_superpacket_inst (
    .superpacket            (superpacket),
    .new_superpacket        (new_dataword),
    .which_fifo             (which_fifo),
    .k_out                  (k_out),
    .bypass_8b10b_enc       (bypass_8b10b_enc),
    .simulation_done        (simulation_done),
    .reset_n                (reset_n)
    );
// END PACMAN analysis

