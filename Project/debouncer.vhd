----------------------------------------------------------------------------------
-- Company: 			Engs 31 15X
-- Engineer: 			E.W. Hansen
-- 
-- Create Date:    	09:29:46 08/14/2008 / revised 07/17/2015
-- Design Name: 
-- Module Name:    	debouncer - Behavioral 
-- Project Name: 		
-- Target Devices: 	Spartan 3E, Spartan 6
-- Tool versions: 	ISE 14.7
-- Description: 		Shift-register debouncer, mimics MC14490
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Revision 1.00 (07/17/2015) removed pulse output, now it is just a level
--										no clock divider, runs on 1000 Hz clock
--
-- Additional Comments: 
--		In the future, might try a different design following the Maxim MAX6816, 
--		uses a counter instead of a shift register.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity debouncer is 
	port( 	clk, switch			: in STD_LOGIC;
				dbswitch				: out std_logic );
end debouncer;

architecture behavioral of debouncer is 
constant REG_LEN : integer := 10;	-- typ 10ms, lengthen for more delay
signal dbreg	:	std_logic_vector(REG_LEN-1 downto 0) := (others => '0'); 

begin	  

debounce: 
process(clk, dbreg)
begin
	if rising_edge(clk) then
		if switch /= dbreg(0) then
			dbreg <= switch & dbreg(REG_LEN-1 downto 1);
		else
			dbreg <= (others => switch);
		end if;
	end if;
	
	dbswitch <= dbreg(0);
end process;

end behavioral;
