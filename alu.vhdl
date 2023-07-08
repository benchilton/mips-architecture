library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use work.defines.all;

entity alu is
    generic (
        data_size : natural := 32
    );
    port (
        operand_a   : in  signed(data_size-1 downto 0);
        operand_b   : in  signed(data_size-1 downto 0);
        alu_func    : in  alu_operations;


        zero        : out std_logic;
        negative    : out std_logic;
        carry       : out std_logic;
        overflow    : out std_logic;
        output_data : out signed(2*data_size-1 downto 0)
    );
end alu;

architecture alu_desc of alu is
    signal result    : signed(2*data_size-1 downto 0);
    signal less_than : signed(2*data_size-1 downto 0);
    signal z : std_logic;
    signal n : std_logic;
    signal c : std_logic;

begin
    process( operand_a, operand_b, alu_func )
    begin

        case alu_func is
            when ALU_ADD =>
                result <= resize( operand_a + operand_b , output_data'length );
            when ALU_ADDU =>
                result <= signed(resize( unsigned(operand_a + operand_b) , output_data'length ));
            when ALU_SUB =>
                result <= resize( signed(operand_a - operand_b) , output_data'length );
            when ALU_SUBU =>
                result <= signed(resize( unsigned(operand_a - operand_b) , output_data'length ));
            when ALU_MUL =>
                result <= operand_a * operand_b;
            when ALU_DIV =>
                result <= (operand_a mod operand_b) & (operand_a / operand_b);
            when ALU_AND =>
                result <= signed(resize( signed(operand_a and operand_b) , output_data'length ));
            when ALU_OR =>
                result <= signed(resize( signed(operand_a or operand_b) , output_data'length ));
            when ALU_NOR =>
                result <=signed(resize( signed(operand_a nor operand_b) , output_data'length ));
            when ALU_XOR =>
                result <=signed(resize( signed(operand_a xor operand_b) , output_data'length ));
            when ALU_LSL =>
                result <= shift_left( signed( resize(signed(operand_a), output_data'length) ) , to_integer(operand_b) );
            when ALU_RSL =>
                result <= shift_right( signed( resize(signed(operand_a), output_data'length) ) , to_integer(operand_b) );
            when ALU_LSA =>
                result <= shift_left( resize(signed(operand_a), output_data'length) , to_integer(operand_b) );
            when ALU_RSA =>
                result <= shift_right( resize(signed(operand_a), output_data'length) , to_integer(operand_b) );
            when ALU_LESS_THAN =>
                result <= less_than;
        end case;
    end process;

    n <= result(data_size-1);
    z <= '1' when result = "0" else '0'; 
    c <=    ( operand_a(data_size - 1) and operand_b(data_size - 1)) or
            ( operand_a(data_size - 1) and (not result(data_size-1) ) ) or 
            ( operand_b(data_size - 1) and (not result(data_size-1) ) );

    less_than <= signed( to_unsigned( 1 , less_than'length) ) when (operand_a < operand_b) else signed( to_unsigned( 0 , less_than'length) );

    carry <= c;
    overflow <= not c;

    output_data <= result;
    zero <= z;
    negative <= n;

end alu_desc;