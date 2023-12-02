-- Register testbench
library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

use work.defines.all;

entity testbench_counter is
    generic (
        half_period   : time    := 50 ns;
        counter_size  : natural := 8
    );
end testbench_counter;

architecture testbench of testbench_counter is
    
    signal enable   : std_logic := '0';
    signal clk      : std_logic := '0';
    signal nreset   : std_logic := '0';

    signal count    : std_logic_vector( counter_size - 1 downto 0 );
    signal overflow : std_logic;

    shared variable seed1, seed2 : integer := 100;

    impure function rand_logic return std_logic is
        variable rand    : real;
        variable ret_val : std_logic := '0';
    begin
        uniform(seed1, seed2, rand);
        if( rand > 0.5 ) then
            ret_val := '1';
        else
            ret_val := '0';
        end if;
        return ret_val;
    end function;

    impure function rand_time(min_val, max_val : time; unit : time := ns) return time is
        variable r, r_scaled, min_real, max_real : real;
    begin
        uniform(seed1, seed2, r);
        min_real := real(min_val / unit);
        max_real := real(max_val / unit);
        r_scaled := r * (max_real - min_real) + min_real;
        return real(r_scaled) * unit;
    end function;

begin

    clk <= not clk after half_period;

    -- connecting testbench signals with half_adder.vhd
    DUT : entity work.counter
        generic map( size => counter_size ) 
        port map   ( clk => clk, nreset => nreset, enable => enable,
                     count => count, overflow => overflow);

    ---operand subroutine
    enable_pin : process is
    begin
        wait for rand_time(101 ns , 301 ns , 1 ns); 
        enable <= '1';
        wait for rand_time(301 ns , 401 ns , 1 ns); 
        enable <= '0';
    end process;

    ---operand subroutine
    nreset_stimulus : process is
        begin
            wait for 400 ns;
            nreset <= '0';
            wait for 55 ns;
            nreset <= '1';
            wait;
        end process;

end testbench;
