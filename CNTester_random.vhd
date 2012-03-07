library ieee;
use ieee.std_logic_1164.all;

entity CNTester_random is
	port (
      CLK_IN      : in std_logic;
      RESET       : in std_logic;
      GENERATE_IN : in std_logic;
      RANDOM_OUT  : out std_logic_vector (31 downto 0)            
    );
end entity CNTester_random;

architecture CNTester_random of CNTester_random is

component lfsr is
    port (
        Clk: in  std_logic; 
        Enb: in  std_logic; 
        Rst: in  std_logic; 
        Dout: out  std_logic_vector(31 downto 0));
end component;

begin 

main : lfsr
    port map(
        Clk => CLK_IN, 
        Enb => GENERATE_IN, 
        Rst => RESET, 
        Dout => RANDOM_OUT
        );

end architecture CNTester_random;