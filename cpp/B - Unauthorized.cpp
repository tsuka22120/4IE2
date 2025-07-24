#include <bits/stdc++.h>
using namespace std;

int main() {
    int count = 0;
    int N;
    cin >> N;
    string S, action;
    bool stat = false;
    while (N != 0) {
        cin >> S;
        if (S == "login") {
            stat = true;
        } else if (S == "logout") {
            stat = false;
        } else if (S == "private") {
            if (!stat) {
                count++;
            }
        }
        N--;
    }
    cout << count << endl;
}