.data
    prompt: .asciiz "Nhap chuoi 10 ky tu: "
    output: .asciiz "Chuoi vua nhap: "
    buffer: .space 11   # 10 ký tự + 1 cho null terminator

.text
main:
    # Nhập chuỗi
    li $v0, 4
    la $a0, prompt
    syscall
    
    li $v0, 8          # syscall read string
    la $a0, buffer     # địa chỉ buffer
    li $a1, 11         # độ dài tối đa (10 ký tự + null)
    syscall
    
    # Xuất chuỗi
    li $v0, 4
    la $a0, output
    syscall
    
    li $v0, 4
    la $a0, buffer
    syscall
    
    # Kết thúc
    li $v0, 10
    syscall