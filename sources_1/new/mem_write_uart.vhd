library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;


entity mem_write_uart is
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
end mem_write_uart;

architecture Behavioral of mem_write_uart is

-- signals to control memory
signal write : std_logic;
signal dataAddr : std_logic_vector(16 downto 0);

-- fsm
type fsm_state is (IDLE, RECEIVE, CHECK, START, WAITDATA, ADD, WRITEDATA);
signal state : fsm_state := IDLE;
signal pre_state : fsm_state := IDLE;

-- signal to detect start and stop
signal start0 : std_logic_vector(7 downto 0) := "01010101";
signal stop0 : std_logic_vector(7 downto 0) := "01010101";

-- secondary fsm to detect start
type sig_check is (DEF, FIRST_DET, SEC_DET);
signal startDet : sig_check := DEF;

signal stopDet : std_logic;

signal rdy1 : std_logic;
signal rdy2 : std_logic;
signal rdyRise : std_logic;
signal rdyFall : std_logic;

-- signals for data reassembly
type arr is array(3 downto 0) of std_logic_vector(7 downto 0);
signal data : arr := (others => (others => '0'));
constant byteNo : natural := 3;
signal byteIndex : natural := 0;


begin

writeMem <= write;
writeAddr <= dataAddr;

dataOut(7 downto 0) <= data(0);
dataOut(15 downto 8) <= data(1);
dataOut(23 downto 16) <= data(2);
dataOut(31 downto 24) <= data(3);

nx_state_p : process(clock, uartRdy)
begin
    if(rising_edge(clock)) then
        if(reset = '0') then
            case state is
                when IDLE =>
                   if(rdyFall = '1') then
                        state <= RECEIVE;
                   end if;
                when RECEIVE =>
                    if(rdyRise = '1') then
                        state <= CHECK;
                   end if;
                when CHECK =>
                    if(startDet = FIRST_DET) then
                        state <= RECEIVE;
                    elsif(startDet = SEC_DET) then
                        state <= START;
                    else
                        state <= IDLE;
                    end if;
                when START =>
                    state <= WRITEDATA;
                when WAITDATA =>
                    if(stopDet = '1') then
                        state <= IDLE;
                    else
                        if(rdyRise = '1') then
                            state <= WRITEDATA;
                        end if;
                    end if;
                when WRITEDATA =>
                    if(stopDet = '1') then
                        state <= IDLE;
                    else
                        if(byteIndex < byteNo) then
                            state <= WAITDATA;
                        else
                            state <= ADD;
                        end if;
                    end if;
                when ADD =>
                    state <= WAITDATA;
                when others =>
                    state <= IDLE;
            end case;
        else
            state <= IDLE;
        end if;
        
    end if;
end process;

memBusy <= "000" when state = IDLE else
           "001" when state = RECEIVE else
           "010" when state = CHECK else
           "011" when state = START else
           "100" when state = WAITDATA else
           "101" when state = WRITEDATA else
           "110" when state = ADD;


-- byte latch
byte_p : process(clock)
begin
    if rising_edge(clock) then
        if(state = WRITEDATA) then
            data(byteIndex) <= uartIn;
        end if;
    end if;
end process;

-- byte index update
byteIndex_p : process(clock)
begin
    if rising_edge(clock) then
        if(state = WAITDATA) then
            if(pre_state = WRITEDATA) then
                byteIndex <= byteIndex + 1;
            end if;
        elsif(state = ADD or state = IDLE) then
            byteIndex <= 0;
        end if;
    end if;
end process;

-- start detection
start_det_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state = CHECK) then
            if(startDet = DEF and uartIn = "00000000") then
                start0 <= uartIn;
                startDet <= FIRST_DET;
            elsif(startDet = FIRST_DET) then
                start0 <= "01010101";
                if(uartIn = "11111111") then
                    startDet <= SEC_DET;
                else
                    startDet <= DEF;
                end if;
            else
                start0 <= "01010101";
                startDet <= DEF;
            end if;
        end if;
    end if;
end process;

-- stop detection latch
stop_det_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state = WRITEDATA) then
            stop0 <= uartIn;
        elsif(state = IDLE) then
            stop0 <= "01010101";
        end if;
    end if;
end process;

stopDet <= '1' when stop0 = "00000000" and uartIn = "11111111" else '0';

write <= '1' when pre_state = ADD and state = WAITDATA else '0';

-- update address
update_addr_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state = WAITDATA) then
            if(pre_state = ADD) then
                dataAddr <= dataAddr + 1;
            end if;
        elsif(state = IDLE) then
            dataAddr <= (others => '0');
        end if;
    end if;
end process;


-- latch uart ready
rdy_trans_p : process(clock)
begin
    if(rising_edge(clock)) then
        rdy1 <= uartRdy;
        rdy2 <= rdy1;
    end if;
end process;

rdyRise <= '1' when rdy2 = '0' and rdy1 = '1' else '0';
rdyFall <= '1' when rdy2 = '1' and rdy1 = '0' else '0';


-- state latch
state_latch_p : process(clock)
begin
    if(rising_edge(clock)) then
        pre_state <= state;
    end if;
end process;

writeBusy <= '0' when state = IDLE or state = RECEIVE or state = CHECK else '1';

end Behavioral;