#include <bits/stdc++.h>

using namespace std;

int main() {
    int N, M;
    int count = 0;
    cin >> N >> M;
    vector<int> A(N);
    vector<int> Num(M);
    for (int i = 0; i < N; i++) {
        cin >> A[i];
    }
    while (1) {
        for (int i = 0; i < N; i++) {
            Num[A[i] - 1] = A[i];
        }
        for (int i = 0; i < M; i++) {
            if (Num[i] != i + 1) {
                cout << count << endl;
                return 0;
            }
        }
        count++;
        A.pop_back();
        N--;
        for (int i = 0; i < M; i++) {
            Num[i] = 0;
        }
    }
}