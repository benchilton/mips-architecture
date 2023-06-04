library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity program_memory is
    generic (
        instruction_length : natural := 32;
        address_size       : natural := 10
    );
    port (
        address     : in  unsigned(address_size-1 downto 0);

        instruction : out std_logic_vector(instruction_length-1 downto 0)
    );
end program_memory;

architecture program_memory_desc of program_memory is

    ---Up to 2^32 locations
    constant prog_mem_size : natural := 2**address_size;

    type prog_memory_t is array (0 to prog_mem_size-1) of std_logic_vector(instruction_length-1 downto 0);
    signal prog_mem : prog_memory_t;

    signal ins_address : integer range 0 to (prog_mem_size-1);

begin

    ins_address <= to_integer( address );

    instruction <= prog_mem(ins_address);


end program_memory_desc;