-- ALU testbench
library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

use work.defines.all;

entity testbench_ALU is
    generic (
        data_size : natural := 8
    );
end testbench_ALU;

architecture testbench of testbench_ALU is
    signal operand_a : signed(data_size-1 downto 0) := to_signed(0 , data_size);
    signal operand_b : signed(data_size-1 downto 0) := to_signed(0 , data_size);
    signal alu_func  : alu_operations := ALU_ADD;

    signal zero        : std_logic;
    signal negative    : std_logic;
    signal carry       : std_logic;
    signal overflow    : std_logic;
    signal output_data : signed(2*data_size-1 downto 0);
begin

    -- connecting testbench signals with half_adder.vhd
    DUT : entity work.alu generic map(data_size => data_size) port map (operand_a => operand_a, operand_b => operand_b, alu_func => alu_func,
    zero => zero, negative => negative, carry => carry , overflow => overflow, output_data => output_data);

    ---operand subroutine
    process is

        variable seed1, seed2 : integer := 100;

        impure function rand_signed ( min_val , max_val : integer ) return integer is
            variable rand : real;
        begin
            uniform(seed1, seed2, rand);
            return integer( round(rand * real(max_val - min_val + 1) + real(min_val) - 0.5) );
        end function;

    begin
        loop
            operand_a <= to_signed( rand_signed( -128 , 127 ) , operand_a'length );
            operand_b <= to_signed( rand_signed( -128 , 127 ) , operand_b'length );

            alu_func <= alu_operations'val( rand_signed( 0 , 11 ) );

            wait for 25 ns;
        end loop;

    end process;

end testbench;
