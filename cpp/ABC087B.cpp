#include <bits/stdc++.h>

using namespace std;

int main() {
    int count = 0;
    int A, B, C;
    int X;
    cin >> A >> B >> C;
    cin >> X;
    for (int i = 0; i < A + 1; i++) {
        for (int j = 0; j < B + 1; j++) {
            for (int k = 0; k < C + 1; k++) {
                if (X == 500 * i + 100 * j + 50 * k) {
                    count++;
                }
            }
        }
    }
    cout << count << endl;
}