--------------------------------------------------------------------------------
---                                                                         RAM
---                                                    LMC (Little Man Computer)
--------------------------------------------------------------------------------
--- Name:	ram.vhdl
--- Desc:
---       Little Man Computer
---
---		  This is the RAM module for the LMC. In the original design the slots
---		  are called mailslots, but I am going with a more readable RAM name.
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
--- Date  : 25th Feb 2011
--------------------------------------------------------------------------------
---                                             Copyright (c) 2011 Peter Antoine
-----------------------------------------------------------------------------{{{
--- Version  Author  Date        Changes
--- -------  ------  ----------  ----------------------------------------------
--- 0.1      PA      25.02.2011  Initial Revision.
-----------------------------------------------------------------------------}}}

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.definitions.all;

entity RAM is
	port (
			sel			: in 	std_logic;						--- select
			rw			: in	std_logic;						--- rw line
			address		: in	std_logic_vector(7 downto 0);	--- address to read
			data		: inout	std_logic_vector(7 downto 0)	--- data
		);
end entity;

architecture rtl of RAM is
	type RAM_ARRAY is array (0 to 255) of std_logic_vector(7 downto 0);

	signal memory :	RAM_ARRAY := (		"00001000",
										"00000000",
										"00000011",
										"00101110",
										"00000100",
										"00110001",
										"00000011",
										"00101111",
										"00000011",
										"00110000",
										"00000100",
										"00101111",
										"00000010",
										"00101110",
										"00000111",
										"00011100",
										"00000100",
										"00110000",
										"00000001",
										"00110010",
										"00000011",
										"00110000",
										"00000001",
										"00101111",
										"00000011",
										"00101111",
										"00000101",
										"00001010",
										"00000100",
										"00101110",
										"00000010",
										"00101111",
										"00000110",
										"00101000",
										"00000100",
										"00110001",
										"00001001",
										"00000000",
										"00000101",
										"00101100",
										"00000100",
										"00110000",
										"00001001",
										"00000000",
										"00000000",
										"00000000",
										"00000000",
										"00000000",
										"00000000",
										"00000000",
										"00000001",
										others => "00000000");

begin

	data <= memory(to_integer(unsigned(address))) when (sel = '1' and rw = RW_READ) else (others => 'Z');
	memory(to_integer(unsigned(address))) <= data when (sel = '1' and rw = RW_WRITE); 

end architecture rtl;
