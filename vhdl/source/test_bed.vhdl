--------------------------------------------------------------------------------
---                                                                     TEST BED
---                                                    LMC (Little Man Computer)
--------------------------------------------------------------------------------
--- Name:	test_bed.vhdl
--- Desc:
---       Little Man Computer
---
---       This is the test bed for the LMC computer.
---       It expects a ram/rom with the program in it.
---
--- Errors:
---       None.
---
--- Dependencies:
---       None.
---
--- Current Target: <don't know>
---
--- Author: Peter Antoine 
--- Date  : 17th Feb 2011
--------------------------------------------------------------------------------
---                                             Copyright (c) 2011 Peter Antoine
-----------------------------------------------------------------------------{{{
--- Version  Author  Date        Changes
--- -------  ------  ----------  ----------------------------------------------
--- 0.1      PA      17.02.2011  Initial Revision.
-----------------------------------------------------------------------------}}}

library ieee;
use ieee.std_logic_1164.all;
use work.definitions.all;

entity LMC_TB is
end entity LMC_TB;

architecture rtl of LMC_TB is

	------------------------------------------------------------
	--- components
	------------------------------------------------------------
	component ROM
		port (
				sel			: in 	std_logic;						--- select
				address		: in	std_logic_vector(7 downto 0);	--- address to read
				data		: out	std_logic_vector(7 downto 0)	--- data
		);
	end component ROM;

	component LMC
		port (	reset	: in	std_logic;									--- resets the processor
				clock	: in	std_logic;									--- the system clock
				enable	: in	std_logic;									--- enables the processor
				wr		: out	std_logic;									--- read/write line
				as		: out	std_logic;									--- address strobe
				ips		: out	std_logic;									--- input latched
				ops		: out	std_logic;									--- output latched
				address	: out	std_logic_vector(ADDR_WIDTH-1 downto 0);	---	address lines
				data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0);	--- data lines
				input	: in	std_logic_vector(DATA_WIDTH-1 downto 0);	--- input port
				output	: out	std_logic_vector(DATA_WIDTH-1 downto 0)		--- output port
		);
	end component LMC;

	------------------------------------------------------------
	--- wires
	------------------------------------------------------------

	signal clock	: std_logic := '0';
	signal reset	: std_logic;
	signal enable	: std_logic;
	signal as_wire	: std_logic;
	signal rw_wire	: std_logic;
	signal addr_bus	: std_logic_vector (ADDR_WIDTH-1 downto 0);
	signal data_bus	: std_logic_vector (DATA_WIDTH-1 downto 0);
	signal input	: std_logic_vector (DATA_WIDTH-1 downto 0);

begin

	--- init
	enable <= '1' after 5 ns;
	reset  <= '1', '0' after 4 ns;

	input <= (others => '0');

	--- clock
	clock <= not clock after 5 ns;	
	
	--- blocks to be tested
	rc: ROM port map (sel => as_wire, address => addr_bus, data => data_bus);
	lc: LMC port map (reset => reset, enable => enable, clock => clock, wr => rw_wire, as => as_wire, address => addr_bus, data => data_bus, input => input);

end architecture rtl;

--- vi:nocin:sw=4 ts=4:fdm=marker
