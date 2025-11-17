.data
str1: .asciiz "Computer Science and Engineering, HCMUT\n"
str2: .asciiz "Computer Architecture 2022\n"
.text
main:
li $t0, 6 #a
div $t0, $t0, 2
mfhi $t2
beq $t2, $zero, if
j else
if:
la $a0, str1
li $v0, 4
syscall
j end
else:
la $a0, str2
li $v0, 4
syscall
j end
end:
li $v0, 10
syscall
