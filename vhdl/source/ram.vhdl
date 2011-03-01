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

	signal memory :	RAM_ARRAY;
begin
	
	process (sel,rw,address)
	begin
		if (sel = '0')
		then
			data <= (others => 'Z');

		elsif (rw = RW_READ)
		then
			data <= memory(to_integer(unsigned(address)));
		
		elsif (rw = RW_WRITE)
		then
			memory(to_integer(unsigned(address))) <= data;
		end if;
	end process;

end architecture rtl;
