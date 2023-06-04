library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity data_memory is
    generic (
        word_size     : natural := 32;
        address_size  : natural := 32;
        ram_size      : natural := 256;
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
    constant memory_size : natural := ram_size;

    type data_memory_t is array (0 to memory_size-1) of std_logic_vector(word_size-1 downto 0);
    signal memory_bank : data_memory_t;

    signal mem_address : integer range 0 to (memory_size-1);

begin

    process ( clk ) is
    begin
        if rising_edge(clk) then
            if write_enable = '1' then
                memory_bank( mem_address ) <= std_logic_vector( write_data );   
            end if ;
            if read_enable = '1' then
                output_data <=  memory_bank( mem_address );
            end if ;
        end if ;
        
    end process;

    mem_address <= to_integer( unsigned( address ) );


end data_memory_desc;