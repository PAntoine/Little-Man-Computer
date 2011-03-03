--------------------------------------------------------------------------------
---                                                                       BRIDGE
---                                                    LMC (Little Man Computer)
--------------------------------------------------------------------------------
--- Name:	bridge.vhdl
--- Desc:
---       Little Man Computer
---		
---		This block is the device controller bridge block.
---		It will handle the IO connection between the LMC processor and the
---		devices on the bus.
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

entity BRIDGE is
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
end entity BRIDGE;

architecture rtl of BRIDGE is

	component ROM_CONTROLLER is
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
	end component ROM_CONTROLLER;


	signal int_dev_sel	:	std_logic_vector(NUM_DEVICES-1 downto 0);

    ----------------------------------------------------
    --- Internal Wiring of the devices
    ----------------------------------------------------
	constant	INT_DEVICE_SEL_ROM :	std_logic_vector(7 downto 0) := "00000001";

	constant	INT_ROM_CONTROLLER :	natural := 0;

begin

	------------------------------------------------------------
	--- Address decode
	------------------------------------------------------------
	process (enable, address)
	begin
		if ( enable = '0')
		then
			int_dev_sel <= (others => '0');

		else
			case address is
				when DEVICE_ROM_ADDRESS =>	int_dev_sel	<= INT_DEVICE_SEL_ROM;
				when others				=>	int_dev_sel	<= (others => '0');
			end case;
		end if;
	end process;

	------------------------------------------------------------
	--- Device Mapping
	--- Each device must float the bus when it's select line
	--- is low.
	------------------------------------------------------------
	romc : ROM_CONTROLLER port map (reset => reset, enable => int_dev_sel(INT_ROM_CONTROLLER), rw => rw, data => data, dev_as => dev_as, dev_sel => dev_sel(ROM_DEVICE), dev_addr => dev_addr, dev_data => dev_data);


end architecture rtl;

--- vi:nocin:sw=4 ts=4:fdm=marker

