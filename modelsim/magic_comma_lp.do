onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate :larpix_madcap_tb:reset_n
add wave -noupdate :larpix_madcap_tb:reset_n_larpix
add wave -noupdate :larpix_madcap_tb:reset_n_lp
add wave -noupdate :larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:config_bits
add wave -noupdate {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:CHANNELS[0]:channel_ctrl_inst:State}
add wave -noupdate {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:CHANNELS[0]:channel_ctrl_inst:reset_n}
add wave -noupdate :larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:external_interface_inst:config_regile_inst:reset_n
add wave -noupdate :larpix_madcap_tb:piso
add wave -noupdate :larpix_madcap_tb:posi
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:channel_event_out
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:read_rx
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:load_event_n
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:ack_fifo_data
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:mc_config_packet
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:write_fifo_data_req
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:rx_empty
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:clk
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:reset_n
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:channel_waiting
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:channel_blacklist
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:read_rx_fast
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:wait_counter
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:wait_counter_done
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:veto_event
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:State
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:event_router_mc_inst:Next
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:datapath_fsm_inst:packet_rcvd
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:datapath_fsm_inst:get_fifo_data_n
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:datapath_fsm_inst:load_serializer
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:datapath_fsm_inst:build_data
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:datapath_fsm_inst:build_k
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:datapath_fsm_inst:rx_fifo_empty
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:datapath_fsm_inst:clk
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:datapath_fsm_inst:reset_n
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:datapath_fsm_inst:datapath_cnt
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:datapath_fsm_inst:State
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:datapath_fsm_inst:Next
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:output_packet
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:k_in
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:enable_8b10b
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:rx_data
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:channel_id
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:chip_id
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:packet_rcvd
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:rx_fifo_cnt
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:config_fifo_cnt
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:which_fifo
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:enable_fifo_panic
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:config_fifo_half
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:config_fifo_full
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:build_data
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:build_k
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:test_mode
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:test_packet
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:crc_word
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:clk
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:reset_n
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:State
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:datapath_inst:data_packet_builder_inst:Next
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:superpacket
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:new_superpacket
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:which_fifo
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:k_out
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:bypass_8b10b_enc
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:simulation_done
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:reset_n
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:packet_number
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:rcvd_packet_declare
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:rcvd_which_fifo
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:rcvd_fifo_usage
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:rcvd_chip_id
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:rcvd_channel_id
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:rcvd_larpix_payload
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:rcvd_crc_word
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:total_data_packets
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:total_idle_packets
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:total_test_packets
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:total_bypass_packets
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:total_packets
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:total_errors
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:expected_crc_word
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:check_crc
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:crc_error
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:madcap_reg_addr
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:madcap_reg_data
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:larpix_reg_addr
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:larpix_reg_data
add wave -noupdate :larpix_madcap_tb:analyze_superpacket_inst:verbose
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:driver_ctrl_inst:trigger_larpix
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:driver_ctrl_inst:reset_n_larpix
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:driver_ctrl_inst:clk_larpix
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:driver_ctrl_inst:pd_trigger_drivers
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:driver_ctrl_inst:pd_reset_n_drivers
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:driver_ctrl_inst:pd_clk_drivers
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:driver_ctrl_inst:external_trigger
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:driver_ctrl_inst:reset_n_lp
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:driver_ctrl_inst:clk
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:driver_ctrl_inst:external_trigger_resampled
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:driver_ctrl_inst:reset_n_larpix_resampled
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:lp_hard_rst_found
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:lp_rst_out
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:lp_soft_rst_found
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:lp_timestamp_rst_found
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:lp_trigger_found
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:lp_trigger_out
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:mc_rst_found
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:mc_rst_out
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:symbol_start
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:symbol_locked
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:comma_found
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:lp_trigger_found
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:lp_soft_rst_found
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:lp_hard_rst_found
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:lp_timestamp_rst_found
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:mc_rst_found
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:dataword10b
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:dataword10b_ready
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:start_sync
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:sync_in
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:clk
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:reset_n
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:bit_cnt
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:symbol_start_loc
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:idle_found
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:sync_cnt
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:en_sync_cnt
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:State
add wave -noupdate :larpix_madcap_tb:madcap_inst:digital_core_mc_inst:config_path_inst:comma_detect_inst:Next
add wave -noupdate :larpix_madcap_tb:make_larpix_packet
add wave -noupdate :larpix_madcap_tb:make_lp_hard_reset_packet
add wave -noupdate :larpix_madcap_tb:make_lp_soft_reset_packet
add wave -noupdate :larpix_madcap_tb:make_lp_timestamp_packet
add wave -noupdate :larpix_madcap_tb:make_lp_trigger_packet
add wave -noupdate :larpix_madcap_tb:make_madcap_packet
add wave -noupdate :larpix_madcap_tb:make_mc_soft_reset_packet
add wave -noupdate :larpix_madcap_tb:which_byte
add wave -noupdate :larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:reset_n_sync
add wave -noupdate :larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:sync_timestamp
add wave -noupdate :larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:reset_n_config_sync
add wave -noupdate :larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:clk
add wave -noupdate :larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:reset_n
add wave -noupdate :larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_clk
add wave -noupdate :larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_timestamp
add wave -noupdate -radix unsigned -childformat {{{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[31]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[30]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[29]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[28]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[27]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[26]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[25]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[24]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[23]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[22]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[21]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[20]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[19]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[18]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[17]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[16]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[15]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[14]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[13]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[12]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[11]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[10]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[9]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[8]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[7]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[6]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[5]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[4]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[3]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[2]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[1]} -radix unsigned} {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[0]} -radix unsigned}} -expand -subitemconfig {{:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[31]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[30]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[29]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[28]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[27]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[26]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[25]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[24]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[23]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[22]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[21]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[20]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[19]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[18]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[17]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[16]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[15]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[14]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[13]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[12]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[11]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[10]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[9]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[8]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[7]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[6]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[5]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[4]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[3]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[2]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[1]} {-height 16 -radix unsigned} {:larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config[0]} {-height 16 -radix unsigned}} :larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:srg_config
add wave -noupdate :larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:all_0
add wave -noupdate :larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:all_0_timestamp
add wave -noupdate :larpix_madcap_tb:larpix_v2b_inst:digital_core_inst:reset_sync_inst:all_0_config
add wave -noupdate :larpix_madcap_tb:reset_n_larpix
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {575010000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 1126
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1050 us}
