#include <bits/stdc++.h>

using namespace std;

int main(void) {
    int i;
    int count = 0;
    int n;
    cin >> n;
    vector<int> A(n);
    for (i = 0; i < n; i++) {
        cin >> A.at(i);
    }
    while (1) {
        for (i = 0; i < n; i++) {
            if (A.at(i) % 2 != 0) {
                break;
            }
        }
        if (i != n) {
            break;
        } else {
            for (i = 0; i < n; i++) {
                A.at(i) /= 2;
            }
            count++;
        }
    }
    cout << count << endl;
}