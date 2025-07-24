#include <bits/stdc++.h>

using namespace std;

int main() {
    int R, X;
    cin >> R >> X;
    if (X == 1) {
        if (1600 <= R && R <= 2999) {
            cout << "Yes" << endl;
            return 0;
        }
    } else if (X == 2){
        if(1200 <= R && R <= 2399){
            cout << "Yes" << endl;
            return 0;
        }
    }
    cout << "No" << endl;
}