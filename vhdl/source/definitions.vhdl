--------------------------------------------------------------------------------
---                                                           definitions package
---                                                    LMC (Little Man Computer)
--------------------------------------------------------------------------------
--- Name:	defintions.vhdl
--- Desc:
---       This file 
---
---
--- Errors:
---       There are several versions of the processor instruction set floating
---       around on the internet, I have goner with one based on the York one
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

library IEEE;
use IEEE.std_logic_1164.all;

package definitions is

	------------------------------------------------------------
	--- Other constants
	------------------------------------------------------------
	constant	RW_READ		: std_logic := '0';
	constant	RW_WRITE	: std_logic := '1';
	
	constant	ADDR_WIDTH	: natural := 8;
	constant	DATA_WIDTH	: natural := 8;

	constant	ZEROS		: std_logic_vector(DATA_WIDTH-1 downto 0)	:= (others => '0');

	------------------------------------------------------------
	--- State Machine
	------------------------------------------------------------
	constant	SM_IFETCH	:	std_logic_vector(1 downto 0)	:= "00";	--- fetch instruction byte 1
	constant	SM_OFETCH	:	std_logic_vector(1 downto 0)	:= "01";	--- fetch instruction byte 1
	constant	SM_EXECUTE	:	std_logic_vector(1 downto 0)	:= "10";	--- execute the instruction

	------------------------------------------------------------
	--- Opcodes
	------------------------------------------------------------
	constant	OP_HLT	:	std_logic_vector(7 downto 0) := "00000000";
	constant	OP_ADD	:	std_logic_vector(7 downto 0) := "00000001";
	constant	OP_SUB	:	std_logic_vector(7 downto 0) := "00000010";
	constant	OP_STA	:	std_logic_vector(7 downto 0) := "00000011";
	constant	OP_LDA	:	std_logic_vector(7 downto 0) := "00000100";
	constant	OP_BRA	:	std_logic_vector(7 downto 0) := "00000101";
	constant	OP_BRZ	:	std_logic_vector(7 downto 0) := "00000110";
	constant	OP_BRP	:	std_logic_vector(7 downto 0) := "00000111";
	constant	OP_INP	:	std_logic_vector(7 downto 0) := "00001000";
	constant	OP_OUT	:	std_logic_vector(7 downto 0) := "00001001";
	constant	OP_INT	:	std_logic_vector(7 downto 0) := "00001010";
	constant	OP_IRT	:	std_logic_vector(7 downto 0) := "00001011";

    ----------------------------------------------------
    --- functions
    ----------------------------------------------------
    function Increment ( din : std_logic_vector) return std_logic_vector;
	function Add_Sub (	signal  ain : std_logic_vector(DATA_WIDTH-1 downto 0);
						signal  bin : std_logic_vector(DATA_WIDTH-1 downto 0);
						signal 	add : std_logic								) return std_logic_vector;


end package definitions;

package body definitions is

	----------------------------------------------------
	--- Increment
	---
	--- This function will increment the counter
	----------------------------------------------------
	function Increment ( din : std_logic_vector) return std_logic_vector is

	variable x		: std_logic := '1';
	variable dout	: std_logic_vector (din'range);

    begin
        x := '1';

        for i in din'range loop

            dout(i) := din(i) xor x;

            x := x and din(i);
        end loop;

		return dout;

    end function;

	----------------------------------------------------
	--- Add_Sub
	---
	--- This function will increment the counter
	----------------------------------------------------
	function Add_Sub (	signal  ain : std_logic_vector(DATA_WIDTH-1 downto 0);
						signal  bin : std_logic_vector(DATA_WIDTH-1 downto 0);
						signal 	add : std_logic								) return std_logic_vector is

	variable c		: std_logic := '0';
	variable b		: std_logic := '0';
	variable dout	: std_logic_vector (ain'range);

    begin

        for i in ain'range loop
			
			--- select bin(i) if adding, and not bin(i) if subtracting 
			b := (bin(i) and add) or (not bin(i) and not add);

            dout(i) := ain(i) xor b xor c;
            c := (ain(i) and b) or (ain(i) and c) or (b and c);
        
		end loop;

		return dout;

    end function;



end definitions;

--- vi:nocin:sw=4 ts=4:fdm=marker

