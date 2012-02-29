library ieee;
use ieee.std_logic_1164.all;

entity CNTester_random is
    generic ( width : integer :=  32 ); 
	port (
      CLK_IN      : in std_logic;
      GENERATE_IN : in std_logic;
      RANDOM_OUT  : out std_logic_vector (width-1 downto 0)   --output vector            
    );
end entity CNTester_random;

architecture CNTester_random of CNTester_random is
	
begin

RAND_PROC : process(CLK_IN)
	variable rand_temp : std_logic_vector(width-1 downto 0):=(width-1 => '1',others => '0');
	variable temp : std_logic := '0';
	
begin
	if(rising_edge(CLK_IN)) then
		if (GENERATE_IN = '1') then
			temp := rand_temp(width-1) xor rand_temp(width-2);
			rand_temp(width-1 downto 1) := rand_temp(width-2 downto 0);
			rand_temp(0) := temp;
		end if;
	end if;

	random_num <= rand_temp;
end process;

end architecture CNTester_random;