LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_ARITH.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;

use work.trb_net_gbe_components.all;

entity trb_net16_med_ecp_sfp_gbe_8b is
-- gk 28.04.10
generic (
	USE_125MHZ_EXTCLK			: integer range 0 to 1 := 1
);
port(
	RESET					: in	std_logic;
	GSR_N					: in	std_logic;
	CLK_125_OUT				: out	std_logic;
	CLK_125_IN				: in	std_logic;  -- gk 28.04.10  used when intclk
	CLK_125_RX_OUT				: out	std_logic;
	--SGMII connection to frame transmitter (tsmac)
	FT_TX_CLK_EN_OUT			: out	std_logic;
	FT_RX_CLK_EN_OUT			: out	std_logic;
	FT_COL_OUT				: out	std_logic;
	FT_CRS_OUT				: out	std_logic;
	FT_TXD_IN				: in	std_logic_vector(7 downto 0);
	FT_TX_EN_IN				: in	std_logic;
	FT_TX_ER_IN				: in	std_logic;

	FT_RXD_OUT				: out	std_logic_vector(7 downto 0);
	FT_RX_EN_OUT				: out	std_logic;
	FT_RX_ER_OUT				: out	std_logic;
	
	-- Autonegotiation stuff 
	MR_RESET_IN				: in	std_logic;
	MR_MODE_IN				: in	std_logic;
	MR_ADV_ABILITY_IN			: in 	std_logic_vector(15 downto 0); -- should be x"0020
	MR_AN_LP_ABILITY_OUT			: out	std_logic_vector(15 downto 0); -- advert page from link partner
	MR_AN_PAGE_RX_OUT			: out	std_logic;
	MR_AN_COMPLETE_OUT			: out	std_logic; 
	MR_AN_ENABLE_IN				: in	std_logic;
	MR_RESTART_AN_IN			: in	std_logic;
	
	SD_RX_CLK_IN                : in	std_logic;
	SD_TX_DATA_OUT              : out	std_logic_vector(7 downto 0);
	SD_TX_KCNTL_OUT             : out	std_logic;
	SD_TX_CORRECT_DISP_OUT      : out	std_logic;
	SD_RX_DATA_IN               : in	std_logic_vector(7 downto 0);
	SD_RX_KCNTL_IN              : in	std_logic;
	SD_RX_DISP_ERROR_IN         : in	std_logic;
	SD_RX_CV_ERROR_IN           : in	std_logic;
	SD_RX_SERDES_RST_OUT        : out	std_logic;
	SD_RX_PCS_RST_OUT           : out	std_logic;
	SD_TX_PCS_RST_OUT			: out	std_logic;
	SD_RX_LOS_IN				: in	std_logic;
	SD_SIGNAL_DETECTED_IN		: in	std_logic;
	SD_RX_CDR_IN				: in	std_logic;
	SD_TX_PLL_LOL_IN            : in	std_logic;
	SD_QUAD_RST_OUT             : out	std_logic;
	SD_XMIT_OUT                 : out	std_logic              
);
end entity;

architecture trb_net16_med_ecp_sfp_gbe_8b of trb_net16_med_ecp_sfp_gbe_8b is

attribute syn_sharing : string;
attribute syn_sharing of trb_net16_med_ecp_sfp_gbe_8b : architecture is "off";

component sgmii_gbe_pcs34
port( rst_n                  : in	std_logic;
	  signal_detect          : in	std_logic;
	  gbe_mode               : in	std_logic;
	  sgmii_mode             : in	std_logic;
	  operational_rate       : in	std_logic_vector(1 downto 0);
	  debug_link_timer_short : in	std_logic;

 force_isolate : in std_logic;
 force_loopback : in std_logic;
 force_unidir : in std_logic;

	  rx_compensation_err    : out	std_logic;

 ctc_drop_flag : out std_logic;
 ctc_add_flag : out std_logic;
 an_link_ok : out std_logic;

	  tx_clk_125             : in	std_logic;                    
	  tx_clock_enable_source : out	std_logic;
	  tx_clock_enable_sink   : in	std_logic;          
	  tx_d                   : in	std_logic_vector(7 downto 0); 
	  tx_en                  : in	std_logic;       
	  tx_er                  : in	std_logic;       
	  rx_clk_125             : in	std_logic; 
	  rx_clock_enable_source : out	std_logic;
	  rx_clock_enable_sink   : in	std_logic;          
	  rx_d                   : out	std_logic_vector(7 downto 0);       
	  rx_dv                  : out	std_logic;  
	  rx_er                  : out	std_logic; 
	  col                    : out	std_logic;  
	  crs                    : out	std_logic;  
	  tx_data                : out	std_logic_vector(7 downto 0);  
	  tx_kcntl               : out	std_logic; 
	  tx_disparity_cntl      : out	std_logic; 

 xmit_autoneg : out std_logic;

	  serdes_recovered_clk   : in	std_logic; 
	  rx_data                : in	std_logic_vector(7 downto 0);  
	  rx_even                : in	std_logic;  
	  rx_kcntl               : in	std_logic; 
	  rx_disp_err            : in	std_logic; 
	  rx_cv_err              : in	std_logic; 
	  rx_err_decode_mode     : in	std_logic; 
	  mr_an_complete         : out	std_logic; 
	  mr_page_rx             : out	std_logic; 
	  mr_lp_adv_ability      : out	std_logic_vector(15 downto 0); 
	  mr_main_reset          : in	std_logic; 
	  mr_an_enable           : in	std_logic; 
	  mr_restart_an          : in	std_logic; 
	  mr_adv_ability         : in	std_logic_vector(15 downto 0)  
	);
end component;

component trb_net16_lsm_sfp_gbe is
port( SYSCLK			: in	std_logic; -- fabric clock (100MHz)
	  RESET				: in	std_logic; -- synchronous reset
	  CLEAR				: in	std_logic; -- asynchronous reset, connect to '0' if not needed / available
	  -- status signals
	  SFP_MISSING_IN	: in	std_logic; -- SFP Missing ('1' = no SFP mounted, '0' = SFP in place)
	  SFP_LOS_IN		: in	std_logic; -- SFP Loss Of Signal ('0' = OK, '1' = no signal)
	  SD_LINK_OK_IN		: in	std_logic; -- SerDes Link OK ('0' = not linked, '1' link established)
	  SD_LOS_IN			: in	std_logic; -- SerDes Loss Of Signal ('0' = OK, '1' = signal lost)
	  SD_TXCLK_BAD_IN	: in	std_logic; -- SerDes Tx Clock locked ('0' = locked, '1' = not locked)
	  SD_RXCLK_BAD_IN	: in	std_logic; -- SerDes Rx Clock locked ('0' = locked, '1' = not locked)
	  -- control signals
	  FULL_RESET_OUT	: out	std_logic; -- full reset AKA quad_reset
	  LANE_RESET_OUT	: out	std_logic; -- partial reset AKA lane_reset
	  USER_RESET_OUT	: out	std_logic; -- FPGA reset for user logic
	  -- debug signals
	  TIMING_CTR_OUT	: out	std_logic_vector(18 downto 0);
	  BSM_OUT			: out	std_logic_vector(3 downto 0);
	  DEBUG_OUT			: out	std_logic_vector(31 downto 0)
	);
end component;

component reset_controller_pcs port (
	rst_n                 : in std_logic;
	clk                   : in std_logic;
	tx_plol               : in std_logic; 
	rx_cdr_lol            : in std_logic; 
        quad_rst_out          : out std_logic; 
        tx_pcs_rst_out        : out std_logic; 
        rx_pcs_rst_out        : out std_logic
   );
end component;
component reset_controller_cdr port (
	rst_n                 : in std_logic;
	clk                   : in std_logic;
	cdr_lol               : in std_logic; 
        cdr_rst_out           : out std_logic
   );
end component;

component rate_resolution port (
	gbe_mode               : in std_logic;
	sgmii_mode             : in std_logic;
	an_enable              : in std_logic; 
	advertised_rate        : in std_logic_vector(1 downto 0);
	link_partner_rate      : in std_logic_vector(1 downto 0);
	non_an_rate            : in std_logic_vector(1 downto 0);
	operational_rate       : out std_logic_vector(1 downto 0)  
   );
end component;

component register_interface_hb port (
	rst_n                  : in std_logic;
	hclk                   : in std_logic;
	gbe_mode               : in std_logic;
	sgmii_mode             : in std_logic;
	hcs_n                  : in std_logic;
	hwrite_n               : in std_logic;
	haddr                  : in std_logic_vector(3 downto 0);
	hdatain                : in std_logic_vector(7 downto 0);
	hdataout               : out std_logic_vector(7 downto 0);   
	hready_n               : out std_logic;
	mr_an_complete         : in std_logic; 
	mr_page_rx             : in std_logic; 
	mr_lp_adv_ability      : in std_logic_vector(15 downto 0); 
	mr_main_reset          : out std_logic; 
	mr_an_enable           : out std_logic; 
	mr_restart_an          : out std_logic; 
	mr_adv_ability         : out std_logic_vector(15 downto 0) 
   );
end component;

signal refclkcore			: std_logic;

signal sd_link_ok			: std_logic;
signal sd_link_error		: std_logic_vector(2 downto 0);

signal sd_tx_data			: std_logic_vector(7 downto 0);
signal sd_tx_kcntl			: std_logic;
signal sd_tx_correct_disp	: std_logic;
signal sd_tx_clk			: std_logic;

signal sd_rx_data			: std_logic_vector(7 downto 0);
signal sd_rx_even			: std_logic;
signal sd_rx_kcntl			: std_logic;
signal sd_rx_disp_error		: std_logic;
signal sd_rx_cv_error		: std_logic;
signal sd_rx_clk			: std_logic;

signal sd_tx_data_q			: std_logic_vector(7 downto 0);
signal sd_tx_kcntl_q			: std_logic;
signal sd_tx_correct_disp_q	: std_logic;

signal sd_rx_data_q			: std_logic_vector(7 downto 0);
signal sd_rx_kcntl_q			: std_logic;
signal sd_rx_disp_error_q		: std_logic;
signal sd_rx_cv_error_q		: std_logic;

signal pcs_mr_an_complete	: std_logic;
signal pcs_mr_ability		: std_logic_vector(15 downto 0);
signal pcs_mr_page_rx		: std_logic;
signal pcs_mr_reset			: std_logic;

signal pcs_tx_clk_en		: std_logic;
signal pcs_rx_clk_en		: std_logic;
signal pcs_rx_comp_err		: std_logic;

signal pcs_rx_d				: std_logic_vector(7 downto 0);
signal pcs_rx_dv			: std_logic;
signal pcs_rx_er			: std_logic;

signal sd_rx_debug			: std_logic_vector(15 downto 0);
signal sd_tx_debug			: std_logic_vector(15 downto 0);

signal buf_stat_debug		: std_logic_vector(63 downto 0);

signal quad_rst				: std_logic;
signal lane_rst				: std_logic;
signal user_rst				: std_logic;

signal reset_bsm			: std_logic_vector(3 downto 0);
signal reset_debug			: std_logic_vector(31 downto 0);
signal   test_clk : std_logic;

signal xmit : std_logic;
signal signal_detected, compensation_err, tx_clk_en, rx_clk_en, rst_n, an_complete : std_logic;
signal tx_pll_lol, rx_cdr_lol, los, tx_pcs_rst, rx_pcs_rst, rx_serdes_rst : std_logic;

signal operational_rate : std_logic_vector(1 downto 0);

signal mr_an_enable, mr_restart_an, mr_main_reset, mr_page_rx : std_logic;
signal mr_lp_adv_ability, mr_adv_ability : std_logic_vector(15 downto 0);


  attribute syn_keep : boolean;
  attribute syn_preserve : boolean;

  --attribute syn_keep of sd_tx_clk : signal is true;
  --attribute syn_preserve of sd_tx_clk : signal is true;
  attribute syn_keep of sd_rx_clk : signal is true;
  attribute syn_preserve of sd_rx_clk : signal is true;
  
  attribute syn_keep of sd_tx_correct_disp_q, sd_tx_kcntl_q, sd_tx_data_q, sd_rx_data_q, sd_rx_cv_error_q, sd_rx_disp_error_q, sd_rx_kcntl_q : signal is true;
  attribute syn_preserve of sd_tx_correct_disp_q, sd_tx_kcntl_q, sd_tx_data_q, sd_rx_data_q, sd_rx_cv_error_q, sd_rx_disp_error_q, sd_rx_kcntl_q : signal is true;

begin

	refclkcore <= CLK_125_IN; --sd_tx_clk; --CLK_125_IN;


   
   SYNC_TX_PROC : process(CLK_125_IN)
   begin
   	if rising_edge(CLK_125_IN) then
   		SD_TX_DATA_OUT <= sd_tx_data;
   		SD_TX_KCNTL_OUT <= sd_tx_kcntl;
   		SD_TX_CORRECT_DISP_OUT <= sd_tx_correct_disp;
   	end if;
   end process SYNC_TX_PROC;
   
   SYNC_RX_PROC : process(SD_RX_CLK_IN)
   begin
   	if rising_edge(SD_RX_CLK_IN) then
   		sd_rx_data_q <= SD_RX_DATA_IN;
   		sd_rx_kcntl_q <= SD_RX_KCNTL_IN;
   		sd_rx_disp_error_q <= SD_RX_DISP_ERROR_IN;
   		sd_rx_cv_error_q <= SD_RX_CV_ERROR_IN;
   	end if;
   end process SYNC_RX_PROC;
   
   

 
 SGMII_GBE_PCS : sgmii_gbe_pcs34
 port map(
	rst_n					=> GSR_N,
	signal_detect			=> SD_SIGNAL_DETECTED_IN,
	gbe_mode				=> '1',
	sgmii_mode				=> '0',
	operational_rate		=> operational_rate,
	debug_link_timer_short	=> '0',
	 
	force_isolate 			=> '0',
	force_loopback 			=> '0',
	force_unidir 			=> '0',
 
 	rx_compensation_err		=> open,
 
	ctc_drop_flag 			=> open,
	ctc_add_flag 			=> open,
	an_link_ok 				=> open,
 
 	-- MAC interface
 	tx_clk_125				=> CLK_125_IN, --refclkcore, -- original clock from SerDes
 	tx_clock_enable_source	=> tx_clk_en,
 	tx_clock_enable_sink	=> tx_clk_en,
 	tx_d					=> FT_TXD_IN, -- TX data from MAC
 	tx_en					=> FT_TX_EN_IN, -- TX data enable from MAC
 	tx_er					=> FT_TX_ER_IN, -- TX error from MAC
 	rx_clk_125				=> CLK_125_IN, --refclkcore, -- original clock from SerDes
 	rx_clock_enable_source	=> rx_clk_en,
 	rx_clock_enable_sink	=> rx_clk_en,
 	rx_d					=> FT_RXD_OUT, -- RX data to MAC
 	rx_dv					=> FT_RX_EN_OUT, -- RX data enable to MAC
 	rx_er					=> FT_RX_ER_OUT, -- RX error to MAC
 	col						=> FT_COL_OUT,
 	crs						=> FT_CRS_OUT,
 	
 	-- SerDes interface
 	tx_data					=> sd_tx_data, -- TX data to SerDes
 	tx_kcntl				=> sd_tx_kcntl, -- TX komma control to SerDes
 	tx_disparity_cntl		=> sd_tx_correct_disp, -- idle parity state control in IPG (to SerDes)
 
  	xmit_autoneg 			=> SD_XMIT_OUT,
 	serdes_recovered_clk	=> SD_RX_CLK_IN, -- 125MHz recovered from receive bit stream
 	
 	rx_data					=> sd_rx_data_q, -- RX data from SerDes
 	rx_kcntl				=> sd_rx_kcntl_q, -- RX komma control from SerDes
 	rx_err_decode_mode		=> '0', -- receive error control mode fixed to normal
 	rx_even					=> '0', -- unused (receive error control mode = normal, tie to GND)
 	rx_disp_err				=> sd_rx_disp_error_q, -- RX disparity error from SerDes
 	rx_cv_err				=> sd_rx_cv_error_q, -- RX code violation error from SerDes
 	
 	-- Autonegotiation stuff
 	mr_an_complete			=> an_complete,
 	mr_page_rx				=> mr_page_rx,
 	mr_lp_adv_ability		=> mr_lp_adv_ability,
 	mr_main_reset			=> mr_main_reset,
 	mr_an_enable			=> MR_AN_ENABLE_IN,
 	mr_restart_an			=> mr_restart_an,
 	mr_adv_ability			=> mr_adv_ability
 );

rst_n <= not RESET;


u0_reset_controller_pcs : reset_controller_pcs port map(
	rst_n           => rst_n,
	clk             => CLK_125_IN,
	tx_plol         => SD_TX_PLL_LOL_IN,
	rx_cdr_lol      => SD_RX_CDR_IN,
	quad_rst_out    => SD_QUAD_RST_OUT,
	tx_pcs_rst_out  => SD_TX_PCS_RST_OUT,
	rx_pcs_rst_out  => SD_RX_PCS_RST_OUT
);

u0_reset_controller_cdr : reset_controller_cdr port map(
	rst_n           => rst_n,
	clk             => CLK_125_IN,
	cdr_lol         => SD_RX_CDR_IN,
	cdr_rst_out     => SD_RX_SERDES_RST_OUT
);

u0_rate_resolution : rate_resolution port map(
	gbe_mode          => '1',
	sgmii_mode        => '0',
	an_enable         => '1',
	advertised_rate   => mr_adv_ability(11 downto 10),
	link_partner_rate => mr_lp_adv_ability(11 downto 10),
	non_an_rate       => "10", -- 1Gbps is rate when auto-negotiation disabled
                          
	operational_rate  => operational_rate
);

u0_ri : register_interface_hb port map(
	-- Control Signals
	rst_n      => rst_n,
	hclk       => CLK_125_IN,
	gbe_mode   => '1',
	sgmii_mode => '0',
                   
	-- Host Bus
	hcs_n      => '1',
	hwrite_n   => '1',
	haddr      => (others => '0'),
	hdatain    => (others => '0'),
                   
	hdataout   => open,
	hready_n   => open,

	-- Register Outputs
	mr_an_enable   => mr_an_enable,
	mr_restart_an  => mr_restart_an,
	mr_main_reset  => mr_main_reset,
	mr_adv_ability => mr_adv_ability,

	-- Register Inputs
	mr_an_complete     => an_complete,
	mr_page_rx         => mr_page_rx,
	mr_lp_adv_ability  => mr_lp_adv_ability
	);

FT_TX_CLK_EN_OUT     <= tx_clk_en; -- to MAC
FT_RX_CLK_EN_OUT     <= rx_clk_en; -- to MAC

MR_AN_LP_ABILITY_OUT <= pcs_mr_ability;
MR_AN_COMPLETE_OUT   <= an_complete;
MR_AN_PAGE_RX_OUT    <= pcs_mr_page_rx;

-- Clock games
CLK_125_OUT    <= CLK_125_IN;
CLK_125_RX_OUT <= SD_RX_CLK_IN;


end architecture;