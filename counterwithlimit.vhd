----------------------------------------------------------------------------------
-- Company: @Home
-- Engineer: Zoltan Pekic (zpekic@hotmail.com)
-- 
-- Create Date:    11:26:14 02/14/2016 
-- Design Name: 
-- Module Name:    counterwithlimit - Behavioral 
-- Project Name:   Alarm Clock
-- Target Devices: Mercury FPGA + Baseboard (http://www.micro-nova.com/mercury/)
-- Tool versions:  Xilinx ISE 14.7 (nt64)
-- Description: 
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

entity counterwithlimit is
    Port ( clock : in  STD_LOGIC;
           clear : in  STD_LOGIC;
           up : in  STD_LOGIC;
           down : in  STD_LOGIC;
           limit : in  STD_LOGIC_VECTOR (3 downto 0);
           value : out  STD_LOGIC_VECTOR (3 downto 0);
           is_zero : out  STD_LOGIC;
           is_limit : out  STD_LOGIC);
end counterwithlimit;

architecture Behavioral of counterwithlimit is

	signal cnt: unsigned(3 downto 0);
	signal maxval: unsigned(3 downto 0);

begin
	value(3) <= cnt(3);
	value(2) <= cnt(2);
	value(1) <= cnt(1);
	value(0) <= cnt(0);
	
	maxval(3) <= limit(3);
	maxval(2) <= limit(2);
	maxval(1) <= limit(1);
	maxval(0) <= limit(0);
	
	compare_with_zero: process(cnt)
	begin
		if cnt = "0000" then
			is_zero <= '1';
		else 
			is_zero <= '0';
		end if;
	end process;

	compare_with_limit: process(cnt, maxval)
	begin
		if cnt = maxval then
			is_limit <= '1';
		else 
			is_limit <= '0';
		end if;
	end process;
	
	count: process(clock, clear)
	begin
		if clear = '1' then
			cnt <= "0000";
		else
			if clock'event and clock = '1' then
				if up = '1' then
					if cnt = maxval then
						cnt <= "0000";
					else
						cnt <= cnt + 1;
					end if;
				end if;
				if down = '1' then
					if cnt = "0000" then
						cnt <= maxval;
					else 
						cnt <= cnt - 1;
					end if;
				end if;
			end if;
		end if;
	end process;


end Behavioral;

