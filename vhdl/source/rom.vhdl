library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom is
	port (
			sel			: in 	std_logic;						--- select
			address		: in	std_logic_vector(5 downto 0);	--- address to read
			data		: out	std_logic_vector(7 downto 0)	--- data
		);
end entity;

architecture rtl of rom is
	type ROM_ARRAY is array (0 to 50) of std_logic_vector(7 downto 0);

	constant	memory	: ROM_ARRAY	:= (
										"00001000",
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
										"00000001" 
);
begin
	
	data <= memory(to_integer(unsigned(address))) when sel = '1' else (others => 'Z');
	
end architecture rtl;
