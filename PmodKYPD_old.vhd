----------------------------------------------------------------------------------
-- Company: @Home
-- Engineer: Zoltan Pekic (zpekic@hotmail.com)
-- 
-- Create Date:    23:44:29 03/08/2016 
-- Design Name: 
-- Module Name:    PmodKYPD - Behavioral (http://store.digilentinc.com/pmodkypd-16-button-keypad/)
-- Project Name:   Alarm Clock
-- Target Devices: Mercury FPGA + Baseboard (http://www.micro-nova.com/mercury/)
-- Tool versions:  Xilinx ISE 14.7 (nt64)
-- Description:    12hr/24hr alarm clock with display dimming showcasing baseboard hardware
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PmodKYPD is
    Port ( 
           clk : in  STD_LOGIC;
			  reset: in STD_LOGIC;
			  bcdmode: in STD_LOGIC;
           Col : out  STD_LOGIC_VECTOR (3 downto 0);
			  Row : in  STD_LOGIC_VECTOR (3 downto 0);
           entry : out  STD_LOGIC_VECTOR (15 downto 0);
			  key_code: out  STD_LOGIC_VECTOR (3 downto 0);
			  key_down: out STD_LOGIC
         );
end PmodKYPD;

use work.debouncer;

architecture Behavioral of PmodKYPD is

component debouncer is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           signal_in : in  STD_LOGIC;
           signal_out : out  STD_LOGIC);
end component;

signal counter: unsigned(4 downto 0) := "00000";
signal uniquerow: STD_LOGIC_VECTOR (3 downto 0);
signal hex_entry: STD_LOGIC_VECTOR (15 downto 0);
signal key_value: STD_LOGIC_VECTOR (3 downto 0);

signal key_pressed, key_mask, key_hit: STD_LOGIC;

begin
entry <= hex_entry;
-- scan columns by decode to '0' (because rows have pull-ups)
Col(0) <= key_mask or not ((not counter(2)) and (not counter(1)));
Col(1) <= key_mask or not ((not counter(2)) and counter(1));
Col(2) <= key_mask or not (counter(2) and (not counter(1)));
Col(3) <= key_mask or not (counter(2) and counter(1));

-- key pressed reflects contact between rows and columns (but allow only single row at a time!)
key_pressed <=			((not row(0)) and (not counter(4)) and (not counter(3)) and row(1) and row(2) and row(3)) or 
							((not row(1)) and (not counter(4)) and counter(3) and row(0) and row(2) and row(3)) or 
							((not row(2)) and counter(4) and (not counter(3)) and row(0) and row(1) and row(3)) or 
							((not row(3)) and counter(4) and counter(3) and row(0) and row(1) and row(2));--

key_hit <= key_pressed and not counter(0);
-- outputs
key_down <= key_pressed and counter(0);
--key_code <= key_value;

--debounce_key: debouncer port map (
--	clock => clk,
--	reset => '0',
--	signal_in => key_hit,
--	signal_out => key_down
--);

-- scanning rows and cols
scan_key: process(reset, clk)
begin
   if (reset = '1') then
		counter <= "00000";
	else
		if (clk'event and clk = '1') then
			counter <= counter + 1;
				case counter(4 downto 1) is
					when "0000" =>
						key_value <= X"1"; 
						key_mask <= '0';
					when "0001" =>
						key_value <= X"2"; 
						key_mask <= '0';
					when "0010" =>
						key_value <= X"3"; 
						key_mask <= '0';
					when "0011" =>
						key_value <= X"A"; 
						key_mask <= bcdmode;
					when "0100" =>
						key_value <= X"4"; 
						key_mask <= '0';
					when "0101" =>
						key_value <= X"5"; 
						key_mask <= '0';
					when "0110" =>
						key_value <= X"6"; 
						key_mask <= '0';
					when "0111" =>
						key_value <= X"B"; 
						key_mask <= bcdmode;
					when "1000" =>
						key_value <= X"7"; 
						key_mask <= '0';
					when "1001" =>
						key_value <= X"8"; 
						key_mask <= '0';
					when "1010" =>
						key_value <= X"9"; 
						key_mask <= '0';
					when "1011" =>
						key_value <= X"C"; 
						key_mask <= bcdmode;
					when "1100" =>
						key_value <= X"0"; 
						key_mask <= '0';
					when "1101" =>
						key_value <= X"F"; 
						key_mask <= bcdmode;
					when "1110" =>
						key_value <= X"E"; 
						key_mask <= bcdmode;
					when "1111" =>
						key_value <= X"D"; 
						key_mask <= bcdmode;
					when others =>
						null;
				end case;
		end if;
	end if;
end process;

-- react to key
capture_key: process(reset, key_hit)
begin
   if (reset = '1') then
		hex_entry <= X"0000";
	else
		if (key_hit'event and key_hit = '1') then
				hex_entry(15 downto 0) <= hex_entry(11 downto 0) & key_value;
		end if;
	end if;
end process;

end Behavioral;

--dazhiruoyule


----------------------------------------------------------------------------------
-- Company: @Home
-- Engineer: Zoltan Pekic (zpekic@hotmail.com)
-- 
-- Create Date:    23:44:29 03/08/2016 
-- Design Name: 
-- Module Name:    PmodKYPD - Behavioral (http://store.digilentinc.com/pmodkypd-16-button-keypad/)
-- Project Name:   Alarm Clock
-- Target Devices: Mercury FPGA + Baseboard (http://www.micro-nova.com/mercury/)
-- Tool versions:  Xilinx ISE 14.7 (nt64)
-- Description:    12hr/24hr alarm clock with display dimming showcasing baseboard hardware
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PmodKYPD is
    Port ( 
           clk : in  STD_LOGIC;
			  reset: in STD_LOGIC;
			  bcdmode: in STD_LOGIC;
           Col : out  STD_LOGIC_VECTOR (3 downto 0);
			  Row : in  STD_LOGIC_VECTOR (3 downto 0);
           entry : out  STD_LOGIC_VECTOR (15 downto 0);
			  key_code: out  STD_LOGIC_VECTOR (3 downto 0);
			  key_down: out STD_LOGIC
         );
end PmodKYPD;

use work.debouncer;

architecture Behavioral of PmodKYPD is

component debouncer is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           signal_in : in  STD_LOGIC;
           signal_out : out  STD_LOGIC);
end component;

signal counter: unsigned(3 downto 0) := "0000";
--signal uniquerow: STD_LOGIC_VECTOR (3 downto 0);
signal entry_internal: STD_LOGIC_VECTOR (15 downto 0);
signal key_value: STD_LOGIC_VECTOR (3 downto 0);

signal key_pressed, key_down_internal, key_mask: STD_LOGIC;
signal key_code_internal: STD_LOGIC_VECTOR (3 downto 0);

begin
-- these will be consumed internally, and connected to outputs too
entry <= entry_internal;
key_code <= key_code_internal;
key_down <= key_down_internal;
-- scan columns by decode to '0' (because rows have pull-ups)
Col(0) <= not ((not counter(1)) and (not counter(0)));
Col(1) <= not ((not counter(1)) and counter(0));
Col(2) <= not (counter(1) and (not counter(0)));
Col(3) <= not (counter(1) and counter(0));

-- key pressed reflects contact between rows and columns (but allow only single row at a time!)
key_pressed <=			((not row(0)) and (not counter(3)) and (not counter(2)) and row(1) and row(2) and row(3)) or 
							((not row(1)) and (not counter(3)) and counter(2) and row(0) and row(2) and row(3)) or 
							((not row(2)) and counter(3) and (not counter(2)) and row(0) and row(1) and row(3)) or 
							((not row(3)) and counter(3) and counter(2) and row(0) and row(1) and row(2));--


--debounce_key: debouncer port map (
--	clock => clk,
--	reset => '0',
--	signal_in => key_hit,
--	signal_out => key_down
--);

-- scanning rows and cols
scan_key: process(reset, clk)
begin
   if (reset = '1') then
		counter <= "0000";
	else
		if (clk'event and clk = '1') then
			counter <= counter + 1;
		end if;
	   if (clk'event and clk = '0') then
			key_down_internal <= key_pressed and not key_mask;
			key_code_internal <= key_value;	
		end if;
	end if;
end process;

map_key: process(clk, counter)
begin
	if (clk = '1') then
			case counter is
				when "0000" =>
					key_value <= X"1"; 
					key_mask <= '0';
				when "0001" =>
					key_value <= X"2"; 
					key_mask <= '0';
				when "0010" =>
					key_value <= X"3"; 
					key_mask <= '0';
				when "0011" =>
					key_value <= X"A"; 
					key_mask <= bcdmode;
				when "0100" =>
					key_value <= X"4"; 
					key_mask <= '0';
				when "0101" =>
					key_value <= X"5"; 
					key_mask <= '0';
				when "0110" =>
					key_value <= X"6"; 
					key_mask <= '0';
				when "0111" =>
					key_value <= X"B"; 
					key_mask <= bcdmode;
				when "1000" =>
					key_value <= X"7"; 
					key_mask <= '0';
				when "1001" =>
					key_value <= X"8"; 
					key_mask <= '0';
				when "1010" =>
					key_value <= X"9"; 
					key_mask <= '0';
				when "1011" =>
					key_value <= X"C"; 
					key_mask <= bcdmode;
				when "1100" =>
					key_value <= X"0"; 
					key_mask <= '0';
				when "1101" =>
					key_value <= X"F"; 
					key_mask <= bcdmode;
				when "1110" =>
					key_value <= X"E"; 
					key_mask <= bcdmode;
				when "1111" =>
					key_value <= X"D"; 
					key_mask <= bcdmode;
				when others =>
					null;
			end case;
		end if;
end process;

-- react to key
capture_key: process(reset, key_down_internal)
begin
   if (reset = '1') then
		entry_internal <= X"0000";
	else
		if (key_down_internal'event and key_down_internal = '1') then
				entry_internal(15 downto 0) <= entry_internal(11 downto 0) & key_code_internal;
		end if;
	end if;
end process;

end Behavioral;

map_key: process(clk, counter)
begin
	if (clk = '1') then
			case counter is
				when "0000" =>
					Col <= "1110";
					key_value <= X"1";
					key_mask <= "0001";
				when "0001" =>
					Col <= "1101";
					key_value <= X"2"; 
					key_mask <= "0001";
				when "0010" =>
					Col <= "1011";
					key_value <= X"3"; 
					key_mask <= "0001";
				when "0011" =>
					Col <= "0111";
					key_value <= X"A"; 
					key_mask <= "0001";-- when bcdmode = '1' else "1111";
				when "0100" =>
					Col <= "1110";
					key_value <= X"4"; 
					key_mask <= "0010";
				when "0101" =>
					Col <= "1101";
					key_value <= X"5"; 
					key_mask <= "0010";
				when "0110" =>
					Col <= "1011";
					key_value <= X"6"; 
					key_mask <= "0010";
				when "0111" =>
					Col <= "0111";
					key_value <= X"B"; 
					key_mask <= "0010";-- when bcdmode = '1' else "1111";
				when "1000" =>
					Col <= "1110";
					key_value <= X"7"; 
					key_mask <= "0100";
				when "1001" =>
					Col <= "1101";
					key_value <= X"8"; 
					key_mask <= "0100";
				when "1010" =>
					Col <= "1011";
					key_value <= X"9"; 
					key_mask <= "0100";
				when "1011" =>
					Col <= "0111";
					key_value <= X"C"; 
					key_mask <= "0100";-- when bcdmode = '1' else "1111";
				when "1100" =>
					Col <= "1110";
					key_value <= X"0"; 
					key_mask <= "1000";
				when "1101" =>
					Col <= "1101";
					key_value <= X"F"; 
					key_mask <= "1000";-- when bcdmode = '1' else "1111";
				when "1110" =>
					Col <= "1011";
					key_value <= X"E"; 
					key_mask <= "1000";-- when bcdmode = '1' else "1111";
				when "1111" =>
					Col <= "0111";
					key_value <= X"D"; 
					key_mask <= "1000";-- when bcdmode = '1' else "1111";
				when others =>
					null;
			end case;
		end if;
end process;
