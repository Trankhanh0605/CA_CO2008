.data
    message: .asciiz "Kien Truc May Tinh 2022"

.text
main:
    # Xuất chuỗi
    li $v0, 4
    la $a0, message
    syscall
    
    # Kết thúc
    li $v0, 10
    syscall