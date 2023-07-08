-- program_counter testbench
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity testbench_program_counter is
    generic (
        half_period : time := 100 ns;
        pc_size : natural := 10
    );
end testbench_program_counter;

architecture testbench of testbench_program_counter is
    signal clk          : std_logic := '0';
    signal nreset       : std_logic;  -- std_logic inputs
    signal address      : unsigned(pc_size-1 downto 0);  -- outputs
    signal new_address  : unsigned(pc_size-1 downto 0);  -- outputs
begin
    clk <= not clk after half_period;
    -- connecting testbench signals with half_adder.vhd
    DUT : entity work.program_counter generic map(pc_size => pc_size) port map (clk => clk, nreset => nreset, new_address => new_address, address => address);

---nreset subroutine
    nreset <= '1', '0' after 10 ns, '1' after 20 ns;   
    
    new_address <= address + 4;
    
end testbench;
