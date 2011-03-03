--------------------------------------------------------------------------------
---                                                               ROM CONTROLLER
---                                                    LMC (Little Man Computer)
--------------------------------------------------------------------------------
--- Name:	rom_controller.vhdl
--- Desc:
---       Little Man Computer
---
---		This block handles interfacing the ROM to the data bus via the bridge
---		block.
---
---		When this block is written to it latches the data as the address that
---		is going to be used to read the rom. It will latch the data from the
---		rom on the falling edge of the clock.
---	
---		When in read mode this block asserts the rom data in the latch, while
---		latching the data from the rom. It will increment the rom address and
---		store it when the enable line goes low.
---
--- Errors:
---		<none>
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
use ieee.std_logic_unsigned.all;
use work.definitions.all;

entity ROM_CONTROLLER is
	port (	enable		: in	std_logic;									--- enable the rom controller
			reset		: in	std_logic;									--- reset the rom controller
			rw			: in	std_logic;									--- read/write
			data		: inout	std_logic_vector(DATA_WIDTH-1 downto 0);	--- data

			--- Device bus
			dev_as		: out	std_logic;									--- device address strobe
			dev_sel		: out	std_logic;									--- device select line
			dev_addr	: out	std_logic_vector(ADDR_WIDTH-1 downto 0);	--- device address lines
			dev_data	: in	std_logic_vector(DATA_WIDTH-1 downto 0)		--- device data lines
	);
end entity ROM_CONTROLLER;

architecture rtl of ROM_CONTROLLER is

	signal next_addr		: std_logic_vector (ADDR_WIDTH-1 downto 0);
	signal addr_register	: std_logic_vector (ADDR_WIDTH-1 downto 0);
	signal data_register	: std_logic_vector (DATA_WIDTH-1 downto 0);

begin
	
	------------------------------------------------------------
	--- Address register handling
	------------------------------------------------------------
	process (enable,reset,rw)
	begin
		if (reset = '1')
		then
			addr_register	<= (others => '0');

		elsif (enable'event and enable = '1')
		then
			if (rw = RW_WRITE)
			then
				addr_register <= data;
			
			elsif (rw = RW_READ)
			then
				addr_register <= next_addr;
			end if;
		end if;
	end process;

	process (enable, addr_register,reset)
	begin
		if (reset = '1')
		then
			next_addr <= (others => '0');

		elsif (enable'event and enable = '0')
		then
			next_addr <= addr_register + 1;
		end if;
	end process;

	------------------------------------------------------------
	--- Data register handling
	------------------------------------------------------------
	process (enable,reset,rw,dev_data)
	begin
		if (reset = '1')
		then
			data_register <= (others => '0');

		elsif (enable = '1' and reset = '0')
		then
			if (rw = RW_READ)
			then
				data_register <= dev_data;
			
			end if;
		end if;
	end process;

	------------------------------------------------------------
	--- Mux the output
	------------------------------------------------------------
	dev_as 		<= '1' when (enable = '1' and reset = '0') else 'Z';
	dev_sel		<= '1' when (enable = '1' and reset = '0') else 'Z';
	dev_addr	<= addr_register when (enable = '1' and reset = '0') else (others => 'Z');
	data		<= data_register when (enable = '1' and reset = '0' and rw = RW_READ) else (others => 'Z');

end architecture rtl;

--- vi:nocin:sw=4 ts=4:fdm=marker

