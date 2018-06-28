library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity trivium is
	Generic (
		-- Keystream output width: 1,2,4,8,16,32,64
	KSOUT_WIDTH : integer	:= 8
	);
    Port ( 
		--TRIVIUM Key
	key : in  STD_LOGIC_VECTOR (79 downto 0);
		
		--TRIVIUM Initial Vector
        iv : in  STD_LOGIC_VECTOR (79 downto 0);
		
		--Main Clock
        clk : in  STD_LOGIC;
		
		--Return next keystream word on the next cycle, active high
	nxt : in STD_LOGIC;
		
		--Reset
        rst : in  STD_LOGIC;
		
		--Indicates that the keystream output is valid, active high
        rdy : out  STD_LOGIC;
		
		--Keystream Output
        ksout : out  STD_LOGIC_VECTOR (KSOUT_WIDTH-1 downto 0)
	);
end trivium;

architecture Behavioral of trivium is

-- Internal State
signal ei  : STD_LOGIC_VECTOR (287 downto 0);

-- Generated bits to be shifted into the internal 
-- state register after each cycle
signal a1,a2,a3 : STD_LOGIC_VECTOR (KSOUT_WIDTH-1 downto 0);

-- State:
-- 00 - Reset, Internal State initialize
-- 01 - Internal State initialization, let 'y' cycles pass
-- 11 - Initialized, generating valid keystream
signal modo : STD_LOGIC_VECTOR(1 downto 0);

-- 'y' counter for State 01
-- 1152/KSOUT_WIDTH cicles must take place for the initialization to finish
signal y : integer range 0 to (1152/KSOUT_WIDTH);

-- generated keystream
signal z : STD_LOGIC_VECTOR (KSOUT_WIDTH-1 downto 0);

--auxiliary signal to generate a keystream word only when
--indicated (when next=1) after the initialization is finished
signal sclk : STD_LOGIC;

--Ready signal
signal srdy : STD_LOGIC;

begin

--Ready and keystream-out signals Control
control1: process(clk)
begin 
	if falling_edge(clk) then
		if modo = "11" then
			srdy <= '1';
			ksout <= z;
		
		else
			srdy <= '0';
	--change to " ksout <= (others => '0') "
	--if you don't want to see
	--non valid ks-out during
	--the initialization
			ksout <= z;
			--ksout <= (others => '0');
		end if;
	end if;
end process control1;

rdy <= srdy;

--this defines the auxiliary clock signal 
--that controls keystream generation, 
--clock signal will be left untouched while
--initialization takes place and then it 
--will only update the keystream when nxt=1

--|clk|rdy|nxt||sclk|
--+---+---+---++----+
--| 0 | X | X ||  0 |
--| 1 | 0 | X ||  1 |
--| 1 | 1 | 0 ||  0 |
--| 1 | 1 | 1 ||  1 |
--+---+---+---++----+

sclk <= clk and not(srdy and (not nxt));

--"y" counter and Mode Control
control2: process(rst, clk)
begin

	if rst = '1' then
		modo <= "00";
		y <= 0;
		
	elsif falling_edge(clk) then
		if y < ((1152/KSOUT_WIDTH)-1) then --1152/32
			modo <= "10";
			y <= y + 1;
		else
			modo <= "11";
		end if;
	end if;
	
end process control2;

--TRIVIUM initialization and keystream generation

trivium1: process(key, iv, clk, sclk, modo, ei, a1, a2, a3)
begin
	if modo(1)='0' then
	
		ei(79 downto 0)    <= key;
		
		ei(92 downto 80)   <= (others => '0');
		
		ei(172 downto 93)  <= iv;
		
		ei(284 downto 173) <= (others => '0');
		ei(287 downto 285) <= (others => '1');	
		
	elsif rising_edge(sclk) then
	
		ei(92 downto KSOUT_WIDTH) <= ei(92-KSOUT_WIDTH downto 0);
		ei(KSOUT_WIDTH-1 downto 0) <= a3;
		
		ei(176 downto 93+KSOUT_WIDTH) <= ei(176-KSOUT_WIDTH downto 93);
		ei(93+(KSOUT_WIDTH-1) downto 93) <= a1;
		
		ei(287 downto 177+KSOUT_WIDTH) <= ei(287-KSOUT_WIDTH downto 177);
		ei(177+(KSOUT_WIDTH-1) downto 177) <= a2;
		
	end if;
	
end process trivium1;

g_z: for ii in 0 to KSOUT_WIDTH-1 generate
	--To change endianness uncomment the next line and comment the line below it
	--z((KSOUT_WIDTH-1)-ii)<= (ei(65-ii) xor ei(92-ii)) xor (ei(161-ii) xor ei(176-ii)) xor (ei(242-ii) xor ei(287-ii));
	z(ii) <= (ei(65-ii) xor ei(92-ii)) xor (ei(161-ii) xor ei(176-ii)) xor (ei(242-ii) xor ei(287-ii)); 
end generate g_z;

g_a1: for ii in 0 to KSOUT_WIDTH-1 generate
   a1((KSOUT_WIDTH-ii)-1) <= (ei(65-ii) xor ei(92-ii)) xor (ei(170-ii) xor (ei(90-ii) and ei(91-ii)));
end generate g_a1;

g_a2: for ii in 0 to KSOUT_WIDTH-1 generate
	a2((KSOUT_WIDTH-ii)-1) <= ( ei(161-ii) xor ei(176-ii) ) xor (ei(263-ii) xor (ei(174-ii) and ei(175-ii)));
end generate g_a2;

g_a3: for ii in 0 to KSOUT_WIDTH-1 generate
	a3((KSOUT_WIDTH-ii)-1) <= (ei(242-ii) xor ei(287-ii)) xor (ei(68-ii) xor (ei(285-ii) and ei(286-ii)));
end generate g_a3;

end Behavioral;
