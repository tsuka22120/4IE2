#include <stdio.h>
#include <math.h>

#define PARTS_LENGTH 0.1
#define NUM_PARTS 20

double integrand(double x, double y) { return (2 * y) / (1 + x); }

int main(void) {
    double x_0 = 0, y_0 = 0.5;
    double x_i, y_i;
    double k_1, k_2;
    double h = PARTS_LENGTH;
    double RealValue;
    printf("x_0 = %f, y_0 = %f\n", x_0, y_0);
    for (int i = 1; i <= NUM_PARTS; i++) {
        x_i = x_0 + h;
        k_1 = integrand(x_0, y_0) * h;
        k_2 = integrand(x_i, y_0 + k_1) * h;
        y_i = y_0 + (k_1 + k_2) / 2;
        RealValue = pow(x_i + 1, 2) / 2;
        printf("x_%d = %f, y_%d = %f true:%f ", i, x_i, i, y_i, RealValue);
        printf("error = %f\n", fabs(RealValue - y_i));
        x_0 = x_i;
        y_0 = y_i;
    }
    return 0;
}