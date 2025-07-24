#include <math.h>
#include <stdio.h>

#define PARTS_LENGTH 0.01
#define NUM_PARTS 5000
// 初期値
#define X 0
#define Y_1 5
#define Y_2 1
#define A 2
#define B 1
#define C 3
#define D 1

float y_1X(float y_1, float y_2) { return A * y_1 - C * y_1 * y_2;}

float y_2X(float y_1, float y_2) { return D * y_1 * y_2 - B * y_2;}

int main(void) {
    float x_0 = X;
    float y_1_0 = Y_1;
    float y_2_0 = Y_2;
    float x_i, y_1_i, y_2_i;
    float h = PARTS_LENGTH;
    float a, b, c, d;
    a = A;
    b = B;
    c = C;
    d = D;
    printf("#x, y_1, y_2\n");
    printf("%f, %f, %f\n", x_0, y_1_0, y_2_0);
    for (int i = 1; i <= NUM_PARTS; i++) {
        x_i = x_0 + h;
        y_1_i = y_1_0 + h * y_1X(y_1_0, y_2_0);
        y_2_i = y_2_0 + h * y_2X(y_1_0, y_2_0);
        printf("%f, %f, %f\n", x_i, y_1_i, y_2_i);
        x_0 = x_i;
        y_1_0 = y_1_i;
        y_2_0 = y_2_i;
    }
    return 0;
}