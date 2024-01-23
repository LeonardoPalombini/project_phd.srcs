library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

use IEEE.math_real.all;



entity fft_filter_tb is
--  Port ( );
end fft_filter_tb;

architecture Behavioral of fft_filter_tb is

component fft_filter is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        startFilter : in std_logic;
        dataIn : in std_logic_vector(63 downto 0);
        
        dataOut : out std_logic_vector(63 downto 0);
        address : out std_logic_vector(16 downto 0);
        write : out std_logic;
        busy : out std_logic;
        
        -- debug signals
        spyFsm : out std_logic_vector(2 downto 0);
        spy_fft_clk : out std_logic;
        spy_rBusy : out std_logic;
        spy_r_fft_dataIn_valid : out std_logic;
        spy_cBusy : out std_logic;
        spy_fft_dataIn_ready : out std_logic;
        spy_fft_dataOut_valid : out std_logic;
        spy_fft_dataIn_last : out std_logic;
        spy_events : out std_logic_vector(7 downto 0);
        spy_fft_config_tready : out std_logic;
        spyFftData : out std_logic_vector(63 downto 0)
    );
end component;

signal clk : std_logic;
signal rst : std_logic;
signal startFilter : std_logic;
signal dataIn : std_logic_vector(63 downto 0);
signal dataOut : std_logic_vector(63 downto 0);
signal address : std_logic_vector(16 downto 0);
signal write : std_logic;
signal spyFsm : std_logic_vector(2 downto 0);
signal spy_fft_clk : std_logic;
signal spy_rBusy : std_logic;
signal spy_cBusy : std_logic;
signal spy_fft_dataIn_ready : std_logic;
signal spy_fft_dataOut_valid : std_logic;
signal spy_fft_dataIn_last : std_logic;
signal spy_events : std_logic_vector(7 downto 0);
signal spy_fft_config_tready : std_logic;
signal spy_r_fft_dataIn_valid : std_logic;
signal spyFftData : std_logic_vector(63 downto 0);

type arr is array (300 downto 0) of std_logic_vector(63 downto 0);
signal s_mem_r : arr;
signal s_mem_c : arr;

begin

DUT : fft_filter
    port map(
        clk => clk,
        rst => rst,
        startFilter => startFilter,
        dataIn => dataIn,
        
        dataOut => dataOut,
        address => address,
        write => write,
        
        spyFsm => spyFsm,
        spy_fft_clk => spy_fft_clk,
        spy_rBusy => spy_rBusy,
        spy_r_fft_dataIn_valid => spy_r_fft_dataIn_valid,
        spy_cBusy => spy_cBusy,
        spy_fft_dataIn_ready => spy_fft_dataIn_ready,
        spy_fft_dataOut_valid => spy_fft_dataOut_valid,
        spy_fft_dataIn_last => spy_fft_dataIn_last,
        spy_events => spy_events,
        spy_fft_config_tready => spy_fft_config_tready,
        spyFftData => spyFftData
    );

gen_arr : for i in 0 to 300 generate
    s_mem_r(i) <= std_logic_vector(to_unsigned(i+1,64));
    s_mem_c(i) <= std_logic_vector(to_unsigned(i+256,64));
end generate gen_arr;
dataIn <= s_mem_r(to_integer(unsigned(address))) when to_integer(unsigned(address)) < 256 else
          s_mem_c(to_integer(unsigned(address)) / 256);

test_p : process
begin
    rst <= '1';
    startFilter <= '0';
    wait for 5000 ns;
    rst <= '0';
    wait for 300 ns;
    startFilter <= '1';
    wait for 10 ns;
    startFilter <= '0';
    wait;
end process;


main_clock_p : process
begin
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns; 
end process;



end Behavioral;
