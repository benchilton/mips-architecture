library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.numeric_std.all;

use work.defines.all;
use work.defines.all;
use work.defines.lookup_inst_opcode;

entity stage_decode is
    generic (
        data_size       : natural := 32;
        opcode_len      : natural := 6;
        funct_len       : natural := 6;
        shamt_len       : natural := 5;
        reg_addr_size   : natural := 5;
        immediate_len   : natural := 16
    );
    port (

        clock           : in std_logic;

        opcode          : in std_logic_vector( opcode_len - 1 downto 0 );
        reg_a_addr      : in std_logic_vector( reg_addr_size - 1 downto 0 );
        reg_b_addr      : in std_logic_vector( reg_addr_size - 1 downto 0 );
        w_addr          : in std_logic_vector( reg_addr_size - 1 downto 0 );

        negative        : in std_logic;
        zero            : in std_logic;

        immediate       : in std_logic_vector( immediate_len - 1 downto 0 );

        write_back_data : in signed( data_size - 1 downto 0 );

        ext_immediate   : out signed( data_size - 1 downto 0);
        reg_data_a      : out signed( data_size - 1 downto 0);
        reg_data_b      : out signed( data_size - 1 downto 0);

        alu_src_a       : out std_logic;
        use_immediate   : out std_logic;

        reg_hi_en       : out std_logic;
        reg_lo_en       : out std_logic;

        wb_source       : out std_logic_vector(1 downto 0);

        reg_w_src       : out std_logic;

        mem_w_en        : out std_logic;
        mem_r_en        : out std_logic;

        branch          : out std_logic;
        jump            : out std_logic;

        alu_func        : out alu_operations;

        should_branch   : out std_logic;

        jump_from_alu   : out std_logic

    );
end stage_decode;

architecture stage_decode_desc of stage_decode is

    signal ext_imm           : signed( data_size - 1 downto 0);

    signal shamt             : std_logic_vector( shamt_len-1 downto 0 );
    signal funct             : inst_funct;
    signal op                : inst_opcodes;

    signal reg_w_en          : std_logic;

    signal reg_w_source      : std_logic;

    signal reg_write_address : std_logic_vector( reg_addr_size - 1 downto 0 );

    signal reg_w_to_ra       : std_logic;

    signal parse_shamt       : std_logic;

    signal func_bits         : std_logic_vector( funct_len-1 downto 0 );

    signal rd_addr           : std_logic_vector( reg_addr_size - 1 downto 0 );

begin

    func_bits <= immediate( funct_len-1 downto 0 );

    Registers : entity work.registers 
        generic map (
            word_size => data_size,
            address_size => reg_addr_size
        )
        port map (
            clock           => clock,
            write_enable    => reg_w_en,
            register_A_addr => reg_a_addr,
            register_B_addr => rd_addr,
            write_address   => reg_write_address,
            write_data      => write_back_data,
            register_A_data => reg_data_a,
            register_B_data => reg_data_b
        );
    Decoder : entity work.decoder 
        generic map (
            opcode_size => opcode_len,
            funct_size => funct_len
        )
        port map (
            opcode          => op,
            funct           => funct,
            alu_src_a       => alu_src_a,
            alu_src_b       => use_immediate,
            reg_hi_en       => reg_hi_en,
            reg_lo_en       => reg_lo_en,
            wb_source       => wb_source,
            reg_w_en        => reg_w_en,
            reg_w_src       => reg_w_source,
            alu_func        => alu_func,
            jump            => jump,
            branch          => branch,
            mem_w_en        => mem_w_en,
            mem_r_en        => mem_r_en,
            should_branch   => should_branch,
            negative        => negative,
            zero            => zero,
            reg_w_to_ra     => reg_w_to_ra,
            jump_from_alu   => jump_from_alu,
            parse_shamt     => parse_shamt
        );

    reg_w_src <= reg_w_source;

    process (w_addr , reg_w_source , reg_b_addr, reg_w_to_ra ) is
        variable sel : std_logic_vector(1 downto 0);
    begin
        sel := reg_w_to_ra & reg_w_source;
        case( sel ) is
            when "00"   =>
                reg_write_address <= w_addr;
            when "01"   =>
                reg_write_address <= reg_b_addr;
            when others =>
                reg_write_address <= std_logic_vector( to_unsigned( 31 , reg_write_address'length) );
        end case;
    end process;

    process ( reg_b_addr, reg_w_to_ra ) is
        begin
            if reg_w_to_ra = '1' then
                rd_addr <= std_logic_vector( to_unsigned( 0 , rd_addr'length) );
            else
                rd_addr <= reg_b_addr;
        end if;
    
    end process;

    process ( parse_shamt, ext_imm , shamt) is
        begin
            if parse_shamt = '1' then
                ext_immediate <= signed( resize( unsigned(shamt) , ext_immediate'length ) );
            else
                ext_immediate <= ext_imm;
        end if;
    
    end process;


    shamt <= immediate( shamt_len+funct_len-1 downto funct_len );
    op    <= lookup_inst_opcode( to_integer( unsigned(opcode) ) );
    funct <= lookup_inst_funct( to_integer( unsigned( func_bits )) );
--Sign extension
    ext_imm <= resize( signed(immediate) , ext_imm'length );

end stage_decode_desc;
