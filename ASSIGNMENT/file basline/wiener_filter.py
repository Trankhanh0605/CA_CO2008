import numpy as np
import os

# ============================================================================
# BƯỚC 1: TẠO DỮ LIỆU ĐẦU VÀO (nếu chưa có)
# ============================================================================

def create_sample_data(n_samples=500):
    """Tạo file desired.txt và noise.txt mẫu"""

    # Tạo tín hiệu mong muốn (desired signal): sin wave
    np.random.seed(42)
    t = np.linspace(0, 10*np.pi, n_samples)
    desired_signal = np.sin(t) + 0.1 * np.cos(2*t)

    # Tạo nhiễu trắng (white noise)
    noise_white = np.random.normal(0, 0.5, n_samples)

    # Ghi desired.txt
    with open('desired.txt', 'w') as f:
        for val in desired_signal:
            f.write(f"{val:.1f}\n")

    # Ghi noise.txt (nhiễu trắng)
    with open('noise.txt', 'w') as f:
        for val in noise_white:
            f.write(f"{val:.1f}\n")

    print("✓ Tạo desired.txt và noise.txt thành công!")
    return desired_signal, noise_white

# ============================================================================
# BƯỚC 2: KẾT HỢP DESIRED + NOISE VÀO INPUT.TXT
# ============================================================================

def create_input_from_desired_and_noise(desired_file, noise_file, input_file):
    """Kết hợp desired.txt và noise.txt để tạo input.txt"""

    # Đọc desired signal - BỎ QUA DÒNG TRỐNG
    with open(desired_file, 'r') as f:
        desired = np.array([float(line.strip()) for line in f if line.strip()])

    # Đọc noise - BỎ QUA DÒNG TRỐNG
    with open(noise_file, 'r') as f:
        noise = np.array([float(line.strip()) for line in f if line.strip()])

    # Kiểm tra kích thước
    if len(desired) != len(noise):
        print("✗ Lỗi: Kích thước desired và noise không khớp!")
        print(f"  desired: {len(desired)} số")
        print(f"  noise: {len(noise)} số")
        return False

    # Kết hợp: x(n) = s(n) + w(n)
    input_signal = desired + noise

    # Ghi input.txt
    with open(input_file, 'w') as f:
        for val in input_signal:
            f.write(f"{val:.1f}\n")

    print(f"✓ Tạo {input_file} từ {desired_file} + {noise_file} thành công!")
    print(f"  Số mẫu: {len(input_signal)}")
    return True

# ============================================================================
# BƯỚC 3: THUẬT TOÁN BỘ LỌC WIENER
# ============================================================================

def wiener_filter(input_signal, desired_signal, M=None):
    """
    Cài đặt bộ lọc Wiener

    Parameters:
    -----------
    input_signal: mảng x(n) - tín hiệu đầu vào (có nhiễu)
    desired_signal: mảng d(n) - tín hiệu mong muốn
    M: độ dài bộ lọc (số taps). Nếu None, sẽ tự chọn = min(20, N//4)

    Returns:
    --------
    h_opt: hệ số bộ lọc tối ưu
    y: tín hiệu đầu ra (lọc)
    MMSE: sai số bình phương trung bình tối thiểu
    """

    N = len(input_signal)

    # Tự chọn M nếu không chỉ định
    if M is None:
        M = min(20, max(3, N // 4))

    # Không để M quá lớn so với N
    if M >= N:
        M = max(3, N // 2)

    print(f"    Độ dài bộ lọc M = {M} (N = {N})")

    # ===== Bước 1: Tính tự tương quan γ_xx =====
    # γ_xx(k) = E[x(n) * x(n-k)]
    gamma_xx = np.zeros(M)
    for k in range(M):
        for n in range(k, N):
            gamma_xx[k] += input_signal[n] * input_signal[n-k]
        gamma_xx[k] /= (N - k)

    # ===== Bước 2: Tính tương quan chéo γ_dx =====
    # γ_dx(k) = E[d(n) * x(n-k)]
    gamma_dx = np.zeros(M)
    for k in range(M):
        for n in range(k, N):
            gamma_dx[k] += desired_signal[n] * input_signal[n-k]
        gamma_dx[k] /= (N - k)

    # ===== Bước 3: Xây dựng ma trận Toeplitz R_M =====
    # R_M là ma trận Toeplitz với phần tử R[l,k] = γ_xx(l-k)
    R_M = np.zeros((M, M))
    for l in range(M):
        for k in range(M):
            R_M[l, k] = gamma_xx[abs(l - k)]

    # ===== Bước 4: Giải phương trình Wiener-Hopf: R_M * h = γ_dx =====
    try:
        h_opt = np.linalg.solve(R_M, gamma_dx)
    except np.linalg.LinAlgError:
        print("    ⚠ Cảnh báo: Ma trận R_M suy biến, sử dụng least squares")
        h_opt = np.linalg.lstsq(R_M, gamma_dx, rcond=None)[0]

    # ===== Bước 5: Tính đầu ra y(n) = Σ h_k * x(n-k) =====
    y = np.zeros(N)
    for n in range(N):
        for k in range(M):
            if n - k >= 0:  # Chỉ cộng khi có dữ liệu
                y[n] += h_opt[k] * input_signal[n-k]

    # ===== Bước 6: Tính MMSE =====
    # MMSE = σ_d² - γ_d^T * R_M^(-1) * γ_d
    sigma_d_sq = np.mean(desired_signal**2)  # Phương sai của d(n)

    try:
        R_M_inv = np.linalg.inv(R_M)
        MMSE = sigma_d_sq - gamma_dx @ R_M_inv @ gamma_dx
    except np.linalg.LinAlgError:
        # Nếu không thể invert, tính MMSE từ sai số trực tiếp
        error = desired_signal - y
        MMSE = np.mean(error**2)

    return h_opt, y, MMSE

# ============================================================================
# BƯỚC 4: CHƯƠNG TRÌNH CHÍNH
# ============================================================================

def main():
    print("=" * 70)
    print("CHƯƠNG TRÌNH LỌC WIENER - PYTHON (CẬP NHẬT)")
    print("=" * 70)

    # Tạo dữ liệu mẫu nếu chưa có
    if not os.path.exists('desired.txt') or not os.path.exists('noise.txt'):
        print("\n[1] Tạo dữ liệu đầu vào mẫu...")
        create_sample_data(n_samples=500)
    else:
        print("\n[1] Sử dụng file desired.txt và noise.txt có sẵn")

    # Tạo input.txt từ desired.txt + noise.txt
    print("\n[2] Kết hợp desired.txt + noise.txt → input.txt...")
    if not create_input_from_desired_and_noise('desired.txt', 'noise.txt', 'input.txt'):
        return

    # Đọc input.txt - BỎ QUA DÒNG TRỐNG
    print("\n[3] Đọc input.txt...")
    with open('input.txt', 'r') as f:
        input_signal = np.array([float(line.strip()) for line in f if line.strip()])

    # Đọc desired.txt - BỎ QUA DÒNG TRỐNG
    with open('desired.txt', 'r') as f:
        desired_signal = np.array([float(line.strip()) for line in f if line.strip()])

    # Kiểm tra kích thước
    if len(input_signal) != len(desired_signal):
        print("✗ Lỗi: Kích thước input và desired không khớp!")
        with open('output.txt', 'w') as f:
            f.write("Error: size not match\n")
        return

    print(f"✓ Đọc thành công: {len(input_signal)} mẫu")

    # Áp dụng bộ lọc Wiener
    print("\n[4] Áp dụng bộ lọc Wiener...")

    # Tự động chọn M dựa trên số mẫu
    N = len(input_signal)
    M = 3  # Chọn M phù hợp

    h_opt, y_output, MMSE = wiener_filter(input_signal, desired_signal, M=M)

    print(f"  MMSE = {MMSE:.6f}")

    # Ghi output.txt
    print("\n[5] Ghi output.txt...")
    with open('output.txt', 'w') as f:
        # Ghi N giá trị đầu ra
        for val in y_output:
            f.write(f"{val:.1f}\n")
        # Ghi MMSE ở cuối
        f.write(f"MMSE: {MMSE:.1f}\n")

    print("✓ Ghi output.txt thành công!")

    # Thống kê
    print("\n" + "=" * 70)
    print("THỐNG KÊ KẾT QUẢ:")
    print("=" * 70)
    print(f"Số mẫu xử lý: {len(y_output)}")
    print(f"Độ dài bộ lọc: {M}")
    print(f"\nHệ số bộ lọc tối ưu (h_opt):")
    for i, h in enumerate(h_opt):
        print(f"  h[{i}] = {h:.6f}")

    print(f"\nMMSE (Mean Square Error): {MMSE:.6f}")

    sigma_d_sq = np.mean(desired_signal**2)
    if sigma_d_sq > 0:
        mse_percent = (MMSE / sigma_d_sq * 100)
        print(f"MSE% (so với phương sai tín hiệu): {mse_percent:.2f}%")

    error_signal = desired_signal - y_output
    mse_direct = np.mean(error_signal**2)
    print(f"\nSai số trực tiếp (desired - output):")
    print(f"  MSE: {mse_direct:.6f}")
    print(f"  Độ lệch chuẩn: {np.std(error_signal):.6f}")

    print("\n" + "=" * 70)
    print("Hoàn thành! Kiểm tra file output.txt")
    print("=" * 70)

if __name__ == '__main__':
    main()
