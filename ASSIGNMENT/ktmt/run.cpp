#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <iomanip> // Để làm tròn số
#include <cmath>   // Dùng cho hàm abs() và pow()
#include <numeric> // Dùng cho hàm std::inner_product

/**
 * LƯU Ý QUAN TRỌNG:
 * Bậc của bộ lọc (M) là một tham số quan trọng.
 * Nó không được cho trước trong đề bài, vì vậy chúng ta phải chọn nó.
 * Bậc lọc càng cao, bộ lọc càng "nhớ" được xa, nhưng tính toán càng nặng.
 * Chúng ta sẽ bắt đầu với M = 5.
 */
#define FILTER_ORDER 5

// --- KHAI BÁO CÁC HÀM TIỆN ÍCH (HELPER FUNCTIONS) ---

/**
 * @brief Đọc một tệp văn bản chứa các số thực vào một vector.
 */
bool read_file_to_vector(const std::string& filename, std::vector<float>& vec) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Lỗi: Không thể mở tệp " << filename << std::endl;
        return false;
    }
    float val;
    while (file >> val) {
        vec.push_back(val);
    }
    file.close();
    return true;
}

/**
 * @brief Ghi một vector số thực ra tệp, mỗi số một dòng.
 */
bool write_vector_to_file(const std::string& filename, const std::vector<float>& vec, float mmse) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Lỗi: Không thể mở tệp " << filename << std::endl;
        return false;
    }
    
    // [cite_start]  // Ghi MMSE ra đầu tệp, theo yêu cầu [cite: 117]
    
    file << std::fixed << std::setprecision(10); // MMSE cần độ chính xác cao
    file << "MMSE: " << mmse << "\n";
    file << "--------------------\n";

    // [cite_start] // Ghi tín hiệu đã lọc ra, làm tròn 1 chữ số thập phân [cite: 113, 114]
    file << std::fixed << std::setprecision(1);
    for (const float& val : vec) {
        file << val << "\n";
    }
    file.close();
    return true;
}

/**
 * @brief Tính toán Tự tương quan (Autocorrelation) $\gamma_{xx}(lag)$.
 * $\gamma_{xx}(k) = \frac{1}{N} \sum_{n=k}^{N-1} x(n)x(n-k)$
 */
float calculate_autocorrelation(const std::vector<float>& signal, int lag) {
    float sum = 0.0f;
    int N = signal.size();
    if (lag < 0) lag = -lag; // $\gamma_{xx}(k) = \gamma_{xx}(-k)$

    for (int n = lag; n < N; ++n) {
        sum += signal[n] * signal[n - lag];
    }
    return sum / N;
}

/**
 * @brief Tính toán Tương quan chéo (Cross-correlation) $\gamma_{dx}(lag)$.
 * $\gamma_{dx}(k) = \frac{1}{N} \sum_{n=k}^{N-1} d(n)x(n-k)$
 */
float calculate_cross_correlation(const std::vector<float>& d, const std::vector<float>& x, int lag) {
    float sum = 0.0f;
    int N = d.size();
    // Giả định x(n) = 0 nếu n < 0
    for (int n = 0; n < N; ++n) {
        if (n - lag >= 0) {
            sum += d[n] * x[n - lag];
        }
    }
    return sum / N;
}

/**
 * @brief Áp dụng bộ lọc (Convolution) để tính y(n). [Theo Công thức (1)]
 * $y(n) = \sum_{k=0}^{M-1} h_k x(n-k)$
 */
std::vector<float> apply_filter(const std::vector<float>& x, const std::vector<float>& h) {
    int N = x.size();
    int M = h.size();
    std::vector<float> y(N);

    for (int n = 0; n < N; ++n) {
        float sum = 0.0f;
        for (int k = 0; k < M; ++k) {
            if (n - k >= 0) {
                sum += h[k] * x[n - k];
            }
        }
        y[n] = sum;
    }
    return y;
}

/**
 * @brief Giải hệ phương trình tuyến tính $Ax = b$ bằng khử Gauss.
 * Đây là phần cốt lõi để tìm $h_{opt}$ từ $R_M h_M = \gamma_d$.
 * Trả về vector $x$ (chính là $h_{opt}$).
 */
std::vector<float> solve_linear_system(std::vector<std::vector<float>>& A, std::vector<float>& b) {
    int N = b.size();

    // --- 1. Quá trình khử xuôi (Forward Elimination) ---
    for (int i = 0; i < N; ++i) {
        // Tìm pivot (phần tử chính)
        float maxVal = std::abs(A[i][i]);
        int maxRow = i;
        for (int k = i + 1; k < N; ++k) {
            if (std::abs(A[k][i]) > maxVal) {
                maxVal = std::abs(A[k][i]);
                maxRow = k;
            }
        }
        // Đổi hàng (Swap rows)
        std::swap(A[i], A[maxRow]);
        std::swap(b[i], b[maxRow]);

        // Biến đổi hàng
        for (int k = i + 1; k < N; ++k) {
            float factor = A[k][i] / A[i][i];
            for (int j = i; j < N; ++j) {
                A[k][j] -= factor * A[i][j];
            }
            b[k] -= factor * b[i];
        }
    }

    // --- 2. Quá trình thế ngược (Back Substitution) ---
    std::vector<float> h_opt(N);
    for (int i = N - 1; i >= 0; --i) {
        h_opt[i] = b[i] / A[i][i];
        for (int k = i - 1; k >= 0; --k) {
            b[k] -= A[k][i] * h_opt[i];
        }
    }
    return h_opt;
}


// --- CHƯƠNG TRÌNH CHÍNH ---

void process_test_case(const std::string& desired_file, 
                         const std::string& input_file, 
                         const std::string& output_file) 
{
    std::cout << "\n--- Đang xử lý: " << input_file << " ---" << std::endl;
    
    // 1. Đọc dữ liệu
    std::vector<float> d, x; // d: desired, x: input
    if (!read_file_to_vector(desired_file, d) || !read_file_to_vector(input_file, x)) {
        return; // Lỗi đã được in trong hàm
    }

    // [cite_start]// 2. Kiểm tra lỗi "size not match" [cite: 142]


    if (d.size() != x.size() || d.empty()) {
        std::cerr << "Lỗi: Kích thước tệp không khớp hoặc tệp rỗng." << std::endl;
        
        // Ghi lỗi ra tệp output theo yêu cầu
        std::ofstream out_err(output_file);
        if (out_err.is_open()) {
            out_err << "Error: size not match\n";
            out_err.close();
        }
        return;
    }
    
    int N = d.size();
    int M = FILTER_ORDER;
    std::cout << "Tín hiệu đọc thành công. Số mẫu (N): " << N << ", Bậc lọc (M): " << M << std::endl;

    // [cite_start]// 3. Xây dựng ma trận R (Autocorrelation Matrix) [cite: 86]
    // R là ma trận Toeplitz M x M
    std::vector<std::vector<float>> R(M, std::vector<float>(M));
    std::vector<float> r_xx(M); // Lưu các giá trị $\gamma_{xx}(0)$ đến $\gamma_{xx}(M-1)$
    for (int k = 0; k < M; ++k) {
        r_xx[k] = calculate_autocorrelation(x, k);
    }
    for (int i = 0; i < M; ++i) {
        for (int j = 0; j < M; ++j) {
            R[i][j] = r_xx[std::abs(i - j)]; // $R_{ij} = \gamma_{xx}(i-j)$
        }
    }

    // [cite_start]// 4. Xây dựng vector $\gamma_d$ (Cross-correlation Vector) [cite: 86]
    
    
    std::vector<float> gamma_d(M);
    for (int k = 0; k < M; ++k) {
        gamma_d[k] = calculate_cross_correlation(d, x, k);
    }

    // [cite_start]// 5. Giải hệ $R h = \gamma_d$ để tìm $h_{opt}$ [cite: 88]
    
    // Hàm solve_linear_system sẽ thay đổi R và gamma_d, 
    // nên ta tạo bản sao để dùng cho tính MMSE sau này.
    std::vector<std::vector<float>> R_copy = R;
    std::vector<float> gamma_d_copy = gamma_d;
    
    std::vector<float> h_opt = solve_linear_system(R_copy, gamma_d_copy);
    
    std::cout << "Đã tìm thấy các hệ số lọc h_opt:" << std::endl;
    for(int k=0; k < M; ++k) {
        std::cout << "h[" << k << "] = " << h_opt[k] << std::endl;
    }

    // [cite_start]// 6. Áp dụng bộ lọc (Convolution) để tìm $y(n)$ [cite: 69]
    
    std::vector<float> y_out = apply_filter(x, h_opt);

    // [cite_start]// 7. Tính MMSE [cite: 91]
    // $MMSE = \sigma_d^2 - \sum_{k=0}^{M-1} h_{opt}(k) \gamma_{dx}(k)$
    
    // $\sigma_d^2$ (phương sai) là $\gamma_{dd}(0)$
    float sigma_d_squared = calculate_autocorrelation(d, 0);
    
    // Tính tích vô hướng (dot product) của $h_{opt}$ và $\gamma_d$
    float h_gamma_dot_product = 0.0f;
    for(int k=0; k<M; ++k) {
        h_gamma_dot_product += h_opt[k] * gamma_d[k];
    }
    
    float mmse = sigma_d_squared - h_gamma_dot_product;
    std::cout << "MMSE tính được: " << mmse << std::endl;

    // 8. Ghi kết quả ra tệp
    if (write_vector_to_file(output_file, y_out, mmse)) {
        std::cout << "Đã ghi thành công kết quả ra tệp " << output_file << std::endl;
    }
}


int main() {
    // --- Xử lý Test Case 1 ---
    process_test_case("desired.txt", "input1.txt", "output_golden_1.txt");
    
    // --- Xử lý Test Case 2 ---
    process_test_case("desired.txt", "input2.txt", "output_golden_2.txt");

    return 0;
}