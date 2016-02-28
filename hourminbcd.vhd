----------------------------------------------------------------------------------
-- Company: @Home
-- Engineer: Zoltan Pekic (zpekic@hotmail.com)
-- 
-- Create Date:    20:49:24 02/20/2016 
-- Design Name: 
-- Module Name:    hourminbcd - structural 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hourminbcd is
    Port ( reset : in  STD_LOGIC;
           sync : in  STD_LOGIC;
			  pulse: in STD_LOGIC;
           mininc : in  STD_LOGIC;
           mindec : in  STD_LOGIC;
           hourinc : in  STD_LOGIC;
           hourdec : in  STD_LOGIC;
			  mode_ampm: in STD_LOGIC;
           bcdout : out  STD_LOGIC_VECTOR (15 downto 0);
			  ispm: out STD_LOGIC
			);
end hourminbcd;

use work.counterwithlimit;
use work.converter24to12;

architecture structural of hourminbcd is

component counterwithlimit is
    Port ( clock : in  STD_LOGIC;
           clear : in  STD_LOGIC;
           up : in  STD_LOGIC;
           down : in  STD_LOGIC;
           limit : in  STD_LOGIC_VECTOR (3 downto 0);
           value : out  STD_LOGIC_VECTOR (3 downto 0);
           is_zero : out  STD_LOGIC;
           is_limit : out  STD_LOGIC
			 );
end component;

component converter24to12 is
    Port ( select12hrmode : in  STD_LOGIC;
           hour24 : in  STD_LOGIC_VECTOR (7 downto 0);
           hour_ispm : out  STD_LOGIC;
           hour_12or24 : out  STD_LOGIC_VECTOR (7 downto 0)
			 );
end component;

signal hour0max: std_logic_vector(3 downto 0);
signal hour0maxis3: std_logic;
signal hour1value, hour0value: std_logic_vector(3 downto 0);
signal min0zero, min1zero, hour0zero, hour1zero: std_logic; -- outputs of digits reaching 0
signal min0limit, min1limit, hour0limit, hour1limit: std_logic; -- outputs of digits reaching max
signal min0up, min1up, hour0up, hour1up: std_logic; -- control when bcd counters go up
signal min0down, min1down, hour0down, hour1down: std_logic; -- control when counters go down

begin
	-- count up/down signals
	min0up <= (mininc) or ((not mininc) and pulse);
	min1up <= (mininc and min0limit) or ((not mininc) and min0limit and pulse);
	hour0up <= (hourinc) or ((not hourinc) and min1limit and min0limit and pulse);
	hour1up <= (hourinc and hour0limit) or ((not hourinc) and hour0limit and min1limit and min0limit and pulse);
	min0down <= mindec;
	min1down <= mindec and min0zero;
	hour0down <= hourdec;
	hour1down <= hourdec and hour0zero;
	-- establish max value for hours least significant digit (3 or 9) - this means hour singles depends on hour tens
	hour0maxis3 <= ((not hourdec) and hour1value(1) and (not hour1value(0))) or (hourdec and (not hour1value(1)) and (not hour1value(0)));
   hour0max(3) <= not hour0maxis3;
   hour0max(2) <= '0';
   hour0max(1) <= hour0maxis3;
   hour0max(0) <= '1';
   -- hour0max <= "0011" when (hour0maxis3 = '1') else "1001";
   -- MINUTES									
	min0: counterwithlimit port map (
								clock => sync,
								clear => reset,
								limit => "1001",
								up => min0up,
								down => min0down,
								value => bcdout(3 downto 0),
								is_limit => min0limit,
								is_zero => min0zero
									);					
	min1: counterwithlimit port map (
								clock => sync,
								clear => reset,
								limit => "0101",
								up => min1up,
								down => min1down,
								value => bcdout(7 downto 4),
								is_limit => min1limit,
								is_zero => min1zero
									);					
	-- HOURS
	hour0: counterwithlimit port map (
								clock => sync,
								clear => reset,
								limit => hour0max, -- this one varies, can be either 3 or 9
								up => hour0up,
								down => hour0down,
								value => hour0value,
								is_limit => hour0limit,
								is_zero => hour0zero
									);					
	hour1: counterwithlimit port map (
								clock => sync,
								clear => reset,
								limit => "0010",
								up => hour1up,
								down => hour1down,
								value => hour1value,
								is_limit => hour1limit,
								is_zero => hour1zero
									);	
	-- 24 to 12 hour converter hooked up to hours
	converthours: converter24to12 port map (
												select12hrmode => mode_ampm,
												hour24(3 downto 0) => hour0value,
												hour24(7 downto 4) => hour1value,
												hour_ispm => ispm,
												hour_12or24 => bcdout(15 downto 8)
														);

end structural;

