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
-- multiplexes between different protocols and manages the responses
-- 
-- 


entity trb_net16_gbe_protocol_selector is
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;

-- signals to/from main controller
	PS_DATA_IN		: in	std_logic_vector(8 downto 0); 
	PS_WR_EN_IN		: in	std_logic;
	PS_PROTO_SELECT_IN	: in	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	PS_BUSY_OUT		: out	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	PS_FRAME_SIZE_IN	: in	std_logic_vector(15 downto 0);
	PS_RESPONSE_READY_OUT	: out	std_logic;
	
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	
-- singals to/from transmit controller with constructed response
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
	TC_RD_EN_IN		: in	std_logic;
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);
	
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	
	TC_BUSY_IN		: in	std_logic;
	
	-- counters from response constructors
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
	PROTOS_DEBUG_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	
	-- misc signals for response constructors
	DHCP_START_IN		: in	std_logic;
	DHCP_DONE_OUT		: out	std_logic;
	
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

	-- input for statistics from outside	
	STAT_DATA_IN             : in std_logic_vector(31 downto 0);
	STAT_ADDR_IN             : in std_logic_vector(7 downto 0);
	STAT_DATA_RDY_IN         : in std_logic;
	STAT_DATA_ACK_OUT        : out std_logic;

	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end trb_net16_gbe_protocol_selector;


architecture trb_net16_gbe_protocol_selector of trb_net16_gbe_protocol_selector is

--attribute HGROUP : string;
--attribute HGROUP of trb_net16_gbe_protocol_selector : architecture is "GBE_MAIN_group";

signal rd_en                    : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal resp_ready               : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal tc_data                  : std_logic_vector(c_MAX_PROTOCOLS * 9 - 1 downto 0);
signal tc_size                  : std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
signal tc_type                  : std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
signal busy                     : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal selected                 : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal tc_mac                   : std_logic_vector(c_MAX_PROTOCOLS * 48 - 1 downto 0);
signal tc_ip                    : std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
signal tc_udp                   : std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
signal tc_src_mac               : std_logic_vector(c_MAX_PROTOCOLS * 48 - 1 downto 0);
signal tc_src_ip                : std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
signal tc_src_udp               : std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
signal tc_ip_proto              : std_logic_vector(c_MAX_PROTOCOLS * 8 - 1 downto 0); 

-- plus 1 is for the outside
signal stat_data                : std_logic_vector((c_MAX_PROTOCOLS + 1) * 32 - 1 downto 0);
signal stat_addr                : std_logic_vector((c_MAX_PROTOCOLS + 1) * 8 - 1 downto 0);
signal stat_rdy                 : std_logic_vector((c_MAX_PROTOCOLS + 1) - 1 downto 0);
signal stat_ack                 : std_logic_vector((c_MAX_PROTOCOLS + 1) - 1 downto 0);

begin

-- protocol Nr. 1 CNTester
CNTeseter : trb_net16_gbe_response_constructor_CNTester
generic map( STAT_ADDRESS_BASE => 6
)
port map (
	CLK			=> CLK,
	RESET			=> RESET,
	
-- INTERFACE	
	PS_DATA_IN		=> PS_DATA_IN,
	PS_WR_EN_IN		=> PS_WR_EN_IN,
	PS_ACTIVATE_IN		=> PS_PROTO_SELECT_IN(0),
	PS_RESPONSE_READY_OUT	=> resp_ready(0),
	PS_BUSY_OUT		=> busy(0),
	PS_SELECTED_IN		=> selected(0),

	PS_SRC_MAC_ADDRESS_IN	=> PS_SRC_MAC_ADDRESS_IN,
	PS_DEST_MAC_ADDRESS_IN  => PS_DEST_MAC_ADDRESS_IN,
	PS_SRC_IP_ADDRESS_IN	=> PS_SRC_IP_ADDRESS_IN,
	PS_DEST_IP_ADDRESS_IN	=> PS_DEST_IP_ADDRESS_IN,
	PS_SRC_UDP_PORT_IN	=> PS_SRC_UDP_PORT_IN,
	PS_DEST_UDP_PORT_IN	=> PS_DEST_UDP_PORT_IN,
	
	TC_RD_EN_IN		=> TC_RD_EN_IN,
	TC_DATA_OUT		=> tc_data(1 * 9 - 1 downto 0 * 9),
	TC_FRAME_SIZE_OUT	=> tc_size(1 * 16 - 1 downto 0 * 16),
	TC_FRAME_TYPE_OUT	=> tc_type(1 * 16 - 1 downto 0 * 16),
	TC_IP_PROTOCOL_OUT	=> tc_ip_proto(1 * 8 - 1 downto 0 * 8),
	
	TC_DEST_MAC_OUT		=> tc_mac(1 * 48 - 1 downto 0 * 48),
	TC_DEST_IP_OUT		=> tc_ip(1 * 32 - 1 downto 0 * 32),
	TC_DEST_UDP_OUT		=> tc_udp(1 * 16 - 1 downto 0 * 16),
	TC_SRC_MAC_OUT		=> tc_src_mac(1 * 48 - 1 downto 0 * 48),
	TC_SRC_IP_OUT		=> tc_src_ip(1 * 32 - 1 downto 0 * 32),
	TC_SRC_UDP_OUT		=> tc_src_udp(1 * 16 - 1 downto 0 * 16),
	
	TC_BUSY_IN		=> TC_BUSY_IN,
	
	STAT_DATA_OUT => stat_data(1 * 32 - 1 downto 0 * 32),
	STAT_ADDR_OUT => stat_addr(1 * 8 - 1 downto 0 * 8),
	STAT_DATA_RDY_OUT => stat_rdy(0),
	STAT_DATA_ACK_IN  => stat_ack(0),
	RECEIVED_FRAMES_OUT	=> RECEIVED_FRAMES_OUT(1 * 16 - 1 downto 0 * 16),
	SENT_FRAMES_OUT		=> SENT_FRAMES_OUT(1 * 16 - 1 downto 0 * 16),
	
-- END OF INTERFACE
	TIMESTAMP_IN         => (others => '0'),
	DEST_ADDR_IN         => (others => '0'),
	GENERATE_PACKET_IN   => '0',
	
	DEBUG_OUT		=> PROTOS_DEBUG_OUT(1 * 32 - 1 downto 0 * 32)
);


--***************
-- DO NOT TOUCH,  response selection logic

stat_data((c_MAX_PROTOCOLS + 1) * 32 - 1 downto c_MAX_PROTOCOLS * 32) <= STAT_DATA_IN;
stat_addr((c_MAX_PROTOCOLS + 1) * 8 - 1 downto c_MAX_PROTOCOLS * 8)   <= STAT_ADDR_IN;
stat_rdy(c_MAX_PROTOCOLS) <= STAT_DATA_RDY_IN;
STAT_DATA_ACK_OUT <= stat_ack(c_MAX_PROTOCOLS);


PS_BUSY_OUT <= busy;

SELECTOR_PROC : process(CLK)
	variable found : boolean := false;
begin
	if rising_edge(CLK) then
	
		selected              <= (others => '0');
	
		if (RESET = '1') then
			TC_DATA_OUT           <= (others => '0');
			TC_FRAME_SIZE_OUT     <= (others => '0');
			TC_FRAME_TYPE_OUT     <= (others => '0');
			TC_DEST_MAC_OUT       <= (others => '0');
			TC_DEST_IP_OUT        <= (others => '0');
			TC_DEST_UDP_OUT       <= (others => '0');
			TC_SRC_MAC_OUT        <= (others => '0');
			TC_SRC_IP_OUT         <= (others => '0');
			TC_SRC_UDP_OUT        <= (others => '0');
			TC_IP_PROTOCOL_OUT    <= (others => '0');
			PS_RESPONSE_READY_OUT <= '0';
			selected              <= (others => '0');
			found := false;
		else
			if (or_all(resp_ready) = '1') then
				for i in 0 to c_MAX_PROTOCOLS - 1 loop
					if (resp_ready(i) = '1') then
						TC_DATA_OUT           <= tc_data((i + 1) * 9 - 1 downto i * 9);
						TC_FRAME_SIZE_OUT     <= tc_size((i + 1) * 16 - 1 downto i * 16);
						TC_FRAME_TYPE_OUT     <= tc_type((i + 1) * 16 - 1 downto i * 16);
						TC_DEST_MAC_OUT       <= tc_mac((i + 1) * 48 - 1 downto i * 48);
						TC_DEST_IP_OUT        <= tc_ip((i + 1) * 32 - 1 downto i * 32);
						TC_DEST_UDP_OUT       <= tc_udp((i + 1) * 16 - 1 downto i * 16);
						TC_SRC_MAC_OUT        <= tc_src_mac((i + 1) * 48 - 1 downto i * 48);
						TC_SRC_IP_OUT         <= tc_src_ip((i + 1) * 32 - 1 downto i * 32);
						TC_SRC_UDP_OUT        <= tc_src_udp((i + 1) * 16 - 1 downto i * 16);
						TC_IP_PROTOCOL_OUT    <= tc_ip_proto((i + 1) * 8 - 1 downto i * 8);
						PS_RESPONSE_READY_OUT <= '1';
						selected(i)           <= '1';
						found := true;
					elsif (i = c_MAX_PROTOCOLS - 1) and (resp_ready(i) = '0') and (found = false) then
						found := false;
						PS_RESPONSE_READY_OUT <= '0';
					end if;
				end loop;
			else
				TC_DATA_OUT           <= (others => '0');
				TC_FRAME_SIZE_OUT     <= (others => '0');
				TC_FRAME_TYPE_OUT     <= (others => '0');
				TC_DEST_MAC_OUT       <= (others => '0');
				TC_DEST_IP_OUT        <= (others => '0');
				TC_DEST_UDP_OUT       <= (others => '0');
				TC_SRC_MAC_OUT        <= (others => '0');
				TC_SRC_IP_OUT         <= (others => '0');
				TC_SRC_UDP_OUT        <= (others => '0');
				TC_IP_PROTOCOL_OUT    <= (others => '0');
				PS_RESPONSE_READY_OUT <= '0';
				found := false;
			end if;
		end if;
		
	end if;
end process SELECTOR_PROC;
-- ************

end trb_net16_gbe_protocol_selector;


