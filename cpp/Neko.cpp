#include<iostream>
#include<string>

class Neko{
    private:
    std::string name;
    public:
    Neko(std::string s){
        name = s;
    }
    void naku(){
        std::cout << name << "がにゃーと鳴きました" << std::endl;
    }
};

int main(){
    std::cout << "猫を生成します" << std::endl;
    std::cout << "猫の名前を入力してください" << std::endl;
    std::string name;
    std::cin >> name;
    std::cout << "あなたが名付けた猫の名前は" << name << "ですね" << std::endl;
    Neko neko1(name);
    std::cout << "あなたが名付けた猫がメモリ上に生成されました" << std::endl;
    std::cout << "猫が鳴きます" << std::endl;
    neko1.naku();
}