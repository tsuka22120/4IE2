#include <math.h>
#include <stdio.h>

#define N 4  // 行列のサイズ

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


//ピボット選択無し
int gaussianEliminationWithoutPivot(int n, double a[n][n], double b[n], double* x) {
    double m;
    // 前進消去
    for (int k = 0; k < n - 1; k++) {
        for (int i = k + 1; i < n; i++) {
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

// ピボット選択あり
int gaussianElimination(int n, double a[n][n], double b[n], double* x) {
    double m;
    // 前進消去
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
    int n = N;  // 行列のサイズ
    double a[N][N] = {
        {1.0, 0.96, 0.84, 0.64},
        {0.96, 0.9214, 0.4406, 0.2222},
        {0.84, 0.4406, 1.0, 0.3444},
        {0.64, 0.2222, 0.3444, 1.0},
    };
    double b[N] = {3.44, 2.5442, 2.6250, 2.2066};
    double x[N];  // 解を格納する配列
    printf("式:\n");
    showMatrix(n, a, b);
    gaussianElimination(n, a, b, x);
    printf("ピボットありの解:\n");
    for (int i = 0; i < n; i++) {
        printf("x[%d] = %f\n", i, x[i]);
    }
    gaussianEliminationWithoutPivot(n, a, b, x);
    printf("ピボットなしの解:\n");
    for (int i = 0; i < n; i++) {
        printf("x[%d] = %f\n", i, x[i]);
    }
    return 0;
}