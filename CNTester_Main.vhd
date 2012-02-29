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
		CLKSYS_IN : in std_logic;
		RESET     : in std_logic;
		
		GENERATE_OUT  : out std_logic_vector(2 downto 0);
		TIMESTAMP_OUT : out std_logic_vector(31 downto 0);
		DEST_ADDR_OUT : out std_logic_vector(15 downto 0)
	);
end entity CNTester_Main;

architecture CNTester_Main of CNTester_Main is
	
begin

	GENERATE_OUT  <= '0';
	TIMESTAMP_OUT <= (others  => '0');
	DEST_ADDR_OUT <= (others  => '0');

end architecture CNTester_Main;
