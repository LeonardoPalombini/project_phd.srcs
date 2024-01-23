library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

use IEEE.math_real.all;




entity fft_imgfilter is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        fft_clk : in std_logic;
        start : in std_logic;
        dataIn : in std_logic_vector(63 downto 0);
        
        busy : out std_logic;
        addrOut : out std_logic_vector(16 downto 0);
        dataOut : out std_logic_vector(63 downto 0);
        dataWrite : out std_logic
    );
end fft_imgfilter;

architecture Behavioral of fft_imgfilter is


COMPONENT floating_point_comp
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_a_tvalid : IN STD_LOGIC;
    s_axis_a_tready : OUT STD_LOGIC;
    s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_b_tvalid : IN STD_LOGIC;
    s_axis_b_tready : OUT STD_LOGIC;
    s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_result_tvalid : OUT STD_LOGIC;
    m_axis_result_tready : IN STD_LOGIC;
    m_axis_result_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) 
  );
END COMPONENT;


signal dataBuffer : std_logic_vector(31 downto 0);

-- fsm
type fsm_state is(IDLE, WAITSTART, READ, CUT);
signal state : fsm_state := IDLE;
signal pre_state : fsm_state := IDLE;

-- sig for rising edge fft_clk
signal pre_fft_clk : std_logic;
signal pre2_fft_clk : std_logic;
signal rise_fft_clk : std_logic;

--sig for data count
constant nMax : natural := 256**2;--**2
--constant nMax : natural := 5;
signal nCount : natural := 0;

signal address: std_logic_vector(16 downto 0);

-- signals for comparator
signal in_validA : std_logic;
signal in_readyA : std_logic;
signal in_validB : std_logic;
signal in_readyB : std_logic;
signal out_valid : std_logic;
signal out_ready : std_logic;
signal out_data : std_logic_vector(7 downto 0);
signal thrFlag : std_logic;


begin

float_compare : floating_point_comp
  PORT MAP (
    aclk => clk,
    s_axis_a_tvalid => in_validA,
    s_axis_a_tready => in_readyA,
    s_axis_a_tdata => dataBuffer,
    s_axis_b_tvalid => in_validB,
    s_axis_b_tready => in_readyB,
    s_axis_b_tdata => x"44fa0000",  -- manually threshold = 2000
    m_axis_result_tvalid => out_valid,
    m_axis_result_tready => out_ready,
    m_axis_result_tdata => out_data
  );

dataBuffer <= dataIn(31 downto 0);
addrOut <= address;
thrFlag <= out_data(0);

-- nx state
nx_state_p : process(clk)
begin
    if rising_edge(clk) then
        if(rst = '0') then
            case state is
                when IDLE =>
                    if(start = '1') then
                        state <= WAITSTART;
                    end if;
                when WAITSTART =>
                    if(rise_fft_clk = '1') then
                        state <= READ;
                    end if;
                when READ =>
                    if(rise_fft_clk = '1') then
                        state <= CUT;
                    end if;
                when CUT =>
                    if(rise_fft_clk = '1') then     --thrFlag = '0' and 
                        if(nCount < nMax) then
                            state <= READ;
                        else
                            state <= IDLE;
                        end if;
                    end if;
                when others =>
                    state <= IDLE;
            end case;
        else
            state <= IDLE;
        end if;
    end if;
end process;
busy <= '0' when state = IDLE else '1';

-- data count
count_p : process(clk)
begin
    if rising_edge(clk) then
        if(state = IDLE) then
            nCount <= 0;
        elsif(state = CUT) then
            if(pre_state = READ) then
                nCount <= nCount + 1;
            end if;
        end if;
    end if;
end process;

-- address update
address_p : process(clk)
begin
    if rising_edge(clk) then
        if(state = IDLE) then
            address <= (others => '0');
        elsif(state = READ) then
            if(pre_state = CUT) then
                address <= address + 1;
            end if;
        end if;
    end if;
end process;


-- data cut
data_cut_p: process(clk)
begin
    if rising_edge(clk) then
        if(state = CUT and pre_state = READ and thrFlag = '1') then
            dataWrite <= '1';
        else
            dataWrite <= '0';
        end if;
    end if;
end process;
dataOut <= (others => '0'); -- always 0, written when flag 1


-- valid data for comparator
in_validA <= '1' when state = READ or state = CUT else '0';
in_validB <= '1' when state = READ or state = CUT else '0';
out_ready <= '1' when state = READ or state = CUT else '0';

-- latch state and fft_clk
latch_p : process(clk)
begin
    if rising_edge(clk) then
        pre_state <= state;
        pre_fft_clk <= fft_clk;
        pre2_fft_clk <= pre_fft_clk;
    end if;
end process;
rise_fft_clk <= '1' when pre2_fft_clk = '0' and pre_fft_clk = '1' else '0';

end Behavioral;
