LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

use work.trb_net_gbe_components.all;

use std.textio.all;
use work.txt_util.all;

entity stats_testbench is
end entity stats_testbench;

architecture RTL of stats_testbench is
	
	
	signal clk_100_i, CLK_GPLL_RIGHT, reset_i, GSR_N, start_stat : std_logic;
	
	signal module_select : std_logic_vector(7 downto 0);
	
begin

LINK_STATS : CNTester_module
generic map( g_GENERATE_STAT => 1 )
port map(
	CLKSYS_IN  => clk_100_i,
	CLKGBE_IN  => CLK_GPLL_RIGHT,
	RESET      => reset_i,
	GSR_N      => GSR_N,
	LINK_OK_OUT => open,
	
	-- serdes io
	SD_RX_CLK_IN                => CLK_GPLL_RIGHT,
	SD_TX_DATA_OUT              => open,
	SD_TX_KCNTL_OUT             => open,
	SD_TX_CORRECT_DISP_OUT      => open,
	SD_RX_DATA_IN               => (others => '0'),
	SD_RX_KCNTL_IN              => '0',
	SD_RX_DISP_ERROR_IN         => '0',
	SD_RX_CV_ERROR_IN           => '0',
	SD_RX_SERDES_RST_OUT        => open,
	SD_RX_PCS_RST_OUT           => open,
	SD_TX_PCS_RST_OUT			=> open,
	SD_RX_LOS_IN				=> '0',
	SD_SIGNAL_DETECTED_IN		=> '1',
	SD_RX_CDR_IN				=> '0',
	SD_TX_PLL_LOL_IN            => '0',
	SD_QUAD_RST_OUT             => open,
	SD_XMIT_OUT                 => open,
	
	MODULE_SELECT_OUT     		=> module_select,
	MODULE_RD_EN_OUT      		=> open,
	MODULE_DATA_IN        		=> module_data,
	STOP_TRANSMISSION_OUT 		=> open,
	START_STAT_IN         	 	=> start_stat,
	
	MODULE_DATA_OUT             => open,
	MODULE_RD_EN_IN             => '0',
	MODULE_SELECTED_IN          => '0',
	MODULE_FULL_OUT             => open,
		
	TEST_PORT_IN         => (others => '0'),
	TEST_PORT_OUT        => open,
	
	MAC_ADDR_IN          => x"123456789020",
	TIMESTAMP_IN         => (others => '0'),
	DEST_ADDR_IN         => (others => '0'),
	GENERATE_PACKET_IN   => '0',
	SIZE_IN              => (others => '0'),
	BUSY_OUT             => open
);


CLK_PROC : process
begin
	clk_100_i <= '0'; wait for 5 ns;
	clk_100_i <= '1'; wait for 5 ns;
end process CLK_PROC;

CLK_125_PROC : process
begin
	CLK_GPLL_RIGHT <= '0'; wait for 4 ns;
	CLK_GPLL_RIGHT <= '1'; wait for 4 ns;
end process CLK_125_PROC;

GSR_N <= not reset_i;

TESTBENCH_PROC : process
begin

	
	wait for 50 ns;
	reset_i <= '1';
	start_stat <= '0';
	wait for 200 ns;
	
	reset_i <= '0';
	
	wait for 100 ns;
	
	wait until rising_edge(clk_100_i);
	start_stat <= '1';
	wait until rising_edge(clk_100_i);
	start_stat <= '0';
	
	wait;
	
end process TESTBENCH_PROC;

end architecture RTL;
