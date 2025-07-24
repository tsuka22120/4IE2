#include <stdio.h>

#define PARTS_LENGTH 0.5
#define NUM_PARTS 4

double integrand(double x, double y) { return y / (1 + x); }

int main(void) {
    double x_0 = 0, y_0 = 1;
    double x_i, y_i;
    double h = PARTS_LENGTH;
    for (int i = 1; i <= NUM_PARTS; i++) {
        x_i = x_0 + h;
        y_i = y_0 + h * integrand(x_0, y_0);
        printf("x_%d = %f, y_%d = %f\n", i, x_i, i, y_i);
        x_0 = x_i;
        y_0 = y_i;
    }
    return 0;
}