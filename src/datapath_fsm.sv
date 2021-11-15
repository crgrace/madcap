///////////////////////////////////////////////////////////////////
// File Name: datapath_fsm.sv
// Engineer:  Carl Grace (crgrace@lbl.gov)
//
// Description: Controller for datapath from PISO inputs to LVDS TX output
//     
//     
///////////////////////////////////////////////////////////////////

module datapath_fsm
    (output logic packet_rcvd,          // high to acknowledge packet rcvd 
    output logic get_fifo_data_n,       // active low 
    output logic load_serializer,       // high to load serializer
    output logic build_data,            // high to initiate data packet
    output logic build_k,               // high to initiate k (idle) packet
    input logic rx_fifo_empty,          // high if FIFO empty
    input logic clk,                    // MADCAP Primary clk
    input logic reset_n);               // digital reset (active low)

    
// inernal registers

logic [5:0] datapath_cnt;   // Counts number of bits between loads
                            // There are 60 clocks between loads
                            // DDR (superpacket is 120b after 8b10b)
// datapath counter
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        datapath_cnt <= '0;
        load_serializer <= 1'b0;
    end
    else begin
        datapath_cnt <= datapath_cnt + 1'b1;
        load_serializer <= 1'b0;
        if (datapath_cnt == 6'b111011) begin  // count to 59
            load_serializer <= 1'b1;
            datapath_cnt <= '0;
        end
    end
end // always_ff


// state machine
enum logic [2:0] // explicit state definitions 
            {IDLE = 3'h0,
            RST_PACKET_BUILDER = 3'h1,
            CHECK_FIFO = 3'h2,
            TRANSFER_FROM_FIFO = 3'h3,
            BUILD_K = 3'h4,
            BUILD_DATA = 3'h5} State, Next;


always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        State <= IDLE;
    else
        State <= Next;
end // always_ff

always_comb begin
    Next = IDLE;
    case (State)
        IDLE: if (datapath_cnt == 6'b000010)   Next = RST_PACKET_BUILDER; 
                else                Next = IDLE;
        RST_PACKET_BUILDER: if (datapath_cnt==6'b001000) Next = CHECK_FIFO;
                else               Next = RST_PACKET_BUILDER;
        CHECK_FIFO: if (!rx_fifo_empty)   Next = TRANSFER_FROM_FIFO;
                else                Next = BUILD_K;
        TRANSFER_FROM_FIFO:         Next = BUILD_DATA;
        BUILD_K:                    Next = IDLE;
        BUILD_DATA:                 Next = IDLE;
    endcase
end // always

// registered outputs
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        get_fifo_data_n <= 1'b1;
        packet_rcvd <= 1'b0;
        build_data <= 1'b0;  
        build_k <= 1'b0;  
    end
    else begin
        get_fifo_data_n <= 1'b1;
        packet_rcvd <= 1'b0;
        build_data <= 1'b0;  
        build_k <= 1'b0; 
        case (Next)
        IDLE: ;
        RST_PACKET_BUILDER: begin
                                packet_rcvd <= 1'b1;
                            end
        CHECK_FIFO:         ;
        TRANSFER_FROM_FIFO: begin
                                get_fifo_data_n <= 1'b0;
                            end
        BUILD_K:            begin
                                build_k <= 1'b1;
                            end    
        BUILD_DATA:         begin
                                build_data <= 1'b1;
                            end 
        default:            ;
        endcase
    end
end // always_ff

endmodule                               





