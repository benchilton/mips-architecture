library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity registers is
    generic (
        word_size     : natural := 32;
        address_size  : natural := 5
    );
    port (

        clock           : in std_logic;

        write_enable    : in  std_logic;

        register_A_addr : in  std_logic_vector(address_size-1 downto 0);
        register_B_addr : in  std_logic_vector(address_size-1 downto 0);

        write_address   : in  std_logic_vector(address_size-1 downto 0);

        write_data      : in  signed(word_size-1 downto 0);

        register_A_data : out signed(word_size-1 downto 0);
        register_B_data : out signed(word_size-1 downto 0)

    );
end registers;

architecture registers_desc of registers is
    constant register_size : natural := 2**address_size;

    type memory is array (0 to register_size-1) of std_logic_vector(word_size-1 downto 0);

    signal addr_a, addr_b , w_addr: integer range 0 to (register_size-1);

    signal memory_bank : memory;

begin

    addr_a <= to_integer( unsigned( register_A_addr ) );
    addr_b <= to_integer( unsigned( register_B_addr ) );
    w_addr <= to_integer( unsigned( write_address ) );

    process ( clock ) is
    begin
        if rising_edge(clock) then
            if write_enable = '1' then
                memory_bank( w_addr ) <= std_logic_vector( write_data );       
            end if;
        end if;
    end process;

    process (addr_a , addr_b) is
    begin
        if addr_a = to_unsigned( 0 , address_size ) then
            register_A_data <= to_signed( 0 , word_size );
        else
            register_A_data <= signed( memory_bank( addr_a ) );
        end if ;
    
        if addr_b = to_unsigned( 0 , address_size ) then
            register_B_data <= to_signed( 0 , word_size );
        else
            register_B_data <= signed( memory_bank( addr_b ) );
        end if ;
    end process;

end registers_desc;