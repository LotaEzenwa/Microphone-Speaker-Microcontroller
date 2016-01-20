----------------------------------------------------------------------------------
-- Company: 	ENGS 31 15X
-- Engineer: 	Ethan Blackwood
-- 
-- Create Date:    15:51:41 07/22/2015 
-- Design Name: 	 Monopulser
-- Module Name:    Monopulser - Behavioral 
-- Project Name:	 Recorder / Loop Pedal
-- Target Devices: NEXYS3 - Spartan-6
-- Tool versions: 
-- Description: a monopulser that sets but_pulse for one clock
--					 cycle per button press
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

entity monopulser is
    Port ( clk : in STD_LOGIC;
			  but_d : in  STD_LOGIC; -- button down
			  but_mp : out STD_LOGIC); -- monopulsed button
end monopulser;

architecture Behavioral of monopulser is
	-- monopulser FSM signals
	type but_state_t is (UP, PULSE, DOWN);	
	signal but_state : but_state_t := UP;
	signal but_state_next : but_state_t;

begin
	state_update: process (clk) -- update both button and stopwatch state
	begin
		if rising_edge(clk) then
			but_state <= but_state_next;
		end if;
	end process state_update;
	
	monopulser: process(but_state, but_d)
	begin
		-- defaults
		but_state_next <= but_state;
		but_mp <= '0';
		
		case but_state is
			when UP =>
				if but_d = '1' then 
					but_state_next <= PULSE;
				end if;
			when PULSE =>
				but_mp <= '1'; -- pulse!
				if but_d = '1' then
					but_state_next <= DOWN;
				else
					but_state_next <= UP;
				end if;
			when DOWN =>
				-- wait until button goes up
				if but_d = '0' then
					but_state_next <= UP;
				end if;
		end case;
	end process monopulser;
	
end Behavioral;

