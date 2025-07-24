#include <bits/stdc++.h>

using namespace std;

int main() {
    int N, Y;
    int i, j, k;
    cin >> N >> Y;
    for (i = 0; i < N + 1; i++) {
        for (j = 0; j < N - i + 1; j++) {
            for (k = 0; k < N - i - j + 1; k++) {
                if (Y == i * 10000 + j * 5000 + k * 1000 && i + j + k == N) {
                    cout << i << " " << j << " " << k << endl;
                    return 0;
                }
            }
        }
    }
    cout << "-1 -1 -1" << endl;
    return 0;
}