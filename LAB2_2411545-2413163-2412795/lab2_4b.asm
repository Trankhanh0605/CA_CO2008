.data
    input_str: .asciiz "2412795 - Tran Van Phuong\n"  

.text
.globl main
main:
    la $t0, input_str      

    # Tim do dai chuoi
    move $t1, $t0           
    li $t2, 0             

find_len:
    lb $t3, 0($t1)
    beq $t3, 10, end_find   # 10 = '\n'
    addi $t1, $t1, 1
    addi $t2, $t2, 1
    j find_len
end_find:

    lb $t4, 0($t0)          # $t4 = ki tu dau
    subi $t2, $t2, 1        # t2 = vi tri cuoi
    add $t5, $t0, $t2
    lb $t6, 0($t5)          # $t6 = ki tu cuoi

    # sýap
    sb $t6, 0($t0)          
    sb $t4, 0($t5)          

    li $v0, 4
    la $a0, input_str
    syscall

    # Thoat
    li $v0, 10
    syscall
