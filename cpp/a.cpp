#include <bits/stdc++.h>
using namespace std;

int main() {
    int N;
    cin >> N;
    vector<int>A(N);
    for(int i = 0;i < N;i++){
        cin >> A[i];
    }
    for(int i = 0;i < N;i++){
        for(int j = i + 1;j < N;j++){
            if(A[i] == A[j]){
                cout << j - i + 1 << endl;
                return 0;
            }
        }
    }
    cout << "-1" << endl;
    return 0;
}