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
			  
           set_hr : in  STD_LOGIC;
           set_min : in  STD_LOGIC;
			  set_inc : in STD_LOGIC;
           set_dec : in  STD_LOGIC;
			  key_code : in STD_LOGIC_VECTOR(3 downto 0);
			  key_hit : in STD_LOGIC;
			  
           bcdout : out  STD_LOGIC_VECTOR (15 downto 0);
			  
			  debug: out STD_LOGIC_VECTOR(3 downto 0)
			);
end hourminbcd;

use work.counterwithlimit;

architecture structural of hourminbcd is

component counterwithlimit is
    Port ( clock : in  STD_LOGIC;
           clear : in  STD_LOGIC;
           up : in  STD_LOGIC;
           down : in  STD_LOGIC;
			  set : in STD_LOGIC;
			  set_value : in STD_LOGIC_VECTOR(3 downto 0);
           limit : in  STD_LOGIC_VECTOR (3 downto 0);
           out_count : out  STD_LOGIC_VECTOR (3 downto 0);
           out_zero : out  STD_LOGIC;
           out_limit : out  STD_LOGIC
			 );
end component;

entity bcd_counter is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           set : in  STD_LOGIC;
           inc : in  STD_LOGIC;
           dec : in  STD_LOGIC;
           maxval : in  STD_LOGIC_VECTOR (7 downto 0);
			  setval : in  STD_LOGIC_VECTOR (3 downto 0);
           is_zero : out  STD_LOGIC;
           is_maxval : out  STD_LOGIC;
           bcd : out  STD_LOGIC_VECTOR (7 downto 0));
end bcd_counter;

signal hour0max: std_logic_vector(3 downto 0);
signal hour1val, hour0val, min0val, min1val: std_logic_vector(3 downto 0);
signal min0zero, min1zero, hour0zero, hour1zero: std_logic; -- outputs of digits reaching 0
signal min0limit, min1limit, hour0limit, hour1limit: std_logic; -- outputs of digits reaching max
signal min0up, min1up, hour0up, hour1up: std_logic; -- control when bcd counters go up
signal min0down, min1down, hour0down, hour1down: std_logic; -- control when counters go down
signal min0out: std_logic_vector(3 downto 0);

signal sync_or_key_min, sync_or_key_hr: STD_LOGIC;
signal mininc_e, mindec_e, minset_e : STD_LOGIC;
signal hourinc_e, hourdec_e, hourset_e : STD_LOGIC;

begin
	-- connect hours to output
	bcdout(15 downto 12) <= hour1val;
	bcdout(11 downto 8) <= hour0val;
	bcdout(7 downto 4) <= min1val;
	bcdout(3 downto 0) <= min0val;
	-- debug
	debug <= hour0max;
	--debug(3) <= sync_or_key_min;
	--debug(2) <= sync_or_key_hr;
	--debug(1) <= key_hit;
	--debug(0) <= sync;
	--debug <= hour0max;
   -- MINUTES
   mininc_e <= set_min and set_inc and (not set_hr) and (not set_dec);
   mindec_e <= set_min and set_dec and (not set_hr) and (not set_inc);
   minset_e <= set_min and (not set_inc) and (not set_hr) and (not set_dec);

	sync_or_key_min <= sync when minset_e = '0' else key_hit;

	min0up <= '1' when mininc_e = '1' else pulse;
	min0down <= mindec_e;
	min0: counterwithlimit port map (
								clock => sync_or_key_min,
								clear => reset,
								limit => X"9",
								up => min0up,
								down => min0down,
								set => minset_e,
								set_value => key_code,
								out_count => min0val, 
								out_limit => min0limit,
								out_zero => min0zero
									);					

	min1up <= min0limit when mininc_e = '1' else (min0limit and pulse);
	min1down <= mindec_e and min0zero;
	min1: counterwithlimit port map (
								clock => sync_or_key_min,
								clear => reset,
								limit => X"5",
								up => min1up,
								down => min1down,
								set => minset_e,
								set_value => min0val, 
								out_count => min1val,
								out_limit => min1limit,
								out_zero => min1zero
									);				
	-- HOURS
   hourinc_e <= set_hr and set_inc and (not set_min) and (not set_dec);
   hourdec_e <= set_hr and set_dec and (not set_min) and (not set_inc);
   hourset_e <= set_hr and (not set_inc) and (not set_min) and (not set_dec);

	sync_or_key_hr <= sync when hourset_e = '0' else key_hit;

	hour0up <= '1' when hourinc_e = '1' else (min1limit and min0limit and pulse);
	hour0down <= hourdec_e;
	-- establish max value for hours least significant digit (3 or 9) - this means hour singles depends on hour tens
   hour0max <= X"3" when ((hour1val = X"2" and hourinc_e = '1') or (hour1val = X"0" and hourdec_e = '1')) else X"9";
	hour0: counterwithlimit port map (
								clock => sync_or_key_hr,
								clear => reset,
								limit => hour0max, 
								up => hour0up,
								down => hour0down,
								set => hourset_e,
								set_value => key_code,
								out_count => hour0val,
								out_limit => hour0limit,
								out_zero => hour0zero
									);					

	hour1up <= hour0limit when hourinc_e = '1' else (hour0limit and min1limit and min0limit and pulse);
	hour1down <= hourdec_e and hour0zero;
	hour1: counterwithlimit port map (
								clock => sync_or_key_hr,
								clear => reset,
								limit => X"2",
								up => hour1up,
								down => hour1down,
								set => hourset_e,
								set_value => hour0val,
								out_count => hour1val
								--out_limit => hour1limit,
								--out_zero => hour1zero
									);	
	
end structural;

