LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_std.all;
use work.trb_net_components.all;
use work.trb_net16_hub_func.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;


--********
-- contains valid frame types codes and performs checking of type and vlan id
-- by default there is place for 32 frame type which is hardcoded value
-- due to allow register which is set by slow control

entity trb_net16_gbe_type_validator is
port (
	CLK			: in	std_logic;  -- 125MHz clock input
	RESET			: in	std_logic;
	-- ethernet level
	FRAME_TYPE_IN		: in	std_logic_vector(15 downto 0);  -- recovered frame type	
	SAVED_VLAN_ID_IN	: in	std_logic_vector(15 downto 0);  -- recovered vlan id
	ALLOWED_TYPES_IN	: in	std_logic_vector(31 downto 0);  -- signal from gbe_setup
	VLAN_ID_IN		: in	std_logic_vector(31 downto 0);  -- two values from gbe setup

	-- IP level
	IP_PROTOCOLS_IN		: in	std_logic_vector(7 downto 0);
	ALLOWED_IP_PROTOCOLS_IN	: in	std_logic_vector(31 downto 0);
	
	-- UDP level
	UDP_PROTOCOL_IN		: in	std_logic_vector(15 downto 0);
	ALLOWED_UDP_PROTOCOLS_IN : in	std_logic_vector(31 downto 0);
	
	VALID_OUT		: out	std_logic
);
end trb_net16_gbe_type_validator;


architecture trb_net16_gbe_type_validator of trb_net16_gbe_type_validator is

--attribute HGROUP : string;
--attribute HGROUP of trb_net16_gbe_type_validator : architecture is "GBE_MAIN_group";

signal result                  : std_logic_vector(c_MAX_FRAME_TYPES - 1 downto 0);
signal ip_result               : std_logic_vector(c_MAX_IP_PROTOCOLS - 1 downto 0);
signal udp_result              : std_logic_vector(c_MAX_UDP_PROTOCOLS - 1 downto 0);
signal partially_valid         : std_logic;  -- only protocols, vlan to be checked

begin

-- DO NOT TOUCH
IP_RESULTS_GEN : for i in 0 to c_MAX_IP_PROTOCOLS - 1 generate

	ip_result(i) <= '1' when (
					IP_PROTOCOLS(i) = IP_PROTOCOLS_IN and
					ALLOWED_IP_PROTOCOLS_IN(i) = '1'
				) else '0';
				
				

end generate IP_RESULTS_GEN;

UDP_RESULTS_GEN : for i in 0 to c_MAX_UDP_PROTOCOLS - 1 generate

	udp_result(i) <= '1' when (
					UDP_PROTOCOLS(i) = UDP_PROTOCOL_IN and
					ALLOWED_UDP_PROTOCOLS_IN(i) = '1'
				) else '0';

end generate UDP_RESULTS_GEN;


RESULT_GEN : for i in 0 to c_MAX_FRAME_TYPES - 1 generate

	result(i) <= '1' when (
				FRAME_TYPES(i) = FRAME_TYPE_IN and 
				ALLOWED_TYPES_IN(i) = '1'
			) else '0';

end generate RESULT_GEN;

PARTIALLY_VALID_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			partially_valid <= '0';
		elsif (FRAME_TYPE_IN = x"0800") then  -- ip frame
			if (IP_PROTOCOLS_IN = x"11") then -- in case of udp inside ip
				partially_valid <= or_all(udp_result);
			elsif (IP_PROTOCOLS_IN = x"01" or IP_PROTOCOLS_IN = x"dd" or IP_PROTOCOLS_IN = x"ee") then  -- in case of ICMP
				partially_valid <= '1';
			else  -- do not accept other protocols than udp and icmp inside ip
				partially_valid <= '0';
			end if;
		else -- other frame
			partially_valid <= or_all(result);			
		end if;
	end if;
end process PARTIALLY_VALID_PROC;

VALID_OUT_PROC : process(partially_valid, SAVED_VLAN_ID_IN, VLAN_ID_IN)
begin
	--if rising_edge(CLK) then
	--	if (RESET = '1') then
	--		VALID_OUT <= '0';
		if (partially_valid = '1') then
			if (SAVED_VLAN_ID_IN = x"0000") then
				VALID_OUT <= '1';
			elsif (VLAN_ID_IN = x"0000_0000") then
				VALID_OUT <= '0';
			elsif (SAVED_VLAN_ID_IN = VLAN_ID_IN(15 downto 0) or SAVED_VLAN_ID_IN = VLAN_ID_IN(31 downto 16)) then
				VALID_OUT <= '1';
			else
				VALID_OUT <= '0';
			end if;
		else
			VALID_OUT <= '0';
		end if;
	--end if;
end process VALID_OUT_PROC;

	--if rising_edge(CLK) then
	--	if (SAVED_VLAN_ID_IN = x"0000") then  -- frame without vlan tag
	--		if (FRAME_TYPE_IN = x"0800") then  -- in case of ip frame
	--			if (IP_PROTOCOLS_IN = x"11") then -- in case of udp inside ip
	--				VALID_OUT <= or_all(udp_result);
	--			elsif (IP_PROTOCOLS_IN = x"01") then  -- in case of ICMP
	--				VALID_OUT <= '1';
	--			else  -- do not accept other protocols than udp inside ip
	--				VALID_OUT <= '0';
	--			end if;
	--		else  -- in case of other frame_type
	--			VALID_OUT <= or_all(result);
	--		end if;
	--		
	--	-- cases for tagged frames
	--	elsif (VLAN_ID_IN = x"0000_0000") then -- no vlan id configured
	--		VALID_OUT <= '0';
	--	elsif (SAVED_VLAN_ID_IN = VLAN_ID_IN(15 downto 0)) then  -- match to first vlan id
	--		if (FRAME_TYPE_IN = x"0800") then  -- in case of ip frame
	--			if (IP_PROTOCOLS_IN = x"11") then -- in case of udp inside ip
	--				VALID_OUT <= or_all(udp_result);
	--			elsif (IP_PROTOCOLS_IN = x"01") then  -- in case of ICMP
	--				VALID_OUT <= '1';
	--			else  -- do not accept other protocols than udp inside ip
	--				VALID_OUT <= '0';
	--			end if;
	--		else  -- in case of other frame_type
	--			VALID_OUT <= or_all(result);
	--		end if;
	--	elsif (SAVED_VLAN_ID_IN = VLAN_ID_IN(31 downto 16)) then  -- match to second vlan id
	--		if (FRAME_TYPE_IN = x"0800") then  -- in case of ip frame
	--			if (IP_PROTOCOLS_IN = x"11") then -- in case of udp inside ip
	--				VALID_OUT <= or_all(udp_result);
	--			elsif (IP_PROTOCOLS_IN = x"01") then  -- in case of ICMP
	--				VALID_OUT <= '1';
	--			else  -- do not accept other protocols than udp inside ip
	--				VALID_OUT <= '0';
	--			end if;
	--		else  -- in case of other frame_type
	--			VALID_OUT <= or_all(result);
	--		end if;
	--	else
	--		VALID_OUT <= '0';
	--	end if;
	--end if;
--end process VALID_OUT_PROC;

end trb_net16_gbe_type_validator;


