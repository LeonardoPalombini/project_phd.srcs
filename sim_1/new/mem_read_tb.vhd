library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

use IEEE.math_real.all;



entity mem_read_tb is
--  Port ( );
end mem_read_tb;

architecture Behavioral of mem_read_tb is

component mem_read_uart is
    Generic(
        MaxMem : natural := 100000;
        NB : natural := 50000000 --115200
    );
    Port (
        clock : in std_logic;
        reset : in std_logic;
        startRead : in std_logic;
        maxNo : in std_logic_vector(natural(ceil(log2(real(MaxMem)))) downto 0);
        readData : in std_logic_vector(31 downto 0);
--        uartRdy : in std_logic;
        uartOut : out std_logic_vector(7 downto 0);
        readAddr :  out std_logic_vector(16 downto 0);
        readBusy : out std_logic;
        uartSend : out std_logic;
        
        --debug signals
        endFlag : out std_logic;
        spyFsm : out std_logic_vector(1 downto 0);
        spyCount : out std_logic_vector(5 downto 0)    
    );
end component;


signal simClk : std_logic;
signal simRst : std_logic;
signal simStart : std_logic;
signal simMaxNo : std_logic_vector(natural(ceil(log2(real(100000)))) downto 0);
signal simMem : std_logic_vector(31 downto 0);
signal simOut : std_logic_vector(7 downto 0);
signal simAddr : std_logic_vector(16 downto 0);
signal simSend : std_logic;
signal simEnd : std_logic;
signal simSpy : std_logic_vector(1 downto 0);
signal simCount : std_logic_vector(5 downto 0);


begin

DUT : mem_read_uart
    port map(
        clock => simClk,
        reset => simRst,
        startRead =>simStart,
        maxNo => simMaxNo,
        readData => simMem,
        uartOut => simOut,
        readAddr => simAddr,
        uartSend => simSend,
        endFlag => simEnd,
        spyFsm => simSpy,
        spyCount => simCount
    );

simMem <= x"aabbccdd" when simAddr = "00000000000000000" else
          x"11223344" when simAddr = "00000000000000001" else
          x"00000000";

test_p : process
begin
    simStart <= '0';
    simRst <= '1';
    simMaxNo <=  std_logic_vector(to_unsigned(100, natural(ceil(log2(real(100000))))+1));
    wait for 100 ns;
    simRst <= '0';
    wait for 200 ns;
    
    simStart <= '1';
    wait for 10 ns;
    simStart <= '0';
    wait;
end process;


clock_p : process
begin
    simClk <= '1';
    wait for 5 ns;
    simClk <= '0';
    wait for 5 ns;    
end process;

end Behavioral;
