
.data
cArray:      .asciiz "Computer Architecture 2022"  # Chuỗi 26 ký tự + 1 byte null
str_original: .asciiz "Chuoi goc:    "
str_reversed: .asciiz "Chuoi dao nguoc: "
str_newline: .asciiz "\n"


.text
.globl main


main:
    # In chuỗi gốc
    li   $v0, 4             # syscall code for print_string
    la   $a0, str_original
    syscall
    
    li   $v0, 4
    la   $a0, cArray        # In nội dung của cArray
    syscall
    
    li   $v0, 4
    la   $a0, str_newline
    syscall

    #--- Chuẩn bị và gọi thủ tục 'reverse' ---
    # 1. Nạp tham số
    la   $a0, cArray        # Tham số 1: Địa chỉ của cArray
    li   $a1, 26            # Tham số 2: Kích thước cArray_size
    
    # 2. Gọi thủ tục (theo yêu cầu của đề bài)
    jal  reverse
    #-------------------------------------------

    # In chuỗi đã đảo ngược
    li   $v0, 4
    la   $a0, str_reversed
    syscall
    
    li   $v0, 4
    la   $a0, cArray        # In lại cArray (bây giờ đã bị thay đổi)
    syscall

    # Kết thúc chương trình
    li   $v0, 10            # syscall code for exit
    syscall

reverse:
   
    srl  $t1, $a1, 1        
    
    # Khởi tạo i: i = 0
    li   $t0, 0             # $t0 (i) = 0

for_loop:
    #--- Điều kiện lặp ---
    # if (i >= cArray_size / 2) thì thoát
    bge  $t0, $t1, exit_loop
    
    #--- Thân vòng lặp ---
    
    # 1. Lấy địa chỉ bên trái: &cArray[i]
    add  $t2, $a0, $t0      # $t2 = $a0 (base) + $t0 (i)
    
    # 2. Lấy giá trị bên trái: temp = cArray[i]
    lb   $t4, 0($t2)        # $t4 (temp) = load byte tại địa chỉ $t2
    
    # 3. Tính chỉ số bên phải: cArray_size - 1 - i
    sub  $t3, $a1, $t0      # $t3 = $a1 - $t0 (size - i)
    addi $t3, $t3, -1       # $t3 = (size - i) - 1
    
    # 4. Lấy địa chỉ bên phải: &cArray[cArray_size - 1 - i]
    add  $t3, $a0, $t3      # $t3 = $a0 (base) + $t3 (chỉ số phải)

    # 5. Lấy giá trị bên phải:
    lb   $t5, 0($t3)        # $t5 = load byte tại địa chỉ $t3
    
    # 6. Gán cArray[i] = cArray[cArray_size - 1 - i]
    sb   $t5, 0($t2)        # store byte $t5 vào địa chỉ $t2
    
    # 7. Gán cArray[cArray_size - 1 - i] = temp
    sb   $t4, 0($t3)        # store byte $t4 (temp) vào địa chỉ $t3
    
    #--- Bước nhảy ---
    # i++
    addi $t0, $t0, 1        # $t0 = $t0 + 1
    
    # Quay lại đầu vòng lặp
    j    for_loop

exit_loop:
    # Trở về từ thủ tục (theo yêu cầu của đề bài)
    jr   $ra