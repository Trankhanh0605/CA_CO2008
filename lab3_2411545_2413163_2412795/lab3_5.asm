.data
str:    .asciiz "Computer Architecture CSE-HCMUT"
.text
.globl main
main:
    la $t0, str          #str
    li $t1, 0            # i 
    li $t2, 'r'          # r

loop:
    lb $t3, 0($t0)       
    beqz $t3, not_found  
    beq $t3, $t2, found  

    addi $t0, $t0, 1     
    addi $t1, $t1, 1     # i++
    j loop

found:
    li $v0, 1
    move $a0, $t1
    syscall
    j end

not_found:
    li $v0, 1
    li $a0, -1
    syscall

end:
    li $v0, 10
    syscall
