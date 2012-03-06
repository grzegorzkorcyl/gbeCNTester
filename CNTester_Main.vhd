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
		
		GENERATE_OUT    : out std_logic_vector(2 downto 0);
		TIMESTAMP_OUT   : out std_logic_vector(31 downto 0);
		DEST_ADDR_OUT   : out std_logic_vector(15 downto 0);
		SIZE_OUT        : out std_logic_vector(15 downto 0);
		
		SENDERS_FREE_IN : in std_logic_vector(2 downto 0)
	);
end entity CNTester_Main;

architecture CNTester_Main of CNTester_Main is

type generate_states is (IDLE, GENERATE_SENDER, GENERATE_SIZE, ACTIVATE);
signal generate_current_state, generate_next_state : generate_states;

signal generate_en : std_logic;
signal values : std_logic_vector(31 downto 0);

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
			if (RESET = '1') and (LINK_OK_IN = '0') then
				generate_current_state <= IDLE;
			else
				generate_current_state <= generate_next_state;
			end if;
		end if;
	end process GENERATE_MACHINE_PROC;
	
	GENERATE_MACHINE : process(generate_current_state, SENDERS_FREE_IN)
	begin
	
		case (generate_current_state) is
		
			when IDLE =>
				if (SENDERS_FREE_IN = "000") then
					generate_next_state <= GENERATE_SENDER;
				else
					generate_next_state <= IDLE;
				end if;
			
			when GENERATE_SENDER =>
				generate_next_state <= GENERATE_SIZE;
				
			when GENERATE_SIZE =>
				generate_next_state <= ACTIVATE;
			
			when ACTIVATE =>
				generate_next_state <= IDLE;
		
		end case;
		
	end process GENERATE_MACHINE;
	
	generate_en <= '1' when generate_current_state = GENERATE_SENDER or generate_current_state = GENERATE_SIZE else '0';
	
	GENERATE_OUT(0) <= '1' when values(20) = '1' and generate_current_state = GENERATE_SIZE else '0';
	GENERATE_OUT(1) <= '1' when values(6) = '1' and generate_current_state = GENERATE_SIZE else '0';
	GENERATE_OUT(2) <= '1' when values(7) = '1' and generate_current_state = GENERATE_SIZE else '0';
	
	SIZE_PROC : process(CLKSYS_IN)
	begin
		if rising_edge(CLKSYS_IN) then
			if (RESET = '1') then
				SIZE_OUT <= (others  => '0');
			elsif (generate_current_state = GENERATE_SIZE) then
				SIZE_OUT <= "0000" & values(7 downto 0) & "1111";
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
