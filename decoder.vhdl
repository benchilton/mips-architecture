library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use work.defines.all;

entity decoder is
    generic (
        opcode_size : natural := 5;
        funct_size  : natural := 6
    );
    port (
        opcode     : in  inst_opcodes;
        funct      : in  inst_funct;

        --Controls the ALU input MUXs
        alu_src_a   : out std_logic;
        alu_src_b   : out std_logic;
        ---Controls the Hi and Lo register enables
        reg_hi_en   : out std_logic;
        reg_lo_en   : out std_logic;
        ---Controls the writeback reg source
        wb_source   : out std_logic_vector(1 downto 0);
        ---GP Register write enable
        reg_w_en    : out std_logic;
        ---GP Register write-back source
        reg_w_src   : out std_logic;
        ---Data memory read and write enable
        mem_w_en    : out std_logic;
        mem_r_en    : out std_logic;
        ---Branch and jump control
        branch      : out std_logic;
        jump        : out std_logic;

        alu_func    : out alu_operations

    );
end decoder;

architecture decoder_desc of decoder is

begin
    process( opcode , funct )
    begin

        alu_src_a   <= '0';
        alu_src_b   <= '1';
        reg_hi_en   <= '0';
        reg_lo_en   <= '0';
        wb_source   <= b"00";
        reg_w_en    <= '1';
        reg_w_src   <= '1';
        mem_w_en    <= '0';
        mem_r_en    <= '0';
        branch      <= '0';
        jump        <= '0';
        alu_func    <= ALU_ADD;

        case opcode is
            when Op_R_TYPE  =>
                case funct is
                    when Fu_SLL     =>
                        reg_w_en <= '1';
                        alu_func <= ALU_LSL;
                    when Fu_SRL     =>
                        reg_w_en <= '1';
                        alu_func <= ALU_RSL;
                    when Fu_SRA     =>
                        reg_w_en <= '1';
                        alu_func <= ALU_RSA;
                    when Fu_SLLV    =>
                        reg_w_en <= '1';
                        alu_func <= ALU_LSL;
                    when Fu_SRLV    =>
                        reg_w_en <= '1';
                        alu_func <= ALU_RSL;
                    when Fu_SRAV    =>
                        reg_w_en <= '1';
                    when Fu_JR      =>
                        jump <= '1';
                    when Fu_JALR    =>
                        jump <= '1';
                    when Fu_MVHI    =>
                        reg_w_en <= '1';
                        wb_source   <= b"11";
                    when Fu_MVLO    =>
                        reg_w_en <= '1';
                        wb_source   <= b"10";
                    when Fu_MULT    =>
                        reg_hi_en <= '1';
                        reg_lo_en <= '1';
                        alu_func <= ALU_MUL;
                    when Fu_MULTU   =>
                        reg_hi_en <= '1';
                        reg_lo_en <= '1';
                        alu_func <= ALU_MUL;
                    when Fu_DIV     =>
                        reg_hi_en <= '1';
                        reg_lo_en <= '1';
                        alu_func <= ALU_DIV;
                    when Fu_DIVU    =>
                        reg_hi_en <= '1';
                        reg_lo_en <= '1';
                        alu_func <= ALU_DIV;
                    when Fu_ADD     =>
                        reg_w_en <= '1';
                        alu_func <= ALU_ADD;
                    when Fu_ADDU    =>
                        reg_w_en <= '1';
                        alu_func <= ALU_ADDU;
                    when Fu_SUB     =>
                        reg_w_en <= '1';
                        alu_func <= ALU_SUB;
                    when Fu_SUBU    =>
                        reg_w_en <= '1';
                        alu_func <= ALU_SUBU;
                    when Fu_AND     =>
                        reg_w_en <= '1';
                        alu_func <= ALU_AND;
                    when Fu_OR      =>
                        reg_w_en <= '1';
                        alu_func <= ALU_OR;
                    when Fu_XOR     =>
                        reg_w_en <= '1';
                        alu_func <= ALU_XOR;
                    when Fu_NOR     =>
                        reg_w_en <= '1';
                        alu_func <= ALU_NOR;
                    when Fu_SLT     =>
                        reg_w_en <= '1';
                        alu_func <= ALU_SUB;
                    when Fu_SLTU    =>
                        reg_w_en <= '1';
                        alu_func <= ALU_SUB;
                end case;
            when Op_J       =>
                jump <= '1';
            when Op_JAL     =>
                jump <= '1';
                reg_w_en <= '1';
            when Op_BEQ     =>
                branch <= '1';
            when Op_BNE     =>
                branch <= '1';
            when Op_BLEZ    =>
                branch <= '1';
            when Op_BGTZ    =>
                branch <= '1';
            when Op_ADDI    =>
                alu_src_b <= '1';
                reg_w_src <= '1';
                alu_func <= ALU_ADD;
            when Op_ADDIU   =>
                alu_src_b <= '1';
                reg_w_src <= '1';
                alu_func <= ALU_ADDU;
            when Op_SLTI    =>
                alu_src_b <= '1';
                reg_w_src <= '1';
                alu_func <= ALU_SUB;
            when Op_SLTIU   =>
                alu_src_b <= '1';
                reg_w_src <= '1';
                alu_func <= ALU_SUB;
            when Op_ANDI    =>
                alu_src_b <= '1';
                reg_w_src <= '1';
                alu_func <= ALU_AND;
            when Op_ORI     =>
                alu_src_b <= '1';
                reg_w_src <= '1';
                alu_func <= ALU_OR;
            when Op_XORI    =>
                alu_src_b <= '1';
                reg_w_src <= '1';
                alu_func <= ALU_XOR;
            when Op_LW      =>
                mem_r_en <= '1';
                alu_func <= ALU_ADD;
            when Op_SW      =>
                mem_w_en <= '1';
                alu_func <= ALU_ADD;
        end case;
    end process;

end decoder_desc;