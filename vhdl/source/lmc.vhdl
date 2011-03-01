--------------------------------------------------------------------------------
---                                                                    Top Level
---                                                    LMC (Little Man Computer)
--------------------------------------------------------------------------------
--- Name:	lmc.vhdl
--- Desc:
---       Little Man Computer
---
---       This is mostly based on the version by York University, Canada.
---
---       The original LMC was created by Dr. Stuart Madrick and is a basic 
---       representation of a von Neumann architecture machine. It purpose was
---       to show the basic workings of a computer without all the logicy stuff
---       getting in the way.
---
---       This version is simply so that I can write both a compiler and a
---       processor. I have at least 5 designs for processors and none of them
---       ever get more than half-way finished (mostly as they are too big and
---       I get board). So this is a perfect processor to implement as it is
---       quite small and the compiler only took me a day to code.
---
--- Errors:
---       There are several versions of the processor instruction set floating
---       around on the internet, I have gone with one based on the York one
---       found above except that I have split the INP and OUT instructions into
---       two different op codes rather that using the same one with the operand
---       making the action. This simple makes the decoder simpler. Also, I have
---       added two instructions (INT and IRT) so that interrupts can be handled.
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

entity LMC is
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
end entity LMC;

architecture rtl of LMC is

	------------------------------------------------------------
	--- registers
	------------------------------------------------------------
	signal acc	: std_logic_vector (DATA_WIDTH-1 downto 0);		--- accumulator
	signal pc	: std_logic_vector (DATA_WIDTH-1 downto 0);		--- program counter

	------------------------------------------------------------
	--- internal buffers
	------------------------------------------------------------
	signal int_clock	: std_logic;
	signal bus_clock	: std_logic;
	signal alu_clock	: std_logic;
	signal io_clock		: std_logic;
		
	------------------------------------------------------------
	--- internal registers/buffers/wires
	------------------------------------------------------------
	signal alu_add		: std_logic;
	signal alu_sub		: std_logic;
	signal load			: std_logic;
	signal store		: std_logic;
	signal fetch		: std_logic;
	signal branch		: std_logic;
	signal io_load		: std_logic;
	signal io_store		: std_logic;

	signal execute		: std_logic;
	signal state		: std_logic_vector (1 downto 0);
	signal next_state	: std_logic_vector (1 downto 0);
	signal ireg			: std_logic_vector (DATA_WIDTH-1 downto 0);
	signal oreg			: std_logic_vector (DATA_WIDTH-1 downto 0);
	signal next_addr	: std_logic_vector (ADDR_WIDTH-1 downto 0);

begin
	------------------------------------------------------------
	--- handle the clocking of the processor
	------------------------------------------------------------
	int_clock <= '1' when (enable = '1' and reset = '0' and clock = '1') else '0';
	
	process (int_clock,reset)
	begin
		if (reset = '1')
		then
			state		<= SM_RESET;
			execute <= '0';
			fetch 	<= '0';
			
		elsif (int_clock'event and int_clock = '1')
		then
			case state is
				when SM_RESET		=>	fetch		<= '0';
										pc			<= (others => '0');
										execute		<= '0';
										state		<= SM_IFETCH;

				when SM_IFETCH		=>	fetch		<= '1';
										execute		<= '0';
										state		<= SM_OFETCH;

				when SM_OFETCH		=>	fetch 		<= '1';
										pc			<= next_addr;
										execute		<= '0';
										state		<= SM_EXECUTE;
			
				when SM_EXECUTE		=>	fetch		<= '0';
										pc			<= next_addr;
										execute		<= '1';
										state		<= SM_IFETCH;

				when others			=>	fetch		<= '0';
                                        execute		<= '0';
			        					state		<= SM_IFETCH;
			end case;

		end if;
	end process;

	------------------------------------------------------------
	--- bus controller
	------------------------------------------------------------
	--- handle rising edge
	bus_clock <= '1' when (int_clock = '1' and (load = '1' or store = '1'  or fetch = '1')) else '0';

	process (load, fetch, store, bus_clock)
	begin
		if (reset = '1')
		then
			ireg <= (others => '0');

		elsif (load = '0' and store = '0' and fetch = '0')
		then
			as 		<= '0';
			address <= (others => 'Z');

		elsif (bus_clock'event and bus_clock = '1')
		then
			if (load = '1')
			then
				as		<= '1';
				address	<= oreg;

			elsif (fetch = '1')
			then
				as		<= '1';
				address	<= pc;
				ireg	<= oreg;

			elsif (store = '1')
			then
				as		<= '1';
				address	<= oreg;
			end if;
		end if;
	end process;

	--- handle falling edge
	process (reset, load, store, fetch, bus_clock)
	begin
		
		if (reset = '1')
		then
			oreg <= (others => '0');

		elsif (load = '0' and store = '0' and fetch = '0')
		then
			wr		<= RW_READ;
			data	<= (others => 'Z');

		elsif (bus_clock'event and bus_clock = '0')
		then
			if (fetch = '1')
			then
				oreg	<= data;
				
			elsif (store = '1')
			then
				wr		<= RW_WRITE;
				data	<= acc;
			end if;
		end if;
	end process;

	------------------------------------------------------------
	--- IO bus driver
	------------------------------------------------------------
	io_clock <= '1' when int_clock = '1' and (io_load = '1' or io_store = '1') else '0';
	
	process (io_load, io_store,io_clock)
	begin
		if (io_load = '0' and io_store = '0')
		then
			io_port <= (others => 'Z');
			
		elsif (io_clock'event and io_clock = '1')
		then
			if (io_store = '1')
			then
				io_port <= acc;
			end if;
		end if;
	end process;

	--- handle setting the io_wr strobe
	process (io_store, io_clock)
	begin
		if (io_store = '0')
		then
			io_wr <= '0';

		elsif (io_clock'event and io_clock = '0')
		then
			io_wr <= '1';
		end if;
	end process;

	------------------------------------------------------------
	--- ALU
	------------------------------------------------------------
	alu_clock <= '1' when (int_clock = '1' and (alu_add = '1' or alu_sub = '1' or load = '1' or io_load = '1')) else '0';

	process (reset, alu_clock, alu_add, alu_sub, load)
	begin
		if (reset = '1')
		then
			acc <= (others => '0');

		elsif (alu_clock'event and alu_clock = '0')
		then
			if (alu_add = '1')
			then
				acc <= acc + oreg;

			elsif (alu_sub = '1')
			then
				acc <= acc - oreg;

			elsif (load = '1')
			then
				acc <= data;
			
			elsif (io_load = '1')
			then
				acc <= io_port;
			end if;
		end if;
	end process;
	
	------------------------------------------------------------
	--- Program Counter Control (next_addr is loaded into PC)
	------------------------------------------------------------
	process (reset, int_clock)
	begin
		if (reset = '1')
		then
			next_addr <= (others => '0');

		elsif (int_clock'event and int_clock = '0')
		then
			if (branch = '1')
			then
				next_addr <= oreg;
			else
				next_addr <= pc + 1;		--- no branch
			end if;
		end if;
	end process;

	------------------------------------------------------------
	--- Instruction Decoder
	------------------------------------------------------------
	process (reset,execute,oreg,ireg,next_addr,acc)
	begin
		if (reset = '1' or execute = '0')
		then
			store		<= '0';
			load 		<= '0';
			alu_add		<= '0';
			alu_sub		<= '0';
			branch 		<= '0';
			io_load 	<= '0';
			io_store	<= '0';

		elsif (execute = '1')
		then
			case ireg is
				when OP_HLT	=>	null;
				when OP_ADD	=>	alu_add		<= '1';
				when OP_SUB	=>	alu_sub		<= '1';
				when OP_STA	=>	store		<= '1';
				when OP_LDA	=>	load		<= '1';
				when OP_BRA	=>	branch		<= '1';
				when OP_BRZ	=>	if (acc = ZEROS) then branch <= '1'; end if;
				when OP_BRP	=>	if (acc /= ZEROS) then branch <= '1'; end if;
				when OP_INP	=>	io_load		<= '1';
				when OP_OUT	=>	io_store	<= '1';
-- nop for now	when OP_INT	=> 	
-- nop for now	when OP_IRT	=> 
				when others	=>	null;
			end case;
		end if;
	end process;

end architecture rtl;

--- vi:nocin:sw=4 ts=4:fdm=marker
