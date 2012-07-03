library ieee;
use ieee.std_logic_1164.all;

use work.trb_net_gbe_components.all;

entity main_testbench is
end entity main_testbench;

architecture RTL of main_testbench is


signal clk, rst : std_logic;
signal senders : std_logic_vector(7 downto 0);
	
begin

main : CNTester_Main
	port map(
		CLKSYS_IN       => clk,
		RESET           => rst,
		LINK_OK_IN      => '1',
		
		GENERATE_OUT    => open,
		TIMESTAMP_OUT   => open,
		DEST_ADDR_OUT   => open,
		SIZE_OUT        => open,
		
		SENDERS_FREE_IN => senders
	);
	
	
CLK_PROC : process
begin
	clk <= '1'; wait for 5 ns;
	clk <= '0'; wait for 5 ns;
end process CLK_PROC;

TESTBENCH_PROC : process
begin
	
	wait for 100 ns;
	rst <= '1';
	senders <= "00000000";
	wait for 100 ns;
	rst <= '0';
	wait for 100 ns;
	
	
	
	wait;
	
end process TESTBENCH_PROC;

end architecture RTL;
