library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top is
    generic (
        data_size : natural := 32;
        io_size   : natural := 64
    );
    port (
        clk       : in  std_logic;

        sw        : in std_logic_vector( 15 downto 0 );
        buttons   : in std_logic_vector( 4 downto 0 );   
        
        leds      : out std_logic_vector( 15 downto 0 );

        svnseg    : out std_logic_vector( 6 downto 0 );
        svnsegsel : out std_logic_vector( 3 downto 0 );

    );
end top;

architecture top_desc of top is

    constant debouncer_count_size : natural := 2;
    constant slow_clk_div         : natural := 25;

    signal nreset         : std_logic;
    signal slow_clk       : std_logic;

    signal load_input     : std_logic := '0';
    signal load_output    : std_logic := '0';

    signal input_reg      : std_logic_vector( iosize - 1 downto 0 );
    signal output_reg     : std_logic_vector( iosize - 1 downto 0 );
    signal mips_out       : std_logic_vector( iosize - 1 downto 0 ); 

    signal slow_clk_count : std_logic_vector(slow_clk_div - 1 downto 0);

begin

    nreset      <= not button(0);
    slow_clk    <= slow_clk_count(slow_clk_div - 1);--Set slow_clk to be the MSB of the counter thus it will have a frequency of clk_freq/(2^slow_clk_div)

    slow_clk_gen : entity work.counter
    generic map(
        size     => slow_clk_div
    );
    port map(
        clk      => clk,
        nreset   => nreset,
        enable   '1',
        count    => slow_clk_count,
        overflow => open
    );

    --Button debouncers

    load_input_debouncer : entity work.button_debouncer
    generic map(
        counter_size => debouncer_count_size
    );
    port map(
        clk      => clk,
        slow_clk => slow_clk,
        
        nreset   => nreset,

        dirty_bit => button(1),
        clean_bit => load_input
    );
    load_output_debouncer : entity work.button_debouncer
    generic map(
        counter_size => debouncer_count_size
    );
    port map(
        clk      => clk,
        slow_clk => slow_clk,
        
        nreset   => nreset,

        dirty_bit => button(2),
        clean_bit => load_output
    );


    io_registers : process ( clk , nreset ) is
    begin
        if( nreset = '0') then
            input_reg  <= ( others => '0');
            output_reg <= ( others => '0');
        elsif( rising_edge(clk) ) then

            if( load_input = '1' ) then
                input_reg <= resize( sw , io_size );
            end if;

            if( load_output = '1' ) then
                output_reg <= mips_out;
            end if;

        end if;

    end process;


    MIPs : entity work.MIPs 
    generic map (
        data_size => data_size,
--      pc_size   => -- not setting as default is 10 (2^10 instructions)
        io_size   => io_size
    )
    port map(
        clk         => clk,
        nreset      => reset_cleaned,

        input_port  => input_reg,
        output_port => mips_out
    );

    leds <= resize( output_reg , 15 );

end top_desc;