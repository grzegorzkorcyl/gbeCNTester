library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.trb_net_std.all;

package trb3_components is



component pll_in200_out100
  port (
    CLK: in std_logic; 
    CLKOP: out std_logic; --100 MHz
    CLKOK: out std_logic; --200 MHz
    LOCK: out std_logic
    );
  end component;
  
  
end package;