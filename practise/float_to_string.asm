# Task 2.3: Thủ tục float_to_string
# Mục tiêu: Chuyển đổi một số thực (float) thành chuỗi ASCII (vd: 12.4).

.data
# Các hằng số FPU
const_10:     .float 10.0
const_0_05:   .float 0.05    # Dùng để làm tròn 1 chữ số
const_0:      .float 0.0

# Dữ liệu kiểm thử
f_test_1:     .float 12.36   # Sẽ làm tròn thành "12.4"
f_test_2:     .float -0.8    # Sẽ là "-0.8"
f_test_3:     .float 5.0     # Sẽ là "5.0"
f_test_4:     .float 0.03    # Sẽ làm tròn thành "0.0"

# Buffer (bộ đệm) để chứa chuỗi kết quả
out_buffer:   .space 32      # 32 bytes là đủ

# Chuỗi thông báo
str_test_1: .asciiz "Test 1 (12.36 -> 12.4):  "
str_test_2: .asciiz "\nTest 2 (-0.8 -> -0.8):   "
str_test_3: .asciiz "\nTest 3 (5.0 -> 5.0):     "
str_test_4: .asciiz "\nTest 4 (0.03 -> 0.0):    "


.text
.globl main
main:
    # --- Chương trình chính để KIỂM THỬ thủ tục ---
    
    # --- Test Case 1 ---
    li   $v0, 4
    la   $a0, str_test_1
    syscall
    
    la   $a0, out_buffer   # $a0 = địa chỉ buffer
    l.s  $f12, f_test_1    # $f12 = 12.36
    jal  float_to_string   # Gọi thủ tục
    
    li   $v0, 4            # In chuỗi kết quả
    la   $a0, out_buffer
    syscall

    # --- Test Case 2 ---
    li   $v0, 4
    la   $a0, str_test_2
    syscall
    
    la   $a0, out_buffer
    l.s  $f12, f_test_2
    jal  float_to_string
    
    li   $v0, 4
    la   $a0, out_buffer
    syscall
    
    # --- Test Case 3 ---
    li   $v0, 4
    la   $a0, str_test_3
    syscall
    
    la   $a0, out_buffer
    l.s  $f12, f_test_3
    jal  float_to_string
    
    li   $v0, 4
    la   $a0, out_buffer
    syscall

    # --- Test Case 4 ---
    li   $v0, 4
    la   $a0, str_test_4
    syscall
    
    la   $a0, out_buffer
    l.s  $f12, f_test_4
    jal  float_to_string
    
    li   $v0, 4
    la   $a0, out_buffer
    syscall
    
    # --- Kết thúc chương trình ---
    li   $v0, 10
    syscall

# =============================================================
# Thủ tục: float_to_string
# Chuyển đổi số thực FPU thành chuỗi ASCII, làm tròn 1 chữ số thập phân.
#
# Arguments:
#   $a0 - Địa chỉ của buffer (nơi lưu chuỗi kết quả).
#   $f12 - Giá trị số thực (float) cần chuyển đổi.
#
# Returns:
#   Không (thay đổi nội dung tại địa chỉ $a0).
#
# Registers sử dụng:
#   $s0 - Con trỏ buffer ($a0)
#   $t0 - Số nguyên (int) đã nhân 10 (vd: 124)
#   $t1 - Hằng số 10 (để chia)
#   $t2 - Bộ đếm số (digit_count)
#   $t3 - Số dư (remainder) / ký tự
# =============================================================
float_to_string:
    # --- 1. Prolog: Cất giữ các thanh ghi ---
    subu  $sp, $sp, 20    # Dành 20 bytes trên stack
    sw    $ra, 0($sp)     # Lưu $ra (return address)
    sw    $s0, 4($sp)     # Lưu $s0
    sw    $t0, 8($sp)     # ... (lưu các thanh ghi $t)
    sw    $t1, 12($sp)
    sw    $t2, 16($sp)
    
    move  $s0, $a0        # $s0 = con trỏ buffer (output string pointer)

    # --- 2. Xử lý dấu (Sign) ---
    l.s   $f0, const_0    # Tải 0.0 vào $f0
    c.lt.s $f12, $f0      # So sánh (value < 0.0)?
    bc1f  is_positive     # Nếu KHÔNG nhỏ hơn, nhảy
    
    # Nếu là số âm:
    li    $t3, '-'
    sb    $t3, 0($s0)     # Ghi ký tự '-' vào buffer
    addiu $s0, $s0, 1     # Tăng con trỏ buffer
    neg.s $f12, $f12      # value = -value (lấy trị tuyệt đối)

is_positive:
    # --- 3. Làm tròn và nhân 10 ---
    l.s   $f1, const_0_05 # $f1 = 0.05
    add.s $f12, $f12, $f1 # value = value + 0.05 (để làm tròn)
    
    l.s   $f1, const_10   # $f1 = 10.0
    mul.s $f12, $f12, $f1 # value = value * 10.0 (vd: 12.41 -> 124.1)

    # --- 4. Chuyển sang số nguyên ---
    cvt.w.s $f12, $f12    # Chuyển float $f12 thành int $f12
    mfc1  $t0, $f12       # Di chuyển int từ FPU sang $t0 (vd: $t0 = 124)
    
    # --- 5. Chuyển Int -> String (Đẩy số vào Stack) ---
    li    $t1, 10         # $t1 = 10 (để chia)
    li    $t2, 0          # $t2 = digit_count = 0
    
    beq   $t0, $zero, handle_zero # Xử lý trường hợp đặc biệt (int = 0)
    
push_loop:
    divu  $t0, $t1        # $t0 / $t1
    mfhi  $t3             # $t3 = remainder (số dư)
    mflo  $t0             # $t0 = quotient (thương)
    
    addiu $t3, $t3, '0'   # Chuyển số 4 -> ký tự '4'
    
    subu  $sp, $sp, 4     # Dành chỗ trên stack
    sw    $t3, 0($sp)     # Đẩy ký tự vào stack
    addiu $t2, $t2, 1     # digit_count++
    
    bnez  $t0, push_loop  # Lặp lại nếu thương != 0
    j     pop_loop        # Khi xong, đi tới vòng lặp pop

handle_zero:
    # Nếu số int là 0 (vd: 0.03 -> 0.0), ta phải đẩy 1 số '0' vào
    li    $t3, '0'
    subu  $sp, $sp, 4
    sw    $t3, 0($sp)
    li    $t2, 1          # digit_count = 1
    
pop_loop:
    # --- 6. Ghi chuỗi (Lấy số từ Stack ra Buffer) ---
    beq   $t2, $zero, done_popping # Nếu digit_count == 0, xong
    
    li    $t3, 1          # $t3 = 1 (vị trí chèn dấu chấm)
    beq   $t2, $t3, insert_decimal # Nếu (digit_count == 1), chèn dấu '.'

pop_char:
    lw    $t3, 0($sp)     # Lấy ký tự từ stack
    addu  $sp, $sp, 4     # Giải phóng stack
    
    sb    $t3, 0($s0)     # Ghi ký tự vào buffer
    addiu $s0, $s0, 1     # Tăng con trỏ buffer
    
    subiu $t2, $t2, 1     # digit_count--
    j     pop_loop

insert_decimal:
    # Chỉ còn 1 số trên stack (số thập phân)
    # Ta phải chèn dấu '.' vào TRƯỚC nó
    li    $t3, '.'
    sb    $t3, 0($s0)
    addiu $s0, $s0, 1
    j     pop_char        # Quay lại để pop số cuối cùng

done_popping:
    # --- 7. Kết thúc chuỗi ---
    li    $t3, 0          # Ký tự Null '\0'
    sb    $t3, 0($s0)     # Ghi vào cuối chuỗi
    
    # --- 8. Epilog: Khôi phục thanh ghi và Trở về ---
    lw    $ra, 0($sp)
    lw    $s0, 4($sp)
    lw    $t0, 8($sp)
    lw    $t1, 12($sp)
    lw    $t2, 16($sp)
    addu  $sp, $sp, 20    # Khôi phục con trỏ stack
    
    jr    $ra