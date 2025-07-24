#include <bits/stdc++.h>

using namespace std;

int match(const vector<vector<string>> S, const vector<vector<string>> T,
          int N) {
    int count = 0;
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            if (S.at(i).at(j) == T.at(i).(j)) {
                count++;
            }
        }
    }
    return count;
}

void turn(const vector<vector<string>> S, vector<vector<string>> &T, int N) {
    int to_i, to_j;
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            to_i += N - 1;
            to_j = j;
            if (to_i >= N) {
                to_j += to_i - N - 1;
                to_i = N - 1;
            }
            T[to_i][to_j] = S[i][j];
        }
    }
}

int main() {
    int count = 0;
    int N;
    int before, after;
    vector<vector<string>> S(N, vector<string>(N));
    vector<vector<string>> T(N, vector<string>(N));
    vector<vector<string>> tmp = S;
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            cin >> S.at(i).at(j);
        }
    }
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            cin >> T.at(i).at(j);
        }
    }
    while (1) {
        before = match(S[0][0], T[0][0], N);
        turn(S[0][0], tmp[0][0], N);
        after
    }
}