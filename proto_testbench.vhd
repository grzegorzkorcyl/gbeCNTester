LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

use work.trb_net_gbe_components.all;

use std.textio.all;
use work.txt_util.all;

entity proto_testbench is
end entity proto_testbench;

architecture RTL of proto_testbench is

signal pc_wr_en					: std_logic;
signal pc_data					: std_logic_vector(7 downto 0);
signal pc_eod					: std_logic;
signal pc_sos					: std_logic;
signal pc_ready					: std_logic;
signal pc_padding				: std_logic;
signal pc_decoding				: std_logic_vector(31 downto 0);
signal pc_event_id				: std_logic_vector(31 downto 0);
signal pc_queue_dec				: std_logic_vector(31 downto 0);
signal pc_max_frame_size        : std_logic_vector(15 downto 0);
signal pc_bsm_constr			: std_logic_vector(3 downto 0);
signal pc_bsm_load				: std_logic_vector(3 downto 0);
signal pc_bsm_save				: std_logic_vector(3 downto 0);
signal pc_shf_empty				: std_logic;
signal pc_shf_full				: std_logic;
signal pc_shf_wr_en				: std_logic;
signal pc_shf_rd_en				: std_logic;
signal pc_shf_q					: std_logic_vector(7 downto 0);
signal pc_df_empty				: std_logic;
signal pc_df_full				: std_logic;
signal pc_df_wr_en				: std_logic;
signal pc_df_rd_en				: std_logic;
signal pc_df_q					: std_logic_vector(7 downto 0);
signal pc_all_ctr				: std_logic_vector(4 downto 0);
signal pc_sub_ctr				: std_logic_vector(4 downto 0);
signal pc_bytes_loaded			: std_logic_vector(15 downto 0);
signal pc_size_left				: std_logic_vector(31 downto 0);
signal pc_sub_size_to_save		: std_logic_vector(31 downto 0);
signal pc_sub_size_loaded		: std_logic_vector(31 downto 0);
signal pc_sub_bytes_loaded		: std_logic_vector(31 downto 0);
signal pc_queue_size			: std_logic_vector(31 downto 0);
signal pc_act_queue_size		: std_logic_vector(31 downto 0);

signal fee_read					: std_logic;
signal cts_readout_finished		: std_logic;
signal cts_dataready			: std_logic;
signal cts_length				: std_logic_vector(15 downto 0);
signal cts_data					: std_logic_vector(31 downto 0); -- DHDR of rest packet
signal cts_error_pattern		: std_logic_vector(31 downto 0);

signal pc_sub_size				: std_logic_vector(31 downto 0);
signal pc_trig_nr				: std_logic_vector(31 downto 0);

signal tc_wr_en					: std_logic;
signal tc_data					: std_logic_vector(7 downto 0);
signal tc_ip_size				: std_logic_vector(15 downto 0);
signal tc_udp_size				: std_logic_vector(15 downto 0);
signal tc_ident					: std_logic_vector(15 downto 0);
signal tc_flags_offset				: std_logic_vector(15 downto 0);
signal tc_sod					: std_logic;
signal tc_eod					: std_logic;
signal tc_h_ready				: std_logic;
signal tc_ready					: std_logic;
signal fc_dest_mac				: std_logic_vector(47 downto 0);
signal fc_dest_ip				: std_logic_vector(31 downto 0);
signal fc_dest_udp				: std_logic_vector(15 downto 0);
signal fc_src_mac				: std_logic_vector(47 downto 0);
signal fc_src_ip				: std_logic_vector(31 downto 0);
signal fc_src_udp				: std_logic_vector(15 downto 0);
signal fc_type					: std_logic_vector(15 downto 0);
signal fc_ihl_version			: std_logic_vector(7 downto 0);
signal fc_tos					: std_logic_vector(7 downto 0);
signal fc_ttl					: std_logic_vector(7 downto 0);
signal fc_protocol				: std_logic_vector(7 downto 0);
signal fc_bsm_constr			: std_logic_vector(7 downto 0);
signal fc_bsm_trans				: std_logic_vector(3 downto 0);

signal ft_data					: std_logic_vector(8 downto 0);-- gk 04.05.10
signal ft_tx_empty				: std_logic;
signal ft_start_of_packet		: std_logic;
signal ft_bsm_init				: std_logic_vector(3 downto 0);
signal ft_bsm_mac				: std_logic_vector(3 downto 0);
signal ft_bsm_trans				: std_logic_vector(3 downto 0);

signal mac_haddr				: std_logic_vector(7 downto 0);
signal mac_hdataout				: std_logic_vector(7 downto 0);
signal mac_hcs					: std_logic;
signal mac_hwrite				: std_logic;
signal mac_hread				: std_logic;
signal mac_fifoavail			: std_logic;
signal mac_fifoempty			: std_logic;
signal mac_fifoeof				: std_logic;
signal mac_hready				: std_logic;
signal mac_hdata_en				: std_logic;
signal mac_tx_done				: std_logic;
signal mac_tx_read				: std_logic;

signal serdes_clk_125			: std_logic;
signal mac_tx_clk_en			: std_logic;
signal mac_rx_clk_en			: std_logic;
signal mac_col					: std_logic;
signal mac_crs					: std_logic;
signal pcs_txd					: std_logic_vector(7 downto 0);
signal pcs_tx_en				: std_logic;
signal pcs_tx_er				: std_logic;
signal pcs_an_lp_ability		: std_logic_vector(15 downto 0);
signal pcs_an_complete			: std_logic;
signal pcs_an_page_rx			: std_logic;

signal pcs_stat_debug			: std_logic_vector(63 downto 0); 

signal stage_stat_regs			: std_logic_vector(31 downto 0);
signal stage_ctrl_regs			: std_logic_vector(31 downto 0);

signal analyzer_debug			: std_logic_vector(63 downto 0);

signal ip_cfg_start			: std_logic;
signal ip_cfg_bank			: std_logic_vector(3 downto 0);
signal ip_cfg_done			: std_logic;

signal ip_cfg_mem_addr			: std_logic_vector(7 downto 0);
signal ip_cfg_mem_data			: std_logic_vector(31 downto 0);
signal ip_cfg_mem_clk			: std_logic;

-- gk 22.04.10
signal max_packet                    : std_logic_vector(31 downto 0);
signal min_packet                    : std_logic_vector(31 downto 0);
signal use_gbe                       : std_logic;
signal use_trbnet                    : std_logic;
signal use_multievents               : std_logic;
-- gk 26.04.10
signal readout_ctr                   : std_logic_vector(23 downto 0);
signal readout_ctr_valid             : std_logic;
signal gbe_trig_nr                   : std_logic_vector(31 downto 0);
-- gk 28.04.10
signal pc_delay                      : std_logic_vector(31 downto 0);
-- gk 04.05.10
signal ft_eod                        : std_logic;
-- gk 08.06.10
signal mac_tx_staten                 : std_logic;
signal mac_tx_statevec               : std_logic_vector(30 downto 0);
signal mac_tx_discfrm                : std_logic;

-- gk 21.07.10
signal allow_large                   : std_logic;

-- gk 28.07.10
signal bytes_sent_ctr                : std_logic_vector(31 downto 0);
signal monitor_sent                  : std_logic_vector(31 downto 0);
signal monitor_dropped               : std_logic_vector(31 downto 0);
signal monitor_sm                    : std_logic_vector(31 downto 0);
signal monitor_lr                    : std_logic_vector(31 downto 0);
signal monitor_hr                    : std_logic_vector(31 downto 0);
signal monitor_fifos                 : std_logic_vector(31 downto 0);
signal monitor_fifos_q               : std_logic_vector(31 downto 0);
signal monitor_discfrm               : std_logic_vector(31 downto 0);

-- gk 02.08.10
signal discfrm_ctr                   : std_logic_vector(31 downto 0);

-- gk 30.09.10
signal fc_rd_en                      : std_logic;
signal link_ok                       : std_logic;
signal link_ok_timeout_ctr           : std_logic_vector(15 downto 0);

type linkStates     is  (ACTIVE, INACTIVE, TIMEOUT, FINALIZE);
signal link_current_state, link_next_state : linkStates;

signal link_down_ctr                 : std_logic_vector(15 downto 0);
signal link_down_ctr_lock            : std_logic;

signal link_state                    : std_logic_vector(3 downto 0);

signal monitor_empty                 : std_logic_vector(31 downto 0);

-- gk 07.10.10
signal pc_eos                        : std_logic;

-- gk 09.12.10
signal frame_delay                   : std_logic_vector(31 downto 0);

-- gk 13.02.11
signal pcs_rxd                       : std_logic_vector(7 downto 0);
signal pcs_rx_en                     : std_logic;
signal pcs_rx_er                     : std_logic;
signal mac_rx_eof                    : std_logic;
signal mac_rx_er                     : std_logic;
signal mac_rxd                       : std_logic_vector(7 downto 0);
signal mac_rx_fifo_err               : std_logic;
signal mac_rx_fifo_full              : std_logic;
signal mac_rx_en                     : std_logic;
signal mac_rx_stat_en                : std_logic;
signal mac_rx_stat_vec               : std_logic_vector(31 downto 0);
signal fr_q                          : std_logic_vector(8 downto 0);
signal fr_rd_en                      : std_logic;
signal fr_frame_valid                : std_logic;
signal rc_rd_en                      : std_logic;
signal rc_q                          : std_logic_vector(8 downto 0);
signal rc_frames_rec_ctr             : std_logic_vector(31 downto 0);
signal tc_pc_ready                   : std_logic;
signal tc_pc_h_ready                 : std_logic;
signal mc_ctrl_frame_req             : std_logic;
signal mc_data                       : std_logic_vector(8 downto 0);
signal mc_rd_en                      : std_logic;
signal fc_wr_en                      : std_logic;
signal fc_data                       : std_logic_vector(7 downto 0);
signal fc_ip_size                    : std_logic_vector(15 downto 0);
signal fc_udp_size                   : std_logic_vector(15 downto 0);
signal fc_ident                      : std_logic_vector(15 downto 0);
signal fc_flags_offset               : std_logic_vector(15 downto 0);
signal fc_sod                        : std_logic;
signal fc_eod                        : std_logic;
signal fc_h_ready                    : std_logic;
signal fc_ready                      : std_logic;
signal rc_frame_ready                : std_logic;
signal allow_rx                      : std_logic;
signal fr_frame_size                 : std_logic_vector(15 downto 0);
signal rc_frame_size                 : std_logic_vector(15 downto 0);
signal mc_frame_size                 : std_logic_vector(15 downto 0);
signal ic_dest_mac			: std_logic_vector(47 downto 0);
signal ic_dest_ip			: std_logic_vector(31 downto 0);
signal ic_dest_udp			: std_logic_vector(15 downto 0);
signal ic_src_mac			: std_logic_vector(47 downto 0);
signal ic_src_ip			: std_logic_vector(31 downto 0);
signal ic_src_udp			: std_logic_vector(15 downto 0);
signal pc_transmit_on			: std_logic;
signal rc_bytes_rec                  : std_logic_vector(31 downto 0);
signal rc_debug                      : std_logic_vector(63 downto 0);
signal mc_busy                       : std_logic;
signal tsmac_gbit_en                 : std_logic;
signal mc_transmit_ctrl              : std_logic;
signal mc_transmit_data              : std_logic;
signal rc_loading_done               : std_logic;
signal fr_get_frame                  : std_logic;
signal mc_transmit_done              : std_logic;

signal dbg_fr                        : std_logic_vector(95 downto 0);
signal dbg_rc                        : std_logic_vector(63 downto 0);
signal dbg_mc                        : std_logic_vector(63 downto 0);
signal dbg_tc                        : std_logic_vector(63 downto 0);

signal fr_allowed_types              : std_logic_vector(31 downto 0);
signal fr_allowed_ip                 : std_logic_vector(31 downto 0);
signal fr_allowed_udp                : std_logic_vector(31 downto 0);

signal fr_frame_proto                : std_logic_vector(15 downto 0);
signal rc_frame_proto                : std_logic_vector(4 - 1 downto 0);

signal dbg_select_rec                : std_logic_vector(4 * 16 - 1 downto 0);
signal dbg_select_sent               : std_logic_vector(4 * 16 - 1 downto 0);
signal dbg_select_protos             : std_logic_vector(4 * 32 - 1 downto 0);
	
signal serdes_rx_clk                 : std_logic;

signal vlan_id                       : std_logic_vector(31 downto 0);
signal mc_type                       : std_logic_vector(15 downto 0);
signal fr_src_mac                : std_logic_vector(47 downto 0);
signal fr_dest_mac               : std_logic_vector(47 downto 0);
signal fr_src_ip                 : std_logic_vector(31 downto 0);
signal fr_dest_ip                : std_logic_vector(31 downto 0);
signal fr_src_udp                : std_logic_vector(15 downto 0);
signal fr_dest_udp               : std_logic_vector(15 downto 0);
signal rc_src_mac                : std_logic_vector(47 downto 0);
signal rc_dest_mac               : std_logic_vector(47 downto 0);
signal rc_src_ip                 : std_logic_vector(31 downto 0);
signal rc_dest_ip                : std_logic_vector(31 downto 0);
signal rc_src_udp                : std_logic_vector(15 downto 0);
signal rc_dest_udp               : std_logic_vector(15 downto 0);

signal mc_dest_mac			: std_logic_vector(47 downto 0);
signal mc_dest_ip			: std_logic_vector(31 downto 0);
signal mc_dest_udp			: std_logic_vector(15 downto 0);
signal mc_src_mac			: std_logic_vector(47 downto 0);
signal mc_src_ip			: std_logic_vector(31 downto 0);
signal mc_src_udp			: std_logic_vector(15 downto 0);

signal dbg_ft                        : std_logic_vector(63 downto 0);

signal fr_ip_proto                   : std_logic_vector(7 downto 0);
signal mc_ip_proto                   : std_logic_vector(7 downto 0);

attribute syn_preserve : boolean;
attribute syn_keep : boolean;
attribute syn_keep of pcs_rxd, pcs_txd, pcs_rx_en, pcs_tx_en, pcs_rx_er, pcs_tx_er : signal is true;
attribute syn_preserve of pcs_rxd, pcs_txd, pcs_rx_en, pcs_tx_en, pcs_rx_er, pcs_tx_er : signal is true;

signal pcs_txd_q, pcs_rxd_q : std_logic_vector(7 downto 0);
signal pcs_tx_en_q, pcs_tx_er_q, pcs_rx_en_q, pcs_rx_er_q, mac_col_q, mac_crs_q : std_logic;

signal pcs_txd_qq, pcs_rxd_qq : std_logic_vector(7 downto 0);
signal pcs_tx_en_qq, pcs_tx_er_qq, pcs_rx_en_qq, pcs_rx_er_qq, mac_col_qq, mac_crs_qq : std_logic;

signal fc_test_rd_en : std_logic;
signal MAC_RX_EOF_IN, MAC_RX_EN_IN, MAC_RX_ER_IN : std_logic;
signal MAC_RXD_IN : std_logic_vector(7 downto 0);
signal clk, clk_125, reset : std_logic;
signal FR_ALLOWED_TYPES_IN : std_logic_vector(31 downto 0);
	
begin

	CLK_PROC : process
	begin
		clk <= '1'; wait for 5 ns;
		clk <= '0'; wait for 5 ns;
	end process CLK_PROC;

	CLK_125_PROC : process
	begin
		clk_125 <= '1'; wait for 4 ns;
		clk_125 <= '0'; wait for 4 ns;
	end process CLK_125_PROC;
	
	serdes_rx_clk <= clk_125;

  FRAME_RECEIVER : trb_net16_gbe_frame_receiver
  port map(
	  CLK			=> clk,
	  RESET			=> RESET,
	  LINK_OK_IN		=> '1',
	  ALLOW_RX_IN		=> '1', --allow_rx,
	  RX_MAC_CLK		=> serdes_rx_clk,

  -- input signals from TS_MAC
	  MAC_RX_EOF_IN		=> MAC_RX_EOF_IN,
	  MAC_RX_ER_IN		=> MAC_RX_ER_IN,
	  MAC_RXD_IN		=> MAC_RXD_IN,
	  MAC_RX_EN_IN		=> MAC_RX_EN_IN,
	  MAC_RX_FIFO_ERR_IN	=> mac_rx_fifo_err,
	  MAC_RX_FIFO_FULL_OUT	=> mac_rx_fifo_full,
	  MAC_RX_STAT_EN_IN	    => mac_rx_stat_en,
	  MAC_RX_STAT_VEC_IN	=> mac_rx_stat_vec,
  -- output signal to control logic
	  FR_Q_OUT		        => fr_q,
	  FR_RD_EN_IN	     	=> fr_rd_en,
	  FR_FRAME_VALID_OUT	=> fr_frame_valid,
	  FR_GET_FRAME_IN	    => fr_get_frame,
	  FR_FRAME_SIZE_OUT  	=> fr_frame_size,
	  FR_FRAME_PROTO_OUT	=> fr_frame_proto,
	  FR_IP_PROTOCOL_OUT	=> fr_ip_proto,
	  FR_ALLOWED_TYPES_IN   => FR_ALLOWED_TYPES_IN,
	  FR_ALLOWED_IP_IN      => fr_allowed_ip,
	  FR_ALLOWED_UDP_IN     => fr_allowed_udp,
	  FR_VLAN_ID_IN		    => vlan_id,
	
	FR_SRC_MAC_ADDRESS_OUT	=> fr_src_mac,
	FR_DEST_MAC_ADDRESS_OUT => fr_dest_mac,
	FR_SRC_IP_ADDRESS_OUT	=> fr_src_ip,
	FR_DEST_IP_ADDRESS_OUT	=> fr_dest_ip,
	FR_SRC_UDP_PORT_OUT	    => fr_src_udp,
	FR_DEST_UDP_PORT_OUT	=> fr_dest_udp,

	  DEBUG_OUT		=> open
  );
  
  RECEIVE_CONTROLLER : trb_net16_gbe_receive_control
port map(
	CLK		    	=> clk,
	RESET			=> RESET,

-- signals to/from frame_receiver
	RC_DATA_IN	    	=> fr_q,
	FR_RD_EN_OUT		=> fr_rd_en,
	FR_FRAME_VALID_IN	=> fr_frame_valid,
	FR_GET_FRAME_OUT	=> fr_get_frame,
	FR_FRAME_SIZE_IN	=> fr_frame_size,
	FR_FRAME_PROTO_IN	=> fr_frame_proto,
	FR_IP_PROTOCOL_IN	=> fr_ip_proto,
	
	FR_SRC_MAC_ADDRESS_IN	=> fr_src_mac,
	FR_DEST_MAC_ADDRESS_IN  => fr_dest_mac,
	FR_SRC_IP_ADDRESS_IN	=> fr_src_ip,
	FR_DEST_IP_ADDRESS_IN	=> fr_dest_ip,
	FR_SRC_UDP_PORT_IN	    => fr_src_udp,
	FR_DEST_UDP_PORT_IN  	=> fr_dest_udp,

-- signals to/from main controller
	RC_RD_EN_IN		        => rc_rd_en,
	RC_Q_OUT		        => rc_q,
	RC_FRAME_WAITING_OUT	=> rc_frame_ready,
	RC_LOADING_DONE_IN	    => rc_loading_done,
	RC_FRAME_SIZE_OUT	    => rc_frame_size,
	RC_FRAME_PROTO_OUT	    => rc_frame_proto,
	
	RC_SRC_MAC_ADDRESS_OUT	=> rc_src_mac,
	RC_DEST_MAC_ADDRESS_OUT => rc_dest_mac,
	RC_SRC_IP_ADDRESS_OUT	=> rc_src_ip,
	RC_DEST_IP_ADDRESS_OUT	=> rc_dest_ip,
	RC_SRC_UDP_PORT_OUT	    => rc_src_udp,
	RC_DEST_UDP_PORT_OUT	=> rc_dest_udp,

-- statistics
	FRAMES_RECEIVED_OUT	    => open,
	BYTES_RECEIVED_OUT      => open,


	DEBUG_OUT		=> open
);

MAIN_CONTROL : trb_net16_gbe_main_control
generic map( g_GENERATE_STAT => 1)
  port map(
	  CLK			=> clk,
	  CLK_125		=> clk_125,
	  RESET			=> RESET,

	  MC_LINK_OK_OUT	=> link_ok,
	  MC_RESET_LINK_IN	=> '0',

  -- signals to/from receive controller
	  RC_FRAME_WAITING_IN	=> rc_frame_ready,
	  RC_LOADING_DONE_OUT	=> rc_loading_done,
	  RC_DATA_IN		=> rc_q,
	  RC_RD_EN_OUT		=> rc_rd_en,
	  RC_FRAME_SIZE_IN	=> rc_frame_size,
	  RC_FRAME_PROTO_IN	=> rc_frame_proto,

	  RC_SRC_MAC_ADDRESS_IN	=> rc_src_mac,
	  RC_DEST_MAC_ADDRESS_IN  => rc_dest_mac,
	  RC_SRC_IP_ADDRESS_IN	=> rc_src_ip,
	  RC_DEST_IP_ADDRESS_IN	=> rc_dest_ip,
	  RC_SRC_UDP_PORT_IN	=> rc_src_udp,
	  RC_DEST_UDP_PORT_IN	=> rc_dest_udp,

  -- signals to/from transmit controller
	  TC_TRANSMIT_CTRL_OUT	=> mc_transmit_ctrl,
	  TC_TRANSMIT_DATA_OUT  => mc_transmit_data,
	  TC_DATA_OUT		=> mc_data,
	  TC_RD_EN_IN		=> mc_rd_en,
	  TC_FRAME_SIZE_OUT	=> mc_frame_size,
	  TC_FRAME_TYPE_OUT	=> mc_type,
	  TC_IP_PROTOCOL_OUT	=> mc_ip_proto,
	  
	  TC_DEST_MAC_OUT	=> mc_dest_mac,
	  TC_DEST_IP_OUT	=> mc_dest_ip,
	  TC_DEST_UDP_OUT	=> mc_dest_udp,
	  TC_SRC_MAC_OUT	=> mc_src_mac,
	  TC_SRC_IP_OUT		=> mc_src_ip,
	  TC_SRC_UDP_OUT	=> mc_src_udp,
	  
	  TC_BUSY_IN		    => mc_busy,
	  TC_TRANSMIT_DONE_IN   => mc_transmit_done,

  -- signals to/from packet constructor
	  PC_READY_IN		=> '1',
	  PC_TRANSMIT_ON_IN	=> '0',
	  PC_SOD_IN		    => '0',

  -- signals to/from sgmii/gbe pcs_an_complete
	  PCS_AN_COMPLETE_IN	=> pcs_an_complete,

  -- signals to/from hub
	  MC_UNIQUE_ID_IN	       => (others => '0'),
	  
	  CNT_GENERATE_PACKET_IN   => '0',
	  CNT_TIMESTAMP_IN         => (others => '0'),
	  CNT_DEST_ADDR_IN         => (others => '0'),
	  CNT_SIZE_IN              => (others => '0'),
	  CNT_BUSY_OUT             => open,
	  
	CNT_MODULE_SELECT_OUT     => open,
	CNT_MODULE_RD_EN_OUT      => open,
	CNT_MODULE_DATA_IN        => (others => '0'),
	CNT_STOP_TRANSMISSION_OUT => open,
	CNT_START_STAT_IN         => '0',
		
	CNT_MODULE_DATA_OUT             => open,
	CNT_MODULE_RD_EN_IN             => '0',
	CNT_MODULE_SELECTED_IN          => '0',
	CNT_MODULE_FULL_OUT             => open,
	CNT_MODULE_ID_IN         => (others => '0'),
	
	  GSC_CLK_IN               => '0',
	  GSC_INIT_DATAREADY_OUT   => open,
	  GSC_INIT_DATA_OUT        => open,
	  GSC_INIT_PACKET_NUM_OUT  => open,
	  GSC_INIT_READ_IN         => '0',
	  GSC_REPLY_DATAREADY_IN   => '0',
	  GSC_REPLY_DATA_IN        => (others => '0'),
	  GSC_REPLY_PACKET_NUM_IN  => (others => '0'),
	  GSC_REPLY_READ_OUT       => open,
	  GSC_BUSY_IN              => '0',

  -- signal to/from Host interface of TriSpeed MAC
	  TSM_HADDR_OUT		=> mac_haddr,
	  TSM_HDATA_OUT		=> mac_hdataout,
	  TSM_HCS_N_OUT		=> mac_hcs,
	  TSM_HWRITE_N_OUT	=> mac_hwrite,
	  TSM_HREAD_N_OUT	=> mac_hread,
	  TSM_HREADY_N_IN	=> mac_hready,
	  TSM_HDATA_EN_N_IN	=> mac_hdata_en,
	  TSM_RX_STAT_VEC_IN  => mac_rx_stat_vec,
	  TSM_RX_STAT_EN_IN   => mac_rx_stat_en,
	  
	  SELECT_REC_FRAMES_OUT		=> open,
	  SELECT_SENT_FRAMES_OUT	=> open,
	  SELECT_PROTOS_DEBUG_OUT	=> open,

	  DEBUG_OUT		=> open
  );
  
  TRANSMIT_CONTROLLER : trb_net16_gbe_transmit_control
port map(
	CLK			    => clk,
	RESET			=> RESET,

-- signals to/from packet constructor
	PC_READY_IN		    => pc_ready,
	PC_DATA_IN		    => tc_data,
	PC_WR_EN_IN		    => tc_wr_en,
	PC_IP_SIZE_IN		=> tc_ip_size,
	PC_UDP_SIZE_IN		=> tc_udp_size,
	PC_FLAGS_OFFSET_IN	=> tc_flags_offset,
	PC_SOD_IN		    => tc_sod,
	PC_EOD_IN		    => tc_eod,
	PC_FC_READY_OUT		=> tc_pc_ready,
	PC_FC_H_READY_OUT	=> tc_pc_h_ready,
	PC_TRANSMIT_ON_IN	=> '0',

      -- signals from ip_configurator used by packet constructor
	IC_DEST_MAC_ADDRESS_IN  => ic_dest_mac,
	IC_DEST_IP_ADDRESS_IN   => ic_dest_ip,
	IC_DEST_UDP_PORT_IN     => ic_dest_udp,
	IC_SRC_MAC_ADDRESS_IN   => ic_src_mac,
	IC_SRC_IP_ADDRESS_IN    => ic_src_ip,
	IC_SRC_UDP_PORT_IN      => ic_src_udp,

-- signal to/from main controller
	MC_TRANSMIT_CTRL_IN	=> mc_transmit_ctrl,
	MC_TRANSMIT_DATA_IN	=> mc_transmit_data,
	MC_DATA_IN		    => mc_data,
	MC_RD_EN_OUT		=> mc_rd_en,
	MC_FRAME_SIZE_IN	=> mc_frame_size,
	MC_FRAME_TYPE_IN	=> mc_type,
	MC_IP_PROTOCOL_IN	=> mc_ip_proto,
	
	MC_DEST_MAC_IN		=> mc_dest_mac,
	MC_DEST_IP_IN		=> mc_dest_ip,
	MC_DEST_UDP_IN		=> mc_dest_udp,
	MC_SRC_MAC_IN		=> mc_src_mac,  --to identify the module
	MC_SRC_IP_IN		=> mc_src_ip,
	MC_SRC_UDP_IN		=> mc_src_udp,
		
	MC_BUSY_OUT		        => mc_busy,
	MC_TRANSMIT_DONE_OUT    => mc_transmit_done,

-- signal to/from frame constructor
	FC_DATA_OUT		    => fc_data,
	FC_WR_EN_OUT		=> fc_wr_en,
	FC_READY_IN		    => fc_ready,
	FC_H_READY_IN		=> fc_h_ready,
	FC_FRAME_TYPE_OUT	=> fc_type,
	FC_IP_SIZE_OUT		=> fc_ip_size,
	FC_UDP_SIZE_OUT		=> fc_udp_size,
	FC_IDENT_OUT		=> fc_ident,
	FC_FLAGS_OFFSET_OUT	=> fc_flags_offset,
	FC_SOD_OUT		    => fc_sod,
	FC_EOD_OUT		    => fc_eod,
	FC_IP_PROTOCOL_OUT	=> fc_protocol,

	DEST_MAC_ADDRESS_OUT    => fc_dest_mac,
	DEST_IP_ADDRESS_OUT     => fc_dest_ip,
	DEST_UDP_PORT_OUT       => fc_dest_udp,
	SRC_MAC_ADDRESS_OUT     => fc_src_mac,
	SRC_IP_ADDRESS_OUT      => fc_src_ip,
	SRC_UDP_PORT_OUT        => fc_src_udp,


-- debug
	DEBUG_OUT		=> open
);

-- Third stage: Frame Constructor
FRAME_CONSTRUCTOR: trb_net16_gbe_frame_constr
port map( 
	-- ports for user logic
	RESET				    => RESET,
	CLK				        => clk,
	LINK_OK_IN			    => link_ok, --pcs_an_complete,  -- gk 03.08.10  -- gk 30.09.10
	--
	WR_EN_IN			    => fc_wr_en,
	DATA_IN				    => fc_data,
	START_OF_DATA_IN		=> fc_sod,
	END_OF_DATA_IN			=> fc_eod,
	IP_F_SIZE_IN			=> fc_ip_size,
	UDP_P_SIZE_IN			=> fc_udp_size,
	HEADERS_READY_OUT		=> fc_h_ready,
	READY_OUT			    => fc_ready,
	DEST_MAC_ADDRESS_IN		=> fc_dest_mac,
	DEST_IP_ADDRESS_IN		=> fc_dest_ip,
	DEST_UDP_PORT_IN		=> fc_dest_udp,
	SRC_MAC_ADDRESS_IN		=> fc_src_mac,
	SRC_IP_ADDRESS_IN		=> fc_src_ip,
	SRC_UDP_PORT_IN			=> fc_src_udp,
	FRAME_TYPE_IN			=> fc_type,
	IHL_VERSION_IN			=> fc_ihl_version,
	TOS_IN				    => fc_tos,
	IDENTIFICATION_IN		=> fc_ident,
	FLAGS_OFFSET_IN			=> fc_flags_offset,
	TTL_IN				    => fc_ttl,
	PROTOCOL_IN			    => fc_protocol,
	FRAME_DELAY_IN			=> (others => '0'), -- gk 09.12.10
	-- ports for packetTransmitter
	RD_CLK				    => clk_125,
	FT_DATA_OUT 			=> ft_data,
	FT_TX_EMPTY_OUT			=> ft_tx_empty,
	FT_TX_RD_EN_IN			=> mac_tx_read,
	FT_START_OF_PACKET_OUT	=> ft_start_of_packet,
	FT_TX_DONE_IN			=> mac_tx_done,
	FT_TX_DISCFRM_IN		=> mac_tx_discfrm,
	-- debug ports
	BSM_CONSTR_OUT			=> open,
	BSM_TRANS_OUT			=> open,
	DEBUG_OUT              	=> open
);
  
  
  TESTBENCH_PROC : process
  begin
  
  wait for 50 ns;
	RESET <= '1';
	
	MAC_RX_EOF_IN		<= '0';
	MAC_RX_ER_IN		<= '0';
	MAC_RXD_IN		<= x"00";
	MAC_RX_EN_IN		<= '0';
	FR_ALLOWED_TYPES_IN     <= x"0000_000f";
	fr_allowed_ip           <= x"0000_000f";
	fr_allowed_udp          <= x"0000_000f";
	--additional_rand_pause   <= '0';
	pc_sos                  <= '0';
--	gsc_init_read           <= '0';
--	gsc_busy                <= '0';
--	gsc_reply_data          <= (others => '0');
--	gsc_reply_dataready     <= '0';
--	
	wait for 10 ns;
	RESET <= '0';
	wait for 50 ns;
	
	--for i in 0 to 1000 loop
	
	wait for 3000 ns;
--	
--			-- SECOND FRAME (ARP Request)	
--	wait until rising_edge(clk_125);
--	MAC_RX_EN_IN <= '1';
---- dest mac
--	MAC_RXD_IN		<= x"ff";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"ff";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"ff";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"ff";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"ff";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"ff";
--	wait until rising_edge(clk_125);
---- src mac
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"aa";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"bb";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"cc";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"dd";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"ee";
--	wait until rising_edge(clk_125);
---- arp frame type
--	MAC_RXD_IN		<= x"08";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"06";
--	wait until rising_edge(clk_125);
---- hardware type
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"01";
--	wait until rising_edge(clk_125);
---- protocol type
--	MAC_RXD_IN		<= x"08";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(clk_125);
---- hardware size
--	MAC_RXD_IN		<= x"06";
--	wait until rising_edge(clk_125);
---- protocol size
--	MAC_RXD_IN		<= x"04";
--	wait until rising_edge(clk_125);
---- opcode (request)
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"01";
--	wait until rising_edge(clk_125);
---- sender mac
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"aa";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"bb";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"cc";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"dd";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"ee";
--	wait until rising_edge(clk_125);
---- sender ip
--	MAC_RXD_IN		<= x"c0";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"a9";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"01";
--	wait until rising_edge(clk_125);
---- target mac
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(clk_125);
---- target ip
--	MAC_RXD_IN		<= x"c0";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"a8";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"00";
--	wait until rising_edge(clk_125);
--	MAC_RXD_IN		<= x"65";
--	wait until rising_edge(clk_125);
--	MAC_RX_EOF_IN <= '1';
--	
--	wait until rising_edge(clk_125);
--	MAC_RX_EN_IN <='0';
--	MAC_RX_EOF_IN <= '0';
--
--	wait;
  
  
  -- FIRST FRAME UDP - DHCP Offer
	wait until rising_edge(clk_125);
	MAC_RX_EN_IN <= '1';
-- dest mac
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"be";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ef";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"be";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ef";
	wait until rising_edge(clk_125);
-- src mac
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"aa";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"bb";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"dd";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ee";
	wait until rising_edge(clk_125);
-- frame type
	MAC_RXD_IN		<= x"08";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
-- ip headers
	MAC_RXD_IN		<= x"45";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"10";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"5a";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"49";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"11";  -- udp
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"02";
-- udp headers
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"c3";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"52";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"c3";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"52";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"2c";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"aa";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"bb";
-- dhcp data
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"03";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"04";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"de";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ad";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"fa";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ce";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"10";
	
	for i in 0 to 219 loop
		wait until rising_edge(clk_125);
		MAC_RXD_IN		<= x"00";
	end loop;
	
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"35";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
		MAC_RX_EOF_IN <= '1';
	
	wait until rising_edge(clk_125);
	MAC_RX_EN_IN <='0';
	MAC_RX_EOF_IN <= '0';
	
	wait for 1000 ns;
	
	wait;
	
	  -- FIRST FRAME UDP - DHCP Offer
	wait until rising_edge(clk_125);
	MAC_RX_EN_IN <= '1';
-- dest mac
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"be";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ef";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"be";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ef";
	wait until rising_edge(clk_125);
-- src mac
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"aa";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"bb";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"dd";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ee";
	wait until rising_edge(clk_125);
-- frame type
	MAC_RXD_IN		<= x"08";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
-- ip headers
	MAC_RXD_IN		<= x"45";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"10";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"5a";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"49";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"11";  -- udp
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"02";
-- udp headers
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"43";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"44";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"2c";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"aa";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"bb";
-- dhcp data
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"06";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"de";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ad";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"fa";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ce";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"10";
	
	for i in 0 to 219 loop
		wait until rising_edge(clk_125);
		MAC_RXD_IN		<= x"00";
	end loop;
	
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"35";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
		MAC_RX_EOF_IN <= '1';
	
	wait until rising_edge(clk_125);
	MAC_RX_EN_IN <='0';
	MAC_RX_EOF_IN <= '0';
	
	wait for 1000 ns;
  
  
  			-- FIRST FRAME 
	wait until rising_edge(clk_125);
	MAC_RX_EN_IN <= '1';
-- dest mac
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ff";
	wait until rising_edge(clk_125);
-- src mac
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"aa";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"bb";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"dd";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ee";
	wait until rising_edge(clk_125);
-- frame type
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"11";
	wait until rising_edge(clk_125);
-- data
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"02";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"03";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"04";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"10";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"20";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"30";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"40";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"aa";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"bb";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"cc";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"dd";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"ee";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"a9";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"01";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"c0";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"a8";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"00";
	wait until rising_edge(clk_125);
	MAC_RXD_IN		<= x"65";
	MAC_RX_EOF_IN <= '1';
	
	wait until rising_edge(clk_125);
	MAC_RX_EN_IN <='0';
	MAC_RX_EOF_IN <= '0';
	
	
	wait;
	
end process TESTBENCH_PROC;


end architecture RTL;
