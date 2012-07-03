-- VHDL netlist generated by SCUBA Diamond_1.4_Production (87)
-- Module  Version: 6.1
--/opt/lattice/diamond/1.4/ispfpga/bin/lin/scuba -w -lang vhdl -synth synplify -bus_exp 7 -bb -arch ep5c00 -type bram -wp 10 -rp 0011 -rdata_width 72 -data_width 72 -num_rows 1024 -outdata REGISTERED -cascade -1 -e 

-- Sat Mar 10 15:33:04 2012

library IEEE;
use IEEE.std_logic_1164.all;
-- synopsys translate_off
library ecp3;
use ecp3.components.all;
-- synopsys translate_on

entity stats_ram is
    port (
        WrAddress: in  std_logic_vector(9 downto 0); 
        RdAddress: in  std_logic_vector(9 downto 0); 
        Data: in  std_logic_vector(71 downto 0); 
        WE: in  std_logic; 
        RdClock: in  std_logic; 
        RdClockEn: in  std_logic; 
        Reset: in  std_logic; 
        WrClock: in  std_logic; 
        WrClockEn: in  std_logic; 
        Q: out  std_logic_vector(71 downto 0));
end stats_ram;

architecture Structure of stats_ram is

    -- internal signal declarations
    signal scuba_vhi: std_logic;
    signal scuba_vlo: std_logic;

    -- local component declarations
    component VHI
        port (Z: out  std_logic);
    end component;
    component VLO
        port (Z: out  std_logic);
    end component;
    component DP16KC
        generic (GSR : in String; WRITEMODE_B : in String; 
                WRITEMODE_A : in String; CSDECODE_B : in String; 
                CSDECODE_A : in String; REGMODE_B : in String; 
                REGMODE_A : in String; DATA_WIDTH_B : in Integer; 
                DATA_WIDTH_A : in Integer);
        port (DIA0: in  std_logic; DIA1: in  std_logic; 
            DIA2: in  std_logic; DIA3: in  std_logic; 
            DIA4: in  std_logic; DIA5: in  std_logic; 
            DIA6: in  std_logic; DIA7: in  std_logic; 
            DIA8: in  std_logic; DIA9: in  std_logic; 
            DIA10: in  std_logic; DIA11: in  std_logic; 
            DIA12: in  std_logic; DIA13: in  std_logic; 
            DIA14: in  std_logic; DIA15: in  std_logic; 
            DIA16: in  std_logic; DIA17: in  std_logic; 
            ADA0: in  std_logic; ADA1: in  std_logic; 
            ADA2: in  std_logic; ADA3: in  std_logic; 
            ADA4: in  std_logic; ADA5: in  std_logic; 
            ADA6: in  std_logic; ADA7: in  std_logic; 
            ADA8: in  std_logic; ADA9: in  std_logic; 
            ADA10: in  std_logic; ADA11: in  std_logic; 
            ADA12: in  std_logic; ADA13: in  std_logic; 
            CEA: in  std_logic; CLKA: in  std_logic; OCEA: in  std_logic; 
            WEA: in  std_logic; CSA0: in  std_logic; CSA1: in  std_logic; 
            CSA2: in  std_logic; RSTA: in  std_logic; 
            DIB0: in  std_logic; DIB1: in  std_logic; 
            DIB2: in  std_logic; DIB3: in  std_logic; 
            DIB4: in  std_logic; DIB5: in  std_logic; 
            DIB6: in  std_logic; DIB7: in  std_logic; 
            DIB8: in  std_logic; DIB9: in  std_logic; 
            DIB10: in  std_logic; DIB11: in  std_logic; 
            DIB12: in  std_logic; DIB13: in  std_logic; 
            DIB14: in  std_logic; DIB15: in  std_logic; 
            DIB16: in  std_logic; DIB17: in  std_logic; 
            ADB0: in  std_logic; ADB1: in  std_logic; 
            ADB2: in  std_logic; ADB3: in  std_logic; 
            ADB4: in  std_logic; ADB5: in  std_logic; 
            ADB6: in  std_logic; ADB7: in  std_logic; 
            ADB8: in  std_logic; ADB9: in  std_logic; 
            ADB10: in  std_logic; ADB11: in  std_logic; 
            ADB12: in  std_logic; ADB13: in  std_logic; 
            CEB: in  std_logic; CLKB: in  std_logic; OCEB: in  std_logic; 
            WEB: in  std_logic; CSB0: in  std_logic; CSB1: in  std_logic; 
            CSB2: in  std_logic; RSTB: in  std_logic; 
            DOA0: out  std_logic; DOA1: out  std_logic; 
            DOA2: out  std_logic; DOA3: out  std_logic; 
            DOA4: out  std_logic; DOA5: out  std_logic; 
            DOA6: out  std_logic; DOA7: out  std_logic; 
            DOA8: out  std_logic; DOA9: out  std_logic; 
            DOA10: out  std_logic; DOA11: out  std_logic; 
            DOA12: out  std_logic; DOA13: out  std_logic; 
            DOA14: out  std_logic; DOA15: out  std_logic; 
            DOA16: out  std_logic; DOA17: out  std_logic; 
            DOB0: out  std_logic; DOB1: out  std_logic; 
            DOB2: out  std_logic; DOB3: out  std_logic; 
            DOB4: out  std_logic; DOB5: out  std_logic; 
            DOB6: out  std_logic; DOB7: out  std_logic; 
            DOB8: out  std_logic; DOB9: out  std_logic; 
            DOB10: out  std_logic; DOB11: out  std_logic; 
            DOB12: out  std_logic; DOB13: out  std_logic; 
            DOB14: out  std_logic; DOB15: out  std_logic; 
            DOB16: out  std_logic; DOB17: out  std_logic);
    end component;
    attribute MEM_LPC_FILE : string; 
    attribute MEM_INIT_FILE : string; 
    attribute RESETMODE : string; 
    attribute MEM_LPC_FILE of stats_ram_0_0_3 : label is "stats_ram.lpc";
    attribute MEM_INIT_FILE of stats_ram_0_0_3 : label is "";
    attribute RESETMODE of stats_ram_0_0_3 : label is "SYNC";
    attribute MEM_LPC_FILE of stats_ram_0_1_2 : label is "stats_ram.lpc";
    attribute MEM_INIT_FILE of stats_ram_0_1_2 : label is "";
    attribute RESETMODE of stats_ram_0_1_2 : label is "SYNC";
    attribute MEM_LPC_FILE of stats_ram_0_2_1 : label is "stats_ram.lpc";
    attribute MEM_INIT_FILE of stats_ram_0_2_1 : label is "";
    attribute RESETMODE of stats_ram_0_2_1 : label is "SYNC";
    attribute MEM_LPC_FILE of stats_ram_0_3_0 : label is "stats_ram.lpc";
    attribute MEM_INIT_FILE of stats_ram_0_3_0 : label is "";
    attribute RESETMODE of stats_ram_0_3_0 : label is "SYNC";

begin
    -- component instantiation statements
    stats_ram_0_0_3: DP16KC
        generic map (CSDECODE_B=> "0b000", CSDECODE_A=> "0b000", 
        WRITEMODE_B=> "NORMAL", WRITEMODE_A=> "NORMAL", GSR=> "DISABLED", 
        REGMODE_B=> "OUTREG", REGMODE_A=> "OUTREG", DATA_WIDTH_B=>  18, 
        DATA_WIDTH_A=>  18)
        port map (DIA0=>Data(0), DIA1=>Data(1), DIA2=>Data(2), 
            DIA3=>Data(3), DIA4=>Data(4), DIA5=>Data(5), DIA6=>Data(6), 
            DIA7=>Data(7), DIA8=>Data(8), DIA9=>Data(9), DIA10=>Data(10), 
            DIA11=>Data(11), DIA12=>Data(12), DIA13=>Data(13), 
            DIA14=>Data(14), DIA15=>Data(15), DIA16=>Data(16), 
            DIA17=>Data(17), ADA0=>scuba_vhi, ADA1=>scuba_vhi, 
            ADA2=>scuba_vlo, ADA3=>scuba_vlo, ADA4=>WrAddress(0), 
            ADA5=>WrAddress(1), ADA6=>WrAddress(2), ADA7=>WrAddress(3), 
            ADA8=>WrAddress(4), ADA9=>WrAddress(5), ADA10=>WrAddress(6), 
            ADA11=>WrAddress(7), ADA12=>WrAddress(8), 
            ADA13=>WrAddress(9), CEA=>WrClockEn, CLKA=>WrClock, 
            OCEA=>WrClockEn, WEA=>WE, CSA0=>scuba_vlo, CSA1=>scuba_vlo, 
            CSA2=>scuba_vlo, RSTA=>Reset, DIB0=>scuba_vlo, 
            DIB1=>scuba_vlo, DIB2=>scuba_vlo, DIB3=>scuba_vlo, 
            DIB4=>scuba_vlo, DIB5=>scuba_vlo, DIB6=>scuba_vlo, 
            DIB7=>scuba_vlo, DIB8=>scuba_vlo, DIB9=>scuba_vlo, 
            DIB10=>scuba_vlo, DIB11=>scuba_vlo, DIB12=>scuba_vlo, 
            DIB13=>scuba_vlo, DIB14=>scuba_vlo, DIB15=>scuba_vlo, 
            DIB16=>scuba_vlo, DIB17=>scuba_vlo, ADB0=>scuba_vlo, 
            ADB1=>scuba_vlo, ADB2=>scuba_vlo, ADB3=>scuba_vlo, 
            ADB4=>RdAddress(0), ADB5=>RdAddress(1), ADB6=>RdAddress(2), 
            ADB7=>RdAddress(3), ADB8=>RdAddress(4), ADB9=>RdAddress(5), 
            ADB10=>RdAddress(6), ADB11=>RdAddress(7), 
            ADB12=>RdAddress(8), ADB13=>RdAddress(9), CEB=>RdClockEn, 
            CLKB=>RdClock, OCEB=>RdClockEn, WEB=>scuba_vlo, 
            CSB0=>scuba_vlo, CSB1=>scuba_vlo, CSB2=>scuba_vlo, 
            RSTB=>Reset, DOA0=>open, DOA1=>open, DOA2=>open, DOA3=>open, 
            DOA4=>open, DOA5=>open, DOA6=>open, DOA7=>open, DOA8=>open, 
            DOA9=>open, DOA10=>open, DOA11=>open, DOA12=>open, 
            DOA13=>open, DOA14=>open, DOA15=>open, DOA16=>open, 
            DOA17=>open, DOB0=>Q(0), DOB1=>Q(1), DOB2=>Q(2), DOB3=>Q(3), 
            DOB4=>Q(4), DOB5=>Q(5), DOB6=>Q(6), DOB7=>Q(7), DOB8=>Q(8), 
            DOB9=>Q(9), DOB10=>Q(10), DOB11=>Q(11), DOB12=>Q(12), 
            DOB13=>Q(13), DOB14=>Q(14), DOB15=>Q(15), DOB16=>Q(16), 
            DOB17=>Q(17));

    stats_ram_0_1_2: DP16KC
        generic map (CSDECODE_B=> "0b000", CSDECODE_A=> "0b000", 
        WRITEMODE_B=> "NORMAL", WRITEMODE_A=> "NORMAL", GSR=> "DISABLED", 
        REGMODE_B=> "OUTREG", REGMODE_A=> "OUTREG", DATA_WIDTH_B=>  18, 
        DATA_WIDTH_A=>  18)
        port map (DIA0=>Data(18), DIA1=>Data(19), DIA2=>Data(20), 
            DIA3=>Data(21), DIA4=>Data(22), DIA5=>Data(23), 
            DIA6=>Data(24), DIA7=>Data(25), DIA8=>Data(26), 
            DIA9=>Data(27), DIA10=>Data(28), DIA11=>Data(29), 
            DIA12=>Data(30), DIA13=>Data(31), DIA14=>Data(32), 
            DIA15=>Data(33), DIA16=>Data(34), DIA17=>Data(35), 
            ADA0=>scuba_vhi, ADA1=>scuba_vhi, ADA2=>scuba_vlo, 
            ADA3=>scuba_vlo, ADA4=>WrAddress(0), ADA5=>WrAddress(1), 
            ADA6=>WrAddress(2), ADA7=>WrAddress(3), ADA8=>WrAddress(4), 
            ADA9=>WrAddress(5), ADA10=>WrAddress(6), ADA11=>WrAddress(7), 
            ADA12=>WrAddress(8), ADA13=>WrAddress(9), CEA=>WrClockEn, 
            CLKA=>WrClock, OCEA=>WrClockEn, WEA=>WE, CSA0=>scuba_vlo, 
            CSA1=>scuba_vlo, CSA2=>scuba_vlo, RSTA=>Reset, 
            DIB0=>scuba_vlo, DIB1=>scuba_vlo, DIB2=>scuba_vlo, 
            DIB3=>scuba_vlo, DIB4=>scuba_vlo, DIB5=>scuba_vlo, 
            DIB6=>scuba_vlo, DIB7=>scuba_vlo, DIB8=>scuba_vlo, 
            DIB9=>scuba_vlo, DIB10=>scuba_vlo, DIB11=>scuba_vlo, 
            DIB12=>scuba_vlo, DIB13=>scuba_vlo, DIB14=>scuba_vlo, 
            DIB15=>scuba_vlo, DIB16=>scuba_vlo, DIB17=>scuba_vlo, 
            ADB0=>scuba_vlo, ADB1=>scuba_vlo, ADB2=>scuba_vlo, 
            ADB3=>scuba_vlo, ADB4=>RdAddress(0), ADB5=>RdAddress(1), 
            ADB6=>RdAddress(2), ADB7=>RdAddress(3), ADB8=>RdAddress(4), 
            ADB9=>RdAddress(5), ADB10=>RdAddress(6), ADB11=>RdAddress(7), 
            ADB12=>RdAddress(8), ADB13=>RdAddress(9), CEB=>RdClockEn, 
            CLKB=>RdClock, OCEB=>RdClockEn, WEB=>scuba_vlo, 
            CSB0=>scuba_vlo, CSB1=>scuba_vlo, CSB2=>scuba_vlo, 
            RSTB=>Reset, DOA0=>open, DOA1=>open, DOA2=>open, DOA3=>open, 
            DOA4=>open, DOA5=>open, DOA6=>open, DOA7=>open, DOA8=>open, 
            DOA9=>open, DOA10=>open, DOA11=>open, DOA12=>open, 
            DOA13=>open, DOA14=>open, DOA15=>open, DOA16=>open, 
            DOA17=>open, DOB0=>Q(18), DOB1=>Q(19), DOB2=>Q(20), 
            DOB3=>Q(21), DOB4=>Q(22), DOB5=>Q(23), DOB6=>Q(24), 
            DOB7=>Q(25), DOB8=>Q(26), DOB9=>Q(27), DOB10=>Q(28), 
            DOB11=>Q(29), DOB12=>Q(30), DOB13=>Q(31), DOB14=>Q(32), 
            DOB15=>Q(33), DOB16=>Q(34), DOB17=>Q(35));

    stats_ram_0_2_1: DP16KC
        generic map (CSDECODE_B=> "0b000", CSDECODE_A=> "0b000", 
        WRITEMODE_B=> "NORMAL", WRITEMODE_A=> "NORMAL", GSR=> "DISABLED", 
        REGMODE_B=> "OUTREG", REGMODE_A=> "OUTREG", DATA_WIDTH_B=>  18, 
        DATA_WIDTH_A=>  18)
        port map (DIA0=>Data(36), DIA1=>Data(37), DIA2=>Data(38), 
            DIA3=>Data(39), DIA4=>Data(40), DIA5=>Data(41), 
            DIA6=>Data(42), DIA7=>Data(43), DIA8=>Data(44), 
            DIA9=>Data(45), DIA10=>Data(46), DIA11=>Data(47), 
            DIA12=>Data(48), DIA13=>Data(49), DIA14=>Data(50), 
            DIA15=>Data(51), DIA16=>Data(52), DIA17=>Data(53), 
            ADA0=>scuba_vhi, ADA1=>scuba_vhi, ADA2=>scuba_vlo, 
            ADA3=>scuba_vlo, ADA4=>WrAddress(0), ADA5=>WrAddress(1), 
            ADA6=>WrAddress(2), ADA7=>WrAddress(3), ADA8=>WrAddress(4), 
            ADA9=>WrAddress(5), ADA10=>WrAddress(6), ADA11=>WrAddress(7), 
            ADA12=>WrAddress(8), ADA13=>WrAddress(9), CEA=>WrClockEn, 
            CLKA=>WrClock, OCEA=>WrClockEn, WEA=>WE, CSA0=>scuba_vlo, 
            CSA1=>scuba_vlo, CSA2=>scuba_vlo, RSTA=>Reset, 
            DIB0=>scuba_vlo, DIB1=>scuba_vlo, DIB2=>scuba_vlo, 
            DIB3=>scuba_vlo, DIB4=>scuba_vlo, DIB5=>scuba_vlo, 
            DIB6=>scuba_vlo, DIB7=>scuba_vlo, DIB8=>scuba_vlo, 
            DIB9=>scuba_vlo, DIB10=>scuba_vlo, DIB11=>scuba_vlo, 
            DIB12=>scuba_vlo, DIB13=>scuba_vlo, DIB14=>scuba_vlo, 
            DIB15=>scuba_vlo, DIB16=>scuba_vlo, DIB17=>scuba_vlo, 
            ADB0=>scuba_vlo, ADB1=>scuba_vlo, ADB2=>scuba_vlo, 
            ADB3=>scuba_vlo, ADB4=>RdAddress(0), ADB5=>RdAddress(1), 
            ADB6=>RdAddress(2), ADB7=>RdAddress(3), ADB8=>RdAddress(4), 
            ADB9=>RdAddress(5), ADB10=>RdAddress(6), ADB11=>RdAddress(7), 
            ADB12=>RdAddress(8), ADB13=>RdAddress(9), CEB=>RdClockEn, 
            CLKB=>RdClock, OCEB=>RdClockEn, WEB=>scuba_vlo, 
            CSB0=>scuba_vlo, CSB1=>scuba_vlo, CSB2=>scuba_vlo, 
            RSTB=>Reset, DOA0=>open, DOA1=>open, DOA2=>open, DOA3=>open, 
            DOA4=>open, DOA5=>open, DOA6=>open, DOA7=>open, DOA8=>open, 
            DOA9=>open, DOA10=>open, DOA11=>open, DOA12=>open, 
            DOA13=>open, DOA14=>open, DOA15=>open, DOA16=>open, 
            DOA17=>open, DOB0=>Q(36), DOB1=>Q(37), DOB2=>Q(38), 
            DOB3=>Q(39), DOB4=>Q(40), DOB5=>Q(41), DOB6=>Q(42), 
            DOB7=>Q(43), DOB8=>Q(44), DOB9=>Q(45), DOB10=>Q(46), 
            DOB11=>Q(47), DOB12=>Q(48), DOB13=>Q(49), DOB14=>Q(50), 
            DOB15=>Q(51), DOB16=>Q(52), DOB17=>Q(53));

    scuba_vhi_inst: VHI
        port map (Z=>scuba_vhi);

    scuba_vlo_inst: VLO
        port map (Z=>scuba_vlo);

    stats_ram_0_3_0: DP16KC
        generic map (CSDECODE_B=> "0b000", CSDECODE_A=> "0b000", 
        WRITEMODE_B=> "NORMAL", WRITEMODE_A=> "NORMAL", GSR=> "DISABLED", 
        REGMODE_B=> "OUTREG", REGMODE_A=> "OUTREG", DATA_WIDTH_B=>  18, 
        DATA_WIDTH_A=>  18)
        port map (DIA0=>Data(54), DIA1=>Data(55), DIA2=>Data(56), 
            DIA3=>Data(57), DIA4=>Data(58), DIA5=>Data(59), 
            DIA6=>Data(60), DIA7=>Data(61), DIA8=>Data(62), 
            DIA9=>Data(63), DIA10=>Data(64), DIA11=>Data(65), 
            DIA12=>Data(66), DIA13=>Data(67), DIA14=>Data(68), 
            DIA15=>Data(69), DIA16=>Data(70), DIA17=>Data(71), 
            ADA0=>scuba_vhi, ADA1=>scuba_vhi, ADA2=>scuba_vlo, 
            ADA3=>scuba_vlo, ADA4=>WrAddress(0), ADA5=>WrAddress(1), 
            ADA6=>WrAddress(2), ADA7=>WrAddress(3), ADA8=>WrAddress(4), 
            ADA9=>WrAddress(5), ADA10=>WrAddress(6), ADA11=>WrAddress(7), 
            ADA12=>WrAddress(8), ADA13=>WrAddress(9), CEA=>WrClockEn, 
            CLKA=>WrClock, OCEA=>WrClockEn, WEA=>WE, CSA0=>scuba_vlo, 
            CSA1=>scuba_vlo, CSA2=>scuba_vlo, RSTA=>Reset, 
            DIB0=>scuba_vlo, DIB1=>scuba_vlo, DIB2=>scuba_vlo, 
            DIB3=>scuba_vlo, DIB4=>scuba_vlo, DIB5=>scuba_vlo, 
            DIB6=>scuba_vlo, DIB7=>scuba_vlo, DIB8=>scuba_vlo, 
            DIB9=>scuba_vlo, DIB10=>scuba_vlo, DIB11=>scuba_vlo, 
            DIB12=>scuba_vlo, DIB13=>scuba_vlo, DIB14=>scuba_vlo, 
            DIB15=>scuba_vlo, DIB16=>scuba_vlo, DIB17=>scuba_vlo, 
            ADB0=>scuba_vlo, ADB1=>scuba_vlo, ADB2=>scuba_vlo, 
            ADB3=>scuba_vlo, ADB4=>RdAddress(0), ADB5=>RdAddress(1), 
            ADB6=>RdAddress(2), ADB7=>RdAddress(3), ADB8=>RdAddress(4), 
            ADB9=>RdAddress(5), ADB10=>RdAddress(6), ADB11=>RdAddress(7), 
            ADB12=>RdAddress(8), ADB13=>RdAddress(9), CEB=>RdClockEn, 
            CLKB=>RdClock, OCEB=>RdClockEn, WEB=>scuba_vlo, 
            CSB0=>scuba_vlo, CSB1=>scuba_vlo, CSB2=>scuba_vlo, 
            RSTB=>Reset, DOA0=>open, DOA1=>open, DOA2=>open, DOA3=>open, 
            DOA4=>open, DOA5=>open, DOA6=>open, DOA7=>open, DOA8=>open, 
            DOA9=>open, DOA10=>open, DOA11=>open, DOA12=>open, 
            DOA13=>open, DOA14=>open, DOA15=>open, DOA16=>open, 
            DOA17=>open, DOB0=>Q(54), DOB1=>Q(55), DOB2=>Q(56), 
            DOB3=>Q(57), DOB4=>Q(58), DOB5=>Q(59), DOB6=>Q(60), 
            DOB7=>Q(61), DOB8=>Q(62), DOB9=>Q(63), DOB10=>Q(64), 
            DOB11=>Q(65), DOB12=>Q(66), DOB13=>Q(67), DOB14=>Q(68), 
            DOB15=>Q(69), DOB16=>Q(70), DOB17=>Q(71));

end Structure;

-- synopsys translate_off
library ecp3;
configuration Structure_CON of stats_ram is
    for Structure
        for all:VHI use entity ecp3.VHI(V); end for;
        for all:VLO use entity ecp3.VLO(V); end for;
        for all:DP16KC use entity ecp3.DP16KC(V); end for;
    end for;
end Structure_CON;

-- synopsys translate_on
