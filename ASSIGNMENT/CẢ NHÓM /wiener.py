#cấu hình
M = 3 #TODO: độ dài bộ lọc,có thể thay đổi (lấy bao nhiêu nhỉ)
N = 5 #TODO: số mẫu tín hiệu đầu vào,được cố định (sửa thành 500 giúp tui)
input_path = 'input.txt'  #đường dẫn file tín hiệu đầu vào
desired_path = 'desired.txt'  #đường dẫn file tín hiệu mong muốn đầu ra
output_path = 'output.txt'  #đường dẫn file tín hiệu đầu ra
desired_signal = '' #tín hiệu mong muốn đầu ra
d = [] #mảng lưu trữ tín hiệu mong muốn đầu ra
noise = '' #nhiễu
input_signal = '' #tín hiệu đầu vào
x = [] #mảng lưu trữ tín hiệu đầu vào
optimize_coefficient = '' #hệ số tối ưu bộ lọc
MMSE = 0 #lưu trữ giá trị MMSE
out = '' #tín hiệu đầu ra
#mở file
with open('input.txt', 'r') as file:
    for line in file:
        line = line.strip() #loại bỏ ký tự xuống dòng và khoảng trắng
        input_signal += line + ' '
        x.append(float(line))
    input_signal = input_signal.strip()


with open('desired.txt', 'r') as file:
    for line in file:
        line = line.strip() #loại bỏ ký tự xuống dòng và khoảng trắng
        desired_signal += line + ' '
        d.append(float(line))
    desired_signal = desired_signal.strip()
    
#nếu độ dài không thích hợp
if len(x) != len(d) or len(x) != N:
    with open('output.txt', 'w') as file:
        file.write('Error: size not match\n')
        #thoát chương trình
    exit()
#tính r_xx
r_xx = []
for k in range(M):
    s = 0.0
    for n in range(k, N):
        s += x[n] * x[n - k]
    r_xx.append(s / N)
#tinh r_dx
r_dx = []
for k in range(M):
    s = 0.0
    for n in range(k, N):
        s += d[n] * x[n - k]
    r_dx.append(s / N)
#ma tran Toeplitz R MxM
R = []
for i in range(M):
    row = []
    for j in range(M):
        row.append(r_xx[abs(i - j)])
    R.append(row)
# co the can them regularize de tranh ma tran ki di
R[0][0] += 1e-8
#giai he Rh = r_dx dung thuat toan Gauss elimination
A = [row[:] for row in R]  #sao chep ma tran R
b = r_dx[:]  #sao chep vector r_dx
m = M

#khử gauss
for k in range(m):
    #pivot
    pivot = k
    max_val = abs(A[k][k])
    for i in range(k + 1, m):
        if abs(A[i][k]) > max_val:
            max_val = abs(A[i][k])
            pivot = i
    if max_val == 0.0:
        #loi ma tran co hang bang 0
        raise ValueError("Matrix is singular.")
    if pivot != k:
        #hoan vi hang
        A[k], A[pivot] = A[pivot], A[k]
        b[k], b[pivot] = b[pivot], b[k]
    #khu gauss
    for i in range(k + 1, m):
        factor = A[i][k] / A[k][k]
        for j in range(k, m):
            A[i][j] -= factor * A[k][j]
        b[i] -= factor * b[k]
#thay the nguoc
h = [0.0] * m
for i in range(m - 1, -1, -1):
    sum_ax = 0.0
    for j in range(i + 1, m):
        sum_ax += A[i][j] * h[j]
    h[i] = (b[i] - sum_ax) / A[i][i]

#tinh y[n]
y = []
for n in range(N):
    yn = 0.0
    for k in range(M):
        if n - k >= 0:
            yn += h[k] * x[n - k]
    #làm tròn 1 chữ số thập phân
    yn = round(yn, 1)
    y.append(yn)
#tinh MMSE
SSE = 0.0
for i in range(N):
    diff = d[i] - y[i]
    SSE += diff * diff
MMSE = SSE / N
#xuat file
with open('output.txt', 'w') as file:
    for v in y:
        file.write(f"{v:.1f}\n")

#TODO: co can viet he so toi uu va MMSE khong?



