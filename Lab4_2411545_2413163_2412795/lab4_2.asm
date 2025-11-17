.data

iArray: .word 5,3,9,1,7,2,10,4,6,8

newline: .asciiz "\n"

.text

.globl main

main:

    la $a0, iArray

    addi $a1, $zero, 10

    jal range

    move $a0, $v0

    li $v0, 1

    syscall

    la $a0, newline

    li $v0, 4

    syscall

    li $v0, 10

    syscall



range:

    addi $sp, $sp, -8

    sw $ra, 4($sp)

    sw $s0, 0($sp)

    move $s0, $a0

    jal max

    move $t0, $v0

    jal min

    sub $v0, $t0, $v0

    lw $s0, 0($sp)

    lw $ra, 4($sp)

    addi $sp, $sp, 8

    jr $ra



max:

    lw $v0, 0($a0)

    li $t0, 1

max_loop:

    beq $t0, $a1, max_end

    sll $t1, $t0, 2

    add $t1, $a0, $t1

    lw $t2, 0($t1)

    slt $t3, $v0, $t2

    movn $v0, $t2, $t3

    addi $t0, $t0, 1

    j max_loop

max_end:

    jr $ra



min:

    lw $v0, 0($a0)

    li $t0, 1

min_loop:

    beq $t0, $a1, min_end

    sll $t1, $t0, 2

    add $t1, $a0, $t1

    lw $t2, 0($t1)

    slt $t3, $t2, $v0

    movn $v0, $t2, $t3

    addi $t0, $t0, 1

    j min_loop

min_end:

    jr $ra

