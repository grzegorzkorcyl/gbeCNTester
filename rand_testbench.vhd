LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

use work.trb_net_gbe_components.all;

use std.textio.all;
use work.txt_util.all;


entity rand_testbench is
  generic (
           log_file:       string  := "rand.log"
  );
end entity rand_testbench;

architecture RTL of rand_testbench is

component lfsr is
    port (
        Clk: in  std_logic; 
        Enb: in  std_logic; 
        Rst: in  std_logic; 
        Dout: out  std_logic_vector(31 downto 0));
end component;

signal clk, rst : std_logic;
signal rand     : std_logic_vector(31 downto 0);

file l_file: TEXT open write_mode is log_file;
	
signal temp : std_logic_vector(31 downto 0); 
signal write_lock : std_logic;
signal condition : std_logic;
	
begin



--main : CNTester_random
--	port map (
--      CLK_IN      => clk,
--      GENERATE_IN => '1',
--      RESET       => rst,
--      RANDOM_OUT  => rand            
--    );
    
main : lfsr
    port map(
        Clk => clk, 
        Enb => '1', 
        Rst => rst, 
        Dout => rand
        );

clk_proc : process
begin
	clk <= '1'; wait for 5 ns;
	clk <= '0'; wait for 5 ns;
end process clk_proc;


TESTBENCH_PROC : process

variable l: line;

begin

	wait for 100 ns;
	rst <= '1';
	wait for 100 ns;
	rst <= '0';
	
	
	while true loop
		wait until rising_edge(clk);
		
			write(l, hstr(rand));
			writeline(l_file, l);
		
	end loop;
	
	wait;
	
end process;
 
end architecture RTL;
