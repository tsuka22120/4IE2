#include <math.h>
#include <stdio.h>

#define M 7  // 標本点の数
#define N 3  // 答えの数

int showMatrix(int n, double a[n][n], double b[n]) {
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            printf("%f", a[i][j]);
            if (j == 0) {
                printf("x + ");
            } else if (j == 1) {
                printf("y + ");
            } else if (j == 2) {
                printf("z ");
            }
        }
        printf("= %f\n", b[i]);
    }
    printf("\n");
}

int gaussianElimination(int n, double a[n][n], double b[n], double* x) {
    double m;
    // 前進消去
    printf("式\n");
    showMatrix(n, a, b);
    for (int k = 0; k < n - 1; k++) {
        for (int i = k + 1; i < n; i++) {
            if (a[k][k] == 0) {
                // ゼロ除算を避けるためk番目の列の中で最も大きい行と入れ替える
                double max = fabs(a[k][k]);
                int maxRow = k;
                for (int j = 0; j < n; j++) {
                    if (fabs(a[j][k]) > max) {
                        max = fabs(a[j][k]);
                        maxRow = j;
                    }
                }
                for (int j = 0; j < n; j++) {
                    double temp = a[k][j];
                    a[k][j] = a[maxRow][j];
                    a[maxRow][j] = temp;
                }
                double tempB = b[k];
                b[k] = b[maxRow];
                b[maxRow] = tempB;
            }
            m = a[i][k] / a[k][k];
            for (int j = k; j < n; j++) {
                a[i][j] -= m * a[k][j];
            }
            b[i] -= m * b[k];
        }
        showMatrix(n, a, b);
    }
    printf("前進消去後の行列:\n");
    showMatrix(n, a, b);
    // 後退代入
    for (int k = n - 1; k >= 0; k--) {
        x[k] = b[k];
        for (int j = k + 1; j < n; j++) {
            x[k] -= a[k][j] * x[j];
        }
        x[k] /= a[k][k];
    }
}

int main(void) {
    int m = M, n = N;
    double a[N][M] = {{0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6},
                      {0, 0.034, 0.138, 0.282, 0.479, 0.724, 1.120}};
    double left[N][N] = {{0, 0, 0}, {0, 0, 0}};
    double right[N] = {0, 0, 0};
    double answer[N] = {0, 0, 0};
    double x_k, y_k, x_k2, y_k2, x_k3, y_k3, x_k4, y_k4;
    double X_kY_k, X_k2Y_k;
    left[0][0] = m;
    printf("式\n");
    for (int i = 0; i < M; i++) {
        printf("%f ", a[0][i]);
    }
    printf("\n");
    for (int i = 0; i < M; i++) {
        printf("%f ", a[1][i]);
    }
    printf("\n");
    left[0][0] = m;
    for (int i = 0; i < m; i++) {
        x_k += a[0][i];
        x_k2 += a[0][i] * a[0][i];
        x_k3 += a[0][i] * a[0][i] * a[0][i];
        x_k4 += a[0][i] * a[0][i] * a[0][i] * a[0][i];
        y_k += a[1][i];
        y_k2 += a[1][i] * a[1][i];
        y_k3 += a[1][i] * a[1][i] * a[1][i];
        y_k4 += a[1][i] * a[1][i] * a[1][i] * a[1][i];
        X_kY_k += a[0][i] * a[1][i];
        X_k2Y_k += a[0][i] * a[0][i] * a[1][i];
    }
    left[0][1] = x_k;
    left[0][2] = x_k2;
    left[1][0] = x_k;
    left[1][1] = x_k2;
    left[1][2] = x_k3;
    left[2][0] = x_k2;
    left[2][1] = x_k3;
    left[2][2] = x_k4;
    right[0] = y_k;
    right[1] = X_kY_k;
    right[2] = X_k2Y_k;
    gaussianElimination(n, left, right, answer);
    printf("解:\n");
    for (int i = 0; i < n; i++) {
        printf("x%d = %f\n", i + 1, answer[i]);
    }
    return 0;
}