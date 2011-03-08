--------------------------------------------------------------------------------
---                                                                       BRIDGE
---                                                    LMC (Little Man Computer)
--------------------------------------------------------------------------------
--- Name:	bridge.vhdl
--- Desc:
---       Little Man Computer
---		
---		This block defines the bridge chip 
---
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
use ieee.std_logic_unsigned.all;
use work.definitions.all;

entity BRIDGE is
		port (	reset		: in	std_logic;									--- reset the state of the bridge
				clock		: in	std_logic;									--- system clock
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
end entity BRIDGE;

architecture rtl of BRIDGE is

	------------------------------------------------------------
	--- wires
	------------------------------------------------------------
	signal int_dev_sel	: std_logic_vector (NUM_DEVICES-1 downto 0);			--- internal device select
	
	signal rom_data 	: std_logic_vector (DATA_WIDTH-1 downto 0);
	signal rom_addr		: std_logic_vector (ADDR_WIDTH-1 downto 0);
	signal next_addr	: std_logic_vector (ADDR_WIDTH-1 downto 0);

	signal rom_addr_clock : std_logic;

begin

	int_dev_sel <=	RAM_SELECT when (io = '0') else
					IOP_SELECT when (io & address) = DEVICE_IOP_ADDRESS else
					ROM_SELECT when (io & address) = DEVICE_ROM_ADDRESS else
					ZEROS;

	------------------------------------------------------------
	--- ROM Controller
	--- When the device is written to use this as the address
	--- to read the contents from. If reading then pass the
	--- rom data to the CPU bus, when increment the ROM addr.
	------------------------------------------------------------
	rom_addr_clock <= '1' when (int_dev_sel(ROM_DEVICE) = '1' and io = '1' and clock = '1') else '0';
	
	process (reset, rom_addr_clock)
	begin
		if (reset = '1')
		then
			next_addr <= (others => '0');
		
		elsif (rom_addr_clock'event and rom_addr_clock = '0')
		then
			if (rw = RW_WRITE)
			then
				next_addr <= data;
			else
				next_addr <= rom_addr + 1;
			end if;
		end if;
	end process;

	--- change the address when the rom is unselected
	process (reset, int_dev_sel(ROM_DEVICE))
	begin
		if (reset = '1')
		then
			rom_addr <= (others => '0');
			rom_data <= (others => '0');

		elsif (int_dev_sel(ROM_DEVICE)'event and int_dev_sel(ROM_DEVICE) = '0')
		then
			rom_data <= dev_data;
			rom_addr <= next_addr;
		end if;
	end process;

	--- mux the rom output to the CPU bus during a read
	data <= rom_data when (int_dev_sel(ROM_DEVICE) = '1' and rw = RW_READ) else (others => 'Z');
	data <= (others => 'Z') when (int_dev_sel(RAM_DEVICE) = '1');

	------------------------------------------------------------
	--- bus control
	------------------------------------------------------------
	process (int_dev_sel)
	begin
		case int_dev_sel is
			when RAM_SELECT	=>	dev_as 		<= '0';
								dev_sel		<= int_dev_sel;
								dev_addr	<= (others => '0');

			when IOP_SELECT	=>	dev_as 		<= '0';
								dev_sel		<= int_dev_sel;
								dev_addr	<= (others => '0');

			when ROM_SELECT	=>	dev_as 		<= '1';
								dev_sel		<= int_dev_sel;
								dev_addr	<= rom_addr;

			when others => 		dev_as		<= '0';
								dev_sel		<= (others => '0');
								dev_addr	<= (others => '0');
		end case;
	end process;

end architecture rtl;

--- vi:nocin:sw=4 ts=4:fdm=marker
