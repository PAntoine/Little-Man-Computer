/*-------------------------------------------------------------------------------------*
 *
 * name:  lmc_as.c
 * proj:  Miniweb browser version 3
 *
 * desc:  This is the simple LMC compiler.
 *
 * auth:  Peter Antoine  
 * date:  16/02/11
 *
 *               Copyright (c) 2009 Miniweb Interactive.
 *                       All rights Reserved.
 *-------------------------------------------------------------------------------------*/

#include <stdio.h>
#include <memory.h>
#include <malloc.h>
#include <stdlib.h>

#include "lmc_as.h"

char*	op_code_strings[] =
{
				"HLT",
				"ADD",
				"SUB",
				"STA",
				"LDA",
				"BRA",
				"BRZ",
				"BRP",
				"INP",
				"OUT",
				"INT",
				"IRT",
				"DAT"
};

unsigned int op_code_size[] = {3,3,3,3,3,3,3,3,3,3,3,3,3,3};

LABEL	label[MAX_LABELS];
unsigned int num_labels = 1;

/*---  FUNCTION  ----------------------------------------------------------------------*
 *         Name:  generate_binary
 *  Description:  This file generates the binary file.
 *-------------------------------------------------------------------------------------*/
unsigned int generate_binary (FILE* out_file, INSTRUCTION* program)  
{
	unsigned int	result = 1;
	unsigned char	instruction[2];
	INSTRUCTION*	current_instruction = program;

	while (current_instruction != NULL && result == 1)
	{
		if (current_instruction->opcode == LMCOC_DAT)
		{
			/* write the data byte the output */
			instruction[0] = label[current_instruction->operand].address & 0xff;
			fwrite(instruction,1,1,out_file);
		}
		else
		{
			/* check for labels */
			if(current_instruction->operand != 0 && label[current_instruction->operand].defined == 0)
			{
				printf("ERROR: undefined operand found - %d %s\n",current_instruction->operand,op_code_strings[current_instruction->opcode]);
				result = 0;
			}

			instruction[0] = current_instruction->opcode;

			if (current_instruction->operand != 0)
			{
				instruction[1] = (label[current_instruction->operand].address & 0xff);
			}
			else
			{
				instruction[1] = 0;
			}

			fwrite(instruction,2,1,out_file);
		}

		current_instruction = current_instruction->next;
	}
	
	return result;
}

/*---  FUNCTION  ----------------------------------------------------------------------*
 *         Name:  semantic_check
 *  Description:  This function will check the assembler is semantically correct.
 *-------------------------------------------------------------------------------------*/
unsigned int	semantic_check(INSTRUCTION* program)
{
	unsigned int	result = 1;
	unsigned int	address = 0;
	INSTRUCTION*	current_instruction = program;

	while (current_instruction != NULL)
	{
		/* check for labels */
		if(current_instruction->label != 0)
		{
			if (label[current_instruction->label].defined)
			{
				printf("ERROR: redefinition of a label\n");
				result = 0;
			}
			else
			{
				label[current_instruction->label].defined = 1;
				label[current_instruction->label].address = address;
			}
		}

		switch(current_instruction->opcode)
		{
			case LMCOC_OUT:
			case LMCOC_INP:
			case LMCOC_INT:
			case LMCOC_HALT:
				if (current_instruction->operand != 0)
				{
					printf("ERROR: unexpected operand\n");
					result = 0;
				}
				
				address += 2;
				break;
					
			case LMCOC_IRT:
			case LMCOC_BRA:
			case LMCOC_BRZ:
			case LMCOC_BRP:
			case LMCOC_STA:
			case LMCOC_LDA:
			case LMCOC_SUB:
			case LMCOC_ADD:
				if (current_instruction->operand == 0)
				{
					printf("ERROR: instruction expecting an operand\n");
					result = 0;
				}
				
				address += 2;
				break;

			case LMCOC_DAT:
				if (current_instruction->label == 0 || current_instruction->operand == 0)
				{
					printf("ERROR: DAT must have operand and a label\n");
					result = 0;
				}
				else
				{
					label[current_instruction->operand].address = atoi(label[current_instruction->operand].name);
				}

				address++;
				break;

			default:
				printf("ERROR: invalid instruction op_code: %02x\n",current_instruction->opcode);
				result = 0;
				break;
		}

		current_instruction = current_instruction->next;
	}

	return result;
}

/*---  FUNCTION  ----------------------------------------------------------------------*
 *         Name:  find_opcode
 *  Description:  This function will find an opcode for the token passed in and 
 *                return it's number.
 *-------------------------------------------------------------------------------------*/
unsigned int find_opcode ( TOKEN* token )
{
	unsigned int count = 0;

	for (count=0;count<LMCOC_MAX_OPCODES;count++)
	{
		if (token->size == op_code_size[count] && memcmp(op_code_strings[count],token->name,token->size) == 0)
		{
			/* ok, found it */
			break;
		}
	}

	return count;
}

/*---  FUNCTION  ----------------------------------------------------------------------*
 *         Name:  find_label
 *  Description:  This function will find a label. It will ADD new labels that it
 *                does not find.
 *-------------------------------------------------------------------------------------*/
unsigned int find_label ( TOKEN* token)
{
	unsigned int result = MAX_LABELS;
	unsigned int search;

	if (token->size > MAX_LABEL_SIZE)
	{
		printf("ERROR: token size too big\n");
	}
	else
	{
		/* found label end */
		for (search = 0; search <= num_labels; search++)
		{
			if (label[search].length == token->size && memcmp(token->name,label[search].name,token->size) == 0)
			{
				/* found the label */
				result = search;
				break;
			}
		}

		if (search == num_labels+1)
		{
			/* did not find the label add it to the end */
			if (num_labels+1 < MAX_LABELS)
			{
				num_labels++;
				memcpy(label[num_labels].name,token->name,token->size);
				label[num_labels].length = token->size;
				result = num_labels;
			}
			else
			{
				printf("ERROR: too many labels specified\n");
			}
		}
	}

	return result;
}

/*---  FUNCTION  ----------------------------------------------------------------------*
 *         Name:  parse_string
 *  Description:  This function will parse an instruction line for instructions.
 *
 *  acceptable formats:
 *   opcode
 *   <label opcode
 *   <label> opcode <operand>
 *
 *
 *-------------------------------------------------------------------------------------*/
INSTRUCTION* parse_string ( char* buffer, unsigned int buffer_length, INSTRUCTION* instruction , unsigned int* failed)
{
	unsigned int	size;
	unsigned int	num_tokens = 0;
	unsigned int	index = 0;
	INSTRUCTION*	result = instruction;
	INSTRUCTION*	temp = calloc(sizeof(INSTRUCTION),1);
	TOKEN			token[4];

	temp->opcode = LMCOC_INVALID_OPCODE;

	while(index < buffer_length && (buffer[index] == ' ' || buffer[index] == '\t'))
		index++;

	token[0].name = &buffer[index];
	size = 0;

	/* lets find the parts of the line */
	while(index < buffer_length && num_tokens < 3)
	{
		if (buffer[index] == ' ' || buffer[index] == '\t')
		{
			token[num_tokens].size = size;

			/* remove white */
			while(index < buffer_length && (buffer[index] == ' ' || buffer[index] == '\t'))
				index++;

			num_tokens++;
			token[num_tokens].name = &buffer[index];
			size = 0;
		}
		else
		{
			size++;
			index++;
		}
	}

	if (size > 0 && index == buffer_length)
	{
		token[num_tokens].size = size-1;
		num_tokens++;
	}

	/* lets check to see if its valid */
	if (num_tokens > 0)
	{
		temp->opcode = find_opcode(&token[0]);

		if (temp->opcode == LMCOC_INVALID_OPCODE)
		{
			/* ok, must be a label to start */
			temp->label = find_label(&token[0]);

			if ((temp->opcode = find_opcode(&token[1])) != LMCOC_INVALID_OPCODE)
			{
				if (num_tokens == 3)
				{
					temp->operand = find_label(&token[2]);
				}
			}
			else
			{
				printf("ERROR: invalid format for instruction\n");
				*failed = 1;
			}
		}
		else
		{
			if (num_tokens >= 2)
				temp->operand = find_label(&token[1]);
		}

		if (*failed == 0)
		{
			/* ok, fine */
			result->next = temp;
			result = temp;
		}
	}

	return result;
}

/*---  FUNCTION  ----------------------------------------------------------------------*
 *         Name:  main
 *  Description:  This is the main function.
 *  
 *        Usage:  lmc_as <input_file> -o output_file
 *
 *-------------------------------------------------------------------------------------*/
int	main(int argc, char* argv[])
{
	int				error = 0;
	int				bytes_read;
	char*			input_file = NULL;
	char*			output_file = "lmc.bin";
	char*			input_string;
	FILE*			in_file;
	FILE*			out_file;
	unsigned int	input_size = 1024;
	unsigned int	failed = 0;
	unsigned int	start = 1;
	INSTRUCTION		first = {0,0,0,NULL};
	INSTRUCTION*	current_instruction;

	current_instruction = &first;

	input_string = malloc(1024);

	if (argc > 0 && argc < 4)
	{
		while (start < argc)
		{
			if (argv[start][0] == '-')
			{
				switch (argv[start][1])
				{
					case 'o':	/* output file name */
						if (argv[start][2] != 0)
						{
							/* we have an attached file name */
							output_file = &argv[start][1];
						}
						else if ( (start + 1) < argc)
						{
							output_file = argv[start+1];
							start++;
						}
					break;

					default:
						error = LMCEC_INVALID_PARAMETER;
						break;
				}
			}
			else
			{
				input_file = argv[start];
			}

			start++;
		}
	}

	if (input_file == NULL || error != LMCEC_OK)
	{
		printf(	"%s\n%s\n%s\n",
				"LMC Assembler version " __LMC_VERSION__,
				"Copyright 2011 (c) Peter Antoine",
				"Error invalid parameter",
				"Usage: <input_file> [-o <outfile>]");
		exit(1);
	}

	if ((in_file = fopen(input_file,"r")) == NULL)
	{
		printf("Failed to open input file %s\n",input_file);
		exit(2);
	}
	else if ((out_file = fopen(output_file,"w")) == NULL)
	{
		printf("Failed to open input file %s\n",input_file);
		exit(3);
	}
	else
	{
		while (!feof(in_file) && current_instruction != NULL)
		{
			bytes_read = getline(&input_string,&input_size,in_file);
			
			if (bytes_read > 0)
			{
				INSTRUCTION* prev = current_instruction;
				current_instruction = parse_string(input_string,bytes_read,current_instruction,&failed);
			}
		}

		if (!failed)
		{
			/* symantic checks will be done during the binary generation */
			if (semantic_check(first.next))
			{
				failed = generate_binary(out_file,first.next);
			}
		}
	}

	close(input_file);
	close(output_file);
	
	if (failed)
		exit(4);
	else
		exit(0);
}

/* $Id$ */

