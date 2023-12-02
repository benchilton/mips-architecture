library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity counter is
    generic(
        size     : natural := 8
    );
    port (
        clk      : in  std_logic;
        nreset   : in  std_logic;
        enable   : in  std_logic;

        count    : out std_logic_vector( size - 1 downto 0 );
        overflow : out std_logic
    );
end counter;

architecture rtl of counter is

    signal counter     : unsigned( size - 1 downto 0);
    signal lrg_counter : unsigned( size downto 0 );

begin

    count    <= std_logic_vector( counter );

    counter_rtl : process( clk , nreset ) is
    begin
        if nreset = '0' then
            lrg_counter <= (others => '0');
        else
            if rising_edge(clk) then

                if( enable = '1') then
                    overflow <= lrg_counter(size);
                    lrg_counter <= resize( counter + 1 , lrg_counter'length);
                    counter  <= lrg_counter( counter'range );
                end if;

            end if;
        end if;
    end process;

end rtl;