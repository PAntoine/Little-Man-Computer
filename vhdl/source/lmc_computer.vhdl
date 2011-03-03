--------------------------------------------------------------------------------
---                                                                 LMC Computer
---                                                    LMC (Little Man Computer)
--------------------------------------------------------------------------------
--- Name:	lmc_computer.vhdl
--- Desc:
---       Little Man Computer
---
---       This is a computer with a LMC chip in the middle.
---
---       This computer has a small rom that holds the boot-loader and OS that
---       is required and a small RAM that is used to run the programs in.
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

entity LMC_SOC is
	port (	reset	: in std_logic;			--- reset the SOC
			enable	: in std_logic;			--- enable the device
			clock	: in std_logic			--- the system clock
	);

end entity LMC_SOC;

architecture rtl of LMC_SOC is

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
				data		: out	std_logic_vector(7 downto 0)	--- data
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
		port (	enable		: in	std_logic;									--- enable the bridge chip
				reset		: in	std_logic;									--- reset the state of the bridge
				rw			: in	std_logic;									--- read/write
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

	signal dev_as		: std_logic;
	signal io_wire		: std_logic;
	signal as_wire		: std_logic;
	signal rw_wire		: std_logic;
	signal ram_sel		: std_logic;
	signal addr_bus		: std_logic_vector (ADDR_WIDTH-1 downto 0);	
	signal data_bus		: std_logic_vector (DATA_WIDTH-1 downto 0);	
	signal dev_addr_bus	: std_logic_vector (ADDR_WIDTH-1 downto 0);
	signal dev_data_bus	: std_logic_vector (DATA_WIDTH-1 downto 0);
	signal dev_sel		: std_logic_vector (NUM_DEVICES-1 downto 0);

begin

	--- blocks to be tested
	romc:	ROM 	port map (sel => as_wire, address => addr_bus(5 downto 0), data => data_bus);
--	brdc:	BRIDGE	port map (reset => reset, enable => io_wire, rw => rw_wire, address => addr_bus, data => data_bus, dev_as => dev_as, dev_sel => dev_sel, dev_addr => dev_addr_bus, dev_data => dev_data_bus);
--	ramc:	RAM 	port map (sel => ram_sel, rw => rw_write, address => addr_bus, data => data_bus);
	lc: 	LMC 	port map (reset => reset, enable => enable, clock => clock, wr => rw_wire, as => as_wire, address => addr_bus, data => data_bus, io => io_wire, io_port => dev_data_bus);

end architecture rtl;

--- vi:nocin:sw=4 ts=4:fdm=marker
