library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

use IEEE.math_real.all;



entity mem_read_uart is
    Generic(
        MaxMem : natural := 100000;
        NB : natural := 115200
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
end mem_read_uart;

architecture Behavioral of mem_read_uart is


signal dataAddr : std_logic_vector(16 downto 0);

-- signal for end communication
constant wid : natural := natural(ceil(log2(real(MaxMem))));
signal countNo : std_logic_vector(wid downto 0);
signal endCom : std_logic;

-- signals for send timing
constant baud : real := real(NB);
--constant baud : real := 11520000.0;
constant maxWait : natural := natural(100000000.0*20.0/baud);
--constant maxWait : natural := 35;
constant waitWid : natural := natural(ceil(log2(real(maxWait))));
signal countWait : std_logic_vector(waitWid-1 downto 0) := (others => '0');
constant countWaitMax : std_logic_vector := std_logic_vector(to_unsigned(maxWait, waitWid));
signal endWait : std_logic;

-- fsm
type fsm_state is (IDLE, STARTNUM, HOLD, SEND);
signal state : fsm_state := IDLE;
signal pre_state : fsm_state := IDLE;

-- signals for data byte-ization
type arr is array(3 downto 0) of std_logic_vector(7 downto 0);
signal data : arr := (others => (others => '0'));
constant byteNo : natural := 3;
signal byteIndex : natural := 0;


begin

endFlag <= endCom;
readAddr <= dataAddr;
--spyCount <= countWait;
--readAddr <= countNo;
  
nx_state_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(reset = '0') then
            case state is
                when IDLE =>
                    if(startRead = '1') then
                        state <= STARTNUM;
                    end if;
                when STARTNUM =>
                    state <= HOLD;
                when HOLD =>
                    if(endWait = '1') then
                            state <= SEND;
                    end if;
                when SEND =>
                    if(byteIndex < byteNo) then
                        state <= HOLD;
                    else
                        if(endCom = '1') then
                            state <= IDLE;
                        else
                            state <= STARTNUM;
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

spyFsm <= "00" when state = IDLE else
          "01" when state = STARTNUM else
          "10" when state = HOLD else
          "11" when state = SEND;


-- data latch
data_p : process(clock)
begin
    if rising_edge(clock) then
        if(state = HOLD) then
            data(0) <= readData(7 downto 0);
            data(1) <= readData(15 downto 8);
            data(2) <= readData(23 downto 16);
            data(3) <= readData(31 downto 24);
        end if;
    end if;
end process;
uartOut <= data(byteIndex);

-- byte index update
byte_index_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state = IDLE or STATE = STARTNUM) then
            byteIndex <= 0;
        elsif(state = HOLD) then
            if(pre_state = SEND) then
                byteIndex <= byteIndex + 1;
            end if;
        end if;
    end if;
end process;

-- address update
addr_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state = IDLE) then
            dataAddr <= (others => '0');
        elsif(state = STARTNUM) then
            if(pre_state = SEND) then
                dataAddr <= dataAddr + 1;
            end if;
        end if;
    end if;
end process;


count_wait_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state = HOLD) then
            countWait <= countWait + 1;
        else
            countWait <= (others => '0');
        end if;
    end if;
end process;

endWait <= '1' when countWait = countWaitMax else '0';


-- control end of send
count_mem_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state = STARTNUM) then
            countNo <= countNo + 1;
        elsif(state = IDLE) then
            countNo <= (others => '0');
        end if;
    end if;
end process;


-- end communic signal
endcom_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state /= IDLE) then
            if(countNo < maxNo) then --countNo < maxNo-1   std_logic_vector(to_unsigned(65534,17))
                endCom <= '0';
            else
                endCom <= '1';
            end if;
        else
            endCom <= '0';
        end if;
    end if;
end process;


-- state latch
state_latch_p : process(clock)
begin
    if(rising_edge(clock)) then
        pre_state <= state;
    end if;
end process;


uartSend <= '1' when state = SEND else '0';

readBusy <= '0' when state = IDLE else '1';

end Behavioral;
