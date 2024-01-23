library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

use IEEE.math_real.all;



entity fft_row_tb is
--  Port ( );
end fft_row_tb;

architecture Behavioral of fft_row_tb is

component fft_row is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        fft_clock : in std_logic;
        start : in std_logic;
        memData : in std_logic_vector(31 downto 0);
        fft_dataIn_ready : in std_logic;
        fft_dataOut_valid : in std_logic;
        fftResult : in std_logic_vector(31 downto 0);
        fft_dataIn_valid : out std_logic;
        fft_dataOut_ready : out std_logic;
        memAddr : out std_logic_vector(16 downto 0);
        memWrite : out std_logic;
        fftData : out std_logic_vector(31 downto 0);
        fftDataLast : out std_logic;
        memResWrite : out std_logic_vector(31 downto 0);
        
        --debug signals
        spyFsm : out std_logic_vector(2 downto 0)
    );
end component;


signal clk : std_logic;
signal rst : std_logic;
signal fft_clock : std_logic;
signal start : std_logic;
signal memData : std_logic_vector(31 downto 0);
signal fft_dataIn_ready : std_logic;
signal fft_dataOut_valid : std_logic;
signal fftResult : std_logic_vector(31 downto 0);
signal fft_dataIn_valid : std_logic;
signal fft_dataOut_ready : std_logic;
signal memAddr : std_logic_vector(16 downto 0);
signal memWrite : std_logic;
signal fftData : std_logic_vector(31 downto 0);
signal fftDataLast : std_logic;
signal memResWrite : std_logic_vector(31 downto 0);
signal spyFsm : std_logic_vector(2 downto 0);

type arr is array (8 downto 0) of std_logic_vector(31 downto 0);
signal data : arr;

begin
data(0) <= x"aaaaaaaa";
data(1) <= x"bbbbbbbb";
data(2) <= x"cccccccc";
data(3) <= x"dddddddd";
data(4) <= x"eeeeeeee";

data(5) <= x"12121212";
data(6) <= x"13131313";
data(7) <= x"14141414";
data(8) <= x"15151515";

DUT : fft_row
    port map (
        clk => clk,
        rst => rst,
        fft_clock => fft_clock,
        start => start,
        memData => memData,
        fft_dataIn_ready => fft_dataIn_ready,
        fft_dataOut_valid => fft_dataOut_valid,
        fftResult => fftResult,
        fft_dataIn_valid => fft_dataIn_valid,
        fft_dataOut_ready => fft_dataOut_ready,
        memAddr => memAddr,
        memWrite => memWrite,
        fftData => fftData,
        fftDataLast => fftDataLast,
        memResWrite => memResWrite,
        spyFsm => spyFsm
    );


test_p : process
begin
    start <= '0';
    rst <= '0';
    fft_dataIn_ready <= '1';
    fft_dataOut_valid <= '0';
    fftResult <= (others => '0');
    wait for 300 ns;
    start <= '1';
    wait for 10 ns;
    start <= '0';
--    wait for 300 ns;
--    fft_dataIn_ready <= '0';
--    wait for 100 ns;
--    fft_dataIn_ready <= '1';
    wait until fft_dataIn_valid = '0';
    wait for 600 ns;
    wait until rising_edge(fft_clock);
    fft_dataOut_valid <= '1';
    fftResult <= x"11111111";
    wait until rising_edge(fft_clock);
    fftResult <= x"22222222";
    wait until rising_edge(fft_clock);
    fftResult <= x"33333333";
    wait until rising_edge(fft_clock);
    fft_dataOut_valid <= '0';
    fftResult <= (others => '0');
    wait until falling_edge(fft_dataIn_valid);
    wait for 700 ns;
    fft_dataOut_valid <= '1';
    fftResult <= x"11111111";
    wait until rising_edge(fft_clock);
    fftResult <= x"22222222";
    wait until rising_edge(fft_clock);
    fftResult <= x"33333333";
    wait until rising_edge(fft_clock);
    fft_dataOut_valid <= '0';
    fftResult <= (others => '0');
    wait until falling_edge(fft_dataIn_valid);
    wait for 700 ns;
    fft_dataOut_valid <= '1';
    fftResult <= x"11111111";
    wait until rising_edge(fft_clock);
    fftResult <= x"22222222";
    wait until rising_edge(fft_clock);
    fftResult <= x"33333333";
    wait until rising_edge(fft_clock);
    fft_dataOut_valid <= '0';
    fftResult <= (others => '0');
    wait;
end process;

main_clock_p : process
begin
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns; 
end process;

fft_clock_p : process
begin
    fft_clock <= '1';
    wait for 50 ns;
    fft_clock <= '0';
    wait for 50 ns;
end process;

memData <= data(0) when memAddr = "00000000000000000" else
           data(1) when memAddr = "00000000000000001" else
           data(2) when memAddr = "00000000000000010" else
           data(3) when memAddr = "00000000000000011" else
           data(4) when memAddr = "00000000000000100" else
           data(5) when memAddr = "00000000000000101" else
           data(6) when memAddr = "00000000000000110" else
           data(7) when memAddr = "00000000000000111" else
           data(8) when memAddr = "00000000000001000" else
           x"00000000";

--data(0) <= memResWrite when memAddr = "00000000000000000" and fft_dataOut_valid <= '1';
--data(1) <= memResWrite when memAddr = "00000000000000001" and fft_dataOut_valid <= '1';
--data(2) <= memResWrite when memAddr = "00000000000000010" and fft_dataOut_valid <= '1';
--data(3) <= memResWrite when memAddr = "00000000000000011" and fft_dataOut_valid <= '1';
--data(4) <= memResWrite when memAddr = "00000000000000100" and fft_dataOut_valid <= '1';

end Behavioral;
