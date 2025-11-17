.data
.text
main:
li $t0, 9 #a
li $t1, 2 #b
li $t2, 3 #c
blt $t0, -3, if
bge $t0, 7, if
j else
if:
mul $t0, $t1, $t2
j end
else:
add $t0, $t1, $t2
j end
end:
li $v0, 10
syscall