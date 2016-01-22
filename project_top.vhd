----------------------------------------------------------------------------------
-- Company:  ENGS 31 15X
-- Engineer: Ethan Blackwood and Lota Ezenwa
-- 
-- Create Date:    19:49:52 08/15/2015 
-- Design Name: 
-- Module Name:    project_top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:  Top-level file for our audio project
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
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;					-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

entity project_top is
    Port ( clk : in  STD_LOGIC;
	 
			  -- controls
				  -- switches
				  sound_sw : in STD_LOGIC; 	-- speaker on/off (in)
				  looper_en : in STD_LOGIC;	-- enable/disable playback and record
				  reverse : in STD_LOGIC; 		-- looper playback direction
  				  ReverbSwitch : in STD_LOGIC;-- reverberation on/off
				  
				  -- buttons				  
				  speed_up : in STD_LOGIC;		-- increase looper playback speed
				  slow_down : in STD_LOGIC;	-- decrease looper playback speed
				  rec_over : in STD_LOGIC; 	-- on next loop, overwrite current recording
				  add_track : in STD_LOGIC; 	-- on next loop, add to current recording
			  
			  -- LEDs
			  rec_led : out STD_LOGIC;							  -- on when recording
			  time_led : out STD_LOGIC_VECTOR(4 downto 0); -- controls 5 LEDs (as quasi-metronome)
			  
			  -- D-A converter interface
			  nCS_da: out STD_LOGIC;			-- low-true chip select
			  sdata_out: out STD_LOGIC;		-- serial data out
			  sclk_da: out STD_LOGIC;			-- sample clock
			  
			  -- A-D converter interface
  			  nCS_ad: out STD_LOGIC;			-- low-true chip select
			  sdata_in: in STD_LOGIC;			-- serial data in
			  sclk_ad: out STD_LOGIC;			-- sample clock
			  
			  -- amplifier interface
			  gain: out STD_LOGIC; -- 0 = 12dB, 1 = 6dB
			  sp_en: out STD_LOGIC -- speaker on/off (out)
			  );
			  
end project_top;

architecture Behavioral of project_top is

------------------ component declarations -----------------------------

component adda is
generic ( BIT_DEPTH: integer );
port (clk: in std_logic;
		sync: out std_logic;
		DinA: out std_logic;
		sclk: out std_logic;
		data: in std_logic_vector(BIT_DEPTH-1 downto 0);
		done: out std_logic
		);
		
end component;

component PmodMICRefComp is
  Generic ( BIT_DEPTH: integer );
  Port    (    
  --General usage
    CLK      : in std_logic;         
     
  --Pmod interface signals
    SDATA   : in std_logic;
    SCLK     : out std_logic;
    nCS      : out std_logic;
        
    --User interface signals
    DATA    : out std_logic_vector(BIT_DEPTH-1 downto 0);
    START    : in std_logic; 
    DONE     : out std_logic
            );

end component;

component FIFO
generic(DAT_W : integer;		
			  ADD_W : integer);		
port(
		clk : in STD_LOGIC;
		char_rx : in  STD_LOGIC_VECTOR (DAT_W-1 downto 0);  -- char from receiver
      char_tx : out  STD_LOGIC_VECTOR (DAT_W-1 downto 0); -- char to transmitter
      rx_done_tick : in  STD_LOGIC;	 -- new char ready from receiver
      tx_done_tick : in  STD_LOGIC;	 -- done transmitting
		tx_from_reg_i : in STD_LOGIC
	);
end component;

component Looper
 Generic ( ADDR_W : integer;
			  DATA_W : integer;
			  SAMPLE_FREQ : integer;
			  CLK_FREQ : integer);
    Port ( clk : in  STD_LOGIC;
           audio_in : in  STD_LOGIC_VECTOR (DATA_W-1 downto 0);
           audio_out : out  STD_LOGIC_VECTOR (DATA_W-1 downto 0);
           reverse : in  STD_LOGIC;
           speed_up : in  STD_LOGIC;
           slow_down : in  STD_LOGIC;
           rec_over : in  STD_LOGIC; -- erase current recording and record a new one on the next loop (button)
			  add_track : in STD_LOGIC; -- add a new track to the current recording on the next loop (button)
			  looper_en : in STD_LOGIC; -- enable the LEDs, playback, recording (switch) (if off, only works as a mic with reverb)
           led_select : out  STD_LOGIC_VECTOR (2 downto 0);
			  rec_led : out STD_LOGIC
			  );
end component;

component debouncer
	port( 	clk, switch			: in STD_LOGIC;
				dbswitch				: out std_logic );
end component;

component monopulser
    Port (clk : in STD_LOGIC;
			 but_d : in  STD_LOGIC; -- button down
			 but_mp : out STD_LOGIC); -- monopulsed button
end component;

------------- constants -------------------------------------

constant BIT_DEPTH : integer := 12;
constant INPUT_OFFSET : unsigned(BIT_DEPTH-1 downto 0) := x"400";
constant REVERB_STRENGTH : integer := 13;
constant LOOPER_ADDR_W : integer := 15;
constant SAMPLE_RATE : integer := 44100;
constant CLOCK_RATE : integer := 100E6;
constant MAX_SAMPLE_CNT : integer := CLOCK_RATE/SAMPLE_RATE - 1;
constant MAX_SAMPLE_CNT_W : integer := integer(ceil(log2(real(max_sample_cnt))));

------------- signals -------------------------------

-- audio path
signal audio_in : STD_LOGIC_VECTOR (BIT_DEPTH-1 downto 0);
signal audio_in_u : UNSIGNED(BIT_DEPTH-1 downto 0);
signal rx : STD_LOGIC_VECTOR (BIT_DEPTH-1 downto 0);
signal reverb_out : STD_LOGIC_VECTOR(BIT_DEPTH-1 downto 0);
signal looper_out : STD_LOGIC_VECTOR(BIT_DEPTH-1 downto 0);
signal audio_out : STD_LOGIC_VECTOR(BIT_DEPTH-1 downto 0);

-- debounced and monopulsed inputs
signal reverse_db : std_logic;
signal speed_up_db : std_logic;
signal speed_up_mp : std_logic;
signal slow_down_db : std_logic;
signal slow_down_mp : std_logic;
signal rec_over_db : std_logic;
signal rec_over_mp : std_logic;
signal add_track_db : std_logic;
signal add_track_mp : std_logic;
signal looper_en_db : std_logic;
signal ReverbSwitch_db : std_logic;

-- sample counter
signal sample_cnt : unsigned(MAX_SAMPLE_CNT_W-1 downto 0) := (others => '0');

-- control lines
signal start_sample : std_logic;
signal sample_done : std_logic;
signal sample_done_mp : std_logic;
signal da_done : std_logic;

-- leds
signal led_select : std_logic_vector(2 downto 0);
signal led_decoded : std_logic_vector(4 downto 0);

begin

-------------------------------------------------------------------------------
------- Monopulsers and Debouncers-----------------

sound_sw_db_c: debouncer
	port map ( clk => clk,
				  switch => sound_sw,
				  dbswitch => sp_en);

reverse_db_c: debouncer
	port map ( clk => clk,
				  switch => reverse,
				  dbswitch => reverse_db);
				  
speed_up_db_c: debouncer
	port map ( clk => clk,
				  switch => speed_up,
				  dbswitch => speed_up_db);
				  
speed_up_mp_c: monopulser
	port map ( clk => clk,
				  but_d => speed_up_db,
				  but_mp => speed_up_mp);
				  
slow_down_db_c: debouncer
	port map ( clk => clk,
				  switch => slow_down,
				  dbswitch => slow_down_db);
				  
slow_down_mp_c: monopulser
	port map ( clk => clk,
				  but_d => slow_down_db,
				  but_mp => slow_down_mp);
				  
rec_over_db_c: debouncer
	port map ( clk => clk,
				  switch => rec_over,
				  dbswitch => rec_over_db);

rec_over_mp_c: monopulser
	port map ( clk => clk,
				  but_d => rec_over_db,
				  but_mp => rec_over_mp);
				  
add_track_db_c: debouncer
	port map ( clk => clk,
				  switch => add_track,
				  dbswitch => add_track_db);
				  
add_track_mp_c: monopulser
	port map ( clk => clk,
				  but_d => add_track_db,
				  but_mp => add_track_mp);
				  
looper_en_db_c: debouncer
	port map ( clk => clk,
				  switch => looper_en,
				  dbswitch => looper_en_db);
				  
ReverbSwitch_db_c: debouncer
	port map ( clk => clk,
				  switch => ReverbSwitch,
				  dbswitch => ReverbSwitch_db);
				 
-- monopulse the sample done tick since it's on a different clock				 
sample_done_mp_c: monopulser
	port map (clk => clk,
				 but_d => sample_done,
				 but_mp => sample_done_mp);
------------------------------------------------------------------

DAConverter: adda
generic map(BIT_DEPTH => BIT_DEPTH)
port map(
	clk => clk,
	sync => nCS_da,
	DinA => sdata_out,
	sclk => sclk_da,
	data => audio_out,
	done => da_done
	);
-------------------------------------------------------------------------------
	
ADConverter: PmodMICRefComp
generic map(BIT_DEPTH => BIT_DEPTH)
port map(
	CLK => clk,
	sdata => sdata_in,
	sclk => sclk_ad,
	nCS => nCS_ad,
	data => audio_in,
	start => start_sample,
	done => sample_done
	);

------------------------------------------------------------------------------
	
Reverberator: FIFO
generic map( DAT_W => BIT_DEPTH,
				 ADD_W => REVERB_STRENGTH)
port map(
	clk => clk,
	char_rx => rx,
   char_tx => reverb_out,
   rx_done_tick => sample_done_mp,
   tx_done_tick => da_done,
	tx_from_reg_i => ReverbSwitch_db
	);
	
--------------------------------------------------------------------------------

Looper_c: Looper
generic map( ADDR_W => LOOPER_ADDR_W,
				 DATA_W => BIT_DEPTH,
				 SAMPLE_FREQ => SAMPLE_RATE,
				 CLK_FREQ => CLOCK_RATE)
port map(
	clk => clk,
   audio_in => reverb_out,
   audio_out => looper_out,
   reverse => reverse_db,
   speed_up => speed_up_mp,
   slow_down => slow_down_mp,
   rec_over => rec_over_mp,
	add_track => add_track_mp,
	looper_en => looper_en_db,
   led_select => led_select,
	rec_led => rec_led
	);

-------------------------------------------------------------------------------------
-- time LED decoder

led_decoded <= "10000" when led_select = "000" else
					"11000" when led_select = "001" else
					"01000" when led_select = "010" else
					"01100" when led_select = "011" else
					"00100" when led_select = "100" else
					"00110" when led_select = "101" else
					"00010" when led_select = "110" else
					"00011" when led_select = "111" else
					"00000";

-- MUX: only light LEDs when the looper is on.
time_led <= led_decoded when looper_en_db = '1' else (others => '0');

sampler: process(clk)
begin
	if rising_edge(clk) then
		if sample_cnt = MAX_SAMPLE_CNT then
			sample_cnt <= (others => '0');
		else
			sample_cnt <= sample_cnt + 1;
		end if;
		
		if sample_cnt < 8 then -- hold for 8 cycles so that the tick is seen by the mic controller, which runs on a slower clock
			start_sample <= '1';
		else
			start_sample <= '0';
		end if;
	end if;
end process sampler;


sample_update: process(clk)
begin 
	if rising_edge(clk) then
		if sample_done = '1' then
			audio_in_u <= unsigned(audio_in) + INPUT_OFFSET;
			rx <= not std_logic(audio_in_u(BIT_DEPTH-1)) & std_logic_vector(audio_in_u(BIT_DEPTH-2 downto 0)); -- convert to signed
		end if;
	end if;
end process sample_update;

gain <= '0';
audio_out <= not looper_out(BIT_DEPTH-1) & looper_out(BIT_DEPTH-2 downto 0); -- convert to unsigned

end Behavioral;

