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

signal lfsr: std_logic_vector (31 downto 0); 
signal d0 : std_logic;

begin 

  d0 <= lfsr(17) xnor lfsr(15);

--  process(lfsr) begin 
--    if(lfsr = x"359") then 
--      lfsr_equal <= '1';
--    else 
--      lfsr_equal <= '0';
--    end if;
--  end process; 

    process (CLK_IN,RESET) begin 
      if (RESET = '1') then 
        lfsr <= (others => '0');
      elsif (CLK_IN'EVENT and CLK_IN = '1') then
      	if (GENERATE_IN = '1') then
	    	lfsr <= lfsr(30 downto 0) & d0;
	    end if;
      end if; 
    end process;
    
    RANDOM_OUT <= lfsr;

end architecture CNTester_random;