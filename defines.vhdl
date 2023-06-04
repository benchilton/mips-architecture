library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

package defines is
    type alu_operations is ( ALU_ADD, ALU_ADDU, ALU_SUB, ALU_SUBU, ALU_MUL, ALU_DIV, ALU_AND, ALU_OR, ALU_NOR, ALU_XOR, ALU_LSL, ALU_RSL, ALU_LSA, ALU_RSA);

    type inst_opcodes is (
      Op_R_TYPE,
      Op_J,
      Op_JAL,
      Op_BEQ,
      Op_BNE,
      Op_BLEZ,
      Op_BGTZ,
      Op_ADDI,
      Op_ADDIU,
      Op_SLTI,
      Op_SLTIU,
      Op_ANDI,
      Op_ORI,
      Op_XORI,
      Op_LW,
      Op_SW
    );

    type inst_opcodes_lookup_t is array ( inst_opcodes ) of std_logic_vector(5 downto 0);
    constant inst_opcodes_lookup : inst_opcodes_lookup_t := (
      Op_R_TYPE => b"000000",
      Op_J      => b"000001",
      Op_JAL    => b"000010",
      Op_BEQ    => b"000011",
      Op_BNE    => b"000100",
      Op_BLEZ   => b"000101",
      Op_BGTZ   => b"000110",
      Op_ADDI   => b"000111",
      Op_ADDIU  => b"001000",
      Op_SLTI   => b"001001",
      Op_SLTIU  => b"001010",
      Op_ANDI   => b"001011",
      Op_ORI    => b"001100",
      Op_XORI   => b"001101",
      Op_LW     => b"001110",
      Op_SW     => b"001111"
    );

    type inst_funct is (
      Fu_SLL,
      Fu_SRL,
      Fu_SRA,
      Fu_SLLV,
      Fu_SRLV,
      Fu_SRAV,
      Fu_JR,
      Fu_JALR,
      Fu_MVHI,
      Fu_MVLO,
      Fu_MULT,
      Fu_MULTU,
      Fu_DIV,
      Fu_DIVU,
      Fu_ADD,
      Fu_ADDU,
      Fu_SUB,
      Fu_SUBU,
      Fu_AND,
      Fu_OR,
      Fu_XOR,
      Fu_NOR,
      Fu_SLT,
      Fu_SLTU
      );

    type inst_funct_lookup_t is array ( inst_funct ) of std_logic_vector(5 downto 0);
    constant inst_funct_lookup : inst_funct_lookup_t := (
      Fu_SLL    => b"000000",
      Fu_SRL    => b"000001",
      Fu_SRA    => b"000010",
      Fu_SLLV   => b"000011",
      Fu_SRLV   => b"000100",
      Fu_SRAV   => b"000101",
      Fu_JR     => b"000110",
      Fu_JALR   => b"000111",
      Fu_MVHI   => b"001000",
      Fu_MVLO   => b"001001",
      Fu_MULT   => b"001010",
      Fu_MULTU  => b"001011",
      Fu_DIV    => b"001100",
      Fu_DIVU   => b"001101",
      Fu_ADD    => b"001110",
      Fu_ADDU   => b"001111",
      Fu_SUB    => b"010000",
      Fu_SUBU   => b"010001",
      Fu_AND    => b"010010",
      Fu_OR     => b"010011",
      Fu_XOR    => b"010100",
      Fu_NOR    => b"010101",
      Fu_SLT    => b"010110",
      Fu_SLTU   => b"010111"
      );

  end package defines;
  
  package body defines is
    
  end package body defines;