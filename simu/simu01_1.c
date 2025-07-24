#include <stdio.h>
#include <math.h>

#define NUM_PARTS 8

float integrand(float x) {
    return 4 / (1 + x * x);  // Integrand for the function 4 / (1 + x^2)
}

float simpsonRule(float a, float b, int numParts) {
    float h = (b - a) / numParts;
    float ans = 0.0;
    ans = integrand(a) + integrand(b);
    for (int i = 1; i <= numParts - 1; i++) {
        if(i % 2 == 0) {
            ans += 2 * integrand(a + i * h);
        } else {
            ans += 4 * integrand(a + i * h);
        }
    }
    ans *= h / 3;
    return ans;
}



int main(void){
    float a = 0.0, b = 1.0;  // Integration limits
    float result = simpsonRule(a, b, NUM_PARTS);
    printf("The integral of 4 / (1 + x^2) from %f to %f with %d parts is: %f\n", a, b, NUM_PARTS, result);
    printf("The exact value is: %f\n", M_PI);  // Exact value of the integral
    return 0;
}