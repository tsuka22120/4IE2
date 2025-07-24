#include <bits/stdc++.h>
using namespace std;

int main() {
    string T, U;
    bool ok = false;
    cin >> T >> U;
    for (int i = 0; i < T.size() + 1 - U.size(); i++) {
        if (ok) {
            break;
        }
        for (int j = 0; j < U.size(); j++) {
            if (T[i + j] != U[j] && T[i + j] != '?') {
                ok = false;
                break;
            } else {
                ok = true;
            }
        }
    }
    if (ok) {
        cout << "Yes" << endl;
    } else {
        cout << "No" << endl;
    }
}