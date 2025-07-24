#include <bits/stdc++.h>

using namespace std;

int main() {
    int ans = 0;
    int i;
    int N;
    int A, B;
    int sum = 0;
    cin >> N >> A >> B;
    i = N;
    while (i != 0) {
        while (1) {
            if (N != 0) {
                sum += N % 10;
                N /= 10;
            } else {
                break;
            }
        }
        if(sum >= A && sum <= B){
            ans += i;
        }
        i--;
        N = i;
        sum = 0;
    }
    cout << ans << endl;
}
