library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

use IEEE.math_real.all;


entity top is
    Generic(
--        NB : POSITIVE := 5000000
        NB : POSITIVE := 115200
    );
    Port (
        sysClk : in std_logic;
        sysRst : in std_logic;
        sysIn : in std_logic;
--        switch : in std_logic;
        sysOut : out std_logic;
        ledIdle : out std_logic;
        ledRec : out std_logic;
        ledSend : out std_logic;
        ledUart : out std_logic;
        ledFilter : out std_logic
        
        -- debug signals
--        spyReady : out std_logic;
--        spyRead : out std_logic_vector(1 downto 0);
--        spyWrite : out std_logic_vector(2 downto 0);
--        spyCount : out std_logic_vector(17 downto 0);
--        spyData : out std_logic_vector(63 downto 0);
--        spyFftClk : out std_logic;
--        spyFftAddr : out std_logic_vector(16 downto 0);
--        spyFft : out std_logic_vector(2 downto 0)
    );
end top;

architecture Behavioral of top is

-- block RAM
COMPONENT blk_mem_gen
  PORT (
    clka : IN STD_LOGIC;
    rsta : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    rsta_busy : OUT STD_LOGIC 
  );
END COMPONENT;


-- UART receiver
component uart_r is
    Generic(
        N : POSITIVE := 8;
        Nbaud : POSITIVE := NB
    );
    Port(
        clk : in std_logic;
        dataIn : in std_logic;
        dataOut : out std_logic_vector(N-1 downto 0);
        ready : out std_logic;
        spyCount : out std_logic
    );
end component;

-- UART transmitter
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


-- memory read to UART transmitter
component mem_read_uart is
    Generic(
        MaxMem : natural := 100000;
        NB : natural := NB
    );
    Port (
        clock : in std_logic;
        reset : in std_logic;
        startRead : in std_logic;
        maxNo : in std_logic_vector(natural(ceil(log2(real(MaxMem)))) downto 0);
        readData : in std_logic_vector(31 downto 0);
--        uartRdy : in std_logic;
        uartOut : out std_logic_vector(7 downto 0);
        readAddr :  out std_logic_vector(16 downto 0);
        readBusy : out std_logic;
        uartSend : out std_logic;
        
        --debug signals
        endFlag : out std_logic;
        spyFsm : out std_logic_vector(1 downto 0);
        spyCount : out std_logic_vector(5 downto 0)      
    );
end component;

-- memory write from UART receiver
component mem_write_uart is
    Port (
        clock : in std_logic;
        reset : in std_logic;
        uartIn : in std_logic_vector(7 downto 0);
        uartRdy : in std_logic;
        writeMem : out std_logic;
        writeAddr :  out std_logic_vector(16 downto 0);
        writeBusy : out std_logic;
        dataOut : out std_logic_vector(31 downto 0);
        --debug signals
        memBusy : out std_logic_vector(2 downto 0);
        addrSig : out std_logic_vector(16 downto 0);
        stopSig : out std_logic          
    );
end component;


-- fft filter
component fft_filter is
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
        spy_fft_config_tready : out std_logic
    );
end component;



-- signals for uart_t
--atype mess is array(0 to 8) of std_logic_vector(7 downto 0);
signal tx_data : std_logic_vector(7 downto 0);
signal tx_ready : std_logic;
signal tx_send : std_logic;

-- signals for uart_r
signal rx_data : std_logic_vector(7 downto 0);
signal rx_ready : std_logic;


--signals for memory1
signal readEnable_1 : std_logic;
signal writeEnable_1 : std_logic_vector(0 downto 0);
signal memAddress_1 : std_logic_vector(16 downto 0);
signal memIn_1 : std_logic_vector(63 downto 0);
signal memOut_1 : std_logic_vector(63 downto 0);
signal memIn_buffer : std_logic_vector(63 downto 0);

-- signals for memory_read 1
signal readAddress_1 : std_logic_vector(16 downto 0);
signal readBusy_1 : std_logic;

-- signals for memory_write 1
signal writeAddress_1 : std_logic_vector(16 downto 0);
signal writeBusy_1 : std_logic;
signal writeOut : std_logic_vector(31 downto 0);
signal startRead_1 : std_logic;
signal writeEn : std_logic;


-- signals for fft filter
signal startFilter : std_logic := '0';
signal filterIn : std_logic_vector(63 downto 0);
signal filterOut : std_logic_vector(63 downto 0);
signal filterAddr : std_logic_vector(16 downto 0);
signal filterBusy : std_logic;
signal filterWrite : std_logic;


-- local signals for top FSM
type txd_state is (IDLE, RECEIVING, FILTERING, SENDING);
signal state : txd_state := IDLE;
signal pre_state : txd_state := IDLE;

signal maxNo : std_logic_vector(natural(ceil(log2(real(100000))))+2 downto 0) := (others => '0');
signal endRead : std_logic;
signal dataRdy : std_logic;
signal pre_writeBusy_1 : std_logic;
signal rise_writeBusy_1 : std_logic;
signal fall_writeBusy_1 : std_logic;
signal pre_readBusy_1 : std_logic;
signal fall_readBusy_1 : std_logic;
signal pre_rx_ready : std_logic;
signal fall_rx_ready : std_logic;
signal pre_filterBusy : std_logic;
signal fall_filterBusy : std_logic;



begin

memory1 : blk_mem_gen
  PORT MAP (
    clka => sysClk,
    rsta => sysRst,
    ena => '1',
    wea => writeEnable_1,
    addra => memAddress_1,
    dina => memIn_1,
    douta => memOut_1
--    rsta_busy => rsta_busy
  );

uart_txd : uart_t
    port map(
        send => tx_send,
        data => tx_data,
        clk => sysClk,
        ready => tx_ready,
        uart_t_out => sysOut
    );

uart_rxd : uart_r
    port map(
        clk => sysClk,
        dataIn => sysIn,
        dataOut => rx_data,
        ready => rx_ready
--        spyCount => spyRxStart
    );
    
memory1_read_uart : mem_read_uart
    port map(
        clock => sysClk,
        reset => sysRst,
        startRead => startRead_1,
        maxNo => maxNo(natural(ceil(log2(real(100000))))+2 downto 2),
--        maxNo => std_logic_vector(to_unsigned(256,natural(ceil(log2(real(100000))))+1)),--65536
        readData => memOut_1(31 downto 0),
--        uartRdy => tx_ready,
        uartOut => tx_data,
        readAddr => readAddress_1,
        readBusy => readBusy_1,
        uartSend => tx_send
--        spyFsm => spyRead
    );
    
memory1_write_uart : mem_write_uart
    port map(
        clock => sysClk,
        reset => sysRst,
        uartIn => rx_data,
        uartRdy => rx_ready,
        writeMem => writeEn,
        writeAddr => writeAddress_1,
        writeBusy => writeBusy_1,
        dataOut => writeOut
--        memBusy => spyWrite
    );
    
    
image_filter : fft_filter
    port map(
        clk => sysClk,
        rst => sysRst,
        startFilter => startFilter,
        dataIn => memOut_1,
        dataOut => filterOut,
        address => filterAddr,
        write => filterWrite,
        busy => filterBusy
--        spyFsm => spyFft,       
--        spy_fft_clk => spyFftClk 
    );
   


memIn_buffer(63 downto 32) <= std_logic_vector(to_unsigned(0,32));
memIn_buffer(31 downto 0) <= writeOut;

ledUart <= rx_ready when state = RECEIVING else
           tx_ready when state = SENDING else
           '0';

--spyData <= memIn_1;
--spyFftAddr <= memAddress_1;
----spyRxStart <= writeBusy_1;
--spyReady <= startRead_1;
--spyCount <= maxNo(natural(ceil(log2(real(100000))))+2 downto 2);

-- next state
nx_state_p : process(sysClk)
begin
    if rising_edge(sysClk) then
        case state is
            when IDLE =>
                if(rise_writeBusy_1 = '1') then
                    state <= RECEIVING;
                end if;
            when RECEIVING =>
                if(fall_writeBusy_1 = '1') then
                    state <= FILTERING;   --FILTERING
                end if;
            when FILTERING =>
                if(fall_filterBusy = '1') then
                    state <= SENDING;
                end if;
            when SENDING =>
                if(fall_readBusy_1 = '1') then
                    state <= IDLE;
                end if;
            when others =>
                state <= IDLE;
        end case;
    end if;
end process;
startFilter <= '1' when state = FILTERING and pre_state = RECEIVING else '0';


-- signal muxxes
memAddress_1 <= writeAddress_1 when state = RECEIVING else 
                readAddress_1 when state = SENDING else
                filterAddr when state = FILTERING else
                (others => '0');

memIn_1 <= filterOut when state = FILTERING else memIn_buffer;


writeEnable_1(0) <= filterWrite when state = FILTERING else writeEn;


-- latch busy sigs
mem1_busy_latch_p : process(sysClk)
begin
    if rising_edge(sysClk) then
        pre_writeBusy_1 <= writeBusy_1;
        pre_readBusy_1 <= readBusy_1;
        pre_filterBusy <= filterBusy;
    end if;
end process;
rise_writeBusy_1 <= '1' when pre_writeBusy_1 = '0' and writeBusy_1 = '1' else '0';
fall_writeBusy_1 <= '1' when pre_writeBusy_1 = '1' and writeBusy_1 = '0' else '0';
fall_readBusy_1 <= '1' when pre_readBusy_1 = '1' and readBusy_1 = '0' else '0';
fall_filterBusy <= '1' when pre_filterBusy = '1' and filterBusy = '0' else '0';


-- count bytes
data_count_p : process(sysClk)
begin
    if rising_edge(sysClk) then
        if(state = IDLE) then
            maxNo <= (others => '0');
        elsif(state = RECEIVING) then
            if(fall_rx_ready = '1') then
                maxNo <= maxNo + 1;
            end if;
        end if;
    end if;
end process;


-- latch receive ready
rx_ready_latch_p : process(sysClk)
begin
    if rising_edge(sysClk) then
        pre_rx_ready <= rx_ready;
    end if;
end process;
fall_rx_ready <= '1' when pre_rx_ready = '1' and rx_ready = '0' else '0';

-- latch state
state_latch_p : process(sysClk)
begin
    if rising_edge(sysClk) then
        pre_state <= state;
    end if;
end process;
startRead_1 <= '1' when pre_state = FILTERING and state = SENDING else '0';


-- led indicators
ledIdle <= '1' when state = IDLE else '0';
ledRec <= '1' when state = RECEIVING else '0';
ledSend <= '1' when state = SENDING else '0';
ledFilter <= '1' when state = FILTERING else '0';

end Behavioral;
