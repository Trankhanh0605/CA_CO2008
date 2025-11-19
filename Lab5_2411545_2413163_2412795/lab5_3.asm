.data
    arr: .float 3.2, 1.1, 5.5, -2.2, 9.9, 4.6, 2.0, 0.5, -7.3, 6.1,
               8.8, 1.0, 2.3, -1.5, 3.7, 4.4, 6.6, -0.4, 5.1, 2.9
    msg_max: .asciiz "max = "
    msg_min: .asciiz "\nmin = "

.text
.globl main
main:
    la $t0, arr    # pointer
    li $t1, 20     # count

    l.s $f0, 0($t0)   # max
    l.s $f1, 0($t0)   # min

loop:
    l.s $f2, 0($t0)

    # max
    c.lt.s $f0, $f2
    bc1t update_max

continue_max:

    # min
    c.lt.s $f2, $f1
    bc1t update_min

continue_min:
    addi $t0, $t0, 4  # next element
    addi $t1, $t1, -1
    bgtz $t1, loop

    # Output
    li $v0, 4
    la $a0, msg_max
    syscall

    li $v0, 2
    mov.s $f12, $f0
    syscall

    li $v0, 4
    la $a0, msg_min
    syscall

    li $v0, 2
    mov.s $f12, $f1
    syscall

    li $v0, 10
    syscall

update_max:
    mov.s $f0, $f2
    b continue_max

update_min:
    mov.s $f1, $f2
    b continue_min
