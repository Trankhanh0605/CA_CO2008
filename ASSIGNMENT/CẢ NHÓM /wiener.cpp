#include <stdio.h>

// Kích thước cố định
#define N 10
#define M 10

// Hàm giá trị tuyệt đối cho float
float my_fabs(float x) {
    return (x < 0) ? -x : x;
}

// Hàm làm tròn xuống cho float
float my_floor(float x) {
    int int_part = (int)x;
    float float_part = x - int_part;
    
    if (x >= 0 || float_part == 0) {
        return (float)int_part;
    } else {
        return (float)(int_part - 1);
    }
}

// Hàm làm tròn lên cho float
float my_ceil(float x) {
    int int_part = (int)x;
    float float_part = x - int_part;
    
    if (float_part == 0 || x <= 0) {
        return (float)int_part;
    } else {
        return (float)(int_part + 1);
    }
}

// Hàm đọc dãy số từ file
int readSignal(const char* filename, float signal[N]) {
    FILE* file = fopen(filename, "r");
    if (file == NULL) {
        printf("Error: Cannot open file: %s\n", filename);
        return 0;
    }
    
    int count = 0;
    while (count < N && fscanf(file, "%f", &signal[count]) == 1) {
        count++;
    }
    
    fclose(file);
    return 1;
}

// Hàm tính tương quan chéo
float crossCorrelation(float x[N], float y[N], int lag) {
    float sum = 0.0f;
    int i, j;
    
    for (i = 0; i < N; i++) {
        j = i - lag;
        if (j >= 0 && j < N) {
            sum += x[i] * y[j];
        }
    }
    
    return sum / N;
}

// Hàm tính tự tương quan
float autoCorrelation(float x[N], int lag) {
    return crossCorrelation(x, x, lag);
}

// Hàm giải hệ phương trình tuyến tính bằng phương pháp Gauss
void solveLinearSystem(float A[M][M], float b[M], float h[M]) {
    int i, j, k, maxRow;
    float temp, factor, pivot;
    
    // Quá trình khử Gauss
    for (i = 0; i < M; i++) {
        // Tìm phần tử chính (pivot)
        maxRow = i;
        for (k = i + 1; k < M; k++) {
            if (my_fabs(A[k][i]) > my_fabs(A[maxRow][i])) {
                maxRow = k;
            }
        }
        
        // Đổi hàng
        if (maxRow != i) {
            for (j = 0; j < M; j++) {
                temp = A[i][j];
                A[i][j] = A[maxRow][j];
                A[maxRow][j] = temp;
            }
            temp = b[i];
            b[i] = b[maxRow];
            b[maxRow] = temp;
        }
        
        // Chuẩn hóa hàng i
        pivot = A[i][i];
        if (my_fabs(pivot) < 0.00001f) {
            continue; // Ma trận suy biến
        }
        
        for (j = i; j < M; j++) {
            A[i][j] /= pivot;
        }
        b[i] /= pivot;
        
        // Khử các hàng khác
        for (k = 0; k < M; k++) {
            if (k != i && my_fabs(A[k][i]) > 0.00001f) {
                factor = A[k][i];
                for (j = i; j < M; j++) {
                    A[k][j] -= factor * A[i][j];
                }
                b[k] -= factor * b[i];
            }
        }
    }
    
    // Sao chép kết quả
    for (i = 0; i < M; i++) {
        h[i] = b[i];
    }
}

// Hàm tính bộ lọc Wiener
void computeWienerFilter(float input[N], float desired[N], float h[M]) {
    float R[M][M];
    float gamma_d[M];
    int i, j, l;
    
    // Xây dựng ma trận tự tương quan R
    for (i = 0; i < M; i++) {
        for (j = 0; j < M; j++) {
            R[i][j] = autoCorrelation(input, i - j);
        }
    }
    
    // Xây dựng vector tương quan chéo
    for (l = 0; l < M; l++) {
        gamma_d[l] = crossCorrelation(desired, input, l);
    }
    
    // Giải hệ phương trình R * h = gamma_d
    solveLinearSystem(R, gamma_d, h);
}

// Hàm lọc tín hiệu
void filterSignal(float input[N], float h[M], float output[N]) {
    int n, k;
    
    for (n = 0; n < N; n++) {
        output[n] = 0.0f;
        for (k = 0; k < M; k++) {
            if (n - k >= 0) {
                output[n] += h[k] * input[n - k];
            }
        }
    }
}

// Hàm tính MMSE
float computeMMSE(float desired[N], float output[N]) {
    float mse = 0.0f;
    float error;
    int i;
    
    for (i = 0; i < N; i++) {
        error = desired[i] - output[i];
        mse += error * error;
    }
    
    return mse / N;
}

// Hàm làm tròn đến 1 chữ số thập phân
float roundToOneDecimal(float value) {
    if (value >= 0.0f) {
        return my_floor(value * 10.0f + 0.5f) / 10.0f;
    } else {
        return my_ceil(value * 10.0f - 0.5f) / 10.0f;
    }
}

// Hàm in mảng với định dạng
void printArray(float arr[N], const char* label) {
    int i;
    printf("%s: ", label);
    for (i = 0; i < N; i++) {
        printf("%7.4f", arr[i]);
        if (i < N - 1) {
            printf("   ");
        }
    }
    printf("\n");
}

int main() {
    float desired_signal[N];
    float input_signal[N];
    float optimize_coefficient[M];
    float output_signal[N];
    float mmse;
    int i;
    FILE* outFile;
    
    // Đọc tín hiệu từ file
    if (!readSignal("desired19-44-21_11-Nov-25_10_10.txt", desired_signal) ||
        !readSignal("input19-44-21_11-Nov-25_10_10_1.txt", input_signal)) {
        return 1;
    }
    
    // Tính hệ số bộ lọc Wiener tối ưu
    computeWienerFilter(input_signal, desired_signal, optimize_coefficient);
    
    // Lọc tín hiệu
    filterSignal(input_signal, optimize_coefficient, output_signal);
    
    // Tính MMSE
    mmse = computeMMSE(desired_signal, output_signal);
    
    // Làm tròn kết quả đến 1 chữ số thập phân
    for (i = 0; i < N; i++) {
        output_signal[i] = roundToOneDecimal(output_signal[i]);
    }
    mmse = roundToOneDecimal(mmse);
    
    // In kết quả ra terminal
    printArray(output_signal, "Filtered output");
    printf("MMSE: %.4f\n", mmse);
    
    // Ghi kết quả vào file output.txt
    outFile = fopen("output.txt", "w");
    if (outFile != NULL) {
        fprintf(outFile, "Filtered output: ");
        for (i = 0; i < N; i++) {
            fprintf(outFile, "%7.4f", output_signal[i]);
            if (i < N - 1) {
                fprintf(outFile, "   ");
            }
        }
        fprintf(outFile, "\nMMSE: %.4f\n", mmse);
        fclose(outFile);
    }

    
    return 0;
}