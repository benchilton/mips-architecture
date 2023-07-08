library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity program_counter is
    generic (
        pc_size : natural := 10
    );
    port (
        clk         : in std_logic;
        nreset      : in std_logic;
        new_address : in unsigned(pc_size-1 downto 0);

        address     : out unsigned(pc_size-1 downto 0)
    );
end program_counter;

architecture pc_desc of program_counter is
    signal count : unsigned(pc_size-1 downto 0);
begin
--Make the block sensitive to the clk and nreset signals
    process(clk , nreset)
    begin
        if(nreset = '0') then
            count <= to_unsigned(0, count'length);
        else
            if( rising_edge(clk) ) then
                count <= new_address;
            end if;
        end if;
    end process;

    address <= count;

end pc_desc;