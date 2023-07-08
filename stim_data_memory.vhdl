-- Data memory testbench
library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity testbench_data_memory is
    generic (
        word_size     : natural := 32;
        address_size  : natural := 4
    );
end testbench_data_memory;

architecture testbench of testbench_data_memory is
    signal   clk          : std_logic := '0';

    signal   write_enable : std_logic;
    signal   read_enable  : std_logic;

    signal   address      : std_logic_vector(address_size-1 downto 0);
    signal   write_data   : std_logic_vector(word_size-1 downto 0);
    signal   output_data  : std_logic_vector(word_size-1 downto 0);

    constant half_period : time := 10 ns;

begin

    -- connecting testbench signals with half_adder.vhd
    DUT : entity work.data_memory
        generic map(
            word_size => word_size ,
            address_size => address_size
        ) 
        port map(
            clk => clk,
            write_enable => write_enable,
            read_enable => read_enable,
            address     => address,
            write_data  => write_data,
            output_data => output_data
        );
    
    clk <= not clk after half_period;

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
            read_enable  <= rand_logic;

            address    <= std_logic_vector( to_unsigned( rand_signed( 1 , 255) , address'length ) );
            write_data <= std_logic_vector( to_unsigned( rand_signed( 0 , 2**16 ) , write_data'length ) );


            wait for 25 ns;
        end loop;

    end process;

end testbench;
