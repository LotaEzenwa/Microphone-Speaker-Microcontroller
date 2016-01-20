----------------------------------------------------------------------------------
-- Company: Engs 31 15X
-- Engineer: Ethan Blackwood and Lota Ezenwa
-- 
-- Create Date:    14:43:54 07/30/2015 
-- Design Name: 
-- Module Name:    ud_counter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 	arbitrary-size up/down counter withs synchronous clear and enable
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

entity ud_counter is
	generic( MAX: Integer);	
    Port ( clk : in  STD_LOGIC;
           en : in  STD_LOGIC;
           tc : out  STD_LOGIC;
           clr : in  STD_LOGIC;
			  count : out STD_LOGIC_VECTOR (integer(ceil(log2(real(MAX+1))))-1 downto 0);
			  up : in STD_LOGIC -- 1 to count up
			  );
end ud_counter; 	


architecture Behavioral of ud_counter is

constant COUNT_LEN: integer := integer(ceil(log2(real(MAX+1))));
constant UMAX: unsigned(COUNT_LEN-1 downto 0) := to_unsigned(MAX, COUNT_LEN);
signal count_i: unsigned(COUNT_LEN-1 downto 0) := (others => '0');
signal tc_i : std_logic;

begin

count_update:
process (clk)
begin
	if rising_edge(clk) then
		if clr = '1' then
			if up = '1' then
				count_i <= (others => '0');
			else
				count_i <= UMAX;
			end if;
		elsif en = '1' then
			if up = '1' then
				if tc_i = '1' then
					count_i <= (others => '0');
				else
					count_i <= count_i + 1;
				end if;
			else
				if tc_i = '1' then
					count_i <= UMAX;
				else
					count_i <= count_i - 1;
				end if;
			end if;
		end if;
	end if;
end process count_update;

tc_proc: process(count_i, up)
begin
	if up = '1' then
		if count_i = UMAX then
			tc_i <= '1';
		else
			tc_i <= '0';
		end if;
	else
		if count_i = to_unsigned(0, COUNT_LEN) then
			tc_i <= '1';
		else
			tc_i <= '0';
		end if;
	end if;
end process tc_proc;

count <= std_logic_vector(count_i);
tc <= tc_i;

end Behavioral;

