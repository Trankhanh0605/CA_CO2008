.data
    result_msg: .asciiz "Ket qua: "
    newline: .asciiz "\n"

.text
.globl main

main:
    # ==========================================
    # BÀI 2: Tính 200000 + 4000 - 700
    # ==========================================
    
    # 200000 = 0x30D40 (lớn hơn 16-bit nên cần chia thành 2 phần)
    # Sử dụng lui và ori để nạp số 200000
    
    lui $t0, 3           # 3 * 65536 = 196608
    ori $t0, $t0, 3392   # 196608 + 3392 = 200000
    
    # Thực hiện phép cộng 4000
    addi $t0, $t0, 4000  # 200000 + 4000 = 204000
    
    # Thực hiện phép trừ 700
    addi $t0, $t0, -700  # 204000 - 700 = 203300
    
    # Lưu kết quả vào $s0 theo yêu cầu
    move $s0, $t0
    
    # ==========================================
    # XUẤT KẾT QUẢ RA MÀN HÌNH
    # ==========================================
    
    # In chuỗi "Ket qua: "
    li $v0, 4
    la $a0, result_msg
    syscall
    
    # In kết quả số
    li $v0, 1
    move $a0, $s0
    syscall
    
    # Xuống dòng
    li $v0, 4
    la $a0, newline
    syscall