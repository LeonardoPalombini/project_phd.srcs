library IEEE;
library ieee_proposed;

use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

use IEEE.math_real.all;



entity top_tb is
--  Port ( );
end top_tb;

architecture Behavioral of top_tb is

component top is
    Port (
        sysClk : in std_logic;
        sysRst : in std_logic;
        sysIn : in std_logic;
--        switch : in std_logic;
        sysOut : out std_logic;
        ledIdle : out std_logic;
        ledRec : out std_logic;
        ledSend : out std_logic;
        ledUart : out std_logic;
        ledFilter : out std_logic;
        
        -- debug signals
        spyReady : out std_logic;
        spyRead : out std_logic_vector(1 downto 0);
        spyWrite : out std_logic_vector(2 downto 0);
        spyCount : out std_logic_vector(17 downto 0);
        spyData : out std_logic_vector(63 downto 0);
        spyFftClk : out std_logic;
        spyFftAddr : out std_logic_vector(16 downto 0);
        spyFft : out std_logic_vector(2 downto 0)
    );
end component;

signal clock : std_logic;
signal reset : std_logic;
signal input : std_logic := '1';
signal output : std_logic;

type arr is array (4*256+4-1 downto 0) of std_logic_vector(7 downto 0);
signal message : arr;

type mess is array (255 downto 0) of std_logic_vector(31 downto 0);
signal mess_spf : mess;

signal arrIndex : natural := 0;

signal spyReady : std_logic;
--signal spyRead : std_logic_vector(1 downto 0);
--signal spyWrite : std_logic_vector(2 downto 0);
signal spyCount : std_logic_vector(17 downto 0);
signal spyData : std_logic_vector(63 downto 0);
signal spyFftClk : std_logic;
signal spyFftAddr : std_logic_vector(16 downto 0);
signal spyFft : std_logic_vector(2 downto 0);

signal ledIdle : std_logic;
signal ledRec : std_logic;
signal ledSend : std_logic;
signal ledUart : std_logic;
signal ledFilter : std_logic;

begin

gen_float : for i in 0 to 63 generate
    mess_spf(i) <= x"3f000000";
    mess_spf(i+64) <= x"bf19999a";
    mess_spf(i+128) <= x"bdcccccd";
    mess_spf(i+192) <= x"3f4ccccd";
end generate gen_float;

message(0) <= "00000000";
message(1) <= "11111111";
gen_arr : for i in 2 to 4*256+1 generate
    message(i) <= mess_spf(natural(floor(real(i-2)/4.0)))(8*((i-2) mod 4)+7 downto 8*((i-2) mod 4));
end generate gen_arr;
message(4*256+2) <= "00000000";
message(4*256+3) <= "11111111";

DUT : top
    port map(
        sysClk => clock,
        sysRst => reset,
        sysIn => input,
        sysOut => output,
        spyReady => spyReady,
--        spyRead => spyRead,
--        spyWrite => spyWrite,
        spyData => spyData,
        spyCount => spyCount,
        spyFftClk => spyFftClk,
        spyFftAddr => spyFftAddr,
        spyFft => spyFft,
        ledIdle => ledIdle,
        ledRec => ledRec,
        ledSend => ledSend,
        ledUart => ledUart,
        ledFilter => ledFilter
    );


clock_p : process
begin
    clock <= '1';
    wait for 5 ns;
    clock <= '0';
    wait for 5 ns;    
end process;


nx_state_p : process
begin
    reset <= '1';
    wait for 100 ns;
    reset <= '0';
    for i in 0 to 4*256+3 loop --259
        input <= '1';
        wait for 600 ns;
        input <= '0';
        wait for 220 ns;
        input <= message(arrIndex)(0);
        wait for 220 ns;
        input <= message(arrIndex)(1);
        wait for 220 ns;
        input <= message(arrIndex)(2);
        wait for 220 ns;
        input <= message(arrIndex)(3);
        wait for 220 ns;
        input <= message(arrIndex)(4);
        wait for 220 ns;
        input <= message(arrIndex)(5);
        wait for 220 ns;
        input <= message(arrIndex)(6);
        wait for 220 ns;
        input <= message(arrIndex)(7);
        wait for 220 ns;
        input <= '1';
        wait for 220 ns;
        arrIndex <= arrIndex + 1;
    end loop;
        input <= '1';
        wait for 50000 ns;
        wait;
end process;

end Behavioral;
