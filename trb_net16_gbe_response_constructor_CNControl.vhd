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
-- reveices control commands from PC and sets the appropriate registers

entity trb_net16_gbe_response_constructor_CNControl is
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

	PACKET_SIZE_OUT : out std_logic_vector(15 downto 0);

-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end trb_net16_gbe_response_constructor_CNControl;


architecture trb_net16_gbe_response_constructor_CNControl of trb_net16_gbe_response_constructor_CNControl is

attribute syn_encoding	: string;

signal state      : std_logic_vector(3 downto 0);
signal size_t     : std_logic_vector(15 downto 0);

signal saved_packet_size : std_logic_vector(15 downto 0);

type dissect_states is (IDLE, SAVE, CLEANUP);
signal dissect_current_state, dissect_next_state : dissect_states;
attribute syn_encoding of dissect_current_state: signal is "safe,gray";

signal resp_bytes_ctr : integer range 0 to 9000;


begin


-- *****************
--  RECEIVING PART

DISSECT_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			dissect_current_state <= IDLE;
		else
			dissect_current_state <= dissect_next_state;
		end if;
	end if;
end process DISSECT_MACHINE_PROC;

DISSECT_MACHINE : process(dissect_current_state, PS_WR_EN_IN, PS_ACTIVATE_IN, PS_DATA_IN)
begin
	case dissect_current_state is
	
		when IDLE =>
			state <= x"1";
			if (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
				dissect_next_state <= SAVE;
			else
				dissect_next_state <= IDLE;
			end if;
		
		when SAVE =>
			state <= x"2";
			if (PS_DATA_IN(8) = '1') then
				dissect_next_state <= CLEANUP;
			else
				dissect_next_state <= SAVE;
			end if;
		
		when CLEANUP =>
			state <= x"5";
			dissect_next_state <= IDLE;
	
	end case;
end process DISSECT_MACHINE;

RESP_BYTES_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (dissect_current_state = CLEANUP) then
			resp_bytes_ctr <= 0;
		elsif (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
			resp_bytes_ctr <= resp_bytes_ctr + 1;
		end if;
	end if;
end process RESP_BYTES_CTR_PROC;

SAVE_VALUES_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (dissect_current_state = IDLE)then
			saved_packet_size <= (others => '0');
		elsif (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
			case (resp_bytes_ctr) is
				
				when 2 =>
					saved_packet_size(7 downto 0) <= PS_DATA_IN(7 downto 0);
				when 1 =>
					saved_packet_size(15 downto 8) <= PS_DATA_IN(7 downto 0);
					
				when others => null;
			end case;
		end if;
	end if;
end process SAVE_VALUES_PROC;

SYNC_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			PACKET_SIZE_OUT <= (others => '0');
		elsif (dissect_current_state = CLEANUP) then
			PACKET_SIZE_OUT <= saved_packet_size;
		end if;
	end if;
end process SYNC_PROC;


-- END OF RECEVING PART
-- *****************




PS_BUSY_OUT <= '0';
PS_RESPONSE_READY_OUT <= '0';

TC_FRAME_SIZE_OUT <= size_t; -- doesn't matter
TC_FRAME_TYPE_OUT <= x"1101"; -- doesn't matter

TC_DEST_MAC_OUT <= x"ffffffffffff"; -- doesn't matter
TC_DEST_IP_OUT  <= (others => '0'); -- doesn't matter
TC_DEST_UDP_OUT <= (others => '0'); -- doesn't matter
TC_SRC_MAC_OUT  <= x"123456789012"; -- doesn't matter
TC_SRC_IP_OUT   <= (others => '0'); -- doesn't matter
TC_SRC_UDP_OUT  <= (others  => '0'); -- doesn't matter
TC_IP_PROTOCOL_OUT <= (others  => '0');  -- doesn't matter


end trb_net16_gbe_response_constructor_CNControl;


