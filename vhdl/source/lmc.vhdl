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
			address	: out	std_logic_vector(ADDR_WIDTH-1 downto 0);	---	address lines
			data	: inout	std_logic_vector(DATA_WIDTH-1 downto 0);	--- int_data lines
			io_port	: inout	std_logic_vector(DATA_WIDTH-1 downto 0)		--- input/output port
		);
end entity LMC;

architecture rtl of LMC is

	------------------------------------------------------------
	--- registers
	------------------------------------------------------------
	signal acc	: std_logic_vector (DATA_WIDTH-1 downto 0);		--- accumulator
	signal pc	: std_logic_vector (ADDR_WIDTH-1 downto 0);		--- program counter

	------------------------------------------------------------
	--- internal buffers
	------------------------------------------------------------
	signal int_clock	: std_logic;
	signal bus_clock	: std_logic;
	signal alu_clock	: std_logic;

	attribute clock_signal : string;
	attribute clock_signal of int_clock : signal is "yes";
	attribute clock_signal of bus_clock : signal is "yes";
	attribute clock_signal of alu_clock : signal is "yes";

	------------------------------------------------------------
	--- internal registers/buffers/wires
	------------------------------------------------------------
	signal execute		: std_logic;
	signal fetch 		: std_logic;
	signal state		: std_logic_vector (1 downto 0);
	signal ireg			: std_logic_vector (DATA_WIDTH-1 downto 0);
	signal oreg			: std_logic_vector (DATA_WIDTH-1 downto 0);
	signal next_addr	: std_logic_vector (ADDR_WIDTH-1 downto 0);

	------------------------------------------------------------
	--- internal control bus
	--- alu switches on the alu
	--- req controls loading the registers
	--- mem controls mmory read writes
	--- bra for branch instructions
	--- ioc  for io calls.
	--- lht for processor halted
	---
	--- details:
	--- alu: 00 = sub, 01 = add
	--- req: 00 = page
	--- mem: 00 = read, 01 = write, 10 = long read, 11 = long_write
	--- bra: 00 = short, 01 = long
	------------------------------------------------------------
	signal control_bus	: std_logic_vector (7 downto 0);

	alias	alu	: std_logic is control_bus(2);
	alias	reg	: std_logic is control_bus(3);
	alias	mem	: std_logic is control_bus(4);
	alias	bra	: std_logic is control_bus(5);
	alias	ioc	: std_logic is control_bus(6);
	alias	hlt	: std_logic is control_bus(7);

	alias	lng : std_logic is control_bus(1);
	alias	dir : std_logic is control_bus(0);

	alias	details		: std_logic_vector(1 downto 0) is control_bus(1 downto 0);

	------------------------------------------------------------
	--- Long Jump Register
	------------------------------------------------------------
	signal page_reg	: std_logic_vector (7 downto 0);
	signal high		: std_logic_vector (7 downto 0);		--- wire for the long jump register

begin

	------------------------------------------------------------
	--- handle the clocking of the processor
	------------------------------------------------------------
	int_clock <= '1' when (enable = '1' and reset = '0' and clock = '1' and hlt = '0') else '0';
	
	process (int_clock,reset)
	begin
		if (reset = '1')
		then
			state	<= SM_RESET;
			execute <= '0';
			fetch 	<= '0';
			
		elsif (int_clock'event and int_clock = '1')
		then
			case state is
				when SM_RESET		=>	fetch		<= '0';
										pc			<= (others => '1');
										execute		<= '0';
										state		<= SM_IFETCH;

				when SM_IFETCH		=>	fetch		<= '1';
										pc			<= next_addr;
										execute		<= '0';
										state		<= SM_OFETCH;

				when SM_OFETCH		=>	fetch 		<= '1';
										pc			<= next_addr;
										execute		<= '0';
										state		<= SM_EXECUTE;
			
				when SM_EXECUTE		=>	fetch		<= '0';
										execute		<= '1';
										state		<= SM_IFETCH;

				when others			=>	null;
			end case;

		end if;
	end process;

	------------------------------------------------------------
	--- bus controller
	------------------------------------------------------------
	bus_clock <= '1' when (int_clock = '1' and (mem = '1' or ioc = '1' or fetch = '1' or alu = '1')) else '0';
	
	wr <= RW_WRITE	when ((ioc = '1' or mem = '1') and dir = DIR_STORE and bus_clock = '0') else RW_READ;
	io <= '1' 		when (ioc = '1') else '0';
	as <= '1'		when (mem = '1' or ioc = '1' or fetch = '1' or alu = '1') else '0';

	data 	<= acc	when ((mem = '1' or ioc = '1') and dir = DIR_STORE and reset = '0') else (others => 'Z');
	io_port <= acc	when (ioc = '1' and dir = DIR_STORE and reset = '0') else (others => 'Z');	

	high 	<= page_reg when lng = '1' else (others => '0');

	address <=	pc				when (fetch = '1') else
				(high & oreg)	when (mem = '1' or ioc = '1' or alu = '1') else
				(others => 'Z');

	process (fetch,bus_clock,reset)
	begin
		if (reset = '1')
		then
			ireg	<= (others => '0');

		elsif (fetch = '1' and bus_clock'event and bus_clock = '1')
		then
			ireg	<= oreg;

		end if;
	end process;

	process (reset, fetch, bus_clock)
	begin
		if (reset = '1')
		then
			oreg <= (others => '0');

		elsif (fetch = '1' and bus_clock'event and bus_clock = '0')
		then
			oreg <= data;

		end if;
	end process;

	------------------------------------------------------------
	--- ALU
	------------------------------------------------------------
	alu_clock <= '1' when (int_clock = '1' and (alu = '1' or (dir = DIR_LOAD and (mem = '1' or ioc = '1')))) else '0';

	process (reset, alu_clock, alu, mem, ioc)
	begin
		if (reset = '1')
		then
			acc <= (others => '0');

		elsif (alu_clock'event and alu_clock = '0')
		then
			if (alu = '1')
			then
				case details is
					when "00" => acc <= acc + data;
					when "01" => acc <= acc - data;
					when "10" => acc <= acc(6 downto 0) & '0';
					when "11" => acc <= '0' & acc (7 downto 1);
					when others => null;
				end case;

			elsif (mem = '1')
			then
				acc <= data;

			elsif (ioc = '1')
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
			if (bra = '1')
			then
				next_addr <= high & oreg;
			else
				next_addr <= pc + 1;		--- no branch
			end if;
		end if;
	end process;

	------------------------------------------------------------
	--- register loading
	--- Load the registers on the falling edge.
	------------------------------------------------------------
	process (reset, reg, int_clock)
	begin
		if (reset = '1')
		then
			page_reg <= (others => '0');

		elsif (int_clock'event and int_clock = '0')
		then
			if (reg = '1')
			then
				-- TODO extend this to other registers
				page_reg <= data;
			end if;
		end if;
	end process;

	------------------------------------------------------------
	--- Instruction Decoder
	------------------------------------------------------------
	process (reset,execute,ireg,acc)
	begin
		if (reset = '1' or execute = '0')
		then
			control_bus <= (others => '0');

		else
			case ireg is
				when OP_ADD	=>	control_bus <= ALU_COMMAND & ALU_ADD;
				when OP_SUB	=>	control_bus <= ALU_COMMAND & ALU_SUB;
				when OP_LDA	=>	control_bus <= MEM_COMMAND & SIZE_SHORT & DIR_LOAD;
				when OP_STA	=>	control_bus	<= MEM_COMMAND & SIZE_SHORT & DIR_STORE;
				when OP_BRA	=>	control_bus <= BRA_COMMAND & SIZE_SHORT & '0';
				when OP_BRZ	=>	if (acc = ZEROS) then control_bus <= BRA_COMMAND & SIZE_SHORT & '0'; else control_bus <= (others => '0'); end if;
				when OP_BRP	=>	if (acc(7) /= '1') then control_bus <= BRA_COMMAND & SIZE_SHORT & '0'; else control_bus <= (others => '0'); end if;		--- HACK: need to add a status register and handle this properly.
				when OP_INP	=>	control_bus	<= IOC_COMMAND & SIZE_SHORT & DIR_LOAD;
				when OP_OUT	=>	control_bus	<= IOC_COMMAND & SIZE_SHORT & DIR_STORE;
				when OP_LLG =>	control_bus <= REG_COMMAND & SIZE_SHORT & DIR_LOAD;
				when OP_PLD	=>	control_bus <= MEM_COMMAND & SIZE_LONG & DIR_LOAD;
				when OP_PST	=>	control_bus	<= MEM_COMMAND & SIZE_LONG & DIR_STORE;
				when OP_INT	=> 	control_bus <= (others => '0');			--- TEMP NOOP
				when OP_IRT	=>	control_bus <= (others => '0');			--- TEMP NOOP
				when OP_HLT	=>	control_bus <= HLT_COMMAND & "00";
				when others	=>	control_bus <= (others => '0');
			end case;
		end if;
	end process;


end architecture rtl;

--- vi:nocin:sw=4 ts=4:fdm=marker
