----------------------------------------------------------------------------------
-- Company: ENGS 31 15X
-- Engineer: Ethan Blackwood and Lota Ezenwa
-- 
-- Create Date:    18:39:58 08/21/2015 
-- Design Name: 
-- Module Name:    Looper - Behavioral 
-- Project Name:   Audio project
-- Target Devices: 
-- Tool versions: 
-- Description: Module that can store and loop an audio clip and change speed and direction of playback
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity Looper is
 Generic ( ADDR_W : integer;
			  DATA_W : integer;
			  SAMPLE_FREQ : integer;
			  CLK_FREQ : integer);
    Port ( clk : in  STD_LOGIC;
           audio_in : in  STD_LOGIC_VECTOR (DATA_W-1 downto 0);
           audio_out : out  STD_LOGIC_VECTOR (DATA_W-1 downto 0); -- (register)
           reverse : in  STD_LOGIC; -- reverse playback and record direction (switch)
           speed_up : in  STD_LOGIC; -- speed up playback (button)
           slow_down : in  STD_LOGIC; -- slow down playback (button)
           rec_over : in  STD_LOGIC; -- erase current recording and record a new one on the next loop (button)
			  add_track : in STD_LOGIC; -- add a new track to the current recording on the next loop (button)
			  looper_en : in STD_LOGIC; -- enable the LEDs, playback, recording (switch) (if off, only works as a mic with reverb)
           led_select : out  STD_LOGIC_VECTOR (2 downto 0);
			  rec_led : out STD_LOGIC );
end Looper;

architecture Behavioral of Looper is

------------- signals -----------------------------------------------

-- control bits
signal wr_en : std_logic; -- write to regfile
signal aout_wr : std_logic; -- write to audio_out
signal out_combine : std_logic; -- 1 to combine current sample with stored sample (to play and possibly write)
signal addr_step : std_logic; -- step address up or down
signal cnt_up : std_logic; -- up/down for address counter
signal addr_reset : std_logic; -- reset address
signal sample_cnt_clr : std_logic; -- clear sample counter

-- status bits
signal addr_tc : std_logic;
signal sample_tc : std_logic; -- true when sample count >= the sample maxcount for the current speed

-- datapath
signal wr_addr : std_logic_vector(ADDR_W-1 downto 0) := (others => '0'); -- write address
signal rd_addr : std_logic_vector(ADDR_W-1 downto 0); 						 -- read address (always = wr_addr + 1)
signal audio_in_s : signed(DATA_W-1 downto 0);
signal audio_from_ram : std_logic_vector(DATA_W-1 downto 0);
signal audio_from_ram_s : signed(DATA_W-1 downto 0);
signal audio_sum : signed(DATA_W downto 0); -- incoming sample added to recorded sample at current address
signal audio_avg : signed(DATA_W-1 downto 0); -- average of incoming sample and recorded sample at current address
signal out_data : std_logic_vector(DATA_W-1 downto 0); -- the data to write to RAM and register to be played

-- sampling
constant MAXCNT_SAMPLE_3 : integer := CLK_FREQ/SAMPLE_FREQ - 1; -- maxcount of sample counter at normal speed
constant MAXCNT_SAMPLE_2 : integer := ((MAXCNT_SAMPLE_3+1) * 2)-1;   -- 1/2x speed
constant MAXCNT_SAMPLE_1 : integer := ((MAXCNT_SAMPLE_2+1) * 2)-1;   -- 1/4x speed
constant MAXCNT_SAMPLE_0 : integer := ((MAXCNT_SAMPLE_1+1) * 2)-1;   -- 1/8x speed
constant MAXCNT_SAMPLE_4 : integer := ((MAXCNT_SAMPLE_3+1) / 2)-1;   -- 2x speed
constant MAXCNT_SAMPLE_5 : integer := ((MAXCNT_SAMPLE_4+1) / 2)-1;   -- 4x speed
constant MAXCNT_SAMPLE_6 : integer := ((MAXCNT_SAMPLE_5+1) / 2)-1;   -- 8x speed
constant MAXCNT_SAMPLE_7 : integer := ((MAXCNT_SAMPLE_6+1) / 2)-1;   -- 16x speed

constant MAXCNT_SAMPLE_W	 : integer := integer(ceil(log2(real(MAXCNT_SAMPLE_0+1))));
type maxcnt_sample_type is array(0 to 7) of std_logic_vector(MAXCNT_SAMPLE_W-1 downto 0);
constant MAXCNT_SAMPLE_ROM : maxcnt_sample_type := (
																	std_logic_vector(to_unsigned(MAXCNT_SAMPLE_0,  MAXCNT_SAMPLE_W)),  -- speed 0 (0.125x)
																	std_logic_vector(to_unsigned(MAXCNT_SAMPLE_1,  MAXCNT_SAMPLE_W)),  -- speed 1 (0.25x)
																	std_logic_vector(to_unsigned(MAXCNT_SAMPLE_2,  MAXCNT_SAMPLE_W)),  -- speed 2 (0.5x)
																	std_logic_vector(to_unsigned(MAXCNT_SAMPLE_3,  MAXCNT_SAMPLE_W)),  -- speed 3 (normal)
																	std_logic_vector(to_unsigned(MAXCNT_SAMPLE_4,  MAXCNT_SAMPLE_W)),  -- speed 3 (2x)
																	std_logic_vector(to_unsigned(MAXCNT_SAMPLE_5,  MAXCNT_SAMPLE_W)),  -- speed 3 (4x)
																	std_logic_vector(to_unsigned(MAXCNT_SAMPLE_6,  MAXCNT_SAMPLE_W)),  -- speed 3 (8x)
																	std_logic_vector(to_unsigned(MAXCNT_SAMPLE_7,  MAXCNT_SAMPLE_W))   -- speed 3 (16x)
																);
signal maxcnt_sample : std_logic_vector(MAXCNT_SAMPLE_W-1 downto 0); -- should be the normal maxcount when looper is off, else depends on speed.
signal speed : unsigned(2 downto 0) := "011";
signal sample_count : std_logic_vector(MAXCNT_SAMPLE_W-1 downto 0);

------------ component declarations--------------------------

component RegFile
	generic (DATA_W : integer;
				ADDR_W : integer);
	port (clk : in std_logic;
			data_in : in std_logic_vector(DATA_W-1 downto 0);
			wr_addr : in std_logic_vector(ADDR_W-1 downto 0);
			rd_addr : in std_logic_vector(ADDR_W-1 downto 0);
			wr_en	  : in std_logic;
			data_out: out std_logic_vector(DATA_W-1 downto 0) );
end component;

component ud_counter
	generic( MAX: Integer);	
    Port ( clk : in  STD_LOGIC;
           en : in  STD_LOGIC;
           tc : out  STD_LOGIC;
           clr : in  STD_LOGIC;
			  count : out STD_LOGIC_VECTOR (integer(ceil(log2(real(MAX+1))))-1 downto 0);
			  up : in STD_LOGIC
			  );
end component;

component loop_control
    Port ( clk : in  STD_LOGIC;
	        rec_over : in  STD_LOGIC;
           add_track : in  STD_LOGIC;
           looper_en : in  STD_LOGIC;
			  addr_tc : in  STD_LOGIC;
           sample_tc : in  STD_LOGIC;
			  rec_led : out  STD_LOGIC;
           wr_en : out  STD_LOGIC;
			  aout_wr : out STD_LOGIC;
           out_combine : out  STD_LOGIC;
           addr_step : out  STD_LOGIC;
           addr_reset : out  STD_LOGIC;
           sample_cnt_clr : out  STD_LOGIC);
end component;

begin

-------- signal assignments----------------------------------------

-- combine incoming audio with recording
audio_in_s <= signed(audio_in);
audio_from_ram_s <= signed(audio_from_ram);

audio_sum_calc: process(audio_in_s, audio_from_ram_s, audio_sum)
begin
	audio_sum <= resize(audio_in_s, DATA_W+1) + resize(audio_from_ram_s, DATA_W+1); -- add sign-extended signals
	
	if audio_sum(DATA_W downto DATA_W-1) = "01" then
		audio_avg <= (DATA_W-1 => '0', others => '1'); --truncate at top
	elsif audio_sum(DATA_W downto DATA_W-1) = "10" then
		audio_avg <= (DATA_W-1 => '1', others => '0'); -- truncate at bottom
	else
		audio_avg <= audio_sum(DATA_W-1 downto 0);
	end if;
end process audio_sum_calc;

-- when to get a new sample
sample_tc <= '1' when sample_count >= maxcnt_sample else '0';

-- pass through either just the input or the input combined with the recording
with out_combine select out_data <=
	std_logic_vector(audio_avg) when '1',
	audio_in when others;
	
-- select LED based on top 3 bits of address (each lights for 1/8 the period)
led_select <= wr_addr(ADDR_W-1 downto ADDR_W-3);
	
cnt_up <= not reverse;

-- read address
rd_addr <= std_logic_vector(unsigned(wr_addr) + 1);
--------- processes---------------------------------------------
	
speed_change: process(clk) -- update speed (only when looper is on)
begin
	if rising_edge(clk) then
		if looper_en = '1' then
			if speed /= "000" and slow_down = '1' then
				speed <= speed - 1;
			elsif speed /= "111" and speed_up = '1' then
				speed <= speed + 1;
			end if;
		end if;
	end if;
end process speed_change;

maxcnt_sample_update: process(clk) -- synchronously change maxcnt_sample
begin
	if rising_edge(clk) then
		if looper_en = '1' then
			maxcnt_sample <= MAXCNT_SAMPLE_ROM(to_integer(speed));
		else
			maxcnt_sample <= MAXCNT_SAMPLE_ROM(3);
		end if;
	end if;
end process maxcnt_sample_update;

regOut: process(clk) -- update audio_out
begin
	if rising_edge(clk) then
		if aout_wr = '1' then
			audio_out <= out_data;
		end if;
	end if;
end process regOut;

--------- subcomponents ---------------------------------

RAM: RegFile
generic map (DATA_W => DATA_W,
				 ADDR_W => ADDR_W)
port map ( clk 		=> clk,
			  data_in 	=> out_data,
			  wr_addr 	=> wr_addr,
			  rd_addr 	=> rd_addr,
			  wr_en 		=> wr_en,
			  data_out 	=> audio_from_ram);
			  
AddrCounter: ud_counter
generic map ( MAX => 2**ADDR_W - 1)
port map ( clk => clk,
				en => addr_step,
				tc => addr_tc,
			  clr => addr_reset,
			count => wr_addr,
			   up => cnt_up);
				
SampleCounter: ud_counter
generic map ( MAX =>	MAXCNT_SAMPLE_0)
port map ( clk => clk,
				en => '1',
				tc => open,
			  clr => sample_cnt_clr,
			count => sample_count,
			   up => '1');
				
Controller: loop_control
port map ( clk 				=> clk,
			  rec_over			=> rec_over,
			  add_track 		=> add_track,
			  looper_en			=> looper_en,
			  addr_tc			=> addr_tc,
			  sample_tc 		=> sample_tc,
			  rec_led 			=> rec_led,
           wr_en 				=> wr_en,
			  aout_wr			=> aout_wr,
           out_combine		=> out_combine,
           addr_step 		=> addr_step,
           addr_reset 		=> addr_reset,
           sample_cnt_clr	=> sample_cnt_clr );
			
end Behavioral;

