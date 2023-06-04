library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use work.defines.all;

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

        opcode          : in std_logic_vector( opcode_len - 1 downto 0 );
        reg_a_addr      : in std_logic_vector( reg_addr_size - 1 downto 0 );
        reg_b_addr      : in std_logic_vector( reg_addr_size - 1 downto 0 );
        w_addr          : in std_logic_vector( reg_addr_size - 1 downto 0 );

        immediate       : in std_logic_vector( immediate_len - 1 downto 0 );

        write_back_data : in signed( data_size - 1 downto 0 );

        ext_immediate   : out signed( data_size - 1 downto 0);
        reg_data_a      : out signed( data_size - 1 downto 0);
        reg_data_b      : out signed( data_size - 1 downto 0);

        alu_src_a       : out std_logic;
        alu_src_b       : out std_logic;

        reg_hi_en       : out std_logic;
        reg_lo_en       : out std_logic;

        wb_source       : out std_logic_vector(1 downto 0);

        reg_w_src       : out std_logic;

        mem_w_en        : out std_logic;
        mem_r_en        : out std_logic;

        branch          : out std_logic;
        jump            : out std_logic;

        alu_func        : out alu_operations

    );
end stage_decode;

architecture stage_decode_desc of stage_decode is

    signal ext_imm : signed( data_size - 1 downto 0);

    signal shamt : std_logic_vector( shamt_len-1 downto 0 );
    signal funct : inst_funct;
    signal op    : inst_opcodes;

    signal reg_w_en : std_logic;

begin

    Registers : entity work.registers 
        generic map (
            word_size => data_size,
            address_size => data_size
        )
        port map (
            write_enable    => reg_w_en,
            register_A_addr => reg_a_addr,
            register_B_addr => reg_b_addr,
            write_address   => w_addr,
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
            opcode => op,
            funct => funct,
            alu_src_a => alu_src_a,
            alu_src_b => alu_src_b,
            reg_hi_en => reg_hi_en,
            reg_lo_en => reg_lo_en,
            wb_source => wb_source,
            reg_w_en  => reg_w_en,
            reg_w_src => reg_w_src,
            alu_func  => alu_func
        );

    shamt <= immediate( funct_len-1 downto 0 );
    op    <= inst_opcodes'val( to_integer( unsigned(opcode) ) );
    funct <= inst_funct'val( to_integer( unsigned(immediate( shamt_len+funct_len-1 downto funct_len ))) );
--Sign extension
    ext_imm <= resize( signed(immediate) , ext_imm'length );
    ext_immediate <= ext_imm;


end stage_decode_desc;
