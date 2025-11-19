.data
pi: .float 3.14
hai: .float 2.0
khong: .float 0.0
msg: .asciiz "Ban kinh khong duoc am"
chuvi: .asciiz "Chu vi: \n"
dientich: .asciiz "\nDien tich: \n"
.text
.globl main
main:
#nhap
li $v0, 6
syscall
mov.s $f12, $f0

#neu am
l.s $f1, khong
c.lt.s $f12, $f1
bc1t  am

#chu vi
l.s $f2, pi
l.s $f3, hai
mul.s $f4, $f3, $f2
mul.s $f6, $f4, $f12

#dien tich
mul.s $f5, $f12, $f12
mul.s $f7, $f2, $f5

#in
li $v0, 4
la $a0, chuvi
syscall

li $v0, 2
mov.s $f12, $f6
syscall

li $v0, 4
la $a0, dientich
syscall

li $v0, 2
mov.s $f12, $f7
syscall

j end

#am
am:
li $v0, 4
la $a0, msg
syscall

end:
li $v0, 10
syscall