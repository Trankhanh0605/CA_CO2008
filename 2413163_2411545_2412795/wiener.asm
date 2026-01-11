.data
# Ten file
desired_file: .asciiz "desired.txt"
input_file: .asciiz "input.txt"
output_file: .asciiz "output.txt"
error_msg: .asciiz "Error: Cannot open file\n"
size_error_msg: .asciiz "Error: size not match\n"
newline: .asciiz "\n"
space: .asciiz " "
# Cac mang voi N=10
desired_signal: .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
input_signal: .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
output_signal: .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
optimize_coefficient: .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 # M=10
# Cac bien khac
M: .word 10 # Do dai bo loc
N: .word 10 # Do dai tin hieu
mmse: .float 0.0
# Hang so
float_ten: .float 10.0
float_zero: .float 0.0
float_one: .float 1.0
float_half: .float 0.5
epsilon: .float 0.00001
# Bo dem
buffer: .space 256
temp_float: .float 0.0
# Nhan van ban
filtered_output_label: .asciiz "Filtered output: "
mmse_label: .asciiz "MMSE: "
.text
.globl main
main:
    # Doc tin hieu desired
    la $a0, desired_file
    la $a1, desired_signal
    jal read_signal_file
  
    # Kiem tra doc thanh cong hay khong
    bltz $v0, exit_error
  
    # Doc tin hieu input
    la $a0, input_file
    la $a1, input_signal
    jal read_signal_file
  
    # Kiem tra doc thanh cong hay khong
    bltz $v0, exit_error
  
    # Thiet ke bo loc Wiener
    jal compute_wiener_filter
  
    # Ap dung bo loc
    jal filter_signal
  
    # Tinh MMSE
    jal compute_mmse
  
    # Lam tron ket qua den 1 chu so thap phan
    jal round_results
  
    # In ket qua voi kiem tra kich thuoc
    jal print_results_with_check
  
    # Ghi vao file output voi kiem tra kich thuoc
    jal write_output_file_with_check
  
    # Thoat
    li $v0, 10
    syscall
exit_error:
    # In thong bao loi
    la $a0, error_msg
    li $v0, 4
    syscall
  
    li $v0, 10
    syscall
# ============================================
# In ket qua voi kiem tra kich thuoc
# ============================================
print_results_with_check:
    sub $sp, $sp, 20
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
  
    # Kiem tra output_signal co du 10 phan tu khong
    la $s0, output_signal
    li $s1, 0 # Dem so phan tu
    li $s2, 10 # So phan tu can kiem tra
  
check_count_loop:
    bge $s1, $s2, check_count_done
  
    # Tinh dia chi cua phan tu thu i
    sll $t0, $s1, 2
    add $t1, $s0, $t0
  
    # Kiem tra xem co phai la gia tri mac dinh 0.0 khong
    # Neu doc file khong du so, cac phan tu con lai van la 0.0
    # Nhung cach nay khong chinh xac vi gia tri thuc te co the la 0.0
    # Thay vao do, ta se kiem tra bang cach doc lai file input va desired
  
    addi $s1, $s1, 1
    j check_count_loop
  
check_count_done:
    # Thay vi kiem tra mang output, ta se kiem tra file input va desired
    # bang cach dem so phan tu thuc te doc duoc
  
    # Doc lai file desired de dem so phan tu
    la $a0, desired_file
    la $a1, buffer
    jal read_file_to_buffer
  
    bltz $v0, print_size_error # Loi doc file
  
    # Phan tich va dem so float trong desired.txt
    la $a0, buffer
    jal count_floats_in_string
    move $s0, $v0 # Luu so luong phan tu trong desired.txt
  
    # Doc lai file input de dem so phan tu
    la $a0, input_file
    la $a1, buffer
    jal read_file_to_buffer
  
    bltz $v0, print_size_error # Loi doc file
  
    # Phan tich va dem so float trong input.txt
    la $a0, buffer
    jal count_floats_in_string
    move $s1, $v0 # Luu so luong phan tu trong input.txt
  
    # Kiem tra neu mot trong hai file khong co du 10 phan tu
    li $t0, 10
    bne $s0, $t0, print_size_error
    bne $s1, $t0, print_size_error
  
    # Neu du 10 phan tu, in ket qua binh thuong
    jal print_results_normal
    j print_results_done
  
print_size_error:
    # In thong bao loi kich thuoc
    la $a0, size_error_msg
    li $v0, 4
    syscall
  
print_results_done:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    add $sp, $sp, 20
    jr $ra
# ============================================
# In ket qua binh thuong (khi du 10 phan tu)
# ============================================
print_results_normal:
    sub $sp, $sp, 20
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
  
    # In "Filtered output: "
    la $a0, filtered_output_label
    li $v0, 4
    syscall
  
    # In output_signal
    la $s0, output_signal
    li $s1, 0
print_loop_normal:
    li $t0, 10
    bge $s1, $t0, print_mmse_normal
  
    # Chuyen doi float thanh chuoi
    l.s $f12, 0($s0)
    la $a0, buffer
    jal float_to_string
  
    # In chuoi
    la $a0, buffer
    li $v0, 4
    syscall
  
    # In khoang trang (tru so cuoi)
    addi $s1, $s1, 1
    li $t0, 10
    bge $s1, $t0, print_mmse_normal
  
    la $a0, space
    li $v0, 4
    syscall
  
    addi $s0, $s0, 4
    j print_loop_normal
  
print_mmse_normal:
    # In xuong dong
    la $a0, newline
    li $v0, 4
    syscall
  
    # In "MMSE: "
    la $a0, mmse_label
    li $v0, 4
    syscall
  
    # Chuyen doi MMSE thanh chuoi va in
    l.s $f12, mmse
    la $a0, buffer
    jal float_to_string
  
    la $a0, buffer
    li $v0, 4
    syscall
  
    # In xuong dong
    la $a0, newline
    li $v0, 4
    syscall
  
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    add $sp, $sp, 20
    jr $ra
# ============================================
# Ghi file output voi kiem tra kich thuoc
# ============================================
write_output_file_with_check:
    sub $sp, $sp, 32
    sw $ra, 0($sp)
    sw $s0, 4($sp) # File descriptor
    sw $s1, 8($sp) # So phan tu desired
    sw $s2, 12($sp) # So phan tu input
    sw $s3, 16($sp)
    sw $s4, 20($sp)
    sw $s5, 24($sp)
    sw $s6, 28($sp)
  
    # Kiem tra so phan tu trong file desired va input
    # Doc file desired de dem so phan tu
    la $a0, desired_file
    la $a1, buffer
    jal read_file_to_buffer
  
    bltz $v0, write_size_error # Loi doc file
  
    # Phan tich va dem so float trong desired.txt
    la $a0, buffer
    jal count_floats_in_string
    move $s1, $v0 # Luu so luong phan tu trong desired.txt
  
    # Doc lai file input de dem so phan tu
    la $a0, input_file
    la $a1, buffer
    jal read_file_to_buffer
  
    bltz $v0, write_size_error # Loi doc file
  
    # Phan tich va dem so float trong input.txt
    la $a0, buffer
    jal count_floats_in_string
    move $s2, $v0 # Luu so luong phan tu trong input.txt
  
    # Kiem tra neu mot trong hai file khong co du 10 phan tu
    li $t0, 10
    bne $s1, $t0, write_size_error
    bne $s2, $t0, write_size_error
  
    # Neu du 10 phan tu, ghi ket qua binh thuong
    jal write_output_file_normal
    j write_output_done_with_check
  
write_size_error:
    # Ghi thong bao loi kich thuoc vao file
    # Mo file
    la $a0, output_file
    li $a1, 1 # Che do ghi
    li $v0, 13
    syscall
  
    bltz $v0, write_output_done_with_check # Neu khong mo duoc file, bo qua
    move $s0, $v0 # File descriptor
  
    # Ghi "Error: size not match\n"
    move $a0, $s0
    la $a1, size_error_msg
    li $a2, 21 # Do dai cua "Error: size not match\n"
    li $v0, 15
    syscall
  
    # Dong file
    move $a0, $s0
    li $v0, 16
    syscall
  
    j write_output_done_with_check
write_output_done_with_check:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $s4, 20($sp)
    lw $s5, 24($sp)
    lw $s6, 28($sp)
    add $sp, $sp, 32
    jr $ra
# ============================================
# Ghi ket qua binh thuong vao file (khi du 10 phan tu)
# ============================================
write_output_file_normal:
    sub $sp, $sp, 32
    sw $ra, 0($sp)
    sw $s0, 4($sp) # File descriptor
    sw $s1, 8($sp) # Con tro den output_signal
    sw $s2, 12($sp) # Chi so
    sw $s3, 16($sp) # Tam thoi cho do dai chuoi
    sw $s4, 20($sp) # Con tro bo dem tam thoi
    sw $s5, 24($sp) # Co khoang trang
    sw $s6, 28($sp) # Dia chi bo dem goc
  
    # Mo file
    la $a0, output_file
    li $a1, 1 # Che do ghi
    li $v0, 13
    syscall
  
    bltz $v0, write_normal_done
    move $s0, $v0 # File descriptor
  
    # Ghi "Filtered output: "
    move $a0, $s0
    la $a1, filtered_output_label
    li $a2, 17 # Do dai cua "Filtered output: "
    li $v0, 15
    syscall
  
    # Ghi gia tri output_signal
    la $s1, output_signal
    li $s2, 0 # Chi so
    li $s5, 0 # Co khoang trang (0 = khong co khoang trang truoc so dau tien)
  
write_signal_loop_normal:
    li $t0, 10
    bge $s2, $t0, write_mmse_label_normal
  
    # Neu khong phai so dau tien, ghi khoang trang
    beqz $s5, skip_space_write_normal
    move $a0, $s0
    la $a1, space
    li $a2, 1 # Ghi mot khoang trang
    li $v0, 15
    syscall
  
skip_space_write_normal:
    li $s5, 1 # Dat co de ghi khoang trang cho cac so tiep theo
  
    # Chuyen doi float hien tai thanh chuoi
    l.s $f12, 0($s1)
    la $a0, buffer
    jal float_to_string
    move $s3, $v0 # Luu do dai chuoi
  
    # Ghi chuoi float
    move $a0, $s0
    la $a1, buffer
    move $a2, $s3
    li $v0, 15
    syscall
  
    # Di chuyen den phan tu tiep theo
    addi $s1, $s1, 4
    addi $s2, $s2, 1
    j write_signal_loop_normal
  
write_mmse_label_normal:
    # Ghi xuong dong
    move $a0, $s0
    la $a1, newline
    li $a2, 1
    li $v0, 15
    syscall
  
    # Ghi "MMSE: "
    move $a0, $s0
    la $a1, mmse_label
    li $a2, 6 # Do dai cua "MMSE: "
    li $v0, 15
    syscall
  
    # Chuyen doi MMSE thanh chuoi va ghi
    l.s $f12, mmse
    la $a0, buffer
    jal float_to_string
    move $s3, $v0 # Luu do dai chuoi
  
    move $a0, $s0
    la $a1, buffer
    move $a2, $s3
    li $v0, 15
    syscall
  
    # Ghi xuong dong cuoi cung
    move $a0, $s0
    la $a1, newline
    li $a2, 1
    li $v0, 15
    syscall
  
    # Dong file
    move $a0, $s0
    li $v0, 16
    syscall
  
write_normal_done:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $s4, 20($sp)
    lw $s5, 24($sp)
    lw $s6, 28($sp)
    add $sp, $sp, 32
    jr $ra
# ============================================
# Doc file vao buffer
# $a0: ten file
# $a1: buffer
# Tra ve: 1 neu thanh cong, -1 neu loi
# ============================================
read_file_to_buffer:
    sub $sp, $sp, 16
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    sw $s0, 12($sp)
  
    # Mo file
    lw $a0, 4($sp)
    li $a1, 0 # Che do doc
    li $v0, 13
    syscall
  
    bltz $v0, read_file_error
    move $s0, $v0 # File descriptor
  
    # Doc file
    move $a0, $s0
    lw $a1, 8($sp) # Buffer
    li $a2, 255
    li $v0, 14
    syscall
  
    # Dong file
    move $a0, $s0
    li $v0, 16
    syscall
  
    # Thanh cong
    li $v0, 1
    j read_file_done
  
read_file_error:
    li $v0, -1
  
read_file_done:
    lw $ra, 0($sp)
    lw $s0, 12($sp)
    add $sp, $sp, 16
    jr $ra
# ============================================
# Dem so float trong chuoi
# $a0: buffer chuoi
# Tra ve: $v0 = so luong float
# ============================================
count_floats_in_string:
    sub $sp, $sp, 16
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $s0, 8($sp)
    sw $s1, 12($sp)
  
    move $s0, $a0 # Con tro chuoi
    li $s1, 0 # Bo dem
  
count_loop:
    lb $t0, 0($s0)
    beqz $t0, count_done # Ket thuc chuoi
  
    # Bo qua khoang trang
    li $t1, ' '
    beq $t0, $t1, count_skip
    li $t1, '\n'
    beq $t0, $t1, count_skip
    li $t1, '\r'
    beq $t0, $t1, count_skip
    li $t1, '\t'
    beq $t0, $t1, count_skip
  
    # Tim thay bat dau cua mot so
    addi $s1, $s1, 1
  
    # Bo qua den cuoi so hien tai
count_skip_number:
    lb $t0, 0($s0)
    beqz $t0, count_done
    li $t1, ' '
    beq $t0, $t1, count_next
    li $t1, '\n'
    beq $t0, $t1, count_next
    li $t1, '\r'
    beq $t0, $t1, count_next
    li $t1, '\t'
    beq $t0, $t1, count_next
    addi $s0, $s0, 1
    j count_skip_number
  
count_next:
    addi $s0, $s0, 1
    j count_loop
  
count_skip:
    addi $s0, $s0, 1
    j count_loop
  
count_done:
    move $v0, $s1
    lw $ra, 0($sp)
    lw $s0, 8($sp)
    lw $s1, 12($sp)
    add $sp, $sp, 16
    jr $ra
# ============================================
# Doc tin hieu tu file (ham goc)
# $a0: ten file
# $a1: buffer de luu cac float
# Tra ve: 1 neu thanh cong, -1 neu loi
# ============================================
read_signal_file:
    sub $sp, $sp, 20
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    sw $s0, 12($sp)
    sw $s1, 16($sp)
  
    # Mo file
    lw $a0, 4($sp)
    li $a1, 0 # Che do doc
    li $v0, 13
    syscall
  
    bltz $v0, read_error
    move $s0, $v0 # File descriptor
  
    # Doc file
    move $a0, $s0
    la $a1, buffer
    li $a2, 255
    li $v0, 14
    syscall
  
    # Dong file
    move $a0, $s0
    li $v0, 16
    syscall
  
    # Phan tich cac float
    la $a0, buffer
    lw $a1, 8($sp)
    jal parse_floats
  
    # Thanh cong
    li $v0, 1
    j read_done
  
read_error:
    li $v0, -1
  
read_done:
    lw $ra, 0($sp)
    lw $s0, 12($sp)
    lw $s1, 16($sp)
    add $sp, $sp, 20
    jr $ra
# ============================================
# Phan tich cac float cach nhau boi khoang trang (ham goc)
# $a0: buffer chuoi
# $a1: mang float de luu
# ============================================
parse_floats:
    sub $sp, $sp, 16
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    sw $s0, 12($sp)
  
    move $s0, $a0 # Con tro chuoi
    lw $a1, 8($sp) # Mang float
  
parse_loop:
    # Bo qua khoang trang
    lb $t0, 0($s0)
    beqz $t0, parse_done
    li $t1, ' '
    beq $t0, $t1, skip_char
    li $t1, '\n'
    beq $t0, $t1, parse_done
    li $t1, '\r'
    beq $t0, $t1, parse_done
  
    # Phan tich float
    move $a0, $s0
    jal atof
    s.s $f0, 0($a1)
    addi $a1, $a1, 4
    move $s0, $v0
    j parse_loop
  
skip_char:
    addi $s0, $s0, 1
    j parse_loop
  
parse_done:
    lw $ra, 0($sp)
    lw $s0, 12($sp)
    add $sp, $sp, 16
    jr $ra
# ============================================
# Chuyen doi chuoi sang float
# $a0: con tro chuoi
# Tra ve: $f0 = float, $v0 = con tro moi
# ============================================
atof:
    sub $sp, $sp, 20
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
  
    move $s0, $a0
    li $s1, 0 # Dau
    li $s2, 0 # Phan nguyen
    li $s3, 0 # So chu so thap phan
  
    # Kiem tra dau
    lb $t0, 0($s0)
    bne $t0, '-', positive
    li $s1, 1
    addi $s0, $s0, 1
  
positive:
    # Phan tich phan nguyen
int_loop:
    lb $t0, 0($s0)
    blt $t0, '0', check_decimal
    bgt $t0, '9', check_decimal
    sub $t0, $t0, '0'
    mul $s2, $s2, 10
    add $s2, $s2, $t0
    addi $s0, $s0, 1
    j int_loop
  
check_decimal:
    bne $t0, '.', convert
    addi $s0, $s0, 1
  
    # Phan tich phan thap phan
decimal_loop:
    lb $t0, 0($s0)
    blt $t0, '0', convert
    bgt $t0, '9', convert
    sub $t0, $t0, '0'
    mul $s2, $s2, 10
    add $s2, $s2, $t0
    addi $s3, $s3, 1
    addi $s0, $s0, 1
    j decimal_loop
  
convert:
    # Chuyen doi thanh float
    mtc1 $s2, $f0
    cvt.s.w $f0, $f0
  
    # Chia cho 10^s3
    beqz $s3, apply_sign
    li $t0, 10
    mtc1 $t0, $f1
    cvt.s.w $f1, $f1
    move $t0, $s3
div_loop_atof:
    blez $t0, apply_sign
    div.s $f0, $f0, $f1
    addi $t0, $t0, -1
    j div_loop_atof
  
apply_sign:
    beqz $s1, atof_done
    neg.s $f0, $f0
  
atof_done:
    move $v0, $s0
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    add $sp, $sp, 20
    jr $ra
# ============================================
# Gia tri tuyet doi cho float
# $f12: dau vao
# Tra ve: $f0 = |$f12|
# ============================================
my_fabs:
    l.s $f0, float_zero
    c.lt.s $f12, $f0
    bc1f fabs_done
    neg.s $f0, $f12
    jr $ra
fabs_done:
    mov.s $f0, $f12
    jr $ra
# ============================================
# Ham floor cho float
# $f12: dau vao
# Tra ve: $f0 = floor($f12)
# ============================================
my_floor:
    sub $sp, $sp, 4
    sw $ra, 0($sp)
  
    # Lay phan nguyen
    cvt.w.s $f0, $f12
    mfc1 $t0, $f0
    mtc1 $t0, $f0
    cvt.s.w $f0, $f0
  
    # Lay phan thap phan
    sub.s $f1, $f12, $f0
  
    l.s $f2, float_zero
    c.lt.s $f12, $f2
    bc1f floor_positive
  
    # So am
    l.s $f2, float_zero
    c.eq.s $f1, $f2
    bc1t floor_done
    l.s $f2, float_one
    sub.s $f0, $f0, $f2
    j floor_done
  
floor_positive:
    # So duong
    mov.s $f0, $f0
  
floor_done:
    lw $ra, 0($sp)
    add $sp, $sp, 4
    jr $ra
# ============================================
# Ham ceil cho float
# $f12: dau vao
# Tra ve: $f0 = ceil($f12)
# ============================================
my_ceil:
    sub $sp, $sp, 4
    sw $ra, 0($sp)
  
    # Lay phan nguyen
    cvt.w.s $f0, $f12
    mfc1 $t0, $f0
    mtc1 $t0, $f0
    cvt.s.w $f0, $f0
  
    # Lay phan thap phan
    sub.s $f1, $f12, $f0
  
    l.s $f2, float_zero
    c.le.s $f12, $f2
    bc1t ceil_done
  
    # So duong co phan thap phan
    l.s $f2, float_zero
    c.eq.s $f1, $f2
    bc1t ceil_done
    l.s $f2, float_one
    add.s $f0, $f0, $f2
  
ceil_done:
    lw $ra, 0($sp)
    add $sp, $sp, 4
    jr $ra
# ============================================
# Tuong quan cheo
# $a0: mang x
# $a1: mang y
# $a2: lag
# Tra ve: $f0 = tuong quan
# ============================================
cross_correlation:
    sub $sp, $sp, 28
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    sw $a2, 12($sp)
    sw $s0, 16($sp)
    sw $s1, 20($sp)
    sw $s2, 24($sp)
  
    l.s $f0, float_zero # tong
    li $s0, 0 # i
  
    lw $a0, 4($sp) # x
    lw $a1, 8($sp) # y
    lw $a2, 12($sp) # lag
  
corr_loop:
    li $t0, 10
    bge $s0, $t0, corr_done
  
    # j = i - lag
    sub $s1, $s0, $a2
  
    # Kiem tra gioi han: 0 <= j < 10
    bltz $s1, corr_next_i
    li $t0, 10
    bge $s1, $t0, corr_next_i
  
    # x[i] * y[j]
    sll $t0, $s0, 2
    add $t0, $a0, $t0
    l.s $f1, 0($t0)
  
    sll $t1, $s1, 2
    add $t1, $a1, $t1
    l.s $f2, 0($t1)
  
    mul.s $f3, $f1, $f2
    add.s $f0, $f0, $f3
  
corr_next_i:
    addi $s0, $s0, 1
    j corr_loop
  
corr_done:
    # Chia cho N
    l.s $f4, float_ten
    div.s $f0, $f0, $f4
  
    lw $ra, 0($sp)
    lw $s0, 16($sp)
    lw $s1, 20($sp)
    lw $s2, 24($sp)
    add $sp, $sp, 28
    jr $ra
# ============================================
# Tu tuong quan
# $a0: mang x
# $a1: lag
# Tra ve: $f0 = tu tuong quan
# ============================================
auto_correlation:
    move $a1, $a0
    j cross_correlation
# ============================================
# Giai he phuong trinh tuyen tinh dung phuong phap Gauss
# $a0: ma tran A (10x10)
# $a1: vector b (10)
# $a2: vector h (10) - dau ra
# ============================================
solve_linear_system:
    sub $sp, $sp, 56
    sw $ra, 0($sp)
    sw $a0, 4($sp) # A
    sw $a1, 8($sp) # b
    sw $a2, 12($sp) # h
    sw $s0, 16($sp) # i
    sw $s1, 20($sp) # j
    sw $s2, 24($sp) # k
    sw $s3, 28($sp) # maxRow
    sw $s4, 32($sp) # tam thoi
    sw $s5, 36($sp) # factor
    sw $s6, 40($sp) # pivot
    sw $s7, 44($sp) # A[i]
    sw $t8, 48($sp)
    sw $t9, 52($sp)
  
    lw $s7, 4($sp) # A
    lw $t8, 8($sp) # b
    lw $t9, 12($sp) # h
  
    # Khu Gauss
    li $s0, 0 # i = 0
  
gauss_outer:
    li $t0, 10
    bge $s0, $t0, gauss_done
  
    # Tim hang pivot
    move $s3, $s0 # maxRow = i
  
    move $s1, $s0
    addi $s1, $s1, 1 # k = i+1
find_pivot:
    li $t0, 10
    bge $s1, $t0, pivot_found
  
    # Lay A[k][i]
    li $t0, 40 # 10*4
    mul $t1, $s1, $t0
    add $t1, $s7, $t1
    sll $t2, $s0, 2
    add $t1, $t1, $t2
    l.s $f0, 0($t1)
  
    # Lay A[maxRow][i]
    li $t0, 40
    mul $t1, $s3, $t0
    add $t1, $s7, $t1
    sll $t2, $s0, 2
    add $t1, $t1, $t2
    l.s $f1, 0($t1)
  
    # |A[k][i]| > |A[maxRow][i]| ?
    mov.s $f12, $f0
    jal my_fabs
    mov.s $f2, $f0
    mov.s $f12, $f1
    jal my_fabs
    c.lt.s $f0, $f2
    bc1f solve_next_k
    move $s3, $s1
  
solve_next_k:
    addi $s1, $s1, 1
    j find_pivot
  
pivot_found:
    # Doi hang neu can
    beq $s3, $s0, no_swap
  
    # Doi A[i] va A[maxRow]
    li $t0, 40
    mul $t1, $s0, $t0
    add $t1, $s7, $t1 # A[i]
    mul $t2, $s3, $t0
    add $t2, $s7, $t2 # A[maxRow]
  
    li $s1, 0 # j = 0
swap_loop:
    li $t0, 10
    bge $s1, $t0, swap_b
  
    sll $t3, $s1, 2
    add $t4, $t1, $t3
    add $t5, $t2, $t3
  
    l.s $f0, 0($t4)
    l.s $f1, 0($t5)
    s.s $f1, 0($t4)
    s.s $f0, 0($t5)
  
    addi $s1, $s1, 1
    j swap_loop
  
swap_b:
    # Doi b[i] va b[maxRow]
    sll $t1, $s0, 2
    add $t1, $t8, $t1
    sll $t2, $s3, 2
    add $t2, $t8, $t2
  
    l.s $f0, 0($t1)
    l.s $f1, 0($t2)
    s.s $f1, 0($t1)
    s.s $f0, 0($t2)
  
no_swap:
    # Chuan hoa hang i
    li $t0, 40
    mul $t1, $s0, $t0
    add $t1, $s7, $t1 # A[i]
    sll $t2, $s0, 2
    add $t1, $t1, $t2 # &A[i][i]
    l.s $f6, 0($t1) # pivot
  
    # Kiem tra neu pivot gan bang 0
    mov.s $f12, $f6
    jal my_fabs
    l.s $f1, epsilon
    c.lt.s $f0, $f1
    bc1t skip_row_solve
  
    # Chuan hoa A[i][j] cho j >= i
    move $s1, $s0 # j = i
normalize_a:
    li $t0, 10
    bge $s1, $t0, normalize_b
  
    sll $t2, $s1, 2
    add $t3, $t1, $t2
    sub $t3, $t3, $s0
    sub $t3, $t3, $s0
    sub $t3, $t3, $s0
    sub $t3, $t3, $s0 # &A[i][j]
  
    l.s $f0, 0($t3)
    div.s $f0, $f0, $f6
    s.s $f0, 0($t3)
  
    addi $s1, $s1, 1
    j normalize_a
  
normalize_b:
    # Chuan hoa b[i]
    sll $t1, $s0, 2
    add $t1, $t8, $t1
    l.s $f0, 0($t1)
    div.s $f0, $f0, $f6
    s.s $f0, 0($t1)
  
    # Khu cac hang khac
    li $s2, 0 # k = 0
eliminate:
    li $t0, 10
    bge $s2, $t0, solve_next_i
  
    beq $s2, $s0, solve_next_row
  
    # Lay factor = A[k][i]
    li $t0, 40
    mul $t1, $s2, $t0
    add $t1, $s7, $t1
    sll $t2, $s0, 2
    add $t1, $t1, $t2
    l.s $f5, 0($t1) # factor
  
    # Kiem tra neu factor gan bang 0
    mov.s $f12, $f5
    jal my_fabs
    l.s $f1, epsilon
    c.lt.s $f0, $f1
    bc1t solve_next_row
  
    # Khu A[k][j] cho j >= i
    move $s1, $s0 # j = i
eliminate_a:
    li $t0, 10
    bge $s1, $t0, eliminate_b
  
    # A[k][j] -= factor * A[i][j]
    li $t0, 40
    mul $t1, $s2, $t0
    add $t1, $s7, $t1
    sll $t2, $s1, 2
    add $t4, $t1, $t2 # &A[k][j]
  
    li $t0, 40
    mul $t1, $s0, $t0
    add $t1, $s7, $t1
    add $t5, $t1, $t2 # &A[i][j]
  
    l.s $f0, 0($t4)
    l.s $f1, 0($t5)
    mul.s $f2, $f5, $f1
    sub.s $f0, $f0, $f2
    s.s $f0, 0($t4)
  
    addi $s1, $s1, 1
    j eliminate_a
  
eliminate_b:
    # b[k] -= factor * b[i]
    sll $t1, $s2, 2
    add $t1, $t8, $t1 # &b[k]
    sll $t2, $s0, 2
    add $t2, $t8, $t2 # &b[i]
  
    l.s $f0, 0($t1)
    l.s $f1, 0($t2)
    mul.s $f2, $f5, $f1
    sub.s $f0, $f0, $f2
    s.s $f0, 0($t1)
  
solve_next_row:
    addi $s2, $s2, 1
    j eliminate
  
skip_row_solve:
solve_next_i:
    addi $s0, $s0, 1
    j gauss_outer
  
gauss_done:
    # Sao chep nghiem vao h
    li $s0, 0
copy_solution:
    li $t0, 10
    bge $s0, $t0, solve_done
  
    sll $t1, $s0, 2
    add $t2, $t8, $t1 # &b[i]
    add $t3, $t9, $t1 # &h[i]
  
    l.s $f0, 0($t2)
    s.s $f0, 0($t3)
  
    addi $s0, $s0, 1
    j copy_solution
  
solve_done:
    lw $ra, 0($sp)
    lw $s0, 16($sp)
    lw $s1, 20($sp)
    lw $s2, 24($sp)
    lw $s3, 28($sp)
    lw $s4, 32($sp)
    lw $s5, 36($sp)
    lw $s6, 40($sp)
    lw $s7, 44($sp)
    lw $t8, 48($sp)
    lw $t9, 52($sp)
    add $sp, $sp, 56
    jr $ra
# ============================================
# Tinh he so bo loc Wiener
# Su dung: desired_signal, input_signal
# Dau ra: optimize_coefficient
# ============================================
compute_wiener_filter:
    sub $sp, $sp, 44
    sw $ra, 0($sp)
    sw $s0, 4($sp) # i
    sw $s1, 8($sp) # j
    sw $s2, 12($sp) # l
    sw $s3, 16($sp) # Con tro ma tran R
    sw $s4, 20($sp) # Con tro gamma_d
    sw $s5, 24($sp) # Con tro h
    sw $s6, 28($sp) # Tam thoi
    sw $s7, 32($sp)
    sw $t8, 36($sp)
    sw $t9, 40($sp)
  
    # Cap phat bo nho cho ma tran R (10x10) va gamma_d (10)
    li $v0, 9 # sbrk
    li $a0, 440 # 10*10*4 + 10*4 = 400 + 40 = 440
    syscall
  
    move $s3, $v0 # Ma tran R
    addi $s4, $v0, 400 # gamma_d (sau R)
    la $s5, optimize_coefficient # h
  
    # Xay dung ma tran R
    li $s0, 0 # i = 0
build_R_i:
    li $t0, 10
    bge $s0, $t0, build_gamma
  
    li $s1, 0 # j = 0
build_R_j:
    li $t0, 10
    bge $s1, $t0, wiener_next_R_i
  
    # Tinh i-j
    sub $a2, $s0, $s1
  
    # Goi auto_correlation
    la $a0, input_signal
    move $a1, $a2
    jal auto_correlation
  
    # Luu vao R[i][j]
    li $t0, 40 # 10*4
    mul $t1, $s0, $t0
    add $t1, $s3, $t1
    sll $t2, $s1, 2
    add $t1, $t1, $t2
    s.s $f0, 0($t1)
  
    addi $s1, $s1, 1
    j build_R_j
  
wiener_next_R_i:
    addi $s0, $s0, 1
    j build_R_i
  
build_gamma:
    # Xay dung vector gamma_d
    li $s2, 0 # l = 0
build_gamma_loop:
    li $t0, 10
    bge $s2, $t0, solve_system_wiener
  
    # Goi cross_correlation
    la $a0, desired_signal
    la $a1, input_signal
    move $a2, $s2
    jal cross_correlation
  
    # Luu vao gamma_d[l]
    sll $t1, $s2, 2
    add $t1, $s4, $t1
    s.s $f0, 0($t1)
  
    addi $s2, $s2, 1
    j build_gamma_loop
  
solve_system_wiener:
    # Giai R * h = gamma_d
    move $a0, $s3 # R
    move $a1, $s4 # gamma_d
    move $a2, $s5 # h
    jal solve_linear_system
  
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $s4, 20($sp)
    lw $s5, 24($sp)
    lw $s6, 28($sp)
    lw $s7, 32($sp)
    lw $t8, 36($sp)
    lw $t9, 40($sp)
    add $sp, $sp, 44
    jr $ra
# ============================================
# Ap dung bo loc cho tin hieu input
# Su dung: input_signal, optimize_coefficient
# Dau ra: output_signal
# ============================================
filter_signal:
    sub $sp, $sp, 24
    sw $ra, 0($sp)
    sw $s0, 4($sp) # n
    sw $s1, 8($sp) # k
    sw $s2, 12($sp) # con tro input
    sw $s3, 16($sp) # con tro output
    sw $s4, 20($sp) # con tro coeff
  
    la $s2, input_signal
    la $s3, output_signal
    la $s4, optimize_coefficient
  
    li $s0, 0 # n = 0
filter_n:
    li $t0, 10
    bge $s0, $t0, filter_done
  
    l.s $f0, float_zero # output[n] = 0
  
    li $s1, 0 # k = 0
filter_k:
    li $t0, 10
    bge $s1, $t0, store_output
  
    # Kiem tra neu n-k >= 0
    sub $t1, $s0, $s1
    bltz $t1, filter_next_k
  
    # h[k] * input[n-k]
    sll $t2, $s1, 2
    add $t2, $s4, $t2
    l.s $f1, 0($t2) # h[k]
  
    sll $t2, $t1, 2
    add $t2, $s2, $t2
    l.s $f2, 0($t2) # input[n-k]
  
    mul.s $f3, $f1, $f2
    add.s $f0, $f0, $f3
  
filter_next_k:
    addi $s1, $s1, 1
    j filter_k
  
store_output:
    sll $t1, $s0, 2
    add $t1, $s3, $t1
    s.s $f0, 0($t1)
  
    addi $s0, $s0, 1
    j filter_n
  
filter_done:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $s4, 20($sp)
    add $sp, $sp, 24
    jr $ra
# ============================================
# Tinh MMSE
# Su dung: desired_signal, output_signal
# Dau ra: mmse
# ============================================
compute_mmse:
    sub $sp, $sp, 20
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
  
    la $s0, desired_signal
    la $s1, output_signal
    la $s2, mmse
  
    l.s $f4, float_zero # mse = 0
    li $s3, 0 # i = 0
  
mmse_loop:
    li $t0, 10
    bge $s3, $t0, mmse_done
  
    # sai so = desired[i] - output[i]
    sll $t1, $s3, 2
    add $t2, $s0, $t1
    l.s $f0, 0($t2)
    add $t2, $s1, $t1
    l.s $f1, 0($t2)
    sub.s $f2, $f0, $f1
  
    # mse += sai so * sai so
    mul.s $f3, $f2, $f2
    add.s $f4, $f4, $f3
  
    addi $s3, $s3, 1
    j mmse_loop
  
mmse_done:
    # mse / N
    l.s $f5, float_ten
    div.s $f4, $f4, $f5
  
    s.s $f4, 0($s2)
  
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    add $sp, $sp, 20
    jr $ra
# ============================================
# Lam tron den 1 chu so thap phan
# ============================================
round_results:
    sub $sp, $sp, 16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
  
    # Lam tron output_signal
    la $s0, output_signal
    li $s1, 0
round_output:
    li $t0, 10
    bge $s1, $t0, round_mmse
  
    l.s $f12, 0($s0)
    jal round_one_decimal
    s.s $f0, 0($s0)
  
    addi $s0, $s0, 4
    addi $s1, $s1, 1
    j round_output
  
round_mmse:
    # Lam tron mmse
    la $s0, mmse
    l.s $f12, 0($s0)
    jal round_one_decimal
    s.s $f0, 0($s0)
  
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    add $sp, $sp, 16
    jr $ra
# ============================================
# Lam tron den 1 chu so thap phan
# $f12: dau vao
# Tra ve: $f0 = gia tri da lam tron
# ============================================
round_one_decimal:
    sub $sp, $sp, 4
    sw $ra, 0($sp)
  
    l.s $f0, float_zero
    c.lt.s $f12, $f0
    bc1f round_positive
  
    # So am
    l.s $f1, float_ten
    mul.s $f0, $f12, $f1
    l.s $f2, float_half
    sub.s $f0, $f0, $f2
    mov.s $f12, $f0
    jal my_ceil
    l.s $f1, float_ten
    div.s $f0, $f0, $f1
    j round_done
  
round_positive:
    # So duong
    l.s $f1, float_ten
    mul.s $f0, $f12, $f1
    l.s $f2, float_half
    add.s $f0, $f0, $f2
    mov.s $f12, $f0
    jal my_floor
    l.s $f1, float_ten
    div.s $f0, $f0, $f1
  
round_done:
    lw $ra, 0($sp)
    add $sp, $sp, 4
    jr $ra
# ============================================
# Chuyen doi float thanh chuoi voi 1 chu so thap phan
# $f12: gia tri float
# $a0: dia chi buffer
# Tra ve: do dai trong $v0
# ============================================
float_to_string:
    sub $sp, $sp, 32
    sw $ra, 0($sp)
    sw $a0, 4($sp) # Luu dia chi buffer
    s.s $f12, 8($sp) # Luu gia tri float
    sw $s0, 12($sp) # Con tro buffer
    sw $s1, 16($sp) # Phan nguyen
    sw $s2, 20($sp) # Phan thap phan
    sw $s3, 24($sp) # Co dau
    sw $s4, 28($sp) # Tam thoi
  
    move $s0, $a0 # Con tro buffer
    l.s $f12, 8($sp) # Tai lai float
  
    # Kiem tra neu gia tri la am
    l.s $f0, float_zero
    c.lt.s $f12, $f0
    bc1f fts_positive
  
    # So am: ghi dau tru
    li $t0, '-'
    sb $t0, 0($s0)
    addi $s0, $s0, 1
    li $s3, 1 # Dat co dau
    neg.s $f12, $f12 # Lam duong de xu ly
    j fts_process
  
fts_positive:
    li $s3, 0 # Xoa co dau
  
fts_process:
    # Dau tien, lam tron den 1 chu so thap phan
    jal round_one_decimal
    mov.s $f12, $f0
  
    # Nhan voi 10 de lay bieu dien nguyen voi 1 chu so thap phan
    l.s $f1, float_ten
    mul.s $f0, $f12, $f1
  
    # Chuyen doi thanh nguyen (gio chua gia tri * 10)
    cvt.w.s $f0, $f0
    mfc1 $t0, $f0 # $t0 = gia tri nguyen (gia tri * 10)
  
    # Xu ly truong hop zero am (neu gia tri am va lam tron thanh 0)
    bnez $t0, not_zero
    beqz $s3, not_zero # Neu duong, chi ghi 0.0
  
    # Neu am va gia tri la 0, chung ta muon -0.0
    li $t0, 0 # Giu la 0
  
not_zero:
    # Tach phan nguyen va phan thap phan
    # Phan nguyen = gia tri * 10 / 10
    # Phan thap phan = gia tri * 10 % 10
    li $t1, 10
    div $t0, $t1
    mflo $s1 # Phan nguyen
    mfhi $s2 # Phan thap phan
  
    # Dam bao phan thap phan la duong
    bgez $s2, decimal_positive
    neg $s2, $s2 # Lay gia tri tuyet doi
  
decimal_positive:
    # Chuyen doi phan nguyen thanh chuoi
    move $a0, $s1
    move $a1, $s0
    jal int_to_string
    add $s0, $s0, $v0 # Di chuyen con tro buffer
  
    # Them dau cham thap phan
    li $t0, '.'
    sb $t0, 0($s0)
    addi $s0, $s0, 1
  
    # Them chu so thap phan
    addi $t0, $s2, '0'
    sb $t0, 0($s0)
    addi $s0, $s0, 1
  
    # Them 3 so 0
    li $t0, '0'
    sb $t0, 0($s0)
    addi $s0, $s0, 1
    sb $t0, 0($s0)
    addi $s0, $s0, 1
    sb $t0, 0($s0)
    addi $s0, $s0, 1
  
    # Them null terminator
    sb $zero, 0($s0)
  
    # Tinh tong do dai
    lw $t0, 4($sp) # Dia chi buffer goc
    sub $v0, $s0, $t0
  
    lw $ra, 0($sp)
    lw $s0, 12($sp)
    lw $s1, 16($sp)
    lw $s2, 20($sp)
    lw $s3, 24($sp)
    lw $s4, 28($sp)
    add $sp, $sp, 32
    jr $ra
# ============================================
# Chuyen doi nguyen thanh chuoi
# $a0: so nguyen
# $a1: dia chi buffer
# Tra ve: do dai trong $v0
# ============================================
int_to_string:
    move $t0, $a0 # Gia tri nguyen
    move $t1, $a1 # Dia chi buffer
  
    # Xu ly truong hop dac biet: 0
    bnez $t0, not_zero_int
    li $t2, '0'
    sb $t2, 0($t1)
    li $v0, 1
    jr $ra
  
not_zero_int:
    # Kiem tra neu am
    li $t3, 0 # Co am
    bgez $t0, positive_int
    li $t3, 1
    neg $t0, $t0
  
positive_int:
    # Day cac chu so vao stack
    li $t4, 10
    li $t5, 0 # So chu so
  
push_digits_int:
    div $t0, $t4
    mfhi $t6 # Phan du (chu so)
    addi $t6, $t6, '0'
    sub $sp, $sp, 1
    sb $t6, 0($sp)
    addi $t5, $t5, 1
    mflo $t0 # Thuong
    bnez $t0, push_digits_int
  
    # Them dau tru neu can
    beqz $t3, pop_digits_int
    li $t6, '-'
    sb $t6, 0($t1)
    addi $t1, $t1, 1
  
pop_digits_int:
    # Lay cac chu so tu stack
    move $v0, $t5
    add $v0, $v0, $t3 # Them 1 cho dau tru neu am
  
pop_loop_int:
    blez $t5, done_int
    lb $t6, 0($sp)
    sb $t6, 0($t1)
    addi $sp, $sp, 1
    addi $t1, $t1, 1
    addi $t5, $t5, -1
    j pop_loop_int
  
done_int:
    sb $zero, 0($t1)
    jr $ra