#A very random test program which does a multiply-accumulate on 2 vectors, the main purpose of this is to demonstrate different functionality of both
#The custom assembler and the processor designed.


#Data segment
.data

mystring:       .asciz  "Hello World"
x:             
                .word   -20 , 20 , -20 , 20
c:              
                .word   2
                .word   8
                .word   -1
                .word   19

y:              .word   0

#Now the program begins
.text

main:   
        addiu   $sp , $sp,-144
        sw      $31 , 140($sp)
        sw      $fp , 136($sp)
        move    $fp , $sp
        sw      $0  , 24($fp)

#Load the address off the variables

        li      $1 , 0
        li      $5 , 0

for_loop:

#Access index 0 for x and c

        lw      $2 , %address(x)( $1 )
        lw      $3 , %address(c)( $1 )

        mult    $3 , $2
        mflo    $4

        add     $5 , $5 , $4

        addi    $1 , $1 , 4

        sltiu   $6 , $1 , %literal( 4 * 4 )
        bnez    $6 , for_loop
exit:   
        li      $a0 , 0
        move    $v0 , $5
        sw      $v0 , %address(y)( $a0 )
