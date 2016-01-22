----------------------------------------------------------------------------------
-- Company: ENGS 31 15X
-- Engineer: Ethan Blackwood and Lota Ezenwa
-- 
-- Create Date:    17:24:44 08/22/2015 
-- Design Name: 
-- Module Name:    loop_control - Behavioral 
-- Project Name:   Audio project
-- Target Devices: 
-- Tool versions: 
-- Description:   Controller for the looper
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

entity loop_control is
    Port ( clk : in  STD_LOGIC;
	 
			  -- status bits
           rec_over : in  STD_LOGIC;
           add_track : in  STD_LOGIC;
           looper_en : in  STD_LOGIC;
			  addr_tc : in  STD_LOGIC;
           sample_tc : in  STD_LOGIC;
			  
			  -- control bits
           rec_led : out  STD_LOGIC;
           wr_en : out  STD_LOGIC;
			  aout_wr : out STD_LOGIC;
           out_combine : out  STD_LOGIC;
           addr_step : out  STD_LOGIC;
           addr_reset : out  STD_LOGIC;
           sample_cnt_clr : out  STD_LOGIC);
end loop_control;

architecture Behavioral of loop_control is

signal rec_next : std_logic := '0'; -- record over on next loop
signal rec_next_n : std_logic;
signal add_next : std_logic := '0'; -- add track on next loop
signal add_next_n : std_logic;
signal recording : std_logic := '0'; -- currently recording over
signal recording_n : std_logic; -- value of recording on next cycle
signal adding : std_logic := '0'; -- currently adding track
signal adding_n : std_logic; -- value of adding on next cycle;

type state_type is (WT, SAMPLE);
signal state : state_type := WT;
signal next_state : state_type;

begin

-- some simple signal assignments
out_combine <= '0' when looper_en = '0' or recording = '1' else '1';
rec_led     <= '1' when recording = '1' or adding = '1'    else '0';

stateUpdate: process(clk)
begin
	if rising_edge(clk) then
		if looper_en = '1' then
			if add_track = '1' then
				rec_next <= '0';
				add_next <= '1';
			elsif rec_over = '1' then
				rec_next <= '1';
				add_next <= '0';
			else
				rec_next <= rec_next_n;
				add_next <= add_next_n;
			end if;
		else
			rec_next <= '0';
			add_next <= '0';
		end if;
		
		state <= next_state;
		recording <= recording_n;
		adding <= adding_n;
	end if;
end process stateUpdate;

combLogic: process(state, rec_next, add_next, recording, adding, addr_tc, sample_tc, looper_en)
begin
	-- defaults
	next_state <= state;
	wr_en <= '0';
	aout_wr <= '0';
	addr_step <= '0';
	addr_reset <= '0';
	sample_cnt_clr <= '0';
	recording_n <= recording;
	adding_n <= adding;
	rec_next_n <= rec_next;
	add_next_n <= add_next;
	
	case state is
		when WT =>
			-- listen for sample tc
			if sample_tc = '1' then
				sample_cnt_clr <= '1'; -- not automatic since this isn't the "real" tc
				next_state <= SAMPLE;
			end if;
			
			-- keep address at 0 if looper is off
			if looper_en = '0' then
				addr_reset <= '1';
			end if;
		when SAMPLE =>
			next_state <= WT;
			aout_wr <= '1';
			
			if looper_en = '1' then
				addr_step <= '1';
				if recording = '1' or adding = '1' then
					wr_en <= '1';
				end if;
			end if;
			
			-- change situation for next loop?
			if addr_tc = '1' then
				recording_n <= '0';
				adding_n <= '0';
				
				if rec_next = '1' then
					recording_n <= '1';
					rec_next_n <= '0';
				elsif add_next = '1' then
					adding_n <= '1';
					add_next_n <= '0';
				end if;
			end if;
	end case;
end process combLogic;

end Behavioral;

