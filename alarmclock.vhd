----------------------------------------------------------------------------------
-- Company: @Home
-- Engineer: Zoltan Pekic (zpekic@hotmail.com)
-- 
-- Create Date:    12:26:24 02/07/2016 
-- Design Name: 
-- Module Name:    alarmclock - structural 
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
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity alarmclock is
	port(
		-- 50MHz on the Mercury board
		CLK: in std_logic;
		-- Master reset button on Mercury board
		USR_BTN: in std_logic; 
		-- Switches on baseboard
		-- SW0 - select alarm (on) or clock (off) to view or set
		-- SW1 - enable alarm (on)
		-- SW2 - 12hr mode (on), or 24hr mode (off)
		-- SW3 - enable ADC display (on), or enable clock/alarm (off)
		-- SW4 - keyboard mode, dec(on), hex(off)
		-- SW5 - not used
		-- SW6 - 7seg dimmer mode select (or ADC channel to display value)
		-- SW7 - 7seg dimmer mode select (or ADC channel to display value)
		-- dimmer mode -- SW7 -- SW6 --
		-- potentiometer	on		 on
		-- light sensor   on 	 off
		-- temperature    off    on
		-- on (max light) off    off
      -------------------------------	
		SW: in std_logic_vector(7 downto 0); 
		-- Push buttons on baseboard
		-- BTN3 - press to set hour for either alarm or clock
		-- BTN2 - press to set minutes for either alarm or clock
		-- BTN1 - decrement hour or minute by one each second (depending on BTN3 or BTN2)
		-- BTN0 - increment hour or minute by one each second (depending on BTN3 or BTN2)
		-- also push any of these to dismiss alarm
		BTN: in std_logic_vector(3 downto 0); 
		-- Stereo audio output on baseboard, used to output sound if alarm is triggered
		AUDIO_OUT_L, AUDIO_OUT_R: out std_logic;
		-- 7seg LED on baseboard to display clock or alarm
		A_TO_G: out std_logic_vector(6 downto 0); 
		AN: out std_logic_vector(3 downto 0); 
		-- dot on digit 0 is lit up - PM if in 12hr mode
		-- dot on digit 2 is lit up - 1Hz blicking if clock or steady if alarm is displayed
		DOT: out std_logic; 
		-- 4 LEDs on Mercury board will "count" (alarm enabled but not triggered), "flash" (alarm triggered) or be off (alarm disabled)
		--LED: out std_logic_vector(3 downto 0);
		LED: out std_logic_vector(3 downto 0);
		-- ADC interface
		ADC_MISO: in std_logic;
		ADC_MOSI: out std_logic;
		ADC_SCK: out std_logic;
		ADC_CSN: out std_logic;
		-- PMOD interface (for hex keypad)
		PMOD: inout std_logic_vector(7 downto 0)
		-- VGA
		--HSYNC: out std_logic;
		--VSYNC: out std_logic;
		--RED: out std_logic_vector(2 downto 0);
		--GRN: out std_logic_vector(2 downto 0);
		--BLU: out std_logic_vector(1 downto 0)
	);
end alarmclock;

use work.clock_divider;
use work.mux16to4;
use work.mux32to16;
use work.fourdigitsevensegled;
use work.counterwithlimit;
use work.pwm10bit;
use work.aclock;
use work.PmodKYPD;
use work.debouncer;
use work.bin2bcd;

architecture structural of alarmclock is

component clock_divider
    Port ( reset : in  STD_LOGIC;
           clock : in  STD_LOGIC;
           div : out  STD_LOGIC_VECTOR (7 downto 0)
			 );
end component;

component mux16to4
    Port ( a : in  STD_LOGIC_VECTOR (3 downto 0);
           b : in  STD_LOGIC_VECTOR (3 downto 0);
           c : in  STD_LOGIC_VECTOR (3 downto 0);
           d : in  STD_LOGIC_VECTOR (3 downto 0);
           s : in  STD_LOGIC_VECTOR (1 downto 0);
           y : out  STD_LOGIC_VECTOR (3 downto 0)
			 );
end component;

component mux32to16
    Port ( a : in  STD_LOGIC_VECTOR (15 downto 0);
           b : in  STD_LOGIC_VECTOR (15 downto 0);
           s : in  STD_LOGIC;
           y : out  STD_LOGIC_VECTOR (15 downto 0)
			 );
end component;

component fourdigitsevensegled is
    Port ( -- inputs
			  data : in  STD_LOGIC_VECTOR (15 downto 0);
           digsel : in  STD_LOGIC_VECTOR (1 downto 0);
           showdigit : in  STD_LOGIC_VECTOR (3 downto 0);
           showdot : in  STD_LOGIC_VECTOR (3 downto 0);
           showsegments : in  STD_LOGIC;
			  -- outputs
           anode : out  STD_LOGIC_VECTOR (3 downto 0);
           segment : out  STD_LOGIC_VECTOR (7 downto 0)
			 );
end component;

component pwm10bit is
    Port ( clk : in  STD_LOGIC;
			  adc_samplingrate: in STD_LOGIC;	
           adc_channel : in  STD_LOGIC_VECTOR (2 downto 0);
			  adc_miso : in  std_logic;         -- ADC SPI MISO
			  adc_mosi : out std_logic;         -- ADC SPI MOSI
			  adc_cs   : out std_logic;         -- ADC SPI CHIP SELECT
			  adc_clk  : out std_logic;         -- ADC SPI CLOCK
			  adc_value: out std_logic_vector(15 downto 0);
			  adc_valid: out std_logic;
           pwm_out : out  STD_LOGIC);
end component;

component aclock is
    Port ( reset : in  STD_LOGIC;
           onehertz : in  STD_LOGIC;

			  select_alarm: in  STD_LOGIC;
			  enable_alarm: in  STD_LOGIC;
			  select_12hr: in  STD_LOGIC;
			  enable_set: in  STD_LOGIC;			  

           set_hr : in  STD_LOGIC;
           set_min : in  STD_LOGIC;
           set_inc : in  STD_LOGIC;
           set_dec : in  STD_LOGIC;
			  key_code : in STD_LOGIC_VECTOR(3 downto 0);
			  key_hit : in STD_LOGIC;

           hrmin_bcd : out  STD_LOGIC_VECTOR (15 downto 0);
			  is_pm: out STD_LOGIC;
           alarm_active : out  STD_LOGIC;
			  debug_port: out STD_LOGIC_VECTOR(3 downto 0));
end component;

component PmodKYPD is
    Port ( 
           clk : in  STD_LOGIC;
			  reset: in STD_LOGIC;
			  bcdmode: in STD_LOGIC;
           Col : out  STD_LOGIC_VECTOR (3 downto 0);
			  Row : in  STD_LOGIC_VECTOR (3 downto 0);
           entry : out  STD_LOGIC_VECTOR (15 downto 0);
			  key_code : out STD_LOGIC_VECTOR(3 downto 0);
			  key_down: out STD_LOGIC
			 );
end component;

component debouncer is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           signal_in : in  STD_LOGIC;
           signal_out : out  STD_LOGIC);
end component;

component bin2bcd is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           bcd_mode : in  STD_LOGIC;
           input_ready : in  STD_LOGIC;
           input : in  STD_LOGIC_VECTOR (15 downto 0);
           output_ready : out  STD_LOGIC;
           output : out  STD_LOGIC_VECTOR (19 downto 0);
			  debug: out STD_LOGIC_VECTOR(3 downto 0));
end component;

-- common signals
signal sel: std_logic_vector(1 downto 0);
signal freq: std_logic_vector(3 downto 0);
signal blinkhours, blinkminutes: std_logic; -- pulse if setting hours/mins
signal resetall: std_logic;
signal onehertz: std_logic; -- sync signals
signal bcd2display, aclock_bcd: std_logic_vector(15 downto 0);
signal showdot: std_logic;
signal is_pm: std_logic;
signal buzz: std_logic;
-- modes of operation
signal select_alarm: std_logic;
signal enable_alarm: std_logic;
signal select_12hr: std_logic;
signal mode_debug: std_logic;
signal mode_operate: std_logic;

-- ADC
signal adc_valid: std_logic;
signal adc_value: std_logic_vector(15 downto 0);
signal adc_ready: std_logic;
signal adc_output: std_logic_vector(19 downto 0);
-- alarm
signal showdot_ispm: std_logic;
signal led4: std_logic_vector(3 downto 0);
-- dimmer
signal freq16, freq32, freq64, freq128: std_logic; -- use either to drive dimmer sample rate, keyboard etc.
signal led_dimmer: std_logic;
signal adc_to_pwm: std_logic;
signal adc_channel: std_logic_vector(2 downto 0);
-- kbd
signal key_code: std_logic_vector(3 downto 0);
signal key_down: std_logic;
-- debug
signal debug16: std_logic_vector(15 downto 0);
signal debug4: std_logic_vector(3 downto 0);
signal pushbutton: std_logic_vector(3 downto 0);
signal debug_adc: unsigned(15 downto 0) := X"03e8";

begin
	-- reset signals
	resetall <= USR_BTN;
	-- mode
	select_alarm <= SW(0);
	enable_alarm <= SW(1);
	select_12hr <= SW(2);
	mode_debug <= SW(3);
	mode_operate <= not mode_debug;
	-- blink per second on the middle dot in clock mode, and keep it on in alarm mode
	onehertz <= (SW(5) and freq128) or ((not SW(5)) and freq(3));
	showdot <= mode_operate and (((not select_alarm) and onehertz) or select_alarm);
	-- show PM status on last dot
	showdot_ispm <= mode_operate and is_pm;
	-- add some blinking to when setting minutes or hours
	blinkhours <= (BTN(3) and freq(2)) or not BTN(3);
	blinkminutes <= (BTN(2) and freq(2)) or not BTN(2);
	-- driving the display mux
	sel(0) <= freq128;
	sel(1) <= freq64;
	-- DIMMER (the mux generates the mapping of 2 switches to 3 out of 8 possible channels and the PWM signal routing)
	dimmer_mux: mux16to4 port map (
		a => "1000", -- full light on, adc channel is ignored
		b(3) => adc_to_pwm,
		b(2 downto 0) => "010", -- measure TEMP (adc channel 2)
		c(3) => adc_to_pwm, -- measure LIGHT (adc channel 3)
		c(2 downto 0) => "011", -- measure LIGHT (adc channel 3)
		d(3) => adc_to_pwm, -- measure POT (adc channel 4)
		d(2 downto 0) => "100", -- measure POT (adc channel 4)
		
		s => SW(7 downto 6),
		
		y(3) => led_dimmer,
		y(2 downto 0) => adc_channel(2 downto 0)
	);
	-- DEBOUNCE the 4 push buttons
	d0: debouncer port map (
		reset => resetall,
		clock => freq128,
		signal_in => BTN(0),
		signal_out => pushbutton(0)
	);
	d1: debouncer port map (
		reset => resetall,
		clock => freq128,
		signal_in => BTN(1),
		signal_out => pushbutton(1)
	);
	d2: debouncer port map (
		reset => resetall,
		clock => freq128,
		signal_in => BTN(2),
		signal_out => pushbutton(2)
	);
	d3: debouncer port map (
		reset => resetall,
		clock => freq128,
		signal_in => BTN(3),
		signal_out => pushbutton(3)
	);
	
	-- EXPERIMENTAL VGA
--	expvga: sr_ff port map (
--		reset => resetall,
--		clock => CLK,
--		h_sync => HSYNC,
--		v_sync => VSYNC,
--		rgb(7 downto 6) => BLU(1 downto 0),
--		rgb(5 downto 3) => GRN(2 downto 0),
--		rgb(2 downto 0) => RED(2 downto 0)
--	);

	-- FREQUENCY GENERATOR
	one_sec: clock_divider port map (
								clock => CLK,
								reset => resetall,
								div(7) => freq(3), -- 1Hz
								div(6) => freq(2), -- 2Hz
								div(5) => freq(1), -- 4Hz
								div(4) => freq(0), -- 8Hz
								div(3) => freq16,  -- 16Hz
								div(2) => freq32,  -- 32Hz
								div(1) => freq64,  -- 64Hz
								div(0) => freq128  -- 128Hz
												);
   -- CLOCK WITH ALARM
   clockwithalarm: aclock Port map (
							  reset => resetall,
							  onehertz => onehertz,
							  
							  select_alarm => select_alarm,
							  enable_alarm => enable_alarm,
							  select_12hr => select_12hr,
							  enable_set => mode_operate,			  

							  set_hr => pushbutton(3),
							  set_min => pushbutton(2),
							  set_inc => pushbutton(1),
							  set_dec => pushbutton(0),
							  key_code => key_code,
							  key_hit => key_down,
							  
							  hrmin_bcd => aclock_bcd,
							  is_pm => is_pm,
							  alarm_active => buzz--,
							  --debug_port => debug4
							 );
	-- indicate alarm (flashing Mercury LEDs and nasty sound)
	muxled: mux16to4 port map (
								a => debug4,   -- alarm disabled, no buzz, show debug bits
								b => "1111",   -- alarm disabled, buzz - this should never happen! 
								c => freq,  	-- alarm enabled but not buzzing (counting lights)
								d(3) => onehertz, -- alarm enabled and buzzing (all flashing)
								d(2) => onehertz,
								d(1) => onehertz,
								d(0) => onehertz,
								y => led4,
								s(1) => enable_alarm,
								s(0) => buzz
									);
	-- dim the LEDs just like the 7seg display
   LED(3) <= adc_to_pwm and led4(3);
   LED(2) <= adc_to_pwm and led4(2);
   LED(1) <= adc_to_pwm and led4(1);
   LED(0) <= adc_to_pwm and led4(0);
	-- "stereo" alternating buzzing sound
	AUDIO_OUT_L <= SW(1) and buzz and ((onehertz and sel(1)) or ((not onehertz) and sel(0))); 
	AUDIO_OUT_R <= SW(1) and buzz and ((onehertz and sel(0)) or ((not onehertz) and sel(1)));

	-- MAIN DISPLAY MUX
	dispmux: mux32to16 port map (
								a => aclock_bcd,
								b => debug16,
								y => bcd2display,
								s => mode_debug
									);
									
	display: fourdigitsevensegled port map ( 
			  data => bcd2display,
           digsel => sel,
           showsegments => led_dimmer,
           showdigit(3) => blinkhours,
           showdigit(2) => blinkhours,
           showdigit(1) => blinkminutes,
           showdigit(0) => blinkminutes,
           showdot(3) => '0',
			  showdot(2) => showdot,
			  showdot(1) => '0',
			  showdot(0) => showdot_ispm,
           anode => AN,
			  segment(7) => DOT,
           segment(6 downto 0) => A_TO_G
				);
   -- DIMMER converts ADC channel signal to pulse-width-modulated one to use for displays
   dimmer: pwm10bit Port map 
		   ( clk => CLK,
			  adc_samplingrate => freq64, -- 64Hz sampling rate	
			  adc_miso => ADC_MISO, -- ADC SPI MISO
			  adc_mosi => ADC_MOSI, -- ADC SPI MOSI
			  adc_cs   => ADC_CSN,  -- ADC SPI CHIP SELECT
			  adc_clk  => ADC_SCK,  -- ADC SPI CLOCK
           adc_channel => adc_channel, -- select light (011) or potentiometer (100)
			  adc_value => adc_value,
			  adc_valid => adc_valid,
           pwm_out => adc_to_pwm
			);
			
	-- Possibly convert ADC reading to BCD		
	adc2bcd: bin2bcd Port map
			( reset => resetall,
           clk => CLK,
           bcd_mode => SW(4),
           input_ready => adc_valid,
           input => adc_value, --std_logic_vector(debug_adc), --adc_value,
           output_ready => adc_ready,
           output => adc_output,
			  debug => debug4
	);
	
	--debug_adc <= X"00" & freq(3) & freq(2) & freq(1) & freq(0) & freq16 & freq32 & freq64 & freq128;
	-- Increment ADC for debug purposes
	--increment_adc: process(freq(2))
	--begin
	--	if (rising_edge(freq(2))) then
	--		debug_adc <= debug_adc + 1;
	--	end if;
	--end process;
	
	-- Capture ADC reading for display
	capture_adc: process(adc_ready)
	begin
		if (rising_edge(adc_ready)) then
			debug16 <= adc_output(15 downto 0);
		end if;
	end process;
	--debug4 <= "11" & adc_valid & adc_ready;
	
	-- KEYBOARD
	kbd: PmodKYPD Port map
			( clk => freq64, -- 64Hz, means each key is sampled at 4Hz rate (64/16)
			  reset => resetall,
			  bcdmode => SW(4),
           Col(3) => PMOD(0),
           Col(2) => PMOD(1),
           Col(1) => PMOD(2),
           Col(0) => PMOD(3),
			  Row(3) => PMOD(4),
			  Row(2) => PMOD(5),
			  Row(1) => PMOD(6),
			  Row(0) => PMOD(7),
           --entry => debug16,
			  key_code => key_code,
			  key_down => key_down			  
			);
				
end structural;

