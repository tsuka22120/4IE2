#include <math.h>
#include <stdio.h>

#define PARTS_LENGTH 0.1
#define NUM_PARTS 100
// 初期値
#define Q 1.0
#define X 1.0
#define Y 0.0
#define V_X 0.0
#define V_Y 1.0

// t, X, Y, V_X, V_Yの5変数関数
double dX_dt(double t, double x, double y, double v_x, double v_y) {
    return v_x;
}

double dY_dt(double t, double x, double y, double v_x, double v_y) {
    return v_y;
}

double dV_X_dt(double t, double x, double y, double v_x, double v_y) {
    return -(1 / Q) * (Q / (x * x + y * y)) * (x / sqrt(x * x + y * y));
}

double dV_Y_dt(double t, double x, double y, double v_x, double v_y) {
    return -(1 / Q) * (Q / (x * x + y * y)) * (y / sqrt(x * x + y * y));
}

int main(void) {
    double dt = PARTS_LENGTH;  // 時間刻み
    double t = 0.0;            // 時間
    double x_0 = X;  // 初期位置X
    double y_0 = Y;  // 初期位置Y
    double v_x_0 = V_X;  // 初期速度X
    double v_y_0 = V_Y;  // 初期速度Y
    double x_i, y_i, v_x_i, v_y_i;
    double k_1_x, k_1_y, k_2_x, k_2_y;
    double l_1_x, l_1_y, l_2_x, l_2_y;
    printf("#t, x, y\n");
    printf("%f, %f, %f\n", t, x_0, y_0);

    for (int i = 1; i <= NUM_PARTS; i++) {
        t = t + dt;
        // Heunの方法を使用してx, y, v_x, v_yを更新
        k_1_x = dV_X_dt(t, x_0, y_0, v_x_0, v_y_0) * dt;
        k_1_y = dV_Y_dt(t, x_0, y_0, v_x_0, v_y_0) * dt;
        l_1_x = dX_dt(t, x_0, y_0, v_x_0, v_y_0) * dt;
        l_1_y = dY_dt(t, x_0, y_0, v_x_0, v_y_0) * dt;
        k_2_x = dV_X_dt(t + dt, x_0 + l_1_x, y_0 + l_1_y, v_x_0 + k_1_x, v_y_0 + k_1_y) * dt;
        k_2_y = dV_Y_dt(t + dt, x_0 + l_1_x, y_0 + l_1_y, v_x_0 + k_1_x, v_y_0 + k_1_y) * dt;
        l_2_x = dX_dt(t + dt, x_0 + l_1_x, y_0 + l_1_y, v_x_0 + k_1_x, v_y_0 + k_1_y) * dt;
        l_2_y = dY_dt(t + dt, x_0 + l_1_x, y_0 + l_1_y, v_x_0 + k_1_x, v_y_0 + k_1_y) * dt;
        x_i = x_0 + (l_1_x + l_2_x) / 2;
        y_i = y_0 + (l_1_y + l_2_y) / 2;
        v_x_i = v_x_0 + (k_1_x + k_2_x) / 2;
        v_y_i = v_y_0 + (k_1_y + k_2_y) / 2;
        printf("%f, %f, %f\n", t, x_i, y_i);
        x_0 = x_i;  // 更新された位置X
        y_0 = y_i;  // 更新された位置Y
        v_x_0 = v_x_i;  // 更新された速度X
        v_y_0 = v_y_i;  // 更新された速度Y
    }
    return 0;
}