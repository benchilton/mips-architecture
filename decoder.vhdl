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
        opcode          : in  inst_opcodes;
        funct           : in  inst_funct;

        negative        : in std_logic;
        zero            : in std_logic;

        --Controls the ALU input MUXs
        alu_src_a       : out std_logic := '0';
        alu_src_b       : out std_logic := '0';
        ---Controls the Hi and Lo register enables
        reg_hi_en       : out std_logic := '0';
        reg_lo_en       : out std_logic := '0';
        ---Controls the writeback reg source
        wb_source       : out std_logic_vector(1 downto 0) := b"00";
        ---GP Register write enable
        reg_w_en        : out std_logic := '1';
        ---GP Register write-back source
        reg_w_src       : out std_logic := '1';
        reg_w_to_ra     : out std_logic := '0';
        ---Data memory read and write enable
        mem_w_en        : out std_logic := '0';
        mem_r_en        : out std_logic := '0';
        ---Branch and jump control
        branch          : out std_logic := '0';
        jump            : out std_logic := '0';
        should_branch   : out std_logic := '0';

        jump_from_alu   : out std_logic := '0';

        parse_shamt     : out std_logic := '0';

        alu_func        : out alu_operations := ALU_ADD

    );
end decoder;

architecture decoder_desc of decoder is

begin
    process( opcode , funct )
    begin

        alu_src_a     <= '0';
        alu_src_b     <= '0';
        reg_hi_en     <= '0';
        reg_lo_en     <= '0';
        wb_source     <= b"00";
        reg_w_en      <= '0';
        reg_w_src     <= '0';
        mem_w_en      <= '0';
        mem_r_en      <= '0';
        branch        <= '0';
        jump          <= '0';
        jump_from_alu <= '0';
        reg_w_to_ra   <= '0';
        parse_shamt   <= '0';
        alu_func      <= ALU_ADD;

        case opcode is
            when Op_R_TYPE  =>
                case funct is
                    when Fu_SLL     =>
                        reg_w_en <= '1';
                        parse_shamt <= '1';
                        alu_src_b   <= '1';
                        alu_func <= ALU_LSL;
                    when Fu_SRL     =>
                        reg_w_en <= '1';
                        parse_shamt <= '1';
                        alu_src_b   <= '1';
                        alu_func <= ALU_RSL;
                    when Fu_SRA     =>
                        reg_w_en <= '1';
                        parse_shamt <= '1';
                        alu_src_b   <= '1';
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
                        jump          <= '1';
                        jump_from_alu <= '1';
                        alu_func      <= ALU_ADD;
                    when Fu_JALR    =>
                        jump          <= '1';
                        jump_from_alu <= '1';
                        alu_src_a     <= '1';
                        alu_src_b     <= '1';
                        alu_func      <= ALU_ADD;
                    when Fu_MFHI    =>
                        reg_w_en <= '1';
                        wb_source   <= b"11";
                    when Fu_MTHI    =>
                        alu_func    <= ALU_LSL;
                        parse_shamt <= '1';
                        alu_src_b   <= '1';
                        reg_hi_en   <= '1';
                    when Fu_MFLO    =>
                        reg_w_en <= '1';
                        wb_source   <= b"10";
                    when Fu_MTLO    =>
                        alu_func <= ALU_ADD;
                        reg_lo_en <= '1';
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
                    when others     =>
                        alu_src_a   <= '0';
                        alu_src_b   <= '0';
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
                end case;
            when Op_J       =>
                jump <= '1';
            when Op_JAL     =>
                jump          <= '1';
                reg_w_en      <= '1';
                alu_src_a     <= '1';
                alu_src_b     <= '0';
                reg_w_to_ra   <= '1';
                alu_func      <= ALU_ADD;
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
                reg_w_en  <= '1';
                alu_func  <= ALU_ADD;
            when Op_ADDIU   =>
                alu_src_b <= '1';
                reg_w_src <= '1';
                reg_w_en  <= '1';
                alu_func <= ALU_ADDU;
            when Op_SLTI    =>
                alu_src_b <= '1';
                reg_w_src <= '1';
                reg_w_en  <= '1';
                alu_func <= ALU_LESS_THAN;
            when Op_SLTIU   =>
                alu_src_b <= '1';
                reg_w_src <= '1';
                reg_w_en  <= '1';
                alu_func  <= ALU_LESS_THAN;
            when Op_ANDI    =>
                alu_src_b <= '1';
                reg_w_src <= '1';
                reg_w_en  <= '1';
                alu_func  <= ALU_AND;
            when Op_ORI     =>
                alu_src_b <= '1';
                reg_w_src <= '1';
                reg_w_en  <= '1';
                alu_func  <= ALU_OR;
            when Op_XORI    =>
                alu_src_b <= '1';
                reg_w_src <= '1';
                reg_w_en  <= '1';
                alu_func  <= ALU_XOR;
            when Op_LWS      =>
                mem_r_en  <= '1';
                reg_w_en  <= '0';
                reg_w_src <= '1';
                alu_src_b <= '1';
                wb_source   <= b"01";
                alu_func  <= ALU_ADD;
            when Op_LWE     =>
                mem_r_en  <= '1';
                alu_src_b <= '1';
                reg_w_src <= '1';
                reg_w_en  <= '1';
                alu_func  <= ALU_ADD;
                wb_source   <= b"01";
            when Op_SW      =>
                mem_w_en <= '1';
                alu_src_b <= '1';
                reg_w_src <= '1';
                alu_func <= ALU_ADD;
                wb_source   <= b"00";
            when others     =>
                alu_src_a   <= '0';
                alu_src_b   <= '0';
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
        end case;
    end process;


    process ( opcode , zero, negative ) is
        begin
            case( opcode ) is
                when Op_BEQ  =>
                    should_branch <= zero;
                when Op_BNE  =>
                    should_branch <= not zero;
                when Op_BLEZ =>
                    if ((negative = '1') or (zero = '1')) then
                        should_branch <= '1';
                    else
                        should_branch <= '0';
                    end if;
                when Op_BGTZ =>
                    if ((negative = '0') or (zero = '1')) then
                        should_branch <= '1';
                    else
                        should_branch <= '0';
                    end if;
                when others =>
                    should_branch <= '0';
            end case;
        end process;

end decoder_desc;