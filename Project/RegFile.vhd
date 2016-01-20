----------------------------------------------------------------------------------
-- Company: Engs 31 15X
-- Engineer: Ethan Blackwood and Lota Ezenwa
-- 
-- Create Date:    16:05:30 08/06/2015 
-- Design Name: 
-- Module Name:    RegFile - Behavioral 
-- Project Name:   Lab 6 - character buffer
-- Target Devices: 
-- Tool versions: 
-- Description: 	General register file with 1 synchronous read and 1 write port
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

entity RegFile is
	generic (DATA_W : integer;
				ADDR_W : integer);
	port (clk : in std_logic;
			data_in : in std_logic_vector(DATA_W-1 downto 0);
			wr_addr : in std_logic_vector(ADDR_W-1 downto 0);
			rd_addr : in std_logic_vector(ADDR_W-1 downto 0);
			wr_en	  : in std_logic;
			data_out: out std_logic_vector(DATA_W-1 downto 0) );
end RegFile;

architecture Behavioral of RegFile is
	type regfile_type is
		array(0 to (2**ADDR_W)-1) of std_logic_vector(DATA_W-1 downto 0);
	signal regfile : regfile_type := (others => (others => '0'));
	signal data_out_i : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
begin

data_out <= data_out_i;

WriteProcess: process(clk)		-- synchronous write
begin
	if rising_edge(clk) then
		if wr_en = '1' then
			regfile(to_integer(unsigned(wr_addr))) <= data_in;
		end if;
	end if;
end process WriteProcess;

ReadProcess: process(clk)	-- synchronous read
begin
	if rising_edge(clk) then
		data_out_i <= regfile(to_integer(unsigned(rd_addr)));
	end if;
end process ReadProcess;

end Behavioral;

