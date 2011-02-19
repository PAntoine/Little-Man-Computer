#include <stdlib.h>
#include <stdio.h>

unsigned char start_str[]  = "library ieee;\nuse ieee.std_logic_1164.all;\nuse ieee.numeric_std.all;\n\nentity rom is"
							 "\n	port (\n			sel			: in 	std_logic;						--- selec"
							 "t\n			address		: in	std_logic_vector(7 downto 0);	--- address to read\n"
							 "			data		: out	std_logic_vector(7 downto 0)	--- data\n		);\nend e"
							 "ntity;\n\narchitecture rtl of rom is\n	type ROM_ARRAY is array (0 to %d) of std_logi"
							 "c_vector(7 downto 0);\n\n	constant	memory	: ROM_ARRAY	:= (\n";

unsigned char end_str[]		= ");\nbegin\n	\n	process (sel,address)\n	begin\n		if (sel = '0')\n		then\n"
							  "			data <= (others => 'Z');\n\n		elsif (sel = '1')\n		then\n			"
							  "data <= memory(to_integer(unsigned(address)));\n		end if;\n	end process;\n\nend "
							  "architecture rtl;\n";

unsigned char line[]	= "\t\t\t\t\t\t\t\t\t\t\"xxxxxxxx\",\n";
unsigned char* string 	= line + 11;

void	to_binary(unsigned char byte, unsigned char* buffer)
{
	buffer[0] = '0' + ((byte & 0x80) >> 7);
	buffer[1] = '0' + ((byte & 0x40) >> 6);
	buffer[2] = '0' + ((byte & 0x20) >> 5);
	buffer[3] = '0' + ((byte & 0x10) >> 4);
	buffer[4] = '0' + ((byte & 0x08) >> 3);
	buffer[5] = '0' + ((byte & 0x04) >> 2);
	buffer[6] = '0' + ((byte & 0x02) >> 1);
	buffer[7] = '0' + ((byte & 0x01));
}

int main(int argc, char* argv[])
{
	int				result = 0;
	char*			input_file = NULL;
	char*			output_file = "rom.vhdl";
	FILE*			in_file;
	FILE*			out_file;
	unsigned char	byte;
	unsigned int	count;
	unsigned int	filesize;
	unsigned int	failed = 0;
	unsigned int	error = 0;
	unsigned int	start = 1;


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
						error = 1;
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

	if (input_file == NULL || error)
	{
		printf(	"%s\n%s\n%s\n",
				"LMC VHDL ROM Builder version 0.1",
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
		fclose(in_file);
		printf("Failed to open input file %s\n",input_file);
		exit(3);
	}
	else
	{
		fseek(in_file,0,SEEK_END);
		filesize = ftell(in_file);
		fseek(in_file,0,SEEK_SET);

		/* print the header of the row file */
		fprintf(out_file,start_str,filesize-1);

		for (count=0; count < filesize; count++)
		{
			byte = fgetc(in_file);
			to_binary(byte,string);

			if (count+1 == filesize)
				line[sizeof(line)-3] = ' ';

			fwrite(line,sizeof(line)-1,1,out_file);
		}

		fwrite(end_str,sizeof(end_str)-1,1,out_file);
		
		fclose(in_file);
		fclose(out_file);
	}

	exit (result);
}
						
/* $Id$ */

