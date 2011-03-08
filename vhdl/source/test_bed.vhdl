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
				address		: in	std_logic_vector(5 downto 0);	--- address to read
				data		: out	std_logic_vector(7 downto 0)	--- data
		);
	end component ROM;

	component RAM is
		port (
				sel			: in 	std_logic;						--- select
				rw			: in	std_logic;						--- rw line
				address		: in	std_logic_vector(7 downto 0);	--- address to read
				data		: inout	std_logic_vector(7 downto 0)	--- data
			);
	end component RAM;

	component LMC
		port (	reset		: in	std_logic;									--- resets the processor
				clock		: in	std_logic;									--- the system clock
				enable		: in	std_logic;									--- enables the processor
				wr			: out	std_logic;									--- read/write line
				as			: out	std_logic;									--- address strobe
				io			: out	std_logic;									--- IO port enable
				address		: out	std_logic_vector(ADDR_WIDTH-1 downto 0);	---	address lines
				data		: inout	std_logic_vector(DATA_WIDTH-1 downto 0);	--- data lines
				io_port		: inout	std_logic_vector(DATA_WIDTH-1 downto 0)		--- input/output port
		);
	end component LMC;

	component BRIDGE is
		port (	reset		: in	std_logic;									--- reset the state of the bridge
				clock		: in	std_logic;									--- clock signal
				rw			: in	std_logic;									--- read/write
				io			: in	std_logic;									--- IO CPU lines
				address		: in	std_logic_vector(ADDR_WIDTH-1 downto 0);	--- address
				data		: inout	std_logic_vector(DATA_WIDTH-1 downto 0);	--- data

				--- Device bus
				dev_as		: out	std_logic;									--- device address strobe
				dev_sel		: out	std_logic_vector(NUM_DEVICES-1 downto 0);	--- device select lines
				dev_addr	: out	std_logic_vector(ADDR_WIDTH-1 downto 0);	--- device address lines
				dev_data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0)		--- device data lines
		);
	end component BRIDGE;

	------------------------------------------------------------
	--- wires
	------------------------------------------------------------
	signal clock	: std_logic := '0';
	signal reset	: std_logic := '0';
	signal enable	: std_logic	:= '0';
	signal io_wire	: std_logic;
	signal as_wire	: std_logic;
	signal rw_wire	: std_logic;
	signal addr_bus	: std_logic_vector (ADDR_WIDTH-1 downto 0);
	signal data_bus	: std_logic_vector (DATA_WIDTH-1 downto 0);
	signal io_bus	: std_logic_vector (DATA_WIDTH-1 downto 0) := "00001111";
	signal dev_sel	: std_logic_vector (NUM_DEVICES-1 downto 0);

begin

	--- init
	enable <= '1' after 5 ns;
	reset  <= '1', '0' after 4 ns;

	--- clock
	clock <= not clock after 5 ns;	
	
	--- blocks to be tested
	bd: BRIDGE port map (reset => reset, clock => clock, rw => rw_wire, io => io_wire, address => addr_bus, dev_sel => dev_sel, data => data_bus, dev_data => io_bus);

	rm: RAM port map (sel => dev_sel(RAM_DEVICE), rw => rw_wire, address => addr_bus(7 downto 0), data => data_bus);
	rc: ROM port map (sel => dev_sel(ROM_DEVICE), address => addr_bus(5 downto 0), data => data_bus);

	lc: LMC port map (reset => reset, enable => enable, clock => clock, wr => rw_wire, as => as_wire, io => io_wire, address => addr_bus, data => data_bus, io_port => io_bus);

end architecture rtl;

--- vi:nocin:sw=4 ts=4:fdm=marker
