/*-------------------------------------------------------------------------------------*
 *
 * name:  lmc_as.h
 *
 * desc:  This file holds the definitions for the Little Man Computer compiler.
 *     
 *        This does slight deviate from the LMC as specified on Wikipedia as it is
 *        HEX (makes it easier for me to code) and the size of the mailboxes are
 *        defined by the users.
 *
 *        The memory organisation is a little weird. The standard Lda and Sta 
 *        commands will only write to the bottom 256 bytes of memory. The same
 *        with the br? commands. This simply a hack to be able to have a boot
 *        loader running from ROM, so the page read/write (PLD and PST) functions
 *        will be able to access a bigger memory space. Also, note that the PC
 *        will handle the larder address space so that the bootload/bootstrap
 *        code can run from ROM.
 *
 *        Also, will need to be able to handle exceptions and interrupts.
 *
 *        The instruction format will be as follows:
 *
 *                                +--------+--------+
 *                                | op code|operand |
 *                                +--------+--------+
 *
 *        The following op codes are supported:
 *
 * 		   0x00		Halt
 *         0x01		Add
 *         0x02		Sub
 *         0x03		Sta (store)
 *         0x04		Lda (load)
 *         0x05		Bra	(branch conditional)
 *         0x06		Brz (branch if zero)
 *         0x07		Brp	(branch if positive)
 *         0x08		INP	(input from input port)
 *         0x09		OUT (outputto output port)
 *		
 *		   Non-standard operand:
 *		   0x0a		INT (interrupt)
 *		   0x0b		IRT (return from interrupt)
 *		   0x0c		LPG	(load page register)
 *		   0x0d		PLO	(page load)
 *		   0x0e		PST	(page store)
 *
 *		   Registers:
 *
 *		   INBOX = external read port
 *		   OUTBOX = external write port
 *		   ACCUMULATOR
 *
 *		   (non-standard register)
 *		   IVECTOR = interrupt vector.
 *		   PAGE_REG = 16 bit access register.
 *
 * auth:  Peter Antoine  
 * date:  16/02/11
 *
 *-------------------------------------------------------------------------------------*
 *                        Copyright (c) 2011 Peter Antoine.
 *                       Released under the Artistic Licence.
 *                             All rights Reserved.
 *-------------------------------------------------------------------------------------*/
#ifndef  __LMC_AS_H__
#define  __LMC_AS_H__

#define __LMC_VERSION__ "0.01"

#define	MAX_LABEL_SIZE	(8)
#define MAX_LABELS		(255)

typedef enum
{
	LMCOC_HALT,
	LMCOC_ADD,
	LMCOC_SUB,
	LMCOC_STA,
	LMCOC_LDA,
	LMCOC_BRA,
	LMCOC_BRZ,
	LMCOC_BRP,
	LMCOC_INP,
	LMCOC_OUT,
	LMCOC_INT,
	LMCOC_IRT,
	LMCOC_LPG,
	LMCOC_PLO,
	LMCOC_PST,
	LMCOC_DAT,
	LMCOC_MAX_OPCODES,
	LMCOC_INVALID_OPCODE = LMCOC_MAX_OPCODES
} LMC_OP_CODES;

typedef struct tag_instruction
{
	unsigned short	label;
	unsigned short	opcode;
	unsigned short	operand;

	struct tag_instruction*	next;
} INSTRUCTION;

typedef struct
{
	unsigned char*	name;
	unsigned int	size;

} TOKEN;

typedef struct
{
	unsigned char	defined;
	unsigned char	name[MAX_LABEL_SIZE];
	unsigned char	length;
	unsigned short	address;
} LABEL;

typedef enum
{
	LMCEC_OK,
	LMCEC_INVALID_PARAMETER

} LMC_ERROR_CODES;

#endif 

/* $Id$ */

