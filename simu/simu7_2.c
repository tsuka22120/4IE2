#include <math.h>
#include <stdio.h>

#define PARTS_LENGTH 0.1
#define NUM_PARTS 1000
// 初期値
#define I_0 0
#define Q_0 10
#define R 8.0
#define C 0.3
#define L 10

// t, I, Qの3変数関数
double dI_dt(double t, double I, double Q) {
    return -((R * I) / L) - (Q / (C * L));
}

double dQ_dt(double t, double I, double Q) { return I; }

int main(void) {
    double t = 0.0;            // 時間
    double I = I_0;            // 初期電流
    double Q = Q_0;            // 初期電荷
    double dt = PARTS_LENGTH;  // 時間刻み
    double I_i, Q_i;
    double k_1, k_2;
    double l_1, l_2;
    printf("#t, I, Q\n");
    printf("%f, %f, %f\n", t, I, Q);
    for (int i = 1; i <= NUM_PARTS; i++) {
        t = t + dt;
        // Heunの方法を使用してIとQを更新
        k_1 = dI_dt(t, I, Q) * dt;
        l_1 = dQ_dt(t, I, Q) * dt;
        k_2 = dI_dt(t + dt, I + k_1, Q + l_1) * dt;
        l_2 = dQ_dt(t + dt, I + k_1, Q + l_1) * dt;
        I_i = I + (k_1 + k_2) / 2;
        Q_i = Q + (l_1 + l_2) / 2;
        printf("%f, %f, %f\n", t, I_i, Q_i);
        I = I_i;  // 更新された電流
        Q = Q_i;  // 更新された電荷
    }
    return 0;
}