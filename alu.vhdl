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
    signal result : signed(2*data_size-1 downto 0);
    signal z : std_logic;
    signal n : std_logic;
    signal c : std_logic;
    signal shamt : integer;

    constant shamt_start_pos : natural := 10;
    constant shamt_end_pos   : natural := 5;

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
                result <= (operand_a / operand_b) & (operand_a mod operand_b);
            when ALU_AND =>
                result <= signed(resize( signed(operand_a and operand_b) , output_data'length ));
            when ALU_OR =>
                result <= signed(resize( signed(operand_a or operand_b) , output_data'length ));
            when ALU_NOR =>
                result <=signed(resize( signed(operand_a nor operand_b) , output_data'length ));
            when ALU_XOR =>
                result <=signed(resize( signed(operand_a xor operand_b) , output_data'length ));
            when ALU_LSL =>
                result <= resize( signed( shift_left(  unsigned(operand_a) , shamt ) ) , output_data'length );
            when ALU_RSL =>
                result <= resize( signed( shift_right( unsigned(operand_a) , shamt ) ) , output_data'length );
            when ALU_LSA =>
                result <= resize( shift_left( signed(operand_a) , shamt ) , output_data'length );
            when ALU_RSA =>
                result <= resize( shift_right( signed(operand_a) , shamt ) , output_data'length );
        end case;
    end process;

    shamt <= to_integer( unsigned(operand_b( shamt_start_pos-1 downto shamt_end_pos )  ) );

    n <= result(data_size-1);
    z <= '1' when result = "0" else '0'; 
    c <=    ( operand_a(data_size - 1) and operand_b(data_size - 1)) or
            ( operand_a(data_size - 1) and (not result(data_size-1) ) ) or 
            ( operand_b(data_size - 1) and (not result(data_size-1) ) );
    carry <= c;
    overflow <= not c;

    output_data <= result;
    zero <= z;
    negative <= n;

end alu_desc;