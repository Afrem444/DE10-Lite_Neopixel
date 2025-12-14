library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DE10Lite_Neopixel is
	port (
		CLOCK_50 : in  std_logic;
		GPIO     : out std_logic_vector(35 downto 0);
		KEY      : in  std_logic_vector(1 downto 0);
		SW       : in  std_logic_vector(9 downto 0)
	); 
end DE10Lite_Neopixel;

architecture rtl of DE10Lite_Neopixel  is
	signal counter   : std_logic_vector (25 downto 0):= (others => '0');    -- 26Bit Vektor als Zähler! (2^26=67'108'864)
	signal Clock_neo : std_logic := '0';
	signal T0H : integer := 5;
	constant T0L : integer := 35;
	constant T1H : integer := 30;
	constant T1L : integer := 35;
	constant TReset : integer := 500000;
	signal BLED1 : std_logic_vector (7 downto 0):= (others => '0');
	signal RLED1 : std_logic_vector (7 downto 0):= (others => '0');
	signal GLED1 : std_logic_vector (7 downto 0):= (others => '0');
	signal RGB1  : std_logic_vector (23 downto 0);
	signal position : integer range 0 to 23 := 0;
	signal led_count : integer range 0 to 9 := 0;
	signal KEY_prev : std_logic_vector(1 downto 0) := "11";  -- Previous KEY state for edge detection
	

	begin
	
		BLED1 <= (others => SW(0));
		RLED1 <= (others => SW(1));
		GLED1 <= (others => SW(2));
	
		RGB1 <= BLED1 & RLED1 & GLED1;
		
		KEY_PROCESS : process (CLOCK_50)
		begin
			if rising_edge(CLOCK_50) then 
				-- Detect rising edge on KEY(0) (active low, so detect 0->1 transition)
				if KEY_prev(0) = '0' and KEY(0) = '1' then 
					T0H <= T0H + 1;
				end if;
				-- Detect rising edge on KEY(1)
				if KEY_prev(1) = '0' and KEY(1) = '1' then 
					T0H <= T0H - 1;
				end if;
				KEY_prev <= KEY;
			end if;
		end process KEY_PROCESS;
		
		DIV_COUNTER : process (CLOCK_50, counter, position, led_count)		   -- Prozess für Clockteiler
		begin
			if (CLOCK_50'event AND CLOCK_50='1')then 		-- Positive Flanke erkennen
				if (led_count = 9) then
					if (counter = TReset) then 
						position <= 0;
						counter <= (others => '0');
						led_count <= 0;
					else
						counter <= counter + 1;
					end if;
				elsif (position = 23) then
					position <= 0;
					counter <= (others => '0');
					led_count <= led_count + 1;
				elsif ((Clock_neo = '1') and (RGB1(position) = '1') and (counter = T1H)) then
					Clock_neo <= '0';		    -- Teiler 
					counter <= (others => '0');
					position <= position + 1;
				elsif ((Clock_neo = '1') and (RGB1(position) = '0') and (counter = T0H)) then
					Clock_neo <= '0';		    -- Teiler 
					counter <= (others => '0');
					position <= position + 1;
				elsif ((Clock_neo = '0') and (RGB1(position) = '1') and (counter = T1L)) then
					Clock_neo <= '1';		    -- Teiler 
					counter <= (others => '0');
				elsif ((Clock_neo = '0') and (RGB1(position) = '0') and (counter = T0L)) then
					Clock_neo <= '1';		    -- Teiler 
					counter <= (others => '0');
				else
					counter <= counter + 1;				
				end if;
			end if;
		end process;
		
		GPIO(0) <= Clock_neo;
		
		
end rtl;