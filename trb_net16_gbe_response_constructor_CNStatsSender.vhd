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
-- gathers statistics from modules and transfers through GBE to the PC

entity trb_net16_gbe_response_constructor_CNStatsSender is
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
end trb_net16_gbe_response_constructor_CNStatsSender;


architecture trb_net16_gbe_response_constructor_CNStatsSender of trb_net16_gbe_response_constructor_CNStatsSender is

attribute syn_encoding	: string;

type construct_states is (IDLE, WAIT_FOR_LOAD, LOAD_DATA, TERMINATION, CLEANUP);
signal construct_current_state, construct_next_state : construct_states;
attribute syn_encoding of construct_current_state: signal is "safe,gray";

type select_states is (IDLE, SELECT_MODULE, WAIT_FOR_TRANSMIT, CLEANUP);
signal select_current_state, select_next_state : select_states;
attribute syn_encoding of select_current_state: signal is "safe,gray";

signal load_ctr   : std_logic_vector(15 downto 0);
signal tc_data    : std_logic_vector(8 downto 0);
signal timer_t    : std_logic_vector(7 downto 0);
signal state      : std_logic_vector(3 downto 0);
signal size_t     : std_logic_vector(15 downto 0);
signal packet_ctr : std_logic_vector(31 downto 0);

signal stats_rd_clk, stats_we, stats_re : std_logic;
signal stats_data, stats_q : std_logic_vector(71 downto 0);

signal module_ctr : std_logic_vector(7 downto 0);
signal pause_ctr  : std_logic_vector(15 downto 0);


begin

-- **************
-- MODULE SELECTION PART

SELECT_MACHINE_PROC : process(CLK)
begin
if rising_edge(CLK) then
		if (RESET = '1') then
			select_current_state <= IDLE;
		else
			select_current_state <= select_next_state;
		end if;
	end if;
end process SELECT_MACHINE_PROC;

SELECT_MACHINE : process(construct_current_state, START_STAT_IN, module_ctr)
begin
	case select_current_state is
	
		when IDLE =>
			if (START_STAT_IN = '1') then
				select_next_state <= SELECT_MODULE;
			else
				select_next_state <= IDLE;
			end if;
		
		when SELECT_MODULE =>
			select_next_state <= WAIT_FOR_TRANSMIT;
		
		when WAIT_FOR_TRANSMIT =>
			if (construct_current_state = CLEANUP) then
				if (module_ctr = "00000010") then  -- send data from only two first modules
					select_next_state <= CLEANUP;
				else
					select_next_state <= SELECT_MODULE;
				end if;
			else
				select_next_state <= WAIT_FOR_TRANSMIT;
			end if;
		
		when CLEANUP =>
			select_next_state <= IDLE; 
	
	end case;
end process SELECT_MACHINE;

-- shift register for module selection
MODULE_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (select_current_state = IDLE) then
			module_ctr <= x"01";
		elsif (select_current_state = WAIT_FOR_TRANSMIT and construct_current_state = CLEANUP) then
			module_ctr(7 downto 1) <= module_ctr(6 downto 0);
			module_ctr(0)          <= '0';
		end if;
	end if;
end process MODULE_CTR_PROC;

MODULE_SELECT_OUT <= module_ctr;

MODULE_RD_EN_OUT <= '1' when (PS_SELECTED_IN = '1' and TC_RD_EN_IN = '1') or (select_current_state = SELECT_MODULE) else '0'; 

-- **************
-- TRANSMISSION PART

CONSTRUCT_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			construct_current_state <= IDLE;
		else
			construct_current_state <= construct_next_state;
		end if;
	end if;
end process CONSTRUCT_MACHINE_PROC;

CONSTRUCT_MACHINE : process(construct_current_state, select_current_state, TC_BUSY_IN, PS_SELECTED_IN, load_ctr)
begin
	case construct_current_state is
	
		when IDLE =>
			state <= x"1";
			if (select_current_state = SELECT_MODULE) then
				construct_next_state <= WAIT_FOR_LOAD;
			else
				construct_next_state <= IDLE;
			end if;
			
		when WAIT_FOR_LOAD =>
			state <= x"2";
			if (TC_BUSY_IN = '0' and PS_SELECTED_IN = '1') then
				construct_next_state <= LOAD_DATA;
			else
				construct_next_state <= WAIT_FOR_LOAD;
			end if;
			
		when LOAD_DATA =>
			state <= x"3";
			if (load_ctr = x"0400") then
				construct_next_state <= TERMINATION;
			else
				construct_next_state <= LOAD_DATA;
			end if;
			
		when TERMINATION =>
			state <= x"4";
			construct_next_state <= CLEANUP;
		
		when CLEANUP =>
			state <= x"5";
			construct_next_state <= IDLE;
	
	end case;
end process CONSTRUCT_MACHINE;

-- counts bytes from one module
LOAD_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (construct_current_state = IDLE) then
			load_ctr <= (others => '0');
		elsif (TC_RD_EN_IN = '1') and (PS_SELECTED_IN = '1') then
			load_ctr <= load_ctr + x"1";
		end if;
	end if;
end process LOAD_CTR_PROC;

TC_DATA_PROC : process(construct_current_state, MODULE_DATA_IN)
begin

	tc_data(8) <= '0';

	case (construct_current_state) is
			
		when LOAD_DATA =>
			for i in 0 to 7 loop
				tc_data(i) <= MODULE_DATA_IN(i);
			end loop;
			
		when TERMINATION =>
			tc_data(7 downto 0) <= x"ff";
			tc_data(8)          <= '1';
		
		when others => tc_data(7 downto 0) <= x"00";
	
	end case;
	
end process;

TC_DATA_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		TC_DATA_OUT <= tc_data;
	end if;
end process TC_DATA_SYNC;


-- END OF TRANSMISSION PART
-- *****************

STOP_TRANSMISSION_OUT <= '1' when select_current_state /= IDLE else '0';


PS_BUSY_OUT <= '0' when (construct_current_state = IDLE) else '1';
PS_RESPONSE_READY_OUT <= '0' when (construct_current_state = IDLE) else '1'; 

TC_FRAME_SIZE_OUT <= x"0400";

TC_FRAME_TYPE_OUT <= x"0008";  -- frame type: ip 

TC_DEST_MAC_OUT <= x"ffffffffffff";
TC_DEST_IP_OUT  <= x"ff00a8c0";
TC_DEST_UDP_OUT <= x"55c3";
TC_SRC_MAC_OUT  <= g_MY_MAC;
TC_SRC_IP_OUT   <= x"aa00a8c0";
TC_SRC_UDP_OUT  <= x"55c3";
TC_IP_PROTOCOL_OUT <= x"11"; -- udp


end trb_net16_gbe_response_constructor_CNStatsSender;


