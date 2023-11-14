----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2023 09:46:59
-- Design Name: 
-- Module Name: top_tb - Behavioral
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

entity top_tb is
--  Port ( );
end top_tb;

architecture Behavioral of top_tb is

component top is
    Port (
        sysClk : in std_logic;
        sysRst : in std_logic;
        sysIn : in std_logic;
        sysOut : out std_logic
    );
end component;

signal clock : std_logic;
signal reset : std_logic;
signal input : std_logic;
signal output : std_logic;

begin

DUT : top
    port map(
        sysClk => clock,
        sysRst => reset,
        sysIn => input,
        sysOut => output
    );


test_p : process
begin
    reset <= '0';
    input <= '1';
    wait for 1000 ns;
    
    input <= '0';
    wait for 500 ns;
    
    input <= '1';
    wait for 500 ns;
    input <= '1';
    wait for 500 ns;
    input <= '0';
    wait for 500 ns;
    input <= '1';
    wait for 500 ns;
    input <= '0';
    wait for 500 ns;
    input <= '0';
    wait for 500 ns;
    input <= '1';
    wait for 500 ns;
    input <= '0';
    wait for 500 ns;
    
    input <= '1';
    wait;
end process;

clock_p : process
begin
    clock <= '1';
    wait for 5 ns;
    clock <= '0';
    wait for 5 ns;    
end process;

end Behavioral;
