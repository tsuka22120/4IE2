#include <math.h>
#include <stdio.h>

#define PARTS_LENGTH 0.1
#define NUM_PARTS 100
// 初期値
#define X 0
#define Y 10
#define V 0
#define M 1
#define K 2
#define L 0.3

double yX(double y, double v) { return v;}

double vX(double y, double v) { return -(K / M) * y - (L / M) * v;}

int main(void) {
    double x_0 = X;
    double y_0 = Y;
    double v_0 = V;
    double x_i, y_i, v_i;
    double h = PARTS_LENGTH;
    double m, k, l;
    m = M;
    k = K;
    l = L;
    printf("#x, y, v\n");
    printf("%f, %f, %f\n", x_0, y_0, v_0);
    for (int i = 1; i <= NUM_PARTS; i++) {
        x_i = x_0 + h;
        y_i = y_0 + h * yX(y_0, v_0);
        v_i = v_0 + h * vX(y_0, v_0);
        printf("%f, %f, %f\n", x_i, y_i, v_i);
        x_0 = x_i;
        y_0 = y_i;
        v_0 = v_i;
    }
    return 0;
}