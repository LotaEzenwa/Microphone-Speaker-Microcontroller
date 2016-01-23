----------------------------------------------------------------------------------
-- Company: Engs 31 15X
-- Engineer: Ethan Blackwood and Lota Ezenwa
-- 
-- Create Date:    14:43:54 07/30/2015 
-- Design Name: 
-- Module Name:    counter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 	arbitrary-size counter withs synchronous clear and enable
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

entity counter is
	generic( MAX: Integer);	
    Port ( clk : in  STD_LOGIC;
           en : in  STD_LOGIC;
           tc : out  STD_LOGIC;
           clr : in  STD_LOGIC;
			  count : out STD_LOGIC_VECTOR (integer(ceil(log2(real(MAX+1))))-1 downto 0)
			  );
end counter;


architecture Behavioral of counter is

constant COUNT_LEN: integer := integer(ceil(log2(real(MAX+1))));
constant UMAX: unsigned(COUNT_LEN-1 downto 0) := to_unsigned(MAX, COUNT_LEN);
signal count_i: unsigned(COUNT_LEN-1 downto 0) := (others => '0');
begin

countUp:
process (clk)
begin
	if rising_edge(clk) then
		if clr = '1' then
			count_i <= (others => '0');
		elsif en = '1' then
			count_i <= count_i + 1;
		end if;
	end if;
end process countUp;

with count_i select tc <= '1' when UMAX, '0' when others; 
count <= std_logic_vector(count_i);

end Behavioral;

