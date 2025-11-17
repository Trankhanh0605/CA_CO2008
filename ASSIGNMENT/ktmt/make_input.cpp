#include <iostream>
#include <fstream>
#include <string>
#include <iomanip> // Thư viện này cần thiết để làm tròn số

/**
 * @brief Hàm này đọc 2 tệp đầu vào, cộng chúng lại từng dòng,
 * và ghi kết quả ra tệp đầu ra.
 * * @param desired_filename Tên tệp tín hiệu mong muốn (vd: "desire.txt")
 * @param noise_filename   Tên tệp nhiễu (vd: "noise_white.txt")
 * @param output_filename  Tên tệp kết quả (vd: "input1.txt")
 * @return true nếu thành công, false nếu có lỗi
 */
bool create_input_file(const std::string& desired_filename,
                       const std::string& noise_filename,
                       const std::string& output_filename) {
    
    // Mở các luồng (stream) tệp
    std::ifstream in_desired(desired_filename);
    std::ifstream in_noise(noise_filename);
    std::ofstream out_input(output_filename);

    // Kiểm tra xem các tệp có mở thành công không
    if (!in_desired.is_open()) {
        std::cerr << "Lỗi: Không thể mở tệp " << desired_filename << std::endl;
        return false;
    }
    if (!in_noise.is_open()) {
        std::cerr << "Lỗi: Không thể mở tệp " << noise_filename << std::endl;
        return false;
    }
    if (!out_input.is_open()) {
        std::cerr << "Lỗi: Không thể mở tệp " << output_filename << std::endl;
        return false;
    }

    std::cout << "Đang xử lý: " << desired_filename << " + " 
              << noise_filename << " -> " << output_filename << std::endl;

    float desired_val, noise_val;

    // Thiết lập để ghi ra tệp output với 1 chữ số thập phân
    out_input << std::fixed << std::setprecision(1);

    // Vòng lặp đọc từng dòng từ cả hai tệp
    while (in_desired >> desired_val && in_noise >> noise_val) {
        // Thực hiện phép cộng
        float sum = desired_val + noise_val;
        
        // Ghi tổng ra tệp output, xuống dòng
        out_input << sum << "\n";
    }

    // Đóng tất cả các tệp lại
    in_desired.close();
    in_noise.close();
    out_input.close();

    return true;
}

int main() {
    std::cout << "--- Bắt đầu tạo các tệp kiểm thử ---" << std::endl;

    // --- Trường hợp 1 ---
    bool success1 = create_input_file("desired.txt", "noise_white.txt", "input1.txt");
    if (success1) {
        std::cout << "Đã tạo input1.txt thành công." << std::endl;
    } else {
        std::cerr << "Thất bại khi tạo input1.txt." << std::endl;
    }

    std::cout << "----------------------------------------" << std::endl;

    // --- Trường hợp 2 ---
    bool success2 = create_input_file("desired.txt", "noise_other.txt", "input2.txt");
    if (success2) {
        std::cout << "Đã tạo input2.txt thành công." << std::endl;
    } else {
        std::cerr << "Thất bại khi tạo input2.txt." << std::endl;
    }

    std::cout << "--- Đã tạo xong các tệp kiểm thử ---" << std::endl;

    return 0;
}