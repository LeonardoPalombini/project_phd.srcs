library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

use IEEE.math_real.all;



entity mem_read is
    Generic(
        MaxMem : natural := 300000
    );
    Port (
        clock : in std_logic;
        reset : in std_logic;
        startRead : in std_logic;
        maxNo : in std_logic_vector(natural(ceil(log2(real(MaxMem))))-1 downto 0);
        rxIn : in std_logic_vector(7 downto 0);
        dataOut : out std_logic_vector(7 downto 0);
--        memBusy : out std_logic_vector(2 downto 0);
        addrSig : out std_logic_vector(8 downto 0);
        sendSig : out std_logic;
        endFlag : out std_logic;
        spyFsm : out std_logic_vector(1 downto 0);
        spyCount : out std_logic_vector(5 downto 0)    
    );
end mem_read;

architecture Behavioral of mem_read is


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


constant wid : natural := natural(ceil(log2(real(MaxMem))));
signal countNo : std_logic_vector(wid-1 downto 0);
signal endCom : std_logic;

--constant baud : real := 115200.0;
constant baud : real := 11520000.0;
constant maxWait : natural := natural(100000000.0*50.0/baud);
--constant maxWait : natural := 35;
constant waitWid : natural := natural(ceil(log2(real(maxWait))));
signal countWait : std_logic_vector(waitWid-1 downto 0) := (others => '0');
constant countWaitMax : std_logic_vector := std_logic_vector(to_unsigned(maxWait, waitWid));
signal endWait : std_logic;

type fsm_state is (IDLE, HOLD, SEND);
signal state : fsm_state := IDLE;



begin

wEnVec(0) <= write;
endFlag <= endCom;
addrSig <= dataAddr;
--spyCount <= countWait;


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
  
nx_state_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(reset = '0') then
            case state is
                when IDLE =>
                    if(startRead = '1') then
                        state <= HOLD;
                    end if;
                when HOLD =>
                    if(endCom = '1') then
                        state <= IDLE;
                    else
                        if(endWait = '1') then
                            state <= SEND;
                        end if;
                    end if;
                when SEND =>
                    state <= HOLD;
                when others =>
                    state <= IDLE;
            end case;
        else
            state <= IDLE;
        end if;
    end if;
end process;

spyFsm <= "00" when state = IDLE else
          "01" when state = HOLD else
          "10" when state = SEND;


addr_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state = IDLE) then
            dataAddr <= (others => '0');
        elsif(state = SEND) then
            dataAddr <= dataAddr + 1;
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


count_mem_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state = SEND) then
            countNo <= countNo + 1;
        elsif(state = IDLE) then
            countNo <= (others => '0');
        end if;
    end if;
end process;

read <= '1' when state = SEND else '0';


endcom_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state /= IDLE) then
            if(countNo = 3) then
                endCom <= '1';
            else
                endCom <= '0';
            end if;
        end if;
    end if;
end process;


send_p : process(clock)
begin
    if(rising_edge(clock)) then
        if(state = SEND) then
            sendSig <= '1';
        else
            sendSig <= '0';
        end if;
    end if;
end process;


end Behavioral;
