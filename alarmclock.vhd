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
		-- 100MHz on the Mercury board
		CLK: in std_logic;
		-- Master reset button on Mercury board
		USR_BTN: in std_logic; 
		-- Switches on baseboard
		-- SW0 - select alarm (on) or clock (off) to view or set
		-- SW1 - enable alarm (on)
		-- SW2 - 12hr mode (on), or 24hr mode (off)
		-- SW3 - not used
		-- SW4 - not used
		-- SW5 - not used
		-- SW6 - 7seg dimmer mode select
		-- SW7 - 7seg dimmer mode select
		-- dimmer mode -- SW7 -- SW6 --
		-- off (blank)		on		 on
		-- potentiometer  on 	 off
		-- light sensor   off    on
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
		LED: out std_logic_vector(3 downto 0);
		-- ADC interface
		ADC_MISO: in std_logic;
		ADC_MOSI: out std_logic;
		ADC_SCK: out std_logic;
		ADC_CSN: out std_logic
		);
end alarmclock;

use work.clock_divider;
use work.mux16to4;
use work.mux32to16;
use work.fourdigitsevensegled;
use work.counterwithlimit;
use work.hourminbcd;
use work.comparatorwithstate;
use work.pwm10bit;

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

component hourminbcd is
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
end component;

component comparatorwithstate is
    Port ( a : in  STD_LOGIC_VECTOR (23 downto 0);
           b : in  STD_LOGIC_VECTOR (23 downto 0);
			  clock: in STD_LOGIC;
           reset : in  STD_LOGIC;
			  enable: in STD_LOGIC;
           trigger : out  STD_LOGIC
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
           pwm_out : out  STD_LOGIC);
end component;

-- common signals
signal sel: std_logic_vector(1 downto 0);
signal freq: std_logic_vector(3 downto 0);
signal blinkhours, blinkminutes: std_logic; -- pulse if setting hours/mins
signal minuteinc, minutedec: std_logic; 
signal hourinc, hourdec: std_logic; -- signals that override regular time counting (to set hours and mins)
signal resetall, resetseconds, resetbuzzer: std_logic;
signal secup, minup: std_logic; -- sync signals
signal bcd2display: std_logic_vector(15 downto 0);
signal showdot: std_logic;
signal ampm_mode: std_logic;
signal showdot_ispm: std_logic;
signal alarmled: std_logic_vector(3 downto 0);
-- dimmer
signal freq16, freq32: std_logic; -- use either to drive dimmer sample rate
signal led_dimmer: std_logic;
signal adc_to_pwm: std_logic;
signal adc_channel: std_logic_vector(2 downto 0);
-- seconds signals
signal sec0limit, sec1limit: std_logic;
signal secvalue: std_logic_vector(7 downto 0);
-- clock signals
signal clock_ispm: std_logic;
signal clock_mode: std_logic;
signal clock_bcd: std_logic_vector(15 downto 0);
signal clock_mininc, clock_mindec, clock_hourinc, clock_hourdec: std_logic;
-- alarm signals
signal alarm_ispm: std_logic;
signal alarm_mode: std_logic;
signal alarm_bcd: std_logic_vector(15 downto 0);
signal alarm_mininc, alarm_mindec, alarm_hourinc, alarm_hourdec: std_logic;
signal alarm_enable: std_logic;
signal buzz: std_logic; -- means alarm is on!!

begin
	-- reset signals
	resetall <= USR_BTN;
	resetseconds <= USR_BTN or minuteinc or minutedec; -- when setting minutes, keep seconds at 0
   resetbuzzer <= USR_BTN or BTN(3) or BTN(2) or BTN(1) or BTN(0); -- any button push should kill the alarm
   -- determine operation mode (display and setting)
	alarm_mode <= SW(0);
	clock_mode <= not alarm_mode;
	alarm_enable <= SW(1);
	ampm_mode <= SW(2);
	-- blink per second on the middle dot in clock mode, and keep it on in alarm mode
	secup <= freq(3);
	showdot <= (clock_mode and secup) or (alarm_mode);
	-- show PM status on last dot
	showdot_ispm <= (alarm_mode and alarm_ispm) or (clock_mode and clock_ispm);
	-- signal to bump up clock minutes
	minup <= sec1limit and sec0limit;
	-- set time button signals
	hourinc <= BTN(3) and (not BTN(2)) and (not BTN(1)) and BTN(0);
	hourdec <= BTN(3) and (not BTN(2)) and BTN(1) and (not BTN(0));
	minuteinc <= (not BTN(3)) and BTN(2) and (not BTN(1)) and BTN(0);
	minutedec <= (not BTN(3)) and BTN(2) and BTN(1) and (not BTN(0));
	-- driving the clock
	clock_mininc <= clock_mode and minuteinc;
	clock_mindec <= clock_mode and minutedec;
	clock_hourinc <= clock_mode and hourinc;
	clock_hourdec <= clock_mode and hourdec;
	-- driving the alarm
	alarm_mininc <= alarm_mode and minuteinc;
	alarm_mindec <= alarm_mode and minutedec;
	alarm_hourinc <= alarm_mode and hourinc;
	alarm_hourdec <= alarm_mode and hourdec;
	-- add some blinking to when setting minutes or hours
	blinkhours <= (BTN(3) and freq(2)) or not BTN(3);
	blinkminutes <= (BTN(2) and freq(2)) or not BTN(2);
	-- drive 7seg dimming
	led_dimmer <= (not(SW(7)) and not(SW(6))) or (SW(7) and not(SW(6)) and adc_to_pwm) or (not(SW(7)) and SW(6) and adc_to_pwm);
	adc_channel(0) <= SW(6);
	adc_channel(1) <= SW(6);
	adc_channel(2) <= SW(7);
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
								div(1) => sel(1),  -- 64Hz
								div(0) => sel(0)   -- 128Hz
												);
	-- SECONDS
	sec0: counterwithlimit port map (
								clock => secup,
								clear => resetseconds,
								limit => "1001",
								value => secvalue(3 downto 0),
								up => '1',
								down => '0',
								is_limit => sec0limit
									);					
	sec1: counterwithlimit port map (
								clock => secup,
								clear => resetseconds,
								limit => "0101",
								value => secvalue(7 downto 4),
								up => sec0limit,
								down => '0',
								is_limit => sec1limit
									);					
   -- CLOCK
	clock: hourminbcd port map ( 
			  reset => resetall,
           sync => secup,
			  pulse => minup,
           mininc => clock_mininc,
           mindec => clock_mindec,
           hourinc => clock_hourinc,
           hourdec => clock_hourdec,
			  mode_ampm => ampm_mode,
           bcdout => clock_bcd,
			  ispm => clock_ispm
			  );
   -- ALARM
	alarm: hourminbcd port map ( 
			  reset => resetall,
           sync => secup,
			  pulse => '0',
           mininc => alarm_mininc,
           mindec => alarm_mindec,
           hourinc => alarm_hourinc,
           hourdec => alarm_hourdec,
			  mode_ampm => ampm_mode,
           bcdout => alarm_bcd,
			  ispm => alarm_ispm
			  );
	-- COMPARATOR
	buzzer: comparatorwithstate port map (
				a(23 downto 8) => clock_bcd,
				a(7 downto 0) => secvalue,
				b(23 downto 8) => alarm_bcd,
				b(7 downto 0) => "00000000",
				clock => secup, -- check for alarm every sec, to make sure it is triggered as minute starts 
				reset => resetbuzzer,
				enable => alarm_enable,
				trigger => buzz
				);
	-- indicate alarm (flashing Mercury LEDs and nasty sound)
	muxled: mux16to4 port map (
								a => "0000",   -- alarm disabled, no buzz
								b => "1111",   -- alarm disabled, buzz - this should never happen! 
								c => freq,  -- alarm enabled but not buzzing (counting lights)
								d(3) => secup, -- alarm enabled and buzzing (all flashing)
								d(2) => secup,
								d(1) => secup,
								d(0) => secup,
								y => alarmled,
								s(1) => alarm_enable,
								s(0) => buzz
									);
	-- dim the LEDs just like the 7seg display
	LED(3) <= adc_to_pwm and alarmled(3);
	LED(2) <= adc_to_pwm and alarmled(2);
	LED(1) <= adc_to_pwm and alarmled(1);
	LED(0) <= adc_to_pwm and alarmled(0);
	-- "stereo" alternating buzzing sound
	AUDIO_OUT_L <= alarm_enable and buzz and ((secup and sel(1)) or ((not secup) and sel(0))); 
	AUDIO_OUT_R <= alarm_enable and buzz and ((secup and sel(0)) or ((not secup) and sel(1)));
   -- MULTIPLEXED DISPLAY
	mux: mux32to16 port map (
								a => clock_bcd,
								b => alarm_bcd,
								y => bcd2display,
								s => alarm_mode
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
			  adc_samplingrate => sel(1), -- 64Hz sampling rate	
			  adc_miso => ADC_MISO, -- ADC SPI MISO
			  adc_mosi => ADC_MOSI, -- ADC SPI MOSI
			  adc_cs   => ADC_CSN,  -- ADC SPI CHIP SELECT
			  adc_clk  => ADC_SCK,  -- ADC SPI CLOCK
           adc_channel => adc_channel, -- select light (011) or potentiometer (100)
           pwm_out => adc_to_pwm
			);
				
end structural;

