.data
    array: .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10   

.text
.globl main
main:
    la $t0, array
    lw $t1, 12($t0)
    lw $t2, 20($t0)      

    sub $t3, $t1, $t2

    li $v0, 1
    move $a0, $t3
    syscall

    li $v0, 10
    syscall
