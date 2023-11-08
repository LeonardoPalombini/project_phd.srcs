----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.11.2023 19:16:49
-- Design Name: 
-- Module Name: uart_r - Behavioral
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
use IEEE.STD_LOGIC_SIGNED.ALL;

use IEEE.math_real.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_r is
    Generic(
        N : POSITIVE := 8;
        Nbaud : POSITIVE := 9600
    );
    Port(
        clk : in std_logic;
        dataIn : in std_logic;
        dataOut : out std_logic_vector(N-1 downto 0);
        ready : out std_logic
    );
end uart_r;

architecture Behavioral of uart_r is

--uart_r state machine
type t_state is (RDY, WAIT_BIT, SAMPLE_BIT, LOAD_DATA);
--parameters for bit sampling timer
constant length : natural := natural(floor(real(100000000)/real(Nbaud)));
constant width : natural := natural(ceil(log2(real(length))));
--parameters for start com timer
constant length_half : natural := natural(floor(0.5*real(100000000)/real(Nbaud)));
constant width_half : natural := natural(ceil(log2(real(length_half))));

--timer to have Nbaud
constant bit_timer_max : std_logic_vector := std_logic_vector(to_unsigned(length, width));
--timer to check start com
constant bit_timer_half : std_logic_vector := std_logic_vector(to_unsigned(length_half, width));
--max bit index data+start+stop
constant max_bit_index : positive := N + 1;

--timer reg for Nbaud
signal rBitTimer : std_logic_vector(width-1 downto 0) := (others => '0');
--timer reg for start com
signal rBitTimer_half : std_logic_vector(width_half-1 downto 0) := (others => '0');
--signal to sample bit
signal rSampleBit : std_logic;
--signal to start reading
signal rStartCount : std_logic;
--index of bit
signal rBitIndex : positive;
--vector with data+start+stop
signal rData_t :std_logic_vector(N+1 downto 0);

--state machine initialization
signal rState_r : t_state := RDY;

begin

--next state logic
next_r_state_process : process(clk)
begin
    if(rising_edge(clk)) then
        case rState_r is
            when RDY =>
                if(rStartCount = '1') then
                    rState_r <= WAIT_BIT;
                end if;
            when WAIT_BIT =>
                if(rSampleBit = '1') then
                    rState_r <= SAMPLE_BIT;
                end if;
            when SAMPLE_BIT =>
                if(rBitIndex = max_bit_index) then
                    rState_r <= LOAD_DATA;
                else
                    State_r <= WAIT_BIT;
                end if;
            when LOAD_DATA =>
                rState_r <= RDY;
        end case;
    end if;
end process;


end Behavioral;
