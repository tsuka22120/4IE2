#include<iostream>
#include<string>

using namespace std;

int main(){
    string name;
    int age;
    cout << "こんにちは．私はコンピュータです．" << endl;
    cout << "あなたの名前は何ですか？" << endl;
    cin >> name;
    cout << "こんにちは，" << name << "さん！" << endl;
    cout << "失礼ですが，あなたの年齢は何歳ですか？" << endl;
    cin >> age;
    cout << "あなたは" << age << "歳なのですね．" << endl;
}