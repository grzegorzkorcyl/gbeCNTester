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
-- generates random dummy packets to feed the Compute Node, receives data back and updates statistics

entity trb_net16_gbe_response_constructor_CNTester is
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

-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end trb_net16_gbe_response_constructor_CNTester;


architecture trb_net16_gbe_response_constructor_CNTester of trb_net16_gbe_response_constructor_CNTester is

attribute syn_encoding	: string;

type construct_states is (IDLE, WAIT_FOR_LOAD, LOAD_DATA, TERMINATION, CLEANUP);
signal construct_current_state, construct_next_state : construct_states;
attribute syn_encoding of construct_current_state: signal is "safe,gray";

signal load_ctr   : std_logic_vector(15 downto 0);
signal tc_data    : std_logic_vector(8 downto 0);
signal timer_t    : std_logic_vector(7 downto 0);
signal state      : std_logic_vector(3 downto 0);
signal size_t     : std_logic_vector(15 downto 0);
signal packet_ctr : std_logic_vector(31 downto 0);


signal stats_rd_clk, stats_we, stats_re : std_logic;
--signal stats_data, stats_q : std_logic_vector(71 downto 0);
signal stats_data : std_logic_vector(63 downto 0);
signal stats_q : std_logic_vector(7 downto 0);
signal saved_timestamp, saved_rec_timestamp, saved_rec_packet_id : std_logic_vector(31 downto 0);

type dissect_states is (IDLE, SAVE, CLEANUP);
signal dissect_current_state, dissect_next_state : dissect_states;
attribute syn_encoding of dissect_current_state: signal is "safe,gray";

signal resp_bytes_ctr : integer range 0 to 10;

begin


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

CONSTRUCT_MACHINE : process(construct_current_state, GENERATE_PACKET_IN, TC_BUSY_IN, PS_SELECTED_IN, load_ctr, SIZE_IN)
begin
	case construct_current_state is
	
		when IDLE =>
			state <= x"1";
			if (GENERATE_PACKET_IN = '1') then
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
			if (load_ctr = size_t - x"1") then
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

SIZE_T_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			size_t <= (others => '0');
		elsif (construct_current_state = IDLE and GENERATE_PACKET_IN = '1') then
			size_t <= SIZE_IN;
		end if;
	end if;
end process SIZE_T_PROC;


--timer_t <=  std_logic_vector(to_unsigned(load_ctr, 8));
TC_DATA_PROC : process(construct_current_state, load_ctr)
begin

	tc_data(8) <= '0';

	case (construct_current_state) is
			
		when LOAD_DATA =>
			for i in 0 to 7 loop
				tc_data(i) <= load_ctr(i);
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
	
		TC_DATA_OUT(8) <= '0';
	
		if (load_ctr = x"0000") then
			TC_DATA_OUT(7 downto 0) <= x"cc";
		elsif (load_ctr = x"0001") then
			TC_DATA_OUT(7 downto 0) <= packet_ctr(31 downto 24);
		elsif (load_ctr = x"0002") then
			TC_DATA_OUT(7 downto 0) <= packet_ctr(23 downto 16);
		elsif (load_ctr = x"0003") then
			TC_DATA_OUT(7 downto 0) <= packet_ctr(15 downto 8);
		elsif (load_ctr = x"0004") then
			TC_DATA_OUT(7 downto 0) <= packet_ctr(7 downto 0);
		elsif (load_ctr = x"0005") then
			TC_DATA_OUT(7 downto 0) <= saved_timestamp(31 downto 24);
		elsif (load_ctr = x"0006") then
			TC_DATA_OUT(7 downto 0) <= saved_timestamp(23 downto 16);
		elsif (load_ctr = x"0007") then
			TC_DATA_OUT(7 downto 0) <= saved_timestamp(15 downto 8);
		elsif (load_ctr = x"0008") then
			TC_DATA_OUT(7 downto 0) <= saved_timestamp(7 downto 0);
		else
			TC_DATA_OUT <= tc_data;
		end if;
	end if;
end process TC_DATA_SYNC;

-- packet counter as packet id for stats memory
PACKET_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			packet_ctr <= (others => '0');
		elsif (construct_current_state = LOAD_DATA and load_ctr = size_t - x"1") then
			packet_ctr <= packet_ctr + x"1";
		end if;
	end if;
end process PACKET_CTR_PROC;

SAVED_TIMESTAMP_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (construct_current_state = CLEANUP) then
			saved_timestamp <= (others => '0');
		elsif (GENERATE_PACKET_IN = '1') then
			saved_timestamp <= TIMESTAMP_IN;
		end if;
	end if;
end process SAVED_TIMESTAMP_PROC;

-- END OF TRANSMISSION PART
-- *****************


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
			saved_rec_packet_id <= (others => '0');
			saved_rec_timestamp <= (others => '0');
		elsif (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
			case (resp_bytes_ctr) is
				
				when 4 =>
					saved_rec_packet_id(7 downto 0) <= PS_DATA_IN(7 downto 0);
				when 3 =>
					saved_rec_packet_id(15 downto 8) <= PS_DATA_IN(7 downto 0);
				when 2 =>
					saved_rec_packet_id(23 downto 16) <= PS_DATA_IN(7 downto 0);
				when 1 =>
					saved_rec_packet_id(31 downto 24) <= PS_DATA_IN(7 downto 0);
					
				when 8 =>
					saved_rec_timestamp(7 downto 0) <= PS_DATA_IN(7 downto 0);
				when 7 =>
					saved_rec_timestamp(15 downto 8) <= PS_DATA_IN(7 downto 0);
				when 6 =>
					saved_rec_timestamp(23 downto 16) <= PS_DATA_IN(7 downto 0);
				when 5 =>
					saved_rec_timestamp(31 downto 24) <= PS_DATA_IN(7 downto 0);
					
				when others => null;
			end case;
		end if;
	end if;
end process SAVE_VALUES_PROC;


-- END OF RECEVING PART
-- *****************



-- *****************
--  STATISTICS PART

STATS_MEM : fifo_512x64x8
    port map(
        Data		=> stats_data,
        RdClock		=> CLK, 
        WrClock		=> CLK,
        WrEn		=> stats_we,
        RdEn		=> stats_re,
        Reset		=> RESET,
        RPReset		=> RESET,
        Q			=> stats_q,
        Empty		=> open,
        Full		=> MODULE_FULL_OUT,
        AlmostEmpty => open,
        AlmostFull  => open
);

stats_re <= '1' when MODULE_RD_EN_IN = '1' and MODULE_SELECTED_IN = '1' else '0'; 

stats_we <= '1' when construct_current_state = TERMINATION or dissect_current_state = CLEANUP else '0';

stats_data(31 downto 0)  <= packet_ctr - x"1" when construct_current_state = TERMINATION else saved_rec_packet_id;
stats_data(63 downto 32) <= saved_timestamp when construct_current_state = TERMINATION else saved_rec_timestamp;

MODULE_DATA_OUT(7 downto 0)  <= stats_q;
MODULE_DATA_OUT(71 downto 8) <= (others => '0');


-- END OF STATISTICS PART
-- ****************


PS_BUSY_OUT <= '0' when (construct_current_state = IDLE) else '1';
PS_RESPONSE_READY_OUT <= '0' when (construct_current_state = IDLE) else '1'; 

TC_FRAME_SIZE_OUT <= size_t; --x"00c9";
TC_FRAME_TYPE_OUT <= x"1101";  -- frame type: CNTester 

TC_DEST_MAC_OUT <= x"ffffffffffff";
TC_DEST_IP_OUT  <= (others => '0');
TC_DEST_UDP_OUT <= (others => '0');
TC_SRC_MAC_OUT  <= x"123456789012";
TC_SRC_IP_OUT   <= (others => '0');
TC_SRC_UDP_OUT  <= (others  => '0');
TC_IP_PROTOCOL_OUT <= (others  => '0'); -- udp


end trb_net16_gbe_response_constructor_CNTester;


