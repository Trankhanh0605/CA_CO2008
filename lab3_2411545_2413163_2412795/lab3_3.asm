.data
.text
main:
li $v0, 5
li $t0, 0
li $t1, 100
li $t2, 2
syscall
move $t3, $v0
beq $t3, 1, case1
beq $t3, 2, case2
beq $t3, 3, case3
beq $t3, 4, case4
j end
case1:
add $t0, $t1, $t2
j end
case2:
sub $t0, $t1, $t2
j end
case3:
mul $t0, $t1, $t2
j end
case4:
div $t0, $t1, $t2
j end
end:
li $v0, 10
syscall