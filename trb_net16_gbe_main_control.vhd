LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

--********
-- controls the work of the whole gbe in both directions
-- multiplexes the output between data stream and output slow control packets based on priority
-- reacts to incoming gbe slow control commands
-- 


entity trb_net16_gbe_main_control is
port (
	CLK			: in	std_logic;  -- system clock
	CLK_125			: in	std_logic;
	RESET			: in	std_logic;

	MC_LINK_OK_OUT		: out	std_logic;
	MC_RESET_LINK_IN	: in	std_logic;

-- signals to/from receive controller
	RC_FRAME_WAITING_IN	: in	std_logic;
	RC_LOADING_DONE_OUT	: out	std_logic;
	RC_DATA_IN		: in	std_logic_vector(8 downto 0);
	RC_RD_EN_OUT		: out	std_logic;
	RC_FRAME_SIZE_IN	: in	std_logic_vector(15 downto 0);
	RC_FRAME_PROTO_IN	: in	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);

	RC_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	RC_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	RC_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	RC_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	RC_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	RC_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);

-- signals to/from transmit controller
	TC_TRANSMIT_CTRL_OUT	: out	std_logic;  -- slow control frame is waiting to be built and sent
	TC_TRANSMIT_DATA_OUT	: out	std_logic;
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
	TC_RD_EN_IN		: in	std_logic;
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	
	TC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);
	
	TC_BUSY_IN		: in	std_logic;
	TC_TRANSMIT_DONE_IN	: in	std_logic;

-- signals to/from packet constructor
	PC_READY_IN		: in	std_logic;
	PC_TRANSMIT_ON_IN	: in	std_logic;
	PC_SOD_IN		: in	std_logic;

-- signals to/from sgmii/gbe pcs_an_complete
	PCS_AN_COMPLETE_IN	: in	std_logic;

-- signals to/from hub
	MC_UNIQUE_ID_IN		: in	std_logic_vector(63 downto 0);
	
	GSC_CLK_IN               : in std_logic;
	GSC_INIT_DATAREADY_OUT   : out std_logic;
	GSC_INIT_DATA_OUT        : out std_logic_vector(15 downto 0);
	GSC_INIT_PACKET_NUM_OUT  : out std_logic_vector(2 downto 0);
	GSC_INIT_READ_IN         : in std_logic;
	GSC_REPLY_DATAREADY_IN   : in std_logic;
	GSC_REPLY_DATA_IN        : in std_logic_vector(15 downto 0);
	GSC_REPLY_PACKET_NUM_IN  : in std_logic_vector(2 downto 0);
	GSC_REPLY_READ_OUT       : out std_logic;
	GSC_BUSY_IN              : in std_logic;

-- signal to/from Host interface of TriSpeed MAC
	TSM_HADDR_OUT		: out	std_logic_vector(7 downto 0);
	TSM_HDATA_OUT		: out	std_logic_vector(7 downto 0);
	TSM_HCS_N_OUT		: out	std_logic;
	TSM_HWRITE_N_OUT	: out	std_logic;
	TSM_HREAD_N_OUT		: out	std_logic;
	TSM_HREADY_N_IN		: in	std_logic;
	TSM_HDATA_EN_N_IN	: in	std_logic;
	TSM_RX_STAT_VEC_IN  : in    std_logic_vector(31 downto 0);
	TSM_RX_STAT_EN_IN   : in	std_logic;

	SELECT_REC_FRAMES_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
	SELECT_SENT_FRAMES_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
	SELECT_PROTOS_DEBUG_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	
	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end trb_net16_gbe_main_control;


architecture trb_net16_gbe_main_control of trb_net16_gbe_main_control is

--attribute HGROUP : string;
--attribute HGROUP of trb_net16_gbe_main_control : architecture is "GBE_MAIN_group";

signal tsm_ready                            : std_logic;
signal tsm_reconf                           : std_logic;
signal tsm_haddr                            : std_logic_vector(7 downto 0);
signal tsm_hdata                            : std_logic_vector(7 downto 0);
signal tsm_hcs_n                            : std_logic;
signal tsm_hwrite_n                         : std_logic;
signal tsm_hread_n                          : std_logic;

type link_states is (ACTIVE, INACTIVE, ENABLE_MAC, TIMEOUT, FINALIZE, WAIT_FOR_BOOT, GET_ADDRESS);
signal link_current_state, link_next_state : link_states;

signal link_down_ctr                 : std_logic_vector(15 downto 0);
signal link_down_ctr_lock            : std_logic;
signal link_ok                       : std_logic;
signal link_ok_timeout_ctr           : std_logic_vector(15 downto 0);

signal mac_control_debug             : std_logic_vector(63 downto 0);

type flow_states is (IDLE, TRANSMIT_DATA, TRANSMIT_CTRL, CLEANUP);
signal flow_current_state, flow_next_state : flow_states;

signal state                        : std_logic_vector(3 downto 0);
signal link_state                   : std_logic_vector(3 downto 0);
signal redirect_state               : std_logic_vector(3 downto 0);

signal ps_wr_en                     : std_logic;
signal ps_response_ready            : std_logic;
signal ps_busy                      : std_logic_vector(c_MAX_PROTOCOLS -1 downto 0);
signal rc_rd_en                     : std_logic;
signal first_byte                   : std_logic;
signal first_byte_q                 : std_logic;
signal first_byte_qq                : std_logic;
signal proto_select                 : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal loaded_bytes_ctr             : std_Logic_vector(15 downto 0);

signal dhcp_start                   : std_logic;
signal dhcp_done                    : std_logic;
signal wait_ctr                     : std_logic_vector(31 downto 0);

signal rc_data_local                : std_logic_vector(8 downto 0);

-- debug
signal frame_waiting_ctr            : std_logic_vector(15 downto 0);
signal ps_busy_q                    : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal rc_frame_proto_q             : std_Logic_vector(c_MAX_PROTOCOLS - 1 downto 0);

type redirect_states is (IDLE, CHECK_TYPE, DROP, CHECK_BUSY, LOAD, BUSY, FINISH, CLEANUP);
signal redirect_current_state, redirect_next_state : redirect_states;

signal frame_type                   : std_logic_vector(15 downto 0);
signal disable_redirect, ps_wr_en_q : std_logic;

type stats_states is (IDLE, LOAD_VECTOR, CLEANUP);
signal stats_current_state, stats_next_state : stats_states;

signal stat_rdy, stat_ack           : std_logic;
signal rx_stat_en_q                 : std_logic;
signal rx_stat_vec_q                : std_logic_vector(31 downto 0);

type array_of_ctrs is array(15 downto 0) of std_logic_vector(31 downto 0);
signal arr : array_of_ctrs;
signal stats_ctr                    : integer range 0 to 15;
signal stat_data                    : std_logic_vector(31 downto 0);
signal stat_addr                    : std_logic_vector(7 downto 0);


begin

protocol_selector : trb_net16_gbe_protocol_selector
port map(
	CLK			=> CLK,
	RESET			=> RESET,
	
	PS_DATA_IN		=> rc_data_local, -- RC_DATA_IN,
	PS_WR_EN_IN		=> ps_wr_en_q, --ps_wr_en,
	PS_PROTO_SELECT_IN	=> proto_select,
	PS_BUSY_OUT		=> ps_busy,
	PS_FRAME_SIZE_IN	=> RC_FRAME_SIZE_IN,
	PS_RESPONSE_READY_OUT	=> ps_response_ready,

	PS_SRC_MAC_ADDRESS_IN	=> RC_SRC_MAC_ADDRESS_IN,
	PS_DEST_MAC_ADDRESS_IN  => RC_DEST_MAC_ADDRESS_IN,
	PS_SRC_IP_ADDRESS_IN	=> RC_SRC_IP_ADDRESS_IN,
	PS_DEST_IP_ADDRESS_IN	=> RC_DEST_IP_ADDRESS_IN,
	PS_SRC_UDP_PORT_IN	=> RC_SRC_UDP_PORT_IN,
	PS_DEST_UDP_PORT_IN	=> RC_DEST_UDP_PORT_IN,
	
	TC_DATA_OUT		=> TC_DATA_OUT,
	TC_RD_EN_IN		=> TC_RD_EN_IN,
	TC_FRAME_SIZE_OUT	=> TC_FRAME_SIZE_OUT,
	TC_FRAME_TYPE_OUT	=> frame_type, --TC_FRAME_TYPE_OUT,
	TC_IP_PROTOCOL_OUT	=> TC_IP_PROTOCOL_OUT,
	
	TC_DEST_MAC_OUT		=> TC_DEST_MAC_OUT,
	TC_DEST_IP_OUT		=> TC_DEST_IP_OUT,
	TC_DEST_UDP_OUT		=> TC_DEST_UDP_OUT,
	TC_SRC_MAC_OUT		=> TC_SRC_MAC_OUT,
	TC_SRC_IP_OUT		=> TC_SRC_IP_OUT,
	TC_SRC_UDP_OUT		=> TC_SRC_UDP_OUT,
	
	TC_BUSY_IN		=> TC_BUSY_IN,
	
	RECEIVED_FRAMES_OUT	=> SELECT_REC_FRAMES_OUT,
	SENT_FRAMES_OUT		=> SELECT_SENT_FRAMES_OUT,
	PROTOS_DEBUG_OUT	=> SELECT_PROTOS_DEBUG_OUT,
	
	DHCP_START_IN		=> dhcp_start,
	DHCP_DONE_OUT		=> dhcp_done,
	
	GSC_CLK_IN               => GSC_CLK_IN,
	GSC_INIT_DATAREADY_OUT   => GSC_INIT_DATAREADY_OUT,
	GSC_INIT_DATA_OUT        => GSC_INIT_DATA_OUT,
	GSC_INIT_PACKET_NUM_OUT  => GSC_INIT_PACKET_NUM_OUT,
	GSC_INIT_READ_IN         => GSC_INIT_READ_IN,
	GSC_REPLY_DATAREADY_IN   => GSC_REPLY_DATAREADY_IN,
	GSC_REPLY_DATA_IN        => GSC_REPLY_DATA_IN,
	GSC_REPLY_PACKET_NUM_IN  => GSC_REPLY_PACKET_NUM_IN,
	GSC_REPLY_READ_OUT       => GSC_REPLY_READ_OUT,
	GSC_BUSY_IN              => GSC_BUSY_IN,
	
	-- input for statistics from outside
	STAT_DATA_IN       => stat_data,
	STAT_ADDR_IN       => stat_addr,
	STAT_DATA_RDY_IN   => stat_rdy,
	STAT_DATA_ACK_OUT  => stat_ack,

	
	DEBUG_OUT		=> open
);

TC_FRAME_TYPE_OUT <= frame_type when flow_current_state = TRANSMIT_CTRL else x"0008";

-- gk 07.11.11
-- do not select any response constructors when dropping a frame
proto_select <= RC_FRAME_PROTO_IN when disable_redirect = '0' else (others => '0');

-- gk 07.11.11
DISABLE_REDIRECT_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			disable_redirect <= '0';
		elsif (redirect_current_state = CHECK_TYPE) then
			if (link_current_state /= ACTIVE and link_current_state /= GET_ADDRESS) then
				disable_redirect <= '1';
			elsif (link_current_state = GET_ADDRESS and RC_FRAME_PROTO_IN /= "10") then
				disable_redirect <= '1';
			else
				disable_redirect <= '0';
			end if;
		end if;
	end if;
end process DISABLE_REDIRECT_PROC;

-- warning
SYNC_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		rc_data_local <= RC_DATA_IN;
	end if;
end process SYNC_PROC;

REDIRECT_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			redirect_current_state <= IDLE;
		else
			redirect_current_state <= redirect_next_state;
		end if;
	end if;
end process REDIRECT_MACHINE_PROC;

REDIRECT_MACHINE : process(redirect_current_state, link_current_state, RC_FRAME_WAITING_IN, RC_DATA_IN, ps_busy, RC_FRAME_PROTO_IN, ps_wr_en, loaded_bytes_ctr, RC_FRAME_SIZE_IN)
begin
	case redirect_current_state is
	
		when IDLE =>
			redirect_state <= x"1";
			if (RC_FRAME_WAITING_IN = '1') then
				redirect_next_state <= CHECK_TYPE;
			else
				redirect_next_state <= IDLE;
			end if;
		-- gk 16.11.11
		when CHECK_TYPE =>
			if (link_current_state = ACTIVE) then
				redirect_next_state <= CHECK_BUSY;
			elsif (link_current_state = GET_ADDRESS and RC_FRAME_PROTO_IN = "10") then
				redirect_next_state <= CHECK_BUSY;
			else
				redirect_next_state <= DROP;
			end if;			
			
		-- gk 07.11.11
		when DROP =>
			redirect_state <= x"7";
			if (loaded_bytes_ctr = RC_FRAME_SIZE_IN - x"1") then
				redirect_next_state <= FINISH;
			else
				redirect_next_state <= DROP;
			end if;
		when CHECK_BUSY =>
			redirect_state <= x"6";
			if (or_all(ps_busy and RC_FRAME_PROTO_IN) = '0') then
				redirect_next_state <= LOAD;
			else
				redirect_next_state <= BUSY;
			end if;
		
		when LOAD =>
			redirect_state <= x"2";
			if (loaded_bytes_ctr = RC_FRAME_SIZE_IN - x"1") then
				redirect_next_state <= FINISH;
			else
				redirect_next_state <= LOAD;
			end if;
		
		when BUSY =>
			redirect_state <= x"3";
			if (or_all(ps_busy and RC_FRAME_PROTO_IN) = '0') then
				redirect_next_state <= LOAD;
			else
				redirect_next_state <= BUSY;
			end if;
		
		when FINISH =>
			redirect_state <= x"4";
			redirect_next_state <= CLEANUP;
		
		when CLEANUP =>
			redirect_state <= x"5";
			redirect_next_state <= IDLE;
	
	end case;
end process REDIRECT_MACHINE;

rc_rd_en <= '1' when redirect_current_state = LOAD or redirect_current_state = DROP else '0';
RC_RD_EN_OUT <= rc_rd_en;

LOADING_DONE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			RC_LOADING_DONE_OUT <= '0';
		elsif (RC_DATA_IN(8) = '1' and ps_wr_en = '1') then
			RC_LOADING_DONE_OUT <= '1';
		else
			RC_LOADING_DONE_OUT <= '0';
		end if;
	end if;
end process LOADING_DONE_PROC;

PS_WR_EN_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		ps_wr_en   <= rc_rd_en;
		ps_wr_en_q <= ps_wr_en;
	end if;
end process PS_WR_EN_PROC;

LOADED_BYTES_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (redirect_current_state = IDLE) then
			loaded_bytes_ctr <= (others => '0');
		elsif (redirect_current_state = LOAD or redirect_current_state = DROP) and (rc_rd_en = '1') then
			loaded_bytes_ctr <= loaded_bytes_ctr + x"1";
		end if;
	end if;
end process LOADED_BYTES_CTR_PROC;

FIRST_BYTE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		first_byte_q  <= first_byte;
		first_byte_qq <= first_byte_q;
		
		if (RESET = '1') then
			first_byte <= '0';
		elsif (redirect_current_state = IDLE) then
			first_byte <= '1';
		else
			first_byte <= '0';
		end if;
	end if;
end process FIRST_BYTE_PROC;

--*********************
--	DATA FLOW CONTROL

FLOW_MACHINE_PROC : process(CLK)
begin
  if rising_edge(CLK) then
    if (RESET = '1') then
      flow_current_state <= IDLE;
    else
      flow_current_state <= flow_next_state;
    end if;
  end if;
end process FLOW_MACHINE_PROC;

FLOW_MACHINE : process(flow_current_state, PC_TRANSMIT_ON_IN, PC_SOD_IN, TC_TRANSMIT_DONE_IN, ps_response_ready)
begin
  case flow_current_state is

    when IDLE =>
      state <= x"1";
      --if (RC_FRAME_WAITING_IN = '1') and (PC_TRANSMIT_ON_IN = '0') then
      if (ps_response_ready = '1') and (PC_TRANSMIT_ON_IN = '0') then
	flow_next_state <= TRANSMIT_CTRL;
      elsif (PC_SOD_IN = '1') then  -- pottential loss of frames
	flow_next_state <= TRANSMIT_DATA;
      else
	flow_next_state <= IDLE;
      end if;

    when TRANSMIT_DATA =>
      state <= x"2";
      if (TC_TRANSMIT_DONE_IN = '1') then
	flow_next_state <= CLEANUP;
      else
	flow_next_state <= TRANSMIT_DATA;
      end if;

    when TRANSMIT_CTRL =>
      state <= x"3";
      if (TC_TRANSMIT_DONE_IN = '1') then
	flow_next_state <= CLEANUP;
      else
	flow_next_state <= TRANSMIT_CTRL;
      end if;

    when CLEANUP =>
      state <= x"4";
      flow_next_state <= IDLE;

  end case;
end process FLOW_MACHINE;

TC_TRANSMIT_DATA_OUT <= '1' when (flow_current_state = TRANSMIT_DATA) else '0';
TC_TRANSMIT_CTRL_OUT <= '1' when (flow_current_state = TRANSMIT_CTRL) else '0';


--***********************
--	LINK STATE CONTROL

LINK_STATE_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			if (g_SIMULATE = 0) then
				link_current_state <= INACTIVE;
			else
				link_current_state <= ACTIVE;
			end if;
		else
			link_current_state <= link_next_state;
		end if;
	end if;
end process;

LINK_STATE_MACHINE : process(link_current_state, dhcp_done, wait_ctr, PCS_AN_COMPLETE_IN, tsm_ready, link_ok_timeout_ctr, PC_READY_IN)
begin
	case link_current_state is

		when ACTIVE =>
			link_state <= x"1";
			if (PCS_AN_COMPLETE_IN = '0') then
				link_next_state <= INACTIVE;
			else
				link_next_state <= ACTIVE;
			end if;

		when INACTIVE =>
			link_state <= x"2";
			if (PCS_AN_COMPLETE_IN = '1') then
				link_next_state <= TIMEOUT;
			else
				link_next_state <= INACTIVE;
			end if;

		when TIMEOUT =>
			link_state <= x"3";
			if (PCS_AN_COMPLETE_IN = '0') then
				link_next_state <= INACTIVE;
			else
				if (link_ok_timeout_ctr = x"ffff") then
					link_next_state <= ENABLE_MAC; --FINALIZE;
				else
					link_next_state <= TIMEOUT;
				end if;
			end if;

		when ENABLE_MAC =>
			link_state <= x"4";
			if (PCS_AN_COMPLETE_IN = '0') then
			  link_next_state <= INACTIVE;
			elsif (tsm_ready = '1') then
			  link_next_state <= FINALIZE; --INACTIVE;
			else
			  link_next_state <= ENABLE_MAC;
			end if;

		when FINALIZE =>
			link_state <= x"5";
			if (PCS_AN_COMPLETE_IN = '0') then
				link_next_state <= INACTIVE;
			else
				if (PC_READY_IN = '1') then
					link_next_state <= WAIT_FOR_BOOT; --ACTIVE;
				else
					link_next_state <= FINALIZE;
				end if;
			end if;
			
		when WAIT_FOR_BOOT =>
			link_state <= x"6";
			if (PCS_AN_COMPLETE_IN = '0') then
				link_next_state <= INACTIVE;
			else
				if (wait_ctr = x"3baa_ca00") then
					link_next_state <= GET_ADDRESS;
				else
					link_next_state <= WAIT_FOR_BOOT;
				end if;
			end if;
		
		when GET_ADDRESS =>
			link_state <= x"7";
			if (PCS_AN_COMPLETE_IN = '0') then
				link_next_state <= INACTIVE;
			else
				if (dhcp_done = '1') then
					link_next_state <= ACTIVE;
				else
					link_next_state <= GET_ADDRESS;
				end if;
			end if;

	end case;
end process LINK_STATE_MACHINE;

LINK_OK_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (link_current_state /= TIMEOUT) then
			link_ok_timeout_ctr <= (others => '0');
		elsif (link_current_state = TIMEOUT) then
			link_ok_timeout_ctr <= link_ok_timeout_ctr + x"1";
		end if;
	end if;
end process LINK_OK_CTR_PROC;

link_ok <= '1' when (link_current_state = ACTIVE) or (link_current_state = GET_ADDRESS) or (link_current_state = WAIT_FOR_BOOT) else '0';

WAIT_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (link_current_state = INACTIVE) then
			wait_ctr <= (others => '0');
		elsif (link_current_state = WAIT_FOR_BOOT) then
			wait_ctr <= wait_ctr + x"1";
		end if;
	end if;
end process WAIT_CTR_PROC;

dhcp_start <= '1' when link_current_state = GET_ADDRESS else '0';

LINK_DOWN_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			link_down_ctr      <= (others => '0');
			link_down_ctr_lock <= '0';
		elsif (PCS_AN_COMPLETE_IN = '1') then
			link_down_ctr_lock <= '0';
		elsif ((PCS_AN_COMPLETE_IN = '0') and (link_down_ctr_lock = '0')) then
			link_down_ctr      <= link_down_ctr + x"1";
			link_down_ctr_lock <= '1';
		end if;
	end if;
end process LINK_DOWN_CTR_PROC;

MC_LINK_OK_OUT <= link_ok;

-- END OF LINK STATE CONTROL
--*************

--*************
-- GENERATE MAC_ADDRESS
--TODO: take the unique id from regio and generate a mac address
g_MY_MAC <= x"efbeefbe0000";
--
--*************

--****************
-- TRI SPEED MAC CONTROLLER

TSMAC_CONTROLLER : trb_net16_gbe_mac_control
port map(
	CLK			=> CLK,
	RESET			=> RESET,

-- signals to/from main controller
	MC_TSMAC_READY_OUT	=> tsm_ready,
	MC_RECONF_IN		=> tsm_reconf,
	MC_GBE_EN_IN		=> '1',
	MC_RX_DISCARD_FCS	=> '0',
	MC_PROMISC_IN		=> '1',
	MC_MAC_ADDR_IN		=> g_MY_MAC, --x"001122334455",

-- signal to/from Host interface of TriSpeed MAC
	TSM_HADDR_OUT		=> tsm_haddr,
	TSM_HDATA_OUT		=> tsm_hdata,
	TSM_HCS_N_OUT		=> tsm_hcs_n,
	TSM_HWRITE_N_OUT	=> tsm_hwrite_n,
	TSM_HREAD_N_OUT		=> tsm_hread_n,
	TSM_HREADY_N_IN		=> TSM_HREADY_N_IN,
	TSM_HDATA_EN_N_IN	=> TSM_HDATA_EN_N_IN,

	DEBUG_OUT		=> mac_control_debug
);

--DEBUG_OUT <= mac_control_debug;

tsm_reconf <= '1' when (link_current_state = INACTIVE) and (PCS_AN_COMPLETE_IN = '1') else '0';

TSM_HADDR_OUT     <= tsm_haddr;
TSM_HCS_N_OUT     <= tsm_hcs_n;
TSM_HDATA_OUT     <= tsm_hdata;
TSM_HREAD_N_OUT   <= tsm_hread_n;
TSM_HWRITE_N_OUT  <= tsm_hwrite_n;

-- END OF TRI SPEED MAC CONTROLLER
--***************


-- *****
--	STATISTICS
-- *****


CTRS_GEN : for n in 0 to 15 generate

	CTR_PROC : process(CLK)
	begin
		if rising_edge(CLK) then
			if (RESET = '1') then
				arr(n) <= (others => '0');
			elsif (rx_stat_en_q = '1' and rx_stat_vec_q(16 + n) = '1') then
				arr(n) <= arr(n) + x"1";
			end if;	
		end if;
	end process CTR_PROC;

end generate CTRS_GEN;

STAT_VEC_SYNC : signal_sync
generic map (
	WIDTH => 32,
	DEPTH => 2
)
port map (
	RESET => RESET,
	CLK0  => CLK,
	CLK1  => CLK,
	D_IN  => TSM_RX_STAT_VEC_IN,
	D_OUT => rx_stat_vec_q
);


STAT_VEC_EN_SYNC : pulse_sync
port map(
	CLK_A_IN    => CLK_125,
	RESET_A_IN  => RESET,
	PULSE_A_IN  => TSM_RX_STAT_EN_IN,
	CLK_B_IN    => CLK,
	RESET_B_IN  => RESET,
	PULSE_B_OUT => rx_stat_en_q
);


STATS_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			stats_current_state <= IDLE;
		else
			stats_current_state <= stats_next_state;
		end if;
	end if;
end process STATS_MACHINE_PROC;

STATS_MACHINE : process(stats_current_state, rx_stat_en_q, stats_ctr)
begin

	case (stats_current_state) is
	
		when IDLE =>
			if (rx_stat_en_q = '1') then
				stats_next_state <= LOAD_VECTOR;
			else
				stats_next_state <= IDLE;
			end if;
		
		when LOAD_VECTOR =>
			--if (stat_ack = '1') then
			if (stats_ctr = 15) then
				stats_next_state <= CLEANUP;
			else
				stats_next_state <= LOAD_VECTOR;
			end if;
		
		when CLEANUP =>
			stats_next_state <= IDLE;
	
	end case;

end process STATS_MACHINE;

STATS_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (stats_current_state = IDLE) then
			stats_ctr <= 0;
		elsif (stats_current_state = LOAD_VECTOR and stat_ack ='1') then
			stats_ctr <= stats_ctr + 1;
		end if;
	end if;
end process STATS_CTR_PROC; 

--stat_data <= arr(stats_ctr);

stat_addr <= x"0c" + std_logic_vector(to_unsigned(stats_ctr, 8)); 

stat_rdy <= '1' when stats_current_state /= IDLE and stats_current_state /= CLEANUP else '0';

stat_data(7 downto 0)   <= arr(stats_ctr)(31 downto 24);
stat_data(15 downto 8)  <= arr(stats_ctr)(23 downto 16);
stat_data(23 downto 16) <= arr(stats_ctr)(15 downto 8);
stat_data(31 downto 24) <= arr(stats_ctr)(7 downto 0);


-- **** debug
FRAME_WAITING_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			frame_waiting_ctr <= (others => '0');
		elsif (RC_FRAME_WAITING_IN = '1') then
			frame_waiting_ctr <= frame_waiting_ctr + x"1";
		end if;
	end if;
end process FRAME_WAITING_CTR_PROC;

SAVE_VALUES_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			ps_busy_q <= (others => '0');
			rc_frame_proto_q <= (others => '0');
		elsif (redirect_current_state = IDLE and RC_FRAME_WAITING_IN = '1') then
			ps_busy_q <= ps_busy;
			rc_frame_proto_q <= RC_FRAME_PROTO_IN;
		end if;
	end if;
end process SAVE_VALUES_PROC;


DEBUG_OUT(3 downto 0)   <= mac_control_debug(3 downto 0);
DEBUG_OUT(7 downto 4)   <= state;
DEBUG_OUT(11 downto 8)  <= redirect_state;
DEBUG_OUT(15 downto 12) <= link_state;
DEBUG_OUT(23 downto 16) <= frame_waiting_ctr(7 downto 0);
DEBUG_OUT(27 downto 24) <= (others => '0'); --ps_busy_q;
DEBUG_OUT(31 downto 28) <= (others => '0'); --rc_frame_proto_q;
DEBUG_OUT(63 downto 32) <= (others => '0');


-- ****



end trb_net16_gbe_main_control;


