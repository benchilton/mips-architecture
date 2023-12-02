library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity button_debouncer is
    generic(
        counter_size : natural := 2
    );
    port (
        clk             : in  std_logic;
        slow_clk        : in  std_logic;--Make this clock to have a period of about 50ms
        
        nreset          : in  std_logic;

        dirty_bit       : in  std_logic;
        clean_bit       : out std_logic
    );
end button_debouncer;

architecture button_debouncer_desc of button_debouncer is

    type counter_state_t is (waiting , counting);

    signal state          : counter_state_t := waiting;

    signal input_sr       : std_logic_vector(1 downto 0);
    signal detected_edge  : std_logic;
    signal count          : unsigned( counter_size - 1 downto 0 );

    signal count_done     : std_logic;
    signal counter_enable : std_logic;

begin

    synchroniser : process( clk , nreset ) is
    begin
        if nreset = '0' then
            input_sr <= (others => '0');
        else 
            if( rising_edge(clk) ) then
                input_sr(1) <= input_sr(0);
                input_sr(0) <= dirty_bit;
                if( input_sr(1) = '0' and input_sr(0) = '1' ) then
                    detected_edge <= '1';
                else
                    detected_edge <= '0';
                end if;
            end if;
        end if;
    end process;

    controller : process( clk , nreset ) is
    begin
        if nreset = '0' then
            state <= waiting;
            counter_enable <= '0';
        else
            if( rising_edge( clk ) ) then
                clean_bit <= '0';
                case( state ) is
                
                    when waiting =>

                        counter_enable <= '0';
                        if( detected_edge = '1' and count_done = '0' ) then
                            state <= counting;
                        end if;

                    when counting =>

                        if(count_done = '1') then
                            state <= waiting;
                            clean_bit <= input_sr(1);
                        else
                            counter_enable <= '1';
                        end if;
                        
                    when others =>
                        state <= waiting;
                end case ;

            end if;
        end if;
    end process;


    slow_counter : process( slow_clk , nreset ) is
    begin
        if nreset = '0' then
            count <= (others => '0');
            count_done <= '0';
        else
            if( rising_edge(slow_clk) ) then

                count_done <= '0';

                if( counter_enable = '1' ) then

                    if( count = 2**counter_size - 1 ) then
                        count_done <= '1';
                        count <= ( others => '0' );
                    else
                        count <= count + 1;
                    end if;

                end if;

            end if;
        end if;
    end process;

end button_debouncer_desc;