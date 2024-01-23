library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;


entity mem_write is
    Port (
        clock : in std_logic;
        reset : in std_logic;
        rxIn : in std_logic_vector(7 downto 0);
        rxReady : in std_logic;
        dataOut : out std_logic_vector(7 downto 0);
        writeBusy : out std_logic;
        memBusy : out std_logic_vector(2 downto 0);
        addrSig : out std_logic_vector(8 downto 0);
        stopSig : out std_logic      
    );
end mem_write;

architecture Behavioral of mem_write is


COMPONENT blk_mem_gen
  PORT (
    clka : IN STD_LOGIC;
    rsta : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rsta_busy : OUT STD_LOGIC 
  );
END COMPONENT;

signal wEnVec : std_logic_vector(0 downto 0);
signal write : std_logic;
signal read : std_logic;
signal dataAddr : std_logic_vector(8 downto 0);
--signal dataIn : std_logic_vector(7 downto 0);
--signal dataOut : std_logic_vector(7 downto 0);

type fsm_state is (IDLE, RECEIVE, CHECK, START, WAITDATA, WRITEDATA);
signal state : fsm_state := IDLE;

signal start0 : std_logic_vector(7 downto 0) := "01010101";
signal stop0 : std_logic_vector(7 downto 0) := "01010101";

type sig_check is (DEF, FIRST_DET, SEC_DET);
signal startDet : sig_check := DEF;

signal stopDet : std_logic;

signal rdy1 : std_logic;
signal rdy2 : std_logic;
signal rdyRise : std_logic;
signal rdyFall : std_logic;


begin


memory : blk_mem_gen
  PORT MAP (
    clka => clock,
    rsta => reset,
    ena => read,
    wea => wEnVec,
    addra => dataAddr,
    dina => rxIn,
    douta => dataOut
--    rsta_busy => rsta_busy
  );


wEnVec(0) <= write;
stopSig <= write;
read <= '1';
addrSig <= dataAddr;

nx_state_p : process(clock, rxReady)
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
                        state <= WAITDATA;
                    end if;
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
           "101" when state = WRITEDATA;


start_det_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state = CHECK) then
            if(startDet = DEF and rxIn = "00000000") then
                start0 <= rxIn;
                startDet <= FIRST_DET;
            elsif(startDet = FIRST_DET) then
                start0 <= "01010101";
                if(rxIn = "11111111") then
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


stop_det_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state = WRITEDATA) then
            stop0 <= rxIn;
        elsif(state = IDLE) then
            stop0 <= "01010101";
        end if;
    end if;
end process;

stopDet <= '1' when stop0 = "00000000" and rxIn = "11111111" else '0';

write <= '1' when state = WRITEDATA else '0';


update_addr_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state = WRITEDATA) then
            dataAddr <= dataAddr + 1;
        elsif(state = IDLE) then
            dataAddr <= (others => '0');
        end if;
    end if;
end process;

rdy_trans_p : process(clock)
begin
    if(rising_edge(clock)) then
        rdy1 <= rxReady;
        rdy2 <= rdy1;
    end if;
end process;

rdyRise <= '1' when rdy2 = '0' and rdy1 = '1' else '0';
rdyFall <= '1' when rdy2 = '1' and rdy1 = '0' else '0';

writeBusy <= '0' when state = IDLE or state = RECEIVE or state = CHECK else '1';

end Behavioral;
