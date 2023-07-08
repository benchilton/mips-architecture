library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

entity data_memory is
    generic (
        word_size     : natural := 32;
        address_size  : natural := 32;
        ram_size      : natural := 256
    );
    port (
        clk             : in  std_logic;

        write_enable    : in  std_logic;
        read_enable     : in  std_logic;

        address         : in  std_logic_vector(address_size-1 downto 0);

        write_data      : in  std_logic_vector(word_size-1 downto 0);

        output_data     : out std_logic_vector(word_size-1 downto 0)

    );
end data_memory;

architecture data_memory_desc of data_memory is
    ---Up to 2^32 locations

    constant byte        : natural := 8;
    constant memory_size : natural := byte * ram_size;

    type data_memory_t is array (0 to memory_size-1) of std_logic_vector(byte-1 downto 0);

    --- Function to initialise memory to a .hex file.
    impure function init_data_mem(filename : in string) return data_memory_t is
        file     data_mem_file : text;
        variable current_line  : line;
        variable line_as_str   : string( 1 to 21 );

        variable address       : string(1 to 8);
        variable content       : string(1 to 8);

        variable tmp_line      : line;

        variable address_val   : std_logic_vector(address_size-1 downto 0);
        variable content_val   : std_logic_vector(word_size-1 downto 0);

        variable data_mem      : data_memory_t;
        variable index         : integer := 0;
    begin

        file_open( data_mem_file , filename ,  read_mode);
        while not endfile( data_mem_file ) loop
            readline( data_mem_file , current_line);
            read( current_line , line_as_str );

            for idx in 1 to 8 loop
                address(idx) := line_as_str(2 + idx);
                content(idx) := line_as_str(13 + idx);
            end loop;

            write(tmp_line , address);
            hread(tmp_line , address_val);

            write(tmp_line , content);
            hread(tmp_line , content_val);

            data_mem( to_integer(unsigned(address_val)) + 0 ) := std_logic_vector( content_val(31 downto 24) );   
            data_mem( to_integer(unsigned(address_val)) + 1 ) := std_logic_vector( content_val(23 downto 16) );   
            data_mem( to_integer(unsigned(address_val)) + 2 ) := std_logic_vector( content_val(15 downto 8) );   
            data_mem( to_integer(unsigned(address_val)) + 3 ) := std_logic_vector( content_val(7 downto 0) );  

            index := index + 1;
        end loop;
        
        return data_mem;

    end function;

    signal memory_bank : data_memory_t := init_data_mem("data_memory.hex");
    signal mem_address : integer range 0 to (memory_size-1);

    signal ins_address : integer range 0 to (memory_size-1);

begin

    process ( address ) is
        begin

            if address > memory_size then
                ins_address <= 0;
            else
                ins_address <= to_integer( unsigned( address ) );
            end if;

    end process;

    process ( clk ) is
    begin
        ---mem_address <= to_integer( unsigned( address ) );
        if rising_edge(clk) then

            if write_enable = '1' then
                memory_bank( ins_address + 0 ) <= std_logic_vector( write_data(31 downto 24) );   
                memory_bank( ins_address + 1 ) <= std_logic_vector( write_data(23 downto 16) );   
                memory_bank( ins_address + 2 ) <= std_logic_vector( write_data(15 downto 8) );   
                memory_bank( ins_address + 3 ) <= std_logic_vector( write_data(7 downto 0) );   
            end if;

            if read_enable = '1' then

                output_data <=  memory_bank( ins_address + 0 ) & memory_bank( ins_address + 1 ) & memory_bank( ins_address + 2 ) & memory_bank( ins_address + 3 );
            end if;

        end if;
        
    end process;

end data_memory_desc;