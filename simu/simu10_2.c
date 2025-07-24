    #include <math.h>
    #include <stdio.h>

    #define N 4  // 行列のサイズ

    int gaussianElimination(int n, double a[n][n], double b[n], double* x) {
        double m;
        // 前進消去
        for(int k = 0; k < n - 1; k++) {
            for(int i = k + 1; i < n; i++) {
                m = a[i][k] / a[k][k];
                for(int j = k; j < n; j++) {
                    a[i][j] -= m * a[k][j];
                }
                b[i] -= m * b[k];
            }
        }
        printf("前進消去後の行列:\n");
        for(int i = 0; i < n; i++) {
            for(int j = 0; j < n; j++) {
                printf("%f ", a[i][j]);
            }
            printf("= %f\n", b[i]);
        }
        // 後退代入
        for(int k = n - 1; k >= 0; k--) {
            x[k] = b[k];
            for(int j = k + 1; j < n; j++) {
                x[k] -= a[k][j] * x[j];
            }
            x[k] /= a[k][k];
        }
    }

    int main(void){
        int n = N; // 行列のサイズ
        double a[N][N] = {
            {1, 2, 1, 5},
            {8, 1, 3, 1},
            {1, 7 ,1 ,1},
            {1, 1, 6, 1}
        };
        double b[N] = {20.5, 14.5, 18.5, 9.0};
        double x[N];// 解を格納する配列
        printf("式:\n");
        for(int i = 0; i < n; i++) {
            for(int j = 0; j < n; j++) {
                printf("%f ", a[i][j]);
            }
            printf("= %f\n", b[i]);
        }
        gaussianElimination(n, a, b, x);
        printf("解:\n");
        for(int i = 0; i < n; i++) {
            printf("x[%d] = %f\n", i, x[i]);
        }
        return 0;
    }