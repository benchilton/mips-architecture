library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.defines.all;

entity branch_controller is
    generic (
        data_size  : natural := 32;
        opcode_len : natural := 6;
        pc_size    : natural := 10;
        j_addr_len : natural := 26;
        b_addr_len : natural := 16
    );
    port (
        branch         : in std_logic;
        jump           : in std_logic;

        should_branch  : in std_logic;

        jump_from_alu  : in std_logic;

        func           : in std_logic_vector( opcode_len-1 downto 0 );

        alu_output     : in signed( 2*data_size - 1 downto 0 );

        jump_address   : in unsigned( j_addr_len-1 downto 0 );
        branch_address : in unsigned( b_addr_len-1 downto 0 );

        current_count  : in unsigned(pc_size-1 downto 0);

        inc_count      : out unsigned(pc_size-1 downto 0);
        new_count      : out unsigned(pc_size-1 downto 0)
    );
end branch_controller;

architecture branch_controller_desc of branch_controller is

    signal opcode : inst_opcodes;

    signal inced  : unsigned(pc_size-1 downto 0);

begin

    opcode    <= lookup_inst_opcode( to_integer( unsigned(func) ) );
    inced     <= current_count + 4;
    inc_count <= inced;

    process ( jump , should_branch , branch, current_count, branch_address, jump_address , jump_from_alu , alu_output ) is
    begin
        new_count <= current_count + 4;
        if ( branch = '1' ) and ( should_branch = '1' ) then
            new_count <= resize(current_count + branch_address , pc_size );
        elsif ( jump = '1' ) then
            if jump_from_alu = '1' then
                new_count <= resize( unsigned(alu_output) , pc_size );
            else
                new_count <= resize( jump_address , pc_size );
            end if ;
        end if;
    end process;

end branch_controller_desc;
