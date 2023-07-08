-- Decoder testbench
library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity testbench_program_memory is
    generic (
        instruction_length : natural := 32;
        address_size       : natural := 10
    );
end testbench_program_memory;

architecture testbench of testbench_program_memory is

    signal address     : unsigned(address_size-1 downto 0) := to_unsigned( 0 , address_size );
    signal instruction : std_logic_vector(instruction_length-1 downto 0);

begin

    Program_Memory : entity work.program_memory 
        generic map (
            instruction_length => instruction_length,
            address_size       => address_size
        )
        port map (
            address     => address,
            instruction => instruction
        );

    process is

    begin
        wait for 20 ns;
        loop

            address <= address + 4;

            wait for 20 ns;
        end loop;

    end process;

end testbench;
