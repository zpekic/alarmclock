----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:50:59 02/13/2016 
-- Design Name: 
-- Module Name:    mux16to4 - structural 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mux16to4 is
    Port ( a : in  STD_LOGIC_VECTOR (3 downto 0);
           b : in  STD_LOGIC_VECTOR (3 downto 0);
           c : in  STD_LOGIC_VECTOR (3 downto 0);
           d : in  STD_LOGIC_VECTOR (3 downto 0);
           s : in  STD_LOGIC_VECTOR (1 downto 0);
           y : out  STD_LOGIC_VECTOR (3 downto 0));
end mux16to4;

architecture rtl of mux16to4 is

signal sela, selb, selc, seld: STD_LOGIC := '0';
	
begin
	sela <= (not s(1)) and (not s(0));
	selb <= (not s(1)) and s(0);
	selc <= s(1) and (not s(0));
	seld <= s(1) and s(0);
	
	y(3) <= (sela and a(3)) or (selb and b(3)) or (selc and c(3)) or (seld and d(3));
	y(2) <= (sela and a(2)) or (selb and b(2)) or (selc and c(2)) or (seld and d(2));
	y(1) <= (sela and a(1)) or (selb and b(1)) or (selc and c(1)) or (seld and d(1));
	y(0) <= (sela and a(0)) or (selb and b(0)) or (selc and c(0)) or (seld and d(0));
end rtl;

