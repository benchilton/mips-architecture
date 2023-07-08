-- program_counter testbench
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity testbench_MIPs is
    generic (
        half_period : time := 100 ns;
        data_size : natural := 32;
        pc_size   : natural := 8
    );
end testbench_MIPs;

architecture testbench of testbench_MIPs is
    signal clk          : std_logic := '0';
    signal nreset       : std_logic;  -- std_logic inputs
begin
    clk <= not clk after half_period;
    -- connecting testbench signals with half_adder.vhd
    DUT : entity work.MIPs
    generic map(
        pc_size => pc_size
    )
    port map (
        clk => clk,
        nreset => nreset
    );

---nreset subroutine
    nreset <= '1', '0' after 10 ns, '1' after 20 ns;   
    
end testbench;
