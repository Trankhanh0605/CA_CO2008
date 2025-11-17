.data
    prompt_a: .asciiz "Nhap so nguyen a: "
    prompt_b: .asciiz "Nhap so nguyen b: "
    prompt_c: .asciiz "Nhap so nguyen c: "
    result: .asciiz "f(a,b,c) = (a - b) - c = "

.text
main:
    # Nhập a
    li $v0, 4
    la $a0, prompt_a
    syscall
    
    li $v0, 5
    syscall
    move $t0, $v0      # $t0 = a
    
    # Nhập b
    li $v0, 4
    la $a0, prompt_b
    syscall
    
    li $v0, 5
    syscall
    move $t1, $v0      # $t1 = b
    
    # Nhập c
    li $v0, 4
    la $a0, prompt_c
    syscall
    
    li $v0, 5
    syscall
    move $t2, $v0      # $t2 = c
    
    # Tính (a - b) - c
    sub $t3, $t0, $t1  # $t3 = a - b
    sub $t3, $t3, $t2  # $t3 = (a - b) - c
    
    # Xuất kết quả
    li $v0, 4
    la $a0, result
    syscall
    
    li $v0, 1
    move $a0, $t3
    syscall
    
    # Kết thúc
    li $v0, 10
    syscall