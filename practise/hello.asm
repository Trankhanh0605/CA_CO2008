.data
num1: .float 4.76
num2: .float 5.19
str_tong: .asciiz "\nTong la: "
str_tich: .asciiz "\nTich la: "
.text
.globl main
main: 

l.s $f0, num1
l.s $f1, num2
mul.s $f2, $f0, $f1
add.s $f3, $f0, $f1 

li $v0, 4
la $a0, str_tong
syscall 

li $v0, 2             # Mã syscall: in số float
mov.s $f12, $f3       # Di chuyển kết quả Tổng ($f3) vào $f12
syscall

li $v0, 4             # Mã syscall: in chuỗi
la $a0, str_tich      # Nạp địa chỉ chuỗi "str_tich"
syscall
 
li $v0, 2 
mov.s $f12, $f2
syscall 
 
li $v0, 10 
syscall 
