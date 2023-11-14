----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.10.2023 19:45:14
-- Design Name: 
-- Module Name: top - Behavioral
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

entity top is
    Generic(
        NB : POSITIVE := 9600
    );
    Port (
        sysClk : in std_logic;
        sysRst : in std_logic;
        sysIn : in std_logic;
--        switch : in std_logic;
        sysOut : out std_logic
    );
end top;

architecture Behavioral of top is

component uart_r is
    Generic(
        N : POSITIVE := 8;
        Nbaud : POSITIVE := NB
    );
    Port(
        clk : in std_logic;
        dataIn : in std_logic;
        dataOut : out std_logic_vector(N-1 downto 0);
        ready : out std_logic
    );
end component;

component uart_t is
    generic(
        N : POSITIVE := 8;
        Nbaud : POSITIVE := NB
    );
    port(
        send : in std_logic;
        data : in std_logic_vector(N-1 downto 0);
        clk : in std_logic;
        ready : out std_logic;
        uart_t_out : out std_logic        
    );
end component;

type mess is array(0 to 8) of std_logic_vector(7 downto 0);

signal word : std_logic_vector(7 downto 0);
signal uart_rdy : std_logic;
signal uart_send : std_logic;

signal message : mess;
signal rx_data : std_logic_vector(7 downto 0);
signal rx_ready : std_logic;

signal internal, edge : std_logic;
signal int_tx, edge_tx : std_logic;

type txd_state is (IDLE, HOLD, LAUNCH);
signal txd_mach : txd_state := IDLE;
signal wordIndex : integer := 0;

constant maxIndex : integer := 4;

signal endTxd : std_logic;

--parameters for bit sampling timer
constant length : natural := natural(floor(6.0*real(100000000)/real(NB)));
constant width : natural := natural(ceil(log2(real(length))));
--timer to have Nbaud
constant timer_max : std_logic_vector := std_logic_vector(to_unsigned(length, width));
signal rTimer : std_logic_vector(width-1 downto 0) := (others => '0');
signal endHold : std_logic;


begin

message(0) <= "01010000";
message(1) <= "01110010";
message(2) <= "01100101";
--message(3) <= "01110011";
message(4) <= "01110011";
message(5) <= "01100101";
message(6) <= "01100100";
message(7) <= "00100000";
--message(8) <= "00000000";

--message(0) <= "01010000";
--message(1) <= "01010000";
--message(2) <= "01010000";
--message(3) <= "01010000";
--message(4) <= "01010000";
--message(5) <= "01010000";
--message(6) <= "01010000";
--message(7) <= "01010000";
--message(8) <= "01010000";

uart_txd : uart_t
    port map(
        send => uart_send,
        data => word,
        clk => sysClk,
        ready => uart_rdy,
        uart_t_out => sysOut
    );

uart_rxd : uart_r
    port map(
        clk => sysClk,
        dataIn => sysIn,
        dataOut => rx_data,
        ready => rx_ready
    );


rxd_det_proc : process(sysClk)
begin
    if rising_edge(sysClk) then
        internal <= rx_ready;
        message(3) <= rx_data;
        if (internal = '0') and (rx_ready = '1') then
            edge <= '1';            
        else
            edge <= '0';
        end if;        
    end if;
end process;

txd_det_proc : process(sysClk)
begin
    if rising_edge(sysClk) then
        int_tx <= uart_rdy;
        if (int_tx = '1') and (uart_rdy = '0') then
            edge_tx <= '1';
        else
            edge_tx <= '0';
        end if;        
    end if;
end process;


nx_state_p : process(sysClk)
begin
    if rising_edge(sysClk) then
        case txd_mach is
            when IDLE =>
                if(edge = '1') then
                    txd_mach <= LAUNCH;
                end if;
            when LAUNCH =>
                txd_mach <= HOLD;
            when HOLD =>
                if(endTxd = '0' and endHold = '1') then
                    txd_mach <= LAUNCH;
                end if;
                if(endTxd = '1') then
                    txd_mach <= IDLE;
                end if;
            when others =>
                txd_mach <= IDLE;
        end case;
    end if;
end process;


hold_p : process(sysClk)
begin
    if rising_edge(sysClk) then
        if(txd_mach = HOLD) then
            rTimer <= rTimer + 1;
        else
            rTimer <= (others => '0');
        end if;
    end if;
end process;

endHold <= '1' when (rTimer = timer_max) else '0';


wrd_count_p : process(sysClk)
begin
    if rising_edge(sysClk) then
        if(txd_mach = IDLE) then
            wordIndex <= 0;
        elsif(txd_mach = LAUNCH and uart_rdy = '1') then
            wordIndex <= wordIndex + 1;
        end if;
    end if;
end process;

endTxd <= '1' when (wordIndex = maxIndex) else '0';

send_msg_p : process(sysClk)
begin
    if rising_edge(sysClk) then
        word <= message(wordIndex);
        if(txd_mach = LAUNCH and uart_rdy = '1') then
            uart_send <= '1';
        else
            uart_send <= '0';
        end if;
    end if;
end process;
    

end Behavioral;
