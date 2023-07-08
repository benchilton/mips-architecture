-- Decoder testbench
library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

use work.defines.all;

entity testbench_decoder is
    generic (
        opcode_len      : natural := 6;
        funct_len       : natural := 6
    );
end testbench_decoder;

architecture testbench of testbench_decoder is

    signal funct    : inst_funct;
    signal op       : inst_opcodes;

    signal reg_w_en : std_logic;

    signal alu_src_a : std_logic;
    signal alu_src_b : std_logic;

    signal reg_hi_en : std_logic;
    signal reg_lo_en : std_logic;

    signal wb_source : std_logic_vector(1 downto 0);

    signal reg_w_src : std_logic;

    signal mem_w_en  : std_logic;
    signal mem_r_en  : std_logic;

    signal branch    : std_logic;
    signal jump      : std_logic;

    signal negative  : std_logic;
    signal zero      : std_logic;

    signal alu_func  : alu_operations;

begin

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
            mem_w_en  => mem_w_en,
            mem_r_en  => mem_r_en,
            alu_func  => alu_func,
            branch    => branch,
            jump      => jump,
            negative  => negative,
            zero      => zero
        );
    
    ---operand subroutine
    process is

        variable seed1, seed2 : integer := 100;
        variable seed3, seed4 : integer := 100;

        impure function rand_signed ( min_val , max_val : integer ) return integer is
            variable rand : real;
        begin
            uniform(seed1, seed2, rand);
            return integer( round(rand * real(max_val - min_val + 1) + real(min_val) - 0.5) );
        end function;

        impure function rand_logic return std_logic is
            variable rand    : real;
            variable ret_val : std_logic := '0';
        begin
            uniform(seed3, seed4, rand);
            if( rand > 0.5 ) then
                ret_val := '1';
            else
                ret_val := '0';
            end if;
            return ret_val;
        end function;

    begin
        loop

            negative <= rand_logic;
            zero     <= rand_logic;

            op <= inst_opcodes'val( rand_signed( 0 , 15 ) );

            if op = Op_R_TYPE then
                funct <= inst_funct'val( rand_signed( 0 , 23 ) );
            else
                funct <= Fu_SLL;
            end if;

            wait for 5 ns;
        end loop;

    end process;

end testbench;
