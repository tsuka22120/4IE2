#include<bits/stdc++.h>
using namespace std;

int main(){
    int sum = 0;
    int N;
    cin >> N;
    vector<int>A(N);
    for(int i = 0;i < N;i++){
        cin >> A[i];
    }
    for(int i = 0;i < N;i += 2){
        sum += A[i];
    }
    cout << sum << endl;
}