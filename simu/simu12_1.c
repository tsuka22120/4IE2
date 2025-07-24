#include <math.h>
#include <stdio.h>

#define M 4  // 標本点の数
#define N 2  // 変数の数

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
    double a[N][M] = {
        {1, 2, 3, 4},
        {0, 1, 2, 4}
    };
    double left[N][N] = {{0, 0}, {0, 0}};
    double right[N] = {0, 0};
    double answer[N] = {0, 0};
    left[0][0] = m;
    printf("式\n");
    for(int i = 0; i < m; i++) {
        printf("%f ", a[0][i]);
    }
    printf("\n");
    for(int i = 0; i < m; i++) {
        printf("%f ", a[1][i]);
    }
    printf("\n");
    for (int i = 0; i < m; i++) {
        left[0][1] += a[0][i];
        left[1][0] += a[0][i];
        left[1][1] += a[0][i] * a[0][i];
        right[0] += a[1][i];
        right[1] += a[0][i] * a[1][i];
    }
    gaussianElimination(n, left, right, answer);
    printf("解:\n");
    for (int i = 0; i < n; i++) {
        printf("x%d = %f\n", i + 1, answer[i]);
    }
    return 0;
}