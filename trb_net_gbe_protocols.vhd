library ieee;
use ieee.std_logic_1164.all;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;
library work;
use work.trb_net_std.all;

package trb_net_gbe_protocols is

signal g_SIMULATE             : integer range 0 to 1 := 0;

-- g_MY_IP is being set by DHCP Response Constructor
signal g_MY_IP                : std_logic_vector(31 downto 0);
-- g_MY_MAC is being set by Main Controller
signal g_MY_MAC               : std_logic_vector(47 downto 0);

constant c_MAX_FRAME_TYPES    : integer range 1 to 16 := 2;
constant c_MAX_PROTOCOLS      : integer range 1 to 16 := 1;
constant c_MAX_IP_PROTOCOLS   : integer range 1 to 16 := 2;
constant c_MAX_UDP_PROTOCOLS  : integer range 1 to 16 := 2;

--WARNING: do not leave zeros as unused types or protocols
type frame_types_a is array(c_MAX_FRAME_TYPES - 1 downto 0) of std_logic_vector(15 downto 0);
constant FRAME_TYPES : frame_types_a := (x"0111", x"ffff"); -- x"0800", x"0806"); 
-- Test protocol only 

type ip_protos_a is array(c_MAX_IP_PROTOCOLS - 1 downto 0) of std_logic_vector(7 downto 0);
constant IP_PROTOCOLS : ip_protos_a := (x"11", x"ff"); --(x"11", x"01");
-- none is being used

type udp_protos_a is array(c_MAX_UDP_PROTOCOLS - 1 downto 0) of std_logic_vector(15 downto 0);
constant UDP_PROTOCOLS : udp_protos_a := (x"0044", x"ffff"); --(x"0044", x"61a8", x"7530");
-- none is being used

component trb_net16_gbe_response_constructor_CNTester is
generic ( STAT_ADDRESS_BASE : integer := 0
);
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;
	
-- INTERFACE	
	PS_DATA_IN		: in	std_logic_vector(8 downto 0);
	PS_WR_EN_IN		: in	std_logic;
	PS_ACTIVATE_IN		: in	std_logic;
	PS_RESPONSE_READY_OUT	: out	std_logic;
	PS_BUSY_OUT		: out	std_logic;
	PS_SELECTED_IN		: in	std_logic;
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
		
	TC_RD_EN_IN		: in	std_logic;
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
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
	
	STAT_DATA_OUT : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT : out std_logic;
	STAT_DATA_ACK_IN  : in std_logic;
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
-- END OF INTERFACE

	TIMESTAMP_IN                : in    std_logic_vector(31 downto 0);
	DEST_ADDR_IN                : in    std_logic_vector(15 downto 0);
	SIZE_IN                     : in    std_logic_vector(15 downto 0);
	GENERATE_PACKET_IN          : in    std_logic;
		
	MODULE_DATA_OUT             : out	std_logic_vector(71 downto 0);
	MODULE_RD_EN_IN             : in	std_logic;
	MODULE_SELECTED_IN           : in	std_logic;
	MODULE_FULL_OUT             : out	std_logic;
	CNT_MODULE_ID_IN            : in std_logic_vector(3 downto 0);
-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end component;

component trb_net16_gbe_response_constructor_CNStatsSender is
generic ( STAT_ADDRESS_BASE : integer := 0
);
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;
	
-- INTERFACE	
	PS_DATA_IN		: in	std_logic_vector(8 downto 0);
	PS_WR_EN_IN		: in	std_logic;
	PS_ACTIVATE_IN		: in	std_logic;
	PS_RESPONSE_READY_OUT	: out	std_logic;
	PS_BUSY_OUT		: out	std_logic;
	PS_SELECTED_IN		: in	std_logic;
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
		
	TC_RD_EN_IN		: in	std_logic;
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
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
	
	STAT_DATA_OUT : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT : out std_logic;
	STAT_DATA_ACK_IN  : in std_logic;
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
-- END OF INTERFACE

	MODULE_SELECT_OUT     : out std_logic_vector(7 downto 0);
	MODULE_RD_EN_OUT      : out std_logic;
	MODULE_DATA_IN        : in std_logic_vector(71 downto 0);
	STOP_TRANSMISSION_OUT : out std_logic;
	START_STAT_IN         : in std_logic;
	CNT_MODULE_ID_IN      : in std_logic_vector(3 downto 0);

-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end component;


end package;
