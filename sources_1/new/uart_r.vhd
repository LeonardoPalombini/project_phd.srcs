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
--        bit_count_out : out std_logic_vector(5 downto 0);
--        half_count_out : out std_logic_vector(4 downto 0);
--        state_probe : out std_logic_vector(1 downto 0)
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
constant bit_timer_half : std_logic_vector := std_logic_vector(to_unsigned(length_half, width_half));
--max bit index data+start+stop
constant max_bit_index : integer := N ;

--timer reg for Nbaud
signal rBitTimer : std_logic_vector(width-1 downto 0) := (others => '0');
--timer reg for start com
signal rBitTimer_half : std_logic_vector(width_half-1 downto 0) := (others => '0');
--signal to sample bit
signal rSampleBit : std_logic;
--signal to start reading
signal rStartCount : std_logic;
--index of bit
signal rBitIndex : integer;
--vector with data+start+stop
signal rData_t :std_logic_vector(N downto 0);
--vector with data only
signal rDataFin_t :std_logic_vector(N-1 downto 0);

--state machine initialization
signal rState_r : t_state := RDY;

begin
--bit_count_out <= rBitTimer;
--half_count_out <= rBitTimer_half;

--next state logic
next_r_state_process : process(clk)
begin
    if(rising_edge(clk)) then
        case rState_r is
            when RDY =>
--                state_probe <= "00";
                if(rStartCount = '1') then
                    rState_r <= WAIT_BIT;
                end if;
            when WAIT_BIT =>
--                state_probe <= "01";
                if(rSampleBit = '1') then
                    rState_r <= SAMPLE_BIT;
                end if;
            when SAMPLE_BIT =>
--                state_probe <= "10";
                if(rBitIndex = max_bit_index) then
                    rState_r <= LOAD_DATA;
                else
                    rState_r <= WAIT_BIT;
                end if;
            when LOAD_DATA =>
--                state_probe <= "11";
                rState_r <= RDY;
        end case;
    end if;
end process;

ready <= '1' when (rState_r = RDY) else '0';


--timing for start com detection
start_com_process : process(clk)
begin
    if(rising_edge(clk)) then
        if(rState_r = RDY) then
            if(dataIn = '0') then
                rBitTimer_half <= rBitTimer_half + 1;
            else   
                rBitTimer_half <= (others => '0');
            end if;
        else
            rBitTimer_half <= (others => '0');
        end if;
    end if;
end process;

--async logic of max start timer
rStartCount <= '1' when (rBitTimer_half = bit_timer_half) else '0';


--timing for Nbaud sampling
bit_timing_process : process(clk)
begin
    if(rising_edge(clk)) then
        if(rState_r = WAIT_BIT) then
            rBitTimer <= rBitTimer + 1;
        else
            rBitTimer <= (others => '0');
        end if;
    end if;
end process;

--async logic of max sample timer
rSampleBit <= '1' when (rBitTimer = bit_timer_max) else '0';


--bit indexing for data parallelization
bit_index_process : process(clk)
begin
    if(rising_edge(clk)) then
		if(rState_r = RDY) then
			rBitIndex <= 0;
		elsif(rState_r = SAMPLE_BIT) then
			rBitIndex <= rBitIndex + 1;
		end if;
	end if;
end process;


--final data container
g_gen_connect : for i in 0 to N-1 generate
    rDataFin_t(i) <= rData_t(i);
end generate g_gen_connect;

--data latch
data_latch_process : process(clk)
begin
    if(rising_edge(clk)) then
        if(rState_r = SAMPLE_BIT) then
            rData_t(rBitIndex) <= dataIn;
        elsif(rState_r = LOAD_DATA) then
            dataOut <= rDataFin_t;
        end if;
    end if;
end process;

end Behavioral;
