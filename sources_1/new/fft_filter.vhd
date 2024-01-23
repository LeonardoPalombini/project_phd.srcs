library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

use IEEE.math_real.all;



entity fft_filter is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        startFilter : in std_logic;
        dataIn : in std_logic_vector(63 downto 0);
        
        dataOut : out std_logic_vector(63 downto 0);
        address : out std_logic_vector(16 downto 0);
        write : out std_logic;
        busy : out std_logic;
        
        -- debug signals
        spyFsm : out std_logic_vector(2 downto 0);
        spy_fft_clk : out std_logic;
        spy_rBusy : out std_logic;
        spy_r_fft_dataIn_valid : out std_logic;
        spy_cBusy : out std_logic;
        spy_fft_dataIn_ready : out std_logic;
        spy_fft_dataOut_valid : out std_logic;
        spy_fft_dataIn_last : out std_logic;
        spy_events : out std_logic_vector(7 downto 0);
        spy_fft_config_tready : out std_logic;
        spyFftData : out std_logic_vector(63 downto 0)
    );
end fft_filter;

architecture Behavioral of fft_filter is

-- secondary clock core
component clk_wiz_0
port
 (-- Clock in ports
  -- Clock out ports
  clk_out1          : out    std_logic;
  clk_in1           : in     std_logic
 );
end component;


-- x256 FFT core, single precision floating point
COMPONENT xfft_0
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_config_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    s_axis_config_tvalid : IN STD_LOGIC;
    s_axis_config_tready : OUT STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    s_axis_data_tlast : IN STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axis_data_tuser : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tready : IN STD_LOGIC;
    m_axis_data_tlast : OUT STD_LOGIC;
    m_axis_status_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_status_tvalid : OUT STD_LOGIC;
    m_axis_status_tready : IN STD_LOGIC;
    event_frame_started : OUT STD_LOGIC;
    event_tlast_unexpected : OUT STD_LOGIC;
    event_tlast_missing : OUT STD_LOGIC;
    event_fft_overflow : OUT STD_LOGIC;
    event_status_channel_halt : OUT STD_LOGIC;
    event_data_in_channel_halt : OUT STD_LOGIC;
    event_data_out_channel_halt : OUT STD_LOGIC 
  );
END COMPONENT;

-- fft of rows
component fft_row is
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
end component;

-- fft of columns
component fft_column is
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
end component;


-- actual filter
component fft_imgfilter is
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
end component;



-- signals for FFT core
signal fft_clk : std_logic;
signal fft_rst : std_logic := '1';
signal fft_config_tdata : std_logic_vector(23 downto 0); --to fix
signal fft_config_tvalid : std_logic := '1';
signal fft_config_tready : std_logic;
signal fft_dataIn : std_logic_vector(63 downto 0);
signal fft_dataIn_valid : std_logic := '0';
signal fft_dataIn_ready : std_logic;
signal fft_dataIn_last : std_logic;
signal fft_dataOut : std_logic_vector(63 downto 0);
signal fft_dataOut_valid : std_logic;
signal fft_dataOut_ready : std_logic := '0';
signal fft_dataOut_last : std_logic;
signal fft_status_tdata : std_logic_vector(7 DOWNTO 0);
signal fft_status_tvalid : std_logic;
signal fft_status_tready : std_logic := '1';

-- signals for FFT rows
signal r_start : std_logic;
signal r_memData : std_logic_vector(63 downto 0);
signal r_fftResult : std_logic_vector(63 downto 0);
signal r_fft_dataIn_valid : std_logic;
signal r_fft_dataOut_ready : std_logic;
signal r_memAddr : std_logic_vector(16 downto 0);
signal r_memWrite : std_logic;
signal r_fftData : std_logic_vector(63 downto 0);
signal r_fftDataLast : std_logic;
signal r_memResWrite : std_logic_vector(63 downto 0);
signal r_busy : std_logic;

-- signals for FFT columns
signal c_start : std_logic;
signal c_memData : std_logic_vector(63 downto 0);
signal c_fftResult : std_logic_vector(63 downto 0);
signal c_fft_dataIn_valid : std_logic;
signal c_fft_dataOut_ready : std_logic;
signal c_memAddr : std_logic_vector(16 downto 0);
signal c_memWrite : std_logic;
signal c_fftData : std_logic_vector(63 downto 0);
signal c_fftDataLast : std_logic;
signal c_memResWrite : std_logic_vector(63 downto 0);
signal c_busy : std_logic;


-- signals for frequency filter
signal f_start : std_logic;
signal f_busy : std_logic;
signal f_memAddr : std_logic_vector(16 downto 0);
signal f_memResWrite :  std_logic_vector(63 downto 0);
signal f_memWrite : std_logic;


-- fsm
type fsm_state is (IDLE, ROWS, COLS, FILTER, IROWS, ICOLS);
signal state : fsm_state := IDLE;
signal pre_state : fsm_state := IDLE;

signal inverse : std_logic := '0';

-- latch rise/fall signals
signal pre_r_busy : std_logic;
signal pre_c_busy : std_logic;
signal pre_f_busy : std_logic;
signal fall_r_busy : std_logic;
signal fall_c_busy : std_logic;
signal fall_f_busy : std_logic;

signal pre_fft_config_tready : std_logic;
signal fall_fft_config_tready : std_logic;

-- signals for secondary clock
--constant nIter : std_logic_vector(2 downto 0) := "100";
--signal counter : std_logic_vector(2 downto 0) := "000";
signal pre_fft_clk : std_logic;
signal rise_fft_clk : std_logic;

-- signals for core reset
constant nHold : std_logic_vector(1 downto 0) := "11";
signal countHold : std_logic_vector(1 downto 0) := "00";

signal n_rst : std_logic;

begin
spy_fft_dataIn_ready <= fft_dataIn_ready;
spy_rBusy <= r_busy;
spy_cBusy <= c_busy;
spy_fft_clk <= fft_clk;
spy_fft_dataIn_last <= r_fftDataLast;
spy_fft_config_tready <= fft_config_tready;
spy_fft_dataOut_valid <= fft_dataOut_valid;
--spy_fft_dataOut_valid <= inverse;
spy_r_fft_dataIn_valid <= fft_dataIn_valid;
spyFftData <= fft_dataOut;

n_rst <= not rst;

secondary_clock : clk_wiz_0
   port map ( 
  -- Clock out ports  
   clk_out1 => fft_clk,
   -- Clock in ports
   clk_in1 => clk
 );


FFT : xfft_0
  PORT MAP (
    aclk => fft_clk,
    aresetn => fft_rst,
    s_axis_config_tdata => fft_config_tdata,
    s_axis_config_tvalid => fft_config_tvalid,
    s_axis_config_tready => fft_config_tready,
    s_axis_data_tdata => fft_dataIn,
    s_axis_data_tvalid => fft_dataIn_valid,
    s_axis_data_tready => fft_dataIn_ready,
    s_axis_data_tlast => fft_dataIn_last,
    m_axis_data_tdata => fft_dataOut,
    m_axis_data_tvalid => fft_dataOut_valid,
    m_axis_data_tready => fft_dataOut_ready,
    m_axis_data_tlast => fft_dataOut_last,
    m_axis_status_tdata => fft_status_tdata,
    m_axis_status_tvalid => fft_status_tvalid,
    m_axis_status_tready => fft_status_tready,
    event_frame_started => spy_events(0),
    event_tlast_unexpected => spy_events(1),
    event_tlast_missing => spy_events(2),
    event_fft_overflow => spy_events(6),
    event_status_channel_halt => spy_events(3),
    event_data_in_channel_halt => spy_events(4),
    event_data_out_channel_halt => spy_events(5)
  );
  
fftRow : fft_row
    port map(
        clk => clk,
        rst => rst,
        fft_clock => fft_clk,
        start => r_start,
        memData => dataIn,
        fft_dataIn_ready => fft_dataIn_ready,
        fft_dataOut_valid => fft_dataOut_valid,
        fftResult => fft_dataOut,
        fft_dataIn_valid => r_fft_dataIn_valid,
        fft_dataOut_ready => r_fft_dataOut_ready,
        memAddr => r_memAddr,
        memWrite => r_memWrite,
        fftData => r_fftData,
        fftDataLast => r_fftDataLast,
        memResWrite => r_memResWrite,
        busy => r_busy,
        spyFsm => spyFsm
    );

fftCol : fft_column
    port map(
        clk => clk,
        rst => rst,
        fft_clock => fft_clk,
        start => c_start,
        memData => dataIn,
        fft_dataIn_ready => fft_dataIn_ready,
        fft_dataOut_valid => fft_dataOut_valid,
        fftResult => fft_dataOut,
        fft_dataIn_valid => c_fft_dataIn_valid,
        fft_dataOut_ready => c_fft_dataOut_ready,
        memAddr => c_memAddr,
        memWrite => c_memWrite,
        fftData => c_fftData,
        fftDataLast => c_fftDataLast,
        memResWrite => c_memResWrite,
        busy => c_busy
--        spyFsm => spyFsm
    );
    
freq_filter : fft_imgfilter
    port map(
        clk => clk,
        rst => rst,
        fft_clk => fft_clk,
        start => f_start,
        dataIn => dataIn,
        busy => f_busy,
        addrOut => f_memAddr,
        dataOut => f_memResWrite,
        dataWrite => f_memWrite
    );


fft_config_tdata(23 downto 1) <= (others => '0');
fft_config_tdata(0) <= inverse;


-- next state process
nx_state_p : process(clk)
begin
    if rising_edge(clk) then
        if(rst = '0') then
            case state is
                when IDLE =>
                    if(startFilter = '1') then
                        state <= ROWS;
                    end if;
                when ROWS =>
                    if(fall_r_busy = '1') then
                        state <= COLS;
                    end if;
                when COLS =>
                    if(fall_c_busy = '1') then
                        state <= FILTER;
                    end if;
                when FILTER =>
                    if(fall_f_busy = '1') then
                        state <= IROWS;
                    end if;
                when IROWS =>
                    if(fall_r_busy = '1') then
                        state <= ICOLS;
                    end if;
                when ICOLS =>
                    if(fall_c_busy = '1') then
                        state <= IDLE;
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

--spyFsm <= "000" when state = IDLE else
--          "001" when state = ROWS else
--          "010" when state = COLS else
--          "011" when state = FILTER else
--          "100" when state = IROWS else
--          "101" when state = ICOLS;
          
-- start signals
r_start <= '1' when (state = ROWS and pre_state = IDLE) or (state = IROWS and pre_state = FILTER) else '0';
c_start <= '1' when (state = COLS and pre_state = ROWS) or (state = ICOLS and pre_state = IROWS) else '0';
f_start <= '1' when state = FILTER and pre_state = COLS else '0';
          

-- set inverse fft: if inv=0 inverse, if inv=1 forward
inverse <= '0' when state = IROWS or state = ICOLS or state = FILTER else '1';
fft_config_tvalid <= '0' when pre_state /= state else '1';


-- signal muxxes
address <= r_memAddr when state = ROWS or state = IROWS else
           c_memAddr when state = COLS or state = ICOLS else
           f_memAddr when state = FILTER else
           (others => '0');
           
dataOut <= r_memResWrite when state = ROWS or state = IROWS else
           c_memResWrite when state = COLS or state = ICOLS else
           f_memResWrite when state = FILTER else
           (others => '0');
           
write <= r_memWrite when state = ROWS or state = IROWS else
         c_memWrite when state = COLS or state = ICOLS else
         f_memWrite when state = FILTER else
         '0';
         
fft_dataIn <= r_fftData when state = ROWS or state = IROWS else
              c_fftData when state = COLS or state = ICOLS else
              (others => '0');
              
fft_dataIn_valid <= r_fft_dataIn_valid when state = ROWS or state = IROWS else
                    c_fft_dataIn_valid when state = COLS or state = ICOLS else
                    '0';
                    
fft_dataOut_ready <= r_fft_dataOut_ready when state = ROWS or state = IROWS else
                     c_fft_dataOut_ready when state = COLS or state = ICOLS else
                     '0';                   

fft_dataIn_last <= r_fftDataLast when state = ROWS or state = IROWS else
                   c_fftDataLast when state = COLS or state = ICOLS else
                   '0';  


-- latch busy signals
latch_busy_p : process(clk)
begin
    if rising_edge(clk) then
        pre_r_busy <= r_busy;
        pre_c_busy <= c_busy;
        pre_f_busy <= f_busy;
    end if;
end process;
fall_r_busy <= '1' when pre_r_busy = '1' and r_busy = '0' else '0';
fall_c_busy <= '1' when pre_c_busy = '1' and c_busy = '0' else '0';
fall_f_busy <= '1' when pre_f_busy = '1' and f_busy = '0' else '0';

-- latch config signals
--latch_config_p : process(clk)
--begin
--    if rising_edge(clk) then
--        pre_fft_config_tready  <= fft_config_tready ;
--    end if;
--end process;
--fall_fft_config_tready  <= '1' when pre_fft_config_tready = '1' and fft_config_tready  = '0' else '0';

-- latch state and sec clock
latch_state_p : process(clk)
begin
    if rising_edge(clk) then
        pre_state <= state;
        pre_fft_clk <= fft_clk;
    end if;
end process;
rise_fft_clk <= '1' when pre_fft_clk = '0' and fft_clk = '1' else '0';


---- secondary clock generation
--fftClock_p : process(clk)
--begin
--    if rising_edge(clk) then
--        if(rst = '0') then
--            if(counter = nIter) then
--                counter <= (others => '0');
--                fft_clk <= not fft_clk;
--            else
--                counter <= counter + 1;
--            end if;
--        else
--            fft_clk <= '0';
--        end if;
--    end if;
--end process;


-- fft core reset signaling
coreRst_p : process(clk)
begin
    if rising_edge(clk) then
        if(state = FILTER) then
            if(rise_fft_clk = '1') then
                if(countHold = nHold) then
                    fft_rst <= '1';
                else
                    fft_rst <= '0';
                    countHold <= countHold + 1;
                end if;
            end if;
        else
            fft_rst <= '1';
            countHold <= (others => '0');
        end if;
    end if;
end process;

end Behavioral;
