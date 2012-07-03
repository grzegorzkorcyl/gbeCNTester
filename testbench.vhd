LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

use work.trb_net_gbe_components.all;

use std.textio.all;
use work.txt_util.all;

entity testbench is
  generic (
           log_file:       string  := "main.log"
  );
end entity testbench;

architecture RTL of testbench is
	
signal clk_100, clk_125, reset, reset_n : std_logic;
signal senders_free, activate_sender : std_logic_vector(7 downto 0);
signal timestamp : std_logic_vector(31 downto 0);
signal dest_addr, size : std_logic_vector(15 downto 0);
signal temp : std_logic_vector(31 downto 0); 
signal write_lock : std_logic;

file l_file: TEXT open write_mode is log_file;
signal sd_rx_clk, sd_quad_rst : std_logic_vector(7 downto 0);
signal sd_tx_k, sd_xmit, sd_tx_disp, sd_rx_k, sd_rx_disp, sd_cv_err, sd_rx_serdes_rst, sd_tx_pcs_rst, sd_rx_pcs_rst, sd_rx_los, sd_rx_cdr, sd_signal_detected : std_logic_vector(3 downto 0);

type arr is array(7 downto 0) of std_logic_vector(7 downto 0);
signal sd_tx_data, sd_rx_data : arr;

signal sd_tx_pll_lol, sd1_quad_rst : std_logic;

signal module_rd_en, stop_trans, start_stat : std_logic;
signal module_select : std_logic_vector(7 downto 0);
signal module_data : std_logic_vector(71 downto 0);
signal module_full : std_logic_vector(7 downto 0);

type arr2 is array(7 downto 0) of std_logic_vector(71 downto 0);
signal module_data_i : arr2;

begin

MAIN : CNTester_Main
	port map (
		CLKSYS_IN  => clk_100,
		RESET      => reset,
		LINK_OK_IN => '1',
		
		GENERATE_OUT    => activate_sender,
		TIMESTAMP_OUT   => timestamp,
		DEST_ADDR_OUT   => dest_addr,
		SIZE_OUT        => size,
		
		SENDERS_FREE_IN => senders_free
	);


LINK_1 : CNTester_module
generic map( g_GENERATE_STAT => 0)
	port map(
		CLKSYS_IN  => clk_100,
		CLKGBE_IN  => clk_125,
		RESET      => reset,
		GSR_N      => reset_n,
		
		-- serdes io
		SD_RX_CLK_IN                => sd_rx_clk(0),
		SD_TX_DATA_OUT              => sd_tx_data(0),
		SD_TX_KCNTL_OUT             => sd_tx_k(0),
		SD_TX_CORRECT_DISP_OUT      => sd_tx_disp(0),
		SD_RX_DATA_IN               => sd_rx_data(0),
		SD_RX_KCNTL_IN              => sd_rx_k(0),
		SD_RX_DISP_ERROR_IN         => sd_rx_disp(0),
		SD_RX_CV_ERROR_IN           => sd_cv_err(0),
		SD_RX_SERDES_RST_OUT        => sd_rx_serdes_rst(0),
		SD_RX_PCS_RST_OUT           => sd_rx_pcs_rst(0),
		SD_TX_PCS_RST_OUT			=> sd_tx_pcs_rst(0),
		SD_RX_LOS_IN				=> sd_rx_los(0),
		SD_SIGNAL_DETECTED_IN		=> sd_signal_detected(0),
		SD_RX_CDR_IN				=> sd_rx_cdr(0),
		SD_TX_PLL_LOL_IN            => sd_tx_pll_lol,
		SD_QUAD_RST_OUT             => sd_quad_rst(0),
		
		-- not used in case of data link
		MODULE_SELECT_OUT     => open,
		MODULE_RD_EN_OUT      => open,
		MODULE_DATA_IN        => (others => '0'),
		STOP_TRANSMISSION_OUT => open,
		START_STAT_IN         => '0',
		-- end of not used
		
		MODULE_DATA_OUT       => module_data_i(0),
		MODULE_RD_EN_IN       => module_rd_en,
		MODULE_SELECTED_IN    => module_select(0),
		MODULE_FULL_OUT       => module_full(0),
		
		MAC_ADDR_IN          => x"012345678914",
		TIMESTAMP_IN         => timestamp,
		DEST_ADDR_IN         => dest_addr,
		GENERATE_PACKET_IN   => activate_sender(0),
		SIZE_IN              => size,
		BUSY_OUT             => senders_free(0)
	);
	
	LINK_2 : CNTester_module
	generic map( g_GENERATE_STAT => 0)
port map(
	CLKSYS_IN  => clk_100,
	CLKGBE_IN  => clk_125,
	RESET      => reset,
	GSR_N      => reset_n,
	LINK_OK_OUT => open,
	
	-- serdes io
	SD_RX_CLK_IN                => sd_rx_clk(1),
	SD_TX_DATA_OUT              => sd_tx_data(1),
	SD_TX_KCNTL_OUT             => sd_tx_k(1),
	SD_TX_CORRECT_DISP_OUT      => sd_tx_disp(1),
	SD_RX_DATA_IN               => sd_rx_data(1),
	SD_RX_KCNTL_IN              => sd_rx_k(1),
	SD_RX_DISP_ERROR_IN         => sd_rx_disp(1),
	SD_RX_CV_ERROR_IN           => sd_cv_err(1),
	SD_RX_SERDES_RST_OUT        => sd_rx_serdes_rst(1),
	SD_RX_PCS_RST_OUT           => sd_rx_pcs_rst(1),
	SD_TX_PCS_RST_OUT			=> sd_tx_pcs_rst(1),
	SD_RX_LOS_IN				=> sd_rx_los(1),
	SD_SIGNAL_DETECTED_IN		=> sd_signal_detected(1),
	SD_RX_CDR_IN				=> sd_rx_cdr(1),
	SD_TX_PLL_LOL_IN            => sd_tx_pll_lol,
	SD_QUAD_RST_OUT             => sd_quad_rst(1),
	SD_XMIT_OUT                 => sd_xmit(1),
	
	-- not used in case of data link
	MODULE_SELECT_OUT     => open,
	MODULE_RD_EN_OUT      => open,
	MODULE_DATA_IN        => (others => '0'),
	STOP_TRANSMISSION_OUT => open,
	START_STAT_IN         => '0',
	-- end of not used
	
	MODULE_DATA_OUT       => module_data_i(1),
	MODULE_RD_EN_IN       => module_rd_en,
	MODULE_SELECTED_IN    => module_select(1),
	MODULE_FULL_OUT       => module_full(1),
	
	MAC_ADDR_IN          => x"012345678913",
	TIMESTAMP_IN         => timestamp,
	DEST_ADDR_IN         => dest_addr,
	GENERATE_PACKET_IN   => activate_sender(1),
	SIZE_IN              => size,
	BUSY_OUT             => senders_free(1)
);

LINK_3 : CNTester_module
generic map( g_GENERATE_STAT => 1)
port map(
	CLKSYS_IN  => clk_100,
	CLKGBE_IN  => clk_125,
	RESET      => reset,
	GSR_N      => reset_n,
	LINK_OK_OUT => open,
	
	-- serdes io
	SD_RX_CLK_IN                => sd_rx_clk(2),
	SD_TX_DATA_OUT              => sd_tx_data(2),
	SD_TX_KCNTL_OUT             => sd_tx_k(2),
	SD_TX_CORRECT_DISP_OUT      => sd_tx_disp(2),
	SD_RX_DATA_IN               => sd_rx_data(2),
	SD_RX_KCNTL_IN              => sd_rx_k(2),
	SD_RX_DISP_ERROR_IN         => sd_rx_disp(2),
	SD_RX_CV_ERROR_IN           => sd_cv_err(2),
	SD_RX_SERDES_RST_OUT        => sd_rx_serdes_rst(2),
	SD_RX_PCS_RST_OUT           => sd_rx_pcs_rst(2),
	SD_TX_PCS_RST_OUT			=> sd_tx_pcs_rst(2),
	SD_RX_LOS_IN				=> sd_rx_los(2),
	SD_SIGNAL_DETECTED_IN		=> sd_signal_detected(2),
	SD_RX_CDR_IN				=> sd_rx_cdr(2),
	SD_TX_PLL_LOL_IN            => sd_tx_pll_lol,
	SD_QUAD_RST_OUT             => sd_quad_rst(2),
	SD_XMIT_OUT                 => sd_xmit(2),
	
	MODULE_SELECT_OUT     => module_select,
	MODULE_RD_EN_OUT      => module_rd_en,
	MODULE_DATA_IN        => module_data,
	STOP_TRANSMISSION_OUT => stop_trans,
	START_STAT_IN         => start_stat,
	
	-- not used in case of stat link
	MODULE_DATA_OUT       => open,
	MODULE_RD_EN_IN       => '0',
	MODULE_SELECTED_IN     => '0',
	MODULE_FULL_OUT       => open,
	-- end of not used
	
	MAC_ADDR_IN          => x"012345678912",
	TIMESTAMP_IN         => timestamp,
	DEST_ADDR_IN         => dest_addr,
	GENERATE_PACKET_IN   => activate_sender(2),
	SIZE_IN              => size,
	BUSY_OUT             => senders_free(2)
);

start_stat <= '1' when module_full /= x"00" else '0';

senders_free(7 downto 3) <= (others => '0');

SERDES1 : serdes4ch
 port map(
------------------
-- CH0 --
    hdinp_ch0			=> '0',
    hdinn_ch0			=> '1',
    hdoutp_ch0			=> open,
    hdoutn_ch0			=> open,
    rxiclk_ch0			=> sd_rx_clk(0),
    txiclk_ch0			=> clk_125,
    rx_full_clk_ch0		=> sd_rx_clk(0),
    rx_half_clk_ch0		=> open,
    tx_full_clk_ch0		=> open,
    tx_half_clk_ch0		=> open,
    fpga_rxrefclk_ch0	=> clk_125,
    txdata_ch0			=> sd_tx_data(0),
    tx_k_ch0			=> sd_tx_k(0),
    xmit_ch0			=> sd_xmit(0),
    tx_disp_correct_ch0 => sd_tx_disp(0),
    rxdata_ch0			=> sd_rx_data(0),
    rx_k_ch0			=> sd_rx_k(0),
    rx_disp_err_ch0		=> sd_rx_disp(0),
    rx_cv_err_ch0		=> sd_cv_err(0),
    rx_serdes_rst_ch0_c => sd_rx_serdes_rst(0),
    sb_felb_ch0_c       => '0',
    sb_felb_rst_ch0_c   => '0',
    tx_pcs_rst_ch0_c    => sd_tx_pcs_rst(0),
    tx_pwrup_ch0_c      => '1',
    rx_pcs_rst_ch0_c    => sd_rx_pcs_rst(0),
    rx_pwrup_ch0_c    	=> '1',
    rx_los_low_ch0_s    => sd_rx_los(0),
    lsm_status_ch0_s    => sd_signal_detected(0),
    rx_cdr_lol_ch0_s    => sd_rx_cdr(0),
-- CH1 --
    hdinp_ch1			=> '0',
    hdinn_ch1			=> '1',
    hdoutp_ch1			=> open,
    hdoutn_ch1			=> open,
    rxiclk_ch1			=> sd_rx_clk(1),
    txiclk_ch1			=> clk_125,
    rx_full_clk_ch1		=> sd_rx_clk(1),
    rx_half_clk_ch1		=> open,
    tx_full_clk_ch1		=> open,
    tx_half_clk_ch1		=> open,
    fpga_rxrefclk_ch1	=> clk_125,
    txdata_ch1			=> sd_tx_data(1),
    tx_k_ch1			=> sd_tx_k(1),
    xmit_ch1			=> sd_xmit(1),
    tx_disp_correct_ch1 => sd_tx_disp(1),
    rxdata_ch1			=> sd_rx_data(1),
    rx_k_ch1			=> sd_rx_k(1),
    rx_disp_err_ch1		=> sd_rx_disp(1),
    rx_cv_err_ch1		=> sd_cv_err(1),
    rx_serdes_rst_ch1_c => sd_rx_serdes_rst(1),
    sb_felb_ch1_c       => '0',
    sb_felb_rst_ch1_c   => '0',
    tx_pcs_rst_ch1_c    => sd_tx_pcs_rst(1),
    tx_pwrup_ch1_c      => '1',
    rx_pcs_rst_ch1_c    => sd_rx_pcs_rst(1),
    rx_pwrup_ch1_c    	=> '1',
    rx_los_low_ch1_s    => sd_rx_los(1),
    lsm_status_ch1_s    => sd_signal_detected(1),
    rx_cdr_lol_ch1_s    => sd_rx_cdr(1),
-- CH2 --
    hdinp_ch2			=> '0',
    hdinn_ch2			=> '1',
    hdoutp_ch2			=> open,
    hdoutn_ch2			=> open,
    rxiclk_ch2			=> sd_rx_clk(2),
    txiclk_ch2			=> clk_125,
    rx_full_clk_ch2		=> sd_rx_clk(2),
    rx_half_clk_ch2		=> open,
    tx_full_clk_ch2		=> open,
    tx_half_clk_ch2		=> open,
    fpga_rxrefclk_ch2	=> clk_125,
    txdata_ch2			=> sd_tx_data(2),
    tx_k_ch2			=> sd_tx_k(2),
    xmit_ch2			=> sd_xmit(2),
    tx_disp_correct_ch2 => sd_tx_disp(2),
    rxdata_ch2			=> sd_rx_data(2),
    rx_k_ch2			=> sd_rx_k(2),
    rx_disp_err_ch2		=> sd_rx_disp(2),
    rx_cv_err_ch2		=> sd_cv_err(2),
    rx_serdes_rst_ch2_c => sd_rx_serdes_rst(2),
    sb_felb_ch2_c       => '0',
    sb_felb_rst_ch2_c   => '0',
    tx_pcs_rst_ch2_c    => sd_tx_pcs_rst(2),
    tx_pwrup_ch2_c      => '1',
    rx_pcs_rst_ch2_c    => sd_rx_pcs_rst(2),
    rx_pwrup_ch2_c    	=> '1',
    rx_los_low_ch2_s    => sd_rx_los(2),
    lsm_status_ch2_s    => sd_signal_detected(2),
    rx_cdr_lol_ch2_s    => sd_rx_cdr(2),
-- CH3 --
    hdinp_ch3			=> '0',
    hdinn_ch3			=> '1',
    hdoutp_ch3			=> open,
    hdoutn_ch3			=> open,
    rxiclk_ch3			=> sd_rx_clk(3),
    txiclk_ch3			=> clk_125,
    rx_full_clk_ch3		=> sd_rx_clk(3),
    rx_half_clk_ch3		=> open,
    tx_full_clk_ch3		=> open,
    tx_half_clk_ch3		=> open,
    fpga_rxrefclk_ch3	=> clk_125,
    txdata_ch3			=> sd_tx_data(3),
    tx_k_ch3			=> sd_tx_k(3),
    xmit_ch3			=> sd_xmit(3),
    tx_disp_correct_ch3 => sd_tx_disp(3),
    rxdata_ch3			=> sd_rx_data(3),
    rx_k_ch3			=> sd_rx_k(3),
    rx_disp_err_ch3		=> sd_rx_disp(3),
    rx_cv_err_ch3		=> sd_cv_err(3),
    rx_serdes_rst_ch3_c => sd_rx_serdes_rst(3),
    sb_felb_ch3_c       => '0',
    sb_felb_rst_ch3_c   => '0',
    tx_pcs_rst_ch3_c    => sd_tx_pcs_rst(3),
    tx_pwrup_ch3_c      => '1',
    rx_pcs_rst_ch3_c    => sd_rx_pcs_rst(3),
    rx_pwrup_ch3_c    	=> '1',
    rx_los_low_ch3_s    => sd_rx_los(3),
    lsm_status_ch3_s    => sd_signal_detected(3),
    rx_cdr_lol_ch3_s    => sd_rx_cdr(3),
---- Miscillaneous ports
    fpga_txrefclk       => clk_125,
    tx_serdes_rst_c     => '0',
    tx_pll_lol_qd_s     => sd_tx_pll_lol,
    tx_sync_qd_c        => '0',
    rst_qd_c            => sd1_quad_rst,
    serdes_rst_qd_c     => '0'
    );
	
	
CLK_100_PROC : process
begin
	clk_100 <= '1'; wait for 5 ns;
	clk_100 <= '0'; wait for 5 ns;
end process CLK_100_PROC;

CLK_125_PROC : process
begin
	clk_125 <= '1'; wait for 4 ns;
	clk_125 <= '0'; wait for 4 ns;
end process CLK_125_PROC;

reset_n <= not reset;

TESTBENCH_PROC : process
begin
	
	wait for 100 ns;
	reset <= '1';
	wait for 100 ns;
	reset <= '0';
	
	wait;
	
end process TESTBENCH_PROC;



LOG_PROC : process
variable l : line;

begin

	while true loop
		wait until rising_edge(clk_100);
		if (senders_free = "000") then
			temp <= temp + x"1";
			write_lock <= '0';
		else
			temp <= (others => '0');
			write_lock <= '1';
		end if;
		
		if senders_free /= "000" and write_lock = '0' then
			write(l, hstr(temp));
			writeline(l_file, l);
			write_lock <= '1';
		end if;
	end loop;

end process LOG_PROC;



		

end architecture RTL;
