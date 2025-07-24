#include <math.h>
#include <stdio.h>

#define NUM_PARTS1 8
#define NUM_PARTS2 16
#define M_PI 3.14159265358979323846

float integrand(float x);

float simpsonRule(float a, float b, int numParts);

int main(void) {
    float a = 0.0, b = M_PI / 2.0;
    float result1 = simpsonRule(a, b, NUM_PARTS1);
    float result2 = simpsonRule(a, b, NUM_PARTS2);
    printf("The integral of sin(x) from %f to 2 / PI with 8 parts: %f\n", a,
           result1);
    printf("The integral of sin(x) from %f to 2 / PI with 16 parts is: %f\n", a,
           result2);
    printf("The exact value is: %f\n", 1.0);
    return 0;
}

float integrand(float x) { return sin(x); }

float simpsonRule(float a, float b, int numParts) {
    float h = (b - a) / numParts;
    float ans = 0.0;
    ans = integrand(a) + integrand(b);
    for (int i = 1; i <= numParts - 1; i++) {
        if (i % 2 == 0) {
            ans += 2 * integrand(a + i * h);
        } else {
            ans += 4 * integrand(a + i * h);
        }
    }
    ans *= h / 3;
    return ans;
}
