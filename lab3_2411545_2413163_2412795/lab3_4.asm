.data
invalid: .asciiz "invalid input"
.text
.globl main
main:
li $v0, 5
syscall
move $t0, $v0 #n
bltz $t0, case1
beqz $t0, case2
beq $t0, 1, case3
j case4
case1:
li $v0, 4
la $a0, invalid
syscall
j end
case2:
li $v0, 1
li $a0, 0
syscall
j end
case3:
li $v0, 1
li $a0, 1
syscall
j end
case4:
li $t1, 0 #f0
li $t2, 1 #f1
li $t3, 2 #i
li $t4, 0 #output
loop:
bgt $t3, $t0, exit
add $t4, $t1, $t2
move $t1, $t2
move $t2, $t4
addi $t3, $t3, 1
j loop
exit:
li $v0, 1
move $a0, $t4
syscall
j end
end:
li $v0, 10
syscall