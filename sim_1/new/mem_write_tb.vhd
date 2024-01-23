----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.01.2024 16:19:13
-- Design Name: 
-- Module Name: mem_write_tb - Behavioral
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

entity mem_write_tb is
--  Port ( );
end mem_write_tb;

architecture Behavioral of mem_write_tb is

component mem_write_uart is
    Port (
        clock : in std_logic;
        reset : in std_logic;
        uartIn : in std_logic_vector(7 downto 0);
        uartRdy : in std_logic;
        writeMem : out std_logic;
        writeAddr :  out std_logic_vector(16 downto 0);
        writeBusy : out std_logic;
        dataOut : out std_logic_vector(31 downto 0);
        --debug signals
        memBusy : out std_logic_vector(2 downto 0);
        addrSig : out std_logic_vector(16 downto 0);
        stopSig : out std_logic      
    );
end component;

signal simClk : std_logic;
signal simRst : std_logic;
signal simIn : std_logic_vector(7 downto 0);
signal simRdy : std_logic;
signal simBusy : std_logic_vector(2 downto 0);
signal simOut : std_logic_vector(31 downto 0);
signal simStop : std_logic;
signal simAddr : std_logic_vector(16 downto 0);
signal simWrite: std_logic;

begin

DUT : mem_write_uart
    port map(
        clock => simClk,
        reset => simRst,
        uartIn => simIn,
        dataOut => simOut,
        uartRdy => simRdy,
        memBusy => simBusy,
        writeAddr => simAddr,
        stopSig => simStop,
        writeMem => simWrite
    );
    

test_p : process
begin
    simRdy <= '1';
    simRst <= '1';
    wait for 100 ns;
    simRdy <= '0';
    simRst <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= "00110101";
    wait for 50 ns;
    simRdy <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= x"00";
    wait for 50 ns;
    simRdy <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= x"ff";
    
    wait for 50 ns;
    simRdy <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= x"aa";
    wait for 50 ns;
    simRdy <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= x"bb";
    wait for 50 ns;
    simRdy <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= x"cc";
    wait for 50 ns;
    simRdy <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= x"dd";
    
     wait for 50 ns;
    simRdy <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= x"11";
    wait for 50 ns;
    simRdy <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= x"22";
    wait for 50 ns;
    simRdy <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= x"33";
    wait for 50 ns;
    simRdy <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= x"44";
    
    wait for 50 ns;
    simRdy <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= "00000000";
    wait for 50 ns;
    simRdy <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= "11111111";
    
    wait for 50 ns;
    simRdy <= '0';
    wait for 200 ns;
    simRdy <= '1';
    simIn <= "00111001";
    wait for 200 ns;
    simIn <= "00000000";
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
