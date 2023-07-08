library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity stage_fetch is
    generic (
        instruction_size    : natural := 32;
        pc_size             : natural := 10;

        opcode_len          : natural := 5;
        reg_addr_size       : natural := 5;
        immediate_len       : natural := 16
    );
    port (
        clk         : in  std_logic;
        nreset      : in  std_logic;

        pc          : out unsigned(pc_size-1 downto 0);
        next_count  : in unsigned(pc_size-1 downto 0);

        opcode      : out std_logic_vector( opcode_len-1 downto 0 );
        rs          : out std_logic_vector( reg_addr_size-1 downto 0 );
        rt          : out std_logic_vector( reg_addr_size-1 downto 0 );
        rd          : out std_logic_vector( reg_addr_size-1 downto 0 );   
        immediate   : out std_logic_vector( immediate_len-1 downto 0 )

    );
end stage_fetch;

architecture stage_fetch_desc of stage_fetch is

    signal instruction  : std_logic_vector(instruction_size-1 downto 0);

    signal address      : unsigned(pc_size-1 downto 0);

    signal i_opcode     : std_logic_vector( opcode_len-1 downto 0 );
    signal i_reg_addr_a : std_logic_vector( reg_addr_size-1 downto 0 );
    signal i_reg_addr_b : std_logic_vector( reg_addr_size-1 downto 0 );
    signal i_w_address  : std_logic_vector( reg_addr_size-1 downto 0 );   
    signal i_immediate  : std_logic_vector( immediate_len-1 downto 0 );

begin

    program_counter : entity work.program_counter 
    generic map (
        pc_size => pc_size
    )
    port map (
        clk         => clk,
        nreset      => nreset,
        new_address => next_count,
        address     => address
    );

    program_memory : entity work.program_memory 
    generic map (
        instruction_length => instruction_size,
        address_size       => pc_size
    )
    port map (
        address     => address,
        instruction => instruction
    );
--Instruction demapping
    i_opcode     <= instruction( 31 downto 26 );
    i_reg_addr_a <= instruction( 25 downto 21 );
    i_reg_addr_b <= instruction( 20 downto 16 );
    i_w_address  <= instruction( 15 downto 11 );
    i_immediate  <= instruction( 15 downto 0  );
    opcode       <= i_opcode;
    rs           <= i_reg_addr_a;
    rt           <= i_reg_addr_b;
    rd           <= i_w_address;
    immediate    <= i_immediate;

    pc           <= address;

end stage_fetch_desc;
