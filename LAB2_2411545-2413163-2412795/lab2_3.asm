.data
.text
.globl main
main:
    li $v0, 5
    syscall
    move $t0, $v0      # $t0 = a

    li $v0, 5
    syscall
    move $t1, $v0      # $t1 = b

    li $v0, 5
    syscall
    move $t2, $v0      # $t2 = c

    li $v0, 5
    syscall
    move $t3, $v0      # $t3 = d

    li $v0, 5
    syscall
    move $t4, $v0      # $t4 = x

    mul $t5, $t0, $t4     # t5 = a * x
    add $t5, $t5, $t1     # t5 = a * x + b
    mul $t5, $t5, $t4     # t5 = (a * x + b) * x
    sub $t5, $t5, $t2     # t5 = (a * x + b) * x - c
    mul $t5, $t5, $t4     # t5 = ((a * x + b) * x - c) * x
    sub $t5, $t5, $t3     # t5 = (((a * x + b) * x - c) * x - d)
    move $s0, $t5         

    li $v0, 1
    move $a0, $s0
    syscall

    li $v0, 10
    syscall
