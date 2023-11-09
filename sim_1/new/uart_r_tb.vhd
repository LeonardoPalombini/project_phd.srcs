----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.11.2023 14:09:56
-- Design Name: 
-- Module Name: uart_r_tb - Behavioral
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

entity uart_r_tb is
--  Port ( );
end uart_r_tb;

architecture Behavioral of uart_r_tb is

component uart_r is
    Generic(
        N : POSITIVE := 4;
        Nbaud : POSITIVE := 2000000
    );
    Port(
        clk : in std_logic;
        dataIn : in std_logic;
        dataOut : out std_logic_vector(N-1 downto 0);
        ready : out std_logic;
        bit_count_out : out std_logic_vector(5 downto 0);
        half_count_out : out std_logic_vector(4 downto 0);
        state_probe : out std_logic_vector(1 downto 0)
--        rDataFin_t : out std_logic_vector(N-1 downto 0)
    );
end component;

signal sysClk : std_logic;
signal sysIn : std_logic;
signal sysRdy : std_logic;
signal sysOut : std_logic_vector(3 downto 0);
signal checkBitCtr : std_logic_vector(5 downto 0);
signal checkHalfPtr : std_logic_vector(4 downto 0);
signal checkStt : std_logic_vector(1 downto 0);
--signal checkFin : std_logic_vector(3 downto 0);

begin

DUT : uart_r
    port map(
        clk => sysClk,
        dataIn => sysIn,
        dataOut => sysOut,
        ready => sysRdy,
        bit_count_out => checkBitCtr,
        half_count_out => checkHalfPtr,
        state_probe => checkStt
        --rDataFin_t => checkFin
    );


test_p : process
begin
    sysIn <= '1';
    wait for 500 ns;
    sysIn <= '0';
    wait for 500 ns;
    sysIn <= '1';
    wait for 500 ns;
    sysIn <= '0';
    wait for 500 ns;
    sysIn <= '1';
    wait for 500 ns;
    sysIn <= '1';
    wait for 1000 ns;
    
    sysIn <= '0';
    wait for 500 ns;
    sysIn <= '0';
    wait for 500 ns;
    sysIn <= '1';
    wait for 500 ns;
    sysIn <= '0';
    wait for 500 ns;
    sysIn <= '1';
    wait for 1000 ns;
    wait;
end process;

clock_p : process
begin
    sysClk <= '1';
    wait for 5 ns;
    sysClk <= '0';
    wait for 5 ns;    
end process;

end Behavioral;
