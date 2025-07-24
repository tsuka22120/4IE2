#include<bits/stdc++.h>
using namespace std;

int main(){
    int Q;
    int stat;
    cin >> Q;
    vector<int>query;

    while(Q != 0){
        cin >> stat;
        if(stat == 1){
            int input;
            cin >> input;
            query.push_back(input);
        }else if(stat == 2){
            cout << query[0] << endl;
            query.erase(query.begin());
        }
        Q--;
    }
    return 0;
}