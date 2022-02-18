///////////////////////////////////////////////////////////////////
// File Name: pacman_model.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
// Description:
//          Simple model for PACMAN controller.
//          This is NOT an independent module. 
//          include this file in testbenches  
//           
///////////////////////////////////////////////////////////////////

// PACMAN to MADCAP config path
logic load_serializer;
logic ready_to_load;
logic [15:0] tx_enable;
logic [3:0] serializer_cnt;
logic disp_out;             // 0 = neg disp; 1 = pos disp; not registered
logic disp_in;              // 0 = neg disp; 1 = pos disp
logic [47:0] upstream_packet; // from FPGA to MADCAP
logic dout_pacman;          // serializer output (single bit)
logic [7:0] data_in8b;      // input to send to 8b10b encoder
logic [7:0] current_byte;   // byte selected from upstream pacet
logic [9:0] data_in10b;     // input to test serializer 
logic next_packet;          // high when ready for new packet
logic [2:0] which_byte;     // byte of packet being serialized
logic k_in;                 // high to indicate 8b symbol represents k-code
logic external_sync;        // high for external sync
logic symbol_start;         // high to mark first bit in symbol
logic enable_8b10b;         // high to enable 8b10b encoder (for PACMAN)
logic bypass_8b10b_dec;     // high to bypass 8b10b decoders
logic bypass_8b10b_enc;     // high to bypass 8b10b encoders
logic external_trigger;     // high for external trigger
logic reset_n_lp;           // reset to send to LArPix

// packet building
logic [1:0] mc_packet_declaration;
logic [2:0] mc_chip_id;
logic [7:0] mc_regmap_address;
logic [7:0] mc_regmap_data;
logic [1:0] lp_packet_declaration;
logic [7:0] lp_chip_id;
logic [7:0] lp_regmap_address;
logic [7:0] lp_regmap_data;
logic [25:0] larpix_packet;
logic [3:0] target_larpix;
logic sending_commas;
logic make_madcap_packet;
logic make_larpix_packet;
logic [63:0] larpix_payload [NUMCHANNELS-1:0]; // data from LArPix ASICs


task larpixTransaction;
input [1:0] op;
input [7:0] chip_id;
input [7:0] addr;
input [7:0] data;
input [3:0] target;
logic debug;
begin
    debug = 0;
    if (debug) $display("in task: sending word to LArPix");
    mc_packet_declaration = 0;
    if (op == READ)
        lp_packet_declaration = 2'b11;
    else if (op == WRITE)
        lp_packet_declaration = 2'b10;
    else
        $display("larpixTransaction: ERROR IN OP DECLARATION");
    lp_chip_id = chip_id;
    lp_regmap_address = addr;
    lp_regmap_data = data;
    target_larpix = target;
    make_larpix_packet = 1;
    @upstream_packet;
    make_larpix_packet = 0;
    #2000 
    if (op == WRITE) begin
        $display("Send MADCAP packet (write to LArPix %d)",target);
    end
    else if (op == READ) begin
        $display("Send MADCAP packet (read from LArPix %d)",target);
    end
    else $display("ERROR in LP OP");
end
endtask

task madcapTransaction;
input [1:0] op;
input [2:0] chip_id;
input [7:0] addr;
input [7:0] data;
logic debug;
begin
    debug = 0;
    if (debug) $display("in task: sending word to MADCAP");
    mc_packet_declaration = 0;
    if (op == READ)
        mc_packet_declaration = 2'b11;
    else if (op == WRITE)
        mc_packet_declaration = 2'b10;
    else
        $display("madcapTransaction: ERROR IN OP DECLARATION");
    mc_chip_id = chip_id;
    mc_regmap_address = addr;
    mc_regmap_data = data;
    make_madcap_packet = 1;
    @upstream_packet;
    make_madcap_packet = 0;
    #2000 
    if (op == WRITE) begin
        $display("Send MADCAP packet (write to MADCAP)");
    end
    else if (op == READ) begin
        $display("Send MADCAP packet (write from MADCAP)");
    end
    else $display("ERROR in MC OP");
end
endtask



//// START CONFIG MODEL
/////////////// MODEL FOR DOWNSTREAM PACMAN CONTROLLER 
////////////// SENDS CONFIG INFORMATION TO MADCAP
always_comb
    if (serializer_cnt == 4'b0010)
        ready_to_load = 1'b1;
    else
        ready_to_load = 1'b0;

// load serializer counter
always_ff @(posedge clk_fast or negedge reset_n) begin
    if (!reset_n) begin
        serializer_cnt <= '0;
        load_serializer <= 1'b0;
    end
    else begin
        serializer_cnt <= serializer_cnt + 1'b1;
        load_serializer <= 1'b0;
        if (serializer_cnt == 4'b1001) begin // count to 9
            serializer_cnt <= '0;
            load_serializer <= 1'b1;
        end
    end
end // always_ff

always_comb begin
    case (which_byte)
        3'b000 : current_byte = upstream_packet[7:0];
        3'b001 : current_byte = upstream_packet[15:8];
        3'b010 : current_byte = upstream_packet[23:16];
        3'b011 : current_byte = upstream_packet[31:24];
        3'b100 : current_byte = upstream_packet[39:32];
        3'b101 : current_byte = upstream_packet[47:40];
        default: current_byte = '0;
    endcase
end // always_comb

always_comb begin
    if ( (sending_commas) || (which_byte == 3'b000) ) begin 
        k_in = 1'b1;
    end
    else begin
        k_in = 1'b0;
    end
end // always_comb

// create next packet
always_ff @(posedge clk_fast or negedge reset_n) begin
    if (!reset_n) begin
        next_packet <= 1'b0;
        which_byte <= 3'b000;
        upstream_packet <= '0;
        enable_8b10b <= 1'b0;
        sending_commas <= 1'b0;
    end
    else begin
        enable_8b10b <= 1'b0;
        if (serializer_cnt == 4'b0100) begin // update a few clocks early
               enable_8b10b <= 1'b1;
            if (which_byte == 3'b101) begin
                next_packet <= 1'b1;
                which_byte <= 3'b00;
                if (make_madcap_packet) begin
                    sending_commas <= 1'b0;
                    upstream_packet <= create_madcap_packet(
                                    mc_packet_declaration,
                                    mc_chip_id,
                                    mc_regmap_address,
                                    mc_regmap_data);
                end
                else if (make_larpix_packet) begin
                    sending_commas <= 1'b0;
                    upstream_packet <= create_larpix_packet(
                                    mc_packet_declaration,
                                    mc_chip_id,
                                    lp_packet_declaration,
                                    lp_chip_id,
                                    lp_regmap_address,
                                    lp_regmap_data,
                                    target_larpix);
                end
                else begin
                    upstream_packet <= create_comma_packet(); 
                    sending_commas <= 1'b1;
                end
            end
            else begin
                next_packet <= 1'b0;
                which_byte <= which_byte + 1'b1;
            end
        end
    end
end

// update input to 8b10b a few clock cycles before the serializer is ready
always_ff @(posedge clk_fast or negedge reset_n) begin
    if (!reset_n)
        data_in8b <= '0;
    else
        if (serializer_cnt == 4'b0111)
            data_in8b <= current_byte;
end // always_ff

// 8b10b encoder disparity flip-flop 
always_ff @(posedge clk_fast or negedge reset_n)
  if (!reset_n)
    disp_in <= 1'b0; // initialize disparity
  else
    if (enable_8b10b)
        disp_in <= disp_out;

// 8b10b encoder 
encode8b10b
    encode8b10_inst (
    .clk        (clk_fast),
    .reset_n    (reset_n),
    .data_in    (data_in8b),    
    .k_in       (k_in),
    .data_out   (data_in10b),
    .disp_in    (disp_in),
    .disp_out   (disp_out)
    );


// behavioral serializer
serializer_sdr
    #(.WIDTH(WIDTH))
    serializer_sdr_inst (
    .dout           (dout_pacman),
    .dout_symbol    (symbol_start),
    .din            (data_in10b),
    .enable         (1'b1),
    .load           (load_serializer),
    .external_sync  (external_sync),
    .clk            (clk_fast),
    .reset_n        (reset_n)
    );
///// END PACMAN CONFIG MODEL

// START PACMAN data rx 
// behavioral double datarate deserializer
deserializer_ddr
    #(.WIDTH(120))
    deserializer_ddr_inst (
    .dataword       (dataword_120b),
    .new_dataword   (new_dataword),
    .din            (dout),
    .frame_start    (dout_frame),
    .clk            (clk_fast),
    .reset_n        (reset_n)
    );

// decode deserialized data words
decode96b120b
    decode96b120b_inst (
    .datain                 (dataword_120b),
    .clk                    (clk_fast),
    .reset_n                (reset_n),
    .dataout                (dataword_96b),
    .k_out                  (k_out),
    .code_err               (code_err),
    .disp_err               (disp_err)
    );

// mux to bypass 8b10b decoder
always_comb begin
    if (bypass_8b10b_enc) 
        superpacket = dataword_120b[95:0];
    else
        superpacket = dataword_96b;
end // always_comb
// END PACMAN data rx


