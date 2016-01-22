----------------------------------------------------------------------------------
-- Company: ENGS 31 15X
-- Engineer: Lota Ezenwa and Ethan Blackwood
-- 
-- Create Date:    16:20:51 08/06/2015 
-- Design Name: 
-- Module Name:    FIFO_controller - Behavioral 
-- Project Name:   Audio project (adapted from Lab 6)
-- Target Devices: 
-- Tool versions: 
-- Description:  Controller for the FIFO
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

entity FIFO_controller is
    Port ( clk : in  STD_LOGIC;				-- clock
           write_inc_en : out  STD_LOGIC; -- increment write address (we do this just before writing, except the first write)
           read_inc_en : out  STD_LOGIC;  -- increment read address  (we do this just before reading, except the first read)
           wr_en : out  STD_LOGIC;			-- enable write to buffer
			  rx_done_tick: in STD_LOGIC;		-- a character has been received
			  tx_done_tick: in STD_LOGIC		-- transmission done
			  );		
end FIFO_controller;

architecture Behavioral of FIFO_controller is

	type ram_state is (EMPTY,		-- buffer empty, reset read and write addresses
							 ACTIVE,		-- store and give back modulated signal
							 WT
							 );
							 
	signal current_state : ram_state := EMPTY;
	signal n_state : ram_state := EMPTY;
	signal tx_ready: std_logic := '1';-- flip-flop that is 0 while a transmission is in progress
	signal tx_start: std_logic; --internal signal for tx_start_tick (used for tx_ready)
	
begin

stateUpdate: process(clk)
begin
	if rising_edge(clk) then
		
		current_state <= n_state;	
		
	end if;
end process stateUpdate;

stateLogic:
process(rx_done_tick, current_state, tx_ready)
begin

--defaults
	write_inc_en <= '0';
	read_inc_en <= '0';
	wr_en <= '0';
	tx_start <= '0';
	
	n_state <= current_state;
	
	case current_state is 
		when EMPTY =>
			if rx_done_tick = '1' then
				n_state <= ACTIVE;
				read_inc_en <= '1';
			end if;
		
		--store: write byte to regfile, transmit received byte (unless transmitter is busy), go to interrupt_state
		when ACTIVE =>
			wr_en <= '1';
			if tx_ready = '1' then
				tx_start <= '1';
			end if;
			n_state <= WT;
			
		-- wait: FIFO not empty, waiting for next character	
		when WT =>
			-- if new character received, increment write address and store it
			if rx_done_tick = '1' then
				write_inc_en <= '1';		-- increment address
				read_inc_en <= '1';
				n_state <= ACTIVE;
			
			end if; 			
	end case;	
end process stateLogic;

-- txready: goes low on tx_start_int (start of transmission) and high on tx_done_tick (end of transmission)
txReady: process (clk, tx_start, tx_done_tick) is
begin
	if rising_edge(clk) then
		if tx_done_tick = '1' then
			tx_ready <= '1';
		elsif tx_start = '1' then
			tx_ready <= '0';
		end if;
	end if;
end process txReady;

end Behavioral;

