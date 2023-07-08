--Top level module
library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use work.defines.all;

entity MIPs is
    generic (
        data_size : natural := 32;
        pc_size   : natural := 10
    );
    port (
        clk         : in  std_logic;
        nreset      : in  std_logic
    );
end MIPs;

architecture MIPs_desc of MIPs is

    ---MIPs core parameters

    --Fetch
    constant opcode_len         : natural := 6;
    constant reg_addr_size      : natural := 5;
    constant immediate_len      : natural := 16;
    constant instruction_length : natural := opcode_len + 2*reg_addr_size + immediate_len;

    constant jump_address_len   : natural := instruction_length - opcode_len;

    --Decode
    constant funct_len          : natural := 6;
    constant shamt_len          : natural := immediate_len - reg_addr_size - funct_len;

    ---Connecting nets

    signal new_pc           : unsigned(pc_size - 1 downto 0);
    signal inc_pc           : unsigned(pc_size - 1 downto 0);

    signal jump_address     : unsigned( jump_address_len - 1 downto 0 );

    signal branch_address   : unsigned( immediate_len - 1 downto 0);

    signal opcode           : std_logic_vector( opcode_len-1 downto 0 );
    signal reg_addr_a       : std_logic_vector( reg_addr_size-1 downto 0 );
    signal reg_addr_b       : std_logic_vector( reg_addr_size-1 downto 0 );
    signal w_address        : std_logic_vector( reg_addr_size-1 downto 0 );   
    signal isnt_immediate   : std_logic_vector( immediate_len-1 downto 0 );

    signal pc_out           : unsigned(pc_size - 1 downto 0);
    signal pc_in            : signed(pc_size - 1 downto 0);

    signal write_back_data  : signed( data_size - 1 downto 0);
    signal immediate        : signed( data_size - 1 downto 0);
    signal reg_data_a       : signed( data_size - 1 downto 0);
    signal reg_data_b       : signed( data_size - 1 downto 0);
    signal alu_src_a        : std_logic;
    signal use_immediate    : std_logic;
    signal reg_hi_en        : std_logic;
    signal reg_lo_en        : std_logic;
    signal wb_source        : std_logic_vector(1 downto 0);
    signal reg_w_src        : std_logic;
    signal mem_w_en         : std_logic;
    signal mem_r_en         : std_logic;
    signal branch           : std_logic;
    signal jump             : std_logic;
    signal jump_from_alu    : std_logic;

    signal alu_func         : alu_operations;

    --Execute Stage nets
    signal zero             : std_logic;
    signal negative         : std_logic;
    signal carry            : std_logic;
    signal overflow         : std_logic;
    signal should_branch    : std_logic;
    signal execute_output   : signed( 2*data_size -1 downto 0 );

    --Memory Stage nets

begin

--Internal connections
    pc_in  <= signed(inc_pc);
    
    jump_address <= resize( shift_left( unsigned(reg_data_a & reg_data_b & immediate) , 2 ), jump_address_len );
    branch_address <= resize( shift_left( unsigned(immediate) , 2 ), immediate_len );

--Program counter and program memory
    fetch : entity work.stage_fetch 
    generic map (
        instruction_size => instruction_length,
        pc_size          => pc_size, 
        opcode_len       => opcode_len,
        reg_addr_size    => reg_addr_size,
        immediate_len    => immediate_len
    )
    port map (
        clk        => clk,
        nreset     => nreset,
        pc         => pc_out,
        opcode     => opcode,
        rs         => reg_addr_a,
        rt         => reg_addr_b,
        rd         => w_address,
        immediate  => isnt_immediate,
        next_count => new_pc
    );

    decode : entity work.stage_decode 
    generic map (
        data_size       => data_size,
        opcode_len      => opcode_len,
        funct_len       => funct_len,
        shamt_len       => shamt_len,
        reg_addr_size   => reg_addr_size,
        immediate_len   => immediate_len
    )
    port map (
        clock           => clk,
        opcode          => opcode,
        reg_a_addr      => reg_addr_a,
        reg_b_addr      => reg_addr_b,
        w_addr          => w_address,
        immediate       => isnt_immediate,
        write_back_data => write_back_data,
        ext_immediate   => immediate,
        reg_data_a      => reg_data_a,
        reg_data_b      => reg_data_b,
        alu_src_a       => alu_src_a,
        use_immediate   => use_immediate,
        reg_hi_en       => reg_hi_en,
        reg_lo_en       => reg_lo_en,
        wb_source       => wb_source,
        reg_w_src       => reg_w_src,
        mem_w_en        => mem_w_en,
        mem_r_en        => mem_r_en,
        branch          => branch,
        jump            => jump,
        alu_func        => alu_func,
        should_branch   => should_branch,
        negative        => negative,
        zero            => zero,
        jump_from_alu   => jump_from_alu
    );

    execute : entity work.stage_execute
    generic map (
        data_size   => data_size,
        pc_size     => pc_size
    )
    port map (
        register_a  => reg_data_a,
        pc          => pc_in,
        register_b  => reg_data_b,
        immediate   => immediate,
        alu_func    => alu_func,

        pc_or_reg   => alu_src_a,
        imm_or_reg  => use_immediate,

        zero        => zero,
        negative    => negative,
        carry       => carry,
        overflow    => overflow,
        output_data => execute_output
    );

    memory : entity work.stage_memory
    generic map (
        data_size   => data_size
    )
    port map (
        clk         => clk,
        nreset      => nreset,

        reg_hi_en   => reg_hi_en,
        reg_lo_en   => reg_lo_en,
        mem_w_en    => mem_w_en,
        mem_r_en    => mem_r_en,

        wb_data_sel => wb_source,

        alu_result  => execute_output,
        mem_write_d => reg_data_b,

        wb_data     => write_back_data
    );


    branch_controller : entity work.branch_controller
    generic map (
        data_size   => data_size,
        opcode_len  => opcode_len,
        pc_size     => pc_size,
        j_addr_len  => jump_address_len,
        b_addr_len  => immediate_len
    )
    port map (
        branch         => branch,
        jump           => jump,

        func           => opcode,

        jump_address   => jump_address,
        branch_address => branch_address,
        current_count  => pc_out,

        new_count      => new_pc,
        inc_count      => inc_pc,

        should_branch  => should_branch,

        jump_from_alu  => jump_from_alu,

        alu_output     => execute_output

    );

end MIPs_desc;
