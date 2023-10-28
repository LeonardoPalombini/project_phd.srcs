----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.10.2023 20:02:26
-- Design Name: 
-- Module Name: uart - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

use IEEE.math_real.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_t is
    Generic(
        Nbit : POSITIVE := 8;
        Nbaud : POSITIVE := 9600;
    );
    Port(
        send : in std_logic;
        data : in std_logic_vector(N-1 downto 0);
        clk : in std_logic;
        ready : out std_logic;
        uart_t_out : out std_logic
    );
end uart_t;

architecture Behavioral of uart_t is

type t_state is (RDY, LOAD_BIT, SEND_BIT);

constant bit_timer_max : std_logic_vector(to_unsigned(floor(real(100000000)/real(9600)), log2(floor(real(100000000)/real(9600)))));

constant max_bit_index : positive := N + 2;


signal rBitTimer : std_logic_vector(log2(floor(real(100000000)/real(9600)))-1 downto 0);

signal rBitDone : std_logic;

signal rBitIndex : positive;

signal rBit_t : std_logic := '1';

signal rData_t :std_logic_vector(N+1 downto 0);

signal rState_t : t_state := RDY;


begin


end Behavioral;
