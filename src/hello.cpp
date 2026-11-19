// CI 矩阵示例程序：编译通过后运行内置自检，退出码非 0 即判定失败。
#include <cassert>
#include <iostream>

int main() {
    int a = 2, b = 2;
    assert(a + b == 4);

    std::cout << "hello from CI matrix" << std::endl;
    std::cout << "a + b = " << a + b << std::endl;
    return 0;
}
