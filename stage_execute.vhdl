library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use work.defines.all;

entity stage_execute is
    generic (
        data_size : natural := 32;
        pc_size : natural := 10
    );
    port (
        register_a  : in  signed(data_size-1 downto 0);
        pc          : in  signed(pc_size-1 downto 0);
        register_b  : in  signed(data_size-1 downto 0);
        immediate   : in  signed(data_size-1 downto 0);
        alu_func    : in  alu_operations;

        pc_or_reg   : in std_logic;
        imm_or_reg  : in std_logic;

        zero        : out std_logic;
        negative    : out std_logic;
        carry       : out std_logic;
        overflow    : out std_logic;
        output_data : out signed(2*data_size-1 downto 0)
    );
end stage_execute;

architecture stage_execute_desc of stage_execute is
    signal pc_count  : signed(data_size-1 downto 0);
    signal operand_a : signed(data_size-1 downto 0);
    signal operand_b : signed(data_size-1 downto 0);
begin

    ALU : entity work.alu 
        generic map(data_size => data_size)
        port map   (operand_a => operand_a, operand_b => operand_b, alu_func => alu_func,
                    zero => zero, negative => negative, carry => carry , overflow => overflow, output_data => output_data);

    --Extend the PC count considering it unsigned for the extension and then convert to signed for the ALU
    pc_count <= signed(resize( unsigned(pc) , pc_count'length ));

    ---Infers multiplexers for the ALU inputs
    operand_a <= pc_count  when (pc_or_reg = '1' ) else register_a;
    operand_b <= immediate when (imm_or_reg = '1') else register_b;

end stage_execute_desc;