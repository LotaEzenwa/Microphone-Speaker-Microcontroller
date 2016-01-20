----------------------------------------------------------------------------------
-- Company: 	Engs 31 15X
-- Engineer: 	Ethan Blackwood and Lota Ezenwa
-- 
-- Create Date:    15:05:12 08/06/2015 
-- Design Name: 
-- Module Name:    FIFO - Behavioral 
-- Project Name: 	 Audio project (adapted from Lab 6)
-- Target Devices: 
-- Tool versions:  FIFO that can store received samples
-- Description: 
--
-- Dependencies: RegFile.vhd, FIFO_controller.vhd
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FIFO is
		generic(DAT_W : integer;		-- width of data in regfile
				  ADD_W : integer);		-- width of address line to regfile
    Port ( clk : in STD_LOGIC;
			  char_rx : in  STD_LOGIC_VECTOR (DAT_W-1 downto 0);  -- char from receiver
           char_tx : out  STD_LOGIC_VECTOR (DAT_W-1 downto 0); -- char to transmitter
           rx_done_tick : in  STD_LOGIC;	 -- new char ready from receiver
           tx_done_tick : in  STD_LOGIC;	 -- done transmitting
			  tx_from_reg_i: in STD_LOGIC
			  );		
end FIFO;

architecture Behavioral of FIFO is

-- component declarations

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

component FIFO_controller
Port ( clk : in  STD_LOGIC;
           write_inc_en : out  STD_LOGIC;
           read_inc_en : out  STD_LOGIC;
           wr_en : out  STD_LOGIC;
			  rx_done_tick: in STD_LOGIC;
			  tx_done_tick: in STD_LOGIC
			  );
end component;

constant MAX_COUNT : Integer := 2**(ADD_W)-1; -- maximum address = max_count for read and write address counters

signal wr_en : std_logic;														-- regfile write enable
signal read_en_i, write_en_i : std_logic;									-- increment read / write address
signal tx_from_reg : std_logic:= '0';																			-- multiplexer control bit
signal data_from_reg : std_logic_vector (DAT_W-1 downto 0); 		-- data read from register
signal mix_sig : std_logic_vector (DAT_W downto 0);
signal mix_sig_out : std_logic_vector (DAT_W-1 downto 0);

signal read_add :  std_logic_vector(ADD_W-1 downto 0);  							-- read address counter
signal read_add_u :        unsigned(ADD_W-1 downto 0) := (others => '0'); 	-- unsigned read address
signal write_add : std_logic_vector(ADD_W-1 downto 0);                     -- write address counter
signal write_add_u :       unsigned(ADD_W-1 downto 0) := (others => '0');  -- unsigned write address

begin

read_add <= std_logic_vector(read_add_u);
write_add <= std_logic_vector(write_add_u);

RegisterFile: RegFile
	generic map(DATA_W => DAT_W,
				ADDR_W => ADD_W)
	port map(clk => clk,
			data_in => mix_sig_out,
			wr_addr => write_add,
			rd_addr => read_add,
			wr_en	=> wr_en,
			data_out => data_from_reg );

ReadCounter: process(clk)
begin
	if rising_edge(clk) then
		if read_en_i = '1' then
			read_add_u <= read_add_u + 1;
		end if;
	end if;
end process ReadCounter;
			  
WriteCounter: process(clk)
begin
	if rising_edge(clk) then
		if write_en_i = '1' then
			write_add_u <= write_add_u + 1;
		end if;
	end if;
end process WriteCounter;

Control: FIFO_controller
port map(clk => clk,
           write_inc_en => write_en_i,
           read_inc_en => read_en_i,
           wr_en => wr_en,
			  rx_done_tick => rx_done_tick,
			  tx_done_tick => tx_done_tick
			  );

	
	
mux: process (tx_from_reg_i, data_from_reg, char_rx)
begin
if tx_from_reg_i = '1' then
	char_tx <= data_from_reg;
else
	char_tx <= char_rx;
end if;
end process mux;

adder:
process (char_rx, data_from_reg, mix_sig)
begin
	mix_sig <= std_logic_vector(resize(signed(char_rx),DAT_W+1) + resize(signed(data_from_reg(DAT_W-1 downto 1)),DAT_W+1));
	
	if mix_sig(DAT_W downto DAT_W-1) = "01" then
		mix_sig_out <= (DAT_W-1 => '0', others => '1'); --truncate at top
	elsif mix_sig(DAT_W downto DAT_W-1) = "10" then
		mix_sig_out <= (DAT_W-1 => '1', others => '0'); -- truncate at bottom
	else
		mix_sig_out <= mix_sig(DAT_W-1 downto 0);
	end if;
end process adder;




end Behavioral;

