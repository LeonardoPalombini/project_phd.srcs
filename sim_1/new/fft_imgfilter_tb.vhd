library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

use IEEE.math_real.all;




entity fft_imgfilter_tb is
--  Port ( );
end fft_imgfilter_tb;

architecture Behavioral of fft_imgfilter_tb is

component fft_imgfilter is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        fft_clk : in std_logic;
        start : in std_logic;
        dataIn : in std_logic_vector(63 downto 0);
        
        busy : out std_logic;
        addrOut : out std_logic_vector(16 downto 0);
        dataOut : out std_logic_vector(63 downto 0);
        dataWrite : out std_logic
    );
end component;

signal clk : std_logic;
signal rst : std_logic;
signal fft_clk : std_logic;
signal start : std_logic;
signal dataIn : std_logic_vector(63 downto 0);
signal busy : std_logic;     
signal addrOut : std_logic_vector(16 downto 0);
signal dataOut : std_logic_vector(63 downto 0);
signal dataWrite : std_logic;

type arr is array(4 downto 0) of std_logic_vector(63 downto 0);
signal mem : arr;

begin

DUT : fft_imgfilter
    port map(
        clk => clk,
        rst => rst,
        fft_clk => fft_clk,
        start => start,
        dataIn => dataIn,
        busy => busy,
        addrOut => addrOut,
        dataOut => dataOut,
        dataWrite => dataWrite
    );


mem(0) <= x"12345678431c0000";
mem(1) <= x"123456783f800000";
mem(2) <= x"12345678453b8000";
mem(3) <= x"12345678c47a0000";
mem(4) <= x"1234567845bb8000";


test_p : process
begin
    rst <= '1';
    start <= '0';
    wait for 200 ns;
    rst <= '0';
    wait for 200 ns;
    start <= '1';
    wait;
end process;

dataIn <= mem(to_integer(unsigned(addrOut)));

main_clock_p : process
begin
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns; 
end process;

fft_clock_p : process
begin
    fft_clk <= '1';
    wait for 50 ns;
    fft_clk <= '0';
    wait for 50 ns;
end process;

end Behavioral;
