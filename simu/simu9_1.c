    #include <math.h>
    #include <stdio.h>

    #define PARTS_LENGTH 0.1
    #define NUM_PARTS 200
    // 初期値
    #define Q 1.0
    #define Q_1 10
    #define Q_2 5
    #define A 5
    #define B -5
    #define X 2
    #define Y 2
    #define V_X -2
    #define V_Y 1

    // t, X, Y, V_X, V_Yの5変数関数
    double dX_dt(double t, double x, double y, double v_x, double v_y) {
        return v_x;
    }

    double dY_dt(double t, double x, double y, double v_x, double v_y) {
        return v_y;
    }

    double dV_X_dt(double t, double x, double y, double v_x, double v_y) {
        return -(1 / Q) * (Q_1 * Q / (x * x + y * y)) * (x / sqrt(x * x + y * y)) -
            (1 / Q) * (Q_2 * Q / ((x - A) * (x - A) + (y - B) * (y - B))) *
                ((x - A) / sqrt((x - A) * (x - A) + (y - B) * (y - B)));
    }

    double dV_Y_dt(double t, double x, double y, double v_x, double v_y) {
        return -(1 / Q) * (Q_1 * Q / (x * x + y * y)) * (y / sqrt(x * x + y * y)) -
            (1 / Q) * (Q_2 * Q / ((x - A) * (x - A) + (y - B) * (y - B))) *
                ((y - B) / sqrt((x - A) * (x - A) + (y - B) * (y - B)));
    }

    int main(void) {
        double dt = PARTS_LENGTH;  // 時間刻み
        double t = 0.0;            // 時間
        double x_0 = X;            // 初期位置X
        double y_0 = Y;            // 初期位置Y
        double v_x_0 = V_X;        // 初期速度X
        double v_y_0 = V_Y;        // 初期速度Y
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
            k_2_x = dV_X_dt(t + dt, x_0 + l_1_x, y_0 + l_1_y, v_x_0 + k_1_x,
                            v_y_0 + k_1_y) *
                    dt;
            k_2_y = dV_Y_dt(t + dt, x_0 + l_1_x, y_0 + l_1_y, v_x_0 + k_1_x,
                            v_y_0 + k_1_y) *
                    dt;
            l_2_x = dX_dt(t + dt, x_0 + l_1_x, y_0 + l_1_y, v_x_0 + k_1_x,
                        v_y_0 + k_1_y) *
                    dt;
            l_2_y = dY_dt(t + dt, x_0 + l_1_x, y_0 + l_1_y, v_x_0 + k_1_x,
                        v_y_0 + k_1_y) *
                    dt;
            x_i = x_0 + (l_1_x + l_2_x) / 2;
            y_i = y_0 + (l_1_y + l_2_y) / 2;
            v_x_i = v_x_0 + (k_1_x + k_2_x) / 2;
            v_y_i = v_y_0 + (k_1_y + k_2_y) / 2;
            printf("%f, %f, %f\n", t, x_i, y_i);
            x_0 = x_i;      // 更新された位置X
            y_0 = y_i;      // 更新された位置Y
            v_x_0 = v_x_i;  // 更新された速度X
            v_y_0 = v_y_i;  // 更新された速度Y
        }
        return 0;
    }