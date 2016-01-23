--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:52:32 08/23/2015
-- Design Name:   
-- Module Name:   C:/Users/Ethan/Dropbox/Engs31/Project/Project/top_tb.vhd
-- Project Name:  Project
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: project_top
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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY top_tb IS
END top_tb;
 
ARCHITECTURE behavior OF top_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT project_top
    PORT(
         clk : IN  std_logic;
         sound_sw : IN  std_logic;
         reverse : IN  std_logic;
         speed_up : IN  std_logic;
         slow_down : IN  std_logic;
         rec_over : IN  std_logic;
         add_track : IN  std_logic;
         looper_en : IN  std_logic;
         rec_led : OUT  std_logic;
         time_led : OUT  std_logic_vector(4 downto 0);
			ReverbSwitch: IN std_logic;
         sync : OUT  std_logic;
         DinA : OUT  std_logic;
         sclk_da : OUT  std_logic;
         sdata_in : IN  std_logic;
         sclk_ad : OUT  std_logic;
         nCS : OUT  std_logic;
         gain : OUT  std_logic;
         sp_en : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal sound_sw : std_logic := '0';
   signal reverse : std_logic := '0';
   signal speed_up : std_logic := '0';
   signal slow_down : std_logic := '0';
   signal rec_over : std_logic := '0';
   signal add_track : std_logic := '0';
   signal looper_en : std_logic := '0';
   signal sdata_in : std_logic := '0';
	signal ReverbSwitch : std_logic := '0';

 	--Outputs
   signal rec_led : std_logic;
   signal time_led : std_logic_vector(4 downto 0);
   signal sync : std_logic;
   signal DinA : std_logic;
   signal sclk_da : std_logic;
   signal sclk_ad : std_logic;
   signal nCS : std_logic;
   signal gain : std_logic;
   signal sp_en : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: project_top PORT MAP (
          clk => clk,
          sound_sw => sound_sw,
          reverse => reverse,
          speed_up => speed_up,
          slow_down => slow_down,
          rec_over => rec_over,
          add_track => add_track,
          looper_en => looper_en,
          rec_led => rec_led,
          time_led => time_led,
			 ReverbSwitch => ReverbSwitch,
          sync => sync,
          DinA => DinA,
          sclk_da => sclk_da,
          sdata_in => sdata_in,
          sclk_ad => sclk_ad,
          nCS => nCS,
          gain => gain,
          sp_en => sp_en
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
		sound_sw <= '1';
		sdata_in <= '1';
      wait for 200 us;
		sdata_in <= '0';
		wait for 200 us;
		sdata_in <= '1';
		wait for 200 us;
		looper_en <= '1';
		rec_over <= '1';
		wait for 20*clk_period;
		rec_over <= '0';
		wait;
		
		
   end process;

END;
