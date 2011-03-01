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
end entity LMC_SOC;

architecture rtl of LMC_SOC is

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

	component RAM is
		port (
				sel			: in 	std_logic;						--- select
				rw			: in	std_logic;						--- rw line
				address		: in	std_logic_vector(7 downto 0);	--- address to read
				data		: out	std_logic_vector(7 downto 0)	--- data
			);
	end component RAM;

	component LMC
		port (	reset	: in	std_logic;									--- resets the processor
				clock	: in	std_logic;									--- the system clock
				enable	: in	std_logic;									--- enables the processor
				wr		: out	std_logic;									--- read/write line
				as		: out	std_logic;									--- address strobe
				io		: out	std_logic;									--- IO port enable
				io_wr	: out	std_logic;									--- direction of the io
				address	: out	std_logic_vector(ADDR_WIDTH-1 downto 0);	---	address lines
				data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0);	--- data lines
				io_port	: inout	std_logic_vector(DATA_WIDTH-1 downto 0)		--- input/output port
		);
	end component LMC;

	------------------------------------------------------------
	--- wires
	------------------------------------------------------------

	signal clock		: std_logic := '0';
	signal reset		: std_logic;
	signal enable		: std_logic;
	signal as_wire		: std_logic;
	signal rw_wire		: std_logic;
	signal rom_sel		: std_logic;
	signal io_rw_wire	: std_logic;
	signal addr_bus		: std_logic_vector (ADDR_WIDTH-1 downto 0);
	signal data_bus		: std_logic_vector (DATA_WIDTH-1 downto 0);
	signal io_port_bus	: std_logic_vector (DATA_WIDTH-1 downto 0);

begin

	--- START TO BE REMOVED
	enable <= '1' after 5 ns;
	reset  <= '1', '0' after 4 ns;
	clock <= not clock after 5 ns;	
	--- END TO BE REMOVED	

	--- blocks to be tested
	rom_sel <= '1' when (as_wire = '1' and rw_wire = RW_READ) else '0';

	romc:	ROM port map (sel => as_wire, address => addr_bus, data => data_bus);
	iocont:	IO	port map (wr => io_wr_wire, data => io_port_bus);
	ramc:	RAM port map (sel => as_wire, rw => rw_write, address => addr_bus, data => data_bus);
	lc: 	LMC port map (reset => reset, enable => enable, clock => clock, wr => rw_wire, as => as_wire, address => addr_bus, data => data_bus, io_wr => io_wr_wire, io_port => io_port_bus);

end architecture rtl;

--- vi:nocin:sw=4 ts=4:fdm=marker
