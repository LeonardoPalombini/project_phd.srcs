library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

use IEEE.math_real.all;



entity fft_row is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        fft_clock : in std_logic;
        start : in std_logic;
        memData : in std_logic_vector(63 downto 0);
        fft_dataIn_ready : in std_logic;
        fft_dataOut_valid : in std_logic;
        fftResult : in std_logic_vector(63 downto 0);
        fft_dataIn_valid : out std_logic;
        fft_dataOut_ready : out std_logic;
        memAddr : out std_logic_vector(16 downto 0);
        memWrite : out std_logic;
        fftData : out std_logic_vector(63 downto 0);
        fftDataLast : out std_logic;
        memResWrite : out std_logic_vector(63 downto 0);
        busy : out std_logic;
        
        --debug signals
        spyFsm : out std_logic_vector(2 downto 0)
    );
end fft_row;

architecture Behavioral of fft_row is

-- fsm
type fsm_state is (IDLE, WAITSTART, READCELL, SENDCELL, WAITFFT, READFFT);
signal state : fsm_state := IDLE;
signal pre_state : fsm_state := IDLE;

signal addr : std_logic_vector(16 downto 0);

-- count cells
signal n_cell : natural := 0;
signal n_row : natural := 0;
constant nMax : natural := 255;
--constant nMax : natural := 2;
constant nMax_v : std_logic_vector := std_logic_vector(to_unsigned(nMax+1, 17));

-- latch and event for fftClock and ready signals
signal pre_fft_clock : std_logic;
signal pre2_fft_clock : std_logic;
signal rise_fft_clock : std_logic;
signal fall_fft_clock : std_logic;

signal pre_fft_dataOut_valid : std_logic;
signal pre2_fft_dataOut_valid : std_logic;
signal rise_fft_dataOut_valid : std_logic;


begin
busy <= '0' when state = IDLE else '1';
memAddr <= addr;

-- next state process
nx_state_p : process(clk, rst)
begin
    if rising_edge(clk) then
        if(rst = '0') then
            case state is
                when IDLE =>
                    if(start = '1') then
                        state <= WAITSTART;
                    end if;
                when WAITSTART =>
                    if(rise_fft_clock = '1' and fft_dataIn_ready = '1') then
                        state <= READCELL;
                    end if;
                when READCELL =>
                    if(rise_fft_clock = '1' and fft_dataIn_ready = '1') then
                        if(n_cell > nMax) then
                            state <= WAITFFT;
                        else
                            state <= SENDCELL;
                        end if;
                    end if;
                when SENDCELL =>
                    state <= READCELL;
                when WAITFFT =>
                    if(rise_fft_dataOut_valid = '1') then
                        state <= READFFT;
                    end if;
                when READFFT =>
                    if(n_cell > nMax and rise_fft_clock = '1') then
                        if(n_row > nMax) then
                            state <= IDLE;
                        else
                            state <= READCELL;
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

spyFsm <= "000" when state = IDLE else
          "001" when state = WAITSTART else
          "010" when state = READCELL else
          "011" when state = SENDCELL else
          "100" when state = WAITFFT else
          "101" when state = READFFT;

-- n_cell update
ncell_p : process(clk)
begin
    if rising_edge(clk) then
        if(state = IDLE or state = WAITFFT) then
            n_cell <= 0;
        elsif(state = SENDCELL) then
            n_cell <= n_cell + 1;
        elsif(state = READFFT) then
            if(fft_dataOut_valid = '1' and fall_fft_clock = '1') then
                n_cell <= n_cell + 1;
            end if;
        elsif(state = READCELL) then
            if(pre_state = READFFT) then
                n_cell <= 0;
            end if;
        end if;
    end if;
end process;


-- n_row update
nrow_p : process(clk)
begin
    if rising_edge(clk) then
        if(state = IDLE) then
            n_row <= 0;
--            n_row <= nMax;
        elsif(state = WAITFFT) then
            if(pre_state = READCELL) then
                n_row <= n_row + 1;
            end if;
        end if;
    end if;
end process;

-- address update
address_p : process(clk)
begin
    if rising_edge(clk) then
        if(state = IDLE) then
            addr <= (others => '0');
        elsif(state = WAITFFT) then
            if(pre_state = READCELL) then
                addr <= addr - nMax_v;
            end if;
        elsif(state = SENDCELL) then
            addr <= addr + 1;
        elsif(state = READFFT) then
            if(rise_fft_clock = '1') then
                addr <= addr + 1;
            end if;
        end if;
    end if;
end process;


-- last cell signal
lastcell_p : process(clk)
begin
    if rising_edge(clk) then
        if(state = SENDCELL) then
            if(n_cell = nMax) then
                fftDataLast <= '1';
            end if;
        elsif(state = WAITFFT or state = IDLE) then
            fftDataLast <= '0';
        end if;
    end if;
end process;


-- latch data from mem to fft
latchdata_p : process(clk)
begin
    if rising_edge(clk) then
        if(state = SENDCELL) then
            fftData <= memData;
        elsif(state = WAITFFT) then
            fftData <= (others => '0');
        end if;
    end if;
end process;


-- valid signal for fftIn
fftIn_valid_p : process(clk)
begin
    if rising_edge(clk) then
        if(state = SENDCELL) then
            fft_dataIn_valid <= '1';
        elsif(state = WAITFFT or state = IDLE) then
            fft_dataIn_valid <= '0';
        end if;
    end if;
end process;
--fft_dataIn_valid <= '1' when pre_state = SENDCELL and state = READCELL else '0';


-- write results in memory
writemem_p : process(clk)
begin
    if rising_edge(clk) then
        if(state = READFFT) then
            if(fft_dataOut_valid = '1' and fall_fft_clock = '1') then
                memWrite <= '1';
            else   
                memWrite <= '0';
            end if;
        else
            memWrite <= '0';
        end if;
    end if;
end process;
fft_dataOut_ready <= '1' when state = WAITFFT or state = READFFT else '0';
memResWrite <= fftResult when state = READFFT else (others => '0');


-- latch and event catch fftClk and fftValid
latch_p : process(clk)
begin
    if rising_edge(clk) then
        pre_fft_clock <= fft_clock;
        pre2_fft_clock <= pre_fft_clock;
        pre_fft_dataOut_valid <= fft_dataOut_valid;
        pre2_fft_dataOut_valid <= pre_fft_dataOut_valid;
    end if;
end process;

rise_fft_clock <= '1' when pre2_fft_clock = '0' and pre_fft_clock = '1' else '0';
fall_fft_clock <= '1' when pre2_fft_clock = '1' and pre_fft_clock = '0' else '0';
rise_fft_dataOut_valid <= '1' when pre2_fft_dataOut_valid = '0' and pre_fft_dataOut_valid = '1' else '0';


-- latch state
latchState_p : process(clk)
begin
    if rising_edge(clk) then
        pre_state <= state;
    end if;
end process;

end Behavioral;