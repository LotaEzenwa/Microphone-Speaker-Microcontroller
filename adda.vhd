----------------------------------------------------------------------------------
-- Company: Dartmouth College
-- Engineer: David Picard
-- 
-- Create Date: 04/29/2015 02:32:19 PM
-- Design Name: 
-- Module Name: adda - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: D-A converter
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
use IEEE.numeric_std.ALL;		-- needed for arithmetic

library UNISIM;					-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;


entity adda is
	Generic (BIT_DEPTH: integer);
    Port ( 
         clk  : in STD_LOGIC;
		   sync : out std_logic;
		   DinA : out std_logic;
		   sclk : out std_logic;
			data : in std_logic_vector(BIT_DEPTH-1 downto 0);
			done : out std_logic
			  );
end adda;

architecture Behavioral of adda is



signal lastsampleclk : STD_LOGIC;
signal sampleclk : STD_LOGIC := '0';
	
signal busy, nSYNC, START : STD_LOGIC;								
constant control     : std_logic_vector(3 downto 0) := "0000";

type states is (Idle, ShiftOut, SyncData);  
signal current_state : states;
signal next_state    : states;
                     
signal temp1         : std_logic_vector(15 downto 0);       
signal clk_div       : std_logic;      
signal clk_counter   : unsigned(27 downto 0):= x"0000000";    
signal shiftCounter  : unsigned(4 downto 0); 
signal enShiftCounter: std_logic;
signal enParalelLoad : std_logic;
signal clk_counter2  : integer := 0;    
signal clk_en        : std_logic := '0';
signal data_counter  : unsigned (4 downto 0) := "00000";

begin


sclk <= clk_en;


	Slow_clock_buffer: BUFG
      port map (I => clk_en,
                O => sampleclk );	
------------------------------------------------------------------------------------

clock_divide2 : process(clk)
begin
    if (clk = '1' and clk'event) then
		if clk_counter2 = 2 then clk_en <= not clk_en;
		   clk_counter2 <= 0;
		else clk_counter2 <= clk_counter2 + 1;
		end if;
    end if;
end process;
------------------------------------------------------------------------------------
count_bits : process (sampleclk)
begin
   if (sampleclk'event) and (sampleclk = '1') then
		start <= '0';
		if data_counter = "11001" then
			data_counter <= (others => '0');
			start <= '1';
		else 
			data_counter <= data_counter + 1;
		end if;

		end if; --clk
	end process;



-----------------------------------------------------------------------------------    

counter : process(sampleclk)
        begin
            if (sampleclk = '1' and sampleclk'event) then
				   DinA <= temp1(15);   
				   if start = '1' then
					   temp1 <= "0000" & std_logic_vector(data);
						end if;
               if enParalelLoad = '1' then
                   shiftCounter <= "00000";

                elsif (enShiftCounter = '1') then 
                   temp1 <= temp1(14 downto 0)&temp1(15);
                   shiftCounter <= shiftCounter + 1;
						
                end if;
            end if;
        end process;

-----------------------------------------------------------------------------------            
SYNC_PROC: process (sampleclk)
   begin
      if (sampleclk'event and sampleclk = '1') then
            current_state <= next_state;
            sync <= nsync;
      end if;
   end process;
    

-----------------------------------------------------------------------------------        
OUTPUT_DECODE: process (current_state)
   begin
      if current_state = Idle then
            enShiftCounter <='0';
            DONE <='1';
            nSYNC <='1';
            enParalelLoad <= '1';
        elsif current_state = ShiftOut then
            enShiftCounter <='1';
            DONE <='0';
            nSYNC <='0';
            enParalelLoad <= '0';
        else --if current_state = SyncData then
            enShiftCounter <='0';
            DONE <='0';
            nSYNC <='1';
            enParalelLoad <= '0';
        end if;
   end process;
    

-----------------------------------------------------------------------------------    
    NEXT_STATE_DECODE: process (current_state, START, shiftCounter)
   begin
      
      next_state <= current_state;  
     
      case (current_state) is
         when Idle =>
            if START = '1' then
               next_state <= ShiftOut;
            end if;
         when ShiftOut =>
            if shiftCounter = "01111" then --"10000" then
               next_state <= SyncData;
            end if;
         when SyncData =>
            if START = '0' then
            next_state <= Idle;
            end if;
         when others =>
            next_state <= Idle;
      end case;      
   end process;
					

end Behavioral;
