#include <bits/stdc++.h>

using namespace std;

int main() {
    int N;
    long long sum = 0;
    long long ans = 0;
    cin >> N;
    vector<int> A(N);
    for (int i = 0; i < N; i++) {
        cin >> A[i];
    }
    for (int i = 0; i < N; i++) {
        ans += sum * A[i];
        sum += A[i];
    }
    cout << ans << endl;
    return 0;
}