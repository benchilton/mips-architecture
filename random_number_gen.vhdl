library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.math_real.all;

package random_number_gen is

	shared variable seed1 : integer := 100;
	shared variable seed2 : integer := 100;

	impure function rand_logic return std_logic;
	impure function rand_integer ( min_val , max_val : integer ) return integer;
	impure function rand_time(min_val, max_val : time; unit : time := ns) return time;

end package random_number_gen;


package body random_number_gen is

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

	impure function rand_integer ( min_val , max_val : integer ) return integer is
        variable rand : real;
    begin
        uniform(seed1, seed2, rand);
        return integer( round(rand * real(max_val - min_val + 1) + real(min_val) - 0.5) );
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

end package body random_number_gen;