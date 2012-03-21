library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb3_components.all;
use work.trb_net_gbe_components.all;



entity trb3_central is
  generic (
    USE_ETHERNET : integer range c_NO to c_YES := c_YES
  );
  port(
    --Clocks
    CLK_EXT                        : in  std_logic_vector(4 downto 3); --from RJ45
    CLK_GPLL_LEFT                  : in  std_logic;  --Clock Manager 2/9, 200 MHz  <-- MAIN CLOCK
    CLK_GPLL_RIGHT                 : in  std_logic;  --Clock Manager 1/9, 125 MHz  <-- for GbE
    CLK_PCLK_LEFT                  : in  std_logic;  --Clock Fan-out, 200/400 MHz 
    CLK_PCLK_RIGHT                 : in  std_logic;  --Clock Fan-out, 200/400 MHz 

    --Trigger
    TRIGGER_LEFT                   : in  std_logic;  --left side trigger input from fan-out
    TRIGGER_RIGHT                  : in  std_logic;  --right side trigger input from fan-out
    TRIGGER_EXT                    : in  std_logic_vector(4 downto 2); --additional trigger from RJ45
    TRIGGER_OUT                    : out std_logic;  --trigger to second input of fan-out
    
    --Serdes
    CLK_SERDES_INT_LEFT            : in  std_logic;  --Clock Manager 2/0, 200 MHz, only in case of problems
    CLK_SERDES_INT_RIGHT           : in  std_logic;  --Clock Manager 1/0, off, 125 MHz possible
    
    --SFP
    SFP_RX_P                       : in  std_logic_vector(16 downto 1); 
    SFP_RX_N                       : in  std_logic_vector(16 downto 1); 
    SFP_TX_P                       : out std_logic_vector(16 downto 1); 
    SFP_TX_N                       : out std_logic_vector(16 downto 1); 
    SFP_TX_FAULT                   : in  std_logic_vector(8 downto 1); --TX broken
    SFP_RATE_SEL                   : out std_logic_vector(8 downto 1); --not supported by our SFP
    SFP_LOS                        : in  std_logic_vector(8 downto 1); --Loss of signal
    SFP_MOD0                       : in  std_logic_vector(8 downto 1); --SFP present
    SFP_MOD1                       : in  std_logic_vector(8 downto 1); --I2C interface
    SFP_MOD2                       : in  std_logic_vector(8 downto 1); --I2C interface
    SFP_TXDIS                      : out std_logic_vector(8 downto 1); --disable TX
    
    --Clock and Trigger Control
    TRIGGER_SELECT                 : out std_logic;  --trigger select for fan-out. 0: external, 1: signal from FPGA5
    CLOCK_SELECT                   : out std_logic;  --clock select for fan-out. 0: 200MHz, 1: external from RJ45
    CLK_MNGR1_USER                 : inout std_logic_vector(3 downto 0); --I/O lines to clock manager 1
    CLK_MNGR2_USER                 : inout std_logic_vector(3 downto 0); --I/O lines to clock manager 1
    
    --Inter-FPGA Communication
    FPGA1_COMM                     : inout std_logic_vector(11 downto 0);
    FPGA2_COMM                     : inout std_logic_vector(11 downto 0);
    FPGA3_COMM                     : inout std_logic_vector(11 downto 0);
    FPGA4_COMM                     : inout std_logic_vector(11 downto 0); 
                                    -- on all FPGAn_COMM:  --Bit 0/1 output, serial link TX active
                                                           --Bit 2/3 input, serial link RX active
                                                           --others yet undefined
    FPGA1_TTL                      : inout std_logic_vector(3 downto 0);
    FPGA2_TTL                      : inout std_logic_vector(3 downto 0);
    FPGA3_TTL                      : inout std_logic_vector(3 downto 0);
    FPGA4_TTL                      : inout std_logic_vector(3 downto 0);
                                    --only for not timing-sensitive signals

    --Communication to small addons
    FPGA1_CONNECTOR                : inout std_logic_vector(7 downto 0); --Bit 2-3: LED for SFP3/4
    FPGA2_CONNECTOR                : inout std_logic_vector(7 downto 0); --Bit 2-3: LED for SFP7/8
    FPGA3_CONNECTOR                : inout std_logic_vector(7 downto 0); --Bit 0-1: LED for SFP5/6 
    FPGA4_CONNECTOR                : inout std_logic_vector(7 downto 0); --Bit 0-1: LED for SFP1/2
                                                                         --Bit 0-3 connected to LED by default, two on each side
                                                                         
    --Big AddOn connector
    ADDON_RESET                    : out std_logic; --reset signal to AddOn
    ADDON_TO_TRB_CLK               : in  std_logic; --Clock from AddOn, connected to PCLK input
    TRB_TO_ADDON_CLK               : out std_logic; --Clock sent to AddOn
    ADO_LV                         : inout std_logic_vector(61 downto 0);
    ADO_TTL                        : inout std_logic_vector(46 downto 0);
    FS_PE                          : inout std_logic_vector(17 downto 0);
    
    --Flash ROM & Reboot
    FLASH_CLK                      : out std_logic;
    FLASH_CS                       : out std_logic;
    FLASH_CIN                      : out std_logic;
    FLASH_DOUT                     : in  std_logic;
    PROGRAMN                       : out std_logic := '1'; --reboot FPGA
    
    --Misc
    ENPIRION_CLOCK                 : out std_logic;  --Clock for power supply, not necessary, floating
    TEMPSENS                       : inout std_logic; --Temperature Sensor
    LED_CLOCK_GREEN                : out std_logic;
    LED_CLOCK_RED                  : out std_logic;
    LED_GREEN                      : out std_logic;
    LED_ORANGE                     : out std_logic; 
    LED_RED                        : out std_logic;
    LED_TRIGGER_GREEN              : out std_logic;
    LED_TRIGGER_RED                : out std_logic; 
    LED_YELLOW                     : out std_logic;

    --Test Connectors
    TEST_LINE                      : out std_logic_vector(31 downto 0)
    );
    
    attribute syn_useioff : boolean;
    --no IO-FF for LEDs relaxes timing constraints
    attribute syn_useioff of LED_CLOCK_GREEN    : signal is false;
    attribute syn_useioff of LED_CLOCK_RED      : signal is false;
    attribute syn_useioff of LED_GREEN          : signal is false;
    attribute syn_useioff of LED_ORANGE         : signal is false;
    attribute syn_useioff of LED_RED            : signal is false;
    attribute syn_useioff of LED_TRIGGER_GREEN  : signal is false;
    attribute syn_useioff of LED_TRIGGER_RED    : signal is false;
    attribute syn_useioff of LED_YELLOW         : signal is false;
    attribute syn_useioff of FPGA1_TTL          : signal is false;
    attribute syn_useioff of FPGA2_TTL          : signal is false;
    attribute syn_useioff of FPGA3_TTL          : signal is false;
    attribute syn_useioff of FPGA4_TTL          : signal is false;
    attribute syn_useioff of SFP_TXDIS          : signal is false;
    
    --important signals _with_ IO-FF
    attribute syn_useioff of FLASH_CLK          : signal is true;
    attribute syn_useioff of FLASH_CS           : signal is true;
    attribute syn_useioff of FLASH_CIN          : signal is true;
    attribute syn_useioff of FLASH_DOUT         : signal is true;
    attribute syn_useioff of FPGA1_COMM         : signal is true;
    attribute syn_useioff of FPGA2_COMM         : signal is true;
    attribute syn_useioff of FPGA3_COMM         : signal is true;
    attribute syn_useioff of FPGA4_COMM         : signal is true;


end entity;

architecture trb3_central_arch of trb3_central is
  attribute syn_keep : boolean;
  attribute syn_preserve : boolean;
  
  signal clk_100_i   : std_logic; --clock for main logic, 100 MHz, via Clock Manager and internal PLL
  signal clk_200_i   : std_logic; --clock for logic at 200 MHz, via Clock Manager and bypassed PLL
  signal pll_lock    : std_logic; --Internal PLL locked. E.g. used to reset all internal logic.
  signal clear_i     : std_logic;
  signal reset_i     : std_logic;
  signal GSR_N       : std_logic;
  attribute syn_keep of GSR_N : signal is true;
  attribute syn_preserve of GSR_N : signal is true;
  
  --FPGA Test
  signal time_counter, time_counter2 : unsigned(31 downto 0);
  
  --Media Interface
  signal med_stat_op             : std_logic_vector (5*16-1  downto 0);
  signal med_ctrl_op             : std_logic_vector (5*16-1  downto 0);
  signal med_stat_debug          : std_logic_vector (5*64-1  downto 0);
  signal med_ctrl_debug          : std_logic_vector (5*64-1  downto 0);
  signal med_data_out            : std_logic_vector (5*16-1  downto 0);
  signal med_packet_num_out      : std_logic_vector (5*3-1   downto 0);
  signal med_dataready_out       : std_logic_vector (5*1-1   downto 0);
  signal med_read_out            : std_logic_vector (5*1-1   downto 0);
  signal med_data_in             : std_logic_vector (5*16-1  downto 0);
  signal med_packet_num_in       : std_logic_vector (5*3-1   downto 0);
  signal med_dataready_in        : std_logic_vector (5*1-1   downto 0);
  signal med_read_in             : std_logic_vector (5*1-1   downto 0);
  
  --Hub
  signal common_stat_regs        : std_logic_vector (std_COMSTATREG*32-1 downto 0);
  signal common_ctrl_regs        : std_logic_vector (std_COMCTRLREG*32-1 downto 0);
  signal my_address              : std_logic_vector (16-1 downto 0);
  signal regio_addr_out          : std_logic_vector (16-1 downto 0);
  signal regio_read_enable_out   : std_logic;
  signal regio_write_enable_out  : std_logic;
  signal regio_data_out          : std_logic_vector (32-1 downto 0);
  signal regio_data_in           : std_logic_vector (32-1 downto 0);
  signal regio_dataready_in      : std_logic;
  signal regio_no_more_data_in   : std_logic;
  signal regio_write_ack_in      : std_logic;
  signal regio_unknown_addr_in   : std_logic;
  signal regio_timeout_out       : std_logic;
  
  signal spictrl_read_en         : std_logic;
  signal spictrl_write_en        : std_logic;
  signal spictrl_data_in         : std_logic_vector(31 downto 0);
  signal spictrl_addr            : std_logic;
  signal spictrl_data_out        : std_logic_vector(31 downto 0);
  signal spictrl_ack             : std_logic;
  signal spictrl_busy            : std_logic;
  signal spimem_read_en          : std_logic;
  signal spimem_write_en         : std_logic;
  signal spimem_data_in          : std_logic_vector(31 downto 0);
  signal spimem_addr             : std_logic_vector(5 downto 0);
  signal spimem_data_out         : std_logic_vector(31 downto 0);
  signal spimem_ack              : std_logic;

  signal spi_bram_addr           : std_logic_vector(7 downto 0);
  signal spi_bram_wr_d           : std_logic_vector(7 downto 0);
  signal spi_bram_rd_d           : std_logic_vector(7 downto 0);
  signal spi_bram_we             : std_logic;

  signal cts_number                   : std_logic_vector(15 downto 0);
  signal cts_code                     : std_logic_vector(7 downto 0);
  signal cts_information              : std_logic_vector(7 downto 0);
  signal cts_start_readout            : std_logic;
  signal cts_readout_type             : std_logic_vector(3 downto 0);
  signal cts_data                     : std_logic_vector(31 downto 0);
  signal cts_dataready                : std_logic;
  signal cts_readout_finished         : std_logic;
  signal cts_read                     : std_logic;
  signal cts_length                   : std_logic_vector(15 downto 0);
  signal cts_status_bits              : std_logic_vector(31 downto 0);
  signal fee_data                     : std_logic_vector(15 downto 0);
  signal fee_dataready                : std_logic;
  signal fee_read                     : std_logic;
  signal fee_status_bits              : std_logic_vector(31 downto 0);
  signal fee_busy                     : std_logic;

signal stage_stat_regs              : std_logic_vector (31 downto 0);
signal stage_ctrl_regs              : std_logic_vector (31 downto 0);

signal mb_stat_reg_data_wr          : std_logic_vector(31 downto 0);
signal mb_stat_reg_data_rd          : std_logic_vector(31 downto 0);
signal mb_stat_reg_read             : std_logic;
signal mb_stat_reg_write            : std_logic;
signal mb_stat_reg_ack              : std_logic;
signal mb_ip_mem_addr               : std_logic_vector(15 downto 0); -- only [7:0] in used
signal mb_ip_mem_data_wr            : std_logic_vector(31 downto 0);
signal mb_ip_mem_data_rd            : std_logic_vector(31 downto 0);
signal mb_ip_mem_read               : std_logic;
signal mb_ip_mem_write              : std_logic;
signal mb_ip_mem_ack                : std_logic;
signal ip_cfg_mem_clk				: std_logic;
signal ip_cfg_mem_addr				: std_logic_vector(7 downto 0);
signal ip_cfg_mem_data				: std_logic_vector(31 downto 0);
signal ctrl_reg_addr                : std_logic_vector(15 downto 0);
signal gbe_stp_reg_addr             : std_logic_vector(15 downto 0);
signal gbe_stp_data                 : std_logic_vector(31 downto 0);
signal gbe_stp_reg_ack              : std_logic;
signal gbe_stp_reg_data_wr          : std_logic_vector(31 downto 0);
signal gbe_stp_reg_read             : std_logic;
signal gbe_stp_reg_write            : std_logic;
signal gbe_stp_reg_data_rd          : std_logic_vector(31 downto 0);

signal debug : std_logic_vector(63 downto 0);

signal next_reset, make_reset_via_network_q : std_logic;
signal reset_counter : std_logic_vector(11 downto 0);
signal link_ok : std_logic;

signal gsc_init_data, gsc_reply_data : std_logic_vector(15 downto 0);
signal gsc_init_read, gsc_reply_read : std_logic;
signal gsc_init_dataready, gsc_reply_dataready : std_logic;
signal gsc_init_packet_num, gsc_reply_packet_num : std_logic_vector(2 downto 0);
signal gsc_busy : std_logic;
signal mc_unique_id : std_logic_vector(63 downto 0);


signal senders_free, activate_sender : std_logic_vector(7 downto 0);
signal timestamp : std_logic_vector(31 downto 0);
signal dest_addr, size : std_logic_vector(15 downto 0);

signal sd_rx_clk, sd_quad_rst, sd1_link_ok, sd2_link_ok : std_logic_vector(7 downto 0);
signal sd_tx_k, sd_xmit, sd_tx_disp, sd_rx_k, sd_rx_disp, sd_cv_err, sd_rx_serdes_rst, sd_tx_pcs_rst, sd_rx_pcs_rst, sd_rx_los, sd_rx_cdr, sd_signal_detected : std_logic_vector(7 downto 0);

type arr is array(7 downto 0) of std_logic_vector(7 downto 0);
signal sd_tx_data, sd_rx_data : arr;

signal sd1_tx_pll_lol, sd1_quad_rst : std_logic;
signal sd2_tx_pll_lol, sd2_quad_rst : std_logic;

signal timer1, timer2 : std_logic_vector(31 downto 0);
signal module_full, module_selected : std_logic_vector(7 downto 0);

type arr2 is array(7 downto 0) of std_logic_vector(71 downto 0);
signal module_data : arr2;

signal stop_trans, start_stat, module_rd_en : std_logic;
signal stat_data : std_logic_vector(71 downto 0);

begin

--link_ok <= sd1_link_ok(0) and sd1_link_ok(1) and sd1_link_ok(2);
link_ok <= '1';

MAIN : CNTester_Main
	port map (
		CLKSYS_IN  => clk_100_i,
		RESET      => reset_i,
		LINK_OK_IN => link_ok,
		
		GENERATE_OUT    => activate_sender,
		TIMESTAMP_OUT   => timestamp,
		DEST_ADDR_OUT   => dest_addr,
		SIZE_OUT        => size,
		
		SENDERS_FREE_IN => senders_free
	);


-- serdes 0 ch 0
LINK_1 : CNTester_module
	port map(
		CLKSYS_IN  => clk_100_i,
		CLKGBE_IN  => CLK_GPLL_RIGHT,
		RESET      => reset_i,
		GSR_N      => GSR_N,
		LINK_OK_OUT => sd1_link_ok(0),
		
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
		SD_TX_PLL_LOL_IN            => sd1_tx_pll_lol,
		SD_QUAD_RST_OUT             => sd_quad_rst(0),
		SD_XMIT_OUT                 => sd_xmit(0),
		
		MODULE_SELECT_OUT     		=> open,
		MODULE_RD_EN_OUT      		=> open,
		MODULE_DATA_IN        		=> (others => '0'),
		STOP_TRANSMISSION_OUT 		=> open,
		START_STAT_IN         	 	=> '0',
		
		MODULE_DATA_OUT             => module_data(0),
		MODULE_RD_EN_IN             => module_rd_en,
		MODULE_SELECTED_IN          => module_selected(0),
		MODULE_FULL_OUT             => module_full(0),
		
		MAC_ADDR_IN          => x"123456789010",
		TIMESTAMP_IN         => timestamp,
		DEST_ADDR_IN         => dest_addr,
		GENERATE_PACKET_IN   => activate_sender(0),
		SIZE_IN              => size,
		BUSY_OUT             => senders_free(0)
	);
	
-- serdes 0 ch 1
LINK_2 : CNTester_module
port map(
	CLKSYS_IN  => clk_100_i,
	CLKGBE_IN  => CLK_GPLL_RIGHT,
	RESET      => reset_i,
	GSR_N      => GSR_N,
	LINK_OK_OUT => sd1_link_ok(1),
	
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
	SD_TX_PLL_LOL_IN            => sd1_tx_pll_lol,
	SD_QUAD_RST_OUT             => sd_quad_rst(1),
	SD_XMIT_OUT                 => sd_xmit(1),
	
	MODULE_SELECT_OUT     		=> open,
	MODULE_RD_EN_OUT      		=> open,
	MODULE_DATA_IN        		=> (others => '0'),
	STOP_TRANSMISSION_OUT 		=> open,
	START_STAT_IN         	 	=> '0',
	
	MODULE_DATA_OUT             => module_data(1),
	MODULE_RD_EN_IN             => module_rd_en,
	MODULE_SELECTED_IN          => module_selected(1),
	MODULE_FULL_OUT             => module_full(1),
		
	
	MAC_ADDR_IN          => x"123456789011",
	TIMESTAMP_IN         => timestamp,
	DEST_ADDR_IN         => dest_addr,
	GENERATE_PACKET_IN   => activate_sender(1),
	SIZE_IN              => size,
	BUSY_OUT             => senders_free(1)
);

-- serdes 0 ch 2
LINK_3 : CNTester_module
port map(
	CLKSYS_IN  => clk_100_i,
	CLKGBE_IN  => CLK_GPLL_RIGHT,
	RESET      => reset_i,
	GSR_N      => GSR_N,
	LINK_OK_OUT => sd1_link_ok(2),
	
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
	SD_TX_PLL_LOL_IN            => sd1_tx_pll_lol,
	SD_QUAD_RST_OUT             => sd_quad_rst(2),
	SD_XMIT_OUT                 => sd_xmit(2),
	
	MODULE_SELECT_OUT     		=> open,
	MODULE_RD_EN_OUT      		=> open,
	MODULE_DATA_IN        		=> (others => '0'),
	STOP_TRANSMISSION_OUT 		=> open,
	START_STAT_IN         	 	=> '0',
	
	MODULE_DATA_OUT             => module_data(2),
	MODULE_RD_EN_IN             => module_rd_en,
	MODULE_SELECTED_IN          => module_selected(2),
	MODULE_FULL_OUT             => module_full(2),
		
	
	MAC_ADDR_IN          => x"123456789012",
	TIMESTAMP_IN         => timestamp,
	DEST_ADDR_IN         => dest_addr,
	GENERATE_PACKET_IN   => activate_sender(2),
	SIZE_IN              => size,
	BUSY_OUT             => senders_free(2)
);

-- serdes 0 ch 3
LINK_4 : CNTester_module
port map(
	CLKSYS_IN  => clk_100_i,
	CLKGBE_IN  => CLK_GPLL_RIGHT,
	RESET      => reset_i,
	GSR_N      => GSR_N,
	LINK_OK_OUT => sd1_link_ok(3),
	
	-- serdes io
	SD_RX_CLK_IN                => sd_rx_clk(3),
	SD_TX_DATA_OUT              => sd_tx_data(3),
	SD_TX_KCNTL_OUT             => sd_tx_k(3),
	SD_TX_CORRECT_DISP_OUT      => sd_tx_disp(3),
	SD_RX_DATA_IN               => sd_rx_data(3),
	SD_RX_KCNTL_IN              => sd_rx_k(3),
	SD_RX_DISP_ERROR_IN         => sd_rx_disp(3),
	SD_RX_CV_ERROR_IN           => sd_cv_err(3),
	SD_RX_SERDES_RST_OUT        => sd_rx_serdes_rst(3),
	SD_RX_PCS_RST_OUT           => sd_rx_pcs_rst(3),
	SD_TX_PCS_RST_OUT			=> sd_tx_pcs_rst(3),
	SD_RX_LOS_IN				=> sd_rx_los(3),
	SD_SIGNAL_DETECTED_IN		=> sd_signal_detected(3),
	SD_RX_CDR_IN				=> sd_rx_cdr(3),
	SD_TX_PLL_LOL_IN            => sd1_tx_pll_lol,
	SD_QUAD_RST_OUT             => sd_quad_rst(3),
	SD_XMIT_OUT                 => sd_xmit(3),
	
	MODULE_SELECT_OUT     		=> open,
	MODULE_RD_EN_OUT      		=> open,
	MODULE_DATA_IN        		=> (others => '0'),
	STOP_TRANSMISSION_OUT 		=> open,
	START_STAT_IN         	 	=> '0',
	
	MODULE_DATA_OUT             => module_data(3),
	MODULE_RD_EN_IN             => module_rd_en,
	MODULE_SELECTED_IN          => module_selected(3),
	MODULE_FULL_OUT             => module_full(3),
		
	
	MAC_ADDR_IN          => x"123456789013",
	TIMESTAMP_IN         => timestamp,
	DEST_ADDR_IN         => dest_addr,
	GENERATE_PACKET_IN   => activate_sender(3),
	SIZE_IN              => size,
	BUSY_OUT             => senders_free(3)
);

-- serdes 1 ch 0
LINK_5 : CNTester_module
port map(
	CLKSYS_IN  => clk_100_i,
	CLKGBE_IN  => CLK_GPLL_RIGHT,
	RESET      => reset_i,
	GSR_N      => GSR_N,
	LINK_OK_OUT => sd2_link_ok(0),
	
	-- serdes io
	SD_RX_CLK_IN                => sd_rx_clk(4),
	SD_TX_DATA_OUT              => sd_tx_data(4),
	SD_TX_KCNTL_OUT             => sd_tx_k(4),
	SD_TX_CORRECT_DISP_OUT      => sd_tx_disp(4),
	SD_RX_DATA_IN               => sd_rx_data(4),
	SD_RX_KCNTL_IN              => sd_rx_k(4),
	SD_RX_DISP_ERROR_IN         => sd_rx_disp(4),
	SD_RX_CV_ERROR_IN           => sd_cv_err(4),
	SD_RX_SERDES_RST_OUT        => sd_rx_serdes_rst(4),
	SD_RX_PCS_RST_OUT           => sd_rx_pcs_rst(4),
	SD_TX_PCS_RST_OUT			=> sd_tx_pcs_rst(4),
	SD_RX_LOS_IN				=> sd_rx_los(4),
	SD_SIGNAL_DETECTED_IN		=> sd_signal_detected(4),
	SD_RX_CDR_IN				=> sd_rx_cdr(4),
	SD_TX_PLL_LOL_IN            => sd2_tx_pll_lol,
	SD_QUAD_RST_OUT             => sd_quad_rst(4),
	SD_XMIT_OUT                 => sd_xmit(4),
	
	MODULE_SELECT_OUT     		=> open,
	MODULE_RD_EN_OUT      		=> open,
	MODULE_DATA_IN        		=> (others => '0'),
	STOP_TRANSMISSION_OUT 		=> open,
	START_STAT_IN         	 	=> '0',
	
	MODULE_DATA_OUT             => module_data(4),
	MODULE_RD_EN_IN             => module_rd_en,
	MODULE_SELECTED_IN          => module_selected(4),
	MODULE_FULL_OUT             => module_full(4),
		
	
	MAC_ADDR_IN          => x"123456789014",
	TIMESTAMP_IN         => timestamp,
	DEST_ADDR_IN         => dest_addr,
	GENERATE_PACKET_IN   => activate_sender(4),
	SIZE_IN              => size,
	BUSY_OUT             => senders_free(4)
);

-- serdes 1 ch 1
LINK_6 : CNTester_module
port map(
	CLKSYS_IN  => clk_100_i,
	CLKGBE_IN  => CLK_GPLL_RIGHT,
	RESET      => reset_i,
	GSR_N      => GSR_N,
	LINK_OK_OUT => sd2_link_ok(1),
	
	-- serdes io
	SD_RX_CLK_IN                => sd_rx_clk(5),
	SD_TX_DATA_OUT              => sd_tx_data(5),
	SD_TX_KCNTL_OUT             => sd_tx_k(5),
	SD_TX_CORRECT_DISP_OUT      => sd_tx_disp(5),
	SD_RX_DATA_IN               => sd_rx_data(5),
	SD_RX_KCNTL_IN              => sd_rx_k(5),
	SD_RX_DISP_ERROR_IN         => sd_rx_disp(5),
	SD_RX_CV_ERROR_IN           => sd_cv_err(5),
	SD_RX_SERDES_RST_OUT        => sd_rx_serdes_rst(5),
	SD_RX_PCS_RST_OUT           => sd_rx_pcs_rst(5),
	SD_TX_PCS_RST_OUT			=> sd_tx_pcs_rst(5),
	SD_RX_LOS_IN				=> sd_rx_los(5),
	SD_SIGNAL_DETECTED_IN		=> sd_signal_detected(5),
	SD_RX_CDR_IN				=> sd_rx_cdr(5),
	SD_TX_PLL_LOL_IN            => sd2_tx_pll_lol,
	SD_QUAD_RST_OUT             => sd_quad_rst(5),
	SD_XMIT_OUT                 => sd_xmit(5),
	
	MODULE_SELECT_OUT     		=> open,
	MODULE_RD_EN_OUT      		=> open,
	MODULE_DATA_IN        		=> (others => '0'),
	STOP_TRANSMISSION_OUT 		=> open,
	START_STAT_IN         	 	=> '0',
	
	MODULE_DATA_OUT             => module_data(5),
	MODULE_RD_EN_IN             => module_rd_en,
	MODULE_SELECTED_IN          => module_selected(5),
	MODULE_FULL_OUT             => module_full(5),
		
	
	MAC_ADDR_IN          => x"123456789015",
	TIMESTAMP_IN         => timestamp,
	DEST_ADDR_IN         => dest_addr,
	GENERATE_PACKET_IN   => activate_sender(5),
	SIZE_IN              => size,
	BUSY_OUT             => senders_free(5)
);

-- serdes 1 ch 2
LINK_7 : CNTester_module
port map(
	CLKSYS_IN  => clk_100_i,
	CLKGBE_IN  => CLK_GPLL_RIGHT,
	RESET      => reset_i,
	GSR_N      => GSR_N,
	LINK_OK_OUT => sd2_link_ok(2),
	
	-- serdes io
	SD_RX_CLK_IN                => sd_rx_clk(6),
	SD_TX_DATA_OUT              => sd_tx_data(6),
	SD_TX_KCNTL_OUT             => sd_tx_k(6),
	SD_TX_CORRECT_DISP_OUT      => sd_tx_disp(6),
	SD_RX_DATA_IN               => sd_rx_data(6),
	SD_RX_KCNTL_IN              => sd_rx_k(6),
	SD_RX_DISP_ERROR_IN         => sd_rx_disp(6),
	SD_RX_CV_ERROR_IN           => sd_cv_err(6),
	SD_RX_SERDES_RST_OUT        => sd_rx_serdes_rst(6),
	SD_RX_PCS_RST_OUT           => sd_rx_pcs_rst(6),
	SD_TX_PCS_RST_OUT			=> sd_tx_pcs_rst(6),
	SD_RX_LOS_IN				=> sd_rx_los(6),
	SD_SIGNAL_DETECTED_IN		=> sd_signal_detected(6),
	SD_RX_CDR_IN				=> sd_rx_cdr(6),
	SD_TX_PLL_LOL_IN            => sd2_tx_pll_lol,
	SD_QUAD_RST_OUT             => sd_quad_rst(6),
	SD_XMIT_OUT                 => sd_xmit(6),
	
	MODULE_SELECT_OUT     		=> open,
	MODULE_RD_EN_OUT      		=> open,
	MODULE_DATA_IN        		=> (others => '0'),
	STOP_TRANSMISSION_OUT 		=> open,
	START_STAT_IN         	 	=> '0',
	
	MODULE_DATA_OUT             => module_data(6),
	MODULE_RD_EN_IN             => module_rd_en,
	MODULE_SELECTED_IN          => module_selected(6),
	MODULE_FULL_OUT             => module_full(6),

	
	MAC_ADDR_IN          => x"123456789016",
	TIMESTAMP_IN         => timestamp,
	DEST_ADDR_IN         => dest_addr,
	GENERATE_PACKET_IN   => activate_sender(6),
	SIZE_IN              => size,
	BUSY_OUT             => senders_free(6)
);

-- serdes 1 ch 3
LINK_STATS : CNTester_module
generic map( g_GENERATE_STAT => 1 )
port map(
	CLKSYS_IN  => clk_100_i,
	CLKGBE_IN  => CLK_GPLL_RIGHT,
	RESET      => reset_i,
	GSR_N      => GSR_N,
	LINK_OK_OUT => sd2_link_ok(3),
	
	-- serdes io
	SD_RX_CLK_IN                => sd_rx_clk(7),
	SD_TX_DATA_OUT              => sd_tx_data(7),
	SD_TX_KCNTL_OUT             => sd_tx_k(7),
	SD_TX_CORRECT_DISP_OUT      => sd_tx_disp(7),
	SD_RX_DATA_IN               => sd_rx_data(7),
	SD_RX_KCNTL_IN              => sd_rx_k(7),
	SD_RX_DISP_ERROR_IN         => sd_rx_disp(7),
	SD_RX_CV_ERROR_IN           => sd_cv_err(7),
	SD_RX_SERDES_RST_OUT        => sd_rx_serdes_rst(7),
	SD_RX_PCS_RST_OUT           => sd_rx_pcs_rst(7),
	SD_TX_PCS_RST_OUT			=> sd_tx_pcs_rst(7),
	SD_RX_LOS_IN				=> sd_rx_los(7),
	SD_SIGNAL_DETECTED_IN		=> sd_signal_detected(7),
	SD_RX_CDR_IN				=> sd_rx_cdr(7),
	SD_TX_PLL_LOL_IN            => sd2_tx_pll_lol,
	SD_QUAD_RST_OUT             => sd_quad_rst(7),
	SD_XMIT_OUT                 => sd_xmit(7),
	
	MODULE_SELECT_OUT     		=> module_selected,
	MODULE_RD_EN_OUT      		=> module_rd_en,
	MODULE_DATA_IN        		=> stat_data,
	STOP_TRANSMISSION_OUT 		=> stop_trans,
	START_STAT_IN         	 	=> start_stat,
	
	MODULE_DATA_OUT             => open,
	MODULE_RD_EN_IN             => '0',
	MODULE_SELECTED_IN          => '0',
	MODULE_FULL_OUT             => open,
		
	
	MAC_ADDR_IN          => x"123456789020",
	TIMESTAMP_IN         => timestamp,
	DEST_ADDR_IN         => dest_addr,
	GENERATE_PACKET_IN   => '0',
	SIZE_IN              => size,
	BUSY_OUT             => open
);

STAT_DATA_SELECTOR : process(module_selected)
begin

	case module_selected is
	
		when "00000001" =>
			stat_data <= module_data(0);
		
		when "00000010" =>
			stat_data <= module_data(1);
			
		when "00000100" =>
			stat_data <= module_data(2);
			
		when "00001000" =>
			stat_data <= module_data(3);
			
		when "00010000" =>
			stat_data <= module_data(4);
			
		when "00100000" =>
			stat_data <= module_data(5);
			
		when "01000000" =>
			stat_data <= module_data(6);
	
		when others =>
			stat_data <= (others => '1');
	
	end case;

end process STAT_DATA_SELECTOR;


SERDES1 : serdes4ch  -- PCSA
 port map(
------------------
-- CH0 --
    hdinp_ch0			=> SFP_RX_P(1),
    hdinn_ch0			=> SFP_RX_N(1),
    hdoutp_ch0			=> SFP_TX_P(1),
    hdoutn_ch0			=> SFP_TX_N(1),
    rxiclk_ch0			=> sd_rx_clk(0),
    txiclk_ch0			=> CLK_GPLL_RIGHT,
    rx_full_clk_ch0		=> sd_rx_clk(0),
    rx_half_clk_ch0		=> open,
    tx_full_clk_ch0		=> open,
    tx_half_clk_ch0		=> open,
    fpga_rxrefclk_ch0	=> CLK_GPLL_RIGHT,
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
    hdinp_ch1			=> SFP_RX_P(2),
    hdinn_ch1			=> SFP_RX_N(2),
    hdoutp_ch1			=> SFP_TX_P(2),
    hdoutn_ch1			=> SFP_TX_N(2),
    rxiclk_ch1			=> sd_rx_clk(1),
    txiclk_ch1			=> CLK_GPLL_RIGHT,
    rx_full_clk_ch1		=> sd_rx_clk(1),
    rx_half_clk_ch1		=> open,
    tx_full_clk_ch1		=> open,
    tx_half_clk_ch1		=> open,
    fpga_rxrefclk_ch1	=> CLK_GPLL_RIGHT,
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
    hdinp_ch2			=> SFP_RX_P(3),
    hdinn_ch2			=> SFP_RX_N(3),
    hdoutp_ch2			=> SFP_TX_P(3),
    hdoutn_ch2			=> SFP_TX_N(3),
    rxiclk_ch2			=> sd_rx_clk(2),
    txiclk_ch2			=> CLK_GPLL_RIGHT,
    rx_full_clk_ch2		=> sd_rx_clk(2),
    rx_half_clk_ch2		=> open,
    tx_full_clk_ch2		=> open,
    tx_half_clk_ch2		=> open,
    fpga_rxrefclk_ch2	=> CLK_GPLL_RIGHT,
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
    hdinp_ch3			=> SFP_RX_P(4),
    hdinn_ch3			=> SFP_RX_N(4),
    hdoutp_ch3			=> SFP_TX_P(4),
    hdoutn_ch3			=> SFP_TX_N(4),
    rxiclk_ch3			=> sd_rx_clk(3),
    txiclk_ch3			=> CLK_GPLL_RIGHT,
    rx_full_clk_ch3		=> sd_rx_clk(3),
    rx_half_clk_ch3		=> open,
    tx_full_clk_ch3		=> open,
    tx_half_clk_ch3		=> open,
    fpga_rxrefclk_ch3	=> CLK_GPLL_RIGHT,
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
-- Miscillaneous ports
    fpga_txrefclk       => CLK_GPLL_RIGHT,
    tx_serdes_rst_c     => '0',
    tx_pll_lol_qd_s     => sd1_tx_pll_lol,
    tx_sync_qd_c        => '1',
    rst_qd_c            => sd1_quad_rst,
    serdes_rst_qd_c     => '0'
    );
    
 SERDES2 : serdes4ch  -- PCSB
 port map(
------------------
-- CH0 --
    hdinp_ch0			=> SFP_RX_P(5),
    hdinn_ch0			=> SFP_RX_N(5),
    hdoutp_ch0			=> SFP_TX_P(5),
    hdoutn_ch0			=> SFP_TX_N(5),
    rxiclk_ch0			=> sd_rx_clk(4),
    txiclk_ch0			=> CLK_GPLL_RIGHT,
    rx_full_clk_ch0		=> sd_rx_clk(4),
    rx_half_clk_ch0		=> open,
    tx_full_clk_ch0		=> open,
    tx_half_clk_ch0		=> open,
    fpga_rxrefclk_ch0	=> CLK_GPLL_RIGHT,
    txdata_ch0			=> sd_tx_data(4),
    tx_k_ch0			=> sd_tx_k(4),
    xmit_ch0			=> sd_xmit(4),
    tx_disp_correct_ch0 => sd_tx_disp(4),
    rxdata_ch0			=> sd_rx_data(4),
    rx_k_ch0			=> sd_rx_k(4),
    rx_disp_err_ch0		=> sd_rx_disp(4),
    rx_cv_err_ch0		=> sd_cv_err(4),
    rx_serdes_rst_ch0_c => sd_rx_serdes_rst(4),
    sb_felb_ch0_c       => '0',
    sb_felb_rst_ch0_c   => '0',
    tx_pcs_rst_ch0_c    => sd_tx_pcs_rst(4),
    tx_pwrup_ch0_c      => '1',
    rx_pcs_rst_ch0_c    => sd_rx_pcs_rst(4),
    rx_pwrup_ch0_c    	=> '1',
    rx_los_low_ch0_s    => sd_rx_los(4),
    lsm_status_ch0_s    => sd_signal_detected(4),
    rx_cdr_lol_ch0_s    => sd_rx_cdr(4),
-- CH1 --
    hdinp_ch1			=> SFP_RX_P(6),
    hdinn_ch1			=> SFP_RX_N(6),
    hdoutp_ch1			=> SFP_TX_P(6),
    hdoutn_ch1			=> SFP_TX_N(6),
    rxiclk_ch1			=> sd_rx_clk(5),
    txiclk_ch1			=> CLK_GPLL_RIGHT,
    rx_full_clk_ch1		=> sd_rx_clk(5),
    rx_half_clk_ch1		=> open,
    tx_full_clk_ch1		=> open,
    tx_half_clk_ch1		=> open,
    fpga_rxrefclk_ch1	=> CLK_GPLL_RIGHT,
    txdata_ch1			=> sd_tx_data(5),
    tx_k_ch1			=> sd_tx_k(5),
    xmit_ch1			=> sd_xmit(5),
    tx_disp_correct_ch1 => sd_tx_disp(5),
    rxdata_ch1			=> sd_rx_data(5),
    rx_k_ch1			=> sd_rx_k(5),
    rx_disp_err_ch1		=> sd_rx_disp(5),
    rx_cv_err_ch1		=> sd_cv_err(5),
    rx_serdes_rst_ch1_c => sd_rx_serdes_rst(5),
    sb_felb_ch1_c       => '0',
    sb_felb_rst_ch1_c   => '0',
    tx_pcs_rst_ch1_c    => sd_tx_pcs_rst(5),
    tx_pwrup_ch1_c      => '1',
    rx_pcs_rst_ch1_c    => sd_rx_pcs_rst(5),
    rx_pwrup_ch1_c    	=> '1',
    rx_los_low_ch1_s    => sd_rx_los(5),
    lsm_status_ch1_s    => sd_signal_detected(5),
    rx_cdr_lol_ch1_s    => sd_rx_cdr(5),
-- CH2 --
    hdinp_ch2			=> SFP_RX_P(7),
    hdinn_ch2			=> SFP_RX_N(7),
    hdoutp_ch2			=> SFP_TX_P(7),
    hdoutn_ch2			=> SFP_TX_N(7),
    rxiclk_ch2			=> sd_rx_clk(6),
    txiclk_ch2			=> CLK_GPLL_RIGHT,
    rx_full_clk_ch2		=> sd_rx_clk(6),
    rx_half_clk_ch2		=> open,
    tx_full_clk_ch2		=> open,
    tx_half_clk_ch2		=> open,
    fpga_rxrefclk_ch2	=> CLK_GPLL_RIGHT,
    txdata_ch2			=> sd_tx_data(6),
    tx_k_ch2			=> sd_tx_k(6),
    xmit_ch2			=> sd_xmit(6),
    tx_disp_correct_ch2 => sd_tx_disp(6),
    rxdata_ch2			=> sd_rx_data(6),
    rx_k_ch2			=> sd_rx_k(6),
    rx_disp_err_ch2		=> sd_rx_disp(6),
    rx_cv_err_ch2		=> sd_cv_err(6),
    rx_serdes_rst_ch2_c => sd_rx_serdes_rst(6),
    sb_felb_ch2_c       => '0',
    sb_felb_rst_ch2_c   => '0',
    tx_pcs_rst_ch2_c    => sd_tx_pcs_rst(6),
    tx_pwrup_ch2_c      => '1',
    rx_pcs_rst_ch2_c    => sd_rx_pcs_rst(6),
    rx_pwrup_ch2_c    	=> '1',
    rx_los_low_ch2_s    => sd_rx_los(6),
    lsm_status_ch2_s    => sd_signal_detected(6),
    rx_cdr_lol_ch2_s    => sd_rx_cdr(6),
-- CH3 --
    hdinp_ch3			=> SFP_RX_P(8),
    hdinn_ch3			=> SFP_RX_N(8),
    hdoutp_ch3			=> SFP_TX_P(8),
    hdoutn_ch3			=> SFP_TX_N(8),
    rxiclk_ch3			=> sd_rx_clk(7),
    txiclk_ch3			=> CLK_GPLL_RIGHT,
    rx_full_clk_ch3		=> sd_rx_clk(7),
    rx_half_clk_ch3		=> open,
    tx_full_clk_ch3		=> open,
    tx_half_clk_ch3		=> open,
    fpga_rxrefclk_ch3	=> CLK_GPLL_RIGHT,
    txdata_ch3			=> sd_tx_data(7),
    tx_k_ch3			=> sd_tx_k(7),
    xmit_ch3			=> sd_xmit(7),
    tx_disp_correct_ch3 => sd_tx_disp(7),
    rxdata_ch3			=> sd_rx_data(7),
    rx_k_ch3			=> sd_rx_k(7),
    rx_disp_err_ch3		=> sd_rx_disp(7),
    rx_cv_err_ch3		=> sd_cv_err(7),
    rx_serdes_rst_ch3_c => sd_rx_serdes_rst(7),
    sb_felb_ch3_c       => '0',
    sb_felb_rst_ch3_c   => '0',
    tx_pcs_rst_ch3_c    => sd_tx_pcs_rst(7),
    tx_pwrup_ch3_c      => '1',
    rx_pcs_rst_ch3_c    => sd_rx_pcs_rst(7),
    rx_pwrup_ch3_c    	=> '1',
    rx_los_low_ch3_s    => sd_rx_los(7),
    lsm_status_ch3_s    => sd_signal_detected(7),
    rx_cdr_lol_ch3_s    => sd_rx_cdr(7),
-- Miscillaneous ports
    fpga_txrefclk       => CLK_GPLL_RIGHT,
    tx_serdes_rst_c     => '0',
    tx_pll_lol_qd_s     => sd2_tx_pll_lol,
    tx_sync_qd_c        => '1',
    rst_qd_c            => sd2_quad_rst,
    serdes_rst_qd_c     => '0'
    );
    
    


sd1_quad_rst <= sd_quad_rst(0) or sd_quad_rst(1) or sd_quad_rst(2);
sd2_quad_rst <= sd_quad_rst(4) or sd_quad_rst(5) or sd_quad_rst(6);


SFP_TXDIS(8 downto 1) <= (others => '0');


---------------------------------------------------------------------------
-- Reset Generation
---------------------------------------------------------------------------

GSR_N   <= pll_lock;
  
reset_i <= not GSR_N;

--THE_RESET_HANDLER : trb_net_reset_handler
--  generic map(
--    RESET_DELAY     => x"FEEE"
--    )
--  port map(
--    CLEAR_IN        => '0',             -- reset input (high active, async)
--    CLEAR_N_IN      => '1',             -- reset input (low active, async)
--    CLK_IN          => clk_200_i,       -- raw master clock, NOT from PLL/DLL!
--    SYSCLK_IN       => clk_100_i,       -- PLL/DLL remastered clock
--    PLL_LOCKED_IN   => pll_lock,        -- master PLL lock signal (async)
--    RESET_IN        => '0',             -- general reset signal (SYSCLK)
--    TRB_RESET_IN    => '0', --med_stat_op(4*16+13), -- TRBnet reset signal (SYSCLK)
--    CLEAR_OUT       => clear_i,         -- async reset out, USE WITH CARE!
--    RESET_OUT       => reset_i,         -- synchronous reset out (SYSCLK)
--    DEBUG_OUT       => open
--  );

---------------------------------------------------------------------------
-- Clock Handling
---------------------------------------------------------------------------
THE_MAIN_PLL : pll_in200_out100
  port map(
    CLK    => CLK_GPLL_LEFT,
    CLKOP  => clk_100_i,
    CLKOK  => clk_200_i,
    LOCK   => pll_lock
    );


---------------------------------------------------------------------------
-- Reboot FPGA
---------------------------------------------------------------------------
--THE_FPGA_REBOOT : fpga_reboot
--  port map(
--    CLK       => clk_100_i,
--    RESET     => reset_i,
--    DO_REBOOT => common_ctrl_regs(15),
--    PROGRAMN  => PROGRAMN
--    );

    
---------------------------------------------------------------------------
-- Clock and Trigger Configuration
---------------------------------------------------------------------------
  TRIGGER_SELECT <= '0'; --always external trigger source
  CLOCK_SELECT   <= '0'; --use on-board oscillator
  CLK_MNGR1_USER <= (others => '0');
  CLK_MNGR2_USER <= (others => '0'); 

  TRIGGER_OUT    <= '0';

---------------------------------------------------------------------------
-- FPGA communication
---------------------------------------------------------------------------
--   FPGA1_COMM <= (others => 'Z');
--   FPGA2_COMM <= (others => 'Z');
--   FPGA3_COMM <= (others => 'Z');
--   FPGA4_COMM <= (others => 'Z');

  FPGA1_TTL <= (others => 'Z');
  FPGA2_TTL <= (others => 'Z');
  FPGA3_TTL <= (others => 'Z');
  FPGA4_TTL <= (others => 'Z');

  FPGA1_CONNECTOR <= (others => 'Z');
  FPGA2_CONNECTOR <= (others => 'Z');
  FPGA3_CONNECTOR <= (others => 'Z');
  FPGA4_CONNECTOR <= (others => 'Z');


---------------------------------------------------------------------------
-- Big AddOn Connector
---------------------------------------------------------------------------
  ADDON_RESET      <= '1';
  TRB_TO_ADDON_CLK <= '0';
  ADO_LV           <= (others => 'Z');
  ADO_TTL          <= (others => 'Z');
  FS_PE            <= (others => 'Z');


---------------------------------------------------------------------------
-- LED
---------------------------------------------------------------------------
  LED_CLOCK_GREEN                <= '0';
  LED_CLOCK_RED                  <= '1';
--   LED_GREEN                      <= not med_stat_op(9);
--   LED_YELLOW                     <= not med_stat_op(10);
--   LED_ORANGE                     <= not med_stat_op(11); 
--   LED_RED                        <= '1';
  LED_TRIGGER_GREEN              <= not med_stat_op(4*16+9);
  LED_TRIGGER_RED                <= not (med_stat_op(4*16+11) or med_stat_op(4*16+10));


--LED_GREEN <= time_counter(27);
--LED_ORANGE <= time_counter2(27);
--LED_RED <= debug(2);
--LED_YELLOW <= debug(3);


TIMER1_PROC : process(CLK_GPLL_RIGHT)
begin
	if rising_edge(CLK_GPLL_RIGHT) then
		if (reset_i = '1') then
			timer1 <= (others => '0');
		else
			timer1 <= timer1 + x"1";
		end if;
	end if;
end process TIMER1_PROC;

TIMER2_PROC : process(sd_rx_clk(0))
begin
	if rising_edge(sd_rx_clk(0)) then
		if (reset_i = '1') then
			timer2 <= (others => '0');
		else
			timer2 <= timer2 + x"1";
		end if;
	end if;
end process TIMER2_PROC;

LED_GREEN <= timer1(28);
LED_ORANGE <= timer2(24);
LED_RED <= reset_i;
LED_YELLOW <= sd_signal_detected(0); --debug(3);


---------------------------------------------------------------------------
-- Test Connector
---------------------------------------------------------------------------    

  TEST_LINE(7 downto 0)   <= med_data_in(7 downto 0);
  TEST_LINE(8)            <= med_dataready_in(0);
  TEST_LINE(9)            <= med_dataready_out(0);

  
  TEST_LINE(31 downto 10) <= (others => '0');


---------------------------------------------------------------------------
-- Test Circuits
---------------------------------------------------------------------------
  process
    begin
      wait until rising_edge(clk_100_i);
      time_counter <= time_counter + 1;
    end process;


end architecture;