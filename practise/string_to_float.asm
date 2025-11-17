.data
# Các hằng số (constants) mà FPU cần dùng
const_10:    .float 10.0
const_1:     .float 1.0
const_neg_1: .float -1.0
const_0:     .float 0.0

# Các chuỗi để kiểm thử
str_test_1: .asciiz "123.45"
str_test_2: .asciiz "-0.8"
str_test_3: .asciiz "5"

# Chuỗi dùng để in
str_nl:     .asciiz "\nTest 1 (123.45): "
str_nl2:    .asciiz "\nTest 2 (-0.8):   "
str_nl3:    .asciiz "\nTest 3 (5):      "

.text
.globl main
main:
# --- Test Case 1: "123.45" ---
    li   $v0, 4
    la   $a0, str_nl
    syscall
    la   $a0, str_test_1   # $a0 = địa chỉ của chuỗi "123.45"
    jal  string_to_float # Gọi thủ tục
    # Kết quả trả về nằm trong $f0
   
li   $v0, 2            # syscall 2: in số thực
    mov.s $f12, $f0      # Di chuyển kết quả vào $f12 để in
    syscall
    
   # --- Test Case 2: "-0.8" ---
    li   $v0, 4
    la   $a0, str_nl2
    syscall
    
    la   $a0, str_test_2   # $a0 = địa chỉ của chuỗi "-0.8"
    jal  string_to_float # Gọi thủ tục
    
    li   $v0, 2
    mov.s $f12, $f0
    syscall
    
# --- Test Case 3: "5" ---
    li   $v0, 4
    la   $a0, str_nl3
    syscall
    
    la   $a0, str_test_3   # $a0 = địa chỉ của chuỗi "5"
    jal  string_to_float # Gọi thủ tục
    
    li   $v0, 2
    mov.s $f12, $f0
    syscall

    # --- Kết thúc chương trình ---
    li   $v0, 10
    syscall
    
string_to_float:
    # --- 1. Prolog: Cất giữ các thanh ghi ---
    # Cần cất $ra (địa chỉ trả về) để có thể gọi `jr $ra`
    subu  $sp, $sp, 4     # Dành 1 word (4 bytes) trên stack
    sw    $ra, 0($sp)     # Lưu $ra vào stack

    # --- 2. Khởi tạo "biến" ---
    # Tải các hằng số vào thanh ghi FPU
    l.s   $f10, const_10  # $f10 = 10.0
    l.s   $f2, const_1    # $f2 (sign) = 1.0
    l.s   $f4, const_1    # $f4 (power) = 1.0 (sẽ dùng cho 0.1, 0.01...)
    l.s   $f0, const_0    # $f0 (result 'value') = 0.0

    # Khởi tạo thanh ghi CPU
    li    $t2, 0          # $t2 (after_decimal flag) = 0 (false)
    move   $t0, $a0        # $t0 (con trỏ 'p') = địa chỉ chuỗi

    # --- 3. Kiểm tra dấu (sign) ở ký tự đầu tiên ---
    lb    $t1, 0($t0)     # $t1 = ký tự đầu tiên
    li    $t3, '-'
    bne   $t1, $t3, parse_loop # Nếu (ký tự != '-') thì nhảy vào vòng lặp chính
    
    # Nếu là dấu '-', xử lý dấu
    l.s   $f2, const_neg_1 # $f2 (sign) = -1.0
    addi  $t0, $t0, 1      # Tăng con trỏ (p++)

parse_loop:
    # --- 4. Vòng lặp chính: duyệt qua các ký tự ---
    lb    $t1, 0($t0)     # $t1 = ký tự hiện tại
    
    # Kiểm tra ký tự kết thúc (End of String)
    li    $t3, 0          # Ký tự Null '\0'
    beq   $t1, $t3, parse_done # Nếu là '\0', xong
    li    $t3, '\n'       # Ký tự xuống dòng '\n' (an toàn)
    beq   $t1, $t3, parse_done # Nếu là '\n', xong
    
    # Kiểm tra dấu chấm thập phân
    li    $t3, '.'
    beq   $t1, $t3, handle_decimal # Nếu là '.', nhảy xử lý
    
    # Nếu không phải 3 trường hợp trên, nó PHẢI là một chữ số
    # Chuyển ký tự '0'...'9' thành số 0...9
    li    $t3, '0'        # ASCII '0' là 48
    subu  $t3, $t1, $t3   # $t3 = int(digit). (vd: '5'(53) - '0'(48) = 5)
    
    # Chuyển int(digit) sang float(digit)
    mtc1  $t3, $f6        # Di chuyển bit pattern của int 5 sang FPU
    cvt.s.w $f6, $f6      # Chuyển đổi int-trong-FPU sang float-trong-FPU
                          # $f6 bây giờ chứa số thực 5.0
    
    # Kiểm tra xem đang xử lý trước hay sau dấu chấm
    beq   $t2, $zero, before_decimal # Nếu cờ (flag) $t2 == 0, nhảy
    
    # --- 4a. Đang SAU dấu chấm (after_decimal == true) ---
    div.s $f4, $f4, $f10  # power = power / 10.0 (vd: 1.0 -> 0.1 -> 0.01)
    mul.s $f8, $f6, $f4   # (digit * power) (vd: 4 * 0.1 = 0.4)
    add.s $f0, $f0, $f8   # value = value + (digit * power)
    j     next_char       # Nhảy tới bước tiếp theo

before_decimal:
    # --- 4b. Đang TRƯỚC dấu chấm (after_decimal == false) ---
    mul.s $f0, $f0, $f10  # value = value * 10.0 (vd: 12.0 -> 120.0)
    add.s $f0, $f0, $f6   # value = value + digit (vd: 120.0 + 3.0 = 123.0)
    
next_char:
    # --- 4c. Tăng con trỏ và lặp lại ---
    addi  $t0, $t0, 1      # p++
    j     parse_loop      # Quay lại đầu vòng lặp

handle_decimal:
    # --- 5. Xử lý dấu chấm ---
    li    $t2, 1          # Đặt cờ after_decimal = true
    addi  $t0, $t0, 1      # p++
    j     parse_loop      # Quay lại vòng lặp

parse_done:
    # --- 6. Hoàn thành: Áp dụng dấu (sign) ---
    mul.s $f0, $f0, $f2   # result = value * sign
    
    # --- 7. Epilog: Khôi phục thanh ghi và Trở về ---
    lw    $ra, 0($sp)     # Khôi phục $ra từ stack
    addu  $sp, $sp, 4     # Giải phóng 4 bytes đã dùng trên stack
    jr    $ra             # Trở về hàm 'main'