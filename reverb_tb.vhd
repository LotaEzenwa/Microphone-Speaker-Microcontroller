--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   06:00:42 08/30/2015
-- Design Name:   
-- Module Name:   C:/Users/Ethan/Dropbox/Engs31/Project/Project/reverb_tb.vhd
-- Project Name:  Project
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: FIFO
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY reverb_tb IS
END reverb_tb;
 
ARCHITECTURE behavior OF reverb_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT FIFO
	 GENERIC(DAT_W : integer;		-- width of data in regfile
			  ADD_W : integer);		-- width of address line to regfile
    PORT(
         clk : IN  std_logic;
         char_rx : IN  std_logic_vector(DAT_W-1 downto 0);
         char_tx : OUT  std_logic_vector(DAT_W-1 downto 0);
         tx_done_tick : IN  std_logic;
         rx_done_tick : IN  std_logic;
         tx_from_reg_i : IN  std_logic
        );
    END COMPONENT;
    
	--Constants
	constant DAT_W : integer := 12;
	constant ADD_W : integer := 3; -- smaller so we can test it

   --Inputs
   signal clk : std_logic := '0';
   signal char_rx : std_logic_vector(DAT_W-1 downto 0) := (others => '0');
   signal rx_done_tick : std_logic := '0';
   signal tx_done_tick : std_logic := '0';
   signal tx_from_reg_i : std_logic := '0';

 	--Outputs
   signal char_tx : std_logic_vector(DAT_W-1 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: FIFO 
	GENERIC MAP (
			 DAT_W => DAT_W,
			 ADD_W => ADD_W)
	PORT MAP (
          clk => clk,
          char_rx => char_rx,
          char_tx => char_tx,
          rx_done_tick => rx_done_tick,
          tx_done_tick => tx_done_tick,
          tx_from_reg_i => tx_from_reg_i
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin	
		
		-- reverb off - FIFO stores the calculated signal with reverb, but the output comes straight from the input
		for i in 0 to 19 loop
			char_rx <= std_logic_vector(to_signed(i,DAT_W));
			tx_done_tick <= '1';
			rx_done_tick <= '1';
			wait for clk_period;
			rx_done_tick <= '0';
			tx_done_tick <= '0';
			wait for clk_period*9;
			
			if i = 9 then
				tx_from_reg_i <= '1'; -- turn on reverb; output should now be a combination of current input and stored input
			end if;
		end loop;

      wait;
   end process;

END;
