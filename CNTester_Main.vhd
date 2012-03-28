LIBRARY ieee;
use ieee.std_logic_1164.all;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;
use IEEE.std_logic_arith.all;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity CNTester_Main is
	port (
		CLKSYS_IN       : in std_logic;
		RESET           : in std_logic;
		LINK_OK_IN		: in std_logic;
		
		GENERATE_OUT    : out std_logic_vector(7 downto 0);
		TIMESTAMP_OUT   : out std_logic_vector(31 downto 0);
		DEST_ADDR_OUT   : out std_logic_vector(15 downto 0);
		SIZE_OUT        : out std_logic_vector(15 downto 0);
		
		SENDERS_FREE_IN : in std_logic_vector(7 downto 0)
	);
end entity CNTester_Main;

architecture CNTester_Main of CNTester_Main is

type generate_states is (IDLE, GENERATE_SENDER, GENERATE_SIZE, ACTIVATE, WAIT1, WAIT2, WAIT3, WAIT4, WAIT5);
signal generate_current_state, generate_next_state : generate_states;

signal generate_en, condition_valid : std_logic;
signal values : std_logic_vector(31 downto 0);
signal generate_t : std_logic_vector(7 downto 0);
signal timer : std_logic_vector(31 downto 0);
	
begin

	RAND : CNTester_random
		port map(
	      CLK_IN      => CLKSYS_IN,
	      RESET       => RESET,
	      GENERATE_IN => generate_en,
	      RANDOM_OUT  => values         
	    );

	
	GENERATE_MACHINE_PROC : process(CLKSYS_IN)
	begin
		if rising_edge(CLKSYS_IN) then
			if (RESET = '1') then
				generate_current_state <= IDLE;
			else
				generate_current_state <= generate_next_state;
			end if;
		end if;
	end process GENERATE_MACHINE_PROC;
	
	GENERATE_MACHINE : process(generate_current_state, SENDERS_FREE_IN, generate_t)
	begin
	
		case (generate_current_state) is
		
			when IDLE =>
				if (SENDERS_FREE_IN = "00000000") and (LINK_OK_IN = '1') then
					generate_next_state <= GENERATE_SENDER;
				else
					generate_next_state <= IDLE;
				end if;
			
			when GENERATE_SENDER =>
				if (generate_t /= "00000000")   then
					generate_next_state <= GENERATE_SIZE;
				else
					generate_next_state <= GENERATE_SENDER;
				end if;
				
			when GENERATE_SIZE =>
				if (values(31 downto 7) /= x"0000_00") then
					generate_next_state <= ACTIVATE;
				else
					generate_next_state <= GENERATE_SIZE;
				end if;
			
			when ACTIVATE =>
				generate_next_state <= WAIT1;
				
			when WAIT1 =>
				generate_next_state <= WAIT2;
			
			when WAIT2 =>
				generate_next_state <= WAIT3;
				
			when WAIT3 =>
				generate_next_state <= WAIT4;
				
			when WAIT4 =>
				generate_next_state <= WAIT5;
				
			when WAIT5 =>
				if (SENDERS_FREE_IN = "00000000") then
					generate_next_state <= IDLE;
				else
					generate_next_state <= WAIT5;
				end if;
		
		end case;
		
	end process GENERATE_MACHINE;
	
	generate_en <= '1' when generate_current_state = GENERATE_SENDER or generate_current_state = GENERATE_SIZE else '0';
	
	GENERATE_T_PROC : process(CLKSYS_IN)
	begin
		if rising_edge(CLKSYS_IN) then
			if (generate_current_state /= GENERATE_SENDER and generate_current_state /= GENERATE_SIZE and generate_current_state /= ACTIVATE) then
				generate_t <= "00000000";
			elsif (generate_current_state = GENERATE_SENDER) and (generate_t = "00000000") then
				if (values(31 downto 28) = x"f") then
					generate_t(0) <= '1';
				elsif (values(27 downto 24) = x"f") then
					generate_t(1) <= '1';
				elsif (values(23 downto 20) = x"f") then
					generate_t(2) <= '1';
				elsif (values(19 downto 16) = x"f") then
					generate_t(3) <= '1';
				elsif (values(15 downto 12) = x"f") then
					generate_t(4) <= '1';
				elsif (values(11 downto 8) = x"f") then
					generate_t(5) <= '1';
				elsif (values(7 downto 4) = x"f") then
					generate_t(6) <= '1';
				elsif (values(3 downto 0) = x"f") then
					generate_t(7) <= '1';
				else
					generate_t(7 downto 0) <= "00000000";
				end if;
			end if;
		end if;
	end process GENERATE_T_PROC;
	
	GENERATE_OUT_PROC : process(CLKSYS_IN)
	begin
		if rising_edge(CLKSYS_IN) then
			if (RESET = '1') or (generate_current_state /= ACTIVATE) then
				GENERATE_OUT <= "00000000";
			elsif (generate_current_state = ACTIVATE) then
				GENERATE_OUT <= generate_t;
			end if;
		end if;
	end process GENERATE_OUT_PROC;
	
	SIZE_PROC : process(CLKSYS_IN)
	begin
		if rising_edge(CLKSYS_IN) then
			if (RESET = '1') or (generate_current_state = IDLE) then
				SIZE_OUT <= (others  => '0');
			elsif (generate_current_state = GENERATE_SIZE) then
				SIZE_OUT <= "00000000" & values(11 downto 8) & "1111";
			end if;
		end if;
	end process SIZE_PROC;

	TIMER_PROC : process(CLKSYS_IN)
	begin
		if rising_edge(CLKSYS_IN) then
			if (RESET = '1') then
				timer <= (others => '0');
			else
				timer <= timer + x"1";
			end if;
		end if;
	end process TIMER_PROC;
	
	TIMESTAMP_OUT <= timer;
	
	DEST_ADDR_OUT <= (others => '0');

end architecture CNTester_Main;
