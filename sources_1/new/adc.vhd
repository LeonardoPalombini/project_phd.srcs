----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.11.2023 14:36:48
-- Design Name: 
-- Module Name: adc - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adc is
    port(
        clk : in std_logic;
        reset : in std_logic;
        Vp : in std_logic;
        Vn : in std_logic;
        data_out : out std_logic_vector(15 downto 0);
        data_ready : out std_logic
    );
end adc;

architecture Behavioral of adc is


COMPONENT xadc_wiz_0
  PORT (
    di_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    daddr_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    den_in : IN STD_LOGIC;
    dwe_in : IN STD_LOGIC;
    drdy_out : OUT STD_LOGIC;
    do_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dclk_in : IN STD_LOGIC;
    reset_in : IN STD_LOGIC;
    vp_in : IN STD_LOGIC;
    vn_in : IN STD_LOGIC;
    channel_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    eoc_out : OUT STD_LOGIC;
    alarm_out : OUT STD_LOGIC;
    eos_out : OUT STD_LOGIC;
    busy_out : OUT STD_LOGIC 
  );
END COMPONENT;

signal drp_in : std_logic_vector(15 downto 0) := (others => '0');
signal address : std_logic_vector(6 DOWNTO 0) := "0000011"; --addr of Vp-Vn channel
signal ready : std_logic;
signal adc_data : std_logic_vector(15 downto 0);
signal eoc : std_logic;


begin


xadc_instance : xadc_wiz_0
  PORT MAP (
    di_in => drp_in,
    daddr_in => address,
    den_in => eoc,
    dwe_in => '0',
    drdy_out => ready,
    do_out => adc_data,
    dclk_in => clk,
    reset_in => reset,
    vp_in => Vp,
    vn_in => Vn,
--    channel_out => channel_out,
    eoc_out => eoc
--    alarm_out => alarm_out,
--    eos_out => eos_out,
--    busy_out => busy_out
  );


read_data_p : process(clk)
begin
    if(rising_edge(clk)) then
        if(reset = '1') then
            data_out <= (others => '0');
        elsif(ready = '1') then
            data_out <= adc_data;
        end if;
    end if;
end process;

data_ready <= ready;

end Behavioral;
