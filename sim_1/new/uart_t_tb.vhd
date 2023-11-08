----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.11.2023 22:05:39
-- Design Name: 
-- Module Name: uart_t_tb - Behavioral
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

entity uart_t_tb is
--  Port ( );
end uart_t_tb;

architecture Behavioral of uart_t_tb is

component uart_t is
    generic(
        N : POSITIVE := 4;
        Nbaud : POSITIVE := 2000000
    );
    port(
        send : in std_logic;
        data : in std_logic_vector(N-1 downto 0);
        clk : in std_logic;
        ready : out std_logic;
        uart_t_out : out std_logic;
        bit_count_out : out std_logic_vector(5 downto 0);
        state_probe : out std_logic_vector(1 downto 0)
    );
end component;

signal sysSend : std_logic;
signal sysIn : std_logic_vector(3 downto 0);
signal sysClk : std_logic;
signal uart_ready : std_logic;
signal sysOut : std_logic;
signal checkTmr : std_logic_vector(5 downto 0);
signal checkSts : std_logic_vector(1 downto 0);

begin

DUT : uart_t
    port map(
        send => sysSend,
        data => sysIn,
        clk => sysClk,
        ready => uart_ready,
        uart_t_out => sysOut,
        bit_count_out => checkTmr,
        state_probe => checkSts
    );
    
test_p : process
begin
    sysSend <= '0';
    sysIn <= "1101";
    wait for 100 ns;
    sysSend <= '1';
    wait for 10 ns;
    sysSend <= '0';
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
