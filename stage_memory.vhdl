library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity stage_memory is
    generic (
        data_size : natural := 32
        ram_size  : natural := 256
    );
    port (

        clk         : in  std_logic;
        nreset      : in  std_logic;

        reg_hi_en   : in  std_logic;
        reg_lo_en   : in  std_logic;
        mem_w_en    : in  std_logic;
        mem_r_en    : in  std_logic;
---Output mux selection
        wb_data_sel : in  std_logic_vector(1 downto 0);

        alu_result  : in  signed(2*data_size-1 downto 0);
        mem_write_d : in  signed(data_size-1 downto 0);

        wb_data     : out signed(data_size-1 downto 0)

    );
end stage_memory;

architecture stage_memory_desc of stage_memory is
    signal alu_trunced : signed(data_size-1 downto 0);
    signal mem_addr    : std_logic_vector(data_size-1 downto 0);

    signal mem_w_d     : std_logic_vector(data_size-1 downto 0);

    signal hi_reg      : signed(data_size-1 downto 0);
    signal lo_reg      : signed(data_size-1 downto 0);

    signal data_mem_d  : std_logic_vector(data_size-1 downto 0);

begin

    MEM : entity work.data_memory 
        generic map (
            word_size    => data_size,
            address_size => data_size,
            ram_size     => ram_size
        )
        port map (
            clk => clk,
            write_enable => mem_w_en,
            read_enable => mem_r_en,
            address => mem_addr,
            write_data => mem_w_d,
            output_data => data_mem_d
        );

    --Extend the PC count considering it unsigned for the extension and then convert to signed for the ALU
    alu_trunced <= resize( alu_result, data_size-1 );
    mem_addr <= std_logic_vector( unsigned(alu_trunced) );
    mem_w_d  <= std_logic_vector( unsigned(mem_write_d) );

    ---Two registers for Hi and Lo.
    process (clk) is
    begin
        if rising_edge(clk) then
            if reg_hi_en = '1' then
                hi_reg <= alu_result(2*data_size - 1 downto data_size);
            end if;

            if reg_lo_en = '1' then
                lo_reg <= alu_result(data_size - 1 downto 0);
            end if;
        end if;
    end process;

    process (wb_data_sel , data_mem_d , alu_trunced , lo_reg , hi_reg) is
    begin
        case wb_data_sel is
            when "00" =>
                wb_data <= alu_trunced;
            when "01" =>
                wb_data <= signed(data_mem_d);
            when "10" =>
                wb_data <= lo_reg;
            when "11" =>
                wb_data <= hi_reg;
            when others =>
                wb_data <= hi_reg;
        end case;
    end process;

end stage_memory_desc;
