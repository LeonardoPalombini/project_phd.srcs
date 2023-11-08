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
use IEEE.STD_LOGIC_SIGNED.ALL;

use IEEE.math_real.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_t is
    Generic(
        N : POSITIVE := 8;
        Nbaud : POSITIVE := 9600
    );
    Port(
        send : in std_logic;
        data : in std_logic_vector(N-1 downto 0);
        clk : in std_logic;
        ready : out std_logic;
        uart_t_out : out std_logic;
        bit_count_out : out std_logic_vector(5 downto 0);
        state_probe : out std_logic_vector(1 downto 0)
    );
end uart_t;

architecture Behavioral of uart_t is

--uart_t state machine
type t_state is (RDY, LOAD_BIT, SEND_BIT);
--parameters for bit timer
constant length : natural := natural(floor(real(100000000)/real(Nbaud)));
constant width : natural := natural(ceil(log2(real(length))));
--timer to have Nbaud
constant bit_timer_max : std_logic_vector := std_logic_vector(to_unsigned(length, width));
--max bit index data+start+stop
constant max_bit_index : positive := N + 1;

--timer reg for Nbaud
signal rBitTimer : std_logic_vector(width-1 downto 0) := (others => '0');
--logic indicating BitTimer reached bit_timer_max
signal rBitDone : std_logic;
--index of bit
signal rBitIndex : positive;
--bit to be trasmitted (standard 1 for no transmisssion)
signal rBit_t : std_logic := '1';
--vector with data+start+stop
signal rData_t :std_logic_vector(N+1 downto 0);
--state machine initialization
signal rState_t : t_state := RDY;


begin
bit_count_out <= rBitTimer;

--Next state logic
next_t_state_process : process(clk)
begin
    if(rising_edge(clk)) then
        case rState_t is
            when RDY =>
                state_probe <= "01";
                if(send = '1') then
                    rState_t <= LOAD_BIT;
                end if;
            when LOAD_BIT =>
                state_probe <= "10";
                rState_t <= SEND_BIT;
            when SEND_BIT =>
                state_probe <= "11";
                if(rBitDone = '1') then
                    if(rBitIndex = max_bit_index) then
                        rState_t <= RDY;
                    else
                        rState_t <= LOAD_BIT;
                    end if;
                end if;
            when others =>
                state_probe <= "00";
                rState_t <= RDY;    --never
        end case;
    end if;
end process;


--bit timing for Nbaud
bit_timing_process : process(clk)
begin
    if(rising_edge(clk)) then
        if(rState_t = RDY) then
            rBitTimer <= (others => '0');
        else
            if(rBitDone = '1') then
                rBitTimer <= (others => '0');
            else
                rBitTimer <= rBitTimer + 1;
            end if;
        end if;
    end if;
end process;

--async logic of max timer
rBitDone <= '1' when (rBitTimer = bit_timer_max) else '0';


--bit indexing for sequential transmission
bit_index_process : process(clk)
begin
    if(rising_edge(clk)) then
		if(rState_t = RDY) then
			rBitIndex <= 0;
		elsif(rState_t = LOAD_BIT) then
			rBitIndex <= rBitIndex + 1;
		end if;
	end if;
end process;


--data forming for transmission
data_latch_process : process(clk)
begin
    if(rising_edge(clk)) then
		if(send = '1') then
			rData_t <= '1' & data & '0';    --latch transmission (start+data+stop)
		end if;
	end if;
end process;


--transmission
t_bit_process : process(clk)
begin
    if(rising_edge(clk)) then
		if(rState_t = RDY) then
			rBit_t <= '1';  --default no transmission
		elsif(rState_t = LOAD_BIT) then
			rBit_t <= rData_t(rBitIndex); --sequential out of 
		end if;
	end if;
end process;

--async out connection
uart_t_out <= rBit_t;
ready <= '1' when (rState_t = RDY) else '0';


end Behavioral;
