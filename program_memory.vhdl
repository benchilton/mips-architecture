library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

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
    constant byte          : natural := 8;
    constant prog_mem_size : natural := (instruction_length/byte) * 2**address_size;

    

    type prog_memory_t is array (0 to prog_mem_size-1) of std_logic_vector(byte-1 downto 0);

    function to_string ( a: std_logic_vector) return string is
        variable b : string (1 to a'length) := (others => NUL);
        variable stri : integer := 1; 
        begin
            for i in a'range loop
                b(stri) := std_logic'image(a((i)))(2);
            stri := stri+1;
            end loop;
        return b;
        end function;

    --- Function to initialise memory to a .hex file.
    impure function init_prog_mem(filename : in string) return prog_memory_t is
        file     prog_mem_file : text;
        variable current_line  : line;
        variable inst_bits     : std_logic_vector(instruction_length-1 downto 0);
        variable prog_mem      : prog_memory_t;
        variable index         : integer := 0;
    begin

        file_open( prog_mem_file , filename ,  read_mode);
        while not endfile( prog_mem_file ) loop
            readline( prog_mem_file , current_line);

            for idx in instruction_length downto 0 loop
                -- readed_char := line_content(j);
                -- if readed_char = '1' then
                if not ( idx = 32) then
                    if current_line(1+idx) = '1' then   -- changed
                        inst_bits( instruction_length - 1 - idx) := '1';
                    else
                        inst_bits( instruction_length - 1 - idx ) := '0'; 
                    end if;
                end if;
            end loop;

            ---read(current_line, inst_bits );
            prog_mem( 4*index + 0 ) := ( inst_bits( byte-1 downto 0 ) );
            prog_mem( 4*index + 1 ) := ( inst_bits( 2*byte-1 downto byte ) );
            prog_mem( 4*index + 2 ) := ( inst_bits( 3*byte-1 downto 2*byte ) );
            prog_mem( 4*index + 3 ) := ( inst_bits( 4*byte-1 downto 3*byte ) );
            index := index + 1;
        end loop;
        
        return prog_mem;
    
    end function;

    signal prog_mem : prog_memory_t := init_prog_mem("program.hex");
    signal ins_address : integer range 0 to (prog_mem_size-1);

begin

    ins_address <= to_integer( address );

    instruction <= ( prog_mem(ins_address + 3) & prog_mem(ins_address + 2) & prog_mem(ins_address + 1) & prog_mem(ins_address + 0) );


end program_memory_desc;