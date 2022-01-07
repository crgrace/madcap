// File Name: config_regfile_assign_mc.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description:  Code snippet used in config_regfile_mc.sv for assignment
//          
//  Register names defined in madcap_constants.sv
//
///////////////////////////////////////////////////////////////////

        config_bits[REFGEN]                 <= 8'h10;
        config_bits[IMONITOR]               <= 8'h00;
        config_bits[VMONITOR]               <= 8'h00;
        config_bits[DMONITOR]               <= 8'h00;
        config_bits[CHIP_ID]                <= 8'h01;
        config_bits[TEST_MODE]              <= 8'h30;
        for (int i = 0; i < 12; i++) begin
            config_bits[TEST_PACKETS + i]   <= 8'h00;
        end
        config_bits[SERIALIZER] <= 8'h01;
        for (int i = 0; i < 2; i++) begin
            config_bits[TX_ENABLE + i]      <= 8'hFF;
        end
        config_bits[TRX0]                   <= 8'hC8;
        config_bits[TRX1]                   <= 8'h08;
        config_bits[TRX2]                   <= 8'h02;
        config_bits[TRX3]                   <= 8'h05;
        config_bits[TRX4]                   <= 8'h8C;
        config_bits[TRX5]                   <= 8'h88;
        config_bits[TRX6]                   <= 8'h08;
        config_bits[PD_LVDS]                <= 8'h00;
        config_bits[PD_DRIVER]              <= 8'h00;
        config_bits[PD_TRIGGER]             <= 8'h00;
        for (int i = 0; i < 2; i++) begin
            config_bits[PD_RX + i]          <= 8'h00;
        end
        for (int i = 0; i < 2; i++) begin
            config_bits[PD_TX + i]          <= 8'h00;
        end
