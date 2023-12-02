-- Decoder testbench
library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity testbench_button_debouncer is
    generic (
        half_period          : time := 100 ns;
        slow_clk_half_period : time := 50 us;
        debounce_time        : time := 10 ns;
        counter_size         : natural := 2
    );
end testbench_button_debouncer;

architecture testbench of testbench_button_debouncer is
    
    signal clk        : std_logic := '0'; 
    signal slow_clk   : std_logic := '0';

    signal nreset     : std_logic;

    signal dirty_data : std_logic;
    signal clean_data : std_logic;

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

    dut : entity work.button_debouncer
    generic map(
        counter_size => counter_size
    )
    port map (
        clk       => clk,
        nreset    => nreset,


        slow_clk  => slow_clk,

        dirty_bit => dirty_data,
        clean_bit => clean_data
    );

    clk      <= not clk         after half_period;
    slow_clk <= not slow_clk    after slow_clk_half_period;

    stimulus : process is
    begin
        dirty_data <= rand_logic;
        wait for rand_time( 900 us , 1000 us , 1 us );
        debouncing : for idx in 0 to 1000 loop
            dirty_data <= rand_logic;
            wait for rand_time( 10 ns , 50 ns , 1 ns );
        end loop;
    end process;

    reset_stimulus : process is
        begin
            nreset <= '1';
            wait for 100 ns;
            nreset <= '0';
            wait for 80 ns;
            nreset <= '1';
            wait;
    end process;

end testbench;
