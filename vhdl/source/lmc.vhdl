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
use work.definitions.all;

entity LMC is
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
end entity LMC;

architecture rtl of LMC is

	------------------------------------------------------------
	--- registers
	------------------------------------------------------------
	signal acc	: std_logic_vector (DATA_WIDTH-1 downto 0);		--- accumlator
	signal pc	: std_logic_vector (ADDR_WIDTH-1 downto 0);		--- program counter

	------------------------------------------------------------
	--- internal buffers
	------------------------------------------------------------
	signal int_wr		: std_logic;
	signal int_as		: std_logic;
	signal int_clock	: std_logic;
	signal int_addr		: std_logic_vector (ADDR_WIDTH-1 downto 0);
	
	------------------------------------------------------------
	--- internal registers/buffers/wires
	------------------------------------------------------------
	signal load			: std_logic;
	signal store		: std_logic;
	signal fault		: std_logic;
	signal fetch		: std_logic;
	signal execute		: std_logic;
	signal state		: std_logic_vector (1 downto 0);
	signal next_state	: std_logic_vector (1 downto 0);
	signal ireg			: std_logic_vector (DATA_WIDTH-1 downto 0);
	signal oreg			: std_logic_vector (DATA_WIDTH-1 downto 0);
	signal next_addr	: std_logic_vector (ADDR_WIDTH-1 downto 0);
	signal const_1		: std_logic := '1';
	signal const_0		: std_logic := '0';

begin
	------------------------------------------------------------
	--- handle the reset
	------------------------------------------------------------
	acc <= (others => '0') when reset = '1' else (others => 'Z');
	pc  <= (others => '0') when reset = '1' else (others => 'Z');

	------------------------------------------------------------
	--- pull down code.
	------------------------------------------------------------
	wr	<= RW_READ when int_wr = 'Z' else 'Z';
	as	<= '1' when int_as = '1' else '0';
	address <= int_addr when int_as = '1' else (others => '0');

	------------------------------------------------------------
	--- handle the clocking of the processor
	------------------------------------------------------------
	int_clock <= '1' when (enable = '1' and reset = '0' and clock = '1') else '0';

	process (int_clock,pc)
	begin
		if (reset = '1')
		then
			state	<= SM_IFETCH;
			pc		<= (others => '0');

		elsif (fault = '0' and int_clock'event and int_clock = '1')
		then
			case state is
				when SM_IFETCH		=>	fetch		<= '1';
										execute		<= '0';
										next_state	<= SM_OFETCH;

				when SM_OFETCH		=>	fetch		<= '1';
										execute		<= '0';
										next_state	<= SM_EXECUTE;
			
				when SM_EXECUTE		=>	fetch		<= '0';
										execute		<= '1';
										next_state	<= SM_IFETCH;

				when others			=>	fetch		<= '0';   
                                        execute		<= '1';
			        					next_state	<= SM_IFETCH;
			end case;

			state <= next_state;
		end if;
	end process;

	------------------------------------------------------------
	--- Execute the instruction
	------------------------------------------------------------
	next_addr <= increment(pc);

	process (execute, pc)
	begin
		if (execute = '1')
		then
			case oreg is
				when OP_HLT	=>	fault	<= '1';		--- cheat
				when OP_ADD	=>	acc 	<= Add_Sub(acc,ireg,const_1);
								pc		<= next_addr;				
	
				when OP_SUB	=>	acc 	<= Add_Sub(acc,ireg,const_0); 
								pc		<= next_addr;
				
				when OP_STA	=>	store	<= '1';
								pc		<= next_addr;
				
				when OP_LDA	=>	load 	<= '1';
								pc		<= next_addr;
				
				when OP_BRA	=>	pc 		<= oreg;
				
				when OP_BRZ	=>	if (acc = ZEROS)
								then
									pc <= oreg;
								else
									pc <= next_addr;
								end if;
				
				when OP_BRP	=>	if (acc(DATA_WIDTH-1) = '0')
								then
									pc <= oreg;
								else
									pc <= next_addr;
								end if;
				
				when OP_INP	=>	acc 	<= input; 
								ips 	<= '1';
								pc		<= next_addr;
				
				when OP_OUT	=>	output 	<= acc; 
								ops 	<= '1';
								pc		<= next_addr;
-- nop for now	when OP_INT	=> 	
-- nop for now	when OP_IRT	=> 
				when others	=> fault <= '1';
			end case;
		else
			ips <= '0';
			ops <= '0';
			load  <= '0';
			store <= '0';

		end if;
	end process;

	------------------------------------------------------------
	--- fetch logic
	--- This will rotate the old oreg into the ireg.
	--- This will save some code and allow for easy clocking.
	------------------------------------------------------------
	process (fetch, int_clock)
	begin
		if (fetch = '0')
		then
			--- float all the lines 
			wr		<= 'Z';
			int_as	<= 'Z';
			int_addr <= (others => 'Z');
			data <= (others => 'Z');

		elsif (fetch'event and fetch = '1')
		then
			ireg	<= oreg;
			int_as	<= '1';
			wr 		<= RW_READ;
			int_addr <= pc;

		elsif (int_clock'event and int_clock = '0')
		then
			--- latch the data
			int_as <= '0';
			wr <= RW_READ;
			oreg <= data;

		end if;
	end process;

	------------------------------------------------------------
	--- Load logic
	------------------------------------------------------------
	process (load, int_clock)
	begin
		if (load = '0')
		then
			--- float all the lines 
			wr <= 'Z';
			int_as <= 'Z';
			int_addr <= (others => 'Z');
			data <= (others => 'Z');

		elsif (load'event and load = '1')
		then
			int_as <= '1';
			wr <= RW_READ;
			int_addr <= oreg;

		elsif (int_clock'event and int_clock = '0')
		then
			--- latch the data
			int_as <= '0';
			wr <= RW_READ;
			acc <= data;

		end if;
	end process;

	------------------------------------------------------------
	--- Store logic
	------------------------------------------------------------
	process (store, int_clock)
	begin
		if (store = '0')
		then
			--- float all the lines 
			wr <= 'Z';
			int_as <= 'Z';
			int_addr <= (others => 'Z');
			data <= (others => 'Z');

		elsif (store'event and store = '1')
		then
			int_as	<= '1';
			wr	<= RW_READ;		--- while the int_address is being set up make sure we don't write
			int_addr <= oreg;
			data <= acc;

		elsif (int_clock'event and int_clock = '0')
		then
			int_as	<= '1';
			wr  <= RW_WRITE;	--- set the data latch

		end if;
	end process;

end architecture rtl;

--- vi:nocin:sw=4 ts=4:fdm=marker

