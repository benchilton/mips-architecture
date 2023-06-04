-- Register testbench
library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

use work.defines.all;

entity testbench_registers is
    generic (
        word_size     : natural := 32;
        address_size  : natural := 5
    );
end testbench_registers;

architecture testbench of testbench_registers is
    signal write_enable    : std_logic;

    signal register_A_addr : std_logic_vector(address_size-1 downto 0);
    signal register_B_addr : std_logic_vector(address_size-1 downto 0);

    signal write_address   : std_logic_vector(address_size-1 downto 0);

    signal write_data      : signed(word_size-1 downto 0);

    signal register_A_data : signed(word_size-1 downto 0);
    signal register_B_data : signed(word_size-1 downto 0);

begin

    -- connecting testbench signals with half_adder.vhd
    DUT : entity work.registers
        generic map(word_size => word_size , address_size => address_size) 
        port map   (write_enable => write_enable, register_A_addr => register_A_addr, register_B_addr => register_B_addr,
                    write_address => write_address, write_data => write_data,
                    register_A_data => register_A_data , register_B_data => register_B_data);

    ---operand subroutine
    process is

        variable seed1, seed2 : integer := 100;
        variable seed3, seed4 : integer := 100;

        impure function rand_signed ( min_val , max_val : integer ) return integer is
            variable rand : real;
        begin
            uniform(seed1, seed2, rand);
            return integer( round(rand * real(max_val - min_val + 1) + real(min_val) - 0.5) );
        end function;

        impure function rand_logic return std_logic is
            variable rand    : real;
            variable ret_val : std_logic := '0';
        begin
            uniform(seed3, seed4, rand);
            if( rand > 0.5 ) then
                ret_val := '1';
            else
                ret_val := '0';
            end if;
            return ret_val;
        end function;

    begin
        loop
            write_enable <= rand_logic;

            register_A_addr <= std_logic_vector (to_unsigned( rand_signed( 0 , 32) , register_A_addr'length ));
            register_B_addr <= std_logic_vector (to_unsigned( rand_signed( 0 , 32) , register_B_addr'length ));

            write_address   <= std_logic_vector (to_unsigned( rand_signed( 0 , 32) , register_B_addr'length ));

            write_data      <= to_signed(rand_signed( 0 , 256) , write_data'length );

            wait for 25 ns;
        end loop;

    end process;

end testbench;
